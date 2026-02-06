// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'MapAB';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get remove => 'Rimuovi';

  @override
  String get retry => 'Riprova';

  @override
  String get close => 'Chiudi';

  @override
  String get back => 'Indietro';

  @override
  String get next => 'Avanti';

  @override
  String get done => 'Fatto';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get or => 'OPPURE';

  @override
  String get edit => 'Modifica';

  @override
  String get loading => 'Caricamento...';

  @override
  String get search => 'Cerca';

  @override
  String get show => 'Mostra';

  @override
  String get apply => 'Applica';

  @override
  String get active => 'Attivo';

  @override
  String get discard => 'Scarta';

  @override
  String get resume => 'Riprendi';

  @override
  String get skip => 'Salta';

  @override
  String get all => 'Tutti';

  @override
  String get total => 'Totale';

  @override
  String get newLabel => 'Nuovo';

  @override
  String get start => 'Partenza';

  @override
  String get destination => 'Destinazione';

  @override
  String get showOnMap => 'Mostra sulla mappa';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get actionCannotBeUndone => 'Questa azione non può essere annullata.';

  @override
  String get details => 'Dettagli';

  @override
  String get generate => 'Genera';

  @override
  String get clear => 'Cancella';

  @override
  String get reset => 'Reimposta';

  @override
  String get end => 'Termina';

  @override
  String get reroll => 'Ricambia';

  @override
  String get filterApply => 'Applica filtro';

  @override
  String get openInGoogleMaps => 'Apri in Google Maps';

  @override
  String get shareLinkCopied => 'Link copiato negli appunti!';

  @override
  String get shareAsText => 'Condividi come testo';

  @override
  String get errorGeneric => 'Si è verificato un errore';

  @override
  String get errorNetwork => 'Nessuna connessione Internet';

  @override
  String get errorNetworkMessage => 'Controlla la tua connessione e riprova.';

  @override
  String get errorServer => 'Server non raggiungibile';

  @override
  String get errorServerMessage => 'Il server non risponde. Riprova più tardi.';

  @override
  String get errorNoResults => 'Nessun risultato';

  @override
  String get errorLocation => 'Posizione non disponibile';

  @override
  String get errorLocationMessage => 'Consenti l\'accesso alla tua posizione.';

  @override
  String get errorPrefix => 'Errore: ';

  @override
  String get pageNotFound => 'Pagina non trovata';

  @override
  String get goToHome => 'Vai alla home';

  @override
  String get errorRouteCalculation => 'Calcolo del percorso fallito. Riprova.';

  @override
  String errorTripGeneration(String error) {
    return 'Generazione del viaggio fallita: $error';
  }

  @override
  String get errorGoogleMapsNotOpened => 'Impossibile aprire Google Maps';

  @override
  String get errorRouteNotShared => 'Impossibile condividere il percorso';

  @override
  String get errorAddingToRoute => 'Errore durante l\'aggiunta';

  @override
  String get errorIncompleteRouteData => 'Dati del percorso incompleti';

  @override
  String get gpsDisabledTitle => 'GPS disabilitato';

  @override
  String get gpsDisabledMessage =>
      'I servizi di localizzazione sono disabilitati. Vuoi aprire le impostazioni GPS?';

  @override
  String get gpsPermissionDenied => 'Permesso GPS negato';

  @override
  String get gpsPermissionDeniedForeverTitle => 'Permesso GPS negato';

  @override
  String get gpsPermissionDeniedForeverMessage =>
      'Il permesso GPS è stato negato in modo permanente. Consenti l\'accesso alla posizione nelle impostazioni dell\'app.';

  @override
  String get gpsCouldNotDetermine => 'Impossibile determinare la posizione GPS';

  @override
  String get appSettingsButton => 'Impostazioni app';

  @override
  String get myLocation => 'La mia posizione';

  @override
  String get authWelcomeTitle => 'Benvenuto su MapAB';

  @override
  String get authWelcomeSubtitle =>
      'Il tuo pianificatore di viaggi AI per itinerari indimenticabili';

  @override
  String get authCloudNotAvailable =>
      'Cloud non disponibile - App compilata senza credenziali Supabase';

  @override
  String get authCloudLoginUnavailable =>
      'Login cloud non disponibile - App compilata senza credenziali Supabase';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailEmpty => 'Inserisci l\'email';

  @override
  String get authEmailInvalid => 'Email non valida';

  @override
  String get authEmailInvalidAddress => 'Indirizzo email non valido';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordEmpty => 'Inserisci la password';

  @override
  String get authPasswordMinLength => 'Minimo 8 caratteri';

  @override
  String get authPasswordRequirements => 'Deve contenere lettere e numeri';

  @override
  String get authPasswordConfirm => 'Conferma password';

  @override
  String get authPasswordMismatch => 'Le password non corrispondono';

  @override
  String get authRememberMe => 'Ricordami';

  @override
  String get authForgotPassword => 'Password dimenticata?';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get authNoAccount => 'Non hai un account? ';

  @override
  String get authRegister => 'Registrati';

  @override
  String get authContinueAsGuest => 'Continua come ospite';

  @override
  String get authGuestInfoCloud =>
      'Come ospite, i tuoi dati verranno salvati solo localmente e non sincronizzati.';

  @override
  String get authGuestInfoLocal =>
      'I tuoi dati verranno salvati localmente sul tuo dispositivo.';

  @override
  String get authCreateAccount => 'Crea account';

  @override
  String get authSecureData => 'Proteggi i tuoi dati nel cloud';

  @override
  String get authNameLabel => 'Nome';

  @override
  String get authNameHint => 'Come vuoi essere chiamato?';

  @override
  String get authNameEmpty => 'Inserisci il nome';

  @override
  String get authNameMinLength => 'Il nome deve avere almeno 2 caratteri';

  @override
  String get authAlreadyHaveAccount => 'Hai già un account? ';

  @override
  String get authExistingAccount => 'Ho già un account';

  @override
  String get authRegistrationSuccess => 'Registrazione completata';

  @override
  String get authRegistrationSuccessMessage =>
      'Controlla la tua email e conferma il tuo account.';

  @override
  String get authResetPassword => 'Reimposta password';

  @override
  String get authResetPasswordInstructions =>
      'Inserisci il tuo indirizzo email e ti invieremo un link per reimpostarla.';

  @override
  String get authSendLink => 'Invia link';

  @override
  String get authBackToLogin => 'Torna al login';

  @override
  String get authEmailSent => 'Email inviata!';

  @override
  String get authEmailSentPrefix => 'Ti abbiamo inviato un\'email a';

  @override
  String get authEmailSentSuffix => '.';

  @override
  String get authResetLinkInstructions =>
      'Clicca sul link nell\'email per impostare una nuova password. Il link è valido per 24 ore.';

  @override
  String get authResend => 'Invia di nuovo';

  @override
  String get authCreateLocalProfile => 'Crea profilo locale';

  @override
  String get authUsernameLabel => 'Nome utente';

  @override
  String get authUsernameHint => 'es. viaggiatore123';

  @override
  String get authDisplayNameLabel => 'Nome visualizzato';

  @override
  String get authDisplayNameHint => 'es. Mario Rossi';

  @override
  String get authEmailOptional => 'Email (opzionale)';

  @override
  String get authEmailHint => 'es. mario@example.com';

  @override
  String get authCreate => 'Crea';

  @override
  String get authRequiredFields =>
      'Nome utente e nome visualizzato sono obbligatori';

  @override
  String get authGuestDescription =>
      'Come ospite puoi iniziare subito. I tuoi dati verranno salvati localmente sul tuo dispositivo.';

  @override
  String get authComingSoon => 'Login cloud in arrivo:';

  @override
  String get authLoadingText => 'Caricamento...';

  @override
  String get splashTagline => 'Il tuo pianificatore di viaggio AI';

  @override
  String get onboardingTitle1 => 'Scopri attrazioni';

  @override
  String get onboardingHighlight1 => 'attrazioni';

  @override
  String get onboardingSubtitle1 =>
      'Trova oltre 500 POI selezionati in tutta Europa.\nCastelli, laghi, musei e gemme nascoste ti aspettano.';

  @override
  String get onboardingTitle2 => 'Il tuo assistente di viaggio AI';

  @override
  String get onboardingHighlight2 => 'AI';

  @override
  String get onboardingSubtitle2 =>
      'Lascia che ti pianifichi automaticamente il percorso perfetto.\nCon ottimizzazione intelligente per i tuoi interessi.';

  @override
  String get onboardingTitle3 => 'I tuoi viaggi nel cloud';

  @override
  String get onboardingHighlight3 => 'Cloud';

  @override
  String get onboardingSubtitle3 =>
      'Salva i preferiti e i viaggi in modo sicuro online.\nSincronizzato su tutti i tuoi dispositivi.';

  @override
  String get onboardingStart => 'Iniziamo';

  @override
  String get categoryCastle => 'Castelli e Fortezze';

  @override
  String get categoryNature => 'Natura e Foreste';

  @override
  String get categoryMuseum => 'Musei';

  @override
  String get categoryViewpoint => 'Punti panoramici';

  @override
  String get categoryLake => 'Laghi';

  @override
  String get categoryCoast => 'Coste e Spiagge';

  @override
  String get categoryPark => 'Parchi e Parchi Nazionali';

  @override
  String get categoryCity => 'Città';

  @override
  String get categoryActivity => 'Attività';

  @override
  String get categoryHotel => 'Hotel';

  @override
  String get categoryRestaurant => 'Ristoranti';

  @override
  String get categoryUnesco => 'Patrimonio UNESCO';

  @override
  String get categoryChurch => 'Chiese';

  @override
  String get categoryMonument => 'Monumenti';

  @override
  String get categoryAttraction => 'Attrazioni';

  @override
  String get weatherGood => 'Buono';

  @override
  String get weatherMixed => 'Variabile';

  @override
  String get weatherBad => 'Brutto';

  @override
  String get weatherDanger => 'Pericoloso';

  @override
  String get weatherUnknown => 'Sconosciuto';

  @override
  String get weatherClear => 'Sereno';

  @override
  String get weatherMostlyClear => 'Prevalentemente sereno';

  @override
  String get weatherPartlyCloudy => 'Parzialmente nuvoloso';

  @override
  String get weatherCloudy => 'Nuvoloso';

  @override
  String get weatherFog => 'Nebbia';

  @override
  String get weatherDrizzle => 'Pioggerella';

  @override
  String get weatherFreezingDrizzle => 'Pioggerella gelata';

  @override
  String get weatherRain => 'Pioggia';

  @override
  String get weatherFreezingRain => 'Pioggia gelata';

  @override
  String get weatherSnow => 'Neve';

  @override
  String get weatherSnowGrains => 'Nevischio';

  @override
  String get weatherRainShowers => 'Rovesci di pioggia';

  @override
  String get weatherSnowShowers => 'Rovesci di neve';

  @override
  String get weatherThunderstorm => 'Temporale';

  @override
  String get weatherThunderstormHail => 'Temporale con grandine';

  @override
  String get weatherForecast7Day => 'Previsioni 7 giorni';

  @override
  String get weatherToday => 'Oggi';

  @override
  String weatherFeelsLike(String temp) {
    return 'Percepiti $temp°';
  }

  @override
  String get weatherSunrise => 'Alba';

  @override
  String get weatherSunset => 'Tramonto';

  @override
  String get weatherUvIndex => 'Indice UV';

  @override
  String get weatherPrecipitation => 'Precipitazioni';

  @override
  String get weatherWind => 'Vento';

  @override
  String get weatherRainRisk => 'Rischio pioggia';

  @override
  String get weatherRecommendationToday => 'Raccomandazione per oggi';

  @override
  String get weatherRecGood =>
      'Tempo perfetto per attività all\'aperto! Consigliati punti panoramici, natura e laghi.';

  @override
  String get weatherRecMixed => 'Variabile - pianifica con flessibilità';

  @override
  String get weatherRecBad =>
      'Pioggia prevista. Consigliate attività al chiuso come musei e chiese.';

  @override
  String get weatherRecDanger =>
      'Allerta maltempo! Evitare attività all\'aperto e rimanere al chiuso.';

  @override
  String get weatherRecUnknown => 'Dati meteo non disponibili.';

  @override
  String weatherUvLow(String value) {
    return '$value (Basso)';
  }

  @override
  String weatherUvMedium(String value) {
    return '$value (Medio)';
  }

  @override
  String weatherUvHigh(String value) {
    return '$value (Alto)';
  }

  @override
  String weatherUvVeryHigh(String value) {
    return '$value (Molto alto)';
  }

  @override
  String weatherUvExtreme(String value) {
    return '$value (Estremo)';
  }

  @override
  String get weatherLoading => 'Caricamento meteo...';

  @override
  String get weatherWinterWeather => 'Tempo invernale';

  @override
  String get weatherStormOnRoute => 'Maltempo sul percorso';

  @override
  String get weatherRainPossible => 'Pioggia possibile';

  @override
  String get weatherGoodWeather => 'Bel tempo';

  @override
  String get weatherChangeable => 'Variabile';

  @override
  String get weatherBadWeather => 'Brutto tempo';

  @override
  String get weatherStormWarning => 'Allerta maltempo';

  @override
  String get weatherPerfect => 'Perfetto';

  @override
  String get weatherStorm => 'Maltempo';

  @override
  String get weatherIdealOutdoor => 'Oggi ideale per POI all\'aperto';

  @override
  String get weatherFlexiblePlanning =>
      'Variabile - pianifica con flessibilità';

  @override
  String get weatherRainIndoor => 'Pioggia - consigliati POI al chiuso';

  @override
  String get weatherStormIndoorOnly => 'Maltempo - solo POI al chiuso!';

  @override
  String get weatherOnlyIndoor => 'Solo POI al chiuso';

  @override
  String weatherStormHighWinds(String speed) {
    return 'Allerta tempesta! Venti forti ($speed km/h) lungo il percorso.';
  }

  @override
  String get weatherStormDelay =>
      'Allerta maltempo! Consigliato posticipare il viaggio.';

  @override
  String get weatherWinterWarning =>
      'Tempo invernale! Possibile neve/ghiaccio.';

  @override
  String get weatherRainRecommendation =>
      'Pioggia prevista. Consigliate attività al chiuso.';

  @override
  String get weatherBadOnRoute => 'Brutto tempo sul percorso.';

  @override
  String get weatherPerfectOutdoor => 'Tempo perfetto per attività all\'aperto';

  @override
  String get weatherBePrepared => 'Variabile - prepararsi a tutto';

  @override
  String get weatherSnowWarning => 'Nevicate - attenzione su strade scivolose';

  @override
  String get weatherBadIndoor =>
      'Brutto tempo - consigliate attività al chiuso';

  @override
  String get weatherStormCaution =>
      'Allerta maltempo! Attenzione su questo tratto';

  @override
  String get weatherNoData => 'Dati meteo non disponibili';

  @override
  String weatherRoutePoint(String index, String total) {
    return 'Punto $index di $total';
  }

  @override
  String weatherExpectedOnDay(String weather, int day) {
    return '$weather previsto il giorno $day';
  }

  @override
  String weatherOutdoorStops(int outdoor, int total) {
    return '$outdoor di $total tappe sono attività all\'aperto.';
  }

  @override
  String get weatherSuggestIndoor => 'Suggerisci alternative al chiuso';

  @override
  String get weatherStormExpected => 'Maltempo previsto';

  @override
  String get weatherRainExpected => 'Pioggia prevista';

  @override
  String get weatherIdealOutdoorWeather => 'Tempo ideale all\'aperto';

  @override
  String get weatherStormIndoorPrefer =>
      'Maltempo previsto – preferire tappe al chiuso';

  @override
  String get weatherRainIndoorHighlight =>
      'Pioggia prevista – tappe al chiuso evidenziate';

  @override
  String get weekdayMon => 'Lun';

  @override
  String get weekdayTue => 'Mar';

  @override
  String get weekdayWed => 'Mer';

  @override
  String get weekdayThu => 'Gio';

  @override
  String get weekdayFri => 'Ven';

  @override
  String get weekdaySat => 'Sab';

  @override
  String get weekdaySun => 'Dom';

  @override
  String get mapFavorites => 'Preferiti';

  @override
  String get mapProfile => 'Profilo';

  @override
  String get mapSettings => 'Impostazioni';

  @override
  String get mapToRoute => 'Al percorso';

  @override
  String get mapSetAsStart => 'Imposta come partenza';

  @override
  String get mapSetAsDestination => 'Imposta come destinazione';

  @override
  String get mapAddAsStop => 'Aggiungi come tappa';

  @override
  String get tripConfigGps => 'GPS';

  @override
  String get tripConfigCityOrAddress => 'Città o indirizzo...';

  @override
  String get tripConfigDestinationOptional => 'Destinazione (opzionale)';

  @override
  String get tripConfigAddDestination => 'Aggiungi destinazione (opzionale)';

  @override
  String get tripConfigEnterDestination => 'Inserisci destinazione...';

  @override
  String get tripConfigNoDestinationRoundtrip =>
      'Senza destinazione: Tour circolare dalla partenza';

  @override
  String get tripConfigSurpriseMe => 'Sorprendimi!';

  @override
  String get tripConfigDeleteRoute => 'Elimina percorso';

  @override
  String get tripConfigTripDuration => 'Durata del viaggio';

  @override
  String get tripConfigDay => 'Giorno';

  @override
  String get tripConfigDays => 'Giorni';

  @override
  String tripConfigDayTrip(String distance) {
    return 'Gita di un giorno — ca. $distance km';
  }

  @override
  String tripConfigWeekendTrip(String distance) {
    return 'Weekend — ca. $distance km';
  }

  @override
  String tripConfigShortVacation(String distance) {
    return 'Breve vacanza — ca. $distance km';
  }

  @override
  String tripConfigWeekTravel(String distance) {
    return 'Viaggio di una settimana — ca. $distance km';
  }

  @override
  String tripConfigEpicEuroTrip(String distance) {
    return 'Epico Euro Trip — ca. $distance km';
  }

  @override
  String get tripConfigRadius => 'Raggio';

  @override
  String get tripConfigPoiCategories => 'Categorie POI';

  @override
  String get tripConfigResetAll => 'Reimposta tutto';

  @override
  String get tripConfigAllCategories => 'Tutte le categorie selezionate';

  @override
  String tripConfigCategoriesSelected(int selected, int total) {
    return '$selected di $total selezionate';
  }

  @override
  String get tripConfigCategories => 'Categorie';

  @override
  String tripConfigSelectedCount(int count) {
    return '$count selezionate';
  }

  @override
  String get tripConfigPoisAlongRoute => 'POI lungo il percorso';

  @override
  String get tripConfigActiveTripTitle => 'Viaggio attivo presente';

  @override
  String tripConfigActiveTripMessage(int days, int completed) {
    return 'Hai un viaggio attivo di $days giorni con $completed giorni completati. Un nuovo viaggio lo sovrascriverà.';
  }

  @override
  String get tripConfigCreateNewTrip => 'Crea nuovo viaggio';

  @override
  String get tripInfoGenerating => 'Generazione del viaggio...';

  @override
  String get tripInfoLoadingPois => 'Caricamento POI, ottimizzazione percorso';

  @override
  String get tripInfoAiEuroTrip => 'AI Euro Trip';

  @override
  String get tripInfoAiDayTrip => 'AI Gita giornaliera';

  @override
  String get tripInfoEditTrip => 'Modifica viaggio';

  @override
  String get tripInfoStartNavigation => 'Avvia navigazione';

  @override
  String get tripInfoStops => 'Tappe';

  @override
  String get tripInfoDistance => 'Distanza';

  @override
  String get tripInfoDaysLabel => 'Giorni';

  @override
  String get activeTripTitle => 'Euro Trip attivo';

  @override
  String get activeTripDiscard => 'Scarta viaggio attivo';

  @override
  String get activeTripDiscardTitle => 'Scartare viaggio?';

  @override
  String activeTripDiscardMessage(int days, int completed) {
    return 'Il tuo viaggio di $days giorni con $completed giorni completati verrà eliminato.';
  }

  @override
  String activeTripDayPending(int day) {
    return 'Giorno $day in programma';
  }

  @override
  String activeTripDaysCompleted(int completed, int total) {
    return '$completed di $total giorni completati';
  }

  @override
  String get tripModeAiDayTrip => 'AI Gita giornaliera';

  @override
  String get tripModeAiEuroTrip => 'AI Euro Trip';

  @override
  String get tripRoutePlanning => 'Pianifica percorso';

  @override
  String get tripNoRoute => 'Nessun percorso disponibile';

  @override
  String get tripTapMap =>
      'Tocca la mappa per impostare partenza e destinazione';

  @override
  String get tripToMap => 'Alla mappa';

  @override
  String get tripGeneratingDescription =>
      'Caricamento POI, ottimizzazione percorso, ricerca hotel';

  @override
  String get tripElevationLoading => 'Caricamento profilo altimetrico...';

  @override
  String get tripSaveRoute => 'Salva percorso';

  @override
  String get tripRouteName => 'Nome del percorso';

  @override
  String get tripExampleDayTrip => 'es. Weekend';

  @override
  String get tripExampleAiDayTrip => 'es. AI Gita giornaliera';

  @override
  String get tripExampleAiEuroTrip => 'es. AI Euro Trip';

  @override
  String tripRouteSaved(String name) {
    return 'Percorso \"$name\" salvato';
  }

  @override
  String get tripYourRoute => 'Il tuo percorso';

  @override
  String get tripDrivingTime => 'Tempo di guida';

  @override
  String get tripStopRemoved => 'Tappa rimossa';

  @override
  String get tripOptimizeRoute => 'Ottimizza percorso';

  @override
  String get tripOptimizeBestOrder => 'Calcola ordine migliore';

  @override
  String get tripShareRoute => 'Condividi percorso';

  @override
  String get tripDeleteAllStops => 'Elimina tutte le tappe';

  @override
  String get tripDeleteEntireRoute => 'Elimina intero percorso';

  @override
  String get tripDeleteRouteAndStops => 'Elimina percorso e tutte le tappe';

  @override
  String get tripConfirmDeleteAllStops => 'Eliminare tutte le tappe?';

  @override
  String get tripConfirmDeleteEntireRoute => 'Eliminare intero percorso?';

  @override
  String get tripDeleteEntireRouteMessage =>
      'Il percorso e tutte le tappe verranno eliminati. Questa azione non può essere annullata.';

  @override
  String get tripBackToConfig => 'Torna alla configurazione';

  @override
  String tripExportDay(int day) {
    return 'Giorno $day in Google Maps';
  }

  @override
  String tripReExportDay(int day) {
    return 'Riesporta giorno $day';
  }

  @override
  String get tripGoogleMapsHint =>
      'Google Maps calcolerà un proprio percorso attraverso le tappe';

  @override
  String tripNoStopsForDay(int day) {
    return 'Nessuna tappa per il giorno $day';
  }

  @override
  String get tripCompleted => 'Viaggio completato!';

  @override
  String tripAllDaysExported(int days) {
    return 'Tutti i $days giorni sono stati esportati con successo. Desideri salvare il viaggio nei preferiti?';
  }

  @override
  String get tripKeep => 'Mantieni';

  @override
  String get tripSaveToFavorites => 'Salva nei preferiti';

  @override
  String get tripShareHeader => 'Il mio percorso con MapAB';

  @override
  String tripShareStart(String address) {
    return 'Partenza: $address';
  }

  @override
  String tripShareEnd(String address) {
    return 'Destinazione: $address';
  }

  @override
  String tripShareDistance(String distance) {
    return 'Distanza: $distance km';
  }

  @override
  String tripShareDuration(String duration) {
    return 'Durata: $duration min';
  }

  @override
  String get tripShareStops => 'Tappe:';

  @override
  String get tripShareOpenMaps => 'Apri in Google Maps:';

  @override
  String get tripMyRoute => 'Il mio percorso';

  @override
  String get tripGoogleMaps => 'Google Maps';

  @override
  String get tripShowInFavorites => 'Visualizza';

  @override
  String get tripGoogleMapsError => 'Impossibile aprire Google Maps';

  @override
  String get tripShareError => 'Impossibile condividere il percorso';

  @override
  String get tripWeatherDangerHint =>
      'Maltempo previsto – preferire tappe al coperto';

  @override
  String get tripWeatherBadHint =>
      'Pioggia prevista – tappe al coperto evidenziate';

  @override
  String get tripStart => 'Partenza';

  @override
  String get tripDestination => 'Destinazione';

  @override
  String get tripNew => 'Nuovo';

  @override
  String get dayEditorTitle => 'Modifica viaggio';

  @override
  String get dayEditorNoTrip => 'Nessun viaggio disponibile';

  @override
  String get dayEditorStartNotAvailable => 'Punto di partenza non disponibile';

  @override
  String dayEditorEditDay(int day) {
    return 'Modifica giorno $day';
  }

  @override
  String get dayEditorRegenerate => 'Rigenera';

  @override
  String dayEditorMaxStops(int max) {
    return 'Max $max tappe al giorno possibili in Google Maps';
  }

  @override
  String get dayEditorSearchRecommendations => 'Cerca raccomandazioni POI...';

  @override
  String get dayEditorLoadRecommendations => 'Carica raccomandazioni POI';

  @override
  String get dayEditorAiRecommendations => 'Raccomandazioni AI';

  @override
  String get dayEditorRecommended => 'Consigliato';

  @override
  String dayEditorAddedToDay(int day) {
    return 'aggiunto al giorno $day';
  }

  @override
  String get dayEditorAllDaysExported =>
      'Tutti i giorni sono stati esportati con successo in Google Maps. Buon viaggio!';

  @override
  String get dayEditorAddPois => 'Aggiungi POI';

  @override
  String dayEditorMyRouteDay(int day) {
    return 'Il mio percorso - Giorno $day con MapAB';
  }

  @override
  String dayEditorMapabRouteDay(int day) {
    return 'Percorso MapAB - Giorno $day';
  }

  @override
  String dayEditorSwapped(String name) {
    return '\"$name\" sostituito';
  }

  @override
  String get corridorTitle => 'POI lungo il percorso';

  @override
  String corridorFound(int total) {
    return '$total trovati';
  }

  @override
  String corridorFoundWithNew(int total, int newCount) {
    return '$total trovati ($newCount nuovi)';
  }

  @override
  String corridorWidth(int km) {
    return 'Corridoio: $km km';
  }

  @override
  String get corridorSearching => 'Ricerca POI nel corridoio...';

  @override
  String get corridorNoPoiInCategory =>
      'Nessun POI trovato in questa categoria';

  @override
  String get corridorNoPois => 'Nessun POI trovato nel corridoio';

  @override
  String get corridorTryWider => 'Prova un corridoio più ampio';

  @override
  String get corridorRemoveStop => 'Rimuovere tappa?';

  @override
  String get corridorMinOneStop => 'Richiesta almeno 1 tappa al giorno';

  @override
  String corridorPoiRemoved(String name) {
    return '\"$name\" rimosso';
  }

  @override
  String get navEndConfirm => 'Terminare navigazione?';

  @override
  String get navDestinationReached => 'Destinazione raggiunta!';

  @override
  String get navDistance => 'Distanza';

  @override
  String get navArrival => 'Arrivo';

  @override
  String get navSpeed => 'Velocità';

  @override
  String get navMuteOn => 'Audio on';

  @override
  String get navMuteOff => 'Audio off';

  @override
  String get navOverview => 'Panoramica';

  @override
  String get navEnd => 'Termina';

  @override
  String get navVoice => 'Voce';

  @override
  String get navVoiceListening => 'Ascolto...';

  @override
  String get navStartButton => 'Avvia navigazione';

  @override
  String get navRerouting => 'Ricalcolo del percorso';

  @override
  String get navVisited => 'Visitato';

  @override
  String navDistanceMeters(String distance) {
    return 'a $distance m';
  }

  @override
  String navDistanceKm(String distance) {
    return 'a $distance km';
  }

  @override
  String get navDepart => 'Parti';

  @override
  String navDepartOn(String street) {
    return 'Parti su $street';
  }

  @override
  String get navArrive => 'Hai raggiunto la tua destinazione';

  @override
  String navArriveAt(String street) {
    return 'Destinazione raggiunta: $street';
  }

  @override
  String navContinueOn(String street) {
    return 'Continua su $street';
  }

  @override
  String get navContinue => 'Continua';

  @override
  String get navTurnRight => 'Svolta a destra';

  @override
  String get navTurnLeft => 'Svolta a sinistra';

  @override
  String navTurnRightOn(String street) {
    return 'Svolta a destra su $street';
  }

  @override
  String navTurnLeftOn(String street) {
    return 'Svolta a sinistra su $street';
  }

  @override
  String get navSlightRight => 'Tieni la destra';

  @override
  String get navSlightLeft => 'Tieni la sinistra';

  @override
  String navSlightRightOn(String street) {
    return 'Tieni la destra su $street';
  }

  @override
  String navSlightLeftOn(String street) {
    return 'Tieni la sinistra su $street';
  }

  @override
  String get navSharpRight => 'Svolta stretta a destra';

  @override
  String get navSharpLeft => 'Svolta stretta a sinistra';

  @override
  String get navUturn => 'Inversione a U';

  @override
  String get navStraight => 'Prosegui dritto';

  @override
  String navStraightOn(String street) {
    return 'Prosegui dritto su $street';
  }

  @override
  String get navMerge => 'Immettiti';

  @override
  String navMergeOn(String street) {
    return 'Immettiti su $street';
  }

  @override
  String get navOnRamp => 'Prendi la rampa';

  @override
  String navOnRampOn(String street) {
    return 'Rampa su $street';
  }

  @override
  String get navOffRamp => 'Prendi l\'uscita';

  @override
  String navOffRampOn(String street) {
    return 'Uscita $street';
  }

  @override
  String navRoundaboutExit(String ordinal) {
    return 'Alla rotonda prendi la $ordinal uscita';
  }

  @override
  String navRoundaboutExitOn(String ordinal, String street) {
    return 'Alla rotonda prendi la $ordinal uscita su $street';
  }

  @override
  String get navRoundaboutEnter => 'Entra nella rotonda';

  @override
  String get navRoundaboutLeave => 'Esci dalla rotonda';

  @override
  String get navForkLeft => 'Al bivio tieni la sinistra';

  @override
  String get navForkRight => 'Al bivio tieni la destra';

  @override
  String navForkLeftOn(String street) {
    return 'Al bivio a sinistra su $street';
  }

  @override
  String navForkRightOn(String street) {
    return 'Al bivio a destra su $street';
  }

  @override
  String get navEndOfRoadLeft => 'Alla fine della strada svolta a sinistra';

  @override
  String get navEndOfRoadRight => 'Alla fine della strada svolta a destra';

  @override
  String navEndOfRoadLeftOn(String street) {
    return 'Alla fine della strada a sinistra su $street';
  }

  @override
  String navEndOfRoadRightOn(String street) {
    return 'Alla fine della strada a destra su $street';
  }

  @override
  String navInDistance(String distance, String instruction) {
    return 'Tra $distance $instruction';
  }

  @override
  String navNow(String instruction) {
    return 'Ora $instruction';
  }

  @override
  String navMeters(String value) {
    return '$value metri';
  }

  @override
  String navKilometers(String value) {
    return '$value chilometri';
  }

  @override
  String get navOrdinalFirst => 'prima';

  @override
  String get navOrdinalSecond => 'seconda';

  @override
  String get navOrdinalThird => 'terza';

  @override
  String get navOrdinalFourth => 'quarta';

  @override
  String get navOrdinalFifth => 'quinta';

  @override
  String get navOrdinalSixth => 'sesta';

  @override
  String get navOrdinalSeventh => 'settima';

  @override
  String get navOrdinalEighth => 'ottava';

  @override
  String navSharpRightOn(String street) {
    return 'Svolta stretta a destra su $street';
  }

  @override
  String navSharpLeftOn(String street) {
    return 'Svolta stretta a sinistra su $street';
  }

  @override
  String navUturnOn(String street) {
    return 'Inversione a U su $street';
  }

  @override
  String get navTurn => 'Svolta';

  @override
  String navTurnOn(String street) {
    return 'Svolta su $street';
  }

  @override
  String get navForkStraight => 'Prosegui al bivio';

  @override
  String navForkStraightOn(String street) {
    return 'Prosegui al bivio su $street';
  }

  @override
  String get navEndOfRoadStraight => 'Prosegui alla fine della strada';

  @override
  String navEndOfRoadStraightOn(String street) {
    return 'Prosegui alla fine della strada su $street';
  }

  @override
  String navRoundaboutLeaveOn(String street) {
    return 'Esci dalla rotonda su $street';
  }

  @override
  String navRoundaboutEnterOn(String street) {
    return 'Entra nella rotonda su $street';
  }

  @override
  String get navStraightContinue => 'Prosegui dritto';

  @override
  String get navDirectionLeft => 'A sinistra ';

  @override
  String get navDirectionRight => 'A destra ';

  @override
  String get navSharpRightShort => 'Stretta a destra';

  @override
  String get navRightShort => 'Destra';

  @override
  String get navSlightRightShort => 'Leggermente a destra';

  @override
  String get navStraightShort => 'Dritto';

  @override
  String get navSlightLeftShort => 'Leggermente a sinistra';

  @override
  String get navLeftShort => 'Sinistra';

  @override
  String get navSharpLeftShort => 'Stretta a sinistra';

  @override
  String get navKeepLeft => 'Tieni la sinistra';

  @override
  String get navKeepRight => 'Tieni la destra';

  @override
  String get navRoundabout => 'Rotonda';

  @override
  String navExitShort(String ordinal) {
    return '$ordinal uscita';
  }

  @override
  String get navMustSeeStop => 'Fermata';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsDesign => 'Design';

  @override
  String get settingsAutoDarkMode => 'Modalità scura automatica';

  @override
  String get settingsAutoDarkModeDesc => 'Attiva automaticamente al tramonto';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsHaptic => 'Feedback aptico';

  @override
  String get settingsHapticDesc => 'Vibrazioni nelle interazioni';

  @override
  String get settingsSound => 'Effetti sonori';

  @override
  String get settingsSoundDesc => 'Suoni nelle azioni';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsAppVersion => 'Versione app';

  @override
  String get settingsLicenses => 'Licenze Open Source';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsThemeOled => 'OLED Nero';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get profileEdit => 'Modifica profilo';

  @override
  String get profileCloudAccount => 'Account cloud';

  @override
  String get profileAutoSync => 'Dati sincronizzati automaticamente';

  @override
  String get profileGuestAccount => 'Account ospite';

  @override
  String get profileLocalStorage => 'Salvato localmente';

  @override
  String get profileUpgradeToCloud => 'Passa ad account cloud';

  @override
  String get profileDeleteAccount => 'Elimina account';

  @override
  String get profileNoAccount => 'Nessun account';

  @override
  String get profileLoginPrompt => 'Accedi per vedere il tuo profilo';

  @override
  String get profileLogin => 'Accedi';

  @override
  String profileLevel(int level) {
    return 'Livello $level';
  }

  @override
  String profileXpProgress(int xp, int level) {
    return 'Ancora $xp XP al livello $level';
  }

  @override
  String get profileStatistics => 'Statistiche';

  @override
  String get profileStatisticsLoading => 'Caricamento statistiche...';

  @override
  String get profileStartFirstTrip =>
      'Inizia il tuo primo viaggio per vedere le statistiche!';

  @override
  String get profileTrips => 'Viaggi';

  @override
  String get profilePois => 'POI';

  @override
  String get profileKilometers => 'Chilometri';

  @override
  String get profileAchievements => 'Obiettivi';

  @override
  String get profileNoAchievements =>
      'Nessun obiettivo sbloccato. Inizia il tuo primo viaggio!';

  @override
  String profileAccountId(String id) {
    return 'ID account: $id';
  }

  @override
  String profileCreatedAt(String date) {
    return 'Creato il: $date';
  }

  @override
  String profileLastLogin(String date) {
    return 'Ultimo accesso: $date';
  }

  @override
  String get profileEditComingSoon => 'Modifica profilo in arrivo!';

  @override
  String get profileLogoutTitle => 'Disconnettersi?';

  @override
  String get profileLogoutMessage => 'Vuoi davvero disconnetterti?';

  @override
  String get profileLogoutCloudMessage =>
      'Vuoi davvero disconnetterti?\n\nI tuoi dati cloud rimarranno salvati e potrai accedere di nuovo in qualsiasi momento.';

  @override
  String get profileLogout => 'Disconnetti';

  @override
  String get profileDeleteTitle => 'Eliminare account?';

  @override
  String get profileDeleteMessage =>
      'Vuoi davvero eliminare il tuo account? Tutti i dati verranno eliminati in modo permanente!';

  @override
  String get favTitle => 'Preferiti';

  @override
  String get favRoutes => 'Percorsi';

  @override
  String get favPois => 'POI';

  @override
  String get favDeleteAll => 'Elimina tutto';

  @override
  String get favNoFavorites => 'Nessun preferito';

  @override
  String get favNoFavoritesDesc => 'Salva percorsi e POI per un accesso rapido';

  @override
  String get favExplore => 'Esplora';

  @override
  String get favNoRoutes => 'Nessun percorso salvato';

  @override
  String get favPlanRoute => 'Pianifica percorso';

  @override
  String get favNoPois => 'Nessun POI preferito';

  @override
  String get favDiscoverPois => 'Scopri POI';

  @override
  String get favRemoveRoute => 'Rimuovere percorso?';

  @override
  String favRemoveRouteConfirm(String name) {
    return 'Vuoi rimuovere \"$name\" dai preferiti?';
  }

  @override
  String get favRemovePoi => 'Rimuovere POI?';

  @override
  String favRemovePoiConfirm(String name) {
    return 'Vuoi rimuovere \"$name\" dai preferiti?';
  }

  @override
  String get favRouteLoaded => 'Percorso caricato';

  @override
  String get favRouteRemoved => 'Percorso rimosso';

  @override
  String get favPoiRemoved => 'POI rimosso';

  @override
  String get favClearAll => 'Eliminare tutti i preferiti?';

  @override
  String get favAllDeleted => 'Tutti i preferiti eliminati';

  @override
  String get poiSearchHint => 'Cerca POI...';

  @override
  String get poiClearFilters => 'Cancella filtri';

  @override
  String get poiResetFilters => 'Reimposta filtri';

  @override
  String get poiLoading => 'Caricamento attrazioni...';

  @override
  String get poiNotFound => 'POI non trovato';

  @override
  String get poiLoadingDetails => 'Caricamento dettagli...';

  @override
  String get poiMoreOnWikipedia => 'Altro su Wikipedia';

  @override
  String get poiOpeningHours => 'Orari di apertura';

  @override
  String poiRouteCreated(String name) {
    return 'Percorso a \"$name\" creato';
  }

  @override
  String get poiOnlyMustSee => 'Solo Must-See';

  @override
  String get poiShowOnlyHighlights => 'Mostra solo highlights';

  @override
  String get poiOnlyIndoor => 'Solo POI al chiuso';

  @override
  String get poiApplyFilters => 'Applica filtri';

  @override
  String get poiReroll => 'Rigenera';

  @override
  String get poiTitle => 'Attrazioni';

  @override
  String get poiMustSee => 'Da vedere';

  @override
  String get poiWeatherTip => 'Consiglio meteo';

  @override
  String poiResultsCount(int filtered, int total) {
    return '$filtered di $total POI';
  }

  @override
  String get poiNoResultsFilter => 'Nessun POI trovato con questi filtri';

  @override
  String get poiNoResultsNearby => 'Nessun POI trovato nelle vicinanze';

  @override
  String get poiGpsPermissionNeeded =>
      'Permesso GPS necessario per trovare POI nelle vicinanze';

  @override
  String get poiWeatherDangerBanner =>
      'Tempesta prevista – POI interni consigliati';

  @override
  String get poiWeatherBadBanner =>
      'Pioggia prevista – attiva \"Consiglio meteo\" per un ordinamento migliore';

  @override
  String get poiAboutPlace => 'Informazioni sul luogo';

  @override
  String get poiNoDescription => 'Nessuna descrizione disponibile.';

  @override
  String get poiDescriptionLoading => 'Caricamento descrizione...';

  @override
  String get poiContactInfo => 'Contatto & Info';

  @override
  String get poiPhone => 'Telefono';

  @override
  String get poiWebsite => 'Sito web';

  @override
  String get poiEmailLabel => 'E-mail';

  @override
  String get poiDetour => 'Deviazione';

  @override
  String get poiTime => 'Tempo';

  @override
  String get poiPosition => 'Posizione';

  @override
  String get poiCurated => 'Selezionato';

  @override
  String get poiVerified => 'Verificato';

  @override
  String poiAddedToRoute(String name) {
    return '$name aggiunto al percorso';
  }

  @override
  String poiFoundedYear(int year) {
    return 'Fondato nel $year';
  }

  @override
  String poiRating(String rating, int count) {
    return '$rating su 5 ($count recensioni)';
  }

  @override
  String get poiAddToRoute => 'Aggiungi al percorso';

  @override
  String get scanTitle => 'Scansiona trip';

  @override
  String get scanInstruction => 'Scansiona QR code';

  @override
  String get scanDescription =>
      'Tieni il telefono su un QR code MapAB per importare un trip condiviso.';

  @override
  String get scanLoading => 'Caricamento trip...';

  @override
  String get scanInvalidCode => 'QR code non valido';

  @override
  String get scanInvalidMapabCode => 'QR code MapAB non valido';

  @override
  String get scanLoadError => 'Impossibile caricare il trip';

  @override
  String get scanTripFound => 'Trip trovato!';

  @override
  String scanStops(int count) {
    return '$count tappe';
  }

  @override
  String scanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get scanImportQuestion => 'Vuoi importare questo trip?';

  @override
  String get scanImport => 'Importa';

  @override
  String scanImportSuccess(String name) {
    return '$name è stato importato!';
  }

  @override
  String get scanImportError => 'Impossibile importare il trip';

  @override
  String get templatesTitle => 'Modelli di viaggio';

  @override
  String get templatesScanQr => 'Scansiona QR code';

  @override
  String get templatesAudienceAll => 'Tutti';

  @override
  String get templatesAudienceCouples => 'Coppie';

  @override
  String get templatesAudienceFamilies => 'Famiglie';

  @override
  String get templatesAudienceAdventurers => 'Avventurieri';

  @override
  String get templatesAudienceFoodies => 'Buongustai';

  @override
  String get templatesAudiencePhotographers => 'Fotografi';

  @override
  String templatesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String templatesCategories(int count) {
    return '$count categorie';
  }

  @override
  String get templatesIncludedCategories => 'Categorie incluse';

  @override
  String get templatesDuration => 'Durata del viaggio';

  @override
  String templatesRecommended(int days, String daysText) {
    return 'Consigliato: $days $daysText';
  }

  @override
  String templatesBestSeason(String season) {
    return 'Stagione migliore: $season';
  }

  @override
  String get templatesStartPlanning => 'Pianifica viaggio';

  @override
  String get seasonSpring => 'Primavera';

  @override
  String get seasonSummer => 'Estate';

  @override
  String get seasonAutumn => 'Autunno';

  @override
  String get seasonWinter => 'Inverno';

  @override
  String get seasonSpringAutumn => 'Primavera ad autunno';

  @override
  String get seasonYearRound => 'Tutto l\'anno';

  @override
  String get day => 'giorno';

  @override
  String get days => 'giorni';

  @override
  String get searchSelectStart => 'Seleziona partenza';

  @override
  String get searchSelectDestination => 'Seleziona destinazione';

  @override
  String get searchStartHint => 'Cerca punto di partenza...';

  @override
  String get searchDestinationHint => 'Cerca destinazione...';

  @override
  String get searchOfflineMode =>
      'Nessuna Internet - Mostra suggerimenti locali';

  @override
  String get searchEnterLocation => 'Inserisci luogo per cercare';

  @override
  String get searchNoResults => 'Nessun risultato trovato';

  @override
  String get searchLocationNotFound => 'Impossibile trovare la posizione';

  @override
  String get chatTitle => 'Assistente AI';

  @override
  String get chatClear => 'Cancella chat';

  @override
  String get chatWelcome =>
      'Ciao! Sono il tuo assistente di viaggio AI. Come posso aiutarti nella pianificazione?';

  @override
  String get chatInputHint => 'Scrivi un messaggio...';

  @override
  String get chatClearConfirm => 'Cancellare chat?';

  @override
  String get chatClearMessage => 'L\'intera conversazione verrà eliminata.';

  @override
  String get chatCheckAgain => 'Controlla di nuovo';

  @override
  String get chatAccept => 'Accetta';

  @override
  String chatShowAllPois(int count) {
    return 'Mostra tutti i POI';
  }

  @override
  String get chatDestinationOptional => 'Destinazione (opzionale)';

  @override
  String get chatEmptyRandomRoute =>
      'Vuoto = Percorso casuale attorno alla partenza';

  @override
  String get chatStartOptional => 'Punto di partenza (opzionale)';

  @override
  String get chatEmptyUseGps => 'Vuoto = Usa posizione GPS';

  @override
  String get chatIndoorTips => 'Consigli al chiuso in caso di pioggia';

  @override
  String get chatPoisNearMe => 'POI vicino a me';

  @override
  String get chatAttractions => 'Attrazioni';

  @override
  String get chatRestaurants => 'Ristoranti';

  @override
  String get chatOutdoorHighlights => 'Highlights all\'aperto';

  @override
  String get chatNatureParks => 'Natura e Parchi';

  @override
  String get chatSearchRadius => 'Raggio di ricerca';

  @override
  String get chatGenerateAiTrip => 'Genera viaggio AI';

  @override
  String get randomTripNoTrip => 'Nessun viaggio generato';

  @override
  String get randomTripRegenerate => 'Rigenera';

  @override
  String get randomTripConfirm => 'Conferma viaggio';

  @override
  String randomTripStopsDay(int day) {
    return 'Tappe (Giorno $day)';
  }

  @override
  String get randomTripStops => 'Tappe';

  @override
  String get randomTripEnterAddress => 'Inserisci città o indirizzo...';

  @override
  String get randomTripShowDetails => 'Mostra dettagli';

  @override
  String get randomTripOpenGoogleMaps => 'Apri in Google Maps';

  @override
  String get randomTripSave => 'Salva viaggio';

  @override
  String get randomTripShow => 'Mostra viaggio';

  @override
  String get randomTripBack => 'Indietro';

  @override
  String get mapModeAiDayTrip => 'AI Gita';

  @override
  String get mapModeAiEuroTrip => 'AI Euro Trip';

  @override
  String get travelDuration => 'Durata del viaggio';

  @override
  String get radiusLabel => 'Raggio';

  @override
  String get categoriesLabel => 'Categorie';

  @override
  String tripDescDayTrip(int radius) {
    return 'Gita giornaliera — ca. $radius km';
  }

  @override
  String tripDescWeekend(int radius) {
    return 'Fine settimana — ca. $radius km';
  }

  @override
  String tripDescShortVacation(int radius) {
    return 'Vacanza breve — ca. $radius km';
  }

  @override
  String tripDescWeekTrip(int radius) {
    return 'Viaggio settimanale — ca. $radius km';
  }

  @override
  String tripDescEpic(int radius) {
    return 'Epico Euro Trip — ca. $radius km';
  }

  @override
  String selectedCount(int count) {
    return '$count selezionati';
  }

  @override
  String get destinationOptional => 'Destinazione (opzionale)';

  @override
  String get enterDestination => 'Inserisci destinazione...';

  @override
  String get mapCityOrAddress => 'Città o indirizzo...';

  @override
  String get mapAddDestination => 'Aggiungi destinazione (opzionale)';

  @override
  String get mapSurpriseMe => 'Sorprendimi!';

  @override
  String get mapDeleteRoute => 'Elimina percorso';

  @override
  String mapDaysLabel(String days) {
    return '$days giorni';
  }

  @override
  String get mapPoiCategories => 'Categorie POI';

  @override
  String get mapResetAll => 'Ripristina tutto';

  @override
  String get mapAllCategoriesSelected => 'Tutte le categorie selezionate';

  @override
  String mapCategoriesSelected(String count, String total) {
    return '$count di $total selezionate';
  }

  @override
  String get mapPoisAlongRoute => 'POI lungo il percorso';

  @override
  String get mapWithoutDestination =>
      'Senza destinazione: viaggio circolare dalla partenza';

  @override
  String get tripTypeDayTrip => 'Gita giornaliera';

  @override
  String get tripTypeEuroTrip => 'Euro Trip';

  @override
  String get tripTypeMultiDay => 'Viaggio di più giorni';

  @override
  String get tripTypeScenic => 'Percorso panoramico';

  @override
  String get tripTypeDayTripDistance => '30-200 km';

  @override
  String get tripTypeEuroTripDistance => '200-800 km';

  @override
  String get tripTypeMultiDayDistance => '2-7 giorni';

  @override
  String get tripTypeScenicDistance => 'variabile';

  @override
  String get tripTypeDayTripDesc => 'Selezione attività, basato sul meteo';

  @override
  String get tripTypeEuroTripDesc => 'Altro paese, suggerimenti hotel';

  @override
  String get tripTypeMultiDayDesc => 'Tappe pernottamento automatiche';

  @override
  String get tripTypeScenicDesc => 'Punti panoramici prioritari';

  @override
  String get accessWheelchair => 'Accessibile in sedia a rotelle';

  @override
  String get accessNoStairs => 'Senza scale';

  @override
  String get accessParking => 'Parcheggio per disabili';

  @override
  String get accessToilet => 'Bagno per disabili';

  @override
  String get accessElevator => 'Ascensore presente';

  @override
  String get accessBraille => 'Braille';

  @override
  String get accessAudioGuide => 'Audio guida';

  @override
  String get accessSignLanguage => 'Lingua dei segni';

  @override
  String get accessAssistDogs => 'Cani guida ammessi';

  @override
  String get accessFullyAccessible => 'Completamente accessibile';

  @override
  String get accessLimited => 'Accesso limitato';

  @override
  String get accessNotAccessible => 'Non accessibile';

  @override
  String get accessUnknown => 'Sconosciuto';

  @override
  String get highlightUnesco => 'Patrimonio UNESCO';

  @override
  String get highlightMustSee => 'Must-See';

  @override
  String get highlightSecret => 'Gemma nascosta';

  @override
  String get highlightHistoric => 'Storico';

  @override
  String get highlightFamilyFriendly => 'Adatto alle famiglie';

  @override
  String experienceDetourKm(int km) {
    return '+$km km di deviazione';
  }

  @override
  String get formatMinShort => 'min';

  @override
  String get formatHourShort => 'h';

  @override
  String get formatMinLong => 'minuti';

  @override
  String formatHourLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ore',
      one: 'ora',
    );
    return '$_temp0';
  }

  @override
  String formatDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String formatStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tappe',
      one: '1 tappa',
    );
    return '$_temp0';
  }

  @override
  String get formatNoInfo => 'Nessuna informazione';

  @override
  String get formatJustNow => 'Proprio ora';

  @override
  String formatAgoMinutes(int count) {
    return '$count min fa';
  }

  @override
  String formatAgoHours(int count) {
    return '$count h fa';
  }

  @override
  String formatAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get formatUnknown => 'Sconosciuto';

  @override
  String get journalTitle => 'Diario di viaggio';

  @override
  String get journalEmptyTitle => 'Nessuna voce';

  @override
  String get journalEmptySubtitle =>
      'Cattura i tuoi ricordi di viaggio con foto e note.';

  @override
  String get journalAddEntry => 'Aggiungi voce';

  @override
  String get journalAddFirstEntry => 'Crea prima voce';

  @override
  String get journalNewEntry => 'Nuova voce';

  @override
  String get journalAddPhoto => 'Aggiungi foto';

  @override
  String get journalCamera => 'Fotocamera';

  @override
  String get journalGallery => 'Galleria';

  @override
  String get journalAddNote => 'Aggiungi nota';

  @override
  String get journalNoteHint => 'Cosa hai vissuto?';

  @override
  String get journalSaveNote => 'Salva solo nota';

  @override
  String get journalSaveLocation => 'Salva posizione';

  @override
  String get journalLocationAvailable => 'Posizione GPS disponibile';

  @override
  String get journalLocationLoading => 'Caricamento posizione...';

  @override
  String get journalEnterNote => 'Inserisci una nota';

  @override
  String get journalDeleteEntryTitle => 'Eliminare la voce?';

  @override
  String get journalDeleteEntryMessage =>
      'Questa voce verrà eliminata definitivamente.';

  @override
  String get journalDeleteTitle => 'Eliminare il diario?';

  @override
  String get journalDeleteMessage =>
      'Tutte le voci e le foto verranno eliminate definitivamente.';

  @override
  String journalPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '1 foto',
      zero: 'Nessuna foto',
    );
    return '$_temp0';
  }

  @override
  String journalEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voci',
      one: '1 voce',
      zero: 'Nessuna voce',
    );
    return '$_temp0';
  }

  @override
  String journalDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String journalDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String journalDayNumber(int day) {
    return 'Giorno $day';
  }

  @override
  String get journalOther => 'Altro';

  @override
  String get journalEntry => 'voce';

  @override
  String get journalEntriesPlural => 'voci';

  @override
  String get journalOpenJournal => 'Apri diario';

  @override
  String get journalAllJournals => 'Tutti i diari';

  @override
  String get journalNoJournals => 'Nessun diario ancora';

  @override
  String get galleryTitle => 'Galleria trip';

  @override
  String get gallerySearch => 'Cerca trip...';

  @override
  String get galleryFeatured => 'In evidenza';

  @override
  String get galleryAllTrips => 'Tutti i trip';

  @override
  String get galleryNoTrips => 'Nessun trip trovato';

  @override
  String get galleryResetFilters => 'Reimposta filtri';

  @override
  String get galleryFilter => 'Filtra';

  @override
  String get galleryFilterReset => 'Reimposta';

  @override
  String get galleryTripType => 'Tipo di trip';

  @override
  String get galleryTags => 'Tag';

  @override
  String get gallerySort => 'Ordina per';

  @override
  String get gallerySortPopular => 'Popolare';

  @override
  String get gallerySortRecent => 'Recente';

  @override
  String get gallerySortLikes => 'Più mi piace';

  @override
  String get galleryTypeAll => 'Tutti';

  @override
  String get galleryTypeDaytrip => 'Gita giornaliera';

  @override
  String get galleryTypeEurotrip => 'Euro Trip';

  @override
  String get galleryRetry => 'Riprova';

  @override
  String galleryLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mi piace',
      one: '1 mi piace',
      zero: 'Nessun mi piace',
    );
    return '$_temp0';
  }

  @override
  String galleryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visualizzazioni',
      one: '1 visualizzazione',
    );
    return '$_temp0';
  }

  @override
  String galleryImports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count importazioni',
      one: '1 importazione',
    );
    return '$_temp0';
  }

  @override
  String gallerySharedAt(String date) {
    return 'Condiviso il $date';
  }

  @override
  String galleryTripsShared(int count) {
    return '$count trip condivisi';
  }

  @override
  String get galleryImportToFavorites => 'Aggiungi ai preferiti';

  @override
  String get galleryImported => 'Importato';

  @override
  String get galleryShowOnMap => 'Sulla mappa';

  @override
  String get galleryShareComingSoon => 'Condivisione in arrivo';

  @override
  String get galleryMapComingSoon => 'Vista mappa in arrivo';

  @override
  String get galleryMapNoData => 'Nessun dato del percorso disponibile';

  @override
  String get galleryMapError => 'Errore durante il caricamento del percorso';

  @override
  String get galleryImportSuccess => 'Trip aggiunto ai preferiti';

  @override
  String get galleryImportError => 'Importazione fallita';

  @override
  String get galleryTripNotFound => 'Trip non trovato';

  @override
  String get galleryLoadError => 'Errore di caricamento';

  @override
  String get publishTitle => 'Pubblica trip';

  @override
  String get publishSubtitle => 'Condividi il tuo trip con la community';

  @override
  String get publishTripName => 'Nome del trip';

  @override
  String get publishTripNameHint => 'es. Road trip Sud della Francia';

  @override
  String get publishTripNameRequired => 'Inserisci un nome';

  @override
  String get publishTripNameMinLength =>
      'Il nome deve avere almeno 3 caratteri';

  @override
  String get publishDescription => 'Descrizione (opzionale)';

  @override
  String get publishDescriptionHint => 'Racconta il tuo trip agli altri...';

  @override
  String get publishTags => 'Tag (opzionale)';

  @override
  String get publishTagsHelper => 'Aiuta gli altri a trovare il tuo trip';

  @override
  String get publishMaxTags => 'Massimo 5 tag';

  @override
  String get publishInfo =>
      'Il tuo trip sarà visibile pubblicamente. Gli altri possono mettere mi piace e importarlo nei loro preferiti.';

  @override
  String get publishButton => 'Pubblica';

  @override
  String get publishPublishing => 'Pubblicazione in corso...';

  @override
  String get publishSuccess => 'Trip pubblicato!';

  @override
  String get publishError => 'Pubblicazione fallita';

  @override
  String get tripPublish => 'Pubblica trip';

  @override
  String get tripPublishDescription => 'Condividi nella galleria pubblica';

  @override
  String get publishEuroTrip => 'Euro Trip';

  @override
  String get publishDaytrip => 'Gita giornaliera';

  @override
  String get dayEditorDriveTime => 'Tempo di guida';

  @override
  String get dayEditorWeather => 'Meteo';

  @override
  String get dayEditorDay => 'Giorno';

  @override
  String dayEditorNoStopsForDay(int day) {
    return 'Nessuna tappa per il giorno $day';
  }

  @override
  String dayEditorDayInGoogleMaps(int day) {
    return 'Giorno $day in Google Maps';
  }

  @override
  String dayEditorOpenAgain(int day) {
    return 'Riaprire giorno $day';
  }

  @override
  String get dayEditorTripCompleted => 'Trip completato!';

  @override
  String get dayEditorRouteShare => 'Condividi percorso';

  @override
  String get dayEditorRouteShareError => 'Impossibile condividere il percorso';

  @override
  String get dayEditorShareStops => 'Tappe';

  @override
  String get dayEditorShareOpenGoogleMaps => 'Apri in Google Maps';

  @override
  String get tripSummaryTotal => 'Totale';

  @override
  String get tripSummaryDriveTime => 'Tempo di guida';

  @override
  String get tripSummaryStops => 'Tappe';

  @override
  String get filterTitle => 'Filtri';

  @override
  String get filterMaxDetour => 'Deviazione massima';

  @override
  String get filterMaxDetourHint =>
      'I POI con deviazione maggiore saranno nascosti';

  @override
  String get filterAllCategories => 'Mostra tutte le categorie';

  @override
  String filterSelectedCount(int count) {
    return '$count selezionate';
  }

  @override
  String get filterCategoriesLabel => 'Categorie';

  @override
  String get categorySelectorDeselectAll => 'Deseleziona tutto';

  @override
  String get categorySelectorNoneHint =>
      'Nessuna selezione = tutte le categorie';

  @override
  String categorySelectorSelectedCount(int count) {
    return '$count selezionate';
  }

  @override
  String get categorySelectorTitle => 'Categorie';

  @override
  String get startLocationLabel => 'Punto di partenza';

  @override
  String get startLocationHint => 'Inserisci città o indirizzo...';

  @override
  String get startLocationGps => 'Usa posizione GPS';

  @override
  String get tripPreviewNoTrip => 'Nessun trip generato';

  @override
  String get tripPreviewYourTrip => 'Il tuo Trip';

  @override
  String get tripPreviewConfirm => 'Conferma trip';

  @override
  String tripPreviewMaxStopsWarning(int max) {
    return 'Max $max tappe al giorno (limite Google Maps)';
  }

  @override
  String tripPreviewStopsDay(int day) {
    return 'Tappe (Giorno $day)';
  }

  @override
  String tripPreviewDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Giorni',
      one: 'Giorno',
    );
    return '$_temp0';
  }

  @override
  String get navSkip => 'Salta';

  @override
  String get navVisitedButton => 'Visitato';

  @override
  String navDistanceAway(String distance) {
    return 'a $distance';
  }

  @override
  String get chatDemoMode => 'Modalità demo: le risposte sono simulate';

  @override
  String get chatLocationLoading => 'Caricamento posizione...';

  @override
  String get chatLocationActive => 'Posizione attiva';

  @override
  String get chatLocationEnable => 'Attiva posizione';

  @override
  String get chatMyLocation => 'La mia posizione';

  @override
  String get chatRadiusTooltip => 'Raggio di ricerca';

  @override
  String get chatNoPoisFound => 'Nessun POI trovato nelle vicinanze';

  @override
  String chatPoisInRadius(int count, String radius) {
    return '$count POI nel raggio di $radius km';
  }

  @override
  String chatRadiusLabel(String radius) {
    return '$radius km';
  }

  @override
  String get chatWelcomeSubtitle => 'Chiedimi tutto sul tuo viaggio!';

  @override
  String get chatDemoBackendNotReachable =>
      'Modalità demo: Backend non raggiungibile';

  @override
  String get chatDemoBackendNotConfigured =>
      'Modalità demo: URL del backend non configurato';

  @override
  String get chatNumberOfDays => 'Numero di giorni';

  @override
  String get chatInterests => 'Interessi:';

  @override
  String get chatLocationNotAvailable => 'Posizione non disponibile';

  @override
  String get chatLocationNotAvailableMessage =>
      'Per trovare POI vicino a te, ho bisogno di accedere alla tua posizione.\n\nAttiva i servizi di localizzazione e riprova.';

  @override
  String get chatPoisSearchError => 'Errore nella ricerca POI';

  @override
  String get chatPoisSearchErrorMessage =>
      'Mi dispiace, si è verificato un problema nel caricamento dei POI.\n\nRiprova.';

  @override
  String get chatNoResponseGenerated =>
      'Mi dispiace, non sono riuscito a generare una risposta.';

  @override
  String get chatRadiusAdjust => 'Regola il raggio di ricerca';

  @override
  String get voiceRerouting => 'Ricalcolo del percorso';

  @override
  String voicePOIApproaching(String name, String distance) {
    return '$name tra $distance';
  }

  @override
  String voiceArrivedAt(String name) {
    return 'Sei arrivato a: $name';
  }

  @override
  String voiceRouteInfo(String distance, String duration) {
    return 'Ancora $distance e $duration fino alla destinazione';
  }

  @override
  String voiceNextStop(String name, String distance) {
    return 'Prossima tappa: $name tra $distance';
  }

  @override
  String voiceCurrentLocation(String location) {
    return 'Posizione attuale: $location';
  }

  @override
  String voiceInMeters(int meters) {
    return '$meters metri';
  }

  @override
  String voiceInKilometers(String km) {
    return '$km chilometri';
  }

  @override
  String voiceHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String voiceMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String voiceStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tappe',
      one: '1 tappa',
    );
    return '$_temp0';
  }

  @override
  String get voiceCmdNextStop => 'Prossima tappa';

  @override
  String get voiceCmdLocation => 'Dove sono';

  @override
  String get voiceCmdDuration => 'Quanto manca';

  @override
  String get voiceCmdEndNavigation => 'Termina navigazione';

  @override
  String get voiceNow => 'Adesso';

  @override
  String get voiceArrived => 'Sei arrivato a destinazione';

  @override
  String voicePOIReached(String name) {
    return '$name raggiunto';
  }

  @override
  String voiceCategory(String category) {
    return 'Categoria: $category';
  }

  @override
  String voiceDistanceMeters(int meters) {
    return 'a $meters metri';
  }

  @override
  String voiceDistanceKm(String km) {
    return 'a $km chilometri';
  }

  @override
  String voiceRouteLength(String distance, String duration, String stops) {
    return 'Il tuo percorso è lungo $distance chilometri, dura circa $duration e ha $stops.';
  }

  @override
  String voiceAndMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti',
      one: '1 minuto',
    );
    return 'e $_temp0';
  }

  @override
  String get voiceCmdPreviousStop => 'Tappa precedente';

  @override
  String get voiceCmdNearby => 'Cosa c\'è nelle vicinanze';

  @override
  String get voiceCmdAdd => 'Aggiungi al percorso';

  @override
  String get voiceCmdStartNav => 'Inizia navigazione';

  @override
  String get voiceCmdStopNav => 'Termina navigazione';

  @override
  String get voiceCmdDescribe => 'Leggi descrizione';

  @override
  String get voiceCmdUnknown => 'Sconosciuto';

  @override
  String get voiceCmdRouteWeather => 'Meteo sul percorso';

  @override
  String get voiceCmdRecommend => 'Raccomandazione';

  @override
  String get voiceCmdOverview => 'Panoramica percorso';

  @override
  String get voiceCmdRemaining => 'Tappe rimanenti';

  @override
  String get voiceCmdHelp => 'Aiuto';

  @override
  String get voiceCmdNotAvailable =>
      'Questo comando non è disponibile durante la navigazione.';

  @override
  String get voiceGreeting1 => 'Pronto per il tuo viaggio?';

  @override
  String get voiceGreeting2 => 'Come posso aiutarti?';

  @override
  String get voiceGreeting3 => 'Cosa vorresti sapere?';

  @override
  String get voiceGreeting4 => 'Ti ascolto!';

  @override
  String get voiceGreeting5 => 'Chiedimi qualcosa!';

  @override
  String get voiceGreeting6 => 'Pronto per il tuo percorso?';

  @override
  String get voiceGreeting7 => 'Il tuo assistente di navigazione!';

  @override
  String get voiceGreeting8 => 'Dove andiamo?';

  @override
  String get voiceUnknown1 =>
      'Hmm, non ho capito. Prova a dire Quanto manca? o Prossima tappa.';

  @override
  String get voiceUnknown2 =>
      'Ops! Il mio cervello da navigatore non ha capito. Di\' Aiuto per tutti i comandi!';

  @override
  String get voiceUnknown3 =>
      'Troppo filosofico per me. Sono solo un semplice navigatore!';

  @override
  String get voiceUnknown4 =>
      'Eh? Sono un navigatore, non un lettore del pensiero! Chiedimi del percorso o del meteo.';

  @override
  String get voiceUnknown5 =>
      'Non ho capito. Prova Dove sono? o Cosa c\'è vicino?';

  @override
  String get voiceUnknown6 =>
      'Beep boop... Comando non riconosciuto! Capisco cose come Quanto manca?';

  @override
  String voiceWeatherOnRoute(String description, String temp) {
    return 'Il meteo sul tuo percorso: $description, $temp gradi.';
  }

  @override
  String get voiceNoWeatherData =>
      'Purtroppo non ho dati meteo per il tuo percorso.';

  @override
  String voiceRecommendPOIs(String names) {
    return 'Ti consiglio: $names. Vere attrazioni imperdibili!';
  }

  @override
  String get voiceNoRecommendations =>
      'Ci sono delle tappe interessanti sul tuo percorso!';

  @override
  String voiceRouteOverview(String distance, String stops) {
    return 'Il tuo percorso è lungo $distance chilometri con $stops tappe.';
  }

  @override
  String get voiceRemainingOne =>
      'Solo un\'altra tappa prima della destinazione!';

  @override
  String voiceRemainingMultiple(int count) {
    return 'Ancora $count tappe davanti a te.';
  }

  @override
  String get voiceHelpText =>
      'Puoi chiedermi: Quanto manca? Prossima tappa? Dove sono? Com\'è il tempo? Raccomandazioni? O di\' Termina navigazione.';

  @override
  String voiceManeuverNow(String instruction) {
    return 'Adesso $instruction';
  }

  @override
  String voiceManeuverInMeters(int meters, String instruction) {
    return 'Tra $meters metri $instruction';
  }

  @override
  String voiceManeuverInKm(String km, String instruction) {
    return 'Tra $km chilometri $instruction';
  }

  @override
  String navMustSeeAnnouncement(String distance, String name) {
    return 'Tra $distance metri c\'è $name, un\'attrazione imperdibile';
  }

  @override
  String advisorDangerWeather(int day, int outdoorCount) {
    return 'Allerta meteo prevista per il giorno $day! $outdoorCount tappe all\'aperto dovrebbero essere sostituite con alternative al coperto.';
  }

  @override
  String advisorBadWeather(int day, int outdoorCount, int totalCount) {
    return 'Pioggia prevista per il giorno $day. $outdoorCount su $totalCount tappe sono attività all\'aperto.';
  }

  @override
  String advisorOutdoorAlternative(String name) {
    return '$name è un\'attività all\'aperto - alternativa consigliata';
  }

  @override
  String advisorOutdoorReplace(String name) {
    return '$name è un\'attività all\'aperto. Sostituisci questa tappa con un\'alternativa al coperto.';
  }

  @override
  String get advisorAiUnavailableSuggestions =>
      'IA non disponibile - mostra suggerimenti locali';

  @override
  String advisorNoStopsForDay(int day) {
    return 'Nessuna tappa per il giorno $day';
  }

  @override
  String get advisorNoRecommendationsFound =>
      'Nessuna raccomandazione trovata nelle vicinanze delle tappe';

  @override
  String get advisorAiUnavailableRecommendations =>
      'IA non disponibile - mostra raccomandazioni locali';

  @override
  String get advisorErrorLoadingRecommendations =>
      'Errore nel caricamento delle raccomandazioni';

  @override
  String advisorPoiCategory(String name, String category) {
    return '$name - $category';
  }

  @override
  String get weatherConditionGood => 'Bel tempo';

  @override
  String get weatherConditionMixed => 'Variabile';

  @override
  String get weatherConditionBad => 'Maltempo';

  @override
  String get weatherConditionDanger => 'Allerta meteo';

  @override
  String get weatherConditionUnknown => 'Meteo sconosciuto';

  @override
  String get weatherBadgeSnow => 'Neve';

  @override
  String get weatherBadgeRain => 'Pioggia';

  @override
  String get weatherBadgePerfect => 'Perfetto';

  @override
  String get weatherBadgeBad => 'Brutto';

  @override
  String get weatherBadgeDanger => 'Allerta';

  @override
  String get weatherRecOutdoorIdeal => 'Ideale per i POI all\'aperto';

  @override
  String get weatherRecRainIndoor => 'Pioggia - POI al coperto consigliati';

  @override
  String get weatherRecDangerIndoor => 'Maltempo - solo POI al coperto!';

  @override
  String get weatherToggleActive => 'Attivo';

  @override
  String get weatherToggleApply => 'Applica';

  @override
  String get weatherPointStart => 'Partenza';

  @override
  String get weatherPointEnd => 'Arrivo';

  @override
  String get weatherIndoorOnly => 'Solo POI al coperto';

  @override
  String weatherAlertStorm(String windSpeed) {
    return 'Allerta tempesta! Venti forti ($windSpeed km/h) lungo il percorso.';
  }

  @override
  String get weatherAlertDanger => 'Allerta meteo! Si consiglia di rinviare.';

  @override
  String get weatherAlertWinter => 'Tempo invernale! Possibile neve/ghiaccio.';

  @override
  String get weatherAlertRain =>
      'Pioggia prevista. Attività al coperto consigliate.';

  @override
  String get weatherAlertBad => 'Maltempo sul percorso.';

  @override
  String get weatherRecToday => 'Raccomandazione di oggi';

  @override
  String get weatherRecGoodDetail =>
      'Tempo perfetto per attività all\'aperto! Punti panoramici, natura e laghi consigliati.';

  @override
  String get weatherRecMixedDetail =>
      'Tempo variabile. Sia POI al coperto che all\'aperto possibili.';

  @override
  String get weatherRecBadDetail =>
      'Pioggia prevista. Attività al coperto come musei e chiese consigliate.';

  @override
  String get weatherRecDangerDetail =>
      'Allerta meteo! Evitare attività all\'aperto e restare al coperto.';

  @override
  String get weatherRecNoData => 'Nessun dato meteo disponibile.';

  @override
  String get weatherRecOutdoorPerfect =>
      'Tempo perfetto per attività all\'aperto';

  @override
  String get weatherRecMixedPrepare => 'Variabile - preparati a tutto';

  @override
  String get weatherRecSnowCaution =>
      'Nevicate - attenzione alle strade scivolose';

  @override
  String get weatherRecBadIndoor =>
      'Maltempo - attività al coperto consigliate';

  @override
  String weatherRecStormWarning(String windSpeed) {
    return 'Allerta tempesta! Venti forti ($windSpeed km/h)';
  }

  @override
  String get weatherRecDangerCaution =>
      'Allerta meteo! Cautela su questo tratto';

  @override
  String get weatherRecNoDataAvailable => 'Nessun dato meteo disponibile';

  @override
  String get mapMyLocation => 'La mia posizione';

  @override
  String get mapDetails => 'Dettagli';

  @override
  String get mapAddToRoute => 'Aggiungi al percorso';

  @override
  String get mapSelectedPoint => 'Punto selezionato';

  @override
  String get mapWaypoint => 'Tappa';

  @override
  String mapRouteCreated(String name) {
    return 'Percorso verso \"$name\" creato';
  }

  @override
  String mapPoiAdded(String name) {
    return '\"$name\" aggiunto';
  }

  @override
  String get mapErrorAdding => 'Errore durante l\'aggiunta';

  @override
  String get tripPreviewStartDay1 => 'Partenza (Giorno 1)';

  @override
  String tripPreviewDayStart(String day) {
    return 'Giorno $day partenza';
  }

  @override
  String get tripPreviewBackToStart => 'Ritorno alla partenza';

  @override
  String tripPreviewEndDay(String day) {
    return 'Fine giorno $day';
  }

  @override
  String tripPreviewDetour(String km) {
    return '+$km km deviazione';
  }

  @override
  String get tripPreviewOvernight => 'Pernottamento';

  @override
  String get gamificationLevelUp => 'Livello aumentato!';

  @override
  String gamificationNewLevel(int level) {
    return 'Livello $level';
  }

  @override
  String get gamificationContinue => 'Continua';

  @override
  String get gamificationAchievementUnlocked => 'Achievement sbloccato!';

  @override
  String get gamificationAwesome => 'Fantastico!';

  @override
  String gamificationXpEarned(int amount) {
    return '+$amount XP';
  }

  @override
  String get gamificationNextAchievements => 'Prossimi achievement';

  @override
  String get gamificationAllAchievements => 'Tutti gli achievement';

  @override
  String gamificationUnlockedCount(int count, int total) {
    return '$count/$total sbloccati';
  }

  @override
  String get gamificationTripCreated => 'Viaggio creato';

  @override
  String get gamificationTripPublished => 'Viaggio pubblicato';

  @override
  String get gamificationTripImported => 'Viaggio importato';

  @override
  String get gamificationPoiVisited => 'POI visitato';

  @override
  String get gamificationPhotoAdded => 'Foto aggiunta';

  @override
  String get gamificationLikeReceived => 'Like ricevuto';

  @override
  String get poiRatingLabel => 'Valutazione';

  @override
  String get poiReviews => 'Recensioni';

  @override
  String get poiPhotos => 'Foto';

  @override
  String get poiComments => 'Commenti';

  @override
  String get poiNoReviews => 'Ancora nessuna recensione';

  @override
  String get poiNoPhotos => 'Ancora nessuna foto';

  @override
  String get poiNoComments => 'Ancora nessun commento';

  @override
  String get poiBeFirstReview => 'Sii il primo a recensire questo luogo!';

  @override
  String get poiBeFirstPhoto => 'Sii il primo a condividere una foto!';

  @override
  String get poiBeFirstComment => 'Scrivi il primo commento!';

  @override
  String poiReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recensioni',
      one: '1 recensione',
      zero: 'Nessuna recensione',
    );
    return '$_temp0';
  }

  @override
  String poiPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '1 foto',
      zero: 'Nessuna foto',
    );
    return '$_temp0';
  }

  @override
  String poiCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commenti',
      one: '1 commento',
      zero: 'Nessun commento',
    );
    return '$_temp0';
  }

  @override
  String get reviewSubmit => 'Invia recensione';

  @override
  String get reviewEdit => 'Modifica recensione';

  @override
  String get reviewYourRating => 'La tua valutazione';

  @override
  String get reviewWriteOptional => 'Scrivi una recensione (opzionale)';

  @override
  String get reviewPlaceholder =>
      'Condividi la tua esperienza con gli altri...';

  @override
  String get reviewVisitDate => 'Data della visita';

  @override
  String get reviewVisitDateOptional => 'Data della visita (opzionale)';

  @override
  String reviewVisitedOn(String date) {
    return 'Visitato il $date';
  }

  @override
  String get reviewHelpful => 'Utile';

  @override
  String reviewHelpfulCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone hanno trovato utile',
      one: '1 persona ha trovato utile',
      zero: 'Non ancora valutato',
    );
    return '$_temp0';
  }

  @override
  String get reviewMarkedHelpful => 'Contrassegnato come utile';

  @override
  String get reviewSuccess => 'Recensione salvata!';

  @override
  String get reviewError => 'Errore nel salvataggio della recensione';

  @override
  String get reviewDelete => 'Elimina recensione';

  @override
  String get reviewDeleteConfirm => 'Vuoi davvero eliminare la tua recensione?';

  @override
  String get reviewDeleteSuccess => 'Recensione eliminata';

  @override
  String get reviewDeleteError => 'Errore nell\'eliminazione della recensione';

  @override
  String get reviewRatingRequired => 'Seleziona una valutazione';

  @override
  String reviewAvgRating(String rating) {
    return '$rating su 5 stelle';
  }

  @override
  String get photoUpload => 'Carica foto';

  @override
  String get photoCaption => 'Didascalia';

  @override
  String get photoCaptionHint => 'Descrivi la tua foto (opzionale)';

  @override
  String get photoFromCamera => 'Fotocamera';

  @override
  String get photoFromGallery => 'Galleria';

  @override
  String get photoUploading => 'Caricamento foto...';

  @override
  String get photoSuccess => 'Foto caricata!';

  @override
  String get photoError => 'Errore nel caricamento della foto';

  @override
  String get photoDelete => 'Elimina foto';

  @override
  String get photoDeleteConfirm => 'Vuoi davvero eliminare questa foto?';

  @override
  String get photoDeleteSuccess => 'Foto eliminata';

  @override
  String get photoDeleteError => 'Errore nell\'eliminazione della foto';

  @override
  String photoBy(String author) {
    return 'Foto di $author';
  }

  @override
  String get commentAdd => 'Aggiungi commento';

  @override
  String get commentPlaceholder => 'Scrivi un commento...';

  @override
  String get commentReply => 'Rispondi';

  @override
  String commentReplyTo(String author) {
    return 'Risposta a $author';
  }

  @override
  String get commentDelete => 'Elimina commento';

  @override
  String get commentDeleteConfirm => 'Vuoi davvero eliminare questo commento?';

  @override
  String get commentDeleteSuccess => 'Commento eliminato';

  @override
  String get commentDeleteError => 'Errore nell\'eliminazione del commento';

  @override
  String commentShowReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostra $count risposte',
      one: 'Mostra 1 risposta',
    );
    return '$_temp0';
  }

  @override
  String get commentHideReplies => 'Nascondi risposte';

  @override
  String get commentSuccess => 'Commento pubblicato!';

  @override
  String get commentError => 'Errore nella pubblicazione del commento';

  @override
  String get commentEmpty => 'Scrivi un commento';

  @override
  String get adminDashboard => 'Dashboard Admin';

  @override
  String get adminNotifications => 'Notifiche';

  @override
  String get adminModeration => 'Moderazione';

  @override
  String get adminNewPhotos => 'Nuove foto';

  @override
  String get adminNewReviews => 'Nuove recensioni';

  @override
  String get adminNewComments => 'Nuovi commenti';

  @override
  String get adminFlaggedContent => 'Contenuti segnalati';

  @override
  String get adminDelete => 'Elimina';

  @override
  String get adminDeleteConfirm => 'Vuoi davvero eliminare questo contenuto?';

  @override
  String get adminDeleteSuccess => 'Contenuto eliminato';

  @override
  String get adminDeleteError => 'Errore nell\'eliminazione';

  @override
  String get adminApprove => 'Approva';

  @override
  String get adminApproveSuccess => 'Contenuto approvato';

  @override
  String get adminApproveError => 'Errore nell\'approvazione';

  @override
  String get adminMarkRead => 'Segna come letto';

  @override
  String get adminMarkAllRead => 'Segna tutto come letto';

  @override
  String get adminNoNotifications => 'Nessuna nuova notifica';

  @override
  String get adminNoFlagged => 'Nessun contenuto segnalato';

  @override
  String get adminStats => 'Statistiche';

  @override
  String adminUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non letti',
      one: '1 non letto',
      zero: 'Nessuno non letto',
    );
    return '$_temp0';
  }

  @override
  String adminFlaggedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segnalati',
      one: '1 segnalato',
      zero: 'Nessuno segnalato',
    );
    return '$_temp0';
  }

  @override
  String get adminNotificationNewPhoto => 'Nuova foto caricata';

  @override
  String get adminNotificationNewReview => 'Nuova recensione';

  @override
  String get adminNotificationNewComment => 'Nuovo commento';

  @override
  String get adminNotificationFlagged => 'Contenuto segnalato';

  @override
  String get socialLoginRequired => 'Accedi per utilizzare questa funzione';

  @override
  String get socialRatingRequired => 'Seleziona una valutazione';

  @override
  String get reportContent => 'Segnala contenuto';

  @override
  String get reportSuccess =>
      'Grazie! Il contenuto è stato segnalato per la revisione.';

  @override
  String get reportError => 'Errore nella segnalazione del contenuto';

  @override
  String get reportReason => 'Motivo della segnalazione';

  @override
  String get reportReasonHint =>
      'Descrivi perché questo contenuto dovrebbe essere segnalato...';

  @override
  String get anonymousUser => 'Anonimo';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Errore';

  @override
  String get success => 'Successo';
}
