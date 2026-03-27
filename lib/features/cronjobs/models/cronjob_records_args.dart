class CronjobRecordsArgs {
  const CronjobRecordsArgs({
    required this.cronjobId,
    required this.name,
    required this.status,
  });

  final int cronjobId;
  final String name;
  final String status;
}
