import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../random_trip/providers/random_trip_state.dart';

part 'app_ui_mode_provider.g.dart';

/// Planungs-Modus (AI Tagestrip oder AI Euro Trip)
enum MapPlanMode { aiTagestrip, aiEuroTrip }

/// Provider für den globalen UI-Modus (AI Tagestrip / AI Euro Trip)
/// Wird von TripModeSelector geschrieben und von MapScreen gelesen
@riverpod
class AppUIModeNotifier extends _$AppUIModeNotifier {
  @override
  MapPlanMode build() => MapPlanMode.aiTagestrip;

  void setMode(MapPlanMode mode) {
    state = mode;
  }

  /// Konvertiert MapPlanMode zu RandomTripMode
  RandomTripMode get randomTripMode {
    return state == MapPlanMode.aiTagestrip
        ? RandomTripMode.daytrip
        : RandomTripMode.eurotrip;
  }
}
