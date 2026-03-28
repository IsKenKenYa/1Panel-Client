import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/common_models.dart';

void main() {
  group('通用模型测试', () {
    group('OperateByID测试', () {
      test('应该正确序列化和反序列化', () {
        final model = OperateByID(id: 123);

        final json = model.toJson();
        final restored = OperateByID.fromJson(json);

        expect(restored.id, equals(123));
      });

      test('应该支持不同的ID值', () {
        final model1 = OperateByID(id: 0);
        final model2 = OperateByID(id: 999999);

        expect(OperateByID.fromJson(model1.toJson()).id, equals(0));
        expect(OperateByID.fromJson(model2.toJson()).id, equals(999999));
      });
    });

    group('OperateByType测试', () {
      test('应该正确序列化和反序列化', () {
        final model = OperateByType(
          id: 1,
          name: 'test',
          type: 'example',
        );

        final json = model.toJson();
        final restored = OperateByType.fromJson(json);

        expect(restored.id, equals(1));
        expect(restored.name, equals('test'));
        expect(restored.type, equals('example'));
      });

      test('应该处理null ID', () {
        final model = OperateByType(
          name: 'test',
          type: 'example',
        );

        final json = model.toJson();
        final restored = OperateByType.fromJson(json);

        expect(restored.id, isNull);
        expect(restored.name, equals('test'));
      });
    });

    group('PageRequest测试', () {
      test('应该正确序列化和反序列化', () {
        final model = PageRequest(
          page: 1,
          pageSize: 20,
        );

        final json = model.toJson();
        final restored = PageRequest.fromJson(json);

        expect(restored.page, equals(1));
        expect(restored.pageSize, equals(20));
      });

      test('应该使用默认值', () {
        final model = PageRequest();

        final json = model.toJson();
        final restored = PageRequest.fromJson(json);

        expect(restored.page, equals(1));
        expect(restored.pageSize, equals(20));
      });
    });

    group('PageResult测试', () {
      test('应该正确从JSON反序列化', () {
        final json = {
          'items': [1, 2, 3],
          'total': 3,
          'page': 1,
          'pageSize': 20,
          'totalPages': 1,
        };

        final result = PageResult<int>.fromJson(json, (item) => item as int);

        expect(result.items, equals([1, 2, 3]));
        expect(result.total, equals(3));
        expect(result.page, equals(1));
        expect(result.pageSize, equals(20));
      });

      test('应该处理空列表', () {
        final json = {
          'items': [],
          'total': 0,
          'page': 1,
          'pageSize': 20,
          'totalPages': 0,
        };

        final result =
            PageResult<String>.fromJson(json, (item) => item as String);

        expect(result.items, isEmpty);
        expect(result.total, equals(0));
      });
    });

    group('ForceDelete测试', () {
      test('应该正确序列化和反序列化', () {
        final model = ForceDelete(
          ids: [1, 2, 3],
          forceDelete: true,
        );

        final json = model.toJson();
        final restored = ForceDelete.fromJson(json);

        expect(restored.ids, equals([1, 2, 3]));
        expect(restored.forceDelete, isTrue);
      });

      test('应该使用默认forceDelete值', () {
        final model = ForceDelete(
          ids: [1],
        );

        final json = model.toJson();
        final restored = ForceDelete.fromJson(json);

        expect(restored.ids, equals([1]));
        expect(restored.forceDelete, isFalse);
      });
    });

    group('SearchWithPage测试', () {
      test('应该正确序列化和反序列化', () {
        final model = SearchWithPage(
          info: 'search term',
          page: 1,
          pageSize: 20,
        );

        final json = model.toJson();
        final restored = SearchWithPage.fromJson(json);

        expect(restored.info, equals('search term'));
        expect(restored.page, equals(1));
        expect(restored.pageSize, equals(20));
      });

      test('应该处理null info', () {
        final model = SearchWithPage(
          page: 1,
          pageSize: 10,
        );

        final json = model.toJson();
        final restored = SearchWithPage.fromJson(json);

        expect(restored.info, isNull);
      });
    });
  });

  group('Command和Script模型测试', () {
    group('CommandInfo测试', () {
      test('应该正确序列化和反序列化', () {
        final model = CommandInfo(
          id: 1,
          name: '重启服务',
          command: 'systemctl restart nginx',
          groupBelong: '系统管理',
          groupID: 1,
          type: 'shell',
        );

        final json = model.toJson();
        final restored = CommandInfo.fromJson(json);

        expect(restored.id, equals(1));
        expect(restored.name, equals('重启服务'));
        expect(restored.command, equals('systemctl restart nginx'));
        expect(restored.groupBelong, equals('系统管理'));
        expect(restored.groupID, equals(1));
        expect(restored.type, equals('shell'));
      });

      test('应该处理null值', () {
        final model = CommandInfo();

        final json = model.toJson();
        final restored = CommandInfo.fromJson(json);

        expect(restored.id, isNull);
        expect(restored.name, isNull);
        expect(restored.command, isNull);
      });
    });

    group('CommandOperate测试', () {
      test('应该正确序列化和反序列化', () {
        final model = CommandOperate(
          id: 1,
          name: '更新系统',
          command: 'apt update',
          groupBelong: '维护',
          groupID: 2,
          type: 'shell',
        );

        final json = model.toJson();
        final restored = CommandOperate.fromJson(json);

        expect(restored.id, equals(1));
        expect(restored.name, equals('更新系统'));
        expect(restored.command, equals('apt update'));
      });

      test('必填字段验证', () {
        final model = CommandOperate(
          name: '测试',
          command: 'echo test',
        );

        final json = model.toJson();
        expect(json['name'], equals('测试'));
        expect(json['command'], equals('echo test'));
        expect(json['id'], isNull);
      });
    });

    group('CommandTree测试', () {
      test('应该正确序列化和反序列化', () {
        final model = CommandTree(
          label: '系统管理',
          value: 'system',
          children: [
            CommandTree(label: '服务', value: 'service'),
            CommandTree(label: '网络', value: 'network'),
          ],
        );

        final json = model.toJson();
        final restored = CommandTree.fromJson(json);

        expect(restored.label, equals('系统管理'));
        expect(restored.value, equals('system'));
        expect(restored.children?.length, equals(2));
        expect(restored.children?[0].label, equals('服务'));
      });

      test('应该处理空children', () {
        final model = CommandTree(
          label: '根节点',
          value: 'root',
        );

        final json = model.toJson();
        final restored = CommandTree.fromJson(json);

        expect(restored.children, isNull);
      });

      test('应该处理嵌套结构', () {
        final model = CommandTree(
          label: '根',
          value: 'root',
          children: [
            CommandTree(
              label: '一级',
              value: 'level1',
              children: [
                CommandTree(label: '二级', value: 'level2'),
              ],
            ),
          ],
        );

        final json = model.toJson();
        final restored = CommandTree.fromJson(json);

        expect(restored.children?[0].children?[0].label, equals('二级'));
      });
    });

    group('ScriptOperate测试', () {
      test('应该正确序列化和反序列化', () {
        final model = ScriptOperate(
          id: 1,
          name: '备份脚本',
          description: '每日备份',
          script: '#!/bin/bash\nbackup',
          groups: '备份',
          isInteractive: false,
        );

        final json = model.toJson();
        final restored = ScriptOperate.fromJson(json);

        expect(restored.id, equals(1));
        expect(restored.name, equals('备份脚本'));
        expect(restored.description, equals('每日备份'));
        expect(restored.script, equals('#!/bin/bash\nbackup'));
        expect(restored.groups, equals('备份'));
        expect(restored.isInteractive, isFalse);
      });

      test('应该处理null值', () {
        final model = ScriptOperate();

        final json = model.toJson();
        final restored = ScriptOperate.fromJson(json);

        expect(restored.id, isNull);
        expect(restored.name, isNull);
        expect(restored.isInteractive, isNull);
      });

      test('应该处理多行脚本', () {
        final scriptContent = '''#!/bin/bash
# 多行脚本
echo "开始"
cd /tmp
ls
echo "结束"''';

        final model = ScriptOperate(
          name: '多行脚本',
          script: scriptContent,
        );

        final json = model.toJson();
        final restored = ScriptOperate.fromJson(json);

        expect(restored.script, equals(scriptContent));
      });
    });

    group('ScriptOptions测试', () {
      test('应该正确序列化和反序列化', () {
        final model = ScriptOptions(
          id: 1,
          name: '选项1',
        );

        final json = model.toJson();
        final restored = ScriptOptions.fromJson(json);

        expect(restored.id, equals(1));
        expect(restored.name, equals('选项1'));
      });

      test('应该处理null值', () {
        final model = ScriptOptions();

        final json = model.toJson();
        final restored = ScriptOptions.fromJson(json);

        expect(restored.id, isNull);
        expect(restored.name, isNull);
      });
    });

    group('OperateByIDs测试', () {
      test('应该正确序列化和反序列化', () {
        final model = OperateByIDs(ids: [1, 2, 3]);

        final json = model.toJson();
        final restored = OperateByIDs.fromJson(json);

        expect(restored.ids, equals([1, 2, 3]));
      });

      test('应该处理空列表', () {
        final model = OperateByIDs(ids: []);

        final json = model.toJson();
        final restored = OperateByIDs.fromJson(json);

        expect(restored.ids, isEmpty);
      });
    });
  });

  group('边界条件测试', () {
    test('Command应该处理空字符串', () {
      final model = CommandInfo(
        id: 1,
        name: '',
        command: '',
      );

      final json = model.toJson();
      final restored = CommandInfo.fromJson(json);

      expect(restored.name, equals(''));
      expect(restored.command, equals(''));
    });

    test('Command应该处理特殊字符', () {
      final model = CommandInfo(
        id: 1,
        name: '命令 & 管道',
        command: 'ls -la | grep "test" > /dev/null',
      );

      final json = model.toJson();
      final restored = CommandInfo.fromJson(json);

      expect(restored.name, equals('命令 & 管道'));
      expect(restored.command, equals('ls -la | grep "test" > /dev/null'));
    });

    test('Command应该处理Unicode字符', () {
      final model = CommandInfo(
        id: 1,
        name: '🚀 部署',
        command: 'echo "你好"',
      );

      final json = model.toJson();
      final restored = CommandInfo.fromJson(json);

      expect(restored.name, equals('🚀 部署'));
      expect(restored.command, equals('echo "你好"'));
    });

    test('Script应该处理空脚本', () {
      final model = ScriptOperate(
        name: '空脚本',
        script: '',
      );

      final json = model.toJson();
      final restored = ScriptOperate.fromJson(json);

      expect(restored.script, equals(''));
    });

    test('Script应该处理长脚本', () {
      final longScript = 'echo "${'a' * 10000}"';
      final model = ScriptOperate(
        name: '长脚本',
        script: longScript,
      );

      final json = model.toJson();
      final restored = ScriptOperate.fromJson(json);

      expect(restored.script?.length, equals(longScript.length));
    });
  });
}
