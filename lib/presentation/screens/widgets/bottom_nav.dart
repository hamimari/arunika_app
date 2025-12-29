import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onArPressed;

  const BottomNav({
    super.key,
    required this.currentIndex,
    this.onArPressed,
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

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(Iconsax.sun_fog,
                color: currentIndex == 0 ? Colors.orange : Colors.grey),
            onPressed: () => _onTap(context, 0),
          ),
          const SizedBox(width: 48), // space for the FAB
          IconButton(
            icon: Icon(Iconsax.profile_circle,
                color: currentIndex == 1 ? Colors.orange : Colors.grey),
            onPressed: () => _onTap(context, 1),
          ),
        ],
      ),
    );
  }
}

