import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/ar_card_category.dart';
import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/core/utils/auth_guard.dart';
import 'package:arunika_app/presentation/screens/vocab/ar_card_detail_screen.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_bloc_handler.dart';
import 'package:arunika_app/constants/app_strings.dart';

class CollectionScreen extends StatelessWidget {
  final String? initialCategoryId;
  const CollectionScreen({super.key, this.initialCategoryId});

  /// Set this from outside to filter the collection tab by category and then
  /// call [MainShell.shellKey.currentState?.switchTab(MainShellTab.collection)].
  /// The value is consumed once and reset to null automatically.
  static final ValueNotifier<String?> externalCategoryFilter = ValueNotifier(
    null,
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CollectionBlocHandler(repository: locator<ArRepository>())
            ..add(LoadArCards(initialCategoryId: initialCategoryId)),
      child: const _CollectionView(),
    );
  }
}

class _CollectionView extends StatefulWidget {
  const _CollectionView();

  @override
  State<_CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<_CollectionView> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    CollectionScreen.externalCategoryFilter.addListener(_onExternalFilter);
  }

  void _onExternalFilter() {
    final catId = CollectionScreen.externalCategoryFilter.value;
    if (catId != null && mounted) {
      context.read<CollectionBlocHandler>().add(FilterByCategory(catId));
      CollectionScreen.externalCategoryFilter.value = null;
    }
  }

  @override
  void dispose() {
    CollectionScreen.externalCategoryFilter.removeListener(_onExternalFilter);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDD5),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFEDD5), AppColors.pageBackground],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSearching ? _buildSearchBar() : _buildTitle(),
                ),
              ),

              // Category dropdowns
              BlocBuilder<CollectionBlocHandler, CollectionState>(
                builder: (context, state) {
                  if (state is! CollectionLoaded) {
                    return const SizedBox.shrink();
                  }
                  ArCardCategory? activeCat;
                  try {
                    activeCat = state.activeCategoryId != null
                        ? state.categories.firstWhere(
                            (c) => c.id == state.activeCategoryId,
                          )
                        : null;
                  } catch (_) {}
                  return _CategoryDropdowns(
                    categories: state.categories,
                    activeCategoryId: state.activeCategoryId,
                    activeSubCategoryId: state.activeSubCategoryId,
                    activeCat: activeCat,
                    onCategoryChanged: (id) => context
                        .read<CollectionBlocHandler>()
                        .add(FilterByCategory(id)),
                    onSubCategoryChanged: (id) => context
                        .read<CollectionBlocHandler>()
                        .add(FilterBySubCategory(id)),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Grid / Loading / Error
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryOrange,
                  onRefresh: () async {
                    context.read<CollectionBlocHandler>().add(LoadArCards());
                  },
                  child: BlocBuilder<CollectionBlocHandler, CollectionState>(
                    builder: (context, state) {
                      if (state is CollectionLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryOrange,
                          ),
                        );
                      }
                      if (state is CollectionError) {
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
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.mediumBrown,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<CollectionBlocHandler>()
                                    .add(LoadArCards()),
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
                      if (state is CollectionLoaded) {
                        final cards = state.displayed;
                        if (cards.isEmpty) {
                          return Center(
                            child: Text(
                              'Tidak ada kartu yang ditemukan.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.mediumBrown,
                              ),
                            ),
                          );
                        }
                        return GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: cards.length,
                          itemBuilder: (_, i) => _ArCardItem(card: cards[i]),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      key: const ValueKey('title'),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.collectionTitle, style: AppTextStyles.heading),
              Text(
                'Temukan semua kartu AR favoritmu!',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isSearching = true),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.primaryOrange,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      key: const ValueKey('search'),
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Cari kartu...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryOrange,
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) {
              context.read<CollectionBlocHandler>().add(SearchArCards(v));
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() => _isSearching = false);
            _searchController.clear();
            context.read<CollectionBlocHandler>().add(SearchArCards(''));
          },
          child: const Text(
            'Batal',
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── AR Card Item ──────────────────────────────────────────────────────────────

class _ArCardItem extends StatelessWidget {
  final ArCardResponse card;
  const _ArCardItem({required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final isLoggedIn = locator<AuthNotifier>().isLoggedIn;
        if (card.isUnlocked) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArCardDetailScreen(card: card)),
          );
        } else if (!isLoggedIn) {
          showLoginRequiredDialog(context, featureLabel: 'koleksi kartu AR');
        } else {
          guardPremium(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _parseBgColor(card.bgColor),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Colored background with image
              Column(
                children: [
                  Expanded(
                    child: ColorFiltered(
                      colorFilter: card.isUnlocked
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                          : const ColorFilter.matrix([
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ]),
                      child: Container(
                        color: _parseBgColor(card.bgColor),
                        child: card.imageUrl.isNotEmpty
                            ? Image.network(
                                card.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    card.emoji.isNotEmpty ? card.emoji : '🃏',
                                    style: const TextStyle(fontSize: 56),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  card.emoji.isNotEmpty ? card.emoji : '🃏',
                                  style: const TextStyle(fontSize: 56),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Name strip at bottom
                  Container(
                    width: double.infinity,
                    color: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Text(
                      card.title ?? '',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Full gray overlay for locked cards
              if (!card.isUnlocked)
                Container(color: Colors.black.withValues(alpha: 0.40)),

              // Lock / unlock badge
              Positioned(
                top: 8,
                right: 8,
                child: card.isUnlocked
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 14,
                        ),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: AppColors.white,
                          size: 18,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseBgColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFFFFF3E0);
    }
  }
}

// ── Category Dropdowns ────────────────────────────────────────────────────────

class _CategoryDropdowns extends StatelessWidget {
  final List<ArCardCategory> categories;
  final String? activeCategoryId;
  final String? activeSubCategoryId;
  final ArCardCategory? activeCat;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubCategoryChanged;

  const _CategoryDropdowns({
    required this.categories,
    required this.activeCategoryId,
    required this.activeSubCategoryId,
    required this.activeCat,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubs = activeCat != null && activeCat!.children.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StyledDropdown<String?>(
              value: activeCategoryId,
              hint: 'Semua Kategori',
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua')),
                ...categories.map(
                  (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text('${cat.emoji} ${cat.name}'.trim()),
                  ),
                ),
              ],
              onChanged: onCategoryChanged,
            ),
          ),
          if (hasSubs) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _StyledDropdown<String?>(
                value: activeSubCategoryId,
                hint: 'Semua Sub',
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua')),
                  ...activeCat!.children.map(
                    (sub) => DropdownMenuItem(
                      value: sub.id,
                      child: Text('${sub.emoji} ${sub.name}'.trim()),
                    ),
                  ),
                ],
                onChanged: onSubCategoryChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lockGrey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryOrange,
            size: 20,
          ),
          style: AppTextStyles.caption.copyWith(color: AppColors.textDark),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
