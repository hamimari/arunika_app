import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/services/push_notification_service.dart';

// Tab ids — used by other screens to switch tabs programmatically. These are
// stable identifiers, not positions: tabs can be hidden (logged out, or a
// feature switched off from the backoffice), which shifts positions.
class MainShellTab {
  static const int home = 0;
  static const int scan = 1;
  static const int collection = 2;
  static const int dongeng = 3;
  static const int parent = 4;
}

class MainShell extends StatefulWidget {
  final Widget homeScreen;
  final Widget scanScreen;
  final Widget collectionScreen;
  final Widget dongengScreen;
  final Widget parentScreen;

  const MainShell({
    super.key,
    required this.homeScreen,
    required this.scanScreen,
    required this.collectionScreen,
    required this.dongengScreen,
    required this.parentScreen,
  });

  /// Switch tabs from anywhere by using a `GlobalKey<MainShellState>`.
  static GlobalKey<MainShellState> shellKey = GlobalKey<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = MainShellTab.home;
  late final AuthNotifier _authNotifier;
  late final FeatureFlagsNotifier _featureFlags;

  @override
  void initState() {
    super.initState();
    _authNotifier = locator<AuthNotifier>();
    _authNotifier.addListener(_onAuthChanged);
    _featureFlags = locator<FeatureFlagsNotifier>();
    _featureFlags.addListener(_onFeatureFlagsChanged);
    WidgetsBinding.instance.addObserver(this);
    // Open whatever a launch-time push notification linked to.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => locator<PushNotificationService>().consumePendingLink(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _featureFlags.removeListener(_onFeatureFlagsChanged);
    _authNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pick up features toggled from the backoffice while the app was in the
    // background.
    if (state == AppLifecycleState.resumed) _featureFlags.refresh();
  }

  void _onFeatureFlagsChanged() {
    // If the tab being viewed was just hidden, fall back to home.
    if (!_visibleTabs().contains(_currentIndex)) {
      _currentIndex = MainShellTab.home;
    }
    setState(() {});
  }

  /// Tab ids currently shown, in display order.
  List<int> _visibleTabs() => [
    MainShellTab.home,
    if (_featureFlags.qrScanEnabled) MainShellTab.scan,
    MainShellTab.collection,
    MainShellTab.dongeng,
    if (_authNotifier.isLoggedIn) MainShellTab.parent,
  ];

  void _onAuthChanged() {
    // Whenever the user is no longer logged in, unconditionally return to the
    // home tab. This covers all tabs (not just the profile tab) and prevents
    // stale tab indices from leaving the shell in an inconsistent state after
    // logout.
    if (!_authNotifier.isLoggedIn) {
      _currentIndex = MainShellTab.home;
    }
    setState(() {});
  }

  /// Switches to the tab with id [tab]; ignored if that tab is hidden.
  void switchTab(int tab) {
    if (!_visibleTabs().contains(tab)) return;
    setState(() => _currentIndex = tab);
  }

  Widget _screenFor(int tab) => switch (tab) {
    MainShellTab.scan => widget.scanScreen,
    MainShellTab.collection => widget.collectionScreen,
    MainShellTab.dongeng => widget.dongengScreen,
    MainShellTab.parent => widget.parentScreen,
    _ => widget.homeScreen,
  };

  @override
  Widget build(BuildContext context) {
    final tabs = _visibleTabs();
    final activeTab = tabs.contains(_currentIndex)
        ? _currentIndex
        : MainShellTab.home;

    return Scaffold(
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
    );
  }

  Widget _buildBottomNav(List<int> visibleTabs, int activeTab) {
    final allItems = <_NavTabItem>[
      _NavTabItem(
        label: AppStrings.navHome,
        icon: Iconsax.sun_fog,
        activeIcon: Iconsax.sun_fog,
        index: MainShellTab.home,
      ),
      _NavTabItem(
        label: AppStrings.navScan,
        icon: Iconsax.scan,
        activeIcon: Iconsax.scan,
        index: MainShellTab.scan,
        // isCenter: true, // ignored: feature disabled but field kept for future use
      ),
      _NavTabItem(
        label: AppStrings.navCollection,
        icon: Iconsax.additem,
        activeIcon: Iconsax.additem,
        index: MainShellTab.collection,
      ),
      _NavTabItem(
        label: AppStrings.navDongeng,
        icon: Iconsax.magicpen,
        activeIcon: Iconsax.magicpen,
        index: MainShellTab.dongeng,
      ),
      _NavTabItem(
        label: AppStrings.navParent,
        icon: Iconsax.profile_circle,
        activeIcon: Iconsax.profile_circle5,
        index: MainShellTab.parent,
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
    if (item.isCenter) {
      // Prominent scan button
      return GestureDetector(
        onTap: () => setState(() => _currentIndex = item.index),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryOrange, AppColors.primaryOrangeDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            color: AppColors.white,
            size: 26,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = item.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryOrange.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
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
    );
  }
}

class _NavTabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final bool isCenter;

  const _NavTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.index,
    // ignore: unused_element_parameter
    this.isCenter = false,
  });
}
