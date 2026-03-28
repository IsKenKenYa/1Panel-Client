import 'package:equatable/equatable.dart';

/// Backup plan model
class BackupPlan extends Equatable {
  final int? id;
  final String? name;
  final String? type;
  final String? source;
  final String? target;
  final String? schedule;
  final bool? enabled;
  final String? lastBackupTime;
  final String? nextBackupTime;
  final int? retentionDays;

  const BackupPlan({
    this.id,
    this.name,
    this.type,
    this.source,
    this.target,
    this.schedule,
    this.enabled,
    this.lastBackupTime,
    this.nextBackupTime,
    this.retentionDays,
  });

  factory BackupPlan.fromJson(Map<String, dynamic> json) {
    return BackupPlan(
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      source: json['source'] as String?,
      target: json['target'] as String?,
      schedule: json['schedule'] as String?,
      enabled: json['enabled'] as bool?,
      lastBackupTime: json['lastBackupTime'] as String?,
      nextBackupTime: json['nextBackupTime'] as String?,
      retentionDays: json['retentionDays'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'source': source,
      'target': target,
      'schedule': schedule,
      'enabled': enabled,
      'lastBackupTime': lastBackupTime,
      'nextBackupTime': nextBackupTime,
      'retentionDays': retentionDays,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        source,
        target,
        schedule,
        enabled,
        lastBackupTime,
        nextBackupTime,
        retentionDays
      ];
}
