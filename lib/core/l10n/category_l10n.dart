import 'package:flutter/widgets.dart';
import '../constants/categories.dart';
import '../../data/providers/settings_provider.dart';
import 'l10n.dart';

/// Lokalisierte Labels fuer POI-Kategorien
extension POICategoryL10n on POICategory {
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
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

/// Lokalisierte Labels fuer Wetter-Zustaende
extension WeatherConditionL10n on WeatherCondition {
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      WeatherCondition.good => l10n.weatherGood,
      WeatherCondition.mixed => l10n.weatherMixed,
      WeatherCondition.bad => l10n.weatherBad,
      WeatherCondition.danger => l10n.weatherDanger,
      WeatherCondition.unknown => l10n.weatherUnknown,
    };
  }
}

/// Lokalisierte Labels fuer Trip-Typen
extension TripTypeL10n on TripType {
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      TripType.daytrip => l10n.tripTypeDayTrip,
      TripType.eurotrip => l10n.tripTypeEuroTrip,
      TripType.multiday => l10n.tripTypeMultiDay,
      TripType.scenic => l10n.tripTypeScenic,
    };
  }

  String localizedDistance(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      TripType.daytrip => l10n.tripTypeDayTripDistance,
      TripType.eurotrip => l10n.tripTypeEuroTripDistance,
      TripType.multiday => l10n.tripTypeMultiDayDistance,
      TripType.scenic => l10n.tripTypeScenicDistance,
    };
  }

  String localizedDescription(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      TripType.daytrip => l10n.tripTypeDayTripDesc,
      TripType.eurotrip => l10n.tripTypeEuroTripDesc,
      TripType.multiday => l10n.tripTypeMultiDayDesc,
      TripType.scenic => l10n.tripTypeScenicDesc,
    };
  }
}

/// Lokalisierte Labels fuer Barrierefreiheits-Features
extension AccessibilityFeatureL10n on AccessibilityFeature {
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AccessibilityFeature.wheelchair => l10n.accessWheelchair,
      AccessibilityFeature.noStairs => l10n.accessNoStairs,
      AccessibilityFeature.parking => l10n.accessParking,
      AccessibilityFeature.toilet => l10n.accessToilet,
      AccessibilityFeature.elevator => l10n.accessElevator,
      AccessibilityFeature.braille => l10n.accessBraille,
      AccessibilityFeature.audioGuide => l10n.accessAudioGuide,
      AccessibilityFeature.signLanguage => l10n.accessSignLanguage,
      AccessibilityFeature.assistDogs => l10n.accessAssistDogs,
    };
  }
}

/// Lokalisierte Labels fuer Rollstuhl-Zugaenglichkeit
extension WheelchairAccessibilityL10n on WheelchairAccessibility {
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      WheelchairAccessibility.yes => l10n.accessFullyAccessible,
      WheelchairAccessibility.limited => l10n.accessLimited,
      WheelchairAccessibility.no => l10n.accessNotAccessible,
      WheelchairAccessibility.unknown => l10n.accessUnknown,
    };
  }
}

/// Lokalisierte Labels fuer POI-Highlights
extension POIHighlightL10n on POIHighlight {
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      POIHighlight.unesco => l10n.highlightUnesco,
      POIHighlight.mustSee => l10n.highlightMustSee,
      POIHighlight.secret => l10n.highlightSecret,
      POIHighlight.historic => l10n.highlightHistoric,
      POIHighlight.familyFriendly => l10n.highlightFamilyFriendly,
    };
  }
}

/// Lokalisierte Labels fuer Theme-Modus
extension AppThemeModeL10n on AppThemeMode {
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AppThemeMode.system => l10n.settingsThemeSystem,
      AppThemeMode.light => l10n.settingsThemeLight,
      AppThemeMode.dark => l10n.settingsThemeDark,
      AppThemeMode.oled => l10n.settingsThemeOled,
    };
  }
}
