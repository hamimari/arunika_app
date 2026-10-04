import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/profile');
        break;
    }
  }

  Widget _navItem(
      BuildContext context, {
        required IconData icon,
        required bool active,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? Colors.orange.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 26,
          color: active ? Colors.orange : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(
              context,
              icon: Iconsax.sun_fog,
              active: currentIndex == 0,
              onTap: () => _onTap(context, 0),
            ),

            const SizedBox(width: 56), // FAB space

            _navItem(
              context,
              icon: Iconsax.profile_circle,
              active: currentIndex == 1,
              onTap: () => _onTap(context, 1),
            ),
          ],
        ),
      ),
    );
  }
}


