class CheckinComment {
  const CheckinComment({
    required this.id,
    required this.checkinId,
    required this.userId,
    required this.body,
    required this.createdAt,
    required this.username,
    required this.displayName,
  });

  factory CheckinComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return CheckinComment(
      id: json['id'] as String,
      checkinId: json['checkin_id'] as String,
      userId: json['user_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      username: profile?['username'] as String?,
      displayName: profile?['display_name'] as String?,
    );
  }

  final String id;
  final String checkinId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String? username;
  final String? displayName;

  String get authorName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';
    return 'Atleta SnapGym';
  }
}
