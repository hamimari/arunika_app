import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/presentation/screens/widgets/header_icon_button.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/utils/auth_guard.dart';
import 'package:arunika_app/core/utils/price_format.dart';
import 'package:arunika_app/data/models/purchasable_item.dart';
import 'package:arunika_app/data/models/response/dongeng_category.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:arunika_app/presentation/screens/widgets/category_dropdowns.dart';
import 'package:arunika_app/presentation/screens/widgets/error_retry_view.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:arunika_app/presentation/screens/widgets/ownership_filter_sheet.dart';
import 'package:arunika_app/presentation/screens/widgets/price_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:arunika_app/core/media/media_cache.dart';
import 'package:arunika_app/core/cart/cart_notifier.dart';
import 'package:arunika_app/data/models/cart.dart';
import 'package:arunika_app/presentation/screens/cart/cart_widgets.dart';

CategoryOption _fromDongengCategory(DongengCategory c) => CategoryOption(
  id: c.id,
  name: c.name,
  imageUrl: c.imageUrl,
  children: c.children.map(_fromDongengCategory).toList(),
);

class NewDongengListScreen extends StatefulWidget {
  const NewDongengListScreen({super.key});

  @override
  State<NewDongengListScreen> createState() => _NewDongengListScreenState();
}

class _NewDongengListScreenState extends State<NewDongengListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _cart = locator<CartNotifier>();

  @override
  void initState() {
    super.initState();
    // A paid cart order unlocks stories; reload so they show as owned.
    _cart.grants.addListener(_reload);
  }

  void _reload() => context.read<DongengListBloc>().add(LoadDongengList());

  @override
  void dispose() {
    _cart.grants.removeListener(_reload);
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() {
    setState(() => _isSearching = false);
    _searchController.clear();
    context.read<DongengListBloc>().add(SearchDongeng(''));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DongengListBloc, DongengListState>(
      buildWhen: (_, curr) => curr is! NavigateToDongengPlayer,
      listenWhen: (_, curr) => curr is NavigateToDongengPlayer,
      listener: (context, state) {
        if (state is NavigateToDongengPlayer) {
          context.push('/dongeng-player', extra: state.dongeng);
          context.read<DongengListBloc>().add(ResetDongengListNavigation());
        }
      },
      builder: (context, state) {
        final isNavigating = state is DongengListNavigating;

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
            child: Stack(
              children: [
                SafeArea(child: _buildBody(context, state)),
                if (isNavigating)
                  IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) =>
                context.read<DongengListBloc>().add(SearchDongeng(v)),
            decoration: InputDecoration(
              hintText: 'Cari dongeng...',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textMedium,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryOrange,
              ),
            ),
            style: AppTextStyles.body,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _stopSearch,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textDark,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Opened from the Belajar hub: back returns to it.
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
              Text(AppStrings.dongengTitle, style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'Nikmati cerita seru yang penuh petualangan!',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _startSearch,
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
              Icons.search_rounded,
              color: AppColors.primaryOrange,
              size: 22,
            ),
          ),
        ),
        const CartHeaderButton(),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DongengListState state) {
    if (state is DongengListLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (state is DongengListError) {
      return ErrorRetryView(
        message: state.message,
        onRetry: () => context.read<DongengListBloc>().add(LoadDongengList()),
      );
    }

    final List<DongengResponse> list;
    if (state is DongengListLoaded) {
      list = state.dongengList;
    } else if (state is DongengListNavigating) {
      list = state.dongengList;
    } else {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with animated search toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSearching ? _buildSearchBar() : _buildTitle(),
          ),
        ),

        // Category filter dropdown(s) + gear icon opening the ownership
        // ("Kepemilikan") filter sheet — replaces the old "Sudah dibeli
        // saja" chip.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: CategoryDropdowns(
                  categories: state is DongengListLoaded
                      ? state.categories.map(_fromDongengCategory).toList()
                      : const [],
                  activeCategoryId: state is DongengListLoaded
                      ? state.activeCategoryId
                      : null,
                  activeSubCategoryId: state is DongengListLoaded
                      ? state.activeSubCategoryId
                      : null,
                  onCategoryChanged: (id) => context
                      .read<DongengListBloc>()
                      .add(FilterByDongengCategory(id)),
                  onSubCategoryChanged: (id) => context
                      .read<DongengListBloc>()
                      .add(FilterByDongengSubCategory(id)),
                ),
              ),
              const SizedBox(width: 8),
              FilterIconButton(
                onTap: () => showOwnershipFilterSheet(
                  context,
                  currentOwnedOnly:
                      state is DongengListLoaded && state.ownedOnly,
                  onApply: (v) =>
                      context.read<DongengListBloc>().add(FilterOwnedOnly(v)),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => RefreshIndicator(
                    color: AppColors.primaryOrange,
                    onRefresh: () async =>
                        context.read<DongengListBloc>().add(LoadDongengList()),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: Text(
                            _isSearching
                                ? 'Tidak ada dongeng yang cocok.'
                                : 'Belum ada dongeng tersedia.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.lockGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : _buildList(context, state, list),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    DongengListState state,
    List<DongengResponse> list,
  ) {
    // In search mode, show a flat list. Normal mode: featured + list.
    if (_isSearching) {
      return RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () async =>
            context.read<DongengListBloc>().add(LoadDongengList()),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final story = list[i];
            final isSelected =
                state is DongengListNavigating && state.selectedId == story.id;
            return _StoryRow(
              dongeng: story,
              isLoading: isSelected,
              onTap: () => _onTap(context, story),
            );
          },
        ),
      );
    }

    // Normal mode: featured card + popular list
    final featured = list.first;
    final rest = list.length > 1 ? list.sublist(1) : <DongengResponse>[];

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: () async =>
          context.read<DongengListBloc>().add(LoadDongengList()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeaturedCard(
                dongeng: featured,
                isLoading:
                    state is DongengListNavigating &&
                    state.selectedId == featured.id,
                onTap: () => _onTap(context, featured),
              ),
            ),

            const SizedBox(height: 24),

            // Popular section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.dongengPopular,
                      style: AppTextStyles.subheading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      AppStrings.dongengSeeAll,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.ctaRust,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Story list rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: rest.length,
              itemBuilder: (_, i) {
                final story = rest[i];
                final isSelected =
                    state is DongengListNavigating &&
                    state.selectedId == story.id;
                return _StoryRow(
                  dongeng: story,
                  isLoading: isSelected,
                  onTap: () => _onTap(context, story),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, DongengResponse story) {
    if (story.isUnlocked) {
      context.read<DongengListBloc>().add(DongengItemSelected(story));
    } else if (!locator<AuthNotifier>().isLoggedIn) {
      showLoginRequiredDialog(context, featureLabel: 'dongeng premium');
    } else {
      goToProductPurchase(
        context,
        productId: story.productId,
        title: story.title,
        priceIdr: story.priceIdr,
        contentType: PurchasedContentType.dongeng,
        subtitle: 'Akses ke dongeng ${story.title}',
        playProductId: story.playProductId,
        strikePriceIdr: story.strikePriceIdr,
        discountPercent: story.discountPercent,
        promoEndsAt: story.promoEndsAt,
      );
    }
  }
}

// ── Shared bits ────────────────────────────────────────────────────────────────

/// A locked, paid story as a cart item.
CartItem cartItemOf(DongengResponse d) => CartItem(
  productId: d.productId!,
  type: CartItemType.dongeng,
  contentId: d.id,
  title: d.title,
  imageUrl: d.imageUrl,
  priceIdr: d.priceIdr!,
  strikePriceIdr: d.strikePriceIdr,
);

String _meta(DongengResponse d) =>
    '${d.ageStart.toInt()}–${d.ageEnd.toInt()} tahun · ${d.duration}';

/// "Beli" (solid) for a locked story, "Baca" (outlined) for one the user can
/// open. Shows a spinner while the story is being opened.
class _StoryAction extends StatelessWidget {
  final bool locked;
  final bool isLoading;
  final VoidCallback onPressed;

  const _StoryAction({
    required this.locked,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: locked ? AppColors.white : AppColors.ctaRust,
            ),
          )
        : null;
    return SizedBox(
      height: 42,
      child: locked
          ? ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: child ?? const Icon(Icons.shopping_cart_outlined, size: 18),
              label: isLoading
                  ? const SizedBox.shrink()
                  : const Text(AppStrings.btnBuy),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctaRust,
                foregroundColor: AppColors.white,
                elevation: 0,
                minimumSize: const Size(96, 42),
                textStyle: AppTextStyles.buttonSmall,
                shape: shape,
              ),
            )
          : OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: child ?? const Icon(Icons.menu_book_outlined, size: 18),
              label: isLoading
                  ? const SizedBox.shrink()
                  : const Text(AppStrings.btnRead),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.ctaRustSoft,
                foregroundColor: AppColors.ctaRust,
                side: const BorderSide(color: AppColors.ctaRust),
                minimumSize: const Size(96, 42),
                textStyle: AppTextStyles.buttonSmall,
                shape: shape,
              ),
            ),
    );
  }
}

/// The price block of a locked story: the crossed-out price above the real
/// one.
class _StoryPrice extends StatelessWidget {
  final DongengResponse dongeng;
  const _StoryPrice({required this.dongeng});

  @override
  Widget build(BuildContext context) {
    final strike = dongeng.strikePriceIdr;
    final price = dongeng.priceIdr!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (strike != null && strike > price)
          Text(
            formatIdr(strike),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textLight,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textLight,
            ),
          ),
        Text(
          formatIdr(price),
          style: AppTextStyles.subheading.copyWith(
            color: AppColors.ctaRust,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A dashed horizontal rule between a story and its price/buy row.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(AppColors.lockGrey.withValues(alpha: 0.7)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

// ── Featured Card ──────────────────────────────────────────────────────────────

/// The story at the top of the list: a wide picture with a "Pilihan minggu
/// ini" pill, then its title, age/duration and a "Baca" (or "Beli") button.
class _FeaturedCard extends StatelessWidget {
  final DongengResponse dongeng;
  final VoidCallback onTap;
  final bool isLoading;

  const _FeaturedCard({
    required this.dongeng,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !dongeng.isUnlocked;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: Image(
                    image: MediaCache.image(dongeng.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.creamCard,
                      child: const Center(
                        child: Text('📖', style: TextStyle(fontSize: 64)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppStrings.dongengFeaturedBadge,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dongeng.title,
                          style: AppTextStyles.subheading,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(_meta(dongeng), style: AppTextStyles.caption),
                        if (locked && dongeng.priceIdr != null) ...[
                          const SizedBox(height: 6),
                          PriceTag(
                            price: dongeng.priceIdr!,
                            strikePrice: dongeng.strikePriceIdr,
                            showDiscount: false,
                            priceColor: AppColors.ctaRust,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StoryAction(
                    locked: locked,
                    isLoading: isLoading,
                    onPressed: onTap,
                  ),
                  if (locked &&
                      dongeng.productId != null &&
                      dongeng.priceIdr != null) ...[
                    const SizedBox(width: 8),
                    CartToggleButton(item: cartItemOf(dongeng), size: 42),
                  ],
                ],
              ),
            ),
            if (locked && dongeng.productId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: InCartLink(productId: dongeng.productId!),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Story Row ─────────────────────────────────────────────────────────────────

/// A story in the list. A locked one gets the full card — thumbnail with a
/// lock, "Hemat N%" when it's on promo, then a dashed rule and its price
/// beside a "Beli" button. One the user can open stays compact, with "Baca".
class _StoryRow extends StatelessWidget {
  final DongengResponse dongeng;
  final bool isLoading;
  final VoidCallback onTap;

  const _StoryRow({
    required this.dongeng,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !dongeng.isUnlocked;
    final buyable = locked && dongeng.priceIdr != null;
    final onPromo =
        buyable &&
        dongeng.strikePriceIdr != null &&
        dongeng.discountPercent != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _thumbnail(locked),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dongeng.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(_meta(dongeng), style: AppTextStyles.caption),
                      if (onPromo) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.discountRedSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Hemat ${dongeng.discountPercent}%',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.discountRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(width: 8),
                  _StoryAction(
                    locked: false,
                    isLoading: isLoading,
                    onPressed: onTap,
                  ),
                ],
              ],
            ),
            if (buyable) ...[
              const SizedBox(height: 12),
              const _DashedDivider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Shrinks a long price rather than pushing Beli off screen.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _StoryPrice(dongeng: dongeng),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StoryAction(
                    locked: true,
                    isLoading: isLoading,
                    onPressed: onTap,
                  ),
                  if (dongeng.productId != null) ...[
                    const SizedBox(width: 8),
                    CartToggleButton(item: cartItemOf(dongeng), size: 42),
                  ],
                ],
              ),
              if (dongeng.productId != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: InCartLink(productId: dongeng.productId!),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(bool locked) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image(
            image: MediaCache.image(dongeng.imageUrl),
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 72,
              height: 72,
              color: AppColors.creamCard,
              child: const Center(
                child: Text('📖', style: TextStyle(fontSize: 30)),
              ),
            ),
          ),
        ),
        if (locked)
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
      ],
    );
  }
}
