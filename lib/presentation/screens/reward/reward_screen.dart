import 'package:flutter/material.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';

class RewardScreen extends StatelessWidget {
  final String animalName;
  final int stars;

  const RewardScreen({super.key, required this.animalName, this.stars = 10});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Star burst icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [AppColors.accentGold, AppColors.primaryOrange],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⭐', style: TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                '+$stars ⭐',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.primaryOrange,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                animalName,
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.rewardSubtitle,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.mediumBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/shell'),
                  child: Text(
                    AppStrings.btnViewCollection,
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
