import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/providers/notification_providers.dart';
import 'package:cinematick/services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late bool _newReleases;
  late bool _specialScreenings;
  late bool _nearbySessionAlerts;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs =
        await ref
            .read(notificationRepositoryProvider)
            .getNotificationPreferences();
    setState(() {
      _newReleases = prefs['newReleases'] ?? true;
      _specialScreenings = prefs['specialScreenings'] ?? true;
      _nearbySessionAlerts = prefs['nearbySessionAlerts'] ?? true;
    });
  }

  Future<void> _updatePreferences() async {
    await ref
        .read(notificationRepositoryProvider)
        .subscribeToNotificationTopics(
          subscribeToNewReleases: _newReleases,
          subscribeToSpecialScreenings: _specialScreenings,
          subscribeToNearbySessionAlerts: _nearbySessionAlerts,
        );

    // Subscribe/unsubscribe from topics based on preferences
    final notificationService = ref.read(notificationServiceProvider);

    if (_newReleases) {
      await notificationService.subscribeToTopic(
        NotificationService.newReleaseTopic,
      );
    } else {
      await notificationService.unsubscribeFromTopic(
        NotificationService.newReleaseTopic,
      );
    }

    if (_specialScreenings) {
      await notificationService.subscribeToTopic(
        NotificationService.specialScreeningTopic,
      );
    } else {
      await notificationService.unsubscribeFromTopic(
        NotificationService.specialScreeningTopic,
      );
    }

    if (_nearbySessionAlerts) {
      await notificationService.subscribeToTopic(
        NotificationService.nearbySessionTopic,
      );
    } else {
      await notificationService.unsubscribeFromTopic(
        NotificationService.nearbySessionTopic,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preferences updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings'), elevation: 0),
      body: ListView(
        children: [
          // Notification Preferences Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _PreferenceSwitch(
                  title: 'New Releases',
                  subtitle: 'Get notified about newly released movies',
                  icon: Icons.star_rounded,
                  value: _newReleases,
                  onChanged: (value) {
                    setState(() => _newReleases = value);
                    _updatePreferences();
                  },
                ),
                const SizedBox(height: 8),
                _PreferenceSwitch(
                  title: 'Special Screenings',
                  subtitle:
                      'Get notified about exclusive and special screenings',
                  icon: Icons.event_rounded,
                  value: _specialScreenings,
                  onChanged: (value) {
                    setState(() => _specialScreenings = value);
                    _updatePreferences();
                  },
                ),
                const SizedBox(height: 8),
                _PreferenceSwitch(
                  title: 'Nearby Session Alerts',
                  subtitle:
                      'Get notified about movie sessions near your location',
                  icon: Icons.location_on_rounded,
                  value: _nearbySessionAlerts,
                  onChanged: (value) {
                    setState(() => _nearbySessionAlerts = value);
                    _updatePreferences();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // Notification Stats Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ref
                    .watch(unreadNotificationCountProvider)
                    .when(
                      data:
                          (count) => _StatCard(
                            title: 'Unread Notifications',
                            value: count.toString(),
                          ),
                      loading:
                          () => const _StatCard(
                            title: 'Unread Notifications',
                            value: '...',
                          ),
                      error:
                          (_, __) => const _StatCard(
                            title: 'Unread Notifications',
                            value: '0',
                          ),
                    ),
              ],
            ),
          ),
          const Divider(height: 32),

          // Notification History by Type
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ref
                    .watch(newReleaseNotificationsProvider)
                    .when(
                      data:
                          (notifications) => _HistoryCard(
                            title: 'New Releases',
                            count: notifications.length,
                            icon: Icons.star_rounded,
                            color: Colors.amber,
                          ),
                      loading:
                          () => const _HistoryCard(
                            title: 'New Releases',
                            count: 0,
                            icon: Icons.star_rounded,
                            color: Colors.amber,
                          ),
                      error:
                          (_, __) => const _HistoryCard(
                            title: 'New Releases',
                            count: 0,
                            icon: Icons.star_rounded,
                            color: Colors.amber,
                          ),
                    ),
                const SizedBox(height: 8),
                ref
                    .watch(specialScreeningNotificationsProvider)
                    .when(
                      data:
                          (notifications) => _HistoryCard(
                            title: 'Special Screenings',
                            count: notifications.length,
                            icon: Icons.event_rounded,
                            color: Colors.purple,
                          ),
                      loading:
                          () => const _HistoryCard(
                            title: 'Special Screenings',
                            count: 0,
                            icon: Icons.event_rounded,
                            color: Colors.purple,
                          ),
                      error:
                          (_, __) => const _HistoryCard(
                            title: 'Special Screenings',
                            count: 0,
                            icon: Icons.event_rounded,
                            color: Colors.purple,
                          ),
                    ),
                const SizedBox(height: 8),
                ref
                    .watch(nearbySessionNotificationsProvider)
                    .when(
                      data:
                          (notifications) => _HistoryCard(
                            title: 'Nearby Sessions',
                            count: notifications.length,
                            icon: Icons.location_on_rounded,
                            color: Colors.green,
                          ),
                      loading:
                          () => const _HistoryCard(
                            title: 'Nearby Sessions',
                            count: 0,
                            icon: Icons.location_on_rounded,
                            color: Colors.green,
                          ),
                      error:
                          (_, __) => const _HistoryCard(
                            title: 'Nearby Sessions',
                            count: 0,
                            icon: Icons.location_on_rounded,
                            color: Colors.green,
                          ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _HistoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
