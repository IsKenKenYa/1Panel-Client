import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UI component coverage gate', () {
    test('all UI components stay above baseline test coverage', () {
      final uiFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) {
            final path = file.path.replaceAll('\\', '/');
            return path.endsWith('.dart') &&
                (path.contains('/pages/') || path.contains('/widgets/')) &&
                !path.contains('/generated/');
          })
          .map((file) => file.path.replaceAll('\\', '/'))
          .toList(growable: false)
        ..sort();

      final testContents = Directory('test')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_test.dart'))
          .map((file) => file.readAsStringSync())
          .toList(growable: false);

      bool isCoveredByTests(String uiPath) {
        final stem = uiPath.split('/').last.replaceAll('.dart', '');
        return testContents.any((content) => content.contains(stem));
      }

      final uncovered = uiFiles
          .where((uiPath) => !isCoveredByTests(uiPath))
          .toList(growable: false)
        ..sort();

      final coverageRate = uiFiles.isEmpty
          ? 1.0
          : (uiFiles.length - uncovered.length) / uiFiles.length;

      const baselineUiCount = 280;
      const baselineUncoveredCount = 202;
      const baselineMinCoverageRate =
          (baselineUiCount - baselineUncoveredCount) / baselineUiCount;

      expect(
        uiFiles.length,
        greaterThanOrEqualTo(baselineUiCount),
        reason:
            'UI inventory unexpectedly shrank, please confirm scan rules or folder moves.',
      );

      expect(
        uncovered.length,
        lessThanOrEqualTo(baselineUncoveredCount),
        reason: 'Uncovered UI components increased. First 25:\n'
            '${uncovered.take(25).join('\n')}',
      );

      expect(
        coverageRate,
        greaterThanOrEqualTo(baselineMinCoverageRate),
        reason:
            'UI component test coverage regressed. coverage=$coverageRate, baseline=$baselineMinCoverageRate',
      );
    });
  });
}
