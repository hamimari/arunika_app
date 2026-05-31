import 'package:flutter/material.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';

class NewLandingScreen extends StatelessWidget {
  const NewLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          // Soft gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF5EC), AppColors.pageBackground],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Decorative blobs
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.premiumPurple.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Logo / brand row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        // decoration: BoxDecoration(
                        //   color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        //   borderRadius: BorderRadius.circular(12),
                        // ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // const Text('🌿', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              'arunika',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Hero illustration card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDE8D8), Color(0xFFFFF3EC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8C4A8).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Floating emoji animals
                        // Positioned(
                        //   top: 0,
                        //   right: 0,
                        //   child: const Text(
                        //     '🦋',
                        //     style: TextStyle(fontSize: 24),
                        //   ),
                        // ),
                        // Positioned(
                        //   bottom: 0,
                        //   left: 8,
                        //   child: const Text(
                        //     '🌿',
                        //     style: TextStyle(fontSize: 20),
                        //   ),
                        // ),
                        Column(
                          children: [
                            Image.network(
                              'https://raw.githubusercontent.com/hamimari/arunika_assets/main/landing_transparent.png', // candy placeholder
                              height: 250,
                            ),
                            // const Text('🦌', style: TextStyle(fontSize: 100)),
                            // const SizedBox(height: 8),
                            // // Feature badges row
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     _FeatureBadge(emoji: '📷', label: 'AR 3D'),
                            //     const SizedBox(width: 8),
                            //     _FeatureBadge(emoji: '📖', label: 'Dongeng'),
                            //     const SizedBox(width: 8),
                            //     _FeatureBadge(emoji: '🦎', label: '100+ Hewan'),
                            //   ],
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Heading
                  Text(
                    AppStrings.welcomeHeading,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.welcomeSubtitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textMedium,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Let's Explore button → signup
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          AppStrings.btnExplore,
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sign in button
                  GestureDetector(
                    onTap: () => context.go('/signin'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Sudah punya akun? Masuk',
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Demo hint
                  TextButton(
                    onPressed: () => context.go('/shell'),
                    child: Text(
                      AppStrings.btnTryDemo,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMedium,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
