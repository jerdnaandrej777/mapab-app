// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_trip_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeTripNotifierHash() =>
    r'41775832bc68c8e15ea03b223cce78b00889c400';

/// Provider für reaktiven Zugriff auf den aktiven Trip
/// keepAlive: true damit der State über Screen-Wechsel erhalten bleibt
///
/// Copied from [ActiveTripNotifier].
@ProviderFor(ActiveTripNotifier)
final activeTripNotifierProvider =
    AsyncNotifierProvider<ActiveTripNotifier, ActiveTripData?>.internal(
  ActiveTripNotifier.new,
  name: r'activeTripNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeTripNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveTripNotifier = AsyncNotifier<ActiveTripData?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
