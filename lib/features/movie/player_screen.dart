import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/player_response.dart';
import '../../shared/widgets/error_retry_row.dart';
import 'providers/movie_provider.dart';

/// Full-screen WebView player showing the movie's embed.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.id, this.title});
  final int id;
  final String? title;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  WebViewController? _controller;
  String? _currentUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// The embed hosts only answer when framed by the site (they check the
  /// Referer), so the embed is loaded as an iframe inside a page whose base
  /// URL is the site itself rather than navigated to directly.
  String _framePage(String url) => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
iframe { position: fixed; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe src="${const HtmlEscape(HtmlEscapeMode.attribute).convert(url)}" allowfullscreen allow="autoplay; encrypted-media; fullscreen; picture-in-picture" referrerpolicy="strict-origin-when-cross-origin"></iframe>
</body>
</html>''';

  WebViewController _createController() {
    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    return WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(AppConfig.userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Embeds may try to redirect the whole page to ads; keep the top
          // frame on the wrapper page and let the iframe navigate freely.
          onNavigationRequest: (request) {
            if (!request.isMainFrame ||
                request.url.startsWith(AppConfig.siteBaseUrl) ||
                request.url.startsWith('about:')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
  }

  void _load(String url) {
    _currentUrl = url;
    _loading = true;
    (_controller ??= _createController())
        .loadHtmlString(_framePage(url), baseUrl: '${AppConfig.siteBaseUrl}/');
  }

  void _select(PlayerVariant variant) {
    if (variant.url == _currentUrl) return;
    setState(() => _load(variant.url));
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider(widget.id));
    final variants = player.valueOrNull?.variants ?? const <PlayerVariant>[];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title ?? 'Просмотр'),
        actions: [
          if (variants.length > 1)
            PopupMenuButton<PlayerVariant>(
              icon: const Icon(Icons.video_library_outlined),
              tooltip: 'Выбрать плеер',
              onSelected: _select,
              itemBuilder: (_) => [
                for (final v in variants)
                  CheckedPopupMenuItem(
                    value: v,
                    checked: v.url == _currentUrl,
                    child: Text(v.title),
                  ),
              ],
            ),
        ],
      ),
      body: player.when(
        data: (p) {
          if (!p.hasPlayer) {
            return const Center(
              child: Text('Плеер недоступен',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          if (_controller == null) _load(p.embedUrl);
          return Stack(
            children: [
              WebViewWidget(controller: _controller!),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (_, __) => Center(
          child: ErrorRetryRow(onRetry: () => ref.invalidate(playerProvider(widget.id))),
        ),
      ),
    );
  }
}
