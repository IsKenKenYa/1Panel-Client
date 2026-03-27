class BackupRecordsArgs {
  const BackupRecordsArgs({
    this.cronjobId,
    this.cronjobName,
    this.type,
    this.name,
    this.detailName,
  });

  final int? cronjobId;
  final String? cronjobName;
  final String? type;
  final String? name;
  final String? detailName;
}
