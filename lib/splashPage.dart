import 'package:flutter/material.dart';
import 'main.dart'; 

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1, milliseconds: 500), // Slightly longer for drama
    vsync: this,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller, 
    curve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();

    _controller.forward().then((_) {
      // Small pause so the user can read the text before it vanishes
      Future.delayed(const Duration(milliseconds: 500), () {
        _controller.reverse().then((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MyHomePage(title: 'Moody Music'),
              ),
            );
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We don't set backgroundColor here because the Container handles it
      body: Container(
        decoration: const BoxDecoration(
          // IMPROVEMENT: A gradient looks much better than a flat solid color
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C4DFF), // Deep Purple Accent
              Color(0xFFB388FF), // Lighter Purple
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: const Text(
              'Moody Music',
              style: TextStyle(
                fontSize: 40, // Bigger and bolder
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0, // Adds space between letters for a modern look
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4.0,
                    color: Colors.black26, // Subtle text shadow for readability
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
