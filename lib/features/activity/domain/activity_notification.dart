enum ActivityNotificationKind {
  follow('follow'),
  like('like'),
  comment('comment'),
  challengeJoin('challenge_join');

  const ActivityNotificationKind(this.dbValue);

  final String dbValue;

  static ActivityNotificationKind fromDb(String value) {
    return ActivityNotificationKind.values.firstWhere(
      (kind) => kind.dbValue == value,
      orElse: () => ActivityNotificationKind.follow,
    );
  }
}

class ActivityNotification {
  const ActivityNotification({
    required this.id,
    required this.kind,
    required this.actorId,
    required this.createdAt,
    this.actorUsername,
    this.actorDisplayName,
    this.checkinId,
    this.workoutType,
    this.commentBody,
    this.challengeId,
    this.challengeTitle,
    this.readAt,
  });

  factory ActivityNotification.fromJson(Map<String, dynamic> json) {
    return ActivityNotification(
      id: json['notification_id'] as String,
      kind: ActivityNotificationKind.fromDb(json['kind'] as String),
      actorId: json['actor_id'] as String,
      actorUsername: json['actor_username'] as String?,
      actorDisplayName: json['actor_display_name'] as String?,
      checkinId: json['checkin_id'] as String?,
      workoutType: json['workout_type'] as String?,
      commentBody: json['comment_body'] as String?,
      challengeId: json['challenge_id'] as String?,
      challengeTitle: json['challenge_title'] as String?,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final ActivityNotificationKind kind;
  final String actorId;
  final String? actorUsername;
  final String? actorDisplayName;
  final String? checkinId;
  final String? workoutType;
  final String? commentBody;
  final String? challengeId;
  final String? challengeTitle;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  String get actorName {
    final displayName = actorDisplayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final username = actorUsername?.trim();
    if (username != null && username.isNotEmpty) return '@$username';
    return 'Alguém';
  }
}
