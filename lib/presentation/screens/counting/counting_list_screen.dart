import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/counting_question.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/counting/counting_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CountingListScreen extends StatefulWidget {
  const CountingListScreen({super.key});

  @override
  State<CountingListScreen> createState() => _CountingListScreenState();
}

class _CountingListScreenState extends State<CountingListScreen> {
  static const _premiumLevels = {'medium', 'hard'};
  String _searchQuery = '';
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    LocalProfileStorage.get().then((p) {
      if (mounted) setState(() => _isSubscribed = p?.isSubscribed ?? false);
    });
  }

  bool _isPremiumLevel(String level) =>
      !_isSubscribed && _premiumLevels.contains(level.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CountingListCubit(repository: locator<CountingRepository>())..load(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFEDD5),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFEDD5), AppColors.pageBackground],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Menghitung', style: AppTextStyles.heading),
                          Text(
                            'Latihan mengenal angka & berhitung',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Search bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (q) => setState(() => _searchQuery = q),
                    decoration: InputDecoration(
                      hintText: 'Cari soal...',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textMedium,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: AppTextStyles.body,
                  ),
                ),

                const SizedBox(height: 12),

                // ── List ──────────────────────────────────────────────────
                Expanded(
                  child: BlocBuilder<CountingListCubit, CountingListState>(
                    builder: (context, state) {
                      if (state is CountingListLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryOrange,
                          ),
                        );
                      }
                      if (state is CountingListError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.primaryOrange,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.message,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.mediumBrown,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    context.read<CountingListCubit>().load(),
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
                        );
                      }
                      if (state is CountingListLoaded) {
                        final filtered = _searchQuery.isEmpty
                            ? state.questions
                            : state.questions
                                  .where(
                                    (q) => q.answer.toString().contains(
                                      _searchQuery,
                                    ),
                                  )
                                  .toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'Tidak ada soal ditemukan.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textMedium,
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: AppColors.primaryOrange,
                          onRefresh: () async =>
                              context.read<CountingListCubit>().load(),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final q = filtered[i];
                              final isPremium = _isPremiumLevel(q.level);
                              return _QuestionCard(
                                index: i,
                                question: q,
                                isPremium: isPremium,
                                onTap: isPremium
                                    ? () => context.push('/premium')
                                    : () => context.push(
                                        '/counting/exercise',
                                        extra: filtered,
                                      ),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Question card ──────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final int index;
  final CountingQuestion question;
  final bool isPremium;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.isPremium,
    required this.onTap,
  });

  String _levelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        return level;
    }
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return AppColors.primaryOrange;
      case 'hard':
        return const Color(0xFFE53935);
      default:
        return AppColors.textMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(question.level);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.mutedBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title + level badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soal ${index + 1}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _levelLabel(question.level),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: levelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // FREE / PAID chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPremium
                    ? AppColors.primaryOrange.withValues(alpha: 0.12)
                    : const Color(0xFF4CAF50).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPremium ? 'PREMIUM' : 'GRATIS',
                style: TextStyle(
                  color: isPremium
                      ? AppColors.primaryOrange
                      : const Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isPremium ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isPremium ? AppColors.primaryOrange : AppColors.textMedium,
            ),
          ],
        ),
      ),
    );
  }
}
