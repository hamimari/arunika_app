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

  static const List<Map<String, dynamic>> stories = [
    {
      'title': 'Poor Pluto',
      'ageGroup': '6–9 years old · 5 min read',
      'imageUrl':
      'https://storage.googleapis.com/a1aa/image/2KbLEXPe53yJBZZcTS3MrE4GC4mmaJ6k0zqQT3Fw4Wc.jpg',
      'label': 'PAID',
      'labelColor': Colors.orange,
    },
    {
      'title': 'Hansel & Grate',
      'ageGroup': '9–12 years old · 7 min read',
      'imageUrl':
      'https://storage.googleapis.com/a1aa/image/2KbLEXPe53yJBZZcTS3MrE4GC4mmaJ6k0zqQT3Fw4Wc.jpg',
      'label': 'FREE',
      'labelColor': Colors.green,
    },
  ];

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
        if (state is NavigateToCategoryList) {
          context.push('/dongeng-list');
          context.read<HomeBloc>().add(HomeRefresh());
        }
        if (state is NavigateToDongengPlayer) {
          context.push('/dongeng-player');
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
        /*body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo ${context.select((HomeBloc b) => b.state.user?.children[0].name)}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[500],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
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
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: HomeScreen.categories.map((category) {
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 1,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            context.read<HomeBloc>().add(HomePressed());
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 100, // Adjust height as needed
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  image: DecorationImage(
                                    image: NetworkImage(category["image"]!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category["title"]!,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "10 Courses Available", // Replace with dynamic data if needed
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),*/
        body: SafeArea(
          child:  Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo ${context.select((HomeBloc b) => b.state.user?.children[0].name)}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[500],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
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

                // Story list
                Expanded(
                  child: ListView.builder(
                    itemCount: HomeScreen.stories.length,
                    itemBuilder: (context, index) {
                      final story = HomeScreen.stories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              context
                                  .read<HomeBloc>()
                                  .add(DongengSelected());
                            },
                            child: StoryCard(
                              title: story['title'],
                              ageGroup: story['ageGroup'],
                              imageUrl: story['imageUrl'],
                              label: story['label'],
                              labelColor: story['labelColor'],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
