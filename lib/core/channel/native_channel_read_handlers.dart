import 'package:flutter/services.dart';

import 'native_channel_read_ai.dart';
import 'native_channel_read_automation.dart';
import 'native_channel_read_business.dart';
import 'native_channel_read_containers.dart';
import 'native_channel_read_core.dart';
import 'native_channel_read_data.dart';
import 'native_channel_read_model_monitor.dart';
import 'native_channel_read_operations.dart';
import 'native_channel_read_virtualization.dart';
import 'native_channel_read_website.dart';

/// 所有 Native Channel 读操作 handlers 的公开入口。
///
/// 被 [NativeChannelManager] 的 dispatch switch 调用。方法按功能域委托到
/// 实现文件，公开通道名称、方法签名与返回结构保持不变：
/// - [NativeChannelCoreHandlers]：服务器与设置、语言文案
/// - [NativeChannelDataReadHandlers]：文件浏览、仪表盘、数据库、监控、设备快照
/// - [NativeChannelContainerReadHandlers]：容器与 Compose、镜像、网络、卷、
///   容器文件、日志跟随流
/// - [NativeChannelBusinessReadHandlers]：应用与网站基础
/// - [NativeChannelOperationsReadHandlers]：日志、SSH、OpenResty、证书、
///   脚本库、防火墙
/// - [NativeChannelAutomationReadHandlers]：计划任务与备份
/// - [NativeChannelWebsiteReadHandlers]：网站深度配置
/// - [NativeChannelAIReadHandlers]：AI 模型、GPU、智能体渠道与 MCP
/// - [NativeChannelVirtualizationReadHandlers]：虚拟机与告警中心
/// - [NativeChannelModelMonitorReadHandlers]：模型下载器、监控中心、运维入口
class NativeChannelReadHandlers {
  // ── 核心域 ──────────────────────────────────────────────────────────────

  static Future<dynamic> getServers(dynamic arguments) =>
      NativeChannelCoreHandlers.getServers(arguments);

  static Future<Map<String, Object?>?> getCurrentServer() =>
      NativeChannelCoreHandlers.getCurrentServer();

  static Future<dynamic> getFiles(dynamic arguments) =>
      NativeChannelDataReadHandlers.getFiles(arguments);

  static Future<String> getUIRenderMode() =>
      NativeChannelCoreHandlers.getUIRenderMode();

  static Future<dynamic> getSettings(dynamic arguments) =>
      NativeChannelCoreHandlers.getSettings(arguments);

  static Future<dynamic> getTranslations() =>
      NativeChannelCoreHandlers.getTranslations();

  static Future<dynamic> getDashboard(dynamic arguments) =>
      NativeChannelDataReadHandlers.getDashboard(arguments);

  static Future<dynamic> getDatabases(dynamic arguments) =>
      NativeChannelDataReadHandlers.getDatabases(arguments);

  static Future<dynamic> getDeviceSnapshot(dynamic arguments) =>
      NativeChannelDataReadHandlers.getDeviceSnapshot(arguments);

  static Future<dynamic> getMonitoring(dynamic arguments) =>
      NativeChannelDataReadHandlers.getMonitoring(arguments);

  static Future<dynamic> getFileContentHandler(dynamic arguments) =>
      NativeChannelDataReadHandlers.getFileContentHandler(arguments);

  static Future<dynamic> getFavoritesHandler(dynamic arguments) =>
      NativeChannelDataReadHandlers.getFavoritesHandler(arguments);

  // ── 容器域 ──────────────────────────────────────────────────────────────

  static Future<dynamic> getContainers(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainers(arguments);

  static Future<dynamic> getContainerLogs(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerLogs(arguments);

  static Future<dynamic> startContainerLogStream(dynamic arguments) =>
      NativeChannelContainerReadHandlers.startContainerLogStream(arguments);

  static Future<dynamic> stopContainerLogStream(dynamic arguments) =>
      NativeChannelContainerReadHandlers.stopContainerLogStream(arguments);

  static Future<dynamic> getContainerImages(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerImages(arguments);

  static Future<dynamic> getContainerNetworks(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerNetworks(arguments);

  static Future<dynamic> getContainerVolumes(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerVolumes(arguments);

  static Future<dynamic> getListeningProcesses(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getListeningProcesses(arguments);

  static Future<dynamic> getContainerRepos(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerRepos(arguments);

  static Future<dynamic> getContainerTemplates(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerTemplates(arguments);

  static Future<dynamic> getContainerFiles(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerFiles(arguments);

  static Future<dynamic> getContainerFileContent(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerFileContent(arguments);

  static Future<dynamic> getContainerInspect(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getContainerInspect(arguments);

  static Future<dynamic> getComposeContent(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getComposeContent(arguments);

  static Future<dynamic> getComposeContainers(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getComposeContainers(arguments);

  static Future<dynamic> getComposeLogs(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getComposeLogs(arguments);

  static Future<dynamic> getComposes(dynamic arguments) =>
      NativeChannelContainerReadHandlers.getComposes(arguments);

  /// 由通道管理器注入同一个方法通道，供日志块回调使用。
  static void bindContainerLogChannel(MethodChannel channel) =>
      NativeChannelContainerReadHandlers.bindContainerLogChannel(channel);

  // ── 业务域 ──────────────────────────────────────────────────────────────

  static Future<dynamic> getApps(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getApps(arguments);

  static Future<dynamic> getAppInstallInfo(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getAppInstallInfo(arguments);

  static Future<dynamic> getAppInstallParams(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getAppInstallParams(arguments);

  static Future<dynamic> getAppDetailByKey(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getAppDetailByKey(arguments);

  static Future<dynamic> getAppStore(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getAppStore(arguments);

  static Future<dynamic> getAppVersions(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getAppVersions(arguments);

  static Future<dynamic> getAppInstallForm(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getAppInstallForm(arguments);

  static Future<dynamic> getWebsites(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getWebsites(arguments);

  static Future<dynamic> getWebsiteCreateOptions(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getWebsiteCreateOptions(arguments);

  static Future<dynamic> getWebsiteDetail(dynamic arguments) =>
      NativeChannelBusinessReadHandlers.getWebsiteDetail(arguments);

  static Future<dynamic> getOperationLogs(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getOperationLogs(arguments);

  static Future<dynamic> getLoginLogs(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getLoginLogs(arguments);

  static Future<dynamic> getSystemLogFiles(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getSystemLogFiles(arguments);

  static Future<dynamic> getSystemLogContent(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getSystemLogContent(arguments);

  static Future<dynamic> getTaskLogs(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getTaskLogs(arguments);

  static Future<dynamic> getTaskLogContent(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getTaskLogContent(arguments);

  static Future<dynamic> getSshInfo(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getSshInfo(arguments);

  static Future<dynamic> getSshConfig(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getSshConfig(arguments);

  static Future<dynamic> getOpenrestySnapshot(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getOpenrestySnapshot(arguments);

  static Future<dynamic> getPanelSslInfo(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getPanelSslInfo(arguments);

  static Future<dynamic> getWebsiteCertificates(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getWebsiteCertificates(arguments);

  static Future<dynamic> getScripts(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getScripts(arguments);

  static Future<dynamic> getFirewallRules(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getFirewallRules(arguments);

  static Future<dynamic> getFirewallIpRules(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getFirewallIpRules(arguments);

  static Future<dynamic> getFirewallBaseInfo(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getFirewallBaseInfo(arguments);

  static Future<dynamic> getFirewallV2Forward(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getFirewallV2Forward(arguments);

  static Future<dynamic> getFirewallV2Docker(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getFirewallV2Docker(arguments);

  static Future<dynamic> getFirewallV2Settings(dynamic arguments) =>
      NativeChannelOperationsReadHandlers.getFirewallV2Settings(arguments);

  static Future<dynamic> getCronJobs(dynamic arguments) =>
      NativeChannelAutomationReadHandlers.getCronJobs(arguments);

  static Future<dynamic> getCronJobInfo(dynamic arguments) =>
      NativeChannelAutomationReadHandlers.getCronJobInfo(arguments);

  static Future<dynamic> getCronJobRecords(dynamic arguments) =>
      NativeChannelAutomationReadHandlers.getCronJobRecords(arguments);

  static Future<dynamic> getBackups(dynamic arguments) =>
      NativeChannelAutomationReadHandlers.getBackups(arguments);

  static Future<dynamic> getBackupAccounts(dynamic arguments) =>
      NativeChannelAutomationReadHandlers.getBackupAccounts(arguments);

  static Future<dynamic> getBackupAccountOptions(dynamic arguments) =>
      NativeChannelAutomationReadHandlers.getBackupAccountOptions(arguments);

  // ── 网站深度配置域 ──────────────────────────────────────────────────────

  static Future<dynamic> getWebsiteHttpsConfig(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteHttpsConfig(arguments);

  static Future<dynamic> getWebsiteProxies(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteProxies(arguments);

  static Future<dynamic> getWebsiteRedirects(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteRedirects(arguments);

  static Future<dynamic> getWebsiteRewrite(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteRewrite(arguments);

  static Future<dynamic> getWebsiteCors(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteCors(arguments);

  static Future<dynamic> getWebsiteLeech(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteLeech(arguments);

  static Future<dynamic> getWebsiteAuths(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteAuths(arguments);

  static Future<dynamic> getWebsitePathAuths(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsitePathAuths(arguments);

  static Future<dynamic> getWebsiteProxyCache(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteProxyCache(arguments);

  static Future<dynamic> getWebsiteRealIP(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteRealIP(arguments);

  static Future<dynamic> getWebsiteStream(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteStream(arguments);

  static Future<dynamic> getWebsiteLoadBalancers(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteLoadBalancers(arguments);

  static Future<dynamic> getWebsiteDomains(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteDomains(arguments);

  static Future<dynamic> getWebsiteLogs(dynamic arguments) =>
      NativeChannelWebsiteReadHandlers.getWebsiteLogs(arguments);

  // ── 平台域 ──────────────────────────────────────────────────────────────

  static Future<dynamic> getAIModels(dynamic arguments) =>
      NativeChannelAIReadHandlers.getAIModels(arguments);

  static Future<dynamic> getGpuLoad(dynamic arguments) =>
      NativeChannelAIReadHandlers.getGpuLoad(arguments);

  static Future<dynamic> getGpuOptions(dynamic arguments) =>
      NativeChannelAIReadHandlers.getGpuOptions(arguments);

  static Future<dynamic> searchGpuHistory(dynamic arguments) =>
      NativeChannelAIReadHandlers.searchGpuHistory(arguments);

  static Future<dynamic> getAgentAccounts(dynamic arguments) =>
      NativeChannelAIReadHandlers.getAgentAccounts(arguments);

  static Future<dynamic> getAgentProviders(dynamic arguments) =>
      NativeChannelAIReadHandlers.getAgentProviders(arguments);

  static Future<dynamic> getAgentAccountModels(dynamic arguments) =>
      NativeChannelAIReadHandlers.getAgentAccountModels(arguments);

  static Future<dynamic> getMcpServers(dynamic arguments) =>
      NativeChannelAIReadHandlers.getMcpServers(arguments);

  static Future<dynamic> getMcpServerDetail(dynamic arguments) =>
      NativeChannelAIReadHandlers.getMcpServerDetail(arguments);

  static Future<dynamic> pageAgentsNative(dynamic arguments) =>
      NativeChannelAIReadHandlers.pageAgentsNative(arguments);

  static Future<dynamic> getAgentOverviewNative(dynamic arguments) =>
      NativeChannelAIReadHandlers.getAgentOverviewNative(arguments);

  static Future<dynamic> getAIBindDomain(dynamic arguments) =>
      NativeChannelAIReadHandlers.getAIBindDomain(arguments);

  static Future<dynamic> getVmEnvironment(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmEnvironment(arguments);

  static Future<dynamic> getVms(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVms(arguments);

  static Future<dynamic> getVmInfo(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmInfo(arguments);

  static Future<dynamic> getVmSnapshots(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmSnapshots(arguments);

  static Future<dynamic> getVmHealth(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmHealth(arguments);

  static Future<dynamic> getVmStats(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmStats(arguments);

  static Future<dynamic> getVmIsos(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmIsos(arguments);

  static Future<dynamic> getVmTemplates(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmTemplates(arguments);

  static Future<dynamic> getVmNetworks(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmNetworks(arguments);

  static Future<dynamic> getVmNetworkOptions(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmNetworkOptions(arguments);

  static Future<dynamic> getVmStorages(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getVmStorages(arguments);

  static Future<dynamic> getAlertRules(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getAlertRules(arguments);

  static Future<dynamic> getAlertLogs(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getAlertLogs(arguments);

  static Future<dynamic> getAlertChannels(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getAlertChannels(arguments);

  static Future<dynamic> getAlertOptions(dynamic arguments) =>
      NativeChannelVirtualizationReadHandlers.getAlertOptions(arguments);

  static Future<dynamic> getModelDownloaderFeatured(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getModelDownloaderFeatured(arguments);

  static Future<dynamic> getModelDownloaderSearch(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getModelDownloaderSearch(arguments);

  static Future<dynamic> getModelDownloaderTasks(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getModelDownloaderTasks(arguments);

  static Future<dynamic> getModelDownloaderLocal(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getModelDownloaderLocal(arguments);

  static Future<dynamic> getModelDownloaderSettings(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getModelDownloaderSettings(arguments);

  static Future<dynamic> getModelDownloaderOptions(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getModelDownloaderOptions(arguments);

  static Future<dynamic> getMonitoringHistory(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getMonitoringHistory(arguments);

  static Future<dynamic> getMonitoringSettings(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getMonitoringSettings(arguments);

  static Future<dynamic> getMonitoringOptions(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getMonitoringOptions(arguments);

  static Future<dynamic> getRuntimes(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getRuntimes(arguments);

  static Future<dynamic> getToolboxDiskSnapshot(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getToolboxDiskSnapshot(arguments);

  static Future<dynamic> getHostAssets(dynamic arguments) =>
      NativeChannelModelMonitorReadHandlers.getHostAssets(arguments);
}