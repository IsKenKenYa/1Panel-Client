import 'package:flutter/material.dart';
import 'package:onepanel_client/features/security/app_lock_gate.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/module_registry.dart';

/// Shared factory for building module pages inside shell containers (mobile,
/// desktop/common, and native-shell content panes).
///
/// Delegates to [ModuleRegistry] so module page construction lives in one
/// place; adding a new module only requires updating the registry.
Widget buildShellModulePage(
  BuildContext context, {
  required ClientModule module,
  required String? serverId,
  String? serverRevision,
  bool useStableModuleKey = false,
}) {
  final page = ModuleRegistry.buildShellPage(
    context,
    module,
    serverId: serverId,
    serverRevision: serverRevision,
    useStableModuleKey: useStableModuleKey,
  );
  return module.pinnable
      ? AppLockGate(target: module.storageId, child: page)
      : page;
}
