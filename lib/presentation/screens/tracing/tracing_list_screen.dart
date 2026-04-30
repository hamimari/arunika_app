import 'package:arunika_app/core/subscription_service.dart';
import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_list_cubit.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_list_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/feature_scaffold.dart';
import 'package:arunika_app/presentation/screens/widgets/premium_dialog.dart';
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
  bool _userIsPremium = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.isPremium().then((v) {
      if (mounted) setState(() => _userIsPremium = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TracingListCubit(repository: locator<TracingRepository>())..load(),
      child: FeatureScaffold(
        title: 'Tracing',
        body: _TracingBody(
          selectedCategory: _selectedCategory,
          searchQuery: _searchQuery,
          userIsPremium: _userIsPremium,
          onCategoryChanged: (c) => setState(() => _selectedCategory = c),
          onSearchChanged: (q) => setState(() => _searchQuery = q),
          categoryLabels: _categoryLabels,
          categoryKeys: _categories,
          categoryIcons: _categoryIcons,
        ),
      ),
    );
  }
}

class _TracingBody extends StatelessWidget {
  final String selectedCategory;
  final String searchQuery;
  final bool userIsPremium;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final List<String> categoryLabels;
  final List<String> categoryKeys;
  final List<IconData> categoryIcons;

  const _TracingBody({
    required this.selectedCategory,
    required this.searchQuery,
    required this.userIsPremium,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.categoryLabels,
    required this.categoryKeys,
    required this.categoryIcons,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TracingListCubit, TracingListState>(
      builder: (context, state) {
        final allItems = state is TracingListLoaded
            ? state.items
            : <TracingItem>[];
        final isLoading = state is TracingListLoading;
        final errorMsg = state is TracingListError ? state.message : null;

        // Client-side filter
        final filtered = allItems.where((item) {
          final matchCat =
              selectedCategory == 'all' || item.type == selectedCategory;
          final matchSearch =
              searchQuery.isEmpty ||
              item.label.toLowerCase().contains(searchQuery.toLowerCase());
          return matchCat && matchSearch;
        }).toList();

        return Column(
          children: [
            // ── Search bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari huruf, angka, atau bentuk...',
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

            // ── Category row ─────────────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categoryKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedCategory == categoryKeys[i];
                  return GestureDetector(
                    onTap: () => onCategoryChanged(categoryKeys[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? Colors.orange : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcons[i],
                            size: 16,
                            color: active ? Colors.white : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            categoryLabels[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : Colors.grey.shade600,
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

            // ── Grid ──────────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : errorMsg != null
                  ? Center(
                      child: Text(
                        errorMsg,
                        style: const TextStyle(color: Color(0xFF6D4C41)),
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ada hasil',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        // difficulty > 1 is premium content
                        final locked = item.difficulty > 1 && !userIsPremium;
                        return _ItemCard(item: item, locked: locked);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final TracingItem item;
  final bool locked;
  const _ItemCard({required this.item, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final labelColor = locked ? Colors.orange : Colors.green;

    return GestureDetector(
      onTap: locked
          ? () => PremiumDialog.show(context)
          : () => context.push('/tracing/exercise', extra: item),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: locked
                ? [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)]
                : [const Color(0xFFFFF4E6), const Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.12),
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
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: locked
                      ? Colors.grey.shade400
                      : const Color(0xFF6D4C41),
                ),
              ),
            ),
            // PAID / FREE badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  locked ? 'PAID' : 'FREE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
                ),
              ),
            ),
            // Lock icon overlay
            if (locked)
              Positioned(
                bottom: 6,
                right: 6,
                child: Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
