import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundTop = Color(
    0xFF1A0B35,
  );
  static const Color backgroundMid = Color(0xFF4A1B7A); // rich purple (mid)
  static const Color backgroundBottom = Color(
    0xFF1A0B35,
  ); // bright violet (bottom-right)

  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundTop, backgroundMid, backgroundBottom],
    stops: [0.0, 0.50, 1.0],
  );

  // 🟧 Accent & Highlights
  static const Color accentOrange = Color(
    0xFFFFB64B,
  ); // Orange for Trending tab, stars, icons
  static const Color goldStar = Color(0xFFFFC14C); // For rating stars
  static const Color orange = Color.fromARGB(
    255,
    238,
    112,
    67,
  ); // Orange for Trending tab, stars, icons

  // 🟣 Selected Chip / Tab
  static const Color selectedChipPurple = Color(
    0xFF6B2ED3,
  ); // Bright purple for active chips

  // ⚪ Whites and Text Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color white90 = Color.fromRGBO(255, 255, 255, 0.9);
  static const Color white70 = Color.fromRGBO(255, 255, 255, 0.7);
  static const Color white60 = Color.fromRGBO(255, 255, 255, 0.6);
  static const Color white24 = Color.fromRGBO(255, 255, 255, 0.24);

  // 🔍 Search Bar
  static const Color searchFill = Color(0xFF2A1B3E);
  static const Color searchBorder = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color searchIcon = Color(0xFFBFC9E8);
  static const Color searchHint = Color(0xFF9CA3AF);

  // 🏷️ Tabs
  static const Color tabSelectedBg = accentOrange;
  static const Color tabSelectedText = white;
  static const Color tabUnselectedBg = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color tabUnselectedText = Color(0xFFE6E7F1);

  // 🟣 Language Chips
  static const Color chipSelectedBg = white;
  static const Color chipSelectedText = Colors.black;
  static const Color chipUnselectedBg = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color chipUnselectedText = Color(0xFFE6E7F1);

  // 🎬 Trending Movie Card Overlay
  static const Gradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.fromRGBO(0, 0, 0, 0.24), Color.fromRGBO(0, 0, 0, 0.72)],
  );
  static const Color cardTitle = white;
  static const Color cardDescription = Color(0xFFCAD5F8);
  static const Color cardMetaBg = Color.fromRGBO(0, 0, 0, 0.7);
  static const Color cardMetaText = white;
  static const Color cardStar = goldStar;

  // 🧭 Navigation Bar
  static const Color bottomNav = Color(0xFF18172F);
  static const Color bottomNavActive = accentOrange;
  static const Color bottomNavInactive = Color(0xFFBDB8D8);
  static const Color blueDistance = Color(
    0xFF357DE0,
  ); // Soft blue for distance pill

  // 🧭 Filter Icon
  static const Color filterIcon = Color(0xFFDAD6F3); // Soft lavender-white tone
  static const Gradient filterGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 151, 109, 247), // vibrant purple (left)
      Color.fromARGB(255, 80, 142, 241), // bright blue (right)
      Color.fromARGB(255, 109, 111, 241), // indigo (mid)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: const [0.0, 0.5, 1.0],
  );

  // ⚙️ Utility
  static const Color borderWhite10 = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color smallCardOverlay = Color.fromRGBO(0, 0, 0, 0.18);

  // 🟢 Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = accentOrange;

  // 🎨 AppBar Title Gradient
  static const Gradient appBarTitleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color.fromARGB(255, 161, 121, 255), // Soft violet (right)
      Color.fromARGB(255, 95, 113, 231), // Mid purple-blue
      Color.fromARGB(255, 115, 51, 243), // Bright blue (left)
    ],
  );
  static const Gradient appBarTickGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFFC53D), // golden yellow
      Color(0xFFFFAA2A), // mid orange
      Color(0xFFFF8B1A), // deep orange
    ],
  );

  static const Color appBarIcon = Color(0xFFDAD6F3);

  static const Color dateSelectedBg = Color(0xFF7F9DFF);
  // 📅 Selected Date Gradient (for active day chip)
  static const Gradient dateSelectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF7F9DFF), // sky blue (left)
      Color(0xFF9D7FFF), // violet-blue (right)
    ],
  );
  static const Color dateSelectedBorder = Color(0xFF79BCFF);
}
