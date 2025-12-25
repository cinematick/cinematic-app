import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/widgets/custom_bottom_nav.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:cinematick/widgets/info_row_card.dart';
import 'package:cinematick/widgets/theatre_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:cinematick/views/show_time_screen.dart';

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
  int selectedDateIndex = 0;
  int selectedLangIndex = -1;
  int selectedInfoIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _movies = [];
  String? _errorMessage;
  List<Map<String, dynamic>> _generatedDates = [];
  List<String> _availableLanguages = [];
  String _searchQuery = '';
  Position? _userPosition;

  final List<String> _allExperiences = ['2D', '3D', 'IMAX', 'Dolby'];
  final List<String> _allGenres = [
    'Action',
    'Comedy',
    'Drama',
    'Sci‑Fi',
    'Horror',
    'Romance',
    'Thriller',
  ];
  List<bool> _langSelected = [];
  List<bool> _xpSelected = [];
  List<bool> _genreSelected = [];

  @override
  void initState() {
    super.initState();
    _xpSelected = List<bool>.filled(_allExperiences.length, false);
    _genreSelected = List<bool>.filled(_allGenres.length, false);
    _getUserLocation();
    _fetchMovies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
        });
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  Future<void> _fetchMovies() async {
    try {
      print('Fetching showtimes from /v1/tick endpoint');
      final response = await http.get(Uri.parse('baseUrl/tick'));

      print('API Response Status: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Decoded data length: ${data.length}');

        if (data.isEmpty) {
          setState(() {
            _movies = [];
            _availableLanguages = [];
            _langSelected = [];
            _generatedDates = _generateDates();
            _isLoading = false;
            _errorMessage = 'No movies available';
          });
          return;
        }

        setState(() {
          _movies = List<Map<String, dynamic>>.from(data);
          _availableLanguages = _extractAvailableLanguages();
          _langSelected = List<bool>.filled(_availableLanguages.length, false);
          _generatedDates = _generateDates();
          print('Loaded ${_movies.length} movies');
          print('Available languages: $_availableLanguages');
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Failed to load movies (Status: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateDates() {
    List<Map<String, dynamic>> dates = [];
    final now = DateTime.now();

    for (int i = 0; i < 6; i++) {
      final date = now.add(Duration(days: i));
      final dayName =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(date.weekday % 7)];
      final monthName =
          [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ][date.month - 1];

      dates.add({
        'label': dayName,
        'num': date.day.toString(),
        'month': monthName,
        'dateStr':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      });
    }
    return dates;
  }

  List<String> _extractAvailableLanguages() {
    final languageSet = <String>{};
    for (var movie in _movies) {
      final language = movie['language'] as String?;
      if (language != null && language.isNotEmpty) {
        languageSet.add(language);
      }
    }
    return languageSet.toList()..sort();
  }

  void _ensureFiltersReady() {
    if (_xpSelected.length != _allExperiences.length) {
      _xpSelected = List<bool>.filled(_allExperiences.length, false);
    }
    if (_genreSelected.length != _allGenres.length) {
      _genreSelected = List<bool>.filled(_allGenres.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mv = widget.movie;
    final selectedNavIndex = ref.watch(bottomNavIndexProvider);

    _ensureFiltersReady();
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: FilterSheetWidget(
          allLanguages: _availableLanguages,
          allExperiences: _allExperiences,
          allGenres: _allGenres,
          langSelected: _langSelected,
          xpSelected: _xpSelected,
          genreSelected: _genreSelected,
          onApply: () {
            Navigator.of(context).maybePop();
            setState(() {});
          },
          onClear: () {
            setState(() {
              for (var i = 0; i < _langSelected.length; i++)
                _langSelected[i] = false;
              for (var i = 0; i < _xpSelected.length; i++)
                _xpSelected[i] = false;
              for (var i = 0; i < _genreSelected.length; i++)
                _genreSelected[i] = false;
            });
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  title: widget.movie?['title'] ?? 'Movies',
                  rating: widget.movie?['vote_average'] ?? 'N/A',
                  generatedDates: _generatedDates,
                  selectedDateIndex: selectedDateIndex,
                  onDateSelected: (index) {
                    setState(() {
                      selectedDateIndex = index;
                    });
                  },
                  langList: _availableLanguages,
                  selectedLangIndex: selectedLangIndex,
                  onLangSelected: (index) {
                    setState(() {
                      selectedLangIndex = index;
                    });
                  },
                  onFilterTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  movies: _movies,
                  selectedInfoIndex: selectedInfoIndex,
                  onInfoIndexChanged: (index) {
                    setState(() {
                      selectedInfoIndex = index;
                    });
                  },
                  searchQuery: _searchQuery,
                  onSearchChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                  userPosition: _userPosition,
                  onCalculateDistance: _calculateDistance,
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_movies.isEmpty)
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
                            'No movies available',
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
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_generatedDates.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final safeIndex =
                          selectedDateIndex >= _generatedDates.length
                              ? 0
                              : selectedDateIndex;
                      final selectedDate =
                          _generatedDates[safeIndex]['dateStr'];
                      final selectedLanguage =
                          selectedLangIndex == -1 ||
                                  selectedLangIndex >=
                                      _availableLanguages.length
                              ? null
                              : _availableLanguages[selectedLangIndex];

                      // Filter and search
                      List<Map<String, dynamic>> filtered =
                          _movies.where((movie) {
                            if (selectedLanguage != null) {
                              final language =
                                  movie['language'] as String? ?? '';
                              if (!language.toLowerCase().contains(
                                selectedLanguage.toLowerCase(),
                              )) {
                                return false;
                              }
                            }

                            if (_searchQuery.isNotEmpty) {
                              final title =
                                  (movie['movieTitle'] as String? ?? '')
                                      .toLowerCase();
                              if (!title.contains(_searchQuery.toLowerCase())) {
                                return false;
                              }
                            }

                            return true;
                          }).toList();

                      // Sort based on selected info index
                      if (selectedInfoIndex == 0) {
                        // Sort by cheapest price (ascending)
                        filtered.sort((a, b) {
                          final priceA =
                              (a['minPrice'] as num?)?.toDouble() ??
                              double.maxFinite;
                          final priceB =
                              (b['minPrice'] as num?)?.toDouble() ??
                              double.maxFinite;
                          return priceA.compareTo(priceB);
                        });
                      } else if (selectedInfoIndex == 1) {
                        // Sort by availability (descending)
                        filtered.sort((a, b) {
                          final availA = _getMaxAvailability(a);
                          final availB = _getMaxAvailability(b);
                          return availB.compareTo(availA);
                        });
                      } else if (selectedInfoIndex == 2) {
                        // Sort by nearest distance
                        if (_userPosition != null) {
                          filtered.sort((a, b) {
                            final cinemaLatA =
                                (a['latitude'] as num?)?.toDouble() ?? 0;
                            final cinemaLonA =
                                (a['longitude'] as num?)?.toDouble() ?? 0;
                            final cinemaLatB =
                                (b['latitude'] as num?)?.toDouble() ?? 0;
                            final cinemaLonB =
                                (b['longitude'] as num?)?.toDouble() ?? 0;

                            final distA = _calculateDistance(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                              cinemaLatA,
                              cinemaLonA,
                            );
                            final distB = _calculateDistance(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                              cinemaLatB,
                              cinemaLonB,
                            );

                            return distA.compareTo(distB);
                          });
                        }
                      } else {
                        // Default: sort by rating (descending)
                        filtered.sort((a, b) {
                          final ratingA = (a['rating'] as num?) ?? 0;
                          final ratingB = (b['rating'] as num?) ?? 0;
                          return ratingB.compareTo(ratingA);
                        });
                      }

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No movies available',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      if (index >= filtered.length) {
                        return const SizedBox.shrink();
                      }

                      final item = filtered[index];
                      final movieIdRaw = item['movieId'];
                      final movieId =
                          movieIdRaw != null ? movieIdRaw.toString() : '';
                      final title = item['movieTitle'] as String? ?? '';
                      final posterPath = item['posterPath'] as String? ?? '';
                      final rating = item['rating'] as num? ?? 0;
                      final language = item['language'] as String? ?? 'N/A';
                      final genres =
                          (item['genres'] as List?)?.cast<String>() ?? [];
                      final cinemaName = item['cinemaName'] as String? ?? '';
                      final showtimes =
                          (item['showtimes'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ShowTimeScreen(
                                      tmdbId: movieId,
                                      movieTitle: title,
                                      backdropPath: '',
                                    ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF5A1EA9),
                                    Color(0xFF3A0E68),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Movie Poster
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 80,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child:
                                            posterPath.isNotEmpty
                                                ? Image.network(
                                                  posterPath,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
                                                        Icons.local_movies,
                                                        color: Colors.white30,
                                                      ),
                                                )
                                                : const Icon(
                                                  Icons.local_movies,
                                                  color: Colors.white30,
                                                  size: 40,
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Color(0xFFFFC107),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating > 0
                                                    ? '${rating.toStringAsFixed(1)}'
                                                    : 'N/A',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  language,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // Cinema Name
                                          Text(
                                            cinemaName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Showtimes
                                          if (showtimes.isNotEmpty)
                                            SizedBox(
                                              height: 55,
                                              child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                itemCount: showtimes.length,
                                                itemBuilder: (context, idx) {
                                                  final showtime =
                                                      showtimes[idx];
                                                  final time = _formatTime(
                                                    showtime['time'],
                                                  );
                                                  final price =
                                                      (showtime['price']
                                                              as num?)
                                                          ?.toDouble() ??
                                                      0;

                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      right:
                                                          idx ==
                                                                  showtimes
                                                                          .length -
                                                                      1
                                                              ? 0
                                                              : 6,
                                                    ),
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        final url =
                                                            showtime['bookingUrl']
                                                                as String? ??
                                                            '';
                                                        if (url.isNotEmpty &&
                                                            await canLaunchUrl(
                                                              Uri.parse(url),
                                                            )) {
                                                          await launchUrl(
                                                            Uri.parse(url),
                                                            mode:
                                                                LaunchMode
                                                                    .externalApplication,
                                                          );
                                                        }
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              time,
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                            Text(
                                                              '\$$price',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white70,
                                                                fontSize: 9,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount:
                        _generatedDates.isEmpty
                            ? 0
                            : _getFilteredMovies(_movies).length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredMovies(
    List<Map<String, dynamic>> movies,
  ) {
    if (movies.isEmpty) return [];

    final selectedLanguage =
        selectedLangIndex == -1 ||
                selectedLangIndex >= _availableLanguages.length
            ? null
            : _availableLanguages[selectedLangIndex];

    List<Map<String, dynamic>> filtered =
        movies.where((movie) {
          if (selectedLanguage != null) {
            final language = movie['language'] as String? ?? '';
            if (!language.toLowerCase().contains(
              selectedLanguage.toLowerCase(),
            )) {
              return false;
            }
          }

          if (_searchQuery.isNotEmpty) {
            final title = (movie['movieTitle'] as String? ?? '').toLowerCase();
            if (!title.contains(_searchQuery.toLowerCase())) {
              return false;
            }
          }

          return true;
        }).toList();

    return filtered;
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return 'N/A';
    }
  }

  int _getMaxAvailability(Map<String, dynamic> movie) {
    int maxAvailability = 0;
    const int totalSeats = 100;
    final showtimes =
        (movie['showtimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (var showtime in showtimes) {
      final availableSeats = (showtime['seatsAvailable'] as num?)?.toInt() ?? 0;
      final availabilityPercentage =
          ((availableSeats / totalSeats) * 100).toInt();
      if (availabilityPercentage > maxAvailability) {
        maxAvailability = availabilityPercentage;
      }
    }
    return maxAvailability;
  }

  bool _hasGenreFilter() {
    for (var selected in _genreSelected) {
      if (selected) return true;
    }
    return false;
  }

  bool _hasExperienceFilter() {
    for (var selected in _xpSelected) {
      if (selected) return true;
    }
    return false;
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String rating;
  final List<Map<String, dynamic>> generatedDates;
  final int selectedDateIndex;
  final Function(int) onDateSelected;
  final List<String> langList;
  final int selectedLangIndex;
  final Function(int) onLangSelected;
  final VoidCallback onFilterTap;
  final List<Map<String, dynamic>> movies;
  final int? selectedInfoIndex;
  final Function(int) onInfoIndexChanged;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final Position? userPosition;
  final Function(double, double, double, double) onCalculateDistance;

  _StickyHeaderDelegate({
    required this.title,
    required this.rating,
    required this.generatedDates,
    required this.selectedDateIndex,
    required this.onDateSelected,
    required this.langList,
    required this.selectedLangIndex,
    required this.onLangSelected,
    required this.onFilterTap,
    required this.movies,
    this.selectedInfoIndex = 0,
    required this.onInfoIndexChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.userPosition,
    required this.onCalculateDistance,
  });

  @override
  double get maxExtent => 340;

  @override
  double get minExtent => 340;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search movies...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
                suffixIcon:
                    searchQuery.isNotEmpty
                        ? GestureDetector(
                          onTap: () => onSearchChanged(''),
                          child: Icon(
                            Icons.close,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        )
                        : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              cursorColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Date Picker
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 70,
              width: double.infinity,
              child:
                  generatedDates.isEmpty
                      ? const Center(
                        child: Text(
                          'Loading dates...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: generatedDates.length,
                        itemBuilder: (context, i) {
                          final selected = i == selectedDateIndex;
                          final dateData = generatedDates[i];
                          return Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 14 : 10,
                              right: 0,
                            ),
                            child: GestureDetector(
                              onTap: () => onDateSelected(i),
                              child: Container(
                                width: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient:
                                      selected
                                          ? AppColors.filterGradient
                                          : null,
                                  color:
                                      selected
                                          ? null
                                          : Colors.white.withOpacity(0.09),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dateData['label']!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.90),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateData['num']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateData['month']!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),

          // Language Filter
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 12),
            child: SizedBox(
              height: 32,
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: langList.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final allSelected = selectedLangIndex == -1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onLangSelected(-1),
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
                              height: 1.0,
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

                  final langIdx = i - 1;
                  final selected = langIdx == selectedLangIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onLangSelected(langIdx),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color:
                              selected
                                  ? AppColors.chipSelectedBg
                                  : AppColors.chipUnselectedBg,
                        ),
                        child: Text(
                          langList[langIdx],
                          style: TextStyle(
                            color:
                                selected
                                    ? AppColors.chipSelectedText
                                    : AppColors.chipUnselectedText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Info Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Builder(
              builder: (context) {
                num cheapestPrice = double.maxFinite;
                int maxAvailability = 0;
                double nearestDistance = double.maxFinite;
                const int totalSeats = 100;

                // Get filtered movies based on language, search, experiences, and genres
                final filteredMovies =
                    movies.where((movie) {
                      // Language filter
                      if (selectedLangIndex != -1 &&
                          selectedLangIndex < langList.length) {
                        final language = movie['language'] as String? ?? '';
                        if (!language.toLowerCase().contains(
                          langList[selectedLangIndex].toLowerCase(),
                        )) {
                          return false;
                        }
                      }

                      // Search filter
                      if (searchQuery.isNotEmpty) {
                        final title =
                            (movie['movieTitle'] as String? ?? '')
                                .toLowerCase();
                        if (!title.contains(searchQuery.toLowerCase())) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();

                // Calculate cheapest price, max availability, and nearest distance from filtered movies
                for (var movie in filteredMovies) {
                  final minPrice =
                      (movie['minPrice'] as num?)?.toDouble() ??
                      double.maxFinite;
                  if (minPrice < cheapestPrice) {
                    cheapestPrice = minPrice;
                  }

                  final showtimes =
                      (movie['showtimes'] as List?)
                          ?.cast<Map<String, dynamic>>() ??
                      [];
                  for (var showtime in showtimes) {
                    final availableSeats =
                        (showtime['seatsAvailable'] as num?)?.toInt() ?? 0;
                    final availabilityPercentage =
                        ((availableSeats / totalSeats) * 100).toInt();
                    if (availabilityPercentage > maxAvailability) {
                      maxAvailability = availabilityPercentage;
                    }
                  }

                  // Calculate distance if user location is available
                  if (userPosition != null) {
                    final cinemaLat =
                        (movie['latitude'] as num?)?.toDouble() ?? 0;
                    final cinemaLon =
                        (movie['longitude'] as num?)?.toDouble() ?? 0;
                    if (cinemaLat != 0 && cinemaLon != 0) {
                      final distance = onCalculateDistance(
                        userPosition!.latitude,
                        userPosition!.longitude,
                        cinemaLat,
                        cinemaLon,
                      );
                      if (distance < nearestDistance) {
                        nearestDistance = distance;
                      }
                    }
                  }
                }

                return InfoRowCard(
                  selected: selectedInfoIndex ?? 0,
                  onChanged: (idx) => onInfoIndexChanged(idx),
                  cheapestPrice:
                      cheapestPrice == double.maxFinite ? 0 : cheapestPrice,
                  availabilityPercentage: maxAvailability,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.rating != rating ||
        oldDelegate.selectedDateIndex != selectedDateIndex ||
        oldDelegate.selectedLangIndex != selectedLangIndex ||
        (oldDelegate.selectedInfoIndex ?? 0) != (selectedInfoIndex ?? 0) ||
        oldDelegate.generatedDates != generatedDates ||
        oldDelegate.movies != movies ||
        oldDelegate.searchQuery != searchQuery;
  }
}
