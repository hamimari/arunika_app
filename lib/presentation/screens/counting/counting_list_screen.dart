import 'package:arunika_app/core/subscription_service.dart';
import 'package:arunika_app/data/models/response/counting_question.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/counting/counting_list_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/feature_scaffold.dart';
import 'package:arunika_app/presentation/screens/widgets/premium_dialog.dart';
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
  bool _userIsPremium = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.isPremium().then((v) {
      if (mounted) setState(() => _userIsPremium = v);
    });
  }

  bool _isPremiumLevel(String level) =>
      !_userIsPremium && _premiumLevels.contains(level.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CountingListCubit(repository: locator<CountingRepository>())..load(),
      child: FeatureScaffold(
        title: 'Angka',
        body: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (q) => setState(() => _searchQuery = q),
                decoration: InputDecoration(
                  hintText: 'Cari soal...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<CountingListCubit, CountingListState>(
                builder: (context, state) {
                  if (state is CountingListLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    );
                  }
                  if (state is CountingListError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Color(0xFF6D4C41)),
                      ),
                    );
                  }
                  if (state is CountingListLoaded) {
                    final filtered = _searchQuery.isEmpty
                        ? state.questions
                        : state.questions
                              .where(
                                (q) => q.answer
                                    .toString()
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()),
                              )
                              .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada soal ditemukan.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final q = filtered[i];
                        final isPremium = _isPremiumLevel(q.level);
                        return _QuestionCard(
                          index: i,
                          question: q,
                          isPremium: isPremium,
                          onTap: isPremium
                              ? () => PremiumDialog.show(context)
                              : () => context.push(
                                  '/counting/exercise',
                                  extra: filtered,
                                ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
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
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessColor = isPremium ? Colors.orange : Colors.green;
    final levelColor = _levelColor(question.level);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.07),
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
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title + level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soal ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF6D4C41),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Level chip
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
            // FREE / PAID label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accessColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPremium ? 'PAID' : 'FREE',
                style: TextStyle(
                  color: accessColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isPremium ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isPremium ? Colors.orange : const Color(0xFF8D6E63),
            ),
          ],
        ),
      ),
    );
  }
}
