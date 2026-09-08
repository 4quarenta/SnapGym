import '../../checkin/domain/workout_type.dart';

class FeedCheckin {
  const FeedCheckin({
    required this.id,
    required this.userId,
    required this.workoutType,
    required this.durationMinutes,
    required this.note,
    required this.photoUrl,
    required this.performedAt,
    required this.username,
    required this.displayName,
  });

  final String id;
  final String userId;
  final WorkoutType workoutType;
  final int durationMinutes;
  final String? note;
  final String photoUrl;
  final DateTime performedAt;
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
