import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_list_bloc.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TracingListScreen extends StatefulWidget {
  const TracingListScreen({super.key});

  @override
  State<TracingListScreen> createState() => _TracingListScreenState();
}

class _TracingListScreenState extends State<TracingListScreen> {
  static const _categories = ['all', 'alphabet', 'number', 'shape'];
  static const _categoryLabels = ['Semua', 'Alfabet', 'Angka', 'Bentuk'];
  static const _categoryIcons = [
    Icons.apps_rounded,
    Icons.abc_rounded,
    Icons.tag_rounded,
    Icons.category_rounded,
  ];

  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    LocalProfileStorage.get().then((p) {
      if (mounted) setState(() => _isSubscribed = p?.isSubscribed ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TracingListCubit(repository: locator<TracingRepository>())..load(),
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
                // ── Header ──────────────────────────────────────────────
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
                          Text('Tracing', style: AppTextStyles.heading),
                          Text(
                            'Latihan menulis huruf, angka, & bentuk',
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

                // ── Search bar ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (q) => setState(() => _searchQuery = q),
                    decoration: InputDecoration(
                      hintText: 'Cari huruf, angka, atau bentuk...',
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

                // ── Category chips ───────────────────────────────────────
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final active = _selectedCategory == _categories[i];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = _categories[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primaryOrange
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: active
                                    ? AppColors.primaryOrange.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryIcons[i],
                                size: 16,
                                color: active
                                    ? Colors.white
                                    : AppColors.textMedium,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _categoryLabels[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ── Grid ─────────────────────────────────────────────────
                Expanded(
                  child: BlocBuilder<TracingListCubit, TracingListState>(
                    builder: (context, state) {
                      if (state is TracingListLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryOrange,
                          ),
                        );
                      }

                      if (state is TracingListError) {
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
                                    context.read<TracingListCubit>().load(),
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

                      final allItems = state is TracingListLoaded
                          ? state.items
                          : <TracingItem>[];

                      final filtered = allItems.where((item) {
                        final matchCat =
                            _selectedCategory == 'all' ||
                            item.type == _selectedCategory;
                        final matchSearch =
                            _searchQuery.isEmpty ||
                            item.label.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            );
                        return matchCat && matchSearch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada hasil',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.primaryOrange,
                        onRefresh: () async =>
                            context.read<TracingListCubit>().load(),
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final item = filtered[i];
                            final locked =
                                item.difficulty > 1 && !_isSubscribed;
                            return _ItemCard(
                              item: item,
                              locked: locked,
                              onTap: locked
                                  ? () => context.push('/premium')
                                  : () => context.push(
                                      '/tracing/exercise',
                                      extra: item,
                                    ),
                            );
                          },
                        ),
                      );
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

// ── Item card ──────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final TracingItem item;
  final bool locked;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: locked
                ? [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)]
                : [const Color(0xFFFFF4E6), const Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: locked ? AppColors.textLight : AppColors.deepBrown,
                ),
              ),
            ),
            // PREMIUM / GRATIS badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: locked
                      ? AppColors.primaryOrange.withValues(alpha: 0.12)
                      : const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  locked ? 'PREMIUM' : 'GRATIS',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: locked
                        ? AppColors.primaryOrange
                        : const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ),
            if (locked)
              Positioned(
                bottom: 6,
                right: 6,
                child: Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: AppColors.textMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
