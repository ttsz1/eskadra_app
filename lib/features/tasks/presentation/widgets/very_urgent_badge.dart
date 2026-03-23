import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';

class VeryUrgentBadge extends StatefulWidget {
  final String label;

  const VeryUrgentBadge({
    super.key,
    this.label = 'Bardzo pilny',
  });

  @override
  State<VeryUrgentBadge> createState() => _VeryUrgentBadgeState();
}

class _VeryUrgentBadgeState extends State<VeryUrgentBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 1, end: 0.35).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkError.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.darkError,
            width: 1,
          ),
        ),
        child: Text(
          widget.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.darkError,
          ),
        ),
      ),
    );
  }
}