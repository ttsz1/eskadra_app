import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../widgets/leave_balance_overview_tab.dart';
import '../widgets/leave_circulation_card_tab.dart';
import '../widgets/leave_plan_tab.dart';
import '../widgets/leave_planned_tab.dart';
import '../widgets/leave_used_tab.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  static const String routePath = '/leave';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urlopy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'wykorzystany'),
                  Tab(text: 'planowany'),
                  Tab(text: 'Zaplanuj urlop'),
                  Tab(text: 'Sprawdź ile kto ma urlopu'),
                  Tab(text: 'Karta obiegowa'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Expanded(
                child: TabBarView(
                  children: [
                    LeaveUsedTab(),
                    LeavePlannedTab(),
                    LeavePlanTab(),
                    LeaveBalanceOverviewTab(),
                    LeaveCirculationCardTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}