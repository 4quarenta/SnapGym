class SocialProfile {
  const SocialProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.followerCount,
    required this.followingCount,
    required this.checkinCount,
    required this.isFollowing,
  });

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      followerCount: _asInt(json['follower_count']),
      followingCount: _asInt(json['following_count']),
      checkinCount: _asInt(json['checkin_count']),
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  final String id;
  final String? username;
  final String? displayName;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final int checkinCount;
  final bool isFollowing;

  String get name {
    final value = displayName?.trim();
    if (value != null && value.isNotEmpty) return value;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';
    return 'Atleta SnapGym';
  }

  String? get handle {
    final value = username?.trim();
    if (value == null || value.isEmpty) return null;
    return '@$value';
  }

  String get initial => name.characters.first.toUpperCase();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}
