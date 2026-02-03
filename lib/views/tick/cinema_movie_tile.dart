import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/providers/timezone_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'tick_controller.dart';

class CinemaMovieTile extends ConsumerWidget {
  final Map<String, dynamic> movie;
  final TickController controller;
  final String region;

  const CinemaMovieTile({
    super.key,
    required this.movie,
    required this.controller,
    required this.region,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poster = movie['posterPath'] ?? '';
    final title = movie['movieTitle'] ?? '';
    final rating = movie['rating'] ?? 0;
    final language = movie['language'] ?? 'N/A';
    final genre = movie['genre'] ?? movie['movieGenre'] ?? '';
    final chainName = movie['chainName'] ?? '';
    final cinemaName = movie['cinemaName'] ?? '';
    final cinemaAddress = movie['address'] ?? movie['cinemaAddress'] ?? '';
    final cinemaCity = movie['city'] ?? movie['cinemaCity'] ?? '';
    final minPrice = (movie['minPrice'] as num?)?.toDouble() ?? 0.0;
    final showtimes =
        (movie['showtimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A1EA9), Color(0xFF3A0E68)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ROW: Image + Title + Cinema Name + Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SMALL POSTER
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 50,
                        height: 75,
                        color: Colors.white12,
                        child:
                            poster.isNotEmpty
                                ? Image.network(poster, fit: BoxFit.cover)
                                : const Icon(
                                  Icons.local_movies,
                                  color: Colors.white30,
                                  size: 24,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // TITLE + CINEMA NAME + LANGUAGE (MIDDLE)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating == 0
                                    ? '0.0'
                                    : (rating as num).toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  language.isNotEmpty
                                      ? language[0].toUpperCase() +
                                          language.substring(1).toLowerCase()
                                      : language,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (genre.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    genre,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (chainName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        95,
                                        1,
                                        66,
                                        171,
                                      ),
                                      border: Border.all(color: Colors.white24),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      chainName,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Container(
                                      child: Text(
                                        ((movie['distance'] as num?)
                                                    ?.toStringAsFixed(1) ??
                                                'N/A') +
                                            ' km',
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            88,
                                            184,
                                            248,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 2),
                          Text(
                            cinemaName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),

                          if (cinemaCity.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      cinemaCity,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // SHOWTIMES
                if (showtimes.isNotEmpty)
                  Builder(
                    builder: (context) {
                      // Filter out past showtimes
                      final futureShowtimes =
                          showtimes.where((showtime) {
                            final timeStr = showtime['time']?.toString() ?? '';
                            if (timeStr.isEmpty) return true;
                            return !_isShowtimePassed(timeStr, ref);
                          }).toList();

                      if (futureShowtimes.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: futureShowtimes.length,
                        itemBuilder: (context, idx) {
                          final s = futureShowtimes[idx];
                          final url = s['bookingUrl'] ?? "";
                          final format = s['format'] ?? "Standard";

                          return GestureDetector(
                            onTap: () async {
                              if (url.isNotEmpty &&
                                  await canLaunchUrl(Uri.parse(url))) {
                                launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatTime(s['time'], ref),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Flexible(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            format,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          minPrice == 0
                                              ? "Sold"
                                              : "\$$minPrice",
                                          style: TextStyle(
                                            color:
                                                minPrice == 0
                                                    ? Colors.red
                                                    : Colors.green,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String? t, WidgetRef ref) {
    if (t == null) return "N/A";
    try {
      DateTime dateTime = DateTime.parse(t);

      // If the string doesn't contain 'Z', treat as local and convert to UTC
      if (!t.contains('Z')) {
        dateTime = dateTime.toUtc();
      }

      // Get timezone location for the region
      final regionTimezoneMap = ref.read(availableAustralianTimezonesProvider);
      final timezoneName = regionTimezoneMap[region] ?? 'Australia/Sydney';
      final location = tz.getLocation(timezoneName);

      // Convert UTC datetime to region timezone
      final regionalTime = tz.TZDateTime.from(dateTime, location);
      final formatter = DateFormat('HH:mm');
      final formattedTime = formatter.format(regionalTime);

      // DEBUG: Print conversion info
      print(
        'TIME_CONVERSION: Input=$t, Region=$region, UTC=${dateTime.toUtc()}, RegionTime=$regionalTime, Display=$formattedTime',
      );

      return formattedTime;
    } catch (e) {
      print('Error formatting time: $e, input: $t');
      return "N/A";
    }
  }

  bool _isShowtimePassed(String startTimeStr, WidgetRef ref) {
    try {
      DateTime showtime = DateTime.parse(startTimeStr);
      if (!startTimeStr.contains('Z')) {
        showtime = showtime.toUtc();
      }

      // Get timezone location for the region
      final regionTimezoneMap = ref.read(availableAustralianTimezonesProvider);
      final timezoneName = regionTimezoneMap[region] ?? 'Australia/Sydney';
      final location = tz.getLocation(timezoneName);

      // Get current time in region's timezone
      final nowInRegion = tz.TZDateTime.from(DateTime.now().toUtc(), location);
      final showtimeInRegion = tz.TZDateTime.from(showtime, location);

      final isPassed = showtimeInRegion.isBefore(nowInRegion);

      if (isPassed) {
        print(
          'FILTERED_SHOWTIME: $startTimeStr (Region: $region) - Showtime: $showtimeInRegion, Now: $nowInRegion',
        );
      }

      return isPassed;
    } catch (e) {
      print('Error checking if showtime passed: $e');
      return false;
    }
  }
}
