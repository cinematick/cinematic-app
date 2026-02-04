import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/widgets/custom_bottom_nav.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:cinematick/config/secrets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:cinematick/widgets/info_row_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cinematick/providers/timezone_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart' as intl;
import 'package:cinematick/providers/timezone_provider.dart'
    show regionTimezoneMap;

class ShowTimeScreen extends ConsumerStatefulWidget {
  final Map<String, String>? movie;
  final String tmdbId;
  final VoidCallback? onBackPressed;
  final String? backdropPath;
  final int? selectedDateIndex;
  final int? selectedLanguageIndex;
  final String? movieTitle;
  final Map<String, dynamic>? cinema;
  final String location;

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
    this.location = 'NSW',
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
    'macquarie park': {'lat': -33.7793, 'lng': 151.1268},
    'liverpool': {'lat': -34.0106, 'lng': 150.9217},
    'shellharbour': {'lat': -34.5747, 'lng': 150.7643},
    'westfield': {'lat': -33.7976, 'lng': 151.1861},
    'penrith': {'lat': -34.0081, 'lng': 150.6952},
    'green hills': {'lat': -32.7263, 'lng': 151.7786},
    'eastgardens': {'lat': -33.9508, 'lng': 151.2188},
    'warringah mall': {'lat': -33.7503, 'lng': 151.2875},
    'broadway': {'lat': -33.8896, 'lng': 151.1988},
    'mt druitt': {'lat': -33.7711, 'lng': 150.8194},
    'mount druitt': {'lat': -33.7711, 'lng': 150.8194},
    'hurstville': {'lat': -34.0038, 'lng': 151.1050},
    'warrawong': {'lat': -34.4281, 'lng': 150.8025},
    'blacktown': {'lat': -33.7714, 'lng': 150.8995},
    'maitland': {'lat': -32.7394, 'lng': 151.5447},
    'east maitland': {'lat': -32.7456, 'lng': 151.5756},
    'brookvale': {'lat': -33.7474, 'lng': 151.3049},
    'rouse hill': {'lat': -33.6703, 'lng': 150.9939},
    'dubbo': {'lat': -32.2533, 'lng': 148.6061},
    'erina': {'lat': -33.4494, 'lng': 151.4269},
    'bankstown': {'lat': -33.9215, 'lng': 150.9996},
    'cronulla': {'lat': -34.0501, 'lng': 151.1561},
    'tweed heads': {'lat': -28.1689, 'lng': 153.5339},
    'moore park': {'lat': -33.8958, 'lng': 151.2190},
  };

  @override
  void initState() {
    super.initState();
    print('TMDB ID: ${widget.tmdbId}');

    selectedDateIndex = 0; // Start with today
    selectedLangIndex = -1; // All languages

    _xpSelected = List<bool>.filled(_allExperiences.length, false);
    _genreSelected = List<bool>.filled(_allGenres.length, false);
    _generatedDates = _generateDates();
    _getUserLocation();

    // Fetch data for today by default
    if (_generatedDates.isNotEmpty) {
      final todayDateStr = _generatedDates[0]['dateStr'];
      _fetchShowtimesForDate(todayDateStr);
    }
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
      print('Error getting user location');
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

  /// Calculates the UTC date to fetch from API for a given local date and region
  /// For Jan 30 Sydney (UTC+11): Midnight END of Jan 30 local = Feb 1 UTC (next day)
  /// The API expects the UTC date for the END of the local date (next day midnight in UTC)
  String _calculateApiDateForRegion(String localDateStr, String region) {
    try {
      // Parse local date (e.g., "2026-01-30")
      final parts = localDateStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Get timezone location for the region
      final tzName = regionTimezoneMap[region] ?? 'Australia/Sydney';
      final location = tz.getLocation(tzName);

      // Create midnight at the END of the local date (next day at midnight)
      final nextDay = DateTime(year, month, day).add(const Duration(days: 1));
      final midnightLocal = tz.TZDateTime(
        location,
        nextDay.year,
        nextDay.month,
        nextDay.day,
        0,
        0,
        0,
      );

      // Convert to UTC
      final utcTime = midnightLocal.toUtc();

      // Return the UTC date that should be sent to the API
      final apiDate =
          '${utcTime.year}-${utcTime.month.toString().padLeft(2, '0')}-${utcTime.day.toString().padLeft(2, '0')}';

      print(
        'API_DATE_CALC: LocalDate=$localDateStr, Region=$region => APIDate=$apiDate',
      );

      return apiDate;
    } catch (e) {
      print('Error calculating API date: $e');
      return localDateStr; // Fallback to local date if error
    }
  }

  Future<void> _fetchShowtimesForDate(
    String dateStr, {
    bool isAutoAdvance = false,
  }) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final region = ref.read(selectedRegionProvider);
      final apiDate = _calculateApiDateForRegion(dateStr, region);

      print('📍 Fetching: Local=$dateStr, API=$apiDate, Region=$region');

      final response = await http.get(
        Uri.parse(
          '$baseUrl/movies/${widget.tmdbId}/showtimes?date=$apiDate&region=$region',
        ),
      );

      print('📡 Response Status: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> processedShowtimes = [];

        if (data is List) {
          // Handle List response
          processedShowtimes = List<Map<String, dynamic>>.from(data);
          print('✅ API returned ${processedShowtimes.length} showtimes');
        } else if (data is Map) {
          // Handle Map response - cast safely
          final dataMap = data as Map<String, dynamic>;
          final movies = dataMap['movies'] as List? ?? [];
          final showtimes = dataMap['showtimes'] as List? ?? [];
          final dataList = dataMap['data'] as List? ?? [];

          // Check for nested showtimes structure
          if (movies.isNotEmpty) {
            final hasNestedShowtimes =
                movies.isNotEmpty &&
                (movies.first as Map).containsKey('showtimes');

            if (hasNestedShowtimes) {
              processedShowtimes = _processShowtimesFromCinemaAPI(dataMap);
            } else {
              processedShowtimes = List<Map<String, dynamic>>.from(movies);
            }
          } else if (showtimes.isNotEmpty) {
            processedShowtimes = List<Map<String, dynamic>>.from(showtimes);
          } else if (dataList.isNotEmpty) {
            processedShowtimes = List<Map<String, dynamic>>.from(dataList);
          }
          print('✅ API returned ${processedShowtimes.length} showtimes');
        }

        // Group showtimes by date for display
        final groupedByDate = _groupShowtimesByDate(processedShowtimes);
        print('🗓️ Showtimes grouped by dates: ${groupedByDate.keys.toList()}');
        print('📊 Total showtimes: ${processedShowtimes.length}');

        // If no showtimes and this is the initial load, try next date
        if (processedShowtimes.isEmpty &&
            !isAutoAdvance &&
            selectedDateIndex < _generatedDates.length - 1) {
          print('⚠️ No showtimes for $dateStr, trying next date...');
          setState(() {
            // Remove today's date and keep selectedDateIndex at 0 (now pointing to tomorrow)
            _generatedDates.removeAt(0);
            selectedDateIndex = 0;

            // Add a 7th date to maintain 6 available dates
            final lastDate =
                _generatedDates.isNotEmpty
                    ? DateTime.parse(_generatedDates.last['dateStr'] as String)
                    : DateTime.now();
            final newDate = lastDate.add(const Duration(days: 1));
            final dayName =
                [
                  'Sun',
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                ][(newDate.weekday % 7)];
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
                ][newDate.month - 1];
            _generatedDates.add({
              'label': dayName,
              'num': newDate.day.toString(),
              'month': monthName,
              'dateStr':
                  '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}',
            });
          });
          final nextDateStr = _generatedDates[selectedDateIndex]['dateStr'];
          await _fetchShowtimesForDate(nextDateStr, isAutoAdvance: true);
          return;
        }

        setState(() {
          // Display all fetched showtimes
          _showtimes = processedShowtimes;
          for (var s in processedShowtimes) {
            // Try to get screen name from multiple sources
            String screenName = 'Screen';

            // First try: screen_name field
            if (s['screen_name'] != null &&
                s['screen_name'].toString().isNotEmpty) {
              screenName = s['screen_name'].toString();
            }
            // Second try: screen object name field
            else if (s['screen'] is Map) {
              final screenName_ = s['screen']['name'];
              if (screenName_ != null && screenName_.toString().isNotEmpty) {
                screenName = screenName_.toString();
              }
            }
            // Third try: first seat type from seats array
            if (screenName == 'Screen' && s['seats'] is List) {
              final seats = s['seats'] as List;
              if (seats.isNotEmpty && seats.first is Map) {
                final firstSeatType = seats.first['type'];
                if (firstSeatType != null &&
                    firstSeatType.toString().isNotEmpty) {
                  final seatType = firstSeatType.toString();
                  screenName =
                      seatType[0].toUpperCase() + seatType.substring(1);
                }
              }
            }

            s['screen_name'] = screenName;
          }

          _availableLanguages = _extractAvailableLanguages();
          _langSelected = List<bool>.filled(_availableLanguages.length, false);
          _calculateCinemaDistances();

          if (_showtimes.isEmpty) {
            print('⚠️ No showtimes returned from API for $dateStr');
          } else {
            print('✅ Displaying ${_showtimes.length} showtimes for $dateStr');
          }
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load showtimes (${response.statusCode})';
          _isLoading = false;
        });
        print('❌ API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ Exception fetching showtimes: $e');
      setState(() {
        _errorMessage = 'Error fetching showtimes';
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
              showtime['screenName'] ?? showtime['screen']?['name'] ?? 'Screen',

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

  Map<String, List<Map<String, dynamic>>> _groupShowtimesByDate(
    List<Map<String, dynamic>> showtimes,
  ) {
    final location = ref.read(timezonLocationProvider);
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var showtime in showtimes) {
      final startTimeStr = showtime['start_time']?.toString() ?? '';
      if (startTimeStr.isEmpty) continue;

      try {
        DateTime utcTime = DateTime.parse(startTimeStr);
        if (!startTimeStr.contains('Z')) {
          utcTime = utcTime.toUtc();
        }

        final localTime = tz.TZDateTime.from(utcTime, location);
        final dateStr =
            '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}';

        if (!grouped.containsKey(dateStr)) {
          grouped[dateStr] = [];
        }
        grouped[dateStr]!.add(showtime);
      } catch (e) {
        // Fallback: try simple substring extraction
        final fallbackDateStr =
            startTimeStr.length >= 10
                ? startTimeStr.substring(0, 10)
                : startTimeStr;
        if (fallbackDateStr.isNotEmpty) {
          if (!grouped.containsKey(fallbackDateStr)) {
            grouped[fallbackDateStr] = [];
          }
          grouped[fallbackDateStr]!.add(showtime);
        }
      }
    }

    print('🗓️ GROUPED DATES: ${grouped.keys.toList()}');
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
    // Listen for region changes and navigate to home screen
    ref.listen(selectedRegionProvider, (previous, next) {
      if (previous != null && previous != next) {
        print('Region changed from $previous to $next, navigating to home...');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    final mv = widget.movie;

    String bannerImage = 'https://picsum.photos/800/500?blur=3'; // default

    if (widget.backdropPath?.isNotEmpty == true) {
      bannerImage = widget.backdropPath!;
    } else if (mv?['backdrop']?.isNotEmpty == true) {
      bannerImage = mv!['backdrop'] as String;
    } else if (mv?['image']?.isNotEmpty == true) {
      bannerImage = mv!['image'] as String;
    } else if (_showtimes.isNotEmpty) {}

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
                          if (index < _generatedDates.length) {
                            final selectedDateStr =
                                _generatedDates[index]['dateStr'];
                            print(
                              'DATE SELECTED: index=$index, dateStr=$selectedDateStr',
                            );

                            // Update index and show loading state
                            setState(() {
                              selectedDateIndex = index;
                              _isLoading = true;
                              _errorMessage = null;
                            });

                            // Fetch the data for the selected date
                            _fetchShowtimesForDate(selectedDateStr);
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
                        isShowtimePassed: _isShowtimePassed,
                        groupShowtimesByDate: _groupShowtimesByDate,
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
                        key: ValueKey(
                          '$selectedDateIndex-${_showtimes.length}',
                        ),
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

                            final groupedByDate = _groupShowtimesByDate(
                              _showtimes,
                            );

                            // Get showtimes for selected date
                            final safeIndex =
                                selectedDateIndex >= _generatedDates.length
                                    ? 0
                                    : selectedDateIndex;
                            final selectedDateStr =
                                _generatedDates[safeIndex]['dateStr'];
                            var showtimesForDate =
                                groupedByDate[selectedDateStr] ?? [];

                            final selectedLanguage =
                                selectedLangIndex == -1 ||
                                        selectedLangIndex >=
                                            _availableLanguages.length
                                    ? null
                                    : _availableLanguages[selectedLangIndex];

                            final filteredShowtimes =
                                showtimesForDate.where((showtime) {
                                  // Filter out past showtimes
                                  final startTimeStr =
                                      showtime['start_time']?.toString() ?? '';
                                  if (startTimeStr.isNotEmpty) {
                                    if (_isShowtimePassed(startTimeStr)) {
                                      return false;
                                    }
                                  }

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
                                        'No showtimes available',
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

                            final theatreShowtimes =
                                sortedTheatres[index].value;
                            final theatreName = sortedTheatres[index].key;

                            // Get cinema info from the first showtime if available
                            Map<String, dynamic> cinema;
                            if (theatreShowtimes.isNotEmpty) {
                              cinema = theatreShowtimes.first['cinema'];
                            } else {
                              // If no showtimes, find cinema info from all showtimes
                              cinema =
                                  _showtimes.firstWhere(
                                    (s) =>
                                        (s['cinema']['name'] ?? 'Unknown') ==
                                        theatreName,
                                    orElse:
                                        () => {
                                          'cinema': {
                                            'name': theatreName,
                                            'city': 'Unknown',
                                            'rating': '4.0',
                                          },
                                        },
                                  )['cinema'] ??
                                  {
                                    'name': theatreName,
                                    'city': 'Unknown',
                                    'rating': '4.0',
                                  };
                            }
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
                                      padding: const EdgeInsets.all(10),
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
                                                  width: 50,
                                                  height: 75,
                                                  color: Colors.black,
                                                  child: SvgPicture.asset(
                                                    _getCinemaLogoPath(
                                                      theatreShowtimes
                                                              .isNotEmpty
                                                          ? theatreShowtimes
                                                                  .first['chain_name'] ??
                                                              ''
                                                          : '',
                                                    ),
                                                    fit: BoxFit.contain,
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
                                          const SizedBox(height: 10),
                                          if (theatreShowtimes.isEmpty)
                                            const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Text(
                                                  'No showtimes available',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 4,
                                                    crossAxisSpacing: 8,
                                                    mainAxisSpacing: 8,
                                                    childAspectRatio: 1.2,
                                                  ),
                                              itemCount:
                                                  theatreShowtimes.length,
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
                                                            4.0,
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
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 1,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Flexible(
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
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
                                                                      fontSize:
                                                                          7,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                minPrice == 0
                                                                    ? 'Sold'
                                                                    : '\$$minPrice',
                                                                style: const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
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
                          childCount: (() {
                            if (_generatedDates.isEmpty) {
                              return 0;
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

                            final groupedByDate = _groupShowtimesByDate(
                              _showtimes,
                            );

                            // Get the specifically selected date (not searching forward)
                            var showtimesForDate =
                                groupedByDate[selectedDate] ?? [];

                            final filteredShowtimes =
                                showtimesForDate.where((showtime) {
                                  // Filter out past showtimes
                                  final startTimeStr =
                                      showtime['start_time']?.toString() ?? '';
                                  if (startTimeStr.isNotEmpty) {
                                    if (_isShowtimePassed(startTimeStr)) {
                                      return false;
                                    }
                                  }

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

                            return groupedByTheatre.length;
                          }()),
                        ),
                      ),
                  ],
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

      // Parse the datetime - handle both UTC and local formats
      DateTime dateTime = DateTime.parse(dateTimeString);

      // Ensure it's UTC
      if (!dateTimeString.contains('Z')) {
        dateTime = dateTime.toUtc();
      }

      // Get the timezone location for selected region
      final location = ref.read(timezonLocationProvider);

      // Convert UTC time to region timezone
      final regionTime = tz.TZDateTime.from(dateTime, location);

      // Format the time
      final formatter = intl.DateFormat('HH:mm');
      final formattedTime = formatter.format(regionTime);

      // DEBUG: Print conversion info
      final region = ref.read(selectedRegionProvider);
      print(
        'TIME_CONVERSION: Input=$dateTimeString, Region=$region, '
        'UTC=$dateTime, RegionTime=$regionTime, Display=$formattedTime',
      );

      return formattedTime;
    } catch (e) {
      print('Error formatting time: $e, dateTimeString: $dateTimeString');
      return 'N/A';
    }
  }

  DateTime _convertToRegionTime(DateTime utcTime, String region) {
    // Ensure input is UTC
    final utcDateTime = utcTime.isUtc ? utcTime : utcTime.toUtc();

    // Get timezone location using the timezone library
    final tzName = regionTimezoneMap[region] ?? 'Australia/Sydney';
    final location = tz.getLocation(tzName);

    // Convert UTC to region timezone
    final regionTime = tz.TZDateTime.from(utcDateTime, location);

    return regionTime;
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

  bool _isShowtimePassed(String startTimeStr) {
    try {
      // Parse the showtime
      DateTime showtime = DateTime.parse(startTimeStr);

      // Handle UTC format
      if (!startTimeStr.contains('Z')) {
        showtime = showtime.toUtc();
      }

      // Get timezone location for selected region
      final location = ref.read(timezonLocationProvider);
      final region = ref.read(selectedRegionProvider);

      // Get current time and convert to region timezone
      final now = DateTime.now().toUtc();
      final nowInRegion = tz.TZDateTime.from(now, location);
      final showtimeInRegion = tz.TZDateTime.from(showtime, location);

      // Compare times
      final isPassed = showtimeInRegion.isBefore(nowInRegion);

      if (isPassed) {
        print(
          'FILTERED_SHOWTIME: $startTimeStr (Region: $region) - '
          'Showtime: $showtimeInRegion, Now: $nowInRegion',
        );
      }

      return isPassed;
    } catch (e) {
      print('Error checking if showtime passed: $e');
      return false;
    }
  }

  bool _isPremiumScreen(String? screenName) {
    if (screenName == null) return false;

    final name = screenName.toLowerCase();

    return name.contains('recliner') ||
        name.contains('boutique') ||
        name.contains('4dx') ||
        name.contains('3d') ||
        name.contains('gold class');
  }

  bool _hasPremiumSeats(Map<String, dynamic> showtime) {
    final screenName = (showtime['screen_name'] ?? '').toString().toLowerCase();

    return screenName.contains('recliner') ||
        screenName.contains('boutique') ||
        screenName.contains('4dx') ||
        screenName.contains('3d') ||
        screenName.contains('gold class');
  }

  String _getCinemaLogoPath(String chainName) {
    final nameLower = chainName.toLowerCase().trim();
    final normalized = nameLower.replaceAll(' ', '').replaceAll('-', '');

    print('DEBUG_LOGO: chainName="$chainName", normalized="$normalized"');

    if (normalized.contains('event')) {
      print('DEBUG_LOGO: Matched EVENT');
      return 'lib/assets/event.svg';
    } else if (normalized.contains('hoyts')) {
      print('DEBUG_LOGO: Matched HOYTS');
      return 'lib/assets/hoytsau.svg';
    } else if (normalized.contains('read')) {
      print('DEBUG_LOGO: Matched READING');
      return 'lib/assets/readingau.svg';
    } else if (normalized.contains('village')) {
      print('DEBUG_LOGO: Matched VILLAGE');
      return 'lib/assets/village.svg';
    } else if (normalized.contains('country')) {
      print('DEBUG_LOGO: Matched COUNTRY');
      return 'lib/assets/country.svg';
    } else if (normalized.contains('palace')) {
      print('DEBUG_LOGO: Matched PALACE');
      return 'lib/assets/palace.svg';
    } else {
      print('DEBUG_LOGO: NO MATCH - defaulting to VILLAGE');
      return 'lib/assets/village.svg';
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
  final Function(String) isShowtimePassed;
  final Function(List<Map<String, dynamic>>) groupShowtimesByDate;

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
    required this.isShowtimePassed,
    required this.groupShowtimesByDate,
  });

  @override
  double get maxExtent => 245;

  @override
  double get minExtent => 245;

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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                    fontSize: 24,
                    letterSpacing: 1,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      color: Color(0xFFFFB64B),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(rating is String ? double.tryParse(rating) ?? 0.0 : rating as num).toStringAsFixed(1)}/10',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: 55,
              width: double.infinity,
              child:
                  generatedDates.isEmpty
                      ? const Center(
                        child: Text(
                          'Loading dates...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : Builder(
                        builder: (context) {
                          // Create a map of original index to display info
                          final dateDisplayMap = <int, Map<String, dynamic>>{};

                          for (int i = 0; i < generatedDates.length; i++) {
                            // Show all 6 generated dates
                            dateDisplayMap[i] = generatedDates[i];
                          }

                          if (dateDisplayMap.isEmpty) {
                            return const Center(
                              child: Text(
                                'No dates available',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: dateDisplayMap.length,
                            itemBuilder: (context, listIndex) {
                              final originalIndex =
                                  dateDisplayMap.keys.toList()[listIndex];
                              final selected =
                                  originalIndex == selectedDateIndex;
                              final dateData = dateDisplayMap[originalIndex]!;

                              return Padding(
                                padding: EdgeInsets.only(
                                  left: listIndex == 0 ? 12 : 8,
                                  right: 0,
                                ),
                                child: GestureDetector(
                                  onTap: () => onDateSelected(originalIndex),
                                  child: Container(
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient:
                                          selected
                                              ? AppColors.filterGradient
                                              : null,
                                      color:
                                          !selected
                                              ? AppColors.chipUnselectedBg
                                              : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dateData['label'],
                                          style: TextStyle(
                                            color:
                                                selected
                                                    ? Colors.white
                                                    : Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateData['num'],
                                          style: TextStyle(
                                            color:
                                                selected
                                                    ? Colors.white
                                                    : Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateData['month'],
                                          style: TextStyle(
                                            color:
                                                selected
                                                    ? Colors.white
                                                    : Colors.white70,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
            child: SizedBox(
              height: 24,
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
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
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
