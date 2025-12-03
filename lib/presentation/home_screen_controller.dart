import 'dart:async';
import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import 'movie_filter_service.dart';

class HomeScreenController {
  late MovieService _movieService;
  late MovieFilterService _filterService;

  int tabIndex = 0;
  int trendingPage = 0;
  int selectedLangIndex = 0;
  int _hintIndex = 0;

  List<Map<String, dynamic>> trendingMovies = [];
  bool isLoading = false;
  String? errorMessage;

  List<bool> langSelected = [];
  List<bool> xpSelected = [];
  List<bool> genreSelected = [];

  PageController? trendingController;
  Timer? autoScrollTimer;
  Timer? hintTimer;

  static const List<String> allLanguages = [
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Korean',
    'Japanese',
  ];
  static const List<String> allExperiences = ['2D', '3D', 'IMAX', 'Dolby'];
  static const List<String> allGenres = [
    'Action',
    'Comedy',
    'Drama',
    'Sci-Fi',
    'Horror',
    'Romance',
    'Thriller',
  ];
  static const List<String> searchHints = [
    'Find premium theatres',
    'Search movies & shows',
    'Discover IMAX & 3D',
    'Browse by language',
  ];
  static const List<String> langList = [
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Malayalam',
  ];

  final VoidCallback? onStateChange;

  HomeScreenController({this.onStateChange}) {
    _movieService = MovieService();
    _filterService = MovieFilterService();
    _initializeFilters();
  }

  void _initializeFilters() {
    langSelected = List<bool>.filled(allLanguages.length, false);
    xpSelected = List<bool>.filled(allExperiences.length, false);
    genreSelected = List<bool>.filled(allGenres.length, false);
  }

  void initialize() {
    trendingController = PageController(
      viewportFraction: 0.93,
      initialPage: trendingPage,
    );
    fetchMovies();
    _startAutoScroll();
    _startHintCycle();
  }

  Future<void> fetchMovies() async {
    isLoading = true;
    errorMessage = null;

    try {
      trendingMovies = await _movieService.fetchMovies();
    } catch (err) {
      errorMessage = 'Failed to load movies: $err';
      trendingMovies = [];
    } finally {
      isLoading = false;
    }
  }

  List<Map<String, dynamic>> get filteredTrendingMovies => _filterService
      .filterMovies(trendingMovies, langSelected, genreSelected, 'Released');

  List<Map<String, dynamic>> get filteredNowPlayingMovies => _filterService
      .filterMovies(trendingMovies, langSelected, genreSelected, 'Released');

  List<Map<String, dynamic>> get filteredComingSoonMovies =>
      _filterService.filterMoviesByStatus(
        trendingMovies,
        langSelected,
        genreSelected,
        ['in production', 'post production', 'planned'],
      );

  List<Map<String, dynamic>> get trendingTop10 =>
      _filterService.sortAndLimitTrendingMovies(filteredTrendingMovies, 10);

  void toggleChip(int idx) {
    if (idx < 0 || idx >= langSelected.length) return;
    langSelected[idx] = !langSelected[idx];
    if (!langSelected.contains(true)) {
      selectedLangIndex = idx;
    } else if (!langSelected[selectedLangIndex]) {
      final first = langSelected.indexWhere((e) => e);
      if (first != -1) selectedLangIndex = first;
    }
    trendingPage = 0;
  }

  void syncChipFromDrawer() {
    if (langSelected.contains(true)) {
      final first = langSelected.indexWhere((e) => e);
      if (first != -1) selectedLangIndex = first;
    }
  }

  void setTabIndex(int index) {
    tabIndex = index;
  }

  void setTrendingPage(int page) {
    trendingPage = page;
  }

  String getHintText() => searchHints[_hintIndex % searchHints.length];

  void _startAutoScroll() {
    autoScrollTimer?.cancel();
    autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (trendingTop10.isEmpty || trendingTop10.length <= 1) return;
      if (trendingController == null || !trendingController!.hasClients) return;

      final nextPage = (trendingPage + 1) % trendingTop10.length;
      try {
        trendingController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
        trendingPage = nextPage;
      } catch (e) {}
    });
  }

  void _startHintCycle() {
    hintTimer?.cancel();
    hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _hintIndex = (_hintIndex + 1) % searchHints.length;
      onStateChange?.call();
    });
  }

  void dispose() {
    autoScrollTimer?.cancel();
    trendingController?.dispose();
    hintTimer?.cancel();
  }
}
