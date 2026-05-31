import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/ar_card_category.dart';
import 'package:arunika_app/data/models/response/banner_item.dart';
import 'package:arunika_app/data/models/response/child_response.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/home/home_banner_cubit.dart';
import 'package:arunika_app/presentation/screens/home/home_dongeng_section_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ─── Main Screen ─────────────────────────────────────────────────────────────

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  late final AuthNotifier _authNotifier;
  ChildResponse? _child;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _authNotifier = locator<AuthNotifier>();
    _authNotifier.addListener(_onAuthChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _authNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!_authNotifier.isLoggedIn) {
      // Immediately clear stale profile so rebuild shows logged-out state
      setState(() {
        _child = null;
        _isSubscribed = false;
      });
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Guard: never show a profile when logged out, even if storage has stale data.
    if (!_authNotifier.isLoggedIn) {
      if (mounted) {
        setState(() {
          _child = null;
          _isSubscribed = false;
        });
      }
      return;
    }
    final profile = await LocalProfileStorage.get();
    if (mounted) {
      setState(() {
        _child = profile?.children.isNotEmpty == true
            ? profile!.children.first
            : null;
        _isSubscribed = profile?.isSubscribed ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _authNotifier.isLoggedIn;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeBannerCubit()),
        BlocProvider(create: (_) => HomeDongengSectionBloc()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFFFEDD5),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFEDD5), AppColors.pageBackground],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HomeHeader(isLoggedIn: isLoggedIn, child: _child),
              ),
              SliverToBoxAdapter(child: _BannerCarouselSection()),
              SliverToBoxAdapter(
                child: _StoriesSection(isLoggedIn: isLoggedIn),
              ),
              SliverToBoxAdapter(child: _CategoriesSection()),
              SliverToBoxAdapter(
                child: _PremiumBanner(
                  isLoggedIn: isLoggedIn,
                  isSubscribed: _isSubscribed,
                ),
              ),
              SliverToBoxAdapter(child: _PrintableSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final bool isLoggedIn;
  final ChildResponse? child;
  const _HomeHeader({required this.isLoggedIn, this.child});

  @override
  Widget build(BuildContext context) {
    final starPoints = child?.starPoints ?? 0;
    final avatarUrl = child != null
        ? 'https://api.dicebear.com/7.x/bottts/png?seed=${child!.name}'
        : null;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: () => isLoggedIn
                  ? MainShell.shellKey.currentState?.switchTab(
                      MainShellTab.parent,
                    )
                  : context.push('/signin'),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFE0B2),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? const Icon(
                        Icons.child_care,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isLoggedIn ? 'Halo, Explorer!' : 'Halo, Teman!',
                        style: AppTextStyles.subheading.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // const Text('👋', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Text(
                    'Yuk, belajar sambil bermain!',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            // XP / Star badge — hidden until feature is enabled
            if (false)
              // ignore: dead_code
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 5),
                      Text(
                        isLoggedIn ? '$starPoints' : '0',
                        style: AppTextStyles.subheading.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner Carousel Section ──────────────────────────────────────────────────

class _BannerCarouselSection extends StatefulWidget {
  const _BannerCarouselSection();

  @override
  State<_BannerCarouselSection> createState() => _BannerCarouselSectionState();
}

class _BannerCarouselSectionState extends State<_BannerCarouselSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBannerCubit, HomeBannerState>(
      builder: (context, state) {
        if (state is HomeBannerEmpty) {
          // Fallback to static hero banner when no banners
          return _HeroBanner(
            onScanTap: () =>
                MainShell.shellKey.currentState?.switchTab(MainShellTab.scan),
          );
        }
        if (state is! HomeBannerLoaded) {
          return const SizedBox(
            height: 198,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final banners = state.banners;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              SizedBox(
                height: 190,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: banners.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final banner = banners[i];
                    if (banner.type == 'daily_animal') {
                      return _DailyAnimalBannerCard(banner: banner);
                    }
                    return _PromoBannerCard(banner: banner);
                  },
                ),
              ),
              if (banners.length > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    banners.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.primaryOrange
                            : AppColors.primaryOrange.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PromoBannerCard extends StatelessWidget {
  final BannerItem banner;
  const _PromoBannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB8E4FF), Color(0xFF80CFFF), Color(0xFFD4F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF80CFFF).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (banner.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          // Gradient overlay for text readability
          // Container(
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(24),
          //     gradient: LinearGradient(
          //       colors: [
          //         Colors.black.withValues(alpha: 0.45),
          //         Colors.transparent,
          //       ],
          //       begin: Alignment.bottomLeft,
          //       end: Alignment.topRight,
          //     ),
          //   ),
          // ),
          Positioned(
            left: 20,
            bottom: 20,
            right: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                ),
                if (banner.ctaUrl != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Lihat', style: AppTextStyles.buttonSmall),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyAnimalBannerCard extends StatelessWidget {
  final BannerItem banner;
  const _DailyAnimalBannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hewan Hari Ini',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  banner.title,
                  style: AppTextStyles.heading.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (banner.fact != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    banner.fact!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => MainShell.shellKey.currentState?.switchTab(
                    MainShellTab.collection,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Lihat Koleksi',
                      style: AppTextStyles.buttonSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(banner.emoji ?? '🐾', style: const TextStyle(fontSize: 80)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Hero AR Banner (fallback) ────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final VoidCallback onScanTap;
  const _HeroBanner({required this.onScanTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GestureDetector(
        onTap: onScanTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            'https://raw.githubusercontent.com/hamimari/arunika_assets/main/banner.png',
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFFB8E4FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('🦌', style: TextStyle(fontSize: 80)),
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Stories Section ──────────────────────────────────────────────────────────

class _StoriesSection extends StatelessWidget {
  final bool isLoggedIn;
  const _StoriesSection({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeDongengSectionBloc, HomeDongengState>(
      builder: (context, state) {
        if (state is HomeDongengError || state is HomeDongengLoading) {
          // Show shimmer placeholder or nothing during load
          return const SizedBox.shrink();
        }
        if (state is! HomeDongengLoaded || state.items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dongeng Populer', style: AppTextStyles.subheading),
                  GestureDetector(
                    onTap: () => MainShell.shellKey.currentState?.switchTab(
                      MainShellTab.dongeng,
                    ),
                    child: Text(
                      'Lihat Semua',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 192,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20),
                itemCount: state.items.length,
                itemBuilder: (context, i) => _StoryCardWidget(
                  dongeng: state.items[i],
                  progress: state.progressMap[state.items[i].id] ?? 0.0,
                  isLoggedIn: isLoggedIn,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StoryCardWidget extends StatelessWidget {
  final DongengResponse dongeng;
  final double progress;
  final bool isLoggedIn;
  const _StoryCardWidget({
    required this.dongeng,
    required this.progress,
    required this.isLoggedIn,
  });

  Future<void> _openDongeng(BuildContext context) async {
    try {
      final full = await locator<FairyTalesRepository>().findById(dongeng.id);
      if (context.mounted) {
        context.push('/dongeng-player', extra: full);
      }
    } catch (_) {
      if (context.mounted) {
        context.push('/dongeng-player', extra: dongeng);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = !dongeng.isFree;
    return GestureDetector(
      onTap: () {
        if (isLocked) {
          if (!isLoggedIn) {
            showLoginRequiredDialog(context, featureLabel: 'dongeng premium');
          } else {
            context.push('/premium');
          }
        } else {
          _openDongeng(context);
        }
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: dongeng.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: Image.network(
                              dongeng.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : const Text('📖', style: TextStyle(fontSize: 60)),
                  ),
                  if (isLocked)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? AppColors.lockGrey
                            : AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isLocked
                                        ? AppColors.lockGrey
                                        : AppColors.primaryOrange)
                                    .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.lock_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dongeng.title,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.35,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: AppColors.primaryOrange.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Categories Section ───────────────────────────────────────────────────────

class _CategoriesSection extends StatefulWidget {
  const _CategoriesSection();

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  List<ArCardCategory> _categories = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await locator<ArRepository>().getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _categories.isEmpty) {
      return const SizedBox.shrink();
    }
    final displayCats = _categories.take(5).toList();
    final hasMore = _categories.length > 5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kategori Kartu AR', style: AppTextStyles.subheading),
              if (hasMore)
                GestureDetector(
                  onTap: () => MainShell.shellKey.currentState?.switchTab(
                    MainShellTab.collection,
                  ),
                  child: Text(
                    'Lihat Semua',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: displayCats
                .map(
                  (cat) => _CategoryTile(
                    id: cat.id,
                    name: cat.name,
                    emoji: cat.emoji,
                    imageUrl: cat.imageUrl,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String id;
  final String name;
  final String emoji;
  final String imageUrl;
  const _CategoryTile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        CollectionScreen.externalCategoryFilter.value = id;
        MainShell.shellKey.currentState?.switchTab(MainShellTab.collection);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.categoryGreenBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.categoryGreen.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Premium Banner ───────────────────────────────────────────────────────────

class _PremiumBanner extends StatelessWidget {
  final bool isLoggedIn;
  final bool isSubscribed;
  const _PremiumBanner({required this.isLoggedIn, this.isSubscribed = false});

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn && isSubscribed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () => context.push('/premium'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.premiumPurple,
                AppColors.premiumPurpleDark,
                Color(0xFF4A35C8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.premiumPurple.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Sparkle decorations
              const Positioned(
                top: 0,
                right: 80,
                child: Text('✨', style: TextStyle(fontSize: 14)),
              ),
              const Positioned(
                top: 24,
                right: 48,
                child: Text('✨', style: TextStyle(fontSize: 10)),
              ),
              // Gift illustration (right)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Text('🎁', style: TextStyle(fontSize: 56)),
              ),
              // Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              'Akses Premium',
                              style: AppTextStyles.subheading.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buka 100+ hewan, semua dongeng,\nfitur eksklusif dan banyak lagi!',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryOrange.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Upgrade Sekarang',
                            style: AppTextStyles.buttonSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Printable Section ────────────────────────────────────────────────────────

class _PrintableSection extends StatelessWidget {
  const _PrintableSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => _showPrintableSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryOrange.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🖨️', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kartu Printable',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Cetak & gunakan untuk AR!',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintableSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _PrintableSheetContent(),
    );
  }
}

class _PrintableSheetContent extends StatefulWidget {
  const _PrintableSheetContent();

  @override
  State<_PrintableSheetContent> createState() => _PrintableSheetContentState();
}

class _PrintableSheetContentState extends State<_PrintableSheetContent> {
  late final ArRepository _arRepository;
  List<ArCardCategory> _categories = [];
  bool _loading = true;
  final Set<String> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _arRepository = locator<ArRepository>();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _arRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadPdf(String categoryId, String name) async {
    setState(() => _downloadingIds.add(categoryId));
    try {
      final bytes = await _arRepository.getPrintablePdf(categoryId);
      if (bytes.isEmpty) {
        if (mounted) _showNoCardDialog(name);
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kartu-ar-$categoryId.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('not found') ||
            msg.contains('404') ||
            msg.contains('empty') ||
            msg.contains('no card') ||
            msg.contains('tidak ada')) {
          _showNoCardDialog(name);
        } else {
          _showDownloadErrorDialog(name);
        }
      }
    } finally {
      if (mounted) setState(() => _downloadingIds.remove(categoryId));
    }
  }

  void _showNoCardDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kartu Tidak Ditemukan',
              style: AppTextStyles.subheading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada kartu yang tersedia untuk kategori "$categoryName". Coba kategori lain.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadErrorDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Mengunduh',
              style: AppTextStyles.subheading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Terjadi kesalahan saat mengunduh kartu "$categoryName". Periksa koneksi internet dan coba lagi.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lockGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Text('Unduh Kartu Printable', style: AppTextStyles.subheading),
          const SizedBox(height: 4),
          Text('Pilih kategori untuk diunduh', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            )
          else if (_categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 30,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kategori Tidak Ditemukan',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belum ada kategori yang tersedia saat ini.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._categories.map(
              (cat) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: cat.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            cat.imageUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              cat.emoji.isNotEmpty ? cat.emoji : '📄',
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        )
                      : Text(
                          cat.emoji.isNotEmpty ? cat.emoji : '📄',
                          style: const TextStyle(fontSize: 26),
                        ),
                  title: Text(cat.name, style: AppTextStyles.bodyLarge),
                  trailing: _downloadingIds.contains(cat.id)
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.download_rounded,
                            color: AppColors.primaryOrange,
                          ),
                          onPressed: () => _downloadPdf(cat.id, cat.name),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
