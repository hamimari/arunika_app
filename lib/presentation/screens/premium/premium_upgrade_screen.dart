import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/utils/price_format.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';
import 'package:arunika_app/data/repositories/premium_pack_repository.dart';
import 'package:arunika_app/data/repositories/profile_loader.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/premium/premium_pack_cubit.dart';
import 'package:arunika_app/presentation/screens/widgets/active_subscription_view.dart';
import 'package:arunika_app/presentation/screens/widgets/price_tag.dart';
import 'package:go_router/go_router.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  // When true (reached from the profile page's "Perpanjang" CTA), only the
  // subscription tab is shown — renewing a subscription has nothing to do
  // with one-time content bundles. An active subscriber inside the renewal
  // window always gets this mode.
  final bool subscriptionOnly;

  const PremiumUpgradeScreen({super.key, this.subscriptionOnly = false});

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  // An active subscriber sees no packages, except inside the renewal window
  // of a subscription the app itself can renew (see SubscriptionInfo).
  bool _checkingSubscription = true;
  SubscriptionInfo? _subscription;
  // Pack types that have at least one pack; a tab is only shown for these.
  List<String> _packTypes = const ['content', 'subscription'];

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    SubscriptionInfo? sub;
    try {
      sub = await locator<ProfileLoader>().activeSubscription();
    } catch (_) {
      // Unknown status: fall through to the normal package list — the
      // backend still refuses a purchase that isn't allowed.
    }
    final showsTabs = sub == null && !widget.subscriptionOnly;
    final types = showsTabs ? await _packTypesWithPacks() : _packTypes;
    if (!mounted) return;
    setState(() {
      _subscription = sub;
      _packTypes = types;
      if (showsTabs && types.length == 2) {
        _tabController = TabController(length: 2, vsync: this);
      }
      _checkingSubscription = false;
    });
  }

  // If the lookup fails, keep both tabs so the screen still works.
  Future<List<String>> _packTypesWithPacks() async {
    const all = ['content', 'subscription'];
    try {
      final repo = locator<PremiumPackRepository>();
      final results = await Future.wait(all.map((t) => repo.fetchPacks(type: t)));
      return [
        for (var i = 0; i < all.length; i++)
          if (results[i].isNotEmpty) all[i],
      ];
    } catch (_) {
      return all;
    }
  }

  AppBar _plainAppBar(String title) => AppBar(
    title: Text(title, style: AppTextStyles.subheading),
    backgroundColor: AppColors.creamBackground,
    elevation: 0,
    leading: const BackButton(color: AppColors.deepBrown),
  );

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSubscription) {
      return Scaffold(
        backgroundColor: AppColors.creamBackground,
        appBar: _plainAppBar(AppStrings.premiumTitle),
        body: const _LoadingSkeleton(),
      );
    }

    final sub = _subscription;
    final canRenewInApp = sub != null && sub.canRenew && !sub.isGooglePlay;
    if (sub != null && !canRenewInApp) {
      return Scaffold(
        backgroundColor: AppColors.creamBackground,
        appBar: _plainAppBar(AppStrings.premiumTitle),
        body: ActiveSubscriptionView(
          subscription: sub,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    if (widget.subscriptionOnly || canRenewInApp) {
      return Scaffold(
        backgroundColor: AppColors.creamBackground,
        appBar: _plainAppBar(AppStrings.premiumTabSubscription),
        body: Column(
          children: [
            if (canRenewInApp && sub.expiresAt != null)
              _RenewalBanner(expiresAt: sub.expiresAt!),
            Expanded(
              child: BlocProvider(
                create: (_) => PremiumPackCubit('subscription')..loadPacks(),
                child: const _PackTabView(),
              ),
            ),
          ],
        ),
      );
    }

    // Only one pack type has packs: show it alone, without a tab bar.
    if (_packTypes.length < 2) {
      final type = _packTypes.isEmpty ? 'content' : _packTypes.first;
      final title = type == 'content'
          ? AppStrings.premiumTabContent
          : AppStrings.premiumTabSubscription;
      return Scaffold(
        backgroundColor: AppColors.creamBackground,
        appBar: _plainAppBar(title),
        body: BlocProvider(
          create: (_) => PremiumPackCubit(type)..loadPacks(),
          child: const _PackTabView(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: Text(AppStrings.premiumTitle, style: AppTextStyles.subheading),
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        leading: const BackButton(color: AppColors.deepBrown),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTextStyles.bodyLarge,
          unselectedLabelStyle: AppTextStyles.body,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: AppColors.mediumBrown,
          indicatorColor: AppColors.primaryOrange,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: AppStrings.premiumTabContent),
            Tab(text: AppStrings.premiumTabSubscription),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Each tab gets its own BlocProvider with a separate cubit instance
          BlocProvider(
            create: (_) => PremiumPackCubit('content')..loadPacks(),
            child: const _PackTabView(),
          ),
          BlocProvider(
            create: (_) => PremiumPackCubit('subscription')..loadPacks(),
            child: const _PackTabView(),
          ),
        ],
      ),
    );
  }
}

// ─── Tab View (shared for both tabs) ─────────────────────────────────────────

class _PackTabView extends StatelessWidget {
  const _PackTabView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PremiumPackCubit, PremiumPackState>(
      builder: (context, state) {
        if (state is PremiumPackLoading || state is PremiumPackInitial) {
          return const _LoadingSkeleton();
        }
        if (state is PremiumPackError) {
          return _ErrorRetry(
            message: state.message,
            onRetry: () => context.read<PremiumPackCubit>().loadPacks(),
          );
        }
        if (state is PremiumPackLoaded) {
          return _PackList(packs: state.packs);
        }
        return const _LoadingSkeleton();
      },
    );
  }
}

// ─── Renewal Banner ───────────────────────────────────────────────────────────

class _RenewalBanner extends StatelessWidget {
  final DateTime expiresAt;
  const _RenewalBanner({required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_repeat_rounded,
            color: AppColors.successGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Masa aktif baru ditambahkan mulai ${formatLongDate(expiresAt)}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.deepBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.mediumBrown),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackList extends StatelessWidget {
  final List<PremiumPack> packs;
  const _PackList({required this.packs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: packs.length,
      itemBuilder: (_, i) => _PackCard(pack: packs[i]),
    );
  }
}

class _PackCard extends StatelessWidget {
  final PremiumPack pack;
  const _PackCard({required this.pack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final auth = locator<AuthNotifier>();
        if (!auth.isLoggedIn) {
          await showDialog<void>(
            context: context,
            builder: (_) => _PremiumLoginGuardDialog(pack: pack),
          );
          return;
        }
        if (context.mounted) {
          context.push('/payment', extra: PurchasableItem.fromPackage(pack));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pack.isBestValue ? AppColors.primaryOrange : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepBrown.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pack.badgeLabel != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pack.isBestValue
                            ? AppColors.accentGold
                            : AppColors.premiumBadgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pack.badgeLabel!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.deepBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    pack.name,
                    style: AppTextStyles.subheading.copyWith(
                      color: pack.isBestValue
                          ? AppColors.white
                          : AppColors.deepBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pack.subtitle,
                    style: AppTextStyles.body.copyWith(
                      color: pack.isBestValue
                          ? AppColors.white.withValues(alpha: 0.85)
                          : AppColors.mediumBrown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PriceTag(
                    price: pack.priceIdr,
                    strikePrice: pack.strikePriceIdr,
                    discountPercent: pack.discountPercent,
                    promoEndsAt: pack.promoEndsAt,
                    showPromoEnd: true,
                    priceColor: pack.isBestValue
                        ? AppColors.white
                        : AppColors.primaryOrange,
                    mutedColor: pack.isBestValue
                        ? AppColors.white.withValues(alpha: 0.75)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: pack.isBestValue ? AppColors.white : AppColors.lockGrey,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Login Guard Dialog for Premium Pack ──────────────────────────────────────

class _PremiumLoginGuardDialog extends StatelessWidget {
  final PremiumPack pack;
  const _PremiumLoginGuardDialog({required this.pack});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('⭐', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Masuk Dulu, Yuk!',
              style: AppTextStyles.subheading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Untuk membeli paket premium, kamu perlu masuk atau daftar terlebih dahulu.',
              style: AppTextStyles.body.copyWith(color: AppColors.mediumBrown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await context.push('/signin');
                  if (context.mounted && locator<AuthNotifier>().isLoggedIn) {
                    context.push('/payment', extra: PurchasableItem.fromPackage(pack));
                  }
                },
                child: Text('Masuk', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 10),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await context.push('/signup');
                  if (context.mounted && locator<AuthNotifier>().isLoggedIn) {
                    context.push('/payment', extra: PurchasableItem.fromPackage(pack));
                  }
                },
                child: Text(
                  'Daftar Gratis',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dismiss
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Nanti Saja',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mediumBrown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
