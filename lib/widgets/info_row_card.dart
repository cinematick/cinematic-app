import 'package:cinematick/widgets/app_colors.dart';
import 'package:flutter/material.dart';

class InfoRowCard extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const InfoRowCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white24, width: 1.1),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (i) {
          return Expanded(
            child: _InfoSection(
              index: i,
              selected: selected == i,
              onTap: () => onChanged(i),
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

  const _InfoSection({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
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
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$16',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.white60,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Cheapest',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
            margin: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : Colors.transparent,

              borderRadius: BorderRadius.circular(10),
             
            ),
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '83%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.white60,
                    fontSize: 17,
                  ),
                ),
            
                Text(
                  'Availability',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.white60,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 8),
                  Container(
                  height: 3,
                  width: 55,
                  margin: EdgeInsets.only(top: 4, bottom: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.83,
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
            margin: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
             
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chair_outlined, color: Colors.white, size: 21),
                SizedBox(height: 5),
                Text(
                  'Premium',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
            margin: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color:
                  selected ? Colors.blue.withOpacity(0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border:
                  selected ? Border.all(color: Colors.blue, width: 1.3) : null,
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_outlined, color: Colors.redAccent, size: 19),
                SizedBox(height: 2),
                Text(
                  'Nearest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
    }
    return SizedBox();
  }
}
