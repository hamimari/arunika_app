import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/core/feature_flags/feature_flags_notifier.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/presentation/screens/cart/cart_widgets.dart';
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
import 'package:arunika_app/presentation/screens/widgets/header_icon_button.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:arunika_app/presentation/screens/widgets/ownership_filter_sheet.dart';
import 'package:arunika_app/presentation/screens/widgets/price_tag.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_bloc_handler.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/core/media/media_cache.dart';
import 'package:go_router/go_router.dart';

CategoryOption _fromArCardCategory(ArCardCategory c) => CategoryOption(
  id: c.id,
  name: c.name,
  imageUrl: c.imageUrl,
  children: c.children.map(_fromArCardCategory).toList(),
);

class CollectionScreen extends StatelessWidget {
  final String? initialCategoryId;
  const CollectionScreen({super.key, this.initialCategoryId});

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
  final _cart = locator<CartNotifier>();

  @override
  void initState() {
    super.initState();
    // A paid cart order unlocks cards; reload so they show as owned.
    _cart.grants.addListener(_reload);
  }

  void _reload() => context.read<CollectionBlocHandler>().add(LoadArCards());

  @override
  void dispose() {
    _cart.grants.removeListener(_reload);
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
                  return ListenableBuilder(
                    listenable: _cart,
                    builder: (context, _) => GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        // Room for "Di keranjang · Lihat" under the buttons.
                        mainAxisExtent: _cart.enabled ? 296 : 276,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (_, i) => _ArCardItem(card: cards[i]),
                    ),
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
        // Opened from the Belajar hub (or the /koleksi route): back returns.
        if (Navigator.of(context).canPop()) ...[
          HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            semanticLabel: 'Kembali',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
        ],
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
        // QR scan moved here from the bottom navigation.
        ListenableBuilder(
          listenable: locator<FeatureFlagsNotifier>(),
          builder: (context, _) =>
              locator<FeatureFlagsNotifier>().qrScanEnabled
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: HeaderIconButton(
                    icon: Icons.qr_code_scanner_rounded,
                    semanticLabel: 'Scan kartu AR',
                    onTap: () => context.push('/ar-scan'),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        HeaderIconButton(
          icon: Icons.search_rounded,
          semanticLabel: 'Cari kartu',
          onTap: () => setState(() => _isSearching = true),
        ),
        const CartHeaderButton(),
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

// Locked cards are shown in greyscale; owned cards keep their colours.
const _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// One card in the collection grid: the picture on top, then title, and an
/// action — "Beli" with the price for a locked card, "Buka AR" for one the
/// user owns.
class _ArCardItem extends StatelessWidget {
  final ArCardResponse card;
  const _ArCardItem({required this.card});

  void _onTap(BuildContext context) {
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
        playProductId: card.playProductId,
        strikePriceIdr: card.strikePriceIdr,
        discountPercent: card.discountPercent,
        promoEndsAt: card.promoEndsAt,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = !card.isUnlocked;
    // Free cards come back unlocked with no product; only a card that has a
    // product and is unlocked was bought. Free is "Gratis", bought is
    // "Dimiliki"; both show as a chip under the title, not over the picture.
    final owned = !locked && card.productId != null;
    final onPromo =
        locked && card.strikePriceIdr != null && card.discountPercent != null;
    // Paid, sold singly and not owned: it can also go in the cart.
    final cartItem = locked && card.productId != null && card.priceIdr != null
        ? CartItem(
            productId: card.productId!,
            type: CartItemType.arCard,
            contentId: card.id ?? '',
            title: card.title ?? 'Kartu AR',
            imageUrl: card.imageUrl,
            priceIdr: card.priceIdr!,
            strikePriceIdr: card.strikePriceIdr,
          )
        : null;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Picture; the space left over after the body below.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: locked
                        ? _greyscale
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child: Container(
                      color: _parseBgColor(card.bgColor),
                      child: _picture(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: onPromo
                        ? _Pill(
                            label: '-${card.discountPercent}%',
                            color: AppColors.discountRed,
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (locked)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Body: title + price/ownership + action.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.title ?? '',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (locked && card.priceIdr != null) ...[
                    const SizedBox(height: 4),
                    PriceTag(
                      price: card.priceIdr!,
                      strikePrice: card.strikePriceIdr,
                      showDiscount: false,
                      priceColor: AppColors.ctaRust,
                    ),
                  ] else if (!locked) ...[
                    const SizedBox(height: 6),
                    owned
                        ? const _StatusChip(
                            label: AppStrings.badgeOwned,
                            icon: Icons.check_rounded,
                            background: AppColors.ownedGreySoft,
                            foreground: AppColors.deepBrown,
                          )
                        : const _StatusChip(
                            label: AppStrings.freeCaption,
                            icon: Icons.card_giftcard_rounded,
                            background: AppColors.freeGreenSoft,
                            foreground: AppColors.ownedGreen,
                          ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: locked
                              ? ElevatedButton.icon(
                                  onPressed: () => _onTap(context),
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 18,
                                  ),
                                  label: const Text(AppStrings.btnBuy),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.ctaRust,
                                    foregroundColor: AppColors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    textStyle: AppTextStyles.buttonSmall,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () => _onTap(context),
                                  icon: const Icon(
                                    Icons.view_in_ar_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(AppStrings.btnOpenAr),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.ctaRustSoft,
                                    foregroundColor: AppColors.ctaRust,
                                    side: const BorderSide(
                                      color: AppColors.ctaRust,
                                    ),
                                    padding: EdgeInsets.zero,
                                    textStyle: AppTextStyles.buttonSmall,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (cartItem != null) ...[
                        const SizedBox(width: 8),
                        CartToggleButton(item: cartItem),
                      ],
                    ],
                  ),
                  if (cartItem != null)
                    InCartLink(productId: cartItem.productId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _picture() {
    Widget emoji() => Center(
      child: Text(
        card.emoji.isNotEmpty ? card.emoji : '🃏',
        style: const TextStyle(fontSize: 56),
      ),
    );
    if (card.imageUrl.isEmpty) return emoji();
    return Image(
      image: MediaCache.image(card.imageUrl),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => emoji(),
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

/// A small rounded label over a card picture ("-50%", "Dimiliki").
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Gratis" / "Dimiliki" chip under an unlocked card's title.
class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// Category dropdown row + gear icon now live in
// lib/presentation/screens/widgets/category_dropdowns.dart, shared with the
// dongeng screen.
