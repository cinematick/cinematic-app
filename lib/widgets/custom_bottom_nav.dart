import 'package:flutter/material.dart';
import 'app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _navItem(IconData icon, String label, int index) {
    final bool selected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? AppColors.white : AppColors.bottomNavInactive,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  selected
                      ? AppColors.bottomNavActive
                      : AppColors.bottomNavInactive,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        color: AppColors.bottomNav,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined, 'Home', 0),
            _navItem(Icons.local_movies_outlined, 'Cinema', 1),
            _navItem(Icons.task_alt_outlined, 'Tick', 2),
            _navItem(Icons.info_outline, 'About', 3),
          ],
        ),
      ),
    );
  }
}
