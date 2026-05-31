import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:arunika_app/presentation/screens/home/home_bloc.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
import 'package:arunika_app/presentation/screens/home/story_card.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<HomeBloc>().add(HomeInitial());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HomeBloc>().add(LoadMoreDongeng());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is NavigateToDongengPlayer) {
          context.push('/dongeng-player', extra: state.dongeng);
          _searchController.clear();
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
              final bool isNavigating = state is HomeNavigating;
              return Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                            Text(
                              "Halo ${state.user?.children.first.name ?? '-'} 👋",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6D4C41),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Yuk dengarkan dongeng hari ini",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8D6E63),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                context.read<HomeBloc>().add(
                                  SearchQueryChanged(value),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: "Cari dongeng favorit",
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              state.dongengList.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.dongengList.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                  ),
                                ),
                              );
                            }
                            final story = state.dongengList[index];
                            final bool isSelected =
                                isNavigating &&
                                // state is guaranteed HomeNavigating when isNavigating is true
                                // ignore: unnecessary_cast
                                (state as HomeNavigating).selectedId ==
                                    story.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: isNavigating
                                    ? null
                                    : () {
                                        context.read<HomeBloc>().add(
                                          DongengSelected(story),
                                        );
                                      },
                                child: StoryCard(
                                  title: story.title,
                                  ageGroup:
                                      "${story.ageStart}–${story.ageEnd} years · ${story.duration}",
                                  imageUrl: story.imageUrl,
                                  label: story.isFree ? 'FREE' : 'PAID',
                                  labelColor: story.isFree
                                      ? Colors.green
                                      : Colors.orange,
                                  isLoading: isSelected,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (isNavigating)
                    IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
