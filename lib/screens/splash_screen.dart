import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1700), // Extended scan time
      vsync: this,
    );

    // Scan line moves from top to bottom
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start animation and navigate when done
    _controller.forward().then((_) => _navigateToHome());
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF003366);
    const scanColor = Color(0xFF00FFC8);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with scan effect
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  // Simulated card icon (white rounded rect)
                  Center(
                    child: Container(
                      width: 100,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 8,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 5,
                              width: 35,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 5,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Scanning beam
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * 130,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: scanColor,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: scanColor.withOpacity(0.8),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Corner brackets (scan frame)
                  ..._buildCornerBrackets(scanColor),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "B-CARD SCANNER",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerBrackets(Color color) {
    const len = 20.0;
    const thick = 3.0;

    return [
      // Top Left
      Positioned(
        left: 0,
        top: 0,
        child: Container(width: len, height: thick, color: color),
      ),
      Positioned(
        left: 0,
        top: 0,
        child: Container(width: thick, height: len, color: color),
      ),
      // Top Right
      Positioned(
        right: 0,
        top: 0,
        child: Container(width: len, height: thick, color: color),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: Container(width: thick, height: len, color: color),
      ),
      // Bottom Left
      Positioned(
        left: 0,
        bottom: 0,
        child: Container(width: len, height: thick, color: color),
      ),
      Positioned(
        left: 0,
        bottom: 0,
        child: Container(width: thick, height: len, color: color),
      ),
      // Bottom Right
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(width: len, height: thick, color: color),
      ),
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(width: thick, height: len, color: color),
      ),
    ];
  }
}
