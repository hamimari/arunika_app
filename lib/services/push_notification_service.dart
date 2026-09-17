import 'dart:async';

import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/core/utils/auth_guard.dart';
import 'package:arunika_app/data/api/notification_api.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/app_router.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/vocab/ar_card_detail_screen.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:arunika_app/presentation/widgets/in_app_notification_banner.dart';
import 'package:arunika_app/services/push_link.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wires Firebase Cloud Messaging into the app:
/// * every install subscribes to the promo topic (guests included), so
///   "all devices" campaigns from the backoffice reach everyone;
/// * the device token is linked to the user on login (for user-targeted
///   pushes) and rotated on logout so the old account stops receiving them;
/// * tapping a notification opens the AR card / dongeng it links to.
class PushNotificationService {
  /// Must match `services.PromoTopic` in the backend.
  static const String promoTopic = 'arunika_promo';

  final FirebaseMessaging _messaging;
  final NotificationApi _api;
  final AuthNotifier _auth;

  bool _initialized = false;
  bool _wasLoggedIn = false;

  /// A link from the notification that launched the app, held until the
  /// main shell exists to navigate from.
  PushLink? _pendingLink;

  PushNotificationService(this._messaging, this._api, this._auth);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _messaging.requestPermission();
      await _messaging.subscribeToTopic(promoTopic);

      _wasLoggedIn = _auth.isLoggedIn;
      if (_wasLoggedIn) unawaited(_registerToken());
      _auth.addListener(_onAuthChanged);
      _messaging.onTokenRefresh.listen((token) {
        if (_auth.isLoggedIn) unawaited(_registerToken(token));
      });

      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => openLink(PushLink.fromData(message.data)),
      );
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        final link = PushLink.fromData(initial.data);
        if (!link.isNone) {
          _pendingLink = link;
          // The shell may already be up if init() finished after it built.
          consumePendingLink();
        }
      }
    } catch (e, st) {
      // Push is non-essential — never let it break app startup.
      AppLogger.error(
        'Push notification setup failed',
        name: 'Push',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _onAuthChanged() {
    final loggedIn = _auth.isLoggedIn;
    if (loggedIn == _wasLoggedIn) return;
    _wasLoggedIn = loggedIn;
    unawaited(loggedIn ? _registerToken() : _rotateToken());
  }

  Future<void> _registerToken([String? token]) async {
    try {
      token ??= await _messaging.getToken();
      if (token == null) return;
      await _api.registerToken(token);
    } catch (e) {
      AppLogger.warning('Failed to register FCM token', name: 'Push', error: e);
    }
  }

  /// The backend has no unlink endpoint, so on logout the device token is
  /// deleted (the server prunes it on its next failed send) and a fresh one
  /// is re-subscribed to the promo topic.
  Future<void> _rotateToken() async {
    try {
      await _messaging.deleteToken();
      await _messaging.subscribeToTopic(promoTopic);
    } catch (e) {
      AppLogger.warning('Failed to rotate FCM token', name: 'Push', error: e);
    }
  }

  /// Android and iOS don't show a system notification while the app is in
  /// the foreground, so show it in-app as a banner at the top of the screen.
  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final overlay =
        AppRouter.router.routerDelegate.navigatorKey.currentState?.overlay;
    if (notification == null || overlay == null) return;
    final link = PushLink.fromData(message.data);
    InAppNotificationBanner.show(
      overlay,
      title: notification.title ?? '',
      body: notification.body ?? '',
      imageUrl: notification.android?.imageUrl ?? notification.apple?.imageUrl,
      onTap: link.isNone ? null : () => openLink(link),
    );
  }

  /// Called by the main shell once it is built, to handle a notification
  /// that launched the app.
  void consumePendingLink() {
    final link = _pendingLink;
    if (link == null || MainShell.shellKey.currentState == null) return;
    _pendingLink = null;
    openLink(link);
  }

  /// Opens the linked content, applying the same unlocked / login /
  /// purchase rules as tapping it in the app.
  Future<void> openLink(PushLink link) async {
    if (link.isNone) return;
    try {
      switch (link.type) {
        case PushLinkType.dongeng:
          final dongeng = await locator<FairyTalesRepository>().findById(
            link.id,
          );
          final context = _navigatorContext;
          if (context == null || !context.mounted) return;
          if (dongeng.isUnlocked) {
            context.push('/dongeng-player', extra: dongeng);
          } else if (!_auth.isLoggedIn) {
            await showLoginRequiredDialog(
              context,
              featureLabel: 'dongeng premium',
            );
          } else {
            goToProductPurchase(
              context,
              productId: dongeng.productId,
              title: dongeng.title,
              priceIdr: dongeng.priceIdr,
              contentType: PurchasedContentType.dongeng,
              subtitle: 'Akses ke dongeng ${dongeng.title}',
            );
          }
        case PushLinkType.arCard:
          final card = await locator<ArRepository>().findById(link.id);
          final context = _navigatorContext;
          if (context == null || !context.mounted) return;
          if (card.isUnlocked) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ArCardDetailScreen(card: card)),
            );
          } else if (!_auth.isLoggedIn) {
            await showLoginRequiredDialog(
              context,
              featureLabel: 'koleksi kartu AR',
            );
          } else {
            goToProductPurchase(
              context,
              productId: card.productId,
              title: card.title ?? 'Kartu AR',
              priceIdr: card.priceIdr,
              contentType: PurchasedContentType.arCard,
              subtitle: 'Akses ke kartu AR ${card.title ?? ''}'.trim(),
            );
          }
        case PushLinkType.none:
          return;
      }
    } catch (e) {
      // Content removed or network down — fall back to the matching tab.
      AppLogger.warning('Failed to open push link', name: 'Push', error: e);
      MainShell.shellKey.currentState?.switchTab(
        link.type == PushLinkType.dongeng
            ? MainShellTab.dongeng
            : MainShellTab.collection,
      );
    }
  }

  BuildContext? get _navigatorContext =>
      AppRouter.router.routerDelegate.navigatorKey.currentContext;
}
