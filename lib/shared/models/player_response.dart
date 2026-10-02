/// Playback payload for a post. Mirrors `shared/models/player_response.dart`.
///
/// The gateway returns one or more player embeds (iframe URLs) possibly with
/// translation/voice variants. We keep the raw embed URL for the WebView
/// player and expose any variant list.
class PlayerResponse {
  const PlayerResponse({
    required this.embedUrl,
    this.variants = const [],
  });

  /// Primary iframe/embed URL loaded by the WebView player.
  final String embedUrl;

  /// Alternative sources (different voices/qualities).
  final List<PlayerVariant> variants;

  bool get hasPlayer => embedUrl.isNotEmpty;

  factory PlayerResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map) ? json['data'] as Map : json;
    final rawVariants =
        (data['variants'] ?? data['sources'] ?? data['players']) as List?;
    final variants = rawVariants
            ?.whereType<Map<String, dynamic>>()
            .map(PlayerVariant.fromJson)
            .toList() ??
        const <PlayerVariant>[];

    final primary = '${data['url'] ?? data['iframe'] ?? data['embed'] ?? ''}';

    return PlayerResponse(
      embedUrl: primary.isNotEmpty
          ? primary
          : (variants.isNotEmpty ? variants.first.url : ''),
      variants: variants,
    );
  }
}

class PlayerVariant {
  const PlayerVariant({required this.title, required this.url});

  final String title;
  final String url;

  factory PlayerVariant.fromJson(Map<String, dynamic> json) => PlayerVariant(
        title: '${json['title'] ?? json['name'] ?? json['translate'] ?? 'Плеер'}',
        url: '${json['url'] ?? json['iframe'] ?? json['embed'] ?? ''}',
      );
}

/// A player's own page, loaded so it can be shown without a frame around it.
class EmbedPage {
  const EmbedPage({required this.html, required this.storageKey});

  final String html;

  /// `localStorage` key under which the player keeps the watch position.
  final String storageKey;
}
