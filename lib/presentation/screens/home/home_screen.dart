import 'package:arunika_app/presentation/screens/arscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_screen.dart';
import 'package:arunika_app/presentation/screens/home/home_bloc.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
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
          context.push('/dongeng-player');
          _searchController.clear();
          context.read<HomeBloc>().add(HomeRefresh());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: BottomNav(
          currentIndex: 0,
          onArPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QRScannerPage()),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QRScannerPage()),
            );
          },
          backgroundColor: Colors.orange,
          child: const Icon(Iconsax.scan),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        body: SafeArea(
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Halo ${state.user?.children.first.name ?? '-'}",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[500],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        context.read<HomeBloc>().add(SearchQueryChanged(value));
                      },
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Expanded(
                      child: ListView.builder(
                        itemCount: state.filteredDongengList.length,
                        itemBuilder: (context, index) {
                          final story = state.filteredDongengList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  context.read<HomeBloc>().add(DongengSelected());
                                },
                                child: StoryCard(
                                  title: story.title,
                                  ageGroup: "${story.ageStart}–${story.ageEnd} years old · 5 min read",
                                  imageUrl: story.imageUrl,
                                  label: story.isFree ? 'FREE' : 'PAID',
                                  labelColor: story.isFree ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

      ),
    );
  }
}
