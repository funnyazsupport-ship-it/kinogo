import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/error_retry_row.dart';
import 'providers/movie_provider.dart';

/// Full-screen WebView player loading the gateway's embed URL.
/// Mirrors `features/movie/player_screen.dart`.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.id, this.title});
  final int id;
  final String? title;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  WebViewController? _controller;
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

  void _initWebView(String url) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(AppConfig.userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider(widget.id));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title ?? 'Просмотр'),
      ),
      body: player.when(
        data: (p) {
          if (!p.hasPlayer) {
            return const Center(
              child: Text('Плеер недоступен',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          _controller ??= (() {
            _initWebView(p.embedUrl);
            return _controller;
          })();
          return Stack(
            children: [
              if (_controller != null)
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
