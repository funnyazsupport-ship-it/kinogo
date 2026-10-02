import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/api/api_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/player_response.dart';
import '../../shared/models/watch_progress.dart';
import '../../shared/widgets/error_retry_row.dart';
import '../history/providers/watch_progress_provider.dart';
import 'player_hook.dart';

/// How to open the player.
class PlayerArgs {
  const PlayerArgs({this.title, this.resume = false});

  final String? title;

  /// Continue from the saved position instead of waiting for a tap.
  final bool resume;
}

enum _Phase { loading, failed, unavailable, ready }

/// Menu value of the "framed mode" switch (player variants use their index).
const int _frameModeItem = -1;

/// Full-screen WebView player.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.id,
    this.title,
    this.resume = false,
  });

  final int id;
  final String? title;
  final bool resume;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final _webViewKey = GlobalKey();
  WebViewController? _controller;

  _Phase _phase = _Phase.loading;
  List<PlayerVariant> _variants = const [];
  int _index = 0;

  /// The page is still loading inside the WebView.
  bool _pageLoading = true;
  bool _landscape = true;

  /// The player is shown directly and reports position and play state.
  bool _tracked = false;

  /// Show players the old way, inside a frame: no position tracking, but it
  /// does not depend on the player's page being loaded by the app. Switched on
  /// by hand from the menu, or by itself when the direct way keeps failing.
  bool _useFrame = false;
  bool _playing = false;
  bool _controlsDimmed = false;
  Timer? _dimTimer;

  /// Bumped on every (re)load so that a slow earlier load cannot overwrite a
  /// newer one.
  int _generation = 0;
  bool _allowMainFrameLoad = false;
  String? _embedHost;

  /// Reloads made in response to the player's errors since it last played.
  int _autoReloads = 0;

  @override
  void initState() {
    super.initState();
    _applyOrientation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open(resume: widget.resume);
    });
  }

  @override
  void dispose() {
    _dimTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Rotate back first: merely allowing every orientation again leaves the
    // interface sideways when the device's rotation lock is on.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp])
        .then((_) => SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    super.dispose();
  }

  /// The player forces its orientation instead of just allowing rotation, so
  /// it turns sideways even with the device's rotation lock on.
  void _applyOrientation() {
    SystemChrome.setPreferredOrientations(
      _landscape
          ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : const [DeviceOrientation.portraitUp],
    );
    SystemChrome.setEnabledSystemUIMode(
      _landscape ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _toggleOrientation() {
    setState(() => _landscape = !_landscape);
    _applyOrientation();
  }

  /// Loads the player. The movie page is fetched anew every time: its player
  /// links are short-lived, and a stale one ends in the player's HTTP 403.
  Future<void> _open({required bool resume, int? index}) async {
    final generation = ++_generation;
    _dimTimer?.cancel();
    setState(() {
      _phase = _Phase.loading;
      _pageLoading = true;
      _playing = false;
      _controlsDimmed = false;
    });

    final service = ref.read(kinogoWebServiceProvider);
    try {
      final player = await service.fetchPlayer(widget.id);
      if (!mounted || generation != _generation) return;
      if (!player.hasPlayer) {
        setState(() => _phase = _Phase.unavailable);
        return;
      }
      final i = (index ?? _index).clamp(0, player.variants.length - 1);
      final url = player.variants[i].url;
      final embed = _useFrame ? null : await service.fetchEmbedPage(url);
      if (!mounted || generation != _generation) return;

      final controller = _controller ??= _createController();
      _allowMainFrameLoad = true;
      _embedHost = Uri.tryParse(url)?.host;
      if (embed != null) {
        final hook = buildPlayerHook(
          storageKey: embed.storageKey,
          seed: ref.read(watchProgressProvider)[widget.id]?.stored,
          resume: resume,
        );
        await controller.loadHtmlString(
          injectPlayerHook(embed.html, hook),
          baseUrl: url,
        );
      } else {
        await controller.loadHtmlString(
          _framePage(url),
          baseUrl: '${AppConfig.siteBaseUrl}/',
        );
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _variants = player.variants;
        _index = i;
        _tracked = embed != null;
        _phase = _Phase.ready;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _phase = _Phase.failed);
    }
  }

  /// Players that cannot be shown directly only answer when framed by the
  /// site (they check the Referer), so they are loaded as an iframe inside a
  /// page whose base URL is the site itself.
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
      ..addJavaScriptChannel(kPlayerChannel, onMessageReceived: _onPlayerMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageFinished: (_) {
            _allowMainFrameLoad = false;
            if (mounted) setState(() => _pageLoading = false);
          },
        ),
      );
  }

  /// Only the page loaded by [_open] may occupy the top frame; anything else
  /// is an ad trying to take over the screen. Frames inside it are free.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (!request.isMainFrame || request.url.startsWith('about:')) {
      return NavigationDecision.navigate;
    }
    if (_allowMainFrameLoad) {
      _allowMainFrameLoad = false;
      return NavigationDecision.navigate;
    }
    // The player asking to reload itself: its link is spent by now, so load
    // a new one instead.
    if (_tracked && Uri.tryParse(request.url)?.host == _embedHost) {
      scheduleMicrotask(() {
        if (mounted) _open(resume: true);
      });
    }
    return NavigationDecision.prevent;
  }

  void _onPlayerMessage(JavaScriptMessage message) {
    final Object? data;
    try {
      data = jsonDecode(message.message);
    } catch (_) {
      return;
    }
    if (!mounted || data is! Map<String, dynamic>) return;

    switch (data['type']) {
      case 'progress':
        final time = (data['time'] as num?)?.toDouble() ?? 0;
        if (time < 1) return;
        ref.read(watchProgressProvider.notifier).save(
              WatchProgress.fromPlayer(
                postId: widget.id,
                time: time,
                duration: (data['duration'] as num?)?.toDouble() ?? 0,
                stored: data['stored'] as String?,
                titles: (data['titles'] as List?)?.whereType<String>().toList() ??
                    const [],
              ),
            );
        // Playback that got this far means the last reload helped.
        _autoReloads = 0;
      case 'state':
        _playing = data['playing'] == true;
        _wakeControls();
      case 'tap':
        _wakeControls();
      case 'notice':
        _onNotice('${data['text']}');
    }
  }

  /// The player's error dialogs. An expired link ("HTTP ошибка ответа: 403")
  /// is cured by loading the page again, which the app does by itself. If the
  /// error comes straight back, the player is reopened the old way, in a
  /// frame.
  void _onNotice(String text) {
    if (!RegExp('403|[Оо]шибк|Не удалось').hasMatch(text)) return;
    _autoReloads++;
    if (_autoReloads == 1) {
      _open(resume: true);
    } else if (_autoReloads == 2) {
      _useFrame = true;
      _open(resume: false);
    }
  }

  /// Shows the app's own buttons at full strength, then lets them fade while
  /// the video plays so they stay out of the way.
  void _wakeControls() {
    _dimTimer?.cancel();
    if (_controlsDimmed) setState(() => _controlsDimmed = false);
    if (_tracked && _playing) {
      _dimTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _controlsDimmed = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      IconButton(
        icon: Icon(_landscape
            ? Icons.stay_current_portrait
            : Icons.screen_rotation),
        color: Colors.white,
        tooltip: _landscape ? 'Вертикально' : 'На весь экран',
        onPressed: _toggleOrientation,
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        color: Colors.white,
        tooltip: 'Перезагрузить плеер',
        onPressed: () {
          _autoReloads = 0;
          _open(resume: true);
        },
      ),
      PopupMenuButton<int>(
        icon: const Icon(Icons.video_library_outlined, color: Colors.white),
        tooltip: 'Плеер',
        onSelected: (i) {
          _autoReloads = 0;
          if (i == _frameModeItem) {
            _useFrame = !_useFrame;
            _open(resume: !_useFrame);
          } else if (i != _index) {
            _open(resume: false, index: i);
          }
        },
        itemBuilder: (_) => [
          for (var i = 0; i < _variants.length; i++)
            CheckedPopupMenuItem(
              value: i,
              checked: i == _index,
              child: Text(_variants[i].title),
            ),
          if (_variants.isNotEmpty) const PopupMenuDivider(),
          CheckedPopupMenuItem(
            value: _frameModeItem,
            checked: _useFrame,
            child: const Text('Совместимый режим'),
          ),
        ],
      ),
    ];

    final Widget content = switch (_phase) {
      _Phase.loading =>
        const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      _Phase.failed => Center(
          child: ErrorRetryRow(onRetry: () => _open(resume: widget.resume)),
        ),
      _Phase.unavailable => const Center(
          child: Text('Плеер недоступен',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      _Phase.ready => Stack(
          children: [
            WebViewWidget(key: _webViewKey, controller: _controller!),
            if (_pageLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
          ],
        ),
    };

    return Scaffold(
      backgroundColor: Colors.black,
      // Sideways the video gets the whole screen; the controls move into a
      // small overlay instead of an app bar.
      appBar: _landscape
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              title: Text(widget.title ?? 'Просмотр'),
              actions: actions,
            ),
      body: SafeArea(
        top: !_landscape,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: content),
            if (_landscape)
              // On the right edge, mid-height: the one area the player keeps
              // free (its episode selectors sit top-left, its own buttons
              // along the bottom).
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AnimatedOpacity(
                    opacity: _controlsDimmed ? 0.3 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: Colors.white,
                            tooltip: 'Закрыть',
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          ...actions,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
