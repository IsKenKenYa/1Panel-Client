import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_status.dart';
import 'package:onepanel_client/features/vm/widgets/vm_sparkline.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

/// 打开虚拟机实时监控弹层。
Future<void> showVmMonitorDialog(BuildContext context, VMItem vm) {
  final provider = context.read<VmProvider>();
  return showAppFormSheet<void>(
    context,
    title: '${context.l10n.vmMonitorTitle} · ${vm.name}',
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: VmMonitorDialog(vm: vm),
    ),
  );
}

class VmMonitorDialog extends StatelessWidget {
  const VmMonitorDialog({super.key, required this.vm});

  final VMItem vm;

  @override
  Widget build(BuildContext context) => VmMonitorView(vm: vm);
}

/// 监控内容视图；与弹层共用同一状态机，便于测试直接挂载。
class VmMonitorView extends StatefulWidget {
  const VmMonitorView({super.key, required this.vm});

  final VMItem vm;

  @override
  State<VmMonitorView> createState() => _VmMonitorState();
}

class _VmMonitorState extends State<VmMonitorView> {
  /// 采样窗口：上游最多 60 点，这里取 50 点以控制绘制开销。
  static const int _maxSamples = 50;
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _timer;
  bool _running = true;
  String? _error;

  final List<double> _cpu = <double>[];
  final List<double> _memory = <double>[];
  final List<double> _disk = <double>[];
  final List<double> _network = <double>[];

  VMStats? _previous;
  VMStats? _latest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _timer = Timer.periodic(_pollInterval, (_) => _poll());
      _poll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (!mounted) {
      return;
    }
    if (!VmStatus.isRunning(widget.vm)) {
      setState(() => _running = false);
      _timer?.cancel();
      return;
    }
    try {
      final stats = await context.read<VmProvider>().getStats(widget.vm.name);
      if (!mounted) {
        return;
      }
      setState(() {
        _previous = _latest;
        _latest = stats;
        _error = null;
        _appendSample(stats);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _timer?.cancel();
      setState(() {
        _error = error.toString();
        _running = false;
      });
    }
  }

  void _appendSample(VMStats stats) {
    final previous = _previous;
    if (previous == null) {
      _cpu.add(_cpuPercent(stats, null));
      _memory.add(_memoryPercent(stats));
      _disk.add(0);
      _network.add(0);
    } else {
      final seconds = (stats.timestamp - previous.timestamp).abs();
      final elapsed = seconds <= 0 ? 1 : seconds;
      _cpu.add(_cpuPercent(stats, previous));
      _memory.add(_memoryPercent(stats));
      final diskDelta =
          (stats.disk.readBytes - previous.disk.readBytes).abs() +
          (stats.disk.writeBytes - previous.disk.writeBytes).abs();
      final netDelta =
          (stats.network.rxBytes - previous.network.rxBytes).abs() +
          (stats.network.txBytes - previous.network.txBytes).abs();
      _disk.add(diskDelta / elapsed);
      _network.add(netDelta / elapsed);
    }
    _trim(_cpu);
    _trim(_memory);
    _trim(_disk);
    _trim(_network);
  }

  void _trim(List<double> values) {
    if (values.length > _maxSamples) {
      values.removeRange(0, values.length - _maxSamples);
    }
  }

  /// CPU 使用率：两次采样的 cpuTime 差值除以采样间隔与核数。
  double _cpuPercent(VMStats stats, VMStats? previous) {
    if (previous == null || stats.vcpu <= 0) {
      return 0;
    }
    final seconds = (stats.timestamp - previous.timestamp).abs();
    final elapsed = seconds <= 0 ? 1 : seconds;
    final delta = stats.cpuTime - previous.cpuTime;
    if (delta <= 0) {
      return 0;
    }
    final percent = delta / (elapsed * stats.vcpu);
    return percent.clamp(0, 1).toDouble() * 100;
  }

  /// 内存使用率：已用内存（总量减可用）占比。
  double _memoryPercent(VMStats stats) {
    final total = stats.memory.actualKiB;
    if (total <= 0) {
      return 0;
    }
    final used = total - stats.memory.availableKiB;
    if (used <= 0) {
      return 0;
    }
    return (used / total).clamp(0, 1).toDouble() * 100;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final latest = _latest;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!_running)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error ?? l10n.vmMonitorStopped,
                style: TextStyle(color: scheme.error),
              ),
            ),
          if (latest == null && _cpu.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.vmMonitorWaitingSamples),
            ),
          _MonitorRow(
            label: l10n.vmMonitorCpuChart,
            samples: _cpu,
            current: latest == null || _cpu.isEmpty ? null : _cpu.last,
            unit: '%',
          ),
          _MonitorRow(
            label: l10n.vmMonitorMemoryChart,
            samples: _memory,
            current: latest == null || _memory.isEmpty ? null : _memory.last,
            unit: '%',
          ),
          _MonitorRow(
            label: l10n.vmMonitorDiskChart,
            samples: _disk,
            current: _disk.isEmpty ? null : _disk.last,
            unit: 'B/s',
            bytesFormatter: true,
          ),
          _MonitorRow(
            label: l10n.vmMonitorNetworkChart,
            samples: _network,
            current: _network.isEmpty ? null : _network.last,
            unit: 'B/s',
            bytesFormatter: true,
          ),
        ],
      ),
    );
  }
}

class _MonitorRow extends StatelessWidget {
  const _MonitorRow({
    required this.label,
    required this.samples,
    required this.current,
    required this.unit,
    this.bytesFormatter = false,
  });

  final String label;
  final List<double> samples;
  final double? current;
  final String unit;
  final bool bytesFormatter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayValue = current == null
        ? '--'
        : bytesFormatter
        ? _formatBytesPerSecond(current!)
        : '${current!.toStringAsFixed(1)}$unit';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(displayValue, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 64,
            child: VmSparkline(
              samples: samples,
              semanticLabel: '$label ${l10n.vmMonitorCurrentLabel}',
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBytesPerSecond(double bytesPerSecond) {
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MiB/s';
    }
    if (bytesPerSecond >= 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KiB/s';
    }
    return '${bytesPerSecond.toStringAsFixed(0)} B/s';
  }
}

/// 供弹层读取实时统计的扩展：经 Provider 取数，避免弹层直连 API。
extension VmStatsReader on BuildContext {
  Future<VMStats> readVmStats(String name) {
    return Provider.of<VmProvider>(this, listen: false).getStats(name);
  }
}
