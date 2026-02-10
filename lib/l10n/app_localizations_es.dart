// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'MapAB';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get remove => 'Quitar';

  @override
  String get retry => 'Reintentar';

  @override
  String get close => 'Cerrar';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get done => 'Hecho';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get or => 'O';

  @override
  String get edit => 'Editar';

  @override
  String get loading => 'Cargando...';

  @override
  String get search => 'Buscar';

  @override
  String get show => 'Mostrar';

  @override
  String get apply => 'Aplicar';

  @override
  String get active => 'Activo';

  @override
  String get discard => 'Descartar';

  @override
  String get resume => 'Continuar';

  @override
  String get skip => 'Omitir';

  @override
  String get all => 'Todos';

  @override
  String get total => 'Total';

  @override
  String get newLabel => 'Nuevo';

  @override
  String get start => 'Inicio';

  @override
  String get destination => 'Destino';

  @override
  String get showOnMap => 'Mostrar en el mapa';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get actionCannotBeUndone => 'Esta acción no se puede deshacer.';

  @override
  String get details => 'Detalles';

  @override
  String get generate => 'Generar';

  @override
  String get clear => 'Borrar';

  @override
  String get reset => 'Restablecer';

  @override
  String get end => 'Terminar';

  @override
  String get reroll => 'Volver a tirar';

  @override
  String get filterApply => 'Aplicar filtro';

  @override
  String get openInGoogleMaps => 'Abrir en Google Maps';

  @override
  String get shareLinkCopied => '¡Enlace copiado al portapapeles!';

  @override
  String get shareAsText => 'Compartir como texto';

  @override
  String get errorGeneric => 'Ha ocurrido un error';

  @override
  String get errorNetwork => 'Sin conexión a Internet';

  @override
  String get errorNetworkMessage =>
      'Por favor, comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get errorServer => 'Servidor no disponible';

  @override
  String get errorServerMessage =>
      'El servidor no responde. Inténtalo más tarde.';

  @override
  String get errorNoResults => 'Sin resultados';

  @override
  String get errorLocation => 'Ubicación no disponible';

  @override
  String get errorLocationMessage =>
      'Por favor, permite el acceso a tu ubicación.';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get goToHome => 'Ir al inicio';

  @override
  String get errorRouteCalculation =>
      'Error al calcular la ruta. Por favor, inténtalo de nuevo.';

  @override
  String errorTripGeneration(String error) {
    return 'Error al generar el viaje: $error';
  }

  @override
  String get errorGoogleMapsNotOpened => 'No se pudo abrir Google Maps';

  @override
  String get errorRouteNotShared => 'No se pudo compartir la ruta';

  @override
  String get errorAddingToRoute => 'Error al añadir';

  @override
  String get errorIncompleteRouteData =>
      'Los datos de la ruta están incompletos';

  @override
  String get gpsDisabledTitle => 'GPS desactivado';

  @override
  String get gpsDisabledMessage =>
      'Los servicios de ubicación están desactivados. ¿Quieres abrir los ajustes del GPS?';

  @override
  String get gpsPermissionDenied => 'Permiso de GPS denegado';

  @override
  String get gpsPermissionDeniedForeverTitle => 'Permiso de GPS denegado';

  @override
  String get gpsPermissionDeniedForeverMessage =>
      'El permiso de GPS ha sido denegado permanentemente. Por favor, permite el acceso a la ubicación en los ajustes de la aplicación.';

  @override
  String get gpsCouldNotDetermine => 'No se pudo determinar la posición GPS';

  @override
  String get appSettingsButton => 'Ajustes de la aplicación';

  @override
  String get myLocation => 'Mi ubicación';

  @override
  String get authWelcomeTitle => 'Bienvenido a MapAB';

  @override
  String get authWelcomeSubtitle =>
      'Tu planificador de viajes con IA para escapadas inolvidables';

  @override
  String get authCloudNotAvailable =>
      'Nube no disponible - App compilada sin credenciales de Supabase';

  @override
  String get authCloudLoginUnavailable =>
      'Inicio de sesión en la nube no disponible - App compilada sin credenciales de Supabase';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authEmailEmpty => 'Por favor, introduce el correo electrónico';

  @override
  String get authEmailInvalid => 'Correo electrónico no válido';

  @override
  String get authEmailInvalidAddress =>
      'Dirección de correo electrónico no válida';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authPasswordEmpty => 'Por favor, introduce la contraseña';

  @override
  String get authPasswordMinLength => 'Mínimo 8 caracteres';

  @override
  String get authPasswordRequirements => 'Debe contener letras y números';

  @override
  String get authPasswordConfirm => 'Confirmar contraseña';

  @override
  String get authPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get authRememberMe => 'Recordar credenciales';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authNoAccount => '¿No tienes cuenta? ';

  @override
  String get authRegister => 'Registrarse';

  @override
  String get authContinueAsGuest => 'Continuar como invitado';

  @override
  String get authGuestInfoCloud =>
      'Como invitado, tus datos solo se guardan localmente y no se sincronizan.';

  @override
  String get authGuestInfoLocal =>
      'Tus datos se guardan localmente en tu dispositivo.';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authSecureData => 'Guarda tus datos en la nube';

  @override
  String get authNameLabel => 'Nombre';

  @override
  String get authNameHint => '¿Cómo te gustaría que te llamaran?';

  @override
  String get authNameEmpty => 'Por favor, introduce tu nombre';

  @override
  String get authNameMinLength => 'El nombre debe tener al menos 2 caracteres';

  @override
  String get authAlreadyHaveAccount => '¿Ya tienes una cuenta? ';

  @override
  String get authExistingAccount => 'Ya tengo una cuenta';

  @override
  String get authRegistrationSuccess => 'Registro exitoso';

  @override
  String get authRegistrationSuccessMessage =>
      'Por favor, revisa tu correo y confirma tu cuenta.';

  @override
  String get authResetPassword => 'Restablecer contraseña';

  @override
  String get authResetPasswordInstructions =>
      'Introduce tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get authSendLink => 'Enviar enlace';

  @override
  String get authBackToLogin => 'Volver al inicio de sesión';

  @override
  String get authEmailSent => '¡Correo enviado!';

  @override
  String get authEmailSentPrefix => 'Te hemos enviado un correo a';

  @override
  String get authEmailSentSuffix => '.';

  @override
  String get authResetLinkInstructions =>
      'Haz clic en el enlace del correo para establecer una nueva contraseña. El enlace es válido durante 24 horas.';

  @override
  String get authResend => 'Reenviar';

  @override
  String get authCreateLocalProfile => 'Crear perfil local';

  @override
  String get authUsernameLabel => 'Nombre de usuario';

  @override
  String get authUsernameHint => 'p. ej. viajero123';

  @override
  String get authDisplayNameLabel => 'Nombre visible';

  @override
  String get authDisplayNameHint => 'p. ej. Juan Pérez';

  @override
  String get authEmailOptional => 'Correo (opcional)';

  @override
  String get authEmailHint => 'p. ej. juan@ejemplo.com';

  @override
  String get authCreate => 'Crear';

  @override
  String get authRequiredFields =>
      'Se requieren nombre de usuario y nombre visible';

  @override
  String get authGuestDescription =>
      'Como invitado puedes empezar inmediatamente. Tus datos se guardan localmente en tu dispositivo.';

  @override
  String get authComingSoon => 'Inicio de sesión en la nube próximamente:';

  @override
  String get authLoadingText => 'Cargando...';

  @override
  String get splashTagline => 'Tu planificador de viaje con IA';

  @override
  String get onboardingTitle1 => 'Descubre lugares de interés';

  @override
  String get onboardingHighlight1 => 'lugares de interés';

  @override
  String get onboardingSubtitle1 =>
      'Encuentra más de 500 POIs seleccionados en toda Europa.\nCastillos, lagos, museos y lugares secretos te esperan.';

  @override
  String get onboardingTitle2 => 'Tu asistente de viaje con IA';

  @override
  String get onboardingHighlight2 => 'IA';

  @override
  String get onboardingSubtitle2 =>
      'Deja que planifique automáticamente la ruta perfecta.\nCon optimización inteligente según tus intereses.';

  @override
  String get onboardingTitle3 => 'Tus viajes en la nube';

  @override
  String get onboardingHighlight3 => 'Nube';

  @override
  String get onboardingSubtitle3 =>
      'Guarda favoritos y viajes de forma segura online.\nSincronizado en todos tus dispositivos.';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get categoryCastle => 'Castillos y fortalezas';

  @override
  String get categoryNature => 'Naturaleza y bosques';

  @override
  String get categoryMuseum => 'Museos';

  @override
  String get categoryViewpoint => 'Miradores';

  @override
  String get categoryLake => 'Lagos';

  @override
  String get categoryCoast => 'Costas y playas';

  @override
  String get categoryPark => 'Parques y parques nacionales';

  @override
  String get categoryCity => 'Ciudades';

  @override
  String get categoryActivity => 'Actividades';

  @override
  String get categoryHotel => 'Hoteles';

  @override
  String get categoryRestaurant => 'Restaurantes';

  @override
  String get categoryUnesco => 'Patrimonio de la UNESCO';

  @override
  String get categoryChurch => 'Iglesias';

  @override
  String get categoryMonument => 'Monumentos';

  @override
  String get categoryAttraction => 'Atracciones';

  @override
  String get weatherGood => 'Bueno';

  @override
  String get weatherMixed => 'Variable';

  @override
  String get weatherBad => 'Malo';

  @override
  String get weatherDanger => 'Peligroso';

  @override
  String get weatherUnknown => 'Desconocido';

  @override
  String get weatherClear => 'Despejado';

  @override
  String get weatherMostlyClear => 'Mayormente despejado';

  @override
  String get weatherPartlyCloudy => 'Parcialmente nublado';

  @override
  String get weatherCloudy => 'Nublado';

  @override
  String get weatherFog => 'Niebla';

  @override
  String get weatherDrizzle => 'Llovizna';

  @override
  String get weatherFreezingDrizzle => 'Llovizna helada';

  @override
  String get weatherRain => 'Lluvia';

  @override
  String get weatherFreezingRain => 'Lluvia helada';

  @override
  String get weatherSnow => 'Nieve';

  @override
  String get weatherSnowGrains => 'Gránulos de nieve';

  @override
  String get weatherRainShowers => 'Chubascos';

  @override
  String get weatherSnowShowers => 'Nevadas';

  @override
  String get weatherThunderstorm => 'Tormenta';

  @override
  String get weatherThunderstormHail => 'Tormenta con granizo';

  @override
  String get weatherForecast7Day => 'Pronóstico 7 días';

  @override
  String get weatherToday => 'Hoy';

  @override
  String weatherFeelsLike(String temp) {
    return 'Sensación de $temp°';
  }

  @override
  String get weatherSunrise => 'Amanecer';

  @override
  String get weatherSunset => 'Atardecer';

  @override
  String get weatherUvIndex => 'Índice UV';

  @override
  String get weatherPrecipitation => 'Precipitación';

  @override
  String get weatherWind => 'Viento';

  @override
  String get weatherRainRisk => 'Riesgo de lluvia';

  @override
  String get weatherRecommendationToday => 'Recomendación para hoy';

  @override
  String get weatherRecGood =>
      '¡Clima perfecto para actividades al aire libre! Miradores, naturaleza y lagos recomendados.';

  @override
  String get weatherRecMixed => 'Variable - planifica con flexibilidad';

  @override
  String get weatherRecBad =>
      'Se espera lluvia. Actividades de interior como museos e iglesias recomendadas.';

  @override
  String get weatherRecDanger =>
      '¡Alerta meteorológica! Por favor, evita actividades al aire libre y permanece en el interior.';

  @override
  String get weatherRecUnknown => 'No hay datos meteorológicos disponibles.';

  @override
  String weatherUvLow(String value) {
    return '$value (Bajo)';
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
    return '$value (Muy alto)';
  }

  @override
  String weatherUvExtreme(String value) {
    return '$value (Extremo)';
  }

  @override
  String get weatherLoading => 'Cargando clima...';

  @override
  String get weatherWinterWeather => 'Clima invernal';

  @override
  String get weatherStormOnRoute => 'Tormenta en la ruta';

  @override
  String get weatherRainPossible => 'Posible lluvia';

  @override
  String get weatherGoodWeather => 'Buen tiempo';

  @override
  String get weatherChangeable => 'Variable';

  @override
  String get weatherBadWeather => 'Mal tiempo';

  @override
  String get weatherStormWarning => 'Alerta de tormenta';

  @override
  String get weatherPerfect => 'Perfecto';

  @override
  String get weatherStorm => 'Tormenta';

  @override
  String get weatherIdealOutdoor => 'Hoy ideal para POIs exteriores';

  @override
  String get weatherFlexiblePlanning => 'Variable - planifica con flexibilidad';

  @override
  String get weatherRainIndoor => 'Lluvia - POIs interiores recomendados';

  @override
  String get weatherStormIndoorOnly => 'Tormenta - ¡solo POIs interiores!';

  @override
  String get weatherOnlyIndoor => 'Solo POIs interiores';

  @override
  String weatherStormHighWinds(String speed) {
    return '¡Alerta de tormenta! Vientos fuertes ($speed km/h) en la ruta.';
  }

  @override
  String get weatherStormDelay =>
      '¡Alerta meteorológica! Se recomienda posponer el viaje.';

  @override
  String get weatherWinterWarning => '¡Clima invernal! Posible nieve/hielo.';

  @override
  String get weatherRainRecommendation =>
      'Se espera lluvia. Actividades de interior recomendadas.';

  @override
  String get weatherBadOnRoute => 'Mal tiempo en la ruta.';

  @override
  String get weatherPerfectOutdoor =>
      'Clima perfecto para actividades al aire libre';

  @override
  String get weatherBePrepared => 'Variable - estar preparado para todo';

  @override
  String get weatherSnowWarning =>
      'Nevadas - precaución en carreteras resbaladizas';

  @override
  String get weatherBadIndoor =>
      'Mal tiempo - actividades de interior recomendadas';

  @override
  String get weatherStormCaution =>
      '¡Alerta meteorológica! Precaución en este tramo';

  @override
  String get weatherNoData => 'No hay datos meteorológicos disponibles';

  @override
  String weatherRoutePoint(String index, String total) {
    return 'Punto $index de $total';
  }

  @override
  String weatherExpectedOnDay(String weather, int day) {
    return '$weather esperado el día $day';
  }

  @override
  String weatherOutdoorStops(int outdoor, int total) {
    return '$outdoor de $total paradas son actividades al aire libre.';
  }

  @override
  String get weatherSuggestIndoor => 'Sugerir alternativas de interior';

  @override
  String get weatherStormExpected => 'Se espera tormenta';

  @override
  String get weatherRainExpected => 'Se espera lluvia';

  @override
  String get weatherIdealOutdoorWeather => 'Clima ideal para exteriores';

  @override
  String get weatherStormIndoorPrefer =>
      'Se espera tormenta – preferir paradas de interior';

  @override
  String get weatherRainIndoorHighlight =>
      'Se espera lluvia – paradas de interior destacadas';

  @override
  String get weekdayMon => 'Lu';

  @override
  String get weekdayTue => 'Ma';

  @override
  String get weekdayWed => 'Mi';

  @override
  String get weekdayThu => 'Ju';

  @override
  String get weekdayFri => 'Vi';

  @override
  String get weekdaySat => 'Sá';

  @override
  String get weekdaySun => 'Do';

  @override
  String get mapFavorites => 'Favoritos';

  @override
  String get mapProfile => 'Perfil';

  @override
  String get mapSettings => 'Ajustes';

  @override
  String get mapToRoute => 'A la ruta';

  @override
  String get mapSetAsStart => 'Establecer como inicio';

  @override
  String get mapSetAsDestination => 'Establecer como destino';

  @override
  String get mapAddAsStop => 'Añadir como parada';

  @override
  String get tripConfigGps => 'GPS';

  @override
  String get tripConfigCityOrAddress => 'Ciudad o dirección...';

  @override
  String get tripConfigDestinationOptional => 'Destino (opcional)';

  @override
  String get tripConfigAddDestination => 'Añadir destino (opcional)';

  @override
  String get tripConfigEnterDestination => 'Introducir destino...';

  @override
  String get tripConfigNoDestinationRoundtrip =>
      'Sin destino: viaje circular desde el inicio';

  @override
  String get tripConfigSurpriseMe => '¡Sorpréndeme!';

  @override
  String get tripConfigDeleteRoute => 'Eliminar ruta';

  @override
  String get tripConfigTripDuration => 'Duración del viaje';

  @override
  String get tripConfigDay => 'Día';

  @override
  String get tripConfigDays => 'Días';

  @override
  String tripConfigDayTrip(String distance) {
    return 'Excursión de un día — aprox. $distance km';
  }

  @override
  String tripConfigWeekendTrip(String distance) {
    return 'Escapada de fin de semana — aprox. $distance km';
  }

  @override
  String tripConfigShortVacation(String distance) {
    return 'Escapada corta — aprox. $distance km';
  }

  @override
  String tripConfigWeekTravel(String distance) {
    return 'Viaje de una semana — aprox. $distance km';
  }

  @override
  String tripConfigEpicEuroTrip(String distance) {
    return 'Épico viaje europeo — aprox. $distance km';
  }

  @override
  String get tripConfigRadius => 'Radio';

  @override
  String get tripConfigPoiCategories => 'Categorías de POI';

  @override
  String get tripConfigResetAll => 'Restablecer todo';

  @override
  String get tripConfigAllCategories => 'Todas las categorías seleccionadas';

  @override
  String tripConfigCategoriesSelected(int selected, int total) {
    return '$selected de $total seleccionadas';
  }

  @override
  String get tripConfigCategories => 'Categorías';

  @override
  String tripConfigSelectedCount(int count) {
    return '$count seleccionadas';
  }

  @override
  String get tripConfigPoisAlongRoute => 'POIs a lo largo de la ruta';

  @override
  String get tripConfigActiveTripTitle => 'Viaje activo existente';

  @override
  String tripConfigActiveTripMessage(int days, int completed) {
    return 'Tienes un viaje activo de $days días con $completed días completados. Un nuevo viaje sobrescribirá este.';
  }

  @override
  String get tripConfigCreateNewTrip => 'Crear nuevo viaje';

  @override
  String get tripInfoGenerating => 'Generando viaje...';

  @override
  String get tripInfoLoadingPois => 'Cargando POIs, optimizando ruta';

  @override
  String get tripInfoAiEuroTrip => 'Viaje europeo con IA';

  @override
  String get tripInfoAiDayTrip => 'Excursión de un día con IA';

  @override
  String get tripInfoEditTrip => 'Editar viaje';

  @override
  String get tripInfoStartNavigation => 'Iniciar navegación';

  @override
  String get tripInfoStops => 'Paradas';

  @override
  String get tripInfoDistance => 'Distancia';

  @override
  String get tripInfoDaysLabel => 'Días';

  @override
  String get activeTripTitle => 'Viaje europeo activo';

  @override
  String get activeTripDiscard => 'Descartar viaje activo';

  @override
  String get activeTripDiscardTitle => '¿Descartar viaje?';

  @override
  String activeTripDiscardMessage(int days, int completed) {
    return 'Tu viaje de $days días con $completed días completados será eliminado.';
  }

  @override
  String activeTripDayPending(int day) {
    return 'Día $day pendiente';
  }

  @override
  String activeTripDaysCompleted(int completed, int total) {
    return '$completed de $total días completados';
  }

  @override
  String get tripModeAiDayTrip => 'Excursión de un día con IA';

  @override
  String get tripModeAiEuroTrip => 'Viaje europeo con IA';

  @override
  String get tripRoutePlanning => 'Planificar ruta';

  @override
  String get tripNoRoute => 'No hay ruta disponible';

  @override
  String get tripTapMap => 'Toca el mapa para establecer inicio y destino';

  @override
  String get tripToMap => 'Al mapa';

  @override
  String get tripGeneratingDescription =>
      'Cargando POIs, optimizando ruta, buscando hoteles';

  @override
  String get tripElevationLoading => 'Cargando perfil de elevación...';

  @override
  String get tripSaveRoute => 'Guardar ruta';

  @override
  String get tripRouteName => 'Nombre de la ruta';

  @override
  String get tripExampleDayTrip => 'p. ej. Escapada de fin de semana';

  @override
  String get tripExampleAiDayTrip => 'p. ej. Excursión con IA';

  @override
  String get tripExampleAiEuroTrip => 'p. ej. Viaje europeo con IA';

  @override
  String tripRouteSaved(String name) {
    return 'Ruta \"$name\" guardada';
  }

  @override
  String get tripYourRoute => 'Tu ruta';

  @override
  String get tripDrivingTime => 'Tiempo de conducción';

  @override
  String get tripStopRemoved => 'Parada eliminada';

  @override
  String get tripOptimizeRoute => 'Optimizar ruta';

  @override
  String get tripOptimizeBestOrder => 'Calcular mejor orden';

  @override
  String get tripShareRoute => 'Compartir ruta';

  @override
  String get tripDeleteAllStops => 'Eliminar todas las paradas';

  @override
  String get tripDeleteEntireRoute => 'Eliminar toda la ruta';

  @override
  String get tripDeleteRouteAndStops => 'Eliminar ruta y todas las paradas';

  @override
  String get tripConfirmDeleteAllStops => '¿Eliminar todas las paradas?';

  @override
  String get tripConfirmDeleteEntireRoute => '¿Eliminar toda la ruta?';

  @override
  String get tripDeleteEntireRouteMessage =>
      'La ruta y todas las paradas serán eliminadas. Esta acción no se puede deshacer.';

  @override
  String get tripBackToConfig => 'Volver a la configuración';

  @override
  String tripExportDay(int day) {
    return 'Día $day en Google Maps';
  }

  @override
  String tripReExportDay(int day) {
    return 'Exportar día $day de nuevo';
  }

  @override
  String get tripGoogleMapsHint =>
      'Google Maps calcula su propia ruta a través de las paradas';

  @override
  String tripNoStopsForDay(int day) {
    return 'Sin paradas para el día $day';
  }

  @override
  String get tripCompleted => '¡Viaje completado!';

  @override
  String tripAllDaysExported(int days) {
    return 'Los $days días se han exportado con éxito. ¿Quieres guardar el viaje en tus favoritos?';
  }

  @override
  String get tripKeep => 'Mantener';

  @override
  String get tripSaveToFavorites => 'Guardar en favoritos';

  @override
  String get tripShareHeader => 'Mi ruta con MapAB';

  @override
  String tripShareStart(String address) {
    return 'Inicio: $address';
  }

  @override
  String tripShareEnd(String address) {
    return 'Destino: $address';
  }

  @override
  String tripShareDistance(String distance) {
    return 'Distancia: $distance km';
  }

  @override
  String tripShareDuration(String duration) {
    return 'Duración: $duration min';
  }

  @override
  String get tripShareStops => 'Paradas:';

  @override
  String get tripShareOpenMaps => 'Abrir en Google Maps:';

  @override
  String get tripMyRoute => 'Mi ruta';

  @override
  String get tripGoogleMaps => 'Google Maps';

  @override
  String get tripShowInFavorites => 'Ver';

  @override
  String get tripGoogleMapsError => 'No se pudo abrir Google Maps';

  @override
  String get tripShareError => 'No se pudo compartir la ruta';

  @override
  String get tripWeatherDangerHint =>
      'Tiempo severo previsto – prefiere paradas cubiertas';

  @override
  String get tripWeatherBadHint =>
      'Lluvia prevista – paradas cubiertas destacadas';

  @override
  String get tripStart => 'Inicio';

  @override
  String get tripDestination => 'Destino';

  @override
  String get tripNew => 'Nuevo';

  @override
  String get dayEditorTitle => 'Editar viaje';

  @override
  String get dayEditorNoTrip => 'No hay viaje disponible';

  @override
  String get dayEditorStartNotAvailable => 'Punto de inicio no disponible';

  @override
  String dayEditorEditDay(int day) {
    return 'Editar día $day';
  }

  @override
  String get dayEditorRegenerate => 'Regenerar';

  @override
  String dayEditorMaxStops(int max) {
    return 'Máx. $max paradas por día posibles en Google Maps';
  }

  @override
  String get dayEditorSearchRecommendations =>
      'Buscando recomendaciones de POI...';

  @override
  String get dayEditorLoadRecommendations => 'Cargar recomendaciones de POI';

  @override
  String get dayEditorAiRecommendations => 'Recomendaciones de IA';

  @override
  String get dayEditorRecommended => 'Recomendado';

  @override
  String get dayEditorNoPhotoFallbackHint =>
      'No hay foto disponible - la descripción y los destacados siguen disponibles.';

  @override
  String dayEditorAddedToDay(int day) {
    return 'añadido al día $day';
  }

  @override
  String get dayEditorAllDaysExported =>
      'Todos los días se han exportado con éxito a Google Maps. ¡Buen viaje!';

  @override
  String get dayEditorAddPois => 'Añadir POIs';

  @override
  String dayEditorMyRouteDay(int day) {
    return 'Mi ruta - Día $day con MapAB';
  }

  @override
  String dayEditorMapabRouteDay(int day) {
    return 'Ruta MapAB - Día $day';
  }

  @override
  String dayEditorSwapped(String name) {
    return '\"$name\" intercambiado';
  }

  @override
  String get corridorTitle => 'POIs a lo largo de la ruta';

  @override
  String corridorFound(int total) {
    return '$total encontrados';
  }

  @override
  String corridorFoundWithNew(int total, int newCount) {
    return '$total encontrados ($newCount nuevos)';
  }

  @override
  String corridorWidth(int km) {
    return 'Corredor: $km km';
  }

  @override
  String get corridorSearching => 'Buscando POIs en el corredor...';

  @override
  String get corridorNoPoiInCategory =>
      'No se encontraron POIs en esta categoría';

  @override
  String get corridorNoPois => 'No se encontraron POIs en el corredor';

  @override
  String get corridorTryWider => 'Intenta con un corredor más ancho';

  @override
  String get corridorRemoveStop => '¿Eliminar parada?';

  @override
  String get corridorMinOneStop => 'Se requiere al menos 1 parada por día';

  @override
  String corridorPoiRemoved(String name) {
    return '\"$name\" eliminado';
  }

  @override
  String get navEndConfirm => '¿Finalizar navegación?';

  @override
  String get navDestinationReached => '¡Destino alcanzado!';

  @override
  String get navDistance => 'Distancia';

  @override
  String get navArrival => 'Llegada';

  @override
  String get navSpeed => 'Velocidad';

  @override
  String get navMuteOn => 'Sonido activado';

  @override
  String get navMuteOff => 'Sonido desactivado';

  @override
  String get navOverview => 'Vista general';

  @override
  String get navEnd => 'Finalizar';

  @override
  String get navVoice => 'Voz';

  @override
  String get navVoiceListening => 'Escuchando...';

  @override
  String get navStartButton => 'Iniciar navegación';

  @override
  String get navRerouting => 'Recalculando ruta';

  @override
  String get navVisited => 'Visitado';

  @override
  String navDistanceMeters(String distance) {
    return 'a $distance m';
  }

  @override
  String navDistanceKm(String distance) {
    return 'a $distance km';
  }

  @override
  String get navDepart => 'Iniciar ruta';

  @override
  String navDepartOn(String street) {
    return 'Iniciar ruta por $street';
  }

  @override
  String get navArrive => 'Ha llegado a su destino';

  @override
  String navArriveAt(String street) {
    return 'Destino alcanzado: $street';
  }

  @override
  String navContinueOn(String street) {
    return 'Continuar por $street';
  }

  @override
  String get navContinue => 'Continuar';

  @override
  String get navTurnRight => 'Gire a la derecha';

  @override
  String get navTurnLeft => 'Gire a la izquierda';

  @override
  String navTurnRightOn(String street) {
    return 'Gire a la derecha por $street';
  }

  @override
  String navTurnLeftOn(String street) {
    return 'Gire a la izquierda por $street';
  }

  @override
  String get navSlightRight => 'Gire ligeramente a la derecha';

  @override
  String get navSlightLeft => 'Gire ligeramente a la izquierda';

  @override
  String navSlightRightOn(String street) {
    return 'Ligeramente a la derecha por $street';
  }

  @override
  String navSlightLeftOn(String street) {
    return 'Ligeramente a la izquierda por $street';
  }

  @override
  String get navSharpRight => 'Gire cerrado a la derecha';

  @override
  String get navSharpLeft => 'Gire cerrado a la izquierda';

  @override
  String get navUturn => 'Dé la vuelta';

  @override
  String get navStraight => 'Continúe recto';

  @override
  String navStraightOn(String street) {
    return 'Recto por $street';
  }

  @override
  String get navMerge => 'Incorpórese';

  @override
  String navMergeOn(String street) {
    return 'Incorpórese a $street';
  }

  @override
  String get navOnRamp => 'Tome la entrada';

  @override
  String navOnRampOn(String street) {
    return 'Entrada a $street';
  }

  @override
  String get navOffRamp => 'Tome la salida';

  @override
  String navOffRampOn(String street) {
    return 'Salida $street';
  }

  @override
  String navRoundaboutExit(String ordinal) {
    return 'En la rotonda, tome la $ordinal salida';
  }

  @override
  String navRoundaboutExitOn(String ordinal, String street) {
    return 'En la rotonda, tome la $ordinal salida por $street';
  }

  @override
  String get navRoundaboutEnter => 'Entre en la rotonda';

  @override
  String get navRoundaboutLeave => 'Salga de la rotonda';

  @override
  String get navForkLeft => 'En la bifurcación, manténgase a la izquierda';

  @override
  String get navForkRight => 'En la bifurcación, manténgase a la derecha';

  @override
  String navForkLeftOn(String street) {
    return 'En la bifurcación a la izquierda por $street';
  }

  @override
  String navForkRightOn(String street) {
    return 'En la bifurcación a la derecha por $street';
  }

  @override
  String get navEndOfRoadLeft => 'Al final de la calle, gire a la izquierda';

  @override
  String get navEndOfRoadRight => 'Al final de la calle, gire a la derecha';

  @override
  String navEndOfRoadLeftOn(String street) {
    return 'Al final de la calle a la izquierda por $street';
  }

  @override
  String navEndOfRoadRightOn(String street) {
    return 'Al final de la calle a la derecha por $street';
  }

  @override
  String navInDistance(String distance, String instruction) {
    return 'En $distance $instruction';
  }

  @override
  String navNow(String instruction) {
    return 'Ahora $instruction';
  }

  @override
  String navMeters(String value) {
    return '$value metros';
  }

  @override
  String navKilometers(String value) {
    return '$value kilómetros';
  }

  @override
  String get navOrdinalFirst => 'primera';

  @override
  String get navOrdinalSecond => 'segunda';

  @override
  String get navOrdinalThird => 'tercera';

  @override
  String get navOrdinalFourth => 'cuarta';

  @override
  String get navOrdinalFifth => 'quinta';

  @override
  String get navOrdinalSixth => 'sexta';

  @override
  String get navOrdinalSeventh => 'séptima';

  @override
  String get navOrdinalEighth => 'octava';

  @override
  String navSharpRightOn(String street) {
    return 'Gire cerrado a la derecha por $street';
  }

  @override
  String navSharpLeftOn(String street) {
    return 'Gire cerrado a la izquierda por $street';
  }

  @override
  String navUturnOn(String street) {
    return 'Dé la vuelta por $street';
  }

  @override
  String get navTurn => 'Gire';

  @override
  String navTurnOn(String street) {
    return 'Gire por $street';
  }

  @override
  String get navForkStraight => 'Continúe en la bifurcación';

  @override
  String navForkStraightOn(String street) {
    return 'Continúe en la bifurcación por $street';
  }

  @override
  String get navEndOfRoadStraight => 'Continúe al final de la calle';

  @override
  String navEndOfRoadStraightOn(String street) {
    return 'Continúe al final de la calle por $street';
  }

  @override
  String navRoundaboutLeaveOn(String street) {
    return 'Salga de la rotonda por $street';
  }

  @override
  String navRoundaboutEnterOn(String street) {
    return 'Entre en la rotonda por $street';
  }

  @override
  String get navStraightContinue => 'Continúe recto';

  @override
  String get navDirectionLeft => 'Izquierda ';

  @override
  String get navDirectionRight => 'Derecha ';

  @override
  String get navSharpRightShort => 'Cerrado a la derecha';

  @override
  String get navRightShort => 'Derecha';

  @override
  String get navSlightRightShort => 'Ligeramente a la derecha';

  @override
  String get navStraightShort => 'Recto';

  @override
  String get navSlightLeftShort => 'Ligeramente a la izquierda';

  @override
  String get navLeftShort => 'Izquierda';

  @override
  String get navSharpLeftShort => 'Cerrado a la izquierda';

  @override
  String get navKeepLeft => 'Manténgase a la izquierda';

  @override
  String get navKeepRight => 'Manténgase a la derecha';

  @override
  String get navRoundabout => 'Rotonda';

  @override
  String navExitShort(String ordinal) {
    return '$ordinal salida';
  }

  @override
  String get navMustSeeStop => 'Parar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsDesign => 'Diseño';

  @override
  String get settingsAutoDarkMode => 'Modo oscuro automático';

  @override
  String get settingsAutoDarkModeDesc => 'Activar automáticamente al anochecer';

  @override
  String get settingsFeedback => 'Comentarios';

  @override
  String get settingsHaptic => 'Vibración táctil';

  @override
  String get settingsHapticDesc => 'Vibraciones al interactuar';

  @override
  String get settingsSound => 'Efectos de sonido';

  @override
  String get settingsSoundDesc => 'Sonidos en acciones';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsAppVersion => 'Versión de la aplicación';

  @override
  String get settingsLicenses => 'Licencias de código abierto';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeOled => 'Negro OLED';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileEdit => 'Editar perfil';

  @override
  String get profileCloudAccount => 'Cuenta en la nube';

  @override
  String get profileAutoSync => 'Los datos se sincronizan automáticamente';

  @override
  String get profileGuestAccount => 'Cuenta de invitado';

  @override
  String get profileLocalStorage => 'Almacenado localmente';

  @override
  String get profileUpgradeToCloud => 'Actualizar a cuenta en la nube';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileNoAccount => 'Sin cuenta';

  @override
  String get profileLoginPrompt => 'Inicia sesión para ver tu perfil';

  @override
  String get profileLogin => 'Iniciar sesión';

  @override
  String profileLevel(int level) {
    return 'Nivel $level';
  }

  @override
  String profileXpProgress(int xp, int level) {
    return 'Faltan $xp XP para el nivel $level';
  }

  @override
  String get profileStatistics => 'Estadísticas';

  @override
  String get profileStatisticsLoading => 'Cargando estadísticas...';

  @override
  String get profileStartFirstTrip =>
      '¡Inicia tu primer viaje para ver estadísticas!';

  @override
  String get profileTrips => 'Viajes';

  @override
  String get profilePois => 'POIs';

  @override
  String get profileKilometers => 'Kilómetros';

  @override
  String get profileAchievements => 'Logros';

  @override
  String get profileNoAchievements =>
      'Aún no hay logros desbloqueados. ¡Inicia tu primer viaje!';

  @override
  String profileAccountId(String id) {
    return 'ID de cuenta: $id';
  }

  @override
  String profileCreatedAt(String date) {
    return 'Creado el: $date';
  }

  @override
  String profileLastLogin(String date) {
    return 'Último inicio: $date';
  }

  @override
  String get profileEditComingSoon => '¡Edición de perfil próximamente!';

  @override
  String get profileLogoutTitle => '¿Cerrar sesión?';

  @override
  String get profileLogoutMessage => '¿Realmente quieres cerrar sesión?';

  @override
  String get profileLogoutCloudMessage =>
      '¿Realmente quieres cerrar sesión?\n\nTus datos en la nube se conservarán y podrás volver a iniciar sesión en cualquier momento.';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get profileDeleteTitle => '¿Eliminar cuenta?';

  @override
  String get profileDeleteMessage =>
      '¿Realmente quieres eliminar tu cuenta? ¡Todos los datos se eliminarán de forma permanente!';

  @override
  String get favTitle => 'Favoritos';

  @override
  String get favRoutes => 'Rutas';

  @override
  String get favPois => 'POIs';

  @override
  String get favDeleteAll => 'Eliminar todo';

  @override
  String get favNoFavorites => 'Sin favoritos';

  @override
  String get favNoFavoritesDesc => 'Guarda rutas y POIs para acceso rápido';

  @override
  String get favExplore => 'Explorar';

  @override
  String get favNoRoutes => 'Sin rutas guardadas';

  @override
  String get favPlanRoute => 'Planificar ruta';

  @override
  String get favNoPois => 'Sin POIs favoritos';

  @override
  String get favDiscoverPois => 'Descubrir POIs';

  @override
  String get favRemoveRoute => '¿Eliminar ruta?';

  @override
  String favRemoveRouteConfirm(String name) {
    return '¿Quieres eliminar \"$name\" de los favoritos?';
  }

  @override
  String get favRemovePoi => '¿Eliminar POI?';

  @override
  String favRemovePoiConfirm(String name) {
    return '¿Quieres eliminar \"$name\" de los favoritos?';
  }

  @override
  String get favRouteLoaded => 'Ruta cargada';

  @override
  String get favRouteRemoved => 'Ruta eliminada';

  @override
  String get favPoiRemoved => 'POI eliminado';

  @override
  String get favClearAll => '¿Eliminar todos los favoritos?';

  @override
  String get favAllDeleted => 'Todos los favoritos eliminados';

  @override
  String get poiSearchHint => 'Buscar POIs...';

  @override
  String get poiClearFilters => 'Borrar filtros';

  @override
  String get poiResetFilters => 'Restablecer filtros';

  @override
  String get poiLoading => 'Cargando lugares de interés...';

  @override
  String get poiNotFound => 'POI no encontrado';

  @override
  String get poiLoadingDetails => 'Cargando detalles...';

  @override
  String get poiMoreOnWikipedia => 'Más en Wikipedia';

  @override
  String get poiOpeningHours => 'Horario de apertura';

  @override
  String poiRouteCreated(String name) {
    return 'Ruta a \"$name\" creada';
  }

  @override
  String get poiOnlyMustSee => 'Solo imprescindibles';

  @override
  String get poiShowOnlyHighlights => 'Mostrar solo destacados';

  @override
  String get poiOnlyIndoor => 'Solo POIs de interior';

  @override
  String get poiApplyFilters => 'Aplicar filtros';

  @override
  String get poiReroll => 'Generar de nuevo';

  @override
  String get poiTitle => 'Atracciones';

  @override
  String get poiMustSee => 'Imprescindibles';

  @override
  String get poiWeatherTip => 'Consejo meteorológico';

  @override
  String poiResultsCount(int filtered, int total) {
    return '$filtered de $total POIs';
  }

  @override
  String get poiNoResultsFilter => 'No se encontraron POIs con estos filtros';

  @override
  String get poiNoResultsNearby => 'No se encontraron POIs cercanos';

  @override
  String get poiGpsPermissionNeeded =>
      'Se necesita permiso GPS para encontrar POIs cercanos';

  @override
  String get poiWeatherDangerBanner =>
      'Tormenta esperada – POIs interiores recomendados';

  @override
  String get poiWeatherBadBanner =>
      'Lluvia esperada – activa \"Consejo meteorológico\" para mejor ordenación';

  @override
  String get poiAboutPlace => 'Sobre este lugar';

  @override
  String get poiNoDescription => 'No hay descripción disponible.';

  @override
  String get poiDescriptionLoading => 'Cargando descripción...';

  @override
  String get poiContactInfo => 'Contacto e Info';

  @override
  String get poiPhone => 'Teléfono';

  @override
  String get poiWebsite => 'Sitio web';

  @override
  String get poiEmailLabel => 'E-mail';

  @override
  String get poiDetour => 'Desvío';

  @override
  String get poiTime => 'Tiempo';

  @override
  String get poiPosition => 'Posición';

  @override
  String get poiCurated => 'Seleccionado';

  @override
  String get poiVerified => 'Verificado';

  @override
  String poiAddedToRoute(String name) {
    return '$name añadido a la ruta';
  }

  @override
  String poiFoundedYear(int year) {
    return 'Fundado en $year';
  }

  @override
  String poiRating(String rating, int count) {
    return '$rating de 5 ($count reseñas)';
  }

  @override
  String get poiAddToRoute => 'Añadir a la ruta';

  @override
  String get scanTitle => 'Escanear trip';

  @override
  String get scanInstruction => 'Escanear código QR';

  @override
  String get scanDescription =>
      'Coloca tu teléfono sobre un código QR de MapAB para importar un trip compartido.';

  @override
  String get scanLoading => 'Cargando trip...';

  @override
  String get scanInvalidCode => 'Código QR no válido';

  @override
  String get scanInvalidMapabCode => 'Código QR de MapAB no válido';

  @override
  String get scanLoadError => 'No se pudo cargar el trip';

  @override
  String get scanTripFound => '¡Trip encontrado!';

  @override
  String scanStops(int count) {
    return '$count paradas';
  }

  @override
  String scanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get scanImportQuestion => '¿Quieres importar este trip?';

  @override
  String get scanImport => 'Importar';

  @override
  String scanImportSuccess(String name) {
    return '¡$name fue importado!';
  }

  @override
  String get scanImportError => 'No se pudo importar el trip';

  @override
  String get templatesTitle => 'Plantillas de viaje';

  @override
  String get templatesScanQr => 'Escanear QR';

  @override
  String get templatesAudienceAll => 'Todos';

  @override
  String get templatesAudienceCouples => 'Parejas';

  @override
  String get templatesAudienceFamilies => 'Familias';

  @override
  String get templatesAudienceAdventurers => 'Aventureros';

  @override
  String get templatesAudienceFoodies => 'Foodies';

  @override
  String get templatesAudiencePhotographers => 'Fotógrafos';

  @override
  String templatesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String templatesCategories(int count) {
    return '$count categorías';
  }

  @override
  String get templatesIncludedCategories => 'Categorías incluidas';

  @override
  String get templatesDuration => 'Duración del viaje';

  @override
  String templatesRecommended(int days, String daysText) {
    return 'Recomendado: $days $daysText';
  }

  @override
  String templatesBestSeason(String season) {
    return 'Mejor temporada: $season';
  }

  @override
  String get templatesStartPlanning => 'Planificar viaje';

  @override
  String get seasonSpring => 'Primavera';

  @override
  String get seasonSummer => 'Verano';

  @override
  String get seasonAutumn => 'Otoño';

  @override
  String get seasonWinter => 'Invierno';

  @override
  String get seasonSpringAutumn => 'Primavera a otoño';

  @override
  String get seasonYearRound => 'Todo el año';

  @override
  String get day => 'día';

  @override
  String get days => 'días';

  @override
  String get searchSelectStart => 'Seleccionar inicio';

  @override
  String get searchSelectDestination => 'Seleccionar destino';

  @override
  String get searchStartHint => 'Buscar punto de inicio...';

  @override
  String get searchDestinationHint => 'Buscar destino...';

  @override
  String get searchOfflineMode =>
      'Sin Internet - Mostrando sugerencias locales';

  @override
  String get searchEnterLocation => 'Introduce ubicación para buscar';

  @override
  String get searchNoResults => 'No se encontraron resultados';

  @override
  String get searchLocationNotFound => 'No se pudo encontrar la ubicación';

  @override
  String get chatTitle => 'Asistente de IA';

  @override
  String get chatClear => 'Limpiar chat';

  @override
  String get chatWelcome =>
      '¡Hola! Soy tu asistente de viaje con IA. ¿Cómo puedo ayudarte con la planificación?';

  @override
  String get chatInputHint => 'Escribe un mensaje...';

  @override
  String get chatClearConfirm => '¿Limpiar chat?';

  @override
  String get chatClearMessage => 'La conversación completa será eliminada.';

  @override
  String get chatCheckAgain => 'Comprobar de nuevo';

  @override
  String get chatAccept => 'Aceptar';

  @override
  String chatShowAllPois(int count) {
    return 'Mostrar todos los POIs';
  }

  @override
  String get chatDestinationOptional => 'Destino (opcional)';

  @override
  String get chatEmptyRandomRoute => 'Vacío = Ruta aleatoria desde el inicio';

  @override
  String get chatStartOptional => 'Punto de inicio (opcional)';

  @override
  String get chatEmptyUseGps => 'Vacío = Usar ubicación GPS';

  @override
  String get chatIndoorTips => 'Consejos de interior con lluvia';

  @override
  String get chatPoisNearMe => 'POIs cerca de mí';

  @override
  String get chatAttractions => 'Lugares de interés';

  @override
  String get chatRestaurants => 'Restaurantes';

  @override
  String get chatOutdoorHighlights => 'Destacados al aire libre';

  @override
  String get chatNatureParks => 'Naturaleza y parques';

  @override
  String get chatSearchRadius => 'Radio de búsqueda';

  @override
  String get chatGenerateAiTrip => 'Generar viaje AI';

  @override
  String get randomTripNoTrip => 'No se ha generado ningún viaje';

  @override
  String get randomTripRegenerate => 'Generar de nuevo';

  @override
  String get randomTripConfirm => 'Confirmar viaje';

  @override
  String randomTripStopsDay(int day) {
    return 'Paradas (Día $day)';
  }

  @override
  String get randomTripStops => 'Paradas';

  @override
  String get randomTripEnterAddress => 'Introduce ciudad o dirección...';

  @override
  String get randomTripShowDetails => 'Mostrar detalles';

  @override
  String get randomTripOpenGoogleMaps => 'Abrir en Google Maps';

  @override
  String get randomTripSave => 'Guardar viaje';

  @override
  String get randomTripShow => 'Mostrar viaje';

  @override
  String get randomTripBack => 'Atrás';

  @override
  String get mapModeAiDayTrip => 'AI Excursión';

  @override
  String get mapModeAiEuroTrip => 'AI Euro Trip';

  @override
  String get travelDuration => 'Duración del viaje';

  @override
  String get radiusLabel => 'Distancia de viaje';

  @override
  String get categoriesLabel => 'Categorías';

  @override
  String tripDescDayTrip(int radius) {
    return 'Excursión — aprox. $radius km';
  }

  @override
  String tripDescWeekend(int radius) {
    return 'Fin de semana — aprox. $radius km';
  }

  @override
  String tripDescShortVacation(int radius) {
    return 'Vacaciones cortas — aprox. $radius km';
  }

  @override
  String tripDescWeekTrip(int radius) {
    return 'Viaje semanal — aprox. $radius km';
  }

  @override
  String tripDescEpic(int radius) {
    return 'Épico Euro Trip — aprox. $radius km';
  }

  @override
  String selectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get destinationOptional => 'Destino (opcional)';

  @override
  String get enterDestination => 'Introducir destino...';

  @override
  String get mapCityOrAddress => 'Ciudad o dirección...';

  @override
  String get mapAddDestination => 'Añadir destino (opcional)';

  @override
  String get mapSurpriseMe => '¡Sorpréndeme!';

  @override
  String get mapDeleteRoute => 'Eliminar ruta';

  @override
  String mapDaysLabel(String days) {
    return '$days días';
  }

  @override
  String get mapPoiCategories => 'Categorías de POI';

  @override
  String get mapResetAll => 'Restablecer todo';

  @override
  String get mapAllCategoriesSelected => 'Todas las categorías seleccionadas';

  @override
  String mapCategoriesSelected(String count, String total) {
    return '$count de $total seleccionadas';
  }

  @override
  String get mapPoisAlongRoute => 'POIs a lo largo de la ruta';

  @override
  String get mapWithoutDestination =>
      'Sin destino: viaje circular desde el inicio';

  @override
  String get tripTypeDayTrip => 'Excursión de un día';

  @override
  String get tripTypeEuroTrip => 'Viaje europeo';

  @override
  String get tripTypeMultiDay => 'Viaje de varios días';

  @override
  String get tripTypeScenic => 'Ruta panorámica';

  @override
  String get tripTypeDayTripDistance => '30-200 km';

  @override
  String get tripTypeEuroTripDistance => '200-800 km';

  @override
  String get tripTypeMultiDayDistance => '2-7 días';

  @override
  String get tripTypeScenicDistance => 'variable';

  @override
  String get tripTypeDayTripDesc =>
      'Selección de actividades, basado en el clima';

  @override
  String get tripTypeEuroTripDesc => 'Otro país, sugerencias de hoteles';

  @override
  String get tripTypeMultiDayDesc => 'Paradas nocturnas automáticas';

  @override
  String get tripTypeScenicDesc => 'Miradores priorizados';

  @override
  String get accessWheelchair => 'Accesible en silla de ruedas';

  @override
  String get accessNoStairs => 'Sin escaleras';

  @override
  String get accessParking => 'Plaza de aparcamiento para discapacitados';

  @override
  String get accessToilet => 'Aseo para discapacitados';

  @override
  String get accessElevator => 'Ascensor disponible';

  @override
  String get accessBraille => 'Braille';

  @override
  String get accessAudioGuide => 'Audioguía';

  @override
  String get accessSignLanguage => 'Lenguaje de signos';

  @override
  String get accessAssistDogs => 'Perros de asistencia permitidos';

  @override
  String get accessFullyAccessible => 'Totalmente accesible';

  @override
  String get accessLimited => 'Accesibilidad limitada';

  @override
  String get accessNotAccessible => 'No accesible';

  @override
  String get accessUnknown => 'Desconocido';

  @override
  String get highlightUnesco => 'Patrimonio de la UNESCO';

  @override
  String get highlightMustSee => 'Imprescindible';

  @override
  String get highlightSecret => 'Lugar secreto';

  @override
  String get highlightHistoric => 'Histórico';

  @override
  String get highlightFamilyFriendly => 'Familiar';

  @override
  String experienceDetourKm(int km) {
    return '+$km km de desvío';
  }

  @override
  String get formatMinShort => 'min';

  @override
  String get formatHourShort => 'h';

  @override
  String get formatMinLong => 'minutos';

  @override
  String formatHourLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'horas',
      one: 'hora',
    );
    return '$_temp0';
  }

  @override
  String formatDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String formatStopCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String get formatNoInfo => 'Sin información';

  @override
  String get formatJustNow => 'Justo ahora';

  @override
  String formatAgoMinutes(int count) {
    return 'Hace $count min';
  }

  @override
  String formatAgoHours(int count) {
    return 'Hace $count h';
  }

  @override
  String formatAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get formatUnknown => 'Desconocido';

  @override
  String get journalTitle => 'Diario de viaje';

  @override
  String get journalEmptyTitle => 'Sin entradas';

  @override
  String get journalEmptySubtitle =>
      'Captura tus recuerdos de viaje con fotos y notas.';

  @override
  String get journalAddEntry => 'Añadir entrada';

  @override
  String get journalAddFirstEntry => 'Crear primera entrada';

  @override
  String get journalNewEntry => 'Nueva entrada';

  @override
  String get journalAddPhoto => 'Añadir foto';

  @override
  String get journalCamera => 'Cámara';

  @override
  String get journalGallery => 'Galería';

  @override
  String get journalAddNote => 'Añadir nota';

  @override
  String get journalNoteHint => '¿Qué has vivido?';

  @override
  String get journalSaveNote => 'Guardar solo nota';

  @override
  String get journalSaveLocation => 'Guardar ubicación';

  @override
  String get journalLocationAvailable => 'Ubicación GPS disponible';

  @override
  String get journalLocationLoading => 'Cargando ubicación...';

  @override
  String get journalEnterNote => 'Por favor ingresa una nota';

  @override
  String get journalDeleteEntryTitle => '¿Eliminar entrada?';

  @override
  String get journalDeleteEntryMessage =>
      'Esta entrada se eliminará permanentemente.';

  @override
  String get journalDeleteTitle => '¿Eliminar diario?';

  @override
  String get journalDeleteMessage =>
      'Todas las entradas y fotos se eliminarán permanentemente.';

  @override
  String journalPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
      zero: 'Sin fotos',
    );
    return '$_temp0';
  }

  @override
  String journalEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
      zero: 'Sin entradas',
    );
    return '$_temp0';
  }

  @override
  String journalDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String journalDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String journalDayNumber(int day) {
    return 'Día $day';
  }

  @override
  String get journalOther => 'Otros';

  @override
  String get journalEntry => 'entrada';

  @override
  String get journalEntriesPlural => 'entradas';

  @override
  String get journalOpenJournal => 'Abrir diario';

  @override
  String get journalAllJournals => 'Todos los diarios';

  @override
  String get journalNoJournals => 'Ningún diario todavía';

  @override
  String get journalMemoryPoint => 'Punto de recuerdo';

  @override
  String get journalRevisit => 'Revisitar';

  @override
  String get journalBack => 'Volver';

  @override
  String get journalEditEntry => 'Editar entrada';

  @override
  String get journalReplacePhoto => 'Reemplazar foto';

  @override
  String get journalRemovePhoto => 'Eliminar foto';

  @override
  String get journalSaveChanges => 'Guardar cambios';

  @override
  String get galleryTitle => 'Galería de trips';

  @override
  String get gallerySearch => 'Buscar trips...';

  @override
  String get galleryFeatured => 'Destacados';

  @override
  String get galleryAllTrips => 'Todos los trips';

  @override
  String get galleryNoTrips => 'No se encontraron trips';

  @override
  String get galleryResetFilters => 'Restablecer filtros';

  @override
  String get galleryFilter => 'Filtrar';

  @override
  String get galleryFilterReset => 'Restablecer';

  @override
  String get galleryTripType => 'Tipo de trip';

  @override
  String get galleryTags => 'Etiquetas';

  @override
  String get gallerySort => 'Ordenar por';

  @override
  String get gallerySortPopular => 'Popular';

  @override
  String get gallerySortRecent => 'Reciente';

  @override
  String get gallerySortLikes => 'Más me gusta';

  @override
  String get galleryTypeAll => 'Todos';

  @override
  String get galleryTypeDaytrip => 'Excursión';

  @override
  String get galleryTypeEurotrip => 'Euro Trip';

  @override
  String get galleryRetry => 'Reintentar';

  @override
  String galleryLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count me gusta',
      one: '1 me gusta',
      zero: 'Sin me gusta',
    );
    return '$_temp0';
  }

  @override
  String galleryViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vistas',
      one: '1 vista',
    );
    return '$_temp0';
  }

  @override
  String galleryImports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count importaciones',
      one: '1 importación',
    );
    return '$_temp0';
  }

  @override
  String gallerySharedAt(String date) {
    return 'Compartido el $date';
  }

  @override
  String galleryTripsShared(int count) {
    return '$count trips compartidos';
  }

  @override
  String get galleryImportToFavorites => 'Añadir a favoritos';

  @override
  String get galleryImported => 'Importado';

  @override
  String get galleryShowOnMap => 'En el mapa';

  @override
  String get galleryShareComingSoon => 'Compartir próximamente';

  @override
  String get galleryMapComingSoon => 'Vista de mapa próximamente';

  @override
  String get galleryMapNoData => 'No hay datos de ruta disponibles';

  @override
  String get galleryMapError => 'Error al cargar la ruta';

  @override
  String get galleryImportSuccess => 'Trip añadido a favoritos';

  @override
  String get galleryImportError => 'Error al importar';

  @override
  String get galleryTripNotFound => 'Trip no encontrado';

  @override
  String get galleryLoadError => 'Error al cargar';

  @override
  String get publishTitle => 'Publicar trip';

  @override
  String get publishSubtitle => 'Comparte tu trip con la comunidad';

  @override
  String get publishPoiTitle => 'Publicar POI';

  @override
  String get publishPoiSubtitle => 'Comparte este lugar con la comunidad';

  @override
  String get publishTripName => 'Nombre del trip';

  @override
  String get publishTripNameHint => 'ej. Road trip Sur de Francia';

  @override
  String get publishTripNameRequired => 'Por favor ingresa un nombre';

  @override
  String get publishTripNameMinLength =>
      'El nombre debe tener al menos 3 caracteres';

  @override
  String get publishDescription => 'Descripción (opcional)';

  @override
  String get publishDescriptionHint => 'Cuéntales a otros sobre tu trip...';

  @override
  String get publishTags => 'Etiquetas (opcional)';

  @override
  String get publishTagsHelper => 'Ayuda a otros a encontrar tu trip';

  @override
  String get publishMaxTags => 'Máximo 5 etiquetas';

  @override
  String get publishInfo =>
      'Tu trip será visible públicamente. Otros pueden darle me gusta e importarlo a sus favoritos.';

  @override
  String get publishButton => 'Publicar';

  @override
  String get publishPublishing => 'Publicando...';

  @override
  String get publishSuccess => '¡Trip publicado!';

  @override
  String get publishError => 'Error al publicar';

  @override
  String get tripPublish => 'Publicar trip';

  @override
  String get tripPublishDescription => 'Compartir en galería pública';

  @override
  String get publishEuroTrip => 'Euro Trip';

  @override
  String get publishDaytrip => 'Excursión';

  @override
  String get publishCoverImage => 'Imagen de portada';

  @override
  String get publishCoverImageHint =>
      'Una imagen de título para tu trip (opcional)';

  @override
  String get tripPhotos => 'Fotos';

  @override
  String get tripNoPhotos => 'Aún no hay fotos subidas';

  @override
  String get tripAddFirstPhoto => 'Añadir primera foto';

  @override
  String get tripPhotoUpload => 'Subir foto del trip';

  @override
  String get dayEditorDriveTime => 'Tiempo de conducción';

  @override
  String get dayEditorWeather => 'Clima';

  @override
  String dayEditorForecastDestination(String name) {
    return 'Destino: $name';
  }

  @override
  String get dayEditorDay => 'Día';

  @override
  String dayEditorNoStopsForDay(int day) {
    return 'Sin paradas para el día $day';
  }

  @override
  String dayEditorDayInGoogleMaps(int day) {
    return 'Día $day en Google Maps';
  }

  @override
  String dayEditorOpenAgain(int day) {
    return 'Reabrir día $day';
  }

  @override
  String get dayEditorTripCompleted => '¡Trip completado!';

  @override
  String get dayEditorRouteShare => 'Compartir ruta';

  @override
  String get dayEditorRouteShareError => 'No se pudo compartir la ruta';

  @override
  String get dayEditorShareStops => 'Paradas';

  @override
  String get dayEditorShareOpenGoogleMaps => 'Abrir en Google Maps';

  @override
  String get tripSummaryTotal => 'Total';

  @override
  String get tripSummaryDriveTime => 'Tiempo de conducción';

  @override
  String get tripSummaryStops => 'Paradas';

  @override
  String get filterTitle => 'Filtros';

  @override
  String get filterMaxDetour => 'Desvío máximo';

  @override
  String get filterMaxDetourHint => 'Los POIs con mayor desvío se ocultarán';

  @override
  String get filterAllCategories => 'Mostrar todas las categorías';

  @override
  String filterSelectedCount(int count) {
    return '$count seleccionadas';
  }

  @override
  String get filterCategoriesLabel => 'Categorías';

  @override
  String get categorySelectorDeselectAll => 'Deseleccionar todo';

  @override
  String get categorySelectorNoneHint => 'Sin selección = todas las categorías';

  @override
  String categorySelectorSelectedCount(int count) {
    return '$count seleccionadas';
  }

  @override
  String get categorySelectorTitle => 'Categorías';

  @override
  String get startLocationLabel => 'Punto de partida';

  @override
  String get startLocationHint => 'Ingresa ciudad o dirección...';

  @override
  String get startLocationGps => 'Usar ubicación GPS';

  @override
  String get tripPreviewNoTrip => 'Ningún trip generado';

  @override
  String get tripPreviewYourTrip => 'Tu Trip';

  @override
  String get tripPreviewConfirm => 'Confirmar trip';

  @override
  String tripPreviewMaxStopsWarning(int max) {
    return 'Máx. $max paradas por día (límite Google Maps)';
  }

  @override
  String tripPreviewStopsDay(int day) {
    return 'Paradas (Día $day)';
  }

  @override
  String tripPreviewDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Días',
      one: 'Día',
    );
    return '$_temp0';
  }

  @override
  String get navSkip => 'Saltar';

  @override
  String get navVisitedButton => 'Visitado';

  @override
  String navDistanceAway(String distance) {
    return 'a $distance';
  }

  @override
  String get chatDemoMode => 'Modo demo: las respuestas son simuladas';

  @override
  String get chatLocationLoading => 'Cargando ubicación...';

  @override
  String get chatLocationActive => 'Ubicación activa';

  @override
  String get chatLocationEnable => 'Activar ubicación';

  @override
  String get chatMyLocation => 'Mi ubicación';

  @override
  String get chatRadiusTooltip => 'Radio de búsqueda';

  @override
  String get chatNoPoisFound => 'No se encontraron POIs cercanos';

  @override
  String chatPoisInRadius(int count, String radius) {
    return '$count POIs en un radio de $radius km';
  }

  @override
  String chatRadiusLabel(String radius) {
    return '$radius km';
  }

  @override
  String get chatWelcomeSubtitle => 'Pregúntame lo que quieras sobre tu viaje!';

  @override
  String get chatDemoBackendNotReachable => 'Modo demo: Backend no disponible';

  @override
  String get chatDemoBackendNotConfigured =>
      'Modo demo: URL del backend no configurada';

  @override
  String get chatNumberOfDays => 'Número de días';

  @override
  String get chatInterests => 'Intereses:';

  @override
  String get chatLocationNotAvailable => 'Ubicación no disponible';

  @override
  String get chatLocationNotAvailableMessage =>
      'Para encontrar POIs cerca de ti, necesito acceso a tu ubicación.\n\nPor favor activa los servicios de ubicación e inténtalo de nuevo.';

  @override
  String get chatPoisSearchError => 'Error en la búsqueda de POIs';

  @override
  String get chatPoisSearchErrorMessage =>
      'Lo siento, hubo un problema al cargar los POIs.\n\nPor favor inténtalo de nuevo.';

  @override
  String get chatNoPhotoFallbackHint =>
      'No hay foto disponible - los detalles siguen disponibles.';

  @override
  String get chatNoResponseGenerated =>
      'Lo siento, no pude generar una respuesta.';

  @override
  String get chatRadiusAdjust => 'Ajustar radio de búsqueda';

  @override
  String get voiceRerouting => 'Recalculando ruta';

  @override
  String voicePOIApproaching(String name, String distance) {
    return '$name en $distance';
  }

  @override
  String voiceArrivedAt(String name) {
    return 'Has llegado a: $name';
  }

  @override
  String voiceRouteInfo(String distance, String duration) {
    return 'Quedan $distance y $duration hasta el destino';
  }

  @override
  String voiceNextStop(String name, String distance) {
    return 'Próxima parada: $name en $distance';
  }

  @override
  String voiceCurrentLocation(String location) {
    return 'Ubicación actual: $location';
  }

  @override
  String voiceInMeters(int meters) {
    return '$meters metros';
  }

  @override
  String voiceInKilometers(String km) {
    return '$km kilómetros';
  }

  @override
  String voiceHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String voiceMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String voiceStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String get voiceCmdNextStop => 'Próxima parada';

  @override
  String get voiceCmdLocation => 'Dónde estoy';

  @override
  String get voiceCmdDuration => 'Cuánto falta';

  @override
  String get voiceCmdEndNavigation => 'Terminar navegación';

  @override
  String get voiceNow => 'Ahora';

  @override
  String get voiceArrived => 'Has llegado a tu destino';

  @override
  String voicePOIReached(String name) {
    return '$name alcanzado';
  }

  @override
  String voiceCategory(String category) {
    return 'Categoría: $category';
  }

  @override
  String voiceDistanceMeters(int meters) {
    return 'a $meters metros';
  }

  @override
  String voiceDistanceKm(String km) {
    return 'a $km kilómetros';
  }

  @override
  String voiceRouteLength(String distance, String duration, String stops) {
    return 'Tu ruta mide $distance kilómetros, dura aproximadamente $duration y tiene $stops.';
  }

  @override
  String voiceAndMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return 'y $_temp0';
  }

  @override
  String get voiceCmdPreviousStop => 'Parada anterior';

  @override
  String get voiceCmdNearby => 'Qué hay cerca';

  @override
  String get voiceCmdAdd => 'Añadir a la ruta';

  @override
  String get voiceCmdStartNav => 'Iniciar navegación';

  @override
  String get voiceCmdStopNav => 'Terminar navegación';

  @override
  String get voiceCmdDescribe => 'Leer descripción';

  @override
  String get voiceCmdUnknown => 'Desconocido';

  @override
  String get voiceCmdRouteWeather => 'Clima en la ruta';

  @override
  String get voiceCmdRecommend => 'Recomendación';

  @override
  String get voiceCmdOverview => 'Resumen de ruta';

  @override
  String get voiceCmdRemaining => 'Paradas restantes';

  @override
  String get voiceCmdHelp => 'Ayuda';

  @override
  String get voiceCmdNotAvailable =>
      'Este comando no está disponible durante la navegación.';

  @override
  String get voiceGreeting1 => '¿Listo para tu viaje?';

  @override
  String get voiceGreeting2 => '¿Cómo puedo ayudarte?';

  @override
  String get voiceGreeting3 => '¿Qué te gustaría saber?';

  @override
  String get voiceGreeting4 => '¡Te escucho!';

  @override
  String get voiceGreeting5 => '¡Pregúntame algo!';

  @override
  String get voiceGreeting6 => '¿Listo para tu ruta?';

  @override
  String get voiceGreeting7 => '¡Tu asistente de navegación aquí!';

  @override
  String get voiceGreeting8 => '¿A dónde vamos?';

  @override
  String get voiceUnknown1 =>
      'Hmm, no entendí eso. Intenta decir ¿Cuánto falta? o Siguiente parada.';

  @override
  String get voiceUnknown2 =>
      '¡Ups! Mi cerebro de navegador no captó eso. ¡Di Ayuda para todos los comandos!';

  @override
  String get voiceUnknown3 =>
      'Eso fue demasiado filosófico para mí. ¡Solo soy un simple navegador!';

  @override
  String get voiceUnknown4 =>
      '¿Eh? ¡Soy un navegador, no un lector de mentes! Pregúntame sobre la ruta o el clima.';

  @override
  String get voiceUnknown5 =>
      'No entendí. Intenta ¿Dónde estoy? o ¿Qué hay cerca?';

  @override
  String get voiceUnknown6 =>
      'Beep boop... ¡Comando no reconocido! Entiendo cosas como ¿Cuánto falta?';

  @override
  String voiceWeatherOnRoute(String description, String temp) {
    return 'El clima en tu ruta: $description, $temp grados.';
  }

  @override
  String get voiceNoWeatherData =>
      'Lamentablemente, no tengo datos del clima para tu ruta.';

  @override
  String voiceRecommendPOIs(String names) {
    return 'Te recomiendo: $names. ¡Verdaderos imprescindibles!';
  }

  @override
  String get voiceNoRecommendations => '¡Hay paradas interesantes en tu ruta!';

  @override
  String voiceRouteOverview(String distance, String stops) {
    return 'Tu ruta tiene $distance kilómetros con $stops paradas.';
  }

  @override
  String get voiceRemainingOne => '¡Solo una parada más hasta el destino!';

  @override
  String voiceRemainingMultiple(int count) {
    return 'Aún $count paradas por delante.';
  }

  @override
  String get voiceHelpText =>
      'Puedes preguntarme: ¿Cuánto falta? ¿Siguiente parada? ¿Dónde estoy? ¿Qué tiempo hace? ¿Recomendaciones? O di Terminar navegación.';

  @override
  String voiceManeuverNow(String instruction) {
    return 'Ahora $instruction';
  }

  @override
  String voiceManeuverInMeters(int meters, String instruction) {
    return 'En $meters metros $instruction';
  }

  @override
  String voiceManeuverInKm(String km, String instruction) {
    return 'En $km kilómetros $instruction';
  }

  @override
  String navMustSeeAnnouncement(String distance, String name) {
    return 'En $distance metros se encuentra $name, un lugar imprescindible';
  }

  @override
  String advisorDangerWeather(int day, int outdoorCount) {
    return '¡Alerta meteorológica prevista para el día $day! $outdoorCount paradas exteriores deberían ser reemplazadas por alternativas interiores.';
  }

  @override
  String advisorBadWeather(int day, int outdoorCount, int totalCount) {
    return 'Lluvia prevista para el día $day. $outdoorCount de $totalCount paradas son actividades exteriores.';
  }

  @override
  String advisorOutdoorAlternative(String name) {
    return '$name es una actividad exterior - alternativa recomendada';
  }

  @override
  String advisorOutdoorReplace(String name) {
    return '$name es una actividad exterior. Reemplaza esta parada por una alternativa interior.';
  }

  @override
  String get advisorAiUnavailableSuggestions =>
      'IA no disponible - mostrando sugerencias locales';

  @override
  String advisorNoStopsForDay(int day) {
    return 'Sin paradas para el día $day';
  }

  @override
  String get advisorNoRecommendationsFound =>
      'No se encontraron recomendaciones cerca de las paradas';

  @override
  String get advisorAiUnavailableRecommendations =>
      'IA no disponible - mostrando recomendaciones locales';

  @override
  String get advisorErrorLoadingRecommendations =>
      'Error al cargar las recomendaciones';

  @override
  String advisorPoiCategory(String name, String category) {
    return '$name - $category';
  }

  @override
  String get weatherConditionGood => 'Buen tiempo';

  @override
  String get weatherConditionMixed => 'Variable';

  @override
  String get weatherConditionBad => 'Mal tiempo';

  @override
  String get weatherConditionDanger => 'Alerta meteorológica';

  @override
  String get weatherConditionUnknown => 'Clima desconocido';

  @override
  String get weatherBadgeSnow => 'Nieve';

  @override
  String get weatherBadgeRain => 'Lluvia';

  @override
  String get weatherBadgePerfect => 'Perfecto';

  @override
  String get weatherBadgeBad => 'Malo';

  @override
  String get weatherBadgeDanger => 'Alerta';

  @override
  String get weatherRecOutdoorIdeal => 'Ideal para POIs al aire libre';

  @override
  String get weatherRecRainIndoor => 'Lluvia - POIs interiores recomendados';

  @override
  String get weatherRecDangerIndoor => 'Tormenta - ¡solo POIs interiores!';

  @override
  String get weatherToggleActive => 'Activo';

  @override
  String get weatherToggleApply => 'Aplicar';

  @override
  String get weatherPointStart => 'Inicio';

  @override
  String get weatherPointEnd => 'Destino';

  @override
  String get weatherIndoorOnly => 'Solo POIs interiores';

  @override
  String weatherAlertStorm(String windSpeed) {
    return '¡Alerta de tormenta! Vientos fuertes ($windSpeed km/h) a lo largo de la ruta.';
  }

  @override
  String get weatherAlertDanger =>
      '¡Alerta meteorológica! Se recomienda posponer.';

  @override
  String get weatherAlertWinter => '¡Clima invernal! Posible nieve/hielo.';

  @override
  String get weatherAlertRain =>
      'Se espera lluvia. Se recomiendan actividades interiores.';

  @override
  String get weatherAlertBad => 'Mal tiempo en la ruta.';

  @override
  String get weatherRecToday => 'Recomendación de hoy';

  @override
  String get weatherRecGoodDetail =>
      '¡Tiempo perfecto para actividades al aire libre! Miradores, naturaleza y lagos recomendados.';

  @override
  String get weatherRecMixedDetail =>
      'Tiempo variable. Tanto POIs interiores como exteriores posibles.';

  @override
  String get weatherRecBadDetail =>
      'Se espera lluvia. Se recomiendan actividades interiores como museos e iglesias.';

  @override
  String get weatherRecDangerDetail =>
      '¡Alerta meteorológica! Evite actividades al aire libre y permanezca en interiores.';

  @override
  String get weatherRecNoData => 'No hay datos meteorológicos disponibles.';

  @override
  String get weatherRecOutdoorPerfect =>
      'Tiempo perfecto para actividades al aire libre';

  @override
  String get weatherRecMixedPrepare => 'Variable - prepárate para todo';

  @override
  String get weatherRecSnowCaution =>
      'Nevadas - precaución en carreteras resbaladizas';

  @override
  String get weatherRecBadIndoor =>
      'Mal tiempo - actividades interiores recomendadas';

  @override
  String weatherRecStormWarning(String windSpeed) {
    return '¡Alerta de tormenta! Vientos fuertes ($windSpeed km/h)';
  }

  @override
  String get weatherRecDangerCaution =>
      '¡Alerta meteorológica! Precaución en este tramo';

  @override
  String get weatherRecNoDataAvailable =>
      'No hay datos meteorológicos disponibles';

  @override
  String get mapMyLocation => 'Mi ubicación';

  @override
  String get mapDetails => 'Detalles';

  @override
  String get mapAddToRoute => 'Añadir a la ruta';

  @override
  String get mapSelectedPoint => 'Punto seleccionado';

  @override
  String get mapWaypoint => 'Parada intermedia';

  @override
  String mapRouteCreated(String name) {
    return 'Ruta a \"$name\" creada';
  }

  @override
  String mapPoiAdded(String name) {
    return '\"$name\" añadido';
  }

  @override
  String get mapErrorAdding => 'Error al añadir';

  @override
  String get tripPreviewStartDay1 => 'Inicio (Día 1)';

  @override
  String tripPreviewDayStart(String day) {
    return 'Día $day inicio';
  }

  @override
  String get tripPreviewBackToStart => 'Volver al inicio';

  @override
  String tripPreviewEndDay(String day) {
    return 'Fin día $day';
  }

  @override
  String tripPreviewDetour(String km) {
    return '+$km km desvío';
  }

  @override
  String get tripPreviewOvernight => 'Alojamiento';

  @override
  String get gamificationLevelUp => '¡Subida de nivel!';

  @override
  String gamificationNewLevel(int level) {
    return 'Nivel $level';
  }

  @override
  String get gamificationContinue => 'Continuar';

  @override
  String get gamificationAchievementUnlocked => '¡Logro desbloqueado!';

  @override
  String get gamificationAwesome => '¡Genial!';

  @override
  String gamificationXpEarned(int amount) {
    return '+$amount XP';
  }

  @override
  String get gamificationNextAchievements => 'Próximos logros';

  @override
  String get gamificationAllAchievements => 'Todos los logros';

  @override
  String gamificationUnlockedCount(int count, int total) {
    return '$count/$total desbloqueados';
  }

  @override
  String get gamificationTripCreated => 'Viaje creado';

  @override
  String get gamificationTripPublished => 'Viaje publicado';

  @override
  String get gamificationTripImported => 'Viaje importado';

  @override
  String get gamificationPoiVisited => 'POI visitado';

  @override
  String get gamificationPhotoAdded => 'Foto añadida';

  @override
  String get gamificationLikeReceived => 'Like recibido';

  @override
  String get leaderboardTitle => 'Clasificación';

  @override
  String get leaderboardSortXp => 'XP';

  @override
  String get leaderboardSortKm => 'Kilómetros';

  @override
  String get leaderboardSortTrips => 'Viajes';

  @override
  String get leaderboardSortLikes => 'Likes';

  @override
  String get leaderboardYourPosition => 'Tu posición';

  @override
  String get leaderboardEmpty => 'Aún sin entradas';

  @override
  String leaderboardRank(int rank) {
    return 'Puesto $rank';
  }

  @override
  String get refresh => 'Actualizar';

  @override
  String get challengesTitle => 'Desafíos';

  @override
  String get challengesWeekly => 'Desafíos semanales';

  @override
  String get challengesCompleted => 'Completados';

  @override
  String get challengesEmpty => '¡Nuevos desafíos desbloqueados cada lunes!';

  @override
  String get challengesFeatured => 'DESTACADO';

  @override
  String get challengesCurrentStreak => 'Racha actual';

  @override
  String challengesStreakDays(int days) {
    return '$days Días';
  }

  @override
  String challengesLongestStreak(int days) {
    return 'Récord: $days días';
  }

  @override
  String challengesVisitCategory(int count, String category) {
    return 'Visita $count $category';
  }

  @override
  String challengesVisitCountry(String country) {
    return 'Visita un POI en $country';
  }

  @override
  String challengesCompleteTrips(int count) {
    return 'Completa $count viajes';
  }

  @override
  String challengesTakePhotos(int count) {
    return 'Toma $count fotos de viaje';
  }

  @override
  String challengesStreak(int count) {
    return '$count días seguidos activo';
  }

  @override
  String get challengesWeather => 'Visita un POI con mal tiempo';

  @override
  String challengesShare(int count) {
    return 'Comparte $count viajes';
  }

  @override
  String challengesDiscover(int count) {
    return 'Descubre $count nuevos POIs';
  }

  @override
  String challengesDistance(int km) {
    return 'Viaja $km kilómetros';
  }

  @override
  String get poiRatingLabel => 'Valoración';

  @override
  String get poiReviews => 'Reseñas';

  @override
  String get poiPhotos => 'Fotos';

  @override
  String get poiComments => 'Comentarios';

  @override
  String get poiNoReviews => 'Aún sin reseñas';

  @override
  String get poiNoPhotos => 'Aún sin fotos';

  @override
  String get poiNoComments => 'Aún sin comentarios';

  @override
  String get poiBeFirstReview => '¡Sé el primero en valorar este lugar!';

  @override
  String get poiBeFirstPhoto => '¡Sé el primero en compartir una foto!';

  @override
  String get poiBeFirstComment => '¡Escribe el primer comentario!';

  @override
  String poiReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reseñas',
      one: '1 reseña',
      zero: 'Sin reseñas',
    );
    return '$_temp0';
  }

  @override
  String poiPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
      zero: 'Sin fotos',
    );
    return '$_temp0';
  }

  @override
  String poiCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios',
      one: '1 comentario',
      zero: 'Sin comentarios',
    );
    return '$_temp0';
  }

  @override
  String get reviewSubmit => 'Enviar reseña';

  @override
  String get reviewEdit => 'Editar reseña';

  @override
  String get reviewYourRating => 'Tu valoración';

  @override
  String get reviewWriteOptional => 'Escribe una reseña (opcional)';

  @override
  String get reviewPlaceholder => 'Comparte tu experiencia con otros...';

  @override
  String get reviewVisitDate => 'Fecha de visita';

  @override
  String get reviewVisitDateOptional => 'Fecha de visita (opcional)';

  @override
  String reviewVisitedOn(String date) {
    return 'Visitado el $date';
  }

  @override
  String get reviewHelpful => 'Útil';

  @override
  String reviewHelpfulCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas encontraron esto útil',
      one: '1 persona encontró esto útil',
      zero: 'Aún sin valorar',
    );
    return '$_temp0';
  }

  @override
  String get reviewMarkedHelpful => 'Marcado como útil';

  @override
  String get reviewSuccess => '¡Reseña guardada!';

  @override
  String get reviewError => 'Error al guardar la reseña';

  @override
  String get reviewDelete => 'Eliminar reseña';

  @override
  String get reviewDeleteConfirm =>
      '¿Estás seguro de que quieres eliminar tu reseña?';

  @override
  String get reviewDeleteSuccess => 'Reseña eliminada';

  @override
  String get reviewDeleteError => 'Error al eliminar la reseña';

  @override
  String get reviewRatingRequired => 'Por favor selecciona una valoración';

  @override
  String reviewAvgRating(String rating) {
    return '$rating de 5 estrellas';
  }

  @override
  String get photoUpload => 'Subir foto';

  @override
  String get photoCaption => 'Descripción';

  @override
  String get photoCaptionHint => 'Describe tu foto (opcional)';

  @override
  String get photoFromCamera => 'Cámara';

  @override
  String get photoFromGallery => 'Galería';

  @override
  String get photoUploading => 'Subiendo foto...';

  @override
  String get photoSuccess => '¡Foto subida!';

  @override
  String get photoError => 'Error al subir la foto';

  @override
  String get photoDelete => 'Eliminar foto';

  @override
  String get photoDeleteConfirm =>
      '¿Estás seguro de que quieres eliminar esta foto?';

  @override
  String get photoDeleteSuccess => 'Foto eliminada';

  @override
  String get photoDeleteError => 'Error al eliminar la foto';

  @override
  String photoBy(String author) {
    return 'Foto de $author';
  }

  @override
  String get commentAdd => 'Añadir comentario';

  @override
  String get commentPlaceholder => 'Escribe un comentario...';

  @override
  String get commentReply => 'Responder';

  @override
  String commentReplyTo(String author) {
    return 'Respuesta a $author';
  }

  @override
  String get commentDelete => 'Eliminar comentario';

  @override
  String get commentDeleteConfirm =>
      '¿Estás seguro de que quieres eliminar este comentario?';

  @override
  String get commentDeleteSuccess => 'Comentario eliminado';

  @override
  String get commentDeleteError => 'Error al eliminar el comentario';

  @override
  String commentShowReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar $count respuestas',
      one: 'Mostrar 1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String get commentHideReplies => 'Ocultar respuestas';

  @override
  String get commentSuccess => '¡Comentario publicado!';

  @override
  String get commentError => 'Error al publicar el comentario';

  @override
  String get commentEmpty => 'Por favor escribe un comentario';

  @override
  String get adminDashboard => 'Panel de administración';

  @override
  String get adminNotifications => 'Notificaciones';

  @override
  String get adminModeration => 'Moderación';

  @override
  String get adminNewPhotos => 'Nuevas fotos';

  @override
  String get adminNewReviews => 'Nuevas reseñas';

  @override
  String get adminNewComments => 'Nuevos comentarios';

  @override
  String get adminFlaggedContent => 'Contenido reportado';

  @override
  String get adminDelete => 'Eliminar';

  @override
  String get adminDeleteConfirm =>
      '¿Estás seguro de que quieres eliminar este contenido?';

  @override
  String get adminDeleteSuccess => 'Contenido eliminado';

  @override
  String get adminDeleteError => 'Error al eliminar';

  @override
  String get adminApprove => 'Aprobar';

  @override
  String get adminApproveSuccess => 'Contenido aprobado';

  @override
  String get adminApproveError => 'Error al aprobar';

  @override
  String get adminMarkRead => 'Marcar como leído';

  @override
  String get adminMarkAllRead => 'Marcar todo como leído';

  @override
  String get adminNoNotifications => 'Sin nuevas notificaciones';

  @override
  String get adminNoFlagged => 'Sin contenido reportado';

  @override
  String get adminStats => 'Estadísticas';

  @override
  String adminUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sin leer',
      one: '1 sin leer',
      zero: 'Ninguno sin leer',
    );
    return '$_temp0';
  }

  @override
  String adminFlaggedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reportados',
      one: '1 reportado',
      zero: 'Ninguno reportado',
    );
    return '$_temp0';
  }

  @override
  String get adminNotificationNewPhoto => 'Nueva foto subida';

  @override
  String get adminNotificationNewReview => 'Nueva reseña';

  @override
  String get adminNotificationNewComment => 'Nuevo comentario';

  @override
  String get adminNotificationFlagged => 'Contenido reportado';

  @override
  String get socialLoginRequired =>
      'Por favor inicia sesión para usar esta función';

  @override
  String get socialRatingRequired => 'Por favor selecciona una valoración';

  @override
  String get reportContent => 'Reportar contenido';

  @override
  String get reportSuccess =>
      '¡Gracias! El contenido ha sido reportado para revisión.';

  @override
  String get reportError => 'Error al reportar el contenido';

  @override
  String get reportReason => 'Motivo del reporte';

  @override
  String get reportReasonHint =>
      'Describe por qué este contenido debería ser reportado...';

  @override
  String get anonymousUser => 'Anónimo';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get shareViaApp => 'Compartir vía app';

  @override
  String get shareViaAppDesc => 'Comparte este viaje con amigos';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get copyLinkDesc => 'Copiar enlace al portapapeles';

  @override
  String get showQrCode => 'Mostrar código QR';

  @override
  String get showQrCodeDesc => 'Escanea para abrir el viaje';

  @override
  String get linkCopied => '¡Enlace copiado!';

  @override
  String get qrCodeHint => 'Escanea este código con la app MapAB';
}
