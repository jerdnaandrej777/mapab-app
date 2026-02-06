import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @appName.
  ///
  /// In de, this message translates to:
  /// **'MapAB'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get remove;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get no;

  /// No description provided for @or.
  ///
  /// In de, this message translates to:
  /// **'ODER'**
  String get or;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Lädt...'**
  String get loading;

  /// No description provided for @search.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get search;

  /// No description provided for @show.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get show;

  /// No description provided for @apply.
  ///
  /// In de, this message translates to:
  /// **'Anwenden'**
  String get apply;

  /// No description provided for @active.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get active;

  /// No description provided for @discard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get discard;

  /// No description provided for @resume.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get resume;

  /// No description provided for @skip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get skip;

  /// No description provided for @all.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get all;

  /// No description provided for @total.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get total;

  /// No description provided for @newLabel.
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get newLabel;

  /// No description provided for @start.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @destination.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get destination;

  /// No description provided for @showOnMap.
  ///
  /// In de, this message translates to:
  /// **'Auf Karte anzeigen'**
  String get showOnMap;

  /// No description provided for @openSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get openSettings;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In de, this message translates to:
  /// **'Diese Aktion kann nicht rückgängig gemacht werden.'**
  String get actionCannotBeUndone;

  /// No description provided for @details.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @generate.
  ///
  /// In de, this message translates to:
  /// **'Generieren'**
  String get generate;

  /// No description provided for @clear.
  ///
  /// In de, this message translates to:
  /// **'Leeren'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get reset;

  /// No description provided for @end.
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get end;

  /// No description provided for @reroll.
  ///
  /// In de, this message translates to:
  /// **'Neu würfeln'**
  String get reroll;

  /// No description provided for @filterApply.
  ///
  /// In de, this message translates to:
  /// **'Filter anwenden'**
  String get filterApply;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In de, this message translates to:
  /// **'In Google Maps öffnen'**
  String get openInGoogleMaps;

  /// No description provided for @shareLinkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link in Zwischenablage kopiert!'**
  String get shareLinkCopied;

  /// No description provided for @shareAsText.
  ///
  /// In de, this message translates to:
  /// **'Als Text teilen'**
  String get shareAsText;

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Ein Fehler ist aufgetreten'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung'**
  String get errorNetwork;

  /// No description provided for @errorNetworkMessage.
  ///
  /// In de, this message translates to:
  /// **'Bitte überprüfe deine Verbindung und versuche es erneut.'**
  String get errorNetworkMessage;

  /// No description provided for @errorServer.
  ///
  /// In de, this message translates to:
  /// **'Server nicht erreichbar'**
  String get errorServer;

  /// No description provided for @errorServerMessage.
  ///
  /// In de, this message translates to:
  /// **'Der Server antwortet nicht. Versuche es später erneut.'**
  String get errorServerMessage;

  /// No description provided for @errorNoResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse'**
  String get errorNoResults;

  /// No description provided for @errorLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort nicht verfügbar'**
  String get errorLocation;

  /// No description provided for @errorLocationMessage.
  ///
  /// In de, this message translates to:
  /// **'Bitte erlaube den Zugriff auf deinen Standort.'**
  String get errorLocationMessage;

  /// No description provided for @errorPrefix.
  ///
  /// In de, this message translates to:
  /// **'Fehler: '**
  String get errorPrefix;

  /// No description provided for @pageNotFound.
  ///
  /// In de, this message translates to:
  /// **'Seite nicht gefunden'**
  String get pageNotFound;

  /// No description provided for @goToHome.
  ///
  /// In de, this message translates to:
  /// **'Zur Startseite'**
  String get goToHome;

  /// No description provided for @errorRouteCalculation.
  ///
  /// In de, this message translates to:
  /// **'Routenberechnung fehlgeschlagen. Bitte versuche es erneut.'**
  String get errorRouteCalculation;

  /// No description provided for @errorTripGeneration.
  ///
  /// In de, this message translates to:
  /// **'Trip-Generierung fehlgeschlagen: {error}'**
  String errorTripGeneration(String error);

  /// No description provided for @errorGoogleMapsNotOpened.
  ///
  /// In de, this message translates to:
  /// **'Google Maps konnte nicht geöffnet werden'**
  String get errorGoogleMapsNotOpened;

  /// No description provided for @errorRouteNotShared.
  ///
  /// In de, this message translates to:
  /// **'Route konnte nicht geteilt werden'**
  String get errorRouteNotShared;

  /// No description provided for @errorAddingToRoute.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Hinzufügen'**
  String get errorAddingToRoute;

  /// No description provided for @errorIncompleteRouteData.
  ///
  /// In de, this message translates to:
  /// **'Route-Daten sind unvollständig'**
  String get errorIncompleteRouteData;

  /// No description provided for @gpsDisabledTitle.
  ///
  /// In de, this message translates to:
  /// **'GPS deaktiviert'**
  String get gpsDisabledTitle;

  /// No description provided for @gpsDisabledMessage.
  ///
  /// In de, this message translates to:
  /// **'Die Ortungsdienste sind deaktiviert. Möchtest du die GPS-Einstellungen öffnen?'**
  String get gpsDisabledMessage;

  /// No description provided for @gpsPermissionDenied.
  ///
  /// In de, this message translates to:
  /// **'GPS-Berechtigung wurde verweigert'**
  String get gpsPermissionDenied;

  /// No description provided for @gpsPermissionDeniedForeverTitle.
  ///
  /// In de, this message translates to:
  /// **'GPS-Berechtigung verweigert'**
  String get gpsPermissionDeniedForeverTitle;

  /// No description provided for @gpsPermissionDeniedForeverMessage.
  ///
  /// In de, this message translates to:
  /// **'Die GPS-Berechtigung wurde dauerhaft verweigert. Bitte erlaube den Standortzugriff in den App-Einstellungen.'**
  String get gpsPermissionDeniedForeverMessage;

  /// No description provided for @gpsCouldNotDetermine.
  ///
  /// In de, this message translates to:
  /// **'GPS-Position konnte nicht ermittelt werden'**
  String get gpsCouldNotDetermine;

  /// No description provided for @appSettingsButton.
  ///
  /// In de, this message translates to:
  /// **'App-Einstellungen'**
  String get appSettingsButton;

  /// No description provided for @myLocation.
  ///
  /// In de, this message translates to:
  /// **'Mein Standort'**
  String get myLocation;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei MapAB'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Dein AI-Reiseplaner für unvergessliche Trips'**
  String get authWelcomeSubtitle;

  /// No description provided for @authCloudNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Cloud nicht verfügbar - App ohne Supabase-Credentials gebaut'**
  String get authCloudNotAvailable;

  /// No description provided for @authCloudLoginUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Login nicht verfügbar - App ohne Supabase-Credentials gebaut'**
  String get authCloudLoginUnavailable;

  /// No description provided for @authEmailLabel.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get authEmailLabel;

  /// No description provided for @authEmailEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte E-Mail eingeben'**
  String get authEmailEmpty;

  /// No description provided for @authEmailInvalid.
  ///
  /// In de, this message translates to:
  /// **'Ungültige E-Mail'**
  String get authEmailInvalid;

  /// No description provided for @authEmailInvalidAddress.
  ///
  /// In de, this message translates to:
  /// **'Ungültige E-Mail-Adresse'**
  String get authEmailInvalidAddress;

  /// No description provided for @authPasswordLabel.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte Passwort eingeben'**
  String get authPasswordEmpty;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 8 Zeichen'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordRequirements.
  ///
  /// In de, this message translates to:
  /// **'Muss Buchstaben und Zahlen enthalten'**
  String get authPasswordRequirements;

  /// No description provided for @authPasswordConfirm.
  ///
  /// In de, this message translates to:
  /// **'Passwort bestätigen'**
  String get authPasswordConfirm;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In de, this message translates to:
  /// **'Passwörter stimmen nicht überein'**
  String get authPasswordMismatch;

  /// No description provided for @authRememberMe.
  ///
  /// In de, this message translates to:
  /// **'Anmeldedaten merken'**
  String get authRememberMe;

  /// No description provided for @authForgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get authSignIn;

  /// No description provided for @authNoAccount.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Konto? '**
  String get authNoAccount;

  /// No description provided for @authRegister.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get authRegister;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In de, this message translates to:
  /// **'Als Gast fortfahren'**
  String get authContinueAsGuest;

  /// No description provided for @authGuestInfoCloud.
  ///
  /// In de, this message translates to:
  /// **'Als Gast werden deine Daten nur lokal gespeichert und nicht synchronisiert.'**
  String get authGuestInfoCloud;

  /// No description provided for @authGuestInfoLocal.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten werden lokal auf deinem Gerät gespeichert.'**
  String get authGuestInfoLocal;

  /// No description provided for @authCreateAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get authCreateAccount;

  /// No description provided for @authSecureData.
  ///
  /// In de, this message translates to:
  /// **'Sichere deine Daten in der Cloud'**
  String get authSecureData;

  /// No description provided for @authNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get authNameLabel;

  /// No description provided for @authNameHint.
  ///
  /// In de, this message translates to:
  /// **'Wie möchtest du genannt werden?'**
  String get authNameHint;

  /// No description provided for @authNameEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte Namen eingeben'**
  String get authNameEmpty;

  /// No description provided for @authNameMinLength.
  ///
  /// In de, this message translates to:
  /// **'Name muss mindestens 2 Zeichen haben'**
  String get authNameMinLength;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In de, this message translates to:
  /// **'Bereits ein Konto? '**
  String get authAlreadyHaveAccount;

  /// No description provided for @authExistingAccount.
  ///
  /// In de, this message translates to:
  /// **'Ich habe bereits ein Konto'**
  String get authExistingAccount;

  /// No description provided for @authRegistrationSuccess.
  ///
  /// In de, this message translates to:
  /// **'Registrierung erfolgreich'**
  String get authRegistrationSuccess;

  /// No description provided for @authRegistrationSuccessMessage.
  ///
  /// In de, this message translates to:
  /// **'Bitte prüfe deine E-Mails und bestätige dein Konto.'**
  String get authRegistrationSuccessMessage;

  /// No description provided for @authResetPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort zurücksetzen'**
  String get authResetPassword;

  /// No description provided for @authResetPasswordInstructions.
  ///
  /// In de, this message translates to:
  /// **'Gib deine E-Mail-Adresse ein und wir senden dir einen Link zum Zurücksetzen.'**
  String get authResetPasswordInstructions;

  /// No description provided for @authSendLink.
  ///
  /// In de, this message translates to:
  /// **'Link senden'**
  String get authSendLink;

  /// No description provided for @authBackToLogin.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Anmeldung'**
  String get authBackToLogin;

  /// No description provided for @authEmailSent.
  ///
  /// In de, this message translates to:
  /// **'E-Mail gesendet!'**
  String get authEmailSent;

  /// No description provided for @authEmailSentPrefix.
  ///
  /// In de, this message translates to:
  /// **'Wir haben dir eine E-Mail an'**
  String get authEmailSentPrefix;

  /// No description provided for @authEmailSentSuffix.
  ///
  /// In de, this message translates to:
  /// **'gesendet.'**
  String get authEmailSentSuffix;

  /// No description provided for @authResetLinkInstructions.
  ///
  /// In de, this message translates to:
  /// **'Klicke auf den Link in der E-Mail, um ein neues Passwort zu setzen. Der Link ist 24 Stunden gültig.'**
  String get authResetLinkInstructions;

  /// No description provided for @authResend.
  ///
  /// In de, this message translates to:
  /// **'Erneut senden'**
  String get authResend;

  /// No description provided for @authCreateLocalProfile.
  ///
  /// In de, this message translates to:
  /// **'Lokales Profil erstellen'**
  String get authCreateLocalProfile;

  /// No description provided for @authUsernameLabel.
  ///
  /// In de, this message translates to:
  /// **'Benutzername'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. reisefan123'**
  String get authUsernameHint;

  /// No description provided for @authDisplayNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Anzeigename'**
  String get authDisplayNameLabel;

  /// No description provided for @authDisplayNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Max Mustermann'**
  String get authDisplayNameHint;

  /// No description provided for @authEmailOptional.
  ///
  /// In de, this message translates to:
  /// **'E-Mail (optional)'**
  String get authEmailOptional;

  /// No description provided for @authEmailHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. max@example.com'**
  String get authEmailHint;

  /// No description provided for @authCreate.
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get authCreate;

  /// No description provided for @authRequiredFields.
  ///
  /// In de, this message translates to:
  /// **'Benutzername und Anzeigename sind erforderlich'**
  String get authRequiredFields;

  /// No description provided for @authGuestDescription.
  ///
  /// In de, this message translates to:
  /// **'Als Gast kannst du sofort loslegen. Deine Daten werden lokal auf deinem Gerät gespeichert.'**
  String get authGuestDescription;

  /// No description provided for @authComingSoon.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Login kommt bald:'**
  String get authComingSoon;

  /// No description provided for @authLoadingText.
  ///
  /// In de, this message translates to:
  /// **'Lade...'**
  String get authLoadingText;

  /// No description provided for @splashTagline.
  ///
  /// In de, this message translates to:
  /// **'Dein AI-Reiseplaner'**
  String get splashTagline;

  /// No description provided for @onboardingTitle1.
  ///
  /// In de, this message translates to:
  /// **'Entdecke Sehenswürdigkeiten'**
  String get onboardingTitle1;

  /// No description provided for @onboardingHighlight1.
  ///
  /// In de, this message translates to:
  /// **'Sehenswürdigkeiten'**
  String get onboardingHighlight1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In de, this message translates to:
  /// **'Finde über 500 handverlesene POIs in ganz Europa.\nSchlösser, Seen, Museen und Geheimtipps warten auf dich.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In de, this message translates to:
  /// **'Dein KI-Reiseassistent'**
  String get onboardingTitle2;

  /// No description provided for @onboardingHighlight2.
  ///
  /// In de, this message translates to:
  /// **'KI'**
  String get onboardingHighlight2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In de, this message translates to:
  /// **'Lass dir automatisch die perfekte Route planen.\nMit smarter Optimierung für deine Interessen.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In de, this message translates to:
  /// **'Deine Reisen in der Cloud'**
  String get onboardingTitle3;

  /// No description provided for @onboardingHighlight3.
  ///
  /// In de, this message translates to:
  /// **'Cloud'**
  String get onboardingHighlight3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In de, this message translates to:
  /// **'Speichere Favoriten und Trips sicher online.\nSynchronisiert auf allen deinen Geräten.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingStart.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get onboardingStart;

  /// No description provided for @categoryCastle.
  ///
  /// In de, this message translates to:
  /// **'Schlösser & Burgen'**
  String get categoryCastle;

  /// No description provided for @categoryNature.
  ///
  /// In de, this message translates to:
  /// **'Natur & Wälder'**
  String get categoryNature;

  /// No description provided for @categoryMuseum.
  ///
  /// In de, this message translates to:
  /// **'Museen'**
  String get categoryMuseum;

  /// No description provided for @categoryViewpoint.
  ///
  /// In de, this message translates to:
  /// **'Aussichtspunkte'**
  String get categoryViewpoint;

  /// No description provided for @categoryLake.
  ///
  /// In de, this message translates to:
  /// **'Seen'**
  String get categoryLake;

  /// No description provided for @categoryCoast.
  ///
  /// In de, this message translates to:
  /// **'Küsten & Strände'**
  String get categoryCoast;

  /// No description provided for @categoryPark.
  ///
  /// In de, this message translates to:
  /// **'Parks & Nationalparks'**
  String get categoryPark;

  /// No description provided for @categoryCity.
  ///
  /// In de, this message translates to:
  /// **'Städte'**
  String get categoryCity;

  /// No description provided for @categoryActivity.
  ///
  /// In de, this message translates to:
  /// **'Aktivitäten'**
  String get categoryActivity;

  /// No description provided for @categoryHotel.
  ///
  /// In de, this message translates to:
  /// **'Hotels'**
  String get categoryHotel;

  /// No description provided for @categoryRestaurant.
  ///
  /// In de, this message translates to:
  /// **'Restaurants'**
  String get categoryRestaurant;

  /// No description provided for @categoryUnesco.
  ///
  /// In de, this message translates to:
  /// **'UNESCO-Welterbe'**
  String get categoryUnesco;

  /// No description provided for @categoryChurch.
  ///
  /// In de, this message translates to:
  /// **'Kirchen'**
  String get categoryChurch;

  /// No description provided for @categoryMonument.
  ///
  /// In de, this message translates to:
  /// **'Monumente'**
  String get categoryMonument;

  /// No description provided for @categoryAttraction.
  ///
  /// In de, this message translates to:
  /// **'Attraktionen'**
  String get categoryAttraction;

  /// No description provided for @weatherGood.
  ///
  /// In de, this message translates to:
  /// **'Gut'**
  String get weatherGood;

  /// No description provided for @weatherMixed.
  ///
  /// In de, this message translates to:
  /// **'Wechselhaft'**
  String get weatherMixed;

  /// No description provided for @weatherBad.
  ///
  /// In de, this message translates to:
  /// **'Schlecht'**
  String get weatherBad;

  /// No description provided for @weatherDanger.
  ///
  /// In de, this message translates to:
  /// **'Gefährlich'**
  String get weatherDanger;

  /// No description provided for @weatherUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get weatherUnknown;

  /// No description provided for @weatherClear.
  ///
  /// In de, this message translates to:
  /// **'Klar'**
  String get weatherClear;

  /// No description provided for @weatherMostlyClear.
  ///
  /// In de, this message translates to:
  /// **'Überwiegend klar'**
  String get weatherMostlyClear;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In de, this message translates to:
  /// **'Teilweise bewölkt'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherCloudy.
  ///
  /// In de, this message translates to:
  /// **'Bewölkt'**
  String get weatherCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In de, this message translates to:
  /// **'Nebel'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In de, this message translates to:
  /// **'Nieselregen'**
  String get weatherDrizzle;

  /// No description provided for @weatherFreezingDrizzle.
  ///
  /// In de, this message translates to:
  /// **'Gefrierender Nieselregen'**
  String get weatherFreezingDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In de, this message translates to:
  /// **'Regen'**
  String get weatherRain;

  /// No description provided for @weatherFreezingRain.
  ///
  /// In de, this message translates to:
  /// **'Gefrierender Regen'**
  String get weatherFreezingRain;

  /// No description provided for @weatherSnow.
  ///
  /// In de, this message translates to:
  /// **'Schneefall'**
  String get weatherSnow;

  /// No description provided for @weatherSnowGrains.
  ///
  /// In de, this message translates to:
  /// **'Schneegriesel'**
  String get weatherSnowGrains;

  /// No description provided for @weatherRainShowers.
  ///
  /// In de, this message translates to:
  /// **'Regenschauer'**
  String get weatherRainShowers;

  /// No description provided for @weatherSnowShowers.
  ///
  /// In de, this message translates to:
  /// **'Schneeschauer'**
  String get weatherSnowShowers;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In de, this message translates to:
  /// **'Gewitter'**
  String get weatherThunderstorm;

  /// No description provided for @weatherThunderstormHail.
  ///
  /// In de, this message translates to:
  /// **'Gewitter mit Hagel'**
  String get weatherThunderstormHail;

  /// No description provided for @weatherForecast7Day.
  ///
  /// In de, this message translates to:
  /// **'7-Tage-Vorhersage'**
  String get weatherForecast7Day;

  /// No description provided for @weatherToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get weatherToday;

  /// No description provided for @weatherFeelsLike.
  ///
  /// In de, this message translates to:
  /// **'Gefühlt {temp}°'**
  String weatherFeelsLike(String temp);

  /// No description provided for @weatherSunrise.
  ///
  /// In de, this message translates to:
  /// **'Sonnenaufgang'**
  String get weatherSunrise;

  /// No description provided for @weatherSunset.
  ///
  /// In de, this message translates to:
  /// **'Sonnenuntergang'**
  String get weatherSunset;

  /// No description provided for @weatherUvIndex.
  ///
  /// In de, this message translates to:
  /// **'UV-Index'**
  String get weatherUvIndex;

  /// No description provided for @weatherPrecipitation.
  ///
  /// In de, this message translates to:
  /// **'Niederschlag'**
  String get weatherPrecipitation;

  /// No description provided for @weatherWind.
  ///
  /// In de, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// No description provided for @weatherRainRisk.
  ///
  /// In de, this message translates to:
  /// **'Regenrisiko'**
  String get weatherRainRisk;

  /// No description provided for @weatherRecommendationToday.
  ///
  /// In de, this message translates to:
  /// **'Empfehlung für heute'**
  String get weatherRecommendationToday;

  /// No description provided for @weatherRecGood.
  ///
  /// In de, this message translates to:
  /// **'Perfektes Wetter für Outdoor-Aktivitäten! Viewpoints, Natur und Seen empfohlen.'**
  String get weatherRecGood;

  /// No description provided for @weatherRecMixed.
  ///
  /// In de, this message translates to:
  /// **'Wechselhaft - flexibel planen'**
  String get weatherRecMixed;

  /// No description provided for @weatherRecBad.
  ///
  /// In de, this message translates to:
  /// **'Regen erwartet. Indoor-Aktivitäten wie Museen und Kirchen empfohlen.'**
  String get weatherRecBad;

  /// No description provided for @weatherRecDanger.
  ///
  /// In de, this message translates to:
  /// **'Unwetterwarnung! Bitte Outdoor-Aktivitäten vermeiden und drinnen bleiben.'**
  String get weatherRecDanger;

  /// No description provided for @weatherRecUnknown.
  ///
  /// In de, this message translates to:
  /// **'Keine Wetterdaten verfügbar.'**
  String get weatherRecUnknown;

  /// No description provided for @weatherUvLow.
  ///
  /// In de, this message translates to:
  /// **'{value} (Niedrig)'**
  String weatherUvLow(String value);

  /// No description provided for @weatherUvMedium.
  ///
  /// In de, this message translates to:
  /// **'{value} (Mittel)'**
  String weatherUvMedium(String value);

  /// No description provided for @weatherUvHigh.
  ///
  /// In de, this message translates to:
  /// **'{value} (Hoch)'**
  String weatherUvHigh(String value);

  /// No description provided for @weatherUvVeryHigh.
  ///
  /// In de, this message translates to:
  /// **'{value} (Sehr hoch)'**
  String weatherUvVeryHigh(String value);

  /// No description provided for @weatherUvExtreme.
  ///
  /// In de, this message translates to:
  /// **'{value} (Extrem)'**
  String weatherUvExtreme(String value);

  /// No description provided for @weatherLoading.
  ///
  /// In de, this message translates to:
  /// **'Wetter laden...'**
  String get weatherLoading;

  /// No description provided for @weatherWinterWeather.
  ///
  /// In de, this message translates to:
  /// **'Winterwetter'**
  String get weatherWinterWeather;

  /// No description provided for @weatherStormOnRoute.
  ///
  /// In de, this message translates to:
  /// **'Unwetter auf der Route'**
  String get weatherStormOnRoute;

  /// No description provided for @weatherRainPossible.
  ///
  /// In de, this message translates to:
  /// **'Regen möglich'**
  String get weatherRainPossible;

  /// No description provided for @weatherGoodWeather.
  ///
  /// In de, this message translates to:
  /// **'Gutes Wetter'**
  String get weatherGoodWeather;

  /// No description provided for @weatherChangeable.
  ///
  /// In de, this message translates to:
  /// **'Wechselhaft'**
  String get weatherChangeable;

  /// No description provided for @weatherBadWeather.
  ///
  /// In de, this message translates to:
  /// **'Schlechtes Wetter'**
  String get weatherBadWeather;

  /// No description provided for @weatherStormWarning.
  ///
  /// In de, this message translates to:
  /// **'Unwetterwarnung'**
  String get weatherStormWarning;

  /// No description provided for @weatherPerfect.
  ///
  /// In de, this message translates to:
  /// **'Perfekt'**
  String get weatherPerfect;

  /// No description provided for @weatherStorm.
  ///
  /// In de, this message translates to:
  /// **'Unwetter'**
  String get weatherStorm;

  /// No description provided for @weatherIdealOutdoor.
  ///
  /// In de, this message translates to:
  /// **'Heute ideal für Outdoor-POIs'**
  String get weatherIdealOutdoor;

  /// No description provided for @weatherFlexiblePlanning.
  ///
  /// In de, this message translates to:
  /// **'Wechselhaft - flexibel planen'**
  String get weatherFlexiblePlanning;

  /// No description provided for @weatherRainIndoor.
  ///
  /// In de, this message translates to:
  /// **'Regen - Indoor-POIs empfohlen'**
  String get weatherRainIndoor;

  /// No description provided for @weatherStormIndoorOnly.
  ///
  /// In de, this message translates to:
  /// **'Unwetter - nur Indoor-POIs!'**
  String get weatherStormIndoorOnly;

  /// No description provided for @weatherOnlyIndoor.
  ///
  /// In de, this message translates to:
  /// **'Nur Indoor-POIs'**
  String get weatherOnlyIndoor;

  /// No description provided for @weatherStormHighWinds.
  ///
  /// In de, this message translates to:
  /// **'Sturmwarnung! Starke Winde ({speed} km/h) entlang der Route.'**
  String weatherStormHighWinds(String speed);

  /// No description provided for @weatherStormDelay.
  ///
  /// In de, this message translates to:
  /// **'Unwetterwarnung! Fahrt verschieben empfohlen.'**
  String get weatherStormDelay;

  /// No description provided for @weatherWinterWarning.
  ///
  /// In de, this message translates to:
  /// **'Winterwetter! Schnee/Glätte möglich.'**
  String get weatherWinterWarning;

  /// No description provided for @weatherRainRecommendation.
  ///
  /// In de, this message translates to:
  /// **'Regen erwartet. Indoor-Aktivitäten empfohlen.'**
  String get weatherRainRecommendation;

  /// No description provided for @weatherBadOnRoute.
  ///
  /// In de, this message translates to:
  /// **'Schlechtes Wetter auf der Route.'**
  String get weatherBadOnRoute;

  /// No description provided for @weatherPerfectOutdoor.
  ///
  /// In de, this message translates to:
  /// **'Perfektes Wetter für Outdoor-Aktivitäten'**
  String get weatherPerfectOutdoor;

  /// No description provided for @weatherBePrepared.
  ///
  /// In de, this message translates to:
  /// **'Wechselhaft - auf alles vorbereitet sein'**
  String get weatherBePrepared;

  /// No description provided for @weatherSnowWarning.
  ///
  /// In de, this message translates to:
  /// **'Schneefall - Vorsicht auf glatten Straßen'**
  String get weatherSnowWarning;

  /// No description provided for @weatherBadIndoor.
  ///
  /// In de, this message translates to:
  /// **'Schlechtes Wetter - Indoor-Aktivitäten empfohlen'**
  String get weatherBadIndoor;

  /// No description provided for @weatherStormCaution.
  ///
  /// In de, this message translates to:
  /// **'Unwetterwarnung! Vorsicht auf diesem Streckenabschnitt'**
  String get weatherStormCaution;

  /// No description provided for @weatherNoData.
  ///
  /// In de, this message translates to:
  /// **'Keine Wetterdaten verfügbar'**
  String get weatherNoData;

  /// No description provided for @weatherRoutePoint.
  ///
  /// In de, this message translates to:
  /// **'Routenpunkt {index} von {total}'**
  String weatherRoutePoint(String index, String total);

  /// No description provided for @weatherExpectedOnDay.
  ///
  /// In de, this message translates to:
  /// **'{weather} auf Tag {day} erwartet'**
  String weatherExpectedOnDay(String weather, int day);

  /// No description provided for @weatherOutdoorStops.
  ///
  /// In de, this message translates to:
  /// **'{outdoor} von {total} Stops sind Outdoor-Aktivitäten.'**
  String weatherOutdoorStops(int outdoor, int total);

  /// No description provided for @weatherSuggestIndoor.
  ///
  /// In de, this message translates to:
  /// **'Indoor-Alternativen vorschlagen'**
  String get weatherSuggestIndoor;

  /// No description provided for @weatherStormExpected.
  ///
  /// In de, this message translates to:
  /// **'Unwetter erwartet'**
  String get weatherStormExpected;

  /// No description provided for @weatherRainExpected.
  ///
  /// In de, this message translates to:
  /// **'Regen erwartet'**
  String get weatherRainExpected;

  /// No description provided for @weatherIdealOutdoorWeather.
  ///
  /// In de, this message translates to:
  /// **'Ideales Outdoor-Wetter'**
  String get weatherIdealOutdoorWeather;

  /// No description provided for @weatherStormIndoorPrefer.
  ///
  /// In de, this message translates to:
  /// **'Unwetter erwartet – Indoor-Stops bevorzugen'**
  String get weatherStormIndoorPrefer;

  /// No description provided for @weatherRainIndoorHighlight.
  ///
  /// In de, this message translates to:
  /// **'Regen erwartet – Indoor-Stops hervorgehoben'**
  String get weatherRainIndoorHighlight;

  /// No description provided for @weekdayMon.
  ///
  /// In de, this message translates to:
  /// **'Mo'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In de, this message translates to:
  /// **'Di'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In de, this message translates to:
  /// **'Mi'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In de, this message translates to:
  /// **'Do'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In de, this message translates to:
  /// **'Fr'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In de, this message translates to:
  /// **'Sa'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In de, this message translates to:
  /// **'So'**
  String get weekdaySun;

  /// No description provided for @mapFavorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get mapFavorites;

  /// No description provided for @mapProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get mapProfile;

  /// No description provided for @mapSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get mapSettings;

  /// No description provided for @mapToRoute.
  ///
  /// In de, this message translates to:
  /// **'Zur Route'**
  String get mapToRoute;

  /// No description provided for @mapSetAsStart.
  ///
  /// In de, this message translates to:
  /// **'Als Start setzen'**
  String get mapSetAsStart;

  /// No description provided for @mapSetAsDestination.
  ///
  /// In de, this message translates to:
  /// **'Als Ziel setzen'**
  String get mapSetAsDestination;

  /// No description provided for @mapAddAsStop.
  ///
  /// In de, this message translates to:
  /// **'Als Stopp hinzufügen'**
  String get mapAddAsStop;

  /// No description provided for @tripConfigGps.
  ///
  /// In de, this message translates to:
  /// **'GPS'**
  String get tripConfigGps;

  /// No description provided for @tripConfigCityOrAddress.
  ///
  /// In de, this message translates to:
  /// **'Stadt oder Adresse...'**
  String get tripConfigCityOrAddress;

  /// No description provided for @tripConfigDestinationOptional.
  ///
  /// In de, this message translates to:
  /// **'Ziel (optional)'**
  String get tripConfigDestinationOptional;

  /// No description provided for @tripConfigAddDestination.
  ///
  /// In de, this message translates to:
  /// **'Ziel hinzufügen (optional)'**
  String get tripConfigAddDestination;

  /// No description provided for @tripConfigEnterDestination.
  ///
  /// In de, this message translates to:
  /// **'Zielort eingeben...'**
  String get tripConfigEnterDestination;

  /// No description provided for @tripConfigNoDestinationRoundtrip.
  ///
  /// In de, this message translates to:
  /// **'Ohne Ziel: Rundreise ab Start'**
  String get tripConfigNoDestinationRoundtrip;

  /// No description provided for @tripConfigSurpriseMe.
  ///
  /// In de, this message translates to:
  /// **'Überrasch mich!'**
  String get tripConfigSurpriseMe;

  /// No description provided for @tripConfigDeleteRoute.
  ///
  /// In de, this message translates to:
  /// **'Route löschen'**
  String get tripConfigDeleteRoute;

  /// No description provided for @tripConfigTripDuration.
  ///
  /// In de, this message translates to:
  /// **'Reisedauer'**
  String get tripConfigTripDuration;

  /// No description provided for @tripConfigDay.
  ///
  /// In de, this message translates to:
  /// **'Tag'**
  String get tripConfigDay;

  /// No description provided for @tripConfigDays.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get tripConfigDays;

  /// No description provided for @tripConfigDayTrip.
  ///
  /// In de, this message translates to:
  /// **'Tagesausflug — ca. {distance} km'**
  String tripConfigDayTrip(String distance);

  /// No description provided for @tripConfigWeekendTrip.
  ///
  /// In de, this message translates to:
  /// **'Wochenend-Trip — ca. {distance} km'**
  String tripConfigWeekendTrip(String distance);

  /// No description provided for @tripConfigShortVacation.
  ///
  /// In de, this message translates to:
  /// **'Kurzurlaub — ca. {distance} km'**
  String tripConfigShortVacation(String distance);

  /// No description provided for @tripConfigWeekTravel.
  ///
  /// In de, this message translates to:
  /// **'Wochenreise — ca. {distance} km'**
  String tripConfigWeekTravel(String distance);

  /// No description provided for @tripConfigEpicEuroTrip.
  ///
  /// In de, this message translates to:
  /// **'Epischer Euro Trip — ca. {distance} km'**
  String tripConfigEpicEuroTrip(String distance);

  /// No description provided for @tripConfigRadius.
  ///
  /// In de, this message translates to:
  /// **'Radius'**
  String get tripConfigRadius;

  /// No description provided for @tripConfigPoiCategories.
  ///
  /// In de, this message translates to:
  /// **'POI-Kategorien'**
  String get tripConfigPoiCategories;

  /// No description provided for @tripConfigResetAll.
  ///
  /// In de, this message translates to:
  /// **'Alle zurücksetzen'**
  String get tripConfigResetAll;

  /// No description provided for @tripConfigAllCategories.
  ///
  /// In de, this message translates to:
  /// **'Alle Kategorien ausgewählt'**
  String get tripConfigAllCategories;

  /// No description provided for @tripConfigCategoriesSelected.
  ///
  /// In de, this message translates to:
  /// **'{selected} von {total} ausgewählt'**
  String tripConfigCategoriesSelected(int selected, int total);

  /// No description provided for @tripConfigCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get tripConfigCategories;

  /// No description provided for @tripConfigSelectedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String tripConfigSelectedCount(int count);

  /// No description provided for @tripConfigPoisAlongRoute.
  ///
  /// In de, this message translates to:
  /// **'POIs entlang der Route'**
  String get tripConfigPoisAlongRoute;

  /// No description provided for @tripConfigActiveTripTitle.
  ///
  /// In de, this message translates to:
  /// **'Aktiver Trip vorhanden'**
  String get tripConfigActiveTripTitle;

  /// No description provided for @tripConfigActiveTripMessage.
  ///
  /// In de, this message translates to:
  /// **'Du hast einen aktiven {days}-Tage-Trip mit {completed} abgeschlossenen Tagen. Ein neuer Trip überschreibt diesen.'**
  String tripConfigActiveTripMessage(int days, int completed);

  /// No description provided for @tripConfigCreateNewTrip.
  ///
  /// In de, this message translates to:
  /// **'Neuen Trip erstellen'**
  String get tripConfigCreateNewTrip;

  /// No description provided for @tripInfoGenerating.
  ///
  /// In de, this message translates to:
  /// **'Trip wird generiert...'**
  String get tripInfoGenerating;

  /// No description provided for @tripInfoLoadingPois.
  ///
  /// In de, this message translates to:
  /// **'POIs laden, Route optimieren'**
  String get tripInfoLoadingPois;

  /// No description provided for @tripInfoAiEuroTrip.
  ///
  /// In de, this message translates to:
  /// **'AI Euro Trip'**
  String get tripInfoAiEuroTrip;

  /// No description provided for @tripInfoAiDayTrip.
  ///
  /// In de, this message translates to:
  /// **'AI Tagestrip'**
  String get tripInfoAiDayTrip;

  /// No description provided for @tripInfoEditTrip.
  ///
  /// In de, this message translates to:
  /// **'Trip bearbeiten'**
  String get tripInfoEditTrip;

  /// No description provided for @tripInfoStartNavigation.
  ///
  /// In de, this message translates to:
  /// **'Navigation starten'**
  String get tripInfoStartNavigation;

  /// No description provided for @tripInfoStops.
  ///
  /// In de, this message translates to:
  /// **'Stops'**
  String get tripInfoStops;

  /// No description provided for @tripInfoDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get tripInfoDistance;

  /// No description provided for @tripInfoDaysLabel.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get tripInfoDaysLabel;

  /// No description provided for @activeTripTitle.
  ///
  /// In de, this message translates to:
  /// **'Aktiver Euro Trip'**
  String get activeTripTitle;

  /// No description provided for @activeTripDiscard.
  ///
  /// In de, this message translates to:
  /// **'Aktiven Trip verwerfen'**
  String get activeTripDiscard;

  /// No description provided for @activeTripDiscardTitle.
  ///
  /// In de, this message translates to:
  /// **'Trip verwerfen?'**
  String get activeTripDiscardTitle;

  /// No description provided for @activeTripDiscardMessage.
  ///
  /// In de, this message translates to:
  /// **'Dein {days}-Tage-Trip mit {completed} abgeschlossenen Tagen wird gelöscht.'**
  String activeTripDiscardMessage(int days, int completed);

  /// No description provided for @activeTripDayPending.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} steht an'**
  String activeTripDayPending(int day);

  /// No description provided for @activeTripDaysCompleted.
  ///
  /// In de, this message translates to:
  /// **'{completed} von {total} Tagen abgeschlossen'**
  String activeTripDaysCompleted(int completed, int total);

  /// No description provided for @tripModeAiDayTrip.
  ///
  /// In de, this message translates to:
  /// **'AI Tagestrip'**
  String get tripModeAiDayTrip;

  /// No description provided for @tripModeAiEuroTrip.
  ///
  /// In de, this message translates to:
  /// **'AI Euro Trip'**
  String get tripModeAiEuroTrip;

  /// No description provided for @tripRoutePlanning.
  ///
  /// In de, this message translates to:
  /// **'Route planen'**
  String get tripRoutePlanning;

  /// No description provided for @tripNoRoute.
  ///
  /// In de, this message translates to:
  /// **'Keine Route vorhanden'**
  String get tripNoRoute;

  /// No description provided for @tripTapMap.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf die Karte, um Start und Ziel festzulegen'**
  String get tripTapMap;

  /// No description provided for @tripToMap.
  ///
  /// In de, this message translates to:
  /// **'Zur Karte'**
  String get tripToMap;

  /// No description provided for @tripGeneratingDescription.
  ///
  /// In de, this message translates to:
  /// **'POIs laden, Route optimieren, Hotels suchen'**
  String get tripGeneratingDescription;

  /// No description provided for @tripElevationLoading.
  ///
  /// In de, this message translates to:
  /// **'Höhenprofil wird geladen...'**
  String get tripElevationLoading;

  /// No description provided for @tripSaveRoute.
  ///
  /// In de, this message translates to:
  /// **'Route speichern'**
  String get tripSaveRoute;

  /// No description provided for @tripRouteName.
  ///
  /// In de, this message translates to:
  /// **'Name der Route'**
  String get tripRouteName;

  /// No description provided for @tripExampleDayTrip.
  ///
  /// In de, this message translates to:
  /// **'z.B. Wochenendausflug'**
  String get tripExampleDayTrip;

  /// No description provided for @tripExampleAiDayTrip.
  ///
  /// In de, this message translates to:
  /// **'z.B. AI Tagesausflug'**
  String get tripExampleAiDayTrip;

  /// No description provided for @tripExampleAiEuroTrip.
  ///
  /// In de, this message translates to:
  /// **'z.B. AI Euro Trip'**
  String get tripExampleAiEuroTrip;

  /// No description provided for @tripRouteSaved.
  ///
  /// In de, this message translates to:
  /// **'Route \"{name}\" gespeichert'**
  String tripRouteSaved(String name);

  /// No description provided for @tripYourRoute.
  ///
  /// In de, this message translates to:
  /// **'Deine Route'**
  String get tripYourRoute;

  /// No description provided for @tripDrivingTime.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeit'**
  String get tripDrivingTime;

  /// No description provided for @tripStopRemoved.
  ///
  /// In de, this message translates to:
  /// **'Stop entfernt'**
  String get tripStopRemoved;

  /// No description provided for @tripOptimizeRoute.
  ///
  /// In de, this message translates to:
  /// **'Route optimieren'**
  String get tripOptimizeRoute;

  /// No description provided for @tripOptimizeBestOrder.
  ///
  /// In de, this message translates to:
  /// **'Beste Reihenfolge berechnen'**
  String get tripOptimizeBestOrder;

  /// No description provided for @tripShareRoute.
  ///
  /// In de, this message translates to:
  /// **'Route teilen'**
  String get tripShareRoute;

  /// No description provided for @tripDeleteAllStops.
  ///
  /// In de, this message translates to:
  /// **'Alle Stops löschen'**
  String get tripDeleteAllStops;

  /// No description provided for @tripDeleteEntireRoute.
  ///
  /// In de, this message translates to:
  /// **'Gesamte Route löschen'**
  String get tripDeleteEntireRoute;

  /// No description provided for @tripDeleteRouteAndStops.
  ///
  /// In de, this message translates to:
  /// **'Route und alle Stops löschen'**
  String get tripDeleteRouteAndStops;

  /// No description provided for @tripConfirmDeleteAllStops.
  ///
  /// In de, this message translates to:
  /// **'Alle Stops löschen?'**
  String get tripConfirmDeleteAllStops;

  /// No description provided for @tripConfirmDeleteEntireRoute.
  ///
  /// In de, this message translates to:
  /// **'Gesamte Route löschen?'**
  String get tripConfirmDeleteEntireRoute;

  /// No description provided for @tripDeleteEntireRouteMessage.
  ///
  /// In de, this message translates to:
  /// **'Die Route und alle Stops werden gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.'**
  String get tripDeleteEntireRouteMessage;

  /// No description provided for @tripBackToConfig.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Konfiguration'**
  String get tripBackToConfig;

  /// No description provided for @tripExportDay.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} in Google Maps'**
  String tripExportDay(int day);

  /// No description provided for @tripReExportDay.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} erneut exportieren'**
  String tripReExportDay(int day);

  /// No description provided for @tripGoogleMapsHint.
  ///
  /// In de, this message translates to:
  /// **'Google Maps berechnet eine eigene Route durch die Stops'**
  String get tripGoogleMapsHint;

  /// No description provided for @tripNoStopsForDay.
  ///
  /// In de, this message translates to:
  /// **'Keine Stops für Tag {day}'**
  String tripNoStopsForDay(int day);

  /// No description provided for @tripCompleted.
  ///
  /// In de, this message translates to:
  /// **'Trip abgeschlossen!'**
  String get tripCompleted;

  /// No description provided for @tripAllDaysExported.
  ///
  /// In de, this message translates to:
  /// **'Alle {days} Tage wurden erfolgreich exportiert. Möchtest du den Trip in deinen Favoriten speichern?'**
  String tripAllDaysExported(int days);

  /// No description provided for @tripKeep.
  ///
  /// In de, this message translates to:
  /// **'Behalten'**
  String get tripKeep;

  /// No description provided for @tripSaveToFavorites.
  ///
  /// In de, this message translates to:
  /// **'In Favoriten speichern'**
  String get tripSaveToFavorites;

  /// No description provided for @tripShareHeader.
  ///
  /// In de, this message translates to:
  /// **'Meine Route mit MapAB'**
  String get tripShareHeader;

  /// No description provided for @tripShareStart.
  ///
  /// In de, this message translates to:
  /// **'Start: {address}'**
  String tripShareStart(String address);

  /// No description provided for @tripShareEnd.
  ///
  /// In de, this message translates to:
  /// **'Ziel: {address}'**
  String tripShareEnd(String address);

  /// No description provided for @tripShareDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz: {distance} km'**
  String tripShareDistance(String distance);

  /// No description provided for @tripShareDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer: {duration} Min'**
  String tripShareDuration(String duration);

  /// No description provided for @tripShareStops.
  ///
  /// In de, this message translates to:
  /// **'Stops:'**
  String get tripShareStops;

  /// No description provided for @tripShareOpenMaps.
  ///
  /// In de, this message translates to:
  /// **'In Google Maps öffnen:'**
  String get tripShareOpenMaps;

  /// No description provided for @tripMyRoute.
  ///
  /// In de, this message translates to:
  /// **'Meine Route'**
  String get tripMyRoute;

  /// No description provided for @tripGoogleMaps.
  ///
  /// In de, this message translates to:
  /// **'Google Maps'**
  String get tripGoogleMaps;

  /// No description provided for @tripShowInFavorites.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get tripShowInFavorites;

  /// No description provided for @tripGoogleMapsError.
  ///
  /// In de, this message translates to:
  /// **'Google Maps konnte nicht geöffnet werden'**
  String get tripGoogleMapsError;

  /// No description provided for @tripShareError.
  ///
  /// In de, this message translates to:
  /// **'Route konnte nicht geteilt werden'**
  String get tripShareError;

  /// No description provided for @tripWeatherDangerHint.
  ///
  /// In de, this message translates to:
  /// **'Unwetter erwartet – Indoor-Stops bevorzugen'**
  String get tripWeatherDangerHint;

  /// No description provided for @tripWeatherBadHint.
  ///
  /// In de, this message translates to:
  /// **'Regen erwartet – Indoor-Stops hervorgehoben'**
  String get tripWeatherBadHint;

  /// No description provided for @tripStart.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get tripStart;

  /// No description provided for @tripDestination.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get tripDestination;

  /// No description provided for @tripNew.
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get tripNew;

  /// No description provided for @dayEditorTitle.
  ///
  /// In de, this message translates to:
  /// **'Trip bearbeiten'**
  String get dayEditorTitle;

  /// No description provided for @dayEditorNoTrip.
  ///
  /// In de, this message translates to:
  /// **'Kein Trip vorhanden'**
  String get dayEditorNoTrip;

  /// No description provided for @dayEditorStartNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt nicht verfügbar'**
  String get dayEditorStartNotAvailable;

  /// No description provided for @dayEditorEditDay.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} bearbeiten'**
  String dayEditorEditDay(int day);

  /// No description provided for @dayEditorRegenerate.
  ///
  /// In de, this message translates to:
  /// **'Neu generieren'**
  String get dayEditorRegenerate;

  /// No description provided for @dayEditorMaxStops.
  ///
  /// In de, this message translates to:
  /// **'Max {max} Stops pro Tag in Google Maps möglich'**
  String dayEditorMaxStops(int max);

  /// No description provided for @dayEditorSearchRecommendations.
  ///
  /// In de, this message translates to:
  /// **'Suche POI-Empfehlungen...'**
  String get dayEditorSearchRecommendations;

  /// No description provided for @dayEditorLoadRecommendations.
  ///
  /// In de, this message translates to:
  /// **'POI-Empfehlungen laden'**
  String get dayEditorLoadRecommendations;

  /// No description provided for @dayEditorAiRecommendations.
  ///
  /// In de, this message translates to:
  /// **'AI-Empfehlungen'**
  String get dayEditorAiRecommendations;

  /// No description provided for @dayEditorRecommended.
  ///
  /// In de, this message translates to:
  /// **'Empfohlen'**
  String get dayEditorRecommended;

  /// No description provided for @dayEditorAddedToDay.
  ///
  /// In de, this message translates to:
  /// **'zu Tag {day} hinzugefügt'**
  String dayEditorAddedToDay(int day);

  /// No description provided for @dayEditorAllDaysExported.
  ///
  /// In de, this message translates to:
  /// **'Alle Tage wurden erfolgreich in Google Maps exportiert. Gute Reise!'**
  String get dayEditorAllDaysExported;

  /// No description provided for @dayEditorAddPois.
  ///
  /// In de, this message translates to:
  /// **'POIs hinzufügen'**
  String get dayEditorAddPois;

  /// No description provided for @dayEditorMyRouteDay.
  ///
  /// In de, this message translates to:
  /// **'Meine Route - Tag {day} mit MapAB'**
  String dayEditorMyRouteDay(int day);

  /// No description provided for @dayEditorMapabRouteDay.
  ///
  /// In de, this message translates to:
  /// **'MapAB Route - Tag {day}'**
  String dayEditorMapabRouteDay(int day);

  /// No description provided for @dayEditorSwapped.
  ///
  /// In de, this message translates to:
  /// **'\"{name}\" eingetauscht'**
  String dayEditorSwapped(String name);

  /// No description provided for @corridorTitle.
  ///
  /// In de, this message translates to:
  /// **'POIs entlang der Route'**
  String get corridorTitle;

  /// No description provided for @corridorFound.
  ///
  /// In de, this message translates to:
  /// **'{total} gefunden'**
  String corridorFound(int total);

  /// No description provided for @corridorFoundWithNew.
  ///
  /// In de, this message translates to:
  /// **'{total} gefunden ({newCount} neu)'**
  String corridorFoundWithNew(int total, int newCount);

  /// No description provided for @corridorWidth.
  ///
  /// In de, this message translates to:
  /// **'Korridor: {km} km'**
  String corridorWidth(int km);

  /// No description provided for @corridorSearching.
  ///
  /// In de, this message translates to:
  /// **'Suche POIs im Korridor...'**
  String get corridorSearching;

  /// No description provided for @corridorNoPoiInCategory.
  ///
  /// In de, this message translates to:
  /// **'Keine POIs in dieser Kategorie gefunden'**
  String get corridorNoPoiInCategory;

  /// No description provided for @corridorNoPois.
  ///
  /// In de, this message translates to:
  /// **'Keine POIs im Korridor gefunden'**
  String get corridorNoPois;

  /// No description provided for @corridorTryWider.
  ///
  /// In de, this message translates to:
  /// **'Versuche einen breiteren Korridor'**
  String get corridorTryWider;

  /// No description provided for @corridorRemoveStop.
  ///
  /// In de, this message translates to:
  /// **'Stop entfernen?'**
  String get corridorRemoveStop;

  /// No description provided for @corridorMinOneStop.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 1 Stop pro Tag erforderlich'**
  String get corridorMinOneStop;

  /// No description provided for @corridorPoiRemoved.
  ///
  /// In de, this message translates to:
  /// **'\"{name}\" entfernt'**
  String corridorPoiRemoved(String name);

  /// No description provided for @navEndConfirm.
  ///
  /// In de, this message translates to:
  /// **'Navigation beenden?'**
  String get navEndConfirm;

  /// No description provided for @navDestinationReached.
  ///
  /// In de, this message translates to:
  /// **'Ziel erreicht!'**
  String get navDestinationReached;

  /// No description provided for @navDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get navDistance;

  /// No description provided for @navArrival.
  ///
  /// In de, this message translates to:
  /// **'Ankunft'**
  String get navArrival;

  /// No description provided for @navSpeed.
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get navSpeed;

  /// No description provided for @navMuteOn.
  ///
  /// In de, this message translates to:
  /// **'Ton an'**
  String get navMuteOn;

  /// No description provided for @navMuteOff.
  ///
  /// In de, this message translates to:
  /// **'Ton aus'**
  String get navMuteOff;

  /// No description provided for @navOverview.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get navOverview;

  /// No description provided for @navEnd.
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get navEnd;

  /// No description provided for @navVoice.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get navVoice;

  /// No description provided for @navVoiceListening.
  ///
  /// In de, this message translates to:
  /// **'Hört...'**
  String get navVoiceListening;

  /// No description provided for @navStartButton.
  ///
  /// In de, this message translates to:
  /// **'Navigation starten'**
  String get navStartButton;

  /// No description provided for @navRerouting.
  ///
  /// In de, this message translates to:
  /// **'Route wird neu berechnet'**
  String get navRerouting;

  /// No description provided for @navVisited.
  ///
  /// In de, this message translates to:
  /// **'Besucht'**
  String get navVisited;

  /// No description provided for @navDistanceMeters.
  ///
  /// In de, this message translates to:
  /// **'{distance} m entfernt'**
  String navDistanceMeters(String distance);

  /// No description provided for @navDistanceKm.
  ///
  /// In de, this message translates to:
  /// **'{distance} km entfernt'**
  String navDistanceKm(String distance);

  /// No description provided for @navDepart.
  ///
  /// In de, this message translates to:
  /// **'Fahre los'**
  String get navDepart;

  /// No description provided for @navDepartOn.
  ///
  /// In de, this message translates to:
  /// **'Fahre los auf {street}'**
  String navDepartOn(String street);

  /// No description provided for @navArrive.
  ///
  /// In de, this message translates to:
  /// **'Sie haben Ihr Ziel erreicht'**
  String get navArrive;

  /// No description provided for @navArriveAt.
  ///
  /// In de, this message translates to:
  /// **'Ziel erreicht: {street}'**
  String navArriveAt(String street);

  /// No description provided for @navContinueOn.
  ///
  /// In de, this message translates to:
  /// **'Weiter auf {street}'**
  String navContinueOn(String street);

  /// No description provided for @navContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiterfahren'**
  String get navContinue;

  /// No description provided for @navTurnRight.
  ///
  /// In de, this message translates to:
  /// **'Rechts abbiegen'**
  String get navTurnRight;

  /// No description provided for @navTurnLeft.
  ///
  /// In de, this message translates to:
  /// **'Links abbiegen'**
  String get navTurnLeft;

  /// No description provided for @navTurnRightOn.
  ///
  /// In de, this message translates to:
  /// **'Rechts abbiegen auf {street}'**
  String navTurnRightOn(String street);

  /// No description provided for @navTurnLeftOn.
  ///
  /// In de, this message translates to:
  /// **'Links abbiegen auf {street}'**
  String navTurnLeftOn(String street);

  /// No description provided for @navSlightRight.
  ///
  /// In de, this message translates to:
  /// **'Leicht rechts abbiegen'**
  String get navSlightRight;

  /// No description provided for @navSlightLeft.
  ///
  /// In de, this message translates to:
  /// **'Leicht links abbiegen'**
  String get navSlightLeft;

  /// No description provided for @navSlightRightOn.
  ///
  /// In de, this message translates to:
  /// **'Leicht rechts auf {street}'**
  String navSlightRightOn(String street);

  /// No description provided for @navSlightLeftOn.
  ///
  /// In de, this message translates to:
  /// **'Leicht links auf {street}'**
  String navSlightLeftOn(String street);

  /// No description provided for @navSharpRight.
  ///
  /// In de, this message translates to:
  /// **'Scharf rechts abbiegen'**
  String get navSharpRight;

  /// No description provided for @navSharpLeft.
  ///
  /// In de, this message translates to:
  /// **'Scharf links abbiegen'**
  String get navSharpLeft;

  /// No description provided for @navUturn.
  ///
  /// In de, this message translates to:
  /// **'Wenden'**
  String get navUturn;

  /// No description provided for @navStraight.
  ///
  /// In de, this message translates to:
  /// **'Geradeaus weiter'**
  String get navStraight;

  /// No description provided for @navStraightOn.
  ///
  /// In de, this message translates to:
  /// **'Geradeaus auf {street}'**
  String navStraightOn(String street);

  /// No description provided for @navMerge.
  ///
  /// In de, this message translates to:
  /// **'Einfädeln'**
  String get navMerge;

  /// No description provided for @navMergeOn.
  ///
  /// In de, this message translates to:
  /// **'Einfädeln auf {street}'**
  String navMergeOn(String street);

  /// No description provided for @navOnRamp.
  ///
  /// In de, this message translates to:
  /// **'Auffahrt nehmen'**
  String get navOnRamp;

  /// No description provided for @navOnRampOn.
  ///
  /// In de, this message translates to:
  /// **'Auffahrt auf {street}'**
  String navOnRampOn(String street);

  /// No description provided for @navOffRamp.
  ///
  /// In de, this message translates to:
  /// **'Abfahrt nehmen'**
  String get navOffRamp;

  /// No description provided for @navOffRampOn.
  ///
  /// In de, this message translates to:
  /// **'Abfahrt {street}'**
  String navOffRampOn(String street);

  /// No description provided for @navRoundaboutExit.
  ///
  /// In de, this message translates to:
  /// **'Im Kreisverkehr die {ordinal} Ausfahrt nehmen'**
  String navRoundaboutExit(String ordinal);

  /// No description provided for @navRoundaboutExitOn.
  ///
  /// In de, this message translates to:
  /// **'Im Kreisverkehr die {ordinal} Ausfahrt nehmen auf {street}'**
  String navRoundaboutExitOn(String ordinal, String street);

  /// No description provided for @navRoundaboutEnter.
  ///
  /// In de, this message translates to:
  /// **'In den Kreisverkehr einfahren'**
  String get navRoundaboutEnter;

  /// No description provided for @navRoundaboutLeave.
  ///
  /// In de, this message translates to:
  /// **'Kreisverkehr verlassen'**
  String get navRoundaboutLeave;

  /// No description provided for @navForkLeft.
  ///
  /// In de, this message translates to:
  /// **'An der Gabelung links halten'**
  String get navForkLeft;

  /// No description provided for @navForkRight.
  ///
  /// In de, this message translates to:
  /// **'An der Gabelung rechts halten'**
  String get navForkRight;

  /// No description provided for @navForkLeftOn.
  ///
  /// In de, this message translates to:
  /// **'An der Gabelung links auf {street}'**
  String navForkLeftOn(String street);

  /// No description provided for @navForkRightOn.
  ///
  /// In de, this message translates to:
  /// **'An der Gabelung rechts auf {street}'**
  String navForkRightOn(String street);

  /// No description provided for @navEndOfRoadLeft.
  ///
  /// In de, this message translates to:
  /// **'Am Straßenende links abbiegen'**
  String get navEndOfRoadLeft;

  /// No description provided for @navEndOfRoadRight.
  ///
  /// In de, this message translates to:
  /// **'Am Straßenende rechts abbiegen'**
  String get navEndOfRoadRight;

  /// No description provided for @navEndOfRoadLeftOn.
  ///
  /// In de, this message translates to:
  /// **'Am Straßenende links auf {street}'**
  String navEndOfRoadLeftOn(String street);

  /// No description provided for @navEndOfRoadRightOn.
  ///
  /// In de, this message translates to:
  /// **'Am Straßenende rechts auf {street}'**
  String navEndOfRoadRightOn(String street);

  /// No description provided for @navInDistance.
  ///
  /// In de, this message translates to:
  /// **'In {distance} {instruction}'**
  String navInDistance(String distance, String instruction);

  /// No description provided for @navNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt {instruction}'**
  String navNow(String instruction);

  /// No description provided for @navMeters.
  ///
  /// In de, this message translates to:
  /// **'{value} Metern'**
  String navMeters(String value);

  /// No description provided for @navKilometers.
  ///
  /// In de, this message translates to:
  /// **'{value} Kilometern'**
  String navKilometers(String value);

  /// No description provided for @navOrdinalFirst.
  ///
  /// In de, this message translates to:
  /// **'erste'**
  String get navOrdinalFirst;

  /// No description provided for @navOrdinalSecond.
  ///
  /// In de, this message translates to:
  /// **'zweite'**
  String get navOrdinalSecond;

  /// No description provided for @navOrdinalThird.
  ///
  /// In de, this message translates to:
  /// **'dritte'**
  String get navOrdinalThird;

  /// No description provided for @navOrdinalFourth.
  ///
  /// In de, this message translates to:
  /// **'vierte'**
  String get navOrdinalFourth;

  /// No description provided for @navOrdinalFifth.
  ///
  /// In de, this message translates to:
  /// **'fünfte'**
  String get navOrdinalFifth;

  /// No description provided for @navOrdinalSixth.
  ///
  /// In de, this message translates to:
  /// **'sechste'**
  String get navOrdinalSixth;

  /// No description provided for @navOrdinalSeventh.
  ///
  /// In de, this message translates to:
  /// **'siebte'**
  String get navOrdinalSeventh;

  /// No description provided for @navOrdinalEighth.
  ///
  /// In de, this message translates to:
  /// **'achte'**
  String get navOrdinalEighth;

  /// No description provided for @navSharpRightOn.
  ///
  /// In de, this message translates to:
  /// **'Scharf rechts abbiegen auf {street}'**
  String navSharpRightOn(String street);

  /// No description provided for @navSharpLeftOn.
  ///
  /// In de, this message translates to:
  /// **'Scharf links abbiegen auf {street}'**
  String navSharpLeftOn(String street);

  /// No description provided for @navUturnOn.
  ///
  /// In de, this message translates to:
  /// **'Wenden auf {street}'**
  String navUturnOn(String street);

  /// No description provided for @navTurn.
  ///
  /// In de, this message translates to:
  /// **'Abbiegen'**
  String get navTurn;

  /// No description provided for @navTurnOn.
  ///
  /// In de, this message translates to:
  /// **'Abbiegen auf {street}'**
  String navTurnOn(String street);

  /// No description provided for @navForkStraight.
  ///
  /// In de, this message translates to:
  /// **'An der Gabelung weiterfahren'**
  String get navForkStraight;

  /// No description provided for @navForkStraightOn.
  ///
  /// In de, this message translates to:
  /// **'An der Gabelung weiterfahren auf {street}'**
  String navForkStraightOn(String street);

  /// No description provided for @navEndOfRoadStraight.
  ///
  /// In de, this message translates to:
  /// **'Am Straßenende weiterfahren'**
  String get navEndOfRoadStraight;

  /// No description provided for @navEndOfRoadStraightOn.
  ///
  /// In de, this message translates to:
  /// **'Am Straßenende weiterfahren auf {street}'**
  String navEndOfRoadStraightOn(String street);

  /// No description provided for @navRoundaboutLeaveOn.
  ///
  /// In de, this message translates to:
  /// **'Kreisverkehr verlassen auf {street}'**
  String navRoundaboutLeaveOn(String street);

  /// No description provided for @navRoundaboutEnterOn.
  ///
  /// In de, this message translates to:
  /// **'In den Kreisverkehr einfahren auf {street}'**
  String navRoundaboutEnterOn(String street);

  /// No description provided for @navStraightContinue.
  ///
  /// In de, this message translates to:
  /// **'Geradeaus weiterfahren'**
  String get navStraightContinue;

  /// No description provided for @navDirectionLeft.
  ///
  /// In de, this message translates to:
  /// **'Links '**
  String get navDirectionLeft;

  /// No description provided for @navDirectionRight.
  ///
  /// In de, this message translates to:
  /// **'Rechts '**
  String get navDirectionRight;

  /// No description provided for @navSharpRightShort.
  ///
  /// In de, this message translates to:
  /// **'Scharf rechts'**
  String get navSharpRightShort;

  /// No description provided for @navRightShort.
  ///
  /// In de, this message translates to:
  /// **'Rechts'**
  String get navRightShort;

  /// No description provided for @navSlightRightShort.
  ///
  /// In de, this message translates to:
  /// **'Leicht rechts'**
  String get navSlightRightShort;

  /// No description provided for @navStraightShort.
  ///
  /// In de, this message translates to:
  /// **'Geradeaus'**
  String get navStraightShort;

  /// No description provided for @navSlightLeftShort.
  ///
  /// In de, this message translates to:
  /// **'Leicht links'**
  String get navSlightLeftShort;

  /// No description provided for @navLeftShort.
  ///
  /// In de, this message translates to:
  /// **'Links'**
  String get navLeftShort;

  /// No description provided for @navSharpLeftShort.
  ///
  /// In de, this message translates to:
  /// **'Scharf links'**
  String get navSharpLeftShort;

  /// No description provided for @navKeepLeft.
  ///
  /// In de, this message translates to:
  /// **'Links halten'**
  String get navKeepLeft;

  /// No description provided for @navKeepRight.
  ///
  /// In de, this message translates to:
  /// **'Rechts halten'**
  String get navKeepRight;

  /// No description provided for @navRoundabout.
  ///
  /// In de, this message translates to:
  /// **'Kreisverkehr'**
  String get navRoundabout;

  /// No description provided for @navExitShort.
  ///
  /// In de, this message translates to:
  /// **'{ordinal} Ausfahrt'**
  String navExitShort(String ordinal);

  /// No description provided for @navMustSeeStop.
  ///
  /// In de, this message translates to:
  /// **'Halt'**
  String get navMustSeeStop;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get settingsAppearance;

  /// No description provided for @settingsDesign.
  ///
  /// In de, this message translates to:
  /// **'Design'**
  String get settingsDesign;

  /// No description provided for @settingsAutoDarkMode.
  ///
  /// In de, this message translates to:
  /// **'Auto Dark Mode'**
  String get settingsAutoDarkMode;

  /// No description provided for @settingsAutoDarkModeDesc.
  ///
  /// In de, this message translates to:
  /// **'Automatisch bei Sonnenuntergang aktivieren'**
  String get settingsAutoDarkModeDesc;

  /// No description provided for @settingsFeedback.
  ///
  /// In de, this message translates to:
  /// **'Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsHaptic.
  ///
  /// In de, this message translates to:
  /// **'Haptisches Feedback'**
  String get settingsHaptic;

  /// No description provided for @settingsHapticDesc.
  ///
  /// In de, this message translates to:
  /// **'Vibrationen bei Interaktionen'**
  String get settingsHapticDesc;

  /// No description provided for @settingsSound.
  ///
  /// In de, this message translates to:
  /// **'Sound-Effekte'**
  String get settingsSound;

  /// No description provided for @settingsSoundDesc.
  ///
  /// In de, this message translates to:
  /// **'Töne bei Aktionen'**
  String get settingsSoundDesc;

  /// No description provided for @settingsAbout.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get settingsAbout;

  /// No description provided for @settingsAppVersion.
  ///
  /// In de, this message translates to:
  /// **'App-Version'**
  String get settingsAppVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In de, this message translates to:
  /// **'Open Source Lizenzen'**
  String get settingsLicenses;

  /// No description provided for @settingsLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeOled.
  ///
  /// In de, this message translates to:
  /// **'OLED Schwarz'**
  String get settingsThemeOled;

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get profileEdit;

  /// No description provided for @profileCloudAccount.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Account'**
  String get profileCloudAccount;

  /// No description provided for @profileAutoSync.
  ///
  /// In de, this message translates to:
  /// **'Daten werden automatisch synchronisiert'**
  String get profileAutoSync;

  /// No description provided for @profileGuestAccount.
  ///
  /// In de, this message translates to:
  /// **'Gast-Account'**
  String get profileGuestAccount;

  /// No description provided for @profileLocalStorage.
  ///
  /// In de, this message translates to:
  /// **'Lokal gespeichert'**
  String get profileLocalStorage;

  /// No description provided for @profileUpgradeToCloud.
  ///
  /// In de, this message translates to:
  /// **'Zu Cloud-Account upgraden'**
  String get profileUpgradeToCloud;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Account löschen'**
  String get profileDeleteAccount;

  /// No description provided for @profileNoAccount.
  ///
  /// In de, this message translates to:
  /// **'Kein Account'**
  String get profileNoAccount;

  /// No description provided for @profileLoginPrompt.
  ///
  /// In de, this message translates to:
  /// **'Melde dich an, um dein Profil zu sehen'**
  String get profileLoginPrompt;

  /// No description provided for @profileLogin.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get profileLogin;

  /// No description provided for @profileLevel.
  ///
  /// In de, this message translates to:
  /// **'Level {level}'**
  String profileLevel(int level);

  /// No description provided for @profileXpProgress.
  ///
  /// In de, this message translates to:
  /// **'Noch {xp} XP bis Level {level}'**
  String profileXpProgress(int xp, int level);

  /// No description provided for @profileStatistics.
  ///
  /// In de, this message translates to:
  /// **'Statistiken'**
  String get profileStatistics;

  /// No description provided for @profileStatisticsLoading.
  ///
  /// In de, this message translates to:
  /// **'Statistiken werden geladen...'**
  String get profileStatisticsLoading;

  /// No description provided for @profileStartFirstTrip.
  ///
  /// In de, this message translates to:
  /// **'Starte deinen ersten Trip, um Statistiken zu sehen!'**
  String get profileStartFirstTrip;

  /// No description provided for @profileTrips.
  ///
  /// In de, this message translates to:
  /// **'Trips'**
  String get profileTrips;

  /// No description provided for @profilePois.
  ///
  /// In de, this message translates to:
  /// **'POIs'**
  String get profilePois;

  /// No description provided for @profileKilometers.
  ///
  /// In de, this message translates to:
  /// **'Kilometer'**
  String get profileKilometers;

  /// No description provided for @profileAchievements.
  ///
  /// In de, this message translates to:
  /// **'Achievements'**
  String get profileAchievements;

  /// No description provided for @profileNoAchievements.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Achievements freigeschaltet. Starte deinen ersten Trip!'**
  String get profileNoAchievements;

  /// No description provided for @profileAccountId.
  ///
  /// In de, this message translates to:
  /// **'Account-ID: {id}'**
  String profileAccountId(String id);

  /// No description provided for @profileCreatedAt.
  ///
  /// In de, this message translates to:
  /// **'Erstellt am: {date}'**
  String profileCreatedAt(String date);

  /// No description provided for @profileLastLogin.
  ///
  /// In de, this message translates to:
  /// **'Letzter Login: {date}'**
  String profileLastLogin(String date);

  /// No description provided for @profileEditComingSoon.
  ///
  /// In de, this message translates to:
  /// **'Profil-Bearbeitung kommt bald!'**
  String get profileEditComingSoon;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausloggen?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutMessage.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du dich wirklich ausloggen?'**
  String get profileLogoutMessage;

  /// No description provided for @profileLogoutCloudMessage.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du dich wirklich ausloggen?\n\nDeine Cloud-Daten bleiben erhalten und du kannst dich jederzeit wieder anmelden.'**
  String get profileLogoutCloudMessage;

  /// No description provided for @profileLogout.
  ///
  /// In de, this message translates to:
  /// **'Ausloggen'**
  String get profileLogout;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Account löschen?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteMessage.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du deinen Account wirklich löschen? Alle Daten werden unwiderruflich gelöscht!'**
  String get profileDeleteMessage;

  /// No description provided for @favTitle.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get favTitle;

  /// No description provided for @favRoutes.
  ///
  /// In de, this message translates to:
  /// **'Routen'**
  String get favRoutes;

  /// No description provided for @favPois.
  ///
  /// In de, this message translates to:
  /// **'POIs'**
  String get favPois;

  /// No description provided for @favDeleteAll.
  ///
  /// In de, this message translates to:
  /// **'Alle löschen'**
  String get favDeleteAll;

  /// No description provided for @favNoFavorites.
  ///
  /// In de, this message translates to:
  /// **'Keine Favoriten'**
  String get favNoFavorites;

  /// No description provided for @favNoFavoritesDesc.
  ///
  /// In de, this message translates to:
  /// **'Speichere Routen und POIs für schnellen Zugriff'**
  String get favNoFavoritesDesc;

  /// No description provided for @favExplore.
  ///
  /// In de, this message translates to:
  /// **'Entdecken'**
  String get favExplore;

  /// No description provided for @favNoRoutes.
  ///
  /// In de, this message translates to:
  /// **'Keine gespeicherten Routen'**
  String get favNoRoutes;

  /// No description provided for @favPlanRoute.
  ///
  /// In de, this message translates to:
  /// **'Route planen'**
  String get favPlanRoute;

  /// No description provided for @favNoPois.
  ///
  /// In de, this message translates to:
  /// **'Keine favorisierten POIs'**
  String get favNoPois;

  /// No description provided for @favDiscoverPois.
  ///
  /// In de, this message translates to:
  /// **'POIs entdecken'**
  String get favDiscoverPois;

  /// No description provided for @favRemoveRoute.
  ///
  /// In de, this message translates to:
  /// **'Route entfernen?'**
  String get favRemoveRoute;

  /// No description provided for @favRemoveRouteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du \"{name}\" aus den Favoriten entfernen?'**
  String favRemoveRouteConfirm(String name);

  /// No description provided for @favRemovePoi.
  ///
  /// In de, this message translates to:
  /// **'POI entfernen?'**
  String get favRemovePoi;

  /// No description provided for @favRemovePoiConfirm.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du \"{name}\" aus den Favoriten entfernen?'**
  String favRemovePoiConfirm(String name);

  /// No description provided for @favRouteLoaded.
  ///
  /// In de, this message translates to:
  /// **'Route geladen'**
  String get favRouteLoaded;

  /// No description provided for @favRouteRemoved.
  ///
  /// In de, this message translates to:
  /// **'Route entfernt'**
  String get favRouteRemoved;

  /// No description provided for @favPoiRemoved.
  ///
  /// In de, this message translates to:
  /// **'POI entfernt'**
  String get favPoiRemoved;

  /// No description provided for @favClearAll.
  ///
  /// In de, this message translates to:
  /// **'Alle Favoriten löschen?'**
  String get favClearAll;

  /// No description provided for @favAllDeleted.
  ///
  /// In de, this message translates to:
  /// **'Alle Favoriten gelöscht'**
  String get favAllDeleted;

  /// No description provided for @poiSearchHint.
  ///
  /// In de, this message translates to:
  /// **'POIs durchsuchen...'**
  String get poiSearchHint;

  /// No description provided for @poiClearFilters.
  ///
  /// In de, this message translates to:
  /// **'Filter löschen'**
  String get poiClearFilters;

  /// No description provided for @poiResetFilters.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get poiResetFilters;

  /// No description provided for @poiLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade Sehenswürdigkeiten...'**
  String get poiLoading;

  /// No description provided for @poiNotFound.
  ///
  /// In de, this message translates to:
  /// **'POI nicht gefunden'**
  String get poiNotFound;

  /// No description provided for @poiLoadingDetails.
  ///
  /// In de, this message translates to:
  /// **'Lade Details...'**
  String get poiLoadingDetails;

  /// No description provided for @poiMoreOnWikipedia.
  ///
  /// In de, this message translates to:
  /// **'Mehr auf Wikipedia'**
  String get poiMoreOnWikipedia;

  /// No description provided for @poiOpeningHours.
  ///
  /// In de, this message translates to:
  /// **'Öffnungszeiten'**
  String get poiOpeningHours;

  /// No description provided for @poiRouteCreated.
  ///
  /// In de, this message translates to:
  /// **'Route zu \"{name}\" erstellt'**
  String poiRouteCreated(String name);

  /// No description provided for @poiOnlyMustSee.
  ///
  /// In de, this message translates to:
  /// **'Nur Must-See'**
  String get poiOnlyMustSee;

  /// No description provided for @poiShowOnlyHighlights.
  ///
  /// In de, this message translates to:
  /// **'Zeige nur Highlights'**
  String get poiShowOnlyHighlights;

  /// No description provided for @poiOnlyIndoor.
  ///
  /// In de, this message translates to:
  /// **'Nur Indoor-POIs'**
  String get poiOnlyIndoor;

  /// No description provided for @poiApplyFilters.
  ///
  /// In de, this message translates to:
  /// **'Filter anwenden'**
  String get poiApplyFilters;

  /// No description provided for @poiReroll.
  ///
  /// In de, this message translates to:
  /// **'Neu würfeln'**
  String get poiReroll;

  /// No description provided for @poiTitle.
  ///
  /// In de, this message translates to:
  /// **'Sehenswürdigkeiten'**
  String get poiTitle;

  /// No description provided for @poiMustSee.
  ///
  /// In de, this message translates to:
  /// **'Must-See'**
  String get poiMustSee;

  /// No description provided for @poiWeatherTip.
  ///
  /// In de, this message translates to:
  /// **'Wetter-Tipp'**
  String get poiWeatherTip;

  /// No description provided for @poiResultsCount.
  ///
  /// In de, this message translates to:
  /// **'{filtered} von {total} POIs'**
  String poiResultsCount(int filtered, int total);

  /// No description provided for @poiNoResultsFilter.
  ///
  /// In de, this message translates to:
  /// **'Keine POIs mit diesen Filtern gefunden'**
  String get poiNoResultsFilter;

  /// No description provided for @poiNoResultsNearby.
  ///
  /// In de, this message translates to:
  /// **'Keine POIs in der Nähe gefunden'**
  String get poiNoResultsNearby;

  /// No description provided for @poiGpsPermissionNeeded.
  ///
  /// In de, this message translates to:
  /// **'GPS-Berechtigung wird benötigt um POIs in der Nähe zu finden'**
  String get poiGpsPermissionNeeded;

  /// No description provided for @poiWeatherDangerBanner.
  ///
  /// In de, this message translates to:
  /// **'Unwetter erwartet – Indoor-POIs empfohlen'**
  String get poiWeatherDangerBanner;

  /// No description provided for @poiWeatherBadBanner.
  ///
  /// In de, this message translates to:
  /// **'Regen erwartet – aktiviere \"Wetter-Tipp\" für bessere Sortierung'**
  String get poiWeatherBadBanner;

  /// No description provided for @poiAboutPlace.
  ///
  /// In de, this message translates to:
  /// **'Über diesen Ort'**
  String get poiAboutPlace;

  /// No description provided for @poiNoDescription.
  ///
  /// In de, this message translates to:
  /// **'Keine Beschreibung verfügbar.'**
  String get poiNoDescription;

  /// No description provided for @poiDescriptionLoading.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung wird geladen...'**
  String get poiDescriptionLoading;

  /// No description provided for @poiContactInfo.
  ///
  /// In de, this message translates to:
  /// **'Kontakt & Info'**
  String get poiContactInfo;

  /// No description provided for @poiPhone.
  ///
  /// In de, this message translates to:
  /// **'Telefon'**
  String get poiPhone;

  /// No description provided for @poiWebsite.
  ///
  /// In de, this message translates to:
  /// **'Website'**
  String get poiWebsite;

  /// No description provided for @poiEmailLabel.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get poiEmailLabel;

  /// No description provided for @poiDetour.
  ///
  /// In de, this message translates to:
  /// **'Umweg'**
  String get poiDetour;

  /// No description provided for @poiTime.
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get poiTime;

  /// No description provided for @poiPosition.
  ///
  /// In de, this message translates to:
  /// **'Position'**
  String get poiPosition;

  /// No description provided for @poiCurated.
  ///
  /// In de, this message translates to:
  /// **'Kuratiert'**
  String get poiCurated;

  /// No description provided for @poiVerified.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert'**
  String get poiVerified;

  /// No description provided for @poiAddedToRoute.
  ///
  /// In de, this message translates to:
  /// **'{name} zur Route hinzugefügt'**
  String poiAddedToRoute(String name);

  /// No description provided for @poiFoundedYear.
  ///
  /// In de, this message translates to:
  /// **'Gegründet {year}'**
  String poiFoundedYear(int year);

  /// No description provided for @poiRating.
  ///
  /// In de, this message translates to:
  /// **'{rating} von 5 ({count} Bewertungen)'**
  String poiRating(String rating, int count);

  /// No description provided for @poiAddToRoute.
  ///
  /// In de, this message translates to:
  /// **'Zur Route'**
  String get poiAddToRoute;

  /// No description provided for @scanTitle.
  ///
  /// In de, this message translates to:
  /// **'Trip scannen'**
  String get scanTitle;

  /// No description provided for @scanInstruction.
  ///
  /// In de, this message translates to:
  /// **'QR-Code scannen'**
  String get scanInstruction;

  /// No description provided for @scanDescription.
  ///
  /// In de, this message translates to:
  /// **'Halte dein Handy über einen MapAB QR-Code, um einen geteilten Trip zu importieren.'**
  String get scanDescription;

  /// No description provided for @scanLoading.
  ///
  /// In de, this message translates to:
  /// **'Trip wird geladen...'**
  String get scanLoading;

  /// No description provided for @scanInvalidCode.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger QR-Code'**
  String get scanInvalidCode;

  /// No description provided for @scanInvalidMapabCode.
  ///
  /// In de, this message translates to:
  /// **'Kein gültiger MapAB QR-Code'**
  String get scanInvalidMapabCode;

  /// No description provided for @scanLoadError.
  ///
  /// In de, this message translates to:
  /// **'Trip konnte nicht geladen werden'**
  String get scanLoadError;

  /// No description provided for @scanTripFound.
  ///
  /// In de, this message translates to:
  /// **'Trip gefunden!'**
  String get scanTripFound;

  /// No description provided for @scanStops.
  ///
  /// In de, this message translates to:
  /// **'{count} Stopps'**
  String scanStops(int count);

  /// No description provided for @scanDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String scanDays(int count);

  /// No description provided for @scanImportQuestion.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du diesen Trip importieren?'**
  String get scanImportQuestion;

  /// No description provided for @scanImport.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get scanImport;

  /// No description provided for @scanImportSuccess.
  ///
  /// In de, this message translates to:
  /// **'{name} wurde importiert!'**
  String scanImportSuccess(String name);

  /// No description provided for @scanImportError.
  ///
  /// In de, this message translates to:
  /// **'Trip konnte nicht importiert werden'**
  String get scanImportError;

  /// No description provided for @templatesTitle.
  ///
  /// In de, this message translates to:
  /// **'Trip-Vorlagen'**
  String get templatesTitle;

  /// No description provided for @templatesScanQr.
  ///
  /// In de, this message translates to:
  /// **'QR-Code scannen'**
  String get templatesScanQr;

  /// No description provided for @templatesAudienceAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get templatesAudienceAll;

  /// No description provided for @templatesAudienceCouples.
  ///
  /// In de, this message translates to:
  /// **'Paare'**
  String get templatesAudienceCouples;

  /// No description provided for @templatesAudienceFamilies.
  ///
  /// In de, this message translates to:
  /// **'Familien'**
  String get templatesAudienceFamilies;

  /// No description provided for @templatesAudienceAdventurers.
  ///
  /// In de, this message translates to:
  /// **'Abenteurer'**
  String get templatesAudienceAdventurers;

  /// No description provided for @templatesAudienceFoodies.
  ///
  /// In de, this message translates to:
  /// **'Foodies'**
  String get templatesAudienceFoodies;

  /// No description provided for @templatesAudiencePhotographers.
  ///
  /// In de, this message translates to:
  /// **'Fotografen'**
  String get templatesAudiencePhotographers;

  /// No description provided for @templatesDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String templatesDays(int count);

  /// No description provided for @templatesCategories.
  ///
  /// In de, this message translates to:
  /// **'{count} Kategorien'**
  String templatesCategories(int count);

  /// No description provided for @templatesIncludedCategories.
  ///
  /// In de, this message translates to:
  /// **'Enthaltene Kategorien'**
  String get templatesIncludedCategories;

  /// No description provided for @templatesDuration.
  ///
  /// In de, this message translates to:
  /// **'Reisedauer'**
  String get templatesDuration;

  /// No description provided for @templatesRecommended.
  ///
  /// In de, this message translates to:
  /// **'Empfohlen: {days} {daysText}'**
  String templatesRecommended(int days, String daysText);

  /// No description provided for @templatesBestSeason.
  ///
  /// In de, this message translates to:
  /// **'Beste Reisezeit: {season}'**
  String templatesBestSeason(String season);

  /// No description provided for @templatesStartPlanning.
  ///
  /// In de, this message translates to:
  /// **'Trip planen'**
  String get templatesStartPlanning;

  /// No description provided for @seasonSpring.
  ///
  /// In de, this message translates to:
  /// **'Frühling'**
  String get seasonSpring;

  /// No description provided for @seasonSummer.
  ///
  /// In de, this message translates to:
  /// **'Sommer'**
  String get seasonSummer;

  /// No description provided for @seasonAutumn.
  ///
  /// In de, this message translates to:
  /// **'Herbst'**
  String get seasonAutumn;

  /// No description provided for @seasonWinter.
  ///
  /// In de, this message translates to:
  /// **'Winter'**
  String get seasonWinter;

  /// No description provided for @seasonSpringAutumn.
  ///
  /// In de, this message translates to:
  /// **'Frühling bis Herbst'**
  String get seasonSpringAutumn;

  /// No description provided for @seasonYearRound.
  ///
  /// In de, this message translates to:
  /// **'Ganzjährig'**
  String get seasonYearRound;

  /// No description provided for @day.
  ///
  /// In de, this message translates to:
  /// **'Tag'**
  String get day;

  /// No description provided for @days.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get days;

  /// No description provided for @searchSelectStart.
  ///
  /// In de, this message translates to:
  /// **'Start wählen'**
  String get searchSelectStart;

  /// No description provided for @searchSelectDestination.
  ///
  /// In de, this message translates to:
  /// **'Ziel wählen'**
  String get searchSelectDestination;

  /// No description provided for @searchStartHint.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt suchen...'**
  String get searchStartHint;

  /// No description provided for @searchDestinationHint.
  ///
  /// In de, this message translates to:
  /// **'Ziel suchen...'**
  String get searchDestinationHint;

  /// No description provided for @searchOfflineMode.
  ///
  /// In de, this message translates to:
  /// **'Kein Internet - Zeige lokale Vorschläge'**
  String get searchOfflineMode;

  /// No description provided for @searchEnterLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort eingeben zum Suchen'**
  String get searchEnterLocation;

  /// No description provided for @searchNoResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse gefunden'**
  String get searchNoResults;

  /// No description provided for @searchLocationNotFound.
  ///
  /// In de, this message translates to:
  /// **'Standort konnte nicht gefunden werden'**
  String get searchLocationNotFound;

  /// No description provided for @chatTitle.
  ///
  /// In de, this message translates to:
  /// **'AI-Assistent'**
  String get chatTitle;

  /// No description provided for @chatClear.
  ///
  /// In de, this message translates to:
  /// **'Chat leeren'**
  String get chatClear;

  /// No description provided for @chatWelcome.
  ///
  /// In de, this message translates to:
  /// **'Hallo! Ich bin dein AI-Reiseassistent. Wie kann ich dir bei der Planung helfen?'**
  String get chatWelcome;

  /// No description provided for @chatInputHint.
  ///
  /// In de, this message translates to:
  /// **'Nachricht eingeben...'**
  String get chatInputHint;

  /// No description provided for @chatClearConfirm.
  ///
  /// In de, this message translates to:
  /// **'Chat leeren?'**
  String get chatClearConfirm;

  /// No description provided for @chatClearMessage.
  ///
  /// In de, this message translates to:
  /// **'Die gesamte Konversation wird gelöscht.'**
  String get chatClearMessage;

  /// No description provided for @chatCheckAgain.
  ///
  /// In de, this message translates to:
  /// **'Erneut prüfen'**
  String get chatCheckAgain;

  /// No description provided for @chatAccept.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get chatAccept;

  /// No description provided for @chatShowAllPois.
  ///
  /// In de, this message translates to:
  /// **'Alle POIs anzeigen'**
  String chatShowAllPois(int count);

  /// No description provided for @chatDestinationOptional.
  ///
  /// In de, this message translates to:
  /// **'Ziel (optional)'**
  String get chatDestinationOptional;

  /// No description provided for @chatEmptyRandomRoute.
  ///
  /// In de, this message translates to:
  /// **'Leer = Zufällige Route um Startpunkt'**
  String get chatEmptyRandomRoute;

  /// No description provided for @chatStartOptional.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt (optional)'**
  String get chatStartOptional;

  /// No description provided for @chatEmptyUseGps.
  ///
  /// In de, this message translates to:
  /// **'Leer = GPS-Standort verwenden'**
  String get chatEmptyUseGps;

  /// No description provided for @chatIndoorTips.
  ///
  /// In de, this message translates to:
  /// **'Indoor-Tipps bei Regen'**
  String get chatIndoorTips;

  /// No description provided for @chatPoisNearMe.
  ///
  /// In de, this message translates to:
  /// **'POIs in meiner Nähe'**
  String get chatPoisNearMe;

  /// No description provided for @chatAttractions.
  ///
  /// In de, this message translates to:
  /// **'Sehenswürdigkeiten'**
  String get chatAttractions;

  /// No description provided for @chatRestaurants.
  ///
  /// In de, this message translates to:
  /// **'Restaurants'**
  String get chatRestaurants;

  /// No description provided for @chatOutdoorHighlights.
  ///
  /// In de, this message translates to:
  /// **'Outdoor-Highlights'**
  String get chatOutdoorHighlights;

  /// No description provided for @chatNatureParks.
  ///
  /// In de, this message translates to:
  /// **'Natur & Parks'**
  String get chatNatureParks;

  /// No description provided for @chatSearchRadius.
  ///
  /// In de, this message translates to:
  /// **'Such-Radius'**
  String get chatSearchRadius;

  /// No description provided for @chatGenerateAiTrip.
  ///
  /// In de, this message translates to:
  /// **'AI-Trip generieren'**
  String get chatGenerateAiTrip;

  /// No description provided for @randomTripNoTrip.
  ///
  /// In de, this message translates to:
  /// **'Kein Trip generiert'**
  String get randomTripNoTrip;

  /// No description provided for @randomTripRegenerate.
  ///
  /// In de, this message translates to:
  /// **'Neu generieren'**
  String get randomTripRegenerate;

  /// No description provided for @randomTripConfirm.
  ///
  /// In de, this message translates to:
  /// **'Trip bestätigen'**
  String get randomTripConfirm;

  /// No description provided for @randomTripStopsDay.
  ///
  /// In de, this message translates to:
  /// **'Stops (Tag {day})'**
  String randomTripStopsDay(int day);

  /// No description provided for @randomTripStops.
  ///
  /// In de, this message translates to:
  /// **'Stops'**
  String get randomTripStops;

  /// No description provided for @randomTripEnterAddress.
  ///
  /// In de, this message translates to:
  /// **'Stadt oder Adresse eingeben...'**
  String get randomTripEnterAddress;

  /// No description provided for @randomTripShowDetails.
  ///
  /// In de, this message translates to:
  /// **'Details anzeigen'**
  String get randomTripShowDetails;

  /// No description provided for @randomTripOpenGoogleMaps.
  ///
  /// In de, this message translates to:
  /// **'In Google Maps öffnen'**
  String get randomTripOpenGoogleMaps;

  /// No description provided for @randomTripSave.
  ///
  /// In de, this message translates to:
  /// **'Trip speichern'**
  String get randomTripSave;

  /// No description provided for @randomTripShow.
  ///
  /// In de, this message translates to:
  /// **'Trip anzeigen'**
  String get randomTripShow;

  /// No description provided for @randomTripBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get randomTripBack;

  /// No description provided for @mapModeAiDayTrip.
  ///
  /// In de, this message translates to:
  /// **'AI Tagestrip'**
  String get mapModeAiDayTrip;

  /// No description provided for @mapModeAiEuroTrip.
  ///
  /// In de, this message translates to:
  /// **'AI Euro Trip'**
  String get mapModeAiEuroTrip;

  /// No description provided for @travelDuration.
  ///
  /// In de, this message translates to:
  /// **'Reisedauer'**
  String get travelDuration;

  /// No description provided for @radiusLabel.
  ///
  /// In de, this message translates to:
  /// **'Radius'**
  String get radiusLabel;

  /// No description provided for @categoriesLabel.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get categoriesLabel;

  /// No description provided for @tripDescDayTrip.
  ///
  /// In de, this message translates to:
  /// **'Tagesausflug — ca. {radius} km'**
  String tripDescDayTrip(int radius);

  /// No description provided for @tripDescWeekend.
  ///
  /// In de, this message translates to:
  /// **'Wochenend-Trip — ca. {radius} km'**
  String tripDescWeekend(int radius);

  /// No description provided for @tripDescShortVacation.
  ///
  /// In de, this message translates to:
  /// **'Kurzurlaub — ca. {radius} km'**
  String tripDescShortVacation(int radius);

  /// No description provided for @tripDescWeekTrip.
  ///
  /// In de, this message translates to:
  /// **'Wochenreise — ca. {radius} km'**
  String tripDescWeekTrip(int radius);

  /// No description provided for @tripDescEpic.
  ///
  /// In de, this message translates to:
  /// **'Epischer Euro Trip — ca. {radius} km'**
  String tripDescEpic(int radius);

  /// No description provided for @selectedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String selectedCount(int count);

  /// No description provided for @destinationOptional.
  ///
  /// In de, this message translates to:
  /// **'Ziel (optional)'**
  String get destinationOptional;

  /// No description provided for @enterDestination.
  ///
  /// In de, this message translates to:
  /// **'Zielort eingeben...'**
  String get enterDestination;

  /// No description provided for @mapCityOrAddress.
  ///
  /// In de, this message translates to:
  /// **'Stadt oder Adresse...'**
  String get mapCityOrAddress;

  /// No description provided for @mapAddDestination.
  ///
  /// In de, this message translates to:
  /// **'Ziel hinzufügen (optional)'**
  String get mapAddDestination;

  /// No description provided for @mapSurpriseMe.
  ///
  /// In de, this message translates to:
  /// **'Überrasch mich!'**
  String get mapSurpriseMe;

  /// No description provided for @mapDeleteRoute.
  ///
  /// In de, this message translates to:
  /// **'Route löschen'**
  String get mapDeleteRoute;

  /// No description provided for @mapDaysLabel.
  ///
  /// In de, this message translates to:
  /// **'{days} Tage'**
  String mapDaysLabel(String days);

  /// No description provided for @mapPoiCategories.
  ///
  /// In de, this message translates to:
  /// **'POI-Kategorien'**
  String get mapPoiCategories;

  /// No description provided for @mapResetAll.
  ///
  /// In de, this message translates to:
  /// **'Alle zurücksetzen'**
  String get mapResetAll;

  /// No description provided for @mapAllCategoriesSelected.
  ///
  /// In de, this message translates to:
  /// **'Alle Kategorien ausgewählt'**
  String get mapAllCategoriesSelected;

  /// No description provided for @mapCategoriesSelected.
  ///
  /// In de, this message translates to:
  /// **'{count} von {total} ausgewählt'**
  String mapCategoriesSelected(String count, String total);

  /// No description provided for @mapPoisAlongRoute.
  ///
  /// In de, this message translates to:
  /// **'POIs entlang der Route'**
  String get mapPoisAlongRoute;

  /// No description provided for @mapWithoutDestination.
  ///
  /// In de, this message translates to:
  /// **'Ohne Ziel: Rundreise ab Start'**
  String get mapWithoutDestination;

  /// No description provided for @tripTypeDayTrip.
  ///
  /// In de, this message translates to:
  /// **'Tagesausflug'**
  String get tripTypeDayTrip;

  /// No description provided for @tripTypeEuroTrip.
  ///
  /// In de, this message translates to:
  /// **'Euro Trip'**
  String get tripTypeEuroTrip;

  /// No description provided for @tripTypeMultiDay.
  ///
  /// In de, this message translates to:
  /// **'Mehrtages-Trip'**
  String get tripTypeMultiDay;

  /// No description provided for @tripTypeScenic.
  ///
  /// In de, this message translates to:
  /// **'Scenic Route'**
  String get tripTypeScenic;

  /// No description provided for @tripTypeDayTripDistance.
  ///
  /// In de, this message translates to:
  /// **'30-200 km'**
  String get tripTypeDayTripDistance;

  /// No description provided for @tripTypeEuroTripDistance.
  ///
  /// In de, this message translates to:
  /// **'200-800 km'**
  String get tripTypeEuroTripDistance;

  /// No description provided for @tripTypeMultiDayDistance.
  ///
  /// In de, this message translates to:
  /// **'2-7 Tage'**
  String get tripTypeMultiDayDistance;

  /// No description provided for @tripTypeScenicDistance.
  ///
  /// In de, this message translates to:
  /// **'variabel'**
  String get tripTypeScenicDistance;

  /// No description provided for @tripTypeDayTripDesc.
  ///
  /// In de, this message translates to:
  /// **'Aktivitäts-Auswahl, Wetter-basiert'**
  String get tripTypeDayTripDesc;

  /// No description provided for @tripTypeEuroTripDesc.
  ///
  /// In de, this message translates to:
  /// **'Anderes Land, Hotel-Vorschläge'**
  String get tripTypeEuroTripDesc;

  /// No description provided for @tripTypeMultiDayDesc.
  ///
  /// In de, this message translates to:
  /// **'Automatische Übernachtungs-Stops'**
  String get tripTypeMultiDayDesc;

  /// No description provided for @tripTypeScenicDesc.
  ///
  /// In de, this message translates to:
  /// **'Aussichtspunkte priorisiert'**
  String get tripTypeScenicDesc;

  /// No description provided for @accessWheelchair.
  ///
  /// In de, this message translates to:
  /// **'Rollstuhlgerecht'**
  String get accessWheelchair;

  /// No description provided for @accessNoStairs.
  ///
  /// In de, this message translates to:
  /// **'Ohne Treppen'**
  String get accessNoStairs;

  /// No description provided for @accessParking.
  ///
  /// In de, this message translates to:
  /// **'Behindertenparkplatz'**
  String get accessParking;

  /// No description provided for @accessToilet.
  ///
  /// In de, this message translates to:
  /// **'Behindertentoilette'**
  String get accessToilet;

  /// No description provided for @accessElevator.
  ///
  /// In de, this message translates to:
  /// **'Aufzug vorhanden'**
  String get accessElevator;

  /// No description provided for @accessBraille.
  ///
  /// In de, this message translates to:
  /// **'Blindenschrift'**
  String get accessBraille;

  /// No description provided for @accessAudioGuide.
  ///
  /// In de, this message translates to:
  /// **'Audio-Guide'**
  String get accessAudioGuide;

  /// No description provided for @accessSignLanguage.
  ///
  /// In de, this message translates to:
  /// **'Gebärdensprache'**
  String get accessSignLanguage;

  /// No description provided for @accessAssistDogs.
  ///
  /// In de, this message translates to:
  /// **'Assistenzhunde erlaubt'**
  String get accessAssistDogs;

  /// No description provided for @accessFullyAccessible.
  ///
  /// In de, this message translates to:
  /// **'Vollständig zugänglich'**
  String get accessFullyAccessible;

  /// No description provided for @accessLimited.
  ///
  /// In de, this message translates to:
  /// **'Eingeschränkt zugänglich'**
  String get accessLimited;

  /// No description provided for @accessNotAccessible.
  ///
  /// In de, this message translates to:
  /// **'Nicht zugänglich'**
  String get accessNotAccessible;

  /// No description provided for @accessUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get accessUnknown;

  /// No description provided for @highlightUnesco.
  ///
  /// In de, this message translates to:
  /// **'UNESCO-Welterbe'**
  String get highlightUnesco;

  /// No description provided for @highlightMustSee.
  ///
  /// In de, this message translates to:
  /// **'Must-See'**
  String get highlightMustSee;

  /// No description provided for @highlightSecret.
  ///
  /// In de, this message translates to:
  /// **'Geheimtipp'**
  String get highlightSecret;

  /// No description provided for @highlightHistoric.
  ///
  /// In de, this message translates to:
  /// **'Historisch'**
  String get highlightHistoric;

  /// No description provided for @highlightFamilyFriendly.
  ///
  /// In de, this message translates to:
  /// **'Familienfreundlich'**
  String get highlightFamilyFriendly;

  /// No description provided for @experienceDetourKm.
  ///
  /// In de, this message translates to:
  /// **'+{km} km Umweg'**
  String experienceDetourKm(int km);

  /// No description provided for @formatMinShort.
  ///
  /// In de, this message translates to:
  /// **'Min.'**
  String get formatMinShort;

  /// No description provided for @formatHourShort.
  ///
  /// In de, this message translates to:
  /// **'Std.'**
  String get formatHourShort;

  /// No description provided for @formatMinLong.
  ///
  /// In de, this message translates to:
  /// **'Minuten'**
  String get formatMinLong;

  /// No description provided for @formatHourLong.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Stunde} other{Stunden}}'**
  String formatHourLong(int count);

  /// No description provided for @formatDayCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String formatDayCount(int count);

  /// No description provided for @formatStopCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Stopp} other{{count} Stopps}}'**
  String formatStopCount(int count);

  /// No description provided for @formatNoInfo.
  ///
  /// In de, this message translates to:
  /// **'Keine Angabe'**
  String get formatNoInfo;

  /// No description provided for @formatJustNow.
  ///
  /// In de, this message translates to:
  /// **'Gerade eben'**
  String get formatJustNow;

  /// No description provided for @formatAgoMinutes.
  ///
  /// In de, this message translates to:
  /// **'Vor {count} Min.'**
  String formatAgoMinutes(int count);

  /// No description provided for @formatAgoHours.
  ///
  /// In de, this message translates to:
  /// **'Vor {count} Std.'**
  String formatAgoHours(int count);

  /// No description provided for @formatAgoDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Vor 1 Tag} other{Vor {count} Tagen}}'**
  String formatAgoDays(int count);

  /// No description provided for @formatUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get formatUnknown;

  /// No description provided for @journalTitle.
  ///
  /// In de, this message translates to:
  /// **'Reisetagebuch'**
  String get journalTitle;

  /// No description provided for @journalEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge'**
  String get journalEmptyTitle;

  /// No description provided for @journalEmptySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Halte deine Reiseerinnerungen mit Fotos und Notizen fest.'**
  String get journalEmptySubtitle;

  /// No description provided for @journalAddEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag hinzufügen'**
  String get journalAddEntry;

  /// No description provided for @journalAddFirstEntry.
  ///
  /// In de, this message translates to:
  /// **'Ersten Eintrag erstellen'**
  String get journalAddFirstEntry;

  /// No description provided for @journalNewEntry.
  ///
  /// In de, this message translates to:
  /// **'Neuer Eintrag'**
  String get journalNewEntry;

  /// No description provided for @journalAddPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get journalAddPhoto;

  /// No description provided for @journalCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get journalCamera;

  /// No description provided for @journalGallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get journalGallery;

  /// No description provided for @journalAddNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz hinzufügen'**
  String get journalAddNote;

  /// No description provided for @journalNoteHint.
  ///
  /// In de, this message translates to:
  /// **'Was hast du erlebt?'**
  String get journalNoteHint;

  /// No description provided for @journalSaveNote.
  ///
  /// In de, this message translates to:
  /// **'Nur Notiz speichern'**
  String get journalSaveNote;

  /// No description provided for @journalSaveLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort speichern'**
  String get journalSaveLocation;

  /// No description provided for @journalLocationAvailable.
  ///
  /// In de, this message translates to:
  /// **'GPS-Standort verfügbar'**
  String get journalLocationAvailable;

  /// No description provided for @journalLocationLoading.
  ///
  /// In de, this message translates to:
  /// **'Standort wird geladen...'**
  String get journalLocationLoading;

  /// No description provided for @journalEnterNote.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine Notiz ein'**
  String get journalEnterNote;

  /// No description provided for @journalDeleteEntryTitle.
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen?'**
  String get journalDeleteEntryTitle;

  /// No description provided for @journalDeleteEntryMessage.
  ///
  /// In de, this message translates to:
  /// **'Dieser Eintrag wird unwiderruflich gelöscht.'**
  String get journalDeleteEntryMessage;

  /// No description provided for @journalDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch löschen?'**
  String get journalDeleteTitle;

  /// No description provided for @journalDeleteMessage.
  ///
  /// In de, this message translates to:
  /// **'Alle Einträge und Fotos werden unwiderruflich gelöscht.'**
  String get journalDeleteMessage;

  /// No description provided for @journalPhotos.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Fotos} =1{1 Foto} other{{count} Fotos}}'**
  String journalPhotos(int count);

  /// No description provided for @journalEntries.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Einträge} =1{1 Eintrag} other{{count} Einträge}}'**
  String journalEntries(int count);

  /// No description provided for @journalDay.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String journalDay(int count);

  /// No description provided for @journalDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String journalDays(int count);

  /// No description provided for @journalDayNumber.
  ///
  /// In de, this message translates to:
  /// **'Tag {day}'**
  String journalDayNumber(int day);

  /// No description provided for @journalOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstige'**
  String get journalOther;

  /// No description provided for @journalEntry.
  ///
  /// In de, this message translates to:
  /// **'Eintrag'**
  String get journalEntry;

  /// No description provided for @journalEntriesPlural.
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get journalEntriesPlural;

  /// No description provided for @journalOpenJournal.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch öffnen'**
  String get journalOpenJournal;

  /// No description provided for @journalAllJournals.
  ///
  /// In de, this message translates to:
  /// **'Alle Tagebücher'**
  String get journalAllJournals;

  /// No description provided for @journalNoJournals.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Tagebücher vorhanden'**
  String get journalNoJournals;

  /// No description provided for @galleryTitle.
  ///
  /// In de, this message translates to:
  /// **'Trip-Galerie'**
  String get galleryTitle;

  /// No description provided for @gallerySearch.
  ///
  /// In de, this message translates to:
  /// **'Trips suchen...'**
  String get gallerySearch;

  /// No description provided for @galleryFeatured.
  ///
  /// In de, this message translates to:
  /// **'Featured'**
  String get galleryFeatured;

  /// No description provided for @galleryAllTrips.
  ///
  /// In de, this message translates to:
  /// **'Alle Trips'**
  String get galleryAllTrips;

  /// No description provided for @galleryNoTrips.
  ///
  /// In de, this message translates to:
  /// **'Keine Trips gefunden'**
  String get galleryNoTrips;

  /// No description provided for @galleryResetFilters.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get galleryResetFilters;

  /// No description provided for @galleryFilter.
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get galleryFilter;

  /// No description provided for @galleryFilterReset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get galleryFilterReset;

  /// No description provided for @galleryTripType.
  ///
  /// In de, this message translates to:
  /// **'Trip-Typ'**
  String get galleryTripType;

  /// No description provided for @galleryTags.
  ///
  /// In de, this message translates to:
  /// **'Tags'**
  String get galleryTags;

  /// No description provided for @gallerySort.
  ///
  /// In de, this message translates to:
  /// **'Sortierung'**
  String get gallerySort;

  /// No description provided for @gallerySortPopular.
  ///
  /// In de, this message translates to:
  /// **'Beliebt'**
  String get gallerySortPopular;

  /// No description provided for @gallerySortRecent.
  ///
  /// In de, this message translates to:
  /// **'Neueste'**
  String get gallerySortRecent;

  /// No description provided for @gallerySortLikes.
  ///
  /// In de, this message translates to:
  /// **'Meiste Likes'**
  String get gallerySortLikes;

  /// No description provided for @galleryTypeAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get galleryTypeAll;

  /// No description provided for @galleryTypeDaytrip.
  ///
  /// In de, this message translates to:
  /// **'Tagesausflug'**
  String get galleryTypeDaytrip;

  /// No description provided for @galleryTypeEurotrip.
  ///
  /// In de, this message translates to:
  /// **'Euro Trip'**
  String get galleryTypeEurotrip;

  /// No description provided for @galleryRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get galleryRetry;

  /// No description provided for @galleryLikes.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Likes} =1{1 Like} other{{count} Likes}}'**
  String galleryLikes(int count);

  /// No description provided for @galleryViews.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Aufruf} other{{count} Aufrufe}}'**
  String galleryViews(int count);

  /// No description provided for @galleryImports.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Import} other{{count} Importe}}'**
  String galleryImports(int count);

  /// No description provided for @gallerySharedAt.
  ///
  /// In de, this message translates to:
  /// **'Geteilt am {date}'**
  String gallerySharedAt(String date);

  /// No description provided for @galleryTripsShared.
  ///
  /// In de, this message translates to:
  /// **'{count} Trips geteilt'**
  String galleryTripsShared(int count);

  /// No description provided for @galleryImportToFavorites.
  ///
  /// In de, this message translates to:
  /// **'In Favoriten'**
  String get galleryImportToFavorites;

  /// No description provided for @galleryImported.
  ///
  /// In de, this message translates to:
  /// **'Importiert'**
  String get galleryImported;

  /// No description provided for @galleryShowOnMap.
  ///
  /// In de, this message translates to:
  /// **'Auf Karte'**
  String get galleryShowOnMap;

  /// No description provided for @galleryShareComingSoon.
  ///
  /// In de, this message translates to:
  /// **'Teilen wird bald verfügbar'**
  String get galleryShareComingSoon;

  /// No description provided for @galleryMapComingSoon.
  ///
  /// In de, this message translates to:
  /// **'Karten-Ansicht wird bald verfügbar'**
  String get galleryMapComingSoon;

  /// No description provided for @galleryMapNoData.
  ///
  /// In de, this message translates to:
  /// **'Keine Route-Daten verfügbar'**
  String get galleryMapNoData;

  /// No description provided for @galleryMapError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden der Route'**
  String get galleryMapError;

  /// No description provided for @galleryImportSuccess.
  ///
  /// In de, this message translates to:
  /// **'Trip in Favoriten importiert'**
  String get galleryImportSuccess;

  /// No description provided for @galleryImportError.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen'**
  String get galleryImportError;

  /// No description provided for @galleryTripNotFound.
  ///
  /// In de, this message translates to:
  /// **'Trip nicht gefunden'**
  String get galleryTripNotFound;

  /// No description provided for @galleryLoadError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden'**
  String get galleryLoadError;

  /// No description provided for @publishTitle.
  ///
  /// In de, this message translates to:
  /// **'Trip veröffentlichen'**
  String get publishTitle;

  /// No description provided for @publishSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Teile deinen Trip mit der Community'**
  String get publishSubtitle;

  /// No description provided for @publishTripName.
  ///
  /// In de, this message translates to:
  /// **'Name des Trips'**
  String get publishTripName;

  /// No description provided for @publishTripNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Südfrankreich Roadtrip'**
  String get publishTripNameHint;

  /// No description provided for @publishTripNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen ein'**
  String get publishTripNameRequired;

  /// No description provided for @publishTripNameMinLength.
  ///
  /// In de, this message translates to:
  /// **'Name muss mindestens 3 Zeichen haben'**
  String get publishTripNameMinLength;

  /// No description provided for @publishDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung (optional)'**
  String get publishDescription;

  /// No description provided for @publishDescriptionHint.
  ///
  /// In de, this message translates to:
  /// **'Erzähle anderen von deinem Trip...'**
  String get publishDescriptionHint;

  /// No description provided for @publishTags.
  ///
  /// In de, this message translates to:
  /// **'Tags (optional)'**
  String get publishTags;

  /// No description provided for @publishTagsHelper.
  ///
  /// In de, this message translates to:
  /// **'Hilf anderen, deinen Trip zu finden'**
  String get publishTagsHelper;

  /// No description provided for @publishMaxTags.
  ///
  /// In de, this message translates to:
  /// **'Maximal 5 Tags'**
  String get publishMaxTags;

  /// No description provided for @publishInfo.
  ///
  /// In de, this message translates to:
  /// **'Dein Trip wird öffentlich sichtbar. Andere können ihn liken und in ihre Favoriten importieren.'**
  String get publishInfo;

  /// No description provided for @publishButton.
  ///
  /// In de, this message translates to:
  /// **'Veröffentlichen'**
  String get publishButton;

  /// No description provided for @publishPublishing.
  ///
  /// In de, this message translates to:
  /// **'Wird veröffentlicht...'**
  String get publishPublishing;

  /// No description provided for @publishSuccess.
  ///
  /// In de, this message translates to:
  /// **'Trip veröffentlicht!'**
  String get publishSuccess;

  /// No description provided for @publishError.
  ///
  /// In de, this message translates to:
  /// **'Veröffentlichen fehlgeschlagen'**
  String get publishError;

  /// No description provided for @tripPublish.
  ///
  /// In de, this message translates to:
  /// **'Trip veröffentlichen'**
  String get tripPublish;

  /// No description provided for @tripPublishDescription.
  ///
  /// In de, this message translates to:
  /// **'In der öffentlichen Galerie teilen'**
  String get tripPublishDescription;

  /// No description provided for @publishEuroTrip.
  ///
  /// In de, this message translates to:
  /// **'Euro Trip'**
  String get publishEuroTrip;

  /// No description provided for @publishDaytrip.
  ///
  /// In de, this message translates to:
  /// **'Tagesausflug'**
  String get publishDaytrip;

  /// No description provided for @dayEditorDriveTime.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeit'**
  String get dayEditorDriveTime;

  /// No description provided for @dayEditorWeather.
  ///
  /// In de, this message translates to:
  /// **'Wetter'**
  String get dayEditorWeather;

  /// No description provided for @dayEditorDay.
  ///
  /// In de, this message translates to:
  /// **'Tag'**
  String get dayEditorDay;

  /// No description provided for @dayEditorNoStopsForDay.
  ///
  /// In de, this message translates to:
  /// **'Keine Stops für Tag {day}'**
  String dayEditorNoStopsForDay(int day);

  /// No description provided for @dayEditorDayInGoogleMaps.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} in Google Maps'**
  String dayEditorDayInGoogleMaps(int day);

  /// No description provided for @dayEditorOpenAgain.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} erneut öffnen'**
  String dayEditorOpenAgain(int day);

  /// No description provided for @dayEditorTripCompleted.
  ///
  /// In de, this message translates to:
  /// **'Trip abgeschlossen!'**
  String get dayEditorTripCompleted;

  /// No description provided for @dayEditorRouteShare.
  ///
  /// In de, this message translates to:
  /// **'Route Teilen'**
  String get dayEditorRouteShare;

  /// No description provided for @dayEditorRouteShareError.
  ///
  /// In de, this message translates to:
  /// **'Route konnte nicht geteilt werden'**
  String get dayEditorRouteShareError;

  /// No description provided for @dayEditorShareStops.
  ///
  /// In de, this message translates to:
  /// **'Stops'**
  String get dayEditorShareStops;

  /// No description provided for @dayEditorShareOpenGoogleMaps.
  ///
  /// In de, this message translates to:
  /// **'In Google Maps öffnen'**
  String get dayEditorShareOpenGoogleMaps;

  /// No description provided for @tripSummaryTotal.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get tripSummaryTotal;

  /// No description provided for @tripSummaryDriveTime.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeit'**
  String get tripSummaryDriveTime;

  /// No description provided for @tripSummaryStops.
  ///
  /// In de, this message translates to:
  /// **'Stops'**
  String get tripSummaryStops;

  /// No description provided for @filterTitle.
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterMaxDetour.
  ///
  /// In de, this message translates to:
  /// **'Maximaler Umweg'**
  String get filterMaxDetour;

  /// No description provided for @filterMaxDetourHint.
  ///
  /// In de, this message translates to:
  /// **'POIs mit größerem Umweg werden ausgeblendet'**
  String get filterMaxDetourHint;

  /// No description provided for @filterAllCategories.
  ///
  /// In de, this message translates to:
  /// **'Alle Kategorien anzeigen'**
  String get filterAllCategories;

  /// No description provided for @filterSelectedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String filterSelectedCount(int count);

  /// No description provided for @filterCategoriesLabel.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get filterCategoriesLabel;

  /// No description provided for @categorySelectorDeselectAll.
  ///
  /// In de, this message translates to:
  /// **'Alle abwählen'**
  String get categorySelectorDeselectAll;

  /// No description provided for @categorySelectorNoneHint.
  ///
  /// In de, this message translates to:
  /// **'Keine Auswahl = alle Kategorien'**
  String get categorySelectorNoneHint;

  /// No description provided for @categorySelectorSelectedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String categorySelectorSelectedCount(int count);

  /// No description provided for @categorySelectorTitle.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get categorySelectorTitle;

  /// No description provided for @startLocationLabel.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt'**
  String get startLocationLabel;

  /// No description provided for @startLocationHint.
  ///
  /// In de, this message translates to:
  /// **'Stadt oder Adresse eingeben...'**
  String get startLocationHint;

  /// No description provided for @startLocationGps.
  ///
  /// In de, this message translates to:
  /// **'GPS-Standort verwenden'**
  String get startLocationGps;

  /// No description provided for @tripPreviewNoTrip.
  ///
  /// In de, this message translates to:
  /// **'Kein Trip generiert'**
  String get tripPreviewNoTrip;

  /// No description provided for @tripPreviewYourTrip.
  ///
  /// In de, this message translates to:
  /// **'Dein Trip'**
  String get tripPreviewYourTrip;

  /// No description provided for @tripPreviewConfirm.
  ///
  /// In de, this message translates to:
  /// **'Trip bestätigen'**
  String get tripPreviewConfirm;

  /// No description provided for @tripPreviewMaxStopsWarning.
  ///
  /// In de, this message translates to:
  /// **'Max {max} Stops pro Tag (Google Maps Limit)'**
  String tripPreviewMaxStopsWarning(int max);

  /// No description provided for @tripPreviewStopsDay.
  ///
  /// In de, this message translates to:
  /// **'Stops (Tag {day})'**
  String tripPreviewStopsDay(int day);

  /// No description provided for @tripPreviewDayCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Tag} other{Tage}}'**
  String tripPreviewDayCount(int count);

  /// No description provided for @navSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get navSkip;

  /// No description provided for @navVisitedButton.
  ///
  /// In de, this message translates to:
  /// **'Besucht'**
  String get navVisitedButton;

  /// No description provided for @navDistanceAway.
  ///
  /// In de, this message translates to:
  /// **'{distance} entfernt'**
  String navDistanceAway(String distance);

  /// No description provided for @chatDemoMode.
  ///
  /// In de, this message translates to:
  /// **'Demo-Modus: Antworten sind simuliert'**
  String get chatDemoMode;

  /// No description provided for @chatLocationLoading.
  ///
  /// In de, this message translates to:
  /// **'Standort wird geladen...'**
  String get chatLocationLoading;

  /// No description provided for @chatLocationActive.
  ///
  /// In de, this message translates to:
  /// **'Standort aktiv'**
  String get chatLocationActive;

  /// No description provided for @chatLocationEnable.
  ///
  /// In de, this message translates to:
  /// **'Standort aktivieren'**
  String get chatLocationEnable;

  /// No description provided for @chatMyLocation.
  ///
  /// In de, this message translates to:
  /// **'Mein Standort'**
  String get chatMyLocation;

  /// No description provided for @chatRadiusTooltip.
  ///
  /// In de, this message translates to:
  /// **'Suchradius'**
  String get chatRadiusTooltip;

  /// No description provided for @chatNoPoisFound.
  ///
  /// In de, this message translates to:
  /// **'Keine POIs in der Nähe gefunden'**
  String get chatNoPoisFound;

  /// No description provided for @chatPoisInRadius.
  ///
  /// In de, this message translates to:
  /// **'{count} POIs im Umkreis von {radius} km'**
  String chatPoisInRadius(int count, String radius);

  /// No description provided for @chatRadiusLabel.
  ///
  /// In de, this message translates to:
  /// **'{radius} km'**
  String chatRadiusLabel(String radius);

  /// No description provided for @chatWelcomeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Frag mich alles über deine Reise!'**
  String get chatWelcomeSubtitle;

  /// No description provided for @chatDemoBackendNotReachable.
  ///
  /// In de, this message translates to:
  /// **'Demo-Modus: Backend nicht erreichbar'**
  String get chatDemoBackendNotReachable;

  /// No description provided for @chatDemoBackendNotConfigured.
  ///
  /// In de, this message translates to:
  /// **'Demo-Modus: Backend-URL nicht konfiguriert'**
  String get chatDemoBackendNotConfigured;

  /// No description provided for @chatNumberOfDays.
  ///
  /// In de, this message translates to:
  /// **'Anzahl Tage'**
  String get chatNumberOfDays;

  /// No description provided for @chatInterests.
  ///
  /// In de, this message translates to:
  /// **'Interessen:'**
  String get chatInterests;

  /// No description provided for @chatLocationNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Standort nicht verfügbar'**
  String get chatLocationNotAvailable;

  /// No description provided for @chatLocationNotAvailableMessage.
  ///
  /// In de, this message translates to:
  /// **'Um POIs in deiner Nähe zu finden, benötige ich Zugriff auf deinen Standort.\n\nBitte aktiviere die Ortungsdienste und versuche es erneut.'**
  String get chatLocationNotAvailableMessage;

  /// No description provided for @chatPoisSearchError.
  ///
  /// In de, this message translates to:
  /// **'Fehler bei der POI-Suche'**
  String get chatPoisSearchError;

  /// No description provided for @chatPoisSearchErrorMessage.
  ///
  /// In de, this message translates to:
  /// **'Entschuldigung, es gab ein Problem beim Laden der POIs.\n\nBitte versuche es erneut.'**
  String get chatPoisSearchErrorMessage;

  /// No description provided for @chatNoResponseGenerated.
  ///
  /// In de, this message translates to:
  /// **'Entschuldigung, ich konnte keine Antwort generieren.'**
  String get chatNoResponseGenerated;

  /// No description provided for @chatRadiusAdjust.
  ///
  /// In de, this message translates to:
  /// **'Such-Radius anpassen'**
  String get chatRadiusAdjust;

  /// No description provided for @voiceRerouting.
  ///
  /// In de, this message translates to:
  /// **'Route wird neu berechnet'**
  String get voiceRerouting;

  /// No description provided for @voicePOIApproaching.
  ///
  /// In de, this message translates to:
  /// **'{name} in {distance}'**
  String voicePOIApproaching(String name, String distance);

  /// No description provided for @voiceArrivedAt.
  ///
  /// In de, this message translates to:
  /// **'Sie haben Ihr Ziel erreicht: {name}'**
  String voiceArrivedAt(String name);

  /// No description provided for @voiceRouteInfo.
  ///
  /// In de, this message translates to:
  /// **'Noch {distance} und {duration} bis zum Ziel'**
  String voiceRouteInfo(String distance, String duration);

  /// No description provided for @voiceNextStop.
  ///
  /// In de, this message translates to:
  /// **'Nächster Stopp: {name} in {distance}'**
  String voiceNextStop(String name, String distance);

  /// No description provided for @voiceCurrentLocation.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Standort: {location}'**
  String voiceCurrentLocation(String location);

  /// No description provided for @voiceInMeters.
  ///
  /// In de, this message translates to:
  /// **'{meters} Meter'**
  String voiceInMeters(int meters);

  /// No description provided for @voiceInKilometers.
  ///
  /// In de, this message translates to:
  /// **'{km} Kilometer'**
  String voiceInKilometers(String km);

  /// No description provided for @voiceHours.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Stunde} other{{count} Stunden}}'**
  String voiceHours(int count);

  /// No description provided for @voiceMinutes.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Minute} other{{count} Minuten}}'**
  String voiceMinutes(int count);

  /// No description provided for @voiceStops.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Stopp} other{{count} Stopps}}'**
  String voiceStops(int count);

  /// No description provided for @voiceCmdNextStop.
  ///
  /// In de, this message translates to:
  /// **'Nächster Stopp'**
  String get voiceCmdNextStop;

  /// No description provided for @voiceCmdLocation.
  ///
  /// In de, this message translates to:
  /// **'Wo bin ich'**
  String get voiceCmdLocation;

  /// No description provided for @voiceCmdDuration.
  ///
  /// In de, this message translates to:
  /// **'Wie lange noch'**
  String get voiceCmdDuration;

  /// No description provided for @voiceCmdEndNavigation.
  ///
  /// In de, this message translates to:
  /// **'Navigation beenden'**
  String get voiceCmdEndNavigation;

  /// No description provided for @voiceNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt'**
  String get voiceNow;

  /// No description provided for @voiceArrived.
  ///
  /// In de, this message translates to:
  /// **'Sie haben Ihr Ziel erreicht'**
  String get voiceArrived;

  /// No description provided for @voicePOIReached.
  ///
  /// In de, this message translates to:
  /// **'{name} erreicht'**
  String voicePOIReached(String name);

  /// No description provided for @voiceCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie: {category}'**
  String voiceCategory(String category);

  /// No description provided for @voiceDistanceMeters.
  ///
  /// In de, this message translates to:
  /// **'{meters} Meter entfernt'**
  String voiceDistanceMeters(int meters);

  /// No description provided for @voiceDistanceKm.
  ///
  /// In de, this message translates to:
  /// **'{km} Kilometer entfernt'**
  String voiceDistanceKm(String km);

  /// No description provided for @voiceRouteLength.
  ///
  /// In de, this message translates to:
  /// **'Deine Route ist {distance} Kilometer lang, dauert etwa {duration} und hat {stops}.'**
  String voiceRouteLength(String distance, String duration, String stops);

  /// No description provided for @voiceAndMinutes.
  ///
  /// In de, this message translates to:
  /// **'und {count, plural, =1{1 Minute} other{{count} Minuten}}'**
  String voiceAndMinutes(int count);

  /// No description provided for @voiceCmdPreviousStop.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Stopp'**
  String get voiceCmdPreviousStop;

  /// No description provided for @voiceCmdNearby.
  ///
  /// In de, this message translates to:
  /// **'Was ist in der Nähe'**
  String get voiceCmdNearby;

  /// No description provided for @voiceCmdAdd.
  ///
  /// In de, this message translates to:
  /// **'Zur Route hinzufügen'**
  String get voiceCmdAdd;

  /// No description provided for @voiceCmdStartNav.
  ///
  /// In de, this message translates to:
  /// **'Navigation starten'**
  String get voiceCmdStartNav;

  /// No description provided for @voiceCmdStopNav.
  ///
  /// In de, this message translates to:
  /// **'Navigation beenden'**
  String get voiceCmdStopNav;

  /// No description provided for @voiceCmdDescribe.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung vorlesen'**
  String get voiceCmdDescribe;

  /// No description provided for @voiceCmdUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get voiceCmdUnknown;

  /// No description provided for @voiceCmdRouteWeather.
  ///
  /// In de, this message translates to:
  /// **'Wetter auf Route'**
  String get voiceCmdRouteWeather;

  /// No description provided for @voiceCmdRecommend.
  ///
  /// In de, this message translates to:
  /// **'Empfehlung'**
  String get voiceCmdRecommend;

  /// No description provided for @voiceCmdOverview.
  ///
  /// In de, this message translates to:
  /// **'Route Übersicht'**
  String get voiceCmdOverview;

  /// No description provided for @voiceCmdRemaining.
  ///
  /// In de, this message translates to:
  /// **'Verbleibende Stopps'**
  String get voiceCmdRemaining;

  /// No description provided for @voiceCmdHelp.
  ///
  /// In de, this message translates to:
  /// **'Hilfe'**
  String get voiceCmdHelp;

  /// No description provided for @voiceCmdNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Dieser Befehl ist während der Navigation nicht verfügbar.'**
  String get voiceCmdNotAvailable;

  /// No description provided for @voiceGreeting1.
  ///
  /// In de, this message translates to:
  /// **'Bereit für deine Reise?'**
  String get voiceGreeting1;

  /// No description provided for @voiceGreeting2.
  ///
  /// In de, this message translates to:
  /// **'Wie kann ich dir helfen?'**
  String get voiceGreeting2;

  /// No description provided for @voiceGreeting3.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du wissen?'**
  String get voiceGreeting3;

  /// No description provided for @voiceGreeting4.
  ///
  /// In de, this message translates to:
  /// **'Ich höre!'**
  String get voiceGreeting4;

  /// No description provided for @voiceGreeting5.
  ///
  /// In de, this message translates to:
  /// **'Frag mich was!'**
  String get voiceGreeting5;

  /// No description provided for @voiceGreeting6.
  ///
  /// In de, this message translates to:
  /// **'Bereit für deinen Trip?'**
  String get voiceGreeting6;

  /// No description provided for @voiceGreeting7.
  ///
  /// In de, this message translates to:
  /// **'Dein Navi-Assistent hier!'**
  String get voiceGreeting7;

  /// No description provided for @voiceGreeting8.
  ///
  /// In de, this message translates to:
  /// **'Wohin gehts?'**
  String get voiceGreeting8;

  /// No description provided for @voiceUnknown1.
  ///
  /// In de, this message translates to:
  /// **'Hmm, das hab ich nicht verstanden. Versuch mal Wie lange noch? oder Nächster Stopp.'**
  String get voiceUnknown1;

  /// No description provided for @voiceUnknown2.
  ///
  /// In de, this message translates to:
  /// **'Ups! Mein Navi-Gehirn hat das nicht gecheckt. Sag Hilfe für alle Befehle!'**
  String get voiceUnknown2;

  /// No description provided for @voiceUnknown3.
  ///
  /// In de, this message translates to:
  /// **'Das war wohl zu philosophisch für mich. Ich bin nur ein einfaches Navi!'**
  String get voiceUnknown3;

  /// No description provided for @voiceUnknown4.
  ///
  /// In de, this message translates to:
  /// **'Hä? Ich bin ein Navi, kein Gedankenleser! Frag mich nach der Route oder dem Wetter.'**
  String get voiceUnknown4;

  /// No description provided for @voiceUnknown5.
  ///
  /// In de, this message translates to:
  /// **'Leider nicht verstanden. Probier Wo bin ich? oder Was ist in der Nähe?'**
  String get voiceUnknown5;

  /// No description provided for @voiceUnknown6.
  ///
  /// In de, this message translates to:
  /// **'Beep boop... Befehl nicht erkannt! Ich verstehe z.B. Wie lange noch?'**
  String get voiceUnknown6;

  /// No description provided for @voiceWeatherOnRoute.
  ///
  /// In de, this message translates to:
  /// **'Das Wetter auf deiner Route: {description}, {temp} Grad.'**
  String voiceWeatherOnRoute(String description, String temp);

  /// No description provided for @voiceNoWeatherData.
  ///
  /// In de, this message translates to:
  /// **'Leider habe ich keine Wetterdaten für deine Route.'**
  String get voiceNoWeatherData;

  /// No description provided for @voiceRecommendPOIs.
  ///
  /// In de, this message translates to:
  /// **'Ich empfehle dir: {names}. Echte Highlights!'**
  String voiceRecommendPOIs(String names);

  /// No description provided for @voiceNoRecommendations.
  ///
  /// In de, this message translates to:
  /// **'Auf deiner Route gibt es einige interessante Stopps!'**
  String get voiceNoRecommendations;

  /// No description provided for @voiceRouteOverview.
  ///
  /// In de, this message translates to:
  /// **'Deine Route ist {distance} Kilometer lang mit {stops} Stopps.'**
  String voiceRouteOverview(String distance, String stops);

  /// No description provided for @voiceRemainingOne.
  ///
  /// In de, this message translates to:
  /// **'Noch ein Stopp bis zum Ziel!'**
  String get voiceRemainingOne;

  /// No description provided for @voiceRemainingMultiple.
  ///
  /// In de, this message translates to:
  /// **'Noch {count} Stopps vor dir.'**
  String voiceRemainingMultiple(int count);

  /// No description provided for @voiceHelpText.
  ///
  /// In de, this message translates to:
  /// **'Du kannst mich fragen: Wie lange noch? Nächster Stopp? Wo bin ich? Wie ist das Wetter? Was empfiehlst du? Oder sag Navigation beenden.'**
  String get voiceHelpText;

  /// No description provided for @voiceManeuverNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt {instruction}'**
  String voiceManeuverNow(String instruction);

  /// No description provided for @voiceManeuverInMeters.
  ///
  /// In de, this message translates to:
  /// **'In {meters} Metern {instruction}'**
  String voiceManeuverInMeters(int meters, String instruction);

  /// No description provided for @voiceManeuverInKm.
  ///
  /// In de, this message translates to:
  /// **'In {km} Kilometern {instruction}'**
  String voiceManeuverInKm(String km, String instruction);

  /// No description provided for @navMustSeeAnnouncement.
  ///
  /// In de, this message translates to:
  /// **'In {distance} Metern befindet sich {name}, ein Must-See Highlight'**
  String navMustSeeAnnouncement(String distance, String name);

  /// No description provided for @advisorDangerWeather.
  ///
  /// In de, this message translates to:
  /// **'Unwetter auf Tag {day} erwartet! {outdoorCount} Outdoor-Stops sollten durch Indoor-Alternativen ersetzt werden.'**
  String advisorDangerWeather(int day, int outdoorCount);

  /// No description provided for @advisorBadWeather.
  ///
  /// In de, this message translates to:
  /// **'Regen auf Tag {day} erwartet. {outdoorCount} von {totalCount} Stops sind Outdoor-Aktivitaeten.'**
  String advisorBadWeather(int day, int outdoorCount, int totalCount);

  /// No description provided for @advisorOutdoorAlternative.
  ///
  /// In de, this message translates to:
  /// **'{name} ist eine Outdoor-Aktivitaet - Alternative empfohlen'**
  String advisorOutdoorAlternative(String name);

  /// No description provided for @advisorOutdoorReplace.
  ///
  /// In de, this message translates to:
  /// **'{name} ist eine Outdoor-Aktivitaet. Ersetze diesen Stop fuer eine Indoor-Alternative.'**
  String advisorOutdoorReplace(String name);

  /// No description provided for @advisorAiUnavailableSuggestions.
  ///
  /// In de, this message translates to:
  /// **'AI nicht erreichbar - zeige lokale Vorschlaege'**
  String get advisorAiUnavailableSuggestions;

  /// No description provided for @advisorNoStopsForDay.
  ///
  /// In de, this message translates to:
  /// **'Keine Stops fuer Tag {day}'**
  String advisorNoStopsForDay(int day);

  /// No description provided for @advisorNoRecommendationsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Empfehlungen in der Naehe der Stops gefunden'**
  String get advisorNoRecommendationsFound;

  /// No description provided for @advisorAiUnavailableRecommendations.
  ///
  /// In de, this message translates to:
  /// **'AI nicht erreichbar - zeige lokale Empfehlungen'**
  String get advisorAiUnavailableRecommendations;

  /// No description provided for @advisorErrorLoadingRecommendations.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden der Empfehlungen'**
  String get advisorErrorLoadingRecommendations;

  /// No description provided for @advisorPoiCategory.
  ///
  /// In de, this message translates to:
  /// **'{name} - {category}'**
  String advisorPoiCategory(String name, String category);

  /// No description provided for @weatherConditionGood.
  ///
  /// In de, this message translates to:
  /// **'Gutes Wetter'**
  String get weatherConditionGood;

  /// No description provided for @weatherConditionMixed.
  ///
  /// In de, this message translates to:
  /// **'Wechselhaft'**
  String get weatherConditionMixed;

  /// No description provided for @weatherConditionBad.
  ///
  /// In de, this message translates to:
  /// **'Schlechtes Wetter'**
  String get weatherConditionBad;

  /// No description provided for @weatherConditionDanger.
  ///
  /// In de, this message translates to:
  /// **'Unwetterwarnung'**
  String get weatherConditionDanger;

  /// No description provided for @weatherConditionUnknown.
  ///
  /// In de, this message translates to:
  /// **'Wetter unbekannt'**
  String get weatherConditionUnknown;

  /// No description provided for @weatherBadgeSnow.
  ///
  /// In de, this message translates to:
  /// **'Schnee'**
  String get weatherBadgeSnow;

  /// No description provided for @weatherBadgeRain.
  ///
  /// In de, this message translates to:
  /// **'Regen'**
  String get weatherBadgeRain;

  /// No description provided for @weatherBadgePerfect.
  ///
  /// In de, this message translates to:
  /// **'Perfekt'**
  String get weatherBadgePerfect;

  /// No description provided for @weatherBadgeBad.
  ///
  /// In de, this message translates to:
  /// **'Schlecht'**
  String get weatherBadgeBad;

  /// No description provided for @weatherBadgeDanger.
  ///
  /// In de, this message translates to:
  /// **'Unwetter'**
  String get weatherBadgeDanger;

  /// No description provided for @weatherRecOutdoorIdeal.
  ///
  /// In de, this message translates to:
  /// **'Heute ideal für Outdoor-POIs'**
  String get weatherRecOutdoorIdeal;

  /// No description provided for @weatherRecRainIndoor.
  ///
  /// In de, this message translates to:
  /// **'Regen - Indoor-POIs empfohlen'**
  String get weatherRecRainIndoor;

  /// No description provided for @weatherRecDangerIndoor.
  ///
  /// In de, this message translates to:
  /// **'Unwetter - nur Indoor-POIs!'**
  String get weatherRecDangerIndoor;

  /// No description provided for @weatherToggleActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get weatherToggleActive;

  /// No description provided for @weatherToggleApply.
  ///
  /// In de, this message translates to:
  /// **'Anwenden'**
  String get weatherToggleApply;

  /// No description provided for @weatherPointStart.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get weatherPointStart;

  /// No description provided for @weatherPointEnd.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get weatherPointEnd;

  /// No description provided for @weatherIndoorOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur Indoor-POIs'**
  String get weatherIndoorOnly;

  /// No description provided for @weatherAlertStorm.
  ///
  /// In de, this message translates to:
  /// **'Sturmwarnung! Starke Winde ({windSpeed} km/h) entlang der Route.'**
  String weatherAlertStorm(String windSpeed);

  /// No description provided for @weatherAlertDanger.
  ///
  /// In de, this message translates to:
  /// **'Unwetterwarnung! Fahrt verschieben empfohlen.'**
  String get weatherAlertDanger;

  /// No description provided for @weatherAlertWinter.
  ///
  /// In de, this message translates to:
  /// **'Winterwetter! Schnee/Glätte möglich.'**
  String get weatherAlertWinter;

  /// No description provided for @weatherAlertRain.
  ///
  /// In de, this message translates to:
  /// **'Regen erwartet. Indoor-Aktivitäten empfohlen.'**
  String get weatherAlertRain;

  /// No description provided for @weatherAlertBad.
  ///
  /// In de, this message translates to:
  /// **'Schlechtes Wetter auf der Route.'**
  String get weatherAlertBad;

  /// No description provided for @weatherRecToday.
  ///
  /// In de, this message translates to:
  /// **'Empfehlung für heute'**
  String get weatherRecToday;

  /// No description provided for @weatherRecGoodDetail.
  ///
  /// In de, this message translates to:
  /// **'Perfektes Wetter für Outdoor-Aktivitäten! Viewpoints, Natur und Seen empfohlen.'**
  String get weatherRecGoodDetail;

  /// No description provided for @weatherRecMixedDetail.
  ///
  /// In de, this message translates to:
  /// **'Wechselhaftes Wetter. Sowohl Indoor- als auch Outdoor-POIs möglich.'**
  String get weatherRecMixedDetail;

  /// No description provided for @weatherRecBadDetail.
  ///
  /// In de, this message translates to:
  /// **'Regen erwartet. Indoor-Aktivitäten wie Museen und Kirchen empfohlen.'**
  String get weatherRecBadDetail;

  /// No description provided for @weatherRecDangerDetail.
  ///
  /// In de, this message translates to:
  /// **'Unwetterwarnung! Bitte Outdoor-Aktivitäten vermeiden und drinnen bleiben.'**
  String get weatherRecDangerDetail;

  /// No description provided for @weatherRecNoData.
  ///
  /// In de, this message translates to:
  /// **'Keine Wetterdaten verfügbar.'**
  String get weatherRecNoData;

  /// No description provided for @weatherRecOutdoorPerfect.
  ///
  /// In de, this message translates to:
  /// **'Perfektes Wetter für Outdoor-Aktivitäten'**
  String get weatherRecOutdoorPerfect;

  /// No description provided for @weatherRecMixedPrepare.
  ///
  /// In de, this message translates to:
  /// **'Wechselhaft - auf alles vorbereitet sein'**
  String get weatherRecMixedPrepare;

  /// No description provided for @weatherRecSnowCaution.
  ///
  /// In de, this message translates to:
  /// **'Schneefall - Vorsicht auf glatten Straßen'**
  String get weatherRecSnowCaution;

  /// No description provided for @weatherRecBadIndoor.
  ///
  /// In de, this message translates to:
  /// **'Schlechtes Wetter - Indoor-Aktivitäten empfohlen'**
  String get weatherRecBadIndoor;

  /// No description provided for @weatherRecStormWarning.
  ///
  /// In de, this message translates to:
  /// **'Sturmwarnung! Starke Winde ({windSpeed} km/h)'**
  String weatherRecStormWarning(String windSpeed);

  /// No description provided for @weatherRecDangerCaution.
  ///
  /// In de, this message translates to:
  /// **'Unwetterwarnung! Vorsicht auf diesem Streckenabschnitt'**
  String get weatherRecDangerCaution;

  /// No description provided for @weatherRecNoDataAvailable.
  ///
  /// In de, this message translates to:
  /// **'Keine Wetterdaten verfügbar'**
  String get weatherRecNoDataAvailable;

  /// No description provided for @mapMyLocation.
  ///
  /// In de, this message translates to:
  /// **'Mein Standort'**
  String get mapMyLocation;

  /// No description provided for @mapDetails.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get mapDetails;

  /// No description provided for @mapAddToRoute.
  ///
  /// In de, this message translates to:
  /// **'Zur Route'**
  String get mapAddToRoute;

  /// No description provided for @mapSelectedPoint.
  ///
  /// In de, this message translates to:
  /// **'Gewählter Punkt'**
  String get mapSelectedPoint;

  /// No description provided for @mapWaypoint.
  ///
  /// In de, this message translates to:
  /// **'Zwischenstopp'**
  String get mapWaypoint;

  /// No description provided for @mapRouteCreated.
  ///
  /// In de, this message translates to:
  /// **'Route zu \"{name}\" erstellt'**
  String mapRouteCreated(String name);

  /// No description provided for @mapPoiAdded.
  ///
  /// In de, this message translates to:
  /// **'\"{name}\" hinzugefügt'**
  String mapPoiAdded(String name);

  /// No description provided for @mapErrorAdding.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Hinzufügen'**
  String get mapErrorAdding;

  /// No description provided for @tripPreviewStartDay1.
  ///
  /// In de, this message translates to:
  /// **'Start (Tag 1)'**
  String get tripPreviewStartDay1;

  /// No description provided for @tripPreviewDayStart.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} Start'**
  String tripPreviewDayStart(String day);

  /// No description provided for @tripPreviewBackToStart.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Start'**
  String get tripPreviewBackToStart;

  /// No description provided for @tripPreviewEndDay.
  ///
  /// In de, this message translates to:
  /// **'Ende Tag {day}'**
  String tripPreviewEndDay(String day);

  /// No description provided for @tripPreviewDetour.
  ///
  /// In de, this message translates to:
  /// **'+{km} km Umweg'**
  String tripPreviewDetour(String km);

  /// No description provided for @tripPreviewOvernight.
  ///
  /// In de, this message translates to:
  /// **'Übernachtung'**
  String get tripPreviewOvernight;

  /// No description provided for @gamificationLevelUp.
  ///
  /// In de, this message translates to:
  /// **'Level Up!'**
  String get gamificationLevelUp;

  /// No description provided for @gamificationNewLevel.
  ///
  /// In de, this message translates to:
  /// **'Level {level}'**
  String gamificationNewLevel(int level);

  /// No description provided for @gamificationContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get gamificationContinue;

  /// No description provided for @gamificationAchievementUnlocked.
  ///
  /// In de, this message translates to:
  /// **'Achievement freigeschaltet!'**
  String get gamificationAchievementUnlocked;

  /// No description provided for @gamificationAwesome.
  ///
  /// In de, this message translates to:
  /// **'Großartig!'**
  String get gamificationAwesome;

  /// No description provided for @gamificationXpEarned.
  ///
  /// In de, this message translates to:
  /// **'+{amount} XP'**
  String gamificationXpEarned(int amount);

  /// No description provided for @gamificationNextAchievements.
  ///
  /// In de, this message translates to:
  /// **'Nächste Achievements'**
  String get gamificationNextAchievements;

  /// No description provided for @gamificationAllAchievements.
  ///
  /// In de, this message translates to:
  /// **'Alle Achievements'**
  String get gamificationAllAchievements;

  /// No description provided for @gamificationUnlockedCount.
  ///
  /// In de, this message translates to:
  /// **'{count}/{total} freigeschaltet'**
  String gamificationUnlockedCount(int count, int total);

  /// No description provided for @gamificationTripCreated.
  ///
  /// In de, this message translates to:
  /// **'Trip erstellt'**
  String get gamificationTripCreated;

  /// No description provided for @gamificationTripPublished.
  ///
  /// In de, this message translates to:
  /// **'Trip veröffentlicht'**
  String get gamificationTripPublished;

  /// No description provided for @gamificationTripImported.
  ///
  /// In de, this message translates to:
  /// **'Trip importiert'**
  String get gamificationTripImported;

  /// No description provided for @gamificationPoiVisited.
  ///
  /// In de, this message translates to:
  /// **'POI besucht'**
  String get gamificationPoiVisited;

  /// No description provided for @gamificationPhotoAdded.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzugefügt'**
  String get gamificationPhotoAdded;

  /// No description provided for @gamificationLikeReceived.
  ///
  /// In de, this message translates to:
  /// **'Like erhalten'**
  String get gamificationLikeReceived;

  /// No description provided for @poiRatingLabel.
  ///
  /// In de, this message translates to:
  /// **'Bewertung'**
  String get poiRatingLabel;

  /// No description provided for @poiReviews.
  ///
  /// In de, this message translates to:
  /// **'Rezensionen'**
  String get poiReviews;

  /// No description provided for @poiPhotos.
  ///
  /// In de, this message translates to:
  /// **'Fotos'**
  String get poiPhotos;

  /// No description provided for @poiComments.
  ///
  /// In de, this message translates to:
  /// **'Kommentare'**
  String get poiComments;

  /// No description provided for @poiNoReviews.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bewertungen'**
  String get poiNoReviews;

  /// No description provided for @poiNoPhotos.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Fotos'**
  String get poiNoPhotos;

  /// No description provided for @poiNoComments.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Kommentare'**
  String get poiNoComments;

  /// No description provided for @poiBeFirstReview.
  ///
  /// In de, this message translates to:
  /// **'Sei der Erste, der diesen Ort bewertet!'**
  String get poiBeFirstReview;

  /// No description provided for @poiBeFirstPhoto.
  ///
  /// In de, this message translates to:
  /// **'Sei der Erste, der ein Foto teilt!'**
  String get poiBeFirstPhoto;

  /// No description provided for @poiBeFirstComment.
  ///
  /// In de, this message translates to:
  /// **'Schreibe den ersten Kommentar!'**
  String get poiBeFirstComment;

  /// No description provided for @poiReviewCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Bewertungen} =1{1 Bewertung} other{{count} Bewertungen}}'**
  String poiReviewCount(int count);

  /// No description provided for @poiPhotoCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Fotos} =1{1 Foto} other{{count} Fotos}}'**
  String poiPhotoCount(int count);

  /// No description provided for @poiCommentCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Kommentare} =1{1 Kommentar} other{{count} Kommentare}}'**
  String poiCommentCount(int count);

  /// No description provided for @reviewSubmit.
  ///
  /// In de, this message translates to:
  /// **'Bewertung abgeben'**
  String get reviewSubmit;

  /// No description provided for @reviewEdit.
  ///
  /// In de, this message translates to:
  /// **'Bewertung bearbeiten'**
  String get reviewEdit;

  /// No description provided for @reviewYourRating.
  ///
  /// In de, this message translates to:
  /// **'Deine Bewertung'**
  String get reviewYourRating;

  /// No description provided for @reviewWriteOptional.
  ///
  /// In de, this message translates to:
  /// **'Rezension schreiben (optional)'**
  String get reviewWriteOptional;

  /// No description provided for @reviewPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Erzähle anderen von deiner Erfahrung...'**
  String get reviewPlaceholder;

  /// No description provided for @reviewVisitDate.
  ///
  /// In de, this message translates to:
  /// **'Besuchsdatum'**
  String get reviewVisitDate;

  /// No description provided for @reviewVisitDateOptional.
  ///
  /// In de, this message translates to:
  /// **'Besuchsdatum (optional)'**
  String get reviewVisitDateOptional;

  /// No description provided for @reviewVisitedOn.
  ///
  /// In de, this message translates to:
  /// **'Besucht am {date}'**
  String reviewVisitedOn(String date);

  /// No description provided for @reviewHelpful.
  ///
  /// In de, this message translates to:
  /// **'Hilfreich'**
  String get reviewHelpful;

  /// No description provided for @reviewHelpfulCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch nicht bewertet} =1{1 Person fand das hilfreich} other{{count} Personen fanden das hilfreich}}'**
  String reviewHelpfulCount(int count);

  /// No description provided for @reviewMarkedHelpful.
  ///
  /// In de, this message translates to:
  /// **'Als hilfreich markiert'**
  String get reviewMarkedHelpful;

  /// No description provided for @reviewSuccess.
  ///
  /// In de, this message translates to:
  /// **'Bewertung gespeichert!'**
  String get reviewSuccess;

  /// No description provided for @reviewError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern der Bewertung'**
  String get reviewError;

  /// No description provided for @reviewDelete.
  ///
  /// In de, this message translates to:
  /// **'Bewertung löschen'**
  String get reviewDelete;

  /// No description provided for @reviewDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du deine Bewertung wirklich löschen?'**
  String get reviewDeleteConfirm;

  /// No description provided for @reviewDeleteSuccess.
  ///
  /// In de, this message translates to:
  /// **'Bewertung gelöscht'**
  String get reviewDeleteSuccess;

  /// No description provided for @reviewDeleteError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen der Bewertung'**
  String get reviewDeleteError;

  /// No description provided for @reviewRatingRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle eine Sternebewertung'**
  String get reviewRatingRequired;

  /// No description provided for @reviewAvgRating.
  ///
  /// In de, this message translates to:
  /// **'{rating} von 5 Sternen'**
  String reviewAvgRating(String rating);

  /// No description provided for @photoUpload.
  ///
  /// In de, this message translates to:
  /// **'Foto hochladen'**
  String get photoUpload;

  /// No description provided for @photoCaption.
  ///
  /// In de, this message translates to:
  /// **'Bildunterschrift'**
  String get photoCaption;

  /// No description provided for @photoCaptionHint.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe dein Foto (optional)'**
  String get photoCaptionHint;

  /// No description provided for @photoFromCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get photoFromCamera;

  /// No description provided for @photoFromGallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get photoFromGallery;

  /// No description provided for @photoUploading.
  ///
  /// In de, this message translates to:
  /// **'Foto wird hochgeladen...'**
  String get photoUploading;

  /// No description provided for @photoSuccess.
  ///
  /// In de, this message translates to:
  /// **'Foto hochgeladen!'**
  String get photoSuccess;

  /// No description provided for @photoError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Hochladen des Fotos'**
  String get photoError;

  /// No description provided for @photoDelete.
  ///
  /// In de, this message translates to:
  /// **'Foto löschen'**
  String get photoDelete;

  /// No description provided for @photoDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du dieses Foto wirklich löschen?'**
  String get photoDeleteConfirm;

  /// No description provided for @photoDeleteSuccess.
  ///
  /// In de, this message translates to:
  /// **'Foto gelöscht'**
  String get photoDeleteSuccess;

  /// No description provided for @photoDeleteError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen des Fotos'**
  String get photoDeleteError;

  /// No description provided for @photoBy.
  ///
  /// In de, this message translates to:
  /// **'Foto von {author}'**
  String photoBy(String author);

  /// No description provided for @commentAdd.
  ///
  /// In de, this message translates to:
  /// **'Kommentar hinzufügen'**
  String get commentAdd;

  /// No description provided for @commentPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Schreibe einen Kommentar...'**
  String get commentPlaceholder;

  /// No description provided for @commentReply.
  ///
  /// In de, this message translates to:
  /// **'Antworten'**
  String get commentReply;

  /// No description provided for @commentReplyTo.
  ///
  /// In de, this message translates to:
  /// **'Antwort auf {author}'**
  String commentReplyTo(String author);

  /// No description provided for @commentDelete.
  ///
  /// In de, this message translates to:
  /// **'Kommentar löschen'**
  String get commentDelete;

  /// No description provided for @commentDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du diesen Kommentar wirklich löschen?'**
  String get commentDeleteConfirm;

  /// No description provided for @commentDeleteSuccess.
  ///
  /// In de, this message translates to:
  /// **'Kommentar gelöscht'**
  String get commentDeleteSuccess;

  /// No description provided for @commentDeleteError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen des Kommentars'**
  String get commentDeleteError;

  /// No description provided for @commentShowReplies.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Antwort anzeigen} other{{count} Antworten anzeigen}}'**
  String commentShowReplies(int count);

  /// No description provided for @commentHideReplies.
  ///
  /// In de, this message translates to:
  /// **'Antworten ausblenden'**
  String get commentHideReplies;

  /// No description provided for @commentSuccess.
  ///
  /// In de, this message translates to:
  /// **'Kommentar gepostet!'**
  String get commentSuccess;

  /// No description provided for @commentError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Posten des Kommentars'**
  String get commentError;

  /// No description provided for @commentEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte schreibe einen Kommentar'**
  String get commentEmpty;

  /// No description provided for @adminDashboard.
  ///
  /// In de, this message translates to:
  /// **'Admin-Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminNotifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get adminNotifications;

  /// No description provided for @adminModeration.
  ///
  /// In de, this message translates to:
  /// **'Moderation'**
  String get adminModeration;

  /// No description provided for @adminNewPhotos.
  ///
  /// In de, this message translates to:
  /// **'Neue Fotos'**
  String get adminNewPhotos;

  /// No description provided for @adminNewReviews.
  ///
  /// In de, this message translates to:
  /// **'Neue Bewertungen'**
  String get adminNewReviews;

  /// No description provided for @adminNewComments.
  ///
  /// In de, this message translates to:
  /// **'Neue Kommentare'**
  String get adminNewComments;

  /// No description provided for @adminFlaggedContent.
  ///
  /// In de, this message translates to:
  /// **'Gemeldete Inhalte'**
  String get adminFlaggedContent;

  /// No description provided for @adminDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get adminDelete;

  /// No description provided for @adminDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du diesen Inhalt wirklich löschen?'**
  String get adminDeleteConfirm;

  /// No description provided for @adminDeleteSuccess.
  ///
  /// In de, this message translates to:
  /// **'Inhalt gelöscht'**
  String get adminDeleteSuccess;

  /// No description provided for @adminDeleteError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen'**
  String get adminDeleteError;

  /// No description provided for @adminApprove.
  ///
  /// In de, this message translates to:
  /// **'Genehmigen'**
  String get adminApprove;

  /// No description provided for @adminApproveSuccess.
  ///
  /// In de, this message translates to:
  /// **'Inhalt genehmigt'**
  String get adminApproveSuccess;

  /// No description provided for @adminApproveError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Genehmigen'**
  String get adminApproveError;

  /// No description provided for @adminMarkRead.
  ///
  /// In de, this message translates to:
  /// **'Als gelesen markieren'**
  String get adminMarkRead;

  /// No description provided for @adminMarkAllRead.
  ///
  /// In de, this message translates to:
  /// **'Alle als gelesen markieren'**
  String get adminMarkAllRead;

  /// No description provided for @adminNoNotifications.
  ///
  /// In de, this message translates to:
  /// **'Keine neuen Benachrichtigungen'**
  String get adminNoNotifications;

  /// No description provided for @adminNoFlagged.
  ///
  /// In de, this message translates to:
  /// **'Keine gemeldeten Inhalte'**
  String get adminNoFlagged;

  /// No description provided for @adminStats.
  ///
  /// In de, this message translates to:
  /// **'Statistiken'**
  String get adminStats;

  /// No description provided for @adminUnreadCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine ungelesenen} =1{1 ungelesen} other{{count} ungelesen}}'**
  String adminUnreadCount(int count);

  /// No description provided for @adminFlaggedCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine gemeldeten} =1{1 gemeldet} other{{count} gemeldet}}'**
  String adminFlaggedCount(int count);

  /// No description provided for @adminNotificationNewPhoto.
  ///
  /// In de, this message translates to:
  /// **'Neues Foto hochgeladen'**
  String get adminNotificationNewPhoto;

  /// No description provided for @adminNotificationNewReview.
  ///
  /// In de, this message translates to:
  /// **'Neue Bewertung'**
  String get adminNotificationNewReview;

  /// No description provided for @adminNotificationNewComment.
  ///
  /// In de, this message translates to:
  /// **'Neuer Kommentar'**
  String get adminNotificationNewComment;

  /// No description provided for @adminNotificationFlagged.
  ///
  /// In de, this message translates to:
  /// **'Inhalt gemeldet'**
  String get adminNotificationFlagged;

  /// No description provided for @socialLoginRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte melde dich an, um diese Funktion zu nutzen'**
  String get socialLoginRequired;

  /// No description provided for @socialRatingRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle eine Bewertung'**
  String get socialRatingRequired;

  /// No description provided for @reportContent.
  ///
  /// In de, this message translates to:
  /// **'Inhalt melden'**
  String get reportContent;

  /// No description provided for @reportSuccess.
  ///
  /// In de, this message translates to:
  /// **'Vielen Dank! Der Inhalt wurde zur Überprüfung gemeldet.'**
  String get reportSuccess;

  /// No description provided for @reportError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Melden des Inhalts'**
  String get reportError;

  /// No description provided for @reportReason.
  ///
  /// In de, this message translates to:
  /// **'Grund der Meldung'**
  String get reportReason;

  /// No description provided for @reportReasonHint.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe, warum dieser Inhalt gemeldet werden sollte...'**
  String get reportReasonHint;

  /// No description provided for @anonymousUser.
  ///
  /// In de, this message translates to:
  /// **'Anonym'**
  String get anonymousUser;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In de, this message translates to:
  /// **'Fehler'**
  String get error;

  /// No description provided for @success.
  ///
  /// In de, this message translates to:
  /// **'Erfolg'**
  String get success;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
