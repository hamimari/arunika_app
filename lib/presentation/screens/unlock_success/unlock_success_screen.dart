import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:go_router/go_router.dart';

class UnlockSuccessScreen extends StatefulWidget {
  final String packName;

  const UnlockSuccessScreen({super.key, required this.packName});

  @override
  State<UnlockSuccessScreen> createState() => _UnlockSuccessScreenState();
}

class _UnlockSuccessScreenState extends State<UnlockSuccessScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
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
                    widget.packName,
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
                      children: AppStrings.unlockItems.map((item) {
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
                              Text(item, style: AppTextStyles.bodyLarge),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to shell and switch to collection tab
                        context.go('/shell');
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          MainShell.shellKey.currentState?.switchTab(
                            MainShellTab.collection,
                          );
                        });
                      },
                      child: Text(
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
