import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // Vibrazione/feedback tattile
    // HapticFeedback.vibrate();

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final success = await provider.lookupProduct(barcode);

    if (!mounted) return;

    if (success) {
      // Prodotto trovato, torna alla schermata precedente
      Navigator.of(context).pop(true);
    } else {
      // Prodotto non trovato
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prodotto non trovato: $barcode'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      // Aspetta un secondo prima di permettere una nuova scansione
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scansiona Codice a Barre'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetected,
          ),

          // Overlay con area di scansione
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          // Istruzioni
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.black.withOpacity(0.7),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isProcessing
                            ? 'Ricerca in corso...'
                            : 'Inquadra il codice a barre del prodotto',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter per l'overlay di scansione
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutWidth = size.width * 0.8;
    final cutoutHeight = size.height * 0.3;
    final cutoutX = (size.width - cutoutWidth) / 2;
    final cutoutY = (size.height - cutoutHeight) / 2;

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cutoutX, cutoutY, cutoutWidth, cutoutHeight),
          const Radius.circular(12),
        ),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, cutoutPath),
      backgroundPaint,
    );

    // Disegna il bordo dell'area di scansione
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cutoutX, cutoutY, cutoutWidth, cutoutHeight),
        const Radius.circular(12),
      ),
      borderPaint,
    );

    // Angoli decorativi
    const cornerLength = 30.0;

    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
      Offset(cutoutX, cutoutY + cornerLength),
      Offset(cutoutX, cutoutY),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutX, cutoutY),
      Offset(cutoutX + cornerLength, cutoutY),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(cutoutX + cutoutWidth - cornerLength, cutoutY),
      Offset(cutoutX + cutoutWidth, cutoutY),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutX + cutoutWidth, cutoutY),
      Offset(cutoutX + cutoutWidth, cutoutY + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(cutoutX, cutoutY + cutoutHeight - cornerLength),
      Offset(cutoutX, cutoutY + cutoutHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutX, cutoutY + cutoutHeight),
      Offset(cutoutX + cornerLength, cutoutY + cutoutHeight),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(cutoutX + cutoutWidth - cornerLength, cutoutY + cutoutHeight),
      Offset(cutoutX + cutoutWidth, cutoutY + cutoutHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutX + cutoutWidth, cutoutY + cutoutHeight - cornerLength),
      Offset(cutoutX + cutoutWidth, cutoutY + cutoutHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
