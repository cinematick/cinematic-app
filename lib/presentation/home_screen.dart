import 'dart:async';
import 'dart:convert';
import 'package:cinematick/presentation/show_time_screen.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:cinematick/widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_colors.dart';
import 'home_screen_controller.dart';
import 'home_screen_widgets.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late HomeScreenController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _controller = HomeScreenController(onStateChange: _onStateChange);
    _controller.initialize();
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _searchResults = [];
        _isSearching = false;
      } else {
        _isSearching = true;
        _searchResults =
            _controller.trendingMovies.where((movie) {
              final title = (movie['title'] ?? '').toString().toLowerCase();
              return title.contains(_searchQuery);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _searchQuery = '';
                _searchResults = [];
                _isSearching = false;
              });
            },
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          Positioned(
            top: 140,
            left: 16,
            right: 16,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 450),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 1, 14, 44),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child:
                  _searchResults.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search,
                              size: 48,
                              color: Colors.white30,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No movies found for "$_searchQuery"',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final movie = _searchResults[index];
                            return _buildSearchResultItem(movie);
                          },
                        ),
                      ),
            ),
          ),
        ],
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
            Text(
              _controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
        CustomAppBar(),
        _buildSearchBar(),
        _buildTabs(),
        _buildLanguageFilter(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBarWidget(
        hint: _controller.getHintText(),
        onSearch: _performSearch,
        onClear: () {
          setState(() {
            _searchQuery = '';
            _searchResults = [];
            _isSearching = false;
          });
        },
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> movie) {
    final title = movie['title'] ?? 'Unknown';
    final year = movie['year'] ?? '';
    final rating = movie['rating'] ?? '0';
    final posterPath = movie['posterPath'] ?? movie['image'] ?? '';

    return GestureDetector(
      onTap: () => _openShowTime(movie),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 110,
                color: Colors.black26,
                child:
                    posterPath.isNotEmpty
                        ? Image.network(
                          posterPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.movie,
                                color: Colors.white24,
                                size: 28,
                              ),
                            );
                          },
                        )
                        : const Center(
                          child: Icon(
                            Icons.movie,
                            color: Colors.white24,
                            size: 28,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (year.isNotEmpty)
                        Text(
                          year,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        size: 13,
                        color: Color(0xFFFFB64B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFB863D7).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                color: Color(0xFFB863D7),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 0, 7),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            HomeScreenWidgets.tabChip(
              'Trending',
              0,
              Icons.trending_up,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 0, 7),
      child: SizedBox(
        height: 34,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: HomeScreenController.langList.length + 1,
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
            final langIdx = i - 1;
            final anySelected = _controller.langSelected.contains(true);
            final selected =
                anySelected
                    ? _controller.langSelected[langIdx]
                    : (langIdx == _controller.selectedLangIndex);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _controller.toggleChip(langIdx)),
                child: HomeScreenWidgets.languageChip(
                  HomeScreenController.langList[langIdx],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.tabIndex == 0) ...[
              const SizedBox(height: 15),
              HomeScreenWidgets.sectionHeader(
                'Trending Movies',
                Icons.trending_up,
              ),
              const SizedBox(height: 18),
              HomeScreenWidgets.buildTrendingCarouselOrList(
                context,
                _controller,
                (page) {
                  setState(() => _controller.setTrendingPage(page));
                },
                _openShowTime,
              ),
              const SizedBox(height: 14),
              HomeScreenWidgets.buildTrendingIndicators(_controller),
              const SizedBox(height: 16),
              HomeScreenWidgets.sectionHeader(
                'Now Playing',
                Icons.local_movies_outlined,
              ),
              const SizedBox(height: 15),
              HomeScreenWidgets.buildGenericMovieGrid(
                _controller.filteredNowPlayingMovies,
                _openShowTime,
              ),
              const SizedBox(height: 14),
            ] else if (_controller.tabIndex == 1) ...[
              const SizedBox(height: 18),
              HomeScreenWidgets.sectionHeader(
                'Now Playing',
                Icons.local_movies_outlined,
              ),
              const SizedBox(height: 18),
              HomeScreenWidgets.buildGenericMovieGrid(
                _controller.filteredNowPlayingMovies,
                _openShowTime,
              ),
              const SizedBox(height: 14),
            ] else ...[
              const SizedBox(height: 18),
              HomeScreenWidgets.sectionHeader('Coming Soon', Icons.schedule),
              const SizedBox(height: 18),
              HomeScreenWidgets.buildGenericMovieGrid(
                _controller.filteredComingSoonMovies,
                _openShowTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: FilterSheetWidget(
        allLanguages: HomeScreenController.allLanguages,
        allExperiences: HomeScreenController.allExperiences,
        allGenres: HomeScreenController.allGenres,
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
            for (var i = 0; i < _controller.langSelected.length; i++)
              _controller.langSelected[i] = false;
            for (var i = 0; i < _controller.xpSelected.length; i++)
              _controller.xpSelected[i] = false;
            for (var i = 0; i < _controller.genreSelected.length; i++)
              _controller.genreSelected[i] = false;
            _controller.selectedLangIndex = 0;
            _controller.setTrendingPage(0);
          });
        },
      ),
    );
  }

  void _openShowTime(Map<String, dynamic> movie) {
    final safe = Map<String, String>.fromEntries(
      movie.entries.map((e) => MapEntry(e.key, e.value?.toString() ?? '')),
    );

    final backdropPath =
        (movie['backdropPath']?.toString().isNotEmpty == true
            ? movie['backdropPath']?.toString()
            : null) ??
        (movie['backdrop']?.toString().isNotEmpty == true
            ? movie['backdrop']?.toString()
            : null) ??
        (movie['image']?.toString().isNotEmpty == true
            ? movie['image']?.toString()
            : null) ??
        (movie['posterPath']?.toString().isNotEmpty == true
            ? movie['posterPath']?.toString()
            : null) ??
        '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ShowTimeScreen(
              movie: safe,
              tmdbId: movie['tmdbId']?.toString() ?? '',
              backdropPath: backdropPath,
            ),
      ),
    );
  }
}
