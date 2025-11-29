import 'package:flutter/material.dart';
import 'app_colors.dart';

class LanguageChips extends StatelessWidget {
  final List<String> languages;
  final String selected;
  final ValueChanged<String> onSelected;

  const LanguageChips({
    super.key,
    required this.languages,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Wrap(
          spacing: 8,
          children: languages.map((lang) {
            final bool isSel = lang == selected;
            return GestureDetector(
              onTap: () => onSelected(lang),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.chipUnselectedText : AppColors.chipUnselectedBg,
                  borderRadius: BorderRadius.circular(10),
                 
                ),
                child: Text(
                  lang,
                  style: TextStyle(
                    color: isSel ? AppColors.chipSelectedBg : AppColors.chipUnselectedText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.chipSelectedBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Icon(Icons.filter_list, color: AppColors.searchIcon, size: 18),
              SizedBox(width: 6),
              Text('Filters', style: TextStyle(color: AppColors.searchIcon)),
            ],
          ),
        ),
      ],
    );
  }
}
