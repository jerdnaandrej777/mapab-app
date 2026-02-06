// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'MapAB';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get remove => 'Retirer';

  @override
  String get retry => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get done => 'Terminé';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get or => 'OU';

  @override
  String get edit => 'Modifier';

  @override
  String get loading => 'Chargement...';

  @override
  String get search => 'Rechercher';

  @override
  String get show => 'Afficher';

  @override
  String get apply => 'Appliquer';

  @override
  String get active => 'Actif';

  @override
  String get discard => 'Abandonner';

  @override
  String get resume => 'Reprendre';

  @override
  String get skip => 'Passer';

  @override
  String get all => 'Tous';

  @override
  String get total => 'Total';

  @override
  String get newLabel => 'Nouveau';

  @override
  String get start => 'Départ';

  @override
  String get destination => 'Destination';

  @override
  String get showOnMap => 'Afficher sur la carte';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get actionCannotBeUndone => 'Cette action ne peut pas être annulée.';

  @override
  String get details => 'Détails';

  @override
  String get generate => 'Générer';

  @override
  String get clear => 'Effacer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get end => 'Terminer';

  @override
  String get reroll => 'Relancer';

  @override
  String get filterApply => 'Appliquer le filtre';

  @override
  String get openInGoogleMaps => 'Ouvrir dans Google Maps';

  @override
  String get shareLinkCopied => 'Lien copié dans le presse-papiers !';

  @override
  String get shareAsText => 'Partager en texte';

  @override
  String get errorGeneric => 'Une erreur s\'est produite';

  @override
  String get errorNetwork => 'Pas de connexion Internet';

  @override
  String get errorNetworkMessage =>
      'Veuillez vérifier votre connexion et réessayer.';

  @override
  String get errorServer => 'Serveur inaccessible';

  @override
  String get errorServerMessage =>
      'Le serveur ne répond pas. Réessayez plus tard.';

  @override
  String get errorNoResults => 'Aucun résultat';

  @override
  String get errorLocation => 'Position non disponible';

  @override
  String get errorLocationMessage =>
      'Veuillez autoriser l\'accès à votre position.';

  @override
  String get errorPrefix => 'Erreur : ';

  @override
  String get pageNotFound => 'Page non trouvée';

  @override
  String get goToHome => 'Aller à l\'accueil';

  @override
  String get errorRouteCalculation =>
      'Calcul de l\'itinéraire échoué. Veuillez réessayer.';

  @override
  String errorTripGeneration(String error) {
    return 'Génération du voyage échouée : $error';
  }

  @override
  String get errorGoogleMapsNotOpened => 'Impossible d\'ouvrir Google Maps';

  @override
  String get errorRouteNotShared => 'Impossible de partager l\'itinéraire';

  @override
  String get errorAddingToRoute => 'Erreur lors de l\'ajout';

  @override
  String get errorIncompleteRouteData => 'Données de l\'itinéraire incomplètes';

  @override
  String get gpsDisabledTitle => 'GPS désactivé';

  @override
  String get gpsDisabledMessage =>
      'Les services de localisation sont désactivés. Voulez-vous ouvrir les paramètres GPS ?';

  @override
  String get gpsPermissionDenied => 'Autorisation GPS refusée';

  @override
  String get gpsPermissionDeniedForeverTitle => 'Autorisation GPS refusée';

  @override
  String get gpsPermissionDeniedForeverMessage =>
      'L\'autorisation GPS a été refusée de manière permanente. Veuillez autoriser l\'accès à la localisation dans les paramètres de l\'application.';

  @override
  String get gpsCouldNotDetermine => 'Impossible de déterminer la position GPS';

  @override
  String get appSettingsButton => 'Paramètres de l\'application';

  @override
  String get myLocation => 'Ma position';

  @override
  String get authWelcomeTitle => 'Bienvenue sur MapAB';

  @override
  String get authWelcomeSubtitle =>
      'Votre planificateur de voyages IA pour des trips inoubliables';

  @override
  String get authCloudNotAvailable =>
      'Cloud non disponible - Application construite sans identifiants Supabase';

  @override
  String get authCloudLoginUnavailable =>
      'Connexion cloud non disponible - Application construite sans identifiants Supabase';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailEmpty => 'Veuillez saisir une adresse e-mail';

  @override
  String get authEmailInvalid => 'E-mail invalide';

  @override
  String get authEmailInvalidAddress => 'Adresse e-mail invalide';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordEmpty => 'Veuillez saisir un mot de passe';

  @override
  String get authPasswordMinLength => 'Au moins 8 caractères';

  @override
  String get authPasswordRequirements =>
      'Doit contenir des lettres et des chiffres';

  @override
  String get authPasswordConfirm => 'Confirmer le mot de passe';

  @override
  String get authPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authRememberMe => 'Se souvenir de moi';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authNoAccount => 'Pas encore de compte ? ';

  @override
  String get authRegister => 'S\'inscrire';

  @override
  String get authContinueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get authGuestInfoCloud =>
      'En tant qu\'invité, vos données seront enregistrées localement uniquement et ne seront pas synchronisées.';

  @override
  String get authGuestInfoLocal =>
      'Vos données seront enregistrées localement sur votre appareil.';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authSecureData => 'Sécurisez vos données dans le cloud';

  @override
  String get authNameLabel => 'Nom';

  @override
  String get authNameHint => 'Comment souhaitez-vous être appelé ?';

  @override
  String get authNameEmpty => 'Veuillez saisir un nom';

  @override
  String get authNameMinLength => 'Le nom doit comporter au moins 2 caractères';

  @override
  String get authAlreadyHaveAccount => 'Vous avez déjà un compte ? ';

  @override
  String get authExistingAccount => 'J\'ai déjà un compte';

  @override
  String get authRegistrationSuccess => 'Inscription réussie';

  @override
  String get authRegistrationSuccessMessage =>
      'Veuillez vérifier vos e-mails et confirmer votre compte.';

  @override
  String get authResetPassword => 'Réinitialiser le mot de passe';

  @override
  String get authResetPasswordInstructions =>
      'Saisissez votre adresse e-mail et nous vous enverrons un lien de réinitialisation.';

  @override
  String get authSendLink => 'Envoyer le lien';

  @override
  String get authBackToLogin => 'Retour à la connexion';

  @override
  String get authEmailSent => 'E-mail envoyé !';

  @override
  String get authEmailSentPrefix => 'Nous vous avons envoyé un e-mail à';

  @override
  String get authEmailSentSuffix => '.';

  @override
  String get authResetLinkInstructions =>
      'Cliquez sur le lien dans l\'e-mail pour définir un nouveau mot de passe. Le lien est valable 24 heures.';

  @override
  String get authResend => 'Renvoyer';

  @override
  String get authCreateLocalProfile => 'Créer un profil local';

  @override
  String get authUsernameLabel => 'Nom d\'utilisateur';

  @override
  String get authUsernameHint => 'ex. voyageur123';

  @override
  String get authDisplayNameLabel => 'Nom d\'affichage';

  @override
  String get authDisplayNameHint => 'ex. Marie Dupont';

  @override
  String get authEmailOptional => 'E-mail (optionnel)';

  @override
  String get authEmailHint => 'ex. marie@exemple.com';

  @override
  String get authCreate => 'Créer';

  @override
  String get authRequiredFields =>
      'Le nom d\'utilisateur et le nom d\'affichage sont requis';

  @override
  String get authGuestDescription =>
      'En tant qu\'invité, vous pouvez commencer immédiatement. Vos données seront enregistrées localement sur votre appareil.';

  @override
  String get authComingSoon => 'Connexion cloud bientôt disponible :';

  @override
  String get authLoadingText => 'Chargement...';

  @override
  String get splashTagline => 'Votre planificateur de voyage IA';

  @override
  String get onboardingTitle1 => 'Découvrez les sites touristiques';

  @override
  String get onboardingHighlight1 => 'sites touristiques';

  @override
  String get onboardingSubtitle1 =>
      'Trouvez plus de 500 POIs sélectionnés dans toute l\'Europe.\nChâteaux, lacs, musées et lieux secrets vous attendent.';

  @override
  String get onboardingTitle2 => 'Votre assistant de voyage IA';

  @override
  String get onboardingHighlight2 => 'IA';

  @override
  String get onboardingSubtitle2 =>
      'Laissez-vous planifier automatiquement l\'itinéraire parfait.\nAvec optimisation intelligente pour vos centres d\'intérêt.';

  @override
  String get onboardingTitle3 => 'Vos voyages dans le cloud';

  @override
  String get onboardingHighlight3 => 'Cloud';

  @override
  String get onboardingSubtitle3 =>
      'Enregistrez vos favoris et voyages en toute sécurité en ligne.\nSynchronisé sur tous vos appareils.';

  @override
  String get onboardingStart => 'C\'est parti';

  @override
  String get categoryCastle => 'Châteaux & Forteresses';

  @override
  String get categoryNature => 'Nature & Forêts';

  @override
  String get categoryMuseum => 'Musées';

  @override
  String get categoryViewpoint => 'Points de vue';

  @override
  String get categoryLake => 'Lacs';

  @override
  String get categoryCoast => 'Côtes & Plages';

  @override
  String get categoryPark => 'Parcs & Parcs nationaux';

  @override
  String get categoryCity => 'Villes';

  @override
  String get categoryActivity => 'Activités';

  @override
  String get categoryHotel => 'Hôtels';

  @override
  String get categoryRestaurant => 'Restaurants';

  @override
  String get categoryUnesco => 'Patrimoine mondial UNESCO';

  @override
  String get categoryChurch => 'Églises';

  @override
  String get categoryMonument => 'Monuments';

  @override
  String get categoryAttraction => 'Attractions';

  @override
  String get weatherGood => 'Bon';

  @override
  String get weatherMixed => 'Variable';

  @override
  String get weatherBad => 'Mauvais';

  @override
  String get weatherDanger => 'Dangereux';

  @override
  String get weatherUnknown => 'Inconnu';

  @override
  String get weatherClear => 'Dégagé';

  @override
  String get weatherMostlyClear => 'Généralement dégagé';

  @override
  String get weatherPartlyCloudy => 'Partiellement nuageux';

  @override
  String get weatherCloudy => 'Nuageux';

  @override
  String get weatherFog => 'Brouillard';

  @override
  String get weatherDrizzle => 'Bruine';

  @override
  String get weatherFreezingDrizzle => 'Bruine verglaçante';

  @override
  String get weatherRain => 'Pluie';

  @override
  String get weatherFreezingRain => 'Pluie verglaçante';

  @override
  String get weatherSnow => 'Chute de neige';

  @override
  String get weatherSnowGrains => 'Grésil';

  @override
  String get weatherRainShowers => 'Averses de pluie';

  @override
  String get weatherSnowShowers => 'Averses de neige';

  @override
  String get weatherThunderstorm => 'Orage';

  @override
  String get weatherThunderstormHail => 'Orage avec grêle';

  @override
  String get weatherForecast7Day => 'Prévisions 7 jours';

  @override
  String get weatherToday => 'Aujourd\'hui';

  @override
  String weatherFeelsLike(String temp) {
    return 'Ressenti $temp°';
  }

  @override
  String get weatherSunrise => 'Lever du soleil';

  @override
  String get weatherSunset => 'Coucher du soleil';

  @override
  String get weatherUvIndex => 'Indice UV';

  @override
  String get weatherPrecipitation => 'Précipitations';

  @override
  String get weatherWind => 'Vent';

  @override
  String get weatherRainRisk => 'Risque de pluie';

  @override
  String get weatherRecommendationToday => 'Recommandation du jour';

  @override
  String get weatherRecGood =>
      'Temps parfait pour les activités en plein air ! Points de vue, nature et lacs recommandés.';

  @override
  String get weatherRecMixed => 'Variable - planifiez avec flexibilité';

  @override
  String get weatherRecBad =>
      'Pluie prévue. Activités en intérieur comme musées et églises recommandées.';

  @override
  String get weatherRecDanger =>
      'Alerte météo ! Veuillez éviter les activités en plein air et rester à l\'intérieur.';

  @override
  String get weatherRecUnknown => 'Aucune donnée météo disponible.';

  @override
  String weatherUvLow(String value) {
    return '$value (Faible)';
  }

  @override
  String weatherUvMedium(String value) {
    return '$value (Moyen)';
  }

  @override
  String weatherUvHigh(String value) {
    return '$value (Élevé)';
  }

  @override
  String weatherUvVeryHigh(String value) {
    return '$value (Très élevé)';
  }

  @override
  String weatherUvExtreme(String value) {
    return '$value (Extrême)';
  }

  @override
  String get weatherLoading => 'Chargement de la météo...';

  @override
  String get weatherWinterWeather => 'Temps hivernal';

  @override
  String get weatherStormOnRoute => 'Intempéries sur le trajet';

  @override
  String get weatherRainPossible => 'Pluie possible';

  @override
  String get weatherGoodWeather => 'Beau temps';

  @override
  String get weatherChangeable => 'Variable';

  @override
  String get weatherBadWeather => 'Mauvais temps';

  @override
  String get weatherStormWarning => 'Alerte météo';

  @override
  String get weatherPerfect => 'Parfait';

  @override
  String get weatherStorm => 'Intempéries';

  @override
  String get weatherIdealOutdoor =>
      'Idéal aujourd\'hui pour les POIs en plein air';

  @override
  String get weatherFlexiblePlanning => 'Variable - planifier avec flexibilité';

  @override
  String get weatherRainIndoor => 'Pluie - POIs en intérieur recommandés';

  @override
  String get weatherStormIndoorOnly =>
      'Intempéries - uniquement POIs en intérieur !';

  @override
  String get weatherOnlyIndoor => 'Uniquement POIs en intérieur';

  @override
  String weatherStormHighWinds(String speed) {
    return 'Alerte tempête ! Vents forts ($speed km/h) le long de l\'itinéraire.';
  }

  @override
  String get weatherStormDelay => 'Alerte météo ! Report du voyage recommandé.';

  @override
  String get weatherWinterWarning =>
      'Météo hivernale ! Neige/verglas possible.';

  @override
  String get weatherRainRecommendation =>
      'Pluie prévue. Activités en intérieur recommandées.';

  @override
  String get weatherBadOnRoute => 'Mauvais temps sur l\'itinéraire.';

  @override
  String get weatherPerfectOutdoor =>
      'Temps parfait pour les activités en plein air';

  @override
  String get weatherBePrepared => 'Variable - être prêt à tout';

  @override
  String get weatherSnowWarning =>
      'Chute de neige - prudence sur routes glissantes';

  @override
  String get weatherBadIndoor =>
      'Mauvais temps - activités en intérieur recommandées';

  @override
  String get weatherStormCaution => 'Alerte météo ! Prudence sur ce tronçon';

  @override
  String get weatherNoData => 'Aucune donnée météo disponible';

  @override
  String weatherRoutePoint(String index, String total) {
    return 'Point $index sur $total';
  }

  @override
  String weatherExpectedOnDay(String weather, int day) {
    return '$weather prévu le jour $day';
  }

  @override
  String weatherOutdoorStops(int outdoor, int total) {
    return '$outdoor arrêts sur $total sont des activités en plein air.';
  }

  @override
  String get weatherSuggestIndoor => 'Suggérer des alternatives en intérieur';

  @override
  String get weatherStormExpected => 'Intempéries prévues';

  @override
  String get weatherRainExpected => 'Pluie prévue';

  @override
  String get weatherIdealOutdoorWeather => 'Temps idéal pour l\'extérieur';

  @override
  String get weatherStormIndoorPrefer =>
      'Intempéries prévues – privilégier les arrêts en intérieur';

  @override
  String get weatherRainIndoorHighlight =>
      'Pluie prévue – arrêts en intérieur mis en avant';

  @override
  String get weekdayMon => 'Lun';

  @override
  String get weekdayTue => 'Mar';

  @override
  String get weekdayWed => 'Mer';

  @override
  String get weekdayThu => 'Jeu';

  @override
  String get weekdayFri => 'Ven';

  @override
  String get weekdaySat => 'Sam';

  @override
  String get weekdaySun => 'Dim';

  @override
  String get mapFavorites => 'Favoris';

  @override
  String get mapProfile => 'Profil';

  @override
  String get mapSettings => 'Paramètres';

  @override
  String get mapToRoute => 'Vers l\'itinéraire';

  @override
  String get mapSetAsStart => 'Définir comme départ';

  @override
  String get mapSetAsDestination => 'Définir comme destination';

  @override
  String get mapAddAsStop => 'Ajouter comme étape';

  @override
  String get tripConfigGps => 'GPS';

  @override
  String get tripConfigCityOrAddress => 'Ville ou adresse...';

  @override
  String get tripConfigDestinationOptional => 'Destination (optionnel)';

  @override
  String get tripConfigAddDestination => 'Ajouter une destination (optionnel)';

  @override
  String get tripConfigEnterDestination => 'Saisir la destination...';

  @override
  String get tripConfigNoDestinationRoundtrip =>
      'Sans destination : voyage circulaire depuis le départ';

  @override
  String get tripConfigSurpriseMe => 'Surprenez-moi !';

  @override
  String get tripConfigDeleteRoute => 'Supprimer l\'itinéraire';

  @override
  String get tripConfigTripDuration => 'Durée du voyage';

  @override
  String get tripConfigDay => 'Jour';

  @override
  String get tripConfigDays => 'Jours';

  @override
  String tripConfigDayTrip(String distance) {
    return 'Excursion d\'un jour — env. $distance km';
  }

  @override
  String tripConfigWeekendTrip(String distance) {
    return 'Voyage de week-end — env. $distance km';
  }

  @override
  String tripConfigShortVacation(String distance) {
    return 'Court séjour — env. $distance km';
  }

  @override
  String tripConfigWeekTravel(String distance) {
    return 'Voyage d\'une semaine — env. $distance km';
  }

  @override
  String tripConfigEpicEuroTrip(String distance) {
    return 'Epic Euro Trip — env. $distance km';
  }

  @override
  String get tripConfigRadius => 'Rayon';

  @override
  String get tripConfigPoiCategories => 'Catégories de POI';

  @override
  String get tripConfigResetAll => 'Tout réinitialiser';

  @override
  String get tripConfigAllCategories => 'Toutes les catégories sélectionnées';

  @override
  String tripConfigCategoriesSelected(int selected, int total) {
    return '$selected sur $total sélectionnées';
  }

  @override
  String get tripConfigCategories => 'Catégories';

  @override
  String tripConfigSelectedCount(int count) {
    return '$count sélectionnées';
  }

  @override
  String get tripConfigPoisAlongRoute => 'POIs le long de l\'itinéraire';

  @override
  String get tripConfigActiveTripTitle => 'Voyage actif existant';

  @override
  String tripConfigActiveTripMessage(int days, int completed) {
    return 'Vous avez un voyage actif de $days jours avec $completed jours terminés. Un nouveau voyage remplacera celui-ci.';
  }

  @override
  String get tripConfigCreateNewTrip => 'Créer un nouveau voyage';

  @override
  String get tripInfoGenerating => 'Génération du voyage...';

  @override
  String get tripInfoLoadingPois =>
      'Chargement des POIs, optimisation de l\'itinéraire';

  @override
  String get tripInfoAiEuroTrip => 'AI Euro Trip';

  @override
  String get tripInfoAiDayTrip => 'AI Excursion d\'un jour';

  @override
  String get tripInfoEditTrip => 'Modifier le voyage';

  @override
  String get tripInfoStartNavigation => 'Démarrer la navigation';

  @override
  String get tripInfoStops => 'Arrêts';

  @override
  String get tripInfoDistance => 'Distance';

  @override
  String get tripInfoDaysLabel => 'Jours';

  @override
  String get activeTripTitle => 'Euro Trip actif';

  @override
  String get activeTripDiscard => 'Abandonner le voyage actif';

  @override
  String get activeTripDiscardTitle => 'Abandonner le voyage ?';

  @override
  String activeTripDiscardMessage(int days, int completed) {
    return 'Votre voyage de $days jours avec $completed jours terminés sera supprimé.';
  }

  @override
  String activeTripDayPending(int day) {
    return 'Jour $day à venir';
  }

  @override
  String activeTripDaysCompleted(int completed, int total) {
    return '$completed sur $total jours terminés';
  }

  @override
  String get tripModeAiDayTrip => 'AI Excursion d\'un jour';

  @override
  String get tripModeAiEuroTrip => 'AI Euro Trip';

  @override
  String get tripRoutePlanning => 'Planifier l\'itinéraire';

  @override
  String get tripNoRoute => 'Aucun itinéraire disponible';

  @override
  String get tripTapMap =>
      'Appuyez sur la carte pour définir le départ et la destination';

  @override
  String get tripToMap => 'Vers la carte';

  @override
  String get tripGeneratingDescription =>
      'Chargement des POIs, optimisation de l\'itinéraire, recherche d\'hôtels';

  @override
  String get tripElevationLoading => 'Chargement du profil d\'altitude...';

  @override
  String get tripSaveRoute => 'Enregistrer l\'itinéraire';

  @override
  String get tripRouteName => 'Nom de l\'itinéraire';

  @override
  String get tripExampleDayTrip => 'ex. Escapade de week-end';

  @override
  String get tripExampleAiDayTrip => 'ex. AI Excursion d\'un jour';

  @override
  String get tripExampleAiEuroTrip => 'ex. AI Euro Trip';

  @override
  String tripRouteSaved(String name) {
    return 'Itinéraire \"$name\" enregistré';
  }

  @override
  String get tripYourRoute => 'Votre itinéraire';

  @override
  String get tripDrivingTime => 'Temps de trajet';

  @override
  String get tripStopRemoved => 'Arrêt supprimé';

  @override
  String get tripOptimizeRoute => 'Optimiser l\'itinéraire';

  @override
  String get tripOptimizeBestOrder => 'Calculer le meilleur ordre';

  @override
  String get tripShareRoute => 'Partager l\'itinéraire';

  @override
  String get tripDeleteAllStops => 'Supprimer tous les arrêts';

  @override
  String get tripDeleteEntireRoute => 'Supprimer tout l\'itinéraire';

  @override
  String get tripDeleteRouteAndStops =>
      'Supprimer l\'itinéraire et tous les arrêts';

  @override
  String get tripConfirmDeleteAllStops => 'Supprimer tous les arrêts ?';

  @override
  String get tripConfirmDeleteEntireRoute => 'Supprimer tout l\'itinéraire ?';

  @override
  String get tripDeleteEntireRouteMessage =>
      'L\'itinéraire et tous les arrêts seront supprimés. Cette action ne peut pas être annulée.';

  @override
  String get tripBackToConfig => 'Retour à la configuration';

  @override
  String tripExportDay(int day) {
    return 'Jour $day dans Google Maps';
  }

  @override
  String tripReExportDay(int day) {
    return 'Exporter à nouveau le jour $day';
  }

  @override
  String get tripGoogleMapsHint =>
      'Google Maps calcule un itinéraire propre à travers les arrêts';

  @override
  String tripNoStopsForDay(int day) {
    return 'Aucun arrêt pour le jour $day';
  }

  @override
  String get tripCompleted => 'Voyage terminé !';

  @override
  String tripAllDaysExported(int days) {
    return 'Tous les $days jours ont été exportés avec succès. Souhaitez-vous enregistrer le voyage dans vos favoris ?';
  }

  @override
  String get tripKeep => 'Conserver';

  @override
  String get tripSaveToFavorites => 'Enregistrer dans les favoris';

  @override
  String get tripShareHeader => 'Mon itinéraire avec MapAB';

  @override
  String tripShareStart(String address) {
    return 'Départ : $address';
  }

  @override
  String tripShareEnd(String address) {
    return 'Destination : $address';
  }

  @override
  String tripShareDistance(String distance) {
    return 'Distance : $distance km';
  }

  @override
  String tripShareDuration(String duration) {
    return 'Durée : $duration min';
  }

  @override
  String get tripShareStops => 'Arrêts :';

  @override
  String get tripShareOpenMaps => 'Ouvrir dans Google Maps :';

  @override
  String get tripMyRoute => 'Mon itinéraire';

  @override
  String get tripGoogleMaps => 'Google Maps';

  @override
  String get tripShowInFavorites => 'Voir';

  @override
  String get tripGoogleMapsError => 'Impossible d\'ouvrir Google Maps';

  @override
  String get tripShareError => 'Impossible de partager l\'itinéraire';

  @override
  String get tripWeatherDangerHint =>
      'Intempéries prévues – privilégiez les arrêts couverts';

  @override
  String get tripWeatherBadHint =>
      'Pluie prévue – arrêts couverts mis en évidence';

  @override
  String get tripStart => 'Départ';

  @override
  String get tripDestination => 'Destination';

  @override
  String get tripNew => 'Nouveau';

  @override
  String get dayEditorTitle => 'Modifier le voyage';

  @override
  String get dayEditorNoTrip => 'Aucun voyage disponible';

  @override
  String get dayEditorStartNotAvailable => 'Point de départ non disponible';

  @override
  String dayEditorEditDay(int day) {
    return 'Modifier le jour $day';
  }

  @override
  String get dayEditorRegenerate => 'Régénérer';

  @override
  String dayEditorMaxStops(int max) {
    return 'Max $max arrêts par jour possibles dans Google Maps';
  }

  @override
  String get dayEditorSearchRecommendations =>
      'Recherche de recommandations de POI...';

  @override
  String get dayEditorLoadRecommendations =>
      'Charger les recommandations de POI';

  @override
  String get dayEditorAiRecommendations => 'Recommandations IA';

  @override
  String get dayEditorRecommended => 'Recommandé';

  @override
  String dayEditorAddedToDay(int day) {
    return 'ajouté au jour $day';
  }

  @override
  String get dayEditorAllDaysExported =>
      'Tous les jours ont été exportés avec succès dans Google Maps. Bon voyage !';

  @override
  String get dayEditorAddPois => 'Ajouter des POIs';

  @override
  String dayEditorMyRouteDay(int day) {
    return 'Mon itinéraire - Jour $day avec MapAB';
  }

  @override
  String dayEditorMapabRouteDay(int day) {
    return 'Itinéraire MapAB - Jour $day';
  }

  @override
  String dayEditorSwapped(String name) {
    return '\"$name\" remplacé';
  }

  @override
  String get corridorTitle => 'POIs le long de l\'itinéraire';

  @override
  String corridorFound(int total) {
    return '$total trouvés';
  }

  @override
  String corridorFoundWithNew(int total, int newCount) {
    return '$total trouvés ($newCount nouveaux)';
  }

  @override
  String corridorWidth(int km) {
    return 'Corridor : $km km';
  }

  @override
  String get corridorSearching => 'Recherche de POIs dans le corridor...';

  @override
  String get corridorNoPoiInCategory => 'Aucun POI trouvé dans cette catégorie';

  @override
  String get corridorNoPois => 'Aucun POI trouvé dans le corridor';

  @override
  String get corridorTryWider => 'Essayez un corridor plus large';

  @override
  String get corridorRemoveStop => 'Supprimer l\'arrêt ?';

  @override
  String get corridorMinOneStop => 'Au moins 1 arrêt par jour requis';

  @override
  String corridorPoiRemoved(String name) {
    return '\"$name\" supprimé';
  }

  @override
  String get navEndConfirm => 'Terminer la navigation ?';

  @override
  String get navDestinationReached => 'Destination atteinte !';

  @override
  String get navDistance => 'Distance';

  @override
  String get navArrival => 'Arrivée';

  @override
  String get navSpeed => 'Vitesse';

  @override
  String get navMuteOn => 'Son activé';

  @override
  String get navMuteOff => 'Son désactivé';

  @override
  String get navOverview => 'Vue d\'ensemble';

  @override
  String get navEnd => 'Terminer';

  @override
  String get navVoice => 'Voix';

  @override
  String get navVoiceListening => 'Écoute...';

  @override
  String get navStartButton => 'Démarrer la navigation';

  @override
  String get navRerouting => 'Recalcul de l\'itinéraire';

  @override
  String get navVisited => 'Visité';

  @override
  String navDistanceMeters(String distance) {
    return 'à $distance m';
  }

  @override
  String navDistanceKm(String distance) {
    return 'à $distance km';
  }

  @override
  String get navDepart => 'Démarrez';

  @override
  String navDepartOn(String street) {
    return 'Démarrez sur $street';
  }

  @override
  String get navArrive => 'Vous avez atteint votre destination';

  @override
  String navArriveAt(String street) {
    return 'Destination atteinte : $street';
  }

  @override
  String navContinueOn(String street) {
    return 'Continuez sur $street';
  }

  @override
  String get navContinue => 'Continuez';

  @override
  String get navTurnRight => 'Tournez à droite';

  @override
  String get navTurnLeft => 'Tournez à gauche';

  @override
  String navTurnRightOn(String street) {
    return 'Tournez à droite sur $street';
  }

  @override
  String navTurnLeftOn(String street) {
    return 'Tournez à gauche sur $street';
  }

  @override
  String get navSlightRight => 'Tournez légèrement à droite';

  @override
  String get navSlightLeft => 'Tournez légèrement à gauche';

  @override
  String navSlightRightOn(String street) {
    return 'Tournez légèrement à droite sur $street';
  }

  @override
  String navSlightLeftOn(String street) {
    return 'Tournez légèrement à gauche sur $street';
  }

  @override
  String get navSharpRight => 'Tournez fortement à droite';

  @override
  String get navSharpLeft => 'Tournez fortement à gauche';

  @override
  String get navUturn => 'Faites demi-tour';

  @override
  String get navStraight => 'Continuez tout droit';

  @override
  String navStraightOn(String street) {
    return 'Tout droit sur $street';
  }

  @override
  String get navMerge => 'Insérez-vous';

  @override
  String navMergeOn(String street) {
    return 'Insérez-vous sur $street';
  }

  @override
  String get navOnRamp => 'Prenez la bretelle d\'accès';

  @override
  String navOnRampOn(String street) {
    return 'Bretelle d\'accès sur $street';
  }

  @override
  String get navOffRamp => 'Prenez la sortie';

  @override
  String navOffRampOn(String street) {
    return 'Sortie $street';
  }

  @override
  String navRoundaboutExit(String ordinal) {
    return 'Au rond-point, prenez la $ordinal sortie';
  }

  @override
  String navRoundaboutExitOn(String ordinal, String street) {
    return 'Au rond-point, prenez la $ordinal sortie sur $street';
  }

  @override
  String get navRoundaboutEnter => 'Entrez dans le rond-point';

  @override
  String get navRoundaboutLeave => 'Quittez le rond-point';

  @override
  String get navForkLeft => 'À l\'embranchement, gardez la gauche';

  @override
  String get navForkRight => 'À l\'embranchement, gardez la droite';

  @override
  String navForkLeftOn(String street) {
    return 'À l\'embranchement, gardez la gauche sur $street';
  }

  @override
  String navForkRightOn(String street) {
    return 'À l\'embranchement, gardez la droite sur $street';
  }

  @override
  String get navEndOfRoadLeft => 'Au bout de la route, tournez à gauche';

  @override
  String get navEndOfRoadRight => 'Au bout de la route, tournez à droite';

  @override
  String navEndOfRoadLeftOn(String street) {
    return 'Au bout de la route, tournez à gauche sur $street';
  }

  @override
  String navEndOfRoadRightOn(String street) {
    return 'Au bout de la route, tournez à droite sur $street';
  }

  @override
  String navInDistance(String distance, String instruction) {
    return 'Dans $distance, $instruction';
  }

  @override
  String navNow(String instruction) {
    return 'Maintenant, $instruction';
  }

  @override
  String navMeters(String value) {
    return '$value mètres';
  }

  @override
  String navKilometers(String value) {
    return '$value kilomètres';
  }

  @override
  String get navOrdinalFirst => 'première';

  @override
  String get navOrdinalSecond => 'deuxième';

  @override
  String get navOrdinalThird => 'troisième';

  @override
  String get navOrdinalFourth => 'quatrième';

  @override
  String get navOrdinalFifth => 'cinquième';

  @override
  String get navOrdinalSixth => 'sixième';

  @override
  String get navOrdinalSeventh => 'septième';

  @override
  String get navOrdinalEighth => 'huitième';

  @override
  String navSharpRightOn(String street) {
    return 'Tournez fortement à droite sur $street';
  }

  @override
  String navSharpLeftOn(String street) {
    return 'Tournez fortement à gauche sur $street';
  }

  @override
  String navUturnOn(String street) {
    return 'Faites demi-tour sur $street';
  }

  @override
  String get navTurn => 'Tournez';

  @override
  String navTurnOn(String street) {
    return 'Tournez sur $street';
  }

  @override
  String get navForkStraight => 'Continuez à l\'embranchement';

  @override
  String navForkStraightOn(String street) {
    return 'Continuez à l\'embranchement sur $street';
  }

  @override
  String get navEndOfRoadStraight => 'Continuez au bout de la route';

  @override
  String navEndOfRoadStraightOn(String street) {
    return 'Continuez au bout de la route sur $street';
  }

  @override
  String navRoundaboutLeaveOn(String street) {
    return 'Quittez le rond-point sur $street';
  }

  @override
  String navRoundaboutEnterOn(String street) {
    return 'Entrez dans le rond-point sur $street';
  }

  @override
  String get navStraightContinue => 'Continuez tout droit';

  @override
  String get navDirectionLeft => 'À gauche ';

  @override
  String get navDirectionRight => 'À droite ';

  @override
  String get navSharpRightShort => 'Fortement à droite';

  @override
  String get navRightShort => 'À droite';

  @override
  String get navSlightRightShort => 'Légèrement à droite';

  @override
  String get navStraightShort => 'Tout droit';

  @override
  String get navSlightLeftShort => 'Légèrement à gauche';

  @override
  String get navLeftShort => 'À gauche';

  @override
  String get navSharpLeftShort => 'Fortement à gauche';

  @override
  String get navKeepLeft => 'Gardez la gauche';

  @override
  String get navKeepRight => 'Gardez la droite';

  @override
  String get navRoundabout => 'Rond-point';

  @override
  String navExitShort(String ordinal) {
    return '$ordinal sortie';
  }

  @override
  String get navMustSeeStop => 'Arrêt';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsDesign => 'Design';

  @override
  String get settingsAutoDarkMode => 'Mode sombre automatique';

  @override
  String get settingsAutoDarkModeDesc =>
      'Activer automatiquement au coucher du soleil';

  @override
  String get settingsFeedback => 'Retour';

  @override
  String get settingsHaptic => 'Retour haptique';

  @override
  String get settingsHapticDesc => 'Vibrations lors des interactions';

  @override
  String get settingsSound => 'Effets sonores';

  @override
  String get settingsSoundDesc => 'Sons lors des actions';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsAppVersion => 'Version de l\'application';

  @override
  String get settingsLicenses => 'Licences Open Source';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeOled => 'OLED Noir';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileEdit => 'Modifier le profil';

  @override
  String get profileCloudAccount => 'Compte cloud';

  @override
  String get profileAutoSync => 'Données synchronisées automatiquement';

  @override
  String get profileGuestAccount => 'Compte invité';

  @override
  String get profileLocalStorage => 'Stockage local';

  @override
  String get profileUpgradeToCloud => 'Passer au compte cloud';

  @override
  String get profileDeleteAccount => 'Supprimer le compte';

  @override
  String get profileNoAccount => 'Aucun compte';

  @override
  String get profileLoginPrompt => 'Connectez-vous pour voir votre profil';

  @override
  String get profileLogin => 'Se connecter';

  @override
  String profileLevel(int level) {
    return 'Niveau $level';
  }

  @override
  String profileXpProgress(int xp, int level) {
    return 'Encore $xp XP jusqu\'au niveau $level';
  }

  @override
  String get profileStatistics => 'Statistiques';

  @override
  String get profileStatisticsLoading => 'Chargement des statistiques...';

  @override
  String get profileStartFirstTrip =>
      'Démarrez votre premier voyage pour voir les statistiques !';

  @override
  String get profileTrips => 'Voyages';

  @override
  String get profilePois => 'POIs';

  @override
  String get profileKilometers => 'Kilomètres';

  @override
  String get profileAchievements => 'Succès';

  @override
  String get profileNoAchievements =>
      'Aucun succès débloqué. Démarrez votre premier voyage !';

  @override
  String profileAccountId(String id) {
    return 'ID de compte : $id';
  }

  @override
  String profileCreatedAt(String date) {
    return 'Créé le : $date';
  }

  @override
  String profileLastLogin(String date) {
    return 'Dernière connexion : $date';
  }

  @override
  String get profileEditComingSoon =>
      'Modification du profil bientôt disponible !';

  @override
  String get profileLogoutTitle => 'Se déconnecter ?';

  @override
  String get profileLogoutMessage => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get profileLogoutCloudMessage =>
      'Voulez-vous vraiment vous déconnecter ?\n\nVos données cloud restent sauvegardées et vous pouvez vous reconnecter à tout moment.';

  @override
  String get profileLogout => 'Se déconnecter';

  @override
  String get profileDeleteTitle => 'Supprimer le compte ?';

  @override
  String get profileDeleteMessage =>
      'Voulez-vous vraiment supprimer votre compte ? Toutes les données seront supprimées définitivement !';

  @override
  String get favTitle => 'Favoris';

  @override
  String get favRoutes => 'Itinéraires';

  @override
  String get favPois => 'POIs';

  @override
  String get favDeleteAll => 'Tout supprimer';

  @override
  String get favNoFavorites => 'Aucun favori';

  @override
  String get favNoFavoritesDesc =>
      'Enregistrez des itinéraires et des POIs pour un accès rapide';

  @override
  String get favExplore => 'Explorer';

  @override
  String get favNoRoutes => 'Aucun itinéraire enregistré';

  @override
  String get favPlanRoute => 'Planifier un itinéraire';

  @override
  String get favNoPois => 'Aucun POI favori';

  @override
  String get favDiscoverPois => 'Découvrir des POIs';

  @override
  String get favRemoveRoute => 'Supprimer l\'itinéraire ?';

  @override
  String favRemoveRouteConfirm(String name) {
    return 'Voulez-vous supprimer \"$name\" des favoris ?';
  }

  @override
  String get favRemovePoi => 'Supprimer le POI ?';

  @override
  String favRemovePoiConfirm(String name) {
    return 'Voulez-vous supprimer \"$name\" des favoris ?';
  }

  @override
  String get favRouteLoaded => 'Itinéraire chargé';

  @override
  String get favRouteRemoved => 'Itinéraire supprimé';

  @override
  String get favPoiRemoved => 'POI supprimé';

  @override
  String get favClearAll => 'Supprimer tous les favoris ?';

  @override
  String get favAllDeleted => 'Tous les favoris supprimés';

  @override
  String get poiSearchHint => 'Rechercher des POIs...';

  @override
  String get poiClearFilters => 'Effacer les filtres';

  @override
  String get poiResetFilters => 'Réinitialiser les filtres';

  @override
  String get poiLoading => 'Chargement des sites touristiques...';

  @override
  String get poiNotFound => 'POI non trouvé';

  @override
  String get poiLoadingDetails => 'Chargement des détails...';

  @override
  String get poiMoreOnWikipedia => 'Plus d\'infos sur Wikipedia';

  @override
  String get poiOpeningHours => 'Horaires d\'ouverture';

  @override
  String poiRouteCreated(String name) {
    return 'Itinéraire vers \"$name\" créé';
  }

  @override
  String get poiOnlyMustSee => 'Uniquement Must-See';

  @override
  String get poiShowOnlyHighlights => 'Afficher uniquement les points forts';

  @override
  String get poiOnlyIndoor => 'Uniquement POIs en intérieur';

  @override
  String get poiApplyFilters => 'Appliquer les filtres';

  @override
  String get poiReroll => 'Relancer';

  @override
  String get poiTitle => 'Sites touristiques';

  @override
  String get poiMustSee => 'Incontournables';

  @override
  String get poiWeatherTip => 'Conseil météo';

  @override
  String poiResultsCount(int filtered, int total) {
    return '$filtered sur $total POIs';
  }

  @override
  String get poiNoResultsFilter => 'Aucun POI trouvé avec ces filtres';

  @override
  String get poiNoResultsNearby => 'Aucun POI trouvé à proximité';

  @override
  String get poiGpsPermissionNeeded =>
      'Autorisation GPS nécessaire pour trouver les POIs à proximité';

  @override
  String get poiWeatherDangerBanner =>
      'Tempête prévue – POIs intérieurs recommandés';

  @override
  String get poiWeatherBadBanner =>
      'Pluie prévue – activez \"Conseil météo\" pour un meilleur tri';

  @override
  String get poiAboutPlace => 'À propos de ce lieu';

  @override
  String get poiNoDescription => 'Aucune description disponible.';

  @override
  String get poiDescriptionLoading => 'Chargement de la description...';

  @override
  String get poiContactInfo => 'Contact & Info';

  @override
  String get poiPhone => 'Téléphone';

  @override
  String get poiWebsite => 'Site web';

  @override
  String get poiEmailLabel => 'E-mail';

  @override
  String get poiDetour => 'Détour';

  @override
  String get poiTime => 'Temps';

  @override
  String get poiPosition => 'Position';

  @override
  String get poiCurated => 'Sélectionné';

  @override
  String get poiVerified => 'Vérifié';

  @override
  String poiAddedToRoute(String name) {
    return '$name ajouté à l\'itinéraire';
  }

  @override
  String poiFoundedYear(int year) {
    return 'Fondé en $year';
  }

  @override
  String poiRating(String rating, int count) {
    return '$rating sur 5 ($count avis)';
  }

  @override
  String get poiAddToRoute => 'Ajouter à l\'itinéraire';

  @override
  String get scanTitle => 'Scanner un trip';

  @override
  String get scanInstruction => 'Scanner le QR code';

  @override
  String get scanDescription =>
      'Placez votre téléphone au-dessus d\'un QR code MapAB pour importer un trip partagé.';

  @override
  String get scanLoading => 'Chargement du trip...';

  @override
  String get scanInvalidCode => 'QR code invalide';

  @override
  String get scanInvalidMapabCode => 'QR code MapAB non valide';

  @override
  String get scanLoadError => 'Impossible de charger le trip';

  @override
  String get scanTripFound => 'Trip trouvé !';

  @override
  String scanStops(int count) {
    return '$count arrêts';
  }

  @override
  String scanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get scanImportQuestion => 'Voulez-vous importer ce trip ?';

  @override
  String get scanImport => 'Importer';

  @override
  String scanImportSuccess(String name) {
    return '$name a été importé !';
  }

  @override
  String get scanImportError => 'Impossible d\'importer le trip';

  @override
  String get templatesTitle => 'Modèles de voyage';

  @override
  String get templatesScanQr => 'Scanner QR code';

  @override
  String get templatesAudienceAll => 'Tous';

  @override
  String get templatesAudienceCouples => 'Couples';

  @override
  String get templatesAudienceFamilies => 'Familles';

  @override
  String get templatesAudienceAdventurers => 'Aventuriers';

  @override
  String get templatesAudienceFoodies => 'Gourmets';

  @override
  String get templatesAudiencePhotographers => 'Photographes';

  @override
  String templatesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String templatesCategories(int count) {
    return '$count catégories';
  }

  @override
  String get templatesIncludedCategories => 'Catégories incluses';

  @override
  String get templatesDuration => 'Durée du voyage';

  @override
  String templatesRecommended(int days, String daysText) {
    return 'Recommandé : $days $daysText';
  }

  @override
  String templatesBestSeason(String season) {
    return 'Meilleure saison : $season';
  }

  @override
  String get templatesStartPlanning => 'Planifier le voyage';

  @override
  String get seasonSpring => 'Printemps';

  @override
  String get seasonSummer => 'Été';

  @override
  String get seasonAutumn => 'Automne';

  @override
  String get seasonWinter => 'Hiver';

  @override
  String get seasonSpringAutumn => 'Printemps à automne';

  @override
  String get seasonYearRound => 'Toute l\'année';

  @override
  String get day => 'jour';

  @override
  String get days => 'jours';

  @override
  String get searchSelectStart => 'Choisir le départ';

  @override
  String get searchSelectDestination => 'Choisir la destination';

  @override
  String get searchStartHint => 'Rechercher le point de départ...';

  @override
  String get searchDestinationHint => 'Rechercher la destination...';

  @override
  String get searchOfflineMode =>
      'Pas d\'Internet - Affichage des suggestions locales';

  @override
  String get searchEnterLocation => 'Saisir un lieu pour rechercher';

  @override
  String get searchNoResults => 'Aucun résultat trouvé';

  @override
  String get searchLocationNotFound => 'Impossible de trouver le lieu';

  @override
  String get chatTitle => 'Assistant IA';

  @override
  String get chatClear => 'Vider le chat';

  @override
  String get chatWelcome =>
      'Bonjour ! Je suis votre assistant de voyage IA. Comment puis-je vous aider dans votre planification ?';

  @override
  String get chatInputHint => 'Saisir un message...';

  @override
  String get chatClearConfirm => 'Vider le chat ?';

  @override
  String get chatClearMessage => 'Toute la conversation sera supprimée.';

  @override
  String get chatCheckAgain => 'Vérifier à nouveau';

  @override
  String get chatAccept => 'Accepter';

  @override
  String chatShowAllPois(int count) {
    return 'Afficher tous les POIs';
  }

  @override
  String get chatDestinationOptional => 'Destination (optionnel)';

  @override
  String get chatEmptyRandomRoute =>
      'Vide = Itinéraire aléatoire autour du point de départ';

  @override
  String get chatStartOptional => 'Point de départ (optionnel)';

  @override
  String get chatEmptyUseGps => 'Vide = Utiliser la position GPS';

  @override
  String get chatIndoorTips => 'Conseils en intérieur par temps de pluie';

  @override
  String get chatPoisNearMe => 'POIs près de moi';

  @override
  String get chatAttractions => 'Sites touristiques';

  @override
  String get chatRestaurants => 'Restaurants';

  @override
  String get chatOutdoorHighlights => 'Points forts en plein air';

  @override
  String get chatNatureParks => 'Nature & Parcs';

  @override
  String get chatSearchRadius => 'Rayon de recherche';

  @override
  String get chatGenerateAiTrip => 'Générer un voyage IA';

  @override
  String get randomTripNoTrip => 'Aucun voyage généré';

  @override
  String get randomTripRegenerate => 'Régénérer';

  @override
  String get randomTripConfirm => 'Confirmer le voyage';

  @override
  String randomTripStopsDay(int day) {
    return 'Arrêts (Jour $day)';
  }

  @override
  String get randomTripStops => 'Arrêts';

  @override
  String get randomTripEnterAddress => 'Saisir une ville ou une adresse...';

  @override
  String get randomTripShowDetails => 'Afficher les détails';

  @override
  String get randomTripOpenGoogleMaps => 'Ouvrir dans Google Maps';

  @override
  String get randomTripSave => 'Sauvegarder le voyage';

  @override
  String get randomTripShow => 'Afficher le voyage';

  @override
  String get randomTripBack => 'Retour';

  @override
  String get mapModeAiDayTrip => 'AI Excursion';

  @override
  String get mapModeAiEuroTrip => 'AI Euro Trip';

  @override
  String get travelDuration => 'Durée du voyage';

  @override
  String get radiusLabel => 'Rayon';

  @override
  String get categoriesLabel => 'Catégories';

  @override
  String tripDescDayTrip(int radius) {
    return 'Excursion — env. $radius km';
  }

  @override
  String tripDescWeekend(int radius) {
    return 'Week-end — env. $radius km';
  }

  @override
  String tripDescShortVacation(int radius) {
    return 'Court séjour — env. $radius km';
  }

  @override
  String tripDescWeekTrip(int radius) {
    return 'Voyage d\'une semaine — env. $radius km';
  }

  @override
  String tripDescEpic(int radius) {
    return 'Épique Euro Trip — env. $radius km';
  }

  @override
  String selectedCount(int count) {
    return '$count sélectionnés';
  }

  @override
  String get destinationOptional => 'Destination (optionnel)';

  @override
  String get enterDestination => 'Saisir la destination...';

  @override
  String get mapCityOrAddress => 'Ville ou adresse...';

  @override
  String get mapAddDestination => 'Ajouter une destination (optionnel)';

  @override
  String get mapSurpriseMe => 'Surprends-moi !';

  @override
  String get mapDeleteRoute => 'Supprimer l\'itinéraire';

  @override
  String mapDaysLabel(String days) {
    return '$days jours';
  }

  @override
  String get mapPoiCategories => 'Catégories de POI';

  @override
  String get mapResetAll => 'Tout réinitialiser';

  @override
  String get mapAllCategoriesSelected => 'Toutes les catégories sélectionnées';

  @override
  String mapCategoriesSelected(String count, String total) {
    return '$count sur $total sélectionnées';
  }

  @override
  String get mapPoisAlongRoute => 'POIs le long de l\'itinéraire';

  @override
  String get mapWithoutDestination => 'Sans destination : circuit au départ';

  @override
  String get tripTypeDayTrip => 'Excursion d\'un jour';

  @override
  String get tripTypeEuroTrip => 'Euro Trip';

  @override
  String get tripTypeMultiDay => 'Voyage de plusieurs jours';

  @override
  String get tripTypeScenic => 'Itinéraire panoramique';

  @override
  String get tripTypeDayTripDistance => '30-200 km';

  @override
  String get tripTypeEuroTripDistance => '200-800 km';

  @override
  String get tripTypeMultiDayDistance => '2-7 jours';

  @override
  String get tripTypeScenicDistance => 'variable';

  @override
  String get tripTypeDayTripDesc => 'Sélection d\'activités, basé sur la météo';

  @override
  String get tripTypeEuroTripDesc => 'Autre pays, suggestions d\'hôtels';

  @override
  String get tripTypeMultiDayDesc => 'Arrêts d\'hébergement automatiques';

  @override
  String get tripTypeScenicDesc => 'Points de vue prioritaires';

  @override
  String get accessWheelchair => 'Accessible en fauteuil roulant';

  @override
  String get accessNoStairs => 'Sans escaliers';

  @override
  String get accessParking => 'Parking handicapés';

  @override
  String get accessToilet => 'Toilettes handicapés';

  @override
  String get accessElevator => 'Ascenseur disponible';

  @override
  String get accessBraille => 'Braille';

  @override
  String get accessAudioGuide => 'Guide audio';

  @override
  String get accessSignLanguage => 'Langue des signes';

  @override
  String get accessAssistDogs => 'Chiens d\'assistance autorisés';

  @override
  String get accessFullyAccessible => 'Entièrement accessible';

  @override
  String get accessLimited => 'Accès limité';

  @override
  String get accessNotAccessible => 'Non accessible';

  @override
  String get accessUnknown => 'Inconnu';

  @override
  String get highlightUnesco => 'Patrimoine mondial UNESCO';

  @override
  String get highlightMustSee => 'Must-See';

  @override
  String get highlightSecret => 'Bon plan';

  @override
  String get highlightHistoric => 'Historique';

  @override
  String get highlightFamilyFriendly => 'Adapté aux familles';

  @override
  String experienceDetourKm(int km) {
    return '+$km km de détour';
  }

  @override
  String get formatMinShort => 'min';

  @override
  String get formatHourShort => 'h';

  @override
  String get formatMinLong => 'minutes';

  @override
  String formatHourLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'heures',
      one: 'heure',
    );
    return '$_temp0';
  }

  @override
  String formatDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String formatStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arrêts',
      one: '1 arrêt',
    );
    return '$_temp0';
  }

  @override
  String get formatNoInfo => 'Aucune information';

  @override
  String get formatJustNow => 'À l\'instant';

  @override
  String formatAgoMinutes(int count) {
    return 'Il y a $count min';
  }

  @override
  String formatAgoHours(int count) {
    return 'Il y a $count h';
  }

  @override
  String formatAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count jours',
      one: 'Il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get formatUnknown => 'Inconnu';

  @override
  String get journalTitle => 'Carnet de voyage';

  @override
  String get journalEmptyTitle => 'Aucune entrée';

  @override
  String get journalEmptySubtitle =>
      'Capturez vos souvenirs de voyage avec des photos et des notes.';

  @override
  String get journalAddEntry => 'Ajouter une entrée';

  @override
  String get journalAddFirstEntry => 'Créer la première entrée';

  @override
  String get journalNewEntry => 'Nouvelle entrée';

  @override
  String get journalAddPhoto => 'Ajouter une photo';

  @override
  String get journalCamera => 'Appareil photo';

  @override
  String get journalGallery => 'Galerie';

  @override
  String get journalAddNote => 'Ajouter une note';

  @override
  String get journalNoteHint => 'Qu\'avez-vous vécu ?';

  @override
  String get journalSaveNote => 'Enregistrer la note uniquement';

  @override
  String get journalSaveLocation => 'Enregistrer la position';

  @override
  String get journalLocationAvailable => 'Position GPS disponible';

  @override
  String get journalLocationLoading => 'Chargement de la position...';

  @override
  String get journalEnterNote => 'Veuillez entrer une note';

  @override
  String get journalDeleteEntryTitle => 'Supprimer l\'entrée ?';

  @override
  String get journalDeleteEntryMessage =>
      'Cette entrée sera définitivement supprimée.';

  @override
  String get journalDeleteTitle => 'Supprimer le carnet ?';

  @override
  String get journalDeleteMessage =>
      'Toutes les entrées et photos seront définitivement supprimées.';

  @override
  String journalPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
      zero: 'Aucune photo',
    );
    return '$_temp0';
  }

  @override
  String journalEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '1 entrée',
      zero: 'Aucune entrée',
    );
    return '$_temp0';
  }

  @override
  String journalDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String journalDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String journalDayNumber(int day) {
    return 'Jour $day';
  }

  @override
  String get journalOther => 'Autres';

  @override
  String get journalEntry => 'entrée';

  @override
  String get journalEntriesPlural => 'entrées';

  @override
  String get journalOpenJournal => 'Ouvrir le carnet';

  @override
  String get journalAllJournals => 'Tous les carnets';

  @override
  String get journalNoJournals => 'Aucun carnet encore';

  @override
  String get galleryTitle => 'Galerie de trips';

  @override
  String get gallerySearch => 'Rechercher des trips...';

  @override
  String get galleryFeatured => 'À la une';

  @override
  String get galleryAllTrips => 'Tous les trips';

  @override
  String get galleryNoTrips => 'Aucun trip trouvé';

  @override
  String get galleryResetFilters => 'Réinitialiser les filtres';

  @override
  String get galleryFilter => 'Filtrer';

  @override
  String get galleryFilterReset => 'Réinitialiser';

  @override
  String get galleryTripType => 'Type de trip';

  @override
  String get galleryTags => 'Tags';

  @override
  String get gallerySort => 'Trier par';

  @override
  String get gallerySortPopular => 'Populaire';

  @override
  String get gallerySortRecent => 'Récent';

  @override
  String get gallerySortLikes => 'Plus aimés';

  @override
  String get galleryTypeAll => 'Tous';

  @override
  String get galleryTypeDaytrip => 'Excursion';

  @override
  String get galleryTypeEurotrip => 'Euro Trip';

  @override
  String get galleryRetry => 'Réessayer';

  @override
  String galleryLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
      zero: 'Aucun like',
    );
    return '$_temp0';
  }

  @override
  String galleryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vues',
      one: '1 vue',
    );
    return '$_temp0';
  }

  @override
  String galleryImports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imports',
      one: '1 import',
    );
    return '$_temp0';
  }

  @override
  String gallerySharedAt(String date) {
    return 'Partagé le $date';
  }

  @override
  String galleryTripsShared(int count) {
    return '$count trips partagés';
  }

  @override
  String get galleryImportToFavorites => 'Ajouter aux favoris';

  @override
  String get galleryImported => 'Importé';

  @override
  String get galleryShowOnMap => 'Sur la carte';

  @override
  String get galleryShareComingSoon => 'Partage bientôt disponible';

  @override
  String get galleryMapComingSoon => 'Vue carte bientôt disponible';

  @override
  String get galleryImportSuccess => 'Trip ajouté aux favoris';

  @override
  String get galleryImportError => 'Échec de l\'import';

  @override
  String get galleryTripNotFound => 'Trip non trouvé';

  @override
  String get galleryLoadError => 'Erreur de chargement';

  @override
  String get publishTitle => 'Publier le trip';

  @override
  String get publishSubtitle => 'Partagez votre trip avec la communauté';

  @override
  String get publishTripName => 'Nom du trip';

  @override
  String get publishTripNameHint => 'ex. Road trip Sud de la France';

  @override
  String get publishTripNameRequired => 'Veuillez entrer un nom';

  @override
  String get publishTripNameMinLength =>
      'Le nom doit contenir au moins 3 caractères';

  @override
  String get publishDescription => 'Description (optionnel)';

  @override
  String get publishDescriptionHint => 'Racontez votre trip aux autres...';

  @override
  String get publishTags => 'Tags (optionnel)';

  @override
  String get publishTagsHelper => 'Aidez les autres à trouver votre trip';

  @override
  String get publishMaxTags => 'Maximum 5 tags';

  @override
  String get publishInfo =>
      'Votre trip sera visible publiquement. Les autres peuvent l\'aimer et l\'importer dans leurs favoris.';

  @override
  String get publishButton => 'Publier';

  @override
  String get publishPublishing => 'Publication en cours...';

  @override
  String get publishSuccess => 'Trip publié !';

  @override
  String get publishError => 'Échec de la publication';

  @override
  String get publishEuroTrip => 'Euro Trip';

  @override
  String get publishDaytrip => 'Excursion';

  @override
  String get dayEditorDriveTime => 'Temps de trajet';

  @override
  String get dayEditorWeather => 'Météo';

  @override
  String get dayEditorDay => 'Jour';

  @override
  String dayEditorNoStopsForDay(int day) {
    return 'Pas d\'arrêts pour le jour $day';
  }

  @override
  String dayEditorDayInGoogleMaps(int day) {
    return 'Jour $day dans Google Maps';
  }

  @override
  String dayEditorOpenAgain(int day) {
    return 'Rouvrir le jour $day';
  }

  @override
  String get dayEditorTripCompleted => 'Trip terminé !';

  @override
  String get dayEditorRouteShare => 'Partager l\'itinéraire';

  @override
  String get dayEditorRouteShareError => 'Impossible de partager l\'itinéraire';

  @override
  String get dayEditorShareStops => 'Arrêts';

  @override
  String get dayEditorShareOpenGoogleMaps => 'Ouvrir dans Google Maps';

  @override
  String get tripSummaryTotal => 'Total';

  @override
  String get tripSummaryDriveTime => 'Temps de trajet';

  @override
  String get tripSummaryStops => 'Arrêts';

  @override
  String get filterTitle => 'Filtres';

  @override
  String get filterMaxDetour => 'Détour maximum';

  @override
  String get filterMaxDetourHint =>
      'Les POIs avec un détour plus long seront masqués';

  @override
  String get filterAllCategories => 'Afficher toutes les catégories';

  @override
  String filterSelectedCount(int count) {
    return '$count sélectionnées';
  }

  @override
  String get filterCategoriesLabel => 'Catégories';

  @override
  String get categorySelectorDeselectAll => 'Tout désélectionner';

  @override
  String get categorySelectorNoneHint =>
      'Aucune sélection = toutes les catégories';

  @override
  String categorySelectorSelectedCount(int count) {
    return '$count sélectionnées';
  }

  @override
  String get categorySelectorTitle => 'Catégories';

  @override
  String get startLocationLabel => 'Point de départ';

  @override
  String get startLocationHint => 'Entrez une ville ou une adresse...';

  @override
  String get startLocationGps => 'Utiliser la position GPS';

  @override
  String get tripPreviewNoTrip => 'Aucun trip généré';

  @override
  String get tripPreviewYourTrip => 'Votre Trip';

  @override
  String get tripPreviewConfirm => 'Confirmer le trip';

  @override
  String tripPreviewMaxStopsWarning(int max) {
    return 'Max $max arrêts par jour (limite Google Maps)';
  }

  @override
  String tripPreviewStopsDay(int day) {
    return 'Arrêts (Jour $day)';
  }

  @override
  String tripPreviewDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jours',
      one: 'Jour',
    );
    return '$_temp0';
  }

  @override
  String get navSkip => 'Passer';

  @override
  String get navVisitedButton => 'Visité';

  @override
  String navDistanceAway(String distance) {
    return 'à $distance';
  }

  @override
  String get chatDemoMode => 'Mode démo : les réponses sont simulées';

  @override
  String get chatLocationLoading => 'Chargement de la position...';

  @override
  String get chatLocationActive => 'Position active';

  @override
  String get chatLocationEnable => 'Activer la position';

  @override
  String get chatMyLocation => 'Ma position';

  @override
  String get chatRadiusTooltip => 'Rayon de recherche';

  @override
  String get chatNoPoisFound => 'Aucun POI trouvé à proximité';

  @override
  String chatPoisInRadius(int count, String radius) {
    return '$count POIs dans un rayon de $radius km';
  }

  @override
  String chatRadiusLabel(String radius) {
    return '$radius km';
  }

  @override
  String get chatWelcomeSubtitle =>
      'Posez-moi toutes vos questions sur votre voyage !';

  @override
  String get chatDemoBackendNotReachable => 'Mode démo : Backend non joignable';

  @override
  String get chatDemoBackendNotConfigured =>
      'Mode démo : URL du backend non configurée';

  @override
  String get chatNumberOfDays => 'Nombre de jours';

  @override
  String get chatInterests => 'Centres d\'intérêt :';

  @override
  String get chatLocationNotAvailable => 'Position non disponible';

  @override
  String get chatLocationNotAvailableMessage =>
      'Pour trouver des POIs près de vous, j\'ai besoin d\'accéder à votre position.\n\nVeuillez activer les services de localisation et réessayer.';

  @override
  String get chatPoisSearchError => 'Erreur lors de la recherche de POIs';

  @override
  String get chatPoisSearchErrorMessage =>
      'Désolé, un problème est survenu lors du chargement des POIs.\n\nVeuillez réessayer.';

  @override
  String get chatNoResponseGenerated =>
      'Désolé, je n\'ai pas pu générer de réponse.';

  @override
  String get chatRadiusAdjust => 'Ajuster le rayon de recherche';

  @override
  String get voiceRerouting => 'Recalcul de l\'itinéraire';

  @override
  String voicePOIApproaching(String name, String distance) {
    return '$name dans $distance';
  }

  @override
  String voiceArrivedAt(String name) {
    return 'Vous êtes arrivé à : $name';
  }

  @override
  String voiceRouteInfo(String distance, String duration) {
    return 'Encore $distance et $duration jusqu\'à la destination';
  }

  @override
  String voiceNextStop(String name, String distance) {
    return 'Prochain arrêt : $name dans $distance';
  }

  @override
  String voiceCurrentLocation(String location) {
    return 'Position actuelle : $location';
  }

  @override
  String voiceInMeters(int meters) {
    return '$meters mètres';
  }

  @override
  String voiceInKilometers(String km) {
    return '$km kilomètres';
  }

  @override
  String voiceHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String voiceMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String voiceStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arrêts',
      one: '1 arrêt',
    );
    return '$_temp0';
  }

  @override
  String get voiceCmdNextStop => 'Prochain arrêt';

  @override
  String get voiceCmdLocation => 'Où suis-je';

  @override
  String get voiceCmdDuration => 'Combien de temps encore';

  @override
  String get voiceCmdEndNavigation => 'Terminer la navigation';

  @override
  String get voiceNow => 'Maintenant';

  @override
  String get voiceArrived => 'Vous êtes arrivé à destination';

  @override
  String voicePOIReached(String name) {
    return '$name atteint';
  }

  @override
  String voiceCategory(String category) {
    return 'Catégorie : $category';
  }

  @override
  String voiceDistanceMeters(int meters) {
    return 'à $meters mètres';
  }

  @override
  String voiceDistanceKm(String km) {
    return 'à $km kilomètres';
  }

  @override
  String voiceRouteLength(String distance, String duration, String stops) {
    return 'Votre itinéraire fait $distance kilomètres, dure environ $duration et comporte $stops.';
  }

  @override
  String voiceAndMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return 'et $_temp0';
  }

  @override
  String get voiceCmdPreviousStop => 'Arrêt précédent';

  @override
  String get voiceCmdNearby => 'Qu\'y a-t-il à proximité';

  @override
  String get voiceCmdAdd => 'Ajouter à l\'itinéraire';

  @override
  String get voiceCmdStartNav => 'Démarrer la navigation';

  @override
  String get voiceCmdStopNav => 'Terminer la navigation';

  @override
  String get voiceCmdDescribe => 'Lire la description';

  @override
  String get voiceCmdUnknown => 'Inconnu';

  @override
  String get voiceCmdRouteWeather => 'Météo sur l\'itinéraire';

  @override
  String get voiceCmdRecommend => 'Recommandation';

  @override
  String get voiceCmdOverview => 'Aperçu de l\'itinéraire';

  @override
  String get voiceCmdRemaining => 'Arrêts restants';

  @override
  String get voiceCmdHelp => 'Aide';

  @override
  String get voiceCmdNotAvailable =>
      'Cette commande n\'est pas disponible pendant la navigation.';

  @override
  String get voiceGreeting1 => 'Prêt pour ton voyage ?';

  @override
  String get voiceGreeting2 => 'Comment puis-je t\'aider ?';

  @override
  String get voiceGreeting3 => 'Que veux-tu savoir ?';

  @override
  String get voiceGreeting4 => 'J\'écoute !';

  @override
  String get voiceGreeting5 => 'Demande-moi quelque chose !';

  @override
  String get voiceGreeting6 => 'Prêt pour ton trajet ?';

  @override
  String get voiceGreeting7 => 'Ton assistant de navigation ici !';

  @override
  String get voiceGreeting8 => 'Où allons-nous ?';

  @override
  String get voiceUnknown1 =>
      'Hmm, je n\'ai pas compris. Essaie Combien de temps ? ou Prochain arrêt.';

  @override
  String get voiceUnknown2 =>
      'Oups ! Mon cerveau de navi n\'a pas capté. Dis Aide pour toutes les commandes !';

  @override
  String get voiceUnknown3 =>
      'C\'était trop philosophique pour moi. Je ne suis qu\'un simple navigateur !';

  @override
  String get voiceUnknown4 =>
      'Hein ? Je suis un navigateur, pas un télépathe ! Demande-moi l\'itinéraire ou la météo.';

  @override
  String get voiceUnknown5 =>
      'Pas compris. Essaie Où suis-je ? ou Qu\'y a-t-il à proximité ?';

  @override
  String get voiceUnknown6 =>
      'Bip boop... Commande non reconnue ! Je comprends par exemple Combien de temps ?';

  @override
  String voiceWeatherOnRoute(String description, String temp) {
    return 'La météo sur ton itinéraire : $description, $temp degrés.';
  }

  @override
  String get voiceNoWeatherData =>
      'Malheureusement, je n\'ai pas de données météo pour ton itinéraire.';

  @override
  String voiceRecommendPOIs(String names) {
    return 'Je te recommande : $names. De vrais incontournables !';
  }

  @override
  String get voiceNoRecommendations =>
      'Il y a des arrêts intéressants sur ton itinéraire !';

  @override
  String voiceRouteOverview(String distance, String stops) {
    return 'Ton itinéraire fait $distance kilomètres avec $stops arrêts.';
  }

  @override
  String get voiceRemainingOne => 'Plus qu\'un arrêt avant la destination !';

  @override
  String voiceRemainingMultiple(int count) {
    return 'Encore $count arrêts devant toi.';
  }

  @override
  String get voiceHelpText =>
      'Tu peux me demander : Combien de temps ? Prochain arrêt ? Où suis-je ? Quel temps fait-il ? Des recommandations ? Ou dis Terminer navigation.';

  @override
  String voiceManeuverNow(String instruction) {
    return 'Maintenant $instruction';
  }

  @override
  String voiceManeuverInMeters(int meters, String instruction) {
    return 'Dans $meters mètres $instruction';
  }

  @override
  String voiceManeuverInKm(String km, String instruction) {
    return 'Dans $km kilomètres $instruction';
  }

  @override
  String navMustSeeAnnouncement(String distance, String name) {
    return 'Dans $distance mètres se trouve $name, un incontournable';
  }

  @override
  String advisorDangerWeather(int day, int outdoorCount) {
    return 'Alerte météo prévue pour le jour $day ! $outdoorCount arrêts extérieurs devraient être remplacés par des alternatives intérieures.';
  }

  @override
  String advisorBadWeather(int day, int outdoorCount, int totalCount) {
    return 'Pluie prévue pour le jour $day. $outdoorCount sur $totalCount arrêts sont des activités extérieures.';
  }

  @override
  String advisorOutdoorAlternative(String name) {
    return '$name est une activité extérieure - alternative recommandée';
  }

  @override
  String advisorOutdoorReplace(String name) {
    return '$name est une activité extérieure. Remplacez cet arrêt par une alternative intérieure.';
  }

  @override
  String get advisorAiUnavailableSuggestions =>
      'IA indisponible - affichage des suggestions locales';

  @override
  String advisorNoStopsForDay(int day) {
    return 'Aucun arrêt pour le jour $day';
  }

  @override
  String get advisorNoRecommendationsFound =>
      'Aucune recommandation trouvée à proximité des arrêts';

  @override
  String get advisorAiUnavailableRecommendations =>
      'IA indisponible - affichage des recommandations locales';

  @override
  String get advisorErrorLoadingRecommendations =>
      'Erreur lors du chargement des recommandations';

  @override
  String advisorPoiCategory(String name, String category) {
    return '$name - $category';
  }

  @override
  String get weatherConditionGood => 'Beau temps';

  @override
  String get weatherConditionMixed => 'Variable';

  @override
  String get weatherConditionBad => 'Mauvais temps';

  @override
  String get weatherConditionDanger => 'Alerte météo';

  @override
  String get weatherConditionUnknown => 'Météo inconnue';

  @override
  String get weatherBadgeSnow => 'Neige';

  @override
  String get weatherBadgeRain => 'Pluie';

  @override
  String get weatherBadgePerfect => 'Parfait';

  @override
  String get weatherBadgeBad => 'Mauvais';

  @override
  String get weatherBadgeDanger => 'Alerte';

  @override
  String get weatherRecOutdoorIdeal => 'Idéal pour les POIs en extérieur';

  @override
  String get weatherRecRainIndoor => 'Pluie - POIs intérieurs recommandés';

  @override
  String get weatherRecDangerIndoor =>
      'Intempéries - POIs intérieurs uniquement !';

  @override
  String get weatherToggleActive => 'Actif';

  @override
  String get weatherToggleApply => 'Appliquer';

  @override
  String get weatherPointStart => 'Départ';

  @override
  String get weatherPointEnd => 'Arrivée';

  @override
  String get weatherIndoorOnly => 'POIs intérieurs uniquement';

  @override
  String weatherAlertStorm(String windSpeed) {
    return 'Alerte tempête ! Vents forts ($windSpeed km/h) le long du trajet.';
  }

  @override
  String get weatherAlertDanger => 'Alerte météo ! Report recommandé.';

  @override
  String get weatherAlertWinter => 'Temps hivernal ! Neige/verglas possible.';

  @override
  String get weatherAlertRain =>
      'Pluie prévue. Activités intérieures recommandées.';

  @override
  String get weatherAlertBad => 'Mauvais temps sur le trajet.';

  @override
  String get weatherRecToday => 'Recommandation du jour';

  @override
  String get weatherRecGoodDetail =>
      'Temps parfait pour les activités en extérieur ! Points de vue, nature et lacs recommandés.';

  @override
  String get weatherRecMixedDetail =>
      'Temps variable. POIs intérieurs et extérieurs possibles.';

  @override
  String get weatherRecBadDetail =>
      'Pluie prévue. Activités intérieures comme musées et églises recommandées.';

  @override
  String get weatherRecDangerDetail =>
      'Alerte météo ! Évitez les activités en extérieur et restez à l\'intérieur.';

  @override
  String get weatherRecNoData => 'Aucune donnée météo disponible.';

  @override
  String get weatherRecOutdoorPerfect =>
      'Temps parfait pour les activités en extérieur';

  @override
  String get weatherRecMixedPrepare => 'Variable - soyez prêt à tout';

  @override
  String get weatherRecSnowCaution =>
      'Chutes de neige - prudence sur les routes glissantes';

  @override
  String get weatherRecBadIndoor =>
      'Mauvais temps - activités intérieures recommandées';

  @override
  String weatherRecStormWarning(String windSpeed) {
    return 'Alerte tempête ! Vents forts ($windSpeed km/h)';
  }

  @override
  String get weatherRecDangerCaution =>
      'Alerte météo ! Prudence sur ce tronçon';

  @override
  String get weatherRecNoDataAvailable => 'Aucune donnée météo disponible';

  @override
  String get mapMyLocation => 'Ma position';

  @override
  String get mapDetails => 'Détails';

  @override
  String get mapAddToRoute => 'Ajouter au trajet';

  @override
  String get mapSelectedPoint => 'Point sélectionné';

  @override
  String get mapWaypoint => 'Étape';

  @override
  String mapRouteCreated(String name) {
    return 'Itinéraire vers \"$name\" créé';
  }

  @override
  String mapPoiAdded(String name) {
    return '\"$name\" ajouté';
  }

  @override
  String get mapErrorAdding => 'Erreur lors de l\'ajout';

  @override
  String get tripPreviewStartDay1 => 'Départ (Jour 1)';

  @override
  String tripPreviewDayStart(String day) {
    return 'Jour $day départ';
  }

  @override
  String get tripPreviewBackToStart => 'Retour au départ';

  @override
  String tripPreviewEndDay(String day) {
    return 'Fin jour $day';
  }

  @override
  String tripPreviewDetour(String km) {
    return '+$km km détour';
  }

  @override
  String get tripPreviewOvernight => 'Hébergement';

  @override
  String get gamificationLevelUp => 'Niveau supérieur !';

  @override
  String gamificationNewLevel(int level) {
    return 'Niveau $level';
  }

  @override
  String get gamificationContinue => 'Continuer';

  @override
  String get gamificationAchievementUnlocked => 'Succès débloqué !';

  @override
  String get gamificationAwesome => 'Génial !';

  @override
  String gamificationXpEarned(int amount) {
    return '+$amount XP';
  }

  @override
  String get gamificationNextAchievements => 'Prochains succès';

  @override
  String get gamificationAllAchievements => 'Tous les succès';

  @override
  String gamificationUnlockedCount(int count, int total) {
    return '$count/$total débloqués';
  }

  @override
  String get gamificationTripCreated => 'Voyage créé';

  @override
  String get gamificationTripPublished => 'Voyage publié';

  @override
  String get gamificationTripImported => 'Voyage importé';

  @override
  String get gamificationPoiVisited => 'POI visité';

  @override
  String get gamificationPhotoAdded => 'Photo ajoutée';

  @override
  String get gamificationLikeReceived => 'Like reçu';

  @override
  String get poiRatingLabel => 'Évaluation';

  @override
  String get poiReviews => 'Avis';

  @override
  String get poiPhotos => 'Photos';

  @override
  String get poiComments => 'Commentaires';

  @override
  String get poiNoReviews => 'Pas encore d\'avis';

  @override
  String get poiNoPhotos => 'Pas encore de photos';

  @override
  String get poiNoComments => 'Pas encore de commentaires';

  @override
  String get poiBeFirstReview => 'Soyez le premier à évaluer ce lieu !';

  @override
  String get poiBeFirstPhoto => 'Soyez le premier à partager une photo !';

  @override
  String get poiBeFirstComment => 'Écrivez le premier commentaire !';

  @override
  String poiReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
      zero: 'Aucun avis',
    );
    return '$_temp0';
  }

  @override
  String poiPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
      zero: 'Aucune photo',
    );
    return '$_temp0';
  }

  @override
  String poiCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires',
      one: '1 commentaire',
      zero: 'Aucun commentaire',
    );
    return '$_temp0';
  }

  @override
  String get reviewSubmit => 'Soumettre un avis';

  @override
  String get reviewEdit => 'Modifier l\'avis';

  @override
  String get reviewYourRating => 'Votre note';

  @override
  String get reviewWriteOptional => 'Écrire un avis (optionnel)';

  @override
  String get reviewPlaceholder =>
      'Partagez votre expérience avec les autres...';

  @override
  String get reviewVisitDate => 'Date de visite';

  @override
  String get reviewVisitDateOptional => 'Date de visite (optionnel)';

  @override
  String reviewVisitedOn(String date) {
    return 'Visité le $date';
  }

  @override
  String get reviewHelpful => 'Utile';

  @override
  String reviewHelpfulCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes ont trouvé cela utile',
      one: '1 personne a trouvé cela utile',
      zero: 'Pas encore évalué',
    );
    return '$_temp0';
  }

  @override
  String get reviewMarkedHelpful => 'Marqué comme utile';

  @override
  String get reviewSuccess => 'Avis enregistré !';

  @override
  String get reviewError => 'Erreur lors de l\'enregistrement de l\'avis';

  @override
  String get reviewDelete => 'Supprimer l\'avis';

  @override
  String get reviewDeleteConfirm =>
      'Voulez-vous vraiment supprimer votre avis ?';

  @override
  String get reviewDeleteSuccess => 'Avis supprimé';

  @override
  String get reviewDeleteError => 'Erreur lors de la suppression de l\'avis';

  @override
  String get reviewRatingRequired => 'Veuillez sélectionner une note';

  @override
  String reviewAvgRating(String rating) {
    return '$rating sur 5 étoiles';
  }

  @override
  String get photoUpload => 'Télécharger une photo';

  @override
  String get photoCaption => 'Légende';

  @override
  String get photoCaptionHint => 'Décrivez votre photo (optionnel)';

  @override
  String get photoFromCamera => 'Appareil photo';

  @override
  String get photoFromGallery => 'Galerie';

  @override
  String get photoUploading => 'Téléchargement de la photo...';

  @override
  String get photoSuccess => 'Photo téléchargée !';

  @override
  String get photoError => 'Erreur lors du téléchargement de la photo';

  @override
  String get photoDelete => 'Supprimer la photo';

  @override
  String get photoDeleteConfirm =>
      'Voulez-vous vraiment supprimer cette photo ?';

  @override
  String get photoDeleteSuccess => 'Photo supprimée';

  @override
  String get photoDeleteError => 'Erreur lors de la suppression de la photo';

  @override
  String photoBy(String author) {
    return 'Photo de $author';
  }

  @override
  String get commentAdd => 'Ajouter un commentaire';

  @override
  String get commentPlaceholder => 'Écrire un commentaire...';

  @override
  String get commentReply => 'Répondre';

  @override
  String commentReplyTo(String author) {
    return 'Réponse à $author';
  }

  @override
  String get commentDelete => 'Supprimer le commentaire';

  @override
  String get commentDeleteConfirm =>
      'Voulez-vous vraiment supprimer ce commentaire ?';

  @override
  String get commentDeleteSuccess => 'Commentaire supprimé';

  @override
  String get commentDeleteError =>
      'Erreur lors de la suppression du commentaire';

  @override
  String commentShowReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher $count réponses',
      one: 'Afficher 1 réponse',
    );
    return '$_temp0';
  }

  @override
  String get commentHideReplies => 'Masquer les réponses';

  @override
  String get commentSuccess => 'Commentaire publié !';

  @override
  String get commentError => 'Erreur lors de la publication du commentaire';

  @override
  String get commentEmpty => 'Veuillez écrire un commentaire';

  @override
  String get adminDashboard => 'Tableau de bord admin';

  @override
  String get adminNotifications => 'Notifications';

  @override
  String get adminModeration => 'Modération';

  @override
  String get adminNewPhotos => 'Nouvelles photos';

  @override
  String get adminNewReviews => 'Nouveaux avis';

  @override
  String get adminNewComments => 'Nouveaux commentaires';

  @override
  String get adminFlaggedContent => 'Contenu signalé';

  @override
  String get adminDelete => 'Supprimer';

  @override
  String get adminDeleteConfirm =>
      'Voulez-vous vraiment supprimer ce contenu ?';

  @override
  String get adminDeleteSuccess => 'Contenu supprimé';

  @override
  String get adminDeleteError => 'Erreur lors de la suppression';

  @override
  String get adminApprove => 'Approuver';

  @override
  String get adminApproveSuccess => 'Contenu approuvé';

  @override
  String get adminApproveError => 'Erreur lors de l\'approbation';

  @override
  String get adminMarkRead => 'Marquer comme lu';

  @override
  String get adminMarkAllRead => 'Tout marquer comme lu';

  @override
  String get adminNoNotifications => 'Aucune nouvelle notification';

  @override
  String get adminNoFlagged => 'Aucun contenu signalé';

  @override
  String get adminStats => 'Statistiques';

  @override
  String adminUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non lus',
      one: '1 non lu',
      zero: 'Aucun non lu',
    );
    return '$_temp0';
  }

  @override
  String adminFlaggedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signalés',
      one: '1 signalé',
      zero: 'Aucun signalé',
    );
    return '$_temp0';
  }

  @override
  String get adminNotificationNewPhoto => 'Nouvelle photo téléchargée';

  @override
  String get adminNotificationNewReview => 'Nouvel avis';

  @override
  String get adminNotificationNewComment => 'Nouveau commentaire';

  @override
  String get adminNotificationFlagged => 'Contenu signalé';

  @override
  String get socialLoginRequired =>
      'Veuillez vous connecter pour utiliser cette fonctionnalité';

  @override
  String get socialRatingRequired => 'Veuillez sélectionner une note';

  @override
  String get reportContent => 'Signaler le contenu';

  @override
  String get reportSuccess => 'Merci ! Le contenu a été signalé pour examen.';

  @override
  String get reportError => 'Erreur lors du signalement du contenu';

  @override
  String get reportReason => 'Motif du signalement';

  @override
  String get reportReasonHint =>
      'Décrivez pourquoi ce contenu devrait être signalé...';

  @override
  String get anonymousUser => 'Anonyme';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';
}
