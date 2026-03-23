import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class EskadraIntroScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const EskadraIntroScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<EskadraIntroScreen> createState() => _EskadraIntroScreenState();
}

class _EskadraIntroScreenState extends State<EskadraIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _glitchController;

  String _displayText = 'ESKADRA';
  bool _expanded = false;

  final _random = Random();

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // glitch start
    _glitchController.repeat();

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _expanded = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() {
      _displayText = 'ELEKTRONICZNY SYSTEM KADR';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    _glitchController.stop();

    await Future.delayed(const Duration(milliseconds: 400));

    widget.onFinished();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // scanlines
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanlinePainter(),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _glitchController,
              builder: (context, _) {
                final glitchOffset =
                    (_glitchController.value * 4) * (_random.nextBool() ? 1 : -1);

                return Transform.translate(
                  offset: Offset(glitchOffset, 0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    style: TextStyle(
                      fontSize: _expanded ? 28 : 42,
                      fontWeight: FontWeight.w700,
                      letterSpacing: _expanded ? 4 : 10,
                      color: baseColor,
                    ),
                    child: Text(
                      _displayText,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),

          // glow
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _expanded ? 0.4 : 0.2,
              child: Text(
                _displayText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _expanded ? 30 : 46,
                  fontWeight: FontWeight.bold,
                  color: baseColor.withOpacity(0.2),
                  letterSpacing: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}