import 'package:cinematick/presentation/cinema_screen.dart';
import 'package:cinematick/presentation/cinema_locations_screen.dart';
import 'package:cinematick/presentation/cinema_showtimes_screen.dart';
import 'package:cinematick/presentation/tick_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/app_colors.dart';
import 'home_screen.dart';
import 'show_time_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;
  String? _selectedChainName;
  String? _selectedChainCount;
  String? _selectedLocationName;
  String? _selectedLocationAddress;
  String? _selectedMovieTitle;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const HomeScreen(),
      _buildCinemaPage(),
      const TickScreen(),
      const Center(
        child: Text('Profile', style: TextStyle(color: AppColors.bottomNav)),
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_selectedChainName != null || _selectedLocationName != null) {
          _goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A0A52), Color(0xFF0F0016)],
              stops: const [0.0, 1.0],
            ),
          ),
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _selectedIndex,
          onTap: (i) {
            setState(() {
              _selectedIndex = i;
              // Reset cinema navigation when switching tabs
              if (i != 1) {
                _selectedChainName = null;
                _selectedChainCount = null;
                _selectedLocationName = null;
                _selectedLocationAddress = null;
                _selectedMovieTitle = null;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildCinemaPage() {
    if (_selectedMovieTitle != null) {
      return ShowTimeScreen(
        movie: {
          'title': _selectedMovieTitle!,
          'backdrop': 'https://picsum.photos/800/500?blur=3',
        },
        onBackPressed: () {
          setState(() {
            _selectedMovieTitle = null;
          });
        },
      );
    } else if (_selectedLocationName != null &&
        _selectedLocationAddress != null) {
      return CinemaShowtimesScreen(
        locationName: _selectedLocationName!,
        locationAddress: _selectedLocationAddress!,
        onMovieSelected: (title) {
          setState(() {
            _selectedMovieTitle = title;
          });
        },
        onBackPressed: () {
          setState(() {
            _selectedLocationName = null;
            _selectedLocationAddress = null;
          });
        },
      );
    } else if (_selectedChainName != null && _selectedChainCount != null) {
      return CinemaLocationsScreen(
        chainName: _selectedChainName!,
        chainCount: _selectedChainCount!,
        onLocationSelected: (name, address) {
          setState(() {
            _selectedLocationName = name;
            _selectedLocationAddress = address;
          });
        },
        onBackPressed: () {
          setState(() {
            _selectedChainName = null;
            _selectedChainCount = null;
          });
        },
      );
    } else {
      return CinemaScreen(
        onChainSelected: (name, count) {
          setState(() {
            _selectedChainName = name;
            _selectedChainCount = count;
          });
        },
      );
    }
  }

  void _goBack() {
    setState(() {
      if (_selectedMovieTitle != null) {
        _selectedMovieTitle = null;
      } else if (_selectedLocationName != null) {
        _selectedLocationName = null;
        _selectedLocationAddress = null;
      } else if (_selectedChainName != null) {
        _selectedChainName = null;
        _selectedChainCount = null;
      }
    });
  }
}
