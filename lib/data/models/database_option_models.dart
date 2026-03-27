import 'package:equatable/equatable.dart';

class DatabaseItemOption extends Equatable {
  const DatabaseItemOption({
    required this.id,
    required this.from,
    required this.database,
    required this.name,
  });

  final int id;
  final String from;
  final String database;
  final String name;

  factory DatabaseItemOption.fromJson(Map<String, dynamic> json) {
    return DatabaseItemOption(
      id: json['id'] as int? ?? 0,
      from: json['from'] as String? ?? '',
      database: json['database'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'from': from,
        'database': database,
        'name': name,
      };

  @override
  List<Object?> get props => <Object?>[id, from, database, name];
}
