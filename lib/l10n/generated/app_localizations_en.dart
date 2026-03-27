// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => '1Panel Client';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonImport => 'Import';

  @override
  String get commonExport => 'Export';

  @override
  String get commonMore => 'More';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonLoad => 'Load';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveSuccess => 'Saved successfully';

  @override
  String get commonSaveFailed => 'Failed to save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUpload => 'Upload';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get commonEmpty => 'No data';

  @override
  String get commonLoadFailedTitle => 'Failed to load';

  @override
  String get websitesPageTitle => 'Websites';

  @override
  String get websitesStatsTitle => 'Statistics';

  @override
  String get websitesStatsTotal => 'Total';

  @override
  String get websitesStatsRunning => 'Running';

  @override
  String get websitesStatsStopped => 'Stopped';

  @override
  String get websitesEmptyTitle => 'No websites';

  @override
  String get websitesEmptySubtitle => 'Create a website in 1Panel first.';

  @override
  String get websitesUnknownDomain => 'Unknown website';

  @override
  String get websitesStatusLabel => 'Status';

  @override
  String get websitesTypeLabel => 'Type';

  @override
  String get websitesStatusRunning => 'Running';

  @override
  String get websitesStatusStopped => 'Stopped';

  @override
  String get websitesActionStart => 'Start';

  @override
  String get websitesActionStop => 'Stop';

  @override
  String get websitesActionRestart => 'Restart';

  @override
  String get websitesActionDelete => 'Delete';

  @override
  String get websitesOperateSuccess => 'Operation successful';

  @override
  String get websitesOperateFailed => 'Operation failed';

  @override
  String websitesLoadFailedMessage(String error) {
    return '$error';
  }

  @override
  String get websitesDefaultName => 'default';

  @override
  String get websitesDeleteTitle => 'Delete website';

  @override
  String websitesDeleteMessage(String domain) {
    return 'Are you sure you want to delete $domain? This action cannot be undone.';
  }

  @override
  String get websitesDeleteSuccess => 'Website deleted';

  @override
  String get websitesDetailTitle => 'Website';

  @override
  String get websitesTabOverview => 'Overview';

  @override
  String get websitesTabConfig => 'Config';

  @override
  String get websitesTabDomains => 'Domains';

  @override
  String get websitesTabSsl => 'SSL';

  @override
  String get websitesTabRewrite => 'Rewrite';

  @override
  String get websitesTabProxy => 'Proxy';

  @override
  String get websitesSslInfoTitle => 'Certificate';

  @override
  String get websitesSslNoCert => 'No certificate bound';

  @override
  String get websitesSslPrimaryDomain => 'Primary domain';

  @override
  String get websitesSslExpireDate => 'Expires';

  @override
  String get websitesSslStatus => 'Status';

  @override
  String get websitesSslAutoRenew => 'Auto renew';

  @override
  String get websitesSslDownload => 'Download';

  @override
  String get websitesConfigHint => 'Nginx config content';

  @override
  String get websitesJsonHint => 'JSON content';

  @override
  String get websitesDomainAddTitle => 'Add domain';

  @override
  String get websitesDomainLabel => 'Domain';

  @override
  String get websitesDomainEmpty => 'No domains';

  @override
  String get websitesDomainDefault => 'Default';

  @override
  String get websitesDomainSslLabel => 'SSL';

  @override
  String get websitesRewriteNameLabel => 'Rewrite name';

  @override
  String get websitesRewriteHint => 'Rewrite content';

  @override
  String get websitesProxyNameLabel => 'Proxy name';

  @override
  String get websitesProxyHint => 'Proxy content';

  @override
  String get websitesNginxAdvancedAction => 'Advanced';

  @override
  String get websitesNginxAdvancedTitle => 'Advanced Nginx Config';

  @override
  String get websitesNginxScopeTitle => 'Scope Load';

  @override
  String get websitesNginxScopeLabel => 'Scope';

  @override
  String get websitesNginxScopeWebsiteIdLabel => 'Website ID (optional)';

  @override
  String get websitesNginxScopeLoad => 'Load scope config';

  @override
  String get websitesNginxScopeResultLabel => 'Scope result';

  @override
  String get websitesNginxUpdateTitle => 'Scope Update';

  @override
  String get websitesNginxUpdateOperateLabel => 'Operate';

  @override
  String get websitesNginxUpdateScopeLabel => 'Scope';

  @override
  String get websitesNginxUpdateWebsiteIdLabel => 'Website ID (optional)';

  @override
  String get websitesNginxUpdateParamsLabel => 'Params JSON';

  @override
  String get websitesNginxUpdateAction => 'Apply update';

  @override
  String get websitesProtocolLabel => 'Protocol';

  @override
  String get websitesDetailInfoTitle => 'Website info';

  @override
  String get websitesSitePathLabel => 'Site path';

  @override
  String get websitesRuntimeLabel => 'Runtime';

  @override
  String get websitesSslStatusLabel => 'SSL status';

  @override
  String get websitesSslExpireLabel => 'SSL expires';

  @override
  String get websitesDetailActionsTitle => 'Quick actions';

  @override
  String get websitesConfigPageTitle => 'Config';

  @override
  String get websitesConfigPageSubtitle => 'Nginx config & PHP version';

  @override
  String get websitesDomainsPageTitle => 'Domains';

  @override
  String get websitesDomainsPageSubtitle => 'Bind and manage domains';

  @override
  String get websitesSslPageTitle => 'SSL certificates';

  @override
  String get websitesSslPageSubtitle => 'Certificate settings & HTTPS';

  @override
  String get websitesOpenrestySubtitle => 'Service status & module management';

  @override
  String get websitesConfigEditorTitle => 'Nginx config file';

  @override
  String get websitesConfigScopeTitle => 'Advanced config';

  @override
  String get websitesConfigScopeLabel => 'Scope';

  @override
  String get websitesConfigScopeEmpty => 'No scope config';

  @override
  String websitesConfigScopeEditTitle(String name) {
    return 'Edit $name params';
  }

  @override
  String get websitesConfigScopeValuesLabel => 'Param list';

  @override
  String get websitesConfigScopeValuesHint =>
      'Separate multiple params with commas';

  @override
  String get websitesPhpVersionTitle => 'PHP version';

  @override
  String get websitesPhpRuntimeIdLabel => 'Runtime ID';

  @override
  String get websitesPhpRuntimeIdHint => 'Enter the runtime ID to switch';

  @override
  String get websitesDomainPortLabel => 'Port';

  @override
  String get websitesDomainPrimary => 'Primary domain';

  @override
  String get websitesSslCreateAction => 'Create certificate';

  @override
  String get websitesSslUploadAction => 'Upload certificate';

  @override
  String get websitesSslListTitle => 'Certificate list';

  @override
  String get websitesSslListEmpty => 'No certificates';

  @override
  String get websitesSslApplyAction => 'Request certificate';

  @override
  String get websitesSslResolveAction => 'Resolve certificate';

  @override
  String get websitesSslUpdateAction => 'Update certificate';

  @override
  String get websitesSslDeleteTitle => 'Delete certificate';

  @override
  String websitesSslDeleteMessage(String domain) {
    return 'Delete certificate for $domain?';
  }

  @override
  String get websitesSslAcmeAccountIdLabel => 'ACME account ID';

  @override
  String get websitesSslProviderLabel => 'Provider';

  @override
  String get websitesSslOtherDomainsLabel => 'Other domains (comma-separated)';

  @override
  String get websitesSslDisableLogLabel => 'Disable logs';

  @override
  String get websitesSslSkipDnsCheckLabel => 'Skip DNS check';

  @override
  String get websitesSslNameserversLabel => 'Nameservers';

  @override
  String get websitesSslDescriptionLabel => 'Description';

  @override
  String get websitesSslUploadTypeLabel => 'Upload method';

  @override
  String get websitesSslUploadTypePaste => 'Paste content';

  @override
  String get websitesSslUploadTypeLocal => 'Local path';

  @override
  String get websitesSslCertificateLabel => 'Certificate';

  @override
  String get websitesSslPrivateKeyLabel => 'Private key';

  @override
  String get websitesSslCertificatePathLabel => 'Certificate path';

  @override
  String get websitesSslPrivateKeyPathLabel => 'Private key path';

  @override
  String get websitesHttpsConfigTitle => 'HTTPS config';

  @override
  String get websitesHttpsEnableLabel => 'Enable HTTPS';

  @override
  String get websitesHttpsModeLabel => 'HTTP mode';

  @override
  String get websitesHttpsTypeLabel => 'Certificate type';

  @override
  String get websitesHttpsSslIdLabel => 'Certificate ID';

  @override
  String get websitesSslAutoRenewMissingFields =>
      'Certificate is missing the primary domain or provider; cannot update auto-renew.';

  @override
  String websitesSslDownloadHint(String link) {
    return 'Certificate download link: $link';
  }

  @override
  String get openrestyPageTitle => 'OpenResty';

  @override
  String get openrestyTabStatus => 'Status';

  @override
  String get openrestyTabHttps => 'HTTPS';

  @override
  String get openrestyTabModules => 'Modules';

  @override
  String get openrestyTabConfig => 'Config';

  @override
  String get openrestyTabBuild => 'Build';

  @override
  String get openrestyTabScope => 'Scope';

  @override
  String get openrestyBuildMirrorLabel => 'Build mirror';

  @override
  String get openrestyBuildTaskIdLabel => 'Task ID';

  @override
  String get openrestyBuildAction => 'Build OpenResty';

  @override
  String get openrestyScopeLabel => 'Scope';

  @override
  String get openrestyScopeWebsiteIdLabel => 'Website ID (optional)';

  @override
  String get openrestyScopeLoad => 'Load scope';

  @override
  String get openrestyScopeResultHint => 'Scope config result';

  @override
  String get monitorNetworkLabel => 'Network';

  @override
  String get monitorMetricCurrent => 'Current';

  @override
  String get monitorMetricMin => 'Min';

  @override
  String get monitorMetricAvg => 'Avg';

  @override
  String get monitorMetricMax => 'Max';

  @override
  String get navServer => 'Servers';

  @override
  String get navFiles => 'Files';

  @override
  String get navSecurity => 'Security';

  @override
  String get navSettings => 'Settings';

  @override
  String noServerSelectedTitle(String module) {
    return '$module needs a server first';
  }

  @override
  String get noServerSelectedDescription =>
      'Choose a current server before opening this module.';

  @override
  String get shellPinnedModulesTitle => 'Bottom Tabs';

  @override
  String get shellPinnedModulesDescription =>
      'Choose two modules for the bottom navigation. Everything else stays in More.';

  @override
  String get shellPinnedModulesCustomize => 'Edit Tabs';

  @override
  String get shellPinnedModulesPrimary => 'Tab 1';

  @override
  String get shellPinnedModulesSecondary => 'Tab 2';

  @override
  String get moduleSubnavCustomize => 'Customize sections';

  @override
  String moduleSubnavHint(int count) {
    return 'The first $count items stay visible. Others move into More.';
  }

  @override
  String get moduleSubnavVisible => 'Visible';

  @override
  String get moduleSubnavHidden => 'In More';

  @override
  String get serverPageTitle => 'Servers';

  @override
  String get serverSearchHint => 'Search server name or IP';

  @override
  String get serverAdd => 'Add';

  @override
  String get serverListEmptyTitle => 'No servers yet';

  @override
  String get serverListEmptyDesc =>
      'Add your first 1Panel server to get started.';

  @override
  String get serverOnline => 'Online';

  @override
  String get serverOffline => 'Offline';

  @override
  String get serverCurrent => 'Current';

  @override
  String get serverDefault => 'Default';

  @override
  String get serverIpLabel => 'IP';

  @override
  String get serverCpuLabel => 'CPU';

  @override
  String get serverMemoryLabel => 'Memory';

  @override
  String get serverLoadLabel => 'Load';

  @override
  String get serverDiskLabel => 'Disk';

  @override
  String get serverMetricsUnavailable => 'Metrics unavailable';

  @override
  String get serverOpenDetail => 'Open details';

  @override
  String get serverDetailTitle => 'Server Details';

  @override
  String get serverModulesTitle => 'Modules';

  @override
  String get serverModuleDashboard => 'Overview';

  @override
  String get serverModuleApps => 'Apps';

  @override
  String get serverModuleContainers => 'Containers';

  @override
  String get serverModuleWebsites => 'Websites';

  @override
  String get serverModuleDatabases => 'Databases';

  @override
  String get serverModuleFirewall => 'Firewall';

  @override
  String get serverModuleTerminal => 'Terminal';

  @override
  String get serverModuleMonitoring => 'Monitoring';

  @override
  String get serverModuleFiles => 'File Manager';

  @override
  String get serverInsightsTitle => 'Overview';

  @override
  String get serverActionsTitle => 'Quick Actions';

  @override
  String get serverActionRefresh => 'Refresh';

  @override
  String get serverActionSwitch => 'Switch server';

  @override
  String get serverActionSecurity => 'Security';

  @override
  String get serverFormTitle => 'Add Server';

  @override
  String get serverFormName => 'Server name';

  @override
  String get serverFormNameHint => 'e.g. Production';

  @override
  String get serverFormUrl => 'Server URL';

  @override
  String get serverFormUrlHint => 'e.g. https://panel.example.com';

  @override
  String get serverFormApiKey => 'API key';

  @override
  String get serverFormApiKeyHint => 'Enter API key';

  @override
  String get serverFormSaveConnect => 'Save and continue';

  @override
  String get serverFormTest => 'Test connection';

  @override
  String get serverFormRequired => 'This field is required';

  @override
  String get serverFormSaveSuccess => 'Server saved';

  @override
  String serverFormSaveFailed(String error) {
    return 'Failed to save server: $error';
  }

  @override
  String get serverFormTestHint =>
      'Connection test can be added after client adaptation.';

  @override
  String get serverTestSuccess => 'Connection successful';

  @override
  String get serverTestFailed => 'Connection failed';

  @override
  String get serverTestTesting => 'Testing connection...';

  @override
  String get serverMetricsAvailable => 'Metrics loaded';

  @override
  String get serverTokenValidity => 'Token validity (minutes)';

  @override
  String get serverTokenValidityHint => 'Set to 0 to skip timestamp validation';

  @override
  String get serverFormMinutes => 'minutes';

  @override
  String get filesPageTitle => 'Files';

  @override
  String get filesPath => 'Path';

  @override
  String get filesRoot => 'Root';

  @override
  String get filesNavigateUp => 'Back to parent';

  @override
  String get filesEmptyTitle => 'This folder is empty';

  @override
  String get filesEmptyDesc =>
      'Tap the button below to create a new file or folder.';

  @override
  String get filesActionUpload => 'Upload';

  @override
  String get filesActionNewFile => 'New file';

  @override
  String get filesActionNewFolder => 'New folder';

  @override
  String get filesActionNew => 'New';

  @override
  String get filesActionOpen => 'Open';

  @override
  String get filesActionDownload => 'Download';

  @override
  String get filesActionRename => 'Rename';

  @override
  String get filesActionCopy => 'Copy';

  @override
  String get filesActionMove => 'Move';

  @override
  String get filesActionExtract => 'Extract';

  @override
  String get filesActionCompress => 'Compress';

  @override
  String get filesActionDelete => 'Delete';

  @override
  String get filesActionSelectAll => 'Select all';

  @override
  String get filesActionDeselect => 'Deselect';

  @override
  String get filesActionSort => 'Sort';

  @override
  String get filesActionSearch => 'Search';

  @override
  String get filesNameLabel => 'Name';

  @override
  String get filesNameHint => 'Enter name';

  @override
  String get filesTargetPath => 'Target path';

  @override
  String get filesTypeDirectory => 'Directory';

  @override
  String get filesSelected => 'selected';

  @override
  String get filesSelectPath => 'Select Path';

  @override
  String get filesCurrentFolder => 'Current Folder';

  @override
  String get filesNoSubfolders => 'No subfolders';

  @override
  String get filesPathSelectorTitle => 'Select Target Path';

  @override
  String get filesDeleteTitle => 'Delete files';

  @override
  String filesDeleteConfirm(int count) {
    return 'Delete $count selected items?';
  }

  @override
  String get filesSortByName => 'Sort by name';

  @override
  String get filesSortBySize => 'Sort by size';

  @override
  String get filesSortByDate => 'Sort by date';

  @override
  String get filesSearchHint => 'Search files';

  @override
  String get filesSearchClear => 'Clear';

  @override
  String get filesRecycleBin => 'Recycle bin';

  @override
  String get filesCopyFailed => 'Copy failed';

  @override
  String get filesMoveFailed => 'Move failed';

  @override
  String get filesRenameFailed => 'Rename failed';

  @override
  String get filesDeleteFailed => 'Delete failed';

  @override
  String get filesCompressFailed => 'Compress failed';

  @override
  String get filesExtractFailed => 'Extract failed';

  @override
  String get filesCreateFailed => 'Create failed';

  @override
  String get filesDownloadFailed => 'Download failed';

  @override
  String get filesDownloadSuccess => 'Download successful';

  @override
  String filesDownloadProgress(int progress) {
    return 'Downloading $progress%';
  }

  @override
  String get filesDownloadCancelled => 'Download cancelled';

  @override
  String filesDownloadSaving(String path) {
    return 'Saving to: $path';
  }

  @override
  String get filesOperationSuccess => 'Operation successful';

  @override
  String get filesCompressType => 'Type';

  @override
  String get filesUploadDeveloping => 'Upload feature is under development';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonName => 'Name';

  @override
  String get commonUsername => 'Username';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonUrl => 'URL';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonContent => 'Content';

  @override
  String get commonRepo => 'Repository';

  @override
  String get commonTemplate => 'Template';

  @override
  String get commonEditRepo => 'Edit Repository';

  @override
  String get commonEditTemplate => 'Edit Template';

  @override
  String get commonDeleteRepoConfirm =>
      'Are you sure you want to delete this repository?';

  @override
  String get commonDeleteTemplateConfirm =>
      'Are you sure you want to delete this template?';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonPath => 'Path';

  @override
  String get commonDriver => 'Driver';

  @override
  String get commonUnknownError => 'Unknown error';

  @override
  String get commonMegabyte => 'MB';

  @override
  String get commonHttp => 'HTTP';

  @override
  String get commonHttps => 'HTTPS';

  @override
  String get securityPageTitle => 'Security';

  @override
  String get securityStatusTitle => 'MFA status';

  @override
  String get securityStatusEnabled => 'Enabled';

  @override
  String get securityStatusDisabled => 'Not enabled';

  @override
  String get securitySecretLabel => 'Secret';

  @override
  String get securityCodeLabel => 'Verification code';

  @override
  String get securityCodeHint => 'Enter 6-digit code';

  @override
  String get securityLoadInfo => 'Load MFA info';

  @override
  String get securityBind => 'Bind MFA';

  @override
  String get securityBindSuccess => 'MFA binding request submitted';

  @override
  String securityBindFailed(String error) {
    return 'Failed to bind MFA: $error';
  }

  @override
  String get securityMockNotice =>
      'Current screen uses UI adapter mode. API client can be connected later.';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsServerManagement => 'Server management';

  @override
  String get settingsResetOnboarding => 'Replay welcome guide';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsFeedbackOpenFailed => 'Could not open the feedback page.';

  @override
  String get settingsResetOnboardingDone => 'Welcome guide has been reset';

  @override
  String get settingsCacheTitle => 'Cache Settings';

  @override
  String get settingsCacheStrategy => 'Cache Strategy';

  @override
  String get settingsCacheStrategyHybrid => 'Hybrid';

  @override
  String get settingsCacheStrategyMemoryOnly => 'Memory Only';

  @override
  String get settingsCacheStrategyDiskOnly => 'Disk Only';

  @override
  String get settingsCacheMaxSize => 'Cache Limit';

  @override
  String get settingsCacheStats => 'Cache Status';

  @override
  String get settingsCacheItemCount => 'Items';

  @override
  String get settingsCacheCurrentSize => 'Current Size';

  @override
  String get settingsCacheClear => 'Clear Cache';

  @override
  String get settingsCacheClearConfirm => 'Confirm Clear Cache';

  @override
  String get settingsCacheClearConfirmMessage =>
      'Are you sure you want to clear all cache? This will delete both memory and disk cache.';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsCacheLimit => 'Cache Limit';

  @override
  String get settingsCacheStatus => 'Cache Status';

  @override
  String get settingsCacheStrategyHybridDesc =>
      'Memory + Disk, best experience';

  @override
  String get settingsCacheStrategyMemoryOnlyDesc =>
      'Memory only, reduce flash wear';

  @override
  String get settingsCacheStrategyDiskOnlyDesc =>
      'Disk only, support offline viewing';

  @override
  String get settingsCacheExpiration => 'Expiration';

  @override
  String get settingsCacheExpirationUnit => 'minutes';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => 'Chinese';

  @override
  String get languageEn => 'English';

  @override
  String get commonExperimental => 'Experimental';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingTitle1 => 'Bring your 1Panel servers into one client';

  @override
  String get onboardingDesc1 =>
      'Connect and manage multiple 1Panel servers from one place, with your common tasks always within reach.';

  @override
  String get onboardingTitle2 => 'Keep everyday operations close';

  @override
  String get onboardingDesc2 =>
      'Check status, manage files, containers, apps, and websites without bouncing between devices.';

  @override
  String get onboardingTitle3 => 'Switch faster and read status clearly';

  @override
  String get onboardingDesc3 =>
      'Use clear server cards and quick entry points to understand each machine and jump to the right one quickly.';

  @override
  String get onboardingTitle4 => 'Connect your first server';

  @override
  String get onboardingDesc4 =>
      'Prepare your server address and API Key, then connect your first machine to start using 1Panel Client.';

  @override
  String get coachServerAddTitle => 'Add your first server';

  @override
  String get coachServerAddDesc =>
      'Use the add button in the top-right corner to enter your server address and API Key.';

  @override
  String get coachServerCardTitle => 'Open a server to continue';

  @override
  String get coachServerCardDesc =>
      'After connecting, tap a server card to open details and jump into files, containers, websites, and more.';

  @override
  String get aboutPageTitle => 'About 1Panel Client';

  @override
  String get aboutBuildSectionTitle => 'Build information';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutBuildLabel => 'Build';

  @override
  String get aboutChannelLabel => 'Channel';

  @override
  String get aboutPreviewSectionTitle => 'Experimental Preview';

  @override
  String get aboutPreviewSummary =>
      'This Android preview build is for early access and collecting user feedback.';

  @override
  String get aboutPreviewNoAutoUpdate =>
      'Automatic updates are not available in this preview. Download newer builds from GitHub Pre-release.';

  @override
  String get aboutPreviewFeedback =>
      'Official feedback channel: GitHub Issues.';

  @override
  String get aboutFeedbackSectionTitle => 'Feedback';

  @override
  String get aboutFeedbackAction => 'Open GitHub Issues';

  @override
  String get aboutFeedbackHint =>
      'Report bugs, usability issues, and suggestions in the official issue tracker.';

  @override
  String get aboutReleaseNotesSectionTitle => 'Current preview notes';

  @override
  String get aboutReleaseNotesBody =>
      'This preview focuses on multi-server management, onboarding polish, and early website management workflows.';

  @override
  String get aboutRepositorySectionTitle => 'Repository';

  @override
  String get aboutRepositoryOpenAction => 'Open repository';

  @override
  String get aboutRepositoryHttpsLabel => 'HTTPS';

  @override
  String get aboutRepositorySshLabel => 'SSH';

  @override
  String get aboutReleaseAction => 'Open Preview Releases';

  @override
  String get aboutLinkOpenFailed => 'Could not open the link.';

  @override
  String get aboutExperimentalModulesTitle => 'Experimental modules';

  @override
  String get aboutExperimentalModulesDescription =>
      'Some modules are still being refined for the preview channel and may change based on feedback.';

  @override
  String get aboutExperimentalModulesList =>
      'Websites, OpenResty, Databases, Firewall, Terminal, Monitoring';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardLoadFailedTitle => 'Failed to load';

  @override
  String get dashboardServerInfoTitle => 'Server info';

  @override
  String get dashboardServerStatusOk => 'Running';

  @override
  String get dashboardServerStatusConnecting => 'Connecting...';

  @override
  String get dashboardHostNameLabel => 'Hostname';

  @override
  String get dashboardOsLabel => 'Operating system';

  @override
  String get dashboardUptimeLabel => 'Uptime';

  @override
  String dashboardUptimeDaysHours(int days, int hours) {
    return '${days}d ${hours}h';
  }

  @override
  String dashboardUptimeHours(int hours) {
    return '${hours}h';
  }

  @override
  String dashboardUpdatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get dashboardResourceTitle => 'System resources';

  @override
  String get dashboardCpuUsage => 'CPU usage';

  @override
  String get dashboardMemoryUsage => 'Memory usage';

  @override
  String get dashboardDiskUsage => 'Disk usage';

  @override
  String get dashboardQuickActionsTitle => 'Quick actions';

  @override
  String get dashboardActionRestart => 'Restart server';

  @override
  String get dashboardActionUpdate => 'System update';

  @override
  String get dashboardActionBackup => 'Create backup';

  @override
  String get dashboardActionSecurity => 'Security check';

  @override
  String get dashboardRestartTitle => 'Restart server';

  @override
  String get dashboardRestartDesc =>
      'Restarting will temporarily interrupt all services. Continue?';

  @override
  String get dashboardRestartSuccess => 'Restart request sent';

  @override
  String dashboardRestartFailed(String error) {
    return 'Failed to restart: $error';
  }

  @override
  String get dashboardUpdateTitle => 'System update';

  @override
  String get dashboardUpdateDesc =>
      'Start the update now? The panel may be temporarily unavailable.';

  @override
  String get dashboardUpdateSuccess => 'Update request sent';

  @override
  String dashboardUpdateFailed(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get dashboardActivityTitle => 'Recent activity';

  @override
  String get dashboardActivityEmpty => 'No recent activity';

  @override
  String dashboardActivityDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String dashboardActivityHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String dashboardActivityMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get dashboardActivityJustNow => 'Just now';

  @override
  String get dashboardTopProcessesTitle => 'Process Monitor';

  @override
  String get dashboardCpuTab => 'CPU';

  @override
  String get dashboardMemoryTab => 'Memory';

  @override
  String get dashboardNoProcesses => 'No process data';

  @override
  String get authLoginTitle => '1Panel Login';

  @override
  String get authLoginSubtitle => 'Please enter your credentials';

  @override
  String get authUsername => 'Username';

  @override
  String get authPassword => 'Password';

  @override
  String get authCaptcha => 'Captcha';

  @override
  String get authLogin => 'Login';

  @override
  String get authUsernameRequired => 'Please enter username';

  @override
  String get authPasswordRequired => 'Please enter password';

  @override
  String get authCaptchaRequired => 'Please enter captcha';

  @override
  String get authMfaTitle => 'Two-Factor Authentication';

  @override
  String get authMfaDesc =>
      'Please enter the verification code from your authenticator app';

  @override
  String get authMfaHint => '000000';

  @override
  String get authMfaVerify => 'Verify';

  @override
  String get authMfaCancel => 'Back to login';

  @override
  String get authDemoMode => 'Demo mode: Some features are limited';

  @override
  String get authLoginFailed => 'Login failed';

  @override
  String get authLogoutSuccess => 'Logged out successfully';

  @override
  String get coachDone => 'Got it';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundDesc => 'The requested page does not exist.';

  @override
  String get legacyRouteRedirect =>
      'This legacy route is redirected to the new shell.';

  @override
  String get monitorDataPoints => 'Data points';

  @override
  String monitorDataPointsCount(int count, String time) {
    return '$count points ($time)';
  }

  @override
  String get monitorRefreshInterval => 'Refresh interval';

  @override
  String monitorSeconds(int count) {
    return '$count seconds';
  }

  @override
  String monitorSecondsDefault(int count) {
    return '$count seconds (default)';
  }

  @override
  String monitorMinute(int count) {
    return '$count minute';
  }

  @override
  String monitorTimeMinutes(int count) {
    return '$count min';
  }

  @override
  String monitorTimeHours(int count) {
    return '$count hour';
  }

  @override
  String monitorDataPointsLabel(int count) {
    return '$count data points';
  }

  @override
  String get monitorSettings => 'Monitor Settings';

  @override
  String get monitorEnable => 'Enable Monitoring';

  @override
  String get monitorInterval => 'Monitor Interval';

  @override
  String get monitorIntervalUnit => 'seconds';

  @override
  String get monitorRetention => 'Data Retention';

  @override
  String get monitorRetentionUnit => 'days';

  @override
  String get monitorCleanData => 'Clean Monitor Data';

  @override
  String get monitorCleanConfirm =>
      'Are you sure you want to clean all monitor data? This action cannot be undone.';

  @override
  String get monitorCleanSuccess => 'Monitor data cleaned successfully';

  @override
  String get monitorCleanFailed => 'Failed to clean monitor data';

  @override
  String get monitorSettingsSaved => 'Settings saved successfully';

  @override
  String get monitorSettingsFailed => 'Failed to save settings';

  @override
  String get monitorGPU => 'GPU Monitor';

  @override
  String get monitorGPUName => 'Name';

  @override
  String get monitorGPUUtilization => 'Utilization';

  @override
  String get monitorGPUMemory => 'Memory';

  @override
  String get monitorGPUTemperature => 'Temperature';

  @override
  String get monitorGPUNotAvailable => 'GPU monitoring not available';

  @override
  String get monitorTimeRange => 'Time Range';

  @override
  String get monitorTimeRangeLast1h => 'Last 1 hour';

  @override
  String get monitorTimeRangeLast6h => 'Last 6 hours';

  @override
  String get monitorTimeRangeLast24h => 'Last 24 hours';

  @override
  String get monitorTimeRangeLast7d => 'Last 7 days';

  @override
  String get monitorTimeRangeCustom => 'Custom';

  @override
  String get monitorTimeRangeFrom => 'From';

  @override
  String get monitorTimeRangeTo => 'To';

  @override
  String get systemSettingsTitle => 'System Settings';

  @override
  String get systemSettingsRefresh => 'Refresh';

  @override
  String get systemSettingsLoadFailed => 'Failed to load settings';

  @override
  String get systemSettingsPanelSection => 'Panel Settings';

  @override
  String get systemSettingsPanelConfig => 'Panel Config';

  @override
  String get systemSettingsPanelConfigDesc =>
      'Panel name, port, bind address, etc.';

  @override
  String get systemSettingsTerminal => 'Terminal Settings';

  @override
  String get systemSettingsTerminalDesc =>
      'Terminal style, font, scrolling, etc.';

  @override
  String get systemSettingsSecuritySection => 'Security Settings';

  @override
  String get systemSettingsSecurityConfig => 'Security Config';

  @override
  String get systemSettingsSecurityConfigDesc =>
      'MFA authentication, access control, etc.';

  @override
  String get systemSettingsApiKey => 'API Key';

  @override
  String get systemSettingsBackupSection => 'Backup & Recovery';

  @override
  String get systemSettingsSnapshot => 'Snapshot Management';

  @override
  String get systemSettingsSnapshotDesc =>
      'Create, restore, delete system snapshots';

  @override
  String get systemSettingsSystemSection => 'System Info';

  @override
  String get systemSettingsUpgrade => 'System Upgrade';

  @override
  String get systemSettingsAbout => 'About';

  @override
  String get systemSettingsAboutDesc => 'System info and version';

  @override
  String systemSettingsLastUpdated(String time) {
    return 'Last updated: $time';
  }

  @override
  String get systemSettingsPanelName => '1Panel';

  @override
  String get systemSettingsSystemVersion => 'System Version';

  @override
  String get systemSettingsMfaStatus => 'MFA Status';

  @override
  String get systemSettingsEnabled => 'Enabled';

  @override
  String get systemSettingsDisabled => 'Disabled';

  @override
  String get systemSettingsApiKeyManage => 'API Key Management';

  @override
  String get systemSettingsCurrentStatus => 'Current Status';

  @override
  String get systemSettingsUnknown => 'Unknown';

  @override
  String get systemSettingsApiKeyLabel => 'API Key';

  @override
  String get systemSettingsNotSet => 'Not set';

  @override
  String get systemSettingsGenerateNewKey => 'Generate New Key';

  @override
  String get systemSettingsApiKeyGenerated => 'API key generated';

  @override
  String get systemSettingsGenerateFailed => 'Generation failed';

  @override
  String get apiKeySettingsTitle => 'API Key Management';

  @override
  String get apiKeySettingsStatus => 'Status';

  @override
  String get apiKeySettingsEnabled => 'API Interface';

  @override
  String get apiKeySettingsInfo => 'Key Information';

  @override
  String get apiKeySettingsKey => 'API Key';

  @override
  String get apiKeySettingsIpWhitelist => 'IP Whitelist';

  @override
  String get apiKeySettingsValidityTime => 'Validity Time';

  @override
  String get apiKeySettingsActions => 'Actions';

  @override
  String get apiKeySettingsRegenerate => 'Regenerate';

  @override
  String get apiKeySettingsRegenerateDesc => 'Generate new API key';

  @override
  String get apiKeySettingsRegenerateConfirm =>
      'Are you sure you want to regenerate the API key? The old key will be invalid immediately.';

  @override
  String get apiKeySettingsRegenerateSuccess => 'API key regenerated';

  @override
  String get apiKeySettingsEnable => 'Enable API';

  @override
  String get apiKeySettingsDisable => 'Disable API';

  @override
  String get apiKeySettingsEnableConfirm =>
      'Are you sure you want to enable API interface?';

  @override
  String get apiKeySettingsDisableConfirm =>
      'Are you sure you want to disable API interface?';

  @override
  String get commonCopied => 'Copied to clipboard';

  @override
  String get sslSettingsTitle => 'SSL Certificate Management';

  @override
  String get sslSettingsInfo => 'Certificate Information';

  @override
  String get sslSettingsDomain => 'Domain';

  @override
  String get sslSettingsStatus => 'Status';

  @override
  String get sslSettingsType => 'Type';

  @override
  String get sslSettingsProvider => 'Provider';

  @override
  String get sslSettingsExpiration => 'Expiration';

  @override
  String get sslSettingsActions => 'Actions';

  @override
  String get sslSettingsUpload => 'Upload Certificate';

  @override
  String get sslSettingsUploadDesc => 'Upload SSL certificate file';

  @override
  String get sslSettingsDownload => 'Download Certificate';

  @override
  String get sslSettingsDownloadDesc => 'Download current SSL certificate';

  @override
  String get sslSettingsDownloadSuccess =>
      'Certificate downloaded successfully';

  @override
  String get sslSettingsCert => 'Certificate Content';

  @override
  String get sslSettingsKey => 'Private Key Content';

  @override
  String get upgradeTitle => 'System Upgrade';

  @override
  String get upgradeCurrentVersion => 'Current Version';

  @override
  String get upgradeCurrentVersionLabel => 'Current System Version';

  @override
  String get upgradeAvailableVersions => 'Available Versions';

  @override
  String get upgradeNoUpdates => 'Already up to date';

  @override
  String get upgradeLatest => 'Latest';

  @override
  String get upgradeConfirm => 'Confirm Upgrade';

  @override
  String upgradeConfirmMessage(Object version) {
    return 'Are you sure you want to upgrade to version $version?';
  }

  @override
  String get upgradeDowngradeConfirm => 'Confirm Downgrade';

  @override
  String upgradeDowngradeMessage(Object version) {
    return 'Are you sure you want to downgrade to version $version? Downgrade may cause data incompatibility.';
  }

  @override
  String get upgradeButton => 'Upgrade';

  @override
  String get upgradeDowngradeButton => 'Downgrade';

  @override
  String get upgradeStarted => 'Upgrade started';

  @override
  String get upgradeViewNotes => 'View Release Notes';

  @override
  String upgradeNotesTitle(Object version) {
    return 'Version $version Release Notes';
  }

  @override
  String get upgradeNotesLoading => 'Loading...';

  @override
  String get upgradeNotesEmpty => 'No release notes available';

  @override
  String get upgradeNotesError => 'Failed to load';

  @override
  String get monitorSettingsTitle => 'Monitor Settings';

  @override
  String get monitorSettingsInterval => 'Monitor Interval';

  @override
  String get monitorSettingsStoreDays => 'Data Retention Days';

  @override
  String get monitorSettingsEnable => 'Enable Monitoring';

  @override
  String get systemSettingsCurrentVersion => 'Current Version';

  @override
  String get systemSettingsCheckingUpdate => 'Checking for updates...';

  @override
  String get systemSettingsClose => 'Close';

  @override
  String get panelSettingsTitle => 'Panel Settings';

  @override
  String get panelSettingsBasicInfo => 'Basic Info';

  @override
  String get panelSettingsPanelName => 'Panel Name';

  @override
  String get panelSettingsVersion => 'System Version';

  @override
  String get panelSettingsPort => 'Listen Port';

  @override
  String get panelSettingsBindAddress => 'Bind Address';

  @override
  String get panelSettingsInterface => 'Interface Settings';

  @override
  String get panelSettingsTheme => 'Theme';

  @override
  String get panelSettingsLanguage => 'Language';

  @override
  String get panelSettingsMenuTabs => 'Menu Tabs';

  @override
  String get panelSettingsAdvanced => 'Advanced Settings';

  @override
  String get panelSettingsDeveloperMode => 'Developer Mode';

  @override
  String get panelSettingsIpv6 => 'IPv6';

  @override
  String get panelSettingsSessionTimeout => 'Session Timeout';

  @override
  String panelSettingsMinutes(String count) {
    return '$count minutes';
  }

  @override
  String get terminalSettingsTitle => 'Terminal Settings';

  @override
  String get terminalSettingsDisplay => 'Display Settings';

  @override
  String get terminalSettingsCursorStyle => 'Cursor Style';

  @override
  String get terminalSettingsCursorBlink => 'Cursor Blink';

  @override
  String get terminalSettingsFontSize => 'Font Size';

  @override
  String get terminalSettingsScroll => 'Scroll Settings';

  @override
  String get terminalSettingsScrollSensitivity => 'Scroll Sensitivity';

  @override
  String get terminalSettingsScrollback => 'Scrollback Buffer';

  @override
  String get terminalSettingsStyle => 'Style Settings';

  @override
  String get terminalSettingsLineHeight => 'Line Height';

  @override
  String get terminalSettingsLetterSpacing => 'Letter Spacing';

  @override
  String get securitySettingsTitle => 'Security Settings';

  @override
  String get securitySettingsPasswordSection => 'Password Management';

  @override
  String get securitySettingsChangePassword => 'Change Password';

  @override
  String get securitySettingsChangePasswordDesc => 'Change login password';

  @override
  String get securitySettingsOldPassword => 'Current Password';

  @override
  String get securitySettingsNewPassword => 'New Password';

  @override
  String get securitySettingsConfirmPassword => 'Confirm Password';

  @override
  String get securitySettingsPasswordMismatch => 'Passwords do not match';

  @override
  String get securitySettingsMfaSection => 'MFA Authentication';

  @override
  String get securitySettingsMfaStatus => 'MFA Status';

  @override
  String get securitySettingsMfaBind => 'Bind MFA';

  @override
  String get securitySettingsMfaUnbind => 'Unbind MFA';

  @override
  String get securitySettingsMfaUnbindDesc =>
      'MFA authentication will be disabled after unbinding. Are you sure?';

  @override
  String get securitySettingsMfaScanQr => 'Scan QR code with authenticator app';

  @override
  String securitySettingsMfaSecret(Object secret) {
    return 'Secret: $secret';
  }

  @override
  String get securitySettingsMfaCode => 'Verification Code';

  @override
  String get securitySettingsUnbindMfa => 'Unbind MFA';

  @override
  String get securitySettingsAccessControl => 'Access Control';

  @override
  String get securitySettingsSecurityEntrance => 'Security Entrance';

  @override
  String get securitySettingsBindDomain => 'Bind Domain';

  @override
  String get securitySettingsAllowIPs => 'Allowed IPs';

  @override
  String get securitySettingsPasswordPolicy => 'Password Policy';

  @override
  String get securitySettingsComplexityVerification =>
      'Complexity Verification';

  @override
  String get securitySettingsExpirationDays => 'Expiration Days';

  @override
  String get securitySettingsEnableMfa => 'Enable MFA';

  @override
  String get securitySettingsDisableMfa => 'Disable MFA';

  @override
  String get securitySettingsEnableMfaConfirm =>
      'Are you sure you want to enable MFA?';

  @override
  String get securitySettingsDisableMfaConfirm =>
      'Are you sure you want to disable MFA?';

  @override
  String get securitySettingsEnterMfaCode =>
      'Please enter MFA verification code';

  @override
  String get securitySettingsVerifyCode => 'Verification Code';

  @override
  String get securitySettingsMfaCodeHint => 'Enter 6-digit code';

  @override
  String get securitySettingsMfaUnbound => 'MFA unbound';

  @override
  String get securitySettingsUnbindFailed => 'Unbind failed';

  @override
  String get snapshotTitle => 'Snapshot Management';

  @override
  String get snapshotCreate => 'Create Snapshot';

  @override
  String get snapshotEmpty => 'No snapshots';

  @override
  String get snapshotCreatedAt => 'Created At';

  @override
  String get snapshotDescription => 'Description';

  @override
  String get snapshotRecover => 'Recover';

  @override
  String get snapshotDownload => 'Download';

  @override
  String get snapshotDelete => 'Delete';

  @override
  String get snapshotImport => 'Import Snapshot';

  @override
  String get snapshotRollback => 'Rollback';

  @override
  String get snapshotEditDesc => 'Edit Description';

  @override
  String get snapshotEnterDesc => 'Enter snapshot description (optional)';

  @override
  String get snapshotDescLabel => 'Description';

  @override
  String get snapshotDescHint => 'Enter snapshot description';

  @override
  String get snapshotCreateSuccess => 'Snapshot created successfully';

  @override
  String get snapshotCreateFailed => 'Failed to create snapshot';

  @override
  String get snapshotImportTitle => 'Import Snapshot';

  @override
  String get snapshotImportPath => 'Snapshot File Path';

  @override
  String get snapshotImportPathHint => 'Enter snapshot file path';

  @override
  String get snapshotImportSuccess => 'Snapshot imported successfully';

  @override
  String get snapshotImportFailed => 'Failed to import snapshot';

  @override
  String get snapshotRollbackTitle => 'Rollback Snapshot';

  @override
  String get snapshotRollbackConfirm =>
      'Are you sure you want to rollback to this snapshot? Current configuration will be overwritten.';

  @override
  String get snapshotRollbackSuccess => 'Snapshot rolled back successfully';

  @override
  String get snapshotRollbackFailed => 'Failed to rollback snapshot';

  @override
  String get snapshotEditDescTitle => 'Edit Snapshot Description';

  @override
  String get snapshotEditDescSuccess => 'Description updated successfully';

  @override
  String get snapshotEditDescFailed => 'Failed to update description';

  @override
  String get snapshotRecoverTitle => 'Recover Snapshot';

  @override
  String get snapshotRecoverConfirm =>
      'Are you sure you want to recover this snapshot? Current configuration will be overwritten.';

  @override
  String get snapshotRecoverSuccess => 'Snapshot recovered successfully';

  @override
  String get snapshotRecoverFailed => 'Failed to recover snapshot';

  @override
  String get snapshotDeleteTitle => 'Delete Snapshot';

  @override
  String get snapshotDeleteConfirm =>
      'Are you sure you want to delete selected snapshots? This action cannot be undone.';

  @override
  String get snapshotDeleteSuccess => 'Snapshot deleted successfully';

  @override
  String get snapshotDeleteFailed => 'Failed to delete snapshot';

  @override
  String get proxySettingsTitle => 'Proxy Settings';

  @override
  String get proxySettingsEnable => 'Enable Proxy';

  @override
  String get proxySettingsType => 'Proxy Type';

  @override
  String get proxySettingsHttp => 'HTTP Proxy';

  @override
  String get proxySettingsHttps => 'HTTPS Proxy';

  @override
  String get proxySettingsHost => 'Proxy Host';

  @override
  String get proxySettingsPort => 'Proxy Port';

  @override
  String get proxySettingsUser => 'Username';

  @override
  String get proxySettingsPassword => 'Password';

  @override
  String get proxySettingsSaved => 'Proxy settings saved';

  @override
  String get proxySettingsFailed => 'Failed to save';

  @override
  String get bindSettingsTitle => 'Bind Address';

  @override
  String get bindSettingsAddress => 'Bind Address';

  @override
  String get bindSettingsPort => 'Panel Port';

  @override
  String get bindSettingsSaved => 'Bind settings saved';

  @override
  String get bindSettingsFailed => 'Failed to save';

  @override
  String get serverModuleSystemSettings => 'System Settings';

  @override
  String get filesFavorites => 'Favorites';

  @override
  String get filesFavoritesEmpty => 'No favorites';

  @override
  String get filesFavoritesEmptyDesc =>
      'Long press a file or folder to add to favorites';

  @override
  String get filesAddToFavorites => 'Add to Favorites';

  @override
  String get filesRemoveFromFavorites => 'Remove from Favorites';

  @override
  String get filesFavoritesAdded => 'Added to favorites';

  @override
  String get filesFavoritesRemoved => 'Removed from favorites';

  @override
  String get filesNavigateToFolder => 'Navigate to folder';

  @override
  String get filesFavoritesLoadFailed => 'Failed to load favorites';

  @override
  String get filesPermissionTitle => 'Permission Management';

  @override
  String get filesPermissionMode => 'Permission Mode';

  @override
  String get filesPermissionOwner => 'Owner';

  @override
  String get filesPermissionGroup => 'Group';

  @override
  String get filesPermissionRead => 'Read';

  @override
  String get filesPermissionWrite => 'Write';

  @override
  String get filesPermissionExecute => 'Execute';

  @override
  String get filesPermissionOwnerLabel => 'Owner Permissions';

  @override
  String get filesPermissionGroupLabel => 'Group Permissions';

  @override
  String get filesPermissionOtherLabel => 'Other Permissions';

  @override
  String get filesPermissionRecursive => 'Apply recursively';

  @override
  String get filesPermissionUser => 'User';

  @override
  String get filesPermissionUserHint => 'Select user';

  @override
  String get filesPermissionGroupHint => 'Select group';

  @override
  String get filesPermissionChangeOwner => 'Change Owner';

  @override
  String get filesPermissionChangeMode => 'Change Mode';

  @override
  String get filesPermissionSuccess => 'Permission changed successfully';

  @override
  String get transferListTitle => 'Transfer List';

  @override
  String get transferClearCompleted => 'Clear Completed';

  @override
  String get transferEmpty => 'No transfer tasks';

  @override
  String get transferStatusRunning => 'Running';

  @override
  String get transferStatusPaused => 'Paused';

  @override
  String get transferStatusCompleted => 'Completed';

  @override
  String get transferStatusFailed => 'Failed';

  @override
  String get transferStatusCancelled => 'Cancelled';

  @override
  String get transferStatusPending => 'Pending';

  @override
  String get transferUploading => 'Uploading';

  @override
  String get transferDownloading => 'Downloading';

  @override
  String get transferChunks => 'chunks';

  @override
  String get transferSpeed => 'Speed';

  @override
  String get transferEta => 'ETA';

  @override
  String get filesPermissionFailed => 'Failed to change permission';

  @override
  String get filesPermissionLoadFailed => 'Failed to load permission info';

  @override
  String get filesPermissionOctal => 'Octal notation';

  @override
  String get filesPreviewTitle => 'File Preview';

  @override
  String get filesEditorTitle => 'Edit File';

  @override
  String get filesPreviewLoading => 'Loading...';

  @override
  String get filesPreviewError => 'Failed to load';

  @override
  String get filesPreviewUnsupported => 'Cannot preview this file type';

  @override
  String get filesEditorSave => 'Save';

  @override
  String get filesEditorSaved => 'Saved';

  @override
  String get filesEditorUnsaved => 'Unsaved';

  @override
  String get filesEditorSaving => 'Saving...';

  @override
  String get filesEditorEncoding => 'Encoding';

  @override
  String get filesEditorLineNumbers => 'Line Numbers';

  @override
  String get filesEditorWordWrap => 'Word Wrap';

  @override
  String get filesGoToLine => 'Go to Line';

  @override
  String get filesLineNumber => 'Line number';

  @override
  String get filesReload => 'Reload';

  @override
  String get filesEditorReloadConfirm =>
      'Switching encoding will reload the file and discard unsaved changes. Continue?';

  @override
  String get filesEncodingConvert => 'Convert Encoding';

  @override
  String get filesEncodingFrom => 'From encoding';

  @override
  String get filesEncodingTo => 'To encoding';

  @override
  String get filesEncodingBackup => 'Backup original file';

  @override
  String get filesEncodingConvertDone => 'Encoding conversion succeeded';

  @override
  String get filesEncodingConvertFailed => 'Encoding conversion failed';

  @override
  String get filesEncodingLog => 'Conversion Log';

  @override
  String get filesEncodingLogEmpty => 'No logs';

  @override
  String get filesPreviewImage => 'Image Preview';

  @override
  String get filesPreviewCode => 'Code Preview';

  @override
  String get filesPreviewText => 'Text Preview';

  @override
  String get filesEditFile => 'Edit File';

  @override
  String get filesActionWgetDownload => 'Remote Download';

  @override
  String get filesWgetUrl => 'Download URL';

  @override
  String get filesWgetUrlHint => 'Enter file URL';

  @override
  String get filesWgetFilename => 'Filename';

  @override
  String get filesWgetFilenameHint => 'Leave empty to use URL filename';

  @override
  String get filesWgetOverwrite => 'Overwrite existing file';

  @override
  String get filesWgetDownload => 'Start Download';

  @override
  String filesWgetSuccess(String path) {
    return 'Download successful: $path';
  }

  @override
  String get filesWgetFailed => 'Download failed';

  @override
  String get recycleBinRestore => 'Restore';

  @override
  String recycleBinRestoreConfirm(int count) {
    return 'Are you sure you want to restore $count selected files?';
  }

  @override
  String get recycleBinRestoreSuccess => 'Files restored successfully';

  @override
  String get recycleBinRestoreFailed => 'Failed to restore files';

  @override
  String recycleBinRestoreSingleConfirm(String name) {
    return 'Are you sure you want to restore \"$name\"?';
  }

  @override
  String get recycleBinDeletePermanently => 'Delete Permanently';

  @override
  String recycleBinDeletePermanentlyConfirm(int count) {
    return 'Are you sure you want to permanently delete $count selected files? This action cannot be undone.';
  }

  @override
  String get recycleBinDeletePermanentlySuccess => 'Files permanently deleted';

  @override
  String get recycleBinDeletePermanentlyFailed =>
      'Failed to delete files permanently';

  @override
  String recycleBinDeletePermanentlySingleConfirm(String name) {
    return 'Are you sure you want to permanently delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get recycleBinClear => 'Clear Recycle Bin';

  @override
  String get recycleBinClearConfirm =>
      'Are you sure you want to clear the recycle bin? All files will be permanently deleted.';

  @override
  String get recycleBinClearSuccess => 'Recycle bin cleared';

  @override
  String get recycleBinClearFailed => 'Failed to clear recycle bin';

  @override
  String get recycleBinSearch => 'Search files';

  @override
  String get recycleBinEmpty => 'Recycle bin is empty';

  @override
  String get recycleBinNoResults => 'No files found';

  @override
  String get recycleBinSourcePath => 'Original path';

  @override
  String get transferManagerTitle => 'Transfer Manager';

  @override
  String get transferFilterAll => 'All';

  @override
  String get transferFilterUploading => 'Uploading';

  @override
  String get transferFilterDownloading => 'Downloading';

  @override
  String get transferSortNewest => 'Newest';

  @override
  String get transferSortOldest => 'Oldest';

  @override
  String get transferSortName => 'Name';

  @override
  String get transferSortSize => 'Size';

  @override
  String get transferTabActive => 'Active';

  @override
  String get transferTabPending => 'Pending';

  @override
  String get transferTabCompleted => 'Completed';

  @override
  String get transferFileNotFound => 'File not found';

  @override
  String get transferFileAlreadyDownloaded => 'File already downloaded';

  @override
  String get transferFileLocationOpened => 'File location opened';

  @override
  String get transferOpenFileError => 'Failed to open file';

  @override
  String get transferOpenFile => 'Open File';

  @override
  String get transferClearTitle => 'Clear Completed Tasks';

  @override
  String get transferClearConfirm =>
      'Are you sure you want to clear all completed transfer tasks?';

  @override
  String get transferPause => 'Pause';

  @override
  String get transferCancel => 'Cancel';

  @override
  String get transferResume => 'Resume';

  @override
  String get transferOpenLocation => 'Open Location';

  @override
  String get transferOpenDownloadsFolder => 'Open Downloads';

  @override
  String get transferCopyPath => 'Copy Path';

  @override
  String get transferCopyDirectoryPath => 'Copy Folder Path';

  @override
  String get transferDownloads => 'Downloads';

  @override
  String get transferUploads => 'Uploads';

  @override
  String get transferSettings => 'Settings';

  @override
  String get transferSettingsTitle => 'Transfer Settings';

  @override
  String get transferHistoryRetentionHint =>
      'History retention days (auto cleanup after)';

  @override
  String transferHistoryDays(int days) {
    return '$days days';
  }

  @override
  String get transferHistorySaved => 'Settings saved';

  @override
  String get largeFileDownloadTitle => 'Large File Download';

  @override
  String get largeFileDownloadHint =>
      'File is large, added to background download queue';

  @override
  String get largeFileDownloadView => 'View Downloads';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionStorageRequired =>
      'Storage permission is required to save files';

  @override
  String get permissionGoToSettings => 'Go to Settings';

  @override
  String get fileSaveSuccess => 'File saved';

  @override
  String get fileSaveFailed => 'Failed to save file';

  @override
  String fileSaveLocation(String path) {
    return 'Saved to: $path';
  }

  @override
  String get filesPropertiesTitle => 'File Properties';

  @override
  String get filesCreatedLabel => 'Created';

  @override
  String get filesModifiedLabel => 'Modified';

  @override
  String get filesAccessedLabel => 'Accessed';

  @override
  String get filesCreateLinkTitle => 'Create Link';

  @override
  String get filesLinkNameLabel => 'Link Name';

  @override
  String get filesLinkTypeLabel => 'Link Type';

  @override
  String get filesLinkTypeSymbolic => 'Symbolic Link';

  @override
  String get filesLinkTypeHard => 'Hard Link';

  @override
  String get filesLinkPath => 'Target Path';

  @override
  String get filesContentSearch => 'Content Search';

  @override
  String get filesContentSearchHint => 'Search Content';

  @override
  String get filesUploadHistory => 'Upload History';

  @override
  String get filesMounts => 'Mount Points';

  @override
  String get filesActionUp => 'Up';

  @override
  String get commonError => 'Error occurred';

  @override
  String get commonCreateSuccess => 'Created successfully';

  @override
  String get commonCopySuccess => 'Copied successfully';

  @override
  String get appStoreTitle => 'App Store';

  @override
  String get appsPageTitle => 'App Management';

  @override
  String get appStoreInstall => 'Install';

  @override
  String get appStoreInstalled => 'Installed';

  @override
  String get appStoreUpdate => 'Update';

  @override
  String get appStoreSearchHint => 'Search apps';

  @override
  String get appStoreSync => 'Sync Apps';

  @override
  String get appStoreSyncSuccess => 'Apps synced successfully';

  @override
  String get appStoreSyncFailed => 'Failed to sync apps';

  @override
  String get appStoreSyncLocal => 'Sync Local Apps';

  @override
  String get appStoreSyncLocalSuccess => 'Local apps synced successfully';

  @override
  String get appStoreSyncLocalFailed => 'Failed to sync local apps';

  @override
  String get appIgnoredUpdatesTitle => 'Ignored Updates';

  @override
  String get appIgnoredUpdatesLoadFailed => 'Failed to load ignored apps';

  @override
  String get appIgnoredUpdatesEmpty => 'No ignored updates';

  @override
  String get appIgnoreUpdate => 'Ignore Update';

  @override
  String get appIgnoreUpdateReason => 'Reason';

  @override
  String get appIgnoreUpdateSuccess => 'Update ignored';

  @override
  String appIgnoreUpdateFailed(String error) {
    return 'Failed to ignore update: $error';
  }

  @override
  String get appIgnoreUpdateCancel => 'Cancel Ignore';

  @override
  String get appStoreTagWebsite => 'Website';

  @override
  String get appStoreTagDatabase => 'Database';

  @override
  String get appStoreTagRuntime => 'Runtime';

  @override
  String get appStoreTagTool => 'Tool';

  @override
  String get appStoreTagDocker => 'Docker';

  @override
  String get appStoreTagCICD => 'CI/CD';

  @override
  String get appStoreTagMonitoring => 'Monitoring';

  @override
  String get appDetailTitle => 'App Details';

  @override
  String get appStatusRunning => 'Running';

  @override
  String get appStatusStopped => 'Stopped';

  @override
  String get appStatusError => 'Error';

  @override
  String get appActionStart => 'Start';

  @override
  String get appActionStop => 'Stop';

  @override
  String get appActionRestart => 'Restart';

  @override
  String get appActionUninstall => 'Uninstall';

  @override
  String get appServiceList => 'Services';

  @override
  String get appBaseInfo => 'Basic Info';

  @override
  String get appInfoName => 'Name';

  @override
  String get appInfoVersion => 'Version';

  @override
  String get appInfoStatus => 'Status';

  @override
  String get appInfoCreated => 'Created At';

  @override
  String get appUninstallConfirm =>
      'Are you sure you want to uninstall this app? This action cannot be undone.';

  @override
  String get appNoPortInfo => 'No port info';

  @override
  String get appConnInfo => 'Connection Info';

  @override
  String get appConnInfoFailed => 'Failed to load connection info';

  @override
  String appReadmeImageUnsupported(String url) {
    return 'Image not supported: $url';
  }

  @override
  String get appOperateSuccess => 'Operation successful';

  @override
  String get commonPort => 'Port';

  @override
  String get commonParams => 'Parameters';

  @override
  String get appUpdate => 'Update';

  @override
  String get appUpdateTitle => 'Update App';

  @override
  String appUpdateConfirm(String app, String version) {
    return 'Are you sure to update $app to $version?';
  }

  @override
  String get appUpdateSuccess => 'Update started successfully';

  @override
  String appUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String appOperateFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get appInstallContainerName => 'Container Name';

  @override
  String get appInstallCpuLimit => 'CPU Limit';

  @override
  String get appInstallMemoryLimit => 'Memory Limit';

  @override
  String get appInstallPorts => 'Ports';

  @override
  String get appInstallEnv => 'Environment Variables';

  @override
  String get appInstallEnvKey => 'Key';

  @override
  String get appInstallEnvValue => 'Value';

  @override
  String get appInstallPortService => 'Service Port';

  @override
  String get appInstallPortHost => 'Host Port';

  @override
  String get appTabInfo => 'Info';

  @override
  String get appTabConfig => 'Config';

  @override
  String get containerTitle => 'Container Management';

  @override
  String get containerStatusRunning => 'Running';

  @override
  String get containerStatusStopped => 'Stopped';

  @override
  String get containerStatusPaused => 'Paused';

  @override
  String get containerStatusExited => 'Exited';

  @override
  String get containerStatusRestarting => 'Restarting';

  @override
  String get containerStatusRemoving => 'Removing';

  @override
  String get containerStatusDead => 'Dead';

  @override
  String get containerStatusCreated => 'Created';

  @override
  String get containerActionStart => 'Start';

  @override
  String get containerActionStop => 'Stop';

  @override
  String get containerActionRestart => 'Restart';

  @override
  String get containerActionDelete => 'Delete';

  @override
  String get containerActionLogs => 'Logs';

  @override
  String get containerActionTerminal => 'Terminal';

  @override
  String get containerActionStats => 'Stats';

  @override
  String get containerActionInspect => 'Inspect';

  @override
  String get containerInspectJson => 'Inspect JSON';

  @override
  String get containerTabInfo => 'Info';

  @override
  String get containerTabLogs => 'Logs';

  @override
  String get containerTabStats => 'Stats';

  @override
  String get containerTabTerminal => 'Terminal';

  @override
  String get containerDetailTitle => 'Container Details';

  @override
  String get containerInfoId => 'Container ID';

  @override
  String get containerInfoName => 'Name';

  @override
  String get containerInfoImage => 'Image';

  @override
  String get containerInfoStatus => 'Status';

  @override
  String get containerInfoCreated => 'Created At';

  @override
  String get containerInfoCommand => 'Command';

  @override
  String get containerInfoPorts => 'Port Bindings';

  @override
  String get containerInfoEnv => 'Environment Variables';

  @override
  String get containerInfoLabels => 'Labels';

  @override
  String get containerStatsCpu => 'CPU Usage';

  @override
  String get containerStatsMemory => 'Memory Usage';

  @override
  String get containerStatsNetwork => 'Network I/O';

  @override
  String get containerStatsBlock => 'Block I/O';

  @override
  String get containerLogsAutoRefresh => 'Auto Refresh';

  @override
  String get containerLogsDownload => 'Download Logs';

  @override
  String containerDeleteConfirm(Object name) {
    return 'Are you sure you want to delete container $name? This action cannot be undone.';
  }

  @override
  String get containerOperateSuccess => 'Operation successful';

  @override
  String containerOperateFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get containerActionRename => 'Rename';

  @override
  String get containerActionUpgrade => 'Upgrade';

  @override
  String get containerActionEdit => 'Edit';

  @override
  String get containerActionCommit => 'Commit';

  @override
  String get containerActionCleanLog => 'Clean Logs';

  @override
  String get containerActionDownloadLog => 'View Logs';

  @override
  String get containerActionPrune => 'Prune';

  @override
  String get containerActionTag => 'Tag';

  @override
  String get containerActionPush => 'Push';

  @override
  String get containerActionSave => 'Save';

  @override
  String get containerImage => 'Image';

  @override
  String get containerUpgradeForcePull => 'Force Pull';

  @override
  String get containerCommitImage => 'New Image';

  @override
  String get containerCommitAuthor => 'Author';

  @override
  String get containerCommitComment => 'Comment';

  @override
  String get containerCommitPause => 'Pause Container';

  @override
  String get containerCpuShares => 'CPU Shares';

  @override
  String get containerMemory => 'Memory';

  @override
  String containerCleanLogConfirm(String name) {
    return 'Clean logs for $name?';
  }

  @override
  String get containerPruneType => 'Prune Type';

  @override
  String get containerPruneTypeContainer => 'Container';

  @override
  String get containerPruneTypeImage => 'Image';

  @override
  String get containerPruneTypeVolume => 'Volume';

  @override
  String get containerPruneTypeNetwork => 'Network';

  @override
  String get containerPruneTypeBuildCache => 'Build Cache';

  @override
  String get containerPruneWithTagAll => 'Include All Tags';

  @override
  String get containerBuildContext => 'Context Directory';

  @override
  String get containerBuildDockerfile => 'Dockerfile Path';

  @override
  String get containerBuildTags => 'Tags (comma separated)';

  @override
  String get containerBuildArgs => 'Build Args';

  @override
  String get containerImageLoadPath => 'Image File Path';

  @override
  String get containerTagLabel => 'Target Image';

  @override
  String get containerPushConfirm => 'Push this image?';

  @override
  String get containerSavePath => 'Save Path';

  @override
  String get containerNoLogs => 'No logs';

  @override
  String get containerLoading => 'Loading...';

  @override
  String get containerTerminalConnect => 'Connect';

  @override
  String get containerTerminalDisconnect => 'Disconnect';

  @override
  String get commonStart => 'Start';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonRestart => 'Restart';

  @override
  String get commonLogs => 'Logs';

  @override
  String get commonDeleteConfirm =>
      'Are you sure you want to delete this item?';

  @override
  String get orchestrationTitle => 'Orchestration';

  @override
  String get orchestrationCompose => 'Compose';

  @override
  String get orchestrationImages => 'Images';

  @override
  String get orchestrationNetworks => 'Networks';

  @override
  String get orchestrationVolumes => 'Volumes';

  @override
  String get orchestrationPullImage => 'Pull Image';

  @override
  String get orchestrationPullImageHint =>
      'Enter image name (e.g. nginx:latest)';

  @override
  String get orchestrationPullSuccess => 'Image pull started';

  @override
  String get orchestrationPullFailed => 'Failed to pull image';

  @override
  String get orchestrationComposeCreateTitle => 'Create Compose Project';

  @override
  String get orchestrationComposeContentLabel => 'Compose Content';

  @override
  String get orchestrationComposeContentHint =>
      'Paste docker-compose.yml content';

  @override
  String get orchestrationComposeUpdate => 'Update Compose';

  @override
  String get orchestrationComposeTest => 'Test Compose';

  @override
  String get orchestrationComposeCleanLog => 'Clean Compose Logs';

  @override
  String orchestrationComposeCleanLogConfirm(String name) {
    return 'Clean logs for $name?';
  }

  @override
  String get orchestrationStatusUnknown => 'Unknown';

  @override
  String get orchestrationServicesLabel => 'Services';

  @override
  String get orchestrationImageBuild => 'Build Image';

  @override
  String get orchestrationImageLoad => 'Load Image';

  @override
  String get orchestrationImageSearch => 'Search Images';

  @override
  String get orchestrationImageSearchResult => 'Search Results';

  @override
  String get orchestrationImageSizeLabel => 'Size';

  @override
  String get orchestrationImageCreatedLabel => 'Created';

  @override
  String get appActionWeb => 'Web';

  @override
  String get containerManagement => 'Container Management';

  @override
  String get orchestration => 'Orchestration';

  @override
  String get images => 'Images';

  @override
  String get networks => 'Networks';

  @override
  String get volumes => 'Volumes';

  @override
  String get compose => 'Compose';

  @override
  String get ports => 'Ports';

  @override
  String get env => 'Environment';

  @override
  String get viewContainer => 'View Container';

  @override
  String get webUI => 'Web UI';

  @override
  String get readme => 'README';

  @override
  String get appDescription => 'Description';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusRestarting => 'Restarting';

  @override
  String get actionStart => 'Start';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionRestart => 'Restart';

  @override
  String get actionUninstall => 'Uninstall';

  @override
  String get logSearchHint => 'Search logs...';

  @override
  String get logRefresh => 'Refresh Logs';

  @override
  String get logScrollToBottom => 'Scroll to Bottom';

  @override
  String get logSettings => 'Settings';

  @override
  String get logSettingsTitle => 'Log Settings';

  @override
  String get logFontSize => 'Font Size';

  @override
  String get logWrap => 'Wrap Text';

  @override
  String get logShowTimestamp => 'Show Timestamp';

  @override
  String get logTheme => 'Theme';

  @override
  String get logNoLogs => 'No logs available';

  @override
  String get logNoMatches => 'No matches found';

  @override
  String get logTimestampFormat => 'Timestamp Format';

  @override
  String get logTimestampAbsolute => 'Absolute';

  @override
  String get logTimestampRelative => 'Relative';

  @override
  String logMatchCount(int current, int total) {
    return '$current/$total matches';
  }

  @override
  String get logPreviousMatch => 'Previous match';

  @override
  String get logNextMatch => 'Next match';

  @override
  String get logEditTheme => 'Edit Theme Rules';

  @override
  String get logThemeEditor => 'Theme Editor';

  @override
  String get logRulePattern => 'Pattern';

  @override
  String get logRuleType => 'Type';

  @override
  String get logRuleCaseSensitive => 'Case Sensitive';

  @override
  String get logRuleCaseInsensitive => 'Case Insensitive';

  @override
  String get logRuleColor => 'Text Color';

  @override
  String get logRuleBackgroundColor => 'Background Color';

  @override
  String get logRuleBold => 'Bold';

  @override
  String get logRuleItalic => 'Italic';

  @override
  String get logRuleUnderline => 'Underline';

  @override
  String get logImportTheme => 'Import Theme';

  @override
  String get logExportTheme => 'Export Theme';

  @override
  String get logImportSuccess => 'Theme imported successfully';

  @override
  String get logInvalidJson => 'Invalid JSON';

  @override
  String get logLineHeight => 'Line Height';

  @override
  String get logViewMode => 'View Mode';

  @override
  String get logModeWrap => 'Wrap';

  @override
  String get logModeScrollLine => 'Scroll Line';

  @override
  String get logModeScrollPage => 'Scroll Page';

  @override
  String get themeDynamicColor => 'Dynamic Color';

  @override
  String get themeDynamicColorDesc => 'Use wallpaper color as theme color';

  @override
  String get themeSeedColor => 'Custom Color';

  @override
  String get themeSeedColorFallbackDesc =>
      'Used when dynamic color is unavailable';

  @override
  String get containerTabOverview => 'Overview';

  @override
  String get containerTabContainers => 'Containers';

  @override
  String get containerTabOrchestration => 'Orchestration';

  @override
  String get containerTabImages => 'Images';

  @override
  String get containerTabNetworks => 'Networks';

  @override
  String get containerTabVolumes => 'Volumes';

  @override
  String get containerTabRepositories => 'Repositories';

  @override
  String get containerTabTemplates => 'Templates';

  @override
  String get containerTabConfig => 'Config';

  @override
  String get containerSearch => 'Search containers';

  @override
  String get containerFilter => 'Filter containers';

  @override
  String get containerNetworkSubnetLabel => 'Subnet';

  @override
  String get containerNetworkSubnetHint => 'e.g. 172.20.0.0/16';

  @override
  String get containerNetworkGatewayLabel => 'Gateway';

  @override
  String get containerNetworkGatewayHint => 'e.g. 172.20.0.1';

  @override
  String get containerRepoUrlExample => 'e.g. https://github.com/user/repo';

  @override
  String get containerTemplateContentHint => 'YAML content';

  @override
  String get containerCreate => 'Create Container';

  @override
  String get containerEmptyTitle => 'No containers';

  @override
  String get containerEmptyDesc => 'Tap the button below to create a container';

  @override
  String get containerStatsTitle => 'Container Stats';

  @override
  String get containerStatsDetailTitle => 'Detailed Status';

  @override
  String get containerStatsImages => 'Images';

  @override
  String get containerStatsNetworks => 'Networks';

  @override
  String get containerStatsVolumes => 'Volumes';

  @override
  String get containerStatsRepos => 'Repos';

  @override
  String get containerStatsTotal => 'Total';

  @override
  String get containerStatsRunning => 'Running';

  @override
  String get containerStatsStopped => 'Stopped';

  @override
  String containerFeatureDeveloping(Object feature) {
    return '$feature is under development';
  }

  @override
  String get orchestrationCreateProject => 'Create Project';

  @override
  String get orchestrationCreateNetwork => 'Create Network';

  @override
  String get orchestrationCreateVolume => 'Create Volume';

  @override
  String get orchestrationCreateRepo => 'Create Repository';

  @override
  String get orchestrationCreateTemplate => 'Create Template';

  @override
  String get operationsCenterPageTitle => 'Operations Center';

  @override
  String get operationsCenterIntro =>
      'Phase 1 capabilities will be delivered here week by week so server operations stay in one mobile-first entry.';

  @override
  String get operationsCenterServerEntryTitle => 'Operations Center';

  @override
  String get operationsCenterServerEntrySubtitle =>
      'Automation, runtime, and system control in one place';

  @override
  String get operationsCenterAutomationSectionTitle => 'Automation';

  @override
  String get operationsCenterAutomationSectionDescription =>
      'Commands, schedules, scripts, and backup flows';

  @override
  String get operationsCenterRuntimeSectionTitle => 'Runtime & Delivery';

  @override
  String get operationsCenterRuntimeSectionDescription =>
      'Shared runtime chains for PHP and Node.js';

  @override
  String get operationsCenterSystemSectionTitle => 'System Control';

  @override
  String get operationsCenterSystemSectionDescription =>
      'Host assets, SSH, processes, and logs';

  @override
  String get operationsCommandsTitle => 'Commands';

  @override
  String get operationsCommandFormTitle => 'Command Form';

  @override
  String get operationsHostAssetsTitle => 'Host Assets';

  @override
  String get operationsHostAssetFormTitle => 'Host Asset Form';

  @override
  String get operationsSshTitle => 'SSH';

  @override
  String get operationsSshCertsTitle => 'SSH Certs';

  @override
  String get operationsSshLogsTitle => 'SSH Logs';

  @override
  String get operationsSshSessionsTitle => 'SSH Sessions';

  @override
  String get operationsProcessesTitle => 'Processes';

  @override
  String get operationsProcessDetailTitle => 'Process Detail';

  @override
  String get operationsCronjobsTitle => 'Cronjobs';

  @override
  String get operationsCronjobFormTitle => 'Cronjob Form';

  @override
  String get operationsCronjobRecordsTitle => 'Cronjob Records';

  @override
  String get operationsScriptsTitle => 'Script Library';

  @override
  String get cronjobsSearchHint => 'Search cronjobs';

  @override
  String get cronjobsFilterAllGroups => 'All groups';

  @override
  String get cronjobsGroupFilterAction => 'Filter by group';

  @override
  String get cronjobsEmptyTitle => 'No cronjobs';

  @override
  String get cronjobsEmptyDescription =>
      'Cronjobs will appear here after the Week 4 mainline flow loads data.';

  @override
  String get cronjobsSpecLabel => 'Spec';

  @override
  String get cronjobsNextRunLabel => 'Next run';

  @override
  String get cronjobsTypeLabel => 'Type';

  @override
  String get cronjobsLastRecordLabel => 'Last record';

  @override
  String get cronjobsEnableAction => 'Enable';

  @override
  String get cronjobsDisableAction => 'Disable';

  @override
  String get cronjobsHandleOnceAction => 'Handle once';

  @override
  String get cronjobsRecordsAction => 'Records';

  @override
  String get cronjobsStopAction => 'Stop';

  @override
  String get cronjobsStatusEnable => 'Enabled';

  @override
  String get cronjobsStatusDisable => 'Disabled';

  @override
  String get cronjobsStatusPending => 'Pending';

  @override
  String get cronjobsTypeShell => 'Shell';

  @override
  String get cronjobsTypeWebsite => 'Website';

  @override
  String get cronjobsTypeDatabase => 'Database';

  @override
  String get cronjobsTypeDirectory => 'Directory';

  @override
  String get cronjobsTypeSnapshot => 'Snapshot';

  @override
  String get cronjobsTypeLog => 'Log Cleanup';

  @override
  String cronjobsUpdateStatusConfirm(String name, String status) {
    return 'Update cronjob $name to $status?';
  }

  @override
  String cronjobsHandleOnceConfirm(String name) {
    return 'Run cronjob $name once now?';
  }

  @override
  String cronjobsStopConfirm(String name) {
    return 'Stop running cronjob $name?';
  }

  @override
  String get cronjobRecordsEmptyTitle => 'No records';

  @override
  String get cronjobRecordsEmptyDescription =>
      'Execution records will appear here after the cronjob runs.';

  @override
  String get cronjobRecordsStatusAll => 'All';

  @override
  String get cronjobRecordsStatusSuccess => 'Success';

  @override
  String get cronjobRecordsStatusWaiting => 'Waiting';

  @override
  String get cronjobRecordsStatusUnexecuted => 'Unexecuted';

  @override
  String get cronjobRecordsStatusFailed => 'Failed';

  @override
  String get cronjobRecordsIntervalLabel => 'Interval';

  @override
  String get cronjobRecordsMessageLabel => 'Message';

  @override
  String get cronjobRecordsViewLogTitle => 'Record Log';

  @override
  String get cronjobRecordsCleanAction => 'Clean records';

  @override
  String get cronjobRecordsCleanConfirm => 'Clean records for this cronjob?';

  @override
  String cronjobsDeleteConfirm(String name) {
    return 'Delete cronjob $name?';
  }

  @override
  String get cronjobFormCreateTitle => 'Create Cronjob';

  @override
  String get cronjobFormEditTitle => 'Edit Cronjob';

  @override
  String get cronjobFormBasicSectionTitle => 'Basic';

  @override
  String get cronjobFormScheduleSectionTitle => 'Schedule';

  @override
  String get cronjobFormTargetSectionTitle => 'Target';

  @override
  String get cronjobFormPolicySectionTitle => 'Policy & Alerts';

  @override
  String get cronjobFormTypeLabel => 'Type';

  @override
  String get cronjobFormUrlTypeLabel => 'URL';

  @override
  String get cronjobFormCustomSpecLabel => 'Custom spec';

  @override
  String get cronjobFormPreviewAction => 'Preview next runs';

  @override
  String get cronjobFormBuilderModeLabel => 'Use builder';

  @override
  String get cronjobFormRawModeLabel => 'Use raw cron spec';

  @override
  String get cronjobFormDeleteConfirm => 'Delete this cronjob?';

  @override
  String get cronjobFormBackupTypeLabel => 'Backup type';

  @override
  String get cronjobFormDatabaseTypeLabel => 'Database type';

  @override
  String get cronjobFormBackupArgsLabel => 'Backup args';

  @override
  String get cronjobFormBackupDirectoryLabel => 'Backup directory';

  @override
  String get cronjobFormDirectoryPathLabel => 'Directory path';

  @override
  String get cronjobFormSelectedFilesLabel => 'Selected files';

  @override
  String get cronjobFormExcludePatternsLabel => 'Exclude patterns';

  @override
  String get cronjobFormIncludeImagesLabel => 'Include images';

  @override
  String get cronjobFormSourceAccountsLabel => 'Source accounts';

  @override
  String get cronjobFormDownloadAccountLabel => 'Default download path';

  @override
  String get cronjobFormSecretLabel => 'Secret';

  @override
  String get cronjobFormExecutorLabel => 'Executor';

  @override
  String get cronjobFormUserLabel => 'User';

  @override
  String get cronjobFormShellInlineLabel => 'Inline';

  @override
  String get cronjobFormShellLibraryLabel => 'Library';

  @override
  String get cronjobFormShellPathLabel => 'Path';

  @override
  String get cronjobFormScriptLibraryLabel => 'Script library';

  @override
  String get cronjobFormScriptPathLabel => 'Script path';

  @override
  String get cronjobFormScriptLabel => 'Script';

  @override
  String get cronjobFormRetainCopiesLabel => 'Retain copies';

  @override
  String get cronjobFormRetryTimesLabel => 'Retry times';

  @override
  String get cronjobFormTimeoutLabel => 'Timeout';

  @override
  String get cronjobFormTimeoutUnitLabel => 'Unit';

  @override
  String get cronjobFormSecondsLabel => 'Seconds';

  @override
  String get cronjobFormMinutesLabel => 'Minutes';

  @override
  String get cronjobFormHoursLabel => 'Hours';

  @override
  String get cronjobFormIgnoreErrorsLabel => 'Ignore errors';

  @override
  String get cronjobFormArgumentsLabel => 'Arguments';

  @override
  String get cronjobFormEnableAlertsLabel => 'Enable alerts';

  @override
  String get cronjobFormAlertCountLabel => 'Alert count';

  @override
  String get cronjobFormScheduleModeLabel => 'Mode';

  @override
  String get cronjobFormScheduleDaily => 'Daily';

  @override
  String get cronjobFormScheduleWeekly => 'Weekly';

  @override
  String get cronjobFormScheduleMonthly => 'Monthly';

  @override
  String get cronjobFormScheduleEveryHours => 'Every N hours';

  @override
  String get cronjobFormScheduleEveryMinutes => 'Every N minutes';

  @override
  String get cronjobFormScheduleMinuteLabel => 'Minute';

  @override
  String get cronjobFormScheduleHourLabel => 'Hour';

  @override
  String get cronjobFormScheduleWeekdayLabel => 'Weekday';

  @override
  String get cronjobFormScheduleDayLabel => 'Day';

  @override
  String get cronjobFormScheduleIntervalLabel => 'Interval';

  @override
  String get scriptLibrarySearchHint => 'Search scripts';

  @override
  String get scriptLibraryFilterAllGroups => 'All groups';

  @override
  String get scriptLibraryGroupFilterAction => 'Filter by group';

  @override
  String get scriptLibraryEmptyTitle => 'No scripts';

  @override
  String get scriptLibraryEmptyDescription =>
      'Scripts will appear here after script library data loads.';

  @override
  String get scriptLibraryViewCodeAction => 'View code';

  @override
  String get scriptLibraryRunAction => 'Run';

  @override
  String get scriptLibrarySyncAction => 'Sync';

  @override
  String get scriptLibraryDeleteAction => 'Delete';

  @override
  String get scriptLibraryInteractiveLabel => 'Interactive';

  @override
  String get scriptLibraryInteractiveYes => 'Yes';

  @override
  String get scriptLibraryInteractiveNo => 'No';

  @override
  String get scriptLibraryCreatedAtLabel => 'Created at';

  @override
  String get scriptLibrarySyncConfirm => 'Sync the script library now?';

  @override
  String scriptLibraryDeleteConfirm(String name) {
    return 'Delete script $name?';
  }

  @override
  String get scriptLibraryCodeTitle => 'Script Code';

  @override
  String get scriptLibraryRunTitle => 'Run Script';

  @override
  String get scriptLibraryRunWaiting => 'Connecting to script output...';

  @override
  String get scriptLibraryRunNoOutput => 'No output yet';

  @override
  String get scriptLibraryRunDisconnected => 'Run output disconnected';

  @override
  String get operationsBackupsTitle => 'Backups';

  @override
  String get operationsBackupAccountFormTitle => 'Backup Account Form';

  @override
  String get operationsBackupRecordsTitle => 'Backup Records';

  @override
  String get operationsBackupRecoverTitle => 'Backup Recover';

  @override
  String get backupAccountsSearchHint => 'Search backup accounts';

  @override
  String get backupAccountsFilterAllTypes => 'All types';

  @override
  String get backupAccountsEmptyTitle => 'No backup accounts';

  @override
  String get backupAccountsEmptyDescription =>
      'Add a backup account to start using backup flows.';

  @override
  String get backupAccountsScopePublic => 'Public';

  @override
  String get backupAccountsScopePrivate => 'Private';

  @override
  String get backupAccountsTokenRefreshed => 'Token refreshed';

  @override
  String get backupAccountsConnectionOk => 'Connection ok';

  @override
  String get backupAccountsConnectionFailed => 'Connection failed';

  @override
  String backupAccountsDeleteConfirm(String name) {
    return 'Delete backup account $name?';
  }

  @override
  String get backupFilesSheetTitle => 'Backup Files';

  @override
  String get backupAccountCardBucketLabel => 'Bucket';

  @override
  String get backupAccountCardEndpointLabel => 'Endpoint';

  @override
  String get backupAccountCardPathLabel => 'Path';

  @override
  String get backupAccountCardBrowseFilesAction => 'Browse files';

  @override
  String get backupAccountCardRefreshTokenAction => 'Refresh token';

  @override
  String get backupFormBasicSectionTitle => 'Basic';

  @override
  String get backupFormCredentialsSectionTitle => 'Credentials';

  @override
  String get backupFormStorageSectionTitle => 'Storage';

  @override
  String get backupFormVerifySectionTitle => 'Verify';

  @override
  String get backupFormPublicScopeLabel => 'Public scope';

  @override
  String get backupFormProviderTypeLabel => 'Provider type';

  @override
  String get backupFormAccessKeyLabel => 'Access Key';

  @override
  String get backupFormUsernameAccessKeyLabel => 'Username / Access Key';

  @override
  String get backupFormCredentialLabel => 'Credential';

  @override
  String get backupFormAddressLabel => 'Address';

  @override
  String get backupFormPortLabel => 'Port';

  @override
  String get backupFormChinaCloudLabel => 'Use China cloud';

  @override
  String get backupFormClientIdLabel => 'Client ID';

  @override
  String get backupFormClientSecretLabel => 'Client Secret';

  @override
  String get backupFormRedirectUriLabel => 'Redirect URI';

  @override
  String get backupFormAuthCodeLabel => 'Authorization Code';

  @override
  String get backupFormOpenAuthorizeAction => 'Open authorize page';

  @override
  String get backupFormTokenJsonLabel => 'Token JSON';

  @override
  String get backupFormDriveIdLabel => 'Drive ID';

  @override
  String get backupFormRefreshTokenLabel => 'Refresh Token';

  @override
  String get backupFormRememberCredentialsLabel => 'Remember credentials';

  @override
  String get backupFormRegionLabel => 'Region';

  @override
  String get backupFormDomainLabel => 'Domain';

  @override
  String get backupFormEndpointLabel => 'Endpoint';

  @override
  String get backupFormBucketLabel => 'Bucket';

  @override
  String get backupFormBackupPathLabel => 'Backup path';

  @override
  String get backupFormVerifiedLabel => 'Verified';

  @override
  String get backupFormNotVerifiedLabel => 'Not verified';

  @override
  String get backupFormTestingLabel => 'Testing...';

  @override
  String get backupFormTestConnectionAction => 'Test connection';

  @override
  String get backupRecordsEmptyTitle => 'No backup records';

  @override
  String get backupRecordsEmptyDescription =>
      'Backup records will appear here after backups run.';

  @override
  String get backupRecordsFilterAction => 'Filter';

  @override
  String backupRecordsDeleteConfirm(String name) {
    return 'Delete backup record $name?';
  }

  @override
  String get backupRecordsTypeLabel => 'Type';

  @override
  String get backupRecordsNameLabel => 'Name';

  @override
  String get backupRecordsDetailNameLabel => 'Detail name';

  @override
  String get backupRecordsApplyAction => 'Apply';

  @override
  String get backupRecordsStatusLabel => 'Status';

  @override
  String get backupRecordsSizeLabel => 'Size';

  @override
  String get backupRecordsDownloadAction => 'Download';

  @override
  String get backupRecordsRecoverAction => 'Recover';

  @override
  String get backupRecoverResourceStepTitle => 'Resource';

  @override
  String get backupRecoverRecordStepTitle => 'Record';

  @override
  String get backupRecoverConfirmStepTitle => 'Confirm';

  @override
  String get backupRecoverTypeLabel => 'Type';

  @override
  String get backupRecoverAppLabel => 'App';

  @override
  String get backupRecoverWebsiteLabel => 'Website';

  @override
  String get backupRecoverDatabaseLabel => 'Database';

  @override
  String get backupRecoverOtherLabel => 'Other';

  @override
  String get backupRecoverSourceTypeLabel => 'Source type';

  @override
  String get backupRecoverDatabaseTypeLabel => 'Database type';

  @override
  String get backupRecoverDatabaseItemLabel => 'Database item';

  @override
  String get backupRecoverLoadRecordsAction => 'Load records';

  @override
  String get backupRecoverNoCandidateRecords => 'No candidate records';

  @override
  String get backupRecoverRecordLabel => 'Backup record';

  @override
  String get backupRecoverSecretLabel => 'Secret';

  @override
  String get backupRecoverTimeoutLabel => 'Timeout';

  @override
  String get backupRecoverStartAction => 'Start recover';

  @override
  String get backupRecoverConfirmMessage =>
      'Start recovery from the selected backup record?';

  @override
  String backupRecoverUnsupportedTypeHint(String type) {
    return 'The current mainline preserves $type record context, but direct recover is not available yet.';
  }

  @override
  String backupRecoverUnsupportedTypeSubmitHint(String type) {
    return 'Recover submit is currently unavailable for $type records.';
  }

  @override
  String backupResourceTypeUnknownLabel(String type) {
    return 'Unknown type: $type';
  }

  @override
  String get backupErrorOauthOpenFailed =>
      'Unable to open the authorization page';

  @override
  String get backupErrorOauthUnsupportedProvider =>
      'This backup provider does not support mobile authorization';

  @override
  String get backupErrorRecordPathEmpty => 'The backup record path is empty';

  @override
  String get backupErrorRecordDownloadEmpty =>
      'The downloaded backup file is empty';

  @override
  String get cronjobFormErrorImportInvalidJson =>
      'The imported cronjob file must be a JSON array.';

  @override
  String get cronjobFormErrorExportEmpty =>
      'The exported cronjob file is empty.';

  @override
  String get cronjobFormErrorSpecRequired => 'Cronjob spec is required.';

  @override
  String get cronjobFormErrorUnsupportedType =>
      'This cronjob type is not supported in the mobile form yet.';

  @override
  String get backupTypeLocal => 'Local';

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
  String get backupTypeAliyun => 'Aliyun Drive';

  @override
  String get backupTypeApp => 'App';

  @override
  String get backupTypeWebsite => 'Website';

  @override
  String get backupTypeDatabase => 'Database';

  @override
  String get backupTypeDirectory => 'Directory';

  @override
  String get backupTypeSnapshot => 'Snapshot';

  @override
  String get backupTypeLog => 'Log';

  @override
  String get backupTypeContainer => 'Container';

  @override
  String get backupTypeCompose => 'Compose';

  @override
  String get backupTypeOther => 'Other';

  @override
  String get databaseTypeMysql => 'MySQL';

  @override
  String get databaseTypeMysqlCluster => 'MySQL Cluster';

  @override
  String get databaseTypeMariadb => 'MariaDB';

  @override
  String get databaseTypePostgresql => 'PostgreSQL';

  @override
  String get databaseTypePostgresqlCluster => 'PostgreSQL Cluster';

  @override
  String get databaseTypeRedis => 'Redis';

  @override
  String get cronjobFormAppsLabel => 'Apps';

  @override
  String get cronjobFormWebsitesLabel => 'Websites';

  @override
  String get cronjobFormDatabasesLabel => 'Databases';

  @override
  String get cronjobFormIgnoreAppsLabel => 'Ignore apps';

  @override
  String get cronjobFormShellModeInline => 'Inline';

  @override
  String get cronjobFormShellModeLibrary => 'Library';

  @override
  String get cronjobFormShellModePath => 'Path';

  @override
  String cronjobFormUrlItemLabel(int index) {
    return 'URL $index';
  }

  @override
  String get cronjobFormAddUrlAction => 'Add URL';

  @override
  String get cronjobFormAlertMethodMail => 'Mail';

  @override
  String get cronjobFormAlertMethodWecom => 'WeCom';

  @override
  String get cronjobFormAlertMethodDingtalk => 'DingTalk';

  @override
  String cronjobFormCustomSpecItemLabel(int index) {
    return 'Custom spec $index';
  }

  @override
  String get cronjobFormImportInvalidJson =>
      'The imported cronjob file must be a JSON array';

  @override
  String get cronjobFormExportEmpty => 'The exported cronjob file is empty';

  @override
  String get cronjobFormSpecRequired => 'Cronjob spec is required';

  @override
  String get cronjobFormUnsupportedType =>
      'This cronjob type is not supported in mobile yet';

  @override
  String cronjobFormUnknownBackupType(String type) {
    return 'Unknown backup type: $type';
  }

  @override
  String cronjobFormUnknownDatabaseType(String type) {
    return 'Unknown database type: $type';
  }

  @override
  String cronjobFormUnknownAlertMethod(String method) {
    return 'Unknown alert method: $method';
  }

  @override
  String cronjobFormUnknownError(String message) {
    return 'Unexpected cronjob form error: $message';
  }

  @override
  String get operationsLogsTitle => 'Logs Center';

  @override
  String get operationsSystemLogViewerTitle => 'System Log Viewer';

  @override
  String get operationsTaskLogDetailTitle => 'Task Log Detail';

  @override
  String get logsCenterTabOperation => 'Operation';

  @override
  String get logsCenterTabLogin => 'Login';

  @override
  String get logsCenterTabTask => 'Task';

  @override
  String get logsCenterTabSystem => 'System';

  @override
  String get logsOperationSourceLabel => 'Source';

  @override
  String get logsOperationActionLabel => 'Operation';

  @override
  String get logsOperationEmptyTitle => 'No operation logs';

  @override
  String get logsOperationEmptyDescription =>
      'Operation logs will appear here after the server records actions.';

  @override
  String get logsLoginIpLabel => 'IP';

  @override
  String get logsLoginEmptyTitle => 'No login logs';

  @override
  String get logsLoginEmptyDescription =>
      'Login logs will appear here after the server records authentication activity.';

  @override
  String get logsTaskTypeLabel => 'Task type';

  @override
  String logsTaskExecutingCountLabel(int count) {
    return 'Executing: $count';
  }

  @override
  String get logsTaskOpenDetailAction => 'View log';

  @override
  String get logsTaskEmptyTitle => 'No task logs';

  @override
  String get logsTaskEmptyDescription =>
      'Task logs will appear here after the server runs background tasks.';

  @override
  String get logsSystemFilesLabel => 'Log files';

  @override
  String get logsSystemSourceLabel => 'Source';

  @override
  String get logsSystemSourceAgent => 'Agent';

  @override
  String get logsSystemSourceCore => 'Core';

  @override
  String get logsSystemOpenViewerAction => 'Open viewer';

  @override
  String get logsSystemEmptyTitle => 'No system log files';

  @override
  String get logsSystemEmptyDescription =>
      'System log files will appear here after the server exposes log output.';

  @override
  String get logsSystemViewerNoFileSelected => 'Select a log file to view.';

  @override
  String get logsSystemWatchLabel => 'Watch';

  @override
  String get logsStatusAll => 'All';

  @override
  String get logsStatusSuccess => 'Success';

  @override
  String get logsStatusFailed => 'Failed';

  @override
  String get logsStatusExecuting => 'Executing';

  @override
  String get logsTaskDetailIdLabel => 'Task ID';

  @override
  String get logsTaskDetailTypeLabel => 'Task type';

  @override
  String get logsTaskDetailStatusLabel => 'Status';

  @override
  String get logsTaskDetailCurrentStepLabel => 'Current step';

  @override
  String get logsTaskDetailCreatedAtLabel => 'Created at';

  @override
  String get logsTaskDetailLogFileLabel => 'Log file';

  @override
  String get logsTaskDetailErrorLabel => 'Error';

  @override
  String get logsOperationLoadFailed => 'Failed to load operation logs.';

  @override
  String get logsLoginLoadFailed => 'Failed to load login logs.';

  @override
  String get logsTaskLoadFailed => 'Failed to load task logs.';

  @override
  String get logsTaskDetailLoadFailed => 'Failed to load task log content.';

  @override
  String get logsTaskMissingTaskId =>
      'Task ID is required to load task log content.';

  @override
  String get logsSystemFilesLoadFailed => 'Failed to load system log files.';

  @override
  String get logsSystemContentLoadFailed =>
      'Failed to load system log content.';

  @override
  String get operationsRuntimesTitle => 'Runtimes';

  @override
  String get operationsRuntimeDetailTitle => 'Runtime Detail';

  @override
  String get operationsRuntimeFormTitle => 'Runtime Form';

  @override
  String get runtimeFormCreateTitle => 'Create Runtime';

  @override
  String get runtimeFormEditTitle => 'Edit Runtime';

  @override
  String get runtimeOverviewTab => 'Overview';

  @override
  String get runtimeConfigTab => 'Config';

  @override
  String get runtimeAdvancedTab => 'Advanced';

  @override
  String get runtimeSearchHint => 'Search runtimes...';

  @override
  String get runtimeEmptyTitle => 'No runtimes';

  @override
  String get runtimeEmptyDescription =>
      'Runtimes in the selected language category will appear here.';

  @override
  String get runtimeActionStart => 'Start';

  @override
  String get runtimeActionStop => 'Stop';

  @override
  String get runtimeActionRestart => 'Restart';

  @override
  String get runtimeActionSync => 'Sync';

  @override
  String runtimeActionUnknown(String action) {
    return 'Unknown action: $action';
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
    return 'Unknown runtime: $type';
  }

  @override
  String get runtimeResourceLocal => 'Local';

  @override
  String get runtimeResourceAppStore => 'App Store';

  @override
  String runtimeResourceUnknown(String resource) {
    return 'Unknown resource: $resource';
  }

  @override
  String get runtimeStatusAll => 'All';

  @override
  String get runtimeStatusRunning => 'Running';

  @override
  String get runtimeStatusStopped => 'Stopped';

  @override
  String get runtimeStatusError => 'Error';

  @override
  String get runtimeStatusStarting => 'Starting';

  @override
  String get runtimeStatusBuilding => 'Building';

  @override
  String get runtimeStatusRecreating => 'Recreating';

  @override
  String get runtimeStatusSystemRestart => 'System Restart';

  @override
  String runtimeStatusUnknown(String status) {
    return 'Unknown status: $status';
  }

  @override
  String get runtimeFieldType => 'Type';

  @override
  String get runtimeFieldStatus => 'Status';

  @override
  String get runtimeFieldVersion => 'Version';

  @override
  String get runtimeFieldResource => 'Resource';

  @override
  String get runtimeFieldImage => 'Image';

  @override
  String get runtimeFieldCodeDir => 'Code directory';

  @override
  String get runtimeFieldExternalPort => 'External port';

  @override
  String get runtimeFieldPath => 'Path';

  @override
  String get runtimeFieldSource => 'Source';

  @override
  String get runtimeFieldRemark => 'Remark';

  @override
  String get runtimeFieldHostIp => 'Host IP';

  @override
  String get runtimeFieldContainerName => 'Container name';

  @override
  String get runtimeFieldContainerStatus => 'Container status';

  @override
  String get runtimeFieldExecScript => 'Run script';

  @override
  String get runtimeFieldPackageManager => 'Package manager';

  @override
  String get runtimeFieldCreatedAt => 'Created at';

  @override
  String get runtimeFieldParams => 'Parameters';

  @override
  String get runtimeFieldRebuild => 'Rebuild on save';

  @override
  String get runtimeFormBasicSectionTitle => 'Basic';

  @override
  String get runtimeFormRuntimeSectionTitle => 'Runtime';

  @override
  String get runtimeFormAdvancedSectionTitle => 'Advanced';

  @override
  String get runtimeFormAppStoreCreateWeek8Hint =>
      'App Store runtime creation stays in the Week 8 wizard. Week 7 only supports the manual runtime skeleton.';

  @override
  String get runtimeFormPhpCreateWeek8Hint =>
      'PHP creation keeps its dedicated flow for Week 8. Week 7 focuses on the shared runtime skeleton.';

  @override
  String get runtimeFormNameRequired => 'Runtime name is required.';

  @override
  String get runtimeFormImageRequired => 'Runtime image is required.';

  @override
  String get runtimeFormCodeDirRequired => 'Code directory is required.';

  @override
  String get runtimeFormPortInvalid => 'External port must be greater than 0.';

  @override
  String get runtimeFormContainerNameRequired => 'Container name is required.';

  @override
  String get runtimeFormExecScriptRequired =>
      'Run script is required for this runtime type.';

  @override
  String get runtimeFormPackageManagerRequired =>
      'Package manager is required for Node runtimes.';

  @override
  String get runtimeAdvancedRequiresRunning =>
      'Advanced runtime-specific capabilities unlock after the runtime is running.';

  @override
  String runtimeAdvancedSummary(
      int ports, int environments, int volumes, int hosts) {
    return 'Advanced config counts: $ports ports, $environments environments, $volumes volumes, $hosts extra hosts.';
  }

  @override
  String runtimeDeleteConfirm(String name) {
    return 'Delete runtime $name?';
  }

  @override
  String runtimeOperateConfirm(String action, String name) {
    return 'Run $action on runtime $name?';
  }

  @override
  String get runtimeListLoadFailed => 'Failed to load runtimes.';

  @override
  String get runtimeDetailLoadFailed => 'Failed to load runtime detail.';

  @override
  String get runtimeFormLoadFailed => 'Failed to load runtime form data.';

  @override
  String get runtimeFormSaveFailed => 'Failed to save runtime.';

  @override
  String get runtimeSyncFailed => 'Failed to sync runtime status.';

  @override
  String get runtimeDeleteFailed => 'Failed to delete runtime.';

  @override
  String get runtimeOperateFailed => 'Failed to operate runtime.';

  @override
  String get runtimeRemarkSaveFailed => 'Failed to save runtime remark.';

  @override
  String get runtimeRemarkTooLong => 'Remark must be 128 characters or fewer.';

  @override
  String get operationsPhpExtensionsTitle => 'PHP Extensions';

  @override
  String get operationsPhpConfigTitle => 'PHP Config';

  @override
  String get operationsNodeModulesTitle => 'Node Modules';

  @override
  String get operationsNodeScriptsTitle => 'Node Scripts';

  @override
  String get commandsCreateTitle => 'Create Command';

  @override
  String get commandsEditTitle => 'Edit Command';

  @override
  String get commandsSearchHint => 'Search commands';

  @override
  String get commandsFilterAllGroups => 'All groups';

  @override
  String get commandsGroupFilterAction => 'Filter by group';

  @override
  String get commandsEmptyTitle => 'No commands';

  @override
  String get commandsEmptyDescription =>
      'Create a quick command or import a CSV to start building your command library.';

  @override
  String get commandsGroupFieldLabel => 'Group';

  @override
  String get commandsCommandFieldLabel => 'Command';

  @override
  String get commandsPreviewLabel => 'Command Preview';

  @override
  String get commandsImportPreviewEmptyTitle => 'Nothing to import';

  @override
  String get commandsImportPreviewEmpty =>
      'The CSV preview returned no commands.';

  @override
  String get commandsImportingLabel => 'Import preview ready';

  @override
  String get commandsSelectAll => 'Select all';

  @override
  String get commandsApplyGroup => 'Apply group';

  @override
  String commandsExportSaved(String path) {
    return 'Command export saved to $path';
  }

  @override
  String commandsDeleteConfirm(String name) {
    return 'Delete command $name?';
  }

  @override
  String commandsDeleteSelectedConfirm(int count) {
    return 'Delete $count selected commands?';
  }

  @override
  String get hostAssetsCreateTitle => 'Create Host Asset';

  @override
  String get hostAssetsEditTitle => 'Edit Host Asset';

  @override
  String get hostAssetsSearchHint => 'Search hosts';

  @override
  String get hostAssetsFilterAllGroups => 'All groups';

  @override
  String get hostAssetsGroupFilterAction => 'Filter by group';

  @override
  String get hostAssetsEmptyTitle => 'No hosts';

  @override
  String get hostAssetsEmptyDescription =>
      'Add a host asset to manage SSH targets and grouped connections from your phone.';

  @override
  String hostAssetsDeleteConfirm(String name) {
    return 'Delete host $name?';
  }

  @override
  String hostAssetsDeleteSelectedConfirm(int count) {
    return 'Delete $count selected hosts?';
  }

  @override
  String get hostAssetsBasicSectionTitle => 'Basic Info';

  @override
  String get hostAssetsAuthSectionTitle => 'Authentication';

  @override
  String get hostAssetsConnectionSectionTitle => 'Connection Check';

  @override
  String get hostAssetsAddressLabel => 'Address';

  @override
  String get hostAssetsPortLabel => 'Port';

  @override
  String get hostAssetsGroupLabel => 'Group';

  @override
  String get hostAssetsUserLabel => 'User';

  @override
  String get hostAssetsPasswordLabel => 'Password';

  @override
  String get hostAssetsPrivateKeyLabel => 'Private Key';

  @override
  String get hostAssetsPassPhraseLabel => 'Passphrase';

  @override
  String get hostAssetsRememberPasswordLabel => 'Remember Password';

  @override
  String get hostAssetsPasswordMode => 'Password';

  @override
  String get hostAssetsKeyMode => 'Private Key';

  @override
  String get hostAssetsTestAction => 'Test Connection';

  @override
  String get hostAssetsMoveGroupAction => 'Move Group';

  @override
  String get hostAssetsStatusNotTested => 'Not tested';

  @override
  String get hostAssetsStatusSuccess => 'Success';

  @override
  String get hostAssetsStatusFailed => 'Failed';

  @override
  String get hostAssetsConnectionVerified => 'Connection verified';

  @override
  String get hostAssetsConnectionNeedsTest =>
      'Run a connection test before saving';

  @override
  String get hostAssetsTestFailed => 'Connection test failed';

  @override
  String get sshSettingsServiceSectionTitle => 'Service';

  @override
  String get sshSettingsAuthenticationSectionTitle => 'Authentication';

  @override
  String get sshSettingsNetworkSectionTitle => 'Network';

  @override
  String get sshSettingsRawFileSectionTitle => 'Raw File';

  @override
  String get sshAutoStartLabel => 'Auto start';

  @override
  String get sshPortLabel => 'Port';

  @override
  String get sshListenAddressLabel => 'Listen address';

  @override
  String get sshPermitRootLoginLabel => 'Permit root login';

  @override
  String get sshPasswordAuthenticationLabel => 'Password authentication';

  @override
  String get sshPubkeyAuthenticationLabel => 'Public key authentication';

  @override
  String get sshUseDnsLabel => 'Use DNS';

  @override
  String get sshCurrentUserLabel => 'Current user';

  @override
  String get sshRawFilePlaceholder => '# The SSH configuration file is empty.';

  @override
  String get sshReloadAction => 'Reload';

  @override
  String get sshSaveRawFileConfirm =>
      'Overwrite the SSH configuration file with the current content?';

  @override
  String sshOperateConfirm(String operation) {
    return 'Run SSH action $operation?';
  }

  @override
  String sshUpdateSettingConfirm(String label, String value) {
    return 'Update $label to $value?';
  }

  @override
  String get sshCertsEmptyTitle => 'No SSH certs';

  @override
  String get sshCertsEmptyDescription =>
      'Create or sync an SSH certificate to manage key login from the panel.';

  @override
  String get sshCertSyncConfirm => 'Sync SSH certs from the current server?';

  @override
  String sshCertDeleteConfirm(String name) {
    return 'Delete SSH cert $name?';
  }

  @override
  String get sshCertCreateTitle => 'Create SSH Cert';

  @override
  String get sshCertEditTitle => 'Edit SSH Cert';

  @override
  String get sshCertEncryptionModeLabel => 'Encryption mode';

  @override
  String get sshCertPassPhraseLabel => 'Passphrase';

  @override
  String get sshCertPublicKeyLabel => 'Public key';

  @override
  String get sshCertPrivateKeyLabel => 'Private key';

  @override
  String get sshCertModeLabel => 'Create mode';

  @override
  String get sshCertModeGenerate => 'Generate';

  @override
  String get sshCertModeInput => 'Input';

  @override
  String get sshCertModeImport => 'Import';

  @override
  String get sshCertCreatedAtLabel => 'Created at';

  @override
  String get sshAuthModePassword => 'Password';

  @override
  String get sshAuthModeKey => 'Key';

  @override
  String get sshLogsEmptyTitle => 'No SSH logs';

  @override
  String get sshLogsEmptyDescription =>
      'SSH login logs will appear here after the server records activity.';

  @override
  String get sshLogsSearchHint => 'Search IP, user, or message';

  @override
  String get sshLogsStatusAll => 'All';

  @override
  String get sshLogsStatusSuccess => 'Success';

  @override
  String get sshLogsStatusFailed => 'Failed';

  @override
  String get sshLogsIpLabel => 'IP';

  @override
  String get sshLogsAreaLabel => 'Area';

  @override
  String get sshLogsAuthModeLabel => 'Auth mode';

  @override
  String get sshLogsTimeLabel => 'Time';

  @override
  String get sshLogsMessageLabel => 'Message';

  @override
  String sshLogsExportSaved(String path) {
    return 'SSH logs exported to $path';
  }

  @override
  String get sshLogCopied => 'SSH log copied';

  @override
  String get sshSessionsEmptyTitle => 'No SSH sessions';

  @override
  String get sshSessionsEmptyDescription =>
      'Active SSH sessions will appear here after the websocket feed returns data.';

  @override
  String get sshSessionsLoginUserLabel => 'Login user';

  @override
  String get sshSessionsLoginIpLabel => 'Login IP';

  @override
  String get sshSessionsTerminalLabel => 'TTY';

  @override
  String get sshSessionsHostLabel => 'Host';

  @override
  String get sshSessionsLoginTimeLabel => 'Login time';

  @override
  String sshSessionDisconnectConfirm(String username) {
    return 'Disconnect SSH session for $username?';
  }

  @override
  String get processesSearchPidLabel => 'PID';

  @override
  String get processesSearchNameLabel => 'Name';

  @override
  String get processesSearchUserLabel => 'User';

  @override
  String get processesFilterStatusLabel => 'Status';

  @override
  String get processesSortCpu => 'CPU';

  @override
  String get processesSortMemory => 'Memory';

  @override
  String get processesSortName => 'Name';

  @override
  String get processesSortPid => 'PID';

  @override
  String get processesEmptyTitle => 'No processes';

  @override
  String get processesEmptyDescription =>
      'Process data will appear here after the websocket feed returns rows.';

  @override
  String get processesListeningPortsLabel => 'Listening ports';

  @override
  String get processesConnectionsLabel => 'Connections';

  @override
  String get processesStartTimeLabel => 'Start time';

  @override
  String get processesThreadsLabel => 'Threads';

  @override
  String processesStopConfirm(String name) {
    return 'Stop process $name?';
  }

  @override
  String get processesStatusRunning => 'Running';

  @override
  String get processesStatusSleep => 'Sleeping';

  @override
  String get processesStatusStop => 'Stopped';

  @override
  String get processesStatusIdle => 'Idle';

  @override
  String get processesStatusWait => 'Waiting';

  @override
  String get processesStatusLock => 'Locked';

  @override
  String get processesStatusZombie => 'Zombie';

  @override
  String get processDetailOverviewSectionTitle => 'Overview';

  @override
  String get processDetailMemorySectionTitle => 'Memory';

  @override
  String get processDetailOpenFilesSectionTitle => 'Open Files';

  @override
  String get processDetailConnectionsSectionTitle => 'Connections';

  @override
  String get processDetailEnvironmentSectionTitle => 'Environment';

  @override
  String get processDetailParentPidLabel => 'Parent PID';

  @override
  String get processDetailDiskReadLabel => 'Disk read';

  @override
  String get processDetailDiskWriteLabel => 'Disk write';

  @override
  String get processDetailCommandLineLabel => 'Command line';

  @override
  String get processDetailNoEnvironment => 'No environment variables';

  @override
  String get processDetailNoConnections => 'No network connections';

  @override
  String get processDetailNoOpenFiles => 'No open files';

  @override
  String get operationsPlaceholderBackAction => 'Back to Operations Center';

  @override
  String operationsPlaceholderDescription(String moduleName, int week) {
    return '$moduleName is scheduled for Week $week. Week 1 only wires the route, shared infrastructure, and reviewable skeleton.';
  }

  @override
  String get operationsGroupSelectorTitle => 'Select Group';

  @override
  String get operationsGroupCreateTitle => 'Create Group';

  @override
  String get operationsGroupRenameTitle => 'Rename Group';

  @override
  String get operationsGroupNameHint => 'Enter a group name';

  @override
  String get operationsGroupEmptyDescription =>
      'No groups are available for this module yet. Create one to keep items organized.';

  @override
  String get operationsGroupDefaultLabel => 'Default';

  @override
  String get operationsGroupDeleteConfirmTitle => 'Delete Group';

  @override
  String operationsGroupDeleteConfirmMessage(String groupName) {
    return 'Delete group $groupName? Existing module items will need a new group assignment later.';
  }
}
