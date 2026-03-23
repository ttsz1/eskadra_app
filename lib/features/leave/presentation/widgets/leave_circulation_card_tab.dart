import 'package:flutter/material.dart';

import '../../../../shared/widgets/ops_panel.dart';

class LeaveCirculationCardTab extends StatelessWidget {
  const LeaveCirculationCardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const OpsPanel(
      child: Center(
        child: Text('Karta obiegowa i karta urlopowa dodamy w następnym kroku.'),
      ),
    );
  }
}