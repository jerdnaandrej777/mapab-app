/// Seed-Script: Importiert curated_pois.json in Supabase PostGIS
///
/// Verwendung:
///   dart run backend/scripts/seed_curated_pois.dart \
///     --url=https://your-project.supabase.co \
///     --key=your-service-role-key
///
/// WICHTIG: Verwende den service_role Key (nicht anon), da RLS INSERT
/// nur fuer authentifizierte User erlaubt ist.
///
/// Idempotent: Kann mehrfach ausgefuehrt werden (Upsert-Semantik).

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Liest curated_pois.json und laed alle POIs per upsert_poi RPC hoch
Future<void> main(List<String> args) async {
  // Args parsen
  String? supabaseUrl;
  String? serviceRoleKey;

  for (final arg in args) {
    if (arg.startsWith('--url=')) {
      supabaseUrl = arg.substring('--url='.length);
    } else if (arg.startsWith('--key=')) {
      serviceRoleKey = arg.substring('--key='.length);
    }
  }

  if (supabaseUrl == null || serviceRoleKey == null) {
    stderr.writeln('Verwendung:');
    stderr.writeln('  dart run backend/scripts/seed_curated_pois.dart \\');
    stderr.writeln('    --url=https://your-project.supabase.co \\');
    stderr.writeln('    --key=your-service-role-key');
    exit(1);
  }

  // JSON laden
  final jsonFile = File('assets/data/curated_pois.json');
  if (!jsonFile.existsSync()) {
    stderr.writeln('FEHLER: assets/data/curated_pois.json nicht gefunden.');
    stderr.writeln('Fuehre das Script aus dem Projekt-Root aus.');
    exit(1);
  }

  final jsonString = jsonFile.readAsStringSync();
  final pois = jsonDecode(jsonString) as List<dynamic>;
  stdout.writeln('Gefunden: ${pois.length} kuratierte POIs');

  // Batch-Upload
  int success = 0;
  int errors = 0;
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < pois.length; i++) {
    final poi = pois[i] as Map<String, dynamic>;

    final id = poi['id'] as String? ?? 'curated-${poi['n']?.hashCode}';
    final name = poi['n'] as String? ?? poi['name'] as String? ?? 'Unbekannt';
    final lat = (poi['lat'] as num).toDouble();
    final lng = (poi['lng'] as num).toDouble();
    final categoryId = poi['c'] as String? ?? poi['category'] as String? ?? 'attraction';
    final score = poi['r'] as int? ?? poi['score'] as int? ?? 50;
    final tags = (poi['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final imageUrl = poi['img'] as String?;
    final description = poi['desc'] as String?;

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/upsert_poi'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer $serviceRoleKey',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'p_id': id,
          'p_name': name,
          'p_latitude': lat,
          'p_longitude': lng,
          'p_category_id': categoryId,
          'p_score': score,
          'p_image_url': imageUrl,
          'p_description': description,
          'p_is_curated': true,
          'p_tags': tags,
          'p_source': 'curated',
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        success++;
      } else {
        errors++;
        if (errors <= 5) {
          stderr.writeln('FEHLER bei $id ($name): ${response.statusCode} ${response.body}');
        }
      }
    } catch (e) {
      errors++;
      if (errors <= 5) {
        stderr.writeln('FEHLER bei $id ($name): $e');
      }
    }

    // Fortschrittsanzeige alle 50 POIs
    if ((i + 1) % 50 == 0 || i == pois.length - 1) {
      stdout.writeln('  ${i + 1}/${pois.length} verarbeitet ($success OK, $errors Fehler)');
    }

    // Rate-Limit-Schutz: 10ms Pause
    await Future.delayed(const Duration(milliseconds: 10));
  }

  stopwatch.stop();
  stdout.writeln('');
  stdout.writeln('=== Seed abgeschlossen ===');
  stdout.writeln('Erfolgreich: $success');
  stdout.writeln('Fehler:      $errors');
  stdout.writeln('Dauer:       ${stopwatch.elapsedMilliseconds}ms');
  stdout.writeln('');
  stdout.writeln('Verifikation:');
  stdout.writeln("  SELECT COUNT(*) FROM pois WHERE is_curated = TRUE;  -- erwartet: ${pois.length}");
}
