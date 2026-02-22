import 'package:cinematick/config/secrets.dart';
import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/widgets/custom_bottom_nav.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:cinematick/providers/timezone_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:cinematick/widgets/info_row_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

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
  String _firstMovieRating = 'N/A';
  List<Map<String, dynamic>> _generatedDates = [];
  Position? _userPosition;
  Map<String, double> _cinemaDistances = {};
  List<String> _availableLanguages = [];
  String _movieSearchQuery = '';
  String _genreSearchQuery = '';
  late TextEditingController _movieSearchController;
  late TextEditingController _genreSearchController;
  final FocusNode _movieSearchFocusNode = FocusNode();
  bool _showMovieSuggestions = false;
  bool _isInitialLoad = true;

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
  List<String> _availableGenres = [];

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
    selectedDateIndex = 0; 
    _xpSelected = List<bool>.filled(_allExperiences.length, false);
    _langSelected = [];
    _genreSelected = [];
    _generatedDates = _generateDates();
    _getUserLocation();
    _fetchShowtimes();
  }

  @override
  void dispose() {
    _movieSearchFocusNode.dispose();
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

  String _calculateApiDateForRegion(String localDateStr, String region) {
    try {
      final parts = localDateStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final regionTimezoneMap = ref.read(availableAustralianTimezonesProvider);
      final timezoneName = regionTimezoneMap[region] ?? 'Australia/Sydney';
      final location = tz.getLocation(timezoneName);

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

      final utcTime = midnightLocal.toUtc();

      final dayAfter = nextDay.add(const Duration(days: 1));
      final nextDayLocal = tz.TZDateTime(
        location,
        dayAfter.year,
        dayAfter.month,
        dayAfter.day,
        0,
        0,
        0,
      );
      final nextDayUtc = nextDayLocal.toUtc();

      final apiDate =
          '${utcTime.year}-${utcTime.month.toString().padLeft(2, '0')}-${utcTime.day.toString().padLeft(2, '0')}';

      return apiDate;
    } catch (e) {
      return localDateStr; 
    }
  }

  Future<void> _fetchShowtimes({bool isAutoAdvance = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

      final region = ref.read(selectedRegionProvider);
      final apiDate = _calculateApiDateForRegion(dateStr, region);

      if (widget.cinemaId != null && widget.cinemaId!.isNotEmpty) {
        print(
          'Fetching showtimes for Cinema ID: ${widget.cinemaId}, Local Date: $dateStr => API Date: $apiDate',
        );
        final response = await http.get(
          Uri.parse('$baseUrl/cinemas/${widget.cinemaId}?date=$apiDate'),
        );
        _processShowtimesFromCinemaAPI(response, isAutoAdvance: isAutoAdvance);
      } else {
        print(
          'Fetching showtimes for TMDB ID: ${widget.tmdbId}, Local Date: $dateStr => API Date: $apiDate',
        );
        final response = await http.get(
          Uri.parse('$baseUrl/movies/${widget.tmdbId}/showtimes?date=$apiDate'),
        );
        _processShowtimesFromMovieAPI(response, isAutoAdvance: isAutoAdvance);
      }
    } catch (e) {
      if (!mounted) return;
      print('Exception in _fetchShowtimes');
      setState(() {
        _errorMessage = 'Error fetching showtimes';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchShowtimesForSpecificDate(
    String dateStr, {
    bool isAutoAdvance = false,
  }) async {
    if (!mounted) return;

    try {
      final region = ref.read(selectedRegionProvider);
      final apiDate = _calculateApiDateForRegion(dateStr, region);

      if (widget.cinemaId != null && widget.cinemaId!.isNotEmpty) {
        print(
          'Fetching showtimes for Cinema ID: ${widget.cinemaId}, Local Date: $dateStr => API Date: $apiDate',
        );
        final response = await http.get(
          Uri.parse('$baseUrl/cinemas/${widget.cinemaId}?date=$apiDate'),
        );
        if (mounted) {
          _processShowtimesFromCinemaAPI(
            response,
            isAutoAdvance: isAutoAdvance,
          );
        }
      } else {
        print(
          'Fetching showtimes for TMDB ID: ${widget.tmdbId}, Local Date: $dateStr => API Date: $apiDate',
        );
        final response = await http.get(
          Uri.parse('$baseUrl/movies/${widget.tmdbId}/showtimes?date=$apiDate'),
        );
        if (mounted) {
          _processShowtimesFromMovieAPI(response, isAutoAdvance: isAutoAdvance);
        }
      }
    } catch (e) {
      if (!mounted) return;
      print('Exception in _fetchShowtimesForSpecificDate: $e');
    }
  }

  void _processShowtimesFromCinemaAPI(
    http.Response response, {
    bool isAutoAdvance = false,
  }) {
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
          final movieGenres = (movie['genres'] as List?)?.cast<String>() ?? [];
          final movieVoteAverage = movie['voteAverage'];

          if (_firstMovieRating == 'N/A' && movieVoteAverage != null) {
            try {
              final ratingValue =
                  (movieVoteAverage is num)
                      ? movieVoteAverage
                      : double.parse(movieVoteAverage.toString());
              final doubleValue =
                  (ratingValue is num)
                      ? (ratingValue as num).toDouble()
                      : ratingValue;
              _firstMovieRating = doubleValue.toStringAsFixed(1);
            } catch (e) {
              _firstMovieRating = 'N/A';
            }
          }

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
              'movie_vote_average': movieVoteAverage ?? 0,
              'genres': movieGenres,
              'language':
                  showtime['language'] ??
                  _getFirstLanguage(movie['language']) ??
                  'english',
              'seats': [
                {'type': 'standard', 'price': showtime['minPrice']},
              ],
              'seatTypes': showtime['seatTypes'] ?? [],
              'isPremium': showtime['isPremium'] ?? false,
              'total_seats': showtime['totalSeats'],
              'total_seats_available': showtime['availableSeats'],
            });
          }
        }

        print('Processed ${flatShowtimes.length} showtimes from cinema API');
        print(
          '   isAutoAdvance=$isAutoAdvance, selectedDateIndex=$selectedDateIndex, generatedDatesLength=${_generatedDates.length}',
        );

        final firstDateStr =
            _generatedDates.isNotEmpty ? _generatedDates[0]['dateStr'] : '';
        final showtimesForFirstDate =
            flatShowtimes.where((showtime) {
              final startTimeStr = showtime['start_time']?.toString() ?? '';
              String showDate =
                  startTimeStr.length >= 10
                      ? startTimeStr.substring(0, 10)
                      : startTimeStr;
              return showDate == firstDateStr;
            }).toList();

        final validShowtimesForFirstDate =
            showtimesForFirstDate.where((showtime) {
              return !_isShowtimePassed(
                showtime['start_time']?.toString() ?? '',
              );
            }).toList();

        if (validShowtimesForFirstDate.isEmpty &&
            !isAutoAdvance &&
            _generatedDates.isNotEmpty &&
            _generatedDates.length > 1) {
          print(
            '⚠️ TRIGGERING AUTO-ADVANCE (Cinema API): No VALID showtimes found for ${_generatedDates[0]['dateStr']}',
          );
          print(
            '   Current dates: ${_generatedDates.map((d) => '${d['num']} ${d['month']}').toList()}',
          );

          final nextDateStr = _generatedDates[1]['dateStr'];

          _generatedDates.removeAt(0);
          selectedDateIndex = 0;

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

          setState(() {
            _isLoading = true;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchShowtimesForSpecificDate(nextDateStr, isAutoAdvance: true);
          });
          return;
        }

        if (_isInitialLoad) {
          _isInitialLoad = false;
        }
        setState(() {
          _showtimes = flatShowtimes;
          _availableLanguages = _extractAvailableLanguages();
          _availableGenres = _extractAvailableGenres();
          _langSelected = List<bool>.filled(_availableLanguages.length, false);
          _genreSelected = List<bool>.filled(_availableGenres.length, false);
          _calculateCinemaDistances();
          _isLoading = false;
          if (!isAutoAdvance) {
            _skipToFirstDateWithShowtimes();
          }
        });
      } catch (e) {
        print('Error parsing cinema API response');
        setState(() {
          _errorMessage = 'Error parsing showtimes';
          _isLoading = false;
        });
      }
    } else {
      print('API Error');
      setState(() {
        _errorMessage = 'Failed to load showtimes ';
        _isLoading = false;
      });
    }
  }

  void _processShowtimesFromMovieAPI(
    http.Response response, {
    bool isAutoAdvance = false,
  }) {
    if (!mounted) return;

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Decoded data length: ${data.length}');

      if (data.isEmpty) {
        print('WARNING: API returned empty list of showtimes');

        if (_generatedDates.isNotEmpty && _generatedDates.length > 1) {
          print(
            '⚠️ TRIGGERING AUTO-ADVANCE (Movie API): No showtimes found for ${_generatedDates[0]['dateStr']}',
          );
          print(
            '   Current dates: ${_generatedDates.map((d) => '${d['num']} ${d['month']}').toList()}',
          );

          final nextDateStr = _generatedDates[1]['dateStr'];

          _generatedDates.removeAt(0);
          selectedDateIndex = 0;

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

          print(
            '   ✅ Removed date, dates NOW: ${_generatedDates.map((d) => '${d['num']} ${d['month']}').toList()}',
          );

          setState(() {
            _isLoading = true;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchShowtimesForSpecificDate(nextDateStr, isAutoAdvance: true);
          });
          return;
        }

        if (_isInitialLoad) {
          _isInitialLoad = false;
        }

        setState(() {
          _showtimes = [];
          _availableLanguages = [];
          _langSelected = [];
          _isLoading = false;
          _errorMessage = 'No showtimes available for this movie';
        });
        return;
      }

      final firstDateStr =
          _generatedDates.isNotEmpty ? _generatedDates[0]['dateStr'] : '';
      final newShowtimes = List<Map<String, dynamic>>.from(data);

      final showtimesForFirstDate =
          newShowtimes.where((showtime) {
            final startTimeStr = showtime['start_time']?.toString() ?? '';
            String showDate =
                startTimeStr.length >= 10
                    ? startTimeStr.substring(0, 10)
                    : startTimeStr;
            return showDate == firstDateStr;
          }).toList();

      final validShowtimesForFirstDate =
          showtimesForFirstDate.where((showtime) {
            return !_isShowtimePassed(showtime['start_time']?.toString() ?? '');
          }).toList();

      if (validShowtimesForFirstDate.isEmpty &&
          !isAutoAdvance &&
          _generatedDates.isNotEmpty &&
          _generatedDates.length > 1) {
        print(
          '⚠️ TRIGGERING AUTO-ADVANCE (Movie API): No valid showtimes for ${_generatedDates[0]['dateStr']}',
        );
        print(
          '   Current dates: ${_generatedDates.map((d) => '${d['num']} ${d['month']}').toList()}',
        );

        final nextDateStr = _generatedDates[1]['dateStr'];

        _generatedDates.removeAt(0);
        selectedDateIndex = 0;

        final lastDate =
            _generatedDates.isNotEmpty
                ? DateTime.parse(_generatedDates.last['dateStr'] as String)
                : DateTime.now();
        final newDate = lastDate.add(const Duration(days: 1));
        final dayName =
            ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][(newDate.weekday %
                7)];
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

        print(
          '   ✅ Removed date, dates NOW: ${_generatedDates.map((d) => '${d['num']} ${d['month']}').toList()}',
        );

        setState(() {
          _isLoading = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchShowtimesForSpecificDate(nextDateStr, isAutoAdvance: true);
        });
        return;
      }

      setState(() {
        final newShowtimes = List<Map<String, dynamic>>.from(data);

        if (newShowtimes.isEmpty) {
          print(
            'API returned empty data - keeping existing ${_showtimes.length} showtimes',
          );
        } else if (_showtimes.isNotEmpty) {
          final existingDates = _groupShowtimesByDate(_showtimes).keys.toSet();
          final newDates = _groupShowtimesByDate(newShowtimes).keys.toSet();

          if (newDates.isNotEmpty && !existingDates.containsAll(newDates)) {
            _showtimes.addAll(newShowtimes);
            print('Merged ${newShowtimes.length} new showtimes');
          } else {
            _showtimes = newShowtimes;
            print('Replaced showtimes with ${newShowtimes.length} items');
          }
        } else {
          _showtimes = newShowtimes;
        }

        _availableLanguages = _extractAvailableLanguages();
        _availableGenres = _extractAvailableGenres();
        _langSelected = List<bool>.filled(_availableLanguages.length, false);
        _genreSelected = List<bool>.filled(_availableGenres.length, false);
        _calculateCinemaDistances();
        print(
          'Loaded ${_showtimes.length} total showtimes with ${_generatedDates.length} unique dates',
        );
        for (var date in _generatedDates) {
          print(
            'Date: ${date['label']} ${date['num']} ${date['month']} (${date['dateStr']})',
          );
        }
        print('Available languages: $_availableLanguages');
        print('Available genres: $_availableGenres');
        _isLoading = false;
        if (!isAutoAdvance) {
          _skipToFirstDateWithShowtimes();
        }
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
      final startTimeStr = showtime['start_time']?.toString() ?? '';
      String dateStr =
          startTimeStr.length >= 10
              ? startTimeStr.substring(0, 10)
              : startTimeStr;
      if (dateStr.isNotEmpty && dateStr != 'null') {
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

  List<String> _extractAvailableGenres() {
    final genreSet = <String>{};
    for (var showtime in _showtimes) {
      final genres = showtime['genres'] as List?;
      if (genres != null) {
        for (var genre in genres) {
          final genreStr = genre as String?;
          if (genreStr != null && genreStr.isNotEmpty) {
            genreSet.add(genreStr);
          }
        }
      }
    }
    return genreSet.toList()..sort();
  }

  String? _getFirstLanguage(dynamic language) {
    if (language == null) return null;
    if (language is List && language.isNotEmpty) {
      return language.first.toString().toLowerCase().trim();
    }
    return language.toString().toLowerCase().trim();
  }

  void _skipToFirstDateWithShowtimes() {
    if (_generatedDates.isEmpty || _showtimes.isEmpty) {
      selectedDateIndex = 0;
      return;
    }

    for (int i = 0; i < _generatedDates.length; i++) {
      final dateStr = _generatedDates[i]['dateStr'];

      final showtimesForDate =
          _showtimes.where((showtime) {
            final startTimeStr = showtime['start_time']?.toString() ?? '';
            String showDate =
                startTimeStr.length >= 10
                    ? startTimeStr.substring(0, 10)
                    : startTimeStr;
            return showDate == dateStr;
          }).toList();

      final validShowtimes =
          showtimesForDate
              .where(
                (showtime) =>
                    !_isShowtimePassed(
                      showtime['start_time']?.toString() ?? '',
                    ),
              )
              .toList();

      if (validShowtimes.isNotEmpty) {
        selectedDateIndex = i;
        print('First date with valid showtimes: $dateStr (index: $i)');
        return;
      }
    }
    selectedDateIndex = 0;
  }

  void _ensureFiltersReady() {
    if (_xpSelected.length != _allExperiences.length) {
      _xpSelected = List<bool>.filled(_allExperiences.length, false);
    }
    if (_genreSelected.length != _availableGenres.length) {
      _genreSelected = List<bool>.filled(_availableGenres.length, false);
    }
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final len1 = s1.length;
    final len2 = s2.length;
    final maxLen = len1 > len2 ? len1 : len2;

    final d = List<List<int>>.generate(
      len1 + 1,
      (i) => List<int>.generate(len2 + 1, (j) => 0),
    );

    for (int i = 0; i <= len1; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return 1.0 - (d[len1][len2] / maxLen);
  }

  bool _fuzzyMatch(String query, String text) {
    if (query.isEmpty) return true;
    if (text.isEmpty) return false;

    final normalizedQuery = query.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      '',
    );
    final normalizedText = text.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      '',
    );

    if (normalizedText.contains(normalizedQuery)) return true;

    var queryIdx = 0;
    for (
      int i = 0;
      i < normalizedText.length && queryIdx < normalizedQuery.length;
      i++
    ) {
      if (normalizedText[i] == normalizedQuery[queryIdx]) {
        queryIdx++;
      }
    }
    if (queryIdx == normalizedQuery.length) return true;

    final similarity = _calculateSimilarity(normalizedQuery, normalizedText);
    return similarity > 0.65; 
  }

  double _getMatchScore(String query, String text) {
    final normalizedQuery = query.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      '',
    );
    final normalizedText = text.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      '',
    );

    if (normalizedText == normalizedQuery) return 100.0;

    if (normalizedText.startsWith(normalizedQuery)) return 90.0;

    if (normalizedText.contains(normalizedQuery)) return 80.0;

    var queryIdx = 0;
    var matchCount = 0;
    for (
      int i = 0;
      i < normalizedText.length && queryIdx < normalizedQuery.length;
      i++
    ) {
      if (normalizedText[i] == normalizedQuery[queryIdx]) {
        queryIdx++;
        matchCount++;
      }
    }
    if (queryIdx == normalizedQuery.length) {
      return 70.0 * (matchCount / normalizedQuery.length);
    }

    return _calculateSimilarity(normalizedQuery, normalizedText) * 60.0;
  }

  List<String> _getMovieSuggestions(String query) {
    if (query.isEmpty) {
      return [];
    }

    final movieTitles = <String>{};
    for (var showtime in _showtimes) {
      final title = showtime['movie_title'] as String?;
      if (title != null && title.isNotEmpty) {
        movieTitles.add(title);
      }
    }

    final matches = <Map<String, dynamic>>[];
    for (var title in movieTitles) {
      if (_fuzzyMatch(query, title)) {
        final score = _getMatchScore(query, title);
        matches.add({'title': title, 'score': score});
      }
    }

    matches.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return matches.map((m) => m['title'] as String).toList();
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
    ref.listen(selectedRegionProvider, (previous, next) {
      if (previous != null && previous != next) {
        print(
          'Region changed from $previous to $next, navigating to cinema screen...',
        );
        Navigator.of(context).pop();
      }
    });

    _ensureFiltersReady();
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF2B1967),
      drawerEnableOpenDragGesture: false,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: FilterSheetWidget(
          allLanguages: _availableLanguages,
          allExperiences: _allExperiences,
          allGenres: _availableGenres,
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
      bottomNavigationBar: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: CustomBottomNav(
          currentIndex: 1,
          onTap: (index) {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                ref.read(bottomNavIndexProvider.notifier).state = index;
                if (index != 1) {
                  ref.read(selectedCinemaChainProvider.notifier).state = null;
                  ref.read(selectedCinemaLocationProvider.notifier).state =
                      null;
                  ref.read(selectedMovieTitleProvider.notifier).state = null;
                }
              }
            });
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _showMovieSuggestions = false;
              });
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 0),
                    child: CustomAppBar(),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    title:
                        widget.cinemaCity ?? widget.movie?['title'] ?? 'Cinema',
                    rating: _firstMovieRating,
                    generatedDates: _generatedDates,
                    selectedDateIndex: selectedDateIndex,
                    onDateSelected: (index) {
                      setState(() {
                        selectedDateIndex = index;
                      });
                      _fetchShowtimes(isAutoAdvance: true);
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
                        _showMovieSuggestions = true;
                      });
                    },
                    onGenreSearchChanged: (query) {
                      setState(() {
                        _genreSearchQuery = query;
                      });
                    },
                    movieSearchController: _movieSearchController,
                    genreSearchController: _genreSearchController,
                    getMovieSuggestions: _getMovieSuggestions,
                    isShowtimePassed: _isShowtimePassed,
                    movieSearchFocusNode: _movieSearchFocusNode,
                    showMovieSuggestions: _showMovieSuggestions,
                    onMovieSearchFocus: () {
                      setState(() {
                        _showMovieSuggestions = true;
                      });
                    },
                    onCloseSuggestions: () {
                      setState(() {
                        _showMovieSuggestions = false;
                      });
                    },
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

                        final groupedByDate = _groupShowtimesByDate(_showtimes);
                        final showtimesForDate =
                            groupedByDate[selectedDate] ?? [];

                        final selectedLanguage =
                            selectedLangIndex == -1 ||
                                    selectedLangIndex >=
                                        _availableLanguages.length
                                ? null
                                : _availableLanguages[selectedLangIndex];

                        final selectedExperiences = <String>[];
                        for (int i = 0; i < _xpSelected.length; i++) {
                          if (_xpSelected[i]) {
                            selectedExperiences.add(_allExperiences[i]);
                          }
                        }

                        final selectedGenres = <String>[];
                        for (int i = 0; i < _genreSelected.length; i++) {
                          if (_genreSelected[i]) {
                            selectedGenres.add(_allGenres[i]);
                          }
                        }

                        final filteredShowtimes =
                            showtimesForDate.where((showtime) {
                              final startTimeStr =
                                  showtime['start_time']?.toString() ?? '';
                              if (startTimeStr.isNotEmpty) {
                                if (_isShowtimePassed(startTimeStr)) {
                                  return false;
                                }
                              }

                              if (selectedLanguage != null) {
                                final language = showtime['language'] ?? '';
                                if (!language.toString().toLowerCase().contains(
                                  selectedLanguage.toLowerCase(),
                                )) {
                                  return false;
                                }
                              }

                              if (selectedGenres.isNotEmpty) {
                                final genreList =
                                    (showtime['genres'] as List?)
                                        ?.cast<String>() ??
                                    (showtime['movie_genres'] as List?)
                                        ?.cast<String>() ??
                                    [];
                                bool hasMatchingGenre = false;
                                for (final genre in selectedGenres) {
                                  if (genreList.any(
                                    (g) =>
                                        g.toLowerCase() == genre.toLowerCase(),
                                  )) {
                                    hasMatchingGenre = true;
                                    break;
                                  }
                                }
                                if (!hasMatchingGenre) {
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

                        if (selectedInfoIndex == 2) {
                          theatreMovieList.sort((a, b) {
                            final aPremiumCount =
                                (a['showtimes'] as List)
                                    .where((s) => s['isPremium'] == true)
                                    .length;

                            final bPremiumCount =
                                (b['showtimes'] as List)
                                    .where((s) => s['isPremium'] == true)
                                    .length;

                            return bPremiumCount.compareTo(aPremiumCount);
                          });
                        }

                        if (_movieSearchQuery.isNotEmpty ||
                            _genreSearchQuery.isNotEmpty) {
                          theatreMovieList =
                              theatreMovieList.where((item) {
                                final movieTitle =
                                    (item['movie_title'] as String)
                                        .toLowerCase();
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
                                    final genreList =
                                        (showtime['genres'] as List?)
                                            ?.cast<String>() ??
                                        (showtime['movie_genres'] as List?)
                                            ?.cast<String>() ??
                                        [];
                                    return genreList.any(
                                      (genre) => genre.toLowerCase().contains(
                                        genreSearchLower,
                                      ),
                                    );
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
                        } else {
                          theatreMovieList.sort((a, b) {
                            final minPriceA = _getMinPrice(a['showtimes']);
                            final minPriceB = _getMinPrice(b['showtimes']);
                            return minPriceA.compareTo(minPriceB);
                          });
                        }

                        if (index == 0 && filteredShowtimes.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white30,
                                    size: 48,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No showtimes available',
                                    style: TextStyle(
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

                        final movieTitle =
                            theatreMovieList[index]['movie_title'];
                        final theatreShowtimes =
                            theatreMovieList[index]['showtimes'];
                        final firstShowtime = theatreShowtimes.first;

                        return GestureDetector(
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Container(
                                              width: 50,
                                              height: 75,
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
                                                              Icons
                                                                  .local_movies,
                                                              color:
                                                                  Colors
                                                                      .white30,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
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
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      _formatMovieRating(
                                                        firstShowtime['movie_vote_average'],
                                                      ),
                                                      style: const TextStyle(
                                                        color: Color.fromRGBO(
                                                          255,
                                                          255,
                                                          255,
                                                          1,
                                                        ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white12,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
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
                                                          color: Colors.white70,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (theatreShowtimes.isNotEmpty)
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3,
                                                crossAxisSpacing: 8,
                                                mainAxisSpacing: 8,
                                                childAspectRatio: 1.8,
                                              ),
                                          itemCount: theatreShowtimes.length,
                                          itemBuilder: (context, idx) {
                                            final showtime =
                                                theatreShowtimes[idx];
                                            final seatTypes =
                                            (showtime['seatTypes'] as List?)?.cast<String>() ?? [];

                                            final seatLabel = seatTypes.isNotEmpty
                                                ? seatTypes.join(', ')
                                                : 'Standard';

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
                                                              s['price'] as num,
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
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
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
                                                          height: 6,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            
                                                            Expanded(
                                                              child: Text(
                                                                seatLabel,
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: const TextStyle(
                                                                  color: Colors.white70,
                                                                  fontSize: 8,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),

                                                            ),
                                                            Text(
                                                              '\$$minPrice',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 8,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
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
                                
                                final selectedExperiences = <String>[];
                                for (int i = 0; i < _xpSelected.length; i++) {
                                  if (_xpSelected[i]) {
                                    selectedExperiences.add(_allExperiences[i]);
                                  }
                                }

                                final selectedGenres = <String>[];
                                for (
                                  int i = 0;
                                  i < _genreSelected.length;
                                  i++
                                ) {
                                  if (_genreSelected[i]) {
                                    selectedGenres.add(_allGenres[i]);
                                  }
                                }

                                final groupedByDate = _groupShowtimesByDate(
                                  _showtimes,
                                );
                                final showtimesForDate =
                                    groupedByDate[selectedDate] ?? [];
                                final filteredShowtimes =
                                    showtimesForDate.where((showtime) {
                                      final startTimeStr =
                                          showtime['start_time']?.toString() ??
                                          '';
                                      if (startTimeStr.isNotEmpty) {
                                        if (_isShowtimePassed(startTimeStr)) {
                                          return false;
                                        }
                                      }
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
                                      if (selectedExperiences.isNotEmpty) {
                                        final screenName =
                                            (showtime['screen_name'] ?? '')
                                                .toString()
                                                .toUpperCase();
                                        bool hasMatchingExperience = false;
                                        for (final exp in selectedExperiences) {
                                          if (screenName.contains(
                                            exp.toUpperCase(),
                                          )) {
                                            hasMatchingExperience = true;
                                            break;
                                          }
                                        }
                                        if (!hasMatchingExperience) {
                                          return false;
                                        }
                                      }
                                      if (selectedGenres.isNotEmpty) {
                                        final genreList =
                                            (showtime['genres'] as List?)
                                                ?.cast<String>() ??
                                            (showtime['movie_genres'] as List?)
                                                ?.cast<String>() ??
                                            [];
                                        bool hasMatchingGenre = false;
                                        for (final genre in selectedGenres) {
                                          if (genreList.any(
                                            (g) =>
                                                g.toLowerCase() ==
                                                genre.toLowerCase(),
                                          )) {
                                            hasMatchingGenre = true;
                                            break;
                                          }
                                        }
                                        if (!hasMatchingGenre) {
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
                                return totalCount > 0 ? totalCount : 1;
                              }()),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);

      if (!dateTimeString.contains('Z')) {
        dateTime = dateTime.toUtc();
      }

      final region = ref.read(selectedRegionProvider);
      final regionTimezoneMap = ref.read(availableAustralianTimezonesProvider);
      final timezoneName = regionTimezoneMap[region] ?? 'Australia/Sydney';
      final location = tz.getLocation(timezoneName);

      final regionalTime = tz.TZDateTime.from(dateTime, location);
      final formatter = DateFormat('HH:mm');
      final formattedTime = formatter.format(regionalTime);

      return formattedTime;
    } catch (e) {
      print('Error formatting time: $e');
      return 'N/A';
    }
  }

  bool _isShowtimePassed(String startTimeStr) {
    try {
      DateTime showtime = DateTime.parse(startTimeStr);

      if (!startTimeStr.contains('Z')) {
        showtime = showtime.toUtc();
      }

      final region = ref.read(selectedRegionProvider);
      final regionTimezoneMap = ref.read(availableAustralianTimezonesProvider);
      final timezoneName = regionTimezoneMap[region] ?? 'Australia/Sydney';
      final location = tz.getLocation(timezoneName);

      final nowInRegion = tz.TZDateTime.from(DateTime.now().toUtc(), location);
      final showtimeInRegion = tz.TZDateTime.from(showtime, location);

      final isPassed = showtimeInRegion.isBefore(nowInRegion);

      return isPassed;
    } catch (e) {
      print('Error checking if showtime passed: $e');
      return false;
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

  String _formatMovieRating(dynamic rating) {
    try {
      if (rating == null || rating == 0) return 'N/A';
      final ratingValue =
          (rating is num) ? rating : double.parse(rating.toString());
      final doubleValue =
          (ratingValue is num) ? (ratingValue as num).toDouble() : ratingValue;
      return doubleValue.toStringAsFixed(1);
    } catch (e) {
      return 'N/A';
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
  final String? cinemaCity;
  final int? screenCount;
  final String movieSearchQuery;
  final Function(String) onMovieSearchChanged;
  final String genreSearchQuery;
  final Function(String) onGenreSearchChanged;
  final TextEditingController movieSearchController;
  final TextEditingController genreSearchController;
  final Function(String) getMovieSuggestions;
  final Function(String) isShowtimePassed;
  final FocusNode movieSearchFocusNode;
  final bool showMovieSuggestions;
  final VoidCallback onMovieSearchFocus;
  final VoidCallback onCloseSuggestions;
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
    this.cinemaCity,
    this.screenCount,
    required this.movieSearchQuery,
    required this.onMovieSearchChanged,
    required this.genreSearchQuery,
    required this.onGenreSearchChanged,
    required this.movieSearchController,
    required this.genreSearchController,
    required this.getMovieSuggestions,
    required this.isShowtimePassed,
    required this.movieSearchFocusNode,
    required this.showMovieSuggestions,
    required this.onMovieSearchFocus,
    required this.onCloseSuggestions,
    required this.groupShowtimesByDate,
  });

  @override
  double get maxExtent => 270;

  @override
  double get minExtent => 270;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${cinemaCity ?? title} • ${screenCount ?? 10} Screens',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: movieSearchController,
                          onChanged: onMovieSearchChanged,
                          focusNode: movieSearchFocusNode,
                          onTap: onMovieSearchFocus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Search movies...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                            suffixIcon:
                                movieSearchQuery.isNotEmpty
                                    ? GestureDetector(
                                      onTap: () {
                                        movieSearchController.clear();
                                        onMovieSearchChanged('');
                                        onCloseSuggestions();
                                      },
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 14,
                                      ),
                                    )
                                    : null,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                          ),
                          cursorColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onFilterTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: Colors.white.withOpacity(0.7),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              Padding(
                padding: const EdgeInsets.only(bottom: 2),
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
                              final dateDisplayMap =
                                  <int, Map<String, dynamic>>{};

                              for (int i = 0; i < generatedDates.length; i++) {
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
                                  final dateData =
                                      dateDisplayMap[originalIndex]!;

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      left: listIndex == 0 ? 12 : 8,
                                      right: 0,
                                    ),
                                    child: GestureDetector(
                                      onTap:
                                          () => onDateSelected(originalIndex),
                                      child: Container(
                                        width: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                padding: const EdgeInsets.only(bottom: 6, top: 6, left: 8),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                padding: const EdgeInsets.only(bottom: 6),
                child: Builder(
                  builder: (context) {
                    final safeIndex =
                        selectedDateIndex >= generatedDates.length
                            ? 0
                            : selectedDateIndex;
                    final selectedDate = generatedDates[safeIndex]['dateStr'];

                    Map<String, List<Map<String, dynamic>>> groupedByDate = {};
                    for (var showtime in showtimes) {
                      final startTimeStr =
                          showtime['start_time']?.toString() ?? '';
                      String dateStr =
                          startTimeStr.length >= 10
                              ? startTimeStr.substring(0, 10)
                              : startTimeStr;
                      if (dateStr.isNotEmpty) {
                        if (!groupedByDate.containsKey(dateStr)) {
                          groupedByDate[dateStr] = [];
                        }
                        groupedByDate[dateStr]!.add(showtime);
                      }
                    }

                    final showtimesForDate = groupedByDate[selectedDate] ?? [];

                    final filteredShowtimesForSummary =
                        showtimesForDate.where((showtime) {
                          final startTimeStr =
                              showtime['start_time']?.toString() ?? '';
                          if (startTimeStr.isNotEmpty) {
                            if (isShowtimePassed(startTimeStr)) {
                              return false;
                            }
                          }
                          return true;
                        }).toList();

                    num cheapestPrice = double.maxFinite;
                    for (var showtime in filteredShowtimesForSummary) {
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
                    for (var showtime in filteredShowtimesForSummary) {
                      final availableSeats =
                          (showtime['total_seats_available'] as num?)
                              ?.toInt() ??
                          0;
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
                      showNearest: false,
                    );
                  },
                ),
              ),
            ],
          ),
          if (showMovieSuggestions &&
              movieSearchQuery.isNotEmpty &&
              getMovieSuggestions(movieSearchQuery).isNotEmpty)
            Positioned(
              top: 116,
              left: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: getMovieSuggestions(movieSearchQuery).length,
                  itemBuilder: (context, index) {
                    final suggestions = getMovieSuggestions(movieSearchQuery);

                    final String movieTitle = suggestions[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          movieSearchController.text = movieTitle;
                          onMovieSearchChanged(movieTitle);
                          onCloseSuggestions();
                          movieSearchFocusNode.unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.movie,
                                size: 18,
                                color: Color(0xFFB863D7),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movieTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Movie',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
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
                  },
                ),
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
        oldDelegate.genreSearchQuery != genreSearchQuery ||
        oldDelegate.showMovieSuggestions != showMovieSuggestions;
  }
}
