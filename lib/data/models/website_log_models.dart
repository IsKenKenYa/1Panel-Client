import 'package:equatable/equatable.dart';

/// 网站日志读取结果，对应上游 `response.WebsiteLog`。
///
/// `content` 是按 `page`/`pageSize` 截取的行文本，`end` 表示已到文件末尾，
/// `enable` 表示该类型日志在面板上是否开启。
class WebsiteLogContent extends Equatable {
  const WebsiteLogContent({
    this.enable = false,
    this.content = '',
    this.end = false,
    this.path = '',
  });

  final bool enable;
  final String content;
  final bool end;
  final String path;

  factory WebsiteLogContent.fromJson(Map<String, dynamic> json) {
    return WebsiteLogContent(
      enable: json['enable'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      end: json['end'] as bool? ?? false,
      path: json['path'] as String? ?? '',
    );
  }

  /// 按行拆分为日志条目，忽略空行。
  List<String> get lines => content
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  @override
  List<Object?> get props => [enable, content, end, path];
}