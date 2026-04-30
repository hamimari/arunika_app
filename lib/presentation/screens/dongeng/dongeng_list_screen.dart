import 'package:arunika_app/core/subscription_service.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/premium_dialog.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/presentation/screens/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class DongengListScreen extends StatefulWidget {
  const DongengListScreen({super.key});

  @override
  State<DongengListScreen> createState() => _DongengListScreenState();
}

class _DongengListScreenState extends State<DongengListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _userIsPremium = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.isPremium().then((v) {
      if (mounted) setState(() => _userIsPremium = v);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final bool isNavigating = state is DongengListNavigating;

        return Scaffold(
          backgroundColor: const Color(0xFFFFFBF5),
          bottomNavigationBar: const BottomNav(currentIndex: 0),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.35),
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          body: SafeArea(
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // ── Header ──────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: Color(0xFF6D4C41),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Dongeng',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6D4C41),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Search bar
                            TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _query = v.toLowerCase()),
                              decoration: InputDecoration(
                                hintText: 'Cari dongeng favorit...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF8D6E63),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── Content ────────────────────────────────────────────
                    SliverToBoxAdapter(child: _buildBody(context, state)),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
                if (isNavigating)
                  IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
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

  Widget _buildBody(BuildContext context, DongengListState state) {
    if (state is DongengListLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (state is DongengListError) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6D4C41)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  context.read<DongengListBloc>().add(LoadDongengList()),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final List<DongengResponse> all;
    if (state is DongengListLoaded) {
      all = state.dongengList;
    } else if (state is DongengListNavigating) {
      all = state.dongengList;
    } else {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final list = _query.isEmpty
        ? all
        : all.where((d) => d.title.toLowerCase().contains(_query)).toList();

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty
                  ? 'Belum ada dongeng tersedia.'
                  : 'Tidak ada hasil untuk "$_query"',
              style: const TextStyle(fontSize: 15, color: Color(0xFF6D4C41)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final story = list[index];
        final bool isSelected =
            state is DongengListNavigating && state.selectedId == story.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: state is DongengListNavigating
                ? null
                : (story.isFree || _userIsPremium)
                ? () => context.read<DongengListBloc>().add(
                    DongengItemSelected(story),
                  )
                : () => PremiumDialog.show(context),
            child: _StoryCard(dongeng: story, isLoading: isSelected),
          ),
        );
      },
    );
  }
}

// ── Story card ─────────────────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  final DongengResponse dongeng;
  final bool isLoading;

  const _StoryCard({required this.dongeng, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final isFree = dongeng.isFree;
    final labelColor = isFree ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.07),
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
              dongeng.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.book_rounded, color: labelColor),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dongeng.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6D4C41),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${dongeng.ageStart.toInt()}–${dongeng.ageEnd.toInt()} tahun · ${dongeng.duration}',
                  style: const TextStyle(
                    color: Color(0xFF8D6E63),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                color: labelColor.withOpacity(0.12),
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
    );
  }
}
