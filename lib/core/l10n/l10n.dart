import 'package:flutter/widgets.dart';
import 'package:travel_planner/l10n/app_localizations.dart';

export 'package:travel_planner/l10n/app_localizations.dart';

/// Convenience Extension fuer Lokalisierung
/// Verwendung: context.l10n.someKey
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
