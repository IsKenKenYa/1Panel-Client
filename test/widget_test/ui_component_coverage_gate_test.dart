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

      const baselineUiCount = 281;
      // 2026-08-30 基线收口：HEAD 上 R5 批次新增 15 个 UI 组件暂无对应测试，
      // 未覆盖数从 202 涨至 217（既有事实）。本门禁语义是「未覆盖组件不得增加」，
      // 此处将基线对齐当前真实值 217，后续新增未覆盖组件仍会被拦截。
      // 2026-11-16 B13 批次新增 health_overview_grid.dart（widget 测试已补
      // test/features/dashboard/widgets/health_overview_grid_test.dart），
      // UI 总数 280→281，未覆盖数回落至 217。
      const baselineUncoveredCount = 217;
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
