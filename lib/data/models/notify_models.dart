import 'package:equatable/equatable.dart';

/// Notification message model
class NotificationMessage extends Equatable {
  final int? id;
  final String? title;
  final String? content;
  final String? level;
  final String? type;
  final bool? read;
  final String? createTime;

  const NotificationMessage({
    this.id,
    this.title,
    this.content,
    this.level,
    this.type,
    this.read,
    this.createTime,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'] as int?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      level: json['level'] as String?,
      type: json['type'] as String?,
      read: json['read'] as bool?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'level': level,
      'type': type,
      'read': read,
      'createTime': createTime,
    };
  }

  @override
  List<Object?> get props =>
      [id, title, content, level, type, read, createTime];
}
