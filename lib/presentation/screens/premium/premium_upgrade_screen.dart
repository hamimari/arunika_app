import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/static/premium_packs.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/premium/premium_pack_cubit.dart';
import 'package:go_router/go_router.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          context.push('/payment', extra: pack);
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pack.formattedPrice,
                  style: AppTextStyles.subheading.copyWith(
                    color: pack.isBestValue
                        ? AppColors.white
                        : AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: pack.isBestValue
                      ? AppColors.white
                      : AppColors.lockGrey,
                ),
              ],
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
                    context.push('/payment', extra: pack);
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
                    context.push('/payment', extra: pack);
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
