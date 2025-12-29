import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/widgets/custom_bottom_nav.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:cinematick/config/secrets.dart';
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

class ShowTimeScreen extends ConsumerStatefulWidget {
  final Map<String, String>? movie;
  final String tmdbId;
  final VoidCallback? onBackPressed;
  final String? backdropPath;
  final int? selectedDateIndex;
  final int? selectedLanguageIndex;
  final String? movieTitle;
  final Map<String, dynamic>? cinema;

  const ShowTimeScreen({
    super.key,
    this.movie,
    required this.tmdbId,
    this.onBackPressed,
    this.backdropPath,
    this.selectedDateIndex,
    this.selectedLanguageIndex,
    this.movieTitle,
    this.cinema,
  });
  @override
  ConsumerState<ShowTimeScreen> createState() => _ShowTimeScreenState();
}

class _ShowTimeScreenState extends ConsumerState<ShowTimeScreen> {
  late int selectedDateIndex;
  late int selectedLangIndex;
  int selectedInfoIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _showtimes = [];
  String? _errorMessage;
  List<Map<String, dynamic>> _generatedDates = [];
  Position? _userPosition;
  Map<String, double> _cinemaDistances = {};
  bool _locationPermissionRequested = false;
  List<String> _availableLanguages = [];
  double _scrollOffset = 0.0;

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
    print('TMDB ID: ${widget.tmdbId}');

    selectedDateIndex = widget.selectedDateIndex ?? 0;
    selectedLangIndex = widget.selectedLanguageIndex ?? -1;

    _xpSelected = List<bool>.filled(_allExperiences.length, false);
    _genreSelected = List<bool>.filled(_allGenres.length, false);
    _generatedDates = _generateDates();
    _getUserLocation();
    _fetchShowtimes();
  }

  @override
  void dispose() {
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
        _locationPermissionRequested = true;
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

      final String apiUrl =
          '$baseUrl/movies/${widget.tmdbId}/showtimes?date=$dateStr';
      print('Fetching from Movie API: $apiUrl');

      final response = await http.get(Uri.parse(apiUrl));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> processedShowtimes = [];

        if (data is List) {
          print('Processing Movie API response with ${data.length} showtimes');
          processedShowtimes = List<Map<String, dynamic>>.from(data);
        }

        setState(() {
          _showtimes = processedShowtimes;
          _availableLanguages = _extractAvailableLanguages();
          _langSelected = List<bool>.filled(_availableLanguages.length, false);
          _calculateCinemaDistances();
          print(
            'Loaded ${_showtimes.length} total showtimes with ${_generatedDates.length} unique dates',
          );
          print('Available languages: $_availableLanguages');
          for (var date in _generatedDates) {
            print(
              'Date: ${date['label']} ${date['num']} ${date['month']} (${date['dateStr']})',
            );
          }
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Failed to load showtimes (Status: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('Error in _fetchShowtimes: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _processShowtimesFromCinemaAPI(
    Map<String, dynamic> apiResponse,
  ) {
    final List<Map<String, dynamic>> flattenedShowtimes = [];
    final moviesArray = apiResponse['movies'] as List? ?? [];

    print('Processing ${moviesArray.length} movies from cinema API');

    for (var movie in moviesArray) {
      final movieTitle = movie['title'] ?? 'Unknown';
      final movieId = movie['tmdbId'];
      final showtimesArray = movie['showtimes'] as List? ?? [];

      print(
        '  Movie: $movieTitle (ID: $movieId) - ${showtimesArray.length} showtimes',
      );

      for (var showtime in showtimesArray) {
        flattenedShowtimes.add({
          'id': showtime['id'],
          'start_time': showtime['start_time'],
          'booking_url': showtime['booking_url'],
          'cinema': showtime['cinema'],
          'movie_title': movieTitle,
          'movie_id': movieId,
          'language': showtime['language'] ?? '',
          'screen_name':
              showtime['screenName'] ?? showtime['screen'] ?? 'Screen',
          'seats': showtime['seats'] ?? [],
          'total_seats': showtime['total_seats'],
          'total_seats_available': showtime['total_seats_available'],
        });
      }
    }

    print('Total flattened showtimes: ${flattenedShowtimes.length}');
    return flattenedShowtimes;
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

  Future<void> _fetchShowtimesForDate(String dateStr) async {
    try {
      print('Fetching showtimes for date: $dateStr');
      final response = await http.get(
        Uri.parse('$baseUrl/movies/${widget.tmdbId}/showtimes?date=$dateStr'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final allShowtimes = List<Map<String, dynamic>>.from(data);

        if (!mounted) return;
        setState(() {
          _showtimes = allShowtimes;
          print('Total showtimes for $dateStr: ${allShowtimes.length}');
        });
      } else {
        print('Failed to load showtimes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching showtimes for date: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupShowtimesByTheater() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var showtime in _showtimes) {
      String theaterName = showtime['cinema']['name'] ?? 'Unknown';
      if (!grouped.containsKey(theaterName)) {
        grouped[theaterName] = [];
      }
      grouped[theaterName]!.add(showtime);
    }
    return grouped;
  }

  Map<String, List<Map<String, dynamic>>> _groupShowtimesByDate(
    List<Map<String, dynamic>> showtimes,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var showtime in showtimes) {
      final startTimeStr = showtime['start_time']?.toString() ?? '';
      String dateStr =
          startTimeStr.length >= 10
              ? startTimeStr.substring(0, 10)
              : startTimeStr;

      if (dateStr.isNotEmpty) {
        if (!grouped.containsKey(dateStr)) {
          grouped[dateStr] = [];
        }
        grouped[dateStr]!.add(showtime);
      }
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
    final mv = widget.movie;

    String bannerImage = 'https://picsum.photos/800/500?blur=3'; // default

    if (widget.backdropPath?.isNotEmpty == true) {
      bannerImage = widget.backdropPath!;
    } else if (mv?['backdrop']?.isNotEmpty == true) {
      bannerImage = mv!['backdrop'] as String;
    } else if (mv?['image']?.isNotEmpty == true) {
      bannerImage = mv!['image'] as String;
    } else if (_showtimes.isNotEmpty) {
      final firstShowtime = _showtimes.first;
    }

    final title = mv?['title'] ?? widget.movieTitle ?? 'Unknown Movie';
    final rating = mv?['rating'] ?? '0.0';
    final selectedNavIndex = ref.watch(bottomNavIndexProvider);

    print('===== ShowTimeScreen Build =====');
    print('Banner Image URL: $bannerImage');
    print('Movie data: $mv');
    print('Showtimes count: ${_showtimes.length}');

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
        currentIndex: selectedNavIndex,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
          if (index != 1) {
            ref.read(selectedCinemaChainProvider.notifier).state = null;
            ref.read(selectedCinemaLocationProvider.notifier).state = null;
            ref.read(selectedMovieTitleProvider.notifier).state = null;
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollNotification) {
                  setState(() {
                    _scrollOffset = scrollNotification.metrics.pixels;
                  });
                  return false;
                },
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: CustomAppBar()),
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          ClipRRect(
                            child: Container(
                              width: double.infinity,
                              color: Colors.grey[800],
                              child: Image.network(
                                bannerImage,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 300,
                                    color: Colors.grey[800],
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color.fromARGB(
                                      255,
                                      58,
                                      22,
                                      103,
                                    ).withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            top: 20,
                            child: GestureDetector(
                              onTap: () async {
                                final youtubeUrl =
                                    widget.movie?['youtubeUrl'] ??
                                    widget.movie?['youtube_url'] ??
                                    widget.movie?['trailerUrl'] ??
                                    '';
                                if (youtubeUrl.isNotEmpty) {
                                  if (await canLaunchUrl(
                                    Uri.parse(youtubeUrl),
                                  )) {
                                    await launchUrl(
                                      Uri.parse(youtubeUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                } else {
                                  final searchUrl =
                                      'https://www.youtube.com/results?search_query=${Uri.encodeComponent(title + " trailer")}';
                                  if (await canLaunchUrl(
                                    Uri.parse(searchUrl),
                                  )) {
                                    await launchUrl(
                                      Uri.parse(searchUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.5),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            top: 20,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyHeaderDelegate(
                        title: title,
                        rating: rating,
                        generatedDates: _generatedDates,
                        selectedDateIndex: selectedDateIndex,
                        onDateSelected: (index) {
                          setState(() => selectedDateIndex = index);
                          if (index < _generatedDates.length) {
                            _fetchShowtimesForDate(
                              _generatedDates[index]['dateStr'],
                            );
                          }
                        },
                        langList: _availableLanguages,
                        selectedLangIndex: selectedLangIndex,
                        onLangSelected: (index) {
                          setState(() => selectedLangIndex = index);
                        },
                        onFilterTap:
                            () => _scaffoldKey.currentState?.openDrawer(),
                        showtimes: _showtimes,
                        selectedInfoIndex: selectedInfoIndex,
                        onInfoIndexChanged: (index) {
                          setState(() => selectedInfoIndex = index);
                        },
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
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      )
                    else if (_showtimes.isEmpty)
                      const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No showtimes available',
                              style: TextStyle(color: Colors.white70),
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
                              return const Center(
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

                            final groupedByDate = _groupShowtimesByDate(
                              _showtimes,
                            );
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

                            final groupedByTheatre =
                                <String, List<Map<String, dynamic>>>{};
                            for (var showtime in filteredShowtimes) {
                              final theatreName =
                                  showtime['cinema']['name'] ?? 'Unknown';
                              if (!groupedByTheatre.containsKey(theatreName)) {
                                groupedByTheatre[theatreName] = [];
                              }
                              groupedByTheatre[theatreName]!.add(showtime);
                            }

                            final sortedTheatres =
                                groupedByTheatre.entries.toList();

                            if (selectedInfoIndex == 1) {
                              sortedTheatres.sort((a, b) {
                                final availabilityA = _getMaxAvailability(
                                  a.value,
                                );
                                final availabilityB = _getMaxAvailability(
                                  b.value,
                                );
                                return availabilityB.compareTo(availabilityA);
                              });
                            } else if (selectedInfoIndex == 3) {
                              sortedTheatres.sort((a, b) {
                                final distanceA =
                                    _cinemaDistances[a.key] ?? double.maxFinite;
                                final distanceB =
                                    _cinemaDistances[b.key] ?? double.maxFinite;
                                return distanceA.compareTo(distanceB);
                              });
                            } else {
                              sortedTheatres.sort((a, b) {
                                final minPriceA = _getMinPrice(a.value);
                                final minPriceB = _getMinPrice(b.value);
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

                            if (index >= sortedTheatres.length) {
                              return const SizedBox.shrink();
                            }

                            final theatreName = sortedTheatres[index].key;
                            final theatreShowtimes =
                                sortedTheatres[index].value;
                            final firstShowtime = theatreShowtimes.first;
                            final cinema = firstShowtime['cinema'];
                            final minPrice = _getMinPrice(theatreShowtimes);

                            final screenWidth =
                                MediaQuery.of(context).size.width;
                            final isSmallScreen = screenWidth < 380;
                            final isMediumScreen = screenWidth < 600;

                            int infoFlex =
                                isSmallScreen
                                    ? 3
                                    : isMediumScreen
                                    ? 4
                                    : 4;
                            int showtimeFlex =
                                isSmallScreen
                                    ? 5
                                    : isMediumScreen
                                    ? 6
                                    : 6;

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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Container(
                                                  width: 67,
                                                  height: 100,
                                                  color: Colors.black,
                                                  child: Image.asset(
                                                    _getCinemaLogoPath(
                                                      cinema['name'] ??
                                                          'Unknown',
                                                    ),
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Center(
                                                        child: Icon(
                                                          Icons.local_movies,
                                                          color: Colors.white30,
                                                          size: 40,
                                                        ),
                                                      );
                                                    },
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
                                                      cinema['name'] ??
                                                          'Cinema Name',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.star,
                                                          size: 14,
                                                          color: Color(
                                                            0xFFFFC107,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${cinema['rating'] ?? '4.2'}',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),

                                                          child: Text(
                                                            (() {
                                                              final cinemaName =
                                                                  cinema['name'] ??
                                                                  'Unknown';
                                                              final distance =
                                                                  _cinemaDistances[cinemaName];
                                                              if (distance !=
                                                                  null) {
                                                                return '${distance.toStringAsFixed(1)} km';
                                                              }
                                                              return 'N/A';
                                                            })(),
                                                            style: const TextStyle(
                                                              color:
                                                                  Color.fromARGB(
                                                                    255,
                                                                    88,
                                                                    184,
                                                                    248,
                                                                  ),
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
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
                                              final showtime =
                                                  theatreShowtimes[idx];
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
                                                            (s) =>
                                                                s['price']
                                                                    as num,
                                                          )
                                                          .reduce(
                                                            (a, b) =>
                                                                a < b ? a : b,
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
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          _formatTime(
                                                            showtime['start_time'],
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          2,
                                                                      vertical:
                                                                          2,
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
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            Text(
                                                              '\$$minPrice',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
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
                                        selectedDateIndex >=
                                                _generatedDates.length
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
                                                  selectedLanguage
                                                      .toLowerCase(),
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

                                    final groupedByTheatre =
                                        <String, List<Map<String, dynamic>>>{};
                                    for (var showtime in filteredShowtimes) {
                                      final theatreName =
                                          showtime['cinema']['name'] ??
                                          'Unknown';
                                      if (!groupedByTheatre.containsKey(
                                        theatreName,
                                      )) {
                                        groupedByTheatre[theatreName] = [];
                                      }
                                      groupedByTheatre[theatreName]!.add(
                                        showtime,
                                      );
                                    }

                                    return groupedByTheatre.length;
                                  }()),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                top:
                    _scrollOffset > 300
                        ? (56 + MediaQuery.of(context).padding.top)
                        : (-60),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: AnimatedOpacity(
                    opacity: _scrollOffset > 300 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      if (dateTimeString.isEmpty) return 'N/A';
      final dateTime = DateTime.parse(dateTimeString);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      print('Error formatting time: $e, dateTimeString: $dateTimeString');
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

  String _getCinemaLogoPath(String cinemaName) {
    final nameLower = cinemaName.toLowerCase();

    if (nameLower.contains('event')) {
      return 'lib/assets/event.png';
    } else if (nameLower.contains('hoyts')) {
      return 'lib/assets/hoyts.png';
    } else if (nameLower.contains('read')) {
      return 'lib/assets/read.png';
    } else if (nameLower.contains('village')) {
      return 'lib/assets/village.png';
    } else {
      return 'lib/assets/village.png';
    }
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
  });

  @override
  double get maxExtent => 380;

  @override
  double get minExtent => 380;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      color: Color(0xFFFFB64B),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$rating/10',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        oldDelegate.showtimes != showtimes;
  }
}
