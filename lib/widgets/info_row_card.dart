import 'package:cinematick/widgets/app_colors.dart';
import 'package:flutter/material.dart';

class InfoRowCard extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final num? cheapestPrice;
  final int availabilityPercentage;
  final bool showNearest;

  const InfoRowCard({
    required this.selected,
    required this.onChanged,
    this.cheapestPrice,
    this.availabilityPercentage = 0,
    this.showNearest = true,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = showNearest ? 4 : 3;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white24, width: 1.1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(itemCount, (i) {
          return Expanded(
            child: _InfoSection(
              index: i,
              selected: selected == i,
              onTap: () => onChanged(i),
              cheapestPrice: cheapestPrice,
              availabilityPercentage: availabilityPercentage,
            ),
          );
        }),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final num? cheapestPrice;
  final int availabilityPercentage;

  const _InfoSection({
    required this.index,
    required this.selected,
    required this.onTap,
    this.cheapestPrice,
    this.availabilityPercentage = 0,
  });

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow:
                  selected
                      ? [
                        BoxShadow(
                          color: AppColors.accentOrange.withOpacity(0.19),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ]
                      : [],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${cheapestPrice ?? 0}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'CHEAPEST',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case 1:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : Colors.transparent,

              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$availabilityPercentage%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.white60,
                    fontSize: 12,
                  ),
                ),

                Text(
                  'AVAILABILITY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.white60,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 2,
                  width: 55,
                  margin: const EdgeInsets.only(top: 2, bottom: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: availabilityPercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),
        );
      case 2:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chair_outlined, color: Colors.white, size: 21),
                SizedBox(height: 2),
                Text(
                  'PREMIUM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      case 3:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow:
                  selected
                      ? [
                        BoxShadow(
                          color: AppColors.accentOrange.withOpacity(0.19),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ]
                      : [],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_outlined, color: Colors.white, size: 19),
                SizedBox(height: 2),
                Text(
                  'NEAREST',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
    }
    return const SizedBox();
  }
}
