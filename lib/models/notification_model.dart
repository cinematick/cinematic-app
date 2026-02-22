enum NotificationType {
  newRelease('new_release'),
  specialScreening('special_screening'),
  nearbySession('nearby_session');

  final String value;
  const NotificationType(this.value);

  factory NotificationType.fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.newRelease,
    );
  }
}

class PushNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? imageUrl;
  final String? movieId;
  final String? screeningId;
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;
  final bool isRead;

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.imageUrl,
    this.movieId,
    this.screeningId,
    this.additionalData,
    required this.timestamp,
    this.isRead = false,
  });

  factory PushNotification.fromFirebase({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return PushNotification(
      id: id,
      title: data['title'] ?? 'New Notification',
      body: data['body'] ?? '',
      type: NotificationType.fromString(data['type'] ?? 'new_release'),
      imageUrl: data['imageUrl'],
      movieId: data['movieId'],
      screeningId: data['screeningId'],
      additionalData: data['additionalData'],
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.value,
    'imageUrl': imageUrl,
    'movieId': movieId,
    'screeningId': screeningId,
    'additionalData': additionalData,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'new_release'),
      imageUrl: json['imageUrl'],
      movieId: json['movieId'],
      screeningId: json['screeningId'],
      additionalData: json['additionalData'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
    );
  }

  PushNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? imageUrl,
    String? movieId,
    String? screeningId,
    Map<String, dynamic>? additionalData,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return PushNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      movieId: movieId ?? this.movieId,
      screeningId: screeningId ?? this.screeningId,
      additionalData: additionalData ?? this.additionalData,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'PushNotification(id: $id, title: $title, type: ${type.value}, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PushNotification &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.isRead == isRead;
  }

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ type.hashCode ^ isRead.hashCode;
}
