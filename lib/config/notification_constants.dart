/// Notification related constants and configuration
class NotificationConstants {
  // FCM Topics
  static const String newReleaseTopic = 'new_releases';
  static const String specialScreeningTopic = 'special_screenings';
  static const String nearbySessionTopic = 'nearby_sessions';

  // Notification types
  static const String typeNewRelease = 'new_release';
  static const String typeSpecialScreening = 'special_screening';
  static const String typeNearbySession = 'nearby_session';

  // Notification channels (Android)
  static const String newReleaseChannelId = 'new_releases_channel';
  static const String specialScreeningChannelId = 'special_screenings_channel';
  static const String nearbySessionChannelId = 'nearby_sessions_channel';

  static const String newReleaseChannelName = 'New Releases';
  static const String specialScreeningChannelName = 'Special Screenings';
  static const String nearbySessionChannelName = 'Nearby Sessions';

  // Default notification settings
  static const bool defaultNewReleasesEnabled = true;
  static const bool defaultSpecialScreeningsEnabled = true;
  static const bool defaultNearbySessionsEnabled = true;
}
