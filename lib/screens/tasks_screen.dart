import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/task_models.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_tag.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedSegment = 0;

  // Demo task data — will be replaced by local DB storage
  static const _urgentTasks = [
    FarmTask(
      titleKey: 'checkIrrigation',
      descriptionKey: 'wheat',
      dueDateKey: 'dueToday',
      duration: '30 min',
      tagKey: 'irrigation',
      priority: TaskPriority.high,
    ),
    FarmTask(
      titleKey: 'harvestWheat',
      descriptionKey: 'wheat',
      dueDateKey: 'dueToday',
      duration: '2 hours',
      tagKey: 'crops',
      priority: TaskPriority.high,
    ),
  ];

  static const _upcomingTasks = [
    FarmTask(
      titleKey: 'applyFertilizer',
      descriptionKey: 'tomato',
      dueDateKey: 'dueTomorrow',
      duration: '45 min',
      tagKey: 'cropCare',
      priority: TaskPriority.medium,
    ),
    FarmTask(
      titleKey: 'soilTesting',
      descriptionKey: 'soilHealth',
      dueDateKey: 'dueTomorrow',
      duration: '1 hour',
      tagKey: 'soilHealth',
      priority: TaskPriority.low,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(l10n),
          const SizedBox(height: 20),

          // Task Stats
          _buildTaskStats(l10n),
          const SizedBox(height: 20),

          // Segmented Control
          _buildSegmentedControl(l10n),
          const SizedBox(height: 20),

          // Urgent Tasks Section
          _buildUrgentTasksSection(l10n),
          const SizedBox(height: 20),

          // All Tasks Section
          _buildAllTasksSection(l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tasks,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.todaysTasks,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => showComingSoon(context),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: Text(l10n.addTask),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskStats(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.weatherTagBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              children: [
                const Text(
                  '2',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.high,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 12,
            child: Column(
              children: [
                const Text(
                  '3',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.pending,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 12,
            child: Column(
              children: [
                const Text(
                  '1',
                  style: TextStyle(
                    color: AppColors.gainText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.completed,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7E1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildSegmentTab(l10n.todaysTasks, 0),
          _buildSegmentTab(l10n.upcomingTasks, 1),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String label, int index) {
    final isActive = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentTasksSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: LucideIcons.alertTriangle,
          title: '${l10n.priority}: ${l10n.high}',
          color: AppColors.urgentText,
          fontSize: 16,
        ),
        const SizedBox(height: 12),
        ..._urgentTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTaskCard(task, l10n),
            )),
      ],
    );
  }

  Widget _buildAllTasksSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.upcomingTasks,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ..._upcomingTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTaskCard(task, l10n),
            )),
      ],
    );
  }

  Widget _buildTaskCard(FarmTask task, AppLocalizations l10n) {
    final title = l10n.translate(task.titleKey);
    final description = l10n.translate(task.descriptionKey);
    final dueDate = l10n.translate(task.dueDateKey);
    final tag = l10n.translate(task.tagKey);
    final priority = _priorityLabel(task.priority, l10n);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: task.isUrgent ? AppColors.urgentBg : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              task.isUrgent ? const Color(0xFFFECACA) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator dot instead of misleading checkbox
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: task.isUrgent
                  ? AppColors.urgentTagText
                  : AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    StatusTag(
                      label: priority,
                      backgroundColor: task.isUrgent
                          ? AppColors.urgentTagBg
                          : AppColors.mediumTagBg,
                      textColor: task.isUrgent
                          ? AppColors.urgentTagText
                          : AppColors.mediumTagText,
                      fontSize: 11,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          dueDate,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.duration,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _priorityLabel(TaskPriority priority, AppLocalizations l10n) {
    switch (priority) {
      case TaskPriority.high:
        return l10n.high;
      case TaskPriority.medium:
        return l10n.medium;
      case TaskPriority.low:
        return l10n.low;
    }
  }
}
