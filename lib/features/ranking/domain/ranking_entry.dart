class RankingEntry {
  const RankingEntry({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.activeDays,
    required this.checkins,
    required this.totalMinutes,
    required this.rank,
    this.avatarKey,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
    userId: json['user_id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    avatarKey: json['avatar_key'] as String?,
    activeDays: (json['active_days'] as num).toInt(),
    checkins: (json['checkins'] as num).toInt(),
    totalMinutes: (json['total_minutes'] as num).toInt(),
    rank: (json['rank'] as num).toInt(),
  );

  final String userId;
  final String username;
  final String displayName;
  final String? avatarKey;
  final int activeDays;
  final int checkins;
  final int totalMinutes;
  final int rank;
}

class StreakSummary {
  const StreakSummary({
    required this.current,
    required this.best,
    required this.trainedToday,
  });

  factory StreakSummary.fromJson(Map<String, dynamic> json) => StreakSummary(
    current: (json['current_streak'] as num).toInt(),
    best: (json['best_streak'] as num).toInt(),
    trainedToday: json['trained_today'] as bool,
  );

  final int current;
  final int best;
  final bool trainedToday;
}
