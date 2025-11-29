import 'package:flutter/material.dart';

class SmallCardList extends StatelessWidget {
  final int count;
  final double height;
  const SmallCardList({super.key, this.count = 4, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(image: NetworkImage('https://picsum.photos/300/400?random=$index'), fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}