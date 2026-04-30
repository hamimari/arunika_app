import 'package:arunika_app/data/models/response/badge_item.dart';
import 'package:arunika_app/data/repositories/badge_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/badge/badge_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/feature_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BadgeGalleryScreen extends StatelessWidget {
  const BadgeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BadgeCubit(repository: locator<BadgeRepository>())..load(),
      child: FeatureScaffold(
        title: 'Lencana',
        body: BlocBuilder<BadgeCubit, BadgeState>(
          builder: (context, state) {
            if (state is BadgeLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            }
            if (state is BadgeError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Color(0xFF6D4C41)),
                ),
              );
            }
            if (state is BadgeLoaded) {
              if (state.badges.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: Colors.orange,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada lencana',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6D4C41),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: state.badges.length,
                itemBuilder: (ctx, i) => _BadgeCard(badge: state.badges[i]),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeItem badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final locked = !badge.earned;
    final progress = badge.threshold > 0
        ? badge.progress / badge.threshold
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: locked ? Colors.grey.shade100 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: locked ? Colors.grey.shade300 : Colors.orange.shade200,
        ),
        boxShadow: locked
            ? []
            : [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            locked ? Icons.lock_rounded : Icons.emoji_events_rounded,
            size: 34,
            color: locked ? Colors.grey.shade400 : Colors.orange,
          ),
          const SizedBox(height: 6),
          Text(
            badge.level,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: locked ? Colors.grey.shade500 : const Color(0xFF6D4C41),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.grey.shade200,
              color: badge.earned ? Colors.orange : Colors.orange.shade200,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${badge.progress}/${badge.threshold}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF8D6E63)),
          ),
        ],
      ),
    );
  }
}
