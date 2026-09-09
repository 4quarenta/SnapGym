class ChallengeSummary {
  const ChallengeSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.startsOn,
    required this.endsOn,
    required this.targetDays,
    required this.creatorId,
    required this.creatorUsername,
    required this.participantCount,
    required this.joined,
    required this.progressDays,
  });

  factory ChallengeSummary.fromJson(Map<String, dynamic> json) {
    return ChallengeSummary(
      id: json['challenge_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startsOn: DateTime.parse(json['starts_on'] as String),
      endsOn: DateTime.parse(json['ends_on'] as String),
      targetDays: (json['target_days'] as num).toInt(),
      creatorId: json['creator_id'] as String,
      creatorUsername: json['creator_username'] as String,
      participantCount: (json['participant_count'] as num).toInt(),
      joined: json['joined'] as bool? ?? false,
      progressDays: (json['progress_days'] as num).toInt(),
    );
  }

  final String id;
  final String title;
  final String description;
  final DateTime startsOn;
  final DateTime endsOn;
  final int targetDays;
  final String creatorId;
  final String creatorUsername;
  final int participantCount;
  final bool joined;
  final int progressDays;

  double get progress {
    if (targetDays <= 0) return 0;
    return (progressDays / targetDays).clamp(0, 1).toDouble();
  }
}

class ChallengeRankingEntry {
  const ChallengeRankingEntry({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.activeDays,
    required this.checkins,
    required this.rank,
  });

  factory ChallengeRankingEntry.fromJson(Map<String, dynamic> json) {
    return ChallengeRankingEntry(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      activeDays: (json['active_days'] as num).toInt(),
      checkins: (json['checkins'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
    );
  }

  final String userId;
  final String username;
  final String displayName;
  final int activeDays;
  final int checkins;
  final int rank;
}
