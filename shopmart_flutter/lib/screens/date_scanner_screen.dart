import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class DateScannerScreen extends StatefulWidget {
  const DateScannerScreen({super.key});

  @override
  State<DateScannerScreen> createState() => _DateScannerScreenState();
}

class _DateScannerScreenState extends State<DateScannerScreen> {
  CameraController? _cameraController;
  final textRecognizer = TextRecognizer();
  bool _isProcessing = false;
  String _detectedText = '';
  DateTime? _detectedDate;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startScanning();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startScanning() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _isProcessing) {
        timer.cancel();
        return;
      }
      await _processImage();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    textRecognizer.close();
    super.dispose();
  }

  // Pattern per riconoscere date in vari formati
  final List<RegExp> _datePatterns = [
    // DD/MM/YYYY o DD-MM-YYYY o DD.MM.YYYY
    RegExp(r'(\d{2})[\s/\-\.](\d{2})[\s/\-\.](\d{4})'),
    // DD/MM/YY o DD-MM-YY o DD.MM.YY
    RegExp(r'(\d{2})[\s/\-\.](\d{2})[\s/\-\.](\d{2})(?!\d)'),
    // DDMMYYYY
    RegExp(r'(?<!\d)(\d{2})(\d{2})(\d{4})(?!\d)'),
    // DDMMYY
    RegExp(r'(?<!\d)(\d{2})(\d{2})(\d{2})(?!\d)'),
    // Formato testo: DD MMM YYYY (es: 25 DIC 2024)
    RegExp(
        r'(\d{2})\s*(GEN|FEB|MAR|APR|MAG|GIU|LUG|AGO|SET|OTT|NOV|DIC)[A-Z]*\.?\s*(\d{2,4})',
        caseSensitive: false),
  ];

  final Map<String, int> _monthMap = {
    'GEN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAG': 5,
    'GIU': 6,
    'LUG': 7,
    'AGO': 8,
    'SET': 9,
    'OTT': 10,
    'NOV': 11,
    'DIC': 12,
  };

  DateTime? _parseDate(String text) {
    // Prova con formato testuale (es: 25 DIC 2024)
    final textMatch = _datePatterns[4].firstMatch(text.toUpperCase());
    if (textMatch != null) {
      try {
        final day = int.parse(textMatch.group(1)!);
        final monthStr = textMatch.group(2)!.substring(0, 3);
        final month = _monthMap[monthStr];
        var year = int.parse(textMatch.group(3)!);

        if (year < 100) {
          year += (year < 50) ? 2000 : 1900;
        }

        if (month != null && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      } catch (e) {
        // Ignora errori di parsing
      }
    }

    // Prova con formati numerici
    for (int i = 0; i < 4; i++) {
      final match = _datePatterns[i].firstMatch(text);
      if (match != null) {
        try {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          var year = int.parse(match.group(3)!);

          if (year < 100) {
            year += (year < 50) ? 2000 : 1900;
          }

          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            final date = DateTime(year, month, day);
            final now = DateTime.now();
            final oneYearAgo = now.subtract(const Duration(days: 365));
            if (date.isAfter(oneYearAgo)) {
              return date;
            }
          }
        } catch (e) {
          // Ignora errori di parsing
        }
      }
    }

    return null;
  }

  Future<void> _processImage() async {
    if (_isProcessing || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      DateTime? foundDate;
      String allText = recognizedText.text;

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final lineText = line.text;
          final date = _parseDate(lineText);
          if (date != null) {
            foundDate = date;
            break;
          }
        }
        if (foundDate != null) break;
      }

      foundDate ??= _parseDate(allText);

      setState(() {
        _detectedText = allText;
        _detectedDate = foundDate;
        _isProcessing = false;
      });

      if (foundDate != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(foundDate);
        }
      } else {
        // Riprova dopo un secondo
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _detectedText = 'Errore: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scansiona Data di Scadenza'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_cameraController != null)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () {
                final current = _cameraController!.value.flashMode;
                _cameraController!.setFlashMode(
                  current == FlashMode.off ? FlashMode.torch : FlashMode.off,
                );
              },
              tooltip: 'Flash',
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Camera preview
                SizedBox.expand(
                  child: CameraPreview(_cameraController!),
                ),

                // Overlay
                CustomPaint(
                  painter: DateScannerOverlay(),
                  child: Container(),
                ),

                // Istruzioni
                Positioned(
                  top: 50,
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
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isProcessing
                                  ? 'Riconoscimento in corso...'
                                  : 'Inquadra la data di scadenza stampata sul prodotto',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Formati supportati:\nDD/MM/YYYY, DD-MM-YYYY\n25 DIC 2024',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Feedback riconoscimento
                if (_detectedText.isNotEmpty)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        color: _detectedDate != null
                            ? Colors.green.withOpacity(0.9)
                            : Colors.orange.withOpacity(0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _detectedDate != null
                                    ? 'Data trovata!'
                                    : 'Testo rilevato:',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _detectedDate != null
                                    ? '${_detectedDate!.day.toString().padLeft(2, '0')}/${_detectedDate!.month.toString().padLeft(2, '0')}/${_detectedDate!.year}'
                                    : _detectedText.length > 50
                                        ? '${_detectedText.substring(0, 50)}...'
                                        : _detectedText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Pulsante scansione manuale
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _processImage,
                        icon: const Icon(Icons.camera),
                        label: const Text('Scatta foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(null),
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Manuale'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// Painter per l'overlay
class DateScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutWidth = size.width * 0.9;
    final cutoutHeight = size.height * 0.15;
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

    // Bordo area di scansione
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

    // Angoli
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
