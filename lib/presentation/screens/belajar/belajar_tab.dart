import 'package:arunika_app/data/models/response/angka_response.dart';
import 'package:arunika_app/presentation/screens/angka/angka_question_screen.dart';
import 'package:arunika_app/presentation/screens/angka/angka_screen.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_hub_screen.dart';
import 'package:arunika_app/data/models/response/huruf_response.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_detail_screen.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_list_screen.dart';
import 'package:flutter/material.dart';

enum BelajarDestination { hub, kartuAr, dongeng, huruf, angka }

/// The Belajar tab: a hub with Kartu AR, Dongeng, Huruf and Angka, each opening inside the
/// tab's own navigation stack so the bottom bar stays visible. Screens they
/// push themselves (AR viewer, Dongeng player, payment) still use the root
/// routes.
class BelajarTab extends StatefulWidget {
  final Widget Function(BuildContext context, String? categoryId)
  kartuArBuilder;
  final Widget Function(BuildContext context, String? highlightProductId)
  dongengBuilder;

  /// Called after the inner stack changes, with whether it can pop.
  final ValueChanged<bool>? onCanPopChanged;

  const BelajarTab({
    super.key,
    required this.kartuArBuilder,
    required this.dongengBuilder,
    this.onCanPopChanged,
  });

  @override
  State<BelajarTab> createState() => BelajarTabState();
}

class BelajarTabState extends State<BelajarTab> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final _observer = _StackObserver(_notify);

  NavigatorState? get _nav => _navigatorKey.currentState;

  bool get canPop => _nav?.canPop() ?? false;

  /// Shows [destination], starting from the hub so back always returns there.
  ///
  /// For Huruf, [hurufLetter] also opens that letter's detail on top of the
  /// letter list (Beranda "Lanjutkan belajar"), starting at [hurufStart].
  /// For Angka, [angkaLevel] resumes that level on top of Belajar Angka.
  void open(
    BelajarDestination destination, {
    String? categoryId,
    String? highlightProductId,
    HurufManifestLetter? hurufLetter,
    HurufActivity? hurufStart,
    AngkaManifestLevel? angkaLevel,
  }) {
    final nav = _nav;
    if (nav == null) return;
    nav.popUntil((r) => r.isFirst);
    switch (destination) {
      case BelajarDestination.hub:
        return;
      case BelajarDestination.kartuAr:
        nav.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'kartu-ar'),
            builder: (ctx) => widget.kartuArBuilder(ctx, categoryId),
          ),
        );
      case BelajarDestination.dongeng:
        nav.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'dongeng'),
            builder: (ctx) => widget.dongengBuilder(ctx, highlightProductId),
          ),
        );
      case BelajarDestination.huruf:
        nav.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'huruf'),
            builder: (_) => const HurufListScreen(),
          ),
        );
        if (hurufLetter != null) {
          nav.push(
            MaterialPageRoute(
              settings: RouteSettings(name: 'huruf-${hurufLetter.upper}'),
              builder: (_) => HurufDetailScreen(
                letter: hurufLetter,
                initialActivity: hurufStart,
              ),
            ),
          );
        }
      case BelajarDestination.angka:
        nav.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'angka'),
            builder: (_) => const AngkaScreen(),
          ),
        );
        if (angkaLevel != null) {
          nav.push(
            MaterialPageRoute(
              settings: RouteSettings(name: 'angka-level-${angkaLevel.id}'),
              builder: (_) => AngkaQuestionScreen(level: angkaLevel),
            ),
          );
        }
    }
  }

  void popToHub() => _nav?.popUntil((r) => r.isFirst);

  void pop() => _nav?.maybePop();

  void _notify() {
    // Navigator callbacks fire mid-frame; report once it has settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCanPopChanged?.call(canPop);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      observers: [_observer],
      onGenerateInitialRoutes: (_, __) => [
        MaterialPageRoute(
          builder: (_) => BelajarHubScreen(onOpen: (d) => open(d)),
        ),
      ],
    );
  }
}

class _StackObserver extends NavigatorObserver {
  final VoidCallback onChange;
  _StackObserver(this.onChange);

  @override
  void didPush(Route route, Route? previousRoute) => onChange();
  @override
  void didPop(Route route, Route? previousRoute) => onChange();
  @override
  void didRemove(Route route, Route? previousRoute) => onChange();
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => onChange();
}
