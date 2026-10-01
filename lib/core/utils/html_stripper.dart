import 'package:html_unescape/html_unescape.dart';

/// Strips HTML tags and unescapes entities from API-provided descriptions.
/// Mirrors `core/utils/html_stripper.dart`.
class HtmlStripper {
  HtmlStripper._();

  static final _unescape = HtmlUnescape();
  static final _tagRe = RegExp(r'<[^>]*>');
  static final _wsRe = RegExp(r'[ \t]+');
  static final _nlRe = RegExp(r'\n{3,}');

  static String strip(String? html) {
    if (html == null || html.isEmpty) return '';
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(_tagRe, '');
    text = _unescape.convert(text);
    text = text.replaceAll(_wsRe, ' ').replaceAll(_nlRe, '\n\n');
    return text.trim();
  }
}
