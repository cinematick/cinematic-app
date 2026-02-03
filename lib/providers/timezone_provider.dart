import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:cinematick/providers/navigation_providers.dart';

// Map of Australian regions to timezone identifiers
const Map<String, String> regionTimezoneMap = {
  'NSW': 'Australia/Sydney',
  'VIC': 'Australia/Melbourne',
  'QLD': 'Australia/Brisbane',
  'TAS': 'Australia/Hobart',
  'SA': 'Australia/Adelaide',
  'NT': 'Australia/Darwin',
  'WA': 'Australia/Perth',
  'ACT': 'Australia/Sydney', // ACT uses same timezone as NSW
};

// Provider to get timezone location from region
final timezonLocationProvider = Provider<tz.Location>((ref) {
  final region = ref.watch(selectedRegionProvider);
  final tzName = regionTimezoneMap[region] ?? 'Australia/Sydney';
  return tz.getLocation(tzName);
});

// Provider for formatting time in selected timezone
final showtimeFormatterProvider = Provider<DateFormat>((ref) {
  return DateFormat('HH:mm');
});

// Provider for converting UTC time to selected region timezone
final convertUtcToRegionProvider = Provider<String Function(DateTime utcTime)>((
  ref,
) {
  final location = ref.watch(timezonLocationProvider);
  final formatter = ref.watch(showtimeFormatterProvider);

  return (DateTime utcTime) {
    // Ensure the input is in UTC
    final utcDateTime = utcTime.isUtc ? utcTime : utcTime.toUtc();

    // Convert to region timezone
    final regionTime = tz.TZDateTime.from(utcDateTime, location);

    // Format and return
    return formatter.format(regionTime);
  };
});

// Provider for getting current time in selected region
final currentTimeInRegionProvider = StreamProvider<DateTime>((ref) async* {
  final location = ref.watch(timezonLocationProvider);

  while (true) {
    final now = DateTime.now().toUtc();
    final regionTime = tz.TZDateTime.from(now, location);
    yield regionTime;

    // Update every second
    await Future.delayed(const Duration(seconds: 1));
  }
});

// Provider for checking if a showtime has passed in selected region
final isShowtimePassedProvider = Provider<bool Function(DateTime)>((ref) {
  final currentRegionTime = ref.watch(currentTimeInRegionProvider);

  return (DateTime showtimeUtc) {
    final currentTime = currentRegionTime.maybeWhen(
      data: (time) => time,
      orElse: () => DateTime.now(),
    );

    // Ensure showtime is in UTC
    final utcShowtime = showtimeUtc.isUtc ? showtimeUtc : showtimeUtc.toUtc();
    final location = ref.read(timezonLocationProvider);
    final showtimeRegion = tz.TZDateTime.from(utcShowtime, location);

    return showtimeRegion.isBefore(currentTime);
  };
});

// Provider to get all available timezones for Australian regions
final availableAustralianTimezonesProvider = Provider<Map<String, String>>((
  ref,
) {
  return regionTimezoneMap;
});
