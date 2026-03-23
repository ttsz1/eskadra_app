import 'package:flutter/material.dart';

import '../widgets/my_calendar_month_panel.dart';

class MyCalendarScreen extends StatelessWidget {
  const MyCalendarScreen({super.key});

  static const String routePath = '/my-calendar';
  static const String routeName = 'my-calendar';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: MyCalendarMonthPanel(),
      ),
    );
  }
}