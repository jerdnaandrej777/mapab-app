import CoreLocation
import Flutter
import Foundation

final class NavigationBackgroundManager: NSObject {
  private let methodChannelName = "mapab/navigation_background"
  private let eventChannelName = "mapab/navigation_background/events"

  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var streamHandler: NavigationBackgroundStreamHandler?

  private let locationManager = CLLocationManager()
  private var alwaysPermissionRequests: [FlutterResult] = []
  private var isTracking = false

  func register(with messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger)
    streamHandler = NavigationBackgroundStreamHandler()

    eventChannel?.setStreamHandler(streamHandler)
    methodChannel?.setMethodCallHandler(handleMethodCall)

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.distanceFilter = 1
    locationManager.pausesLocationUpdatesAutomatically = false

    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = true
    }

    if #available(iOS 11.0, *) {
      locationManager.showsBackgroundLocationIndicator = true
    }
  }

  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      result(true)

    case "start":
      startTracking(result: result)

    case "stop":
      stopTracking()
      result(true)

    case "update":
      // iOS does not require notification updates for background location tracking.
      result(true)

    case "isRunning":
      result(isTracking)

    case "requestAlwaysPermission":
      requestAlwaysPermission(result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startTracking(result: @escaping FlutterResult) {
    let status = currentAuthorizationStatus()
    guard status == .authorizedAlways else {
      streamHandler?.emit([
        "type": "error",
        "message": "Background navigation requires iOS location permission set to Always."
      ])
      result(false)
      return
    }

    locationManager.startUpdatingLocation()
    isTracking = true
    result(true)
  }

  private func stopTracking() {
    locationManager.stopUpdatingLocation()
    isTracking = false
  }

  private func requestAlwaysPermission(result: @escaping FlutterResult) {
    let status = currentAuthorizationStatus()

    if status == .authorizedAlways {
      result(true)
      return
    }

    if status == .denied || status == .restricted {
      result(false)
      return
    }

    alwaysPermissionRequests.append(result)
    locationManager.requestAlwaysAuthorization()
  }

  private func currentAuthorizationStatus() -> CLAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return locationManager.authorizationStatus
    }
    return CLLocationManager.authorizationStatus()
  }

  private func completePendingAlwaysPermissionRequests(with granted: Bool) {
    let callbacks = alwaysPermissionRequests
    alwaysPermissionRequests.removeAll()
    callbacks.forEach { callback in
      callback(granted)
    }
  }
}

extension NavigationBackgroundManager: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    streamHandler?.emit([
      "type": "position",
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "heading": location.course,
      "speed": location.speed,
      "accuracy": location.horizontalAccuracy,
      "timestamp": Int(location.timestamp.timeIntervalSince1970 * 1000)
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    streamHandler?.emit([
      "type": "error",
      "message": error.localizedDescription
    ])
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = currentAuthorizationStatus()
    if status == .authorizedAlways {
      completePendingAlwaysPermissionRequests(with: true)
      return
    }

    if status == .denied || status == .restricted || status == .authorizedWhenInUse {
      completePendingAlwaysPermissionRequests(with: false)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    if #available(iOS 14.0, *) {
      return
    }

    if status == .authorizedAlways {
      completePendingAlwaysPermissionRequests(with: true)
      return
    }

    if status == .denied || status == .restricted || status == .authorizedWhenInUse {
      completePendingAlwaysPermissionRequests(with: false)
    }
  }
}

private final class NavigationBackgroundStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func emit(_ payload: [String: Any]) {
    eventSink?(payload)
  }
}
