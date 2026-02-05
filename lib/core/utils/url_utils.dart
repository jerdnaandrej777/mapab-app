import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Erlaubte URL-Schemes fuer launchUrl()
const _allowedSchemes = {'http', 'https', 'tel', 'mailto'};

/// Sichere URL-Oeffnung mit Scheme-Validierung.
/// Verhindert javascript:, data: und andere potentiell unsichere Schemes.
Future<bool> launchUrlSafe(
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  if (!_allowedSchemes.contains(uri.scheme.toLowerCase())) {
    debugPrint('[URL] Blockiertes Scheme: ${uri.scheme}');
    return false;
  }

  try {
    return await launchUrl(uri, mode: mode);
  } catch (e) {
    debugPrint('[URL] Fehler beim Oeffnen: $e');
    return false;
  }
}

/// Sichere URL-Oeffnung aus String mit Validierung.
Future<bool> launchUrlStringSafe(
  String url, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    debugPrint('[URL] Ungueltige URL: $url');
    return false;
  }
  return launchUrlSafe(uri, mode: mode);
}
