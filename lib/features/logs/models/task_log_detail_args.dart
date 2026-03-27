class TaskLogDetailArgs {
  const TaskLogDetailArgs({
    required this.taskId,
    required this.taskName,
    required this.taskType,
    required this.status,
    this.currentStep,
    this.logFile,
    this.createdAt,
    this.resourceId,
    this.taskOperate,
  });

  final String taskId;
  final String taskName;
  final String taskType;
  final String status;
  final String? currentStep;
  final String? logFile;
  final String? createdAt;
  final int? resourceId;
  final String? taskOperate;
}
