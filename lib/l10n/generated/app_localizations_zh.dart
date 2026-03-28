// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '1Panel Client';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonRetry => '重试';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonClose => '关闭';

  @override
  String get commonCopy => '复制';

  @override
  String get commonImport => '导入';

  @override
  String get commonExport => '导出';

  @override
  String get commonMore => '更多';

  @override
  String get commonAdd => '添加';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonLoad => '加载';

  @override
  String get commonSave => '保存';

  @override
  String get commonSaveSuccess => '保存成功';

  @override
  String get commonSaveFailed => '保存失败';

  @override
  String get commonDelete => '删除';

  @override
  String get commonUpload => '上传';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonReset => '重置';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get commonComingSoon => '即将支持';

  @override
  String get commonEmpty => '暂无数据';

  @override
  String get commonLoadFailedTitle => '加载失败';

  @override
  String get websitesPageTitle => '网站管理';

  @override
  String get websitesStatsTitle => '网站统计';

  @override
  String get websitesStatsTotal => '总数';

  @override
  String get websitesStatsRunning => '运行中';

  @override
  String get websitesStatsStopped => '已停止';

  @override
  String get websitesEmptyTitle => '暂无网站';

  @override
  String get websitesEmptySubtitle => '请先在 1Panel 中创建网站。';

  @override
  String get websitesUnknownDomain => '未知网站';

  @override
  String get websitesStatusLabel => '状态';

  @override
  String get websitesTypeLabel => '类型';

  @override
  String get websitesStatusRunning => '运行中';

  @override
  String get websitesStatusStopped => '已停止';

  @override
  String get websitesActionStart => '启动';

  @override
  String get websitesActionStop => '停止';

  @override
  String get websitesActionRestart => '重启';

  @override
  String get websitesActionDelete => '删除';

  @override
  String get websitesSetDefaultAction => '设为默认站点';

  @override
  String get websitesDefaultServerLabel => '默认站点';

  @override
  String get websitesGroupLabel => '分组';

  @override
  String get websitesRemarkLabel => '备注';

  @override
  String get websitesAliasLabel => '别名';

  @override
  String get websitesPrimaryDomainLabel => '主域名';

  @override
  String get websitesProxyAddressLabel => '代理地址';

  @override
  String get websitesProxyTypeLabel => '代理类型';

  @override
  String get websitesParentWebsiteLabel => '父站点';

  @override
  String get websitesSiteDirLabel => '站点目录';

  @override
  String get websitesFilterAllGroups => '全部分组';

  @override
  String get websitesFilterAllTypes => '全部类型';

  @override
  String get websitesSelectionEnable => '选择';

  @override
  String get websitesSelectionDisable => '取消选择';

  @override
  String get websitesSetGroupAction => '设置分组';

  @override
  String get websitesLifecycleCreateTitle => '创建网站';

  @override
  String get websitesLifecycleEditTitle => '编辑网站';

  @override
  String get websitesLifecycleTypeLabel => '网站类型';

  @override
  String get websitesLifecycleTypeRuntime => '运行时';

  @override
  String get websitesLifecycleTypeProxy => '反向代理';

  @override
  String get websitesLifecycleTypeSubsite => '子站点';

  @override
  String get websitesLifecycleTypeStatic => '静态站点';

  @override
  String get websitesValidationGroupRequired => '请选择网站分组。';

  @override
  String get websitesValidationPrimaryDomainRequired => '请输入主域名。';

  @override
  String get websitesValidationAliasRequired => '请输入别名。';

  @override
  String get websitesValidationRuntimeRequired => '请选择运行时。';

  @override
  String get websitesValidationProxyRequired => '请输入代理地址。';

  @override
  String get websitesValidationParentRequired => '请选择父站点。';

  @override
  String get websitesOperateSuccess => '操作成功';

  @override
  String get websitesOperateFailed => '操作失败';

  @override
  String websitesSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String websitesLoadFailedMessage(String error) {
    return '$error';
  }

  @override
  String get websitesDefaultName => 'default';

  @override
  String get websitesDeleteTitle => '删除网站';

  @override
  String websitesDeleteMessage(String domain) {
    return '确定要删除 $domain 吗？此操作不可撤销。';
  }

  @override
  String get websitesDeleteSuccess => '网站已删除';

  @override
  String websitesBatchDeleteMessage(int count) {
    return '确定删除 $count 个网站吗？此操作不可撤销。';
  }

  @override
  String get websitesDetailTitle => '网站';

  @override
  String get websitesTabOverview => '概览';

  @override
  String get websitesTabConfig => '配置';

  @override
  String get websitesTabDomains => '域名';

  @override
  String get websitesTabSsl => 'SSL';

  @override
  String get websitesTabRewrite => '伪静态';

  @override
  String get websitesTabProxy => '反向代理';

  @override
  String get websitesSslInfoTitle => '证书';

  @override
  String get websitesSslNoCert => '未绑定证书';

  @override
  String get websitesSslPrimaryDomain => '主域名';

  @override
  String get websitesSslExpireDate => '到期时间';

  @override
  String get websitesSslStatus => '状态';

  @override
  String get websitesSslAutoRenew => '自动续期';

  @override
  String get websitesSslDownload => '下载';

  @override
  String get websitesConfigHint => 'Nginx 配置内容';

  @override
  String get websitesJsonHint => 'JSON 内容';

  @override
  String get websitesDomainAddTitle => '添加域名';

  @override
  String get websitesDomainEditTitle => '编辑域名';

  @override
  String get websitesDomainLabel => '域名';

  @override
  String get websitesDomainEmpty => '暂无域名';

  @override
  String get websitesDomainDefault => '默认';

  @override
  String get websitesDomainSslLabel => 'SSL';

  @override
  String get websitesDomainValidationRequired => '请输入域名。';

  @override
  String get websitesDomainValidationPort => '端口必须在 1 到 65535 之间。';

  @override
  String get websitesDomainValidationDuplicate => '该域名已存在。';

  @override
  String websitesDomainDeleteMessage(String domain) {
    return '确定删除域名 $domain 吗？';
  }

  @override
  String get websitesRewriteNameLabel => '规则名称';

  @override
  String get websitesRewriteHint => '伪静态内容';

  @override
  String get websitesProxyNameLabel => '代理名称';

  @override
  String get websitesProxyHint => '代理内容';

  @override
  String get websitesNginxAdvancedAction => '高级配置';

  @override
  String get websitesNginxAdvancedTitle => 'Nginx 高级配置';

  @override
  String get websitesNginxScopeTitle => '范围读取';

  @override
  String get websitesNginxScopeLabel => '范围';

  @override
  String get websitesNginxScopeWebsiteIdLabel => '网站 ID（可选）';

  @override
  String get websitesNginxScopeLoad => '加载范围配置';

  @override
  String get websitesNginxScopeResultLabel => '范围结果';

  @override
  String get websitesNginxUpdateTitle => '范围更新';

  @override
  String get websitesNginxUpdateOperateLabel => '操作类型';

  @override
  String get websitesNginxUpdateScopeLabel => '范围';

  @override
  String get websitesNginxUpdateWebsiteIdLabel => '网站 ID（可选）';

  @override
  String get websitesNginxUpdateParamsLabel => '参数 JSON';

  @override
  String get websitesNginxUpdateAction => '提交更新';

  @override
  String get websitesProtocolLabel => '协议';

  @override
  String get websitesDetailInfoTitle => '站点信息';

  @override
  String get websitesSitePathLabel => '站点路径';

  @override
  String get websitesRuntimeLabel => '运行环境';

  @override
  String get websitesSslStatusLabel => 'SSL 状态';

  @override
  String get websitesSslExpireLabel => 'SSL 到期';

  @override
  String get websitesDetailActionsTitle => '快捷操作';

  @override
  String get websitesConfigPageTitle => '配置管理';

  @override
  String get websitesConfigPageSubtitle => 'Nginx 配置与 PHP 版本';

  @override
  String get websitesBasicConfigTitle => '基础配置';

  @override
  String get websitesBasicConfigDatabaseTitle => '数据库绑定';

  @override
  String get websitesDomainsPageTitle => '域名管理';

  @override
  String get websitesDomainsPageSubtitle => '绑定与维护站点域名';

  @override
  String get websitesSslPageTitle => 'SSL 证书';

  @override
  String get websitesSslPageSubtitle => '证书配置与 HTTPS';

  @override
  String get websitesOpenrestySubtitle => '服务状态与模块管理';

  @override
  String get websitesConfigEditorTitle => 'Nginx 配置文件';

  @override
  String get websitesConfigScopeTitle => '高级配置';

  @override
  String get websitesConfigScopeLabel => '配置范围';

  @override
  String get websitesConfigScopeEmpty => '暂无范围配置';

  @override
  String websitesConfigScopeEditTitle(String name) {
    return '编辑 $name 参数';
  }

  @override
  String get websitesConfigScopeValuesLabel => '参数列表';

  @override
  String get websitesConfigScopeValuesHint => '使用逗号分隔多个参数';

  @override
  String get websitesPhpVersionTitle => 'PHP 版本切换';

  @override
  String get websitesPhpRuntimeIdLabel => '运行时 ID';

  @override
  String get websitesPhpRuntimeIdHint => '请输入要切换的 runtimeID';

  @override
  String get websitesDomainPortLabel => '端口';

  @override
  String get websitesDomainPrimary => '主域名';

  @override
  String get websitesSslCreateAction => '创建证书';

  @override
  String get websitesSslUploadAction => '上传证书';

  @override
  String get websitesSslListTitle => '证书列表';

  @override
  String get websitesSslListEmpty => '暂无证书';

  @override
  String get websitesSslApplyAction => '申请证书';

  @override
  String get websitesSslResolveAction => '解析证书';

  @override
  String get websitesSslUpdateAction => '更新证书';

  @override
  String get websitesSslDeleteTitle => '删除证书';

  @override
  String websitesSslDeleteMessage(String domain) {
    return '确定删除 $domain 的证书吗？';
  }

  @override
  String get websitesSslAcmeAccountIdLabel => 'ACME 账户 ID';

  @override
  String get websitesSslProviderLabel => '证书提供商';

  @override
  String get websitesSslOtherDomainsLabel => '其他域名（逗号分隔）';

  @override
  String get websitesSslDisableLogLabel => '禁用日志';

  @override
  String get websitesSslSkipDnsCheckLabel => '跳过 DNS 校验';

  @override
  String get websitesSslNameserversLabel => 'Nameserver 列表';

  @override
  String get websitesSslDescriptionLabel => '描述';

  @override
  String get websitesSslUploadTypeLabel => '上传方式';

  @override
  String get websitesSslUploadTypePaste => '粘贴内容';

  @override
  String get websitesSslUploadTypeLocal => '本地路径';

  @override
  String get websitesSslCertificateLabel => '证书内容';

  @override
  String get websitesSslPrivateKeyLabel => '私钥内容';

  @override
  String get websitesSslCertificatePathLabel => '证书路径';

  @override
  String get websitesSslPrivateKeyPathLabel => '私钥路径';

  @override
  String get websitesHttpsConfigTitle => 'HTTPS 配置';

  @override
  String get websitesHttpsEnableLabel => '启用 HTTPS';

  @override
  String get websitesHttpsModeLabel => 'HTTP 配置模式';

  @override
  String get websitesHttpsTypeLabel => '证书类型';

  @override
  String get websitesHttpsSslIdLabel => '证书 ID';

  @override
  String get websitesSslAutoRenewMissingFields => '证书缺少主域名或提供商信息，无法更新自动续期。';

  @override
  String websitesSslDownloadHint(String link) {
    return '证书下载链接：$link';
  }

  @override
  String get websitesSslExpirationViewTitle => '到期视图';

  @override
  String websitesSslFilterAllCount(int count) {
    return '全部（$count）';
  }

  @override
  String websitesSslFilterExpiredCount(int count) {
    return '已过期（$count）';
  }

  @override
  String websitesSslFilterWithin7DaysCount(int count) {
    return '7 天内到期（$count）';
  }

  @override
  String websitesSslFilterWithin30DaysCount(int count) {
    return '30 天内到期（$count）';
  }

  @override
  String websitesSslAffectedWebsitesCount(int count) {
    return '受影响网站：$count';
  }

  @override
  String websitesSslAffectedWebsitesDomains(String domains) {
    return '受影响域名：$domains';
  }

  @override
  String get websitesSslImpactHintApply => '立即将该证书应用到已绑定网站吗？';

  @override
  String get websitesSslImpactWarningHigh => '该操作会影响多个网站，请先确认维护窗口。';

  @override
  String get websitesSslNoAffectedWebsites => '暂无绑定网站。';

  @override
  String get websitesSslOpenBoundSiteAction => '打开绑定站点';

  @override
  String get websitesSslGroupAll => '全部证书';

  @override
  String get websitesSslGroupExpired => '已过期';

  @override
  String get websitesSslGroupWithin7Days => '7 天内到期';

  @override
  String get websitesSslGroupWithin30Days => '30 天内到期';

  @override
  String get websitesSslGroupHealthy => '健康';

  @override
  String get websitesSslProviderFilterAll => '全部提供商';

  @override
  String get websitesSslHealthHealthy => '健康';

  @override
  String get websitesSslHealthExpiringSoon => '即将过期';

  @override
  String get websitesSslHealthExpired => '已过期';

  @override
  String get websitesSslHealthUnknown => '未知';

  @override
  String get openrestyPageTitle => 'OpenResty';

  @override
  String get openrestyTabStatus => '状态';

  @override
  String get openrestyTabHttps => 'HTTPS';

  @override
  String get openrestyTabModules => '模块';

  @override
  String get openrestyTabConfig => '配置';

  @override
  String get openrestyTabBuild => '构建';

  @override
  String get openrestyTabScope => '范围';

  @override
  String get openrestyBuildMirrorLabel => '构建镜像地址';

  @override
  String get openrestyBuildTaskIdLabel => '任务 ID';

  @override
  String get openrestyBuildAction => '构建 OpenResty';

  @override
  String get openrestyScopeLabel => '配置范围';

  @override
  String get openrestyScopeWebsiteIdLabel => '网站 ID（可选）';

  @override
  String get openrestyScopeLoad => '加载范围配置';

  @override
  String get openrestyScopeResultHint => '范围配置结果';

  @override
  String get openrestyAdvancedSourceEditorTooltip => '高级源码编辑器';

  @override
  String get openrestyRiskBannerTitle => '网关风险提示';

  @override
  String get openrestyRunningStatusLabel => '运行状态';

  @override
  String get openrestyBuildVersionLabel => '构建 / 版本';

  @override
  String get openrestyCoreSummaryLabel => '核心摘要';

  @override
  String get openrestyHttpsSummaryLabel => 'HTTPS 摘要';

  @override
  String get openrestyModulesSummaryLabel => '模块摘要';

  @override
  String get openrestyCurrentStateLabel => '当前状态';

  @override
  String get openrestyRejectHandshakeLabel => '拒绝握手';

  @override
  String get openrestyEditHttpsAction => '编辑 HTTPS';

  @override
  String get openrestyPreviewDiffAction => '预览差异';

  @override
  String get openrestyRollbackAction => '回滚';

  @override
  String get openrestyHttpsDiffPreviewTitle => 'HTTPS 差异预览';

  @override
  String get openrestyUnnamedModule => '未命名模块';

  @override
  String get openrestyNoModulesReturned => '网关未返回任何模块。';

  @override
  String get openrestyModuleDiffPreviewTitle => '模块差异预览';

  @override
  String get openrestyCurrentConfigLabel => '当前配置';

  @override
  String get openrestyAdvancedAction => '高级';

  @override
  String get openrestyConfigDiffPreviewTitle => '配置差异预览';

  @override
  String get openrestyBuildLastResultLabel => '最近结果';

  @override
  String get openrestyBuildNoRecentAction => '暂无最近构建操作';

  @override
  String get openrestyBuildStartAction => '开始构建';

  @override
  String get openrestyStatusNotRunningSummary => '未运行';

  @override
  String openrestyStatusRunningSummary(int active) {
    return '运行中 · active $active';
  }

  @override
  String get openrestyHttpsEnabledSummary => 'HTTPS 已启用';

  @override
  String get openrestyHttpsDisabledSummary => 'HTTPS 已禁用';

  @override
  String openrestyModulesEnabledSummary(int enabled, int total) {
    return '已启用模块 $enabled/$total';
  }

  @override
  String get openrestyBuildNoMirrorConfigured => '未配置构建镜像地址';

  @override
  String get openrestyConfigNotLoaded => '配置未加载';

  @override
  String openrestyConfigLoadedSummary(int lines) {
    return '已加载 $lines 行';
  }

  @override
  String get openrestyDialogUpdateHttpsTitle => '更新 HTTPS';

  @override
  String get openrestyDialogEnableHttpsLabel => '启用 HTTPS';

  @override
  String get openrestyDialogRejectInvalidHandshakesLabel => '拒绝无效握手';

  @override
  String get openrestyDialogModuleTitleFallback => '模块';

  @override
  String get openrestyDialogEnableModuleLabel => '启用模块';

  @override
  String get openrestyDialogPackagesLabel => '依赖包';

  @override
  String get openrestyDialogParamsLabel => '参数';

  @override
  String get openrestyDialogScriptLabel => '脚本';

  @override
  String get openrestyDialogPreviewConfigTitle => '预览配置变更';

  @override
  String get openrestyDialogConfigSourceLabel => '配置源码';

  @override
  String get openrestyDialogStartBuildTitle => '开始构建 OpenResty';

  @override
  String get openrestyDialogBuildRiskHint => '构建会刷新网关二进制与模块依赖，请在生产节点执行前再次确认。';

  @override
  String get openrestyBuildSubmittedMessage => '构建请求已提交';

  @override
  String openrestyBuildSubmittedWithMirrorMessage(String mirror) {
    return '已使用镜像 $mirror 提交构建请求。';
  }

  @override
  String get openrestyRiskGatewayInactiveTitle => '网关未激活';

  @override
  String get openrestyRiskGatewayInactiveMessage => 'OpenResty 当前未上报活动连接。';

  @override
  String get openrestyRiskHttpsDisabledTitle => 'HTTPS 已禁用';

  @override
  String get openrestyRiskHttpsDisabledMessage => '禁用 HTTPS 会降低网关默认安全基线。';

  @override
  String get openrestyRiskNoModulesTitle => '未加载模块';

  @override
  String get openrestyRiskNoModulesMessage => 'OpenResty 模块列表为空，请检查构建与模块配置。';

  @override
  String get openrestyRiskBuildMirrorMissingTitle => '缺少构建镜像地址';

  @override
  String get openrestyRiskBuildMirrorMissingMessage => '当前未配置构建镜像地址，可能影响构建速度。';

  @override
  String get openrestyRiskRejectHandshakeTitle => '已启用拒绝握手';

  @override
  String get openrestyRiskRejectHandshakeMessage => '这可能阻止 TLS 协商配置不正确的客户端。';

  @override
  String get openrestyRiskModuleDisabledTitle => '模块已禁用';

  @override
  String openrestyRiskModuleDisabledMessage(String module) {
    return '禁用 $module 可能立即改变网关行为。';
  }

  @override
  String get openrestyRiskDependencyChangeTitle => '依赖变更';

  @override
  String openrestyRiskDependencyChangeMessage(String module) {
    return '依赖包或脚本变更可能为 $module 引入依赖冲突。';
  }

  @override
  String get openrestyRiskEmptyConfigTitle => '配置为空';

  @override
  String get openrestyRiskEmptyConfigMessage => '保存空配置会破坏当前网关配置。';

  @override
  String get openrestyRiskBraceMismatchTitle => '括号不匹配';

  @override
  String get openrestyRiskBraceMismatchMessage => '配置中可能存在未匹配的大括号，请先校验。';

  @override
  String get openrestyRiskMissingHttpBlockTitle => '缺少 http 块';

  @override
  String get openrestyRiskMissingHttpBlockMessage => '在配置源码中未检测到 http 块。';

  @override
  String get openrestyRiskTemporaryMarkersTitle => '存在临时标记';

  @override
  String get openrestyRiskTemporaryMarkersMessage => '配置中仍包含 TODO 或 FIXME 标记。';

  @override
  String get openrestyDiffLabelHttps => 'HTTPS';

  @override
  String get openrestyDiffLabelRejectHandshake => '拒绝握手';

  @override
  String get openrestyDiffLabelEnabled => '启用';

  @override
  String get openrestyDiffLabelPackages => '依赖包';

  @override
  String get openrestyDiffLabelParams => '参数';

  @override
  String get openrestyDiffLabelScript => '脚本';

  @override
  String get openrestyDiffLabelConfigSource => '配置源码';

  @override
  String get monitorNetworkLabel => '网络';

  @override
  String get monitorMetricCurrent => '当前';

  @override
  String get monitorMetricMin => '最小';

  @override
  String get monitorMetricAvg => '平均';

  @override
  String get monitorMetricMax => '最大';

  @override
  String get navServer => '服务器';

  @override
  String get navFiles => '文件';

  @override
  String get navSecurity => '安全';

  @override
  String get navSettings => '设置';

  @override
  String noServerSelectedTitle(String module) {
    return '$module 需要先选择服务器';
  }

  @override
  String get noServerSelectedDescription => '请先选择当前服务器，再进入该模块。';

  @override
  String get shellPinnedModulesTitle => '底部标签';

  @override
  String get shellPinnedModulesDescription => '选择 2 个模块固定到底部标签栏，其他模块保留在“更多”中。';

  @override
  String get shellPinnedModulesCustomize => '调整标签栏';

  @override
  String get shellPinnedModulesPrimary => '标签 1';

  @override
  String get shellPinnedModulesSecondary => '标签 2';

  @override
  String get moduleSubnavCustomize => '自定义分区';

  @override
  String moduleSubnavHint(int count) {
    return '前 $count 项固定显示，其余进入“更多”。';
  }

  @override
  String get moduleSubnavVisible => '直接显示';

  @override
  String get moduleSubnavHidden => '收纳到更多';

  @override
  String get serverPageTitle => '服务器';

  @override
  String get serverSearchHint => '请输入服务器名称或 IP';

  @override
  String get serverAdd => '添加';

  @override
  String get serverListEmptyTitle => '暂无服务器';

  @override
  String get serverListEmptyDesc => '先添加一个 1Panel 服务器开始使用。';

  @override
  String get serverOnline => '在线';

  @override
  String get serverOffline => '离线';

  @override
  String get serverCurrent => '当前';

  @override
  String get serverDefault => '默认';

  @override
  String get serverIpLabel => 'IP';

  @override
  String get serverCpuLabel => 'CPU';

  @override
  String get serverMemoryLabel => '内存';

  @override
  String get serverLoadLabel => '负载';

  @override
  String get serverDiskLabel => '磁盘';

  @override
  String get serverMetricsUnavailable => '监控数据暂不可用';

  @override
  String get serverOpenDetail => '查看详情';

  @override
  String get serverDetailTitle => '服务器详情';

  @override
  String get serverModulesTitle => '功能模块';

  @override
  String get serverModuleDashboard => '概览';

  @override
  String get serverModuleApps => '应用';

  @override
  String get serverModuleContainers => '容器';

  @override
  String get serverModuleWebsites => '网站';

  @override
  String get serverModuleAi => 'AI';

  @override
  String get aiTabModels => '模型';

  @override
  String get aiTabGpu => 'GPU';

  @override
  String get aiTabDomain => '域名';

  @override
  String get aiModelCreate => '创建模型';

  @override
  String get aiModelSync => '同步模型';

  @override
  String get aiModelRecreate => '重新创建模型';

  @override
  String get aiModelNameLabel => '模型名称';

  @override
  String get aiTaskIdOptional => '任务 ID（可选）';

  @override
  String get aiModelNameRequired => '请输入模型名称';

  @override
  String get aiForceDelete => '强制删除';

  @override
  String get aiOperationSuccess => '操作成功';

  @override
  String aiOperationFailed(String error) {
    return '操作失败：$error';
  }

  @override
  String get aiOperationResult => '操作结果';

  @override
  String get aiNoGpuData => '暂无 GPU 数据';

  @override
  String get aiFanSpeed => '风扇速度';

  @override
  String get aiPowerUsage => '功耗';

  @override
  String get aiPerformanceState => '性能状态';

  @override
  String get aiDomainHint => '配置 Ollama 域名绑定。请先输入 appInstallID，再加载或提交绑定信息。';

  @override
  String get aiAppInstallIdLabel => '应用安装 ID';

  @override
  String get aiAppInstallIdRequired => '请输入应用安装 ID';

  @override
  String get aiIpAllowListLabel => 'IP 白名单';

  @override
  String get aiSslIdOptionalLabel => 'SSL ID（可选）';

  @override
  String get aiWebsiteIdOptionalLabel => '网站 ID（可选）';

  @override
  String get aiLoadBinding => '加载当前绑定';

  @override
  String get aiBindDomain => '绑定域名';

  @override
  String get aiCurrentBinding => '当前绑定';

  @override
  String get aiConnUrl => '连接地址';

  @override
  String get containerSystemProtectedNetwork => '系统网络不可删除';

  @override
  String get serverModuleDatabases => '数据库';

  @override
  String get serverModuleFirewall => '防火墙';

  @override
  String get databaseMysqlTab => 'MySQL';

  @override
  String get databasePostgresqlTab => 'PostgreSQL';

  @override
  String get databaseRedisTab => 'Redis';

  @override
  String get databaseRemoteTab => '远程';

  @override
  String get databaseOverviewTitle => '概览';

  @override
  String get databaseConfigTitle => '配置文件';

  @override
  String get databaseBaseInfoTitle => '基础信息';

  @override
  String get databaseStatusTitle => '状态';

  @override
  String get databaseVariablesTitle => '变量';

  @override
  String get databaseScopeLabel => '数据库范围';

  @override
  String get databaseEngineLabel => '引擎';

  @override
  String get databaseSourceLabel => '来源';

  @override
  String get databaseAddressLabel => '地址';

  @override
  String get databasePortLabel => '端口';

  @override
  String get databaseContainerLabel => '容器';

  @override
  String get databaseUsernameLabel => '用户名';

  @override
  String get databasePasswordLabel => '密码';

  @override
  String get databaseRemoteAccessLabel => '远程访问';

  @override
  String get databaseChangePasswordAction => '修改密码';

  @override
  String get databaseBindUserAction => '绑定用户';

  @override
  String get databaseTestConnectionAction => '测试连接';

  @override
  String get databaseRedisConfigTitle => 'Redis 配置';

  @override
  String get databaseRedisTimeoutLabel => '超时时间';

  @override
  String get databaseRedisMaxClientsLabel => '最大客户端数';

  @override
  String get databaseRedisPersistenceTitle => 'Redis 持久化';

  @override
  String get databaseRedisAppendOnlyLabel => '仅追加模式';

  @override
  String get databaseRedisSaveLabel => '保存策略';

  @override
  String get databaseManageTitle => '管理';

  @override
  String get databaseBackupsPageTitle => '备份';

  @override
  String get databaseUsersPageTitle => '用户';

  @override
  String get databaseBackupCreateAction => '创建备份';

  @override
  String get databaseBackupRestoreAction => '恢复备份';

  @override
  String get databaseBackupDeleteAction => '删除备份';

  @override
  String get databaseBackupSecretLabel => '压缩密码';

  @override
  String get databaseBackupEmpty => '暂无备份记录。';

  @override
  String get databaseBackupUnsupported => '当前数据库类型不支持备份。';

  @override
  String get databaseBackupRestoreConfirmMessage => '确定恢复此备份记录吗？现有数据可能被覆盖。';

  @override
  String get databaseBackupDeleteConfirmMessage => '确定删除此备份记录吗？此操作不可恢复。';

  @override
  String get databaseUserCurrentLabel => '当前用户';

  @override
  String get databaseUserPermissionLabel => '权限';

  @override
  String get databaseUserSuperUserLabel => '超级用户';

  @override
  String get databaseUserBindAction => '绑定用户';

  @override
  String get databaseUserPrivilegesAction => '更新权限';

  @override
  String get databaseUserNoBinding => '暂无已绑定用户信息。';

  @override
  String get databaseUserUnsupported => '当前数据库类型不支持用户管理。';

  @override
  String get databasePrivilegeUnavailable => '绑定用户后才可调整权限。';

  @override
  String get firewallTabStatus => '状态';

  @override
  String get firewallTabRules => '规则';

  @override
  String get firewallTabIps => 'IP';

  @override
  String get firewallTabPorts => '端口';

  @override
  String get firewallNameLabel => '名称';

  @override
  String get firewallVersionLabel => '版本';

  @override
  String get firewallPingLabel => 'Ping';

  @override
  String get firewallActiveLabel => '启用';

  @override
  String get firewallInitLabel => '已初始化';

  @override
  String get firewallBoundLabel => '已绑定';

  @override
  String get firewallProtocolLabel => '协议';

  @override
  String get firewallAddressLabel => '地址';

  @override
  String get firewallStrategyLabel => '策略';

  @override
  String get firewallPortLabel => '端口';

  @override
  String get firewallFamilyLabel => '族';

  @override
  String get firewallSourcePortLabel => '源端口';

  @override
  String get firewallDestinationPortLabel => '目标端口';

  @override
  String get firewallRuleDefaultTitle => '规则';

  @override
  String get firewallUnknownStrategy => '未知';

  @override
  String get firewallSourceLabel => '来源';

  @override
  String get firewallSourceAnywhere => '任意位置';

  @override
  String get firewallSourceAddress => '指定地址';

  @override
  String get firewallStrategyAccept => '允许';

  @override
  String get firewallStrategyDrop => '拒绝';

  @override
  String get firewallStrategyAll => '全部';

  @override
  String get firewallSearchHint => '按描述、地址或端口搜索';

  @override
  String get firewallSelectionModeEnable => '选择';

  @override
  String get firewallSelectionModeDisable => '完成';

  @override
  String get firewallBatchDeleteAction => '批量删除';

  @override
  String get firewallBatchAcceptAction => '批量允许';

  @override
  String get firewallBatchDropAction => '批量拒绝';

  @override
  String firewallSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get firewallCreatePortRuleAction => '创建端口规则';

  @override
  String get firewallCreateIpRuleAction => '创建 IP 规则';

  @override
  String get firewallToggleStrategyAction => '切换策略';

  @override
  String get firewallOperationConfirmTitle => '确认防火墙变更';

  @override
  String get firewallStartConfirmMessage => '确定启动防火墙服务吗？新规则会立即开始生效。';

  @override
  String get firewallStopConfirmMessage => '确定停止防火墙服务吗？这可能导致服务暴露在无包过滤状态下。';

  @override
  String get firewallRestartConfirmMessage => '确定重启防火墙服务吗？现有连接可能会短暂中断。';

  @override
  String get firewallAddressRequired => '请输入地址。';

  @override
  String get firewallPortRequired => '请输入端口。';

  @override
  String get serverModuleTerminal => '终端';

  @override
  String get serverModuleMonitoring => '监控';

  @override
  String get serverModuleFiles => '文件管理';

  @override
  String get serverInsightsTitle => '运行概览';

  @override
  String get serverActionsTitle => '快捷操作';

  @override
  String get serverActionRefresh => '刷新';

  @override
  String get serverActionSwitch => '切换服务器';

  @override
  String get serverActionSecurity => '安全';

  @override
  String get serverFormTitle => '添加服务器';

  @override
  String get serverFormName => '服务器名称';

  @override
  String get serverFormNameHint => '例如：生产环境';

  @override
  String get serverFormUrl => '服务器地址';

  @override
  String get serverFormUrlHint => '例如：https://panel.example.com';

  @override
  String get serverFormApiKey => 'API 密钥';

  @override
  String get serverFormApiKeyHint => '请输入 API 密钥';

  @override
  String get serverFormSaveConnect => '保存并继续';

  @override
  String get serverFormTest => '测试连接';

  @override
  String get serverFormRequired => '该字段不能为空';

  @override
  String get serverFormSaveSuccess => '服务器已保存';

  @override
  String serverFormSaveFailed(String error) {
    return '保存服务器失败：$error';
  }

  @override
  String get serverFormTestHint => '连接测试可在 client 适配后接入。';

  @override
  String get serverTestSuccess => '连接成功';

  @override
  String get serverTestFailed => '连接失败';

  @override
  String get serverTestTesting => '正在测试连接...';

  @override
  String get serverMetricsAvailable => '监控数据已加载';

  @override
  String get serverTokenValidity => '接口密钥有效期';

  @override
  String get serverTokenValidityHint => '设置为0时不校验时间戳';

  @override
  String get serverFormMinutes => '分钟';

  @override
  String get filesPageTitle => '文件';

  @override
  String get filesPath => '路径';

  @override
  String get filesRoot => '根目录';

  @override
  String get filesNavigateUp => '返回上级';

  @override
  String get filesEmptyTitle => '此文件夹为空';

  @override
  String get filesEmptyDesc => '点击下方按钮创建新文件或文件夹。';

  @override
  String get filesActionUpload => '上传';

  @override
  String get filesActionNewFile => '新建文件';

  @override
  String get filesActionNewFolder => '新建文件夹';

  @override
  String get filesActionNew => '新建';

  @override
  String get filesActionOpen => '打开';

  @override
  String get filesActionDownload => '下载';

  @override
  String get filesActionRename => '重命名';

  @override
  String get filesActionCopy => '复制';

  @override
  String get filesActionMove => '移动';

  @override
  String get filesActionExtract => '解压';

  @override
  String get filesActionCompress => '压缩';

  @override
  String get filesActionDelete => '删除';

  @override
  String get filesActionSelectAll => '全选';

  @override
  String get filesActionDeselect => '取消选择';

  @override
  String get filesActionSort => '排序';

  @override
  String get filesActionSearch => '搜索';

  @override
  String get filesNameLabel => '名称';

  @override
  String get filesNameHint => '输入名称';

  @override
  String get filesTargetPath => '目标路径';

  @override
  String get filesTypeDirectory => '目录';

  @override
  String get filesSelected => '已选择';

  @override
  String get filesSelectPath => '选择路径';

  @override
  String get filesCurrentFolder => '当前文件夹';

  @override
  String get filesNoSubfolders => '没有子文件夹';

  @override
  String get filesPathSelectorTitle => '选择目标路径';

  @override
  String get filesDeleteTitle => '删除文件';

  @override
  String filesDeleteConfirm(int count) {
    return '确定删除选中的 $count 个项目？';
  }

  @override
  String get filesSortByName => '按名称排序';

  @override
  String get filesSortBySize => '按大小排序';

  @override
  String get filesSortByDate => '按日期排序';

  @override
  String get filesSearchHint => '搜索文件';

  @override
  String get filesSearchClear => '清除';

  @override
  String get filesRecycleBin => '回收站';

  @override
  String get filesCopyFailed => '复制失败';

  @override
  String get filesMoveFailed => '移动失败';

  @override
  String get filesRenameFailed => '重命名失败';

  @override
  String get filesDeleteFailed => '删除失败';

  @override
  String get filesCompressFailed => '压缩失败';

  @override
  String get filesExtractFailed => '解压失败';

  @override
  String get filesCreateFailed => '创建失败';

  @override
  String get filesDownloadFailed => '下载失败';

  @override
  String get filesDownloadSuccess => '下载成功';

  @override
  String filesDownloadProgress(int progress) {
    return '下载中 $progress%';
  }

  @override
  String get filesDownloadCancelled => '下载已取消';

  @override
  String filesDownloadSaving(String path) {
    return '正在保存到: $path';
  }

  @override
  String get filesOperationSuccess => '操作成功';

  @override
  String get filesCompressType => '类型';

  @override
  String get filesUploadDeveloping => '上传功能需要进一步开发';

  @override
  String get commonCreate => '创建';

  @override
  String get commonName => '名称';

  @override
  String get commonUsername => '用户名';

  @override
  String get commonPassword => '密码';

  @override
  String get commonUrl => 'URL';

  @override
  String get commonDescription => '描述';

  @override
  String get commonContent => '内容';

  @override
  String get commonRepo => '仓库';

  @override
  String get commonTemplate => '模版';

  @override
  String get commonEditRepo => '编辑仓库';

  @override
  String get commonEditTemplate => '编辑模版';

  @override
  String get commonDeleteRepoConfirm => '确定要删除此仓库吗？';

  @override
  String get commonDeleteTemplateConfirm => '确定要删除此模版吗？';

  @override
  String get commonSearch => '搜索';

  @override
  String get commonPath => '路径';

  @override
  String get commonDriver => '驱动';

  @override
  String get commonUnknownError => '未知错误';

  @override
  String get commonMegabyte => 'MB';

  @override
  String get commonHttp => 'HTTP';

  @override
  String get commonHttps => 'HTTPS';

  @override
  String get securityPageTitle => '安全';

  @override
  String get securityStatusTitle => 'MFA 状态';

  @override
  String get securityStatusEnabled => '已启用';

  @override
  String get securityStatusDisabled => '未启用';

  @override
  String get securitySecretLabel => '密钥';

  @override
  String get securityCodeLabel => '验证码';

  @override
  String get securityCodeHint => '输入 6 位验证码';

  @override
  String get securityLoadInfo => '加载 MFA 信息';

  @override
  String get securityBind => '绑定 MFA';

  @override
  String get securityBindSuccess => 'MFA 绑定请求已提交';

  @override
  String securityBindFailed(String error) {
    return '绑定 MFA 失败：$error';
  }

  @override
  String get securityMockNotice => '当前页面运行在 UI 适配模式，后续可直接接入 API client。';

  @override
  String get settingsPageTitle => '设置';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsStorage => '存储';

  @override
  String get settingsSystem => '系统';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsServerManagement => '服务器管理';

  @override
  String get settingsResetOnboarding => '重新体验新手引导';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsFeedback => '反馈建议';

  @override
  String get settingsFeedbackOpenFailed => '无法打开反馈页面。';

  @override
  String get settingsResetOnboardingDone => '已重置新手引导';

  @override
  String get settingsCacheTitle => '缓存设置';

  @override
  String get settingsCacheStrategy => '缓存策略';

  @override
  String get settingsCacheStrategyHybrid => '混合模式';

  @override
  String get settingsCacheStrategyMemoryOnly => '仅内存';

  @override
  String get settingsCacheStrategyDiskOnly => '仅硬盘';

  @override
  String get settingsCacheMaxSize => '缓存上限';

  @override
  String get settingsCacheStats => '缓存状态';

  @override
  String get settingsCacheItemCount => '缓存项数';

  @override
  String get settingsCacheCurrentSize => '当前大小';

  @override
  String get settingsCacheClear => '清除缓存';

  @override
  String get settingsCacheClearConfirm => '确认清除缓存';

  @override
  String get settingsCacheClearConfirmMessage => '确定要清除所有缓存吗？这将删除内存缓存和硬盘缓存。';

  @override
  String get settingsCacheCleared => '缓存已清除';

  @override
  String get settingsCacheLimit => '缓存限制';

  @override
  String get settingsCacheStatus => '缓存状态';

  @override
  String get settingsCacheStrategyHybridDesc => '内存+硬盘双缓存，体验最佳';

  @override
  String get settingsCacheStrategyMemoryOnlyDesc => '仅内存缓存，减少闪存损耗';

  @override
  String get settingsCacheStrategyDiskOnlyDesc => '仅硬盘缓存，支持离线查看';

  @override
  String get settingsCacheExpiration => '过期时间';

  @override
  String get settingsCacheExpirationUnit => '分钟';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageSystem => '系统';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => '英文';

  @override
  String get commonExperimental => '抢先体验';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingStart => '开始使用';

  @override
  String get onboardingTitle1 => '把 1Panel 服务器装进一个客户端';

  @override
  String get onboardingDesc1 => '集中连接和管理多台 1Panel 服务器，常用操作不再分散在不同设备里。';

  @override
  String get onboardingTitle2 => '把常用运维入口放到手边';

  @override
  String get onboardingDesc2 => '查看状态、管理文件、容器、应用和网站，日常操作都能更快完成。';

  @override
  String get onboardingTitle3 => '切换更快，状态更清楚';

  @override
  String get onboardingDesc3 => '通过清晰的状态卡片和快捷入口，快速判断服务器情况并切换到目标机器。';

  @override
  String get onboardingTitle4 => '先连接第一台服务器';

  @override
  String get onboardingDesc4 => '准备好服务器地址和 API Key，连接后就可以开始使用 1Panel Client。';

  @override
  String get coachServerAddTitle => '先添加第一台服务器';

  @override
  String get coachServerAddDesc => '点击右上角添加按钮，填写服务器地址和 API Key 开始连接。';

  @override
  String get coachServerCardTitle => '从服务器卡片进入功能';

  @override
  String get coachServerCardDesc => '添加完成后，点击服务器卡片查看详情，并进入文件、容器、网站等功能。';

  @override
  String get aboutPageTitle => '关于 1Panel Client';

  @override
  String get aboutBuildSectionTitle => '版本信息';

  @override
  String get aboutVersionLabel => '版本号';

  @override
  String get aboutBuildLabel => '构建号';

  @override
  String get aboutChannelLabel => '发布渠道';

  @override
  String get aboutPreviewSectionTitle => '抢先体验版';

  @override
  String get aboutPreviewSummary => '当前 Android 版本用于抢先体验和收集早期用户反馈。';

  @override
  String get aboutPreviewNoAutoUpdate =>
      '当前抢先体验版不支持自动更新，请通过 GitHub Pre-release 获取新版本。';

  @override
  String get aboutPreviewFeedback => '官方唯一反馈渠道：GitHub Issues。';

  @override
  String get aboutFeedbackSectionTitle => '反馈渠道';

  @override
  String get aboutFeedbackAction => '打开 GitHub Issues';

  @override
  String get aboutFeedbackHint => '欢迎反馈 bug、交互问题和建议，帮助我们继续打磨 1Panel Client。';

  @override
  String get aboutReleaseNotesSectionTitle => '当前版本说明';

  @override
  String get aboutReleaseNotesBody => '本次抢先体验版重点开放多服务器管理、欢迎引导优化，以及网站管理的早期流程体验。';

  @override
  String get aboutRepositorySectionTitle => '项目仓库';

  @override
  String get aboutRepositoryOpenAction => '打开仓库';

  @override
  String get aboutRepositoryHttpsLabel => 'HTTPS';

  @override
  String get aboutRepositorySshLabel => 'SSH';

  @override
  String get aboutReleaseAction => '查看抢先体验版本';

  @override
  String get aboutLinkOpenFailed => '无法打开链接。';

  @override
  String get aboutExperimentalModulesTitle => '实验性模块';

  @override
  String get aboutExperimentalModulesDescription => '以下模块仍在持续打磨中，可能会根据反馈继续调整。';

  @override
  String get aboutExperimentalModulesList => '网站、OpenResty、数据库、防火墙、终端、监控';

  @override
  String get dashboardTitle => '仪表盘';

  @override
  String get dashboardLoadFailedTitle => '加载失败';

  @override
  String get dashboardServerInfoTitle => '服务器信息';

  @override
  String get dashboardServerStatusOk => '运行正常';

  @override
  String get dashboardServerStatusConnecting => '连接中...';

  @override
  String get dashboardHostNameLabel => '主机名';

  @override
  String get dashboardOsLabel => '操作系统';

  @override
  String get dashboardUptimeLabel => '运行时间';

  @override
  String dashboardUptimeDaysHours(int days, int hours) {
    return '$days天 $hours小时';
  }

  @override
  String dashboardUptimeHours(int hours) {
    return '$hours小时';
  }

  @override
  String dashboardUpdatedAt(String time) {
    return '更新时间：$time';
  }

  @override
  String get dashboardResourceTitle => '系统资源';

  @override
  String get dashboardCpuUsage => 'CPU 使用率';

  @override
  String get dashboardMemoryUsage => '内存使用率';

  @override
  String get dashboardDiskUsage => '磁盘使用率';

  @override
  String get dashboardQuickActionsTitle => '快捷操作';

  @override
  String get dashboardActionRestart => '重启服务器';

  @override
  String get dashboardActionUpdate => '系统更新';

  @override
  String get dashboardActionBackup => '创建备份';

  @override
  String get dashboardActionSecurity => '安全检查';

  @override
  String get dashboardRestartTitle => '重启服务器';

  @override
  String get dashboardRestartDesc => '确定要重启服务器吗？这将导致所有服务暂时不可用。';

  @override
  String get dashboardRestartSuccess => '重启请求已发送';

  @override
  String dashboardRestartFailed(String error) {
    return '重启失败：$error';
  }

  @override
  String get dashboardUpdateTitle => '系统更新';

  @override
  String get dashboardUpdateDesc => '现在开始系统更新吗？更新期间面板可能暂时不可用。';

  @override
  String get dashboardUpdateSuccess => '更新请求已发送';

  @override
  String dashboardUpdateFailed(String error) {
    return '更新失败：$error';
  }

  @override
  String get dashboardActivityTitle => '最近活动';

  @override
  String get dashboardActivityEmpty => '暂无活动记录';

  @override
  String dashboardActivityDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String dashboardActivityHoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String dashboardActivityMinutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String get dashboardActivityJustNow => '刚刚';

  @override
  String get dashboardTopProcessesTitle => '进程监控';

  @override
  String get dashboardCpuTab => 'CPU';

  @override
  String get dashboardMemoryTab => '内存';

  @override
  String get dashboardNoProcesses => '暂无进程数据';

  @override
  String get authLoginTitle => '1Panel 登录';

  @override
  String get authLoginSubtitle => '请输入您的登录凭据';

  @override
  String get authUsername => '用户名';

  @override
  String get authPassword => '密码';

  @override
  String get authCaptcha => '验证码';

  @override
  String get authLogin => '登录';

  @override
  String get authUsernameRequired => '请输入用户名';

  @override
  String get authPasswordRequired => '请输入密码';

  @override
  String get authCaptchaRequired => '请输入验证码';

  @override
  String get authMfaTitle => '双因素认证';

  @override
  String get authMfaDesc => '请输入您的认证器应用中的验证码';

  @override
  String get authMfaHint => '000000';

  @override
  String get authMfaVerify => '验证';

  @override
  String get authMfaCancel => '返回登录';

  @override
  String get authDemoMode => '演示模式：部分功能受限';

  @override
  String get authLoginFailed => '登录失败';

  @override
  String get authLogoutSuccess => '已成功登出';

  @override
  String get coachDone => '我知道了';

  @override
  String get notFoundTitle => '页面不存在';

  @override
  String get notFoundDesc => '请求的页面不存在或已迁移。';

  @override
  String get legacyRouteRedirect => '该旧路由已跳转到新版主界面。';

  @override
  String get monitorDataPoints => '数据点数量';

  @override
  String monitorDataPointsCount(int count, String time) {
    return '$count个点 ($time)';
  }

  @override
  String get monitorRefreshInterval => '刷新间隔';

  @override
  String monitorSeconds(int count) {
    return '$count秒';
  }

  @override
  String monitorSecondsDefault(int count) {
    return '$count秒 (默认)';
  }

  @override
  String monitorMinute(int count) {
    return '$count分钟';
  }

  @override
  String monitorTimeMinutes(int count) {
    return '$count分钟';
  }

  @override
  String monitorTimeHours(int count) {
    return '$count小时';
  }

  @override
  String monitorDataPointsLabel(int count) {
    return '$count 个数据点';
  }

  @override
  String get monitorSettings => '监控设置';

  @override
  String get monitorEnable => '启用监控';

  @override
  String get monitorInterval => '监控间隔';

  @override
  String get monitorIntervalUnit => '秒';

  @override
  String get monitorRetention => '数据保留时间';

  @override
  String get monitorRetentionUnit => '天';

  @override
  String get monitorCleanData => '清理监控数据';

  @override
  String get monitorCleanConfirm => '确定要清理所有监控数据吗？此操作无法撤销。';

  @override
  String get monitorCleanSuccess => '监控数据清理成功';

  @override
  String get monitorCleanFailed => '清理监控数据失败';

  @override
  String get monitorSettingsSaved => '设置保存成功';

  @override
  String get monitorSettingsFailed => '保存设置失败';

  @override
  String get monitorGPU => 'GPU监控';

  @override
  String get monitorGPUName => '名称';

  @override
  String get monitorGPUUtilization => '利用率';

  @override
  String get monitorGPUMemory => '显存';

  @override
  String get monitorGPUTemperature => '温度';

  @override
  String get monitorGPUNotAvailable => 'GPU监控不可用';

  @override
  String get monitorTimeRange => '时间范围';

  @override
  String get monitorTimeRangeLast1h => '最近1小时';

  @override
  String get monitorTimeRangeLast6h => '最近6小时';

  @override
  String get monitorTimeRangeLast24h => '最近24小时';

  @override
  String get monitorTimeRangeLast7d => '最近7天';

  @override
  String get monitorTimeRangeCustom => '自定义';

  @override
  String get monitorTimeRangeFrom => '从';

  @override
  String get monitorTimeRangeTo => '到';

  @override
  String get systemSettingsTitle => '系统设置';

  @override
  String get systemSettingsRefresh => '刷新';

  @override
  String get systemSettingsLoadFailed => '加载设置失败';

  @override
  String get systemSettingsPanelSection => '面板设置';

  @override
  String get systemSettingsPanelConfig => '面板配置';

  @override
  String get systemSettingsPanelConfigDesc => '面板名称、端口、绑定地址等';

  @override
  String get systemSettingsTerminal => '终端设置';

  @override
  String get systemSettingsTerminalDesc => '终端样式、字体、滚动等';

  @override
  String get systemSettingsSecuritySection => '安全设置';

  @override
  String get systemSettingsSecurityConfig => '安全配置';

  @override
  String get systemSettingsSecurityConfigDesc => 'MFA认证、访问控制等';

  @override
  String get systemSettingsApiKey => 'API密钥';

  @override
  String get systemSettingsBackupSection => '备份恢复';

  @override
  String get systemSettingsSnapshot => '快照管理';

  @override
  String get systemSettingsSnapshotDesc => '创建、恢复、删除系统快照';

  @override
  String get systemSettingsSystemSection => '系统信息';

  @override
  String get systemSettingsUpgrade => '系统升级';

  @override
  String get systemSettingsAbout => '关于';

  @override
  String get systemSettingsAboutDesc => '系统信息与版本';

  @override
  String systemSettingsLastUpdated(String time) {
    return '最后更新: $time';
  }

  @override
  String get systemSettingsPanelName => '1Panel面板';

  @override
  String get systemSettingsSystemVersion => '系统版本';

  @override
  String get systemSettingsMfaStatus => 'MFA状态';

  @override
  String get systemSettingsEnabled => '启用';

  @override
  String get systemSettingsDisabled => '禁用';

  @override
  String get systemSettingsApiKeyManage => 'API密钥管理';

  @override
  String get systemSettingsCurrentStatus => '当前状态';

  @override
  String get systemSettingsUnknown => '未知';

  @override
  String get systemSettingsApiKeyLabel => 'API密钥';

  @override
  String get systemSettingsNotSet => '未设置';

  @override
  String get systemSettingsGenerateNewKey => '生成新密钥';

  @override
  String get systemSettingsApiKeyGenerated => 'API密钥已生成';

  @override
  String get systemSettingsGenerateFailed => '生成失败';

  @override
  String get apiKeySettingsTitle => 'API密钥管理';

  @override
  String get apiKeySettingsStatus => '状态';

  @override
  String get apiKeySettingsEnabled => 'API接口';

  @override
  String get apiKeySettingsInfo => '密钥信息';

  @override
  String get apiKeySettingsKey => 'API密钥';

  @override
  String get apiKeySettingsIpWhitelist => 'IP白名单';

  @override
  String get apiKeySettingsValidityTime => '有效期';

  @override
  String get apiKeySettingsActions => '操作';

  @override
  String get apiKeySettingsRegenerate => '重新生成';

  @override
  String get apiKeySettingsRegenerateDesc => '生成新的API密钥';

  @override
  String get apiKeySettingsRegenerateConfirm => '确定要重新生成API密钥吗？旧密钥将立即失效。';

  @override
  String get apiKeySettingsRegenerateSuccess => 'API密钥已重新生成';

  @override
  String get apiKeySettingsEnable => '启用API';

  @override
  String get apiKeySettingsDisable => '禁用API';

  @override
  String get apiKeySettingsEnableConfirm => '确定要启用API接口吗？';

  @override
  String get apiKeySettingsDisableConfirm => '确定要禁用API接口吗？';

  @override
  String get commonCopied => '已复制到剪贴板';

  @override
  String get sslSettingsTitle => 'SSL证书管理';

  @override
  String get sslSettingsInfo => '证书信息';

  @override
  String get sslSettingsDomain => '域名';

  @override
  String get sslSettingsStatus => '状态';

  @override
  String get sslSettingsType => '类型';

  @override
  String get sslSettingsProvider => '提供商';

  @override
  String get sslSettingsExpiration => '过期时间';

  @override
  String get sslSettingsActions => '操作';

  @override
  String get sslSettingsUpload => '上传证书';

  @override
  String get sslSettingsUploadDesc => '上传SSL证书文件';

  @override
  String get sslSettingsDownload => '下载证书';

  @override
  String get sslSettingsDownloadDesc => '下载当前SSL证书';

  @override
  String get sslSettingsDownloadSuccess => '证书下载成功';

  @override
  String get sslSettingsCert => '证书内容';

  @override
  String get sslSettingsKey => '私钥内容';

  @override
  String get panelTlsTitle => '面板 TLS';

  @override
  String get panelTlsOverviewTitle => '概览';

  @override
  String get panelTlsCertificateTitle => '证书';

  @override
  String get panelTlsRiskTitle => '风险';

  @override
  String get panelTlsHistoryTitle => '历史';

  @override
  String get panelTlsUploadHint => '上传新证书会立即替换当前面板 TLS 证书包。';

  @override
  String get panelTlsIssuerLabel => '签发者';

  @override
  String get panelTlsCertificatePathLabel => '证书路径';

  @override
  String get panelTlsKeyPathLabel => '私钥路径';

  @override
  String get panelTlsSerialNumberLabel => '序列号';

  @override
  String get panelTlsLastUpdatedLabel => '最近更新时间';

  @override
  String get panelTlsNoRecentActions => '暂无最近本地操作。';

  @override
  String get panelTlsUploadDialogTitle => '上传面板证书';

  @override
  String get panelTlsCertificatePemLabel => '证书 PEM';

  @override
  String get panelTlsPrivateKeyPemLabel => '私钥 PEM';

  @override
  String get panelTlsApplyUpdateTitle => '应用证书更新';

  @override
  String get panelTlsApplyUpdateMessage =>
      '该操作会替换当前面板 TLS 证书，并可能在网关重载前短暂影响已连接会话。';

  @override
  String get panelTlsDownloadDialogTitle => '下载证书包';

  @override
  String get panelTlsDownloadDialogMessage => '下载仅用于备份或外部校验，请妥善保管导出的私钥。';

  @override
  String get panelTlsContinueAction => '继续';

  @override
  String panelTlsDownloadSuccess(int bytes) {
    return '证书包已下载（$bytes 字节）';
  }

  @override
  String get panelTlsHealthHealthy => '健康';

  @override
  String get panelTlsHealthExpiringSoon => '即将到期';

  @override
  String get panelTlsHealthExpired => '已过期';

  @override
  String get panelTlsHealthUnknown => '未知';

  @override
  String get panelTlsRiskUnknownTitle => '证书到期时间未知';

  @override
  String get panelTlsRiskUnknownMessage => '无法解析面板证书的到期时间。';

  @override
  String get panelTlsRiskExpiredTitle => '证书已过期';

  @override
  String get panelTlsRiskExpiredMessage => '面板 TLS 证书已过期，请立即更换。';

  @override
  String get panelTlsRiskExpiringSoonTitle => '证书即将到期';

  @override
  String panelTlsRiskExpiringSoonMessage(int days) {
    return '面板 TLS 证书将在 $days 天后到期。';
  }

  @override
  String get panelTlsRiskSelfSignedTitle => '自签名证书';

  @override
  String get panelTlsRiskSelfSignedMessage => '自签名证书可能触发浏览器信任告警。';

  @override
  String get panelTlsValidationDomainRequired => '域名不能为空。';

  @override
  String get panelTlsValidationCertificateRequired => '证书内容不能为空。';

  @override
  String get panelTlsValidationCertificatePemRequired => '证书内容必须包含 PEM 证书块。';

  @override
  String get panelTlsValidationPrivateKeyRequired => '私钥内容不能为空。';

  @override
  String get panelTlsValidationPrivateKeyPemRequired => '私钥内容必须包含 PEM 私钥块。';

  @override
  String panelTlsHistoryLoaded(String domain) {
    return '已加载 $domain 的面板 TLS 状态';
  }

  @override
  String panelTlsHistoryUploaded(String domain) {
    return '已为 $domain 上传新的面板 TLS 证书';
  }

  @override
  String panelTlsHistoryDownloaded(int bytes) {
    return '已下载面板 TLS 证书包（$bytes 字节）';
  }

  @override
  String get upgradeTitle => '系统升级';

  @override
  String get upgradeCurrentVersion => '当前版本';

  @override
  String get upgradeCurrentVersionLabel => '当前系统版本';

  @override
  String get upgradeAvailableVersions => '可用版本';

  @override
  String get upgradeNoUpdates => '已是最新版本';

  @override
  String get upgradeLatest => '最新';

  @override
  String get upgradeConfirm => '确认升级';

  @override
  String upgradeConfirmMessage(Object version) {
    return '确定要升级到版本 $version 吗？';
  }

  @override
  String get upgradeDowngradeConfirm => '确认降级';

  @override
  String upgradeDowngradeMessage(Object version) {
    return '确定要降级到版本 $version 吗？降级可能会导致数据不兼容。';
  }

  @override
  String get upgradeButton => '升级';

  @override
  String get upgradeDowngradeButton => '降级';

  @override
  String get upgradeStarted => '升级已开始';

  @override
  String get upgradeViewNotes => '查看更新说明';

  @override
  String upgradeNotesTitle(Object version) {
    return '版本 $version 更新说明';
  }

  @override
  String get upgradeNotesLoading => '正在加载...';

  @override
  String get upgradeNotesEmpty => '暂无更新说明';

  @override
  String get upgradeNotesError => '加载失败';

  @override
  String get monitorSettingsTitle => '监控设置';

  @override
  String get monitorSettingsInterval => '监控间隔';

  @override
  String get monitorSettingsStoreDays => '数据保留天数';

  @override
  String get monitorSettingsEnable => '启用监控';

  @override
  String get systemSettingsCurrentVersion => '当前版本';

  @override
  String get systemSettingsCheckingUpdate => '正在检查更新...';

  @override
  String get systemSettingsClose => '关闭';

  @override
  String get panelSettingsTitle => '面板设置';

  @override
  String get panelSettingsBasicInfo => '基本信息';

  @override
  String get panelSettingsPanelName => '面板名称';

  @override
  String get panelSettingsVersion => '系统版本';

  @override
  String get panelSettingsPort => '监听端口';

  @override
  String get panelSettingsBindAddress => '绑定地址';

  @override
  String get panelSettingsInterface => '界面设置';

  @override
  String get panelSettingsTheme => '主题';

  @override
  String get panelSettingsLanguage => '语言';

  @override
  String get panelSettingsMenuTabs => '菜单标签';

  @override
  String get panelSettingsAdvanced => '高级设置';

  @override
  String get panelSettingsDeveloperMode => '开发者模式';

  @override
  String get panelSettingsIpv6 => 'IPv6';

  @override
  String get panelSettingsSessionTimeout => '会话超时';

  @override
  String panelSettingsMinutes(String count) {
    return '$count 分钟';
  }

  @override
  String get terminalSettingsTitle => '终端设置';

  @override
  String get terminalSettingsDisplay => '显示设置';

  @override
  String get terminalSettingsCursorStyle => '光标样式';

  @override
  String get terminalSettingsCursorBlink => '光标闪烁';

  @override
  String get terminalSettingsFontSize => '字体大小';

  @override
  String get terminalSettingsScroll => '滚动设置';

  @override
  String get terminalSettingsScrollSensitivity => '滚动灵敏度';

  @override
  String get terminalSettingsScrollback => '滚动缓冲区';

  @override
  String get terminalSettingsStyle => '样式设置';

  @override
  String get terminalSettingsLineHeight => '行高';

  @override
  String get terminalSettingsLetterSpacing => '字母间距';

  @override
  String get securitySettingsTitle => '安全设置';

  @override
  String get securitySettingsPasswordSection => '密码管理';

  @override
  String get securitySettingsChangePassword => '修改密码';

  @override
  String get securitySettingsChangePasswordDesc => '修改登录密码';

  @override
  String get securitySettingsOldPassword => '当前密码';

  @override
  String get securitySettingsNewPassword => '新密码';

  @override
  String get securitySettingsConfirmPassword => '确认密码';

  @override
  String get securitySettingsPasswordMismatch => '两次密码输入不一致';

  @override
  String get securitySettingsMfaSection => 'MFA认证';

  @override
  String get securitySettingsMfaStatus => 'MFA状态';

  @override
  String get securitySettingsMfaBind => '绑定MFA';

  @override
  String get securitySettingsMfaUnbind => '解绑MFA';

  @override
  String get securitySettingsMfaUnbindDesc => '解绑后将无法使用MFA认证，确定要解绑吗？';

  @override
  String get securitySettingsMfaScanQr => '请使用认证器APP扫描二维码';

  @override
  String securitySettingsMfaSecret(Object secret) {
    return '密钥: $secret';
  }

  @override
  String get securitySettingsMfaCode => '验证码';

  @override
  String get securitySettingsUnbindMfa => '解绑MFA';

  @override
  String get securitySettingsAccessControl => '访问控制';

  @override
  String get securitySettingsSecurityEntrance => '安全入口';

  @override
  String get securitySettingsBindDomain => '绑定域名';

  @override
  String get securitySettingsAllowIPs => '允许IP列表';

  @override
  String get securitySettingsPasswordPolicy => '密码策略';

  @override
  String get securitySettingsComplexityVerification => '复杂度验证';

  @override
  String get securitySettingsExpirationDays => '过期天数';

  @override
  String get securitySettingsEnableMfa => '启用MFA';

  @override
  String get securitySettingsDisableMfa => '禁用MFA';

  @override
  String get securitySettingsEnableMfaConfirm => '确定要启用MFA认证吗？';

  @override
  String get securitySettingsDisableMfaConfirm => '确定要禁用MFA认证吗？';

  @override
  String get securitySettingsEnterMfaCode => '请输入MFA验证码';

  @override
  String get securitySettingsVerifyCode => '验证码';

  @override
  String get securitySettingsMfaCodeHint => '请输入6位验证码';

  @override
  String get securitySettingsMfaUnbound => 'MFA已解绑';

  @override
  String get securitySettingsUnbindFailed => '解绑失败';

  @override
  String get snapshotTitle => '快照管理';

  @override
  String get snapshotCreate => '创建快照';

  @override
  String get snapshotEmpty => '暂无快照';

  @override
  String get snapshotCreatedAt => '创建时间';

  @override
  String get snapshotDescription => '描述';

  @override
  String get snapshotRecover => '恢复';

  @override
  String get snapshotDownload => '下载';

  @override
  String get snapshotDelete => '删除';

  @override
  String get snapshotImport => '导入快照';

  @override
  String get snapshotRollback => '回滚';

  @override
  String get snapshotEditDesc => '编辑描述';

  @override
  String get snapshotEnterDesc => '请输入快照描述（可选）';

  @override
  String get snapshotDescLabel => '描述';

  @override
  String get snapshotDescHint => '请输入快照描述';

  @override
  String get snapshotCreateSuccess => '快照创建成功';

  @override
  String get snapshotCreateFailed => '快照创建失败';

  @override
  String get snapshotImportTitle => '导入快照';

  @override
  String get snapshotImportPath => '快照文件路径';

  @override
  String get snapshotImportPathHint => '请输入快照文件路径';

  @override
  String get snapshotImportSuccess => '快照导入成功';

  @override
  String get snapshotImportFailed => '快照导入失败';

  @override
  String get snapshotRollbackTitle => '回滚快照';

  @override
  String get snapshotRollbackConfirm => '确定要回滚到此快照吗？回滚后当前配置将被覆盖。';

  @override
  String get snapshotRollbackSuccess => '快照回滚成功';

  @override
  String get snapshotRollbackFailed => '快照回滚失败';

  @override
  String get snapshotEditDescTitle => '编辑快照描述';

  @override
  String get snapshotEditDescSuccess => '描述更新成功';

  @override
  String get snapshotEditDescFailed => '描述更新失败';

  @override
  String get snapshotRecoverTitle => '恢复快照';

  @override
  String get snapshotRecoverConfirm => '确定要恢复此快照吗？恢复后当前配置将被覆盖。';

  @override
  String get snapshotRecoverSuccess => '快照恢复成功';

  @override
  String get snapshotRecoverFailed => '快照恢复失败';

  @override
  String get snapshotDeleteTitle => '删除快照';

  @override
  String get snapshotDeleteConfirm => '确定要删除选中的快照吗？此操作不可恢复。';

  @override
  String get snapshotDeleteSuccess => '快照删除成功';

  @override
  String get snapshotDeleteFailed => '快照删除失败';

  @override
  String get proxySettingsTitle => '代理设置';

  @override
  String get proxySettingsEnable => '启用代理';

  @override
  String get proxySettingsType => '代理类型';

  @override
  String get proxySettingsHttp => 'HTTP代理';

  @override
  String get proxySettingsHttps => 'HTTPS代理';

  @override
  String get proxySettingsHost => '代理地址';

  @override
  String get proxySettingsPort => '代理端口';

  @override
  String get proxySettingsUser => '用户名';

  @override
  String get proxySettingsPassword => '密码';

  @override
  String get proxySettingsSaved => '代理设置已保存';

  @override
  String get proxySettingsFailed => '保存失败';

  @override
  String get bindSettingsTitle => '绑定地址';

  @override
  String get bindSettingsAddress => '绑定地址';

  @override
  String get bindSettingsPort => '面板端口';

  @override
  String get bindSettingsSaved => '绑定设置已保存';

  @override
  String get bindSettingsFailed => '保存失败';

  @override
  String get serverModuleSystemSettings => '系统设置';

  @override
  String get filesFavorites => '收藏夹';

  @override
  String get filesFavoritesEmpty => '暂无收藏';

  @override
  String get filesFavoritesEmptyDesc => '长按文件或文件夹可添加到收藏夹';

  @override
  String get filesAddToFavorites => '添加到收藏夹';

  @override
  String get filesRemoveFromFavorites => '取消收藏';

  @override
  String get filesFavoritesAdded => '已添加到收藏夹';

  @override
  String get filesFavoritesRemoved => '已从收藏夹移除';

  @override
  String get filesNavigateToFolder => '跳转到所在目录';

  @override
  String get filesFavoritesLoadFailed => '加载收藏夹失败';

  @override
  String get filesPermissionTitle => '权限管理';

  @override
  String get filesPermissionMode => '权限模式';

  @override
  String get filesPermissionOwner => '所有者';

  @override
  String get filesPermissionGroup => '所属组';

  @override
  String get filesPermissionRead => '读取';

  @override
  String get filesPermissionWrite => '写入';

  @override
  String get filesPermissionExecute => '执行';

  @override
  String get filesPermissionOwnerLabel => '所有者权限';

  @override
  String get filesPermissionGroupLabel => '组权限';

  @override
  String get filesPermissionOtherLabel => '其他权限';

  @override
  String get filesPermissionRecursive => '递归应用到子目录';

  @override
  String get filesPermissionUser => '用户';

  @override
  String get filesPermissionUserHint => '选择用户';

  @override
  String get filesPermissionGroupHint => '选择组';

  @override
  String get filesPermissionChangeOwner => '修改所有者';

  @override
  String get filesPermissionChangeMode => '修改权限';

  @override
  String get filesPermissionSuccess => '权限修改成功';

  @override
  String get transferListTitle => '传输列表';

  @override
  String get transferClearCompleted => '清除已完成';

  @override
  String get transferEmpty => '暂无传输任务';

  @override
  String get transferStatusRunning => '传输中';

  @override
  String get transferStatusPaused => '已暂停';

  @override
  String get transferStatusCompleted => '已完成';

  @override
  String get transferStatusFailed => '失败';

  @override
  String get transferStatusCancelled => '已取消';

  @override
  String get transferStatusPending => '等待中';

  @override
  String get transferUploading => '上传中';

  @override
  String get transferDownloading => '下载中';

  @override
  String get transferChunks => '分块';

  @override
  String get transferSpeed => '速度';

  @override
  String get transferEta => '剩余时间';

  @override
  String get filesPermissionFailed => '权限修改失败';

  @override
  String get filesPermissionLoadFailed => '加载权限信息失败';

  @override
  String get filesPermissionOctal => '八进制表示';

  @override
  String get filesPreviewTitle => '文件预览';

  @override
  String get filesEditorTitle => '编辑文件';

  @override
  String get filesPreviewLoading => '加载中...';

  @override
  String get filesPreviewError => '加载失败';

  @override
  String get filesPreviewUnsupported => '不支持预览此文件类型';

  @override
  String get filesEditorSave => '保存';

  @override
  String get filesEditorSaved => '已保存';

  @override
  String get filesEditorUnsaved => '未保存';

  @override
  String get filesEditorSaving => '保存中...';

  @override
  String get filesEditorEncoding => '编码';

  @override
  String get filesEditorLineNumbers => '行号';

  @override
  String get filesEditorWordWrap => '自动换行';

  @override
  String get filesGoToLine => '跳转行';

  @override
  String get filesLineNumber => '行号';

  @override
  String get filesReload => '重新加载';

  @override
  String get filesEditorReloadConfirm => '切换编码将重新加载文件内容，未保存修改将丢失，是否继续？';

  @override
  String get filesEncodingConvert => '转换编码';

  @override
  String get filesEncodingFrom => '源编码';

  @override
  String get filesEncodingTo => '目标编码';

  @override
  String get filesEncodingBackup => '备份原文件';

  @override
  String get filesEncodingConvertDone => '编码转换成功';

  @override
  String get filesEncodingConvertFailed => '编码转换失败';

  @override
  String get filesEncodingLog => '转换日志';

  @override
  String get filesEncodingLogEmpty => '暂无日志';

  @override
  String get filesPreviewImage => '图片预览';

  @override
  String get filesPreviewCode => '代码预览';

  @override
  String get filesPreviewText => '文本预览';

  @override
  String get filesEditFile => '编辑文件';

  @override
  String get filesActionWgetDownload => '远程下载';

  @override
  String get filesWgetUrl => '下载地址';

  @override
  String get filesWgetUrlHint => '请输入文件URL';

  @override
  String get filesWgetFilename => '文件名';

  @override
  String get filesWgetFilenameHint => '留空则使用URL中的文件名';

  @override
  String get filesWgetOverwrite => '覆盖已存在的文件';

  @override
  String get filesWgetDownload => '开始下载';

  @override
  String filesWgetSuccess(String path) {
    return '下载成功: $path';
  }

  @override
  String get filesWgetFailed => '下载失败';

  @override
  String get recycleBinRestore => '恢复';

  @override
  String recycleBinRestoreConfirm(int count) {
    return '确定要恢复选中的 $count 个文件吗？';
  }

  @override
  String get recycleBinRestoreSuccess => '文件恢复成功';

  @override
  String get recycleBinRestoreFailed => '恢复文件失败';

  @override
  String recycleBinRestoreSingleConfirm(String name) {
    return '确定要恢复 \"$name\" 吗？';
  }

  @override
  String get recycleBinDeletePermanently => '彻底删除';

  @override
  String recycleBinDeletePermanentlyConfirm(int count) {
    return '确定要彻底删除选中的 $count 个文件吗？此操作无法撤销。';
  }

  @override
  String get recycleBinDeletePermanentlySuccess => '文件已彻底删除';

  @override
  String get recycleBinDeletePermanentlyFailed => '彻底删除文件失败';

  @override
  String recycleBinDeletePermanentlySingleConfirm(String name) {
    return '确定要彻底删除 \"$name\" 吗？此操作无法撤销。';
  }

  @override
  String get recycleBinClear => '清空回收站';

  @override
  String get recycleBinClearConfirm => '确定要清空回收站吗？所有文件将被永久删除。';

  @override
  String get recycleBinClearSuccess => '回收站已清空';

  @override
  String get recycleBinClearFailed => '清空回收站失败';

  @override
  String get recycleBinSearch => '搜索文件';

  @override
  String get recycleBinEmpty => '回收站为空';

  @override
  String get recycleBinNoResults => '未找到文件';

  @override
  String get recycleBinSourcePath => '原路径';

  @override
  String get transferManagerTitle => '传输管理';

  @override
  String get transferFilterAll => '全部';

  @override
  String get transferFilterUploading => '上传中';

  @override
  String get transferFilterDownloading => '下载中';

  @override
  String get transferSortNewest => '最新';

  @override
  String get transferSortOldest => '最旧';

  @override
  String get transferSortName => '名称';

  @override
  String get transferSortSize => '大小';

  @override
  String get transferTabActive => '进行中';

  @override
  String get transferTabPending => '等待中';

  @override
  String get transferTabCompleted => '已完成';

  @override
  String get transferFileNotFound => '文件不存在';

  @override
  String get transferFileAlreadyDownloaded => '文件已下载完成，无需重试';

  @override
  String get transferFileLocationOpened => '已打开文件位置';

  @override
  String get transferOpenFileError => '打开文件失败';

  @override
  String get transferOpenFile => '打开文件';

  @override
  String get transferClearTitle => '清除已完成任务';

  @override
  String get transferClearConfirm => '确定要清除所有已完成的传输任务吗？';

  @override
  String get transferPause => '暂停';

  @override
  String get transferCancel => '取消';

  @override
  String get transferResume => '继续';

  @override
  String get transferOpenLocation => '打开位置';

  @override
  String get transferOpenDownloadsFolder => '打开下载目录';

  @override
  String get transferCopyPath => '复制路径';

  @override
  String get transferCopyDirectoryPath => '复制目录路径';

  @override
  String get transferDownloads => '下载';

  @override
  String get transferUploads => '上传';

  @override
  String get transferSettings => '设置';

  @override
  String get transferSettingsTitle => '传输设置';

  @override
  String get transferHistoryRetentionHint => '历史记录保留天数（超过天数自动清理）';

  @override
  String transferHistoryDays(int days) {
    return '$days天';
  }

  @override
  String get transferHistorySaved => '设置已保存';

  @override
  String get largeFileDownloadTitle => '大文件下载';

  @override
  String get largeFileDownloadHint => '文件较大，已添加到后台下载队列';

  @override
  String get largeFileDownloadView => '查看下载';

  @override
  String get permissionRequired => '需要权限';

  @override
  String get permissionStorageRequired => '需要存储权限才能保存文件';

  @override
  String get permissionGoToSettings => '去设置';

  @override
  String get fileSaveSuccess => '文件已保存';

  @override
  String get fileSaveFailed => '保存文件失败';

  @override
  String fileSaveLocation(String path) {
    return '保存位置: $path';
  }

  @override
  String get filesPropertiesTitle => '文件属性';

  @override
  String get filesCreatedLabel => '创建时间';

  @override
  String get filesModifiedLabel => '修改时间';

  @override
  String get filesAccessedLabel => '访问时间';

  @override
  String get filesCreateLinkTitle => '创建链接';

  @override
  String get filesLinkNameLabel => '链接名称';

  @override
  String get filesLinkTypeLabel => '链接类型';

  @override
  String get filesLinkTypeSymbolic => '符号链接';

  @override
  String get filesLinkTypeHard => '硬链接';

  @override
  String get filesLinkPath => '目标路径';

  @override
  String get filesContentSearch => '内容搜索';

  @override
  String get filesContentSearchHint => '搜索内容';

  @override
  String get filesUploadHistory => '上传历史';

  @override
  String get filesMounts => '挂载点';

  @override
  String get filesActionUp => '返回上级';

  @override
  String get commonError => '发生错误';

  @override
  String get commonCreateSuccess => '创建成功';

  @override
  String get commonCopySuccess => '复制成功';

  @override
  String get appStoreTitle => '应用商店';

  @override
  String get appsPageTitle => '应用管理';

  @override
  String get appStoreInstall => '安装';

  @override
  String get appStoreInstalled => '已安装';

  @override
  String get appStoreUpdate => '更新';

  @override
  String get appStoreSearchHint => '搜索应用';

  @override
  String get appStoreSync => '同步应用';

  @override
  String get appStoreSyncSuccess => '同步应用列表成功';

  @override
  String get appStoreSyncFailed => '同步应用列表失败';

  @override
  String get appStoreSyncLocal => '同步本地应用';

  @override
  String get appStoreSyncLocalSuccess => '同步本地应用成功';

  @override
  String get appStoreSyncLocalFailed => '同步本地应用失败';

  @override
  String get appIgnoredUpdatesTitle => '忽略更新';

  @override
  String get appIgnoredUpdatesLoadFailed => '加载忽略列表失败';

  @override
  String get appIgnoredUpdatesEmpty => '暂无忽略更新';

  @override
  String get appIgnoreUpdate => '忽略更新';

  @override
  String get appIgnoreUpdateReason => '原因';

  @override
  String get appIgnoreUpdateSuccess => '已忽略更新';

  @override
  String appIgnoreUpdateFailed(String error) {
    return '忽略更新失败：$error';
  }

  @override
  String get appIgnoreUpdateCancel => '取消忽略';

  @override
  String get appStoreTagWebsite => '网站';

  @override
  String get appStoreTagDatabase => '数据库';

  @override
  String get appStoreTagRuntime => '运行环境';

  @override
  String get appStoreTagTool => '工具';

  @override
  String get appStoreTagDocker => 'Docker';

  @override
  String get appStoreTagCICD => 'CI/CD';

  @override
  String get appStoreTagMonitoring => '监控';

  @override
  String get appDetailTitle => '应用详情';

  @override
  String get appStatusRunning => '运行中';

  @override
  String get appStatusStopped => '已停止';

  @override
  String get appStatusError => '错误';

  @override
  String get appActionStart => '启动';

  @override
  String get appActionStop => '停止';

  @override
  String get appActionRestart => '重启';

  @override
  String get appActionUninstall => '卸载';

  @override
  String get appServiceList => '服务列表';

  @override
  String get appBaseInfo => '基本信息';

  @override
  String get appInfoName => '应用名称';

  @override
  String get appInfoVersion => '版本';

  @override
  String get appInfoStatus => '状态';

  @override
  String get appInfoCreated => '创建时间';

  @override
  String get appUninstallConfirm => '确定要卸载该应用吗？此操作不可恢复。';

  @override
  String get appNoPortInfo => '暂无端口信息';

  @override
  String get appConnInfo => '连接信息';

  @override
  String get appConnInfoFailed => '获取连接信息失败';

  @override
  String appReadmeImageUnsupported(String url) {
    return '图片不支持：$url';
  }

  @override
  String get appOperateSuccess => '操作成功';

  @override
  String get commonPort => '端口';

  @override
  String get commonParams => '参数';

  @override
  String get appUpdate => '更新';

  @override
  String get appUpdateTitle => '更新应用';

  @override
  String appUpdateConfirm(String app, String version) {
    return '确定要将 $app 更新到 $version 吗？';
  }

  @override
  String get appUpdateSuccess => '更新任务已启动';

  @override
  String appUpdateFailed(String error) {
    return '更新失败: $error';
  }

  @override
  String appOperateFailed(String error) {
    return '操作失败：$error';
  }

  @override
  String get appInstallContainerName => '容器名称';

  @override
  String get appInstallCpuLimit => 'CPU 限制';

  @override
  String get appInstallMemoryLimit => '内存限制';

  @override
  String get appInstallPorts => '端口';

  @override
  String get appInstallEnv => '环境变量';

  @override
  String get appInstallEnvKey => '键';

  @override
  String get appInstallEnvValue => '值';

  @override
  String get appInstallPortService => '服务端口';

  @override
  String get appInstallPortHost => '主机端口';

  @override
  String get appTabInfo => '信息';

  @override
  String get appTabConfig => '配置';

  @override
  String get containerTitle => '容器管理';

  @override
  String get containerStatusRunning => '运行中';

  @override
  String get containerStatusStopped => '已停止';

  @override
  String get containerStatusPaused => '已暂停';

  @override
  String get containerStatusExited => '已退出';

  @override
  String get containerStatusRestarting => '重启中';

  @override
  String get containerStatusRemoving => '删除中';

  @override
  String get containerStatusDead => '已死亡';

  @override
  String get containerStatusCreated => '已创建';

  @override
  String get containerActionStart => '启动';

  @override
  String get containerActionStop => '停止';

  @override
  String get containerActionRestart => '重启';

  @override
  String get containerActionDelete => '删除';

  @override
  String get containerActionLogs => '日志';

  @override
  String get containerActionTerminal => '终端';

  @override
  String get containerActionStats => '监控';

  @override
  String get containerActionInspect => '详情';

  @override
  String get containerInspectJson => '查看 JSON';

  @override
  String get containerTabInfo => '信息';

  @override
  String get containerTabLogs => '日志';

  @override
  String get containerTabStats => '监控';

  @override
  String get containerTabTerminal => '终端';

  @override
  String get containerDetailTitle => '容器详情';

  @override
  String get containerInfoId => '容器ID';

  @override
  String get containerInfoName => '名称';

  @override
  String get containerInfoImage => '镜像';

  @override
  String get containerInfoStatus => '状态';

  @override
  String get containerInfoCreated => '创建时间';

  @override
  String get containerInfoCommand => '命令';

  @override
  String get containerInfoPorts => '端口映射';

  @override
  String get containerInfoEnv => '环境变量';

  @override
  String get containerInfoLabels => '标签';

  @override
  String get containerStatsCpu => 'CPU使用率';

  @override
  String get containerStatsMemory => '内存使用';

  @override
  String get containerStatsNetwork => '网络I/O';

  @override
  String get containerStatsBlock => '磁盘I/O';

  @override
  String get containerLogsAutoRefresh => '自动刷新';

  @override
  String get containerLogsDownload => '下载日志';

  @override
  String containerDeleteConfirm(Object name) {
    return '确定要删除容器 $name 吗？此操作不可恢复。';
  }

  @override
  String get containerOperateSuccess => '操作成功';

  @override
  String containerOperateFailed(String error) {
    return '操作失败：$error';
  }

  @override
  String get containerActionRename => '重命名';

  @override
  String get containerActionUpgrade => '升级';

  @override
  String get containerActionEdit => '编辑';

  @override
  String get containerActionCommit => '提交镜像';

  @override
  String get containerActionCleanLog => '清理日志';

  @override
  String get containerActionDownloadLog => '查看日志';

  @override
  String get containerActionPrune => '清理';

  @override
  String get containerActionTag => '标记';

  @override
  String get containerActionPush => '推送';

  @override
  String get containerActionSave => '保存';

  @override
  String get containerImage => '镜像';

  @override
  String get containerUpgradeForcePull => '强制拉取';

  @override
  String get containerCommitImage => '新镜像名';

  @override
  String get containerCommitAuthor => '作者';

  @override
  String get containerCommitComment => '备注';

  @override
  String get containerCommitPause => '暂停容器';

  @override
  String get containerCpuShares => 'CPU 配额';

  @override
  String get containerMemory => '内存';

  @override
  String containerCleanLogConfirm(String name) {
    return '确定清理 $name 的日志吗？';
  }

  @override
  String get containerPruneType => '清理类型';

  @override
  String get containerPruneTypeContainer => '容器';

  @override
  String get containerPruneTypeImage => '镜像';

  @override
  String get containerPruneTypeVolume => '存储卷';

  @override
  String get containerPruneTypeNetwork => '网络';

  @override
  String get containerPruneTypeBuildCache => '构建缓存';

  @override
  String get containerPruneWithTagAll => '包含所有标签';

  @override
  String get containerBuildContext => '构建上下文目录';

  @override
  String get containerBuildDockerfile => 'Dockerfile 路径';

  @override
  String get containerBuildTags => '标签（逗号分隔）';

  @override
  String get containerBuildArgs => '构建参数';

  @override
  String get containerImageLoadPath => '镜像文件路径';

  @override
  String get containerTagLabel => '目标镜像';

  @override
  String get containerPushConfirm => '确定推送此镜像吗？';

  @override
  String get containerSavePath => '保存路径';

  @override
  String get containerNoLogs => '暂无日志';

  @override
  String get containerLoading => '加载中...';

  @override
  String get containerTerminalConnect => '连接';

  @override
  String get containerTerminalDisconnect => '断开';

  @override
  String get commonStart => '启动';

  @override
  String get commonStop => '停止';

  @override
  String get commonRestart => '重启';

  @override
  String get commonLogs => '日志';

  @override
  String get commonDeleteConfirm => '确定要删除此项吗？';

  @override
  String get orchestrationTitle => '编排';

  @override
  String get orchestrationCompose => '编排';

  @override
  String get orchestrationImages => '镜像';

  @override
  String get orchestrationNetworks => '网络';

  @override
  String get orchestrationVolumes => '卷';

  @override
  String get orchestrationPullImage => '拉取镜像';

  @override
  String get orchestrationPullImageHint => '输入镜像名称 (如 nginx:latest)';

  @override
  String get orchestrationPullSuccess => '已开始拉取镜像';

  @override
  String get orchestrationPullFailed => '拉取镜像失败';

  @override
  String get orchestrationComposeCreateTitle => '创建 Compose 项目';

  @override
  String get orchestrationComposeContentLabel => 'Compose 内容';

  @override
  String get orchestrationComposeContentHint => '粘贴 docker-compose.yml 内容';

  @override
  String get orchestrationComposeUpdate => '更新 Compose';

  @override
  String get orchestrationComposeTest => '测试 Compose';

  @override
  String get orchestrationComposeCleanLog => '清理 Compose 日志';

  @override
  String orchestrationComposeCleanLogConfirm(String name) {
    return '确定清理 $name 的日志吗？';
  }

  @override
  String get orchestrationStatusUnknown => '未知';

  @override
  String get orchestrationServicesLabel => '服务';

  @override
  String get orchestrationImageBuild => '构建镜像';

  @override
  String get orchestrationImageLoad => '加载镜像';

  @override
  String get orchestrationImageSearch => '搜索镜像';

  @override
  String get orchestrationImageSearchResult => '搜索结果';

  @override
  String get orchestrationImageSizeLabel => '大小';

  @override
  String get orchestrationImageCreatedLabel => '创建时间';

  @override
  String get appActionWeb => 'Web';

  @override
  String get containerManagement => '容器管理';

  @override
  String get orchestration => '容器编排';

  @override
  String get images => '镜像';

  @override
  String get networks => '网络';

  @override
  String get volumes => '数据卷';

  @override
  String get compose => 'Compose';

  @override
  String get ports => '端口';

  @override
  String get env => '环境变量';

  @override
  String get viewContainer => '查看容器';

  @override
  String get webUI => 'Web界面';

  @override
  String get readme => '说明文档';

  @override
  String get appDescription => '应用描述';

  @override
  String get statusRunning => '运行中';

  @override
  String get statusStopped => '已停止';

  @override
  String get statusRestarting => '重启中';

  @override
  String get actionStart => '启动';

  @override
  String get actionStop => '停止';

  @override
  String get actionRestart => '重启';

  @override
  String get actionUninstall => '卸载';

  @override
  String get logSearchHint => '搜索日志...';

  @override
  String get logRefresh => '刷新日志';

  @override
  String get logScrollToBottom => '滚动到底部';

  @override
  String get logSettings => '设置';

  @override
  String get logSettingsTitle => '日志设置';

  @override
  String get logFontSize => '字体大小';

  @override
  String get logWrap => '自动换行';

  @override
  String get logShowTimestamp => '显示时间戳';

  @override
  String get logTheme => '配色主题';

  @override
  String get logNoLogs => '暂无日志';

  @override
  String get logNoMatches => '未找到匹配项';

  @override
  String get logTimestampFormat => '时间戳格式';

  @override
  String get logTimestampAbsolute => '绝对时间';

  @override
  String get logTimestampRelative => '相对时间';

  @override
  String logMatchCount(int current, int total) {
    return '$current/$total 匹配';
  }

  @override
  String get logPreviousMatch => '上一个匹配';

  @override
  String get logNextMatch => '下一个匹配';

  @override
  String get logEditTheme => '编辑配色规则';

  @override
  String get logThemeEditor => '配色编辑器';

  @override
  String get logRulePattern => '匹配模式';

  @override
  String get logRuleType => '类型';

  @override
  String get logRuleCaseSensitive => '区分大小写';

  @override
  String get logRuleCaseInsensitive => '不区分大小写';

  @override
  String get logRuleColor => '文字颜色';

  @override
  String get logRuleBackgroundColor => '背景颜色';

  @override
  String get logRuleBold => '粗体';

  @override
  String get logRuleItalic => '斜体';

  @override
  String get logRuleUnderline => '下划线';

  @override
  String get logImportTheme => '导入主题';

  @override
  String get logExportTheme => '导出主题';

  @override
  String get logImportSuccess => '主题导入成功';

  @override
  String get logInvalidJson => '无效的JSON格式';

  @override
  String get logLineHeight => '行高';

  @override
  String get logViewMode => '显示模式';

  @override
  String get logModeWrap => '自动换行';

  @override
  String get logModeScrollLine => '单行滑动';

  @override
  String get logModeScrollPage => '整页滑动';

  @override
  String get themeDynamicColor => '动态取色';

  @override
  String get themeDynamicColorDesc => '使用壁纸颜色作为主题色';

  @override
  String get themeSeedColor => '自定义颜色';

  @override
  String get themeSeedColorFallbackDesc => '当动态取色不可用时使用';

  @override
  String get containerTabOverview => '概览';

  @override
  String get containerTabContainers => '容器';

  @override
  String get containerTabOrchestration => '编排';

  @override
  String get containerTabImages => '镜像';

  @override
  String get containerTabNetworks => '网络';

  @override
  String get containerTabVolumes => '存储卷';

  @override
  String get containerTabRepositories => '仓库';

  @override
  String get containerTabTemplates => '编排模版';

  @override
  String get containerTabConfig => '配置';

  @override
  String get containerSearch => '搜索容器';

  @override
  String get containerFilter => '筛选容器';

  @override
  String get containerNetworkSubnetLabel => '子网';

  @override
  String get containerNetworkSubnetHint => '例如 172.20.0.0/16';

  @override
  String get containerNetworkGatewayLabel => '网关';

  @override
  String get containerNetworkGatewayHint => '例如 172.20.0.1';

  @override
  String get containerRepoUrlExample => '例如 https://github.com/user/repo';

  @override
  String get containerTemplateContentHint => 'YAML 内容';

  @override
  String get containerCreate => '创建容器';

  @override
  String get containerEmptyTitle => '暂无容器';

  @override
  String get containerEmptyDesc => '点击右下角按钮创建容器';

  @override
  String get containerStatsTitle => '容器统计';

  @override
  String get containerStatsDetailTitle => '详细状态';

  @override
  String get containerStatsImages => '镜像';

  @override
  String get containerStatsNetworks => '网络';

  @override
  String get containerStatsVolumes => '卷';

  @override
  String get containerStatsRepos => '仓库';

  @override
  String get containerStatsTotal => '总数';

  @override
  String get containerStatsRunning => '运行中';

  @override
  String get containerStatsStopped => '已停止';

  @override
  String containerFeatureDeveloping(Object feature) {
    return '$feature 功能开发中';
  }

  @override
  String get orchestrationCreateProject => '创建项目';

  @override
  String get orchestrationCreateNetwork => '创建网络';

  @override
  String get orchestrationCreateVolume => '创建存储卷';

  @override
  String get orchestrationCreateRepo => '创建仓库';

  @override
  String get orchestrationCreateTemplate => '创建模版';

  @override
  String get operationsCenterPageTitle => '运维中心';

  @override
  String get operationsCenterIntro => '第一阶段新增能力会按周统一落在这里，保持服务器运维入口在移动端只有一个主链路。';

  @override
  String get operationsCenterServerEntryTitle => '运维中心';

  @override
  String get operationsCenterServerEntrySubtitle => '把自动化、运行时和系统控制放到统一入口';

  @override
  String get operationsCenterAutomationSectionTitle => '自动化';

  @override
  String get operationsCenterAutomationSectionDescription =>
      '命令、计划任务、脚本库和备份主链路';

  @override
  String get operationsCenterRuntimeSectionTitle => '运行时与交付';

  @override
  String get operationsCenterRuntimeSectionDescription =>
      'PHP 与 Node.js 的通用运行时链路';

  @override
  String get operationsCenterSystemSectionTitle => '系统控制';

  @override
  String get operationsCenterSystemSectionDescription => '主机资产、SSH、进程与日志入口';

  @override
  String get operationsCommandsTitle => '命令库';

  @override
  String get operationsCommandFormTitle => '命令表单';

  @override
  String get operationsHostAssetsTitle => '主机资产';

  @override
  String get operationsHostAssetFormTitle => '主机资产表单';

  @override
  String get operationsSshTitle => 'SSH';

  @override
  String get operationsSshCertsTitle => 'SSH 证书';

  @override
  String get operationsSshLogsTitle => 'SSH 日志';

  @override
  String get operationsSshSessionsTitle => 'SSH 会话';

  @override
  String get operationsProcessesTitle => '进程';

  @override
  String get operationsProcessDetailTitle => '进程详情';

  @override
  String get operationsToolboxTitle => '工具箱';

  @override
  String get operationsCronjobsTitle => '计划任务';

  @override
  String get operationsCronjobFormTitle => '计划任务表单';

  @override
  String get operationsCronjobRecordsTitle => '计划任务记录';

  @override
  String get operationsScriptsTitle => '脚本库';

  @override
  String get toolboxCenterTitle => '工具箱';

  @override
  String get toolboxCenterIntro => '工具聚合入口，包含 ClamAV、Fail2ban、FTP 与设备管理。';

  @override
  String get toolboxCommonOverviewTitle => '概览';

  @override
  String get toolboxCommonRecentRecordsTitle => '最近记录';

  @override
  String get toolboxStatusLabel => '状态';

  @override
  String get toolboxVersionLabel => '版本';

  @override
  String get toolboxStatusEnabled => '已启用';

  @override
  String get toolboxStatusDisabled => '已停用';

  @override
  String get toolboxClamTitle => 'ClamAV';

  @override
  String get toolboxClamCardSubtitle => '扫描任务状态与最近扫描记录';

  @override
  String get toolboxClamTasksTitle => '扫描任务';

  @override
  String get toolboxClamRecordsTitle => '最近扫描记录';

  @override
  String get toolboxFail2banTitle => 'Fail2ban';

  @override
  String get toolboxFail2banCardSubtitle => '封禁策略与拦截记录';

  @override
  String get toolboxFail2banConfigTitle => 'Fail2ban 配置';

  @override
  String get toolboxFail2banEditConfig => '编辑 Fail2ban 配置';

  @override
  String get toolboxFail2banBantime => '封禁时长';

  @override
  String get toolboxFail2banFindtime => '统计窗口';

  @override
  String get toolboxFail2banMaxretry => '最大重试次数';

  @override
  String get toolboxFail2banPort => '端口';

  @override
  String get toolboxFtpTitle => 'FTP';

  @override
  String get toolboxFtpCardSubtitle => 'FTP 服务状态与用户同步';

  @override
  String get toolboxFtpUsersTitle => 'FTP 用户';

  @override
  String get toolboxFtpBaseDir => '根目录';

  @override
  String get toolboxFtpSyncAction => '同步用户';

  @override
  String get toolboxFtpSyncSuccess => 'FTP 用户同步成功';

  @override
  String get toolboxFtpSyncFailed => 'FTP 用户同步失败';

  @override
  String get toolboxDeviceTitle => '设备管理';

  @override
  String get toolboxDeviceCardSubtitle => '主机名、DNS、NTP 与 Swap 配置';

  @override
  String get toolboxDeviceOverviewTitle => '设备概览';

  @override
  String get toolboxDeviceConfigTitle => '设备配置';

  @override
  String get toolboxDeviceUsersTitle => '系统用户';

  @override
  String get toolboxDeviceZoneOptionsTitle => '时区选项';

  @override
  String get toolboxDeviceHostname => '主机名';

  @override
  String get toolboxDeviceDns => 'DNS';

  @override
  String get toolboxDeviceNtp => 'NTP';

  @override
  String get toolboxDeviceSwap => 'Swap';

  @override
  String get toolboxDeviceTimeLabel => '本地时间';

  @override
  String get toolboxDeviceSystemLabel => '系统';

  @override
  String get toolboxDeviceCheckDns => '检查 DNS';

  @override
  String get toolboxDeviceEditConfig => '编辑配置';

  @override
  String get toolboxDeviceCheckDnsSuccess => 'DNS 检查通过';

  @override
  String get toolboxDeviceCheckDnsFailed => 'DNS 检查失败';

  @override
  String get toolboxDeviceDnsRequired => '请先填写 DNS';

  @override
  String get cronjobsSearchHint => '搜索计划任务';

  @override
  String get cronjobsFilterAllGroups => '全部分组';

  @override
  String get cronjobsGroupFilterAction => '按分组筛选';

  @override
  String get cronjobsEmptyTitle => '暂无计划任务';

  @override
  String get cronjobsEmptyDescription => 'Week 4 主链路加载到计划任务后，会在这里展示。';

  @override
  String get cronjobsSpecLabel => '计划表达式';

  @override
  String get cronjobsNextRunLabel => '下次执行';

  @override
  String get cronjobsTypeLabel => '类型';

  @override
  String get cronjobsLastRecordLabel => '最近记录';

  @override
  String get cronjobsEnableAction => '启用';

  @override
  String get cronjobsDisableAction => '停用';

  @override
  String get cronjobsHandleOnceAction => '执行一次';

  @override
  String get cronjobsRecordsAction => '执行记录';

  @override
  String get cronjobsStopAction => '停止';

  @override
  String get cronjobsStatusEnable => '已启用';

  @override
  String get cronjobsStatusDisable => '已停用';

  @override
  String get cronjobsStatusPending => '执行中';

  @override
  String get cronjobsTypeShell => 'Shell';

  @override
  String get cronjobsTypeWebsite => '网站';

  @override
  String get cronjobsTypeDatabase => '数据库';

  @override
  String get cronjobsTypeDirectory => '目录';

  @override
  String get cronjobsTypeSnapshot => '快照';

  @override
  String get cronjobsTypeLog => '日志清理';

  @override
  String cronjobsUpdateStatusConfirm(String name, String status) {
    return '确认将计划任务 $name 更新为 $status 吗？';
  }

  @override
  String cronjobsHandleOnceConfirm(String name) {
    return '确认立即执行一次计划任务 $name 吗？';
  }

  @override
  String cronjobsStopConfirm(String name) {
    return '确认停止正在执行的计划任务 $name 吗？';
  }

  @override
  String get cronjobRecordsEmptyTitle => '暂无执行记录';

  @override
  String get cronjobRecordsEmptyDescription => '计划任务运行后，会在这里展示执行记录。';

  @override
  String get cronjobRecordsStatusAll => '全部';

  @override
  String get cronjobRecordsStatusSuccess => '成功';

  @override
  String get cronjobRecordsStatusWaiting => '等待中';

  @override
  String get cronjobRecordsStatusUnexecuted => '未执行';

  @override
  String get cronjobRecordsStatusFailed => '失败';

  @override
  String get cronjobRecordsIntervalLabel => '耗时';

  @override
  String get cronjobRecordsMessageLabel => '消息';

  @override
  String get cronjobRecordsViewLogTitle => '记录日志';

  @override
  String get cronjobRecordsCleanAction => '清理记录';

  @override
  String get cronjobRecordsCleanConfirm => '确认清理这个计划任务的执行记录吗？';

  @override
  String cronjobsDeleteConfirm(String name) {
    return '确认删除计划任务 $name 吗？';
  }

  @override
  String get cronjobFormCreateTitle => '创建计划任务';

  @override
  String get cronjobFormEditTitle => '编辑计划任务';

  @override
  String get cronjobFormBasicSectionTitle => '基础信息';

  @override
  String get cronjobFormScheduleSectionTitle => '调度规则';

  @override
  String get cronjobFormTargetSectionTitle => '执行目标';

  @override
  String get cronjobFormPolicySectionTitle => '保留与告警';

  @override
  String get cronjobFormTypeLabel => '类型';

  @override
  String get cronjobFormUrlTypeLabel => 'URL';

  @override
  String get cronjobFormCustomSpecLabel => '自定义表达式';

  @override
  String get cronjobFormPreviewAction => '预览下次执行';

  @override
  String get cronjobFormBuilderModeLabel => '使用规则构建';

  @override
  String get cronjobFormRawModeLabel => '使用原始表达式';

  @override
  String get cronjobFormDeleteConfirm => '确认删除这个计划任务吗？';

  @override
  String get cronjobFormBackupTypeLabel => '备份类型';

  @override
  String get cronjobFormDatabaseTypeLabel => '数据库类型';

  @override
  String get cronjobFormBackupArgsLabel => '备份参数';

  @override
  String get cronjobFormBackupDirectoryLabel => '备份目录';

  @override
  String get cronjobFormDirectoryPathLabel => '目录路径';

  @override
  String get cronjobFormSelectedFilesLabel => '选中文件';

  @override
  String get cronjobFormExcludePatternsLabel => '排除规则';

  @override
  String get cronjobFormIncludeImagesLabel => '包含镜像';

  @override
  String get cronjobFormSourceAccountsLabel => '来源账户';

  @override
  String get cronjobFormDownloadAccountLabel => '默认下载路径';

  @override
  String get cronjobFormSecretLabel => '密钥';

  @override
  String get cronjobFormExecutorLabel => '执行器';

  @override
  String get cronjobFormUserLabel => '用户';

  @override
  String get cronjobFormShellInlineLabel => '内联内容';

  @override
  String get cronjobFormShellLibraryLabel => '脚本库';

  @override
  String get cronjobFormShellPathLabel => '路径';

  @override
  String get cronjobFormScriptLibraryLabel => '脚本库';

  @override
  String get cronjobFormScriptPathLabel => '脚本路径';

  @override
  String get cronjobFormScriptLabel => '脚本内容';

  @override
  String get cronjobFormRetainCopiesLabel => '保留副本数';

  @override
  String get cronjobFormRetryTimesLabel => '重试次数';

  @override
  String get cronjobFormTimeoutLabel => '超时';

  @override
  String get cronjobFormTimeoutUnitLabel => '单位';

  @override
  String get cronjobFormSecondsLabel => '秒';

  @override
  String get cronjobFormMinutesLabel => '分钟';

  @override
  String get cronjobFormHoursLabel => '小时';

  @override
  String get cronjobFormIgnoreErrorsLabel => '忽略错误';

  @override
  String get cronjobFormArgumentsLabel => '附加参数';

  @override
  String get cronjobFormEnableAlertsLabel => '启用告警';

  @override
  String get cronjobFormAlertCountLabel => '告警次数';

  @override
  String get cronjobFormScheduleModeLabel => '模式';

  @override
  String get cronjobFormScheduleDaily => '每天';

  @override
  String get cronjobFormScheduleWeekly => '每周';

  @override
  String get cronjobFormScheduleMonthly => '每月';

  @override
  String get cronjobFormScheduleEveryHours => '每 N 小时';

  @override
  String get cronjobFormScheduleEveryMinutes => '每 N 分钟';

  @override
  String get cronjobFormScheduleMinuteLabel => '分钟';

  @override
  String get cronjobFormScheduleHourLabel => '小时';

  @override
  String get cronjobFormScheduleWeekdayLabel => '周几';

  @override
  String get cronjobFormScheduleDayLabel => '日期';

  @override
  String get cronjobFormScheduleIntervalLabel => '间隔';

  @override
  String get scriptLibrarySearchHint => '搜索脚本';

  @override
  String get scriptLibraryFilterAllGroups => '全部分组';

  @override
  String get scriptLibraryGroupFilterAction => '按分组筛选';

  @override
  String get scriptLibraryEmptyTitle => '暂无脚本';

  @override
  String get scriptLibraryEmptyDescription => '脚本库加载到脚本后，会在这里展示。';

  @override
  String get scriptLibraryViewCodeAction => '查看代码';

  @override
  String get scriptLibraryRunAction => '运行';

  @override
  String get scriptLibrarySyncAction => '同步';

  @override
  String get scriptLibraryDeleteAction => '删除';

  @override
  String get scriptLibraryInteractiveLabel => '交互式';

  @override
  String get scriptLibraryInteractiveYes => '是';

  @override
  String get scriptLibraryInteractiveNo => '否';

  @override
  String get scriptLibraryCreatedAtLabel => '创建时间';

  @override
  String get scriptLibrarySyncConfirm => '确认立即同步脚本库吗？';

  @override
  String scriptLibraryDeleteConfirm(String name) {
    return '确认删除脚本 $name 吗？';
  }

  @override
  String get scriptLibraryCodeTitle => '脚本代码';

  @override
  String get scriptLibraryRunTitle => '运行脚本';

  @override
  String get scriptLibraryRunWaiting => '正在连接脚本输出...';

  @override
  String get scriptLibraryRunNoOutput => '暂无输出';

  @override
  String get scriptLibraryRunDisconnected => '脚本输出已断开';

  @override
  String get operationsBackupsTitle => '备份中心';

  @override
  String get operationsBackupAccountFormTitle => '备份账户表单';

  @override
  String get operationsBackupRecordsTitle => '备份记录';

  @override
  String get operationsBackupRecoverTitle => '备份恢复';

  @override
  String get backupAccountsSearchHint => '搜索备份账户';

  @override
  String get backupAccountsFilterAllTypes => '全部类型';

  @override
  String get backupAccountsEmptyTitle => '暂无备份账户';

  @override
  String get backupAccountsEmptyDescription => '添加备份账户后，就可以开始使用备份主链路。';

  @override
  String get backupAccountsScopePublic => '公共';

  @override
  String get backupAccountsScopePrivate => '私有';

  @override
  String get backupAccountsTokenRefreshed => 'Token 已刷新';

  @override
  String get backupAccountsConnectionOk => '连接成功';

  @override
  String get backupAccountsConnectionFailed => '连接失败';

  @override
  String backupAccountsDeleteConfirm(String name) {
    return '确认删除备份账户 $name 吗？';
  }

  @override
  String get backupFilesSheetTitle => '备份文件';

  @override
  String get backupAccountCardBucketLabel => 'Bucket';

  @override
  String get backupAccountCardEndpointLabel => 'Endpoint';

  @override
  String get backupAccountCardPathLabel => '路径';

  @override
  String get backupAccountCardBrowseFilesAction => '浏览文件';

  @override
  String get backupAccountCardRefreshTokenAction => '刷新 Token';

  @override
  String get backupFormBasicSectionTitle => '基础信息';

  @override
  String get backupFormCredentialsSectionTitle => '凭据';

  @override
  String get backupFormStorageSectionTitle => '存储配置';

  @override
  String get backupFormVerifySectionTitle => '连接验证';

  @override
  String get backupFormPublicScopeLabel => '公共范围';

  @override
  String get backupFormProviderTypeLabel => 'Provider 类型';

  @override
  String get backupFormAccessKeyLabel => 'Access Key';

  @override
  String get backupFormUsernameAccessKeyLabel => '用户名 / Access Key';

  @override
  String get backupFormCredentialLabel => '凭据';

  @override
  String get backupFormAddressLabel => '地址';

  @override
  String get backupFormPortLabel => '端口';

  @override
  String get backupFormChinaCloudLabel => '使用中国区云';

  @override
  String get backupFormClientIdLabel => 'Client ID';

  @override
  String get backupFormClientSecretLabel => 'Client Secret';

  @override
  String get backupFormRedirectUriLabel => '回调地址';

  @override
  String get backupFormAuthCodeLabel => '授权码';

  @override
  String get backupFormOpenAuthorizeAction => '打开授权页';

  @override
  String get backupFormTokenJsonLabel => 'Token JSON';

  @override
  String get backupFormDriveIdLabel => 'Drive ID';

  @override
  String get backupFormRefreshTokenLabel => 'Refresh Token';

  @override
  String get backupFormRememberCredentialsLabel => '记住凭据';

  @override
  String get backupFormRegionLabel => '地域';

  @override
  String get backupFormDomainLabel => '域名';

  @override
  String get backupFormEndpointLabel => 'Endpoint';

  @override
  String get backupFormBucketLabel => 'Bucket';

  @override
  String get backupFormBackupPathLabel => '备份路径';

  @override
  String get backupFormVerifiedLabel => '已验证';

  @override
  String get backupFormNotVerifiedLabel => '未验证';

  @override
  String get backupFormTestingLabel => '验证中...';

  @override
  String get backupFormTestConnectionAction => '测试连接';

  @override
  String get backupRecordsEmptyTitle => '暂无备份记录';

  @override
  String get backupRecordsEmptyDescription => '执行备份后，会在这里展示记录。';

  @override
  String get backupRecordsFilterAction => '筛选';

  @override
  String backupRecordsDeleteConfirm(String name) {
    return '确认删除备份记录 $name 吗？';
  }

  @override
  String get backupRecordsTypeLabel => '类型';

  @override
  String get backupRecordsNameLabel => '名称';

  @override
  String get backupRecordsDetailNameLabel => '详细名称';

  @override
  String get backupRecordsApplyAction => '应用';

  @override
  String get backupRecordsStatusLabel => '状态';

  @override
  String get backupRecordsSizeLabel => '大小';

  @override
  String get backupRecordsDownloadAction => '下载';

  @override
  String get backupRecordsRecoverAction => '恢复';

  @override
  String get backupRecoverResourceStepTitle => '资源';

  @override
  String get backupRecoverRecordStepTitle => '记录';

  @override
  String get backupRecoverConfirmStepTitle => '确认';

  @override
  String get backupRecoverTypeLabel => '类型';

  @override
  String get backupRecoverAppLabel => '应用';

  @override
  String get backupRecoverWebsiteLabel => '网站';

  @override
  String get backupRecoverDatabaseLabel => '数据库';

  @override
  String get backupRecoverOtherLabel => '其他';

  @override
  String get backupRecoverSourceTypeLabel => '来源类型';

  @override
  String get backupRecoverDatabaseTypeLabel => '数据库类型';

  @override
  String get backupRecoverDatabaseItemLabel => '数据库项';

  @override
  String get backupRecoverLoadRecordsAction => '加载记录';

  @override
  String get backupRecoverNoCandidateRecords => '暂无可恢复记录';

  @override
  String get backupRecoverRecordLabel => '备份记录';

  @override
  String get backupRecoverSecretLabel => '密钥';

  @override
  String get backupRecoverTimeoutLabel => '超时';

  @override
  String get backupRecoverStartAction => '开始恢复';

  @override
  String get backupRecoverConfirmMessage => '确认从所选备份记录发起恢复吗？';

  @override
  String backupRecoverUnsupportedTypeHint(String type) {
    return '当前主链先保留 $type 记录的恢复上下文，直接恢复操作暂未开放。';
  }

  @override
  String backupRecoverUnsupportedTypeSubmitHint(String type) {
    return '当前暂不支持对 $type 记录直接提交恢复。';
  }

  @override
  String backupResourceTypeUnknownLabel(String type) {
    return '未知类型：$type';
  }

  @override
  String get backupErrorOauthOpenFailed => '无法打开授权页面';

  @override
  String get backupErrorOauthUnsupportedProvider => '当前备份提供商不支持移动端授权流程';

  @override
  String get backupErrorRecordPathEmpty => '备份记录路径为空';

  @override
  String get backupErrorRecordDownloadEmpty => '下载得到的备份文件为空';

  @override
  String get cronjobFormErrorImportInvalidJson => '导入的计划任务文件必须是 JSON 数组。';

  @override
  String get cronjobFormErrorExportEmpty => '导出的计划任务文件为空。';

  @override
  String get cronjobFormErrorSpecRequired => '计划任务表达式不能为空。';

  @override
  String get cronjobFormErrorUnsupportedType => '当前移动端表单暂不支持该计划任务类型。';

  @override
  String get backupTypeLocal => '本地';

  @override
  String get backupTypeSftp => 'SFTP';

  @override
  String get backupTypeWebdav => 'WebDAV';

  @override
  String get backupTypeS3 => 'S3';

  @override
  String get backupTypeMinio => 'MINIO';

  @override
  String get backupTypeOss => 'OSS';

  @override
  String get backupTypeCos => 'COS';

  @override
  String get backupTypeKodo => 'KODO';

  @override
  String get backupTypeUpyun => 'UPYUN';

  @override
  String get backupTypeOneDrive => 'OneDrive';

  @override
  String get backupTypeGoogleDrive => 'Google Drive';

  @override
  String get backupTypeAliyun => '阿里云盘';

  @override
  String get backupTypeApp => '应用';

  @override
  String get backupTypeWebsite => '网站';

  @override
  String get backupTypeDatabase => '数据库';

  @override
  String get backupTypeDirectory => '目录';

  @override
  String get backupTypeSnapshot => '快照';

  @override
  String get backupTypeLog => '日志';

  @override
  String get backupTypeContainer => '容器';

  @override
  String get backupTypeCompose => '编排';

  @override
  String get backupTypeOther => '其他';

  @override
  String get databaseTypeMysql => 'MySQL';

  @override
  String get databaseTypeMysqlCluster => 'MySQL 集群';

  @override
  String get databaseTypeMariadb => 'MariaDB';

  @override
  String get databaseTypePostgresql => 'PostgreSQL';

  @override
  String get databaseTypePostgresqlCluster => 'PostgreSQL 集群';

  @override
  String get databaseTypeRedis => 'Redis';

  @override
  String get cronjobFormAppsLabel => '应用';

  @override
  String get cronjobFormWebsitesLabel => '网站';

  @override
  String get cronjobFormDatabasesLabel => '数据库';

  @override
  String get cronjobFormIgnoreAppsLabel => '忽略应用';

  @override
  String get cronjobFormShellModeInline => '内联';

  @override
  String get cronjobFormShellModeLibrary => '脚本库';

  @override
  String get cronjobFormShellModePath => '路径';

  @override
  String cronjobFormUrlItemLabel(int index) {
    return 'URL $index';
  }

  @override
  String get cronjobFormAddUrlAction => '添加 URL';

  @override
  String get cronjobFormAlertMethodMail => '邮件';

  @override
  String get cronjobFormAlertMethodWecom => '企业微信';

  @override
  String get cronjobFormAlertMethodDingtalk => '钉钉';

  @override
  String cronjobFormCustomSpecItemLabel(int index) {
    return '自定义表达式 $index';
  }

  @override
  String get cronjobFormImportInvalidJson => '导入的计划任务文件必须是 JSON 数组';

  @override
  String get cronjobFormExportEmpty => '导出的计划任务文件为空';

  @override
  String get cronjobFormSpecRequired => '计划任务表达式不能为空';

  @override
  String get cronjobFormUnsupportedType => '当前移动端暂不支持这种计划任务类型';

  @override
  String cronjobFormUnknownBackupType(String type) {
    return '未知备份类型：$type';
  }

  @override
  String cronjobFormUnknownDatabaseType(String type) {
    return '未知数据库类型：$type';
  }

  @override
  String cronjobFormUnknownAlertMethod(String method) {
    return '未知告警方式：$method';
  }

  @override
  String cronjobFormUnknownError(String message) {
    return '计划任务表单出现未预期错误：$message';
  }

  @override
  String get operationsLogsTitle => '日志中心';

  @override
  String get operationsSystemLogViewerTitle => '系统日志查看';

  @override
  String get operationsTaskLogDetailTitle => '任务日志详情';

  @override
  String get logsCenterTabOperation => '操作';

  @override
  String get logsCenterTabLogin => '登录';

  @override
  String get logsCenterTabTask => '任务';

  @override
  String get logsCenterTabSystem => '系统';

  @override
  String get logsOperationSourceLabel => '来源';

  @override
  String get logsOperationActionLabel => '操作';

  @override
  String get logsOperationEmptyTitle => '暂无操作日志';

  @override
  String get logsOperationEmptyDescription => '服务端记录操作后，会在这里显示操作日志。';

  @override
  String get logsLoginIpLabel => 'IP';

  @override
  String get logsLoginEmptyTitle => '暂无登录日志';

  @override
  String get logsLoginEmptyDescription => '服务端记录认证活动后，会在这里显示登录日志。';

  @override
  String get logsTaskTypeLabel => '任务类型';

  @override
  String logsTaskExecutingCountLabel(int count) {
    return '执行中：$count';
  }

  @override
  String get logsTaskOpenDetailAction => '查看日志';

  @override
  String get logsTaskEmptyTitle => '暂无任务日志';

  @override
  String get logsTaskEmptyDescription => '服务端执行后台任务后，会在这里显示任务日志。';

  @override
  String get logsSystemFilesLabel => '日志文件';

  @override
  String get logsSystemSourceLabel => '来源';

  @override
  String get logsSystemSourceAgent => 'Agent';

  @override
  String get logsSystemSourceCore => 'Core';

  @override
  String get logsSystemOpenViewerAction => '打开查看器';

  @override
  String get logsSystemEmptyTitle => '暂无系统日志文件';

  @override
  String get logsSystemEmptyDescription => '服务端暴露日志输出后，会在这里显示系统日志文件。';

  @override
  String get logsSystemViewerNoFileSelected => '请选择要查看的日志文件。';

  @override
  String get logsSystemWatchLabel => '监听';

  @override
  String get logsStatusAll => '全部';

  @override
  String get logsStatusSuccess => '成功';

  @override
  String get logsStatusFailed => '失败';

  @override
  String get logsStatusExecuting => '执行中';

  @override
  String get logsTaskDetailIdLabel => '任务 ID';

  @override
  String get logsTaskDetailTypeLabel => '任务类型';

  @override
  String get logsTaskDetailStatusLabel => '状态';

  @override
  String get logsTaskDetailCurrentStepLabel => '当前步骤';

  @override
  String get logsTaskDetailCreatedAtLabel => '创建时间';

  @override
  String get logsTaskDetailLogFileLabel => '日志文件';

  @override
  String get logsTaskDetailErrorLabel => '错误信息';

  @override
  String get logsOperationLoadFailed => '加载操作日志失败。';

  @override
  String get logsLoginLoadFailed => '加载登录日志失败。';

  @override
  String get logsTaskLoadFailed => '加载任务日志失败。';

  @override
  String get logsTaskDetailLoadFailed => '加载任务日志内容失败。';

  @override
  String get logsTaskMissingTaskId => '缺少任务 ID，无法加载任务日志内容。';

  @override
  String get logsSystemFilesLoadFailed => '加载系统日志文件失败。';

  @override
  String get logsSystemContentLoadFailed => '加载系统日志内容失败。';

  @override
  String get operationsRuntimesTitle => '运行时';

  @override
  String get operationsRuntimeDetailTitle => '运行时详情';

  @override
  String get operationsRuntimeFormTitle => '运行时表单';

  @override
  String get runtimeFormCreateTitle => '创建运行时';

  @override
  String get runtimeFormEditTitle => '编辑运行时';

  @override
  String get runtimeOverviewTab => '概览';

  @override
  String get runtimeConfigTab => '配置';

  @override
  String get runtimeAdvancedTab => '高级';

  @override
  String get runtimeSearchHint => '搜索运行时...';

  @override
  String get runtimeEmptyTitle => '暂无运行时';

  @override
  String get runtimeEmptyDescription => '当前语言分类下的运行时会显示在这里。';

  @override
  String get runtimeActionStart => '启动';

  @override
  String get runtimeActionStop => '停止';

  @override
  String get runtimeActionRestart => '重启';

  @override
  String get runtimeActionSync => '同步';

  @override
  String runtimeActionUnknown(String action) {
    return '未知操作：$action';
  }

  @override
  String get runtimeTypePhp => 'PHP';

  @override
  String get runtimeTypeNode => 'Node';

  @override
  String get runtimeTypeJava => 'Java';

  @override
  String get runtimeTypeGo => 'Go';

  @override
  String get runtimeTypePython => 'Python';

  @override
  String get runtimeTypeDotnet => '.NET';

  @override
  String runtimeTypeUnknown(String type) {
    return '未知运行时：$type';
  }

  @override
  String get runtimeResourceLocal => '本地';

  @override
  String get runtimeResourceAppStore => '应用商店';

  @override
  String runtimeResourceUnknown(String resource) {
    return '未知来源：$resource';
  }

  @override
  String get runtimeStatusAll => '全部';

  @override
  String get runtimeStatusRunning => '运行中';

  @override
  String get runtimeStatusStopped => '已停止';

  @override
  String get runtimeStatusError => '错误';

  @override
  String get runtimeStatusStarting => '启动中';

  @override
  String get runtimeStatusBuilding => '构建中';

  @override
  String get runtimeStatusRecreating => '重建中';

  @override
  String get runtimeStatusSystemRestart => '系统重启中';

  @override
  String runtimeStatusUnknown(String status) {
    return '未知状态：$status';
  }

  @override
  String get runtimeFieldType => '类型';

  @override
  String get runtimeFieldStatus => '状态';

  @override
  String get runtimeFieldVersion => '版本';

  @override
  String get runtimeFieldResource => '来源';

  @override
  String get runtimeFieldImage => '镜像';

  @override
  String get runtimeFieldCodeDir => '代码目录';

  @override
  String get runtimeFieldExternalPort => '外部端口';

  @override
  String get runtimeFieldPath => '路径';

  @override
  String get runtimeFieldSource => '源地址';

  @override
  String get runtimeFieldRemark => '备注';

  @override
  String get runtimeFieldHostIp => '主机 IP';

  @override
  String get runtimeFieldContainerName => '容器名称';

  @override
  String get runtimeFieldContainerStatus => '容器状态';

  @override
  String get runtimeFieldExecScript => '运行脚本';

  @override
  String get runtimeFieldPackageManager => '包管理器';

  @override
  String get runtimeFieldCreatedAt => '创建时间';

  @override
  String get runtimeFieldParams => '参数';

  @override
  String get runtimeFieldRebuild => '保存时重建';

  @override
  String get runtimeFormBasicSectionTitle => '基础信息';

  @override
  String get runtimeFormRuntimeSectionTitle => '运行时配置';

  @override
  String get runtimeFormAdvancedSectionTitle => '高级设置';

  @override
  String get runtimeFormAppStoreCreateWeek8Hint =>
      '应用商店运行时创建留到 Week 8 的专用向导，本周只支持手动运行时骨架。';

  @override
  String get runtimeFormPhpCreateWeek8Hint =>
      'PHP 创建流保留到 Week 8 的专用表单，本周先收口通用运行时骨架。';

  @override
  String get runtimeFormNameRequired => '运行时名称不能为空。';

  @override
  String get runtimeFormImageRequired => '运行时镜像不能为空。';

  @override
  String get runtimeFormCodeDirRequired => '代码目录不能为空。';

  @override
  String get runtimeFormPortInvalid => '外部端口必须大于 0。';

  @override
  String get runtimeFormContainerNameRequired => '容器名称不能为空。';

  @override
  String get runtimeFormExecScriptRequired => '当前运行时类型必须填写运行脚本。';

  @override
  String get runtimeFormPackageManagerRequired => 'Node 运行时必须选择包管理器。';

  @override
  String get runtimeAdvancedRequiresRunning => '运行时启动后，才会解锁更多语言专属高级能力。';

  @override
  String runtimeAdvancedSummary(
      int ports, int environments, int volumes, int hosts) {
    return '高级配置统计：$ports 个端口、$environments 个环境变量、$volumes 个挂载、$hosts 个额外主机。';
  }

  @override
  String runtimeDeleteConfirm(String name) {
    return '确认删除运行时 $name 吗？';
  }

  @override
  String runtimeOperateConfirm(String action, String name) {
    return '确认对运行时 $name 执行 $action 吗？';
  }

  @override
  String get runtimeListLoadFailed => '加载运行时列表失败。';

  @override
  String get runtimeDetailLoadFailed => '加载运行时详情失败。';

  @override
  String get runtimeFormLoadFailed => '加载运行时表单数据失败。';

  @override
  String get runtimeFormSaveFailed => '保存运行时失败。';

  @override
  String get runtimeSyncFailed => '同步运行时状态失败。';

  @override
  String get runtimeDeleteFailed => '删除运行时失败。';

  @override
  String get runtimeOperateFailed => '执行运行时操作失败。';

  @override
  String get runtimeRemarkSaveFailed => '保存运行时备注失败。';

  @override
  String get runtimeRemarkTooLong => '备注不能超过 128 个字符。';

  @override
  String runtimeNodeScriptExecuting(String name) {
    return '正在执行脚本 $name，并回读运行时状态...';
  }

  @override
  String get runtimeNodeScriptCompleted => '脚本执行完成';

  @override
  String get runtimeNodeScriptFailed => '脚本执行失败';

  @override
  String runtimeNodeScriptRuntimeStatus(String status) {
    return '运行时状态：$status';
  }

  @override
  String runtimeNodeScriptRuntimeMessage(String message) {
    return '运行时消息：$message';
  }

  @override
  String runtimeNodeScriptPollAttempts(int count) {
    return '状态轮询次数：$count';
  }

  @override
  String runtimeNodeScriptCompletedWithStatus(String status) {
    return '脚本执行完成，运行时状态：$status';
  }

  @override
  String runtimeNodeScriptFailedWithStatus(String status) {
    return '脚本执行失败，运行时状态：$status';
  }

  @override
  String get runtimeNodeScriptWaitTimeout => '脚本已触发，但状态确认超时，请稍后手动刷新确认。';

  @override
  String get operationsPhpExtensionsTitle => 'PHP 扩展';

  @override
  String get operationsPhpConfigTitle => 'PHP 配置';

  @override
  String get runtimePhpTabBasic => '基础';

  @override
  String get runtimePhpTabFpm => 'FPM';

  @override
  String get runtimePhpTabContainer => '容器';

  @override
  String get runtimePhpTabPhpFile => 'PHP 文件';

  @override
  String get runtimePhpTabFpmFile => 'FPM 文件';

  @override
  String get runtimePhpFpmConfigTitle => 'FPM 参数';

  @override
  String get runtimePhpFpmMode => '进程管理模式';

  @override
  String get runtimePhpFpmMaxChildren => 'pm.max_children';

  @override
  String get runtimePhpFpmStartServers => 'pm.start_servers';

  @override
  String get runtimePhpFpmMinSpareServers => 'pm.min_spare_servers';

  @override
  String get runtimePhpFpmMaxSpareServers => 'pm.max_spare_servers';

  @override
  String get runtimePhpContainerExtraHosts => '额外主机';

  @override
  String get runtimePhpContainerPort => '容器端口';

  @override
  String get runtimePhpHostPort => '主机端口';

  @override
  String get runtimePhpHostIp => '主机 IP';

  @override
  String get runtimePhpVolumeTarget => '目标';

  @override
  String get operationsSupervisorTitle => 'Supervisor 管理';

  @override
  String get runtimeSupervisorStatusWarning => '部分运行';

  @override
  String get operationsNodeModulesTitle => 'Node 模块';

  @override
  String get operationsNodeScriptsTitle => 'Node 脚本';

  @override
  String get commandsCreateTitle => '创建命令';

  @override
  String get commandsEditTitle => '编辑命令';

  @override
  String get commandsSearchHint => '搜索命令';

  @override
  String get commandsFilterAllGroups => '全部分组';

  @override
  String get commandsGroupFilterAction => '按分组筛选';

  @override
  String get commandsEmptyTitle => '暂无命令';

  @override
  String get commandsEmptyDescription => '先创建快捷命令，或导入 CSV 建立你的命令库。';

  @override
  String get commandsGroupFieldLabel => '分组';

  @override
  String get commandsCommandFieldLabel => '命令';

  @override
  String get commandsPreviewLabel => '命令预览';

  @override
  String get commandsImportPreviewEmptyTitle => '没有可导入内容';

  @override
  String get commandsImportPreviewEmpty => 'CSV 预览没有返回任何命令。';

  @override
  String get commandsImportingLabel => '导入预览已就绪';

  @override
  String get commandsSelectAll => '全选';

  @override
  String get commandsApplyGroup => '统一改组';

  @override
  String commandsExportSaved(String path) {
    return '命令导出已保存到 $path';
  }

  @override
  String commandsDeleteConfirm(String name) {
    return '确认删除命令 $name 吗？';
  }

  @override
  String commandsDeleteSelectedConfirm(int count) {
    return '确认删除已选中的 $count 条命令吗？';
  }

  @override
  String get hostAssetsCreateTitle => '创建主机资产';

  @override
  String get hostAssetsEditTitle => '编辑主机资产';

  @override
  String get hostAssetsSearchHint => '搜索主机';

  @override
  String get hostAssetsFilterAllGroups => '全部分组';

  @override
  String get hostAssetsGroupFilterAction => '按分组筛选';

  @override
  String get hostAssetsEmptyTitle => '暂无主机';

  @override
  String get hostAssetsEmptyDescription => '先添加一个主机资产，在手机端统一管理 SSH 目标和连接配置。';

  @override
  String hostAssetsDeleteConfirm(String name) {
    return '确认删除主机 $name 吗？';
  }

  @override
  String hostAssetsDeleteSelectedConfirm(int count) {
    return '确认删除已选中的 $count 台主机吗？';
  }

  @override
  String get hostAssetsBasicSectionTitle => '基础信息';

  @override
  String get hostAssetsAuthSectionTitle => '认证方式';

  @override
  String get hostAssetsConnectionSectionTitle => '连接验证';

  @override
  String get hostAssetsAddressLabel => '地址';

  @override
  String get hostAssetsPortLabel => '端口';

  @override
  String get hostAssetsGroupLabel => '分组';

  @override
  String get hostAssetsUserLabel => '用户';

  @override
  String get hostAssetsPasswordLabel => '密码';

  @override
  String get hostAssetsPrivateKeyLabel => '私钥';

  @override
  String get hostAssetsPassPhraseLabel => '密钥口令';

  @override
  String get hostAssetsRememberPasswordLabel => '记住密码';

  @override
  String get hostAssetsPasswordMode => '密码';

  @override
  String get hostAssetsKeyMode => '私钥';

  @override
  String get hostAssetsTestAction => '测试连接';

  @override
  String get hostAssetsMoveGroupAction => '移动分组';

  @override
  String get hostAssetsStatusNotTested => '未测试';

  @override
  String get hostAssetsStatusSuccess => '成功';

  @override
  String get hostAssetsStatusFailed => '失败';

  @override
  String get hostAssetsConnectionVerified => '连接验证通过';

  @override
  String get hostAssetsConnectionNeedsTest => '保存前请先完成连接测试';

  @override
  String get hostAssetsTestFailed => '连接测试失败';

  @override
  String get sshSettingsServiceSectionTitle => '服务';

  @override
  String get sshSettingsAuthenticationSectionTitle => '认证';

  @override
  String get sshSettingsNetworkSectionTitle => '网络';

  @override
  String get sshSettingsRawFileSectionTitle => '原始配置文件';

  @override
  String get sshAutoStartLabel => '开机启动';

  @override
  String get sshPortLabel => '端口';

  @override
  String get sshListenAddressLabel => '监听地址';

  @override
  String get sshPermitRootLoginLabel => '允许 root 登录';

  @override
  String get sshPasswordAuthenticationLabel => '密码认证';

  @override
  String get sshPubkeyAuthenticationLabel => '公钥认证';

  @override
  String get sshUseDnsLabel => '使用 DNS';

  @override
  String get sshCurrentUserLabel => '当前用户';

  @override
  String get sshRawFilePlaceholder => '# SSH 配置文件为空。';

  @override
  String get sshReloadAction => '重新加载';

  @override
  String get sshSaveRawFileConfirm => '确认用当前内容覆盖 SSH 配置文件吗？';

  @override
  String sshOperateConfirm(String operation) {
    return '确认执行 SSH 操作：$operation 吗？';
  }

  @override
  String sshUpdateSettingConfirm(String label, String value) {
    return '确认将 $label 更新为 $value 吗？';
  }

  @override
  String get sshCertsEmptyTitle => '暂无 SSH 证书';

  @override
  String get sshCertsEmptyDescription => '先创建或同步一个 SSH 证书，用于面板管理密钥登录。';

  @override
  String get sshCertSyncConfirm => '确认从当前服务器同步 SSH 证书吗？';

  @override
  String sshCertDeleteConfirm(String name) {
    return '确认删除 SSH 证书 $name 吗？';
  }

  @override
  String get sshCertCreateTitle => '创建 SSH 证书';

  @override
  String get sshCertEditTitle => '编辑 SSH 证书';

  @override
  String get sshCertEncryptionModeLabel => '加密模式';

  @override
  String get sshCertPassPhraseLabel => '口令';

  @override
  String get sshCertPublicKeyLabel => '公钥';

  @override
  String get sshCertPrivateKeyLabel => '私钥';

  @override
  String get sshCertModeLabel => '创建方式';

  @override
  String get sshCertModeGenerate => '生成';

  @override
  String get sshCertModeInput => '手动输入';

  @override
  String get sshCertModeImport => '导入';

  @override
  String get sshCertCreatedAtLabel => '创建时间';

  @override
  String get sshAuthModePassword => '密码';

  @override
  String get sshAuthModeKey => '密钥';

  @override
  String get sshLogsEmptyTitle => '暂无 SSH 日志';

  @override
  String get sshLogsEmptyDescription => '服务器产生 SSH 登录记录后，会在这里展示。';

  @override
  String get sshLogsSearchHint => '搜索 IP、用户或消息';

  @override
  String get sshLogsStatusAll => '全部';

  @override
  String get sshLogsStatusSuccess => '成功';

  @override
  String get sshLogsStatusFailed => '失败';

  @override
  String get sshLogsIpLabel => 'IP';

  @override
  String get sshLogsAreaLabel => '地区';

  @override
  String get sshLogsAuthModeLabel => '认证方式';

  @override
  String get sshLogsTimeLabel => '时间';

  @override
  String get sshLogsMessageLabel => '消息';

  @override
  String sshLogsExportSaved(String path) {
    return 'SSH 日志已导出到 $path';
  }

  @override
  String get sshLogCopied => 'SSH 日志已复制';

  @override
  String get sshSessionsEmptyTitle => '暂无 SSH 会话';

  @override
  String get sshSessionsEmptyDescription => 'websocket 返回活跃 SSH 会话后，会在这里展示。';

  @override
  String get sshSessionsLoginUserLabel => '登录用户';

  @override
  String get sshSessionsLoginIpLabel => '登录 IP';

  @override
  String get sshSessionsTerminalLabel => 'TTY';

  @override
  String get sshSessionsHostLabel => '主机';

  @override
  String get sshSessionsLoginTimeLabel => '登录时间';

  @override
  String sshSessionDisconnectConfirm(String username) {
    return '确认断开用户 $username 的 SSH 会话吗？';
  }

  @override
  String get processesSearchPidLabel => 'PID';

  @override
  String get processesSearchNameLabel => '名称';

  @override
  String get processesSearchUserLabel => '用户';

  @override
  String get processesFilterStatusLabel => '状态';

  @override
  String get processesSortCpu => 'CPU';

  @override
  String get processesSortMemory => '内存';

  @override
  String get processesSortName => '名称';

  @override
  String get processesSortPid => 'PID';

  @override
  String get processesEmptyTitle => '暂无进程';

  @override
  String get processesEmptyDescription => 'websocket 返回进程列表后，会在这里展示。';

  @override
  String get processesListeningPortsLabel => '监听端口';

  @override
  String get processesConnectionsLabel => '连接数';

  @override
  String get processesStartTimeLabel => '启动时间';

  @override
  String get processesThreadsLabel => '线程数';

  @override
  String processesStopConfirm(String name) {
    return '确认停止进程 $name 吗？';
  }

  @override
  String get processesStatusRunning => '运行中';

  @override
  String get processesStatusSleep => '休眠';

  @override
  String get processesStatusStop => '已停止';

  @override
  String get processesStatusIdle => '空闲';

  @override
  String get processesStatusWait => '等待';

  @override
  String get processesStatusLock => '锁定';

  @override
  String get processesStatusZombie => '僵尸';

  @override
  String get processDetailOverviewSectionTitle => '概览';

  @override
  String get processDetailMemorySectionTitle => '内存';

  @override
  String get processDetailOpenFilesSectionTitle => '打开文件';

  @override
  String get processDetailConnectionsSectionTitle => '连接';

  @override
  String get processDetailEnvironmentSectionTitle => '环境变量';

  @override
  String get processDetailParentPidLabel => '父进程 PID';

  @override
  String get processDetailDiskReadLabel => '磁盘读取';

  @override
  String get processDetailDiskWriteLabel => '磁盘写入';

  @override
  String get processDetailCommandLineLabel => '命令行';

  @override
  String get processDetailNoEnvironment => '暂无环境变量';

  @override
  String get processDetailNoConnections => '暂无网络连接';

  @override
  String get processDetailNoOpenFiles => '暂无打开文件';

  @override
  String get operationsPlaceholderBackAction => '返回运维中心';

  @override
  String operationsPlaceholderDescription(String moduleName, int week) {
    return '$moduleName 计划在第 $week 周交付。Week 1 仅先打通路由、共享基础设施与可评审骨架。';
  }

  @override
  String get operationsGroupSelectorTitle => '选择分组';

  @override
  String get operationsGroupCreateTitle => '创建分组';

  @override
  String get operationsGroupRenameTitle => '重命名分组';

  @override
  String get operationsGroupNameHint => '请输入分组名称';

  @override
  String get operationsGroupEmptyDescription =>
      '当前模块还没有可用分组，先创建一个，后续主机、命令或计划任务就能复用。';

  @override
  String get operationsGroupDefaultLabel => '默认分组';

  @override
  String get operationsGroupDeleteConfirmTitle => '删除分组';

  @override
  String operationsGroupDeleteConfirmMessage(String groupName) {
    return '确认删除分组 $groupName 吗？后续相关模块项需要重新指定分组。';
  }
}
