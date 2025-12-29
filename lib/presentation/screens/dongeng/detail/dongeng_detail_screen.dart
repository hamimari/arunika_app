import 'package:arunika_app/presentation/screens/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';

class DongengDetailScreen extends StatelessWidget {
  const DongengDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image/Thumbnail
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.greenAccent, width: 4),
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    "Hansel & Gratle",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  // Subtitle
                  const SizedBox(height: 8),
                  Text(
                    "Suitable for 9–12 years old",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[200],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            activeTrackColor: Colors.orange,
                            inactiveTrackColor: Colors.grey,
                            thumbColor: Colors.orange,
                          ),
                          child: Slider(
                            value: 2.43,
                            min: 0,
                            max: 6.21,
                            onChanged: (value) {},
                          ),
                        ),

                        // Time labels
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("02:43"),
                              Text("06:21"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Player controls
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.replay_10, size: 28),
                        Icon(Icons.skip_previous, size: 28),
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.play_arrow, size: 36),
                        ),
                        Icon(Icons.skip_next, size: 28),
                        Icon(Icons.forward_10, size: 28),
                      ],
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
