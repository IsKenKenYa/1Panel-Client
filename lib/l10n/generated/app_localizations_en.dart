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
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

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
  String get websitesSetDefaultAction => 'Set Default';

  @override
  String get websitesDefaultServerLabel => 'Default server';

  @override
  String get websitesGroupLabel => 'Group';

  @override
  String get websitesRemarkLabel => 'Remark';

  @override
  String get websitesAliasLabel => 'Alias';

  @override
  String get websitesPrimaryDomainLabel => 'Primary domain';

  @override
  String get websitesProxyAddressLabel => 'Proxy address';

  @override
  String get websitesProxyTypeLabel => 'Proxy type';

  @override
  String get websitesParentWebsiteLabel => 'Parent website';

  @override
  String get websitesSiteDirLabel => 'Site directory';

  @override
  String get websitesFilterAllGroups => 'All groups';

  @override
  String get websitesFilterAllTypes => 'All types';

  @override
  String get websitesSelectionEnable => 'Select';

  @override
  String get websitesSelectionDisable => 'Cancel selection';

  @override
  String get websitesSetGroupAction => 'Set Group';

  @override
  String get websitesLifecycleCreateTitle => 'Create Website';

  @override
  String get websitesLifecycleEditTitle => 'Edit Website';

  @override
  String get websitesLifecycleTypeLabel => 'Website type';

  @override
  String get websitesLifecycleTypeRuntime => 'Runtime';

  @override
  String get websitesLifecycleTypeProxy => 'Proxy';

  @override
  String get websitesLifecycleTypeSubsite => 'Subsite';

  @override
  String get websitesLifecycleTypeStatic => 'Static';

  @override
  String get websitesValidationGroupRequired => 'Select a website group.';

  @override
  String get websitesValidationPrimaryDomainRequired =>
      'Primary domain is required.';

  @override
  String get websitesValidationAliasRequired => 'Alias is required.';

  @override
  String get websitesValidationRuntimeRequired => 'Select a runtime.';

  @override
  String get websitesValidationProxyRequired => 'Proxy address is required.';

  @override
  String get websitesValidationParentRequired => 'Select a parent website.';

  @override
  String get websitesOperateSuccess => 'Operation successful';

  @override
  String get websitesOperateFailed => 'Operation failed';

  @override
  String websitesSelectedCount(int count) {
    return '$count selected';
  }

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
  String websitesBatchDeleteMessage(int count) {
    return 'Delete $count websites? This action cannot be undone.';
  }

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
  String get websitesDomainEditTitle => 'Edit domain';

  @override
  String get websitesDomainLabel => 'Domain';

  @override
  String get websitesDomainEmpty => 'No domains';

  @override
  String get websitesDomainDefault => 'Default';

  @override
  String get websitesDomainSslLabel => 'SSL';

  @override
  String get websitesDomainValidationRequired => 'Domain is required.';

  @override
  String get websitesDomainValidationPort =>
      'Port must be between 1 and 65535.';

  @override
  String get websitesDomainValidationDuplicate => 'This domain already exists.';

  @override
  String get websitesDomainBatchAddTitle => 'Batch add domains';

  @override
  String get websitesDomainBatchAddAction => 'Import domains';

  @override
  String get websitesDomainBatchAddHint =>
      'One domain per line. You can use domain or domain:port.';

  @override
  String get websitesDomainBatchInputLabel => 'Domains';

  @override
  String get websitesDomainBatchValidationEmpty => 'Enter at least one domain.';

  @override
  String websitesDomainBatchValidationInvalid(String line) {
    return 'Invalid domain line: $line';
  }

  @override
  String websitesDomainDeleteMessage(String domain) {
    return 'Delete domain $domain?';
  }

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
  String get websitesBasicConfigTitle => 'Basic';

  @override
  String get websitesBasicConfigDatabaseTitle => 'Database binding';

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
  String get websitesSslExpirationViewTitle => 'Expiration view';

  @override
  String websitesSslFilterAllCount(int count) {
    return 'All ($count)';
  }

  @override
  String websitesSslFilterExpiredCount(int count) {
    return 'Expired ($count)';
  }

  @override
  String websitesSslFilterWithin7DaysCount(int count) {
    return 'Within 7 days ($count)';
  }

  @override
  String websitesSslFilterWithin30DaysCount(int count) {
    return 'Within 30 days ($count)';
  }

  @override
  String websitesSslAffectedWebsitesCount(int count) {
    return 'Affected websites: $count';
  }

  @override
  String websitesSslAffectedWebsitesDomains(String domains) {
    return 'Affected domains: $domains';
  }

  @override
  String get websitesSslImpactHintApply =>
      'Apply this certificate to bound websites now?';

  @override
  String get websitesSslImpactWarningHigh =>
      'This action affects multiple websites. Confirm maintenance window first.';

  @override
  String get websitesSslNoAffectedWebsites => 'No bound websites.';

  @override
  String get websitesSslOpenBoundSiteAction => 'Open bound site';

  @override
  String get websitesSslGroupAll => 'All certificates';

  @override
  String get websitesSslGroupExpired => 'Expired';

  @override
  String get websitesSslGroupWithin7Days => 'Within 7 days';

  @override
  String get websitesSslGroupWithin30Days => 'Within 30 days';

  @override
  String get websitesSslGroupHealthy => 'Healthy';

  @override
  String get websitesSslProviderFilterAll => 'All providers';

  @override
  String get websitesSslHealthHealthy => 'Healthy';

  @override
  String get websitesSslHealthExpiringSoon => 'Expiring soon';

  @override
  String get websitesSslHealthExpired => 'Expired';

  @override
  String get websitesSslHealthUnknown => 'Unknown';

  @override
  String get websitesSslAccountsCaTab => 'CA';

  @override
  String get websitesSslAccountsAcmeTab => 'ACME';

  @override
  String get websitesSslAccountsDnsTab => 'DNS';

  @override
  String get websitesSslAccountsEmpty => 'No accounts';

  @override
  String get websitesSslAccountsCreateCaAction => 'Create CA';

  @override
  String get websitesSslAccountsCreateAcmeAction => 'Create ACME account';

  @override
  String get websitesSslAccountsEditAcmeAction => 'Edit ACME account';

  @override
  String get websitesSslAccountsCreateDnsAction => 'Create DNS account';

  @override
  String get websitesSslAccountsEditDnsAction => 'Edit DNS account';

  @override
  String get websitesSslAccountsObtainAction => 'Obtain certificate';

  @override
  String get websitesSslAccountsRenewAction => 'Renew certificate';

  @override
  String get websitesSslAccountsDownloadAction => 'Download CA file';

  @override
  String get websitesSslAccountsTypeLabel => 'Type';

  @override
  String get websitesSslAccountsAuthorizationLabel => 'Authorization JSON';

  @override
  String get websitesSslAccountsEmailLabel => 'Email';

  @override
  String get websitesSslAccountsKeyTypeLabel => 'Key type';

  @override
  String get websitesSslAccountsUseProxyLabel => 'Use proxy';

  @override
  String get websitesSslAccountsCommonNameLabel => 'Common name';

  @override
  String get websitesSslAccountsCountryLabel => 'Country';

  @override
  String get websitesSslAccountsOrganizationLabel => 'Organization';

  @override
  String get websitesSslAccountsOrganizationUnitLabel => 'Organization unit';

  @override
  String get websitesSslAccountsProvinceLabel => 'Province';

  @override
  String get websitesSslAccountsCityLabel => 'City';

  @override
  String get websitesSslAccountsDomainsLabel => 'Domains (comma-separated)';

  @override
  String get websitesSslAccountsTimeLabel => 'Validity period';

  @override
  String get websitesSslAccountsUnitLabel => 'Unit';

  @override
  String get websitesSslAccountsValidationNameRequired => 'Name is required.';

  @override
  String get websitesSslAccountsValidationTypeRequired => 'Type is required.';

  @override
  String get websitesSslAccountsValidationEmailRequired => 'Email is required.';

  @override
  String get websitesSslAccountsValidationAuthorizationRequired =>
      'Authorization is required.';

  @override
  String get websitesSslAccountsValidationAuthorizationInvalid =>
      'Authorization must be a valid JSON object.';

  @override
  String get websitesSslAccountsValidationRequiredFields =>
      'Please complete all required fields.';

  @override
  String get websitesSslAccountsValidationDomainsRequired =>
      'Domains are required.';

  @override
  String get websitesSslAccountsValidationTimeInvalid =>
      'Validity period must be greater than 0.';

  @override
  String get websitesSslAccountsMissingId => 'Missing account ID.';

  @override
  String get websitesSslAccountsMissingSslId => 'Missing SSL ID for renew.';

  @override
  String get websitesSslAccountsRenewConfirmMessage =>
      'Renew this certificate now?';

  @override
  String get websitesSslAccountsDownloadSuccess =>
      'CA download request submitted.';

  @override
  String websitesSslAccountsDeleteDnsMessage(String name) {
    return 'Delete DNS account $name?';
  }

  @override
  String websitesSslAccountsDeleteAcmeMessage(String email) {
    return 'Delete ACME account $email?';
  }

  @override
  String websitesSslAccountsDeleteCaMessage(String name) {
    return 'Delete CA $name?';
  }

  @override
  String get openrestyPageTitle => 'OpenResty';

  @override
  String get openrestyNotInstalledTitle => 'OpenResty Not Installed';

  @override
  String get openrestyNotInstalledDescription =>
      'OpenResty is not installed or not ready. Install OpenResty from the App Store before managing websites.';

  @override
  String get openrestyGoStore => 'Go to App Store';

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
  String get openrestyAdvancedSourceEditorTooltip => 'Advanced source editor';

  @override
  String get openrestyRiskBannerTitle => 'Gateway risk banner';

  @override
  String get openrestyRunningStatusLabel => 'Running Status';

  @override
  String get openrestyBuildVersionLabel => 'Build / Version';

  @override
  String get openrestyCoreSummaryLabel => 'Core Summary';

  @override
  String get openrestyHttpsSummaryLabel => 'HTTPS Summary';

  @override
  String get openrestyModulesSummaryLabel => 'Modules Summary';

  @override
  String get openrestyCurrentStateLabel => 'Current State';

  @override
  String get openrestyRejectHandshakeLabel => 'Reject Handshake';

  @override
  String get openrestyEditHttpsAction => 'Edit HTTPS';

  @override
  String get openrestyPreviewDiffAction => 'Preview diff';

  @override
  String get openrestyRollbackAction => 'Rollback';

  @override
  String get openrestyHttpsDiffPreviewTitle => 'HTTPS diff preview';

  @override
  String get openrestyUnnamedModule => 'Unnamed module';

  @override
  String get openrestyNoModulesReturned =>
      'No modules returned by the gateway.';

  @override
  String get openrestyModuleDiffPreviewTitle => 'Module diff preview';

  @override
  String get openrestyCurrentConfigLabel => 'Current Config';

  @override
  String get openrestyAdvancedAction => 'Advanced';

  @override
  String get openrestyConfigDiffPreviewTitle => 'Config diff preview';

  @override
  String get openrestyBuildLastResultLabel => 'Last Result';

  @override
  String get openrestyBuildNoRecentAction => 'No recent build action';

  @override
  String get openrestyBuildStartAction => 'Start build';

  @override
  String get openrestyStatusNotRunningSummary => 'Not running';

  @override
  String openrestyStatusRunningSummary(int active) {
    return 'Running · active $active';
  }

  @override
  String get openrestyHttpsEnabledSummary => 'HTTPS enabled';

  @override
  String get openrestyHttpsDisabledSummary => 'HTTPS disabled';

  @override
  String openrestyModulesEnabledSummary(int enabled, int total) {
    return '$enabled/$total modules enabled';
  }

  @override
  String get openrestyBuildNoMirrorConfigured => 'No mirror configured';

  @override
  String get openrestyConfigNotLoaded => 'Config not loaded';

  @override
  String openrestyConfigLoadedSummary(int lines) {
    return '$lines lines loaded';
  }

  @override
  String get openrestyDialogUpdateHttpsTitle => 'Update HTTPS';

  @override
  String get openrestyDialogEnableHttpsLabel => 'Enable HTTPS';

  @override
  String get openrestyDialogRejectInvalidHandshakesLabel =>
      'Reject invalid handshakes';

  @override
  String get openrestyDialogModuleTitleFallback => 'Module';

  @override
  String get openrestyDialogEnableModuleLabel => 'Enable module';

  @override
  String get openrestyDialogPackagesLabel => 'Packages';

  @override
  String get openrestyDialogParamsLabel => 'Params';

  @override
  String get openrestyDialogScriptLabel => 'Script';

  @override
  String get openrestyDialogPreviewConfigTitle => 'Preview config change';

  @override
  String get openrestyDialogConfigSourceLabel => 'Config source';

  @override
  String get openrestyDialogStartBuildTitle => 'Start OpenResty build';

  @override
  String get openrestyDialogBuildRiskHint =>
      'Build can refresh gateway binaries and module packages. Confirm before running on production nodes.';

  @override
  String get openrestyBuildSubmittedMessage => 'Build submitted';

  @override
  String openrestyBuildSubmittedWithMirrorMessage(String mirror) {
    return 'Build submitted with mirror $mirror.';
  }

  @override
  String get openrestyRiskGatewayInactiveTitle => 'Gateway inactive';

  @override
  String get openrestyRiskGatewayInactiveMessage =>
      'OpenResty is not reporting active connections.';

  @override
  String get openrestyRiskHttpsDisabledTitle => 'HTTPS disabled';

  @override
  String get openrestyRiskHttpsDisabledMessage =>
      'Disabling HTTPS reduces the default gateway security baseline.';

  @override
  String get openrestyRiskNoModulesTitle => 'No modules loaded';

  @override
  String get openrestyRiskNoModulesMessage =>
      'OpenResty modules are empty. Review build and module config.';

  @override
  String get openrestyRiskBuildMirrorMissingTitle => 'Build mirror missing';

  @override
  String get openrestyRiskBuildMirrorMissingMessage =>
      'No build mirror is configured. Build speed may be affected.';

  @override
  String get openrestyRiskRejectHandshakeTitle => 'Reject handshake enabled';

  @override
  String get openrestyRiskRejectHandshakeMessage =>
      'This may block clients with invalid TLS negotiation settings.';

  @override
  String get openrestyRiskModuleDisabledTitle => 'Module disabled';

  @override
  String openrestyRiskModuleDisabledMessage(String module) {
    return 'Disabling $module may change gateway behavior immediately.';
  }

  @override
  String get openrestyRiskDependencyChangeTitle => 'Dependency change';

  @override
  String openrestyRiskDependencyChangeMessage(String module) {
    return 'Package or script changes can introduce dependency conflicts for $module.';
  }

  @override
  String get openrestyRiskEmptyConfigTitle => 'Empty config';

  @override
  String get openrestyRiskEmptyConfigMessage =>
      'Saving an empty config will break the current gateway setup.';

  @override
  String get openrestyRiskBraceMismatchTitle => 'Brace mismatch';

  @override
  String get openrestyRiskBraceMismatchMessage =>
      'The config appears to have unmatched braces. Validate before saving.';

  @override
  String get openrestyRiskMissingHttpBlockTitle => 'Missing http block';

  @override
  String get openrestyRiskMissingHttpBlockMessage =>
      'No http block was detected in the config source.';

  @override
  String get openrestyRiskTemporaryMarkersTitle => 'Temporary markers found';

  @override
  String get openrestyRiskTemporaryMarkersMessage =>
      'The config still contains TODO or FIXME markers.';

  @override
  String get openrestyDiffLabelHttps => 'HTTPS';

  @override
  String get openrestyDiffLabelRejectHandshake => 'Reject Handshake';

  @override
  String get openrestyDiffLabelEnabled => 'Enabled';

  @override
  String get openrestyDiffLabelPackages => 'Packages';

  @override
  String get openrestyDiffLabelParams => 'Params';

  @override
  String get openrestyDiffLabelScript => 'Script';

  @override
  String get openrestyDiffLabelConfigSource => 'Config Source';

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
  String get hostNavScriptLibrary => 'Script Library';

  @override
  String get hostNavDatabases => 'Databases';

  @override
  String get hostNavCronJobs => 'CronJobs';

  @override
  String get hostNavBackups => 'Backups';

  @override
  String get hostNavHost => 'Host';

  @override
  String get hostNavCommands => 'Commands';

  @override
  String get hostNavLogs => 'Logs';

  @override
  String get hostNavGateway => 'Gateway';

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
  String get serverModuleAi => 'AI';

  @override
  String get aiTabModels => 'Models';

  @override
  String get aiTabGpu => 'GPU';

  @override
  String get aiTabDomain => 'Domain';

  @override
  String get aiModelCreate => 'Create Model';

  @override
  String get aiModelSync => 'Sync Models';

  @override
  String get aiModelRecreate => 'Recreate Model';

  @override
  String get aiModelNameLabel => 'Model Name';

  @override
  String get aiTaskIdOptional => 'Task ID (optional)';

  @override
  String get aiModelNameRequired => 'Model name is required';

  @override
  String get aiForceDelete => 'Force Delete';

  @override
  String get aiOperationSuccess => 'Operation successful';

  @override
  String aiOperationFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get aiOperationResult => 'Operation Result';

  @override
  String get aiNoGpuData => 'No GPU data available';

  @override
  String get aiFanSpeed => 'Fan Speed';

  @override
  String get aiPowerUsage => 'Power';

  @override
  String get aiPerformanceState => 'Performance State';

  @override
  String get aiDomainHint =>
      'Configure Ollama domain binding. Enter the appInstallID first, then load or submit binding.';

  @override
  String get aiAppInstallIdLabel => 'App Install ID';

  @override
  String get aiAppInstallIdRequired => 'App Install ID is required';

  @override
  String get aiIpAllowListLabel => 'Allow IP List';

  @override
  String get aiSslIdOptionalLabel => 'SSL ID (optional)';

  @override
  String get aiWebsiteIdOptionalLabel => 'Website ID (optional)';

  @override
  String get aiLoadBinding => 'Load Current Binding';

  @override
  String get aiBindDomain => 'Bind Domain';

  @override
  String get aiCurrentBinding => 'Current Binding';

  @override
  String get aiConnUrl => 'Connection URL';

  @override
  String get containerSystemProtectedNetwork =>
      'System network cannot be deleted';

  @override
  String get serverModuleDatabases => 'Databases';

  @override
  String get serverModuleFirewall => 'Firewall';

  @override
  String get databaseMysqlTab => 'MySQL';

  @override
  String get databasePostgresqlTab => 'PostgreSQL';

  @override
  String get databaseRedisTab => 'Redis';

  @override
  String get databaseRemoteTab => 'Remote';

  @override
  String get databaseMongodbTab => 'MongoDB';

  @override
  String get databaseOverviewTitle => 'Overview';

  @override
  String get databaseConfigTitle => 'Config File';

  @override
  String get databaseBaseInfoTitle => 'Base Info';

  @override
  String get databaseStatusTitle => 'Status';

  @override
  String get databaseVariablesTitle => 'Variables';

  @override
  String get databaseScopeLabel => 'Database Scope';

  @override
  String get databaseFormBasicSectionTitle => 'Basic Configuration';

  @override
  String get databaseFormAdvancedSectionTitle => 'Advanced Settings';

  @override
  String get databaseEngineLabel => 'Engine';

  @override
  String get databaseSourceLabel => 'Source';

  @override
  String get databaseAddressLabel => 'Address';

  @override
  String get databasePortLabel => 'Port';

  @override
  String get databaseContainerLabel => 'Container';

  @override
  String get databaseUsernameLabel => 'Username';

  @override
  String get databasePasswordLabel => 'Password';

  @override
  String get databaseRemoteAccessLabel => 'Remote Access';

  @override
  String get databaseChangePasswordAction => 'Change Password';

  @override
  String get databaseBindUserAction => 'Bind User';

  @override
  String get databaseTestConnectionAction => 'Test Connection';

  @override
  String get databaseRedisConfigTitle => 'Redis Config';

  @override
  String get databaseRedisTimeoutLabel => 'Timeout';

  @override
  String get databaseRedisMaxClientsLabel => 'Max Clients';

  @override
  String get databaseRedisPersistenceTitle => 'Redis Persistence';

  @override
  String get databaseRedisAppendOnlyLabel => 'Append Only';

  @override
  String get databaseRedisSaveLabel => 'Save Policy';

  @override
  String get databaseManageTitle => 'Manage';

  @override
  String get databaseBackupsPageTitle => 'Backups';

  @override
  String get databaseUsersPageTitle => 'Users';

  @override
  String get databaseBackupCreateAction => 'Create Backup';

  @override
  String get databaseBackupRestoreAction => 'Restore Backup';

  @override
  String get databaseBackupDeleteAction => 'Delete Backup';

  @override
  String get databaseBackupSecretLabel => 'Compression Password';

  @override
  String get databaseBackupEmpty => 'No backup records yet.';

  @override
  String get databaseBackupUnsupported =>
      'Backups are not supported for this database type.';

  @override
  String get databaseBackupRestoreConfirmMessage =>
      'Restore this backup record? Existing data may be overwritten.';

  @override
  String get databaseBackupDeleteConfirmMessage =>
      'Delete this backup record? This action cannot be undone.';

  @override
  String get databaseUserCurrentLabel => 'Current User';

  @override
  String get databaseUserPermissionLabel => 'Permission';

  @override
  String get databaseUserSuperUserLabel => 'Superuser';

  @override
  String get databaseUserBindAction => 'Bind User';

  @override
  String get databaseUserPrivilegesAction => 'Update Privileges';

  @override
  String get databaseUserNoBinding =>
      'No bound user information is available yet.';

  @override
  String get databaseUserUnsupported =>
      'User management is not supported for this database type.';

  @override
  String get databasePrivilegeUnavailable =>
      'Privileges can be adjusted after a user is bound.';

  @override
  String get databaseTargetInstance => 'Target Instance';

  @override
  String get databaseTargetInstanceRequired =>
      'Please select a target instance';

  @override
  String get databasePermission => 'Permission';

  @override
  String get databaseCharsetLabel => 'Charset';

  @override
  String get databaseFormatLabel => 'Format';

  @override
  String get databaseDbLabel => 'DB';

  @override
  String get firewallTabStatus => 'Status';

  @override
  String get firewallTabRules => 'Rules';

  @override
  String get firewallTabIps => 'IPs';

  @override
  String get firewallTabPorts => 'Ports';

  @override
  String get firewallNameLabel => 'Name';

  @override
  String get firewallVersionLabel => 'Version';

  @override
  String get firewallPingLabel => 'Ping';

  @override
  String get firewallActiveLabel => 'Active';

  @override
  String get firewallInitLabel => 'Initialized';

  @override
  String get firewallBoundLabel => 'Bound';

  @override
  String get firewallProtocolLabel => 'Protocol';

  @override
  String get firewallAddressLabel => 'Address';

  @override
  String get firewallStrategyLabel => 'Strategy';

  @override
  String get firewallPortLabel => 'Port';

  @override
  String get firewallFamilyLabel => 'Family';

  @override
  String get firewallSourcePortLabel => 'Source Port';

  @override
  String get firewallDestinationPortLabel => 'Destination Port';

  @override
  String get firewallRuleDefaultTitle => 'Rule';

  @override
  String get firewallUnknownStrategy => 'Unknown';

  @override
  String get firewallSourceLabel => 'Source';

  @override
  String get firewallSourceAnywhere => 'Anywhere';

  @override
  String get firewallSourceAddress => 'Address';

  @override
  String get firewallStrategyAccept => 'Accept';

  @override
  String get firewallStrategyDrop => 'Drop';

  @override
  String get firewallStrategyAll => 'All';

  @override
  String get firewallSearchHint => 'Search by description, address, or port';

  @override
  String get firewallRulesEmptyTitle => 'No rules yet';

  @override
  String get firewallRulesEmptyHint =>
      'Tap Add in the top toolbar to create a port or IP rule.';

  @override
  String get firewallIpsEmptyTitle => 'No IP rules yet';

  @override
  String get firewallIpsEmptyHint =>
      'Tap Add in the top toolbar to block an IP address.';

  @override
  String get firewallPortsEmptyTitle => 'No port rules yet';

  @override
  String get firewallPortsEmptyHint =>
      'Tap Add in the top toolbar to open a port.';

  @override
  String get firewallSelectionModeEnable => 'Select';

  @override
  String get firewallSelectionModeDisable => 'Done';

  @override
  String get firewallBatchDeleteAction => 'Batch Delete';

  @override
  String get firewallBatchAcceptAction => 'Batch Accept';

  @override
  String get firewallBatchDropAction => 'Batch Drop';

  @override
  String firewallSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get firewallCreatePortRuleAction => 'Create Port Rule';

  @override
  String get firewallCreateIpRuleAction => 'Create IP Rule';

  @override
  String get firewallRuleSectionTitle => 'Rule Configuration';

  @override
  String get firewallToggleStrategyAction => 'Toggle Strategy';

  @override
  String get firewallOperationConfirmTitle => 'Confirm firewall change';

  @override
  String get firewallStartConfirmMessage =>
      'Start the firewall service? New rules will begin taking effect immediately.';

  @override
  String get firewallStopConfirmMessage =>
      'Stop the firewall service? This may expose services without packet filtering.';

  @override
  String get firewallRestartConfirmMessage =>
      'Restart the firewall service? Existing connections may be interrupted briefly.';

  @override
  String get firewallAddressRequired => 'Address is required.';

  @override
  String get firewallPortRequired => 'Port is required.';

  @override
  String get firewallChainLabel => 'Chain';

  @override
  String get firewallBindAction => 'Bind';

  @override
  String get firewallUnbindAction => 'Unbind';

  @override
  String get firewallForwardStrategyToggleError =>
      'Forward rules do not support strategy toggling.';

  @override
  String get firewallTargetIPLabel => 'Target IP';

  @override
  String get firewallTargetPortLabel => 'Target Port';

  @override
  String get firewallInterfaceLabel => 'Interface';

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
  String get serverFormBasicSectionTitle => 'Basic Configuration';

  @override
  String get serverFormConnectionSectionTitle => 'Connection';

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
  String get serverDeleteConfirmTitle => 'Delete server';

  @override
  String serverDeleteConfirmMessage(String name) {
    return 'Delete server $name?';
  }

  @override
  String serverDeleteSuccess(String name) {
    return 'Deleted server $name';
  }

  @override
  String serverDeleteFailed(String error) {
    return 'Failed to delete server: $error';
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
  String get serverFormAllowInsecureTls => 'Ignore TLS certificate validation';

  @override
  String get serverFormAllowInsecureTlsHint =>
      'Only enable for trusted self-signed or internal endpoints.';

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
  String filesSelectedCount(int count) {
    return '$count selected';
  }

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
  String get settingsAppSectionTitle => 'App';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageHint =>
      'Language updates apply immediately. If not specified, the app follows system settings.';

  @override
  String get settingsUIRenderMode => 'UI Render Mode';

  @override
  String get settingsUIRenderModeNative => 'Native';

  @override
  String get settingsUIRenderModeMD3 => 'MDUI3';

  @override
  String get settingsUIRenderModeRestartHint =>
      'Please restart the app for the UI render mode changes to take effect.';

  @override
  String get settingsUIRenderModeHostMissing =>
      'Native host missing. Build: dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug';

  @override
  String get settingsUIRenderModeHostMissingStatus =>
      'Native host not ready (OnePanelNativeHost.exe missing) — this session fell back to MDUI3.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAppLock => 'App Lock';

  @override
  String get settingsAppLockDesc =>
      'Use biometric/device credentials to protect sensitive modules';

  @override
  String get settingsServerManagement => 'Server management';

  @override
  String get settingsServerManagementSubtitle =>
      'Manage multiple connected servers. Server system settings are only available from each server detail page.';

  @override
  String get settingsResetOnboarding => 'Replay welcome guide';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsFeedbackCenterTitle => 'Feedback Center';

  @override
  String get settingsFeedbackCenterSubtitle =>
      'Manage logs and submit product feedback';

  @override
  String get settingsFeedbackCenterIntro =>
      'Before submitting an issue, export logs and include repro steps to speed up triage.';

  @override
  String get settingsFeedbackGuideTitle => 'Feedback Checklist';

  @override
  String get settingsFeedbackGuideStep1 =>
      'Confirm the issue is reproducible and capture the key operation path.';

  @override
  String get settingsFeedbackGuideStep2 =>
      'Export app logs and include the timestamp and release channel.';

  @override
  String get settingsFeedbackGuideStep3 =>
      'Describe the difference between expected and actual behavior.';

  @override
  String get settingsFeedbackIssueSubtitle =>
      'Report bugs or suggestions in GitHub Issues';

  @override
  String get settingsFeedbackCopyTemplate => 'Copy feedback template';

  @override
  String get settingsFeedbackTemplateHint =>
      'Copy a structured template and fill it in directly';

  @override
  String get settingsFeedbackLogsTitle => 'Log Management';

  @override
  String get settingsFeedbackLogExportWarningTitle =>
      'Export Logs & Testing Advice';

  @override
  String get settingsFeedbackLogExportWarningMessage =>
      'This is a Dev release for public testing and feedback collection. We recommend using a private IP (e.g., an internal 1Panel server or VM) for testing to avoid unexpected impacts.\n\nPublic IP addresses in the logs are automatically masked. However, please do not share logs with unrelated personnel, and manually check for any remaining sensitive information before reporting issues.';

  @override
  String get settingsFeedbackLogExportConfirm => 'Export';

  @override
  String get settingsFeedbackTemplateTitle => 'Issue Summary';

  @override
  String get settingsFeedbackTemplateSummary => 'What happened';

  @override
  String get settingsFeedbackTemplateRepro => 'Steps to reproduce';

  @override
  String get settingsFeedbackTemplateExpected => 'Expected behavior';

  @override
  String get settingsFeedbackTemplateActual => 'Actual behavior';

  @override
  String get settingsFeedbackTemplateLogs => 'Logs and screenshots';

  @override
  String get settingsFeedbackTemplateEnvironment => 'Environment';

  @override
  String get settingsLegalCenterTitle => 'Legal';

  @override
  String get settingsLegalCenterSubtitle =>
      'Privacy, terms, and open-source notices';

  @override
  String get settingsLegalCenterIntro =>
      'These documents describe data handling, service terms, and open-source dependency notices.';

  @override
  String get settingsLegalDocumentsTitle => 'Legal Documents';

  @override
  String get settingsLegalPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsLegalTermsOfService => 'Terms of Service';

  @override
  String get settingsLegalThirdPartyNotices => 'Third-party License Notices';

  @override
  String get settingsLegalOpenSourceLicense =>
      'Project Open-source License (GPL-3.0)';

  @override
  String get settingsLegalFlutterPackages => 'Flutter Package Licenses';

  @override
  String get settingsMainlandSdkDisclosureTitle =>
      'Mainland China SDK Disclosure';

  @override
  String get settingsMainlandSdkDisclosureSubtitle =>
      'View integrated dependencies and regional notes';

  @override
  String get settingsMainlandSdkDisclaimer =>
      'This page shows auto-scanned integrated dependencies and reserved regional compliance notes.';

  @override
  String get settingsMainlandSdkNone =>
      'No proprietary SDK dedicated to Mainland China is currently integrated. If introduced, it will be disclosed here.';

  @override
  String get settingsMainlandSdkAutoScanTitle => 'Auto-scanned Dependency List';

  @override
  String get settingsMainlandSdkAutoScanEmpty =>
      'No dependency data found. Tap refresh and try again.';

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
  String get releaseChannelPreview => 'Dev';

  @override
  String get releaseChannelAlpha => 'Dev (Alpha)';

  @override
  String get releaseChannelBeta => 'Beta';

  @override
  String get releaseChannelPreRelease => 'Pre-Release';

  @override
  String get releaseChannelRelease => 'Release';

  @override
  String testingWarningDialogTitle(String channel) {
    return '$channel warning';
  }

  @override
  String get testingWarningDialogBody =>
      'This build is for testing and feedback collection. Continue only if you understand the risks.';

  @override
  String get testingWarningRiskUnstable =>
      'This version may be unstable and features can change at any time.';

  @override
  String get testingWarningRiskDataLoss =>
      'Data loss or configuration issues may occur during testing. Please back up first.';

  @override
  String get testingWarningRiskNoProd =>
      'Do not use test builds on production servers.';

  @override
  String get testingWarningConsentText =>
      'I understand these risks and agree to continue using the test build.';

  @override
  String get testingWarningExit => 'Exit app';

  @override
  String get testingWarningContinue => 'Continue';

  @override
  String get testingWarningAgreeAndContinue => 'Agree and continue';

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
  String get aboutPackageNameLabel => 'Package name';

  @override
  String get aboutChannelLabel => 'Channel';

  @override
  String get aboutBranchLabel => 'Source branch';

  @override
  String get aboutCommitLabel => 'Commit';

  @override
  String get aboutBuildDateLabel => 'Build date';

  @override
  String get aboutOfficialDomainLabel => 'Official domain';

  @override
  String get aboutProjectSectionTitle => 'Project';

  @override
  String get aboutProjectSummary =>
      '1Panel Client is a mobile app for managing 1Panel servers across multiple environments.';

  @override
  String get aboutProjectFeatureList =>
      'Core capabilities: multi-server management, file and website operations, terminal access, and status monitoring.';

  @override
  String get aboutFeedbackAction => 'Open GitHub Issues';

  @override
  String get aboutFeedbackHint =>
      'Report bugs, usability issues, and suggestions in the official issue tracker.';

  @override
  String get aboutReleaseNotesSectionTitle => 'Release notes';

  @override
  String get aboutReleaseNotesBody =>
      'See latest updates and changes in the releases page.';

  @override
  String get aboutRepositorySectionTitle => 'Repository';

  @override
  String get aboutLinkOpenAction => 'Open link';

  @override
  String get aboutRepositoryOpenAction => 'Open repository';

  @override
  String get aboutRepositoryHttpsLabel => 'HTTPS';

  @override
  String get aboutRepositorySshLabel => 'SSH';

  @override
  String get aboutReleaseAction => 'View Releases';

  @override
  String get aboutLinkOpenFailed => 'Could not open the link.';

  @override
  String get aboutExperimentalModulesTitle => 'Modules';

  @override
  String get aboutExperimentalModulesDescription =>
      'Server, websites, containers, databases, firewall, terminal, and monitoring.';

  @override
  String get aboutExperimentalModulesList =>
      'Server · Websites · Containers · Databases · Firewall · Terminal · Monitoring';

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
  String dashboardUptimeMinutes(int minutes) {
    return '${minutes}m';
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
  String get authPasskeyLogin => 'Login with Passkey';

  @override
  String get authPasskeyUnsupported => 'Passkey unavailable';

  @override
  String get authDemoMode => 'Demo mode: Some features are limited';

  @override
  String get authLoginFailed => 'Login failed';

  @override
  String get authLogoutSuccess => 'Logged out successfully';

  @override
  String get appLockTitle => 'App Lock';

  @override
  String get appLockDeviceAuthStatus => 'Device authentication';

  @override
  String get appLockDeviceAuthSupported =>
      'Biometric or device credential is available on this device';

  @override
  String get appLockDeviceAuthUnsupported =>
      'Current device does not support local authentication';

  @override
  String get appLockEnable => 'Enable app lock';

  @override
  String get appLockEnableDesc =>
      'Prompt for local authentication before opening protected content';

  @override
  String get appLockLockOnAppOpen => 'Require unlock on app open';

  @override
  String get appLockLockOnAppOpenDesc =>
      'Verify identity before entering the app';

  @override
  String get appLockLockOnProtectedModule =>
      'Require unlock for protected modules';

  @override
  String get appLockLockOnProtectedModuleDesc =>
      'Only selected modules will require another verification';

  @override
  String get appLockRelockAfterMinutes => 'Relock after background time';

  @override
  String appLockRelockAfterMinutesOption(int minutes) {
    return '$minutes min';
  }

  @override
  String get appLockProtectedModules => 'Protected modules';

  @override
  String get appLockSelectAll => 'Select all';

  @override
  String get appLockClearAll => 'Clear';

  @override
  String get appLockNoProtectedModules =>
      'Module protection is currently disabled.';

  @override
  String get appLockAuthFailed => 'Authentication failed';

  @override
  String get appLockUnlockReasonEnable =>
      'Verify your identity to enable app lock';

  @override
  String get appLockUnlockReasonAppOpen =>
      'Verify your identity to open 1Panel Client';

  @override
  String appLockUnlockReasonModule(String module) {
    return 'Verify your identity to open $module';
  }

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
  String get systemSettingsFileExportSection => 'File Export & Download';

  @override
  String get systemSettingsFileExportUsePicker => 'Use file picker when saving';

  @override
  String get systemSettingsFileExportUsePickerDesc =>
      'When off, files save into the default download directory (grouped by subfolder)';

  @override
  String get systemSettingsFileExportSubDirTitle => 'Default sub-folder name';

  @override
  String get systemSettingsFileExportSubDirHelper =>
      'Used when the picker is off. Leave empty to skip the parent folder. Default: 1Panel-Client';

  @override
  String fileSaveSuccessPicker(String displayName) {
    return 'Saved to $displayName Downloads';
  }

  @override
  String get fileSaveSuccessDownloads => 'Saved to Downloads';

  @override
  String get fileSaveCancelled => 'Save cancelled';

  @override
  String get fileSavePrivateFallback =>
      'File picker unavailable, saved to the app private directory';

  @override
  String get filePickerUnavailable => 'File picker unavailable';

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
  String get systemSettingsDashboardMemo => 'Dashboard Memo';

  @override
  String get systemSettingsDashboardMemoHint =>
      'Write a quick note for your dashboard...';

  @override
  String get systemSettingsAppLogsExportSubtitle =>
      'Export local application debug logs';

  @override
  String get systemSettingsAppLogsPreviewButton => 'Export Preview';

  @override
  String get systemSettingsAppLogsPreviewSubtitle =>
      'View the latest 200 log lines, preview human / AI Agent formats';

  @override
  String get systemSettingsAppLogsPreviewTabHuman => 'Human-readable';

  @override
  String get systemSettingsAppLogsPreviewTabAi => 'AI Agent format';

  @override
  String get systemSettingsAppLogsPreviewSave => 'Save this format';

  @override
  String get systemSettingsAppLogsPreviewEmpty => 'No logs available';

  @override
  String get systemSettingsAppLogsPreviewLoading => 'Loading logs...';

  @override
  String get systemSettingsAppLogsLevelTitle => 'App log level';

  @override
  String get systemSettingsAppLogsLevelLocked =>
      'The current channel locks log level (forced Debug).';

  @override
  String get systemSettingsLogLevelTrace => 'Trace';

  @override
  String get systemSettingsLogLevelDebug => 'Debug';

  @override
  String get systemSettingsLogLevelInfo => 'Info';

  @override
  String get systemSettingsLogLevelWarning => 'Warning';

  @override
  String get systemSettingsLogLevelError => 'Error';

  @override
  String get systemSettingsLogLevelFatal => 'Fatal';

  @override
  String get systemSettingsAppLogsClearSubtitle =>
      'Delete local persisted log files';

  @override
  String get systemSettingsAppLogsClearTitle => 'Clear app logs';

  @override
  String get systemSettingsAppLogsClearConfirm =>
      'Are you sure you want to clear local app logs? This action cannot be undone.';

  @override
  String get systemSettingsAppLogsCleared => 'App logs cleared';

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
  String get systemSettingsBackupAccountTitle => 'Backup Accounts';

  @override
  String get systemSettingsBackupAccountDesc =>
      'Manage backup storage accounts';

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
  String get panelTlsTitle => 'Panel TLS';

  @override
  String get panelTlsOverviewTitle => 'Overview';

  @override
  String get panelTlsCertificateTitle => 'Certificate';

  @override
  String get panelTlsRiskTitle => 'Risk';

  @override
  String get panelTlsHistoryTitle => 'History';

  @override
  String get panelTlsUploadHint =>
      'Uploading a new certificate replaces the current panel TLS bundle immediately.';

  @override
  String get panelTlsIssuerLabel => 'Issuer';

  @override
  String get panelTlsCertificatePathLabel => 'Certificate Path';

  @override
  String get panelTlsKeyPathLabel => 'Key Path';

  @override
  String get panelTlsSerialNumberLabel => 'Serial Number';

  @override
  String get panelTlsLastUpdatedLabel => 'Last Updated';

  @override
  String get panelTlsNoRecentActions => 'No recent local actions yet.';

  @override
  String get panelTlsUploadDialogTitle => 'Upload panel certificate';

  @override
  String get panelTlsCertificatePemLabel => 'Certificate PEM';

  @override
  String get panelTlsPrivateKeyPemLabel => 'Private Key PEM';

  @override
  String get panelTlsApplyUpdateTitle => 'Apply certificate update';

  @override
  String get panelTlsApplyUpdateMessage =>
      'This replaces the current panel TLS certificate and may interrupt active browser sessions until the gateway reload finishes.';

  @override
  String get panelTlsDownloadDialogTitle => 'Download certificate bundle';

  @override
  String get panelTlsDownloadDialogMessage =>
      'Use downloads for backup or external validation only. Handle private keys carefully after export.';

  @override
  String get panelTlsContinueAction => 'Continue';

  @override
  String panelTlsDownloadSuccess(int bytes) {
    return 'Downloaded certificate bundle ($bytes bytes)';
  }

  @override
  String get panelTlsHealthHealthy => 'Healthy';

  @override
  String get panelTlsHealthExpiringSoon => 'Expiring soon';

  @override
  String get panelTlsHealthExpired => 'Expired';

  @override
  String get panelTlsHealthUnknown => 'Unknown';

  @override
  String get panelTlsRiskUnknownTitle => 'Certificate expiry unknown';

  @override
  String get panelTlsRiskUnknownMessage =>
      'The panel certificate expiration time could not be parsed.';

  @override
  String get panelTlsRiskExpiredTitle => 'Certificate expired';

  @override
  String get panelTlsRiskExpiredMessage =>
      'The panel TLS certificate has already expired and should be replaced immediately.';

  @override
  String get panelTlsRiskExpiringSoonTitle => 'Certificate expiring soon';

  @override
  String panelTlsRiskExpiringSoonMessage(int days) {
    return 'The panel TLS certificate expires in $days day(s).';
  }

  @override
  String get panelTlsRiskSelfSignedTitle => 'Self-signed certificate';

  @override
  String get panelTlsRiskSelfSignedMessage =>
      'Self-signed certificates can trigger browser trust warnings.';

  @override
  String get panelTlsValidationDomainRequired => 'Domain is required.';

  @override
  String get panelTlsValidationCertificateRequired =>
      'Certificate content is required.';

  @override
  String get panelTlsValidationCertificatePemRequired =>
      'Certificate must contain a PEM certificate block.';

  @override
  String get panelTlsValidationPrivateKeyRequired =>
      'Private key content is required.';

  @override
  String get panelTlsValidationPrivateKeyPemRequired =>
      'Private key must contain a PEM key block.';

  @override
  String panelTlsHistoryLoaded(String domain) {
    return 'Loaded current panel TLS status for $domain';
  }

  @override
  String panelTlsHistoryUploaded(String domain) {
    return 'Uploaded a new panel TLS certificate for $domain';
  }

  @override
  String panelTlsHistoryDownloaded(int bytes) {
    return 'Downloaded panel TLS certificate bundle ($bytes bytes)';
  }

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
  String get terminalSettingsFontFamily => 'Font Family';

  @override
  String get terminalSettingsBackgroundColor => 'Background Color';

  @override
  String get terminalSettingsForegroundColor => 'Foreground Color';

  @override
  String get terminalSettingsDefaultLocalConnection =>
      'Default Local Connection';

  @override
  String get terminalSettingsShowLocalByDefault =>
      'Show local session by default';

  @override
  String get terminalSettingsCurrentConnection => 'Current connection';

  @override
  String get terminalSettingsPreview => 'Preview';

  @override
  String get terminalSettingsFontFamilyHint =>
      'Choose one or more monospaced fonts for terminal rendering.';

  @override
  String get terminalSettingsCursorBlock => 'Block';

  @override
  String get terminalSettingsCursorUnderline => 'Underline';

  @override
  String get terminalSettingsCursorBar => 'Bar';

  @override
  String get terminalSettingsConnectionSetup => 'Connection Setup';

  @override
  String get terminalSettingsTestConnection => 'Test Connection';

  @override
  String get terminalSettingsConnectionAuthMode => 'Authentication';

  @override
  String get terminalSettingsConnectionPassword => 'Password';

  @override
  String get terminalSettingsConnectionPrivateKey => 'Private Key';

  @override
  String get terminalSettingsConnectionPassPhrase => 'Passphrase';

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
  String get securitySettingsPasskeySection => 'Passkey';

  @override
  String get securitySettingsPasskeyRegister => 'Register Passkey';

  @override
  String get securitySettingsPasskeyRegisterDesc =>
      'Create a new passkey on this device';

  @override
  String get securitySettingsPasskeyUnsupported => 'Passkey not supported';

  @override
  String get securitySettingsPasskeyUnsupportedDesc =>
      'Current platform or browser does not support passkey.';

  @override
  String get securitySettingsPasskeyEmpty => 'No passkeys yet';

  @override
  String get securitySettingsPasskeyCreatedAt => 'Created';

  @override
  String get securitySettingsPasskeyLastUsedAt => 'Last used';

  @override
  String get securitySettingsPasskeyName => 'Passkey name';

  @override
  String get securitySettingsPasskeyNameHint => 'e.g. My iPhone or Work Laptop';

  @override
  String get securitySettingsPasskeyDeleteTitle => 'Delete Passkey';

  @override
  String securitySettingsPasskeyDeleteMessage(String name) {
    return 'Delete passkey \"$name\"? This action cannot be undone.';
  }

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
  String get snapshotLoadFailed => 'Failed to load snapshot list';

  @override
  String snapshotLoadFailedWithError(String error) {
    return 'Failed to load snapshot list: $error';
  }

  @override
  String get snapshotBackupAccountLoadFailed =>
      'Failed to load backup accounts';

  @override
  String get snapshotNoBackupAccountHint =>
      'No backup account available. Please add one in Backup Account management first.';

  @override
  String get snapshotBackupAccountLabel => 'Backup Account';

  @override
  String get snapshotCreateErrorTitle => 'Failed to create snapshot';

  @override
  String get snapshotImportErrorTitle => 'Failed to import snapshot';

  @override
  String get snapshotRecoverErrorTitle => 'Failed to recover snapshot';

  @override
  String get snapshotRollbackErrorTitle => 'Failed to rollback snapshot';

  @override
  String get snapshotEditDescErrorTitle => 'Failed to update description';

  @override
  String get snapshotDeleteErrorTitle => 'Failed to delete snapshot';

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
  String get transferBackgroundDownloadUnsupported =>
      'Current platform does not support background downloads yet.';

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
  String get transferOpenDownloadedFileUnsupported =>
      'Current platform does not support opening downloaded files directly.';

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
  String get appsInstalledEmptyDescription =>
      'No apps installed yet. Visit the App Store to install one.';

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
  String get containerInfoProject => 'Project';

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
  String get orchestrationComposeDelete => 'Delete Compose';

  @override
  String orchestrationComposeDeleteConfirm(String name) {
    return 'Stop and remove all containers in $name?';
  }

  @override
  String get orchestrationComposeForceDelete => 'Force Delete';

  @override
  String get orchestrationComposeDeleteFile => 'Delete Compose File';

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
  String get orchestrationImageId => 'ID';

  @override
  String get orchestrationImageDigest => 'Digest';

  @override
  String get orchestrationImageTags => 'Tags';

  @override
  String get orchestrationImageSizeLabel => 'Size';

  @override
  String get orchestrationImageCreatedLabel => 'Created';

  @override
  String get orchestrationImageInUse => 'In Use';

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
  String get containerCreateBasicSectionTitle => 'Basic Configuration';

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
      'A unified entry for server operations tools, organized by category.';

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
      'Groups, host assets, SSH, processes, logs, and toolbox tools';

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
  String get operationsToolboxTitle => 'Toolbox';

  @override
  String get operationsCronjobsTitle => 'Cronjobs';

  @override
  String get operationsCronjobFormTitle => 'Cronjob Form';

  @override
  String get operationsCronjobRecordsTitle => 'Cronjob Records';

  @override
  String get operationsScriptsTitle => 'Script Library';

  @override
  String get toolboxCenterTitle => 'Toolbox';

  @override
  String get toolboxCenterIntro =>
      'A consolidated tools entry for ClamAV, Fail2ban, FTP, and device management.';

  @override
  String get toolboxCommonOverviewTitle => 'Overview';

  @override
  String get toolboxCommonRecentRecordsTitle => 'Recent Records';

  @override
  String get toolboxStatusLabel => 'Status';

  @override
  String get toolboxVersionLabel => 'Version';

  @override
  String get toolboxStatusEnabled => 'Enabled';

  @override
  String get toolboxStatusDisabled => 'Disabled';

  @override
  String get toolboxClamTitle => 'ClamAV';

  @override
  String get toolboxClamCardSubtitle =>
      'Scan task status and recent scan records';

  @override
  String get toolboxClamTasksTitle => 'Scan Tasks';

  @override
  String get toolboxClamRecordsTitle => 'Recent Scan Records';

  @override
  String get toolboxFail2banTitle => 'Fail2ban';

  @override
  String get toolboxFail2banCardSubtitle => 'Ban policy and blocked IP records';

  @override
  String get toolboxFail2banConfigTitle => 'Fail2ban Configuration';

  @override
  String get toolboxFail2banEditConfig => 'Edit Fail2ban Configuration';

  @override
  String get toolboxFail2banBantime => 'Ban Time';

  @override
  String get toolboxFail2banFindtime => 'Find Time';

  @override
  String get toolboxFail2banMaxretry => 'Max Retry';

  @override
  String get toolboxFail2banPort => 'Port';

  @override
  String get toolboxFtpTitle => 'FTP';

  @override
  String get toolboxFtpCardSubtitle =>
      'FTP service status and user synchronization';

  @override
  String get toolboxFtpUsersTitle => 'FTP Users';

  @override
  String get toolboxFtpBaseDir => 'Base Directory';

  @override
  String get toolboxFtpSyncAction => 'Sync Users';

  @override
  String get toolboxFtpSyncSuccess => 'FTP users synchronized';

  @override
  String get toolboxFtpSyncFailed => 'Failed to synchronize FTP users';

  @override
  String get toolboxDeviceTitle => 'Device Management';

  @override
  String get toolboxDeviceCardSubtitle =>
      'Hostname, DNS, NTP, and swap configuration';

  @override
  String get toolboxDeviceOverviewTitle => 'Device Overview';

  @override
  String get toolboxDeviceConfigTitle => 'Device Configuration';

  @override
  String get toolboxDeviceUsersTitle => 'System Users';

  @override
  String get toolboxDeviceZoneOptionsTitle => 'Time Zone Options';

  @override
  String get toolboxDeviceHostname => 'Hostname';

  @override
  String get toolboxDeviceDns => 'DNS';

  @override
  String get toolboxDeviceNtp => 'NTP';

  @override
  String get toolboxDeviceSwap => 'Swap';

  @override
  String get toolboxDeviceTimeLabel => 'Local Time';

  @override
  String get toolboxDeviceSystemLabel => 'System';

  @override
  String get toolboxDeviceCheckDns => 'Check DNS';

  @override
  String get toolboxDeviceEditConfig => 'Edit Configuration';

  @override
  String get toolboxDeviceCheckDnsSuccess => 'DNS check succeeded';

  @override
  String get toolboxDeviceCheckDnsFailed => 'DNS check failed';

  @override
  String get toolboxDeviceDnsRequired => 'Please provide DNS first';

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
      'Your cronjobs will appear here once created.';

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
      'App Store runtimes should be installed from the App Store. Use this form to create runtimes manually.';

  @override
  String get runtimeFormPhpCreateWeek8Hint =>
      'PHP runtimes are created with this form as well. Fill in the image and startup command as needed.';

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
  String runtimeNodeScriptExecuting(String name) {
    return 'Running script $name, syncing runtime status...';
  }

  @override
  String get runtimeNodeScriptCompleted => 'Script execution completed';

  @override
  String get runtimeNodeScriptFailed => 'Script execution failed';

  @override
  String runtimeNodeScriptRuntimeStatus(String status) {
    return 'Runtime status: $status';
  }

  @override
  String runtimeNodeScriptRuntimeMessage(String message) {
    return 'Runtime message: $message';
  }

  @override
  String runtimeNodeScriptPollAttempts(int count) {
    return 'Status polls: $count';
  }

  @override
  String runtimeNodeScriptCompletedWithStatus(String status) {
    return 'Script execution completed, runtime status: $status';
  }

  @override
  String runtimeNodeScriptFailedWithStatus(String status) {
    return 'Script execution failed, runtime status: $status';
  }

  @override
  String get runtimeNodeScriptWaitTimeout =>
      'Script was triggered, but status confirmation timed out. Please refresh later.';

  @override
  String get operationsPhpExtensionsTitle => 'PHP Extensions';

  @override
  String get operationsPhpConfigTitle => 'PHP Config';

  @override
  String get runtimePhpTabBasic => 'Basic';

  @override
  String get runtimePhpTabFpm => 'FPM';

  @override
  String get runtimePhpTabContainer => 'Container';

  @override
  String get runtimePhpTabPhpFile => 'PHP File';

  @override
  String get runtimePhpTabFpmFile => 'FPM File';

  @override
  String get runtimePhpFpmConfigTitle => 'FPM Parameters';

  @override
  String get runtimePhpFpmMode => 'Process manager mode';

  @override
  String get runtimePhpFpmMaxChildren => 'pm.max_children';

  @override
  String get runtimePhpFpmStartServers => 'pm.start_servers';

  @override
  String get runtimePhpFpmMinSpareServers => 'pm.min_spare_servers';

  @override
  String get runtimePhpFpmMaxSpareServers => 'pm.max_spare_servers';

  @override
  String get runtimePhpContainerExtraHosts => 'Extra hosts';

  @override
  String get runtimePhpContainerPort => 'Container Port';

  @override
  String get runtimePhpHostPort => 'Host Port';

  @override
  String get runtimePhpHostIp => 'Host IP';

  @override
  String get runtimePhpVolumeTarget => 'Target';

  @override
  String get operationsSupervisorTitle => 'Supervisor';

  @override
  String get runtimeSupervisorStatusWarning => 'Partially running';

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
      'Active SSH sessions will appear here.';

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
  String get terminalWorkbenchSessionsTitle => 'Terminal Sessions';

  @override
  String get terminalWorkbenchNoSessions => 'No terminal sessions';

  @override
  String get terminalWorkbenchOpenHint => 'Open or create a terminal session';

  @override
  String get terminalWorkbenchLocalLabel => 'Local';

  @override
  String get terminalWorkbenchStatusConnected => 'Connected';

  @override
  String get terminalWorkbenchStatusClosed => 'Closed';

  @override
  String get terminalWorkbenchStatusIdle => 'Idle';

  @override
  String get terminalWorkbenchKeyboard => 'Keyboard';

  @override
  String get terminalWorkbenchCommand => 'Command';

  @override
  String get terminalWorkbenchQuickCommand => 'Quick Command';

  @override
  String get terminalWorkbenchSearchHost => 'Search host';

  @override
  String get terminalWorkbenchPaste => 'Paste';

  @override
  String get terminalWorkbenchSessionClosed => 'Session closed';

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
  String get operationsGroupCenterTitle => 'Group Center';

  @override
  String get operationsGroupCenterDescription =>
      'Manage reusable groups across core and agent namespaces.';

  @override
  String get operationsGroupScopeCore => 'Core';

  @override
  String get operationsGroupScopeAgent => 'Agent';

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

  @override
  String get commonClear => 'Clear';

  @override
  String get aiTabMcp => 'MCP';

  @override
  String get aiMcpSearchHint => 'Search MCP servers';

  @override
  String get aiMcpCreate => 'Create server';

  @override
  String get aiMcpEdit => 'Edit server';

  @override
  String get aiMcpBindDomain => 'Bind domain';

  @override
  String get aiMcpBindingTitle => 'MCP domain binding';

  @override
  String get aiMcpNoServers => 'No MCP servers';

  @override
  String get aiMcpConfigPreviewTitle => 'Config Preview';

  @override
  String aiMcpDeleteConfirm(String name) {
    return 'Delete MCP server $name?';
  }

  @override
  String get aiMcpDialogCreateTitle => 'Create MCP Server';

  @override
  String get aiMcpDialogEditTitle => 'Edit MCP Server';

  @override
  String get aiMcpCommandLabel => 'Command';

  @override
  String get aiMcpTransportLabel => 'Transport';

  @override
  String get aiMcpTypeLabel => 'Type';

  @override
  String get aiMcpPortLabel => 'Port';

  @override
  String get aiMcpBaseUrlLabel => 'Base URL';

  @override
  String get aiMcpHostIpLabel => 'Host IP';

  @override
  String get aiMcpContainerLabel => 'Container Name';

  @override
  String get aiMcpSsePathLabel => 'SSE Path';

  @override
  String get aiMcpStreamablePathLabel => 'Streamable HTTP Path';

  @override
  String get aiMcpExternalUrl => 'External URL';

  @override
  String get aiMcpStatusLabel => 'Status';

  @override
  String get aiMcpNameRequired => 'Enter a server name';

  @override
  String get aiMcpCommandRequired => 'Enter a command';

  @override
  String get aiMcpTypeRequired => 'Enter a type';

  @override
  String get aiMcpTransportRequired => 'Enter a transport';

  @override
  String get aiMcpPortRequired => 'Enter a valid port';

  @override
  String get aiMcpDomainDialogTitle => 'Update MCP Domain';

  @override
  String get aiMcpDomainRequired => 'Enter a domain';

  @override
  String get menuSettingsTitle => 'Menu Settings';

  @override
  String get menuSettingsDescription =>
      'Manage the default menu order returned by the panel.';

  @override
  String get menuSettingsAddLabel => 'Menu item';

  @override
  String get menuSettingsEditTitle => 'Edit Menu Item';

  @override
  String get menuSettingsSaveSuccess => 'Menu settings saved';

  @override
  String get toolboxDiskTitle => 'Disk Management';

  @override
  String get toolboxDiskCardSubtitle =>
      'Inspect disks, partitions, and mount state';

  @override
  String get toolboxDiskOverviewTitle => 'Disk Overview';

  @override
  String get toolboxDiskTotalDisksLabel => 'Total disks';

  @override
  String get toolboxDiskTotalCapacityLabel => 'Total capacity';

  @override
  String get toolboxDiskUnpartitionedSectionTitle => 'Unpartitioned disks';

  @override
  String get toolboxDiskSystemSectionTitle => 'System disks';

  @override
  String get toolboxDiskDataSectionTitle => 'Data disks';

  @override
  String get toolboxDiskMountAction => 'Mount';

  @override
  String get toolboxDiskUnmountAction => 'Unmount';

  @override
  String get toolboxDiskPartitionAction => 'Partition';

  @override
  String get toolboxDiskFilesystemLabel => 'Filesystem';

  @override
  String get toolboxDiskMountPointLabel => 'Mount point';

  @override
  String get toolboxDiskAutoMountLabel => 'Auto mount';

  @override
  String get toolboxDiskNoFailLabel => 'No fail';

  @override
  String get toolboxDiskLabelLabel => 'Label';

  @override
  String get toolboxDiskMountSuccess => 'Disk mounted';

  @override
  String get toolboxDiskPartitionSuccess => 'Disk partitioned';

  @override
  String get toolboxDiskUnmountSuccess => 'Disk unmounted';

  @override
  String get toolboxDiskSizeLabel => 'Size';

  @override
  String get toolboxDiskModelLabel => 'Model';

  @override
  String get toolboxDiskUnmounted => 'Unmounted';

  @override
  String get toolboxDiskSystemDiskTag => 'System';

  @override
  String get toolboxHostToolTitle => 'Host Tool';

  @override
  String get toolboxHostToolCardSubtitle =>
      'Manage supervisord service and process files';

  @override
  String get toolboxHostToolServiceSectionTitle => 'Supervisor Service';

  @override
  String get toolboxHostToolConfigSectionTitle => 'Supervisor Config';

  @override
  String get toolboxHostToolProcessSectionTitle => 'Supervisor Processes';

  @override
  String get toolboxHostToolStatusLabel => 'Status';

  @override
  String get toolboxHostToolVersionLabel => 'Version';

  @override
  String get toolboxHostToolConfigPathLabel => 'Config path';

  @override
  String get toolboxHostToolServiceNameLabel => 'Service name';

  @override
  String get toolboxHostToolInitAction => 'Initialize';

  @override
  String get toolboxHostToolStartAction => 'Start';

  @override
  String get toolboxHostToolStopAction => 'Stop';

  @override
  String get toolboxHostToolSaveSuccess => 'Host tool updated';

  @override
  String get toolboxHostToolCommandLabel => 'Command';

  @override
  String get toolboxHostToolNumprocsLabel => 'Processes';

  @override
  String get toolboxHostToolUserLabel => 'User';

  @override
  String get toolboxHostToolDirLabel => 'Working directory';

  @override
  String get toolboxHostToolEnvironmentLabel => 'Environment';

  @override
  String get toolboxHostToolAutoStartLabel => 'Auto start';

  @override
  String get toolboxHostToolAutoRestartLabel => 'Auto restart';

  @override
  String get toolboxHostToolProcessCreateTitle => 'Create Supervisor Process';

  @override
  String get toolboxHostToolProcessEditTitle => 'Edit Supervisor Process';

  @override
  String get toolboxHostToolConfigFileAction => 'Config file';

  @override
  String get toolboxHostToolOutLogAction => 'stdout log';

  @override
  String get toolboxHostToolErrLogAction => 'stderr log';

  @override
  String get aiTabAgents => 'Agents';

  @override
  String get aiAgentsSubTabAgent => 'Agents';

  @override
  String get aiAgentsSubTabModel => 'Models';

  @override
  String get aiAgentsSearchHint => 'Search agents';

  @override
  String get aiAgentsCreate => 'Create Agent';

  @override
  String get aiAgentsDeleteConfirm =>
      'Are you sure you want to delete this item?';

  @override
  String get aiAgentsNoAgents => 'No agents found';

  @override
  String get aiAgentsNoSelection => 'Select an agent to view details';

  @override
  String get aiAgentsOverview => 'Overview';

  @override
  String get aiAgentsChannels => 'Channels';

  @override
  String get aiAgentsSkills => 'Skills';

  @override
  String get aiAgentsSettings => 'Settings';

  @override
  String get aiAgentsSkillSearchHint => 'Search skills';

  @override
  String get aiAgentsInstall => 'Install';

  @override
  String get aiAgentsEnabled => 'Enabled';

  @override
  String get aiAgentsDisabled => 'Disabled';

  @override
  String get aiAgentsNotInstalled => 'Not installed';

  @override
  String get aiAgentsAllowedOrigins => 'Allowed origins';

  @override
  String get aiAgentsTimezone => 'Timezone';

  @override
  String get aiAgentsNpmRegistry => 'NPM Registry';

  @override
  String get aiAgentsBrowserEnabled => 'Enable browser tool';

  @override
  String get aiAgentsConfigFile => 'Config file';

  @override
  String get aiAgentsSaveConfig => 'Save config';

  @override
  String get aiAgentsAgentType => 'Agent type';

  @override
  String get aiAgentsOpenclaw => 'OpenClaw';

  @override
  String get aiAgentsCopaw => 'CoPaw';

  @override
  String get aiAgentsAppVersion => 'App version';

  @override
  String get aiAgentsVersionRequired => 'App version is required';

  @override
  String get aiAgentsWebUiPort => 'WebUI port';

  @override
  String get aiAgentsPortRequired => 'Enter a valid port';

  @override
  String get aiAgentsAccount => 'Account';

  @override
  String get aiAgentsAccountRequired => 'Select an account';

  @override
  String get aiAgentsModel => 'Model';

  @override
  String get aiAgentsModelRequired => 'Select a model';

  @override
  String get aiAgentsTokenOptional => 'Token (optional)';

  @override
  String get aiAgentsNameRequired => 'Name is required';

  @override
  String get aiAgentsProvider => 'Provider';

  @override
  String get aiAgentsProviderRequired => 'Select a provider';

  @override
  String get aiAgentsApiKey => 'API Key';

  @override
  String get aiAgentsApiKeyRequired => 'API key is required';

  @override
  String get aiAgentsBaseUrl => 'Base URL';

  @override
  String get aiAgentsApiType => 'API Type';

  @override
  String get aiAgentsApiTypeRequired => 'API type is required';

  @override
  String get aiAgentsRememberApiKey => 'Remember API key';

  @override
  String get aiAgentsSyncAgents => 'Sync associated agents';

  @override
  String get aiAgentsVerify => 'Verify';

  @override
  String get aiAgentsVerified => 'Verified';

  @override
  String get aiAgentsUnverified => 'Unverified';

  @override
  String get aiAgentsAllProviders => 'All providers';

  @override
  String get aiAgentsBrowserConfig => 'Browser config';

  @override
  String get aiAgentsBrowserDefaultProfile => 'Default profile';

  @override
  String get aiAgentsBrowserExecutablePath => 'Executable path';

  @override
  String get aiAgentsBrowserHeadless => 'Headless mode';

  @override
  String get aiAgentsBrowserNoSandbox => 'Disable sandbox';

  @override
  String get aiAgentsSaveBrowserConfig => 'Save browser config';

  @override
  String get aiAgentsBrowserDefaultProfileRequired =>
      'Default profile is required';

  @override
  String get aiAgentsFeishuPairing => 'Feishu pairing';

  @override
  String get aiAgentsPairingCode => 'Pairing code';

  @override
  String get aiAgentsApprovePairing => 'Approve pairing';

  @override
  String get aiAgentsPairingCodeRequired => 'Pairing code is required';

  @override
  String get aiAgentsPairingApproveSuccess => 'Pairing approved';

  @override
  String get containerNetworkIdLabel => 'ID';

  @override
  String get containerNetworkDriverLabel => 'Driver';

  @override
  String get containerNetworkScopeLabel => 'Scope';

  @override
  String get containerNetworkInternalLabel => 'Internal';

  @override
  String get containerNetworkAttachableLabel => 'Attachable';

  @override
  String containerNetworkDriverChip(String driver) {
    return 'Driver: $driver';
  }

  @override
  String get containerNetworkSystemChip => 'System';

  @override
  String get containerNetworkEnableIPv6 => 'Enable IPv6';

  @override
  String get containerNetworkLabelsLabel => 'Labels';

  @override
  String get containerNetworkLabelsHint => 'key1=value1,key2=value2';

  @override
  String get volumeDetailDriver => 'Driver';

  @override
  String get volumeDetailMountpoint => 'Mountpoint';

  @override
  String get volumeDetailLabels => 'Labels';

  @override
  String get volumeDetailOptions => 'Options';

  @override
  String get volumeFormLabels => 'Labels';

  @override
  String get volumeFormLabelsHint => 'key=value, one per line';

  @override
  String get volumeFormOptions => 'Mount Options';

  @override
  String get volumeFormOptionsHint => 'key=value, one per line';

  @override
  String get securityGatewayPageTitle => 'Security & Gateway';

  @override
  String get securityGatewayUnifiedSummaryTitle => 'Unified security summary';

  @override
  String get securityGatewaySummarySection => 'Security Summary';

  @override
  String get securityGatewayEntryFocusLabel => 'Entry Focus';

  @override
  String get securityGatewayAvailable => 'Available';

  @override
  String get securityGatewayUnavailable => 'Unavailable';

  @override
  String get securityGatewayWebsiteExpiringLabel => 'Website Expiring';

  @override
  String securityGatewayCertificateCount(int count) {
    return '$count certificate(s)';
  }

  @override
  String get securityGatewayLatestApplyLabel => 'Latest Apply';

  @override
  String get securityGatewayQuickActionsSection => 'Quick Actions';

  @override
  String get securityGatewayCertificateCenterAction => 'Certificate Center';

  @override
  String get securityGatewayOpenRestyHttpsAction => 'OpenResty HTTPS';

  @override
  String get securityGatewayRollbackSuccess =>
      'Rolled back the latest local snapshot.';

  @override
  String get securityGatewayRollbackEmpty => 'No rollback snapshot available.';

  @override
  String get securityGatewayRollbackLatestAction => 'Rollback Latest';

  @override
  String get securityGatewayPanelTlsSection => 'Panel TLS';

  @override
  String get securityGatewayStatusLabel => 'Status';

  @override
  String get securityGatewayLoaded => 'Loaded';

  @override
  String get securityGatewayRiskLabel => 'Risk';

  @override
  String get securityGatewayNoPanelTlsRisk => 'No panel TLS risk detected';

  @override
  String get securityGatewayRecentLabel => 'Recent';

  @override
  String get securityGatewayOpenPanelTlsAction => 'Open Panel TLS details';

  @override
  String get securityGatewayWebsiteCertsSection => 'Website Certificates';

  @override
  String get securityGatewaySummaryLabel => 'Summary';

  @override
  String securityGatewayCertsLoadedCount(int count) {
    return '$count certificates loaded';
  }

  @override
  String securityGatewayExpiringSoonCount(int count) {
    return '$count expiring soon';
  }

  @override
  String get securityGatewayOpenCertCenterAction => 'Open certificate center';

  @override
  String get securityGatewayOpenWebsiteStrategyAction =>
      'Open current website strategy';

  @override
  String get securityGatewayOpenRestyGatewaySection => 'OpenResty Gateway';

  @override
  String get securityGatewayOpenOpenRestyAction => 'Open OpenResty console';

  @override
  String get securityGatewayEntryPanelTls => 'Panel TLS';

  @override
  String get securityGatewayEntryWebsiteCerts => 'Website Certificates';

  @override
  String get securityGatewayEntryOpenResty => 'OpenResty Gateway';

  @override
  String get securityGatewayOpenRestyLabel => 'OpenResty';

  @override
  String get securityGatewayRunning => 'Running';

  @override
  String get securityGatewayInactive => 'Inactive';

  @override
  String get securityGatewayEnabled => 'Enabled';

  @override
  String get securityGatewayDisabled => 'Disabled';

  @override
  String get securityGatewayRiskPanelTlsExpiredTitle => 'Panel TLS expired';

  @override
  String get securityGatewayRiskPanelTlsExpiredMessage =>
      'The panel TLS certificate is expired and should be replaced.';

  @override
  String get securityGatewayRiskWebsiteCertsExpiringTitle =>
      'Website certificates expiring';

  @override
  String securityGatewayRiskWebsiteCertsExpiringMessage(int count) {
    return '$count website certificate(s) expire within 30 days.';
  }

  @override
  String get securityGatewayRiskOpenRestyUnavailableTitle =>
      'OpenResty status unavailable';

  @override
  String get securityGatewayRiskOpenRestyUnavailableMessage =>
      'The gateway is not reporting as active.';

  @override
  String get securityGatewayNoRecentSnapshot => 'No recent local snapshot';

  @override
  String get websiteSiteSslPageTitle => 'HTTPS Strategy';

  @override
  String websiteSiteSslPageTitleWithDomain(String domain) {
    return 'HTTPS Strategy · $domain';
  }

  @override
  String get websiteSiteSslRiskNoticesTitle => 'Risk notices';

  @override
  String get websiteSiteSslCurrentCertSection => 'Current Certificate';

  @override
  String get websiteSiteSslNoCertificateBound => 'No certificate bound';

  @override
  String get websiteSiteSslProviderRow => 'Provider';

  @override
  String get websiteSiteSslExpirationRow => 'Expiration';

  @override
  String get websiteSiteSslCurrentModeRow => 'Current Mode';

  @override
  String get websiteSiteSslStrategySection => 'HTTPS Strategy';

  @override
  String get websiteSiteSslHttpModeRow => 'HTTP Mode';

  @override
  String get websiteSiteSslCertTypeRow => 'Certificate Type';

  @override
  String get websiteSiteSslEditStrategyAction => 'Edit strategy';

  @override
  String get websiteSiteSslPreviewDiffAction => 'Preview diff';

  @override
  String get websiteSiteSslStrategyDiffTitle => 'Strategy diff preview';

  @override
  String get websiteSiteSslCertActionsSection => 'Certificate Actions';

  @override
  String get websiteSiteSslSelectedCertRow => 'Selected Certificate';

  @override
  String get websiteSiteSslOpenCertCenterAction => 'Open certificate center';

  @override
  String get websiteSiteSslRollbackSuccess =>
      'Rolled back last successful HTTPS strategy.';

  @override
  String get websiteSiteSslRollbackAction => 'Rollback last change';

  @override
  String get websiteSiteSslAdvancedSection => 'Advanced';

  @override
  String get websiteSiteSslAdvancedDescription =>
      'Use the advanced page for certificate obtain/upload/update flows that are outside the binding strategy path.';

  @override
  String get websiteSiteSslOpenAdvancedAction => 'Open advanced SSL page';

  @override
  String get websiteSiteSslUpdateDialogTitle => 'Update HTTPS strategy';

  @override
  String get websiteSiteSslEnableHttpsLabel => 'Enable HTTPS';

  @override
  String get websiteSiteSslNoCertificate => 'No certificate';

  @override
  String get websiteSiteSslPreviewAction => 'Preview';

  @override
  String get websiteSiteSslRiskNoCertTitle =>
      'HTTPS enabled without certificate';

  @override
  String get websiteSiteSslRiskNoCertMessage =>
      'Enable HTTPS only after selecting a valid certificate.';

  @override
  String get websiteSiteSslRiskDomainMismatchTitle => 'Domain mismatch';

  @override
  String get websiteSiteSslRiskDomainMismatchMessage =>
      'The selected certificate primary domain does not match the current website domain.';

  @override
  String get websiteSiteSslRiskExpiredCertTitle => 'Expired certificate';

  @override
  String get websiteSiteSslRiskExpiredCertMessage =>
      'The selected certificate is already expired.';

  @override
  String get websiteSiteSslRiskExpiringSoonTitle => 'Certificate expiring soon';

  @override
  String get websiteSiteSslRiskExpiringSoonMessage =>
      'The selected certificate should be rotated soon.';

  @override
  String get websiteSiteSslDiffLabelHttps => 'HTTPS';

  @override
  String get websiteSiteSslDiffLabelHttpMode => 'HTTP Mode';

  @override
  String get websiteSiteSslDiffLabelCertificate => 'Certificate';

  @override
  String get websiteSiteSslDiffLabelExpiration => 'Expiration';

  @override
  String get websiteSiteSslDiffLabelProvider => 'Provider';

  @override
  String phpExtensionsRecordsTitle(String title) {
    return '$title Records';
  }

  @override
  String get phpExtensionsLabel => 'Extensions';

  @override
  String get commonUpdated => 'Updated';

  @override
  String get commonUpdateFailed => 'Update failed';

  @override
  String get commonOperationFailed => 'Operation failed';

  @override
  String get commonDeleted => 'Deleted';

  @override
  String get commonDeleteFailed => 'Delete failed';

  @override
  String get commonTestConnection => 'Test Connection';

  @override
  String get commonTestPassed => 'Connection test passed';

  @override
  String get commonTestFailed => 'Connection test failed';

  @override
  String get commonAddress => 'Address';

  @override
  String get commonVersion => 'Version';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonSize => 'Size';

  @override
  String get commonType => 'Type';

  @override
  String get commonCommand => 'Command';

  @override
  String get commonImage => 'Image';

  @override
  String get commonTimeout => 'Timeout';

  @override
  String get commonOk => 'OK';

  @override
  String get commonAction => 'Action';

  @override
  String get commonEnable => 'Enable';

  @override
  String get commonWebsiteIds => 'Website IDs (comma separated)';

  @override
  String get commonTimeoutSeconds => 'Timeout (s)';

  @override
  String get websiteHttpsUpdateFailed => 'Failed to update HTTPS config';

  @override
  String get websiteHttpsHsts => 'HSTS';

  @override
  String get websiteHttpsSslCertificate => 'SSL Certificate';

  @override
  String get websiteRedirectTitle => 'Redirect';

  @override
  String get websiteRedirectEmpty => 'No redirect rules';

  @override
  String get websiteCorsTitle => 'CORS';

  @override
  String get websiteLeechTitle => 'Anti-Leech';

  @override
  String get websiteLeechProtection => 'Anti-Leech Protection';

  @override
  String get websiteLogClear => 'Clear logs';

  @override
  String get websiteLogEmpty => 'No logs';

  @override
  String get websiteAuthBasicTitle => 'Auth';

  @override
  String get websiteAuthBasicEmpty => 'No auth users';

  @override
  String get websiteResourceTitle => 'Resource';

  @override
  String get websiteLoadBalancerTitle => 'Load Balancer';

  @override
  String get websiteLoadBalancerEmpty => 'No load balancers';

  @override
  String get routingRulesBatchActions => 'Batch Actions';

  @override
  String get routingRulesBatchProxyStatus => 'Batch Proxy Status';

  @override
  String get routingRulesBatchDeleteProxy => 'Batch Delete Proxy';

  @override
  String get routingRulesBatchRedirectFile => 'Batch Redirect File';

  @override
  String get routingRulesBatchLoadBalancerFile => 'Batch Load Balancer File';

  @override
  String get routingRulesBatchInvalidIds => 'No valid website IDs.';

  @override
  String routingRulesBatchResult(int success, int failed) {
    return 'Batch done: success $success, failed $failed.';
  }

  @override
  String get fileShareTitle => 'File Shares';

  @override
  String get fileShareEmpty => 'No shares';

  @override
  String get wgetTitle => 'WGET Downloads';

  @override
  String get wgetEmpty => 'No active downloads';

  @override
  String get wgetStopFailed => 'Stop failed';

  @override
  String get wgetStopped => 'Stopped';

  @override
  String get fileHistoryEmpty => 'No history';

  @override
  String get fileHistoryRestore => 'Restore';

  @override
  String get fileHistoryRestored => 'Restored';

  @override
  String get fileHistoryRestoreFailed => 'Restore failed';

  @override
  String get filePermissionApply => 'Apply';

  @override
  String get filePermissionRecursive => 'Recursive';

  @override
  String get filePermissionOwner => 'Owner (e.g. root)';

  @override
  String get filePermissionGroup => 'Group (e.g. root)';

  @override
  String get filePermissionMode => 'Mode (e.g. 0644, 0755)';

  @override
  String get filePermissionUpdated => 'Permissions updated';

  @override
  String get recycleBinStatusTitle => 'Recycle Bin Status';

  @override
  String get recycleBinTitle => 'Recycle Bin';

  @override
  String get aiGpuHistoryTitle => 'GPU History';

  @override
  String get aiGpuHistoryEmpty => 'No GPU data';

  @override
  String get mcpServerDetailServerName => 'Server Name';

  @override
  String get mcpServerDetailSyncStatus => 'Sync status';

  @override
  String get mcpServerDetailSynced => 'Status synced';

  @override
  String get mcpServerDetailSyncFailed => 'Sync failed';

  @override
  String get mcpServerDetailTestFailed => 'Test failed';

  @override
  String get aiAccountsTitle => 'AI Accounts';

  @override
  String get aiAccountsEmpty => 'No accounts';

  @override
  String get aiOllamaTitle => 'Ollama Models';

  @override
  String get aiOllamaEmpty => 'No models';

  @override
  String get aiOllamaSync => 'Sync';

  @override
  String get aiOllamaSynced => 'Synced';

  @override
  String get aiOllamaSyncFailed => 'Sync failed';

  @override
  String get aiOllamaLoadFailed => 'Load failed';

  @override
  String get aiOllamaLoading => 'Loading';

  @override
  String get aiOllamaModified => 'Modified';

  @override
  String get aiAgentsTitle => 'AI Agents';

  @override
  String get databaseMongodbEmpty => 'No databases';

  @override
  String get databaseMysqlVariablesTitle => 'MySQL Variables';

  @override
  String get databaseMysqlVariablesEmpty => 'No variables';

  @override
  String get databasePgPrivilegesTitle => 'PostgreSQL Privileges';

  @override
  String get databasePgPrivilegesEmpty => 'No privileges';

  @override
  String get databaseRedisRdbTitle => 'RDB Persistence';

  @override
  String get databaseRedisRdbDesc => 'RDB snapshot';

  @override
  String get databaseRedisAofTitle => 'AOF Persistence';

  @override
  String get databaseRedisAofDesc => 'Append-only file';

  @override
  String get databaseSlowLogTitle => 'Slow Query Log';

  @override
  String get databaseSlowLogEmpty => 'No slow queries';

  @override
  String get databaseSlowLogDuration => 'Duration';

  @override
  String get databaseRemoteTitle => 'Remote';

  @override
  String get databaseRemoteTimeoutLabel => 'Timeout (s)';

  @override
  String get databaseRemoteTestBeforeSave => 'Test connection before saving';

  @override
  String get containerInspectEntrypoint => 'Entrypoint';

  @override
  String get containerInspectWorkingDir => 'Working Dir';

  @override
  String get containerInspectGateway => 'Gateway';

  @override
  String get dockerConfigTitle => 'Docker Configuration';

  @override
  String get containerMaintenanceTitle => 'Container Maintenance';

  @override
  String get containerMaintenanceCommitTitle => 'Commit Container';

  @override
  String get containerMaintenanceCommitMessage => 'Commit Message (optional)';

  @override
  String get containerMaintenanceNewImageName =>
      'New Image Name (e.g. myimage:v1)';

  @override
  String get containerMaintenanceCommit => 'Commit';

  @override
  String get containerMaintenanceCommitted => 'Committed';

  @override
  String get containerMaintenanceCommitFailed => 'Commit failed';

  @override
  String get containerMaintenancePruneTitle => 'Prune Stopped Containers';

  @override
  String get containerMaintenancePrune => 'Prune';

  @override
  String get containerMaintenancePruneFailed => 'Prune failed';

  @override
  String get containerMaintenanceContainerId => 'Container ID';

  @override
  String get containerFilesTitle => 'Files';

  @override
  String get containerFilesEmpty => 'No files';

  @override
  String get containerFilesDirectory => 'Directory';

  @override
  String containerFilesSizeBytes(String size) {
    return '$size bytes';
  }

  @override
  String get imageOpsTitle => 'Image Operations';

  @override
  String get imageOpsPushImage => 'Push Image';

  @override
  String get imageOpsPush => 'Push';

  @override
  String get imageOpsPushStarted => 'Push started';

  @override
  String get imageOpsPushFailed => 'Push failed';

  @override
  String get imageOpsSaveImage => 'Save Image to Tar';

  @override
  String get imageOpsImageSaved => 'Image saved';

  @override
  String get imageOpsTagImage => 'Tag Image';

  @override
  String get imageOpsTag => 'Tag';

  @override
  String get imageOpsTagged => 'Tagged';

  @override
  String get imageOpsTagFailed => 'Tag failed';

  @override
  String get imageOpsSourceImage => 'Source image';

  @override
  String get imageOpsTargetTag => 'Target tag';

  @override
  String get imageOpsImageName => 'Image name';

  @override
  String get imageOpsImageNameHint => 'Image name (e.g. registry/myimage:v1)';

  @override
  String get toolboxSupervisorTitle => 'Supervisor';

  @override
  String get toolboxSupervisorStatusTitle => 'Supervisor Status';

  @override
  String get toolboxSupervisorEmpty => 'No processes';

  @override
  String get toolboxSupervisorNotInit => 'Not initialized';

  @override
  String get monitorSettingsStatus => 'Monitor Status';

  @override
  String fileHistoryTitleWith(String path) {
    return 'History: $path';
  }

  @override
  String filePermissionTitleWith(int count) {
    return 'Permissions ($count files)';
  }

  @override
  String aiOllamaSizeWith(String size) {
    return 'Size: $size';
  }

  @override
  String aiAgentsTypeWith(String type) {
    return 'Type: $type';
  }

  @override
  String databaseMongodbSizeWith(String size) {
    return 'Size: $size';
  }

  @override
  String databasePgPrivilegeWith(String privileges) {
    return 'Privileges: $privileges';
  }

  @override
  String databaseSlowLogTimeWith(String time) {
    return 'Time: $time';
  }

  @override
  String containerInspectIpWith(String ip) {
    return 'IP: $ip';
  }

  @override
  String monitorSettingsEdit(String key) {
    return 'Edit $key';
  }

  @override
  String get containerInspectTitle => 'Inspect';

  @override
  String get orchestrationTemplates => 'Templates';

  @override
  String get composeTemplateCreate => 'Create Template';

  @override
  String get composeTemplateEdit => 'Edit Template';

  @override
  String get composeTemplateContent => 'Template Content';

  @override
  String get composeTemplateNameRequired => 'Template name is required';

  @override
  String get composeTemplateEmpty => 'No templates';

  @override
  String get containerTerminal => 'Terminal';

  @override
  String composeTemplateDeleteConfirm(String name) {
    return 'Delete template $name?';
  }

  @override
  String get toolboxClamFilesTitle => 'Config Files';

  @override
  String get toolboxClamFileContent => 'File Content';

  @override
  String get toolboxClamFileReadonly => 'Log Content (read-only)';

  @override
  String get toolboxClamCronExpression => 'Cron expression';

  @override
  String get toolboxClamInfectedDirectory => 'Infected directory';

  @override
  String get logsCenterTabWebsite => 'Website Logs';

  @override
  String get logsWebsiteSelectorLabel => 'Select Website';

  @override
  String get databaseUserListTitle => 'Database Users';

  @override
  String get databaseUserChangePassword => 'Change Password';

  @override
  String databaseUserDeleteConfirm(String name) {
    return 'Delete user $name?';
  }

  @override
  String get databaseUserNewPasswordLabel => 'New Password';

  @override
  String get aiAgentPluginsTitle => 'Agent Plugins';

  @override
  String get aiAgentInstalledPlugins => 'Installed Plugins';

  @override
  String get aiAgentPluginMarket => 'Plugin Market';

  @override
  String get aiAgentPluginSearchHint => 'Search market plugins';

  @override
  String get aiAgentPluginMarketEmpty => 'Search the market to find plugins';

  @override
  String get aiAgentPluginInstallConfirm => 'Install this plugin?';

  @override
  String get aiAgentPluginUninstall => 'Uninstall';

  @override
  String get aiAgentPluginUpgrade => 'Upgrade';

  @override
  String get hostDiagnosticsTitle => 'Runtime Diagnostics';

  @override
  String get hostDiagnosticsSummary => 'Diagnostics Summary';

  @override
  String get hostDiagnosticsCaptureTitle => 'Capture Profile';

  @override
  String get hostDiagnosticsDuration => 'Duration';

  @override
  String get hostDiagnosticsCapture => 'Capture';

  @override
  String get hostDiagnosticsGoroutines => 'Goroutine Dump';

  @override
  String get hostDiagnosticsCaptureDone => 'Profile captured';

  @override
  String get toolboxClamFreshStart => 'Freshclam Start';

  @override
  String get toolboxClamFreshStop => 'Freshclam Stop';

  @override
  String get toolboxClamFreshRestart => 'Freshclam Restart';

  @override
  String get websiteRoutingProxyStatusDelete => 'Proxy Status / Delete';

  @override
  String get databaseSourceAll => 'All';

  @override
  String get databaseSourceLocal => 'Local';

  @override
  String get databaseSourceRemote => 'Remote';

  @override
  String get databaseFormPgSuperuser => 'PostgreSQL Superuser';

  @override
  String get filePreviewLoadFailed => 'Failed to load file';

  @override
  String get filePreviewSaveFailed => 'Failed to save file';

  @override
  String get filePreviewLoadSuccess => 'File loaded';

  @override
  String get dashboardRefreshInterval => 'Refresh interval';

  @override
  String get dashboardInterval3s => '3 seconds';

  @override
  String get dashboardInterval5s => '5 seconds (default)';

  @override
  String get dashboardInterval10s => '10 seconds';

  @override
  String get dashboardInterval30s => '30 seconds';

  @override
  String get dashboardInterval1m => '1 minute';

  @override
  String get filePreviewLoadImageFailed => 'Failed to load image';

  @override
  String get filePreviewLoadPdfFailed => 'Failed to load PDF';

  @override
  String get filePreviewVideoNotInitialized => 'Video player not initialized';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsSystemBackdrop => 'System backdrop';

  @override
  String get settingsRestartRequired => 'Restart required';

  @override
  String get commonNone => 'None';

  @override
  String get hostServersRefreshFailed => 'Failed to refresh servers.';

  @override
  String get hostServersActions => 'Server actions';

  @override
  String get hostServersSwitch => 'Switch';

  @override
  String get hostServersDeleteCurrentBlocked =>
      'The current server cannot be deleted. Switch to another server first.';

  @override
  String get hostServersNamePlaceholder => 'My server';

  @override
  String get hostServersUrlRequired => 'URL is required.';

  @override
  String get hostServersUrlHttpRequired =>
      'URL must start with http:// or https://.';

  @override
  String get hostServersApiKeyRequired => 'API key is required.';

  @override
  String get hostFilesPathPlaceholder => 'Enter a path and press Enter';

  @override
  String get hostFilesFolderNamePlaceholder => 'Folder name';

  @override
  String get hostFilesFolderNameEmpty => 'Folder name cannot be empty.';

  @override
  String get hostContainersRefreshFailed => 'Failed to refresh containers.';

  @override
  String get hostContainersStopContainer => 'Stop container';

  @override
  String get hostContainersStartContainer => 'Start container';

  @override
  String get hostContainersRestartContainer => 'Restart container';

  @override
  String get hostContainersDeleteContainer => 'Delete container';

  @override
  String get hostContainersDeleteConfirm => 'Delete Container';

  @override
  String get hostAppsRefreshFailed => 'Failed to refresh apps.';

  @override
  String get hostAppsInstallOpenresty => 'Install OpenResty';

  @override
  String get hostAppsStopApp => 'Stop app';

  @override
  String get hostAppsStartApp => 'Start app';

  @override
  String get hostAppsUninstallApp => 'Uninstall app';

  @override
  String get hostAppsUninstallConfirm => 'Uninstall App';

  @override
  String get hostAppsOpenrestyInstallConfirm =>
      'OpenResty will be downloaded and installed from the app store. This may take a few minutes. Continue?';

  @override
  String get hostAppsOpenrestyInstallSubmitted =>
      'OpenResty install task submitted.';

  @override
  String get hostWebsitesRefreshFailed => 'Failed to refresh websites.';

  @override
  String get hostWebsitesStopWebsite => 'Stop website';

  @override
  String get hostWebsitesStartWebsite => 'Start website';

  @override
  String get hostWebsitesPrimaryDomainHint => 'e.g. example.com';

  @override
  String get hostWebsitesAliasHint => 'Auto-derived from domain if empty';

  @override
  String get hostWebsitesAddFailed => 'Failed to add website.';

  @override
  String get hostCommonOptional => 'Optional';

  @override
  String get hostCommonPortNumeric => 'Port must be a number.';

  @override
  String get hostOpenrestyRefreshFailed =>
      'Failed to refresh the OpenResty snapshot.';

  @override
  String get hostOpenrestyConfigEmptyHint =>
      '# The OpenResty configuration source is empty or unavailable (/etc/nginx/nginx.conf)';

  @override
  String get hostOpenrestyConfigSource =>
      'Configuration source (/etc/nginx/nginx.conf)';

  @override
  String get hostOpenrestySaveConfig => 'Save OpenResty configuration';

  @override
  String get hostOpenrestySaveConfigConfirm =>
      'This will overwrite /etc/nginx/nginx.conf with the edited content.\nAn invalid configuration may make hosted websites unavailable. Continue?';

  @override
  String get hostOpenrestySaveConfigFailed =>
      'Failed to save the OpenResty configuration.';

  @override
  String get hostDatabaseCreate => 'Create database';

  @override
  String get hostDatabaseRefreshFailed => 'Failed to refresh databases.';

  @override
  String get hostDatabaseActions => 'Database actions';

  @override
  String get hostDatabasePasswordRequired => 'Password is required.';

  @override
  String get hostDatabaseDeleteTitle => 'Delete Database';

  @override
  String get hostDatabaseNameHint => 'e.g. app_db';

  @override
  String get hostDatabaseAddressHint => 'e.g. 192.168.1.10';

  @override
  String get hostDatabasePortHint => 'e.g. 3306';

  @override
  String get hostDatabaseCreateFailed => 'Failed to create database.';

  @override
  String get hostDatabaseCreateRetryHint =>
      'Create failed. Adjust the inputs and try again.';

  @override
  String get hostDatabaseRemoteAddressRequired =>
      'Address is required for remote databases.';

  @override
  String get hostDatabaseRemotePortRequired =>
      'Port is required for remote databases.';

  @override
  String get hostDatabaseRemoteUsernameRequired =>
      'Username is required for remote databases.';

  @override
  String get hostDatabaseRemotePasswordRequired =>
      'Password is required for remote databases.';

  @override
  String get hostOrchestrationRefreshFailed => 'Failed to refresh composes.';

  @override
  String get hostOrchestrationActions => 'Compose actions';

  @override
  String get hostOrchestrationUp => 'Up';

  @override
  String get hostOrchestrationDown => 'Down';

  @override
  String get hostOrchestrationDownTitle => 'Down Compose';

  @override
  String get hostOrchestrationNamePlaceholder => 'e.g. my-app';

  @override
  String get hostOrchestrationCreateFrom => 'Create from';

  @override
  String get hostOrchestrationFromPath => 'From path';

  @override
  String get hostOrchestrationFromContent => 'From content';

  @override
  String get hostOrchestrationFromTemplate => 'From template';

  @override
  String get hostOrchestrationComposeFilePath => 'Compose file path';

  @override
  String get hostOrchestrationPathPlaceholder =>
      'e.g. /opt/1panel/docker/compose/my-app/docker-compose.yml';

  @override
  String get hostOrchestrationNewComposeContent => 'New compose content (YAML)';

  @override
  String get hostOrchestrationFullReplacementHint =>
      'Full replacement: paste the complete new config; empty content will be rejected';

  @override
  String get hostOrchestrationTemplateId => 'Template ID';

  @override
  String get hostOrchestrationTemplateIdPlaceholder => 'e.g. 1';

  @override
  String get hostOrchestrationCreateFailed => 'Failed to create compose.';

  @override
  String get hostOrchestrationContentRequired => 'Compose content is required.';

  @override
  String get hostOrchestrationEditTitle => 'Edit Compose';

  @override
  String get hostOrchestrationReplace => 'Replace';

  @override
  String get hostOrchestrationSaveFailedReopen =>
      'Save failed. The editor reopens with your content; try again.';

  @override
  String get hostOrchestrationPathRequired => 'Compose file path is required.';

  @override
  String get hostOrchestrationTemplateIdRequired => 'Template ID is required.';

  @override
  String get hostOrchestrationTemplateIdInteger =>
      'Template ID must be an integer.';

  @override
  String get hostCommonCreateFailed =>
      'Create failed. Adjust the inputs and try again.';

  @override
  String get hostCommonSaveFailed =>
      'Save failed. Adjust the inputs and try again.';

  @override
  String get hostCronJobsCreateTask => 'Create task';

  @override
  String get hostCronJobsRefreshFailed => 'Failed to refresh cron jobs.';

  @override
  String get hostCronJobsLastRun => 'Last run';

  @override
  String get hostCronJobsTaskActions => 'Task actions';

  @override
  String get hostCronJobsDeleteTaskTitle => 'Delete Task';

  @override
  String get hostCronJobsNamePlaceholder => 'e.g. Cleanup logs';

  @override
  String get hostCronJobsScriptReplaceHint =>
      'Optional; submitting replaces the stored script';

  @override
  String get hostCronJobsScriptPlaceholder => 'Optional shell script';

  @override
  String get hostCronJobsEditTask => 'Edit task';

  @override
  String get hostCronJobsSaveFailed => 'Failed to save the task.';

  @override
  String get hostCronJobsCreateFailed => 'Failed to create the task.';

  @override
  String get hostBackupsRefreshFailed => 'Failed to refresh backup records.';

  @override
  String get hostBackupsActions => 'Backup actions';

  @override
  String get hostBackupsRestoreUnavailableFailed =>
      'Restore is unavailable for failed backup records.';

  @override
  String get hostBackupsRestoreUnavailableSize =>
      'Restore is unavailable while the file size is unknown.';

  @override
  String get hostBackupsDeleteUnavailableWaiting =>
      'Delete is unavailable while the backup is still waiting.';

  @override
  String get hostBackupsRestoreOverwriteWarning =>
      'This will overwrite the current data and cannot be undone.';

  @override
  String get hostBackupsDeleteRecordTitle => 'Delete Backup Record';

  @override
  String get hostHostSshTitle => 'SSH';

  @override
  String get hostHostSshRefreshFailed =>
      'Failed to refresh the SSH information.';

  @override
  String get hostHostSshNotInstalled =>
      'SSH service is not installed on this server.';

  @override
  String get hostHostSshConfigLoadFailed =>
      'Failed to load the configuration file.';

  @override
  String get hostHostSshConfigEmptyPlaceholder =>
      '# The SSH configuration file does not exist or is empty (/etc/ssh/sshd_config)';

  @override
  String get hostHostSshConfigFileTitle =>
      'Configuration file (/etc/ssh/sshd_config)';

  @override
  String get hostHostSshSaveTitle => 'Save SSH configuration';

  @override
  String get hostHostSshSaveMessage =>
      'This will overwrite /etc/ssh/sshd_config with the edited content.\nAn invalid configuration may make the SSH service unavailable. Continue?';

  @override
  String get hostHostSshSaveFailed => 'Failed to save the SSH configuration.';

  @override
  String get hostToolboxSnapshotRefreshFailed =>
      'Failed to refresh device snapshot.';

  @override
  String get hostToolboxKernelLabel => 'Kernel';

  @override
  String get hostToolboxProductLabel => 'Product';

  @override
  String get hostToolboxTimeZoneLabel => 'Time Zone';

  @override
  String get hostToolboxNtpServerLabel => 'NTP Server';

  @override
  String get hostToolboxSwapOff => 'Off';

  @override
  String get hostToolboxSwapOffHint => 'Swap is disabled on this host.';

  @override
  String get hostToolboxSwapTotalHint => 'Total swap size.';

  @override
  String get hostToolboxDnsPlaceholder => 'e.g. 8.8.8.8';

  @override
  String get hostToolboxDnsVerifyAction => 'Verify';

  @override
  String get hostToolboxDnsReachable => 'DNS reachable';

  @override
  String get hostToolboxDnsEmptyError => 'Enter a DNS server to verify.';

  @override
  String get hostToolboxUsersTitle => 'Users';

  @override
  String get hostAiModelsRefreshFailed => 'Failed to refresh AI models.';

  @override
  String get hostAiModelUnknownName => 'Unknown';

  @override
  String get hostAiConnectionTitle => 'Connection';

  @override
  String get hostAiOllamaNotDetected => 'Ollama not detected on this server.';

  @override
  String get hostAiDomainBoundHint =>
      'Domain bound. Refresh to see connection details.';

  @override
  String get hostAiIpAllowlistLabel =>
      'IP allowlist (optional, comma-separated)';

  @override
  String get hostAiBindDomainFailed => 'Failed to bind domain.';

  @override
  String get hostAiBindFailedRetry =>
      'Bind failed. Adjust the input and try again.';

  @override
  String get hostAiModelActions => 'Model actions';

  @override
  String get hostAiModelRecreateAction => 'Recreate';

  @override
  String get hostAiModelDeleteTitle => 'Delete AI Model';

  @override
  String get hostAiModelCreateFailed => 'Failed to create model.';

  @override
  String get hostAiCreateFailedRetry =>
      'Create failed. Adjust the input and try again.';

  @override
  String get hostCommandsRefreshFailed => 'Failed to refresh commands.';

  @override
  String get hostCommandsRowActions => 'Command actions';

  @override
  String get hostCommandsDeleteTitle => 'Delete Command';

  @override
  String get hostCommandsNameHint => 'e.g. Cleanup logs';

  @override
  String get hostCommandsCommandHint => 'e.g. docker ps -a';

  @override
  String get hostCommandsDefaultGroup => 'Default group';

  @override
  String get hostCommandsCreateFailed => 'Failed to create the command.';

  @override
  String get hostCommandsCreateFormError =>
      'Create failed. Adjust the inputs and try again.';

  @override
  String get hostCommandsCommandRequired => 'Command is required.';

  @override
  String get hostScriptLibraryRefreshFailed => 'Failed to refresh scripts.';

  @override
  String get hostScriptLibraryDeleteSelected => 'Delete selected';

  @override
  String get hostScriptLibraryRowActions => 'Script actions';

  @override
  String get hostScriptLibraryDeleteTitle => 'Delete Script';

  @override
  String get hostScriptLibraryDeleteSelectedTitle => 'Delete Scripts';

  @override
  String get hostLogsRefreshOperationFailed =>
      'Failed to refresh operation logs.';

  @override
  String get hostLogsRefreshLoginFailed => 'Failed to refresh login logs.';

  @override
  String get hostLogsFileNameRequired => 'File name is required.';

  @override
  String get hostLogsRefreshTab => 'Refresh current tab';

  @override
  String get hostLogsFileNameLabel => 'File name';

  @override
  String get hostLogsCoreToggle => 'Core logs';

  @override
  String get hostLogsSystemHint =>
      'Enter a log file name and click Load to view its content.';

  @override
  String get hostSecurityRefreshFailed => 'Failed to refresh firewall rules.';

  @override
  String get hostSecurityAddRule => 'Add rule';

  @override
  String get hostSecurityDeleteRule => 'Delete rule';

  @override
  String get hostSecurityPortHint => 'e.g. 8080';

  @override
  String get hostSecurityAddressHint => 'Leave empty for all addresses';

  @override
  String get hostSecurityAddRuleTitle => 'Add Rule';

  @override
  String get hostSecurityPortNumeric => 'Port must be a number.';

  @override
  String get hostSecurityDeleteRuleTitle => 'Delete Rule';

  @override
  String get hostGatewayRefreshFailed =>
      'Failed to refresh the security gateway snapshot.';

  @override
  String get hostGatewayOpenrestyStatus => 'OpenResty Status';

  @override
  String get hostGatewayHttpsRedirectTitle => 'Default HTTPS redirect';

  @override
  String get hostGatewayHttpsRedirectDescription =>
      'Redirect HTTP to HTTPS for all websites';

  @override
  String get hostGatewayStateUnknown => 'Current state unknown';

  @override
  String get hostGatewayDisable => 'Disable';

  @override
  String get hostGatewayHttpsRedirectEnableTitle =>
      'Enable Default HTTPS Redirect';

  @override
  String get hostGatewayHttpsRedirectDisableTitle =>
      'Disable Default HTTPS Redirect';

  @override
  String get hostGatewayHttpsRedirectEnableMessage =>
      'Enable HTTP→HTTPS redirect for all websites?';

  @override
  String get hostGatewayHttpsRedirectDisableMessage =>
      'Disable HTTP→HTTPS redirect?';

  @override
  String get hostGatewayHttpsRedirectEnableFailed =>
      'Failed to enable the default HTTPS redirect.';

  @override
  String get hostGatewayHttpsRedirectDisableFailed =>
      'Failed to disable the default HTTPS redirect.';

  @override
  String get hostGatewayCertificatePlaceholder =>
      'Paste the full PEM certificate chain';

  @override
  String get hostGatewayPrivateKeyPlaceholder =>
      'Paste the matching PEM private key';

  @override
  String get hostGatewayDescriptionOptional => 'Description (optional)';

  @override
  String get hostGatewayDescriptionPlaceholder =>
      'e.g. *.example.com issued 2026-09';

  @override
  String get hostGatewayCertificateRequired => 'Certificate is required.';

  @override
  String get hostGatewayUploadConfirmMessage =>
      'The certificate will be imported into the panel and becomes available to websites. Continue?';

  @override
  String get hostGatewayUploadFailed => 'Failed to upload the certificate.';

  @override
  String get hostGatewayUploadFormError =>
      'Upload failed. The form reopens with your content; try again.';

  @override
  String get hostGatewayRenewNoId =>
      'This certificate has no id and cannot be renewed.';

  @override
  String get hostGatewayRenew => 'Renew';

  @override
  String get hostGatewayRenewalRequested => 'Renewal requested.';

  @override
  String get hostGatewayExpiresToday => 'Expires today';

  @override
  String get hostGatewayValid => 'Valid';

  @override
  String get hostDashboardRefreshFailed => 'Failed to refresh dashboard.';

  @override
  String get hostDashboardKernelLabel => 'Kernel';

  @override
  String get hostDashboardCpuCoresLabel => 'CPU Cores';

  @override
  String get hostDashboardPanelVersionLabel => 'Panel Version';

  @override
  String get hostMonitoringRefreshFailed =>
      'Failed to refresh monitoring data.';

  @override
  String get hostMonitoringLoadAverage => 'Load Average';

  @override
  String get hostMonitoringLoad1 => 'Load 1';

  @override
  String get hostMonitoringLoad5 => 'Load 5';

  @override
  String get hostMonitoringLoad15 => 'Load 15';

  @override
  String get hostMonitoringLoadWindows => '1/5/15 min';

  @override
  String get hostAuthDeleteConfirm =>
      'Delete this basic authentication user? This cannot be undone.';

  @override
  String get hostAuthDeleteFailed =>
      'Failed to delete the basic authentication user.';

  @override
  String get hostAuthDisableConfirm =>
      'Disable basic authentication for this website?';

  @override
  String get hostAuthEditHelper =>
      'The password cannot be echoed. Editing resets the password.';

  @override
  String get hostAuthEnableConfirm => 'Enable basic authentication for {0}?';

  @override
  String get hostAuthEnableFailed =>
      'Failed to update the basic authentication switch.';

  @override
  String get hostAuthEnableSwitch => 'Enable basic authentication';

  @override
  String get hostAuthLoadFailed =>
      'Failed to load the basic authentication configuration.';

  @override
  String get hostAuthNameRequired => 'Name is required.';

  @override
  String get hostAuthPasswordInvalid =>
      'Password may only contain letters, digits and _-.@\$!%*?& (max 72 characters).';

  @override
  String get hostAuthPasswordRequired => 'Password is required.';

  @override
  String get hostAuthPathDeleteConfirm =>
      'Delete path authentication rule {0}? This cannot be undone.';

  @override
  String get hostAuthPathEmpty => 'No path authentication rules';

  @override
  String get hostAuthPathRequired => 'Path is required.';

  @override
  String get hostAuthRandom => 'Random';

  @override
  String get hostAuthRemark => 'Remark';

  @override
  String get hostAuthSaveFailed => 'Failed to update the basic authentication.';

  @override
  String get hostAuthSaved => 'Basic authentication updated.';

  @override
  String get hostAuthScopeGlobal => 'Global';

  @override
  String get hostAuthUsernameRequired => 'Username is required.';

  @override
  String get hostCorsAllowCredentials => 'Allow cookies to be sent';

  @override
  String get hostCorsAllowHeaders => 'Allowed request headers';

  @override
  String get hostCorsAllowMethods => 'Allowed request methods';

  @override
  String get hostCorsAllowOrigins => 'Allowed domains';

  @override
  String get hostCorsEnable => 'Enable CORS';

  @override
  String get hostCorsLoadFailed => 'Failed to load the CORS configuration.';

  @override
  String get hostCorsOriginsRequired =>
      'Allowed domains is required when CORS is enabled.';

  @override
  String get hostCorsPreflight => 'Preflight request fast response';

  @override
  String get hostCorsPreflightHelper =>
      'Answers cross-origin OPTIONS preflight requests automatically with 204 and the CORS headers';

  @override
  String get hostCorsSaveConfirm => 'Save the CORS configuration for {0}?';

  @override
  String get hostCorsSaveFailed => 'Failed to save the CORS configuration.';

  @override
  String get hostCorsSaved => 'CORS configuration saved.';

  @override
  String get hostDomainsActionsLabel => 'Actions';

  @override
  String get hostDomainsAddFailed => 'Failed to add domains.';

  @override
  String get hostDomainsAddSuccess => 'Domains added.';

  @override
  String get hostDomainsDeleteConfirm =>
      'Delete domain {0}? This action cannot be undone.';

  @override
  String get hostDomainsDeleteFailed => 'Failed to delete domain.';

  @override
  String get hostDomainsDeleteSuccess => 'Domain deleted.';

  @override
  String get hostDomainsDeleteTitle => 'Delete domain';

  @override
  String get hostDomainsInputHint =>
      'One domain per line. All entries share the port and SSL option below.';

  @override
  String get hostDomainsInputRequired => 'Enter at least one domain.';

  @override
  String get hostDomainsLastDeleteDisabled =>
      'At least one domain must remain.';

  @override
  String get hostDomainsLoadFailed => 'Failed to load domains.';

  @override
  String get hostHttpsAlgorithmLabel => 'Encryption algorithm';

  @override
  String get hostHttpsAlgorithmRequired => 'Encryption algorithm is required.';

  @override
  String get hostHttpsCertEmpty =>
      'No certificates available. Import one from the SSL certificate page first.';

  @override
  String get hostHttpsCertLoadFailed => 'Failed to load certificates.';

  @override
  String get hostHttpsCertRequired =>
      'Certificate and private key are required.';

  @override
  String get hostHttpsCertSelectPlaceholder => 'Select certificate';

  @override
  String get hostHttpsCertificateLabel => 'Certificate';

  @override
  String get hostHttpsDisableConfirm =>
      'Disabling HTTPS will delete the certificate related configuration. Continue?';

  @override
  String get hostHttpsDisableTitle => 'Disable HTTPS';

  @override
  String get hostHttpsHelper =>
      'Note: Do not use SSL certificates for illegal websites.\nIf HTTPS access cannot be used after enabling, check whether the firewall has released port 443.';

  @override
  String get hostHttpsHstsHelper =>
      'Enabling HSTS can increase website security';

  @override
  String get hostHttpsHstsSubDomainsLabel => 'HSTS include subdomains';

  @override
  String get hostHttpsHttp3Helper =>
      'HTTP/3 offers faster connections, but not all browsers support it; enabling it may make the site unreachable for some browsers.';

  @override
  String get hostHttpsHttp3Label => 'HTTP3';

  @override
  String get hostHttpsHttpConfigAlso => 'Allow direct HTTP requests';

  @override
  String get hostHttpsHttpConfigLabel => 'HTTP options';

  @override
  String get hostHttpsHttpConfigOnly => 'Block HTTP requests';

  @override
  String get hostHttpsHttpConfigToHttps => 'Redirect to HTTPS';

  @override
  String get hostHttpsInsecureSuffix => '(not safe)';

  @override
  String get hostHttpsIpWarn =>
      'Websites with IP as domain names need to be set as default site to be accessed normally.';

  @override
  String get hostHttpsLoadFailed => 'Failed to load HTTPS configuration.';

  @override
  String get hostHttpsPortLabel => 'HTTPS port';

  @override
  String get hostHttpsPrivateKeyLabel => 'Private key';

  @override
  String get hostHttpsProtocolLabel => 'Protocol version';

  @override
  String get hostHttpsProtocolRequired =>
      'Select at least one TLS protocol version.';

  @override
  String get hostHttpsSaveConfirm => 'Apply the HTTPS configuration to {0}?';

  @override
  String get hostHttpsSaveConfirmTitle => 'Save HTTPS settings';

  @override
  String get hostHttpsSectionAdvanced => 'Protocol settings';

  @override
  String get hostHttpsSectionBasic => 'Basic';

  @override
  String get hostHttpsSectionCert => 'Certificate settings';

  @override
  String get hostHttpsSelectCertRequired => 'Please select a certificate.';

  @override
  String get hostHttpsTypeExisted => 'Existing certificate';

  @override
  String get hostHttpsTypeLabel => 'SSL options';

  @override
  String get hostHttpsTypeManual => 'Import certificate manually';

  @override
  String get hostLeechAccessDomains => 'Allowed domains';

  @override
  String get hostLeechBlockedHelper =>
      'When Allow empty referrer is on, requests without a Referer are not blocked; this also allows any Referer not starting with http/https';

  @override
  String get hostLeechBlockedRef => 'Allow non-standard Referer';

  @override
  String get hostLeechBrowserCache => 'Browser Cache';

  @override
  String get hostLeechCacheControl => 'Cache control';

  @override
  String get hostLeechCacheTime => 'Browser Cache Time';

  @override
  String get hostLeechCacheTimeHelper =>
      'The time static resources are cached locally in the browser, reducing redundant requests';

  @override
  String get hostLeechCacheTimeInvalid =>
      'Cache time must be an integer between 1 and 65535.';

  @override
  String get hostLeechDomainsHelper => 'One domain per line';

  @override
  String get hostLeechDomainsRequired =>
      'At least one allowed domain is required when enabled.';

  @override
  String get hostLeechEnable => 'Enable';

  @override
  String get hostLeechExtends => 'File extensions';

  @override
  String get hostLeechLoadFailed =>
      'Failed to load the anti-leech configuration.';

  @override
  String get hostLeechLogEnable => 'Log static asset requests';

  @override
  String get hostLeechLogHelper =>
      'Logs static asset requests; usually disabled in production to avoid noisy logs';

  @override
  String get hostLeechNoneRef => 'Allow empty referrer';

  @override
  String get hostLeechReturn => 'Response resource';

  @override
  String get hostLeechReturnHelper =>
      'HTTP status code returned after blocking hotlinking requests';

  @override
  String get hostLeechSaveConfirm =>
      'Save the anti-leech configuration for {0}?';

  @override
  String get hostLeechSaveFailed =>
      'Failed to save the anti-leech configuration.';

  @override
  String get hostLeechSaved => 'Anti-leech configuration saved.';

  @override
  String get hostLogsAccessLog => 'Website logs';

  @override
  String get hostLogsErrorLog => 'Error log';

  @override
  String get hostLogsLoadFailed => 'Failed to load the website log.';

  @override
  String get hostLogsRefreshFailed => 'Failed to refresh the website log.';

  @override
  String get hostLogsStateHint =>
      'Log switch state (read-only in this release)';

  @override
  String get hostProxyAdd => 'Add Proxy';

  @override
  String get hostProxyAddressPlaceholder => 'e.g. 127.0.0.1:8080';

  @override
  String get hostProxyAddressRequired => 'Target address is required.';

  @override
  String get hostProxyAllowCredentials => 'Allow credentials';

  @override
  String get hostProxyAllowHeaders => 'Allow headers';

  @override
  String get hostProxyAllowMethods => 'Allow methods';

  @override
  String get hostProxyAllowOrigins => 'Allow origins';

  @override
  String get hostProxyBrowserCache => 'Browser cache';

  @override
  String get hostProxyBrowserCacheNoModify => 'No modify';

  @override
  String get hostProxyBrowserCacheTime => 'Cache time';

  @override
  String get hostProxyBrowserCacheTimeHelper =>
      'How long browsers may cache responses.';

  @override
  String get hostProxyCacheSection => 'Cache';

  @override
  String get hostProxyCacheTimeInvalid =>
      'Cache time must be a number between 1 and 65535.';

  @override
  String get hostProxyCancelEdit => 'Cancel edit';

  @override
  String get hostProxyCors => 'Enable CORS';

  @override
  String get hostProxyCorsSection => 'CORS';

  @override
  String get hostProxyDeleteConfirmMessage =>
      'Delete proxy {0}? The proxy config file will be removed.';

  @override
  String get hostProxyDeleteConfirmTitle => 'Delete proxy';

  @override
  String get hostProxyDeleteFailed => 'Failed to delete the proxy.';

  @override
  String get hostProxyDeleted => 'Proxy deleted.';

  @override
  String get hostProxyDisable => 'Disable';

  @override
  String get hostProxyDisabled => 'disabled';

  @override
  String get hostProxyEditTitle => 'Edit Proxy';

  @override
  String get hostProxyEmpty => 'No proxy rules yet.';

  @override
  String get hostProxyHost => 'Proxy host';

  @override
  String get hostProxyHostHelper =>
      'Host header sent upstream; \$host keeps the original domain.';

  @override
  String get hostProxyHostRequired => 'Proxy host is required.';

  @override
  String get hostProxyListTitle => 'Proxy rules';

  @override
  String get hostProxyLoadFailed => 'Failed to load the proxy list.';

  @override
  String get hostProxyMatch => 'Proxy path';

  @override
  String get hostProxyMatchRequired => 'Proxy path is required.';

  @override
  String get hostProxyNameRequired => 'Name is required.';

  @override
  String get hostProxyOriginsRequired =>
      'Allow origins is required when CORS is enabled.';

  @override
  String get hostProxyPass => 'Target address';

  @override
  String get hostProxyPassHelper =>
      'Upstream address the requests are forwarded to.';

  @override
  String get hostProxyPreflight => 'Preflight';

  @override
  String get hostProxySaveFailed => 'Failed to save the proxy.';

  @override
  String get hostProxyServerCache => 'Server cache';

  @override
  String get hostProxyServerCacheTime => 'Cache time';

  @override
  String get hostProxyServerCacheTimeHelper =>
      'How long upstream responses stay in the server cache.';

  @override
  String get hostProxySni => 'SNI';

  @override
  String get hostProxySniHelper =>
      'Send the server name to the HTTPS upstream (proxy_ssl_server_name).';

  @override
  String get hostProxySslVerify => 'SSL verify';

  @override
  String get hostProxySslVerifyHelper =>
      'Verify the upstream certificate when proxying over HTTPS.';

  @override
  String get hostProxyStatusFailed => 'Failed to update the proxy status.';

  @override
  String get hostProxyStatusUpdated => 'Proxy status updated.';

  @override
  String get hostRedirectAdd => 'Add Redirect';

  @override
  String get hostRedirectCancelEdit => 'Cancel edit';

  @override
  String get hostRedirectDeleteConfirmMessage => 'Delete redirect {0}?';

  @override
  String get hostRedirectDeleteConfirmTitle => 'Delete redirect';

  @override
  String get hostRedirectDeleteFailed => 'Failed to delete the redirect.';

  @override
  String get hostRedirectDeleted => 'Redirect deleted.';

  @override
  String get hostRedirectDisable => 'Disable';

  @override
  String get hostRedirectDomains => 'Domains';

  @override
  String get hostRedirectDomainsHelper => 'One domain per line.';

  @override
  String get hostRedirectDomainsPlaceholder =>
      'One domain per line, e.g. old.example.com';

  @override
  String get hostRedirectDomainsRequired => 'At least one domain is required.';

  @override
  String get hostRedirectEditTitle => 'Edit Redirect';

  @override
  String get hostRedirectEmpty => 'No redirect rules yet.';

  @override
  String get hostRedirectKeep => 'keep path';

  @override
  String get hostRedirectKeepPath => 'Keep path';

  @override
  String get hostRedirectKeepPathHelper =>
      'Append the original request path to the target URL.';

  @override
  String get hostRedirectListTitle => 'Redirect rules';

  @override
  String get hostRedirectLoadFailed => 'Failed to load the redirect list.';

  @override
  String get hostRedirectNameRequired => 'Name is required.';

  @override
  String get hostRedirectNotKeep => 'drop path';

  @override
  String get hostRedirectPathRequired => 'Path is required.';

  @override
  String get hostRedirectSaveFailed => 'Failed to save the redirect.';

  @override
  String get hostRedirectStatusFailed =>
      'Failed to update the redirect status.';

  @override
  String get hostRedirectStatusUpdated => 'Redirect status updated.';

  @override
  String get hostRedirectTarget => 'Target URL';

  @override
  String get hostRedirectTargetRequired => 'Target URL is required.';

  @override
  String get hostRedirectTypeDomain => 'Domain';

  @override
  String get hostRedirectTypePath => 'Path';

  @override
  String get hostRedirectWay => 'Redirect';

  @override
  String get hostRedirectWayHelper => '301 is permanent, 302 is temporary.';

  @override
  String get hostRewriteCardTitle => 'Rewrite rules';

  @override
  String get hostRewriteContentPlaceholder => '# nginx rewrite rules';

  @override
  String get hostRewriteCurrent => 'Current';

  @override
  String get hostRewriteHelper =>
      'Saved rules take effect once nginx reloads, which happens automatically after saving.';

  @override
  String get hostRewriteHelper2 =>
      'Modifying rewrite rules may affect how the website resolves.';

  @override
  String get hostRewriteLoadFailed => 'Failed to load the rewrite content.';

  @override
  String get hostRewriteMode => 'Rewrite mode';

  @override
  String get hostRewriteSaveAndReload => 'Save and reload';

  @override
  String get hostRewriteSaveConfirmMessage =>
      'Save the rewrite rules for {0} and reload nginx?';

  @override
  String get hostRewriteSaveFailed => 'Failed to save the rewrite rules.';

  @override
  String get hostRewriteSaved => 'Rewrite rules saved and nginx reloaded.';

  @override
  String get hostWebsiteConfigBack => 'Back to websites';

  @override
  String get hostWebsiteTabPlaceholder =>
      'This module will be provided in a later batch.';

  @override
  String get hostWebsitesConfig => 'Config';

  @override
  String get hostWebsitesConfigHint => 'Website configuration';

  @override
  String get hostHttpsTabTitle => 'HTTPS';

  @override
  String get hostDomainsTabTitle => 'Domains';

  @override
  String get hostWebsiteTabProxy => 'Reverse Proxy';

  @override
  String get hostWebsiteTabRedirect => 'Redirect';

  @override
  String get hostWebsiteTabRewrite => 'Rewrite';

  @override
  String get hostWebsiteTabCors => 'CORS';

  @override
  String get hostWebsiteTabAntiLeech => 'Anti-Leech';

  @override
  String get hostWebsiteTabBasicAuth => 'Basic Auth';

  @override
  String get hostWebsiteTabLogs => 'Logs';

  @override
  String get hostFilesEditorBack => 'Back to files';

  @override
  String get hostFilesEditorLoadFailed => 'Failed to load file content.';

  @override
  String get hostFilesEditorSaveConfirm => 'Save changes to {0}?';

  @override
  String get hostFilesSearchNoMatch => 'No matching files.';

  @override
  String get hostFilesPasteAction => 'Paste';

  @override
  String get hostFilesCutAction => 'Cut';

  @override
  String get hostFilesPermissionLabel => 'Permissions';

  @override
  String get hostFilesFileNamePlaceholder => 'File name';

  @override
  String get hostFilesFileNameEmpty => 'File name cannot be empty.';

  @override
  String get hostFilesCreateFileFailed => 'Failed to create file {0}.';

  @override
  String get hostFilesRenameFailed => 'Failed to rename {0}.';

  @override
  String get hostFilesCutToast => 'Cut. Paste it in the target directory.';

  @override
  String get hostFilesCopyToast => 'Copied. Paste it in the target directory.';

  @override
  String get hostFilesPasteFailed => 'Paste failed.';

  @override
  String get hostFilesDestinationLabel => 'Destination directory';

  @override
  String get hostFilesCompressFailed => 'Failed to compress {0}.';

  @override
  String get hostFilesModePlaceholder => 'e.g. 755';

  @override
  String get hostFilesModeInvalid =>
      'Enter a 3-digit octal permission (e.g. 755).';

  @override
  String get hostFilesModeFailed => 'Failed to change permissions of {0}.';

  @override
  String get hostFilesFavoriteFailed => 'Failed to add favorite.';

  @override
  String get hostAiAccountsAddAction => 'Add account';

  @override
  String get hostAiAccountsTitle => 'Agent Accounts';

  @override
  String get hostAiAccountProviderLabel => 'Provider';

  @override
  String get hostAiAccountApiTypeLabel => 'API Type';

  @override
  String get hostAiAccountBaseUrlLabel => 'Base URL';

  @override
  String get hostAiAccountApiKeyLabel => 'API Key';

  @override
  String get hostAiAccountRemarkLabel => 'Remark';

  @override
  String get hostAiAccountsRefreshFailed => 'Failed to refresh agent accounts.';

  @override
  String get hostAiAccountsEmpty => 'No agent accounts yet.';

  @override
  String get hostAiAccountProviderRequired => 'Provider is required.';

  @override
  String get hostAiAccountNameRequired => 'Name is required.';

  @override
  String get hostAiAccountApiTypeRequired => 'API type is required.';

  @override
  String get hostAiAccountBaseUrlRequired => 'Base URL is required.';

  @override
  String get hostAiAccountApiKeyRequired => 'API Key is required.';

  @override
  String get hostAiAccountsSaved => 'Agent account saved.';

  @override
  String get hostAiAccountsUpdateFailed =>
      'Failed to update the agent account.';

  @override
  String get hostAiAccountsCreateFailed =>
      'Failed to create the agent account.';

  @override
  String get hostAiAccountsSaveFailedRetry =>
      'Save failed. Adjust the input and try again.';

  @override
  String get hostAiAccountDeleteConfirm =>
      'Delete agent account {0}? This cannot be undone.';

  @override
  String get hostAiAccountsDeleted => 'Agent account deleted.';

  @override
  String get hostAiAccountsDeleteFailed =>
      'Failed to delete the agent account.';

  @override
  String get hostAiAccountsLoadFailed => 'Failed to load agent accounts.';

  @override
  String get hostAiGpuEmpty => 'No GPU detected on this server.';

  @override
  String get hostAiGpuRefreshFailed => 'Failed to refresh the GPU status.';

  @override
  String get hostAiGpuDriverVersion => 'Driver Version';

  @override
  String get hostAiGpuCudaVersion => 'CUDA Version';

  @override
  String get hostAiGpuTitle => 'GPU';

  @override
  String get hostAiGpuUnknownDevice => 'Unknown device';

  @override
  String get hostAiGpuUtilization => 'GPU Utilization';

  @override
  String get hostAiGpuTemperature => 'Temperature';

  @override
  String get hostAiGpuPerformanceState => 'Performance State';

  @override
  String get hostAiGpuPowerUsage => 'Power Usage';

  @override
  String get hostAiGpuMemoryUsage => 'Memory Usage';

  @override
  String get hostAiGpuFanSpeed => 'Fan Speed';

  @override
  String get hostAiGpuBusId => 'Bus ID';

  @override
  String get hostAiGpuPersistenceMode => 'Persistence Mode';

  @override
  String get hostAiGpuDisplayActive => 'Display Active';

  @override
  String get hostAiGpuEcc => 'Uncorr. ECC';

  @override
  String get hostAiGpuComputeMode => 'Compute Mode';

  @override
  String get hostAiGpuMigMode => 'MIG Mode';

  @override
  String get hostAiGpuMemoryUtilization => 'Memory Utilization';

  @override
  String get hostAiGpuFrequency => 'Frequency';

  @override
  String get hostAiGpuProcesses => 'Processes';

  @override
  String get hostAiGpuShr => 'Shared Mem';

  @override
  String get hostAiGpuProcessName => 'Process Name';

  @override
  String get hostAiGpuProcessMemory => 'Memory Usage';

  @override
  String get hostAiGpuProcessTypeC => 'Compute';

  @override
  String get hostAiGpuProcessTypeG => 'Graphics';

  @override
  String get hostAiGpuProcessTypeCG => 'Compute+Graphics';

  @override
  String get hostAiGpuLoadFailed => 'Failed to load the GPU status.';

  @override
  String get hostAiMcpLoadFailed => 'Failed to load MCP servers.';

  @override
  String get hostAiMcpTestConnection => 'Test connection';

  @override
  String get hostAiMcpOperateConfirm =>
      'Are you sure to {0} the MCP server {1}?';

  @override
  String get hostAiMcpOperationSuccess => 'Operation completed.';

  @override
  String get hostAiMcpOperationFailed => 'MCP server operation failed.';

  @override
  String get hostAiMcpTestSuccess => 'Connection test passed.';

  @override
  String get hostAiMcpTestFailed => 'Connection test failed.';

  @override
  String get hostAiMcpDeleteFailed => 'Failed to delete the MCP server.';

  @override
  String get hostAiMcpUrlRequired => 'Enter the base URL.';

  @override
  String get hostAiMcpPathRequired => 'Enter the transport path.';

  @override
  String get hostAiMcpContainerRequired => 'Enter a container name.';

  @override
  String get hostAiMcpImageRequired => 'Enter the gateway image.';

  @override
  String get hostAiMcpCreateFailed => 'Failed to create the MCP server.';

  @override
  String get hostAiMcpStatusError => 'Error';

  @override
  String get hostAiAgentTypeHermes => 'Hermes Agent';

  @override
  String get hostAiAgentCreateFailed =>
      'Agent creation failed or timed out. The installation may still be running on the server - wait patiently or check the server task list.';

  @override
  String get hostAiAgentLoadFailed => 'Failed to load agents.';

  @override
  String get hostAiAgentOverviewFailed => 'Failed to load the agent overview.';

  @override
  String get hostAiAgentDefaultModelLabel => 'Default model';

  @override
  String get hostAiAgentJobCountLabel => 'Jobs';

  @override
  String get hostAiAgentSessionCountLabel => 'Sessions';

  @override
  String get hostAiAgentDeleteConfirm =>
      'Delete agent {0}? This action cannot be undone.';

  @override
  String get hostAiAgentOperationSuccess => 'Operation completed.';

  @override
  String get hostAiAgentDeleteFailed => 'Failed to delete the agent.';

  @override
  String get hostAiAgentStatusError => 'Error';
}
