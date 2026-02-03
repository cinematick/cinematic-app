import 'package:cinematick/providers/navigation_providers.dart';
import 'package:cinematick/views/show_time_screen.dart';
import 'package:cinematick/views/cinema/cinema_detail_screen.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:cinematick/widgets/region_selector.dart';
import 'package:cinematick/widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../widgets/app_colors.dart';
import 'package:cinematick/config/secrets.dart';
import 'home_controller.dart';
import 'home_screen_widgets.dart';

class HomeScreenContent extends ConsumerStatefulWidget {
  const HomeScreenContent({super.key});

  @override
  ConsumerState<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<HomeScreenContent> {
  late HomeScreenController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _searchBarKey = GlobalKey();

  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  String _selectedRegion = 'NSW';

  @override
  void initState() {
    super.initState();
    _controller = HomeScreenController(onStateChange: _onStateChange);
    _controller.initialize();
    _loadCachedLocation();
  }

  Future<void> _loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLocation = prefs.getString('selected_region') ?? 'NSW';
      setState(() {
        _selectedRegion = cachedLocation;
      });
    } catch (e) {
      print('Error loading cached location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (previous != null && previous != 0 && next == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            (_searchBarKey.currentState as dynamic)?.clearSearchBar();
            _resetSearchState();
          }
        });
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawer: _buildDrawer(),
      backgroundColor: const Color(0xFF2B1967),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [_buildBody(), if (_isSearching) _buildSearchOverlay()],
        ),
      ),
    );
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetSearchState() {
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
        _searchResults = [];
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _searchResults = [];
      } else {
        final suggestions = <Map<String, dynamic>>[];
        final seenKeys = <String>{};

        for (var movie in _controller.trendingMovies) {
          final title = (movie['title'] ?? '').toString().toLowerCase();

          if (title.isNotEmpty && title.contains(_searchQuery)) {
            final key = 'movie_${movie['title']}';
            if (!seenKeys.contains(key)) {
              suggestions.add({
                'type': 'movie',
                'title': movie['title'],
                'year': movie['year'] ?? '',
                'rating': movie['rating'] ?? 'N/A',
                'posterPath': movie['posterPath'] ?? movie['image'] ?? '',
                'tmdbId': movie['tmdbId'] ?? movie['id'] ?? '',
                'icon': Icons.movie,
              });
              seenKeys.add(key);
            }
          }
        }

        _searchCinemas(query, suggestions, seenKeys);

        _searchResults = suggestions;
      }
    });
  }

  Future<void> _searchCinemas(
    String query,
    List<Map<String, dynamic>> suggestions,
    Set<String> seenKeys,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/cinemas/search?query=$query&region=$_selectedRegion',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cinemas = (data as List?)?.cast<Map<String, dynamic>>() ?? [];
        final queryLower = query.toLowerCase();

        for (var cinema in cinemas) {
          final cinemaName = (cinema['cinema_name'] ?? '').toString();
          final cinemaCity = (cinema['cinema_city'] ?? '').toString();
          final cinemaCityLower = cinemaCity.toLowerCase();
          final key = 'cinema_$cinemaCity';

          if (cinemaCityLower.isNotEmpty &&
              cinemaCityLower.contains(queryLower)) {
            if (!seenKeys.contains(key)) {
              suggestions.add({
                'type': 'cinema',
                'name': cinemaName,
                'city': cinemaCity,
                'address': cinema['cinema_state'] ?? '',
                'id': cinema['cinema_id'] ?? '',
                'icon': Icons.location_on,
              });
              seenKeys.add(key);
            }
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = suggestions;
          });
        }
      }
    } catch (e) {
      print('Error searching cinemas: $e');
    }
  }

  Widget _buildSearchOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              _resetSearchState();
            },
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: SearchBarWidget(
                key: _searchBarKey,
                hint: _controller.getHintText(),
                onSearch: _performSearch,
                onClear: () {
                  _resetSearchState();
                },
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Positioned(
              top: 130,
              left: 16,
              right: 16,
              child: _buildSearchSuggestionsBox(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestionsBox() {
    if (_searchResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _searchResults.length,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          final isLast = index == _searchResults.length - 1;
          final isMovie = result['type'] == 'movie';

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isMovie) {
                  _openShowTime(result);
                } else {
                  _navigateToCinemaDetail(result);
                }
                _resetSearchState();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border:
                      !isLast
                          ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          )
                          : null,
                ),
                child: Row(
                  children: [
                    if (isMovie)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 40,
                          height: 50,
                          color: Colors.black26,
                          child:
                              (result['posterPath'] ?? '').toString().isNotEmpty
                                  ? Image.network(
                                    result['posterPath'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Center(
                                          child: Icon(
                                            Icons.movie,
                                            color: Colors.white24,
                                            size: 20,
                                          ),
                                        ),
                                  )
                                  : const Center(
                                    child: Icon(
                                      Icons.movie,
                                      color: Colors.white24,
                                      size: 20,
                                    ),
                                  ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64B5F6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF64B5F6),
                          size: 16,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMovie
                                ? (result['title'] ?? 'Unknown')
                                : (result['name'] ?? 'Unknown'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (isMovie)
                            Row(
                              children: [
                                if ((result['year'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    result['year'].toString(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                if ((result['year'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  const SizedBox(width: 8),
                                Icon(
                                  Icons.star_border_rounded,
                                  size: 11,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  result['rating']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              result['city'] ?? 'Unknown Location',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.trendingMovies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null &&
        _controller.trendingMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white30, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Check your connectivity',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.fetchMovies,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        CustomAppBar(
          onLocationTap: _showRegionSelector,
          onSearchTap: _isSearching ? null : _focusSearchBar,
          onCloseTap:
              _isSearching
                  ? () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchResults = [];
                    });
                    (_searchBarKey.currentState as dynamic)?.clearSearchBar();
                  }
                  : null,
        ),
        _buildTabs(),
        _buildLanguageFilter(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 0, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            HomeScreenWidgets.tabChip(
              'Trending',
              0,
              Icons.local_fire_department,
              _controller.tabIndex,
              () => setState(() => _controller.setTabIndex(0)),
            ),
            HomeScreenWidgets.tabChip(
              'Now Playing',
              1,
              Icons.local_movies_outlined,
              _controller.tabIndex,
              () => setState(() => _controller.setTabIndex(1)),
            ),
            HomeScreenWidgets.tabChip(
              'Coming Soon',
              2,
              Icons.schedule,
              _controller.tabIndex,
              () => setState(() => _controller.setTabIndex(2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageFilter() {
    final displayLanguages = [
      'English',
      'Hindi',
      'Telugu',
      'Tamil',
      'Kannada',
      'Malayalam',
      'Punjabi',
      'Mandarin',
      'Korean',
      'Italian',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 0, 4),
      child: SizedBox(
        height: 28,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: displayLanguages.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: HomeScreenWidgets.filterButton(),
                ),
              );
            }

            if (i == 1) {
              final anyLanguageSelected = _controller.langSelected.contains(
                true,
              );
              final allSelected = !anyLanguageSelected;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      for (
                        var j = 0;
                        j < _controller.langSelected.length;
                        j++
                      ) {
                        _controller.langSelected[j] = false;
                      }
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color:
                          allSelected
                              ? AppColors.chipSelectedBg
                              : AppColors.chipUnselectedBg,
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        height: 1,
                        color:
                            allSelected
                                ? AppColors.chipSelectedText
                                : AppColors.chipUnselectedText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }

            final langIdx = i - 2;
            final displayLanguage = displayLanguages[langIdx];

            // Find the index of this language in the full langList
            final fullLangIdx = _controller.langList.indexOf(displayLanguage);
            final selected =
                fullLangIdx >= 0
                    ? _controller.langSelected[fullLangIdx]
                    : false;

            final capitalizedLanguage =
                displayLanguage[0].toUpperCase() + displayLanguage.substring(1);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (fullLangIdx >= 0) {
                    setState(() => _controller.toggleChip(fullLangIdx));
                  }
                },
                child: HomeScreenWidgets.languageChip(
                  capitalizedLanguage,
                  selected,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          double paddingH;
          double paddingV;

          if (screenWidth > 1200) {
            paddingH = 24;
            paddingV = 4;
          } else if (screenWidth > 800) {
            paddingH = 16;
            paddingV = 3;
          } else {
            paddingH = 8;
            paddingV = 3;
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: paddingV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_controller.tabIndex == -1) ...[
                  const SizedBox(height: 6),
                  HomeScreenWidgets.sectionHeader(
                    'Trending',
                    Icons.local_fire_department,
                    onButtonPressed: _navigateToTickScreen,
                  ),
                  const SizedBox(height: 6),
                  HomeScreenWidgets.buildTrendingCarouselOrList(
                    context,
                    _controller,
                    (page) => setState(() => _controller.setTrendingPage(page)),
                    _openShowTime,
                  ),
                  const SizedBox(height: 6),
                  HomeScreenWidgets.buildTrendingIndicators(_controller),
                  const SizedBox(height: 12),
                  HomeScreenWidgets.sectionHeader(
                    'Now Playing',
                    Icons.local_movies_outlined,
                  ),
                  HomeScreenWidgets.buildGenericMovieGrid(
                    _controller.filteredNowPlayingMovies,
                    _openShowTime,
                    errorMessage: _controller.errorMessage,
                  ),
                  const SizedBox(height: 12),
                  HomeScreenWidgets.sectionHeader(
                    'Coming Soon',
                    Icons.schedule,
                  ),
                  HomeScreenWidgets.buildGenericMovieGrid(
                    _controller.filteredComingSoonMovies,
                    _openShowTime,
                    errorMessage: _controller.errorMessage,
                  ),
                  const SizedBox(height: 8),
                ] else if (_controller.tabIndex == 0) ...[
                  const SizedBox(height: 12),
                  HomeScreenWidgets.sectionHeader(
                    'Trending',
                    Icons.local_fire_department,
                  ),
                  const SizedBox(height: 4),
                  HomeScreenWidgets.buildGenericMovieGrid(
                    _controller.filteredTrendingMoviesSortedByRating,
                    _openShowTime,
                    errorMessage: _controller.errorMessage,
                  ),
                  const SizedBox(height: 8),
                ] else if (_controller.tabIndex == 1) ...[
                  const SizedBox(height: 12),
                  HomeScreenWidgets.sectionHeader(
                    'Now Playing',
                    Icons.local_movies_outlined,
                  ),
                  const SizedBox(height: 4),
                  HomeScreenWidgets.buildGenericMovieGrid(
                    _controller.filteredNowPlayingMovies,
                    _openShowTime,
                    errorMessage: _controller.errorMessage,
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 12),
                  HomeScreenWidgets.sectionHeader(
                    'Coming Soon',
                    Icons.schedule,
                  ),
                  const SizedBox(height: 4),
                  HomeScreenWidgets.buildGenericMovieGrid(
                    _controller.filteredComingSoonMovies,
                    _openShowTime,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: GestureDetector(
        onTap: () {},
        child: FilterSheetWidget(
          allLanguages: _controller.langList,
          allExperiences: HomeScreenController.allExperiences,
          allGenres: _controller.genreList,
          langSelected: _controller.langSelected,
          xpSelected: _controller.xpSelected,
          genreSelected: _controller.genreSelected,
          onApply: () {
            setState(() {
              _controller.syncChipFromDrawer();
              _controller.setTrendingPage(0);
            });
            Navigator.of(context).maybePop();
          },
          onClear: () {
            setState(() {
              for (var i = 0; i < _controller.langSelected.length; i++) {
                _controller.langSelected[i] = false;
              }
              for (var i = 0; i < _controller.xpSelected.length; i++) {
                _controller.xpSelected[i] = false;
              }
              for (var i = 0; i < _controller.genreSelected.length; i++) {
                _controller.genreSelected[i] = false;
              }
              _controller.selectedLangIndex = -1;
              _controller.setTrendingPage(0);
            });
          },
        ),
      ),
    );
  }

  void _openShowTime(Map<String, dynamic> movie) {
    final safe = Map<String, String>.fromEntries(
      movie.entries.map((e) => MapEntry(e.key, e.value?.toString() ?? '')),
    );

    final backdropPath =
        (movie['backdropPath']?.toString().isNotEmpty == true
                        ? movie['backdropPath']
                        : movie['backdrop'])
                    ?.toString()
                    .isNotEmpty ==
                true
            ? movie['backdropPath'] ?? movie['backdrop']
            : movie['image']?.toString().isNotEmpty == true
            ? movie['image']
            : movie['posterPath'] ?? '';

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (_) => ShowTimeScreen(
                  movie: safe,
                  tmdbId: movie['tmdbId']?.toString() ?? '',
                  backdropPath: backdropPath.toString(),
                  location: _selectedRegion,
                ),
          ),
        )
        .then((_) {
          // Clear search bar when returning from ShowTimeScreen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              (_searchBarKey.currentState as dynamic)?.clearSearchBar();
              _resetSearchState();
            }
          });
        });
  }

  void _navigateToCinemaDetail(Map<String, dynamic> cinema) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (_) => CinemaDetailScreen(
                  tmdbId: '',
                  cinemaId: cinema['id']?.toString() ?? '',
                  cinemaCity: cinema['city']?.toString() ?? '',
                ),
          ),
        )
        .then((_) {
          // Clear search bar when returning
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              (_searchBarKey.currentState as dynamic)?.clearSearchBar();
              _resetSearchState();
            }
          });
        });
  }

  void _navigateToTickScreen() {
    ref.read(bottomNavIndexProvider.notifier).state = 2;
  }

  void _showRegionSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => RegionSelector(
            selectedRegion: _selectedRegion,
            onRegionSelected: (region) {
              setState(() {
                _selectedRegion = region;
              });
              // Save to cache
              _saveLocationToCache(region);
              // Update the Riverpod provider
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedRegionProvider.notifier).state = region;
              });
              // Refetch movies, languages, and genres for the selected region
              _controller.fetchMovies(region: region);
              _controller.fetchLanguages(region: region);
              _controller.fetchGenres(region: region);
            },
          ),
    );
  }

  void _focusSearchBar() {
    // Show search overlay when the icon is tapped
    setState(() {
      _isSearching = true;
    });
    // Focus on the search bar after the overlay is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        (_searchBarKey.currentState as dynamic)?.focusSearchBar();
      }
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FilterSheetWidget(
            allLanguages: _controller.langList,
            allExperiences: HomeScreenController.allExperiences,
            allGenres: _controller.genreList,
            langSelected: _controller.langSelected,
            xpSelected: _controller.xpSelected,
            genreSelected: _controller.genreSelected,
            onApply: () {
              setState(() {
                _controller.syncChipFromDrawer();
                _controller.setTrendingPage(0);
              });
              Navigator.of(context).maybePop();
            },
            onClear: () {
              setState(() {
                for (var i = 0; i < _controller.langSelected.length; i++) {
                  _controller.langSelected[i] = false;
                }
                for (var i = 0; i < _controller.xpSelected.length; i++) {
                  _controller.xpSelected[i] = false;
                }
                for (var i = 0; i < _controller.genreSelected.length; i++) {
                  _controller.genreSelected[i] = false;
                }
                _controller.selectedLangIndex = -1;
                _controller.setTrendingPage(0);
              });
            },
          ),
    );
  }

  Future<void> _saveLocationToCache(String location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_region', location);
    } catch (e) {
      print('Error saving location to cache: $e');
    }
  }
}
