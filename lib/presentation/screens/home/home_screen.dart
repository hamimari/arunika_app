import 'dart:async';

import 'package:arunika_app/data/api/banner_api.dart';
import 'package:arunika_app/data/api/category_api.dart';
import 'package:arunika_app/data/models/response/banner_item.dart';
import 'package:arunika_app/data/models/response/category_item.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:arunika_app/presentation/screens/home/home_bloc.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
import 'package:arunika_app/presentation/screens/widgets/premium_dialog.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  @override
  void didPopNext() {
    context.read<HomeBloc>().add(HomeInitial());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is NavigateToDongengPlayer) {
          context.push('/dongeng-player', extra: state.dongeng);
          context.read<HomeBloc>().add(ResetNavigation());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        bottomNavigationBar: const BottomNav(currentIndex: 0),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.orange,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        QRScannerBloc(repository: locator<ArRepository>()),
                    child: QRScannerPage(),
                  ),
                ),
              );
            },
            child: const Icon(Iconsax.scan, size: 28),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: SafeArea(
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              final childName = state.user?.children.firstOrNull?.name ?? '-';
              final hasActivities = state.dongengList.isNotEmpty;

              return CustomScrollView(
                slivers: [
                  // ── Original gradient header ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF4E6), Color(0xFFFFE0B2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, $childName! 👋',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6D4C41),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Apa yang mau dipelajari hari ini?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8D6E63),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            iconSize: 28,
                            color: const Color(0xFF6D4C41),
                            onPressed: () => context.push('/notifications'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Banner carousel ────────────────────────────────────────
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: _BannerCarousel(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Kategori label ────────────────────────────────────────
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6D4C41),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Category cards ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _CategoryRow(compact: hasActivities),
                  ),

                  // ── Aktivitas Terakhir ─────────────────────────────────────
                  if (hasActivities) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Aktivitas Terakhir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6D4C41),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final story = state.dongengList[index];
                          final bool isNavigating = state is HomeNavigating;
                          final bool isSelected =
                              state is HomeNavigating &&
                              state.selectedId == story.id;
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _RecentStoryCard(
                              title: story.title,
                              subtitle:
                                  '${story.ageStart.toInt()}–${story.ageEnd.toInt()} tahun · ${story.duration}',
                              imageUrl: story.imageUrl,
                              isFree: story.isFree,
                              isLoading: isSelected,
                              onTap: isNavigating
                                  ? null
                                  : (story.isFree ||
                                        (state.user?.isPremium ?? false))
                                  ? () => context.read<HomeBloc>().add(
                                      DongengSelected(story),
                                    )
                                  : () => PremiumDialog.show(context),
                            ),
                          );
                        },
                        childCount: state.dongengList.length > 5
                            ? 5
                            : state.dongengList.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/dongeng-list'),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.orange,
                          ),
                          label: const Text(
                            'Lihat semua dongeng',
                            style: TextStyle(color: Colors.orange),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _EmptyActivity(),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Banner Carousel ────────────────────────────────────────────────────────────

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<BannerItem> _banners = [];
  bool _loading = true;

  // Fallback placeholder gradients when no banners from backend
  static const _placeholders = [
    LinearGradient(
      colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF9C27B0), Color(0xFFCE93D8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF1565C0), Color(0xFF90CAF9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];
  static const _placeholderLabels = [
    'Selamat Belajar!',
    'Cerita Seru Menanti',
    'Latihan Hari Ini',
  ];
  static const _placeholderSubs = [
    'Mulai aktivitas favoritmu',
    'Dongeng untuk tumbuh kembang',
    'Asah kemampuan bersama Arunika',
  ];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final api = BannerApi();
      final list = await api.getActiveBanners();
      if (mounted) {
        setState(() {
          _banners = BannerItem.fromJsonList(list);
          _loading = false;
        });
        _startTimer();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      _startTimer();
    }
  }

  void _startTimer() {
    final count = _banners.isNotEmpty ? _banners.length : _placeholders.length;
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % count;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildPlaceholderBanner(0);
    }

    final count = _banners.isNotEmpty ? _banners.length : _placeholders.length;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              if (_banners.isNotEmpty) {
                return _buildImageBanner(_banners[i]);
              }
              return _buildPlaceholderBanner(i % _placeholders.length);
            },
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.orange
                      : Colors.orange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildImageBanner(BannerItem banner) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Light background for letterboxing
          Container(color: const Color(0xFFFFF4E6)),
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderBanner(0),
          ),
          // Gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (banner.description.isNotEmpty)
                  Text(
                    banner.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBanner(int idx) {
    return Container(
      decoration: BoxDecoration(
        gradient: _placeholders[idx],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _placeholderLabels[idx],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _placeholderSubs[idx],
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category Row (fetches from API) ───────────────────────────────────────────

/// Maps backend category names (case-insensitive) to app routes.
String? _routeForCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('dongeng') || n.contains('story') || n.contains('cerita')) {
    return '/dongeng-list';
  }
  if (n.contains('trac')) return '/tracing';
  if (n.contains('angka') ||
      n.contains('count') ||
      n.contains('hitung') ||
      n.contains('number')) {
    return '/counting';
  }
  return null;
}

class _CategoryRow extends StatefulWidget {
  /// When true (activities present), overflow beyond 4 scrolls horizontally.
  /// When false (no activities), overflow wraps into a vertical grid.
  final bool compact;
  const _CategoryRow({this.compact = true});

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  List<CategoryItem> _categories = [];
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();
  int _activeDot = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final cardWidth = _cardWidth(context);
    final stride = cardWidth + 14.0; // card + gap
    final page = (offset / stride).round().clamp(0, _categories.length - 1);
    if (page != _activeDot) setState(() => _activeDot = page);
  }

  double _cardWidth(BuildContext ctx) {
    const double hPadding = 40.0; // 20 left + 20 right
    const double gap = 14.0;
    const int visible = 4;
    return (MediaQuery.of(ctx).size.width - hPadding - gap * (visible - 1)) /
        visible;
  }

  Future<void> _load() async {
    try {
      final list = await CategoryApi().getCategories();
      if (mounted) {
        setState(() {
          _categories = CategoryItem.fromJsonList(
            list,
          ).where((c) => !c.hidden).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _StaticCategoryRow(),
      );
    }

    const double gap = 14.0;
    final bool overflow = _categories.length > 4;

    // ── ≤ 4: equal-width row filling screen ─────────────────────────────────
    if (!overflow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final route = _routeForCategory(cat.name);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
                child: _CategoryCard(
                  label: cat.name,
                  imageUrl: cat.imageUrl,
                  onTap: route != null ? () => context.push(route) : null,
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // ── > 4 + activities present: horizontal scroll + dot indicator ──────────
    if (widget.compact) {
      final cardW = _cardWidth(context);
      return Column(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _categories.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final route = _routeForCategory(cat.name);
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
                  child: SizedBox(
                    width: cardW,
                    child: _CategoryCard(
                      label: cat.name,
                      imageUrl: cat.imageUrl,
                      onTap: route != null ? () => context.push(route) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Dot indicator — one dot per category, active dot = orange
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_categories.length, (i) {
              final active = i == _activeDot;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.orange
                      : Colors.orange.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      );
    }

    // ── > 4 + no activities: vertical 2-column wrap ──────────────────────────
    final cardW = (MediaQuery.of(context).size.width - 40 - gap) / 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: _categories.map((cat) {
          final route = _routeForCategory(cat.name);
          return SizedBox(
            width: cardW,
            child: _CategoryCard(
              label: cat.name,
              imageUrl: cat.imageUrl,
              onTap: route != null ? () => context.push(route) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Static fallback (shown when API returns empty) ────────────────────────────

class _StaticCategoryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CategoryCard(
            label: 'Dongeng',
            fallbackIcon: Icons.menu_book_rounded,
            fallbackColor: const Color(0xFF9C27B0),
            onTap: () => context.push('/dongeng-list'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _CategoryCard(
            label: 'Tracing',
            fallbackIcon: Icons.draw_rounded,
            fallbackColor: const Color(0xFFF57C00),
            onTap: () => context.push('/tracing'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _CategoryCard(
            label: 'Angka',
            fallbackIcon: Icons.calculate_rounded,
            fallbackColor: const Color(0xFF1565C0),
            onTap: () => context.push('/counting'),
          ),
        ),
      ],
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData? fallbackIcon;
  final Color? fallbackColor;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.label,
    this.imageUrl,
    this.fallbackIcon,
    this.fallbackColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color:
                    fallbackColor?.withValues(alpha: 0.12) ??
                    Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6D4C41),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(
        fallbackIcon ?? Icons.category_rounded,
        size: 36,
        color: fallbackColor ?? Colors.orange,
      ),
    );
  }
}

// ── Recent story card ──────────────────────────────────────────────────────────

class _RecentStoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isFree;
  final bool isLoading;
  final VoidCallback? onTap;

  const _RecentStoryCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.isFree,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isFree ? Colors.green : Colors.orange;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.book_rounded, color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D4C41),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.orange,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFree ? 'FREE' : 'PAID',
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty activity ─────────────────────────────────────────────────────────────

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: 48,
            color: Colors.orange,
          ),
          SizedBox(height: 8),
          Text(
            'Mulai belajar sekarang!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D4C41),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pilih kategori di atas untuk memulai aktivitas.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8D6E63)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
