import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/l10n/l10n.dart';
import '../../data/services/sharing_service.dart';
import '../../data/models/trip.dart';
import '../trip/providers/trip_state_provider.dart';
import '../../data/repositories/routing_repo.dart';
import '../../shared/widgets/app_snackbar.dart';

/// QR-Code Scanner zum Importieren von geteilten Trips
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.scanTitle),
        actions: [
          // Taschenlampe umschalten
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          // Kamera wechseln
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Kamera-Vorschau
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scanner-Overlay
          _buildScannerOverlay(colorScheme),

          // Anleitung unten
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.scanInstruction,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.scanDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Loading-Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.scanLoading,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(ColorScheme colorScheme) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(
        borderColor: colorScheme.primary,
        borderWidth: 3,
        overlayColor: Colors.black.withValues(alpha: 0.5),
        borderRadius: 16,
        scanAreaSize: 280,
      ),
      child: const SizedBox.expand(),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    // Nur verarbeiten wenn nicht bereits am Laden
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Duplikate vermeiden
    if (code == _lastScannedCode) return;
    _lastScannedCode = code;

    debugPrint(
        '[QRScanner] Code erkannt: ${code.substring(0, code.length.clamp(0, 50))}...');

    // Pruefen ob es ein MapAB-Link ist
    if (code.startsWith('mapab://trip?data=')) {
      _handleMapABLink(code);
    } else if (code.startsWith('https://mapab.app/gallery/')) {
      _handleMapABLink(code);
    } else if (code.startsWith('https://mapab.app/trip/')) {
      _handleMapABLink(code);
    } else {
      // Versuchen als direktes Base64-kodiertes Trip-Data zu parsen
      _tryParseDirectData(code);
    }
  }

  Future<void> _handleMapABLink(String link) async {
    setState(() => _isProcessing = true);

    try {
      final publicTripId = extractPublicTripIdFromLink(link);
      if (publicTripId != null) {
        _openPublicTrip(publicTripId);
        return;
      }

      // Data aus URL extrahieren
      String? encodedData;
      if (link.startsWith('mapab://trip?data=')) {
        encodedData = link.replaceFirst('mapab://trip?data=', '');
      } else if (link.startsWith('https://mapab.app/trip/')) {
        encodedData = link.replaceFirst('https://mapab.app/trip/', '');
      }

      if (encodedData == null || encodedData.isEmpty) {
        _showError(context.l10n.scanInvalidCode);
        return;
      }

      await _importTrip(encodedData);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _tryParseDirectData(String data) async {
    setState(() => _isProcessing = true);

    try {
      await _importTrip(data);
    } catch (e) {
      if (!mounted) return;
      _showError(context.l10n.scanInvalidMapabCode);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _importTrip(String encodedData) async {
    final sharingService = ref.read(sharingServiceProvider);
    final trip = sharingService.decodeTrip(encodedData);

    if (trip == null) {
      _showError(context.l10n.scanLoadError);
      return;
    }

    // Erfolgs-Dialog anzeigen
    if (!mounted) return;
    final shouldImport = await _showImportDialog(trip);

    if (shouldImport != true) {
      _lastScannedCode = null; // Reset fuer neuen Scan
      return;
    }

    // Trip importieren
    await _loadTrip(trip);
  }

  void _openPublicTrip(String tripId) {
    if (!mounted) return;
    context.go('/gallery/$tripId');
  }

  Future<bool?> _showImportDialog(Trip trip) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(context.l10n.scanTripFound)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 16),
                const SizedBox(width: 4),
                Text(context.l10n.scanStops(trip.stops.length)),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(context.l10n.scanDays(trip.days)),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.l10n.scanImportQuestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.download),
            label: Text(context.l10n.scanImport),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTrip(Trip trip) async {
    try {
      // Route neu berechnen falls Koordinaten fehlen
      final routeEmpty = trip.route.coordinates.isEmpty;

      if (routeEmpty) {
        final routingRepo = ref.read(routingRepositoryProvider);

        if (trip.stops.length >= 2) {
          // Waypoints als LatLng-Liste erstellen
          final stopCoords =
              trip.stops.map((s) => LatLng(s.latitude, s.longitude)).toList();

          final start = stopCoords.first;
          final end = stopCoords.last;
          final waypoints = stopCoords.length > 2
              ? stopCoords.sublist(1, stopCoords.length - 1)
              : <LatLng>[];

          final route = await routingRepo.calculateFastRoute(
            start: start,
            end: end,
            waypoints: waypoints,
            startAddress: trip.stops.first.name,
            endAddress: trip.stops.last.name,
          );

          // Trip mit neuer Route aktualisieren
          ref.read(tripStateProvider.notifier).setRouteAndStops(
                route,
                trip.stops.map((s) => s.toPOI()).toList(),
              );
        }
      } else {
        // Trip direkt laden
        ref.read(tripStateProvider.notifier).setRouteAndStops(
              trip.route,
              trip.stops.map((s) => s.toPOI()).toList(),
            );
      }

      if (!mounted) return;

      AppSnackbar.showSuccess(
          context, context.l10n.scanImportSuccess(trip.name));

      // Zur Karte navigieren
      context.go('/');
    } catch (e) {
      debugPrint('[QRScanner] Import-Fehler: $e');
      _showError(context.l10n.scanImportError);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AppSnackbar.showError(context, message);
    _lastScannedCode = null;
  }
}

/// Custom Painter fuer das Scanner-Overlay mit Scan-Bereich
class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double scanAreaSize;

  _ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
    required this.borderRadius,
    required this.scanAreaSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 60);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Dunkles Overlay ausserhalb des Scan-Bereichs
    final overlayPaint = Paint()..color = overlayColor;
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Eckmarkierungen
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Oben links
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top + cornerLength),
      Offset(scanRect.left, scanRect.top + borderRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left + cornerLength, scanRect.top),
      Offset(scanRect.left + borderRadius, scanRect.top),
      cornerPaint,
    );

    // Oben rechts
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top + cornerLength),
      Offset(scanRect.right, scanRect.top + borderRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.top),
      Offset(scanRect.right - borderRadius, scanRect.top),
      cornerPaint,
    );

    // Unten links
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom - cornerLength),
      Offset(scanRect.left, scanRect.bottom - borderRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left + cornerLength, scanRect.bottom),
      Offset(scanRect.left + borderRadius, scanRect.bottom),
      cornerPaint,
    );

    // Unten rechts
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom - cornerLength),
      Offset(scanRect.right, scanRect.bottom - borderRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.bottom),
      Offset(scanRect.right - borderRadius, scanRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
