import 'package:equatable/equatable.dart';

class HostTreeNode extends Equatable {
  const HostTreeNode({
    required this.id,
    required this.label,
    this.children = const <HostTreeChild>[],
  });

  final int id;
  final String label;
  final List<HostTreeChild> children;

  factory HostTreeNode.fromJson(Map<String, dynamic> json) {
    return HostTreeNode(
      id: json['id'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      children: (json['children'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(HostTreeChild.fromJson)
              .toList() ??
          const <HostTreeChild>[],
    );
  }

  @override
  List<Object?> get props => <Object?>[id, label, children];
}

class HostTreeChild extends Equatable {
  const HostTreeChild({
    required this.id,
    required this.label,
  });

  final int id;
  final String label;

  factory HostTreeChild.fromJson(Map<String, dynamic> json) {
    return HostTreeChild(
      id: json['id'] as int? ?? 0,
      label: json['label'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[id, label];
}
