import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/features/navigation/services/navigation_background_service_ios.dart';

const MethodChannel _methodChannel =
    MethodChannel('mapab/navigation_background');
const MethodChannel _eventMethodChannel =
    MethodChannel('mapab/navigation_background/events');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool listenedToEventChannel;

  setUp(() {
    listenedToEventChannel = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_methodChannel, (MethodCall call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'start':
          return true;
        case 'stop':
          return true;
        case 'update':
          return true;
        case 'isRunning':
          return true;
        case 'requestAlwaysPermission':
          return true;
        default:
          return null;
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_eventMethodChannel, (MethodCall call) async {
      if (call.method == 'listen') {
        listenedToEventChannel = true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_methodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_eventMethodChannel, null);
  });

  test('start and isRunning use iOS method channel', () async {
    final service = IOSNavigationBackgroundService.instance;

    final started = await service.start(
      destinationName: 'Munich',
      distanceKm: 12.3,
      etaMinutes: 20,
    );
    final running = await service.isRunning();

    expect(started, isTrue);
    expect(running, isTrue);
  });

  test('registering callback subscribes to iOS event channel', () async {
    final service = IOSNavigationBackgroundService.instance;

    void callback(Object data) {
      // no-op
    }

    service.setDataCallback(callback);
    await service.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    service.removeDataCallback(callback);

    expect(listenedToEventChannel, isTrue);
  });

  test('permission bridge delegates to method channel', () async {
    final granted =
        await IOSNavigationPermissionBridge.requestAlwaysPermission();
    expect(granted, isTrue);
  });
}
