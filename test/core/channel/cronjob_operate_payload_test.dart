import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/cronjob_operate_payload.dart';

/// 原生编辑表单只收集名称、表达式与脚本，其余字段必须从原记录回填，
/// 否则服务端会按空值覆盖，导致任务配置丢失。
void main() {
  group('定时任务编辑请求回填', () {
    test('保留非 shell 任务的类型与专属字段', () {
      final request = buildCronjobOperateRequest(
        <String, dynamic>{'name': 'nginx-log', 'spec': '0 2 * * *'},
        id: 7,
        existing: <String, dynamic>{
          'type': 'website',
          'groupID': 2,
          'website': 'example.test',
          'exclusionRules': '*.log',
          'retainCopies': 5,
          'alertCount': 2,
          'alertTitle': '任务失败',
          'scopes': ['access', 'error'],
        },
      );

      expect(request.type, 'website');
      expect(request.groupID, 2);
      expect(request.website, 'example.test');
      expect(request.exclusionRules, '*.log');
      expect(request.retainCopies, 5);
      expect(request.alertCount, 2);
      expect(request.alertMethod, '');
      expect(request.scopes, ['access', 'error']);
    });

    test('提交值优先于原记录', () {
      final request = buildCronjobOperateRequest(
        <String, dynamic>{
          'name': 'rename',
          'spec': '*/5 * * * *',
          'script': 'echo new',
          'groupID': 9,
        },
        id: 7,
        existing: <String, dynamic>{
          'type': 'shell',
          'groupID': 1,
          'script': 'echo old',
        },
      );

      expect(request.name, 'rename');
      expect(request.spec, '*/5 * * * *');
      expect(request.script, 'echo new');
      expect(request.groupID, 9);
    });

    test('新建任务未提交类型时按 shell 构造', () {
      final request = buildCronjobOperateRequest(
        <String, dynamic>{'name': 'task', 'spec': '* * * * *'},
      );

      expect(request.id, isNull);
      expect(request.type, 'shell');
    });

    test('编辑任务缺少类型且原记录也没有类型时拒绝构造', () {
      expect(
        () => buildCronjobOperateRequest(
          <String, dynamic>{'name': 'task', 'spec': '* * * * *'},
          id: 7,
        ),
        throwsArgumentError,
      );
    });

    test('保留快照规则与数字类字段', () {
      final request = buildCronjobOperateRequest(
        <String, dynamic>{'name': 'snapshot', 'spec': '0 3 * * *'},
        id: 7,
        existing: <String, dynamic>{
          'type': 'snapshot',
          'timeout': 7200,
          'retryTimes': 2,
          'ignoreErr': true,
          'snapshotRule': <String, dynamic>{
            'withImage': true,
            'ignoreAppIDs': <dynamic>[3],
          },
        },
      );

      expect(request.timeout, 7200);
      expect(request.retryTimes, 2);
      expect(request.ignoreErr, isTrue);
      expect(request.snapshotRule.withImage, isTrue);
      expect(request.snapshotRule.ignoreAppIDs, [3]);
    });
  });
}