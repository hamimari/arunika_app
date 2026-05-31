import 'package:flutter/material.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';

@immutable
class AnimalData {
  final String id;
  final String name;
  final String emoji;
  final String category; // 'ternak' | 'hutan' | 'laut'
  final String funFact;
  final bool isUnlocked;
  final Color bgColor;
  final String imageUrl;

  const AnimalData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.funFact,
    this.isUnlocked = true,
    required this.bgColor,
    this.imageUrl = '',
  });
}

/// Static animal catalogue — replace with API / local DB in future phase.
const List<AnimalData> kAnimals = [
  AnimalData(
    id: 'rusa',
    name: 'Rusa',
    emoji: '🦌',
    category: 'hutan',
    funFact:
        'Rusa jantan memiliki tanduk yang tumbuh setiap tahun dan bisa mencapai panjang 1 meter!',
    bgColor: Color(0xFFE8F5E9),
  ),
  AnimalData(
    id: 'sapi',
    name: 'Sapi',
    emoji: '🐄',
    category: 'ternak',
    funFact: 'Sapi memiliki empat lambung dan bisa mengenali wajah manusia!',
    bgColor: Color(0xFFFFF3E4),
  ),
  AnimalData(
    id: 'ikan_pari',
    name: 'Ikan Pari',
    emoji: '🐡',
    category: 'laut',
    funFact:
        'Ikan pari bisa terbang sejauh 2 meter di atas permukaan air untuk menghindari predator.',
    isUnlocked: false,
    bgColor: Color(0xFFE3F2FD),
  ),
  AnimalData(
    id: 'harimau',
    name: 'Harimau',
    emoji: '🐯',
    category: 'hutan',
    funFact:
        'Harimau adalah kucing terbesar di dunia. Mereka bisa melompat sejauh 6 meter!',
    isUnlocked: false,
    bgColor: Color(0xFFFFF8E1),
  ),
  AnimalData(
    id: 'ayam',
    name: 'Ayam',
    emoji: '🐔',
    category: 'ternak',
    funFact:
        'Ayam adalah burung yang paling banyak di dunia — lebih dari 33 miliar ekor!',
    bgColor: Color(0xFFFCE4EC),
  ),
  AnimalData(
    id: 'lumba_lumba',
    name: 'Lumba-lumba',
    emoji: '🐬',
    category: 'laut',
    funFact:
        'Lumba-lumba tidur dengan satu mata terbuka untuk tetap waspada terhadap bahaya.',
    isUnlocked: false,
    bgColor: Color(0xFFE8EAF6),
  ),
  AnimalData(
    id: 'kuda',
    name: 'Kuda',
    emoji: '🐴',
    category: 'ternak',
    funFact:
        'Kuda bisa tidur sambil berdiri berkat sistem penguncian lututnya.',
    bgColor: Color(0xFFF3E5F5),
  ),
  AnimalData(
    id: 'gajah',
    name: 'Gajah',
    emoji: '🐘',
    category: 'hutan',
    funFact:
        'Gajah adalah satu-satunya hewan yang tidak bisa melompat, tapi bisa berenang jarak jauh!',
    bgColor: Color(0xFFE0F2F1),
  ),
];

class AnimalDetailScreen extends StatefulWidget {
  final AnimalData animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: animal.bgColor,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.deepBrown,
                  size: 18,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => _isFavorite = !_isFavorite),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : AppColors.deepBrown,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: animal.bgColor,
                child: Center(
                  child: animal.imageUrl.isNotEmpty
                      ? Image.network(
                          animal.imageUrl,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Text(
                            animal.emoji,
                            style: const TextStyle(fontSize: 120),
                          ),
                        )
                      : Text(
                          animal.emoji,
                          style: const TextStyle(fontSize: 120),
                        ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + category badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(animal.name, style: AppTextStyles.heading),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.creamCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          animal.category.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fun fact card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepBrown.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.funFactTitle,
                              style: AppTextStyles.subheading,
                            ),
                            const Spacer(),
                            Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.primaryOrange,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(animal.funFact, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Scan AR button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/ar-scan'),
                      icon: const Icon(Icons.qr_code_scanner, size: 22),
                      label: Text(
                        AppStrings.btnScanAR,
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sound + Share buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.volume_up_rounded,
                          label: AppStrings.btnSound,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_rounded,
                          label: AppStrings.btnShare,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
