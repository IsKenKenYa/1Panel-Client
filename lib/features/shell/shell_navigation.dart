import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';

ClientModule? shellModuleForRoute(String route) {
  switch (route) {
    case AppRoutes.server:
    case AppRoutes.serverSelection:
      return ClientModule.servers;
    case AppRoutes.files:
      return ClientModule.files;
    case AppRoutes.containers:
      return ClientModule.containers;
    case AppRoutes.apps:
      return ClientModule.apps;
    case AppRoutes.websites:
      return ClientModule.websites;
    case AppRoutes.ai:
      return ClientModule.ai;
    case AppRoutes.securityVerification:
      return ClientModule.verification;
    case AppRoutes.settings:
      return ClientModule.settings;
  }
  return null;
}

Future<void> openRouteRespectingShell(
  BuildContext context,
  String route, {
  Object? arguments,
}) {
  final module = shellModuleForRoute(route);
  if (module != null && PlatformUtils.isDesktop(context)) {
    return Navigator.of(context).pushReplacementNamed(
      AppRoutes.home,
      arguments: <String, dynamic>{
        'module': module.storageId,
      },
    );
  }

  return Navigator.of(context).pushNamed(route, arguments: arguments);
}
