// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'MapAB';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get remove => 'Entfernen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get close => 'Schließen';

  @override
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get done => 'Fertig';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get or => 'ODER';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get loading => 'Laden...';

  @override
  String get search => 'Suchen';

  @override
  String get show => 'Anzeigen';

  @override
  String get apply => 'Anwenden';

  @override
  String get active => 'Aktiv';

  @override
  String get discard => 'Verwerfen';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get skip => 'Überspringen';

  @override
  String get all => 'Alle';

  @override
  String get total => 'Gesamt';

  @override
  String get newLabel => 'Neu';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Ziel';

  @override
  String get showOnMap => 'Auf Karte anzeigen';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get actionCannotBeUndone =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get details => 'Details';

  @override
  String get generate => 'Generieren';

  @override
  String get clear => 'Leeren';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get end => 'Beenden';

  @override
  String get reroll => 'Neu würfeln';

  @override
  String get filterApply => 'Filter anwenden';

  @override
  String get openInGoogleMaps => 'In Google Maps öffnen';

  @override
  String get shareLinkCopied => 'Link in Zwischenablage kopiert!';

  @override
  String get shareAsText => 'Als Text teilen';

  @override
  String get errorGeneric => 'Ein Fehler ist aufgetreten';

  @override
  String get errorNetwork => 'Keine Internetverbindung';

  @override
  String get errorNetworkMessage =>
      'Bitte überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get errorServer => 'Server nicht erreichbar';

  @override
  String get errorServerMessage =>
      'Der Server antwortet nicht. Versuche es später erneut.';

  @override
  String get errorNoResults => 'Keine Ergebnisse';

  @override
  String get errorLocation => 'Standort nicht verfügbar';

  @override
  String get errorLocationMessage =>
      'Bitte erlaube den Zugriff auf deinen Standort.';

  @override
  String get errorPrefix => 'Fehler: ';

  @override
  String get pageNotFound => 'Seite nicht gefunden';

  @override
  String get goToHome => 'Zur Startseite';

  @override
  String get errorRouteCalculation =>
      'Routenberechnung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String errorTripGeneration(String error) {
    return 'Trip-Generierung fehlgeschlagen: $error';
  }

  @override
  String get errorGoogleMapsNotOpened =>
      'Google Maps konnte nicht geöffnet werden';

  @override
  String get errorRouteNotShared => 'Route konnte nicht geteilt werden';

  @override
  String get errorAddingToRoute => 'Fehler beim Hinzufügen';

  @override
  String get errorIncompleteRouteData => 'Route-Daten sind unvollständig';

  @override
  String get gpsDisabledTitle => 'GPS deaktiviert';

  @override
  String get gpsDisabledMessage =>
      'Die Ortungsdienste sind deaktiviert. Möchtest du die GPS-Einstellungen öffnen?';

  @override
  String get gpsPermissionDenied => 'GPS-Berechtigung wurde verweigert';

  @override
  String get gpsPermissionDeniedForeverTitle => 'GPS-Berechtigung verweigert';

  @override
  String get gpsPermissionDeniedForeverMessage =>
      'Die GPS-Berechtigung wurde dauerhaft verweigert. Bitte erlaube den Standortzugriff in den App-Einstellungen.';

  @override
  String get gpsCouldNotDetermine =>
      'GPS-Position konnte nicht ermittelt werden';

  @override
  String get appSettingsButton => 'App-Einstellungen';

  @override
  String get myLocation => 'Mein Standort';

  @override
  String get authWelcomeTitle => 'Willkommen bei MapAB';

  @override
  String get authWelcomeSubtitle =>
      'Dein AI-Reiseplaner für unvergessliche Trips';

  @override
  String get authCloudNotAvailable =>
      'Cloud nicht verfügbar - App ohne Supabase-Credentials gebaut';

  @override
  String get authCloudLoginUnavailable =>
      'Cloud-Login nicht verfügbar - App ohne Supabase-Credentials gebaut';

  @override
  String get authEmailLabel => 'E-Mail';

  @override
  String get authEmailEmpty => 'Bitte E-Mail eingeben';

  @override
  String get authEmailInvalid => 'Ungültige E-Mail';

  @override
  String get authEmailInvalidAddress => 'Ungültige E-Mail-Adresse';

  @override
  String get authPasswordLabel => 'Passwort';

  @override
  String get authPasswordEmpty => 'Bitte Passwort eingeben';

  @override
  String get authPasswordMinLength => 'Mindestens 8 Zeichen';

  @override
  String get authPasswordRequirements => 'Muss Buchstaben und Zahlen enthalten';

  @override
  String get authPasswordConfirm => 'Passwort bestätigen';

  @override
  String get authPasswordMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get authRememberMe => 'Anmeldedaten merken';

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authNoAccount => 'Noch kein Konto? ';

  @override
  String get authRegister => 'Registrieren';

  @override
  String get authContinueAsGuest => 'Als Gast fortfahren';

  @override
  String get authGuestInfoCloud =>
      'Als Gast werden deine Daten nur lokal gespeichert und nicht synchronisiert.';

  @override
  String get authGuestInfoLocal =>
      'Deine Daten werden lokal auf deinem Gerät gespeichert.';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authSecureData => 'Sichere deine Daten in der Cloud';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authNameHint => 'Wie möchtest du genannt werden?';

  @override
  String get authNameEmpty => 'Bitte Namen eingeben';

  @override
  String get authNameMinLength => 'Name muss mindestens 2 Zeichen haben';

  @override
  String get authAlreadyHaveAccount => 'Bereits ein Konto? ';

  @override
  String get authExistingAccount => 'Ich habe bereits ein Konto';

  @override
  String get authRegistrationSuccess => 'Registrierung erfolgreich';

  @override
  String get authRegistrationSuccessMessage =>
      'Bitte prüfe deine E-Mails und bestätige dein Konto.';

  @override
  String get authResetPassword => 'Passwort zurücksetzen';

  @override
  String get authResetPasswordInstructions =>
      'Gib deine E-Mail-Adresse ein und wir senden dir einen Link zum Zurücksetzen.';

  @override
  String get authSendLink => 'Link senden';

  @override
  String get authBackToLogin => 'Zurück zur Anmeldung';

  @override
  String get authEmailSent => 'E-Mail gesendet!';

  @override
  String get authEmailSentPrefix => 'Wir haben dir eine E-Mail an';

  @override
  String get authEmailSentSuffix => 'gesendet.';

  @override
  String get authResetLinkInstructions =>
      'Klicke auf den Link in der E-Mail, um ein neues Passwort zu setzen. Der Link ist 24 Stunden gültig.';

  @override
  String get authResend => 'Erneut senden';

  @override
  String get authCreateLocalProfile => 'Lokales Profil erstellen';

  @override
  String get authUsernameLabel => 'Benutzername';

  @override
  String get authUsernameHint => 'z.B. reisefan123';

  @override
  String get authDisplayNameLabel => 'Anzeigename';

  @override
  String get authDisplayNameHint => 'z.B. Max Mustermann';

  @override
  String get authEmailOptional => 'E-Mail (optional)';

  @override
  String get authEmailHint => 'z.B. max@example.com';

  @override
  String get authCreate => 'Erstellen';

  @override
  String get authRequiredFields =>
      'Benutzername und Anzeigename sind erforderlich';

  @override
  String get authGuestDescription =>
      'Als Gast kannst du sofort loslegen. Deine Daten werden lokal auf deinem Gerät gespeichert.';

  @override
  String get authComingSoon => 'Cloud-Login kommt bald:';

  @override
  String get authLoadingText => 'Lade...';

  @override
  String get splashTagline => 'Dein AI-Reiseplaner';

  @override
  String get onboardingTitle1 => 'Entdecke Sehenswürdigkeiten';

  @override
  String get onboardingHighlight1 => 'Sehenswürdigkeiten';

  @override
  String get onboardingSubtitle1 =>
      'Finde über 500 handverlesene POIs in ganz Europa.\nSchlösser, Seen, Museen und Geheimtipps warten auf dich.';

  @override
  String get onboardingTitle2 => 'Dein KI-Reiseassistent';

  @override
  String get onboardingHighlight2 => 'KI';

  @override
  String get onboardingSubtitle2 =>
      'Lass dir automatisch die perfekte Route planen.\nMit smarter Optimierung für deine Interessen.';

  @override
  String get onboardingTitle3 => 'Deine Reisen in der Cloud';

  @override
  String get onboardingHighlight3 => 'Cloud';

  @override
  String get onboardingSubtitle3 =>
      'Speichere Favoriten und Trips sicher online.\nSynchronisiert auf allen deinen Geräten.';

  @override
  String get onboardingStart => 'Los geht\'s';

  @override
  String get categoryCastle => 'Schlösser & Burgen';

  @override
  String get categoryNature => 'Natur & Wälder';

  @override
  String get categoryMuseum => 'Museen';

  @override
  String get categoryViewpoint => 'Aussichtspunkte';

  @override
  String get categoryLake => 'Seen';

  @override
  String get categoryCoast => 'Küsten & Strände';

  @override
  String get categoryPark => 'Parks & Nationalparks';

  @override
  String get categoryCity => 'Städte';

  @override
  String get categoryActivity => 'Aktivitäten';

  @override
  String get categoryHotel => 'Hotels';

  @override
  String get categoryRestaurant => 'Restaurants';

  @override
  String get categoryUnesco => 'UNESCO-Welterbe';

  @override
  String get categoryChurch => 'Kirchen';

  @override
  String get categoryMonument => 'Monumente';

  @override
  String get categoryAttraction => 'Attraktionen';

  @override
  String get weatherGood => 'Gut';

  @override
  String get weatherMixed => 'Wechselhaft';

  @override
  String get weatherBad => 'Schlecht';

  @override
  String get weatherDanger => 'Gefährlich';

  @override
  String get weatherUnknown => 'Unbekannt';

  @override
  String get weatherClear => 'Klar';

  @override
  String get weatherMostlyClear => 'Überwiegend klar';

  @override
  String get weatherPartlyCloudy => 'Teilweise bewölkt';

  @override
  String get weatherCloudy => 'Bewölkt';

  @override
  String get weatherFog => 'Nebel';

  @override
  String get weatherDrizzle => 'Nieselregen';

  @override
  String get weatherFreezingDrizzle => 'Gefrierender Nieselregen';

  @override
  String get weatherRain => 'Regen';

  @override
  String get weatherFreezingRain => 'Gefrierender Regen';

  @override
  String get weatherSnow => 'Schneefall';

  @override
  String get weatherSnowGrains => 'Schneegriesel';

  @override
  String get weatherRainShowers => 'Regenschauer';

  @override
  String get weatherSnowShowers => 'Schneeschauer';

  @override
  String get weatherThunderstorm => 'Gewitter';

  @override
  String get weatherThunderstormHail => 'Gewitter mit Hagel';

  @override
  String get weatherForecast7Day => '7-Tage-Vorhersage';

  @override
  String get weatherToday => 'Heute';

  @override
  String weatherFeelsLike(String temp) {
    return 'Gefühlt $temp°';
  }

  @override
  String get weatherSunrise => 'Sonnenaufgang';

  @override
  String get weatherSunset => 'Sonnenuntergang';

  @override
  String get weatherUvIndex => 'UV-Index';

  @override
  String get weatherPrecipitation => 'Niederschlag';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherRainRisk => 'Regenrisiko';

  @override
  String get weatherRecommendationToday => 'Empfehlung für heute';

  @override
  String get weatherRecGood =>
      'Perfektes Wetter für Outdoor-Aktivitäten! Viewpoints, Natur und Seen empfohlen.';

  @override
  String get weatherRecMixed =>
      'Wechselhaftes Wetter. Sowohl Indoor- als auch Outdoor-POIs möglich.';

  @override
  String get weatherRecBad =>
      'Regen erwartet. Indoor-Aktivitäten wie Museen und Kirchen empfohlen.';

  @override
  String get weatherRecDanger =>
      'Unwetterwarnung! Bitte Outdoor-Aktivitäten vermeiden und drinnen bleiben.';

  @override
  String get weatherRecUnknown => 'Keine Wetterdaten verfügbar.';

  @override
  String weatherUvLow(String value) {
    return '$value (Niedrig)';
  }

  @override
  String weatherUvMedium(String value) {
    return '$value (Mittel)';
  }

  @override
  String weatherUvHigh(String value) {
    return '$value (Hoch)';
  }

  @override
  String weatherUvVeryHigh(String value) {
    return '$value (Sehr hoch)';
  }

  @override
  String weatherUvExtreme(String value) {
    return '$value (Extrem)';
  }

  @override
  String get weatherLoading => 'Wetter laden...';

  @override
  String get weatherWinterWeather => 'Winterwetter';

  @override
  String get weatherStormOnRoute => 'Unwetter auf der Route';

  @override
  String get weatherRainPossible => 'Regen möglich';

  @override
  String get weatherGoodWeather => 'Gutes Wetter';

  @override
  String get weatherChangeable => 'Wechselhaft';

  @override
  String get weatherBadWeather => 'Schlechtes Wetter';

  @override
  String get weatherStormWarning => 'Unwetterwarnung';

  @override
  String get weatherPerfect => 'Perfekt';

  @override
  String get weatherStorm => 'Unwetter';

  @override
  String get weatherIdealOutdoor => 'Heute ideal für Outdoor-POIs';

  @override
  String get weatherFlexiblePlanning => 'Wechselhaft - flexibel planen';

  @override
  String get weatherRainIndoor => 'Regen - Indoor-POIs empfohlen';

  @override
  String get weatherStormIndoorOnly => 'Unwetter - nur Indoor-POIs!';

  @override
  String get weatherOnlyIndoor => 'Nur Indoor-POIs';

  @override
  String weatherStormHighWinds(String speed) {
    return 'Sturmwarnung! Starke Winde ($speed km/h) entlang der Route.';
  }

  @override
  String get weatherStormDelay =>
      'Unwetterwarnung! Fahrt verschieben empfohlen.';

  @override
  String get weatherWinterWarning => 'Winterwetter! Schnee/Glätte möglich.';

  @override
  String get weatherRainRecommendation =>
      'Regen erwartet. Indoor-Aktivitäten empfohlen.';

  @override
  String get weatherBadOnRoute => 'Schlechtes Wetter auf der Route.';

  @override
  String get weatherPerfectOutdoor =>
      'Perfektes Wetter für Outdoor-Aktivitäten';

  @override
  String get weatherBePrepared => 'Wechselhaft - auf alles vorbereitet sein';

  @override
  String get weatherSnowWarning => 'Schneefall - Vorsicht auf glatten Straßen';

  @override
  String get weatherBadIndoor =>
      'Schlechtes Wetter - Indoor-Aktivitäten empfohlen';

  @override
  String get weatherStormCaution =>
      'Unwetterwarnung! Vorsicht auf diesem Streckenabschnitt';

  @override
  String get weatherNoData => 'Keine Wetterdaten verfügbar';

  @override
  String weatherRoutePoint(int index, int total) {
    return 'Routenpunkt $index von $total';
  }

  @override
  String weatherExpectedOnDay(String weather, int day) {
    return '$weather auf Tag $day erwartet';
  }

  @override
  String weatherOutdoorStops(int outdoor, int total) {
    return '$outdoor von $total Stops sind Outdoor-Aktivitäten.';
  }

  @override
  String get weatherSuggestIndoor => 'Indoor-Alternativen vorschlagen';

  @override
  String get weatherStormExpected => 'Unwetter erwartet';

  @override
  String get weatherRainExpected => 'Regen erwartet';

  @override
  String get weatherIdealOutdoorWeather => 'Ideales Outdoor-Wetter';

  @override
  String get weatherStormIndoorPrefer =>
      'Unwetter erwartet – Indoor-Stops bevorzugen';

  @override
  String get weatherRainIndoorHighlight =>
      'Regen erwartet – Indoor-Stops hervorgehoben';

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Di';

  @override
  String get weekdayWed => 'Mi';

  @override
  String get weekdayThu => 'Do';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'So';

  @override
  String get mapFavorites => 'Favoriten';

  @override
  String get mapProfile => 'Profil';

  @override
  String get mapSettings => 'Einstellungen';

  @override
  String get mapToRoute => 'Zur Route';

  @override
  String get mapSetAsStart => 'Als Start setzen';

  @override
  String get mapSetAsDestination => 'Als Ziel setzen';

  @override
  String get mapAddAsStop => 'Als Stopp hinzufügen';

  @override
  String get tripConfigGps => 'GPS';

  @override
  String get tripConfigCityOrAddress => 'Stadt oder Adresse...';

  @override
  String get tripConfigDestinationOptional => 'Ziel (optional)';

  @override
  String get tripConfigAddDestination => 'Ziel hinzufügen (optional)';

  @override
  String get tripConfigEnterDestination => 'Zielort eingeben...';

  @override
  String get tripConfigNoDestinationRoundtrip =>
      'Ohne Ziel: Rundreise ab Start';

  @override
  String get tripConfigSurpriseMe => 'Überrasch mich!';

  @override
  String get tripConfigDeleteRoute => 'Route löschen';

  @override
  String get tripConfigTripDuration => 'Reisedauer';

  @override
  String get tripConfigDay => 'Tag';

  @override
  String get tripConfigDays => 'Tage';

  @override
  String tripConfigDayTrip(String distance) {
    return 'Tagesausflug — ca. $distance km';
  }

  @override
  String tripConfigWeekendTrip(String distance) {
    return 'Wochenend-Trip — ca. $distance km';
  }

  @override
  String tripConfigShortVacation(String distance) {
    return 'Kurzurlaub — ca. $distance km';
  }

  @override
  String tripConfigWeekTravel(String distance) {
    return 'Wochenreise — ca. $distance km';
  }

  @override
  String tripConfigEpicEuroTrip(String distance) {
    return 'Epischer Euro Trip — ca. $distance km';
  }

  @override
  String get tripConfigRadius => 'Radius';

  @override
  String get tripConfigPoiCategories => 'POI-Kategorien';

  @override
  String get tripConfigResetAll => 'Alle zurücksetzen';

  @override
  String get tripConfigAllCategories => 'Alle Kategorien ausgewählt';

  @override
  String tripConfigCategoriesSelected(int selected, int total) {
    return '$selected von $total ausgewählt';
  }

  @override
  String get tripConfigCategories => 'Kategorien';

  @override
  String tripConfigSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get tripConfigPoisAlongRoute => 'POIs entlang der Route';

  @override
  String get tripConfigActiveTripTitle => 'Aktiver Trip vorhanden';

  @override
  String tripConfigActiveTripMessage(int days, int completed) {
    return 'Du hast einen aktiven $days-Tage-Trip mit $completed abgeschlossenen Tagen. Ein neuer Trip überschreibt diesen.';
  }

  @override
  String get tripConfigCreateNewTrip => 'Neuen Trip erstellen';

  @override
  String get tripInfoGenerating => 'Trip wird generiert...';

  @override
  String get tripInfoLoadingPois => 'POIs laden, Route optimieren';

  @override
  String get tripInfoAiEuroTrip => 'AI Euro Trip';

  @override
  String get tripInfoAiDayTrip => 'AI Tagestrip';

  @override
  String get tripInfoEditTrip => 'Trip bearbeiten';

  @override
  String get tripInfoStartNavigation => 'Navigation starten';

  @override
  String get tripInfoStops => 'Stops';

  @override
  String get tripInfoDistance => 'Distanz';

  @override
  String get tripInfoDaysLabel => 'Tage';

  @override
  String get activeTripTitle => 'Aktiver Euro Trip';

  @override
  String get activeTripDiscard => 'Aktiven Trip verwerfen';

  @override
  String get activeTripDiscardTitle => 'Trip verwerfen?';

  @override
  String activeTripDiscardMessage(int days, int completed) {
    return 'Dein $days-Tage-Trip mit $completed abgeschlossenen Tagen wird gelöscht.';
  }

  @override
  String activeTripDayPending(int day) {
    return 'Tag $day steht an';
  }

  @override
  String activeTripDaysCompleted(int completed, int total) {
    return '$completed von $total Tagen abgeschlossen';
  }

  @override
  String get tripModeAiDayTrip => 'AI Tagestrip';

  @override
  String get tripModeAiEuroTrip => 'AI Euro Trip';

  @override
  String get tripRoutePlanning => 'Route planen';

  @override
  String get tripNoRoute => 'Keine Route vorhanden';

  @override
  String get tripTapMap => 'Tippe auf die Karte, um Start und Ziel festzulegen';

  @override
  String get tripToMap => 'Zur Karte';

  @override
  String get tripGeneratingDescription =>
      'POIs laden, Route optimieren, Hotels suchen';

  @override
  String get tripElevationLoading => 'Höhenprofil wird geladen...';

  @override
  String get tripSaveRoute => 'Route speichern';

  @override
  String get tripRouteName => 'Name der Route';

  @override
  String get tripExampleDayTrip => 'z.B. Wochenendausflug';

  @override
  String get tripExampleAiDayTrip => 'z.B. AI Tagesausflug';

  @override
  String get tripExampleAiEuroTrip => 'z.B. AI Euro Trip';

  @override
  String tripRouteSaved(String name) {
    return 'Route \"$name\" gespeichert';
  }

  @override
  String get tripYourRoute => 'Deine Route';

  @override
  String get tripDrivingTime => 'Fahrzeit';

  @override
  String get tripStopRemoved => 'Stop entfernt';

  @override
  String get tripOptimizeRoute => 'Route optimieren';

  @override
  String get tripOptimizeBestOrder => 'Beste Reihenfolge berechnen';

  @override
  String get tripShareRoute => 'Route teilen';

  @override
  String get tripDeleteAllStops => 'Alle Stops löschen';

  @override
  String get tripDeleteEntireRoute => 'Gesamte Route löschen';

  @override
  String get tripDeleteRouteAndStops => 'Route und alle Stops löschen';

  @override
  String get tripConfirmDeleteAllStops => 'Alle Stops löschen?';

  @override
  String get tripConfirmDeleteEntireRoute => 'Gesamte Route löschen?';

  @override
  String get tripDeleteEntireRouteMessage =>
      'Die Route und alle Stops werden gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get tripBackToConfig => 'Zurück zur Konfiguration';

  @override
  String tripExportDay(int day) {
    return 'Tag $day in Google Maps';
  }

  @override
  String tripReExportDay(int day) {
    return 'Tag $day erneut exportieren';
  }

  @override
  String get tripGoogleMapsHint =>
      'Google Maps berechnet eine eigene Route durch die Stops';

  @override
  String tripNoStopsForDay(int day) {
    return 'Keine Stops für Tag $day';
  }

  @override
  String get tripCompleted => 'Trip abgeschlossen!';

  @override
  String tripAllDaysExported(int days) {
    return 'Alle $days Tage wurden erfolgreich exportiert. Möchtest du den Trip in deinen Favoriten speichern?';
  }

  @override
  String get tripKeep => 'Behalten';

  @override
  String get tripSaveToFavorites => 'In Favoriten speichern';

  @override
  String get tripShareHeader => 'Meine Route mit MapAB';

  @override
  String tripShareStart(String address) {
    return 'Start: $address';
  }

  @override
  String tripShareEnd(String address) {
    return 'Ziel: $address';
  }

  @override
  String tripShareDistance(String distance) {
    return 'Distanz: $distance km';
  }

  @override
  String tripShareDuration(String duration) {
    return 'Dauer: $duration Min';
  }

  @override
  String get tripShareStops => 'Stops:';

  @override
  String get tripShareOpenMaps => 'In Google Maps öffnen:';

  @override
  String get tripMyRoute => 'Meine Route';

  @override
  String get tripGoogleMaps => 'Google Maps';

  @override
  String get tripShowInFavorites => 'Anzeigen';

  @override
  String get tripGoogleMapsError => 'Google Maps konnte nicht geöffnet werden';

  @override
  String get tripShareError => 'Route konnte nicht geteilt werden';

  @override
  String get tripWeatherDangerHint =>
      'Unwetter erwartet – Indoor-Stops bevorzugen';

  @override
  String get tripWeatherBadHint =>
      'Regen erwartet – Indoor-Stops hervorgehoben';

  @override
  String get tripStart => 'Start';

  @override
  String get tripDestination => 'Ziel';

  @override
  String get tripNew => 'Neu';

  @override
  String get dayEditorTitle => 'Trip bearbeiten';

  @override
  String get dayEditorNoTrip => 'Kein Trip vorhanden';

  @override
  String get dayEditorStartNotAvailable => 'Startpunkt nicht verfügbar';

  @override
  String dayEditorEditDay(int day) {
    return 'Tag $day bearbeiten';
  }

  @override
  String get dayEditorRegenerate => 'Neu generieren';

  @override
  String dayEditorMaxStops(int max) {
    return 'Max $max Stops pro Tag in Google Maps möglich';
  }

  @override
  String get dayEditorSearchRecommendations => 'Suche POI-Empfehlungen...';

  @override
  String get dayEditorLoadRecommendations => 'POI-Empfehlungen laden';

  @override
  String get dayEditorAiRecommendations => 'AI-Empfehlungen';

  @override
  String get dayEditorRecommended => 'Empfohlen';

  @override
  String dayEditorAddedToDay(int day) {
    return 'zu Tag $day hinzugefügt';
  }

  @override
  String get dayEditorAllDaysExported =>
      'Alle Tage wurden erfolgreich in Google Maps exportiert. Gute Reise!';

  @override
  String get dayEditorAddPois => 'POIs hinzufügen';

  @override
  String dayEditorMyRouteDay(int day) {
    return 'Meine Route - Tag $day mit MapAB';
  }

  @override
  String dayEditorMapabRouteDay(int day) {
    return 'MapAB Route - Tag $day';
  }

  @override
  String dayEditorSwapped(String name) {
    return '\"$name\" eingetauscht';
  }

  @override
  String get corridorTitle => 'POIs entlang der Route';

  @override
  String corridorFound(int total) {
    return '$total gefunden';
  }

  @override
  String corridorFoundWithNew(int total, int newCount) {
    return '$total gefunden ($newCount neu)';
  }

  @override
  String corridorWidth(int km) {
    return 'Korridor: $km km';
  }

  @override
  String get corridorSearching => 'Suche POIs im Korridor...';

  @override
  String get corridorNoPoiInCategory =>
      'Keine POIs in dieser Kategorie gefunden';

  @override
  String get corridorNoPois => 'Keine POIs im Korridor gefunden';

  @override
  String get corridorTryWider => 'Versuche einen breiteren Korridor';

  @override
  String get corridorRemoveStop => 'Stop entfernen?';

  @override
  String get corridorMinOneStop => 'Mindestens 1 Stop pro Tag erforderlich';

  @override
  String corridorPoiRemoved(String name) {
    return '\"$name\" entfernt';
  }

  @override
  String get navEndConfirm => 'Navigation beenden?';

  @override
  String get navDestinationReached => 'Ziel erreicht!';

  @override
  String get navDistance => 'Distanz';

  @override
  String get navArrival => 'Ankunft';

  @override
  String get navSpeed => 'Tempo';

  @override
  String get navMuteOn => 'Ton an';

  @override
  String get navMuteOff => 'Ton aus';

  @override
  String get navOverview => 'Übersicht';

  @override
  String get navEnd => 'Beenden';

  @override
  String get navVoice => 'Sprache';

  @override
  String get navVoiceListening => 'Hört...';

  @override
  String get navStartButton => 'Navigation starten';

  @override
  String get navRerouting => 'Route wird neu berechnet';

  @override
  String get navVisited => 'Besucht';

  @override
  String navDistanceMeters(String distance) {
    return '$distance m entfernt';
  }

  @override
  String navDistanceKm(String distance) {
    return '$distance km entfernt';
  }

  @override
  String get navDepart => 'Fahre los';

  @override
  String navDepartOn(String street) {
    return 'Fahre los auf $street';
  }

  @override
  String get navArrive => 'Sie haben Ihr Ziel erreicht';

  @override
  String navArriveAt(String street) {
    return 'Ziel erreicht: $street';
  }

  @override
  String navContinueOn(String street) {
    return 'Weiter auf $street';
  }

  @override
  String get navContinue => 'Weiterfahren';

  @override
  String get navTurnRight => 'Rechts abbiegen';

  @override
  String get navTurnLeft => 'Links abbiegen';

  @override
  String navTurnRightOn(String street) {
    return 'Rechts abbiegen auf $street';
  }

  @override
  String navTurnLeftOn(String street) {
    return 'Links abbiegen auf $street';
  }

  @override
  String get navSlightRight => 'Leicht rechts abbiegen';

  @override
  String get navSlightLeft => 'Leicht links abbiegen';

  @override
  String navSlightRightOn(String street) {
    return 'Leicht rechts auf $street';
  }

  @override
  String navSlightLeftOn(String street) {
    return 'Leicht links auf $street';
  }

  @override
  String get navSharpRight => 'Scharf rechts abbiegen';

  @override
  String get navSharpLeft => 'Scharf links abbiegen';

  @override
  String get navUturn => 'Wenden';

  @override
  String get navStraight => 'Geradeaus weiter';

  @override
  String navStraightOn(String street) {
    return 'Geradeaus auf $street';
  }

  @override
  String get navMerge => 'Einfädeln';

  @override
  String navMergeOn(String street) {
    return 'Einfädeln auf $street';
  }

  @override
  String get navOnRamp => 'Auffahrt nehmen';

  @override
  String navOnRampOn(String street) {
    return 'Auffahrt auf $street';
  }

  @override
  String get navOffRamp => 'Abfahrt nehmen';

  @override
  String navOffRampOn(String street) {
    return 'Abfahrt $street';
  }

  @override
  String navRoundaboutExit(String ordinal) {
    return 'Im Kreisverkehr die $ordinal Ausfahrt nehmen';
  }

  @override
  String navRoundaboutExitOn(String ordinal, String street) {
    return 'Im Kreisverkehr die $ordinal Ausfahrt nehmen auf $street';
  }

  @override
  String get navRoundaboutEnter => 'In den Kreisverkehr einfahren';

  @override
  String get navRoundaboutLeave => 'Kreisverkehr verlassen';

  @override
  String get navForkLeft => 'An der Gabelung links halten';

  @override
  String get navForkRight => 'An der Gabelung rechts halten';

  @override
  String navForkLeftOn(String street) {
    return 'An der Gabelung links auf $street';
  }

  @override
  String navForkRightOn(String street) {
    return 'An der Gabelung rechts auf $street';
  }

  @override
  String get navEndOfRoadLeft => 'Am Straßenende links abbiegen';

  @override
  String get navEndOfRoadRight => 'Am Straßenende rechts abbiegen';

  @override
  String navEndOfRoadLeftOn(String street) {
    return 'Am Straßenende links auf $street';
  }

  @override
  String navEndOfRoadRightOn(String street) {
    return 'Am Straßenende rechts auf $street';
  }

  @override
  String navInDistance(String distance, String instruction) {
    return 'In $distance $instruction';
  }

  @override
  String navNow(String instruction) {
    return 'Jetzt $instruction';
  }

  @override
  String navMeters(String value) {
    return '$value Metern';
  }

  @override
  String navKilometers(String value) {
    return '$value Kilometern';
  }

  @override
  String get navOrdinalFirst => 'erste';

  @override
  String get navOrdinalSecond => 'zweite';

  @override
  String get navOrdinalThird => 'dritte';

  @override
  String get navOrdinalFourth => 'vierte';

  @override
  String get navOrdinalFifth => 'fünfte';

  @override
  String get navMustSeeStop => 'Halt';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get settingsDesign => 'Design';

  @override
  String get settingsAutoDarkMode => 'Auto Dark Mode';

  @override
  String get settingsAutoDarkModeDesc =>
      'Automatisch bei Sonnenuntergang aktivieren';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsHaptic => 'Haptisches Feedback';

  @override
  String get settingsHapticDesc => 'Vibrationen bei Interaktionen';

  @override
  String get settingsSound => 'Sound-Effekte';

  @override
  String get settingsSoundDesc => 'Töne bei Aktionen';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsAppVersion => 'App-Version';

  @override
  String get settingsLicenses => 'Open Source Lizenzen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeOled => 'OLED Schwarz';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileEdit => 'Profil bearbeiten';

  @override
  String get profileCloudAccount => 'Cloud-Account';

  @override
  String get profileAutoSync => 'Daten werden automatisch synchronisiert';

  @override
  String get profileGuestAccount => 'Gast-Account';

  @override
  String get profileLocalStorage => 'Lokal gespeichert';

  @override
  String get profileUpgradeToCloud => 'Zu Cloud-Account upgraden';

  @override
  String get profileDeleteAccount => 'Account löschen';

  @override
  String get profileNoAccount => 'Kein Account';

  @override
  String get profileLoginPrompt => 'Melde dich an, um dein Profil zu sehen';

  @override
  String get profileLogin => 'Anmelden';

  @override
  String profileLevel(int level) {
    return 'Level $level';
  }

  @override
  String profileXpProgress(int xp, int level) {
    return 'Noch $xp XP bis Level $level';
  }

  @override
  String get profileStatistics => 'Statistiken';

  @override
  String get profileStatisticsLoading => 'Statistiken werden geladen...';

  @override
  String get profileStartFirstTrip =>
      'Starte deinen ersten Trip, um Statistiken zu sehen!';

  @override
  String get profileTrips => 'Trips';

  @override
  String get profilePois => 'POIs';

  @override
  String get profileKilometers => 'Kilometer';

  @override
  String get profileAchievements => 'Achievements';

  @override
  String get profileNoAchievements =>
      'Noch keine Achievements freigeschaltet. Starte deinen ersten Trip!';

  @override
  String profileAccountId(String id) {
    return 'Account-ID: $id';
  }

  @override
  String profileCreatedAt(String date) {
    return 'Erstellt am: $date';
  }

  @override
  String profileLastLogin(String date) {
    return 'Letzter Login: $date';
  }

  @override
  String get profileEditComingSoon => 'Profil-Bearbeitung kommt bald!';

  @override
  String get profileLogoutTitle => 'Ausloggen?';

  @override
  String get profileLogoutMessage => 'Möchtest du dich wirklich ausloggen?';

  @override
  String get profileLogoutCloudMessage =>
      'Möchtest du dich wirklich ausloggen?\n\nDeine Cloud-Daten bleiben erhalten und du kannst dich jederzeit wieder anmelden.';

  @override
  String get profileLogout => 'Ausloggen';

  @override
  String get profileDeleteTitle => 'Account löschen?';

  @override
  String get profileDeleteMessage =>
      'Möchtest du deinen Account wirklich löschen? Alle Daten werden unwiderruflich gelöscht!';

  @override
  String get favTitle => 'Favoriten';

  @override
  String get favRoutes => 'Routen';

  @override
  String get favPois => 'POIs';

  @override
  String get favDeleteAll => 'Alle löschen';

  @override
  String get favNoFavorites => 'Keine Favoriten';

  @override
  String get favNoFavoritesDesc =>
      'Speichere Routen und POIs für schnellen Zugriff';

  @override
  String get favExplore => 'Entdecken';

  @override
  String get favNoRoutes => 'Keine gespeicherten Routen';

  @override
  String get favPlanRoute => 'Route planen';

  @override
  String get favNoPois => 'Keine favorisierten POIs';

  @override
  String get favDiscoverPois => 'POIs entdecken';

  @override
  String get favRemoveRoute => 'Route entfernen?';

  @override
  String favRemoveRouteConfirm(String name) {
    return 'Möchtest du \"$name\" aus den Favoriten entfernen?';
  }

  @override
  String get favRemovePoi => 'POI entfernen?';

  @override
  String favRemovePoiConfirm(String name) {
    return 'Möchtest du \"$name\" aus den Favoriten entfernen?';
  }

  @override
  String get favRouteLoaded => 'Route geladen';

  @override
  String get favRouteRemoved => 'Route entfernt';

  @override
  String get favPoiRemoved => 'POI entfernt';

  @override
  String get favClearAll => 'Alle Favoriten löschen?';

  @override
  String get favAllDeleted => 'Alle Favoriten gelöscht';

  @override
  String get poiSearchHint => 'POIs durchsuchen...';

  @override
  String get poiClearFilters => 'Filter löschen';

  @override
  String get poiResetFilters => 'Filter zurücksetzen';

  @override
  String get poiLoading => 'Lade Sehenswürdigkeiten...';

  @override
  String get poiNotFound => 'POI nicht gefunden';

  @override
  String get poiLoadingDetails => 'Lade Details...';

  @override
  String get poiMoreOnWikipedia => 'Mehr auf Wikipedia';

  @override
  String get poiOpeningHours => 'Öffnungszeiten';

  @override
  String poiRouteCreated(String name) {
    return 'Route zu \"$name\" erstellt';
  }

  @override
  String get poiOnlyMustSee => 'Nur Must-See';

  @override
  String get poiShowOnlyHighlights => 'Zeige nur Highlights';

  @override
  String get poiOnlyIndoor => 'Nur Indoor-POIs';

  @override
  String get poiApplyFilters => 'Filter anwenden';

  @override
  String get poiReroll => 'Neu würfeln';

  @override
  String get poiTitle => 'Sehenswürdigkeiten';

  @override
  String get poiMustSee => 'Must-See';

  @override
  String get poiWeatherTip => 'Wetter-Tipp';

  @override
  String poiResultsCount(int filtered, int total) {
    return '$filtered von $total POIs';
  }

  @override
  String get poiNoResultsFilter => 'Keine POIs mit diesen Filtern gefunden';

  @override
  String get poiNoResultsNearby => 'Keine POIs in der Nähe gefunden';

  @override
  String get poiGpsPermissionNeeded =>
      'GPS-Berechtigung wird benötigt um POIs in der Nähe zu finden';

  @override
  String get poiWeatherDangerBanner =>
      'Unwetter erwartet – Indoor-POIs empfohlen';

  @override
  String get poiWeatherBadBanner =>
      'Regen erwartet – aktiviere \"Wetter-Tipp\" für bessere Sortierung';

  @override
  String get poiAboutPlace => 'Über diesen Ort';

  @override
  String get poiNoDescription => 'Keine Beschreibung verfügbar.';

  @override
  String get poiDescriptionLoading => 'Beschreibung wird geladen...';

  @override
  String get poiContactInfo => 'Kontakt & Info';

  @override
  String get poiPhone => 'Telefon';

  @override
  String get poiWebsite => 'Website';

  @override
  String get poiEmailLabel => 'E-Mail';

  @override
  String get poiDetour => 'Umweg';

  @override
  String get poiTime => 'Zeit';

  @override
  String get poiPosition => 'Position';

  @override
  String get poiCurated => 'Kuratiert';

  @override
  String get poiVerified => 'Verifiziert';

  @override
  String poiAddedToRoute(String name) {
    return '$name zur Route hinzugefügt';
  }

  @override
  String poiFoundedYear(int year) {
    return 'Gegründet $year';
  }

  @override
  String poiRating(String rating, int count) {
    return '$rating von 5 ($count Bewertungen)';
  }

  @override
  String get poiAddToRoute => 'Zur Route';

  @override
  String get scanTitle => 'Trip scannen';

  @override
  String get scanInstruction => 'QR-Code scannen';

  @override
  String get scanDescription =>
      'Halte dein Handy über einen MapAB QR-Code, um einen geteilten Trip zu importieren.';

  @override
  String get scanLoading => 'Trip wird geladen...';

  @override
  String get scanInvalidCode => 'Ungültiger QR-Code';

  @override
  String get scanInvalidMapabCode => 'Kein gültiger MapAB QR-Code';

  @override
  String get scanLoadError => 'Trip konnte nicht geladen werden';

  @override
  String get scanTripFound => 'Trip gefunden!';

  @override
  String scanStops(int count) {
    return '$count Stopps';
  }

  @override
  String scanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get scanImportQuestion => 'Möchtest du diesen Trip importieren?';

  @override
  String get scanImport => 'Importieren';

  @override
  String scanImportSuccess(String name) {
    return '$name wurde importiert!';
  }

  @override
  String get scanImportError => 'Trip konnte nicht importiert werden';

  @override
  String get templatesTitle => 'Trip-Vorlagen';

  @override
  String get templatesScanQr => 'QR-Code scannen';

  @override
  String get templatesAudienceAll => 'Alle';

  @override
  String get templatesAudienceCouples => 'Paare';

  @override
  String get templatesAudienceFamilies => 'Familien';

  @override
  String get templatesAudienceAdventurers => 'Abenteurer';

  @override
  String get templatesAudienceFoodies => 'Foodies';

  @override
  String get templatesAudiencePhotographers => 'Fotografen';

  @override
  String templatesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String templatesCategories(int count) {
    return '$count Kategorien';
  }

  @override
  String get templatesIncludedCategories => 'Enthaltene Kategorien';

  @override
  String get templatesDuration => 'Reisedauer';

  @override
  String templatesRecommended(int days, String daysText) {
    return 'Empfohlen: $days $daysText';
  }

  @override
  String templatesBestSeason(String season) {
    return 'Beste Reisezeit: $season';
  }

  @override
  String get templatesStartPlanning => 'Trip planen';

  @override
  String get seasonSpring => 'Frühling';

  @override
  String get seasonSummer => 'Sommer';

  @override
  String get seasonAutumn => 'Herbst';

  @override
  String get seasonWinter => 'Winter';

  @override
  String get seasonSpringAutumn => 'Frühling bis Herbst';

  @override
  String get seasonYearRound => 'Ganzjährig';

  @override
  String get day => 'Tag';

  @override
  String get days => 'Tage';

  @override
  String get searchSelectStart => 'Start wählen';

  @override
  String get searchSelectDestination => 'Ziel wählen';

  @override
  String get searchStartHint => 'Startpunkt suchen...';

  @override
  String get searchDestinationHint => 'Ziel suchen...';

  @override
  String get searchOfflineMode => 'Kein Internet - Zeige lokale Vorschläge';

  @override
  String get searchEnterLocation => 'Ort eingeben zum Suchen';

  @override
  String get searchNoResults => 'Keine Ergebnisse gefunden';

  @override
  String get searchLocationNotFound => 'Standort konnte nicht gefunden werden';

  @override
  String get chatTitle => 'AI-Assistent';

  @override
  String get chatClear => 'Chat leeren';

  @override
  String get chatWelcome =>
      'Hallo! Ich bin dein AI-Reiseassistent. Wie kann ich dir bei der Planung helfen?';

  @override
  String get chatInputHint => 'Nachricht eingeben...';

  @override
  String get chatClearConfirm => 'Chat leeren?';

  @override
  String get chatClearMessage => 'Die gesamte Konversation wird gelöscht.';

  @override
  String get chatCheckAgain => 'Erneut prüfen';

  @override
  String get chatAccept => 'Übernehmen';

  @override
  String chatShowAllPois(int count) {
    return 'Alle $count POIs anzeigen';
  }

  @override
  String get chatDestinationOptional => 'Ziel (optional)';

  @override
  String get chatEmptyRandomRoute => 'Leer = Zufällige Route um Startpunkt';

  @override
  String get chatStartOptional => 'Startpunkt (optional)';

  @override
  String get chatEmptyUseGps => 'Leer = GPS-Standort verwenden';

  @override
  String get chatIndoorTips => 'Indoor-Tipps bei Regen';

  @override
  String get chatPoisNearMe => 'POIs in meiner Nähe';

  @override
  String get chatAttractions => 'Sehenswürdigkeiten';

  @override
  String get chatRestaurants => 'Restaurants';

  @override
  String get chatOutdoorHighlights => 'Outdoor-Highlights';

  @override
  String get chatNatureParks => 'Natur & Parks';

  @override
  String get chatSearchRadius => 'Such-Radius';

  @override
  String get chatGenerateAiTrip => 'AI-Trip generieren';

  @override
  String get randomTripNoTrip => 'Kein Trip generiert';

  @override
  String get randomTripRegenerate => 'Neu generieren';

  @override
  String get randomTripConfirm => 'Trip bestätigen';

  @override
  String randomTripStopsDay(int day) {
    return 'Stops (Tag $day)';
  }

  @override
  String get randomTripStops => 'Stops';

  @override
  String get randomTripEnterAddress => 'Stadt oder Adresse eingeben...';

  @override
  String get randomTripShowDetails => 'Details anzeigen';

  @override
  String get randomTripOpenGoogleMaps => 'In Google Maps öffnen';

  @override
  String get randomTripSave => 'Trip speichern';

  @override
  String get randomTripShow => 'Trip anzeigen';

  @override
  String get randomTripBack => 'Zurück';

  @override
  String get tripTypeDayTrip => 'Tagesausflug';

  @override
  String get tripTypeEuroTrip => 'Euro Trip';

  @override
  String get tripTypeMultiDay => 'Mehrtages-Trip';

  @override
  String get tripTypeScenic => 'Scenic Route';

  @override
  String get tripTypeDayTripDistance => '30-200 km';

  @override
  String get tripTypeEuroTripDistance => '200-800 km';

  @override
  String get tripTypeMultiDayDistance => '2-7 Tage';

  @override
  String get tripTypeScenicDistance => 'variabel';

  @override
  String get tripTypeDayTripDesc => 'Aktivitäts-Auswahl, Wetter-basiert';

  @override
  String get tripTypeEuroTripDesc => 'Anderes Land, Hotel-Vorschläge';

  @override
  String get tripTypeMultiDayDesc => 'Automatische Übernachtungs-Stops';

  @override
  String get tripTypeScenicDesc => 'Aussichtspunkte priorisiert';

  @override
  String get accessWheelchair => 'Rollstuhlgerecht';

  @override
  String get accessNoStairs => 'Ohne Treppen';

  @override
  String get accessParking => 'Behindertenparkplatz';

  @override
  String get accessToilet => 'Behindertentoilette';

  @override
  String get accessElevator => 'Aufzug vorhanden';

  @override
  String get accessBraille => 'Blindenschrift';

  @override
  String get accessAudioGuide => 'Audio-Guide';

  @override
  String get accessSignLanguage => 'Gebärdensprache';

  @override
  String get accessAssistDogs => 'Assistenzhunde erlaubt';

  @override
  String get accessFullyAccessible => 'Vollständig zugänglich';

  @override
  String get accessLimited => 'Eingeschränkt zugänglich';

  @override
  String get accessNotAccessible => 'Nicht zugänglich';

  @override
  String get accessUnknown => 'Unbekannt';

  @override
  String get highlightUnesco => 'UNESCO-Welterbe';

  @override
  String get highlightMustSee => 'Must-See';

  @override
  String get highlightSecret => 'Geheimtipp';

  @override
  String get highlightHistoric => 'Historisch';

  @override
  String get highlightFamilyFriendly => 'Familienfreundlich';

  @override
  String experienceDetourKm(int km) {
    return '+$km km Umweg';
  }

  @override
  String get formatMinShort => 'Min.';

  @override
  String get formatHourShort => 'Std.';

  @override
  String get formatMinLong => 'Minuten';

  @override
  String formatHourLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Stunden',
      one: 'Stunde',
    );
    return '$_temp0';
  }

  @override
  String formatDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String formatStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stopps',
      one: '1 Stopp',
    );
    return '$_temp0';
  }

  @override
  String get formatNoInfo => 'Keine Angabe';

  @override
  String get formatJustNow => 'Gerade eben';

  @override
  String formatAgoMinutes(int count) {
    return 'Vor $count Min.';
  }

  @override
  String formatAgoHours(int count) {
    return 'Vor $count Std.';
  }

  @override
  String formatAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen',
      one: 'Vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get formatUnknown => 'Unbekannt';

  @override
  String get journalTitle => 'Reisetagebuch';

  @override
  String get journalEmptyTitle => 'Noch keine Einträge';

  @override
  String get journalEmptySubtitle =>
      'Halte deine Reiseerinnerungen mit Fotos und Notizen fest.';

  @override
  String get journalAddEntry => 'Eintrag hinzufügen';

  @override
  String get journalAddFirstEntry => 'Ersten Eintrag erstellen';

  @override
  String get journalNewEntry => 'Neuer Eintrag';

  @override
  String get journalAddPhoto => 'Foto hinzufügen';

  @override
  String get journalCamera => 'Kamera';

  @override
  String get journalGallery => 'Galerie';

  @override
  String get journalAddNote => 'Notiz hinzufügen';

  @override
  String get journalNoteHint => 'Was hast du erlebt?';

  @override
  String get journalSaveNote => 'Nur Notiz speichern';

  @override
  String get journalSaveLocation => 'Standort speichern';

  @override
  String get journalLocationAvailable => 'GPS-Standort verfügbar';

  @override
  String get journalLocationLoading => 'Standort wird geladen...';

  @override
  String get journalEnterNote => 'Bitte gib eine Notiz ein';

  @override
  String get journalDeleteEntryTitle => 'Eintrag löschen?';

  @override
  String get journalDeleteEntryMessage =>
      'Dieser Eintrag wird unwiderruflich gelöscht.';

  @override
  String get journalDeleteTitle => 'Tagebuch löschen?';

  @override
  String get journalDeleteMessage =>
      'Alle Einträge und Fotos werden unwiderruflich gelöscht.';

  @override
  String journalPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos',
      one: '1 Foto',
      zero: 'Keine Fotos',
    );
    return '$_temp0';
  }

  @override
  String journalEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
      zero: 'Keine Einträge',
    );
    return '$_temp0';
  }

  @override
  String journalDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String journalDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String journalDayNumber(int day) {
    return 'Tag $day';
  }

  @override
  String get journalOther => 'Sonstige';

  @override
  String get journalEntry => 'Eintrag';

  @override
  String get journalEntriesPlural => 'Einträge';

  @override
  String get journalOpenJournal => 'Tagebuch öffnen';

  @override
  String get journalAllJournals => 'Alle Tagebücher';

  @override
  String get journalNoJournals => 'Noch keine Tagebücher vorhanden';

  @override
  String get galleryTitle => 'Trip-Galerie';

  @override
  String get gallerySearch => 'Trips suchen...';

  @override
  String get galleryFeatured => 'Featured';

  @override
  String get galleryAllTrips => 'Alle Trips';

  @override
  String get galleryNoTrips => 'Keine Trips gefunden';

  @override
  String get galleryResetFilters => 'Filter zurücksetzen';

  @override
  String get galleryFilter => 'Filter';

  @override
  String get galleryFilterReset => 'Zurücksetzen';

  @override
  String get galleryTripType => 'Trip-Typ';

  @override
  String get galleryTags => 'Tags';

  @override
  String get gallerySort => 'Sortierung';

  @override
  String get gallerySortPopular => 'Beliebt';

  @override
  String get gallerySortRecent => 'Neueste';

  @override
  String get gallerySortLikes => 'Meiste Likes';

  @override
  String get galleryTypeAll => 'Alle';

  @override
  String get galleryTypeDaytrip => 'Tagesausflug';

  @override
  String get galleryTypeEurotrip => 'Euro Trip';

  @override
  String get galleryRetry => 'Erneut versuchen';

  @override
  String galleryLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Likes',
      one: '1 Like',
      zero: 'Noch keine Likes',
    );
    return '$_temp0';
  }

  @override
  String galleryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufrufe',
      one: '1 Aufruf',
    );
    return '$_temp0';
  }

  @override
  String galleryImports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Importe',
      one: '1 Import',
    );
    return '$_temp0';
  }

  @override
  String gallerySharedAt(String date) {
    return 'Geteilt am $date';
  }

  @override
  String galleryTripsShared(int count) {
    return '$count Trips geteilt';
  }

  @override
  String get galleryImportToFavorites => 'In Favoriten';

  @override
  String get galleryImported => 'Importiert';

  @override
  String get galleryShowOnMap => 'Auf Karte';

  @override
  String get galleryShareComingSoon => 'Teilen wird bald verfügbar';

  @override
  String get galleryMapComingSoon => 'Karten-Ansicht wird bald verfügbar';

  @override
  String get galleryImportSuccess => 'Trip in Favoriten importiert';

  @override
  String get galleryImportError => 'Import fehlgeschlagen';

  @override
  String get galleryTripNotFound => 'Trip nicht gefunden';

  @override
  String get galleryLoadError => 'Fehler beim Laden';

  @override
  String get publishTitle => 'Trip veröffentlichen';

  @override
  String get publishSubtitle => 'Teile deinen Trip mit der Community';

  @override
  String get publishTripName => 'Name des Trips';

  @override
  String get publishTripNameHint => 'z.B. Südfrankreich Roadtrip';

  @override
  String get publishTripNameRequired => 'Bitte gib einen Namen ein';

  @override
  String get publishTripNameMinLength => 'Name muss mindestens 3 Zeichen haben';

  @override
  String get publishDescription => 'Beschreibung (optional)';

  @override
  String get publishDescriptionHint => 'Erzähle anderen von deinem Trip...';

  @override
  String get publishTags => 'Tags (optional)';

  @override
  String get publishTagsHelper => 'Hilf anderen, deinen Trip zu finden';

  @override
  String get publishMaxTags => 'Maximal 5 Tags';

  @override
  String get publishInfo =>
      'Dein Trip wird öffentlich sichtbar. Andere können ihn liken und in ihre Favoriten importieren.';

  @override
  String get publishButton => 'Veröffentlichen';

  @override
  String get publishPublishing => 'Wird veröffentlicht...';

  @override
  String get publishSuccess => 'Trip veröffentlicht!';

  @override
  String get publishError => 'Veröffentlichen fehlgeschlagen';

  @override
  String get publishEuroTrip => 'Euro Trip';

  @override
  String get publishDaytrip => 'Tagesausflug';
}
