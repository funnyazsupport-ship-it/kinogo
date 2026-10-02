import 'dart:convert';

/// Name of the JavaScript channel the hook reports to.
const String kPlayerChannel = 'KinogoPlayer';

/// Script placed at the top of the player page, before the player's own code.
///
/// The player (PlayerJS) announces everything through a global
/// `PlayerjsEvents(event, id, info)` callback and keeps the watch position in
/// `localStorage` under [storageKey]. The hook:
///  * puts [seed] (a position saved earlier) back into that storage, so the
///    player reopens the same episode and offers to continue;
///  * forwards position, play state and error notices to the app;
///  * with [resume], presses the player's own "continue" button once it shows.
String buildPlayerHook({
  required String storageKey,
  String? seed,
  bool resume = false,
}) =>
    _hookSource
        .replaceAll('__KEY__', jsonEncode(storageKey))
        .replaceAll('__SEED__', jsonEncode(seed))
        .replaceAll('__RESUME__', resume ? 'true' : 'false')
        .replaceAll('__CHANNEL__', kPlayerChannel);

/// Inserts the hook into the player page.
String injectPlayerHook(String html, String hook) {
  final tag = '<script>$hook</script>';
  final head = RegExp('<head[^>]*>', caseSensitive: false).firstMatch(html);
  if (head == null) return '$tag$html';
  return html.replaceRange(head.end, head.end, tag);
}

// PLAYER-HOOK-BEGIN
const String _hookSource = r'''
(function () {
  if (window.__kgHook) return;
  window.__kgHook = true;
  var KEY = __KEY__, SEED = __SEED__, RESUME = __RESUME__;
  try {
    if (SEED) localStorage.setItem(KEY, SEED);
  } catch (e) {}

  function send(o) {
    try {
      window.__CHANNEL__.postMessage(JSON.stringify(o));
    } catch (e) {}
  }

  var time = 0, duration = 0, lastSent = 0, lastNotice = '';

  function titles() {
    var out = [];
    var nodes = document.querySelectorAll('.playlist-title');
    for (var i = 0; i < nodes.length; i++) {
      var t = (nodes[i].textContent || '').replace(/\s+/g, ' ').trim();
      if (t) out.push(t);
    }
    return out;
  }

  function report(force) {
    var now = Date.now();
    if (!force && now - lastSent < 4000) return;
    lastSent = now;
    var stored = null;
    try {
      stored = localStorage.getItem(KEY);
    } catch (e) {}
    if (!duration) {
      var v = document.querySelector('video');
      if (v && isFinite(v.duration)) duration = v.duration;
    }
    send({type: 'progress', time: time, duration: duration, titles: titles(), stored: stored});
  }

  var original = null;
  function hook(event, id, info) {
    try {
      if (event === 'time') {
        time = parseFloat(info) || 0;
        report(false);
      } else if (event === 'duration') {
        duration = parseFloat(info) || 0;
      } else if (event === 'new') {
        time = 0;
        duration = 0;
      } else if (event === 'play') {
        send({type: 'state', playing: true});
      } else if (event === 'pause' || event === 'finish') {
        send({type: 'state', playing: false});
        report(true);
      } else if (event === 'seek') {
        report(true);
      } else if (event === 'click') {
        send({type: 'tap'});
      }
    } catch (e) {}
    var result = original ? original.apply(this, arguments) : undefined;
    if (event === 'init') {
      send({type: 'ready'});
      if (RESUME) {
        setTimeout(function () {
          var c = document.querySelector('.continue');
          if (c) c.click();
        }, 400);
      }
    }
    return result;
  }
  try {
    Object.defineProperty(window, 'PlayerjsEvents', {
      configurable: true,
      get: function () { return hook; },
      set: function (fn) { original = fn; }
    });
  } catch (e) {}

  setInterval(function () {
    var n = document.querySelector('.notice-dialog__message, .notice-error');
    var t = n ? (n.textContent || '').replace(/\s+/g, ' ').trim() : '';
    if (t && t !== lastNotice) send({type: 'notice', text: t});
    lastNotice = t;
  }, 1500);
})();
''';
// PLAYER-HOOK-END
