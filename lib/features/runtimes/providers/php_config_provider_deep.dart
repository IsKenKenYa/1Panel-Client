part of 'php_config_provider.dart';

void phpConfigProviderUpdateFpmParam(
  PhpConfigProvider provider,
  String key,
  String value,
) {
  final next = <String, String>{...provider._fpmConfig.params};
  next[key] = value;
  provider._fpmConfig = provider._fpmConfig.copyWith(params: next);
  provider._notifyStateChange();
}

void phpConfigProviderUpdateContainerName(
  PhpConfigProvider provider,
  String value,
) {
  provider._containerConfig = provider._containerConfig.copyWith(
    containerName: value,
  );
  provider._notifyStateChange();
}

void phpConfigProviderUpdatePhpFileContent(
  PhpConfigProvider provider,
  String value,
) {
  provider._phpFileContent = value;
  provider._notifyStateChange();
}

void phpConfigProviderUpdateFpmFileContent(
  PhpConfigProvider provider,
  String value,
) {
  provider._fpmFileContent = value;
  provider._notifyStateChange();
}

void phpConfigProviderAddEnvironment(PhpConfigProvider provider) {
  final next = List<PhpContainerEnvironment>.from(
    provider._containerConfig.safeEnvironments,
  )..add(const PhpContainerEnvironment());
  provider._containerConfig = provider._containerConfig.copyWith(
    environments: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderUpdateEnvironment(
  PhpConfigProvider provider,
  int index, {
  String? key,
  String? value,
}) {
  final next = List<PhpContainerEnvironment>.from(
    provider._containerConfig.safeEnvironments,
  );
  if (index < 0 || index >= next.length) return;
  next[index] = next[index].copyWith(key: key, value: value);
  provider._containerConfig = provider._containerConfig.copyWith(
    environments: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderRemoveEnvironment(PhpConfigProvider provider, int index) {
  final next = List<PhpContainerEnvironment>.from(
    provider._containerConfig.safeEnvironments,
  );
  if (index < 0 || index >= next.length) return;
  next.removeAt(index);
  provider._containerConfig = provider._containerConfig.copyWith(
    environments: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderAddExposedPort(PhpConfigProvider provider) {
  final next = List<PhpContainerExposedPort>.from(
    provider._containerConfig.safeExposedPorts,
  )..add(const PhpContainerExposedPort());
  provider._containerConfig = provider._containerConfig.copyWith(
    exposedPorts: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderUpdateExposedPort(
  PhpConfigProvider provider,
  int index, {
  int? containerPort,
  String? hostIP,
  int? hostPort,
}) {
  final next = List<PhpContainerExposedPort>.from(
    provider._containerConfig.safeExposedPorts,
  );
  if (index < 0 || index >= next.length) return;
  next[index] = next[index].copyWith(
    containerPort: containerPort,
    hostIP: hostIP,
    hostPort: hostPort,
  );
  provider._containerConfig = provider._containerConfig.copyWith(
    exposedPorts: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderRemoveExposedPort(PhpConfigProvider provider, int index) {
  final next = List<PhpContainerExposedPort>.from(
    provider._containerConfig.safeExposedPorts,
  );
  if (index < 0 || index >= next.length) return;
  next.removeAt(index);
  provider._containerConfig = provider._containerConfig.copyWith(
    exposedPorts: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderAddExtraHost(PhpConfigProvider provider) {
  final next = List<PhpContainerExtraHost>.from(
    provider._containerConfig.safeExtraHosts,
  )..add(const PhpContainerExtraHost());
  provider._containerConfig = provider._containerConfig.copyWith(
    extraHosts: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderUpdateExtraHost(
  PhpConfigProvider provider,
  int index, {
  String? hostname,
  String? ip,
}) {
  final next = List<PhpContainerExtraHost>.from(
    provider._containerConfig.safeExtraHosts,
  );
  if (index < 0 || index >= next.length) return;
  next[index] = next[index].copyWith(hostname: hostname, ip: ip);
  provider._containerConfig = provider._containerConfig.copyWith(
    extraHosts: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderRemoveExtraHost(PhpConfigProvider provider, int index) {
  final next = List<PhpContainerExtraHost>.from(
    provider._containerConfig.safeExtraHosts,
  );
  if (index < 0 || index >= next.length) return;
  next.removeAt(index);
  provider._containerConfig = provider._containerConfig.copyWith(
    extraHosts: next,
  );
  provider._notifyStateChange();
}

void phpConfigProviderAddVolume(PhpConfigProvider provider) {
  final next =
      List<PhpContainerVolume>.from(provider._containerConfig.safeVolumes)
        ..add(const PhpContainerVolume());
  provider._containerConfig = provider._containerConfig.copyWith(volumes: next);
  provider._notifyStateChange();
}

void phpConfigProviderUpdateVolume(
  PhpConfigProvider provider,
  int index, {
  String? source,
  String? target,
}) {
  final next =
      List<PhpContainerVolume>.from(provider._containerConfig.safeVolumes);
  if (index < 0 || index >= next.length) return;
  next[index] = next[index].copyWith(source: source, target: target);
  provider._containerConfig = provider._containerConfig.copyWith(volumes: next);
  provider._notifyStateChange();
}

void phpConfigProviderRemoveVolume(PhpConfigProvider provider, int index) {
  final next =
      List<PhpContainerVolume>.from(provider._containerConfig.safeVolumes);
  if (index < 0 || index >= next.length) return;
  next.removeAt(index);
  provider._containerConfig = provider._containerConfig.copyWith(volumes: next);
  provider._notifyStateChange();
}
