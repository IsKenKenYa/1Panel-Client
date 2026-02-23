import 'package:flutter/material.dart';
import 'log_viewer_controller.dart';

class LogLineWidget extends StatelessWidget {
  final int index;
  final LogLine line;
  final LogSettings settings;
  final String query;
  final DateTime? firstLogTimestamp;

  const LogLineWidget({
    super.key,
    required this.index,
    required this.line,
    required this.settings,
    this.query = '',
    this.firstLogTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final defaultStyle = TextStyle(
      fontSize: settings.fontSize,
      fontFamily: 'monospace',
      color: textColor,
      height: settings.lineHeight,
    );

    final spans = <InlineSpan>[];

    // Line Number
    spans.add(TextSpan(
      text: '$index  ',
      style: defaultStyle.copyWith(color: Colors.grey[600]),
    ));

    // Content with highlighting
    String content = line.originalContent;
    if (line.timestamp != null && line.timestampEndIndex != null) {
      if (!settings.showTimestamp) {
        if (line.timestampEndIndex! < content.length) {
          content = content.substring(line.timestampEndIndex!).trimLeft();
        } else {
          content = '';
        }
      } else if (settings.timestampFormat == LogTimestampFormat.relative && firstLogTimestamp != null) {
        final duration = line.timestamp!.difference(firstLogTimestamp!);
        final relativeTime = _formatDuration(duration);
        final message = line.timestampEndIndex! < content.length 
            ? content.substring(line.timestampEndIndex!).trimLeft() 
            : '';
        content = '$relativeTime $message';
      }
    }

    spans.addAll(_buildContentSpans(content, defaultStyle, theme.colorScheme));

    final richText = RichText(
      text: TextSpan(children: spans),
      softWrap: settings.viewMode == LogViewMode.wrap,
      overflow: settings.viewMode == LogViewMode.wrap ? TextOverflow.visible : TextOverflow.clip,
    );

    if (settings.viewMode == LogViewMode.wrap) {
      return richText;
    }

    if (settings.viewMode == LogViewMode.scrollLine) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: richText,
      );
    }

    // LogViewMode.scrollPage
    // The parent container (LogViewer) handles the horizontal scrolling.
    // We just render the text without wrapping.
    return richText;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final millis = d.inMilliseconds % 1000;
    return '+${minutes}m${seconds}s.${millis}ms';
  }

  List<InlineSpan> _buildContentSpans(String text, TextStyle baseStyle, ColorScheme scheme) {
    // 1. Identify all ranges that need styling
    final ranges = <_StyleRange>[];

    // Search query highlight (Highest Priority)
    if (query.isNotEmpty) {
      final lowerText = text.toLowerCase();
      final lowerQuery = query.toLowerCase();
      int start = 0;
      while (true) {
        final idx = lowerText.indexOf(lowerQuery, start);
        if (idx == -1) break;
        ranges.add(_StyleRange(
          start: idx,
          end: idx + query.length,
          style: baseStyle.copyWith(backgroundColor: Colors.yellow.withOpacity(0.5)),
          priority: 100,
        ));
        start = idx + query.length;
      }
    }

    // Theme rules highlight
    for (final rule in settings.theme.rules) {
      final matches = _findMatches(text, rule);
      for (final match in matches) {
        ranges.add(_StyleRange(
          start: match.start,
          end: match.end,
          style: _getRuleStyle(baseStyle, rule, scheme),
          priority: 10, // Lower priority than search
        ));
      }
    }

    // 2. Sort ranges
    ranges.sort((a, b) => a.start.compareTo(b.start));

    // 3. Flatten ranges (Handling overlaps is complex, let's simplify: highest priority wins)
    // We will build a list of non-overlapping spans.
    final spans = <InlineSpan>[];

    // A simple way to handle overlaps is to use a "mask" array, but for text it's better to iterate.
    // Let's use a "stack" approach or just split by boundaries.
    
    // Collect all boundaries
    final boundaries = <int>{0, text.length};
    for (final range in ranges) {
      boundaries.add(range.start);
      boundaries.add(range.end);
    }
    final sortedBoundaries = boundaries.toList()..sort();

    for (int i = 0; i < sortedBoundaries.length - 1; i++) {
      final start = sortedBoundaries[i];
      final end = sortedBoundaries[i+1];
      if (start >= end) continue;

      // Find the highest priority rule that covers this segment
      _StyleRange? bestRange;
      for (final range in ranges) {
        if (range.start <= start && range.end >= end) {
          if (bestRange == null || range.priority > bestRange.priority) {
            bestRange = range;
          }
        }
      }

      spans.add(TextSpan(
        text: text.substring(start, end),
        style: bestRange?.style ?? baseStyle,
      ));
    }

    return spans;
  }

  TextStyle _getRuleStyle(TextStyle base, LogHighlightRule rule, ColorScheme scheme) {
    return base.copyWith(
      color: _resolveColor(rule.color, rule.colorName, scheme),
      backgroundColor: _resolveColor(rule.backgroundColor, rule.backgroundColorName, scheme),
      fontWeight: rule.isBold ? FontWeight.bold : null,
      fontStyle: rule.isItalic ? FontStyle.italic : null,
      decoration: rule.isUnderline ? TextDecoration.underline : null,
    );
  }

  Color? _resolveColor(Color? color, String? colorName, ColorScheme scheme) {
    if (colorName != null) {
      switch (colorName) {
        case 'primary': return scheme.primary;
        case 'onPrimary': return scheme.onPrimary;
        case 'primaryContainer': return scheme.primaryContainer;
        case 'onPrimaryContainer': return scheme.onPrimaryContainer;
        case 'secondary': return scheme.secondary;
        case 'onSecondary': return scheme.onSecondary;
        case 'secondaryContainer': return scheme.secondaryContainer;
        case 'onSecondaryContainer': return scheme.onSecondaryContainer;
        case 'tertiary': return scheme.tertiary;
        case 'onTertiary': return scheme.onTertiary;
        case 'tertiaryContainer': return scheme.tertiaryContainer;
        case 'onTertiaryContainer': return scheme.onTertiaryContainer;
        case 'error': return scheme.error;
        case 'onError': return scheme.onError;
        case 'errorContainer': return scheme.errorContainer;
        case 'onErrorContainer': return scheme.onErrorContainer;
        case 'background': return scheme.surface; // Material 3 uses surface
        case 'onBackground': return scheme.onSurface;
        case 'surface': return scheme.surface;
        case 'onSurface': return scheme.onSurface;
        case 'surfaceVariant': return scheme.surfaceContainerHighest;
        case 'onSurfaceVariant': return scheme.onSurfaceVariant;
        case 'outline': return scheme.outline;
        case 'outlineVariant': return scheme.outlineVariant;
        case 'shadow': return scheme.shadow;
        case 'scrim': return scheme.scrim;
        case 'inverseSurface': return scheme.inverseSurface;
        case 'onInverseSurface': return scheme.onInverseSurface;
        case 'inversePrimary': return scheme.inversePrimary;
        case 'surfaceTint': return scheme.surfaceTint;
      }
    }
    return color;
  }

  List<({int start, int end})> _findMatches(String text, LogHighlightRule rule) {
    final matches = <({int start, int end})>[];
    if (rule.type == HighlightType.regex) {
      try {
        final regex = RegExp(rule.pattern, caseSensitive: rule.caseSensitive);
        for (final match in regex.allMatches(text)) {
          matches.add((start: match.start, end: match.end));
        }
      } catch (_) {
        // Ignore invalid regex
      }
    } else {
      final pattern = rule.caseSensitive ? rule.pattern : rule.pattern.toLowerCase();
      final target = rule.caseSensitive ? text : text.toLowerCase();
      int start = 0;
      while (true) {
        final idx = target.indexOf(pattern, start);
        if (idx == -1) break;
        matches.add((start: idx, end: idx + pattern.length));
        start = idx + pattern.length;
      }
    }
    return matches;
  }
}

class _StyleRange {
  final int start;
  final int end;
  final TextStyle style;
  final int priority;

  _StyleRange({
    required this.start,
    required this.end,
    required this.style,
    required this.priority,
  });
}

