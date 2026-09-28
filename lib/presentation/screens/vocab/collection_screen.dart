import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/models/response/ar_card_category.dart';
import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/core/utils/auth_guard.dart';
import 'package:arunika_app/presentation/screens/vocab/ar_card_detail_screen.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/category_dropdowns.dart';
import 'package:arunika_app/presentation/screens/widgets/error_retry_view.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:arunika_app/presentation/screens/widgets/ownership_filter_sheet.dart';
import 'package:arunika_app/presentation/screens/widgets/price_tag.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_bloc_handler.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/core/media/media_cache.dart';

CategoryOption _fromArCardCategory(ArCardCategory c) => CategoryOption(
  id: c.id,
  name: c.name,
  imageUrl: c.imageUrl,
  children: c.children.map(_fromArCardCategory).toList(),
);

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
          child: BlocBuilder<CollectionBlocHandler, CollectionState>(
            buildWhen: (prev, curr) =>
                prev is CollectionError || curr is CollectionError,
            builder: (context, state) {
              // Like the dongeng list: on a load failure the whole page is
              // the error view — no header, search or filters.
              if (state is CollectionError) {
                return ErrorRetryView(
                  message: state.message,
                  onRetry: () =>
                      context.read<CollectionBlocHandler>().add(LoadArCards()),
                );
              }
              return _buildContent(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
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

        // Category dropdown(s) + gear icon opening the ownership
        // ("Kepemilikan") filter sheet — replaces the old "Sudah
        // dibeli saja" chip.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: BlocBuilder<CollectionBlocHandler, CollectionState>(
            builder: (context, state) {
              if (state is! CollectionLoaded) {
                return const SizedBox.shrink();
              }
              return Row(
                children: [
                  Expanded(
                    child: CategoryDropdowns(
                      categories: state.categories
                          .map(_fromArCardCategory)
                          .toList(),
                      activeCategoryId: state.activeCategoryId,
                      activeSubCategoryId: state.activeSubCategoryId,
                      onCategoryChanged: (id) => context
                          .read<CollectionBlocHandler>()
                          .add(FilterByCategory(id)),
                      onSubCategoryChanged: (id) => context
                          .read<CollectionBlocHandler>()
                          .add(FilterBySubCategory(id)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterIconButton(
                    onTap: () => showOwnershipFilterSheet(
                      context,
                      currentOwnedOnly: state.ownedOnly,
                      onApply: (v) => context.read<CollectionBlocHandler>().add(
                        ToggleOwnedOnly(v),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
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
          goToProductPurchase(
            context,
            productId: card.productId,
            title: card.title ?? 'Kartu AR',
            priceIdr: card.priceIdr,
            contentType: PurchasedContentType.arCard,
            subtitle: 'Akses ke kartu AR ${card.title ?? ''}'.trim(),
            strikePriceIdr: card.strikePriceIdr,
            discountPercent: card.discountPercent,
            promoEndsAt: card.promoEndsAt,
          );
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
                            ? Image(
                                image: MediaCache.image(card.imageUrl),
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

              // Price (with promo strike price) on locked, purchasable cards
              if (!card.isUnlocked && card.priceIdr != null)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: PriceTag(
                        price: card.priceIdr!,
                        strikePrice: card.strikePriceIdr,
                        compact: true,
                      ),
                    ),
                  ),
                ),

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

// Category dropdown row + gear icon now live in
// lib/presentation/screens/widgets/category_dropdowns.dart, shared with the
// dongeng screen.
