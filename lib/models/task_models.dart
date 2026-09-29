/// Priority level for a farm task.
enum TaskPriority { high, medium, low }

/// Current status of a farm task.
enum TaskStatus { pending, completed, overdue }

/// Represents a farm task with scheduling and priority info.
class FarmTask {
  final String titleKey;
  final String descriptionKey;
  final String dueDateKey;
  final String duration;
  final String tagKey;
  final TaskPriority priority;
  final TaskStatus status;

  const FarmTask({
    required this.titleKey,
    required this.descriptionKey,
    required this.dueDateKey,
    required this.duration,
    required this.tagKey,
    required this.priority,
    this.status = TaskStatus.pending,
  });

  bool get isUrgent => priority == TaskPriority.high;
}
