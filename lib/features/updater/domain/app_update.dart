class AppUpdate {
  const AppUpdate({
    required this.platform,
    required this.channel,
    required this.versionName,
    required this.buildNumber,
    required this.isMandatory,
    required this.publishedAt,
    this.downloadUrl,
    this.actionUrl,
    this.sha256,
    this.releaseNotes,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      platform: json['platform'] as String,
      channel: json['channel'] as String,
      versionName: json['version_name'] as String,
      buildNumber: json['build_number'] as int,
      downloadUrl: json['download_url'] as String?,
      actionUrl: json['action_url'] as String?,
      sha256: json['sha256'] as String?,
      releaseNotes: json['release_notes'] as String?,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }

  final String platform;
  final String channel;
  final String versionName;
  final int buildNumber;
  final String? downloadUrl;
  final String? actionUrl;
  final String? sha256;
  final String? releaseNotes;
  final bool isMandatory;
  final DateTime publishedAt;
}

bool isNewerBuild({required int currentBuild, required int candidateBuild}) {
  return candidateBuild > currentBuild;
}
