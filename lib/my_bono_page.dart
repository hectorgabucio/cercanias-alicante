import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyBonoPage extends StatefulWidget {
  const MyBonoPage({super.key});

  @override
  State<MyBonoPage> createState() => _MyBonoPageState();
}

class _MyBonoPageState extends State<MyBonoPage> {
  String? qrData;
  bool loading = false;
  String? error;
  bool showSuccess = false;
  bool _cameraMode = false;
  MobileScannerController? _scannerController;

  // Helper: parse and validate QR
  Map<String, dynamic>? parseBonoQR(String? data) {
    if (data == null) return null;
    final regex = RegExp(r'^(\w+)(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+)([a-fA-F0-9]+)$');
    final match = regex.firstMatch(data);
    if (match == null) return null;
    final code = match.group(1)!;
    final dateStr = match.group(2)!;
    final hash = match.group(3)!;
    DateTime? generatedAt;
    try {
      generatedAt = DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
    final parsed = {'code': code, 'generatedAt': generatedAt, 'hash': hash};
    print('[parseBonoQR] Parsed QR: code=$code, generatedAt=$generatedAt, hash=$hash');
    return parsed;
  }

  @override
  void initState() {
    super.initState();
    _loadQR();
  }

  Future<void> _loadQR() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      qrData = prefs.getString('my_bono_qr');
    });
  }

  Future<void> _saveQR(String data) async {
    // Log the content of the scanned QR
    print('[MyBono] Scanned QR content: $data');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_bono_qr', data);
    setState(() {
      qrData = data;
      showSuccess = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      showSuccess = false;
    });
  }

  void _scanQR() async {
    setState(() {
      _cameraMode = true;
      error = null;
    });
    _scannerController = MobileScannerController();
  }

  void _onCameraDetect(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final qr = barcodes.first.rawValue!;
      await _saveQR(qr);
      setState(() {
        _cameraMode = false;
      });
      _scannerController?.stop();
    }
  }

  void _pickImageAndScan() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() { loading = true; error = null; });
      try {
        print('[MyBono] Picked image: ${picked.path}');
        final file = File(picked.path);
        final bytes = await file.readAsBytes();
        print('[MyBono] Image bytes length: ${bytes.length}');
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          final imageData = decodedImage.data;
          if (imageData == null) {
            setState(() { error = 'Could not decode image data.'; loading = false; });
            print('[MyBono] Error: imageData is null');
            return;
          }
          final rgbBytes = imageData.buffer.asUint8List();
          final int pixelCount = decodedImage.width * decodedImage.height;
          Int32List rgbaPixels;
          if (imageData.buffer.asInt32List().length == pixelCount) {
            // Already RGBA/ARGB
            rgbaPixels = imageData.buffer.asInt32List();
          } else if (rgbBytes.length == pixelCount * 3) {
            // Convert from RGB to RGBA (alpha=0xFF)
            rgbaPixels = Int32List(pixelCount);
            for (int i = 0, j = 0; i < pixelCount; i++, j += 3) {
              final r = rgbBytes[j];
              final g = rgbBytes[j + 1];
              final b = rgbBytes[j + 2];
              rgbaPixels[i] = (0xFF << 24) | (r << 16) | (g << 8) | b;
            }
          } else {
            setState(() { error = 'Unsupported image format for QR scan.'; loading = false; });
            print('[MyBono] Unsupported image format: rgbBytes.length=${rgbBytes.length}, pixelCount=${pixelCount}');
            return;
          }
          print('[MyBono] Final pixel buffer length: ${rgbaPixels.length} (should be width*height=${pixelCount})');
          final luminanceSource = RGBLuminanceSource(
            decodedImage.width,
            decodedImage.height,
            rgbaPixels,
          );
          final bitmap = BinaryBitmap(HybridBinarizer(luminanceSource));
          final reader = QRCodeReader();
          final result = reader.decode(bitmap);
          print('[MyBono] QR decode result: ${result.text}');
          if (result.text.isNotEmpty) {
            await _saveQR(result.text);
          } else {
            setState(() { error = 'No QR code found in image.'; });
            print('[MyBono] No QR code found in image.');
          }
        } else {
          setState(() { error = 'Could not decode image.'; });
          print('[MyBono] Could not decode image bytes to image.');
        }
      } catch (e, stack) {
        setState(() { error = 'Error scanning image: ${e.toString()}'; });
        print('[MyBono] Error scanning image: ${e.toString()}');
        print(stack);
      }
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _cameraMode
            ? Scaffold(
                appBar: AppBar(
                  title: const Text('Scan QR'),
                  backgroundColor: Colors.white,
                  elevation: 1,
                  iconTheme: const IconThemeData(color: Colors.black),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _cameraMode = false;
                        _scannerController?.stop();
                      });
                    },
                  ),
                ),
                body: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onCameraDetect,
                ),
              )
            : Scaffold(
                appBar: AppBar(title: const Text('My bono'), backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black)),
                body: Center(
                  child: loading
                      ? const CircularProgressIndicator()
                      : qrData != null
                          ? Builder(
                              builder: (context) {
                                final parsed = parseBonoQR(qrData);
                                if (parsed == null) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 32),
                                      QrImageView(
                                        data: qrData!,
                                        version: QrVersions.auto,
                                        size: 240.0,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('This is not a valid bono', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Delete QR'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade100, foregroundColor: Colors.red.shade700),
                                        onPressed: () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.remove('my_bono_qr');
                                          setState(() { qrData = null; });
                                        },
                                      ),
                                    ],
                                  );
                                } else {
                                  final code = parsed['code'] as String;
                                  final generatedAt = parsed['generatedAt'] as DateTime;
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 32),
                                      QrImageView(
                                        data: qrData!,
                                        version: QrVersions.auto,
                                        size: 240.0,
                                      ),
                                      const SizedBox(height: 16),
                                      Text('Code: $code', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text('Generated at: '
                                        '${generatedAt.toLocal()}'.split('.')[0],
                                        style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Delete QR'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade100, foregroundColor: Colors.red.shade700),
                                        onPressed: () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.remove('my_bono_qr');
                                          setState(() { qrData = null; });
                                        },
                                      ),
                                    ],
                                  );
                                }
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 32),
                                Center(
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/qr_placeholder.svg',
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No bono QR added yet',
                                  style: TextStyle(fontSize: 18, color: Colors.black38, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scan QR'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4EC7B3)),
                                  onPressed: _scanQR,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.image),
                                  label: const Text('Upload Image'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade700),
                                  onPressed: _pickImageAndScan,
                                ),
                              ],
                            ),
                  ),
                ),
            if (showSuccess)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Lottie.asset(
                      'assets/qr_success.json',
                      width: 220,
                      repeat: false,
                      package: null,
                      delegates: LottieDelegates(
                        values: [
                          // fallback for .lottie files (dotLottie) if needed
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _QRScannerPage extends StatelessWidget {
  const _QRScannerPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR'), backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Colors.black)),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            Navigator.of(context).pop(barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}
