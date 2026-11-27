import 'package:equatable/equatable.dart';

/// 服务端系统日志来源。`journalctl` 支持关键字筛选，`file` 不支持。
enum SystemLogSourceKind {
  journalctl,
  file,
  unknown;

  static SystemLogSourceKind fromValue(String? value) {
    return switch (value) {
      'journalctl' => SystemLogSourceKind.journalctl,
      'file' => SystemLogSourceKind.file,
      _ => SystemLogSourceKind.unknown,
    };
  }

  /// 仅 journalctl 来源支持关键字筛选。
  bool get supportsKeywordFilter => this == SystemLogSourceKind.journalctl;
}

/// `GET /logs/system/status` 响应。
class SystemLogStatus extends Equatable {
  const SystemLogStatus({
    required this.source,
    this.version,
    this.message,
    this.keywordFilterSupported = false,
  });

  final SystemLogSourceKind source;
  final String? version;

  /// 服务端返回的说明文本；`file` 来源用于解释为何不能按关键字筛选。
  final String? message;

  /// 服务端声明的关键字筛选能力，与 [source] 一致时取服务端值。
  final bool keywordFilterSupported;

  bool get canFilterByKeyword =>
      keywordFilterSupported || source.supportsKeywordFilter;

  factory SystemLogStatus.fromJson(Map<String, dynamic> json) {
    final source = SystemLogSourceKind.fromValue(json['source'] as String?);
    return SystemLogStatus(
      source: source,
      version: json['version'] as String?,
      message: json['message'] as String?,
      keywordFilterSupported:
          json['keywordFilterSupported'] as bool? ?? source.supportsKeywordFilter,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'source': source.name,
        'version': version,
        'message': message,
        'keywordFilterSupported': keywordFilterSupported,
      };

  @override
  List<Object?> get props =>
      [source, version, message, keywordFilterSupported];
}

/// `POST /logs/system/read` 请求。游标分页，不提供页码。
class SystemLogSearch extends Equatable {
  const SystemLogSearch({
    this.pageSize = 50,
    this.cursor,
    this.startTime,
    this.endTime,
    this.keyword,
    this.priority,
    this.service,
  });

  /// 服务端上限 500。
  final int pageSize;
  final String? cursor;
  final String? startTime;
  final String? endTime;
  final String? keyword;
  final String? priority;
  final String? service;

  SystemLogSearch copyWith({
    int? pageSize,
    String? cursor,
    String? startTime,
    String? endTime,
    String? keyword,
    String? priority,
    String? service,
  }) {
    return SystemLogSearch(
      pageSize: pageSize ?? this.pageSize,
      cursor: cursor ?? this.cursor,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      keyword: keyword ?? this.keyword,
      priority: priority ?? this.priority,
      service: service ?? this.service,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pageSize': pageSize,
        if (cursor != null && cursor!.isNotEmpty) 'cursor': cursor,
        if (startTime != null && startTime!.isNotEmpty) 'startTime': startTime,
        if (endTime != null && endTime!.isNotEmpty) 'endTime': endTime,
        if (keyword != null && keyword!.isNotEmpty) 'keyword': keyword,
        if (priority != null && priority!.isNotEmpty) 'priority': priority,
        if (service != null && service!.isNotEmpty) 'service': service,
      };

  @override
  List<Object?> get props =>
      [pageSize, cursor, startTime, endTime, keyword, priority, service];
}

/// 单条系统日志。
class SystemLogEntry extends Equatable {
  const SystemLogEntry({
    required this.time,
    required this.message,
    this.priority,
    this.service,
    this.raw,
  });

  final String time;
  final String message;
  final String? priority;
  final String? service;
  final String? raw;

  factory SystemLogEntry.fromJson(Map<String, dynamic> json) {
    return SystemLogEntry(
      time: json['time']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      priority: json['priority'] as String?,
      service: json['service'] as String?,
      raw: json['raw'] as String?,
    );
  }

  @override
  List<Object?> get props => [time, message, priority, service, raw];
}

/// `POST /logs/system/read` 响应。
class SystemLogPage extends Equatable {
  const SystemLogPage({
    this.source = '',
    this.items = const <SystemLogEntry>[],
    this.hasMore = false,
    this.nextCursor,
  });

  final String source;
  final List<SystemLogEntry> items;
  final bool hasMore;
  final String? nextCursor;

  factory SystemLogPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return SystemLogPage(
      source: json['source']?.toString() ?? '',
      items: rawItems
          .map((dynamic item) =>
              SystemLogEntry.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      hasMore: json['hasMore'] as bool? ?? false,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  @override
  List<Object?> get props => [source, items, hasMore, nextCursor];
}
