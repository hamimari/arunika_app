import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:arunika_app/presentation/screens/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DongengListScreen extends StatelessWidget {
  const DongengListScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<DongengListBloc, DongengListState>(
      listener: (context, state) {
        if (state is NavigateToDongengPlayer) {
          context.push('/dongeng-player'); // <-- GoRouter style navigation
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category title
                const Text(
                  'Dongeng',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),

                // Story list
                Expanded(
                  child: ListView.builder(
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              context
                                  .read<DongengListBloc>()
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

        // Bottom navigation
        bottomNavigationBar: const BottomNav(currentIndex: 1),
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final String title;
  final String ageGroup;
  final String imageUrl;
  final String label;
  final Color labelColor;

  const StoryCard({
    super.key,
    required this.title,
    required this.ageGroup,
    required this.imageUrl,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(imageUrl),
            backgroundColor: labelColor.withOpacity(0.2),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                    )),
                const SizedBox(height: 4),
                Text(ageGroup, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: labelColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10),
            ),
          )
        ],
      ),
    );
  }
}
