import 'package:cinematick/views/tick/sticky_header.dart';
import 'package:cinematick/views/tick/cinema_movie_tile.dart';
import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:cinematick/providers/timezone_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math' as math;
import 'tick_controller.dart';

class TickScreen extends ConsumerStatefulWidget {
  final Map<String, String>? movie;
  final String tmdbId;
  final VoidCallback? onBackPressed;
  final String? backdropPath;

  const TickScreen({
    super.key,
    this.movie,
    required this.tmdbId,
    this.onBackPressed,
    this.backdropPath,
  });

  @override
  ConsumerState<TickScreen> createState() => _TickScreenState();
}

class _TickScreenState extends ConsumerState<TickScreen> {
  late final FocusNode _searchFocusNode;
  late final TextEditingController _searchTextController;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchTextController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.unfocus();
      _searchTextController.clear();
      final controller = ref.read(tickControllerProvider.notifier);
      controller.closeSearchSuggestions();
      controller.resetPagination();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  bool _hasAnyFutureShowtime(Map<String, dynamic> movie, String region) {
    final showtimes =
        (movie['showtimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    for (var showtime in showtimes) {
      final timeStr = showtime['time']?.toString() ?? '';
      if (timeStr.isEmpty) continue;

      try {
        DateTime showTime = DateTime.parse(timeStr);
        if (!timeStr.contains('Z')) {
          showTime = showTime.toUtc();
        }

        final regionTimezoneMap = ref.read(
          availableAustralianTimezonesProvider,
        );
        final timezoneName = regionTimezoneMap[region] ?? 'Australia/Sydney';
        final location = tz.getLocation(timezoneName);

        final nowInRegion = tz.TZDateTime.from(
          DateTime.now().toUtc(),
          location,
        );
        final showtimeInRegion = tz.TZDateTime.from(showTime, location);

        final isPassed = showtimeInRegion.isBefore(nowInRegion);

        if (!isPassed) {
          return true;
        }
      } catch (e) {
        return true;
      }
    }
    return false;
  }

  List<Widget> _buildPageNumbers(
    int currentPage,
    int totalPages,
    TickController controller,
  ) {
    List<Widget> widgets = [];
    const maxVisible = 5;

    if (totalPages <= maxVisible) {
      for (int i = 0; i < totalPages; i++) {
        widgets.add(
          _PaginationButton(
            onPressed: () => controller.goToPage(i),
            label: '${i + 1}',
            isActive: i == currentPage,
          ),
        );
      }
    } else {
      widgets.add(
        _PaginationButton(
          onPressed: () => controller.goToPage(0),
          label: '1',
          isActive: currentPage == 0,
        ),
      );

      if (currentPage > 2) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('...', style: TextStyle(color: Colors.white70)),
          ),
        );
      }

      final start = math.max(1, currentPage - 1);
      final end = math.min(totalPages - 2, currentPage + 1);

      for (int i = start; i <= end; i++) {
        widgets.add(
          _PaginationButton(
            onPressed: () => controller.goToPage(i),
            label: '${i + 1}',
            isActive: i == currentPage,
          ),
        );
      }

      if (currentPage < totalPages - 3) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('...', style: TextStyle(color: Colors.white70)),
          ),
        );
      }

      widgets.add(
        _PaginationButton(
          onPressed: () => controller.goToPage(totalPages - 1),
          label: '$totalPages',
          isActive: currentPage == totalPages - 1,
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tickControllerProvider);
    final controller = ref.read(tickControllerProvider.notifier);
    final selectedRegion = ref.watch(selectedRegionProvider);

    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (next == 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.unfocus();
          _searchTextController.clear();
          controller.closeSearchSuggestions();
        });
      }
    });

    return Scaffold(
      drawerEnableOpenDragGesture: false,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: FilterSheetWidget(
          allLanguages: state.availableLanguages,
          allExperiences: controller.allExperiences,
          allGenres: controller.allGenres,
          langSelected: state.langSelected,
          xpSelected: state.xpSelected,
          genreSelected: state.genreSelected,
          onApply: () {
            Navigator.pop(context);
          },
          onClear: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: CustomAppBar()),
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyHeader(
                  state: state,
                  controller: controller,
                  searchFocusNode: _searchFocusNode,
                  searchTextController: _searchTextController,
                  selectedRegion: selectedRegion,
                ),
              ),
              if (state.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (state.errorMessage != null)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white30, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Check your connectivity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (controller.sortedMovies().isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_movies,
                            color: Colors.white30,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No showtimes available',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final allMovies = controller.sortedMovies();
                    final moviesWithFutureShowtimes =
                        allMovies
                            .where(
                              (movie) =>
                                  _hasAnyFutureShowtime(movie, selectedRegion),
                            )
                            .toList();

                    if (moviesWithFutureShowtimes.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_movies,
                                  color: Colors.white30,
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No showtimes available',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final totalPages =
                        (moviesWithFutureShowtimes.length / 50).ceil();
                    final startIndex = state.currentPage * 50;
                    final endIndex = math.min(
                      startIndex + 50,
                      moviesWithFutureShowtimes.length,
                    );

                    final paginatedMovies =
                        startIndex < moviesWithFutureShowtimes.length
                            ? moviesWithFutureShowtimes.sublist(
                              startIndex,
                              endIndex,
                            )
                            : [];

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < paginatedMovies.length) {
                            return CinemaMovieTile(
                              movie: paginatedMovies[index],
                              controller: controller,
                              region: selectedRegion,
                            );
                          }
                          if (index == paginatedMovies.length &&
                              totalPages > 1) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 24,
                              ),
                              child: Center(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _PaginationButton(
                                      onPressed:
                                          state.currentPage > 0
                                              ? () => controller.goToPage(0)
                                              : null,
                                      label: '«',
                                      isActive: false,
                                    ),
                                    _PaginationButton(
                                      onPressed:
                                          state.currentPage > 0
                                              ? () => controller.previousPage()
                                              : null,
                                      label: '<',
                                      isActive: false,
                                    ),
                                    ..._buildPageNumbers(
                                      state.currentPage,
                                      totalPages,
                                      controller,
                                    ),
                                    _PaginationButton(
                                      onPressed:
                                          state.currentPage < totalPages - 1
                                              ? () => controller.nextPage()
                                              : null,
                                      label: '>',
                                      isActive: false,
                                    ),
                                    _PaginationButton(
                                      onPressed:
                                          state.currentPage < totalPages - 1
                                              ? () => controller.goToPage(
                                                totalPages - 1,
                                              )
                                              : null,
                                      label: '»',
                                      isActive: false,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        childCount:
                            totalPages > 1
                                ? paginatedMovies.length + 1
                                : paginatedMovies.length,
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isActive;

  const _PaginationButton({
    this.onPressed,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF9500) : Colors.transparent,
          border:
              isActive
                  ? Border.all(color: const Color(0xFFFF9500), width: 2)
                  : Border.all(color: Colors.grey[700]!, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
