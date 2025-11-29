import 'package:flutter/material.dart';
import 'app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final String hint;
  const SearchBarWidget({super.key, this.hint = 'IMAX theaters'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.searchFill,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 30,color: AppColors.searchIcon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                color: AppColors.searchHint,
                fontSize: 16,
              ),
            ),
          ),
          const Icon(Icons.mic_none, color: AppColors.searchIcon),
        ],
      ),
    );
  }
}
