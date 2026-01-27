import 'package:arunika_app/presentation/screens/arscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/home/home_bloc.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
import 'package:arunika_app/presentation/screens/home/story_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  static const List<Map<String, String>> categories = [
    {
      "title": "Numbers",
      "image":
          "https://storage.googleapis.com/a1aa/image/KTco9PlO4VnxwpIOmykV40oSaTChaGPp_g0n39XWZDs.jpg",
    },
    {
      "title": "Shapes",
      "image":
          "https://storage.googleapis.com/a1aa/image/qSzsuL39YBR5CfR01URSfbRouZ7Q_2tImmwg-1eoKkI.jpg",
    },
    {
      "title": "Vocab",
      "image":
          "https://storage.googleapis.com/a1aa/image/Vt4DLo0qLYSGDuRSmGEizcrwpaywqfa5vjg5z55fQ5c.jpg",
    },
    {
      "title": "Dongeng",
      "image":
          "https://storage.googleapis.com/a1aa/image/hrtjK7BpRwCPJeq8wKrawJrq6dYsWJFSGknFf-ZeKxk.jpg",
    },
  ];

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<HomeBloc>().add(HomeInitial());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is NavigateToCategoryList) {
          context.push('/dongeng-list');
          context.read<HomeBloc>().add(HomeRefresh());
        }
        if (state is NavigateToDongengPlayer) {
          context.push('/dongeng-player', extra: state.dongeng);
          _searchController.clear();
          context.read<HomeBloc>().add(HomeRefresh());
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
                MaterialPageRoute(builder: (_) => QRScannerPage()),
              );
            },
            child: const Icon(Iconsax.scan, size: 28),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        body: SafeArea(
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return Column(
                children: [
                  // 🌤 Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFF4E6),
                          Color(0xFFFFE0B2),
                        ],
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
                            color: Color(0xFF6D4C41), // warm brown
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

                        // 🔍 Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            context.read<HomeBloc>().add(SearchQueryChanged(value));
                          },
                          decoration: InputDecoration(
                            hintText: "Cari dongeng favorit",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
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

                  // 📚 Story List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.filteredDongengList.length,
                      itemBuilder: (context, index) {
                        final story = state.filteredDongengList[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              context.read<HomeBloc>().add(DongengSelected(story));
                            },
                            child: StoryCard(
                              title: story.title,
                              ageGroup:
                              "${story.ageStart}–${story.ageEnd} years · 10 min",
                              imageUrl: story.imageUrl,
                              label: story.isFree ? 'FREE' : 'PAID',
                              labelColor: story.isFree ? Colors.green : Colors.orange,
                            ),
                          ),
                        );

                      },
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
