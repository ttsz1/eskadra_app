import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EskadraIntroScreen extends StatefulWidget {
  const EskadraIntroScreen({super.key});

  static const routePath = '/intro';

  @override
  State<EskadraIntroScreen> createState() => _EskadraIntroScreenState();
}

class _EskadraIntroScreenState extends State<EskadraIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glitchController;

  final _random = Random();

  String _displayText = 'ESKADRA';
  bool _expanded = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    _glitchController.repeat();

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _expanded = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      _displayText = 'ELEKTRONICZNY SYSTEM KADR';
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    _glitchController.stop();

    setState(() {
      _finished = true;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanlinePainter(),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _glitchController,
              builder: (context, _) {
                final offset =
                    (_glitchController.value * 3.5) * (_random.nextBool() ? 1 : -1);

                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      color: primary,
                      fontSize: _expanded ? 26 : 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: _expanded ? 4.5 : 11,
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
          Center(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 700),
                opacity: _finished ? 0.0 : (_expanded ? 0.24 : 0.14),
                child: Text(
                  _displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primary.withOpacity(0.22),
                    fontSize: _expanded ? 30 : 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: _expanded ? 6 : 13,
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