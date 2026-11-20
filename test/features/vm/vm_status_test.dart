import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/features/vm/vm_status.dart';

void main() {
  VMItem make(String status, {String? graphicsType, String createTaskID = ''}) {
    return VMItem(
      id: 1,
      name: 'vm',
      status: status,
      createTaskID: createTaskID,
      graphics: graphicsType == null
          ? null
          : VMGraphics(type: graphicsType, port: '5900', listen: '127.0.0.1'),
    );
  }

  group('VmStatus', () {
    test('normalizes "shut off" with surrounding whitespace', () {
      expect(VmStatus.isShutOff(make('  Shut Off  ')), isTrue);
      expect(VmStatus.isShutOff(make('running')), isFalse);
    });

    test('start is only available on a powered-off machine', () {
      expect(VmStatus.canOperate(make('shut off'), 'start'), isTrue);
      expect(VmStatus.canOperate(make('running'), 'start'), isFalse);
    });

    test('shutdown, reboot and suspend require running or blocked', () {
      for (final operation in <String>['shutdown', 'reboot', 'suspend']) {
        expect(VmStatus.canOperate(make('running'), operation), isTrue);
        expect(VmStatus.canOperate(make('blocked'), operation), isTrue);
        expect(VmStatus.canOperate(make('shut off'), operation), isFalse);
      }
    });

    test('resume requires paused or pmsuspended', () {
      expect(VmStatus.canOperate(make('paused'), 'resume'), isTrue);
      expect(VmStatus.canOperate(make('pmsuspended'), 'resume'), isTrue);
      expect(VmStatus.canOperate(make('running'), 'resume'), isFalse);
    });

    test('destroy requires allocated memory or crashed', () {
      expect(VmStatus.canOperate(make('running'), 'destroy'), isTrue);
      expect(VmStatus.canOperate(make('crashed'), 'destroy'), isTrue);
      expect(VmStatus.canOperate(make('shut off'), 'destroy'), isFalse);
    });

    test('resource-unavailable states block every operation', () {
      expect(VmStatus.canOperate(make('creating'), 'start'), isFalse);
      expect(VmStatus.canOperate(make('deleted'), 'start'), isFalse);
      expect(
        VmStatus.canOperate(make('failed', createTaskID: 'task-1'), 'start'),
        isFalse,
      );
    });

    test('edit, rename and template conversion require a powered-off state', () {
      expect(VmStatus.canEdit(make('shut off')), isTrue);
      expect(VmStatus.canEdit(make('running')), isFalse);
      expect(VmStatus.canEdit(make('creating')), isFalse);
    });

    test('console requires running plus VNC graphics', () {
      expect(
        VmStatus.canOpenConsole(make('running', graphicsType: 'vnc')),
        isTrue,
      );
      expect(
        VmStatus.canOpenConsole(make('running', graphicsType: 'spice')),
        isFalse,
      );
      expect(
        VmStatus.canOpenConsole(make('shut off', graphicsType: 'vnc')),
        isFalse,
      );
      expect(VmStatus.canOpenConsole(make('running')), isFalse);
    });

    test('disk resize is available unless the create task failed', () {
      expect(VmStatus.canResizeDisk(make('running')), isTrue);
      expect(VmStatus.canResizeDisk(make('failed', createTaskID: 'task-1')),
          isFalse);
    });

    test('failed without a create task id is not a create failure', () {
      expect(VmStatus.isCreateFailed(make('failed')), isFalse);
      expect(VmStatus.isCreateFailed(make('failed', createTaskID: 'task-1')),
          isTrue);
    });
  });
}
