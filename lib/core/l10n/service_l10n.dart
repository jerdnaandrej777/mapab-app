import 'dart:ui';

import 'package:travel_planner/l10n/app_localizations.dart';
import 'package:travel_planner/l10n/app_localizations_de.dart';
import 'package:travel_planner/l10n/app_localizations_en.dart';
import 'package:travel_planner/l10n/app_localizations_es.dart';
import 'package:travel_planner/l10n/app_localizations_fr.dart';
import 'package:travel_planner/l10n/app_localizations_it.dart';
import '../constants/categories.dart';

/// Ermoeglicht Services/Providers ohne BuildContext Zugriff auf Lokalisierung.
///
/// Verwendung:
/// ```dart
/// final l10n = ServiceL10n.fromLocale('de');
/// print(l10n.cancel); // "Abbrechen"
/// ```
class ServiceL10n {
  ServiceL10n._();

  /// Erstellt AppLocalizations anhand eines Sprach-Codes (z.B. 'de', 'en').
  static AppLocalizations fromLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return AppLocalizationsEn();
      case 'fr':
        return AppLocalizationsFr();
      case 'it':
        return AppLocalizationsIt();
      case 'es':
        return AppLocalizationsEs();
      case 'de':
      default:
        return AppLocalizationsDe();
    }
  }

  /// Erstellt AppLocalizations anhand einer Locale.
  static AppLocalizations fromLocale(Locale locale) {
    return fromLanguageCode(locale.languageCode);
  }

  /// Lokalisiertes Label fuer eine POICategory (ohne BuildContext).
  /// Fuer Verwendung in Providers/Services.
  static String localizedCategoryLabel(AppLocalizations l10n, POICategory category) {
    return switch (category) {
      POICategory.castle => l10n.categoryCastle,
      POICategory.nature => l10n.categoryNature,
      POICategory.museum => l10n.categoryMuseum,
      POICategory.viewpoint => l10n.categoryViewpoint,
      POICategory.lake => l10n.categoryLake,
      POICategory.coast => l10n.categoryCoast,
      POICategory.park => l10n.categoryPark,
      POICategory.city => l10n.categoryCity,
      POICategory.activity => l10n.categoryActivity,
      POICategory.hotel => l10n.categoryHotel,
      POICategory.restaurant => l10n.categoryRestaurant,
      POICategory.unesco => l10n.categoryUnesco,
      POICategory.church => l10n.categoryChurch,
      POICategory.monument => l10n.categoryMonument,
      POICategory.attraction => l10n.categoryAttraction,
    };
  }
}
