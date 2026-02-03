import 'package:cinematick/views/cinema/cinema_screen.dart';
import 'package:cinematick/views/tick/tick_screen.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/app_colors.dart';
import '../home/home_screen.dart';
import '../show_time_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BottomNavScreen extends ConsumerWidget {
  const BottomNavScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final selectedChain = ref.watch(selectedCinemaChainProvider);
    final selectedLocation = ref.watch(selectedCinemaLocationProvider);
    final selectedMovie = ref.watch(selectedMovieTitleProvider);

    final List<Widget> pages = <Widget>[
      const HomeScreenContent(),
      _buildCinemaPage(
        context,
        ref,
        selectedChain,
        selectedLocation,
        selectedMovie,
      ),
      const TickScreen(tmdbId: '83533'),
      const Center(
        child: Text('Profile', style: TextStyle(color: AppColors.bottomNav)),
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (selectedChain != null || selectedLocation != null) {
          ref.read(selectedCinemaChainProvider.notifier).state = null;
          ref.read(selectedCinemaLocationProvider.notifier).state = null;
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
          child: IndexedStack(index: selectedIndex, children: pages),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: selectedIndex,
          onTap: (i) {
            // Close any open modals using the navigator key
            if (navigatorKey.currentState != null) {
              while (navigatorKey.currentState!.canPop()) {
                navigatorKey.currentState!.pop();
              }
            }

            ref.read(bottomNavIndexProvider.notifier).state = i;
            if (i != 1) {
              ref.read(selectedCinemaChainProvider.notifier).state = null;
              ref.read(selectedCinemaLocationProvider.notifier).state = null;
              ref.read(selectedMovieTitleProvider.notifier).state = null;
            }
          },
        ),
      ),
    );
  }

  Widget _buildCinemaPage(
    BuildContext context,
    WidgetRef ref,
    dynamic selectedChain,
    dynamic selectedLocation,
    String? selectedMovie,
  ) {
    final selectedRegion = ref.watch(selectedRegionProvider);

    if (selectedMovie != null) {
      return ShowTimeScreen(
        movie: {
          'title': selectedMovie,
          'backdrop': 'https://picsum.photos/800/500?blur=3',
        },
        onBackPressed: () {
          ref.read(selectedMovieTitleProvider.notifier).state = null;
        },
        tmdbId: '',
        location: selectedRegion,
      );
    } else {
      return CinemaScreen(
        onChainSelected: (name, chainId, count) {
          ref.read(selectedCinemaChainProvider.notifier).state = (
            name: name,
            id: chainId,
            count: count,
          );
        },
        location: selectedRegion,
      );
    }
  }
}
