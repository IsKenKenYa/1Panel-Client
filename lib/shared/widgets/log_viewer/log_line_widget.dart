import 'package:flutter/material.dart';
import 'log_viewer_controller.dart';

class LogLineWidget extends StatelessWidget {
  final int index;
  final LogLine line;
  final LogSettings settings;
  final String query;

  const LogLineWidget({
    super.key,
    required this.index,
    required this.line,
    required this.settings,
    this.query = '',
  });

  static final RegExp _logPattern = RegExp(
    r'^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)\s*(?:\[?(\w+)\]?)?\s*(.*)$',
  );

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warn:
        return Colors.orange;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.debug:
        return Colors.grey;
      default:
        return Colors.black; // Fallback, will be overridden by theme usually
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final defaultStyle = TextStyle(
      fontSize: settings.fontSize,
      fontFamily: 'monospace',
      color: textColor,
    );

    final spans = <InlineSpan>[];

    if (settings.showTimestamp) {
      spans.add(TextSpan(
        text: '$index  ',
        style: defaultStyle.copyWith(color: Colors.grey[600]),
      ));
    }
    
    final match = _logPattern.firstMatch(line.originalContent);
    
    if (match != null && match.groupCount >= 3) {
      final timestampStr = match.group(1);
      final levelStr = match.group(2); 
      final messageStr = match.group(3);

      if (settings.showTimestamp && timestampStr != null) {
        spans.add(_buildSpan(timestampStr, Colors.grey, defaultStyle));
        spans.add(TextSpan(text: ' ', style: defaultStyle));
      }

      if (levelStr != null) {
        final levelColor = _getLevelColor(line.level);
        spans.add(TextSpan(text: '[', style: defaultStyle.copyWith(color: Colors.grey)));
        spans.add(_buildSpan(levelStr, levelColor, defaultStyle));
        spans.add(TextSpan(text: '] ', style: defaultStyle.copyWith(color: Colors.grey)));
      }

      if (messageStr != null) {
        spans.add(_buildSpan(messageStr, null, defaultStyle));
      }
    } else {
      spans.add(_buildSpan(line.displayContent, null, defaultStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      softWrap: settings.isWrap,
      overflow: settings.isWrap ? TextOverflow.visible : TextOverflow.clip,
    );
  }

  TextSpan _buildSpan(String text, Color? color, TextStyle style) {
    final effectiveStyle = color != null ? style.copyWith(color: color) : style;
    
    if (query.isEmpty) {
      return TextSpan(text: text, style: effectiveStyle);
    }

    final children = <InlineSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (indexOfMatch > start) {
        children.add(TextSpan(
          text: text.substring(start, indexOfMatch),
          style: effectiveStyle,
        ));
      }
      
      children.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: effectiveStyle.copyWith(backgroundColor: Colors.yellow.withOpacity(0.5)),
      ));
      
      start = indexOfMatch + query.length;
    }

    if (start < text.length) {
      children.add(TextSpan(
        text: text.substring(start),
        style: effectiveStyle,
      ));
    }

    return TextSpan(children: children, style: effectiveStyle);
  }
}

