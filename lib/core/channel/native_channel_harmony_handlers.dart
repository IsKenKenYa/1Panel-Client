import 'package:flutter/services.dart';

import 'native_channel_apps.dart';
import 'native_channel_container_deep_handlers.dart';
import 'native_channel_harmony_automation.dart';
import 'native_channel_harmony_compute.dart';
import 'native_channel_harmony_databases.dart';
import 'native_channel_harmony_feedback.dart';
import 'native_channel_harmony_file_secondary.dart';
import 'native_channel_harmony_file_transfers.dart';
import 'native_channel_harmony_host.dart';
import 'native_channel_harmony_legal.dart';
import 'native_channel_harmony_panel.dart';
import 'native_channel_harmony_privacy.dart';
import 'native_channel_harmony_security_verification.dart';
import 'native_channel_harmony_settings.dart';
import 'native_server_config.dart';
import 'native_channel_website_config.dart';
import 'native_channel_website_lifecycle.dart';
import 'native_channel_website_runtime_advanced.dart';
import 'native_channel_website_runtimes.dart';
import 'native_channel_website_security_handlers.dart';
import 'native_channel_website_ssl.dart';
import 'native_channel_website_templates.dart';

class NativeChannelHarmonyHandlers {
  static Future<dynamic> dispatch(String method, dynamic arguments) {
    switch (method) {
      case 'testHarmonyServerConnection':
        return testHarmonyServerConnection(arguments as Map);
      case 'getHarmonyFileSecondary':
      case 'operateHarmonyFileSecondary':
        return NativeChannelHarmonyFileSecondary.dispatch(method, arguments);
      case 'getHarmonyPanelEntrance':
        return NativeChannelHarmonySecurityVerification.getPanelEntrance(arguments);
      case 'openHarmonyPanelEntrance':
        return NativeChannelHarmonySecurityVerification.openPanelEntrance(arguments);
      case 'getHarmonyFileTransfers':
      case 'getHarmonyFileDirectory':
      case 'operateHarmonyFileTransfer':
      case 'enqueueHarmonyFileDownload':
      case 'uploadHarmonyFiles':
      case 'moveHarmonyFiles':
      case 'getHarmonyFileUploadHistory':
      case 'getHarmonyFilePreview':
      case 'getHarmonyFileEditor':
      case 'saveHarmonyFileEditor':
      case 'releaseHarmonyFilePreview':
      case 'openHarmonyFilePreview':
        return NativeChannelHarmonyFileTransfers.dispatch(method, arguments);
      case 'searchNativeRuntimes':
      case 'getNativeRuntimeDetail':
      case 'getNativeRuntimeForm':
      case 'saveNativeRuntime':
      case 'syncNativeRuntimes':
      case 'operateNativeRuntime':
      case 'updateNativeRuntimeRemark':
      case 'checkNativeRuntimeDelete':
      case 'deleteNativeRuntime':
        return NativeChannelWebsiteRuntimesHandlers.dispatch(method, arguments);
      case 'getNativeRuntimeManagement':
      case 'performNativeRuntimeManagement':
        return NativeChannelWebsiteRuntimeAdvancedHandlers.dispatch(method, arguments);
      case 'syncInstalledApps':
      case 'syncRemoteApps':
      case 'syncLocalApps':
      case 'getIgnoredAppDetails':
      case 'ignoreAppUpdate':
      case 'cancelIgnoreAppUpdate':
      case 'getAppServices':
      case 'loadAppDatabaseFormats':
      case 'loadAppWebsiteDir':
      case 'getAppConnInfo':
      case 'getAppUpdateVersions':
      case 'checkAppUninstall':
      case 'updateAppParams':
      case 'changeAppPort':
      case 'updateAppInstallConfig':
      case 'upgradeHarmonyApp':
      case 'installHarmonyApp':
      case 'uninstallHarmonyApp':
      case 'getHarmonyAppIcon':
        return NativeChannelApps.dispatch(method, arguments);
      case 'searchNativeWebsites':
      case 'getNativeWebsiteDetail':
      case 'getNativeWebsiteGroups':
      case 'createNativeWebsite':
      case 'updateNativeWebsite':
      case 'operateNativeWebsites':
      case 'setNativeWebsiteGroup':
      case 'setNativeDefaultWebsite':
      case 'updateNativeWebsiteDomain':
      case 'getNativeDefaultWebsiteHtml':
      case 'updateNativeDefaultWebsiteHtml':
        return NativeChannelWebsiteLifecycleHandlers.dispatch(method, arguments);
      case 'getNativeWebsiteNginx':
      case 'saveNativeWebsiteNginx':
      case 'getNativeWebsiteResource':
      case 'setNativeWebsiteDatabase':
      case 'setNativeWebsitePhp':
      case 'getNativeWebsiteScope':
      case 'saveNativeWebsiteScope':
      case 'saveNativeWebsiteRuleSource':
        return NativeChannelWebsiteConfigHandlers.dispatch(method, arguments);
      case 'getNativeOpenrestyState':
      case 'performNativeOpenrestyAction':
      case 'releaseNativeOpenrestyState':
      case 'getNativeSecurityGatewayState':
      case 'rollbackNativeSecurityGateway':
        return NativeChannelWebsiteSecurityHandlers.dispatch(method, arguments);
      case 'getNativeWebsiteSslCenter':
      case 'releaseNativeWebsiteSsl':
      case 'getNativeWebsiteCertificate':
      case 'performNativeWebsiteSslAction':
      case 'pickNativeWebsiteSslFile':
      case 'getNativeWebsiteSslAccounts':
      case 'performNativeWebsiteSslAccountAction':
      case 'getNativeWebsiteHttps':
      case 'performNativeWebsiteHttpsAction':
        return NativeChannelWebsiteSslHandlers.dispatch(method, arguments);
      case 'getNativeWebsiteTemplates':
      case 'getNativeWebsiteTemplate':
      case 'saveNativeWebsiteTemplate':
      case 'deleteNativeWebsiteTemplate':
      case 'getNativeWebsiteTemplateOutputs':
      case 'getNativeWebsiteTemplateOutput':
      case 'previewNativeWebsiteTemplate':
      case 'createNativeWebsiteTemplateOutput':
      case 'deleteNativeWebsiteTemplateOutput':
        return NativeChannelWebsiteTemplateHandlers.dispatch(method, arguments);
      case 'getHarmonyDatabasePage':
        return HarmonyDatabaseHandlers.getPage(arguments);
      case 'getHarmonyDatabaseTargets':
        return HarmonyDatabaseHandlers.getTargets(arguments);
      case 'getHarmonyDatabaseDetail':
        return HarmonyDatabaseHandlers.getDetail(arguments);
      case 'getHarmonyRemoteDatabaseConfig':
        return HarmonyDatabaseHandlers.getRemoteConfig(arguments);
      case 'submitHarmonyDatabaseForm':
        return HarmonyDatabaseHandlers.submitForm(arguments);
      case 'testHarmonyDatabaseConnection':
        return HarmonyDatabaseHandlers.testConnection(arguments);
      case 'updateHarmonyDatabaseDescription':
        return HarmonyDatabaseHandlers.updateDescription(arguments);
      case 'changeHarmonyDatabasePassword':
        return HarmonyDatabaseHandlers.changePassword(arguments);
      case 'loadHarmonyDatabaseFromRemote':
        return HarmonyDatabaseHandlers.loadFromRemote(arguments);
      case 'getHarmonyDatabaseUsers':
        return HarmonyDatabaseHandlers.getUsers(arguments);
      case 'bindHarmonyDatabaseUser':
        return HarmonyDatabaseHandlers.bindUser(arguments);
      case 'updateHarmonyDatabasePrivileges':
        return HarmonyDatabaseHandlers.updatePrivileges(arguments);
      case 'getHarmonyDatabaseBackups':
        return HarmonyDatabaseHandlers.getBackups(arguments);
      case 'createHarmonyDatabaseBackup':
        return HarmonyDatabaseHandlers.createBackup(arguments);
      case 'restoreHarmonyDatabaseBackup':
        return HarmonyDatabaseHandlers.restoreBackup(arguments);
      case 'deleteHarmonyDatabaseBackup':
        return HarmonyDatabaseHandlers.deleteBackup(arguments);
      case 'getHarmonyMongodbPrivileges':
        return HarmonyDatabaseHandlers.getMongodbPrivileges(arguments);
      case 'getHarmonyPostgresqlPrivileges':
        return HarmonyDatabaseHandlers.getPostgresqlPrivileges(arguments);
      case 'deleteHarmonyDatabase':
        return HarmonyDatabaseHandlers.deleteDatabase(arguments);
      case 'getHarmonyDatabaseSlowLog':
        return HarmonyDatabaseHandlers.getSlowLog(arguments);
      case 'changeHarmonyMongodbRootPassword':
        return HarmonyDatabaseHandlers.changeMongodbRootPassword(arguments);
      case 'changeHarmonyMongodbPrivileges':
        return HarmonyDatabaseHandlers.changeMongodbPrivileges(arguments);
      case 'getContainerForm':
        return NativeChannelContainerDeepHandlers.getContainerForm(arguments);
      case 'createContainerFromForm':
        return NativeChannelContainerDeepHandlers.createContainerFromForm(arguments);
      case 'getContainerStats':
        return NativeChannelContainerDeepHandlers.getContainerStats(arguments);
      case 'renameContainer':
        return NativeChannelContainerDeepHandlers.renameContainer(arguments);
      case 'upgradeContainer':
        return NativeChannelContainerDeepHandlers.upgradeContainer(arguments);
      case 'commitContainer':
        return NativeChannelContainerDeepHandlers.commitContainer(arguments);
      case 'updateContainer':
        return NativeChannelContainerDeepHandlers.updateContainer(arguments);
      case 'cleanContainerLog':
        return NativeChannelContainerDeepHandlers.cleanContainerLog(arguments);
      case 'pruneContainers':
        return NativeChannelContainerDeepHandlers.pruneContainers(arguments);
      case 'getDockerConfiguration':
        return NativeChannelContainerDeepHandlers.getDockerConfiguration(arguments);
      case 'saveDockerConfiguration':
        return NativeChannelContainerDeepHandlers.saveDockerConfiguration(arguments);
      case 'operateDocker':
        return NativeChannelContainerDeepHandlers.operateDocker(arguments);
      case 'tagContainerImage':
        return NativeChannelContainerDeepHandlers.tagContainerImage(arguments);
      case 'saveContainerImage':
        return NativeChannelContainerDeepHandlers.saveContainerImage(arguments);
      case 'loadContainerImage':
        return NativeChannelContainerDeepHandlers.loadContainerImage(arguments);
      case 'updateContainerTemplate':
        return NativeChannelContainerDeepHandlers.updateContainerTemplate(arguments);
      case 'getHarmonyAppearance':
        return NativeChannelHarmonySettings.getAppearance(arguments);
      case 'updateHarmonyAppearance':
        return NativeChannelHarmonySettings.updateAppearance(arguments);
      case 'resetHarmonyOnboarding':
        return NativeChannelHarmonySettings.resetOnboarding(arguments);
      case 'getHarmonyAppLock':
        return NativeChannelHarmonyPrivacy.getAppLock(arguments);
      case 'updateHarmonyAppLock':
        return NativeChannelHarmonyPrivacy.updateAppLock(arguments);
      case 'getHarmonyStorage':
        return NativeChannelHarmonyPrivacy.getStorage(arguments);
      case 'updateHarmonyStorage':
        return NativeChannelHarmonyPrivacy.updateStorage(arguments);
      case 'getHarmonyFeedback':
        return NativeChannelHarmonyFeedback.getHarmonyFeedback(arguments);
      case 'getHarmonyLogPreview':
        return NativeChannelHarmonyFeedback.getHarmonyLogPreview(arguments);
      case 'updateHarmonyLogLevel':
        return NativeChannelHarmonyFeedback.updateHarmonyLogLevel(arguments);
      case 'copyHarmonyFeedbackTemplate':
        return NativeChannelHarmonyFeedback.copyHarmonyFeedbackTemplate(arguments);
      case 'exportHarmonyLogs':
        return NativeChannelHarmonyFeedback.exportHarmonyLogs(arguments);
      case 'clearHarmonyLogs':
        return NativeChannelHarmonyFeedback.clearHarmonyLogs(arguments);
      case 'getHarmonyAboutInfo':
        return NativeChannelHarmonyLegal.getHarmonyAboutInfo(arguments);
      case 'getHarmonyLegalDocuments':
        return NativeChannelHarmonyLegal.getHarmonyLegalDocuments(arguments);
      case 'getHarmonyLicensePackages':
        return NativeChannelHarmonyLegal.getHarmonyLicensePackages(arguments);
      case 'getHarmonyPackageLicenses':
        return NativeChannelHarmonyLegal.getHarmonyPackageLicenses(arguments);
      case 'openHarmonyAboutLink':
        return NativeChannelHarmonyLegal.openHarmonyAboutLink(arguments);
      case 'openHarmonyLegalDocument':
        return NativeChannelHarmonyLegal.openHarmonyLegalDocument(arguments);
      case 'copyHarmonyAboutField':
        return NativeChannelHarmonyLegal.copyHarmonyAboutField(arguments);
      case String() when method.contains('HarmonyPanel'):
        return NativeChannelHarmonyPanel.dispatch(method, arguments);
      case String() when method.startsWith('harmonyCompute/'):
        return NativeChannelHarmonyCompute.dispatch(
          method.substring('harmonyCompute/'.length),
          arguments,
        );
      case String() when method.startsWith('harmonyAutomation/'):
        return NativeChannelHarmonyAutomation.dispatch(
          method.substring('harmonyAutomation/'.length),
          arguments,
        );
      case String() when _computeMethod.hasMatch(method):
        return NativeChannelHarmonyCompute.dispatch(method, arguments);
      case String() when _automationMethod.hasMatch(method):
        return NativeChannelHarmonyAutomation.dispatch(method, arguments);
      case String() when _hostMethod.hasMatch(method):
        return NativeChannelHarmonyHost.dispatch(method, arguments);
      default:
        throw MissingPluginException(method);
    }
  }

  static final _computeMethod =
      RegExp(r'Native(Vm|Alert|Agent|ModelDownload|Mcp|Ollama)');
  static final _automationMethod = RegExp(
    r'Native(Command|Group|Script|Cronjob|Backup|LoginLog|OperationLog)',
  );
  static final _hostMethod = RegExp(
    r'Native(Host|Process|Ssh|Device|Disk|Ftp|Fail2ban|Clam|Supervisor)',
  );
}
