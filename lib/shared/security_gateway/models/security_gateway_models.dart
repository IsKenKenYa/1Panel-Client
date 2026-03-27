import 'package:equatable/equatable.dart';

enum RiskLevel {
  low,
  medium,
  high,
}

enum CertificateHealthStatus {
  healthy,
  expiringSoon,
  expired,
  unknown,
}

class RiskNotice extends Equatable {
  const RiskNotice({
    required this.level,
    required this.title,
    required this.message,
  });

  final RiskLevel level;
  final String title;
  final String message;

  @override
  List<Object?> get props => [level, title, message];
}

class ConfigDiffItem extends Equatable {
  const ConfigDiffItem({
    required this.field,
    required this.label,
    required this.currentValue,
    required this.nextValue,
  });

  final String field;
  final String label;
  final String currentValue;
  final String nextValue;

  @override
  List<Object?> get props => [field, label, currentValue, nextValue];
}

class ConfigDraftState<T> extends Equatable {
  const ConfigDraftState({
    required this.currentValue,
    required this.draftValue,
    this.diffItems = const <ConfigDiffItem>[],
    this.risks = const <RiskNotice>[],
  });

  final T currentValue;
  final T draftValue;
  final List<ConfigDiffItem> diffItems;
  final List<RiskNotice> risks;

  bool get hasChanges => diffItems.isNotEmpty;

  @override
  List<Object?> get props => [currentValue, draftValue, diffItems, risks];
}

class ConfigRollbackSnapshot<T> extends Equatable {
  const ConfigRollbackSnapshot({
    required this.scope,
    required this.title,
    required this.summary,
    required this.data,
    required this.createdAt,
  });

  final String scope;
  final String title;
  final String summary;
  final T data;
  final DateTime createdAt;

  @override
  List<Object?> get props => [scope, title, summary, data, createdAt];
}
