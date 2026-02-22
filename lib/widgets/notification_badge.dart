import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/providers/notification_providers.dart';

/// A widget that displays a badge with the count of unread notifications
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final TextStyle? badgeTextStyle;
  final Color? badgeColor;
  final EdgeInsets? padding;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeTextStyle,
    this.badgeColor,
    this.padding = const EdgeInsets.all(2),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return unreadCount.when(
      data: (count) {
        if (count == 0) {
          return child;
        }

        return Badge(
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style:
                badgeTextStyle ??
                const TextStyle(color: Colors.white, fontSize: 10),
          ),
          backgroundColor: badgeColor ?? Colors.red,
          padding: padding,
          alignment: Alignment.topRight,
          child: child,
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

/// A floating action button that shows unread notification count
class NotificationFAB extends ConsumerWidget {
  final VoidCallback? onPressed;

  const NotificationFAB({super.key, this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return unreadCount.when(
      data: (count) {
        return FloatingActionButton(
          onPressed: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading:
          () => FloatingActionButton(
            onPressed: onPressed,
            child: const Icon(Icons.notifications),
          ),
      error:
          (_, __) => FloatingActionButton(
            onPressed: onPressed,
            child: const Icon(Icons.notifications),
          ),
    );
  }
}
