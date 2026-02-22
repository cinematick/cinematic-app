import 'dart:async';
import 'package:cinematick/repositories/cinema_repository.dart';
import 'package:cinematick/config/secrets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/movie_filter_service.dart';

class HomeScreenController {
  late final CinemaRepository _movieRepository;
  late final MovieFilterService _filterService;

  int tabIndex = 0;
  int trendingPage = 0;
  int selectedLangIndex = 0;
  int _hintIndex = 0;
  String currentRegion = 'NSW';

  List<Map<String, dynamic>> trendingMovies = [];
  List<Map<String, dynamic>> upcomingMovies = [];
  List<String> langList = [];
  List<String> genreList = [];
  bool _isLoadingLanguages = true;

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
    'Mandarin',
    'Korean',
    'Italian',
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
    'Search movies...',
    'Search cinemas...',
    'Find nearest cinemas...',
    'Find cheapest tickets...',
  ];

  final VoidCallback? onStateChange;

  HomeScreenController({this.onStateChange}) {
    _movieRepository = CinemaRepository();
    _filterService = MovieFilterService();
    _initializeFilters();
  }

  void _initializeFilters() {
    langList = allLanguages;
    genreList = allGenres;
    langSelected = List<bool>.filled(langList.length, false);
    xpSelected = List<bool>.filled(allExperiences.length, false);
    genreSelected = List<bool>.filled(genreList.length, false);
  }

  void initialize() {
    trendingController = PageController(
      viewportFraction: 0.93,
      initialPage: trendingPage,
    );
    fetchMovies();
    fetchLanguages();
    fetchGenres();
    _startAutoScroll();
    _startHintCycle();
  }

  Future<void> fetchLanguages({String? region}) async {
    final finalRegion = region ?? currentRegion;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movies/region/list?region=$finalRegion'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List?;
        final movies = data?.cast<Map<String, dynamic>>() ?? [];

        final languageSet = <String>{};
        for (var movie in movies) {
          final languages = (movie['language'] as List?)?.cast<String>() ?? [];
          languageSet.addAll(languages);
        }

        final fetchedLanguages = languageSet.toList();

        for (int i = 0; i < fetchedLanguages.length; i++) {
          print('  ${i + 1}. ${fetchedLanguages[i]}');
        }

        langList =
            fetchedLanguages
                .map((lang) => lang[0].toUpperCase() + lang.substring(1))
                .toList();

        if (langList.isEmpty) {
          langList = allLanguages;
        }

        langSelected = List<bool>.filled(langList.length, false);
        _isLoadingLanguages = false;
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      langList = allLanguages;
      langSelected = List<bool>.filled(allLanguages.length, false);
      _isLoadingLanguages = false;
    }
    onStateChange?.call();
  }

  Future<void> fetchGenres({String? region}) async {
    final finalRegion = region ?? currentRegion;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movies/region/list?region=$finalRegion'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List?;
        final movies = data?.cast<Map<String, dynamic>>() ?? [];

        final genreSet = <String>{};
        for (var movie in movies) {
          final genres = (movie['genres'] as List?)?.cast<String>() ?? [];
          genreSet.addAll(genres);
        }

        final fetchedGenres = genreSet.toList();

        for (int i = 0; i < fetchedGenres.length; i++) {
          print('  ${i + 1}. ${fetchedGenres[i]}');
        }

        genreList = fetchedGenres;
        if (genreList.isEmpty) {
          genreList = allGenres;
        }

        genreSelected = List<bool>.filled(genreList.length, false);
      } else {
        throw Exception('Failed to load genres');
      }
    } catch (e) {
      print('Error fetching genres (home): $e');
      genreList = allGenres;
      genreSelected = List<bool>.filled(allGenres.length, false);
    }
    onStateChange?.call();
  }

  Future<void> fetchMovies({String? region, String? language}) async {
    if (region != null) {
      currentRegion = region;
    }
    isLoading = true;
    errorMessage = null;

    try {
      trendingMovies = await _movieRepository.getMovies(
        region: currentRegion,
        language: language,
      );

      upcomingMovies = await _movieRepository.getUpcomingMovies(
        region: currentRegion,
        language: language,
      );

      for (var movie in upcomingMovies) {
        movie['status'] = 'Upcoming';
      }
    } catch (err) {
      errorMessage = 'Failed to load movies';
      trendingMovies = [];
      upcomingMovies = [];
    } finally {
      isLoading = false;
    }

    onStateChange?.call();
  }

  List<Map<String, dynamic>> get filteredTrendingMovies {
    final filtered = _filterService.filterMovies(
      trendingMovies,
      langSelected,
      genreSelected,
      'Released',
      langList: langList,
    );
    return filtered.where((movie) {
      final regions = movie['regions'] as List?;
      if (regions == null || regions.isEmpty) return true;
      return regions.contains(currentRegion);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredTrendingMoviesSortedByRating {
    final sorted = List<Map<String, dynamic>>.from(filteredTrendingMovies);
    sorted.sort((a, b) {
      final ra = double.tryParse((a['rating'] ?? '0').toString()) ?? 0;
      final rb = double.tryParse((b['rating'] ?? '0').toString()) ?? 0;
      return rb.compareTo(ra);
    });
    return sorted;
  }

  List<Map<String, dynamic>> get filteredNowPlayingMovies =>
      _filterService.filterMovies(
        trendingMovies,
        langSelected,
        genreSelected,
        'Released',
        langList: langList,
      );

  List<Map<String, dynamic>> get filteredComingSoonMovies =>
      _filterService.filterMovies(
        upcomingMovies,
        langSelected,
        genreSelected,
        'Upcoming',
        langList: langList,
      );

  List<Map<String, dynamic>> get trendingTop10 =>
      _filterService.sortAndLimitTrendingMovies(trendingMovies, 5);

  void toggleChip(int index) {
    if (index >= langList.length) return;

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

    String? selectedLanguageCode;
    if (selectedLangIndex >= 0 && selectedLangIndex < langList.length) {
      final languageName = langList[selectedLangIndex];
      selectedLanguageCode = _languageNameToCode(languageName);
    }
    fetchMovies(region: currentRegion, language: selectedLanguageCode);
  }

  String _languageNameToCode(String languageName) {
    const Map<String, String> langNameToCode = {
      'english': 'en',
      'hindi': 'hi',
      'telugu': 'te',
      'tamil': 'ta',
      'kannada': 'kn',
      'malayalam': 'ml',
      'punjabi': 'pa',
      'korean': 'ko',
      'italian': 'it',
      'mandarin': 'zh',
    };

    final normalized = languageName.toLowerCase().trim();
    return langNameToCode[normalized] ?? normalized;
  }

  void syncChipFromDrawer() {
    if (langSelected.contains(true)) {
      selectedLangIndex = langSelected.indexWhere((e) => e);
    }
  }

  void setTabIndex(int index) {
    if (tabIndex != index) {
      tabIndex = index;
    }
    onStateChange?.call();
  }

  void setTrendingPage(int page) {
    trendingPage = page;
  }

  String getHintText() => searchHints[_hintIndex];

  void _startAutoScroll() {
    autoScrollTimer?.cancel();
    autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final movies = trendingTop10;
      if (movies.length <= 1) return;
      if (trendingController == null || !trendingController!.hasClients) return;

      final nextPage = (trendingPage + 1) % movies.length;

      trendingController!.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );

      trendingPage = nextPage;
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
    hintTimer?.cancel();
    trendingController?.dispose();
  }
}
