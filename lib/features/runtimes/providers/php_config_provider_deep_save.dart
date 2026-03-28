part of 'php_config_provider.dart';

Future<bool> phpConfigProviderSaveFpmConfig(PhpConfigProvider provider) async {
  final runtimeId = provider._runtimeId;
  if (runtimeId == null) {
    return false;
  }
  provider._isSavingFpmConfig = true;
  provider._clearProviderError(notify: false);
  provider._notifyStateChange();
  try {
    await provider._service.saveFpmConfig(
      runtimeId: runtimeId,
      params: provider._fpmConfig.params,
    );
    provider._fpmConfig = await provider._service.loadFpmConfig(runtimeId);
    return true;
  } catch (error, stackTrace) {
    appLogger.eWithPackage(
      'features.runtimes.providers.php_config',
      'save fpm config failed',
      error: error,
      stackTrace: stackTrace,
    );
    provider._setProviderError('runtime.form.saveFailed', notify: false);
    return false;
  } finally {
    provider._isSavingFpmConfig = false;
    provider._notifyStateChange();
  }
}

Future<bool> phpConfigProviderSaveContainerConfig(
  PhpConfigProvider provider,
) async {
  final runtimeId = provider._runtimeId;
  if (runtimeId == null) {
    return false;
  }
  provider._isSavingContainerConfig = true;
  provider._clearProviderError(notify: false);
  provider._notifyStateChange();
  try {
    final request = _buildContainerSaveRequest(provider, runtimeId);
    await provider._service.saveContainerConfig(request);
    provider._containerConfig =
        await provider._service.loadContainerConfig(runtimeId);
    return true;
  } catch (error, stackTrace) {
    appLogger.eWithPackage(
      'features.runtimes.providers.php_config',
      'save container config failed',
      error: error,
      stackTrace: stackTrace,
    );
    provider._setProviderError('runtime.form.saveFailed', notify: false);
    return false;
  } finally {
    provider._isSavingContainerConfig = false;
    provider._notifyStateChange();
  }
}

Future<bool> phpConfigProviderSavePhpFile(PhpConfigProvider provider) {
  return _saveConfigFile(
    provider,
    type: PhpConfigProvider.phpFileType,
    content: provider._phpFileContent,
  );
}

Future<bool> phpConfigProviderSaveFpmFile(PhpConfigProvider provider) {
  return _saveConfigFile(
    provider,
    type: PhpConfigProvider.fpmFileType,
    content: provider._fpmFileContent,
  );
}

Future<bool> _saveConfigFile(
  PhpConfigProvider provider, {
  required String type,
  required String content,
}) async {
  final runtimeId = provider._runtimeId;
  if (runtimeId == null) {
    return false;
  }
  final isPhp = type == PhpConfigProvider.phpFileType;
  if (isPhp) {
    provider._isSavingPhpFile = true;
  } else {
    provider._isSavingFpmFile = true;
  }
  provider._clearProviderError(notify: false);
  provider._notifyStateChange();
  try {
    await provider._service.saveConfigFile(
      runtimeId: runtimeId,
      type: type,
      content: content,
    );
    final refreshed = await provider._service.loadConfigFile(
      runtimeId: runtimeId,
      type: type,
    );
    if (isPhp) {
      provider._phpFilePath = refreshed.path;
      provider._phpFileContent = refreshed.content;
    } else {
      provider._fpmFilePath = refreshed.path;
      provider._fpmFileContent = refreshed.content;
    }
    return true;
  } catch (error, stackTrace) {
    appLogger.eWithPackage(
      'features.runtimes.providers.php_config',
      'save config file failed, type=$type',
      error: error,
      stackTrace: stackTrace,
    );
    provider._setProviderError('runtime.form.saveFailed', notify: false);
    return false;
  } finally {
    if (isPhp) {
      provider._isSavingPhpFile = false;
    } else {
      provider._isSavingFpmFile = false;
    }
    provider._notifyStateChange();
  }
}

PHPContainerConfig _buildContainerSaveRequest(
  PhpConfigProvider provider,
  int runtimeId,
) {
  final environments = provider._containerConfig.safeEnvironments
      .where(
        (item) =>
            (item.key?.trim().isNotEmpty ?? false) ||
            (item.value?.trim().isNotEmpty ?? false),
      )
      .map(
        (item) => item.copyWith(
          key: item.key?.trim(),
          value: item.value?.trim(),
        ),
      )
      .toList(growable: false);

  final exposedPorts = provider._containerConfig.safeExposedPorts
      .where(
        (item) =>
            item.containerPort != null ||
            item.hostPort != null ||
            (item.hostIP?.trim().isNotEmpty ?? false),
      )
      .map(
        (item) => item.copyWith(
          hostIP: item.hostIP?.trim(),
        ),
      )
      .toList(growable: false);

  final extraHosts = provider._containerConfig.safeExtraHosts
      .where(
        (item) =>
            (item.hostname?.trim().isNotEmpty ?? false) ||
            (item.ip?.trim().isNotEmpty ?? false),
      )
      .map(
        (item) => item.copyWith(
          hostname: item.hostname?.trim(),
          ip: item.ip?.trim(),
        ),
      )
      .toList(growable: false);

  final volumes = provider._containerConfig.safeVolumes
      .where(
        (item) =>
            (item.source?.trim().isNotEmpty ?? false) ||
            (item.target?.trim().isNotEmpty ?? false),
      )
      .map(
        (item) => item.copyWith(
          source: item.source?.trim(),
          target: item.target?.trim(),
        ),
      )
      .toList(growable: false);

  return provider._containerConfig.copyWith(
    id: provider._containerConfig.id == 0
        ? runtimeId
        : provider._containerConfig.id,
    containerName: provider._containerConfig.containerName?.trim(),
    environments: environments,
    exposedPorts: exposedPorts,
    extraHosts: extraHosts,
    volumes: volumes,
  );
}
