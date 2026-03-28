import 'package:flutter/material.dart';

enum HighlightType {
  keyword,
  regex,
}

class LogHighlightRule {
  final String id;
  final String pattern;
  final HighlightType type;
  final Color? color;
  final String? colorName;
  final Color? backgroundColor;
  final String? backgroundColorName;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool caseSensitive;

  const LogHighlightRule({
    required this.id,
    required this.pattern,
    this.type = HighlightType.keyword,
    this.color,
    this.colorName,
    this.backgroundColor,
    this.backgroundColorName,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.caseSensitive = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pattern': pattern,
      'type': type.index,
      'color': color?.toARGB32(),
      'colorName': colorName,
      'backgroundColor': backgroundColor?.toARGB32(),
      'backgroundColorName': backgroundColorName,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'caseSensitive': caseSensitive,
    };
  }

  factory LogHighlightRule.fromJson(Map<String, dynamic> json) {
    return LogHighlightRule(
      id: json['id'] as String,
      pattern: json['pattern'] as String,
      type: HighlightType.values[json['type'] as int],
      color: json['color'] != null ? Color(json['color'] as int) : null,
      colorName: json['colorName'] as String?,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      backgroundColorName: json['backgroundColorName'] as String?,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
    );
  }

  LogHighlightRule copyWith({
    String? pattern,
    HighlightType? type,
    Color? color,
    String? colorName,
    Color? backgroundColor,
    String? backgroundColorName,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? caseSensitive,
  }) {
    return LogHighlightRule(
      id: id,
      pattern: pattern ?? this.pattern,
      type: type ?? this.type,
      color: color ?? this.color,
      colorName: colorName ?? this.colorName,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundColorName: backgroundColorName ?? this.backgroundColorName,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      caseSensitive: caseSensitive ?? this.caseSensitive,
    );
  }
}

class LogTheme {
  final String name;
  final List<LogHighlightRule> rules;
  final Color? defaultColor;
  final Color? defaultBackgroundColor;

  const LogTheme({
    required this.name,
    required this.rules,
    this.defaultColor,
    this.defaultBackgroundColor,
  });

  static LogTheme get defaultTheme {
    return const LogTheme(
      name: 'Default',
      rules: [
        LogHighlightRule(
          id: 'error',
          pattern: 'ERROR|ERR|EXCEPTION|FATAL',
          type: HighlightType.regex,
          colorName: 'error',
          isBold: true,
        ),
        LogHighlightRule(
          id: 'warn',
          pattern: 'WARN|WARNING',
          type: HighlightType.regex,
          colorName: 'tertiary',
        ),
        LogHighlightRule(
          id: 'info',
          pattern: 'INFO',
          type: HighlightType.keyword,
          colorName: 'primary',
        ),
        LogHighlightRule(
          id: 'debug',
          pattern: 'DEBUG',
          type: HighlightType.keyword,
          colorName: 'outline',
        ),
        // Timestamp regex
        LogHighlightRule(
          id: 'timestamp',
          pattern: r'^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?',
          type: HighlightType.regex,
          colorName: 'outline',
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rules': rules.map((r) => r.toJson()).toList(),
      'defaultColor': defaultColor?.toARGB32(),
      'defaultBackgroundColor': defaultBackgroundColor?.toARGB32(),
    };
  }

  factory LogTheme.fromJson(Map<String, dynamic> json) {
    return LogTheme(
      name: json['name'] as String,
      rules: (json['rules'] as List)
          .map((r) => LogHighlightRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      defaultColor: json['defaultColor'] != null
          ? Color(json['defaultColor'] as int)
          : null,
      defaultBackgroundColor: json['defaultBackgroundColor'] != null
          ? Color(json['defaultBackgroundColor'] as int)
          : null,
    );
  }

  LogTheme copyWith({
    String? name,
    List<LogHighlightRule>? rules,
    Color? defaultColor,
    Color? defaultBackgroundColor,
  }) {
    return LogTheme(
      name: name ?? this.name,
      rules: rules ?? this.rules,
      defaultColor: defaultColor ?? this.defaultColor,
      defaultBackgroundColor:
          defaultBackgroundColor ?? this.defaultBackgroundColor,
    );
  }
}
