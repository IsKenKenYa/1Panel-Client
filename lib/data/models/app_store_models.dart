import 'package:equatable/equatable.dart';

/// App information model
class AppInfo extends Equatable {
  final String? id;
  final String? name;
  final String? description;
  final String? version;
  final String? author;
  final String? icon;
  final List<String>? tags;
  final String? status;
  final String? installPath;
  final int? downloadCount;
  final String? updateTime;

  const AppInfo({
    this.id,
    this.name,
    this.description,
    this.version,
    this.author,
    this.icon,
    this.tags,
    this.status,
    this.installPath,
    this.downloadCount,
    this.updateTime,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      version: json['version'] as String?,
      author: json['author'] as String?,
      icon: json['icon'] as String?,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList(),
      status: json['status'] as String?,
      installPath: json['installPath'] as String?,
      downloadCount: json['downloadCount'] as int?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'author': author,
      'icon': icon,
      'tags': tags,
      'status': status,
      'installPath': installPath,
      'downloadCount': downloadCount,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        version,
        author,
        icon,
        tags,
        status,
        installPath,
        downloadCount,
        updateTime
      ];
}
