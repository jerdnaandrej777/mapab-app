import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../map_screen.dart';
import '../../random_trip/providers/random_trip_state.dart';

part 'app_ui_mode_provider.g.dart';

/// Provider für den globalen UI-Modus (AI Tagestrip / AI Euro Trip)
/// Wird von TripModeSelector geschrieben und von MapScreen gelesen
@Riverpod(keepAlive: true)
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
