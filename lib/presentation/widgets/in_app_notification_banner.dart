import 'dart:async';

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/media/media_cache.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Shows a push notification received while the app is open as a card that
/// slides down from the top of the screen, styled like the app's own cards.
///
/// Only one banner is visible at a time: a new one replaces the current one.
/// It dismisses itself after [duration], on swipe-up, via its close button, or
/// when tapped (after running [onTap]).
class InAppNotificationBanner {
  InAppNotificationBanner._();

  static const Duration duration = Duration(seconds: 6);

  static OverlayEntry? _current;

  static void show(
    OverlayState overlay, {
    required String title,
    required String body,
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    dismiss();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BannerView(
        title: title,
        body: body,
        imageUrl: imageUrl,
        onTap: onTap,
        onDismissed: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  /// Removes the visible banner immediately, if any.
  static void dismiss() {
    final entry = _current;
    _current = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _BannerView extends StatefulWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback onDismissed;

  const _BannerView({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  State<_BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<_BannerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  Timer? _autoDismiss;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoDismiss = Timer(InAppNotificationBanner.duration, _close);
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _autoDismiss?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  void _handleTap() {
    widget.onTap?.call();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final hasImage = widget.imageUrl?.startsWith('https://') ?? false;

    return Positioned(
      top: topInset + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _controller,
          child: Dismissible(
            key: const ValueKey('in-app-notification'),
            direction: DismissDirection.up,
            onDismissed: (_) {
              _autoDismiss?.cancel();
              widget.onDismissed();
            },
            child: Semantics(
              liveRegion: true,
              button: widget.onTap != null,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _handleTap,
                  child: Ink(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.18,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Leading(imageUrl: hasImage ? widget.imageUrl : null),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.title.isNotEmpty)
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepBrown,
                                    height: 1.3,
                                  ),
                                ),
                              if (widget.body.isNotEmpty)
                                Text(
                                  widget.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.mediumBrown,
                                    height: 1.4,
                                  ),
                                ),
                              if (widget.onTap != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Lihat',
                                    style: AppTextStyles.buttonSmall.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tutup',
                          visualDensity: VisualDensity.compact,
                          onPressed: _close,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.lightBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  final String? imageUrl;

  const _Leading({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryOrangeLight, AppColors.primaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Iconsax.notification_bing,
        color: AppColors.white,
        size: 24,
      ),
    );
    if (imageUrl == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image(
        image: MediaCache.image(imageUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
