import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cinematick/config/secrets.dart';
import 'package:cinematick/providers/navigation_providers.dart';
import 'package:cinematick/providers/timezone_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'tick_state.dart';

final tickControllerProvider = StateNotifierProvider<TickController, TickState>(
  (ref) => TickController(ref),
);

class TickController extends StateNotifier<TickState> {
  final Ref ref;
  bool _isInitialLoad = true;

  TickController(this.ref) : super(const TickState()) {
    _init();
  }

  final allExperiences = ['2D', '3D', 'IMAX', 'Dolby'];
  final allGenres = [
    'Action',
    'Comedy',
    'Drama',
    'Sci-Fi',
    'Horror',
    'Romance',
    'Thriller',
  ];

  void _init() {
    _generateDates();
    getUserLocation();
    fetchMovies();

    // Refetch movies when region changes
    ref.listen(selectedRegionProvider, (previous, next) {
      if (previous != null && previous != next) {
        print('Region changed from $previous to $next - refetching movies');
        fetchMovies();
      }
    });
  }

  Future<void> getUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      state = state.copyWith(userPosition: pos);
    } catch (_) {}
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earth = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _generateDates() {
    final now = DateTime.now();
    final list = List.generate(6, (i) {
      final date = now.add(Duration(days: i));
      final week =
          ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][(date.weekday % 7)];
      final month =
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

      return {
        'label': week,
        'num': date.day.toString(),
        'month': month,
        'dateStr':
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      };
    });

    state = state.copyWith(generatedDates: list);
  }

  Future<void> fetchMovies({bool isAutoAdvance = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final date = state.generatedDates[state.selectedDateIndex]['dateStr'];
      final region = ref.read(selectedRegionProvider);
      final res = await http.get(
        Uri.parse("$baseUrl/tick?date=$date&region=$region"),
      );

      if (res.statusCode != 200) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Failed to load movies",
        );
        return;
      }

      final data = jsonDecode(res.body);
      final movies = List<Map<String, dynamic>>.from(data);

      // Check if there are any movies with valid (non-past) showtimes for today
      final moviesWithFutureShowtimes =
          movies.where((movie) => _hasFutureShowtime(movie, region)).toList();

      // Auto-advance if no valid showtimes found on initial load
      if (moviesWithFutureShowtimes.isEmpty &&
          _isInitialLoad &&
          !isAutoAdvance &&
          state.selectedDateIndex < state.generatedDates.length - 1) {
        print('⚠️ No VALID showtimes for today, auto-advancing to tomorrow...');
        print(
          '   Current dates: ${state.generatedDates.map((d) => '${d['num']} ${d['month']}').toList()}',
        );

        // Remove today's date and keep selectedDateIndex at 0 (now pointing to tomorrow)
        final updatedDates = List<Map<String, dynamic>>.from(
          state.generatedDates,
        );
        updatedDates.removeAt(0);

        // Add a 7th date to maintain 6 available dates
        final lastDate =
            updatedDates.isNotEmpty
                ? DateTime.parse(updatedDates.last['dateStr'] as String)
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

        updatedDates.add({
          'label': dayName,
          'num': newDate.day.toString(),
          'month': monthName,
          'dateStr':
              "${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}",
        });

        state = state.copyWith(
          generatedDates: updatedDates,
          selectedDateIndex: 0,
        );

        print(
          '   ✅ Removed today, dates NOW: ${updatedDates.map((d) => '${d['num']} ${d['month']}').toList()}',
        );

        _isInitialLoad = false;
        await fetchMovies(isAutoAdvance: true);
        return;
      }

      // Mark initial load as complete
      if (_isInitialLoad) {
        _isInitialLoad = false;
      }

      final langs =
          movies
              .map((e) => (e['language'] ?? '').toString())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();

      state = state.copyWith(
        movies: movies,
        availableLanguages: langs,
        langSelected: List<bool>.filled(langs.length, false),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Error fetching movies",
      );
    }
  }

  int getMaxAvailability({String? region}) {
    int maxAvail = 0;

    // Get all movies without premium filter for KPI calculation
    for (var movie in _getMoviesWithoutPremium()) {
      // Skip movies with $0 price
      final price = (movie['minPrice'] as num?)?.toDouble() ?? 0.0;
      if (price == 0) {
        continue;
      }

      // If region is provided, only consider movies with future showtimes
      if (region != null) {
        if (!_hasFutureShowtime(movie, region)) {
          continue;
        }
      }

      final total = (movie['rawTotalSeats'] as num?)?.toInt() ?? 1;
      final available = (movie['rawAvailableSeats'] as num?)?.toInt() ?? 0;

      if (total > 0) {
        final percentage = ((available / total) * 100).toInt();
        if (percentage > maxAvail) maxAvail = percentage;
      }
    }

    return maxAvail;
  }

  bool _hasFutureShowtime(Map<String, dynamic> movie, String region) {
    final showtimes =
        (movie['showtimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    for (var showtime in showtimes) {
      final timeStr = showtime['time']?.toString() ?? '';
      if (timeStr.isEmpty) continue;

      try {
        DateTime showTime = DateTime.parse(timeStr);
        if (!timeStr.contains('Z')) {
          showTime = showTime.toUtc();
        }

        final now = DateTime.now().toUtc();
        final nowInRegion = _convertToRegionTime(now, region);
        final showtimeInRegion = _convertToRegionTime(showTime, region);

        final isPassed =
            showtimeInRegion.isBefore(nowInRegion) ||
            (showtimeInRegion.hour == nowInRegion.hour &&
                showtimeInRegion.minute == nowInRegion.minute);

        if (!isPassed) {
          return true;
        }
      } catch (e) {
        return true;
      }
    }
    return false;
  }

  DateTime _convertToRegionTime(DateTime utcTime, String region) {
    try {
      final regionTimezoneMap = ref.read(availableAustralianTimezonesProvider);
      final timezoneName = regionTimezoneMap[region] ?? 'Australia/Sydney';
      final location = tz.getLocation(timezoneName);
      final tzDateTime = tz.TZDateTime.from(utcTime, location);
      return tzDateTime;
    } catch (e) {
      print('Error converting timezone: $e');
      // Fallback to hardcoded offset if timezone conversion fails
      const Map<String, double> regionTimezoneOffsets = {
        'NSW': 11.0,
        'VIC': 11.0,
        'QLD': 10.0,
        'TAS': 11.0,
        'SA': 10.5,
        'NT': 9.5,
        'WA': 8.0,
        'ACT': 11.0,
      };
      final offset = regionTimezoneOffsets[region] ?? 10.0;
      return utcTime.add(
        Duration(hours: offset.toInt(), minutes: ((offset % 1) * 60).toInt()),
      );
    }
  }

  bool hasShowtimesForDate(int dateIndex, String region) {
    if (dateIndex >= state.generatedDates.length) return false;

    final movies = filteredMovies();
    for (var movie in movies) {
      final showtimes =
          (movie['showtimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      for (var showtime in showtimes) {
        final timeStr = showtime['time']?.toString() ?? '';
        if (timeStr.isEmpty) continue;

        try {
          DateTime showTime = DateTime.parse(timeStr);
          if (!timeStr.contains('Z')) {
            showTime = showTime.toUtc();
          }

          final now = DateTime.now().toUtc();
          final nowInRegion = _convertToRegionTime(now, region);
          final showtimeInRegion = _convertToRegionTime(showTime, region);

          final isPassed =
              showtimeInRegion.isBefore(nowInRegion) ||
              (showtimeInRegion.hour == nowInRegion.hour &&
                  showtimeInRegion.minute == nowInRegion.minute);

          if (!isPassed) {
            return true;
          }
        } catch (e) {
          return true;
        }
      }
    }
    return false;
  }

  num getCheapestPrice() {
    num cheapest = double.maxFinite;

    // Get all movies without premium filter for KPI calculation
    for (var movie in _getMoviesWithoutPremium()) {
      final price = (movie['minPrice'] as num?)?.toDouble() ?? double.maxFinite;
      // Skip prices that are 0 or less, only consider prices > 0
      if (price > 0 && price < cheapest) cheapest = price;
    }

    return cheapest == double.maxFinite ? 0 : cheapest;
  }

  void updateSelectedInfoIndex(int index) {
    state = state.copyWith(selectedInfoIndex: index, currentPage: 0);
  }

  void updateSelectedLanguage(int index) {
    state = state.copyWith(selectedLangIndex: index, currentPage: 0);
  }

  void updateSelectedDate(int index) {
    state = state.copyWith(selectedDateIndex: index, currentPage: 0);
    fetchMovies();
  }

  void updateSearch(String q) {
    state = state.copyWith(
      searchQuery: q,
      showSearchSuggestions: true,
      currentPage: 0,
    );
  }

  void closeSearchSuggestions() {
    state = state.copyWith(showSearchSuggestions: false);
  }

  void openSearchSuggestions() {
    state = state.copyWith(showSearchSuggestions: true);
  }

  List<Map<String, dynamic>> _getMoviesWithoutPremium() {
    final langIndex = state.selectedLangIndex;
    final lang =
        langIndex == -1 || langIndex >= state.availableLanguages.length
            ? null
            : state.availableLanguages[langIndex];

    final q = state.searchQuery.toLowerCase();

    return state.movies.where((m) {
      // 🎯 Language filter
      if (lang != null &&
          !m['language'].toString().toLowerCase().contains(
            lang.toLowerCase(),
          )) {
        return false;
      }

      // 🔍 Search filter
      if (q.isNotEmpty) {
        final movieMatch = m['movieTitle'].toString().toLowerCase().contains(q);

        final cinemaName =
            (m['cinemaName'] ?? m['cinema']?['name'] ?? m['theatreName'] ?? '')
                .toString()
                .toLowerCase();

        final cinemaMatch = cinemaName.contains(q);

        if (!movieMatch && !cinemaMatch) return false;
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> filteredMovies() {
    final baseMovies = _getMoviesWithoutPremium();

    // ⭐ Apply premium filter if selected (index 4)
    if (state.selectedInfoIndex == 4) {
      return baseMovies.where((m) {
        final showtimes =
            (m['showtimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        bool hasPremiumShowtime = false;
        for (var showtime in showtimes) {
          final screenName = (showtime['screen_name'] ?? '').toString();
          if (_isPremiumScreen(screenName)) {
            hasPremiumShowtime = true;
            break;
          }
        }

        return hasPremiumShowtime;
      }).toList();
    }

    return baseMovies;
  }

  List<Map<String, dynamic>> sortedMovies() {
    final list = List<Map<String, dynamic>>.from(filteredMovies());

    // Calculate distance for all movies if user location is available
    if (state.userPosition != null) {
      final pos = state.userPosition!;
      for (var movie in list) {
        double latA = (movie['latitude'] as num?)?.toDouble() ?? 0;
        double lonA = (movie['longitude'] as num?)?.toDouble() ?? 0;

        // If coordinates are missing or defaulted to 0, try to get them from city
        if (latA == 0 && lonA == 0) {
          final city =
              (movie['city'] ?? movie['cinemaCity'] ?? '')
                  .toString()
                  .toLowerCase();
          final cityCoords = _getCityCoordinates(city);
          if (cityCoords != null) {
            latA = cityCoords['lat'] ?? 0;
            lonA = cityCoords['lng'] ?? 0;
          }
        }

        // Only calculate distance if we have valid coordinates
        if (latA != 0 || lonA != 0) {
          final distance = calculateDistance(
            pos.latitude,
            pos.longitude,
            latA,
            lonA,
          );
          movie['distance'] = distance;
        } else {
          // Default to max value if no coordinates available
          movie['distance'] = double.maxFinite;
        }
      }
    }

    switch (state.selectedInfoIndex) {
      case 0:
        list.sort((a, b) {
          final pa = (a['minPrice'] as num?)?.toDouble() ?? double.maxFinite;
          final pb = (b['minPrice'] as num?)?.toDouble() ?? double.maxFinite;
          return pa.compareTo(pb);
        });
        break;

      case 1:
        // Filter out $0 movies, then sort by availability
        final availableMovies =
            list.where((m) {
              final price = (m['minPrice'] as num?)?.toDouble() ?? 0.0;
              return price > 0;
            }).toList();

        availableMovies.sort((a, b) {
          final ta = (a['rawTotalSeats'] as num?)?.toInt() ?? 1;
          final aa = (a['rawAvailableSeats'] as num?)?.toInt() ?? 0;
          final ap = (aa / ta) * 100;

          final tb = (b['rawTotalSeats'] as num?)?.toInt() ?? 1;
          final ab = (b['rawAvailableSeats'] as num?)?.toInt() ?? 0;
          final bp = (ab / tb) * 100;

          return bp.compareTo(ap);
        });

        // Return filtered and sorted list
        return availableMovies;

      case 2:
        // Filter by premium screens (Recliner, Boutique, 4DX, 3D, Gold Class) only
        final premiumMovies =
            list.where((m) {
              final showtimes =
                  (m['showtimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              for (var showtime in showtimes) {
                final screenName = (showtime['screen_name'] ?? '').toString();
                if (_isPremiumScreen(screenName)) {
                  return true;
                }
              }
              return false;
            }).toList();
        return premiumMovies;

      case 3:
        list.sort((a, b) {
          final dA = (a['distance'] as num?)?.toDouble() ?? double.maxFinite;
          final dB = (b['distance'] as num?)?.toDouble() ?? double.maxFinite;
          return dA.compareTo(dB);
        });
        break;
    }

    return list;
  }

  Map<String, double>? _getCityCoordinates(String city) {
    const cityCoordinates = {
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

    return cityCoordinates[city]?.cast<String, double>();
  }

  // Pagination methods
  List<Map<String, dynamic>> getPaginatedMovies() {
    final allMovies = sortedMovies();
    final startIndex = state.currentPage * state.itemsPerPage;
    final endIndex = math.min(
      startIndex + state.itemsPerPage,
      allMovies.length,
    );

    if (startIndex >= allMovies.length) {
      return [];
    }

    return allMovies.sublist(startIndex, endIndex);
  }

  int getTotalPages() {
    final totalMovies = sortedMovies().length;
    if (totalMovies == 0)
      return 1; // Show at least 1 page even when empty for UI consistency
    return (totalMovies / state.itemsPerPage).ceil();
  }

  void nextPage() {
    final totalPages = getTotalPages();
    if (state.currentPage < totalPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  /// Returns true if the current filtered results are empty (no movies match current filters/language)
  bool hasNoMovies() {
    return sortedMovies().isEmpty;
  }

  void goToPage(int page) {
    final totalPages = getTotalPages();
    if (page >= 0 && page < totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  bool _isPremiumScreen(String? screenName) {
    if (screenName == null) return false;

    final name = screenName.toLowerCase();

    return name.startsWith('recliner') ||
        name.startsWith('boutique') ||
        name.startsWith('4dx') ||
        name.startsWith('3d') ||
        name.startsWith('gold') ||
        name.startsWith('gold class');
  }

  void resetPagination() {
    state = state.copyWith(currentPage: 0);
  }
}
