import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/belajar/belajar_tab.dart';
import 'package:arunika_app/presentation/screens/vocab/ar_card_detail_screen.dart';
import 'package:go_router/go_router.dart';

class UnlockSuccessScreen extends StatefulWidget {
  final PurchasableItem item;

  const UnlockSuccessScreen({super.key, required this.item});

  @override
  State<UnlockSuccessScreen> createState() => _UnlockSuccessScreenState();
}

class _UnlockSuccessScreenState extends State<UnlockSuccessScreen> {
  late final ConfettiController _confetti;
  bool _isOpeningCard = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _confetti.play();
    _refreshProfile();
  }

  // Refresh the cached profile so the home screen's premium banner reflects
  // the new subscription/entitlement immediately, instead of waiting for the
  // next pull-to-refresh or app restart.
  Future<void> _refreshProfile() async {
    final userId = await SecureTokenStorage.getUserId();
    if (userId == null) return;
    try {
      final profile = await locator<UserRepository>().findById(userId);
      await LocalProfileStorage.save(profile);
    } catch (_) {
      // best-effort — home screen will still refetch on its own next load
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  // Subscription purchases land on the profile page (shows the new plan);
  // single-dongeng purchases land on the dongeng tab with the story pinned
  // as the featured item (list stays unfiltered); a single AR card purchase
  // opens straight into that card's detail screen; everything else (content
  // bundles) keeps the previous default of the collection tab.
  Future<void> _onExplorePressed(BuildContext context) async {
    final item = widget.item;

    if (item.isSubscriptionPurchase) {
      _goToShell((shell) => shell.switchTab(MainShellTab.profil));
      return;
    }

    if (item.isDongengPurchase) {
      _goToShell(
        (shell) => shell.openBelajar(
          BelajarDestination.dongeng,
          highlightProductId: item.id,
        ),
      );
      return;
    }

    if (item.contentType == PurchasedContentType.arCard) {
      setState(() => _isOpeningCard = true);
      final card = await locator<ArRepository>()
          .findByProductId(item.id)
          .catchError((_) => null);
      if (!context.mounted) return;
      setState(() => _isOpeningCard = false);
      if (card != null) {
        _goToShell((shell) {
          shell.openBelajar(BelajarDestination.kartuAr);
          Navigator.push(
            shell.context,
            MaterialPageRoute(builder: (_) => ArCardDetailScreen(card: card)),
          );
        });
        return;
      }
    }

    _goToShell((shell) => shell.openBelajar(BelajarDestination.kartuAr));
  }

  void _goToShell(void Function(MainShellState shell) then) {
    context.go('/shell');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shell = MainShell.shellKey.currentState;
      if (shell != null) then(shell);
    });
  }

  // Turns the purchased item's own real subtitle into checklist lines,
  // instead of a generic hardcoded list unrelated to what was actually
  // bought. Package subtitles list their contents joined by "+" (e.g. "8
  // Hewan Hutan + 2 Dongeng"); single-product subtitles are already a
  // single descriptive line (e.g. "Akses ke dongeng Kancil dan Buaya").
  List<String> _unlockedItemLines() {
    final subtitle = widget.item.subtitle;
    if (subtitle.contains('+')) {
      return subtitle
          .split('+')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [subtitle];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Confetti
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            colors: const [
              AppColors.primaryOrange,
              AppColors.accentGold,
              AppColors.mutedBlue,
              AppColors.successGreen,
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Star icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🎉', style: TextStyle(fontSize: 52)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    AppStrings.unlockSuccessHeading,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.name,
                    style: AppTextStyles.subheading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.unlockSuccessSubtitle,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.mediumBrown,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Unlocked items checklist
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepBrown.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ..._unlockedItemLines().map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(item, style: AppTextStyles.bodyLarge),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.mediumBrown,
                              ),
                            ),
                            Text(
                              widget.item.priceLabel,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isOpeningCard
                          ? null
                          : () => _onExplorePressed(context),
                      child: _isOpeningCard
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              AppStrings.btnStartExplore,
                              style: AppTextStyles.button,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
