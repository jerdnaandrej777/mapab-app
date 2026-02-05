// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MapAB';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get or => 'OR';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading...';

  @override
  String get search => 'Search';

  @override
  String get show => 'Show';

  @override
  String get apply => 'Apply';

  @override
  String get active => 'Active';

  @override
  String get discard => 'Discard';

  @override
  String get resume => 'Resume';

  @override
  String get skip => 'Skip';

  @override
  String get all => 'All';

  @override
  String get total => 'Total';

  @override
  String get newLabel => 'New';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destination';

  @override
  String get showOnMap => 'Show on map';

  @override
  String get openSettings => 'Open settings';

  @override
  String get actionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get details => 'Details';

  @override
  String get generate => 'Generate';

  @override
  String get clear => 'Clear';

  @override
  String get reset => 'Reset';

  @override
  String get end => 'End';

  @override
  String get reroll => 'Reroll';

  @override
  String get filterApply => 'Apply filter';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get shareLinkCopied => 'Link copied to clipboard!';

  @override
  String get shareAsText => 'Share as text';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get errorNetwork => 'No internet connection';

  @override
  String get errorNetworkMessage =>
      'Please check your connection and try again.';

  @override
  String get errorServer => 'Server unreachable';

  @override
  String get errorServerMessage =>
      'The server is not responding. Try again later.';

  @override
  String get errorNoResults => 'No results';

  @override
  String get errorLocation => 'Location unavailable';

  @override
  String get errorLocationMessage => 'Please allow access to your location.';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get goToHome => 'Go to home';

  @override
  String get errorRouteCalculation =>
      'Route calculation failed. Please try again.';

  @override
  String errorTripGeneration(String error) {
    return 'Trip generation failed: $error';
  }

  @override
  String get errorGoogleMapsNotOpened => 'Could not open Google Maps';

  @override
  String get errorRouteNotShared => 'Could not share route';

  @override
  String get errorAddingToRoute => 'Error adding to route';

  @override
  String get errorIncompleteRouteData => 'Route data is incomplete';

  @override
  String get gpsDisabledTitle => 'GPS disabled';

  @override
  String get gpsDisabledMessage =>
      'Location services are disabled. Would you like to open GPS settings?';

  @override
  String get gpsPermissionDenied => 'GPS permission denied';

  @override
  String get gpsPermissionDeniedForeverTitle => 'GPS permission denied';

  @override
  String get gpsPermissionDeniedForeverMessage =>
      'GPS permission has been permanently denied. Please enable location access in app settings.';

  @override
  String get gpsCouldNotDetermine => 'Could not determine GPS position';

  @override
  String get appSettingsButton => 'App settings';

  @override
  String get myLocation => 'My location';

  @override
  String get authWelcomeTitle => 'Welcome to MapAB';

  @override
  String get authWelcomeSubtitle =>
      'Your AI travel planner for unforgettable trips';

  @override
  String get authCloudNotAvailable =>
      'Cloud not available - app built without Supabase credentials';

  @override
  String get authCloudLoginUnavailable =>
      'Cloud login unavailable - app built without Supabase credentials';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailEmpty => 'Please enter email';

  @override
  String get authEmailInvalid => 'Invalid email';

  @override
  String get authEmailInvalidAddress => 'Invalid email address';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordEmpty => 'Please enter password';

  @override
  String get authPasswordMinLength => 'At least 8 characters';

  @override
  String get authPasswordRequirements => 'Must contain letters and numbers';

  @override
  String get authPasswordConfirm => 'Confirm password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authRegister => 'Register';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authGuestInfoCloud =>
      'As a guest, your data is only stored locally and not synchronized.';

  @override
  String get authGuestInfoLocal =>
      'Your data is stored locally on your device.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSecureData => 'Secure your data in the cloud';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authNameHint => 'What would you like to be called?';

  @override
  String get authNameEmpty => 'Please enter name';

  @override
  String get authNameMinLength => 'Name must be at least 2 characters';

  @override
  String get authAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get authExistingAccount => 'I already have an account';

  @override
  String get authRegistrationSuccess => 'Registration successful';

  @override
  String get authRegistrationSuccessMessage =>
      'Please check your email and confirm your account.';

  @override
  String get authResetPassword => 'Reset password';

  @override
  String get authResetPasswordInstructions =>
      'Enter your email address and we\'ll send you a reset link.';

  @override
  String get authSendLink => 'Send link';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String get authEmailSent => 'Email sent!';

  @override
  String get authEmailSentPrefix => 'We\'ve sent an email to';

  @override
  String get authEmailSentSuffix => '.';

  @override
  String get authResetLinkInstructions =>
      'Click the link in the email to set a new password. The link is valid for 24 hours.';

  @override
  String get authResend => 'Resend';

  @override
  String get authCreateLocalProfile => 'Create local profile';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authUsernameHint => 'e.g. travelfan123';

  @override
  String get authDisplayNameLabel => 'Display name';

  @override
  String get authDisplayNameHint => 'e.g. John Doe';

  @override
  String get authEmailOptional => 'Email (optional)';

  @override
  String get authEmailHint => 'e.g. john@example.com';

  @override
  String get authCreate => 'Create';

  @override
  String get authRequiredFields => 'Username and display name are required';

  @override
  String get authGuestDescription =>
      'As a guest, you can start right away. Your data is stored locally on your device.';

  @override
  String get authComingSoon => 'Cloud login coming soon:';

  @override
  String get authLoadingText => 'Loading...';

  @override
  String get splashTagline => 'Your AI Travel Planner';

  @override
  String get onboardingTitle1 => 'Discover Attractions';

  @override
  String get onboardingHighlight1 => 'Attractions';

  @override
  String get onboardingSubtitle1 =>
      'Find over 500 handpicked POIs across Europe.\nCastles, lakes, museums and hidden gems await you.';

  @override
  String get onboardingTitle2 => 'Your AI Travel Assistant';

  @override
  String get onboardingHighlight2 => 'AI';

  @override
  String get onboardingSubtitle2 =>
      'Let us automatically plan the perfect route for you.\nWith smart optimization for your interests.';

  @override
  String get onboardingTitle3 => 'Your Trips in the Cloud';

  @override
  String get onboardingHighlight3 => 'Cloud';

  @override
  String get onboardingSubtitle3 =>
      'Save favorites and trips securely online.\nSynchronized across all your devices.';

  @override
  String get onboardingStart => 'Let\'s go';

  @override
  String get categoryCastle => 'Castles & Fortresses';

  @override
  String get categoryNature => 'Nature & Forests';

  @override
  String get categoryMuseum => 'Museums';

  @override
  String get categoryViewpoint => 'Viewpoints';

  @override
  String get categoryLake => 'Lakes';

  @override
  String get categoryCoast => 'Coasts & Beaches';

  @override
  String get categoryPark => 'Parks & National Parks';

  @override
  String get categoryCity => 'Cities';

  @override
  String get categoryActivity => 'Activities';

  @override
  String get categoryHotel => 'Hotels';

  @override
  String get categoryRestaurant => 'Restaurants';

  @override
  String get categoryUnesco => 'UNESCO World Heritage';

  @override
  String get categoryChurch => 'Churches';

  @override
  String get categoryMonument => 'Monuments';

  @override
  String get categoryAttraction => 'Attractions';

  @override
  String get weatherGood => 'Good';

  @override
  String get weatherMixed => 'Mixed';

  @override
  String get weatherBad => 'Bad';

  @override
  String get weatherDanger => 'Dangerous';

  @override
  String get weatherUnknown => 'Unknown';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherMostlyClear => 'Mostly clear';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherFreezingDrizzle => 'Freezing drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherFreezingRain => 'Freezing rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherSnowGrains => 'Snow grains';

  @override
  String get weatherRainShowers => 'Rain showers';

  @override
  String get weatherSnowShowers => 'Snow showers';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherThunderstormHail => 'Thunderstorm with hail';

  @override
  String get weatherForecast7Day => '7-day forecast';

  @override
  String get weatherToday => 'Today';

  @override
  String weatherFeelsLike(String temp) {
    return 'Feels like $temp°';
  }

  @override
  String get weatherSunrise => 'Sunrise';

  @override
  String get weatherSunset => 'Sunset';

  @override
  String get weatherUvIndex => 'UV Index';

  @override
  String get weatherPrecipitation => 'Precipitation';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherRainRisk => 'Rain risk';

  @override
  String get weatherRecommendationToday => 'Recommendation for today';

  @override
  String get weatherRecGood =>
      'Perfect weather for outdoor activities! Viewpoints, nature and lakes recommended.';

  @override
  String get weatherRecMixed => 'Changeable - plan flexibly';

  @override
  String get weatherRecBad =>
      'Rain expected. Indoor activities like museums and churches recommended.';

  @override
  String get weatherRecDanger =>
      'Storm warning! Please avoid outdoor activities and stay indoors.';

  @override
  String get weatherRecUnknown => 'No weather data available.';

  @override
  String weatherUvLow(String value) {
    return '$value (Low)';
  }

  @override
  String weatherUvMedium(String value) {
    return '$value (Medium)';
  }

  @override
  String weatherUvHigh(String value) {
    return '$value (High)';
  }

  @override
  String weatherUvVeryHigh(String value) {
    return '$value (Very high)';
  }

  @override
  String weatherUvExtreme(String value) {
    return '$value (Extreme)';
  }

  @override
  String get weatherLoading => 'Loading weather...';

  @override
  String get weatherWinterWeather => 'Winter weather';

  @override
  String get weatherStormOnRoute => 'Severe weather on route';

  @override
  String get weatherRainPossible => 'Rain possible';

  @override
  String get weatherGoodWeather => 'Good weather';

  @override
  String get weatherChangeable => 'Changeable';

  @override
  String get weatherBadWeather => 'Bad weather';

  @override
  String get weatherStormWarning => 'Storm warning';

  @override
  String get weatherPerfect => 'Perfect';

  @override
  String get weatherStorm => 'Storm';

  @override
  String get weatherIdealOutdoor => 'Ideal for outdoor POIs today';

  @override
  String get weatherFlexiblePlanning => 'Changeable - plan flexibly';

  @override
  String get weatherRainIndoor => 'Rain - indoor POIs recommended';

  @override
  String get weatherStormIndoorOnly => 'Storm - indoor POIs only!';

  @override
  String get weatherOnlyIndoor => 'Indoor POIs only';

  @override
  String weatherStormHighWinds(String speed) {
    return 'Storm warning! Strong winds ($speed km/h) along the route.';
  }

  @override
  String get weatherStormDelay => 'Storm warning! Postponing trip recommended.';

  @override
  String get weatherWinterWarning => 'Winter weather! Snow/ice possible.';

  @override
  String get weatherRainRecommendation =>
      'Rain expected. Indoor activities recommended.';

  @override
  String get weatherBadOnRoute => 'Bad weather on route.';

  @override
  String get weatherPerfectOutdoor => 'Perfect weather for outdoor activities';

  @override
  String get weatherBePrepared => 'Changeable - be prepared for anything';

  @override
  String get weatherSnowWarning => 'Snow - caution on slippery roads';

  @override
  String get weatherBadIndoor => 'Bad weather - indoor activities recommended';

  @override
  String get weatherStormCaution => 'Storm warning! Caution on this section';

  @override
  String get weatherNoData => 'No weather data available';

  @override
  String weatherRoutePoint(String index, String total) {
    return 'Route point $index of $total';
  }

  @override
  String weatherExpectedOnDay(String weather, int day) {
    return '$weather expected on day $day';
  }

  @override
  String weatherOutdoorStops(int outdoor, int total) {
    return '$outdoor of $total stops are outdoor activities.';
  }

  @override
  String get weatherSuggestIndoor => 'Suggest indoor alternatives';

  @override
  String get weatherStormExpected => 'Storm expected';

  @override
  String get weatherRainExpected => 'Rain expected';

  @override
  String get weatherIdealOutdoorWeather => 'Ideal outdoor weather';

  @override
  String get weatherStormIndoorPrefer => 'Storm expected – prefer indoor stops';

  @override
  String get weatherRainIndoorHighlight =>
      'Rain expected – indoor stops highlighted';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get mapFavorites => 'Favorites';

  @override
  String get mapProfile => 'Profile';

  @override
  String get mapSettings => 'Settings';

  @override
  String get mapToRoute => 'To route';

  @override
  String get mapSetAsStart => 'Set as start';

  @override
  String get mapSetAsDestination => 'Set as destination';

  @override
  String get mapAddAsStop => 'Add as stop';

  @override
  String get tripConfigGps => 'GPS';

  @override
  String get tripConfigCityOrAddress => 'City or address...';

  @override
  String get tripConfigDestinationOptional => 'Destination (optional)';

  @override
  String get tripConfigAddDestination => 'Add destination (optional)';

  @override
  String get tripConfigEnterDestination => 'Enter destination...';

  @override
  String get tripConfigNoDestinationRoundtrip =>
      'No destination: Round trip from start';

  @override
  String get tripConfigSurpriseMe => 'Surprise me!';

  @override
  String get tripConfigDeleteRoute => 'Delete route';

  @override
  String get tripConfigTripDuration => 'Trip duration';

  @override
  String get tripConfigDay => 'Day';

  @override
  String get tripConfigDays => 'Days';

  @override
  String tripConfigDayTrip(String distance) {
    return 'Day trip — approx. $distance km';
  }

  @override
  String tripConfigWeekendTrip(String distance) {
    return 'Weekend trip — approx. $distance km';
  }

  @override
  String tripConfigShortVacation(String distance) {
    return 'Short vacation — approx. $distance km';
  }

  @override
  String tripConfigWeekTravel(String distance) {
    return 'Week trip — approx. $distance km';
  }

  @override
  String tripConfigEpicEuroTrip(String distance) {
    return 'Epic Euro trip — approx. $distance km';
  }

  @override
  String get tripConfigRadius => 'Radius';

  @override
  String get tripConfigPoiCategories => 'POI categories';

  @override
  String get tripConfigResetAll => 'Reset all';

  @override
  String get tripConfigAllCategories => 'All categories selected';

  @override
  String tripConfigCategoriesSelected(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get tripConfigCategories => 'Categories';

  @override
  String tripConfigSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get tripConfigPoisAlongRoute => 'POIs along route';

  @override
  String get tripConfigActiveTripTitle => 'Active trip exists';

  @override
  String tripConfigActiveTripMessage(int days, int completed) {
    return 'You have an active $days-day trip with $completed completed days. A new trip will overwrite this.';
  }

  @override
  String get tripConfigCreateNewTrip => 'Create new trip';

  @override
  String get tripInfoGenerating => 'Generating trip...';

  @override
  String get tripInfoLoadingPois => 'Loading POIs, optimizing route';

  @override
  String get tripInfoAiEuroTrip => 'AI Euro Trip';

  @override
  String get tripInfoAiDayTrip => 'AI Day Trip';

  @override
  String get tripInfoEditTrip => 'Edit trip';

  @override
  String get tripInfoStartNavigation => 'Start navigation';

  @override
  String get tripInfoStops => 'Stops';

  @override
  String get tripInfoDistance => 'Distance';

  @override
  String get tripInfoDaysLabel => 'Days';

  @override
  String get activeTripTitle => 'Active Euro Trip';

  @override
  String get activeTripDiscard => 'Discard active trip';

  @override
  String get activeTripDiscardTitle => 'Discard trip?';

  @override
  String activeTripDiscardMessage(int days, int completed) {
    return 'Your $days-day trip with $completed completed days will be deleted.';
  }

  @override
  String activeTripDayPending(int day) {
    return 'Day $day is pending';
  }

  @override
  String activeTripDaysCompleted(int completed, int total) {
    return '$completed of $total days completed';
  }

  @override
  String get tripModeAiDayTrip => 'AI Day Trip';

  @override
  String get tripModeAiEuroTrip => 'AI Euro Trip';

  @override
  String get tripRoutePlanning => 'Route planning';

  @override
  String get tripNoRoute => 'No route available';

  @override
  String get tripTapMap => 'Tap the map to set start and destination';

  @override
  String get tripToMap => 'To map';

  @override
  String get tripGeneratingDescription =>
      'Loading POIs, optimizing route, searching hotels';

  @override
  String get tripElevationLoading => 'Loading elevation profile...';

  @override
  String get tripSaveRoute => 'Save route';

  @override
  String get tripRouteName => 'Route name';

  @override
  String get tripExampleDayTrip => 'e.g. Weekend trip';

  @override
  String get tripExampleAiDayTrip => 'e.g. AI Day Trip';

  @override
  String get tripExampleAiEuroTrip => 'e.g. AI Euro Trip';

  @override
  String tripRouteSaved(String name) {
    return 'Route \"$name\" saved';
  }

  @override
  String get tripYourRoute => 'Your route';

  @override
  String get tripDrivingTime => 'Driving time';

  @override
  String get tripStopRemoved => 'Stop removed';

  @override
  String get tripOptimizeRoute => 'Optimize route';

  @override
  String get tripOptimizeBestOrder => 'Calculate best order';

  @override
  String get tripShareRoute => 'Share route';

  @override
  String get tripDeleteAllStops => 'Delete all stops';

  @override
  String get tripDeleteEntireRoute => 'Delete entire route';

  @override
  String get tripDeleteRouteAndStops => 'Delete route and all stops';

  @override
  String get tripConfirmDeleteAllStops => 'Delete all stops?';

  @override
  String get tripConfirmDeleteEntireRoute => 'Delete entire route?';

  @override
  String get tripDeleteEntireRouteMessage =>
      'The route and all stops will be deleted. This action cannot be undone.';

  @override
  String get tripBackToConfig => 'Back to configuration';

  @override
  String tripExportDay(int day) {
    return 'Day $day in Google Maps';
  }

  @override
  String tripReExportDay(int day) {
    return 'Re-export day $day';
  }

  @override
  String get tripGoogleMapsHint =>
      'Google Maps will calculate its own route through the stops';

  @override
  String tripNoStopsForDay(int day) {
    return 'No stops for day $day';
  }

  @override
  String get tripCompleted => 'Trip completed!';

  @override
  String tripAllDaysExported(int days) {
    return 'All $days days have been successfully exported. Would you like to save the trip to your favorites?';
  }

  @override
  String get tripKeep => 'Keep';

  @override
  String get tripSaveToFavorites => 'Save to favorites';

  @override
  String get tripShareHeader => 'My route with MapAB';

  @override
  String tripShareStart(String address) {
    return 'Start: $address';
  }

  @override
  String tripShareEnd(String address) {
    return 'Destination: $address';
  }

  @override
  String tripShareDistance(String distance) {
    return 'Distance: $distance km';
  }

  @override
  String tripShareDuration(String duration) {
    return 'Duration: $duration min';
  }

  @override
  String get tripShareStops => 'Stops:';

  @override
  String get tripShareOpenMaps => 'Open in Google Maps:';

  @override
  String get tripMyRoute => 'My route';

  @override
  String get tripGoogleMaps => 'Google Maps';

  @override
  String get tripShowInFavorites => 'View';

  @override
  String get tripGoogleMapsError => 'Could not open Google Maps';

  @override
  String get tripShareError => 'Could not share route';

  @override
  String get tripWeatherDangerHint =>
      'Severe weather expected – prefer indoor stops';

  @override
  String get tripWeatherBadHint => 'Rain expected – indoor stops highlighted';

  @override
  String get tripStart => 'Start';

  @override
  String get tripDestination => 'Destination';

  @override
  String get tripNew => 'New';

  @override
  String get dayEditorTitle => 'Edit trip';

  @override
  String get dayEditorNoTrip => 'No trip available';

  @override
  String get dayEditorStartNotAvailable => 'Start point not available';

  @override
  String dayEditorEditDay(int day) {
    return 'Edit day $day';
  }

  @override
  String get dayEditorRegenerate => 'Regenerate';

  @override
  String dayEditorMaxStops(int max) {
    return 'Max $max stops per day possible in Google Maps';
  }

  @override
  String get dayEditorSearchRecommendations =>
      'Searching POI recommendations...';

  @override
  String get dayEditorLoadRecommendations => 'Load POI recommendations';

  @override
  String get dayEditorAiRecommendations => 'AI recommendations';

  @override
  String get dayEditorRecommended => 'Recommended';

  @override
  String dayEditorAddedToDay(int day) {
    return 'added to day $day';
  }

  @override
  String get dayEditorAllDaysExported =>
      'All days have been successfully exported to Google Maps. Have a great trip!';

  @override
  String get dayEditorAddPois => 'Add POIs';

  @override
  String dayEditorMyRouteDay(int day) {
    return 'My route - Day $day with MapAB';
  }

  @override
  String dayEditorMapabRouteDay(int day) {
    return 'MapAB Route - Day $day';
  }

  @override
  String dayEditorSwapped(String name) {
    return '\"$name\" swapped';
  }

  @override
  String get corridorTitle => 'POIs along route';

  @override
  String corridorFound(int total) {
    return '$total found';
  }

  @override
  String corridorFoundWithNew(int total, int newCount) {
    return '$total found ($newCount new)';
  }

  @override
  String corridorWidth(int km) {
    return 'Corridor: $km km';
  }

  @override
  String get corridorSearching => 'Searching POIs in corridor...';

  @override
  String get corridorNoPoiInCategory => 'No POIs found in this category';

  @override
  String get corridorNoPois => 'No POIs found in corridor';

  @override
  String get corridorTryWider => 'Try a wider corridor';

  @override
  String get corridorRemoveStop => 'Remove stop?';

  @override
  String get corridorMinOneStop => 'At least 1 stop per day required';

  @override
  String corridorPoiRemoved(String name) {
    return '\"$name\" removed';
  }

  @override
  String get navEndConfirm => 'End navigation?';

  @override
  String get navDestinationReached => 'Destination reached!';

  @override
  String get navDistance => 'Distance';

  @override
  String get navArrival => 'Arrival';

  @override
  String get navSpeed => 'Speed';

  @override
  String get navMuteOn => 'Sound on';

  @override
  String get navMuteOff => 'Sound off';

  @override
  String get navOverview => 'Overview';

  @override
  String get navEnd => 'End';

  @override
  String get navVoice => 'Voice';

  @override
  String get navVoiceListening => 'Listening...';

  @override
  String get navStartButton => 'Start navigation';

  @override
  String get navRerouting => 'Recalculating route';

  @override
  String get navVisited => 'Visited';

  @override
  String navDistanceMeters(String distance) {
    return '$distance m away';
  }

  @override
  String navDistanceKm(String distance) {
    return '$distance km away';
  }

  @override
  String get navDepart => 'Depart';

  @override
  String navDepartOn(String street) {
    return 'Depart on $street';
  }

  @override
  String get navArrive => 'You have reached your destination';

  @override
  String navArriveAt(String street) {
    return 'Destination reached: $street';
  }

  @override
  String navContinueOn(String street) {
    return 'Continue on $street';
  }

  @override
  String get navContinue => 'Continue';

  @override
  String get navTurnRight => 'Turn right';

  @override
  String get navTurnLeft => 'Turn left';

  @override
  String navTurnRightOn(String street) {
    return 'Turn right onto $street';
  }

  @override
  String navTurnLeftOn(String street) {
    return 'Turn left onto $street';
  }

  @override
  String get navSlightRight => 'Bear right';

  @override
  String get navSlightLeft => 'Bear left';

  @override
  String navSlightRightOn(String street) {
    return 'Bear right onto $street';
  }

  @override
  String navSlightLeftOn(String street) {
    return 'Bear left onto $street';
  }

  @override
  String get navSharpRight => 'Sharp right';

  @override
  String get navSharpLeft => 'Sharp left';

  @override
  String get navUturn => 'Make a U-turn';

  @override
  String get navStraight => 'Continue straight';

  @override
  String navStraightOn(String street) {
    return 'Continue straight on $street';
  }

  @override
  String get navMerge => 'Merge';

  @override
  String navMergeOn(String street) {
    return 'Merge onto $street';
  }

  @override
  String get navOnRamp => 'Take the on-ramp';

  @override
  String navOnRampOn(String street) {
    return 'Take the on-ramp to $street';
  }

  @override
  String get navOffRamp => 'Take the exit';

  @override
  String navOffRampOn(String street) {
    return 'Take exit $street';
  }

  @override
  String navRoundaboutExit(String ordinal) {
    return 'Take the $ordinal exit at the roundabout';
  }

  @override
  String navRoundaboutExitOn(String ordinal, String street) {
    return 'Take the $ordinal exit at the roundabout onto $street';
  }

  @override
  String get navRoundaboutEnter => 'Enter the roundabout';

  @override
  String get navRoundaboutLeave => 'Exit the roundabout';

  @override
  String get navForkLeft => 'Keep left at the fork';

  @override
  String get navForkRight => 'Keep right at the fork';

  @override
  String navForkLeftOn(String street) {
    return 'Keep left at the fork onto $street';
  }

  @override
  String navForkRightOn(String street) {
    return 'Keep right at the fork onto $street';
  }

  @override
  String get navEndOfRoadLeft => 'Turn left at the end of the road';

  @override
  String get navEndOfRoadRight => 'Turn right at the end of the road';

  @override
  String navEndOfRoadLeftOn(String street) {
    return 'Turn left at the end of the road onto $street';
  }

  @override
  String navEndOfRoadRightOn(String street) {
    return 'Turn right at the end of the road onto $street';
  }

  @override
  String navInDistance(String distance, String instruction) {
    return 'In $distance $instruction';
  }

  @override
  String navNow(String instruction) {
    return '$instruction now';
  }

  @override
  String navMeters(String value) {
    return '$value meters';
  }

  @override
  String navKilometers(String value) {
    return '$value kilometers';
  }

  @override
  String get navOrdinalFirst => 'first';

  @override
  String get navOrdinalSecond => 'second';

  @override
  String get navOrdinalThird => 'third';

  @override
  String get navOrdinalFourth => 'fourth';

  @override
  String get navOrdinalFifth => 'fifth';

  @override
  String get navOrdinalSixth => 'sixth';

  @override
  String get navOrdinalSeventh => 'seventh';

  @override
  String get navOrdinalEighth => 'eighth';

  @override
  String navSharpRightOn(String street) {
    return 'Sharp right onto $street';
  }

  @override
  String navSharpLeftOn(String street) {
    return 'Sharp left onto $street';
  }

  @override
  String navUturnOn(String street) {
    return 'Make a U-turn onto $street';
  }

  @override
  String get navTurn => 'Turn';

  @override
  String navTurnOn(String street) {
    return 'Turn onto $street';
  }

  @override
  String get navForkStraight => 'Continue at the fork';

  @override
  String navForkStraightOn(String street) {
    return 'Continue at the fork onto $street';
  }

  @override
  String get navEndOfRoadStraight => 'Continue at the end of the road';

  @override
  String navEndOfRoadStraightOn(String street) {
    return 'Continue at the end of the road onto $street';
  }

  @override
  String navRoundaboutLeaveOn(String street) {
    return 'Exit the roundabout onto $street';
  }

  @override
  String navRoundaboutEnterOn(String street) {
    return 'Enter the roundabout onto $street';
  }

  @override
  String get navStraightContinue => 'Continue straight ahead';

  @override
  String get navDirectionLeft => 'Left ';

  @override
  String get navDirectionRight => 'Right ';

  @override
  String get navSharpRightShort => 'Sharp right';

  @override
  String get navRightShort => 'Right';

  @override
  String get navSlightRightShort => 'Slight right';

  @override
  String get navStraightShort => 'Straight';

  @override
  String get navSlightLeftShort => 'Slight left';

  @override
  String get navLeftShort => 'Left';

  @override
  String get navSharpLeftShort => 'Sharp left';

  @override
  String get navKeepLeft => 'Keep left';

  @override
  String get navKeepRight => 'Keep right';

  @override
  String get navRoundabout => 'Roundabout';

  @override
  String navExitShort(String ordinal) {
    return '$ordinal exit';
  }

  @override
  String get navMustSeeStop => 'Stop';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDesign => 'Design';

  @override
  String get settingsAutoDarkMode => 'Auto dark mode';

  @override
  String get settingsAutoDarkModeDesc => 'Automatically activate at sunset';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsHaptic => 'Haptic feedback';

  @override
  String get settingsHapticDesc => 'Vibrations on interactions';

  @override
  String get settingsSound => 'Sound effects';

  @override
  String get settingsSoundDesc => 'Sounds on actions';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeOled => 'OLED Black';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileCloudAccount => 'Cloud account';

  @override
  String get profileAutoSync => 'Data is automatically synchronized';

  @override
  String get profileGuestAccount => 'Guest account';

  @override
  String get profileLocalStorage => 'Stored locally';

  @override
  String get profileUpgradeToCloud => 'Upgrade to cloud account';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileNoAccount => 'No account';

  @override
  String get profileLoginPrompt => 'Sign in to see your profile';

  @override
  String get profileLogin => 'Sign in';

  @override
  String profileLevel(int level) {
    return 'Level $level';
  }

  @override
  String profileXpProgress(int xp, int level) {
    return '$xp XP until level $level';
  }

  @override
  String get profileStatistics => 'Statistics';

  @override
  String get profileStatisticsLoading => 'Loading statistics...';

  @override
  String get profileStartFirstTrip =>
      'Start your first trip to see statistics!';

  @override
  String get profileTrips => 'Trips';

  @override
  String get profilePois => 'POIs';

  @override
  String get profileKilometers => 'Kilometers';

  @override
  String get profileAchievements => 'Achievements';

  @override
  String get profileNoAchievements =>
      'No achievements unlocked yet. Start your first trip!';

  @override
  String profileAccountId(String id) {
    return 'Account ID: $id';
  }

  @override
  String profileCreatedAt(String date) {
    return 'Created: $date';
  }

  @override
  String profileLastLogin(String date) {
    return 'Last login: $date';
  }

  @override
  String get profileEditComingSoon => 'Profile editing coming soon!';

  @override
  String get profileLogoutTitle => 'Sign out?';

  @override
  String get profileLogoutMessage => 'Do you really want to sign out?';

  @override
  String get profileLogoutCloudMessage =>
      'Do you really want to sign out?\n\nYour cloud data will be preserved and you can sign in again at any time.';

  @override
  String get profileLogout => 'Sign out';

  @override
  String get profileDeleteTitle => 'Delete account?';

  @override
  String get profileDeleteMessage =>
      'Do you really want to delete your account? All data will be permanently deleted!';

  @override
  String get favTitle => 'Favorites';

  @override
  String get favRoutes => 'Routes';

  @override
  String get favPois => 'POIs';

  @override
  String get favDeleteAll => 'Delete all';

  @override
  String get favNoFavorites => 'No favorites';

  @override
  String get favNoFavoritesDesc => 'Save routes and POIs for quick access';

  @override
  String get favExplore => 'Explore';

  @override
  String get favNoRoutes => 'No saved routes';

  @override
  String get favPlanRoute => 'Plan route';

  @override
  String get favNoPois => 'No favorite POIs';

  @override
  String get favDiscoverPois => 'Discover POIs';

  @override
  String get favRemoveRoute => 'Remove route?';

  @override
  String favRemoveRouteConfirm(String name) {
    return 'Do you want to remove \"$name\" from favorites?';
  }

  @override
  String get favRemovePoi => 'Remove POI?';

  @override
  String favRemovePoiConfirm(String name) {
    return 'Do you want to remove \"$name\" from favorites?';
  }

  @override
  String get favRouteLoaded => 'Route loaded';

  @override
  String get favRouteRemoved => 'Route removed';

  @override
  String get favPoiRemoved => 'POI removed';

  @override
  String get favClearAll => 'Delete all favorites?';

  @override
  String get favAllDeleted => 'All favorites deleted';

  @override
  String get poiSearchHint => 'Search POIs...';

  @override
  String get poiClearFilters => 'Clear filters';

  @override
  String get poiResetFilters => 'Reset filters';

  @override
  String get poiLoading => 'Loading attractions...';

  @override
  String get poiNotFound => 'POI not found';

  @override
  String get poiLoadingDetails => 'Loading details...';

  @override
  String get poiMoreOnWikipedia => 'More on Wikipedia';

  @override
  String get poiOpeningHours => 'Opening hours';

  @override
  String poiRouteCreated(String name) {
    return 'Route to \"$name\" created';
  }

  @override
  String get poiOnlyMustSee => 'Must-see only';

  @override
  String get poiShowOnlyHighlights => 'Show highlights only';

  @override
  String get poiOnlyIndoor => 'Indoor POIs only';

  @override
  String get poiApplyFilters => 'Apply filters';

  @override
  String get poiReroll => 'Reroll';

  @override
  String get poiTitle => 'Attractions';

  @override
  String get poiMustSee => 'Must-See';

  @override
  String get poiWeatherTip => 'Weather Tip';

  @override
  String poiResultsCount(int filtered, int total) {
    return '$filtered of $total POIs';
  }

  @override
  String get poiNoResultsFilter => 'No POIs found with these filters';

  @override
  String get poiNoResultsNearby => 'No POIs found nearby';

  @override
  String get poiGpsPermissionNeeded =>
      'GPS permission required to find nearby POIs';

  @override
  String get poiWeatherDangerBanner =>
      'Storm expected – indoor POIs recommended';

  @override
  String get poiWeatherBadBanner =>
      'Rain expected – enable \"Weather Tip\" for better sorting';

  @override
  String get poiAboutPlace => 'About this place';

  @override
  String get poiNoDescription => 'No description available.';

  @override
  String get poiDescriptionLoading => 'Loading description...';

  @override
  String get poiContactInfo => 'Contact & Info';

  @override
  String get poiPhone => 'Phone';

  @override
  String get poiWebsite => 'Website';

  @override
  String get poiEmailLabel => 'Email';

  @override
  String get poiDetour => 'Detour';

  @override
  String get poiTime => 'Time';

  @override
  String get poiPosition => 'Position';

  @override
  String get poiCurated => 'Curated';

  @override
  String get poiVerified => 'Verified';

  @override
  String poiAddedToRoute(String name) {
    return '$name added to route';
  }

  @override
  String poiFoundedYear(int year) {
    return 'Founded $year';
  }

  @override
  String poiRating(String rating, int count) {
    return '$rating of 5 ($count reviews)';
  }

  @override
  String get poiAddToRoute => 'Add to route';

  @override
  String get scanTitle => 'Scan trip';

  @override
  String get scanInstruction => 'Scan QR code';

  @override
  String get scanDescription =>
      'Hold your phone over a MapAB QR code to import a shared trip.';

  @override
  String get scanLoading => 'Loading trip...';

  @override
  String get scanInvalidCode => 'Invalid QR code';

  @override
  String get scanInvalidMapabCode => 'Not a valid MapAB QR code';

  @override
  String get scanLoadError => 'Could not load trip';

  @override
  String get scanTripFound => 'Trip found!';

  @override
  String scanStops(int count) {
    return '$count stops';
  }

  @override
  String scanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get scanImportQuestion => 'Do you want to import this trip?';

  @override
  String get scanImport => 'Import';

  @override
  String scanImportSuccess(String name) {
    return '$name was imported!';
  }

  @override
  String get scanImportError => 'Could not import trip';

  @override
  String get templatesTitle => 'Trip Templates';

  @override
  String get templatesScanQr => 'Scan QR code';

  @override
  String get templatesAudienceAll => 'All';

  @override
  String get templatesAudienceCouples => 'Couples';

  @override
  String get templatesAudienceFamilies => 'Families';

  @override
  String get templatesAudienceAdventurers => 'Adventurers';

  @override
  String get templatesAudienceFoodies => 'Foodies';

  @override
  String get templatesAudiencePhotographers => 'Photographers';

  @override
  String templatesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String templatesCategories(int count) {
    return '$count categories';
  }

  @override
  String get templatesIncludedCategories => 'Included categories';

  @override
  String get templatesDuration => 'Trip duration';

  @override
  String templatesRecommended(int days, String daysText) {
    return 'Recommended: $days $daysText';
  }

  @override
  String templatesBestSeason(String season) {
    return 'Best season: $season';
  }

  @override
  String get templatesStartPlanning => 'Plan trip';

  @override
  String get seasonSpring => 'Spring';

  @override
  String get seasonSummer => 'Summer';

  @override
  String get seasonAutumn => 'Autumn';

  @override
  String get seasonWinter => 'Winter';

  @override
  String get seasonSpringAutumn => 'Spring to Autumn';

  @override
  String get seasonYearRound => 'Year-round';

  @override
  String get day => 'day';

  @override
  String get days => 'days';

  @override
  String get searchSelectStart => 'Select start';

  @override
  String get searchSelectDestination => 'Select destination';

  @override
  String get searchStartHint => 'Search start point...';

  @override
  String get searchDestinationHint => 'Search destination...';

  @override
  String get searchOfflineMode => 'No internet - showing local suggestions';

  @override
  String get searchEnterLocation => 'Enter location to search';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get searchLocationNotFound => 'Location could not be found';

  @override
  String get chatTitle => 'AI Assistant';

  @override
  String get chatClear => 'Clear chat';

  @override
  String get chatWelcome =>
      'Hello! I\'m your AI travel assistant. How can I help you plan?';

  @override
  String get chatInputHint => 'Enter message...';

  @override
  String get chatClearConfirm => 'Clear chat?';

  @override
  String get chatClearMessage => 'The entire conversation will be deleted.';

  @override
  String get chatCheckAgain => 'Check again';

  @override
  String get chatAccept => 'Accept';

  @override
  String chatShowAllPois(int count) {
    return 'Show all POIs';
  }

  @override
  String get chatDestinationOptional => 'Destination (optional)';

  @override
  String get chatEmptyRandomRoute => 'Empty = Random route around start point';

  @override
  String get chatStartOptional => 'Start point (optional)';

  @override
  String get chatEmptyUseGps => 'Empty = Use GPS location';

  @override
  String get chatIndoorTips => 'Indoor tips for rainy weather';

  @override
  String get chatPoisNearMe => 'POIs near me';

  @override
  String get chatAttractions => 'Attractions';

  @override
  String get chatRestaurants => 'Restaurants';

  @override
  String get chatOutdoorHighlights => 'Outdoor highlights';

  @override
  String get chatNatureParks => 'Nature & parks';

  @override
  String get chatSearchRadius => 'Search radius';

  @override
  String get chatGenerateAiTrip => 'Generate AI trip';

  @override
  String get randomTripNoTrip => 'No trip generated';

  @override
  String get randomTripRegenerate => 'Regenerate';

  @override
  String get randomTripConfirm => 'Confirm trip';

  @override
  String randomTripStopsDay(int day) {
    return 'Stops (Day $day)';
  }

  @override
  String get randomTripStops => 'Stops';

  @override
  String get randomTripEnterAddress => 'Enter city or address...';

  @override
  String get randomTripShowDetails => 'Show details';

  @override
  String get randomTripOpenGoogleMaps => 'Open in Google Maps';

  @override
  String get randomTripSave => 'Save trip';

  @override
  String get randomTripShow => 'Show trip';

  @override
  String get randomTripBack => 'Back';

  @override
  String get mapModeAiDayTrip => 'AI Day Trip';

  @override
  String get mapModeAiEuroTrip => 'AI Euro Trip';

  @override
  String get travelDuration => 'Travel duration';

  @override
  String get radiusLabel => 'Radius';

  @override
  String get categoriesLabel => 'Categories';

  @override
  String tripDescDayTrip(int radius) {
    return 'Day trip — approx. $radius km';
  }

  @override
  String tripDescWeekend(int radius) {
    return 'Weekend trip — approx. $radius km';
  }

  @override
  String tripDescShortVacation(int radius) {
    return 'Short vacation — approx. $radius km';
  }

  @override
  String tripDescWeekTrip(int radius) {
    return 'Week trip — approx. $radius km';
  }

  @override
  String tripDescEpic(int radius) {
    return 'Epic Euro Trip — approx. $radius km';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get destinationOptional => 'Destination (optional)';

  @override
  String get enterDestination => 'Enter destination...';

  @override
  String get mapCityOrAddress => 'City or address...';

  @override
  String get mapAddDestination => 'Add destination (optional)';

  @override
  String get mapSurpriseMe => 'Surprise me!';

  @override
  String get mapDeleteRoute => 'Delete route';

  @override
  String mapDaysLabel(String days) {
    return '$days days';
  }

  @override
  String get mapPoiCategories => 'POI categories';

  @override
  String get mapResetAll => 'Reset all';

  @override
  String get mapAllCategoriesSelected => 'All categories selected';

  @override
  String mapCategoriesSelected(String count, String total) {
    return '$count of $total selected';
  }

  @override
  String get mapPoisAlongRoute => 'POIs along the route';

  @override
  String get mapWithoutDestination =>
      'Without destination: round trip from start';

  @override
  String get tripTypeDayTrip => 'Day trip';

  @override
  String get tripTypeEuroTrip => 'Euro trip';

  @override
  String get tripTypeMultiDay => 'Multi-day trip';

  @override
  String get tripTypeScenic => 'Scenic route';

  @override
  String get tripTypeDayTripDistance => '30-200 km';

  @override
  String get tripTypeEuroTripDistance => '200-800 km';

  @override
  String get tripTypeMultiDayDistance => '2-7 days';

  @override
  String get tripTypeScenicDistance => 'variable';

  @override
  String get tripTypeDayTripDesc => 'Activity selection, weather-based';

  @override
  String get tripTypeEuroTripDesc => 'Different country, hotel suggestions';

  @override
  String get tripTypeMultiDayDesc => 'Automatic overnight stops';

  @override
  String get tripTypeScenicDesc => 'Viewpoints prioritized';

  @override
  String get accessWheelchair => 'Wheelchair accessible';

  @override
  String get accessNoStairs => 'No stairs';

  @override
  String get accessParking => 'Disabled parking';

  @override
  String get accessToilet => 'Accessible restroom';

  @override
  String get accessElevator => 'Elevator available';

  @override
  String get accessBraille => 'Braille';

  @override
  String get accessAudioGuide => 'Audio guide';

  @override
  String get accessSignLanguage => 'Sign language';

  @override
  String get accessAssistDogs => 'Service dogs allowed';

  @override
  String get accessFullyAccessible => 'Fully accessible';

  @override
  String get accessLimited => 'Limited accessibility';

  @override
  String get accessNotAccessible => 'Not accessible';

  @override
  String get accessUnknown => 'Unknown';

  @override
  String get highlightUnesco => 'UNESCO World Heritage';

  @override
  String get highlightMustSee => 'Must-see';

  @override
  String get highlightSecret => 'Hidden gem';

  @override
  String get highlightHistoric => 'Historic';

  @override
  String get highlightFamilyFriendly => 'Family-friendly';

  @override
  String experienceDetourKm(int km) {
    return '+$km km detour';
  }

  @override
  String get formatMinShort => 'min';

  @override
  String get formatHourShort => 'hr';

  @override
  String get formatMinLong => 'minutes';

  @override
  String formatHourLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    return '$_temp0';
  }

  @override
  String formatDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String formatStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String get formatNoInfo => 'No information';

  @override
  String get formatJustNow => 'Just now';

  @override
  String formatAgoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String formatAgoHours(int count) {
    return '$count hr ago';
  }

  @override
  String formatAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get formatUnknown => 'Unknown';

  @override
  String get journalTitle => 'Travel Journal';

  @override
  String get journalEmptyTitle => 'No entries yet';

  @override
  String get journalEmptySubtitle =>
      'Capture your travel memories with photos and notes.';

  @override
  String get journalAddEntry => 'Add entry';

  @override
  String get journalAddFirstEntry => 'Create first entry';

  @override
  String get journalNewEntry => 'New entry';

  @override
  String get journalAddPhoto => 'Add photo';

  @override
  String get journalCamera => 'Camera';

  @override
  String get journalGallery => 'Gallery';

  @override
  String get journalAddNote => 'Add note';

  @override
  String get journalNoteHint => 'What did you experience?';

  @override
  String get journalSaveNote => 'Save note only';

  @override
  String get journalSaveLocation => 'Save location';

  @override
  String get journalLocationAvailable => 'GPS location available';

  @override
  String get journalLocationLoading => 'Loading location...';

  @override
  String get journalEnterNote => 'Please enter a note';

  @override
  String get journalDeleteEntryTitle => 'Delete entry?';

  @override
  String get journalDeleteEntryMessage =>
      'This entry will be permanently deleted.';

  @override
  String get journalDeleteTitle => 'Delete journal?';

  @override
  String get journalDeleteMessage =>
      'All entries and photos will be permanently deleted.';

  @override
  String journalPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
      zero: 'No photos',
    );
    return '$_temp0';
  }

  @override
  String journalEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String journalDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String journalDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String journalDayNumber(int day) {
    return 'Day $day';
  }

  @override
  String get journalOther => 'Other';

  @override
  String get journalEntry => 'entry';

  @override
  String get journalEntriesPlural => 'entries';

  @override
  String get journalOpenJournal => 'Open journal';

  @override
  String get journalAllJournals => 'All journals';

  @override
  String get journalNoJournals => 'No journals yet';

  @override
  String get galleryTitle => 'Trip Gallery';

  @override
  String get gallerySearch => 'Search trips...';

  @override
  String get galleryFeatured => 'Featured';

  @override
  String get galleryAllTrips => 'All Trips';

  @override
  String get galleryNoTrips => 'No trips found';

  @override
  String get galleryResetFilters => 'Reset filters';

  @override
  String get galleryFilter => 'Filter';

  @override
  String get galleryFilterReset => 'Reset';

  @override
  String get galleryTripType => 'Trip type';

  @override
  String get galleryTags => 'Tags';

  @override
  String get gallerySort => 'Sort by';

  @override
  String get gallerySortPopular => 'Popular';

  @override
  String get gallerySortRecent => 'Recent';

  @override
  String get gallerySortLikes => 'Most likes';

  @override
  String get galleryTypeAll => 'All';

  @override
  String get galleryTypeDaytrip => 'Day trip';

  @override
  String get galleryTypeEurotrip => 'Euro Trip';

  @override
  String get galleryRetry => 'Try again';

  @override
  String galleryLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
      zero: 'No likes yet',
    );
    return '$_temp0';
  }

  @override
  String galleryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count views',
      one: '1 view',
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
    return 'Shared on $date';
  }

  @override
  String galleryTripsShared(int count) {
    return '$count trips shared';
  }

  @override
  String get galleryImportToFavorites => 'Add to favorites';

  @override
  String get galleryImported => 'Imported';

  @override
  String get galleryShowOnMap => 'Show on map';

  @override
  String get galleryShareComingSoon => 'Sharing coming soon';

  @override
  String get galleryMapComingSoon => 'Map view coming soon';

  @override
  String get galleryImportSuccess => 'Trip added to favorites';

  @override
  String get galleryImportError => 'Import failed';

  @override
  String get galleryTripNotFound => 'Trip not found';

  @override
  String get galleryLoadError => 'Error loading';

  @override
  String get publishTitle => 'Publish Trip';

  @override
  String get publishSubtitle => 'Share your trip with the community';

  @override
  String get publishTripName => 'Trip name';

  @override
  String get publishTripNameHint => 'e.g. South France Road Trip';

  @override
  String get publishTripNameRequired => 'Please enter a name';

  @override
  String get publishTripNameMinLength => 'Name must be at least 3 characters';

  @override
  String get publishDescription => 'Description (optional)';

  @override
  String get publishDescriptionHint => 'Tell others about your trip...';

  @override
  String get publishTags => 'Tags (optional)';

  @override
  String get publishTagsHelper => 'Help others find your trip';

  @override
  String get publishMaxTags => 'Maximum 5 tags';

  @override
  String get publishInfo =>
      'Your trip will be publicly visible. Others can like it and import it to their favorites.';

  @override
  String get publishButton => 'Publish';

  @override
  String get publishPublishing => 'Publishing...';

  @override
  String get publishSuccess => 'Trip published!';

  @override
  String get publishError => 'Publishing failed';

  @override
  String get publishEuroTrip => 'Euro Trip';

  @override
  String get publishDaytrip => 'Day trip';

  @override
  String get dayEditorDriveTime => 'Drive time';

  @override
  String get dayEditorWeather => 'Weather';

  @override
  String get dayEditorDay => 'Day';

  @override
  String dayEditorNoStopsForDay(int day) {
    return 'No stops for day $day';
  }

  @override
  String dayEditorDayInGoogleMaps(int day) {
    return 'Day $day in Google Maps';
  }

  @override
  String dayEditorOpenAgain(int day) {
    return 'Reopen day $day';
  }

  @override
  String get dayEditorTripCompleted => 'Trip completed!';

  @override
  String get dayEditorRouteShare => 'Share Route';

  @override
  String get dayEditorRouteShareError => 'Could not share route';

  @override
  String get dayEditorShareStops => 'Stops';

  @override
  String get dayEditorShareOpenGoogleMaps => 'Open in Google Maps';

  @override
  String get tripSummaryTotal => 'Total';

  @override
  String get tripSummaryDriveTime => 'Drive time';

  @override
  String get tripSummaryStops => 'Stops';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterMaxDetour => 'Maximum detour';

  @override
  String get filterMaxDetourHint => 'POIs with a longer detour will be hidden';

  @override
  String get filterAllCategories => 'Show all categories';

  @override
  String filterSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get filterCategoriesLabel => 'Categories';

  @override
  String get categorySelectorDeselectAll => 'Deselect all';

  @override
  String get categorySelectorNoneHint => 'No selection = all categories';

  @override
  String categorySelectorSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get categorySelectorTitle => 'Categories';

  @override
  String get startLocationLabel => 'Starting point';

  @override
  String get startLocationHint => 'Enter city or address...';

  @override
  String get startLocationGps => 'Use GPS location';

  @override
  String get tripPreviewNoTrip => 'No trip generated';

  @override
  String get tripPreviewYourTrip => 'Your Trip';

  @override
  String get tripPreviewConfirm => 'Confirm trip';

  @override
  String tripPreviewMaxStopsWarning(int max) {
    return 'Max $max stops per day (Google Maps limit)';
  }

  @override
  String tripPreviewStopsDay(int day) {
    return 'Stops (Day $day)';
  }

  @override
  String tripPreviewDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Days',
      one: 'Day',
    );
    return '$_temp0';
  }

  @override
  String get navSkip => 'Skip';

  @override
  String get navVisitedButton => 'Visited';

  @override
  String navDistanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get chatDemoMode => 'Demo mode: Responses are simulated';

  @override
  String get chatLocationLoading => 'Loading location...';

  @override
  String get chatLocationActive => 'Location active';

  @override
  String get chatLocationEnable => 'Enable location';

  @override
  String get chatMyLocation => 'My location';

  @override
  String get chatRadiusTooltip => 'Search radius';

  @override
  String get chatNoPoisFound => 'No POIs found nearby';

  @override
  String chatPoisInRadius(int count, String radius) {
    return '$count POIs within $radius km';
  }

  @override
  String chatRadiusLabel(String radius) {
    return '$radius km';
  }

  @override
  String get chatWelcomeSubtitle => 'Ask me anything about your trip!';

  @override
  String get chatDemoBackendNotReachable => 'Demo mode: Backend not reachable';

  @override
  String get chatDemoBackendNotConfigured =>
      'Demo mode: Backend URL not configured';

  @override
  String get chatNumberOfDays => 'Number of days';

  @override
  String get chatInterests => 'Interests:';

  @override
  String get chatLocationNotAvailable => 'Location not available';

  @override
  String get chatLocationNotAvailableMessage =>
      'To find POIs near you, I need access to your location.\n\nPlease enable location services and try again.';

  @override
  String get chatPoisSearchError => 'Error during POI search';

  @override
  String get chatPoisSearchErrorMessage =>
      'Sorry, there was a problem loading the POIs.\n\nPlease try again.';

  @override
  String get chatNoResponseGenerated =>
      'Sorry, I could not generate a response.';

  @override
  String get chatRadiusAdjust => 'Adjust search radius';

  @override
  String get voiceRerouting => 'Recalculating route';

  @override
  String voicePOIApproaching(String name, String distance) {
    return '$name in $distance';
  }

  @override
  String voiceArrivedAt(String name) {
    return 'You have arrived at: $name';
  }

  @override
  String voiceRouteInfo(String distance, String duration) {
    return '$distance and $duration remaining to destination';
  }

  @override
  String voiceNextStop(String name, String distance) {
    return 'Next stop: $name in $distance';
  }

  @override
  String voiceCurrentLocation(String location) {
    return 'Current location: $location';
  }

  @override
  String voiceInMeters(int meters) {
    return '$meters meters';
  }

  @override
  String voiceInKilometers(String km) {
    return '$km kilometers';
  }

  @override
  String voiceHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
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
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String get voiceCmdNextStop => 'Next stop';

  @override
  String get voiceCmdLocation => 'Where am I';

  @override
  String get voiceCmdDuration => 'How long left';

  @override
  String get voiceCmdEndNavigation => 'End navigation';

  @override
  String get voiceNow => 'Now';

  @override
  String get voiceArrived => 'You have arrived at your destination';

  @override
  String voicePOIReached(String name) {
    return '$name reached';
  }

  @override
  String voiceCategory(String category) {
    return 'Category: $category';
  }

  @override
  String voiceDistanceMeters(int meters) {
    return '$meters meters away';
  }

  @override
  String voiceDistanceKm(String km) {
    return '$km kilometers away';
  }

  @override
  String voiceRouteLength(String distance, String duration, String stops) {
    return 'Your route is $distance kilometers long, takes about $duration and has $stops.';
  }

  @override
  String voiceAndMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return 'and $_temp0';
  }

  @override
  String get voiceCmdPreviousStop => 'Previous stop';

  @override
  String get voiceCmdNearby => 'What is nearby';

  @override
  String get voiceCmdAdd => 'Add to route';

  @override
  String get voiceCmdStartNav => 'Start navigation';

  @override
  String get voiceCmdStopNav => 'End navigation';

  @override
  String get voiceCmdDescribe => 'Read description';

  @override
  String get voiceCmdUnknown => 'Unknown';

  @override
  String voiceManeuverNow(String instruction) {
    return 'Now $instruction';
  }

  @override
  String voiceManeuverInMeters(int meters, String instruction) {
    return 'In $meters meters $instruction';
  }

  @override
  String voiceManeuverInKm(String km, String instruction) {
    return 'In $km kilometers $instruction';
  }

  @override
  String navMustSeeAnnouncement(String distance, String name) {
    return 'In $distance meters is $name, a must-see highlight';
  }

  @override
  String advisorDangerWeather(int day, int outdoorCount) {
    return 'Severe weather expected on day $day! $outdoorCount outdoor stops should be replaced with indoor alternatives.';
  }

  @override
  String advisorBadWeather(int day, int outdoorCount, int totalCount) {
    return 'Rain expected on day $day. $outdoorCount of $totalCount stops are outdoor activities.';
  }

  @override
  String advisorOutdoorAlternative(String name) {
    return '$name is an outdoor activity - alternative recommended';
  }

  @override
  String advisorOutdoorReplace(String name) {
    return '$name is an outdoor activity. Replace this stop with an indoor alternative.';
  }

  @override
  String get advisorAiUnavailableSuggestions =>
      'AI unavailable - showing local suggestions';

  @override
  String advisorNoStopsForDay(int day) {
    return 'No stops for day $day';
  }

  @override
  String get advisorNoRecommendationsFound =>
      'No recommendations found near the stops';

  @override
  String get advisorAiUnavailableRecommendations =>
      'AI unavailable - showing local recommendations';

  @override
  String get advisorErrorLoadingRecommendations =>
      'Error loading recommendations';

  @override
  String advisorPoiCategory(String name, String category) {
    return '$name - $category';
  }

  @override
  String get weatherConditionGood => 'Good weather';

  @override
  String get weatherConditionMixed => 'Changeable';

  @override
  String get weatherConditionBad => 'Bad weather';

  @override
  String get weatherConditionDanger => 'Severe weather warning';

  @override
  String get weatherConditionUnknown => 'Weather unknown';

  @override
  String get weatherBadgeSnow => 'Snow';

  @override
  String get weatherBadgeRain => 'Rain';

  @override
  String get weatherBadgePerfect => 'Perfect';

  @override
  String get weatherBadgeBad => 'Bad';

  @override
  String get weatherBadgeDanger => 'Severe';

  @override
  String get weatherRecOutdoorIdeal => 'Ideal for outdoor POIs today';

  @override
  String get weatherRecRainIndoor => 'Rain - indoor POIs recommended';

  @override
  String get weatherRecDangerIndoor => 'Severe weather - indoor POIs only!';

  @override
  String get weatherToggleActive => 'Active';

  @override
  String get weatherToggleApply => 'Apply';

  @override
  String get weatherPointStart => 'Start';

  @override
  String get weatherPointEnd => 'End';

  @override
  String get weatherIndoorOnly => 'Indoor POIs only';

  @override
  String weatherAlertStorm(String windSpeed) {
    return 'Storm warning! Strong winds ($windSpeed km/h) along the route.';
  }

  @override
  String get weatherAlertDanger =>
      'Severe weather warning! Postponing recommended.';

  @override
  String get weatherAlertWinter => 'Winter weather! Snow/ice possible.';

  @override
  String get weatherAlertRain =>
      'Rain expected. Indoor activities recommended.';

  @override
  String get weatherAlertBad => 'Bad weather on the route.';

  @override
  String get weatherRecToday => 'Today\'s recommendation';

  @override
  String get weatherRecGoodDetail =>
      'Perfect weather for outdoor activities! Viewpoints, nature and lakes recommended.';

  @override
  String get weatherRecMixedDetail =>
      'Changeable weather. Both indoor and outdoor POIs possible.';

  @override
  String get weatherRecBadDetail =>
      'Rain expected. Indoor activities like museums and churches recommended.';

  @override
  String get weatherRecDangerDetail =>
      'Severe weather warning! Please avoid outdoor activities and stay inside.';

  @override
  String get weatherRecNoData => 'No weather data available.';

  @override
  String get weatherRecOutdoorPerfect =>
      'Perfect weather for outdoor activities';

  @override
  String get weatherRecMixedPrepare =>
      'Changeable - be prepared for everything';

  @override
  String get weatherRecSnowCaution => 'Snowfall - caution on slippery roads';

  @override
  String get weatherRecBadIndoor =>
      'Bad weather - indoor activities recommended';

  @override
  String weatherRecStormWarning(String windSpeed) {
    return 'Storm warning! Strong winds ($windSpeed km/h)';
  }

  @override
  String get weatherRecDangerCaution =>
      'Severe weather warning! Caution on this section';

  @override
  String get weatherRecNoDataAvailable => 'No weather data available';

  @override
  String get mapMyLocation => 'My location';

  @override
  String get mapDetails => 'Details';

  @override
  String get mapAddToRoute => 'Add to route';

  @override
  String get mapSelectedPoint => 'Selected point';

  @override
  String get mapWaypoint => 'Waypoint';

  @override
  String mapRouteCreated(String name) {
    return 'Route to \"$name\" created';
  }

  @override
  String mapPoiAdded(String name) {
    return '\"$name\" added';
  }

  @override
  String get mapErrorAdding => 'Error adding';

  @override
  String get tripPreviewStartDay1 => 'Start (Day 1)';

  @override
  String tripPreviewDayStart(String day) {
    return 'Day $day start';
  }

  @override
  String get tripPreviewBackToStart => 'Back to start';

  @override
  String tripPreviewEndDay(String day) {
    return 'End day $day';
  }

  @override
  String tripPreviewDetour(String km) {
    return '+$km km detour';
  }

  @override
  String get tripPreviewOvernight => 'Overnight stay';
}
