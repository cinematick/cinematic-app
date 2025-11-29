import 'package:flutter/material.dart';
import 'app_colors.dart';

class TabSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const TabSelector({super.key, required this.selected, required this.onChanged});

  Widget _tab(String label, IconData icon, int idx) {
    final bool isSel = selected == idx;
    return GestureDetector(
      onTap: () => onChanged(idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: isSel ? AppColors.tabSelectedBg : AppColors.tabUnselectedBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSel ? AppColors.tabSelectedBg : AppColors.tabUnselectedBg,
              size: 18,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: isSel ? AppColors.tabSelectedText : AppColors.tabUnselectedText,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab('Trending', Icons.trending_up, 0),
        const SizedBox(width: 10),
        _tab('Now Playing', Icons.local_movies, 1),
        const SizedBox(width: 10),
        _tab('Coming Soon', Icons.schedule, 2),
      ],
    );
  }
}
