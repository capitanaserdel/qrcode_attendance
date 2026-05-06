import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:platform_qr_scanner/screens/scanner_screen.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<Splash> {

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            double logoSize;

            if (screenWidth < 350) {
              logoSize = screenWidth * 0.20;
            } else if (screenWidth < 600) {
              logoSize = screenWidth * 0.15;
            } else {
              logoSize = 220;
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      child: Image.asset(
                        'assets/logo.png',
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.1),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

