/// Where the user stopped watching a post.
class WatchProgress {
  const WatchProgress({
    required this.postId,
    required this.time,
    this.duration = 0,
    this.season,
    this.episode,
    this.stored,
    this.updatedAt = 0,
  });

  final int postId;

  /// Position and length of the current video, in seconds.
  final double time;
  final double duration;

  /// Set for series only.
  final int? season;
  final int? episode;

  /// The value the player keeps in its own storage
  /// (`{playlist-path}time--duration--timestamp`). Handing it back lets the
  /// player reopen the same episode and offer to continue.
  final String? stored;

  /// Milliseconds since epoch.
  final int updatedAt;

  /// Builds progress from what the player reports. The playlist path inside
  /// [stored] names the episode (`...-s01e02-...`); [titles] are the labels
  /// of the player's selectors ("Сезон 1", "Серия 2", ...).
  factory WatchProgress.fromPlayer({
    required int postId,
    required double time,
    required double duration,
    String? stored,
    List<String> titles = const [],
    int? updatedAt,
  }) {
    int? season;
    int? episode;
    final id = RegExp(r's(\d+)e(\d+)').firstMatch(stored?.split('}').first ?? '');
    if (id != null) {
      season = int.tryParse(id.group(1)!);
      episode = int.tryParse(id.group(2)!);
    } else {
      for (final title in titles) {
        final number = int.tryParse(RegExp(r'\d+').firstMatch(title)?.group(0) ?? '');
        final lower = title.toLowerCase();
        if (lower.contains('сезон')) season = number;
        if (lower.contains('серия')) episode = number;
      }
    }
    return WatchProgress(
      postId: postId,
      time: time,
      duration: duration,
      season: season,
      episode: episode,
      stored: stored,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool get isSeries => season != null || episode != null;

  /// Watched share of the current video, 0..1.
  double get fraction =>
      duration > 0 ? (time / duration).clamp(0.0, 1.0).toDouble() : 0;

  bool get isFinished => duration > 0 && time >= duration * 0.97;

  /// The player itself offers to continue from 3 seconds on.
  bool get canResume => time >= 3 && !isFinished;

  /// "12:34" or "1:02:03".
  String get position {
    final total = time.floor();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  /// "1 сезон 2 серия", or null for a film.
  String? get episodeLabel {
    if (!isSeries) return null;
    return [
      if (season != null) '$season сезон',
      if (episode != null) '$episode серия',
    ].join(' ');
  }

  /// "Продолжить с 12:34" / "Продолжить — 1 сезон 2 серия с 12:34".
  String get resumeLabel => isSeries
      ? 'Продолжить — $episodeLabel с $position'
      : 'Продолжить с $position';

  /// "1 сезон 2 серия · 12:34" / "12:34".
  String get shortLabel => isSeries ? '$episodeLabel · $position' : position;

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'time': time,
        'duration': duration,
        'season': season,
        'episode': episode,
        'stored': stored,
        'updatedAt': updatedAt,
      };

  factory WatchProgress.fromJson(Map<String, dynamic> json) {
    double asDouble(Object? v) => v is num ? v.toDouble() : 0;
    int? asInt(Object? v) => v is num ? v.toInt() : null;
    return WatchProgress(
      postId: asInt(json['postId']) ?? 0,
      time: asDouble(json['time']),
      duration: asDouble(json['duration']),
      season: asInt(json['season']),
      episode: asInt(json['episode']),
      stored: json['stored'] as String?,
      updatedAt: asInt(json['updatedAt']) ?? 0,
    );
  }
}
