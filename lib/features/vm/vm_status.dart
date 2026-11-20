import '../../data/models/vm/vm_models.dart';

/// 虚拟机状态取值来自 dto.VMInfo.status。
///
/// `shut off` 含空格，比较前统一裁剪与转小写，与上游 `utils/vm.ts` 一致。
class VmStatus {
  const VmStatus._();

  static const String running = 'running';
  static const String shutOff = 'shut off';
  static const String blocked = 'blocked';
  static const String paused = 'paused';
  static const String pmsuspended = 'pmsuspended';
  static const String crashed = 'crashed';
  static const String creating = 'creating';
  static const String failed = 'failed';
  static const String deleted = 'deleted';

  static String normalize(String status) => status.trim().toLowerCase();

  static bool isRunning(VMItem vm) => normalize(vm.status) == running;
  static bool isShutOff(VMItem vm) => normalize(vm.status) == shutOff;
  static bool isPaused(VMItem vm) => normalize(vm.status) == paused;
  static bool isCreating(VMItem vm) => normalize(vm.status) == creating;
  static bool isDeleted(VMItem vm) => normalize(vm.status) == deleted;

  /// 创建失败：状态为 failed 且带有创建任务标识。
  static bool isCreateFailed(VMItem vm) =>
      normalize(vm.status) == failed && vm.createTaskID.isNotEmpty;

  /// 处于创建中、创建失败或已删除的实例无法执行任何资源级操作。
  static bool isResourceUnavailable(VMItem vm) =>
      isCreating(vm) || isCreateFailed(vm) || isDeleted(vm);

  /// 已占用宿主机内存的状态集合。
  static bool isMemoryAllocated(VMItem vm) => const <String>[
        running,
        blocked,
        paused,
        'shutdown',
        pmsuspended,
      ].contains(normalize(vm.status));

  /// 电源操作是否可用。
  static bool canOperate(VMItem vm, String operation) {
    if (isResourceUnavailable(vm)) return false;
    switch (operation) {
      case 'start':
        return isShutOff(vm);
      case 'shutdown':
      case 'reboot':
      case 'suspend':
        return isRunning(vm) || normalize(vm.status) == blocked;
      case 'resume':
        return isPaused(vm) || normalize(vm.status) == pmsuspended;
      case 'destroy':
        return isMemoryAllocated(vm) || normalize(vm.status) == crashed;
      default:
        return false;
    }
  }

  /// 编辑、重命名与转模板仅在关机态可用。
  static bool canEdit(VMItem vm) =>
      !isResourceUnavailable(vm) && isShutOff(vm);

  /// VNC 控制台需要运行中且图形类型为 vnc。
  static bool canOpenConsole(VMItem vm) {
    final type = vm.graphics?.type.toLowerCase() ?? '';
    return isRunning(vm) && type == 'vnc';
  }

  /// 快照与健康检查对未创建完成的实例不可用。
  static bool canInspectResources(VMItem vm) => !isResourceUnavailable(vm);

  /// 磁盘扩容在实例创建失败时不可用。
  static bool canResizeDisk(VMItem vm) => !isCreateFailed(vm);
}
