import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/data/models/response/huruf_response.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_cubit.dart';
import 'package:arunika_app/services/push_notification_service.dart';

// Tab ids — used by other screens to switch tabs programmatically. These are
// stable identifiers, not positions: tabs can be hidden (logged out, or a
// feature switched off from the backoffice), which shifts positions.
class MainShellTab {
  static const int home = 0;
  static const int belajar = 1;
  static const int tumbuh = 2;
  static const int profil = 3;
}

/// Beranda · Belajar · Tumbuh · Profil. Kartu AR and Dongeng live inside
/// Belajar (see [BelajarTab]); QR scan is reached from the Kartu AR header.
class MainShell extends StatefulWidget {
  final Widget homeScreen;
  final Widget Function(BuildContext context, String? categoryId)
  kartuArBuilder;
  final Widget Function(BuildContext context, String? highlightProductId)
  dongengBuilder;
  final Widget growthScreen;
  final Widget profileScreen;

  /// Called whenever the visible tab changes, with its id.
  final ValueChanged<int>? onTabChanged;

  const MainShell({
    super.key,
    required this.homeScreen,
    required this.kartuArBuilder,
    required this.dongengBuilder,
    required this.growthScreen,
    required this.profileScreen,
    this.onTabChanged,
  });

  /// Switch tabs from anywhere by using a `GlobalKey<MainShellState>`.
  static GlobalKey<MainShellState> shellKey = GlobalKey<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = MainShellTab.home;
  bool _belajarCanPop = false;
  final _belajarKey = GlobalKey<BelajarTabState>();
  late final AuthNotifier _authNotifier;
  late final FeatureFlagsNotifier _featureFlags;

  @override
  void initState() {
    super.initState();
    _authNotifier = locator<AuthNotifier>();
    _authNotifier.addListener(_onVisibilityChanged);
    _featureFlags = locator<FeatureFlagsNotifier>();
    _featureFlags.addListener(_onVisibilityChanged);
    WidgetsBinding.instance.addObserver(this);
    // Open whatever a launch-time push notification linked to.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => locator<PushNotificationService>().consumePendingLink(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _featureFlags.removeListener(_onVisibilityChanged);
    _authNotifier.removeListener(_onVisibilityChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pick up features toggled from the backoffice while the app was in the
    // background.
    if (state == AppLifecycleState.resumed) _featureFlags.refresh();
  }

  /// Logging out, or a feature switched off, can hide the open tab: whenever
  /// that happens, return to home.
  void _onVisibilityChanged() {
    if (!_visibleTabs().contains(_currentIndex)) {
      _currentIndex = MainShellTab.home;
      widget.onTabChanged?.call(_currentIndex);
    }
    setState(() {});
  }

  /// Tab ids currently shown, in display order.
  List<int> _visibleTabs() => [
    MainShellTab.home,
    MainShellTab.belajar,
    if (_authNotifier.isLoggedIn && _featureFlags.growthTrackingEnabled)
      MainShellTab.tumbuh,
    if (_authNotifier.isLoggedIn) MainShellTab.profil,
  ];

  /// Switches to the tab with id [tab]; ignored if that tab is hidden.
  void switchTab(int tab) {
    if (!_visibleTabs().contains(tab)) return;
    if (tab == _currentIndex) {
      // Tapping Belajar again returns to its hub.
      if (tab == MainShellTab.belajar) _belajarKey.currentState?.popToHub();
      return;
    }
    setState(() => _currentIndex = tab);
    widget.onTabChanged?.call(tab);
  }

  /// Opens a Belajar destination (Kartu AR, optionally filtered to a category,
  /// Dongeng, optionally highlighting a story, or Huruf, optionally a letter).
  void openBelajar(
    BelajarDestination destination, {
    String? categoryId,
    String? highlightProductId,
    HurufManifestLetter? hurufLetter,
    HurufActivity? hurufStart,
  }) {
    if (_currentIndex != MainShellTab.belajar) {
      setState(() => _currentIndex = MainShellTab.belajar);
      widget.onTabChanged?.call(MainShellTab.belajar);
    }
    _belajarKey.currentState?.open(
      destination,
      categoryId: categoryId,
      highlightProductId: highlightProductId,
      hurufLetter: hurufLetter,
      hurufStart: hurufStart,
    );
  }

  Widget _screenFor(int tab) => switch (tab) {
    MainShellTab.belajar => BelajarTab(
      key: _belajarKey,
      kartuArBuilder: widget.kartuArBuilder,
      dongengBuilder: widget.dongengBuilder,
      onCanPopChanged: (v) {
        if (mounted && v != _belajarCanPop) setState(() => _belajarCanPop = v);
      },
    ),
    MainShellTab.tumbuh => widget.growthScreen,
    MainShellTab.profil => widget.profileScreen,
    _ => widget.homeScreen,
  };

  @override
  Widget build(BuildContext context) {
    final tabs = _visibleTabs();
    final activeTab = tabs.contains(_currentIndex)
        ? _currentIndex
        : MainShellTab.home;
    final innerBack = activeTab == MainShellTab.belajar && _belajarCanPop;

    return PopScope(
      // System back closes Kartu AR / Dongeng before leaving the app.
      canPop: !innerBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && innerBack) _belajarKey.currentState?.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: tabs.indexOf(activeTab),
          // Keyed by tab id so hiding a tab doesn't hand its state to the
          // screen that slides into its position.
          children: [
            for (final tab in tabs)
              KeyedSubtree(key: ValueKey(tab), child: _screenFor(tab)),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(tabs, activeTab),
      ),
    );
  }

  Widget _buildBottomNav(List<int> visibleTabs, int activeTab) {
    const allItems = <_NavTabItem>[
      _NavTabItem(
        label: AppStrings.navHome,
        icon: Iconsax.sun_fog,
        index: MainShellTab.home,
      ),
      _NavTabItem(
        label: AppStrings.navBelajar,
        icon: Iconsax.teacher,
        index: MainShellTab.belajar,
      ),
      _NavTabItem(
        label: AppStrings.navTumbuh,
        icon: Icons.spa_outlined,
        index: MainShellTab.tumbuh,
      ),
      _NavTabItem(
        label: AppStrings.navParent,
        icon: Iconsax.profile_circle,
        index: MainShellTab.profil,
      ),
    ];
    final items = allItems.where((i) => visibleTabs.contains(i.index));

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items
              .map((item) => _buildNavTab(item, activeTab == item.index))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildNavTab(_NavTabItem item, bool isActive) {
    return Semantics(
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: () => switchTab(item.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.navActivePill : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: isActive ? AppColors.navActive : AppColors.navInactive,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.navActive : AppColors.navInactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTabItem {
  final String label;
  final IconData icon;
  final int index;

  const _NavTabItem({
    required this.label,
    required this.icon,
    required this.index,
  });
}
