import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _controller;
  bool _isProcessing = false;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
    );
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller.stop();
        break;
      default:
        break;
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
    } else {
      final result = await Permission.camera.request();
      setState(() => _hasPermission = result.isGranted);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    debugPrint('[SCANNER] Detected: $rawValue');
    
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 100);
    }

    final String targetUrl = "https://attendance.ratelplus.net.ng/checkin?token=$rawValue";
    final Uri uri = Uri.parse(targetUrl);

    try {
      debugPrint('[SCANNER] Attempting to launch: $targetUrl');
      // On some Android devices, canLaunchUrl returns false but launchUrl works.
      // We'll attempt launch regardless but log the result.
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (!launched) {
        _handleError('Could not open browser');
      } else {
        // Successful launch, wait before allowing another scan
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[SCANNER] Launch error: $e');
      _handleError('Error: $e');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isProcessing = false;
    });
    
    // Clear error after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_hasPermission)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.blue)),

          // Top Bar with Logo and Torch
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 34,
                  fit: BoxFit.contain,
                ),
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, state, child) {
                        return Icon(
                          state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                          color: state.torchState == TorchState.on ? Colors.yellow : Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Status Indicators (Processing / Error)
          if (_isProcessing || _errorMessage != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _errorMessage != null ? Colors.red.withValues(alpha: 0.9) : Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _errorMessage != null ? Colors.white24 : Colors.blue.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing && _errorMessage == null)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        ),
                      Text(
                        _errorMessage ?? 'Processing Scan...',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Simple Scanning Bracket (Overlay)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _errorMessage != null ? Colors.red : Colors.blue, 
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
