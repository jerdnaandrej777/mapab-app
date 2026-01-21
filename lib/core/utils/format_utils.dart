import 'package:intl/intl.dart';

/// Formatierungs-Utilities
/// Übernommen von MapAB js/utils/format.js
class FormatUtils {
  FormatUtils._();

  /// Formatiert eine Distanz in km
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    } else if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${km.round()} km';
    }
  }

  /// Formatiert eine Dauer in Minuten
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes Min.';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours Std.';
      }
      return '$hours Std. $mins Min.';
    }
  }

  /// Formatiert eine Dauer ausführlich
  static String formatDurationLong(int minutes) {
    if (minutes < 60) {
      return '$minutes Minuten';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours ${hours == 1 ? 'Stunde' : 'Stunden'}';
      }
      return '$hours Std. $mins Min.';
    }
  }

  /// Generiert Sterne-String für Bewertung (z.B. ★★★★☆)
  static String formatStars(double rating, {int maxStars = 5}) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = maxStars - fullStars - (hasHalfStar ? 1 : 0);

    return '★' * fullStars +
        (hasHalfStar ? '½' : '') +
        '☆' * emptyStars;
  }

  /// Formatiert eine Bewertung als String
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Formatiert eine Zahl mit Tausendertrennzeichen
  static String formatNumber(int number) {
    return NumberFormat('#,###', 'de_DE').format(number);
  }

  /// Formatiert ein Datum
  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy', 'de_DE').format(date);
  }

  /// Formatiert ein Datum mit Wochentag
  static String formatDateWithWeekday(DateTime date) {
    return DateFormat('EEEE, dd.MM.yyyy', 'de_DE').format(date);
  }

  /// Formatiert eine Uhrzeit
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm', 'de_DE').format(time);
  }

  /// Formatiert einen Umweg
  static String formatDetour(double km, int minutes) {
    return '+${formatDistance(km)} (+${formatDuration(minutes)})';
  }

  /// Kürzt einen Text auf maximale Länge
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Formatiert Öffnungszeiten leserlich
  static String formatOpeningHours(String? hours) {
    if (hours == null || hours.isEmpty) return 'Keine Angabe';

    // OSM-Format übersetzen
    return hours
        .replaceAll('Mo', 'Mo')
        .replaceAll('Tu', 'Di')
        .replaceAll('We', 'Mi')
        .replaceAll('Th', 'Do')
        .replaceAll('Fr', 'Fr')
        .replaceAll('Sa', 'Sa')
        .replaceAll('Su', 'So')
        .replaceAll('-', ' - ')
        .replaceAll(',', ', ')
        .replaceAll(';', '; ');
  }

  /// Formatiert eine Telefonnummer
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    // Entfernt Leerzeichen und formatiert
    return phone.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Formatiert eine URL für die Anzeige (ohne https://)
  static String formatWebsiteDisplay(String? url) {
    if (url == null || url.isEmpty) return '';
    return url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  /// Generiert einen relativen Zeitstempel
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'Vor ${difference.inMinutes} Min.';
    } else if (difference.inHours < 24) {
      return 'Vor ${difference.inHours} Std.';
    } else if (difference.inDays < 7) {
      return 'Vor ${difference.inDays} ${difference.inDays == 1 ? 'Tag' : 'Tagen'}';
    } else {
      return formatDate(dateTime);
    }
  }
}
