import 'package:cinematick/config/secrets.dart';
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
import 'dart:math';

class CinemaDetailScreen extends ConsumerStatefulWidget {
  final Map<String, String>? movie;
  final String tmdbId;
  final VoidCallback? onBackPressed;
  final String? backdropPath;
  final Map<String, dynamic>? cinema;
  final String? cinemaCity;
  final String? chainName;
  final String? cinemaId;
  final int? screenCount;

  const CinemaDetailScreen({
    super.key,
    this.movie,
    required this.tmdbId,
    this.onBackPressed,
    this.backdropPath,
    this.cinema,
    this.cinemaCity,
    this.chainName,
    this.cinemaId,
    this.screenCount,
  });
  @override
  ConsumerState<CinemaDetailScreen> createState() => _CinemaDetailScreenState();
}

class _CinemaDetailScreenState extends ConsumerState<CinemaDetailScreen> {
  int selectedDateIndex = 0;
  int selectedLangIndex = -1;
  int selectedInfoIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _showtimes = [];
  String? _errorMessage;
  List<Map<String, dynamic>> _generatedDates = [];
  Position? _userPosition;
  Map<String, double> _cinemaDistances = {};
  List<String> _availableLanguages = [];
  String _movieSearchQuery = '';
  String _genreSearchQuery = '';
  late TextEditingController _movieSearchController;
  late TextEditingController _genreSearchController;

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

  final Map<String, Map<String, double>> _cityCoordinates = {
    'sydney': {'lat': -33.8688, 'lng': 151.2093},
    'glendale': {'lat': -33.5061, 'lng': 151.4278},
    'tuggerah': {'lat': -33.4461, 'lng': 151.4456},
    'hornsby': {'lat': -33.6844, 'lng': 151.0947},
    'campbelltown': {'lat': -34.0695, 'lng': 150.7829},
    'kotara': {'lat': -33.0313, 'lng': 151.7269},
    'albury': {'lat': -36.0795, 'lng': 146.9171},
    'wetherill park': {'lat': -33.8633, 'lng': 150.9249},
    'chatswood': {'lat': -33.7976, 'lng': 151.1861},
    'parramatta': {'lat': -33.8173, 'lng': 151.0029},
    'ryde': {'lat': -33.8061, 'lng': 151.1255},
    'ed square': {'lat': -33.8173, 'lng': 151.0029},
    'charlestown': {'lat': -33.0423, 'lng': 151.7213},
    'top ryde city': {'lat': -33.8061, 'lng': 151.1255},
    'miranda': {'lat': -34.0277, 'lng': 151.1394},
    'burwood': {'lat': -33.8888, 'lng': 151.1144},
    'rhodes': {'lat': -33.8428, 'lng': 151.0761},
    'auburn': {'lat': -33.8470, 'lng': 150.9821},
    'george street': {'lat': -33.8688, 'lng': 151.2093},
    'bondi junction': {'lat': -33.8844, 'lng': 151.2485},
    'castle hill': {'lat': -33.7367, 'lng': 150.9857},
    'macquarie': {'lat': -33.7793, 'lng': 151.1268},
    'liverpool': {'lat': -34.0106, 'lng': 150.9217},
    'shellharbour': {'lat': -34.5747, 'lng': 150.7643},
    'westfield': {'lat': -33.7976, 'lng': 151.1861},
    'penrith': {'lat': -34.0081, 'lng': 150.6952},
    'green hills': {'lat': -32.7263, 'lng': 151.7786},
    'eastgardens': {'lat': -33.9508, 'lng': 151.2188},
    'warringah mall': {'lat': -33.7503, 'lng': 151.2875},
    'broadway': {'lat': -33.8896, 'lng': 151.1988},
    'mt druitt': {'lat': -33.7711, 'lng': 150.8194},
    'hurstville': {'lat': -34.0038, 'lng': 151.1050},
    'warrawong': {'lat': -34.4281, 'lng': 150.8025},
  };

  @override
  void initState() {
    super.initState();
    _movieSearchController = TextEditingController();
    _genreSearchController = TextEditingController();
    print('TMDB ID: ${widget.tmdbId}');
    _xpSelected = List<bool>.filled(_allExperiences.length, false);
    _genreSelected = List<bool>.filled(_allGenres.length, false);
    _generatedDates = _generateDates();
    _getUserLocation();
    _fetchShowtimes();
  }

  @override
  void dispose() {
    _movieSearchController.dispose();
    _genreSearchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showLocationPermissionDialog(
                'Location Services Disabled',
                'Please enable location services to see cinemas nearest to you.',
                openSettings: true,
              );
            }
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission status: $permission');

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        print('Requesting location permission from user...');
        permission = await Geolocator.requestPermission();
        print('User response to permission request: $permission');
      }

      if (permission == LocationPermission.denied) {
        print('User denied location permission.');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showLocationPermissionDialog(
                'Location Permission Denied',
                'Grant location permission to display nearby cinemas. You can change this in app settings.',
              );
            }
          });
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        print('User permanently denied location permission.');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showLocationPermissionDialog(
                'Location Permission Required',
                'Location permission is permanently denied. Please enable it in app settings.',
                openSettings: true,
              );
            }
          });
        }
        return;
      }

      if (!mounted) return;
      print('Permission granted. Getting user position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _userPosition = position;
          _calculateCinemaDistances();
        });
        print(
          'User location obtained: Latitude ${position.latitude}, Longitude ${position.longitude}',
        );
      }
    } catch (e) {
      print('Error getting user location: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showLocationPermissionDialog(
              'Location Error',
              'Unable to get your location. Make sure location services are enabled and try again.',
            );
          }
        });
      }
    }
  }

  void _showLocationPermissionDialog(
    String title,
    String message, {
    bool openSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A1A4E),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss'),
            ),
            if (openSettings)
              TextButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
          ],
        );
      },
    );
  }

  double _calculateDistance(
    double userLat,
    double userLng,
    double cinemaLat,
    double cinemaLng,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(cinemaLat - userLat);
    final dLng = _degreesToRadians(cinemaLng - userLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(userLat)) *
            cos(_degreesToRadians(cinemaLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadiusKm * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  Future<void> _fetchShowtimes() async {
    try {
      String dateStr;
      if (_generatedDates.isNotEmpty &&
          selectedDateIndex < _generatedDates.length) {
        dateStr = _generatedDates[selectedDateIndex]['dateStr'];
      } else {
        final now = DateTime.now();
        dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      }

      if (widget.cinemaId != null && widget.cinemaId!.isNotEmpty) {
        print(
          'Fetching showtimes for Cinema ID: ${widget.cinemaId}, Date: $dateStr',
        );
        final response = await http.get(
          Uri.parse('$baseUrl/cinemas/${widget.cinemaId}?date=$dateStr'),
        );
        _processShowtimesFromCinemaAPI(response);
      } else {
        print(
          'Fetching showtimes for TMDB ID: ${widget.tmdbId}, Date: $dateStr',
        );
        final response = await http.get(
          Uri.parse('$baseUrl/movies/${widget.tmdbId}/showtimes?date=$dateStr'),
        );
        _processShowtimesFromMovieAPI(response);
      }
    } catch (e) {
      if (!mounted) return;
      print('Exception in _fetchShowtimes: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _processShowtimesFromCinemaAPI(http.Response response) {
    if (!mounted) return;

    print('API Response Status: ${response.statusCode}');
    print('API Response Body Length: ${response.body.length}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final movies =
            (data['movies'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        List<Map<String, dynamic>> flatShowtimes = [];
        for (var movie in movies) {
          final movieShowtimes =
              (movie['showtimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          for (var showtime in movieShowtimes) {
            flatShowtimes.add({
              'id': showtime['id'],
              'start_time': showtime['startTime'],
              'booking_url': showtime['bookingUrl'],
              'cinema': {
                'name': widget.cinemaCity ?? 'Cinema',
                'city': widget.cinemaCity,
              },
              'movie_title': movie['title'] ?? 'Unknown Movie',
              'movie_id': movie['tmdbId'] ?? 'unknown',
              'movie_poster': movie['posterPath'] ?? movie['poster_path'] ?? '',
              'language':
                  showtime['language'] ?? movie['language'] ?? 'english',
              'screen_name':
                  showtime['screenName'] ?? showtime['screen'] ?? 'Screen',
              'seats': [
                {'type': 'standard', 'price': showtime['minPrice']},
              ],
              'total_seats': showtime['totalSeats'],
              'total_seats_available': showtime['availableSeats'],
            });
          }
        }

        print('Processed ${flatShowtimes.length} showtimes from cinema API');

        setState(() {
          _showtimes = flatShowtimes;
          _availableLanguages = _extractAvailableLanguages();
          _langSelected = List<bool>.filled(_availableLanguages.length, false);
          _generatedDates = _generateDates();
          _calculateCinemaDistances();
          _isLoading = false;
        });
      } catch (e) {
        print('Error parsing cinema API response: $e');
        setState(() {
          _errorMessage = 'Error parsing showtimes: $e';
          _isLoading = false;
        });
      }
    } else {
      print('API Error: Status ${response.statusCode}');
      setState(() {
        _errorMessage =
            'Failed to load showtimes (Status: ${response.statusCode})';
        _isLoading = false;
      });
    }
  }

  void _processShowtimesFromMovieAPI(http.Response response) {
    if (!mounted) return;

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Decoded data length: ${data.length}');

      if (data.isEmpty) {
        print('WARNING: API returned empty list of showtimes');
        setState(() {
          _showtimes = [];
          _availableLanguages = [];
          _langSelected = [];
          _generatedDates = _generateDates();
          _isLoading = false;
          _errorMessage = 'No showtimes available for this movie';
        });
        return;
      }

      setState(() {
        _showtimes = List<Map<String, dynamic>>.from(data);
        _availableLanguages = _extractAvailableLanguages();
        _langSelected = List<bool>.filled(_availableLanguages.length, false);
        _generatedDates = _generateDates();
        _calculateCinemaDistances();
        print(
          'Loaded ${_showtimes.length} showtimes with ${_generatedDates.length} unique dates',
        );
        for (var date in _generatedDates) {
          print(
            'Date: ${date['label']} ${date['num']} ${date['month']} (${date['dateStr']})',
          );
        }
        print('Available languages: $_availableLanguages');
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      print('API Error: Status ${response.statusCode}');
      setState(() {
        _errorMessage =
            'Failed to load showtimes (Status: ${response.statusCode})';
        _isLoading = false;
      });
    }
  }

  void _calculateCinemaDistances() {
    if (_userPosition == null) {
      print(
        'User position not available. Location permission may need to be granted by the user.',
      );
      return;
    }

    int distancesCalculated = 0;
    for (var showtime in _showtimes) {
      final cinema = showtime['cinema'];
      if (cinema != null) {
        final cinemaName = cinema['name'] as String?;
        final city = cinema['city'] as String?;

        if (cinemaName != null && city != null) {
          final cityLower = city.toLowerCase().trim();
          final coords = _cityCoordinates[cityLower];

          if (coords != null) {
            final distance = _calculateDistance(
              _userPosition!.latitude,
              _userPosition!.longitude,
              coords['lat']!,
              coords['lng']!,
            );
            _cinemaDistances[cinemaName] = distance;
            distancesCalculated++;
            print(
              '$cinemaName ($city) distance: ${distance.toStringAsFixed(2)} km',
            );
          } else {
            print('City "$city" not found in coordinates map');
          }
        }
      }
    }
    print('Calculated distances for $distancesCalculated cinemas');
  }

  Map<String, List<Map<String, dynamic>>> _groupShowtimesByDate(
    List<Map<String, dynamic>> showtimes,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var showtime in showtimes) {
      final startTimeStr = showtime['start_time'].toString();
      String dateStr =
          startTimeStr.length >= 10
              ? startTimeStr.substring(0, 10)
              : startTimeStr;
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(showtime);
    }
    return grouped;
  }

  List<Map<String, dynamic>> _generateDates() {
    List<Map<String, dynamic>> dates = [];
    final now = DateTime.now();

    for (int i = 0; i < 6; i++) {
      final date = now.add(Duration(days: i));
      final dayName =
          ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][(date.weekday % 7)];
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
    for (var showtime in _showtimes) {
      final language = showtime['language'] as String?;
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

  final List<Map<String, dynamic>> theatres = [
    {
      'name': 'The Roxy Movie House',
      'address': '789 Picture Rd, Sydney',
      'distance': '8.3km',
      'rating': '4.2',
      'shows': [
        {'time': '21:00', 'price': 16, 'highlight': false},
      ],
    },
    {
      'name': 'Cineplex Grand Central',
      'address': '123 Movie Lane, Sydney',
      'distance': '2.5km',
      'rating': '4.5',
      'shows': [
        {'time': '19:15', 'price': 19, 'highlight': false},
      ],
    },
    {
      'name': 'Starlight Cinemas Downtown',
      'address': '456 Film Ave, Sydney',
      'distance': '5.1km',
      'rating': '4.8',
      'shows': [
        {'time': '20:00', 'price': 26, 'highlight': true},
      ],
    },
  ];

  final dateList = [
    {'label': 'Sun', 'num': '2', 'month': 'Nov'},
    {'label': 'Mon', 'num': '3', 'month': 'Nov'},
    {'label': 'Tue', 'num': '4', 'month': 'Nov'},
    {'label': 'Wed', 'num': '5', 'month': 'Nov'},
    {'label': 'Thu', 'num': '6', 'month': 'Nov'},
    {'label': 'Fri', 'num': '7', 'month': 'Nov'},
  ];

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: CustomAppBar(location: 'Sydney')),
              SliverPersistentHeader(
                pinned: false,
                delegate: _StickyHeaderDelegate(
                  title:
                      widget.cinemaCity ?? widget.movie?['title'] ?? 'Cinema',
                  rating: widget.movie?['vote_average'] ?? 'N/A',
                  generatedDates: _generatedDates,
                  selectedDateIndex: selectedDateIndex,
                  onDateSelected: (index) {
                    setState(() {
                      selectedDateIndex = index;
                    });
                    _fetchShowtimes();
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
                  showtimes: _showtimes,
                  selectedInfoIndex: selectedInfoIndex,
                  onInfoIndexChanged: (index) {
                    setState(() {
                      selectedInfoIndex = index;
                    });
                  },
                  cinemaCity: widget.cinemaCity,
                  screenCount: widget.screenCount,
                  movieSearchQuery: _movieSearchQuery,
                  genreSearchQuery: _genreSearchQuery,
                  onMovieSearchChanged: (query) {
                    setState(() {
                      _movieSearchQuery = query;
                    });
                  },
                  onGenreSearchChanged: (query) {
                    setState(() {
                      _genreSearchQuery = query;
                    });
                  },
                  movieSearchController: _movieSearchController,
                  genreSearchController: _genreSearchController,
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
              else if (_showtimes.isEmpty)
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
                SliverList(
                  key: ValueKey(selectedDateIndex),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_generatedDates.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No dates available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      }

                      final safeIndex =
                          selectedDateIndex >= _generatedDates.length
                              ? 0
                              : selectedDateIndex;
                      final selectedDate =
                          _generatedDates[safeIndex]['dateStr'];

                      final groupedByDate = _groupShowtimesByDate(_showtimes);
                      final showtimesForDate =
                          groupedByDate[selectedDate] ?? [];

                      final selectedLanguage =
                          selectedLangIndex == -1 ||
                                  selectedLangIndex >=
                                      _availableLanguages.length
                              ? null
                              : _availableLanguages[selectedLangIndex];
                      final filteredShowtimes =
                          showtimesForDate.where((showtime) {
                            if (selectedLanguage != null) {
                              final language = showtime['language'] ?? '';
                              if (!language.toString().toLowerCase().contains(
                                selectedLanguage.toLowerCase(),
                              )) {
                                return false;
                              }
                            }

                            if (selectedInfoIndex == 2) {
                              if (!_hasPremiumSeats(showtime)) {
                                return false;
                              }
                            }

                            return true;
                          }).toList();

                      final groupedByTheatreAndMovie =
                          <String, Map<String, List<Map<String, dynamic>>>>{};
                      for (var showtime in filteredShowtimes) {
                        final theatreName =
                            showtime['cinema']['name'] ?? 'Unknown';
                        final movieTitle = showtime['movie_title'] ?? 'Unknown';

                        if (!groupedByTheatreAndMovie.containsKey(
                          theatreName,
                        )) {
                          groupedByTheatreAndMovie[theatreName] = {};
                        }
                        if (!groupedByTheatreAndMovie[theatreName]!.containsKey(
                          movieTitle,
                        )) {
                          groupedByTheatreAndMovie[theatreName]![movieTitle] =
                              [];
                        }
                        groupedByTheatreAndMovie[theatreName]![movieTitle]!.add(
                          showtime,
                        );
                      }

                      List<Map<String, dynamic>> theatreMovieList = [];
                      for (var theatreEntry
                          in groupedByTheatreAndMovie.entries) {
                        for (var movieEntry in theatreEntry.value.entries) {
                          theatreMovieList.add({
                            'theatre_name': theatreEntry.key,
                            'movie_title': movieEntry.key,
                            'showtimes': movieEntry.value,
                          });
                        }
                      }

                      if (_movieSearchQuery.isNotEmpty ||
                          _genreSearchQuery.isNotEmpty) {
                        theatreMovieList =
                            theatreMovieList.where((item) {
                              final movieTitle =
                                  (item['movie_title'] as String).toLowerCase();
                              final movieSearchLower =
                                  _movieSearchQuery.toLowerCase();
                              final genreSearchLower =
                                  _genreSearchQuery.toLowerCase();

                              bool movieMatch =
                                  _movieSearchQuery.isEmpty ||
                                  movieTitle.contains(movieSearchLower);
                              bool genreMatch = _genreSearchQuery.isEmpty;

                              if (_genreSearchQuery.isNotEmpty) {
                                final showtimes =
                                    item['showtimes']
                                        as List<Map<String, dynamic>>;
                                genreMatch = showtimes.any((showtime) {
                                  final screenName =
                                      (showtime['screen_name'] as String?)
                                          ?.toLowerCase() ??
                                      '';
                                  return screenName.contains(genreSearchLower);
                                });
                              }

                              return movieMatch && genreMatch;
                            }).toList();
                      }

                      if (selectedInfoIndex == 1) {
                        theatreMovieList.sort((a, b) {
                          final availabilityA = _getMaxAvailability(
                            a['showtimes'],
                          );
                          final availabilityB = _getMaxAvailability(
                            b['showtimes'],
                          );
                          return availabilityB.compareTo(availabilityA);
                        });
                      } else if (selectedInfoIndex == 3) {
                        theatreMovieList.sort((a, b) {
                          final distanceA =
                              _cinemaDistances[a['theatre_name']] ??
                              double.maxFinite;
                          final distanceB =
                              _cinemaDistances[b['theatre_name']] ??
                              double.maxFinite;
                          return distanceA.compareTo(distanceB);
                        });
                      } else {
                        theatreMovieList.sort((a, b) {
                          final minPriceA = _getMinPrice(a['showtimes']);
                          final minPriceB = _getMinPrice(b['showtimes']);
                          return minPriceA.compareTo(minPriceB);
                        });
                      }

                      if (index == 0 && filteredShowtimes.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white30,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No showtimes in $selectedLanguage on ${_generatedDates[safeIndex]['label']} ${_generatedDates[safeIndex]['num']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (index >= theatreMovieList.length) {
                        return const SizedBox.shrink();
                      }

                      final theatreName =
                          theatreMovieList[index]['theatre_name'];
                      final movieTitle = theatreMovieList[index]['movie_title'];
                      final theatreShowtimes =
                          theatreMovieList[index]['showtimes'];
                      final firstShowtime = theatreShowtimes.first;
                      final cinema = firstShowtime['cinema'];

                      return GestureDetector(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Container(
                                            width: 67,
                                            height: 100,
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            child:
                                                firstShowtime['movie_poster'] !=
                                                            null &&
                                                        (firstShowtime['movie_poster']
                                                                as String)
                                                            .isNotEmpty
                                                    ? Image.network(
                                                      'https://image.tmdb.org/t/p/w200${firstShowtime['movie_poster']}',
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return const Center(
                                                          child: Icon(
                                                            Icons.local_movies,
                                                            color:
                                                                Colors.white30,
                                                            size: 40,
                                                          ),
                                                        );
                                                      },
                                                      loadingBuilder: (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return const Center(
                                                          child: SizedBox(
                                                            width: 30,
                                                            height: 30,
                                                            child: CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    Colors
                                                                        .white30,
                                                                  ),
                                                              strokeWidth: 2,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    )
                                                    : const Center(
                                                      child: Icon(
                                                        Icons.local_movies,
                                                        color: Colors.white30,
                                                        size: 40,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                movieTitle,
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
                                                    '${cinema['rating'] ?? '4.2'}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                      color:
                                                          const Color.fromARGB(
                                                            255,
                                                            124,
                                                            38,
                                                            137,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      (() {
                                                        final lang =
                                                            (firstShowtime['language'] ??
                                                                    'english')
                                                                .toString();
                                                        return lang[0]
                                                                .toUpperCase() +
                                                            lang.substring(1);
                                                      })(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 1.45,
                                          ),
                                      itemCount: theatreShowtimes.length,
                                      itemBuilder: (context, idx) {
                                        final showtime = theatreShowtimes[idx];
                                        final seats =
                                            (showtime['seats'] as List?)
                                                ?.cast<
                                                  Map<String, dynamic>
                                                >() ??
                                            [];
                                        final minPrice =
                                            seats.isNotEmpty
                                                ? seats
                                                    .map(
                                                      (s) => s['price'] as num,
                                                    )
                                                    .reduce(
                                                      (a, b) => a < b ? a : b,
                                                    )
                                                : 0;

                                        return GestureDetector(
                                          onTap: () async {
                                            final bookingUrl =
                                                showtime['booking_url']
                                                    as String? ??
                                                '';
                                            if (bookingUrl.isNotEmpty) {
                                              if (await canLaunchUrl(
                                                Uri.parse(bookingUrl),
                                              )) {
                                                await launchUrl(
                                                  Uri.parse(bookingUrl),
                                                  mode:
                                                      LaunchMode
                                                          .externalApplication,
                                                );
                                              }
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _formatTime(
                                                      showtime['start_time'],
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Flexible(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 2,
                                                                vertical: 2,
                                                              ),
                                                          child: Text(
                                                            showtime['screen_name'] ??
                                                                'Screen',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: const TextStyle(
                                                              color:
                                                                  Color.fromARGB(
                                                                    255,
                                                                    252,
                                                                    252,
                                                                    253,
                                                                  ),
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        '\$$minPrice',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
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
                            : (() {
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

                              final groupedByDate = _groupShowtimesByDate(
                                _showtimes,
                              );
                              final showtimesForDate =
                                  groupedByDate[selectedDate] ?? [];
                              final filteredShowtimes =
                                  showtimesForDate.where((showtime) {
                                    if (selectedLanguage != null) {
                                      final language =
                                          showtime['language'] ?? '';
                                      if (!language
                                          .toString()
                                          .toLowerCase()
                                          .contains(
                                            selectedLanguage.toLowerCase(),
                                          )) {
                                        return false;
                                      }
                                    }

                                    if (selectedInfoIndex == 2) {
                                      if (!_hasPremiumSeats(showtime)) {
                                        return false;
                                      }
                                    }

                                    return true;
                                  }).toList();

                              final groupedByTheatreAndMovie =
                                  <
                                    String,
                                    Map<String, List<Map<String, dynamic>>>
                                  >{};
                              for (var showtime in filteredShowtimes) {
                                final theatreName =
                                    showtime['cinema']['name'] ?? 'Unknown';
                                final movieTitle =
                                    showtime['movie_title'] ?? 'Unknown';
                                if (!groupedByTheatreAndMovie.containsKey(
                                  theatreName,
                                )) {
                                  groupedByTheatreAndMovie[theatreName] = {};
                                }
                                if (!groupedByTheatreAndMovie[theatreName]!
                                    .containsKey(movieTitle)) {
                                  groupedByTheatreAndMovie[theatreName]![movieTitle] =
                                      [];
                                }
                                groupedByTheatreAndMovie[theatreName]![movieTitle]!
                                    .add(showtime);
                              }

                              int totalCount = 0;
                              for (var entry
                                  in groupedByTheatreAndMovie.values) {
                                totalCount += entry.length;
                              }

                              return totalCount;
                            }()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
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

  num _getMinPrice(List<Map<String, dynamic>> showtimes) {
    num minPrice = double.maxFinite;
    for (var showtime in showtimes) {
      final seats =
          (showtime['seats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (seats.isNotEmpty) {
        final price = seats
            .map((s) => s['price'] as num)
            .reduce((a, b) => a < b ? a : b);
        if (price < minPrice) {
          minPrice = price;
        }
      }
    }
    return minPrice == double.maxFinite ? 0 : minPrice;
  }

  int _getMaxAvailability(List<Map<String, dynamic>> showtimes) {
    int maxAvailability = 0;
    for (var showtime in showtimes) {
      final availableSeats =
          (showtime['total_seats_available'] as num?)?.toInt() ?? 0;
      final totalSeats = (showtime['total_seats'] as num?)?.toInt() ?? 1;
      if (totalSeats > 0) {
        final availabilityPercentage =
            ((availableSeats / totalSeats) * 100).toInt();
        if (availabilityPercentage > maxAvailability) {
          maxAvailability = availabilityPercentage;
        }
      }
    }
    return maxAvailability;
  }

  bool _hasPremiumSeats(Map<String, dynamic> showtime) {
    final seats =
        (showtime['seats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (seats.isEmpty) return false;

    for (var seat in seats) {
      final seatType = (seat['type'] as String?)?.toLowerCase() ?? '';
      if (seatType.contains('recliner') ||
          seatType.contains('daybed') ||
          seatType.contains('platinum') ||
          seatType.contains('gold') ||
          seatType.contains('vip')) {
        return true;
      }
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
  final List<Map<String, dynamic>> showtimes;
  final int? selectedInfoIndex;
  final Function(int) onInfoIndexChanged;
  final String? cinemaCity;
  final int? screenCount;
  final String movieSearchQuery;
  final Function(String) onMovieSearchChanged;
  final String genreSearchQuery;
  final Function(String) onGenreSearchChanged;
  final TextEditingController movieSearchController;
  final TextEditingController genreSearchController;

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
    required this.showtimes,
    this.selectedInfoIndex = 0,
    required this.onInfoIndexChanged,
    this.cinemaCity,
    this.screenCount,
    required this.movieSearchQuery,
    required this.onMovieSearchChanged,
    required this.genreSearchQuery,
    required this.onGenreSearchChanged,
    required this.movieSearchController,
    required this.genreSearchController,
  });

  @override
  double get maxExtent => 420;

  @override
  double get minExtent => 420;

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

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${cinemaCity ?? title} • ${screenCount ?? 10} Screens',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: movieSearchController,
                    onChanged: onMovieSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search movies...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      suffixIcon:
                          movieSearchQuery.isNotEmpty
                              ? GestureDetector(
                                onTap: () {
                                  movieSearchController.clear();
                                  onMovieSearchChanged('');
                                },
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
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    cursorColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: genreSearchController,
                    onChanged: onGenreSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search genres...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.category,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      suffixIcon:
                          genreSearchQuery.isNotEmpty
                              ? GestureDetector(
                                onTap: () {
                                  genreSearchController.clear();
                                  onGenreSearchChanged('');
                                },
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
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    cursorColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

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
                          langList[langIdx][0].toUpperCase() +
                              langList[langIdx].substring(1),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Builder(
              builder: (context) {
                num cheapestPrice = double.maxFinite;
                for (var showtime in showtimes) {
                  final seats =
                      (showtime['seats'] as List?)
                          ?.cast<Map<String, dynamic>>() ??
                      [];
                  if (seats.isNotEmpty) {
                    final price = seats
                        .map((s) => s['price'] as num)
                        .reduce((a, b) => a < b ? a : b);
                    if (price < cheapestPrice) {
                      cheapestPrice = price;
                    }
                  }
                }

                int maxAvailability = 0;
                for (var showtime in showtimes) {
                  final availableSeats =
                      (showtime['total_seats_available'] as num?)?.toInt() ?? 0;
                  final totalSeats =
                      (showtime['total_seats'] as num?)?.toInt() ?? 1;
                  if (totalSeats > 0) {
                    final availabilityPercentage =
                        ((availableSeats / totalSeats) * 100).toInt();
                    if (availabilityPercentage > maxAvailability) {
                      maxAvailability = availabilityPercentage;
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
        oldDelegate.showtimes != showtimes ||
        oldDelegate.cinemaCity != cinemaCity ||
        oldDelegate.screenCount != screenCount ||
        oldDelegate.movieSearchQuery != movieSearchQuery ||
        oldDelegate.genreSearchQuery != genreSearchQuery;
  }
}
