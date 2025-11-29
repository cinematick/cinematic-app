import 'package:flutter/material.dart';

import 'app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String location;
  const CustomAppBar({super.key, this.location = 'Sydney'});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false, 
      title: Row(
        children: [
          ShaderMask(
            shaderCallback:
                (bounds) => AppColors.appBarTitleGradient
                .createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
            child: const Text(
              'Cinema',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Colors.white, 
              ),
            ),
          ),
          ShaderMask(
            shaderCallback:
                (bounds) => AppColors.appBarTickGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
            child: const Text(
              'Tick',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Colors.white,
              ),
            ),
          ),

          const Spacer(),
          const Icon(
            Icons.location_on_outlined,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            location,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
