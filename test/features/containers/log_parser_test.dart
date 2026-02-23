import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Log Parser', () {
    test('parses SSE format correctly', () {
      const input = '''
data: 2023-01-01 12:00:00 Log entry 1

data: 2023-01-01 12:00:01 Log entry 2
data:   Indented line
''';
      
      final lines = input.split('\n');
      final logs = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith('data:')) {
          var content = line.substring(5);
          if (content.startsWith(' ')) {
            content = content.substring(1);
          }
          logs.add(content);
        } else {
          logs.add(line);
        }
      }
      final result = logs.join('\n');
      
      expect(result, '2023-01-01 12:00:00 Log entry 1\n2023-01-01 12:00:01 Log entry 2\n  Indented line');
    });

    test('handles lines without data prefix', () {
      const input = 'Just a normal line\nAnother line';
      
      final lines = input.split('\n');
      final logs = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith('data:')) {
          var content = line.substring(5);
          if (content.startsWith(' ')) {
            content = content.substring(1);
          }
          logs.add(content);
        } else {
          logs.add(line);
        }
      }
      final result = logs.join('\n');
      
      expect(result, 'Just a normal line\nAnother line');
    });
  });
}
