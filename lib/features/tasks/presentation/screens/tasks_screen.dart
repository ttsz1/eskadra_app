import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/layout/ops_topbar.dart';
import '../widgets/task_create_dialog.dart';
import '../widgets/task_detail_panel.dart';
import '../widgets/task_list_panel.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const String routePath = '/tasks';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OpsTopbar(
            title: 'Task control',
            subtitle: 'Zarządzanie zadaniami',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 1100;

                  if (isCompact) {
                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: () => showTaskCreateDialog(context),
                            icon: const Icon(Icons.add_task),
                            label: const Text('Utwórz zadanie'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                flex: 4,
                                child: TaskListPanel(),
                              ),
                              SizedBox(height: AppSpacing.md),
                              Expanded(
                                flex: 5,
                                child: TaskDetailPanel(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () => showTaskCreateDialog(context),
                          icon: const Icon(Icons.add_task),
                          label: const Text('Utwórz zadanie'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: TaskListPanel(),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 6,
                              child: TaskDetailPanel(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}