import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/data/repositories/toolbox_repository.dart';

class ToolboxDeviceSnapshot {
  const ToolboxDeviceSnapshot({
    required this.baseInfo,
    required this.conf,
    required this.users,
    required this.zoneOptions,
  });

  final DeviceBaseInfo baseInfo;
  final Map<String, dynamic> conf;
  final List<String> users;
  final List<String> zoneOptions;
}

class ToolboxDeviceService {
  ToolboxDeviceService({ToolboxRepository? repository})
      : _repository = repository ?? ToolboxRepository();

  final ToolboxRepository _repository;

  Future<ToolboxDeviceSnapshot> loadSnapshot() async {
    final results = await Future.wait<dynamic>([
      _repository.getDeviceBaseInfo(),
      _repository.getDeviceConf(),
      _repository.getDeviceUsers(),
      _repository.getDeviceZoneOptions(),
    ]);

    return ToolboxDeviceSnapshot(
      baseInfo: results[0] as DeviceBaseInfo,
      conf: results[1] as Map<String, dynamic>,
      users: results[2] as List<String>,
      zoneOptions: results[3] as List<String>,
    );
  }

  Future<void> updateConfig({
    required String dns,
    required String hostname,
    required String ntp,
    required String swap,
  }) async {
    await _repository.updateDeviceConf(
      DeviceConfUpdate(
        dns: dns,
        hostname: hostname,
        ntp: ntp,
        swap: swap,
      ),
    );
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _repository.updateDevicePassword(
      DevicePasswdUpdate(
        oldPasswd: oldPassword,
        newPasswd: newPassword,
      ),
    );
  }

  Future<void> updateSwap(String swap) {
    return _repository.updateDeviceSwap(swap);
  }

  Future<void> verifyDns(String dns) async {
    await _repository.checkDns(dns);
  }

  String readConfigValue(Map<String, dynamic> conf, List<String> keys) {
    for (final key in keys) {
      final value = conf[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '-';
  }
}
