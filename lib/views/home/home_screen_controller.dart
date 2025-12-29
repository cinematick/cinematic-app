import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cinematick/core/services/api_service.dart';
import '../../widgets/movie_filter_service.dart';

class HomeScreenController {
  late ApiService _apiService;
  late MovieFilterService _filterService;

  int tabIndex = -1;
  int trendingPage = 0;
  int selectedLangIndex = 0;
  int _hintIndex = 0;

  List<Map<String, dynamic>> trendingMovies = [];
  List<Map<String, dynamic>> upcomingMovies = [];
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
    'Italian',
    'Mandarin',
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
    'Search movies, search cinemas, find cheapest movie, find nearest cinemas',
    'For cheapest movie take them to tick page with cheapest kpi active',
    'For nearest cinemas take them to tick page nearest kpi active',
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
    _apiService = ApiService();
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
      trendingMovies = await _apiService.fetchMovies();
      upcomingMovies = await _apiService.fetchUpcomingMovies();
      for (var movie in upcomingMovies) {
        movie['status'] = 'Upcoming';
      }
    } catch (err) {
      errorMessage = 'Failed to load movies: $err';
      trendingMovies = [];
      upcomingMovies = [];
    } finally {
      isLoading = false;
    }
    onStateChange?.call();
  }

  List<Map<String, dynamic>> get filteredTrendingMovies => _filterService
      .filterMovies(trendingMovies, langSelected, genreSelected, 'Released');

  List<Map<String, dynamic>> get filteredTrendingMoviesSortedByRating {
    final movies = filteredTrendingMovies;
    final sorted = List<Map<String, dynamic>>.from(movies);
    sorted.sort((a, b) {
      final ratingA = double.tryParse((a['rating'] ?? '0').toString()) ?? 0;
      final ratingB = double.tryParse((b['rating'] ?? '0').toString()) ?? 0;
      return ratingB.compareTo(ratingA);
    });
    return sorted;
  }

  List<Map<String, dynamic>> get filteredNowPlayingMovies => _filterService
      .filterMovies(trendingMovies, langSelected, genreSelected, 'Released');

  List<Map<String, dynamic>> get filteredComingSoonMovies => _filterService
      .filterMovies(upcomingMovies, langSelected, genreSelected, 'Upcoming');

  List<Map<String, dynamic>> get trendingTop10 =>
      _filterService.sortAndLimitTrendingMovies(filteredTrendingMovies, 10);

  void toggleChip(int index) {
    if (selectedLangIndex == -1) {
      selectedLangIndex = index;
      for (int i = 0; i < langSelected.length; i++) {
        langSelected[i] = (i == index);
      }
    } else if (selectedLangIndex == index) {
      selectedLangIndex = -1;
      for (int i = 0; i < langSelected.length; i++) {
        langSelected[i] = false;
      }
    } else {
      selectedLangIndex = index;
      for (int i = 0; i < langSelected.length; i++) {
        langSelected[i] = (i == index);
      }
    }
    onStateChange?.call();
  }

  void syncChipFromDrawer() {
    if (langSelected.contains(true)) {
      final first = langSelected.indexWhere((e) => e);
      if (first != -1) selectedLangIndex = first;
    }
  }

  void setTabIndex(int index) {
    if (tabIndex == index) {
      tabIndex = -1;
    } else {
      tabIndex = index;
    }
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
