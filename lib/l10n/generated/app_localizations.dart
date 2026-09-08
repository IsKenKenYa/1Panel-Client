import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'1Panel Client'**
  String get appName;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commonImport;

  /// No description provided for @commonExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get commonExport;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get commonLoad;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get commonSaveSuccess;

  /// No description provided for @commonSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get commonSaveFailed;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get commonUpload;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonComingSoon;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get commonEmpty;

  /// No description provided for @commonLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get commonLoadFailedTitle;

  /// No description provided for @websitesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Websites'**
  String get websitesPageTitle;

  /// No description provided for @websitesStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get websitesStatsTitle;

  /// No description provided for @websitesStatsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get websitesStatsTotal;

  /// No description provided for @websitesStatsRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get websitesStatsRunning;

  /// No description provided for @websitesStatsStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get websitesStatsStopped;

  /// No description provided for @websitesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No websites'**
  String get websitesEmptyTitle;

  /// No description provided for @websitesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a website in 1Panel first.'**
  String get websitesEmptySubtitle;

  /// No description provided for @websitesUnknownDomain.
  ///
  /// In en, this message translates to:
  /// **'Unknown website'**
  String get websitesUnknownDomain;

  /// No description provided for @websitesStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get websitesStatusLabel;

  /// No description provided for @websitesTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get websitesTypeLabel;

  /// No description provided for @websitesStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get websitesStatusRunning;

  /// No description provided for @websitesStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get websitesStatusStopped;

  /// No description provided for @websitesActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get websitesActionStart;

  /// No description provided for @websitesActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get websitesActionStop;

  /// No description provided for @websitesActionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get websitesActionRestart;

  /// No description provided for @websitesActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get websitesActionDelete;

  /// No description provided for @websitesSetDefaultAction.
  ///
  /// In en, this message translates to:
  /// **'Set Default'**
  String get websitesSetDefaultAction;

  /// No description provided for @websitesDefaultServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Default server'**
  String get websitesDefaultServerLabel;

  /// No description provided for @websitesGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get websitesGroupLabel;

  /// No description provided for @websitesRemarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get websitesRemarkLabel;

  /// No description provided for @websitesAliasLabel.
  ///
  /// In en, this message translates to:
  /// **'Alias'**
  String get websitesAliasLabel;

  /// No description provided for @websitesPrimaryDomainLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary domain'**
  String get websitesPrimaryDomainLabel;

  /// No description provided for @websitesProxyAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Proxy address'**
  String get websitesProxyAddressLabel;

  /// No description provided for @websitesProxyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Proxy type'**
  String get websitesProxyTypeLabel;

  /// No description provided for @websitesParentWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent website'**
  String get websitesParentWebsiteLabel;

  /// No description provided for @websitesSiteDirLabel.
  ///
  /// In en, this message translates to:
  /// **'Site directory'**
  String get websitesSiteDirLabel;

  /// No description provided for @websitesFilterAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get websitesFilterAllGroups;

  /// No description provided for @websitesFilterAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get websitesFilterAllTypes;

  /// No description provided for @websitesSelectionEnable.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get websitesSelectionEnable;

  /// No description provided for @websitesSelectionDisable.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get websitesSelectionDisable;

  /// No description provided for @websitesSetGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Set Group'**
  String get websitesSetGroupAction;

  /// No description provided for @websitesLifecycleCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Website'**
  String get websitesLifecycleCreateTitle;

  /// No description provided for @websitesLifecycleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Website'**
  String get websitesLifecycleEditTitle;

  /// No description provided for @websitesLifecycleTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Website type'**
  String get websitesLifecycleTypeLabel;

  /// No description provided for @websitesLifecycleTypeRuntime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get websitesLifecycleTypeRuntime;

  /// No description provided for @websitesLifecycleTypeProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get websitesLifecycleTypeProxy;

  /// No description provided for @websitesLifecycleTypeSubsite.
  ///
  /// In en, this message translates to:
  /// **'Subsite'**
  String get websitesLifecycleTypeSubsite;

  /// No description provided for @websitesLifecycleTypeStatic.
  ///
  /// In en, this message translates to:
  /// **'Static'**
  String get websitesLifecycleTypeStatic;

  /// No description provided for @websitesValidationGroupRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a website group.'**
  String get websitesValidationGroupRequired;

  /// No description provided for @websitesValidationPrimaryDomainRequired.
  ///
  /// In en, this message translates to:
  /// **'Primary domain is required.'**
  String get websitesValidationPrimaryDomainRequired;

  /// No description provided for @websitesValidationAliasRequired.
  ///
  /// In en, this message translates to:
  /// **'Alias is required.'**
  String get websitesValidationAliasRequired;

  /// No description provided for @websitesValidationRuntimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a runtime.'**
  String get websitesValidationRuntimeRequired;

  /// No description provided for @websitesValidationProxyRequired.
  ///
  /// In en, this message translates to:
  /// **'Proxy address is required.'**
  String get websitesValidationProxyRequired;

  /// No description provided for @websitesValidationParentRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a parent website.'**
  String get websitesValidationParentRequired;

  /// No description provided for @websitesOperateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get websitesOperateSuccess;

  /// No description provided for @websitesOperateFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get websitesOperateFailed;

  /// No description provided for @websitesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String websitesSelectedCount(int count);

  /// No description provided for @websitesLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'{error}'**
  String websitesLoadFailedMessage(String error);

  /// No description provided for @websitesDefaultName.
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get websitesDefaultName;

  /// No description provided for @websitesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete website'**
  String get websitesDeleteTitle;

  /// No description provided for @websitesDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {domain}? This action cannot be undone.'**
  String websitesDeleteMessage(String domain);

  /// No description provided for @websitesDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Website deleted'**
  String get websitesDeleteSuccess;

  /// No description provided for @websitesBatchDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} websites? This action cannot be undone.'**
  String websitesBatchDeleteMessage(int count);

  /// No description provided for @websitesDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get websitesDetailTitle;

  /// No description provided for @websitesTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get websitesTabOverview;

  /// No description provided for @websitesTabConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get websitesTabConfig;

  /// No description provided for @websitesTabDomains.
  ///
  /// In en, this message translates to:
  /// **'Domains'**
  String get websitesTabDomains;

  /// No description provided for @websitesTabSsl.
  ///
  /// In en, this message translates to:
  /// **'SSL'**
  String get websitesTabSsl;

  /// No description provided for @websitesTabRewrite.
  ///
  /// In en, this message translates to:
  /// **'Rewrite'**
  String get websitesTabRewrite;

  /// No description provided for @websitesTabProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get websitesTabProxy;

  /// No description provided for @websitesSslInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get websitesSslInfoTitle;

  /// No description provided for @websitesSslNoCert.
  ///
  /// In en, this message translates to:
  /// **'No certificate bound'**
  String get websitesSslNoCert;

  /// No description provided for @websitesSslPrimaryDomain.
  ///
  /// In en, this message translates to:
  /// **'Primary domain'**
  String get websitesSslPrimaryDomain;

  /// No description provided for @websitesSslExpireDate.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get websitesSslExpireDate;

  /// No description provided for @websitesSslStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get websitesSslStatus;

  /// No description provided for @websitesSslAutoRenew.
  ///
  /// In en, this message translates to:
  /// **'Auto renew'**
  String get websitesSslAutoRenew;

  /// No description provided for @websitesSslDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get websitesSslDownload;

  /// No description provided for @websitesConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Nginx config content'**
  String get websitesConfigHint;

  /// No description provided for @websitesJsonHint.
  ///
  /// In en, this message translates to:
  /// **'JSON content'**
  String get websitesJsonHint;

  /// No description provided for @websitesDomainAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add domain'**
  String get websitesDomainAddTitle;

  /// No description provided for @websitesDomainEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit domain'**
  String get websitesDomainEditTitle;

  /// No description provided for @websitesDomainLabel.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get websitesDomainLabel;

  /// No description provided for @websitesDomainEmpty.
  ///
  /// In en, this message translates to:
  /// **'No domains'**
  String get websitesDomainEmpty;

  /// No description provided for @websitesDomainDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get websitesDomainDefault;

  /// No description provided for @websitesDomainSslLabel.
  ///
  /// In en, this message translates to:
  /// **'SSL'**
  String get websitesDomainSslLabel;

  /// No description provided for @websitesDomainValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Domain is required.'**
  String get websitesDomainValidationRequired;

  /// No description provided for @websitesDomainValidationPort.
  ///
  /// In en, this message translates to:
  /// **'Port must be between 1 and 65535.'**
  String get websitesDomainValidationPort;

  /// No description provided for @websitesDomainValidationDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This domain already exists.'**
  String get websitesDomainValidationDuplicate;

  /// No description provided for @websitesDomainBatchAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch add domains'**
  String get websitesDomainBatchAddTitle;

  /// No description provided for @websitesDomainBatchAddAction.
  ///
  /// In en, this message translates to:
  /// **'Import domains'**
  String get websitesDomainBatchAddAction;

  /// No description provided for @websitesDomainBatchAddHint.
  ///
  /// In en, this message translates to:
  /// **'One domain per line. You can use domain or domain:port.'**
  String get websitesDomainBatchAddHint;

  /// No description provided for @websitesDomainBatchInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Domains'**
  String get websitesDomainBatchInputLabel;

  /// No description provided for @websitesDomainBatchValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one domain.'**
  String get websitesDomainBatchValidationEmpty;

  /// No description provided for @websitesDomainBatchValidationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid domain line: {line}'**
  String websitesDomainBatchValidationInvalid(String line);

  /// No description provided for @websitesDomainDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete domain {domain}?'**
  String websitesDomainDeleteMessage(String domain);

  /// No description provided for @websitesRewriteNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Rewrite name'**
  String get websitesRewriteNameLabel;

  /// No description provided for @websitesRewriteHint.
  ///
  /// In en, this message translates to:
  /// **'Rewrite content'**
  String get websitesRewriteHint;

  /// No description provided for @websitesProxyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Proxy name'**
  String get websitesProxyNameLabel;

  /// No description provided for @websitesProxyHint.
  ///
  /// In en, this message translates to:
  /// **'Proxy content'**
  String get websitesProxyHint;

  /// No description provided for @websitesNginxAdvancedAction.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get websitesNginxAdvancedAction;

  /// No description provided for @websitesNginxAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Nginx Config'**
  String get websitesNginxAdvancedTitle;

  /// No description provided for @websitesNginxScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scope Load'**
  String get websitesNginxScopeTitle;

  /// No description provided for @websitesNginxScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get websitesNginxScopeLabel;

  /// No description provided for @websitesNginxScopeWebsiteIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Website ID (optional)'**
  String get websitesNginxScopeWebsiteIdLabel;

  /// No description provided for @websitesNginxScopeLoad.
  ///
  /// In en, this message translates to:
  /// **'Load scope config'**
  String get websitesNginxScopeLoad;

  /// No description provided for @websitesNginxScopeResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope result'**
  String get websitesNginxScopeResultLabel;

  /// No description provided for @websitesNginxUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Scope Update'**
  String get websitesNginxUpdateTitle;

  /// No description provided for @websitesNginxUpdateOperateLabel.
  ///
  /// In en, this message translates to:
  /// **'Operate'**
  String get websitesNginxUpdateOperateLabel;

  /// No description provided for @websitesNginxUpdateScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get websitesNginxUpdateScopeLabel;

  /// No description provided for @websitesNginxUpdateWebsiteIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Website ID (optional)'**
  String get websitesNginxUpdateWebsiteIdLabel;

  /// No description provided for @websitesNginxUpdateParamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Params JSON'**
  String get websitesNginxUpdateParamsLabel;

  /// No description provided for @websitesNginxUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Apply update'**
  String get websitesNginxUpdateAction;

  /// No description provided for @websitesProtocolLabel.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get websitesProtocolLabel;

  /// No description provided for @websitesDetailInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Website info'**
  String get websitesDetailInfoTitle;

  /// No description provided for @websitesSitePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Site path'**
  String get websitesSitePathLabel;

  /// No description provided for @websitesRuntimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get websitesRuntimeLabel;

  /// No description provided for @websitesSslStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'SSL status'**
  String get websitesSslStatusLabel;

  /// No description provided for @websitesSslExpireLabel.
  ///
  /// In en, this message translates to:
  /// **'SSL expires'**
  String get websitesSslExpireLabel;

  /// No description provided for @websitesDetailActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get websitesDetailActionsTitle;

  /// No description provided for @websitesConfigPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get websitesConfigPageTitle;

  /// No description provided for @websitesConfigPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nginx config & PHP version'**
  String get websitesConfigPageSubtitle;

  /// No description provided for @websitesBasicConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get websitesBasicConfigTitle;

  /// No description provided for @websitesBasicConfigDatabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Database binding'**
  String get websitesBasicConfigDatabaseTitle;

  /// No description provided for @websitesDomainsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Domains'**
  String get websitesDomainsPageTitle;

  /// No description provided for @websitesDomainsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bind and manage domains'**
  String get websitesDomainsPageSubtitle;

  /// No description provided for @websitesSslPageTitle.
  ///
  /// In en, this message translates to:
  /// **'SSL certificates'**
  String get websitesSslPageTitle;

  /// No description provided for @websitesSslPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate settings & HTTPS'**
  String get websitesSslPageSubtitle;

  /// No description provided for @websitesOpenrestySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Service status & module management'**
  String get websitesOpenrestySubtitle;

  /// No description provided for @websitesConfigEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Nginx config file'**
  String get websitesConfigEditorTitle;

  /// No description provided for @websitesConfigScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced config'**
  String get websitesConfigScopeTitle;

  /// No description provided for @websitesConfigScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get websitesConfigScopeLabel;

  /// No description provided for @websitesConfigScopeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scope config'**
  String get websitesConfigScopeEmpty;

  /// No description provided for @websitesConfigScopeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name} params'**
  String websitesConfigScopeEditTitle(String name);

  /// No description provided for @websitesConfigScopeValuesLabel.
  ///
  /// In en, this message translates to:
  /// **'Param list'**
  String get websitesConfigScopeValuesLabel;

  /// No description provided for @websitesConfigScopeValuesHint.
  ///
  /// In en, this message translates to:
  /// **'Separate multiple params with commas'**
  String get websitesConfigScopeValuesHint;

  /// No description provided for @websitesPhpVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'PHP version'**
  String get websitesPhpVersionTitle;

  /// No description provided for @websitesPhpRuntimeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Runtime ID'**
  String get websitesPhpRuntimeIdLabel;

  /// No description provided for @websitesPhpRuntimeIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the runtime ID to switch'**
  String get websitesPhpRuntimeIdHint;

  /// No description provided for @websitesDomainPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get websitesDomainPortLabel;

  /// No description provided for @websitesDomainPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary domain'**
  String get websitesDomainPrimary;

  /// No description provided for @websitesSslCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create certificate'**
  String get websitesSslCreateAction;

  /// No description provided for @websitesSslUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Upload certificate'**
  String get websitesSslUploadAction;

  /// No description provided for @websitesSslListTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate list'**
  String get websitesSslListTitle;

  /// No description provided for @websitesSslListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No certificates'**
  String get websitesSslListEmpty;

  /// No description provided for @websitesSslApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Request certificate'**
  String get websitesSslApplyAction;

  /// No description provided for @websitesSslResolveAction.
  ///
  /// In en, this message translates to:
  /// **'Resolve certificate'**
  String get websitesSslResolveAction;

  /// No description provided for @websitesSslUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update certificate'**
  String get websitesSslUpdateAction;

  /// No description provided for @websitesSslDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete certificate'**
  String get websitesSslDeleteTitle;

  /// No description provided for @websitesSslDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete certificate for {domain}?'**
  String websitesSslDeleteMessage(String domain);

  /// No description provided for @websitesSslAcmeAccountIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ACME account ID'**
  String get websitesSslAcmeAccountIdLabel;

  /// No description provided for @websitesSslProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get websitesSslProviderLabel;

  /// No description provided for @websitesSslOtherDomainsLabel.
  ///
  /// In en, this message translates to:
  /// **'Other domains (comma-separated)'**
  String get websitesSslOtherDomainsLabel;

  /// No description provided for @websitesSslDisableLogLabel.
  ///
  /// In en, this message translates to:
  /// **'Disable logs'**
  String get websitesSslDisableLogLabel;

  /// No description provided for @websitesSslSkipDnsCheckLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip DNS check'**
  String get websitesSslSkipDnsCheckLabel;

  /// No description provided for @websitesSslNameserversLabel.
  ///
  /// In en, this message translates to:
  /// **'Nameservers'**
  String get websitesSslNameserversLabel;

  /// No description provided for @websitesSslDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get websitesSslDescriptionLabel;

  /// No description provided for @websitesSslUploadTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload method'**
  String get websitesSslUploadTypeLabel;

  /// No description provided for @websitesSslUploadTypePaste.
  ///
  /// In en, this message translates to:
  /// **'Paste content'**
  String get websitesSslUploadTypePaste;

  /// No description provided for @websitesSslUploadTypeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local path'**
  String get websitesSslUploadTypeLocal;

  /// No description provided for @websitesSslCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get websitesSslCertificateLabel;

  /// No description provided for @websitesSslPrivateKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get websitesSslPrivateKeyLabel;

  /// No description provided for @websitesSslCertificatePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate path'**
  String get websitesSslCertificatePathLabel;

  /// No description provided for @websitesSslPrivateKeyPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Private key path'**
  String get websitesSslPrivateKeyPathLabel;

  /// No description provided for @websitesHttpsConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'HTTPS config'**
  String get websitesHttpsConfigTitle;

  /// No description provided for @websitesHttpsEnableLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable HTTPS'**
  String get websitesHttpsEnableLabel;

  /// No description provided for @websitesHttpsModeLabel.
  ///
  /// In en, this message translates to:
  /// **'HTTP mode'**
  String get websitesHttpsModeLabel;

  /// No description provided for @websitesHttpsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate type'**
  String get websitesHttpsTypeLabel;

  /// No description provided for @websitesHttpsSslIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate ID'**
  String get websitesHttpsSslIdLabel;

  /// No description provided for @websitesSslAutoRenewMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Certificate is missing the primary domain or provider; cannot update auto-renew.'**
  String get websitesSslAutoRenewMissingFields;

  /// No description provided for @websitesSslDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'Certificate download link: {link}'**
  String websitesSslDownloadHint(String link);

  /// No description provided for @websitesSslExpirationViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiration view'**
  String get websitesSslExpirationViewTitle;

  /// No description provided for @websitesSslFilterAllCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String websitesSslFilterAllCount(int count);

  /// No description provided for @websitesSslFilterExpiredCount.
  ///
  /// In en, this message translates to:
  /// **'Expired ({count})'**
  String websitesSslFilterExpiredCount(int count);

  /// No description provided for @websitesSslFilterWithin7DaysCount.
  ///
  /// In en, this message translates to:
  /// **'Within 7 days ({count})'**
  String websitesSslFilterWithin7DaysCount(int count);

  /// No description provided for @websitesSslFilterWithin30DaysCount.
  ///
  /// In en, this message translates to:
  /// **'Within 30 days ({count})'**
  String websitesSslFilterWithin30DaysCount(int count);

  /// No description provided for @websitesSslAffectedWebsitesCount.
  ///
  /// In en, this message translates to:
  /// **'Affected websites: {count}'**
  String websitesSslAffectedWebsitesCount(int count);

  /// No description provided for @websitesSslAffectedWebsitesDomains.
  ///
  /// In en, this message translates to:
  /// **'Affected domains: {domains}'**
  String websitesSslAffectedWebsitesDomains(String domains);

  /// No description provided for @websitesSslImpactHintApply.
  ///
  /// In en, this message translates to:
  /// **'Apply this certificate to bound websites now?'**
  String get websitesSslImpactHintApply;

  /// No description provided for @websitesSslImpactWarningHigh.
  ///
  /// In en, this message translates to:
  /// **'This action affects multiple websites. Confirm maintenance window first.'**
  String get websitesSslImpactWarningHigh;

  /// No description provided for @websitesSslNoAffectedWebsites.
  ///
  /// In en, this message translates to:
  /// **'No bound websites.'**
  String get websitesSslNoAffectedWebsites;

  /// No description provided for @websitesSslOpenBoundSiteAction.
  ///
  /// In en, this message translates to:
  /// **'Open bound site'**
  String get websitesSslOpenBoundSiteAction;

  /// No description provided for @websitesSslGroupAll.
  ///
  /// In en, this message translates to:
  /// **'All certificates'**
  String get websitesSslGroupAll;

  /// No description provided for @websitesSslGroupExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get websitesSslGroupExpired;

  /// No description provided for @websitesSslGroupWithin7Days.
  ///
  /// In en, this message translates to:
  /// **'Within 7 days'**
  String get websitesSslGroupWithin7Days;

  /// No description provided for @websitesSslGroupWithin30Days.
  ///
  /// In en, this message translates to:
  /// **'Within 30 days'**
  String get websitesSslGroupWithin30Days;

  /// No description provided for @websitesSslGroupHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get websitesSslGroupHealthy;

  /// No description provided for @websitesSslProviderFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All providers'**
  String get websitesSslProviderFilterAll;

  /// No description provided for @websitesSslHealthHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get websitesSslHealthHealthy;

  /// No description provided for @websitesSslHealthExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get websitesSslHealthExpiringSoon;

  /// No description provided for @websitesSslHealthExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get websitesSslHealthExpired;

  /// No description provided for @websitesSslHealthUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get websitesSslHealthUnknown;

  /// No description provided for @websitesSslAccountsCaTab.
  ///
  /// In en, this message translates to:
  /// **'CA'**
  String get websitesSslAccountsCaTab;

  /// No description provided for @websitesSslAccountsAcmeTab.
  ///
  /// In en, this message translates to:
  /// **'ACME'**
  String get websitesSslAccountsAcmeTab;

  /// No description provided for @websitesSslAccountsDnsTab.
  ///
  /// In en, this message translates to:
  /// **'DNS'**
  String get websitesSslAccountsDnsTab;

  /// No description provided for @websitesSslAccountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get websitesSslAccountsEmpty;

  /// No description provided for @websitesSslAccountsCreateCaAction.
  ///
  /// In en, this message translates to:
  /// **'Create CA'**
  String get websitesSslAccountsCreateCaAction;

  /// No description provided for @websitesSslAccountsCreateAcmeAction.
  ///
  /// In en, this message translates to:
  /// **'Create ACME account'**
  String get websitesSslAccountsCreateAcmeAction;

  /// No description provided for @websitesSslAccountsEditAcmeAction.
  ///
  /// In en, this message translates to:
  /// **'Edit ACME account'**
  String get websitesSslAccountsEditAcmeAction;

  /// No description provided for @websitesSslAccountsCreateDnsAction.
  ///
  /// In en, this message translates to:
  /// **'Create DNS account'**
  String get websitesSslAccountsCreateDnsAction;

  /// No description provided for @websitesSslAccountsEditDnsAction.
  ///
  /// In en, this message translates to:
  /// **'Edit DNS account'**
  String get websitesSslAccountsEditDnsAction;

  /// No description provided for @websitesSslAccountsObtainAction.
  ///
  /// In en, this message translates to:
  /// **'Obtain certificate'**
  String get websitesSslAccountsObtainAction;

  /// No description provided for @websitesSslAccountsRenewAction.
  ///
  /// In en, this message translates to:
  /// **'Renew certificate'**
  String get websitesSslAccountsRenewAction;

  /// No description provided for @websitesSslAccountsDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download CA file'**
  String get websitesSslAccountsDownloadAction;

  /// No description provided for @websitesSslAccountsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get websitesSslAccountsTypeLabel;

  /// No description provided for @websitesSslAccountsAuthorizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Authorization JSON'**
  String get websitesSslAccountsAuthorizationLabel;

  /// No description provided for @websitesSslAccountsEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get websitesSslAccountsEmailLabel;

  /// No description provided for @websitesSslAccountsKeyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Key type'**
  String get websitesSslAccountsKeyTypeLabel;

  /// No description provided for @websitesSslAccountsUseProxyLabel.
  ///
  /// In en, this message translates to:
  /// **'Use proxy'**
  String get websitesSslAccountsUseProxyLabel;

  /// No description provided for @websitesSslAccountsCommonNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Common name'**
  String get websitesSslAccountsCommonNameLabel;

  /// No description provided for @websitesSslAccountsCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get websitesSslAccountsCountryLabel;

  /// No description provided for @websitesSslAccountsOrganizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get websitesSslAccountsOrganizationLabel;

  /// No description provided for @websitesSslAccountsOrganizationUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization unit'**
  String get websitesSslAccountsOrganizationUnitLabel;

  /// No description provided for @websitesSslAccountsProvinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get websitesSslAccountsProvinceLabel;

  /// No description provided for @websitesSslAccountsCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get websitesSslAccountsCityLabel;

  /// No description provided for @websitesSslAccountsDomainsLabel.
  ///
  /// In en, this message translates to:
  /// **'Domains (comma-separated)'**
  String get websitesSslAccountsDomainsLabel;

  /// No description provided for @websitesSslAccountsTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Validity period'**
  String get websitesSslAccountsTimeLabel;

  /// No description provided for @websitesSslAccountsUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get websitesSslAccountsUnitLabel;

  /// No description provided for @websitesSslAccountsValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get websitesSslAccountsValidationNameRequired;

  /// No description provided for @websitesSslAccountsValidationTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Type is required.'**
  String get websitesSslAccountsValidationTypeRequired;

  /// No description provided for @websitesSslAccountsValidationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get websitesSslAccountsValidationEmailRequired;

  /// No description provided for @websitesSslAccountsValidationAuthorizationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authorization is required.'**
  String get websitesSslAccountsValidationAuthorizationRequired;

  /// No description provided for @websitesSslAccountsValidationAuthorizationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Authorization must be a valid JSON object.'**
  String get websitesSslAccountsValidationAuthorizationInvalid;

  /// No description provided for @websitesSslAccountsValidationRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields.'**
  String get websitesSslAccountsValidationRequiredFields;

  /// No description provided for @websitesSslAccountsValidationDomainsRequired.
  ///
  /// In en, this message translates to:
  /// **'Domains are required.'**
  String get websitesSslAccountsValidationDomainsRequired;

  /// No description provided for @websitesSslAccountsValidationTimeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Validity period must be greater than 0.'**
  String get websitesSslAccountsValidationTimeInvalid;

  /// No description provided for @websitesSslAccountsMissingId.
  ///
  /// In en, this message translates to:
  /// **'Missing account ID.'**
  String get websitesSslAccountsMissingId;

  /// No description provided for @websitesSslAccountsMissingSslId.
  ///
  /// In en, this message translates to:
  /// **'Missing SSL ID for renew.'**
  String get websitesSslAccountsMissingSslId;

  /// No description provided for @websitesSslAccountsRenewConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Renew this certificate now?'**
  String get websitesSslAccountsRenewConfirmMessage;

  /// No description provided for @websitesSslAccountsDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'CA download request submitted.'**
  String get websitesSslAccountsDownloadSuccess;

  /// No description provided for @websitesSslAccountsDeleteDnsMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete DNS account {name}?'**
  String websitesSslAccountsDeleteDnsMessage(String name);

  /// No description provided for @websitesSslAccountsDeleteAcmeMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete ACME account {email}?'**
  String websitesSslAccountsDeleteAcmeMessage(String email);

  /// No description provided for @websitesSslAccountsDeleteCaMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete CA {name}?'**
  String websitesSslAccountsDeleteCaMessage(String name);

  /// No description provided for @openrestyPageTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenResty'**
  String get openrestyPageTitle;

  /// No description provided for @openrestyNotInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenResty Not Installed'**
  String get openrestyNotInstalledTitle;

  /// No description provided for @openrestyNotInstalledDescription.
  ///
  /// In en, this message translates to:
  /// **'OpenResty is not installed or not ready. Install OpenResty from the App Store before managing websites.'**
  String get openrestyNotInstalledDescription;

  /// No description provided for @openrestyGoStore.
  ///
  /// In en, this message translates to:
  /// **'Go to App Store'**
  String get openrestyGoStore;

  /// No description provided for @openrestyTabStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get openrestyTabStatus;

  /// No description provided for @openrestyTabHttps.
  ///
  /// In en, this message translates to:
  /// **'HTTPS'**
  String get openrestyTabHttps;

  /// No description provided for @openrestyTabModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get openrestyTabModules;

  /// No description provided for @openrestyTabConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get openrestyTabConfig;

  /// No description provided for @openrestyTabBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get openrestyTabBuild;

  /// No description provided for @openrestyTabScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get openrestyTabScope;

  /// No description provided for @openrestyBuildMirrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Build mirror'**
  String get openrestyBuildMirrorLabel;

  /// No description provided for @openrestyBuildTaskIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Task ID'**
  String get openrestyBuildTaskIdLabel;

  /// No description provided for @openrestyBuildAction.
  ///
  /// In en, this message translates to:
  /// **'Build OpenResty'**
  String get openrestyBuildAction;

  /// No description provided for @openrestyScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get openrestyScopeLabel;

  /// No description provided for @openrestyScopeWebsiteIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Website ID (optional)'**
  String get openrestyScopeWebsiteIdLabel;

  /// No description provided for @openrestyScopeLoad.
  ///
  /// In en, this message translates to:
  /// **'Load scope'**
  String get openrestyScopeLoad;

  /// No description provided for @openrestyScopeResultHint.
  ///
  /// In en, this message translates to:
  /// **'Scope config result'**
  String get openrestyScopeResultHint;

  /// No description provided for @openrestyAdvancedSourceEditorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Advanced source editor'**
  String get openrestyAdvancedSourceEditorTooltip;

  /// No description provided for @openrestyRiskBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Gateway risk banner'**
  String get openrestyRiskBannerTitle;

  /// No description provided for @openrestyRunningStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Running Status'**
  String get openrestyRunningStatusLabel;

  /// No description provided for @openrestyBuildVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Build / Version'**
  String get openrestyBuildVersionLabel;

  /// No description provided for @openrestyCoreSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Core Summary'**
  String get openrestyCoreSummaryLabel;

  /// No description provided for @openrestyHttpsSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'HTTPS Summary'**
  String get openrestyHttpsSummaryLabel;

  /// No description provided for @openrestyModulesSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Modules Summary'**
  String get openrestyModulesSummaryLabel;

  /// No description provided for @openrestyCurrentStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Current State'**
  String get openrestyCurrentStateLabel;

  /// No description provided for @openrestyRejectHandshakeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reject Handshake'**
  String get openrestyRejectHandshakeLabel;

  /// No description provided for @openrestyEditHttpsAction.
  ///
  /// In en, this message translates to:
  /// **'Edit HTTPS'**
  String get openrestyEditHttpsAction;

  /// No description provided for @openrestyPreviewDiffAction.
  ///
  /// In en, this message translates to:
  /// **'Preview diff'**
  String get openrestyPreviewDiffAction;

  /// No description provided for @openrestyRollbackAction.
  ///
  /// In en, this message translates to:
  /// **'Rollback'**
  String get openrestyRollbackAction;

  /// No description provided for @openrestyHttpsDiffPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'HTTPS diff preview'**
  String get openrestyHttpsDiffPreviewTitle;

  /// No description provided for @openrestyUnnamedModule.
  ///
  /// In en, this message translates to:
  /// **'Unnamed module'**
  String get openrestyUnnamedModule;

  /// No description provided for @openrestyNoModulesReturned.
  ///
  /// In en, this message translates to:
  /// **'No modules returned by the gateway.'**
  String get openrestyNoModulesReturned;

  /// No description provided for @openrestyModuleDiffPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Module diff preview'**
  String get openrestyModuleDiffPreviewTitle;

  /// No description provided for @openrestyCurrentConfigLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Config'**
  String get openrestyCurrentConfigLabel;

  /// No description provided for @openrestyAdvancedAction.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get openrestyAdvancedAction;

  /// No description provided for @openrestyConfigDiffPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Config diff preview'**
  String get openrestyConfigDiffPreviewTitle;

  /// No description provided for @openrestyBuildLastResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Result'**
  String get openrestyBuildLastResultLabel;

  /// No description provided for @openrestyBuildNoRecentAction.
  ///
  /// In en, this message translates to:
  /// **'No recent build action'**
  String get openrestyBuildNoRecentAction;

  /// No description provided for @openrestyBuildStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start build'**
  String get openrestyBuildStartAction;

  /// No description provided for @openrestyStatusNotRunningSummary.
  ///
  /// In en, this message translates to:
  /// **'Not running'**
  String get openrestyStatusNotRunningSummary;

  /// No description provided for @openrestyStatusRunningSummary.
  ///
  /// In en, this message translates to:
  /// **'Running · active {active}'**
  String openrestyStatusRunningSummary(int active);

  /// No description provided for @openrestyHttpsEnabledSummary.
  ///
  /// In en, this message translates to:
  /// **'HTTPS enabled'**
  String get openrestyHttpsEnabledSummary;

  /// No description provided for @openrestyHttpsDisabledSummary.
  ///
  /// In en, this message translates to:
  /// **'HTTPS disabled'**
  String get openrestyHttpsDisabledSummary;

  /// No description provided for @openrestyModulesEnabledSummary.
  ///
  /// In en, this message translates to:
  /// **'{enabled}/{total} modules enabled'**
  String openrestyModulesEnabledSummary(int enabled, int total);

  /// No description provided for @openrestyBuildNoMirrorConfigured.
  ///
  /// In en, this message translates to:
  /// **'No mirror configured'**
  String get openrestyBuildNoMirrorConfigured;

  /// No description provided for @openrestyConfigNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Config not loaded'**
  String get openrestyConfigNotLoaded;

  /// No description provided for @openrestyConfigLoadedSummary.
  ///
  /// In en, this message translates to:
  /// **'{lines} lines loaded'**
  String openrestyConfigLoadedSummary(int lines);

  /// No description provided for @openrestyDialogUpdateHttpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Update HTTPS'**
  String get openrestyDialogUpdateHttpsTitle;

  /// No description provided for @openrestyDialogEnableHttpsLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable HTTPS'**
  String get openrestyDialogEnableHttpsLabel;

  /// No description provided for @openrestyDialogRejectInvalidHandshakesLabel.
  ///
  /// In en, this message translates to:
  /// **'Reject invalid handshakes'**
  String get openrestyDialogRejectInvalidHandshakesLabel;

  /// No description provided for @openrestyDialogModuleTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get openrestyDialogModuleTitleFallback;

  /// No description provided for @openrestyDialogEnableModuleLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable module'**
  String get openrestyDialogEnableModuleLabel;

  /// No description provided for @openrestyDialogPackagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get openrestyDialogPackagesLabel;

  /// No description provided for @openrestyDialogParamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Params'**
  String get openrestyDialogParamsLabel;

  /// No description provided for @openrestyDialogScriptLabel.
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get openrestyDialogScriptLabel;

  /// No description provided for @openrestyDialogPreviewConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview config change'**
  String get openrestyDialogPreviewConfigTitle;

  /// No description provided for @openrestyDialogConfigSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Config source'**
  String get openrestyDialogConfigSourceLabel;

  /// No description provided for @openrestyDialogStartBuildTitle.
  ///
  /// In en, this message translates to:
  /// **'Start OpenResty build'**
  String get openrestyDialogStartBuildTitle;

  /// No description provided for @openrestyDialogBuildRiskHint.
  ///
  /// In en, this message translates to:
  /// **'Build can refresh gateway binaries and module packages. Confirm before running on production nodes.'**
  String get openrestyDialogBuildRiskHint;

  /// No description provided for @openrestyBuildSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Build submitted'**
  String get openrestyBuildSubmittedMessage;

  /// No description provided for @openrestyBuildSubmittedWithMirrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Build submitted with mirror {mirror}.'**
  String openrestyBuildSubmittedWithMirrorMessage(String mirror);

  /// No description provided for @openrestyRiskGatewayInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Gateway inactive'**
  String get openrestyRiskGatewayInactiveTitle;

  /// No description provided for @openrestyRiskGatewayInactiveMessage.
  ///
  /// In en, this message translates to:
  /// **'OpenResty is not reporting active connections.'**
  String get openrestyRiskGatewayInactiveMessage;

  /// No description provided for @openrestyRiskHttpsDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'HTTPS disabled'**
  String get openrestyRiskHttpsDisabledTitle;

  /// No description provided for @openrestyRiskHttpsDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Disabling HTTPS reduces the default gateway security baseline.'**
  String get openrestyRiskHttpsDisabledMessage;

  /// No description provided for @openrestyRiskNoModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'No modules loaded'**
  String get openrestyRiskNoModulesTitle;

  /// No description provided for @openrestyRiskNoModulesMessage.
  ///
  /// In en, this message translates to:
  /// **'OpenResty modules are empty. Review build and module config.'**
  String get openrestyRiskNoModulesMessage;

  /// No description provided for @openrestyRiskBuildMirrorMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Build mirror missing'**
  String get openrestyRiskBuildMirrorMissingTitle;

  /// No description provided for @openrestyRiskBuildMirrorMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'No build mirror is configured. Build speed may be affected.'**
  String get openrestyRiskBuildMirrorMissingMessage;

  /// No description provided for @openrestyRiskRejectHandshakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject handshake enabled'**
  String get openrestyRiskRejectHandshakeTitle;

  /// No description provided for @openrestyRiskRejectHandshakeMessage.
  ///
  /// In en, this message translates to:
  /// **'This may block clients with invalid TLS negotiation settings.'**
  String get openrestyRiskRejectHandshakeMessage;

  /// No description provided for @openrestyRiskModuleDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Module disabled'**
  String get openrestyRiskModuleDisabledTitle;

  /// No description provided for @openrestyRiskModuleDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Disabling {module} may change gateway behavior immediately.'**
  String openrestyRiskModuleDisabledMessage(String module);

  /// No description provided for @openrestyRiskDependencyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dependency change'**
  String get openrestyRiskDependencyChangeTitle;

  /// No description provided for @openrestyRiskDependencyChangeMessage.
  ///
  /// In en, this message translates to:
  /// **'Package or script changes can introduce dependency conflicts for {module}.'**
  String openrestyRiskDependencyChangeMessage(String module);

  /// No description provided for @openrestyRiskEmptyConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty config'**
  String get openrestyRiskEmptyConfigTitle;

  /// No description provided for @openrestyRiskEmptyConfigMessage.
  ///
  /// In en, this message translates to:
  /// **'Saving an empty config will break the current gateway setup.'**
  String get openrestyRiskEmptyConfigMessage;

  /// No description provided for @openrestyRiskBraceMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Brace mismatch'**
  String get openrestyRiskBraceMismatchTitle;

  /// No description provided for @openrestyRiskBraceMismatchMessage.
  ///
  /// In en, this message translates to:
  /// **'The config appears to have unmatched braces. Validate before saving.'**
  String get openrestyRiskBraceMismatchMessage;

  /// No description provided for @openrestyRiskMissingHttpBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing http block'**
  String get openrestyRiskMissingHttpBlockTitle;

  /// No description provided for @openrestyRiskMissingHttpBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'No http block was detected in the config source.'**
  String get openrestyRiskMissingHttpBlockMessage;

  /// No description provided for @openrestyRiskTemporaryMarkersTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporary markers found'**
  String get openrestyRiskTemporaryMarkersTitle;

  /// No description provided for @openrestyRiskTemporaryMarkersMessage.
  ///
  /// In en, this message translates to:
  /// **'The config still contains TODO or FIXME markers.'**
  String get openrestyRiskTemporaryMarkersMessage;

  /// No description provided for @openrestyDiffLabelHttps.
  ///
  /// In en, this message translates to:
  /// **'HTTPS'**
  String get openrestyDiffLabelHttps;

  /// No description provided for @openrestyDiffLabelRejectHandshake.
  ///
  /// In en, this message translates to:
  /// **'Reject Handshake'**
  String get openrestyDiffLabelRejectHandshake;

  /// No description provided for @openrestyDiffLabelEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get openrestyDiffLabelEnabled;

  /// No description provided for @openrestyDiffLabelPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get openrestyDiffLabelPackages;

  /// No description provided for @openrestyDiffLabelParams.
  ///
  /// In en, this message translates to:
  /// **'Params'**
  String get openrestyDiffLabelParams;

  /// No description provided for @openrestyDiffLabelScript.
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get openrestyDiffLabelScript;

  /// No description provided for @openrestyDiffLabelConfigSource.
  ///
  /// In en, this message translates to:
  /// **'Config Source'**
  String get openrestyDiffLabelConfigSource;

  /// No description provided for @monitorNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get monitorNetworkLabel;

  /// No description provided for @monitorMetricCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get monitorMetricCurrent;

  /// No description provided for @monitorMetricMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get monitorMetricMin;

  /// No description provided for @monitorMetricAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get monitorMetricAvg;

  /// No description provided for @monitorMetricMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get monitorMetricMax;

  /// No description provided for @navServer.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get navServer;

  /// No description provided for @navFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get navFiles;

  /// No description provided for @navSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get navSecurity;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @hostNavScriptLibrary.
  ///
  /// In en, this message translates to:
  /// **'Script Library'**
  String get hostNavScriptLibrary;

  /// No description provided for @hostNavDatabases.
  ///
  /// In en, this message translates to:
  /// **'Databases'**
  String get hostNavDatabases;

  /// No description provided for @hostNavCronJobs.
  ///
  /// In en, this message translates to:
  /// **'CronJobs'**
  String get hostNavCronJobs;

  /// No description provided for @hostNavBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get hostNavBackups;

  /// No description provided for @hostNavHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get hostNavHost;

  /// No description provided for @hostNavCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get hostNavCommands;

  /// No description provided for @hostNavLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get hostNavLogs;

  /// No description provided for @hostNavGateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get hostNavGateway;

  /// No description provided for @noServerSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'{module} needs a server first'**
  String noServerSelectedTitle(String module);

  /// No description provided for @noServerSelectedDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a current server before opening this module.'**
  String get noServerSelectedDescription;

  /// No description provided for @shellPinnedModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Bottom Tabs'**
  String get shellPinnedModulesTitle;

  /// No description provided for @shellPinnedModulesDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose two modules for the bottom navigation. Everything else stays in More.'**
  String get shellPinnedModulesDescription;

  /// No description provided for @shellPinnedModulesCustomize.
  ///
  /// In en, this message translates to:
  /// **'Edit Tabs'**
  String get shellPinnedModulesCustomize;

  /// No description provided for @shellPinnedModulesPrimary.
  ///
  /// In en, this message translates to:
  /// **'Tab 1'**
  String get shellPinnedModulesPrimary;

  /// No description provided for @shellPinnedModulesSecondary.
  ///
  /// In en, this message translates to:
  /// **'Tab 2'**
  String get shellPinnedModulesSecondary;

  /// No description provided for @moduleSubnavCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize sections'**
  String get moduleSubnavCustomize;

  /// No description provided for @moduleSubnavHint.
  ///
  /// In en, this message translates to:
  /// **'The first {count} items stay visible. Others move into More.'**
  String moduleSubnavHint(int count);

  /// No description provided for @moduleSubnavVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get moduleSubnavVisible;

  /// No description provided for @moduleSubnavHidden.
  ///
  /// In en, this message translates to:
  /// **'In More'**
  String get moduleSubnavHidden;

  /// No description provided for @serverPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get serverPageTitle;

  /// No description provided for @serverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search server name or IP'**
  String get serverSearchHint;

  /// No description provided for @serverAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get serverAdd;

  /// No description provided for @serverListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No servers yet'**
  String get serverListEmptyTitle;

  /// No description provided for @serverListEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first 1Panel server to get started.'**
  String get serverListEmptyDesc;

  /// No description provided for @serverOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get serverOnline;

  /// No description provided for @serverOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get serverOffline;

  /// No description provided for @serverCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get serverCurrent;

  /// No description provided for @serverDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get serverDefault;

  /// No description provided for @serverIpLabel.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get serverIpLabel;

  /// No description provided for @serverCpuLabel.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get serverCpuLabel;

  /// No description provided for @serverMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get serverMemoryLabel;

  /// No description provided for @serverLoadLabel.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get serverLoadLabel;

  /// No description provided for @serverDiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get serverDiskLabel;

  /// No description provided for @serverMetricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Metrics unavailable'**
  String get serverMetricsUnavailable;

  /// No description provided for @serverOpenDetail.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get serverOpenDetail;

  /// No description provided for @serverDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Details'**
  String get serverDetailTitle;

  /// No description provided for @serverModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get serverModulesTitle;

  /// No description provided for @serverModuleDashboard.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get serverModuleDashboard;

  /// No description provided for @serverModuleApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get serverModuleApps;

  /// No description provided for @serverModuleContainers.
  ///
  /// In en, this message translates to:
  /// **'Containers'**
  String get serverModuleContainers;

  /// No description provided for @serverModuleWebsites.
  ///
  /// In en, this message translates to:
  /// **'Websites'**
  String get serverModuleWebsites;

  /// No description provided for @serverModuleAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get serverModuleAi;

  /// No description provided for @aiTabModels.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get aiTabModels;

  /// No description provided for @aiTabGpu.
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get aiTabGpu;

  /// No description provided for @aiTabDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get aiTabDomain;

  /// No description provided for @aiModelCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Model'**
  String get aiModelCreate;

  /// No description provided for @aiModelSync.
  ///
  /// In en, this message translates to:
  /// **'Sync Models'**
  String get aiModelSync;

  /// No description provided for @aiModelRecreate.
  ///
  /// In en, this message translates to:
  /// **'Recreate Model'**
  String get aiModelRecreate;

  /// No description provided for @aiModelNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get aiModelNameLabel;

  /// No description provided for @aiTaskIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Task ID (optional)'**
  String get aiTaskIdOptional;

  /// No description provided for @aiModelNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Model name is required'**
  String get aiModelNameRequired;

  /// No description provided for @aiForceDelete.
  ///
  /// In en, this message translates to:
  /// **'Force Delete'**
  String get aiForceDelete;

  /// No description provided for @aiOperationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get aiOperationSuccess;

  /// No description provided for @aiOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String aiOperationFailed(String error);

  /// No description provided for @aiOperationResult.
  ///
  /// In en, this message translates to:
  /// **'Operation Result'**
  String get aiOperationResult;

  /// No description provided for @aiNoGpuData.
  ///
  /// In en, this message translates to:
  /// **'No GPU data available'**
  String get aiNoGpuData;

  /// No description provided for @aiFanSpeed.
  ///
  /// In en, this message translates to:
  /// **'Fan Speed'**
  String get aiFanSpeed;

  /// No description provided for @aiPowerUsage.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get aiPowerUsage;

  /// No description provided for @aiPerformanceState.
  ///
  /// In en, this message translates to:
  /// **'Performance State'**
  String get aiPerformanceState;

  /// No description provided for @aiDomainHint.
  ///
  /// In en, this message translates to:
  /// **'Configure Ollama domain binding. Enter the appInstallID first, then load or submit binding.'**
  String get aiDomainHint;

  /// No description provided for @aiAppInstallIdLabel.
  ///
  /// In en, this message translates to:
  /// **'App Install ID'**
  String get aiAppInstallIdLabel;

  /// No description provided for @aiAppInstallIdRequired.
  ///
  /// In en, this message translates to:
  /// **'App Install ID is required'**
  String get aiAppInstallIdRequired;

  /// No description provided for @aiIpAllowListLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow IP List'**
  String get aiIpAllowListLabel;

  /// No description provided for @aiSslIdOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'SSL ID (optional)'**
  String get aiSslIdOptionalLabel;

  /// No description provided for @aiWebsiteIdOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Website ID (optional)'**
  String get aiWebsiteIdOptionalLabel;

  /// No description provided for @aiLoadBinding.
  ///
  /// In en, this message translates to:
  /// **'Load Current Binding'**
  String get aiLoadBinding;

  /// No description provided for @aiBindDomain.
  ///
  /// In en, this message translates to:
  /// **'Bind Domain'**
  String get aiBindDomain;

  /// No description provided for @aiCurrentBinding.
  ///
  /// In en, this message translates to:
  /// **'Current Binding'**
  String get aiCurrentBinding;

  /// No description provided for @aiConnUrl.
  ///
  /// In en, this message translates to:
  /// **'Connection URL'**
  String get aiConnUrl;

  /// No description provided for @containerSystemProtectedNetwork.
  ///
  /// In en, this message translates to:
  /// **'System network cannot be deleted'**
  String get containerSystemProtectedNetwork;

  /// No description provided for @serverModuleDatabases.
  ///
  /// In en, this message translates to:
  /// **'Databases'**
  String get serverModuleDatabases;

  /// No description provided for @serverModuleFirewall.
  ///
  /// In en, this message translates to:
  /// **'Firewall'**
  String get serverModuleFirewall;

  /// No description provided for @databaseMysqlTab.
  ///
  /// In en, this message translates to:
  /// **'MySQL'**
  String get databaseMysqlTab;

  /// No description provided for @databasePostgresqlTab.
  ///
  /// In en, this message translates to:
  /// **'PostgreSQL'**
  String get databasePostgresqlTab;

  /// No description provided for @databaseRedisTab.
  ///
  /// In en, this message translates to:
  /// **'Redis'**
  String get databaseRedisTab;

  /// No description provided for @databaseRemoteTab.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get databaseRemoteTab;

  /// No description provided for @databaseMongodbTab.
  ///
  /// In en, this message translates to:
  /// **'MongoDB'**
  String get databaseMongodbTab;

  /// No description provided for @databaseOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get databaseOverviewTitle;

  /// No description provided for @databaseConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Config File'**
  String get databaseConfigTitle;

  /// No description provided for @databaseBaseInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Base Info'**
  String get databaseBaseInfoTitle;

  /// No description provided for @databaseStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get databaseStatusTitle;

  /// No description provided for @databaseVariablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get databaseVariablesTitle;

  /// No description provided for @databaseScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Database Scope'**
  String get databaseScopeLabel;

  /// No description provided for @databaseFormBasicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Configuration'**
  String get databaseFormBasicSectionTitle;

  /// No description provided for @databaseFormAdvancedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get databaseFormAdvancedSectionTitle;

  /// No description provided for @databaseEngineLabel.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get databaseEngineLabel;

  /// No description provided for @databaseSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get databaseSourceLabel;

  /// No description provided for @databaseAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get databaseAddressLabel;

  /// No description provided for @databasePortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get databasePortLabel;

  /// No description provided for @databaseContainerLabel.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get databaseContainerLabel;

  /// No description provided for @databaseUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get databaseUsernameLabel;

  /// No description provided for @databasePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get databasePasswordLabel;

  /// No description provided for @databaseRemoteAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Remote Access'**
  String get databaseRemoteAccessLabel;

  /// No description provided for @databaseChangePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get databaseChangePasswordAction;

  /// No description provided for @databaseBindUserAction.
  ///
  /// In en, this message translates to:
  /// **'Bind User'**
  String get databaseBindUserAction;

  /// No description provided for @databaseTestConnectionAction.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get databaseTestConnectionAction;

  /// No description provided for @databaseRedisConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Redis Config'**
  String get databaseRedisConfigTitle;

  /// No description provided for @databaseRedisTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get databaseRedisTimeoutLabel;

  /// No description provided for @databaseRedisMaxClientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Clients'**
  String get databaseRedisMaxClientsLabel;

  /// No description provided for @databaseRedisPersistenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Redis Persistence'**
  String get databaseRedisPersistenceTitle;

  /// No description provided for @databaseRedisAppendOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Append Only'**
  String get databaseRedisAppendOnlyLabel;

  /// No description provided for @databaseRedisSaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save Policy'**
  String get databaseRedisSaveLabel;

  /// No description provided for @databaseManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get databaseManageTitle;

  /// No description provided for @databaseBackupsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get databaseBackupsPageTitle;

  /// No description provided for @databaseUsersPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get databaseUsersPageTitle;

  /// No description provided for @databaseBackupCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get databaseBackupCreateAction;

  /// No description provided for @databaseBackupRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get databaseBackupRestoreAction;

  /// No description provided for @databaseBackupDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get databaseBackupDeleteAction;

  /// No description provided for @databaseBackupSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Compression Password'**
  String get databaseBackupSecretLabel;

  /// No description provided for @databaseBackupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backup records yet.'**
  String get databaseBackupEmpty;

  /// No description provided for @databaseBackupUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Backups are not supported for this database type.'**
  String get databaseBackupUnsupported;

  /// No description provided for @databaseBackupRestoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup record? Existing data may be overwritten.'**
  String get databaseBackupRestoreConfirmMessage;

  /// No description provided for @databaseBackupDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this backup record? This action cannot be undone.'**
  String get databaseBackupDeleteConfirmMessage;

  /// No description provided for @databaseUserCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current User'**
  String get databaseUserCurrentLabel;

  /// No description provided for @databaseUserPermissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get databaseUserPermissionLabel;

  /// No description provided for @databaseUserSuperUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Superuser'**
  String get databaseUserSuperUserLabel;

  /// No description provided for @databaseUserBindAction.
  ///
  /// In en, this message translates to:
  /// **'Bind User'**
  String get databaseUserBindAction;

  /// No description provided for @databaseUserPrivilegesAction.
  ///
  /// In en, this message translates to:
  /// **'Update Privileges'**
  String get databaseUserPrivilegesAction;

  /// No description provided for @databaseUserNoBinding.
  ///
  /// In en, this message translates to:
  /// **'No bound user information is available yet.'**
  String get databaseUserNoBinding;

  /// No description provided for @databaseUserUnsupported.
  ///
  /// In en, this message translates to:
  /// **'User management is not supported for this database type.'**
  String get databaseUserUnsupported;

  /// No description provided for @databasePrivilegeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Privileges can be adjusted after a user is bound.'**
  String get databasePrivilegeUnavailable;

  /// No description provided for @databaseTargetInstance.
  ///
  /// In en, this message translates to:
  /// **'Target Instance'**
  String get databaseTargetInstance;

  /// No description provided for @databaseTargetInstanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a target instance'**
  String get databaseTargetInstanceRequired;

  /// No description provided for @databasePermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get databasePermission;

  /// No description provided for @databaseCharsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Charset'**
  String get databaseCharsetLabel;

  /// No description provided for @databaseFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get databaseFormatLabel;

  /// No description provided for @databaseDbLabel.
  ///
  /// In en, this message translates to:
  /// **'DB'**
  String get databaseDbLabel;

  /// No description provided for @firewallTabStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get firewallTabStatus;

  /// No description provided for @firewallTabRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get firewallTabRules;

  /// No description provided for @firewallTabIps.
  ///
  /// In en, this message translates to:
  /// **'IPs'**
  String get firewallTabIps;

  /// No description provided for @firewallTabPorts.
  ///
  /// In en, this message translates to:
  /// **'Ports'**
  String get firewallTabPorts;

  /// No description provided for @firewallNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get firewallNameLabel;

  /// No description provided for @firewallVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get firewallVersionLabel;

  /// No description provided for @firewallPingLabel.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get firewallPingLabel;

  /// No description provided for @firewallActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get firewallActiveLabel;

  /// No description provided for @firewallInitLabel.
  ///
  /// In en, this message translates to:
  /// **'Initialized'**
  String get firewallInitLabel;

  /// No description provided for @firewallBoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Bound'**
  String get firewallBoundLabel;

  /// No description provided for @firewallProtocolLabel.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get firewallProtocolLabel;

  /// No description provided for @firewallAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get firewallAddressLabel;

  /// No description provided for @firewallStrategyLabel.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get firewallStrategyLabel;

  /// No description provided for @firewallPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get firewallPortLabel;

  /// No description provided for @firewallFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get firewallFamilyLabel;

  /// No description provided for @firewallSourcePortLabel.
  ///
  /// In en, this message translates to:
  /// **'Source Port'**
  String get firewallSourcePortLabel;

  /// No description provided for @firewallDestinationPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination Port'**
  String get firewallDestinationPortLabel;

  /// No description provided for @firewallRuleDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get firewallRuleDefaultTitle;

  /// No description provided for @firewallUnknownStrategy.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get firewallUnknownStrategy;

  /// No description provided for @firewallSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get firewallSourceLabel;

  /// No description provided for @firewallSourceAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get firewallSourceAnywhere;

  /// No description provided for @firewallSourceAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get firewallSourceAddress;

  /// No description provided for @firewallStrategyAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get firewallStrategyAccept;

  /// No description provided for @firewallStrategyDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get firewallStrategyDrop;

  /// No description provided for @firewallStrategyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get firewallStrategyAll;

  /// No description provided for @firewallSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by description, address, or port'**
  String get firewallSearchHint;

  /// No description provided for @firewallRulesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rules yet'**
  String get firewallRulesEmptyTitle;

  /// No description provided for @firewallRulesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Add in the top toolbar to create a port or IP rule.'**
  String get firewallRulesEmptyHint;

  /// No description provided for @firewallIpsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No IP rules yet'**
  String get firewallIpsEmptyTitle;

  /// No description provided for @firewallIpsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Add in the top toolbar to block an IP address.'**
  String get firewallIpsEmptyHint;

  /// No description provided for @firewallPortsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No port rules yet'**
  String get firewallPortsEmptyTitle;

  /// No description provided for @firewallPortsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Add in the top toolbar to open a port.'**
  String get firewallPortsEmptyHint;

  /// No description provided for @firewallSelectionModeEnable.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get firewallSelectionModeEnable;

  /// No description provided for @firewallSelectionModeDisable.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get firewallSelectionModeDisable;

  /// No description provided for @firewallBatchDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Batch Delete'**
  String get firewallBatchDeleteAction;

  /// No description provided for @firewallBatchAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'Batch Accept'**
  String get firewallBatchAcceptAction;

  /// No description provided for @firewallBatchDropAction.
  ///
  /// In en, this message translates to:
  /// **'Batch Drop'**
  String get firewallBatchDropAction;

  /// No description provided for @firewallSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String firewallSelectedCount(int count);

  /// No description provided for @firewallCreatePortRuleAction.
  ///
  /// In en, this message translates to:
  /// **'Create Port Rule'**
  String get firewallCreatePortRuleAction;

  /// No description provided for @firewallCreateIpRuleAction.
  ///
  /// In en, this message translates to:
  /// **'Create IP Rule'**
  String get firewallCreateIpRuleAction;

  /// No description provided for @firewallRuleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rule Configuration'**
  String get firewallRuleSectionTitle;

  /// No description provided for @firewallToggleStrategyAction.
  ///
  /// In en, this message translates to:
  /// **'Toggle Strategy'**
  String get firewallToggleStrategyAction;

  /// No description provided for @firewallOperationConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm firewall change'**
  String get firewallOperationConfirmTitle;

  /// No description provided for @firewallStartConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Start the firewall service? New rules will begin taking effect immediately.'**
  String get firewallStartConfirmMessage;

  /// No description provided for @firewallStopConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Stop the firewall service? This may expose services without packet filtering.'**
  String get firewallStopConfirmMessage;

  /// No description provided for @firewallRestartConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Restart the firewall service? Existing connections may be interrupted briefly.'**
  String get firewallRestartConfirmMessage;

  /// No description provided for @firewallAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required.'**
  String get firewallAddressRequired;

  /// No description provided for @firewallPortRequired.
  ///
  /// In en, this message translates to:
  /// **'Port is required.'**
  String get firewallPortRequired;

  /// No description provided for @firewallChainLabel.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get firewallChainLabel;

  /// No description provided for @firewallBindAction.
  ///
  /// In en, this message translates to:
  /// **'Bind'**
  String get firewallBindAction;

  /// No description provided for @firewallUnbindAction.
  ///
  /// In en, this message translates to:
  /// **'Unbind'**
  String get firewallUnbindAction;

  /// No description provided for @firewallForwardStrategyToggleError.
  ///
  /// In en, this message translates to:
  /// **'Forward rules do not support strategy toggling.'**
  String get firewallForwardStrategyToggleError;

  /// No description provided for @firewallTargetIPLabel.
  ///
  /// In en, this message translates to:
  /// **'Target IP'**
  String get firewallTargetIPLabel;

  /// No description provided for @firewallTargetPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Port'**
  String get firewallTargetPortLabel;

  /// No description provided for @firewallInterfaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get firewallInterfaceLabel;

  /// No description provided for @serverModuleTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get serverModuleTerminal;

  /// No description provided for @serverModuleMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get serverModuleMonitoring;

  /// No description provided for @serverModuleFiles.
  ///
  /// In en, this message translates to:
  /// **'File Manager'**
  String get serverModuleFiles;

  /// No description provided for @serverInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get serverInsightsTitle;

  /// No description provided for @serverActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get serverActionsTitle;

  /// No description provided for @serverActionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get serverActionRefresh;

  /// No description provided for @serverActionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch server'**
  String get serverActionSwitch;

  /// No description provided for @serverActionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get serverActionSecurity;

  /// No description provided for @serverFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get serverFormTitle;

  /// No description provided for @serverFormName.
  ///
  /// In en, this message translates to:
  /// **'Server name'**
  String get serverFormName;

  /// No description provided for @serverFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Production'**
  String get serverFormNameHint;

  /// No description provided for @serverFormUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverFormUrl;

  /// No description provided for @serverFormUrlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://panel.example.com'**
  String get serverFormUrlHint;

  /// No description provided for @serverFormApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get serverFormApiKey;

  /// No description provided for @serverFormApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter API key'**
  String get serverFormApiKeyHint;

  /// No description provided for @serverFormSaveConnect.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get serverFormSaveConnect;

  /// No description provided for @serverFormBasicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Configuration'**
  String get serverFormBasicSectionTitle;

  /// No description provided for @serverFormConnectionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get serverFormConnectionSectionTitle;

  /// No description provided for @serverFormTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get serverFormTest;

  /// No description provided for @serverFormRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get serverFormRequired;

  /// No description provided for @serverFormSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Server saved'**
  String get serverFormSaveSuccess;

  /// No description provided for @serverFormSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save server: {error}'**
  String serverFormSaveFailed(String error);

  /// No description provided for @serverDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete server'**
  String get serverDeleteConfirmTitle;

  /// No description provided for @serverDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete server {name}?'**
  String serverDeleteConfirmMessage(String name);

  /// No description provided for @serverDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted server {name}'**
  String serverDeleteSuccess(String name);

  /// No description provided for @serverDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete server: {error}'**
  String serverDeleteFailed(String error);

  /// No description provided for @serverFormTestHint.
  ///
  /// In en, this message translates to:
  /// **'Connection test can be added after client adaptation.'**
  String get serverFormTestHint;

  /// No description provided for @serverTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get serverTestSuccess;

  /// No description provided for @serverTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get serverTestFailed;

  /// No description provided for @serverTestTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing connection...'**
  String get serverTestTesting;

  /// No description provided for @serverMetricsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Metrics loaded'**
  String get serverMetricsAvailable;

  /// No description provided for @serverTokenValidity.
  ///
  /// In en, this message translates to:
  /// **'Token validity (minutes)'**
  String get serverTokenValidity;

  /// No description provided for @serverTokenValidityHint.
  ///
  /// In en, this message translates to:
  /// **'Set to 0 to skip timestamp validation'**
  String get serverTokenValidityHint;

  /// No description provided for @serverFormAllowInsecureTls.
  ///
  /// In en, this message translates to:
  /// **'Ignore TLS certificate validation'**
  String get serverFormAllowInsecureTls;

  /// No description provided for @serverFormAllowInsecureTlsHint.
  ///
  /// In en, this message translates to:
  /// **'Only enable for trusted self-signed or internal endpoints.'**
  String get serverFormAllowInsecureTlsHint;

  /// No description provided for @serverFormMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get serverFormMinutes;

  /// No description provided for @filesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesPageTitle;

  /// No description provided for @filesPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get filesPath;

  /// No description provided for @filesRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get filesRoot;

  /// No description provided for @filesNavigateUp.
  ///
  /// In en, this message translates to:
  /// **'Back to parent'**
  String get filesNavigateUp;

  /// No description provided for @filesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get filesEmptyTitle;

  /// No description provided for @filesEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to create a new file or folder.'**
  String get filesEmptyDesc;

  /// No description provided for @filesActionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get filesActionUpload;

  /// No description provided for @filesActionNewFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get filesActionNewFile;

  /// No description provided for @filesActionNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get filesActionNewFolder;

  /// No description provided for @filesActionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get filesActionNew;

  /// No description provided for @filesActionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get filesActionOpen;

  /// No description provided for @filesActionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get filesActionDownload;

  /// No description provided for @filesActionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get filesActionRename;

  /// No description provided for @filesActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get filesActionCopy;

  /// No description provided for @filesActionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get filesActionMove;

  /// No description provided for @filesActionExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get filesActionExtract;

  /// No description provided for @filesActionCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get filesActionCompress;

  /// No description provided for @filesActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get filesActionDelete;

  /// No description provided for @filesActionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get filesActionSelectAll;

  /// No description provided for @filesActionDeselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get filesActionDeselect;

  /// No description provided for @filesActionSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get filesActionSort;

  /// No description provided for @filesActionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get filesActionSearch;

  /// No description provided for @filesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get filesNameLabel;

  /// No description provided for @filesNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get filesNameHint;

  /// No description provided for @filesTargetPath.
  ///
  /// In en, this message translates to:
  /// **'Target path'**
  String get filesTargetPath;

  /// No description provided for @filesTypeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get filesTypeDirectory;

  /// No description provided for @filesSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get filesSelected;

  /// No description provided for @filesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String filesSelectedCount(int count);

  /// No description provided for @filesSelectPath.
  ///
  /// In en, this message translates to:
  /// **'Select Path'**
  String get filesSelectPath;

  /// No description provided for @filesCurrentFolder.
  ///
  /// In en, this message translates to:
  /// **'Current Folder'**
  String get filesCurrentFolder;

  /// No description provided for @filesNoSubfolders.
  ///
  /// In en, this message translates to:
  /// **'No subfolders'**
  String get filesNoSubfolders;

  /// No description provided for @filesPathSelectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Target Path'**
  String get filesPathSelectorTitle;

  /// No description provided for @filesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete files'**
  String get filesDeleteTitle;

  /// No description provided for @filesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected items?'**
  String filesDeleteConfirm(int count);

  /// No description provided for @filesSortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get filesSortByName;

  /// No description provided for @filesSortBySize.
  ///
  /// In en, this message translates to:
  /// **'Sort by size'**
  String get filesSortBySize;

  /// No description provided for @filesSortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by date'**
  String get filesSortByDate;

  /// No description provided for @filesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search files'**
  String get filesSearchHint;

  /// No description provided for @filesSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filesSearchClear;

  /// No description provided for @filesRecycleBin.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin'**
  String get filesRecycleBin;

  /// No description provided for @filesCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed'**
  String get filesCopyFailed;

  /// No description provided for @filesMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Move failed'**
  String get filesMoveFailed;

  /// No description provided for @filesRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed'**
  String get filesRenameFailed;

  /// No description provided for @filesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get filesDeleteFailed;

  /// No description provided for @filesCompressFailed.
  ///
  /// In en, this message translates to:
  /// **'Compress failed'**
  String get filesCompressFailed;

  /// No description provided for @filesExtractFailed.
  ///
  /// In en, this message translates to:
  /// **'Extract failed'**
  String get filesExtractFailed;

  /// No description provided for @filesCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Create failed'**
  String get filesCreateFailed;

  /// No description provided for @filesDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get filesDownloadFailed;

  /// No description provided for @filesDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Download successful'**
  String get filesDownloadSuccess;

  /// No description provided for @filesDownloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading {progress}%'**
  String filesDownloadProgress(int progress);

  /// No description provided for @filesDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get filesDownloadCancelled;

  /// No description provided for @filesDownloadSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving to: {path}'**
  String filesDownloadSaving(String path);

  /// No description provided for @filesOperationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get filesOperationSuccess;

  /// No description provided for @filesCompressType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filesCompressType;

  /// No description provided for @filesUploadDeveloping.
  ///
  /// In en, this message translates to:
  /// **'Upload feature is under development'**
  String get filesUploadDeveloping;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get commonUsername;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get commonUrl;

  /// No description provided for @commonDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get commonContent;

  /// No description provided for @commonRepo.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get commonRepo;

  /// No description provided for @commonTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get commonTemplate;

  /// No description provided for @commonEditRepo.
  ///
  /// In en, this message translates to:
  /// **'Edit Repository'**
  String get commonEditRepo;

  /// No description provided for @commonEditTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get commonEditTemplate;

  /// No description provided for @commonDeleteRepoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this repository?'**
  String get commonDeleteRepoConfirm;

  /// No description provided for @commonDeleteTemplateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this template?'**
  String get commonDeleteTemplateConfirm;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get commonPath;

  /// No description provided for @commonDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get commonDriver;

  /// No description provided for @commonUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get commonUnknownError;

  /// No description provided for @commonMegabyte.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get commonMegabyte;

  /// No description provided for @commonHttp.
  ///
  /// In en, this message translates to:
  /// **'HTTP'**
  String get commonHttp;

  /// No description provided for @commonHttps.
  ///
  /// In en, this message translates to:
  /// **'HTTPS'**
  String get commonHttps;

  /// No description provided for @securityPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityPageTitle;

  /// No description provided for @securityStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'MFA status'**
  String get securityStatusTitle;

  /// No description provided for @securityStatusEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get securityStatusEnabled;

  /// No description provided for @securityStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get securityStatusDisabled;

  /// No description provided for @securitySecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get securitySecretLabel;

  /// No description provided for @securityCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get securityCodeLabel;

  /// No description provided for @securityCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get securityCodeHint;

  /// No description provided for @securityLoadInfo.
  ///
  /// In en, this message translates to:
  /// **'Load MFA info'**
  String get securityLoadInfo;

  /// No description provided for @securityBind.
  ///
  /// In en, this message translates to:
  /// **'Bind MFA'**
  String get securityBind;

  /// No description provided for @securityBindSuccess.
  ///
  /// In en, this message translates to:
  /// **'MFA binding request submitted'**
  String get securityBindSuccess;

  /// No description provided for @securityBindFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to bind MFA: {error}'**
  String securityBindFailed(String error);

  /// No description provided for @securityMockNotice.
  ///
  /// In en, this message translates to:
  /// **'Current screen uses UI adapter mode. API client can be connected later.'**
  String get securityMockNotice;

  /// No description provided for @settingsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsAppSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppSectionTitle;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Language updates apply immediately. If not specified, the app follows system settings.'**
  String get settingsLanguageHint;

  /// No description provided for @settingsUIRenderMode.
  ///
  /// In en, this message translates to:
  /// **'UI Render Mode'**
  String get settingsUIRenderMode;

  /// No description provided for @settingsUIRenderModeNative.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get settingsUIRenderModeNative;

  /// No description provided for @settingsUIRenderModeMD3.
  ///
  /// In en, this message translates to:
  /// **'MDUI3'**
  String get settingsUIRenderModeMD3;

  /// No description provided for @settingsUIRenderModeRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Please restart the app for the UI render mode changes to take effect.'**
  String get settingsUIRenderModeRestartHint;

  /// No description provided for @settingsUIRenderModeHostMissing.
  ///
  /// In en, this message translates to:
  /// **'Native host missing. Build: dotnet build windows/runner/native_host/OnePanelNativeHost/OnePanelNativeHost.csproj -c Debug'**
  String get settingsUIRenderModeHostMissing;

  /// No description provided for @settingsUIRenderModeHostMissingStatus.
  ///
  /// In en, this message translates to:
  /// **'Native host not ready (OnePanelNativeHost.exe missing) — this session fell back to MDUI3.'**
  String get settingsUIRenderModeHostMissingStatus;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAppLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Use biometric/device credentials to protect sensitive modules'**
  String get settingsAppLockDesc;

  /// No description provided for @settingsServerManagement.
  ///
  /// In en, this message translates to:
  /// **'Server management'**
  String get settingsServerManagement;

  /// No description provided for @settingsServerManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage multiple connected servers. Server system settings are only available from each server detail page.'**
  String get settingsServerManagementSubtitle;

  /// No description provided for @settingsResetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Replay welcome guide'**
  String get settingsResetOnboarding;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsFeedbackCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Center'**
  String get settingsFeedbackCenterTitle;

  /// No description provided for @settingsFeedbackCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage logs and submit product feedback'**
  String get settingsFeedbackCenterSubtitle;

  /// No description provided for @settingsFeedbackCenterIntro.
  ///
  /// In en, this message translates to:
  /// **'Before submitting an issue, export logs and include repro steps to speed up triage.'**
  String get settingsFeedbackCenterIntro;

  /// No description provided for @settingsFeedbackGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Checklist'**
  String get settingsFeedbackGuideTitle;

  /// No description provided for @settingsFeedbackGuideStep1.
  ///
  /// In en, this message translates to:
  /// **'Confirm the issue is reproducible and capture the key operation path.'**
  String get settingsFeedbackGuideStep1;

  /// No description provided for @settingsFeedbackGuideStep2.
  ///
  /// In en, this message translates to:
  /// **'Export app logs and include the timestamp and release channel.'**
  String get settingsFeedbackGuideStep2;

  /// No description provided for @settingsFeedbackGuideStep3.
  ///
  /// In en, this message translates to:
  /// **'Describe the difference between expected and actual behavior.'**
  String get settingsFeedbackGuideStep3;

  /// No description provided for @settingsFeedbackIssueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report bugs or suggestions in GitHub Issues'**
  String get settingsFeedbackIssueSubtitle;

  /// No description provided for @settingsFeedbackCopyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Copy feedback template'**
  String get settingsFeedbackCopyTemplate;

  /// No description provided for @settingsFeedbackTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Copy a structured template and fill it in directly'**
  String get settingsFeedbackTemplateHint;

  /// No description provided for @settingsFeedbackLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Management'**
  String get settingsFeedbackLogsTitle;

  /// No description provided for @settingsFeedbackLogExportWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Logs & Testing Advice'**
  String get settingsFeedbackLogExportWarningTitle;

  /// No description provided for @settingsFeedbackLogExportWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a Dev release for public testing and feedback collection. We recommend using a private IP (e.g., an internal 1Panel server or VM) for testing to avoid unexpected impacts.\n\nPublic IP addresses in the logs are automatically masked. However, please do not share logs with unrelated personnel, and manually check for any remaining sensitive information before reporting issues.'**
  String get settingsFeedbackLogExportWarningMessage;

  /// No description provided for @settingsFeedbackLogExportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsFeedbackLogExportConfirm;

  /// No description provided for @settingsFeedbackTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue Summary'**
  String get settingsFeedbackTemplateTitle;

  /// No description provided for @settingsFeedbackTemplateSummary.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get settingsFeedbackTemplateSummary;

  /// No description provided for @settingsFeedbackTemplateRepro.
  ///
  /// In en, this message translates to:
  /// **'Steps to reproduce'**
  String get settingsFeedbackTemplateRepro;

  /// No description provided for @settingsFeedbackTemplateExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected behavior'**
  String get settingsFeedbackTemplateExpected;

  /// No description provided for @settingsFeedbackTemplateActual.
  ///
  /// In en, this message translates to:
  /// **'Actual behavior'**
  String get settingsFeedbackTemplateActual;

  /// No description provided for @settingsFeedbackTemplateLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs and screenshots'**
  String get settingsFeedbackTemplateLogs;

  /// No description provided for @settingsFeedbackTemplateEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get settingsFeedbackTemplateEnvironment;

  /// No description provided for @settingsLegalCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegalCenterTitle;

  /// No description provided for @settingsLegalCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy, terms, and open-source notices'**
  String get settingsLegalCenterSubtitle;

  /// No description provided for @settingsLegalCenterIntro.
  ///
  /// In en, this message translates to:
  /// **'These documents describe data handling, service terms, and open-source dependency notices.'**
  String get settingsLegalCenterIntro;

  /// No description provided for @settingsLegalDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Documents'**
  String get settingsLegalDocumentsTitle;

  /// No description provided for @settingsLegalPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsLegalPrivacyPolicy;

  /// No description provided for @settingsLegalTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsLegalTermsOfService;

  /// No description provided for @settingsLegalThirdPartyNotices.
  ///
  /// In en, this message translates to:
  /// **'Third-party License Notices'**
  String get settingsLegalThirdPartyNotices;

  /// No description provided for @settingsLegalOpenSourceLicense.
  ///
  /// In en, this message translates to:
  /// **'Project Open-source License (GPL-3.0)'**
  String get settingsLegalOpenSourceLicense;

  /// No description provided for @settingsLegalFlutterPackages.
  ///
  /// In en, this message translates to:
  /// **'Flutter Package Licenses'**
  String get settingsLegalFlutterPackages;

  /// No description provided for @settingsMainlandSdkDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Mainland China SDK Disclosure'**
  String get settingsMainlandSdkDisclosureTitle;

  /// No description provided for @settingsMainlandSdkDisclosureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View integrated dependencies and regional notes'**
  String get settingsMainlandSdkDisclosureSubtitle;

  /// No description provided for @settingsMainlandSdkDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This page shows auto-scanned integrated dependencies and reserved regional compliance notes.'**
  String get settingsMainlandSdkDisclaimer;

  /// No description provided for @settingsMainlandSdkNone.
  ///
  /// In en, this message translates to:
  /// **'No proprietary SDK dedicated to Mainland China is currently integrated. If introduced, it will be disclosed here.'**
  String get settingsMainlandSdkNone;

  /// No description provided for @settingsMainlandSdkAutoScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-scanned Dependency List'**
  String get settingsMainlandSdkAutoScanTitle;

  /// No description provided for @settingsMainlandSdkAutoScanEmpty.
  ///
  /// In en, this message translates to:
  /// **'No dependency data found. Tap refresh and try again.'**
  String get settingsMainlandSdkAutoScanEmpty;

  /// No description provided for @settingsFeedbackOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the feedback page.'**
  String get settingsFeedbackOpenFailed;

  /// No description provided for @settingsResetOnboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Welcome guide has been reset'**
  String get settingsResetOnboardingDone;

  /// No description provided for @settingsCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache Settings'**
  String get settingsCacheTitle;

  /// No description provided for @settingsCacheStrategy.
  ///
  /// In en, this message translates to:
  /// **'Cache Strategy'**
  String get settingsCacheStrategy;

  /// No description provided for @settingsCacheStrategyHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get settingsCacheStrategyHybrid;

  /// No description provided for @settingsCacheStrategyMemoryOnly.
  ///
  /// In en, this message translates to:
  /// **'Memory Only'**
  String get settingsCacheStrategyMemoryOnly;

  /// No description provided for @settingsCacheStrategyDiskOnly.
  ///
  /// In en, this message translates to:
  /// **'Disk Only'**
  String get settingsCacheStrategyDiskOnly;

  /// No description provided for @settingsCacheMaxSize.
  ///
  /// In en, this message translates to:
  /// **'Cache Limit'**
  String get settingsCacheMaxSize;

  /// No description provided for @settingsCacheStats.
  ///
  /// In en, this message translates to:
  /// **'Cache Status'**
  String get settingsCacheStats;

  /// No description provided for @settingsCacheItemCount.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get settingsCacheItemCount;

  /// No description provided for @settingsCacheCurrentSize.
  ///
  /// In en, this message translates to:
  /// **'Current Size'**
  String get settingsCacheCurrentSize;

  /// No description provided for @settingsCacheClear.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsCacheClear;

  /// No description provided for @settingsCacheClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear Cache'**
  String get settingsCacheClearConfirm;

  /// No description provided for @settingsCacheClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all cache? This will delete both memory and disk cache.'**
  String get settingsCacheClearConfirmMessage;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsCacheLimit.
  ///
  /// In en, this message translates to:
  /// **'Cache Limit'**
  String get settingsCacheLimit;

  /// No description provided for @settingsCacheStatus.
  ///
  /// In en, this message translates to:
  /// **'Cache Status'**
  String get settingsCacheStatus;

  /// No description provided for @settingsCacheStrategyHybridDesc.
  ///
  /// In en, this message translates to:
  /// **'Memory + Disk, best experience'**
  String get settingsCacheStrategyHybridDesc;

  /// No description provided for @settingsCacheStrategyMemoryOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Memory only, reduce flash wear'**
  String get settingsCacheStrategyMemoryOnlyDesc;

  /// No description provided for @settingsCacheStrategyDiskOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Disk only, support offline viewing'**
  String get settingsCacheStrategyDiskOnlyDesc;

  /// No description provided for @settingsCacheExpiration.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get settingsCacheExpiration;

  /// No description provided for @settingsCacheExpirationUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get settingsCacheExpirationUnit;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @commonExperimental.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get commonExperimental;

  /// No description provided for @releaseChannelPreview.
  ///
  /// In en, this message translates to:
  /// **'Dev'**
  String get releaseChannelPreview;

  /// No description provided for @releaseChannelAlpha.
  ///
  /// In en, this message translates to:
  /// **'Dev (Alpha)'**
  String get releaseChannelAlpha;

  /// No description provided for @releaseChannelBeta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get releaseChannelBeta;

  /// No description provided for @releaseChannelPreRelease.
  ///
  /// In en, this message translates to:
  /// **'Pre-Release'**
  String get releaseChannelPreRelease;

  /// No description provided for @releaseChannelRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get releaseChannelRelease;

  /// No description provided for @testingWarningDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'{channel} warning'**
  String testingWarningDialogTitle(String channel);

  /// No description provided for @testingWarningDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This build is for testing and feedback collection. Continue only if you understand the risks.'**
  String get testingWarningDialogBody;

  /// No description provided for @testingWarningRiskUnstable.
  ///
  /// In en, this message translates to:
  /// **'This version may be unstable and features can change at any time.'**
  String get testingWarningRiskUnstable;

  /// No description provided for @testingWarningRiskDataLoss.
  ///
  /// In en, this message translates to:
  /// **'Data loss or configuration issues may occur during testing. Please back up first.'**
  String get testingWarningRiskDataLoss;

  /// No description provided for @testingWarningRiskNoProd.
  ///
  /// In en, this message translates to:
  /// **'Do not use test builds on production servers.'**
  String get testingWarningRiskNoProd;

  /// No description provided for @testingWarningConsentText.
  ///
  /// In en, this message translates to:
  /// **'I understand these risks and agree to continue using the test build.'**
  String get testingWarningConsentText;

  /// No description provided for @testingWarningExit.
  ///
  /// In en, this message translates to:
  /// **'Exit app'**
  String get testingWarningExit;

  /// No description provided for @testingWarningContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get testingWarningContinue;

  /// No description provided for @testingWarningAgreeAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get testingWarningAgreeAndContinue;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Bring your 1Panel servers into one client'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Connect and manage multiple 1Panel servers from one place, with your common tasks always within reach.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Keep everyday operations close'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Check status, manage files, containers, apps, and websites without bouncing between devices.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Switch faster and read status clearly'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Use clear server cards and quick entry points to understand each machine and jump to the right one quickly.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Connect your first server'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'Prepare your server address and API Key, then connect your first machine to start using 1Panel Client.'**
  String get onboardingDesc4;

  /// No description provided for @coachServerAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first server'**
  String get coachServerAddTitle;

  /// No description provided for @coachServerAddDesc.
  ///
  /// In en, this message translates to:
  /// **'Use the add button in the top-right corner to enter your server address and API Key.'**
  String get coachServerAddDesc;

  /// No description provided for @coachServerCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a server to continue'**
  String get coachServerCardTitle;

  /// No description provided for @coachServerCardDesc.
  ///
  /// In en, this message translates to:
  /// **'After connecting, tap a server card to open details and jump into files, containers, websites, and more.'**
  String get coachServerCardDesc;

  /// No description provided for @aboutPageTitle.
  ///
  /// In en, this message translates to:
  /// **'About 1Panel Client'**
  String get aboutPageTitle;

  /// No description provided for @aboutBuildSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Build information'**
  String get aboutBuildSectionTitle;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

  /// No description provided for @aboutBuildLabel.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutBuildLabel;

  /// No description provided for @aboutPackageNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Package name'**
  String get aboutPackageNameLabel;

  /// No description provided for @aboutChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get aboutChannelLabel;

  /// No description provided for @aboutBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Source branch'**
  String get aboutBranchLabel;

  /// No description provided for @aboutCommitLabel.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get aboutCommitLabel;

  /// No description provided for @aboutBuildDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Build date'**
  String get aboutBuildDateLabel;

  /// No description provided for @aboutOfficialDomainLabel.
  ///
  /// In en, this message translates to:
  /// **'Official domain'**
  String get aboutOfficialDomainLabel;

  /// No description provided for @aboutProjectSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get aboutProjectSectionTitle;

  /// No description provided for @aboutProjectSummary.
  ///
  /// In en, this message translates to:
  /// **'1Panel Client is a mobile app for managing 1Panel servers across multiple environments.'**
  String get aboutProjectSummary;

  /// No description provided for @aboutProjectFeatureList.
  ///
  /// In en, this message translates to:
  /// **'Core capabilities: multi-server management, file and website operations, terminal access, and status monitoring.'**
  String get aboutProjectFeatureList;

  /// No description provided for @aboutFeedbackAction.
  ///
  /// In en, this message translates to:
  /// **'Open GitHub Issues'**
  String get aboutFeedbackAction;

  /// No description provided for @aboutFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Report bugs, usability issues, and suggestions in the official issue tracker.'**
  String get aboutFeedbackHint;

  /// No description provided for @aboutReleaseNotesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get aboutReleaseNotesSectionTitle;

  /// No description provided for @aboutReleaseNotesBody.
  ///
  /// In en, this message translates to:
  /// **'See latest updates and changes in the releases page.'**
  String get aboutReleaseNotesBody;

  /// No description provided for @aboutRepositorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get aboutRepositorySectionTitle;

  /// No description provided for @aboutLinkOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get aboutLinkOpenAction;

  /// No description provided for @aboutRepositoryOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open repository'**
  String get aboutRepositoryOpenAction;

  /// No description provided for @aboutRepositoryHttpsLabel.
  ///
  /// In en, this message translates to:
  /// **'HTTPS'**
  String get aboutRepositoryHttpsLabel;

  /// No description provided for @aboutRepositorySshLabel.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get aboutRepositorySshLabel;

  /// No description provided for @aboutReleaseAction.
  ///
  /// In en, this message translates to:
  /// **'View Releases'**
  String get aboutReleaseAction;

  /// No description provided for @aboutLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get aboutLinkOpenFailed;

  /// No description provided for @aboutExperimentalModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get aboutExperimentalModulesTitle;

  /// No description provided for @aboutExperimentalModulesDescription.
  ///
  /// In en, this message translates to:
  /// **'Server, websites, containers, databases, firewall, terminal, and monitoring.'**
  String get aboutExperimentalModulesDescription;

  /// No description provided for @aboutExperimentalModulesList.
  ///
  /// In en, this message translates to:
  /// **'Server · Websites · Containers · Databases · Firewall · Terminal · Monitoring'**
  String get aboutExperimentalModulesList;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get dashboardLoadFailedTitle;

  /// No description provided for @dashboardServerInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Server info'**
  String get dashboardServerInfoTitle;

  /// No description provided for @dashboardServerStatusOk.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get dashboardServerStatusOk;

  /// No description provided for @dashboardServerStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get dashboardServerStatusConnecting;

  /// No description provided for @dashboardHostNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get dashboardHostNameLabel;

  /// No description provided for @dashboardOsLabel.
  ///
  /// In en, this message translates to:
  /// **'Operating system'**
  String get dashboardOsLabel;

  /// No description provided for @dashboardUptimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get dashboardUptimeLabel;

  /// No description provided for @dashboardUptimeDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h'**
  String dashboardUptimeDaysHours(int days, int hours);

  /// No description provided for @dashboardUptimeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String dashboardUptimeHours(int hours);

  /// No description provided for @dashboardUptimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String dashboardUptimeMinutes(int minutes);

  /// No description provided for @dashboardUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String dashboardUpdatedAt(String time);

  /// No description provided for @dashboardResourceTitle.
  ///
  /// In en, this message translates to:
  /// **'System resources'**
  String get dashboardResourceTitle;

  /// No description provided for @dashboardCpuUsage.
  ///
  /// In en, this message translates to:
  /// **'CPU usage'**
  String get dashboardCpuUsage;

  /// No description provided for @dashboardMemoryUsage.
  ///
  /// In en, this message translates to:
  /// **'Memory usage'**
  String get dashboardMemoryUsage;

  /// No description provided for @dashboardDiskUsage.
  ///
  /// In en, this message translates to:
  /// **'Disk usage'**
  String get dashboardDiskUsage;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardActionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart server'**
  String get dashboardActionRestart;

  /// No description provided for @dashboardActionUpdate.
  ///
  /// In en, this message translates to:
  /// **'System update'**
  String get dashboardActionUpdate;

  /// No description provided for @dashboardActionBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get dashboardActionBackup;

  /// No description provided for @dashboardActionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security check'**
  String get dashboardActionSecurity;

  /// No description provided for @dashboardRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart server'**
  String get dashboardRestartTitle;

  /// No description provided for @dashboardRestartDesc.
  ///
  /// In en, this message translates to:
  /// **'Restarting will temporarily interrupt all services. Continue?'**
  String get dashboardRestartDesc;

  /// No description provided for @dashboardRestartSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restart request sent'**
  String get dashboardRestartSuccess;

  /// No description provided for @dashboardRestartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restart: {error}'**
  String dashboardRestartFailed(String error);

  /// No description provided for @dashboardUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'System update'**
  String get dashboardUpdateTitle;

  /// No description provided for @dashboardUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the update now? The panel may be temporarily unavailable.'**
  String get dashboardUpdateDesc;

  /// No description provided for @dashboardUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Update request sent'**
  String get dashboardUpdateSuccess;

  /// No description provided for @dashboardUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String dashboardUpdateFailed(String error);

  /// No description provided for @dashboardActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardActivityTitle;

  /// No description provided for @dashboardActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get dashboardActivityEmpty;

  /// No description provided for @dashboardActivityDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String dashboardActivityDaysAgo(int count);

  /// No description provided for @dashboardActivityHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String dashboardActivityHoursAgo(int count);

  /// No description provided for @dashboardActivityMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String dashboardActivityMinutesAgo(int count);

  /// No description provided for @dashboardActivityJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get dashboardActivityJustNow;

  /// No description provided for @dashboardTopProcessesTitle.
  ///
  /// In en, this message translates to:
  /// **'Process Monitor'**
  String get dashboardTopProcessesTitle;

  /// No description provided for @dashboardCpuTab.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get dashboardCpuTab;

  /// No description provided for @dashboardMemoryTab.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get dashboardMemoryTab;

  /// No description provided for @dashboardNoProcesses.
  ///
  /// In en, this message translates to:
  /// **'No process data'**
  String get dashboardNoProcesses;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'1Panel Login'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials'**
  String get authLoginSubtitle;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authCaptcha.
  ///
  /// In en, this message translates to:
  /// **'Captcha'**
  String get authCaptcha;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get authUsernameRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get authPasswordRequired;

  /// No description provided for @authCaptchaRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter captcha'**
  String get authCaptchaRequired;

  /// No description provided for @authMfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get authMfaTitle;

  /// No description provided for @authMfaDesc.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code from your authenticator app'**
  String get authMfaDesc;

  /// No description provided for @authMfaHint.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get authMfaHint;

  /// No description provided for @authMfaVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authMfaVerify;

  /// No description provided for @authMfaCancel.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get authMfaCancel;

  /// No description provided for @authPasskeyLogin.
  ///
  /// In en, this message translates to:
  /// **'Login with Passkey'**
  String get authPasskeyLogin;

  /// No description provided for @authPasskeyUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Passkey unavailable'**
  String get authPasskeyUnsupported;

  /// No description provided for @authDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: Some features are limited'**
  String get authDemoMode;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get authLoginFailed;

  /// No description provided for @authLogoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get authLogoutSuccess;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLockTitle;

  /// No description provided for @appLockDeviceAuthStatus.
  ///
  /// In en, this message translates to:
  /// **'Device authentication'**
  String get appLockDeviceAuthStatus;

  /// No description provided for @appLockDeviceAuthSupported.
  ///
  /// In en, this message translates to:
  /// **'Biometric or device credential is available on this device'**
  String get appLockDeviceAuthSupported;

  /// No description provided for @appLockDeviceAuthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Current device does not support local authentication'**
  String get appLockDeviceAuthUnsupported;

  /// No description provided for @appLockEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable app lock'**
  String get appLockEnable;

  /// No description provided for @appLockEnableDesc.
  ///
  /// In en, this message translates to:
  /// **'Prompt for local authentication before opening protected content'**
  String get appLockEnableDesc;

  /// No description provided for @appLockLockOnAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Require unlock on app open'**
  String get appLockLockOnAppOpen;

  /// No description provided for @appLockLockOnAppOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify identity before entering the app'**
  String get appLockLockOnAppOpenDesc;

  /// No description provided for @appLockLockOnProtectedModule.
  ///
  /// In en, this message translates to:
  /// **'Require unlock for protected modules'**
  String get appLockLockOnProtectedModule;

  /// No description provided for @appLockLockOnProtectedModuleDesc.
  ///
  /// In en, this message translates to:
  /// **'Only selected modules will require another verification'**
  String get appLockLockOnProtectedModuleDesc;

  /// No description provided for @appLockRelockAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Relock after background time'**
  String get appLockRelockAfterMinutes;

  /// No description provided for @appLockRelockAfterMinutesOption.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String appLockRelockAfterMinutesOption(int minutes);

  /// No description provided for @appLockProtectedModules.
  ///
  /// In en, this message translates to:
  /// **'Protected modules'**
  String get appLockProtectedModules;

  /// No description provided for @appLockSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get appLockSelectAll;

  /// No description provided for @appLockClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get appLockClearAll;

  /// No description provided for @appLockNoProtectedModules.
  ///
  /// In en, this message translates to:
  /// **'Module protection is currently disabled.'**
  String get appLockNoProtectedModules;

  /// No description provided for @appLockAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get appLockAuthFailed;

  /// No description provided for @appLockUnlockReasonEnable.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to enable app lock'**
  String get appLockUnlockReasonEnable;

  /// No description provided for @appLockUnlockReasonAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to open 1Panel Client'**
  String get appLockUnlockReasonAppOpen;

  /// No description provided for @appLockUnlockReasonModule.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to open {module}'**
  String appLockUnlockReasonModule(String module);

  /// No description provided for @coachDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get coachDone;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'The requested page does not exist.'**
  String get notFoundDesc;

  /// No description provided for @legacyRouteRedirect.
  ///
  /// In en, this message translates to:
  /// **'This legacy route is redirected to the new shell.'**
  String get legacyRouteRedirect;

  /// No description provided for @monitorDataPoints.
  ///
  /// In en, this message translates to:
  /// **'Data points'**
  String get monitorDataPoints;

  /// No description provided for @monitorDataPointsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} points ({time})'**
  String monitorDataPointsCount(int count, String time);

  /// No description provided for @monitorRefreshInterval.
  ///
  /// In en, this message translates to:
  /// **'Refresh interval'**
  String get monitorRefreshInterval;

  /// No description provided for @monitorSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String monitorSeconds(int count);

  /// No description provided for @monitorSecondsDefault.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds (default)'**
  String monitorSecondsDefault(int count);

  /// No description provided for @monitorMinute.
  ///
  /// In en, this message translates to:
  /// **'{count} minute'**
  String monitorMinute(int count);

  /// No description provided for @monitorTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String monitorTimeMinutes(int count);

  /// No description provided for @monitorTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hour'**
  String monitorTimeHours(int count);

  /// No description provided for @monitorDataPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} data points'**
  String monitorDataPointsLabel(int count);

  /// No description provided for @monitorSettings.
  ///
  /// In en, this message translates to:
  /// **'Monitor Settings'**
  String get monitorSettings;

  /// No description provided for @monitorEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Monitoring'**
  String get monitorEnable;

  /// No description provided for @monitorInterval.
  ///
  /// In en, this message translates to:
  /// **'Monitor Interval'**
  String get monitorInterval;

  /// No description provided for @monitorIntervalUnit.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get monitorIntervalUnit;

  /// No description provided for @monitorRetention.
  ///
  /// In en, this message translates to:
  /// **'Data Retention'**
  String get monitorRetention;

  /// No description provided for @monitorRetentionUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get monitorRetentionUnit;

  /// No description provided for @monitorCleanData.
  ///
  /// In en, this message translates to:
  /// **'Clean Monitor Data'**
  String get monitorCleanData;

  /// No description provided for @monitorCleanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clean all monitor data? This action cannot be undone.'**
  String get monitorCleanConfirm;

  /// No description provided for @monitorCleanSuccess.
  ///
  /// In en, this message translates to:
  /// **'Monitor data cleaned successfully'**
  String get monitorCleanSuccess;

  /// No description provided for @monitorCleanFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clean monitor data'**
  String get monitorCleanFailed;

  /// No description provided for @monitorSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get monitorSettingsSaved;

  /// No description provided for @monitorSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get monitorSettingsFailed;

  /// No description provided for @monitorGPU.
  ///
  /// In en, this message translates to:
  /// **'GPU Monitor'**
  String get monitorGPU;

  /// No description provided for @monitorGPUName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get monitorGPUName;

  /// No description provided for @monitorGPUUtilization.
  ///
  /// In en, this message translates to:
  /// **'Utilization'**
  String get monitorGPUUtilization;

  /// No description provided for @monitorGPUMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get monitorGPUMemory;

  /// No description provided for @monitorGPUTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get monitorGPUTemperature;

  /// No description provided for @monitorGPUNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'GPU monitoring not available'**
  String get monitorGPUNotAvailable;

  /// No description provided for @monitorTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get monitorTimeRange;

  /// No description provided for @monitorTimeRangeLast1h.
  ///
  /// In en, this message translates to:
  /// **'Last 1 hour'**
  String get monitorTimeRangeLast1h;

  /// No description provided for @monitorTimeRangeLast6h.
  ///
  /// In en, this message translates to:
  /// **'Last 6 hours'**
  String get monitorTimeRangeLast6h;

  /// No description provided for @monitorTimeRangeLast24h.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get monitorTimeRangeLast24h;

  /// No description provided for @monitorTimeRangeLast7d.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get monitorTimeRangeLast7d;

  /// No description provided for @monitorTimeRangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get monitorTimeRangeCustom;

  /// No description provided for @monitorTimeRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get monitorTimeRangeFrom;

  /// No description provided for @monitorTimeRangeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get monitorTimeRangeTo;

  /// No description provided for @systemSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettingsTitle;

  /// No description provided for @systemSettingsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get systemSettingsRefresh;

  /// No description provided for @systemSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings'**
  String get systemSettingsLoadFailed;

  /// No description provided for @systemSettingsPanelSection.
  ///
  /// In en, this message translates to:
  /// **'Panel Settings'**
  String get systemSettingsPanelSection;

  /// No description provided for @systemSettingsFileExportSection.
  ///
  /// In en, this message translates to:
  /// **'File Export & Download'**
  String get systemSettingsFileExportSection;

  /// No description provided for @systemSettingsFileExportUsePicker.
  ///
  /// In en, this message translates to:
  /// **'Use file picker when saving'**
  String get systemSettingsFileExportUsePicker;

  /// No description provided for @systemSettingsFileExportUsePickerDesc.
  ///
  /// In en, this message translates to:
  /// **'When off, files save into the default download directory (grouped by subfolder)'**
  String get systemSettingsFileExportUsePickerDesc;

  /// No description provided for @systemSettingsFileExportSubDirTitle.
  ///
  /// In en, this message translates to:
  /// **'Default sub-folder name'**
  String get systemSettingsFileExportSubDirTitle;

  /// No description provided for @systemSettingsFileExportSubDirHelper.
  ///
  /// In en, this message translates to:
  /// **'Used when the picker is off. Leave empty to skip the parent folder. Default: 1Panel-Client'**
  String get systemSettingsFileExportSubDirHelper;

  /// No description provided for @fileSaveSuccessPicker.
  ///
  /// In en, this message translates to:
  /// **'Saved to {displayName} Downloads'**
  String fileSaveSuccessPicker(String displayName);

  /// No description provided for @fileSaveSuccessDownloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads'**
  String get fileSaveSuccessDownloads;

  /// No description provided for @fileSaveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Save cancelled'**
  String get fileSaveCancelled;

  /// No description provided for @fileSavePrivateFallback.
  ///
  /// In en, this message translates to:
  /// **'File picker unavailable, saved to the app private directory'**
  String get fileSavePrivateFallback;

  /// No description provided for @filePickerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'File picker unavailable'**
  String get filePickerUnavailable;

  /// No description provided for @systemSettingsPanelConfig.
  ///
  /// In en, this message translates to:
  /// **'Panel Config'**
  String get systemSettingsPanelConfig;

  /// No description provided for @systemSettingsPanelConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'Panel name, port, bind address, etc.'**
  String get systemSettingsPanelConfigDesc;

  /// No description provided for @systemSettingsTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal Settings'**
  String get systemSettingsTerminal;

  /// No description provided for @systemSettingsTerminalDesc.
  ///
  /// In en, this message translates to:
  /// **'Terminal style, font, scrolling, etc.'**
  String get systemSettingsTerminalDesc;

  /// No description provided for @systemSettingsSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get systemSettingsSecuritySection;

  /// No description provided for @systemSettingsSecurityConfig.
  ///
  /// In en, this message translates to:
  /// **'Security Config'**
  String get systemSettingsSecurityConfig;

  /// No description provided for @systemSettingsSecurityConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'MFA authentication, access control, etc.'**
  String get systemSettingsSecurityConfigDesc;

  /// No description provided for @systemSettingsDashboardMemo.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Memo'**
  String get systemSettingsDashboardMemo;

  /// No description provided for @systemSettingsDashboardMemoHint.
  ///
  /// In en, this message translates to:
  /// **'Write a quick note for your dashboard...'**
  String get systemSettingsDashboardMemoHint;

  /// No description provided for @systemSettingsAppLogsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export local application debug logs'**
  String get systemSettingsAppLogsExportSubtitle;

  /// No description provided for @systemSettingsAppLogsPreviewButton.
  ///
  /// In en, this message translates to:
  /// **'Export Preview'**
  String get systemSettingsAppLogsPreviewButton;

  /// No description provided for @systemSettingsAppLogsPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View the latest 200 log lines, preview human / AI Agent formats'**
  String get systemSettingsAppLogsPreviewSubtitle;

  /// No description provided for @systemSettingsAppLogsPreviewTabHuman.
  ///
  /// In en, this message translates to:
  /// **'Human-readable'**
  String get systemSettingsAppLogsPreviewTabHuman;

  /// No description provided for @systemSettingsAppLogsPreviewTabAi.
  ///
  /// In en, this message translates to:
  /// **'AI Agent format'**
  String get systemSettingsAppLogsPreviewTabAi;

  /// No description provided for @systemSettingsAppLogsPreviewSave.
  ///
  /// In en, this message translates to:
  /// **'Save this format'**
  String get systemSettingsAppLogsPreviewSave;

  /// No description provided for @systemSettingsAppLogsPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs available'**
  String get systemSettingsAppLogsPreviewEmpty;

  /// No description provided for @systemSettingsAppLogsPreviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading logs...'**
  String get systemSettingsAppLogsPreviewLoading;

  /// No description provided for @systemSettingsAppLogsLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'App log level'**
  String get systemSettingsAppLogsLevelTitle;

  /// No description provided for @systemSettingsAppLogsLevelLocked.
  ///
  /// In en, this message translates to:
  /// **'The current channel locks log level (forced Debug).'**
  String get systemSettingsAppLogsLevelLocked;

  /// No description provided for @systemSettingsLogLevelTrace.
  ///
  /// In en, this message translates to:
  /// **'Trace'**
  String get systemSettingsLogLevelTrace;

  /// No description provided for @systemSettingsLogLevelDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get systemSettingsLogLevelDebug;

  /// No description provided for @systemSettingsLogLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get systemSettingsLogLevelInfo;

  /// No description provided for @systemSettingsLogLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get systemSettingsLogLevelWarning;

  /// No description provided for @systemSettingsLogLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get systemSettingsLogLevelError;

  /// No description provided for @systemSettingsLogLevelFatal.
  ///
  /// In en, this message translates to:
  /// **'Fatal'**
  String get systemSettingsLogLevelFatal;

  /// No description provided for @systemSettingsAppLogsClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete local persisted log files'**
  String get systemSettingsAppLogsClearSubtitle;

  /// No description provided for @systemSettingsAppLogsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear app logs'**
  String get systemSettingsAppLogsClearTitle;

  /// No description provided for @systemSettingsAppLogsClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear local app logs? This action cannot be undone.'**
  String get systemSettingsAppLogsClearConfirm;

  /// No description provided for @systemSettingsAppLogsCleared.
  ///
  /// In en, this message translates to:
  /// **'App logs cleared'**
  String get systemSettingsAppLogsCleared;

  /// No description provided for @systemSettingsApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get systemSettingsApiKey;

  /// No description provided for @systemSettingsBackupSection.
  ///
  /// In en, this message translates to:
  /// **'Backup & Recovery'**
  String get systemSettingsBackupSection;

  /// No description provided for @systemSettingsSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot Management'**
  String get systemSettingsSnapshot;

  /// No description provided for @systemSettingsSnapshotDesc.
  ///
  /// In en, this message translates to:
  /// **'Create, restore, delete system snapshots'**
  String get systemSettingsSnapshotDesc;

  /// No description provided for @systemSettingsBackupAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Accounts'**
  String get systemSettingsBackupAccountTitle;

  /// No description provided for @systemSettingsBackupAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage backup storage accounts'**
  String get systemSettingsBackupAccountDesc;

  /// No description provided for @systemSettingsSystemSection.
  ///
  /// In en, this message translates to:
  /// **'System Info'**
  String get systemSettingsSystemSection;

  /// No description provided for @systemSettingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'System Upgrade'**
  String get systemSettingsUpgrade;

  /// No description provided for @systemSettingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get systemSettingsAbout;

  /// No description provided for @systemSettingsAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'System info and version'**
  String get systemSettingsAboutDesc;

  /// No description provided for @systemSettingsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String systemSettingsLastUpdated(String time);

  /// No description provided for @systemSettingsPanelName.
  ///
  /// In en, this message translates to:
  /// **'1Panel'**
  String get systemSettingsPanelName;

  /// No description provided for @systemSettingsSystemVersion.
  ///
  /// In en, this message translates to:
  /// **'System Version'**
  String get systemSettingsSystemVersion;

  /// No description provided for @systemSettingsMfaStatus.
  ///
  /// In en, this message translates to:
  /// **'MFA Status'**
  String get systemSettingsMfaStatus;

  /// No description provided for @systemSettingsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get systemSettingsEnabled;

  /// No description provided for @systemSettingsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get systemSettingsDisabled;

  /// No description provided for @systemSettingsApiKeyManage.
  ///
  /// In en, this message translates to:
  /// **'API Key Management'**
  String get systemSettingsApiKeyManage;

  /// No description provided for @systemSettingsCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get systemSettingsCurrentStatus;

  /// No description provided for @systemSettingsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get systemSettingsUnknown;

  /// No description provided for @systemSettingsApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get systemSettingsApiKeyLabel;

  /// No description provided for @systemSettingsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get systemSettingsNotSet;

  /// No description provided for @systemSettingsGenerateNewKey.
  ///
  /// In en, this message translates to:
  /// **'Generate New Key'**
  String get systemSettingsGenerateNewKey;

  /// No description provided for @systemSettingsApiKeyGenerated.
  ///
  /// In en, this message translates to:
  /// **'API key generated'**
  String get systemSettingsApiKeyGenerated;

  /// No description provided for @systemSettingsGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed'**
  String get systemSettingsGenerateFailed;

  /// No description provided for @apiKeySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'API Key Management'**
  String get apiKeySettingsTitle;

  /// No description provided for @apiKeySettingsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get apiKeySettingsStatus;

  /// No description provided for @apiKeySettingsEnabled.
  ///
  /// In en, this message translates to:
  /// **'API Interface'**
  String get apiKeySettingsEnabled;

  /// No description provided for @apiKeySettingsInfo.
  ///
  /// In en, this message translates to:
  /// **'Key Information'**
  String get apiKeySettingsInfo;

  /// No description provided for @apiKeySettingsKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeySettingsKey;

  /// No description provided for @apiKeySettingsIpWhitelist.
  ///
  /// In en, this message translates to:
  /// **'IP Whitelist'**
  String get apiKeySettingsIpWhitelist;

  /// No description provided for @apiKeySettingsValidityTime.
  ///
  /// In en, this message translates to:
  /// **'Validity Time'**
  String get apiKeySettingsValidityTime;

  /// No description provided for @apiKeySettingsActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get apiKeySettingsActions;

  /// No description provided for @apiKeySettingsRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get apiKeySettingsRegenerate;

  /// No description provided for @apiKeySettingsRegenerateDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate new API key'**
  String get apiKeySettingsRegenerateDesc;

  /// No description provided for @apiKeySettingsRegenerateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to regenerate the API key? The old key will be invalid immediately.'**
  String get apiKeySettingsRegenerateConfirm;

  /// No description provided for @apiKeySettingsRegenerateSuccess.
  ///
  /// In en, this message translates to:
  /// **'API key regenerated'**
  String get apiKeySettingsRegenerateSuccess;

  /// No description provided for @apiKeySettingsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable API'**
  String get apiKeySettingsEnable;

  /// No description provided for @apiKeySettingsDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable API'**
  String get apiKeySettingsDisable;

  /// No description provided for @apiKeySettingsEnableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to enable API interface?'**
  String get apiKeySettingsEnableConfirm;

  /// No description provided for @apiKeySettingsDisableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable API interface?'**
  String get apiKeySettingsDisableConfirm;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get commonCopied;

  /// No description provided for @sslSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SSL Certificate Management'**
  String get sslSettingsTitle;

  /// No description provided for @sslSettingsInfo.
  ///
  /// In en, this message translates to:
  /// **'Certificate Information'**
  String get sslSettingsInfo;

  /// No description provided for @sslSettingsDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get sslSettingsDomain;

  /// No description provided for @sslSettingsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sslSettingsStatus;

  /// No description provided for @sslSettingsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sslSettingsType;

  /// No description provided for @sslSettingsProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get sslSettingsProvider;

  /// No description provided for @sslSettingsExpiration.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get sslSettingsExpiration;

  /// No description provided for @sslSettingsActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get sslSettingsActions;

  /// No description provided for @sslSettingsUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload Certificate'**
  String get sslSettingsUpload;

  /// No description provided for @sslSettingsUploadDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload SSL certificate file'**
  String get sslSettingsUploadDesc;

  /// No description provided for @sslSettingsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download Certificate'**
  String get sslSettingsDownload;

  /// No description provided for @sslSettingsDownloadDesc.
  ///
  /// In en, this message translates to:
  /// **'Download current SSL certificate'**
  String get sslSettingsDownloadDesc;

  /// No description provided for @sslSettingsDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Certificate downloaded successfully'**
  String get sslSettingsDownloadSuccess;

  /// No description provided for @sslSettingsCert.
  ///
  /// In en, this message translates to:
  /// **'Certificate Content'**
  String get sslSettingsCert;

  /// No description provided for @sslSettingsKey.
  ///
  /// In en, this message translates to:
  /// **'Private Key Content'**
  String get sslSettingsKey;

  /// No description provided for @panelTlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Panel TLS'**
  String get panelTlsTitle;

  /// No description provided for @panelTlsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get panelTlsOverviewTitle;

  /// No description provided for @panelTlsCertificateTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get panelTlsCertificateTitle;

  /// No description provided for @panelTlsRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get panelTlsRiskTitle;

  /// No description provided for @panelTlsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get panelTlsHistoryTitle;

  /// No description provided for @panelTlsUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Uploading a new certificate replaces the current panel TLS bundle immediately.'**
  String get panelTlsUploadHint;

  /// No description provided for @panelTlsIssuerLabel.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get panelTlsIssuerLabel;

  /// No description provided for @panelTlsCertificatePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate Path'**
  String get panelTlsCertificatePathLabel;

  /// No description provided for @panelTlsKeyPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Key Path'**
  String get panelTlsKeyPathLabel;

  /// No description provided for @panelTlsSerialNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get panelTlsSerialNumberLabel;

  /// No description provided for @panelTlsLastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get panelTlsLastUpdatedLabel;

  /// No description provided for @panelTlsNoRecentActions.
  ///
  /// In en, this message translates to:
  /// **'No recent local actions yet.'**
  String get panelTlsNoRecentActions;

  /// No description provided for @panelTlsUploadDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload panel certificate'**
  String get panelTlsUploadDialogTitle;

  /// No description provided for @panelTlsCertificatePemLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate PEM'**
  String get panelTlsCertificatePemLabel;

  /// No description provided for @panelTlsPrivateKeyPemLabel.
  ///
  /// In en, this message translates to:
  /// **'Private Key PEM'**
  String get panelTlsPrivateKeyPemLabel;

  /// No description provided for @panelTlsApplyUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply certificate update'**
  String get panelTlsApplyUpdateTitle;

  /// No description provided for @panelTlsApplyUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'This replaces the current panel TLS certificate and may interrupt active browser sessions until the gateway reload finishes.'**
  String get panelTlsApplyUpdateMessage;

  /// No description provided for @panelTlsDownloadDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Download certificate bundle'**
  String get panelTlsDownloadDialogTitle;

  /// No description provided for @panelTlsDownloadDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Use downloads for backup or external validation only. Handle private keys carefully after export.'**
  String get panelTlsDownloadDialogMessage;

  /// No description provided for @panelTlsContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get panelTlsContinueAction;

  /// No description provided for @panelTlsDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Downloaded certificate bundle ({bytes} bytes)'**
  String panelTlsDownloadSuccess(int bytes);

  /// No description provided for @panelTlsHealthHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get panelTlsHealthHealthy;

  /// No description provided for @panelTlsHealthExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get panelTlsHealthExpiringSoon;

  /// No description provided for @panelTlsHealthExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get panelTlsHealthExpired;

  /// No description provided for @panelTlsHealthUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get panelTlsHealthUnknown;

  /// No description provided for @panelTlsRiskUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate expiry unknown'**
  String get panelTlsRiskUnknownTitle;

  /// No description provided for @panelTlsRiskUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'The panel certificate expiration time could not be parsed.'**
  String get panelTlsRiskUnknownMessage;

  /// No description provided for @panelTlsRiskExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate expired'**
  String get panelTlsRiskExpiredTitle;

  /// No description provided for @panelTlsRiskExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'The panel TLS certificate has already expired and should be replaced immediately.'**
  String get panelTlsRiskExpiredMessage;

  /// No description provided for @panelTlsRiskExpiringSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate expiring soon'**
  String get panelTlsRiskExpiringSoonTitle;

  /// No description provided for @panelTlsRiskExpiringSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'The panel TLS certificate expires in {days} day(s).'**
  String panelTlsRiskExpiringSoonMessage(int days);

  /// No description provided for @panelTlsRiskSelfSignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-signed certificate'**
  String get panelTlsRiskSelfSignedTitle;

  /// No description provided for @panelTlsRiskSelfSignedMessage.
  ///
  /// In en, this message translates to:
  /// **'Self-signed certificates can trigger browser trust warnings.'**
  String get panelTlsRiskSelfSignedMessage;

  /// No description provided for @panelTlsValidationDomainRequired.
  ///
  /// In en, this message translates to:
  /// **'Domain is required.'**
  String get panelTlsValidationDomainRequired;

  /// No description provided for @panelTlsValidationCertificateRequired.
  ///
  /// In en, this message translates to:
  /// **'Certificate content is required.'**
  String get panelTlsValidationCertificateRequired;

  /// No description provided for @panelTlsValidationCertificatePemRequired.
  ///
  /// In en, this message translates to:
  /// **'Certificate must contain a PEM certificate block.'**
  String get panelTlsValidationCertificatePemRequired;

  /// No description provided for @panelTlsValidationPrivateKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Private key content is required.'**
  String get panelTlsValidationPrivateKeyRequired;

  /// No description provided for @panelTlsValidationPrivateKeyPemRequired.
  ///
  /// In en, this message translates to:
  /// **'Private key must contain a PEM key block.'**
  String get panelTlsValidationPrivateKeyPemRequired;

  /// No description provided for @panelTlsHistoryLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded current panel TLS status for {domain}'**
  String panelTlsHistoryLoaded(String domain);

  /// No description provided for @panelTlsHistoryUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded a new panel TLS certificate for {domain}'**
  String panelTlsHistoryUploaded(String domain);

  /// No description provided for @panelTlsHistoryDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded panel TLS certificate bundle ({bytes} bytes)'**
  String panelTlsHistoryDownloaded(int bytes);

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'System Upgrade'**
  String get upgradeTitle;

  /// No description provided for @upgradeCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get upgradeCurrentVersion;

  /// No description provided for @upgradeCurrentVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current System Version'**
  String get upgradeCurrentVersionLabel;

  /// No description provided for @upgradeAvailableVersions.
  ///
  /// In en, this message translates to:
  /// **'Available Versions'**
  String get upgradeAvailableVersions;

  /// No description provided for @upgradeNoUpdates.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get upgradeNoUpdates;

  /// No description provided for @upgradeLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get upgradeLatest;

  /// No description provided for @upgradeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Upgrade'**
  String get upgradeConfirm;

  /// No description provided for @upgradeConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to upgrade to version {version}?'**
  String upgradeConfirmMessage(Object version);

  /// No description provided for @upgradeDowngradeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Downgrade'**
  String get upgradeDowngradeConfirm;

  /// No description provided for @upgradeDowngradeMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to downgrade to version {version}? Downgrade may cause data incompatibility.'**
  String upgradeDowngradeMessage(Object version);

  /// No description provided for @upgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeButton;

  /// No description provided for @upgradeDowngradeButton.
  ///
  /// In en, this message translates to:
  /// **'Downgrade'**
  String get upgradeDowngradeButton;

  /// No description provided for @upgradeStarted.
  ///
  /// In en, this message translates to:
  /// **'Upgrade started'**
  String get upgradeStarted;

  /// No description provided for @upgradeViewNotes.
  ///
  /// In en, this message translates to:
  /// **'View Release Notes'**
  String get upgradeViewNotes;

  /// No description provided for @upgradeNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} Release Notes'**
  String upgradeNotesTitle(Object version);

  /// No description provided for @upgradeNotesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get upgradeNotesLoading;

  /// No description provided for @upgradeNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No release notes available'**
  String get upgradeNotesEmpty;

  /// No description provided for @upgradeNotesError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get upgradeNotesError;

  /// No description provided for @monitorSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor Settings'**
  String get monitorSettingsTitle;

  /// No description provided for @monitorSettingsInterval.
  ///
  /// In en, this message translates to:
  /// **'Monitor Interval'**
  String get monitorSettingsInterval;

  /// No description provided for @monitorSettingsStoreDays.
  ///
  /// In en, this message translates to:
  /// **'Data Retention Days'**
  String get monitorSettingsStoreDays;

  /// No description provided for @monitorSettingsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Monitoring'**
  String get monitorSettingsEnable;

  /// No description provided for @systemSettingsCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get systemSettingsCurrentVersion;

  /// No description provided for @systemSettingsCheckingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get systemSettingsCheckingUpdate;

  /// No description provided for @systemSettingsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get systemSettingsClose;

  /// No description provided for @panelSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Panel Settings'**
  String get panelSettingsTitle;

  /// No description provided for @panelSettingsBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get panelSettingsBasicInfo;

  /// No description provided for @panelSettingsPanelName.
  ///
  /// In en, this message translates to:
  /// **'Panel Name'**
  String get panelSettingsPanelName;

  /// No description provided for @panelSettingsVersion.
  ///
  /// In en, this message translates to:
  /// **'System Version'**
  String get panelSettingsVersion;

  /// No description provided for @panelSettingsPort.
  ///
  /// In en, this message translates to:
  /// **'Listen Port'**
  String get panelSettingsPort;

  /// No description provided for @panelSettingsBindAddress.
  ///
  /// In en, this message translates to:
  /// **'Bind Address'**
  String get panelSettingsBindAddress;

  /// No description provided for @panelSettingsInterface.
  ///
  /// In en, this message translates to:
  /// **'Interface Settings'**
  String get panelSettingsInterface;

  /// No description provided for @panelSettingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get panelSettingsTheme;

  /// No description provided for @panelSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get panelSettingsLanguage;

  /// No description provided for @panelSettingsMenuTabs.
  ///
  /// In en, this message translates to:
  /// **'Menu Tabs'**
  String get panelSettingsMenuTabs;

  /// No description provided for @panelSettingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get panelSettingsAdvanced;

  /// No description provided for @panelSettingsDeveloperMode.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode'**
  String get panelSettingsDeveloperMode;

  /// No description provided for @panelSettingsIpv6.
  ///
  /// In en, this message translates to:
  /// **'IPv6'**
  String get panelSettingsIpv6;

  /// No description provided for @panelSettingsSessionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Session Timeout'**
  String get panelSettingsSessionTimeout;

  /// No description provided for @panelSettingsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String panelSettingsMinutes(String count);

  /// No description provided for @terminalSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminal Settings'**
  String get terminalSettingsTitle;

  /// No description provided for @terminalSettingsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display Settings'**
  String get terminalSettingsDisplay;

  /// No description provided for @terminalSettingsCursorStyle.
  ///
  /// In en, this message translates to:
  /// **'Cursor Style'**
  String get terminalSettingsCursorStyle;

  /// No description provided for @terminalSettingsCursorBlink.
  ///
  /// In en, this message translates to:
  /// **'Cursor Blink'**
  String get terminalSettingsCursorBlink;

  /// No description provided for @terminalSettingsFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get terminalSettingsFontSize;

  /// No description provided for @terminalSettingsScroll.
  ///
  /// In en, this message translates to:
  /// **'Scroll Settings'**
  String get terminalSettingsScroll;

  /// No description provided for @terminalSettingsScrollSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Scroll Sensitivity'**
  String get terminalSettingsScrollSensitivity;

  /// No description provided for @terminalSettingsScrollback.
  ///
  /// In en, this message translates to:
  /// **'Scrollback Buffer'**
  String get terminalSettingsScrollback;

  /// No description provided for @terminalSettingsStyle.
  ///
  /// In en, this message translates to:
  /// **'Style Settings'**
  String get terminalSettingsStyle;

  /// No description provided for @terminalSettingsLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get terminalSettingsLineHeight;

  /// No description provided for @terminalSettingsLetterSpacing.
  ///
  /// In en, this message translates to:
  /// **'Letter Spacing'**
  String get terminalSettingsLetterSpacing;

  /// No description provided for @terminalSettingsFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get terminalSettingsFontFamily;

  /// No description provided for @terminalSettingsBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get terminalSettingsBackgroundColor;

  /// No description provided for @terminalSettingsForegroundColor.
  ///
  /// In en, this message translates to:
  /// **'Foreground Color'**
  String get terminalSettingsForegroundColor;

  /// No description provided for @terminalSettingsDefaultLocalConnection.
  ///
  /// In en, this message translates to:
  /// **'Default Local Connection'**
  String get terminalSettingsDefaultLocalConnection;

  /// No description provided for @terminalSettingsShowLocalByDefault.
  ///
  /// In en, this message translates to:
  /// **'Show local session by default'**
  String get terminalSettingsShowLocalByDefault;

  /// No description provided for @terminalSettingsCurrentConnection.
  ///
  /// In en, this message translates to:
  /// **'Current connection'**
  String get terminalSettingsCurrentConnection;

  /// No description provided for @terminalSettingsPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get terminalSettingsPreview;

  /// No description provided for @terminalSettingsFontFamilyHint.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more monospaced fonts for terminal rendering.'**
  String get terminalSettingsFontFamilyHint;

  /// No description provided for @terminalSettingsCursorBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get terminalSettingsCursorBlock;

  /// No description provided for @terminalSettingsCursorUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get terminalSettingsCursorUnderline;

  /// No description provided for @terminalSettingsCursorBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get terminalSettingsCursorBar;

  /// No description provided for @terminalSettingsConnectionSetup.
  ///
  /// In en, this message translates to:
  /// **'Connection Setup'**
  String get terminalSettingsConnectionSetup;

  /// No description provided for @terminalSettingsTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get terminalSettingsTestConnection;

  /// No description provided for @terminalSettingsConnectionAuthMode.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get terminalSettingsConnectionAuthMode;

  /// No description provided for @terminalSettingsConnectionPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get terminalSettingsConnectionPassword;

  /// No description provided for @terminalSettingsConnectionPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get terminalSettingsConnectionPrivateKey;

  /// No description provided for @terminalSettingsConnectionPassPhrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get terminalSettingsConnectionPassPhrase;

  /// No description provided for @securitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettingsTitle;

  /// No description provided for @securitySettingsPasswordSection.
  ///
  /// In en, this message translates to:
  /// **'Password Management'**
  String get securitySettingsPasswordSection;

  /// No description provided for @securitySettingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get securitySettingsChangePassword;

  /// No description provided for @securitySettingsChangePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Change login password'**
  String get securitySettingsChangePasswordDesc;

  /// No description provided for @securitySettingsOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get securitySettingsOldPassword;

  /// No description provided for @securitySettingsNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get securitySettingsNewPassword;

  /// No description provided for @securitySettingsConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get securitySettingsConfirmPassword;

  /// No description provided for @securitySettingsPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get securitySettingsPasswordMismatch;

  /// No description provided for @securitySettingsMfaSection.
  ///
  /// In en, this message translates to:
  /// **'MFA Authentication'**
  String get securitySettingsMfaSection;

  /// No description provided for @securitySettingsMfaStatus.
  ///
  /// In en, this message translates to:
  /// **'MFA Status'**
  String get securitySettingsMfaStatus;

  /// No description provided for @securitySettingsMfaBind.
  ///
  /// In en, this message translates to:
  /// **'Bind MFA'**
  String get securitySettingsMfaBind;

  /// No description provided for @securitySettingsMfaUnbind.
  ///
  /// In en, this message translates to:
  /// **'Unbind MFA'**
  String get securitySettingsMfaUnbind;

  /// No description provided for @securitySettingsMfaUnbindDesc.
  ///
  /// In en, this message translates to:
  /// **'MFA authentication will be disabled after unbinding. Are you sure?'**
  String get securitySettingsMfaUnbindDesc;

  /// No description provided for @securitySettingsMfaScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code with authenticator app'**
  String get securitySettingsMfaScanQr;

  /// No description provided for @securitySettingsMfaSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret: {secret}'**
  String securitySettingsMfaSecret(Object secret);

  /// No description provided for @securitySettingsMfaCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get securitySettingsMfaCode;

  /// No description provided for @securitySettingsUnbindMfa.
  ///
  /// In en, this message translates to:
  /// **'Unbind MFA'**
  String get securitySettingsUnbindMfa;

  /// No description provided for @securitySettingsPasskeySection.
  ///
  /// In en, this message translates to:
  /// **'Passkey'**
  String get securitySettingsPasskeySection;

  /// No description provided for @securitySettingsPasskeyRegister.
  ///
  /// In en, this message translates to:
  /// **'Register Passkey'**
  String get securitySettingsPasskeyRegister;

  /// No description provided for @securitySettingsPasskeyRegisterDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new passkey on this device'**
  String get securitySettingsPasskeyRegisterDesc;

  /// No description provided for @securitySettingsPasskeyUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Passkey not supported'**
  String get securitySettingsPasskeyUnsupported;

  /// No description provided for @securitySettingsPasskeyUnsupportedDesc.
  ///
  /// In en, this message translates to:
  /// **'Current platform or browser does not support passkey.'**
  String get securitySettingsPasskeyUnsupportedDesc;

  /// No description provided for @securitySettingsPasskeyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No passkeys yet'**
  String get securitySettingsPasskeyEmpty;

  /// No description provided for @securitySettingsPasskeyCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get securitySettingsPasskeyCreatedAt;

  /// No description provided for @securitySettingsPasskeyLastUsedAt.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get securitySettingsPasskeyLastUsedAt;

  /// No description provided for @securitySettingsPasskeyName.
  ///
  /// In en, this message translates to:
  /// **'Passkey name'**
  String get securitySettingsPasskeyName;

  /// No description provided for @securitySettingsPasskeyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My iPhone or Work Laptop'**
  String get securitySettingsPasskeyNameHint;

  /// No description provided for @securitySettingsPasskeyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Passkey'**
  String get securitySettingsPasskeyDeleteTitle;

  /// No description provided for @securitySettingsPasskeyDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete passkey \"{name}\"? This action cannot be undone.'**
  String securitySettingsPasskeyDeleteMessage(String name);

  /// No description provided for @securitySettingsAccessControl.
  ///
  /// In en, this message translates to:
  /// **'Access Control'**
  String get securitySettingsAccessControl;

  /// No description provided for @securitySettingsSecurityEntrance.
  ///
  /// In en, this message translates to:
  /// **'Security Entrance'**
  String get securitySettingsSecurityEntrance;

  /// No description provided for @securitySettingsBindDomain.
  ///
  /// In en, this message translates to:
  /// **'Bind Domain'**
  String get securitySettingsBindDomain;

  /// No description provided for @securitySettingsAllowIPs.
  ///
  /// In en, this message translates to:
  /// **'Allowed IPs'**
  String get securitySettingsAllowIPs;

  /// No description provided for @securitySettingsPasswordPolicy.
  ///
  /// In en, this message translates to:
  /// **'Password Policy'**
  String get securitySettingsPasswordPolicy;

  /// No description provided for @securitySettingsComplexityVerification.
  ///
  /// In en, this message translates to:
  /// **'Complexity Verification'**
  String get securitySettingsComplexityVerification;

  /// No description provided for @securitySettingsExpirationDays.
  ///
  /// In en, this message translates to:
  /// **'Expiration Days'**
  String get securitySettingsExpirationDays;

  /// No description provided for @securitySettingsEnableMfa.
  ///
  /// In en, this message translates to:
  /// **'Enable MFA'**
  String get securitySettingsEnableMfa;

  /// No description provided for @securitySettingsDisableMfa.
  ///
  /// In en, this message translates to:
  /// **'Disable MFA'**
  String get securitySettingsDisableMfa;

  /// No description provided for @securitySettingsEnableMfaConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to enable MFA?'**
  String get securitySettingsEnableMfaConfirm;

  /// No description provided for @securitySettingsDisableMfaConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable MFA?'**
  String get securitySettingsDisableMfaConfirm;

  /// No description provided for @securitySettingsEnterMfaCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter MFA verification code'**
  String get securitySettingsEnterMfaCode;

  /// No description provided for @securitySettingsVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get securitySettingsVerifyCode;

  /// No description provided for @securitySettingsMfaCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get securitySettingsMfaCodeHint;

  /// No description provided for @securitySettingsMfaUnbound.
  ///
  /// In en, this message translates to:
  /// **'MFA unbound'**
  String get securitySettingsMfaUnbound;

  /// No description provided for @securitySettingsUnbindFailed.
  ///
  /// In en, this message translates to:
  /// **'Unbind failed'**
  String get securitySettingsUnbindFailed;

  /// No description provided for @snapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Snapshot Management'**
  String get snapshotTitle;

  /// No description provided for @snapshotCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Snapshot'**
  String get snapshotCreate;

  /// No description provided for @snapshotEmpty.
  ///
  /// In en, this message translates to:
  /// **'No snapshots'**
  String get snapshotEmpty;

  /// No description provided for @snapshotCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get snapshotCreatedAt;

  /// No description provided for @snapshotDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get snapshotDescription;

  /// No description provided for @snapshotRecover.
  ///
  /// In en, this message translates to:
  /// **'Recover'**
  String get snapshotRecover;

  /// No description provided for @snapshotDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get snapshotDownload;

  /// No description provided for @snapshotDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get snapshotDelete;

  /// No description provided for @snapshotImport.
  ///
  /// In en, this message translates to:
  /// **'Import Snapshot'**
  String get snapshotImport;

  /// No description provided for @snapshotRollback.
  ///
  /// In en, this message translates to:
  /// **'Rollback'**
  String get snapshotRollback;

  /// No description provided for @snapshotEditDesc.
  ///
  /// In en, this message translates to:
  /// **'Edit Description'**
  String get snapshotEditDesc;

  /// No description provided for @snapshotEnterDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter snapshot description (optional)'**
  String get snapshotEnterDesc;

  /// No description provided for @snapshotDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get snapshotDescLabel;

  /// No description provided for @snapshotDescHint.
  ///
  /// In en, this message translates to:
  /// **'Enter snapshot description'**
  String get snapshotDescHint;

  /// No description provided for @snapshotCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Snapshot created successfully'**
  String get snapshotCreateSuccess;

  /// No description provided for @snapshotCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create snapshot'**
  String get snapshotCreateFailed;

  /// No description provided for @snapshotImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Snapshot'**
  String get snapshotImportTitle;

  /// No description provided for @snapshotImportPath.
  ///
  /// In en, this message translates to:
  /// **'Snapshot File Path'**
  String get snapshotImportPath;

  /// No description provided for @snapshotImportPathHint.
  ///
  /// In en, this message translates to:
  /// **'Enter snapshot file path'**
  String get snapshotImportPathHint;

  /// No description provided for @snapshotImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Snapshot imported successfully'**
  String get snapshotImportSuccess;

  /// No description provided for @snapshotImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import snapshot'**
  String get snapshotImportFailed;

  /// No description provided for @snapshotRollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Rollback Snapshot'**
  String get snapshotRollbackTitle;

  /// No description provided for @snapshotRollbackConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to rollback to this snapshot? Current configuration will be overwritten.'**
  String get snapshotRollbackConfirm;

  /// No description provided for @snapshotRollbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Snapshot rolled back successfully'**
  String get snapshotRollbackSuccess;

  /// No description provided for @snapshotRollbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rollback snapshot'**
  String get snapshotRollbackFailed;

  /// No description provided for @snapshotEditDescTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Snapshot Description'**
  String get snapshotEditDescTitle;

  /// No description provided for @snapshotEditDescSuccess.
  ///
  /// In en, this message translates to:
  /// **'Description updated successfully'**
  String get snapshotEditDescSuccess;

  /// No description provided for @snapshotEditDescFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update description'**
  String get snapshotEditDescFailed;

  /// No description provided for @snapshotRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover Snapshot'**
  String get snapshotRecoverTitle;

  /// No description provided for @snapshotRecoverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to recover this snapshot? Current configuration will be overwritten.'**
  String get snapshotRecoverConfirm;

  /// No description provided for @snapshotRecoverSuccess.
  ///
  /// In en, this message translates to:
  /// **'Snapshot recovered successfully'**
  String get snapshotRecoverSuccess;

  /// No description provided for @snapshotRecoverFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to recover snapshot'**
  String get snapshotRecoverFailed;

  /// No description provided for @snapshotDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Snapshot'**
  String get snapshotDeleteTitle;

  /// No description provided for @snapshotDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete selected snapshots? This action cannot be undone.'**
  String get snapshotDeleteConfirm;

  /// No description provided for @snapshotDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Snapshot deleted successfully'**
  String get snapshotDeleteSuccess;

  /// No description provided for @snapshotDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete snapshot'**
  String get snapshotDeleteFailed;

  /// No description provided for @snapshotLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load snapshot list'**
  String get snapshotLoadFailed;

  /// No description provided for @snapshotLoadFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load snapshot list: {error}'**
  String snapshotLoadFailedWithError(String error);

  /// No description provided for @snapshotBackupAccountLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load backup accounts'**
  String get snapshotBackupAccountLoadFailed;

  /// No description provided for @snapshotNoBackupAccountHint.
  ///
  /// In en, this message translates to:
  /// **'No backup account available. Please add one in Backup Account management first.'**
  String get snapshotNoBackupAccountHint;

  /// No description provided for @snapshotBackupAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup Account'**
  String get snapshotBackupAccountLabel;

  /// No description provided for @snapshotCreateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to create snapshot'**
  String get snapshotCreateErrorTitle;

  /// No description provided for @snapshotImportErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to import snapshot'**
  String get snapshotImportErrorTitle;

  /// No description provided for @snapshotRecoverErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to recover snapshot'**
  String get snapshotRecoverErrorTitle;

  /// No description provided for @snapshotRollbackErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to rollback snapshot'**
  String get snapshotRollbackErrorTitle;

  /// No description provided for @snapshotEditDescErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to update description'**
  String get snapshotEditDescErrorTitle;

  /// No description provided for @snapshotDeleteErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete snapshot'**
  String get snapshotDeleteErrorTitle;

  /// No description provided for @proxySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Proxy Settings'**
  String get proxySettingsTitle;

  /// No description provided for @proxySettingsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Proxy'**
  String get proxySettingsEnable;

  /// No description provided for @proxySettingsType.
  ///
  /// In en, this message translates to:
  /// **'Proxy Type'**
  String get proxySettingsType;

  /// No description provided for @proxySettingsHttp.
  ///
  /// In en, this message translates to:
  /// **'HTTP Proxy'**
  String get proxySettingsHttp;

  /// No description provided for @proxySettingsHttps.
  ///
  /// In en, this message translates to:
  /// **'HTTPS Proxy'**
  String get proxySettingsHttps;

  /// No description provided for @proxySettingsHost.
  ///
  /// In en, this message translates to:
  /// **'Proxy Host'**
  String get proxySettingsHost;

  /// No description provided for @proxySettingsPort.
  ///
  /// In en, this message translates to:
  /// **'Proxy Port'**
  String get proxySettingsPort;

  /// No description provided for @proxySettingsUser.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get proxySettingsUser;

  /// No description provided for @proxySettingsPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get proxySettingsPassword;

  /// No description provided for @proxySettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Proxy settings saved'**
  String get proxySettingsSaved;

  /// No description provided for @proxySettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get proxySettingsFailed;

  /// No description provided for @bindSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bind Address'**
  String get bindSettingsTitle;

  /// No description provided for @bindSettingsAddress.
  ///
  /// In en, this message translates to:
  /// **'Bind Address'**
  String get bindSettingsAddress;

  /// No description provided for @bindSettingsPort.
  ///
  /// In en, this message translates to:
  /// **'Panel Port'**
  String get bindSettingsPort;

  /// No description provided for @bindSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Bind settings saved'**
  String get bindSettingsSaved;

  /// No description provided for @bindSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get bindSettingsFailed;

  /// No description provided for @serverModuleSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get serverModuleSystemSettings;

  /// No description provided for @filesFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get filesFavorites;

  /// No description provided for @filesFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get filesFavoritesEmpty;

  /// No description provided for @filesFavoritesEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Long press a file or folder to add to favorites'**
  String get filesFavoritesEmptyDesc;

  /// No description provided for @filesAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get filesAddToFavorites;

  /// No description provided for @filesRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get filesRemoveFromFavorites;

  /// No description provided for @filesFavoritesAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get filesFavoritesAdded;

  /// No description provided for @filesFavoritesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get filesFavoritesRemoved;

  /// No description provided for @filesNavigateToFolder.
  ///
  /// In en, this message translates to:
  /// **'Navigate to folder'**
  String get filesNavigateToFolder;

  /// No description provided for @filesFavoritesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load favorites'**
  String get filesFavoritesLoadFailed;

  /// No description provided for @filesPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Management'**
  String get filesPermissionTitle;

  /// No description provided for @filesPermissionMode.
  ///
  /// In en, this message translates to:
  /// **'Permission Mode'**
  String get filesPermissionMode;

  /// No description provided for @filesPermissionOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get filesPermissionOwner;

  /// No description provided for @filesPermissionGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get filesPermissionGroup;

  /// No description provided for @filesPermissionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get filesPermissionRead;

  /// No description provided for @filesPermissionWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get filesPermissionWrite;

  /// No description provided for @filesPermissionExecute.
  ///
  /// In en, this message translates to:
  /// **'Execute'**
  String get filesPermissionExecute;

  /// No description provided for @filesPermissionOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner Permissions'**
  String get filesPermissionOwnerLabel;

  /// No description provided for @filesPermissionGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Permissions'**
  String get filesPermissionGroupLabel;

  /// No description provided for @filesPermissionOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other Permissions'**
  String get filesPermissionOtherLabel;

  /// No description provided for @filesPermissionRecursive.
  ///
  /// In en, this message translates to:
  /// **'Apply recursively'**
  String get filesPermissionRecursive;

  /// No description provided for @filesPermissionUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get filesPermissionUser;

  /// No description provided for @filesPermissionUserHint.
  ///
  /// In en, this message translates to:
  /// **'Select user'**
  String get filesPermissionUserHint;

  /// No description provided for @filesPermissionGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Select group'**
  String get filesPermissionGroupHint;

  /// No description provided for @filesPermissionChangeOwner.
  ///
  /// In en, this message translates to:
  /// **'Change Owner'**
  String get filesPermissionChangeOwner;

  /// No description provided for @filesPermissionChangeMode.
  ///
  /// In en, this message translates to:
  /// **'Change Mode'**
  String get filesPermissionChangeMode;

  /// No description provided for @filesPermissionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Permission changed successfully'**
  String get filesPermissionSuccess;

  /// No description provided for @transferListTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer List'**
  String get transferListTitle;

  /// No description provided for @transferClearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed'**
  String get transferClearCompleted;

  /// No description provided for @transferEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transfer tasks'**
  String get transferEmpty;

  /// No description provided for @transferBackgroundDownloadUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Current platform does not support background downloads yet.'**
  String get transferBackgroundDownloadUnsupported;

  /// No description provided for @transferStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get transferStatusRunning;

  /// No description provided for @transferStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get transferStatusPaused;

  /// No description provided for @transferStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transferStatusCompleted;

  /// No description provided for @transferStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get transferStatusFailed;

  /// No description provided for @transferStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get transferStatusCancelled;

  /// No description provided for @transferStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get transferStatusPending;

  /// No description provided for @transferUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get transferUploading;

  /// No description provided for @transferDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get transferDownloading;

  /// No description provided for @transferChunks.
  ///
  /// In en, this message translates to:
  /// **'chunks'**
  String get transferChunks;

  /// No description provided for @transferSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get transferSpeed;

  /// No description provided for @transferEta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get transferEta;

  /// No description provided for @filesPermissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change permission'**
  String get filesPermissionFailed;

  /// No description provided for @filesPermissionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load permission info'**
  String get filesPermissionLoadFailed;

  /// No description provided for @filesPermissionOctal.
  ///
  /// In en, this message translates to:
  /// **'Octal notation'**
  String get filesPermissionOctal;

  /// No description provided for @filesPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'File Preview'**
  String get filesPreviewTitle;

  /// No description provided for @filesEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit File'**
  String get filesEditorTitle;

  /// No description provided for @filesPreviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get filesPreviewLoading;

  /// No description provided for @filesPreviewError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get filesPreviewError;

  /// No description provided for @filesPreviewUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Cannot preview this file type'**
  String get filesPreviewUnsupported;

  /// No description provided for @filesEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get filesEditorSave;

  /// No description provided for @filesEditorSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get filesEditorSaved;

  /// No description provided for @filesEditorUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get filesEditorUnsaved;

  /// No description provided for @filesEditorSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get filesEditorSaving;

  /// No description provided for @filesEditorEncoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get filesEditorEncoding;

  /// No description provided for @filesEditorLineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Line Numbers'**
  String get filesEditorLineNumbers;

  /// No description provided for @filesEditorWordWrap.
  ///
  /// In en, this message translates to:
  /// **'Word Wrap'**
  String get filesEditorWordWrap;

  /// No description provided for @filesGoToLine.
  ///
  /// In en, this message translates to:
  /// **'Go to Line'**
  String get filesGoToLine;

  /// No description provided for @filesLineNumber.
  ///
  /// In en, this message translates to:
  /// **'Line number'**
  String get filesLineNumber;

  /// No description provided for @filesReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get filesReload;

  /// No description provided for @filesEditorReloadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switching encoding will reload the file and discard unsaved changes. Continue?'**
  String get filesEditorReloadConfirm;

  /// No description provided for @filesEncodingConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert Encoding'**
  String get filesEncodingConvert;

  /// No description provided for @filesEncodingFrom.
  ///
  /// In en, this message translates to:
  /// **'From encoding'**
  String get filesEncodingFrom;

  /// No description provided for @filesEncodingTo.
  ///
  /// In en, this message translates to:
  /// **'To encoding'**
  String get filesEncodingTo;

  /// No description provided for @filesEncodingBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup original file'**
  String get filesEncodingBackup;

  /// No description provided for @filesEncodingConvertDone.
  ///
  /// In en, this message translates to:
  /// **'Encoding conversion succeeded'**
  String get filesEncodingConvertDone;

  /// No description provided for @filesEncodingConvertFailed.
  ///
  /// In en, this message translates to:
  /// **'Encoding conversion failed'**
  String get filesEncodingConvertFailed;

  /// No description provided for @filesEncodingLog.
  ///
  /// In en, this message translates to:
  /// **'Conversion Log'**
  String get filesEncodingLog;

  /// No description provided for @filesEncodingLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs'**
  String get filesEncodingLogEmpty;

  /// No description provided for @filesPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Image Preview'**
  String get filesPreviewImage;

  /// No description provided for @filesPreviewCode.
  ///
  /// In en, this message translates to:
  /// **'Code Preview'**
  String get filesPreviewCode;

  /// No description provided for @filesPreviewText.
  ///
  /// In en, this message translates to:
  /// **'Text Preview'**
  String get filesPreviewText;

  /// No description provided for @filesEditFile.
  ///
  /// In en, this message translates to:
  /// **'Edit File'**
  String get filesEditFile;

  /// No description provided for @filesActionWgetDownload.
  ///
  /// In en, this message translates to:
  /// **'Remote Download'**
  String get filesActionWgetDownload;

  /// No description provided for @filesWgetUrl.
  ///
  /// In en, this message translates to:
  /// **'Download URL'**
  String get filesWgetUrl;

  /// No description provided for @filesWgetUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter file URL'**
  String get filesWgetUrlHint;

  /// No description provided for @filesWgetFilename.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get filesWgetFilename;

  /// No description provided for @filesWgetFilenameHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use URL filename'**
  String get filesWgetFilenameHint;

  /// No description provided for @filesWgetOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite existing file'**
  String get filesWgetOverwrite;

  /// No description provided for @filesWgetDownload.
  ///
  /// In en, this message translates to:
  /// **'Start Download'**
  String get filesWgetDownload;

  /// No description provided for @filesWgetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Download successful: {path}'**
  String filesWgetSuccess(String path);

  /// No description provided for @filesWgetFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get filesWgetFailed;

  /// No description provided for @recycleBinRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get recycleBinRestore;

  /// No description provided for @recycleBinRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore {count} selected files?'**
  String recycleBinRestoreConfirm(int count);

  /// No description provided for @recycleBinRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Files restored successfully'**
  String get recycleBinRestoreSuccess;

  /// No description provided for @recycleBinRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore files'**
  String get recycleBinRestoreFailed;

  /// No description provided for @recycleBinRestoreSingleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore \"{name}\"?'**
  String recycleBinRestoreSingleConfirm(String name);

  /// No description provided for @recycleBinDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get recycleBinDeletePermanently;

  /// No description provided for @recycleBinDeletePermanentlyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete {count} selected files? This action cannot be undone.'**
  String recycleBinDeletePermanentlyConfirm(int count);

  /// No description provided for @recycleBinDeletePermanentlySuccess.
  ///
  /// In en, this message translates to:
  /// **'Files permanently deleted'**
  String get recycleBinDeletePermanentlySuccess;

  /// No description provided for @recycleBinDeletePermanentlyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete files permanently'**
  String get recycleBinDeletePermanentlyFailed;

  /// No description provided for @recycleBinDeletePermanentlySingleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \"{name}\"? This action cannot be undone.'**
  String recycleBinDeletePermanentlySingleConfirm(String name);

  /// No description provided for @recycleBinClear.
  ///
  /// In en, this message translates to:
  /// **'Clear Recycle Bin'**
  String get recycleBinClear;

  /// No description provided for @recycleBinClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the recycle bin? All files will be permanently deleted.'**
  String get recycleBinClearConfirm;

  /// No description provided for @recycleBinClearSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin cleared'**
  String get recycleBinClearSuccess;

  /// No description provided for @recycleBinClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear recycle bin'**
  String get recycleBinClearFailed;

  /// No description provided for @recycleBinSearch.
  ///
  /// In en, this message translates to:
  /// **'Search files'**
  String get recycleBinSearch;

  /// No description provided for @recycleBinEmpty.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin is empty'**
  String get recycleBinEmpty;

  /// No description provided for @recycleBinNoResults.
  ///
  /// In en, this message translates to:
  /// **'No files found'**
  String get recycleBinNoResults;

  /// No description provided for @recycleBinSourcePath.
  ///
  /// In en, this message translates to:
  /// **'Original path'**
  String get recycleBinSourcePath;

  /// No description provided for @transferManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Manager'**
  String get transferManagerTitle;

  /// No description provided for @transferFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transferFilterAll;

  /// No description provided for @transferFilterUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get transferFilterUploading;

  /// No description provided for @transferFilterDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get transferFilterDownloading;

  /// No description provided for @transferSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get transferSortNewest;

  /// No description provided for @transferSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get transferSortOldest;

  /// No description provided for @transferSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get transferSortName;

  /// No description provided for @transferSortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get transferSortSize;

  /// No description provided for @transferTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get transferTabActive;

  /// No description provided for @transferTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get transferTabPending;

  /// No description provided for @transferTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transferTabCompleted;

  /// No description provided for @transferFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get transferFileNotFound;

  /// No description provided for @transferFileAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'File already downloaded'**
  String get transferFileAlreadyDownloaded;

  /// No description provided for @transferFileLocationOpened.
  ///
  /// In en, this message translates to:
  /// **'File location opened'**
  String get transferFileLocationOpened;

  /// No description provided for @transferOpenFileError.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get transferOpenFileError;

  /// No description provided for @transferOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get transferOpenFile;

  /// No description provided for @transferOpenDownloadedFileUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Current platform does not support opening downloaded files directly.'**
  String get transferOpenDownloadedFileUnsupported;

  /// No description provided for @transferClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed Tasks'**
  String get transferClearTitle;

  /// No description provided for @transferClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all completed transfer tasks?'**
  String get transferClearConfirm;

  /// No description provided for @transferPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get transferPause;

  /// No description provided for @transferCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get transferCancel;

  /// No description provided for @transferResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get transferResume;

  /// No description provided for @transferOpenLocation.
  ///
  /// In en, this message translates to:
  /// **'Open Location'**
  String get transferOpenLocation;

  /// No description provided for @transferOpenDownloadsFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Downloads'**
  String get transferOpenDownloadsFolder;

  /// No description provided for @transferCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get transferCopyPath;

  /// No description provided for @transferCopyDirectoryPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Folder Path'**
  String get transferCopyDirectoryPath;

  /// No description provided for @transferDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get transferDownloads;

  /// No description provided for @transferUploads.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get transferUploads;

  /// No description provided for @transferSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get transferSettings;

  /// No description provided for @transferSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Settings'**
  String get transferSettingsTitle;

  /// No description provided for @transferHistoryRetentionHint.
  ///
  /// In en, this message translates to:
  /// **'History retention days (auto cleanup after)'**
  String get transferHistoryRetentionHint;

  /// No description provided for @transferHistoryDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String transferHistoryDays(int days);

  /// No description provided for @transferHistorySaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get transferHistorySaved;

  /// No description provided for @largeFileDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Large File Download'**
  String get largeFileDownloadTitle;

  /// No description provided for @largeFileDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'File is large, added to background download queue'**
  String get largeFileDownloadHint;

  /// No description provided for @largeFileDownloadView.
  ///
  /// In en, this message translates to:
  /// **'View Downloads'**
  String get largeFileDownloadView;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionStorageRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to save files'**
  String get permissionStorageRequired;

  /// No description provided for @permissionGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get permissionGoToSettings;

  /// No description provided for @fileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get fileSaveSuccess;

  /// No description provided for @fileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save file'**
  String get fileSaveFailed;

  /// No description provided for @fileSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String fileSaveLocation(String path);

  /// No description provided for @filesPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'File Properties'**
  String get filesPropertiesTitle;

  /// No description provided for @filesCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get filesCreatedLabel;

  /// No description provided for @filesModifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get filesModifiedLabel;

  /// No description provided for @filesAccessedLabel.
  ///
  /// In en, this message translates to:
  /// **'Accessed'**
  String get filesAccessedLabel;

  /// No description provided for @filesCreateLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Link'**
  String get filesCreateLinkTitle;

  /// No description provided for @filesLinkNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Link Name'**
  String get filesLinkNameLabel;

  /// No description provided for @filesLinkTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Link Type'**
  String get filesLinkTypeLabel;

  /// No description provided for @filesLinkTypeSymbolic.
  ///
  /// In en, this message translates to:
  /// **'Symbolic Link'**
  String get filesLinkTypeSymbolic;

  /// No description provided for @filesLinkTypeHard.
  ///
  /// In en, this message translates to:
  /// **'Hard Link'**
  String get filesLinkTypeHard;

  /// No description provided for @filesLinkPath.
  ///
  /// In en, this message translates to:
  /// **'Target Path'**
  String get filesLinkPath;

  /// No description provided for @filesContentSearch.
  ///
  /// In en, this message translates to:
  /// **'Content Search'**
  String get filesContentSearch;

  /// No description provided for @filesContentSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Content'**
  String get filesContentSearchHint;

  /// No description provided for @filesUploadHistory.
  ///
  /// In en, this message translates to:
  /// **'Upload History'**
  String get filesUploadHistory;

  /// No description provided for @filesMounts.
  ///
  /// In en, this message translates to:
  /// **'Mount Points'**
  String get filesMounts;

  /// No description provided for @filesActionUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get filesActionUp;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get commonError;

  /// No description provided for @commonCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Created successfully'**
  String get commonCreateSuccess;

  /// No description provided for @commonCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied successfully'**
  String get commonCopySuccess;

  /// No description provided for @appStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get appStoreTitle;

  /// No description provided for @appsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Management'**
  String get appsPageTitle;

  /// No description provided for @appsInstalledEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No apps installed yet. Visit the App Store to install one.'**
  String get appsInstalledEmptyDescription;

  /// No description provided for @appStoreInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get appStoreInstall;

  /// No description provided for @appStoreInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get appStoreInstalled;

  /// No description provided for @appStoreUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appStoreUpdate;

  /// No description provided for @appStoreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get appStoreSearchHint;

  /// No description provided for @appStoreSync.
  ///
  /// In en, this message translates to:
  /// **'Sync Apps'**
  String get appStoreSync;

  /// No description provided for @appStoreSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Apps synced successfully'**
  String get appStoreSyncSuccess;

  /// No description provided for @appStoreSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync apps'**
  String get appStoreSyncFailed;

  /// No description provided for @appStoreSyncLocal.
  ///
  /// In en, this message translates to:
  /// **'Sync Local Apps'**
  String get appStoreSyncLocal;

  /// No description provided for @appStoreSyncLocalSuccess.
  ///
  /// In en, this message translates to:
  /// **'Local apps synced successfully'**
  String get appStoreSyncLocalSuccess;

  /// No description provided for @appStoreSyncLocalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync local apps'**
  String get appStoreSyncLocalFailed;

  /// No description provided for @appIgnoredUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Ignored Updates'**
  String get appIgnoredUpdatesTitle;

  /// No description provided for @appIgnoredUpdatesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ignored apps'**
  String get appIgnoredUpdatesLoadFailed;

  /// No description provided for @appIgnoredUpdatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ignored updates'**
  String get appIgnoredUpdatesEmpty;

  /// No description provided for @appIgnoreUpdate.
  ///
  /// In en, this message translates to:
  /// **'Ignore Update'**
  String get appIgnoreUpdate;

  /// No description provided for @appIgnoreUpdateReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get appIgnoreUpdateReason;

  /// No description provided for @appIgnoreUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Update ignored'**
  String get appIgnoreUpdateSuccess;

  /// No description provided for @appIgnoreUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to ignore update: {error}'**
  String appIgnoreUpdateFailed(String error);

  /// No description provided for @appIgnoreUpdateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ignore'**
  String get appIgnoreUpdateCancel;

  /// No description provided for @appStoreTagWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get appStoreTagWebsite;

  /// No description provided for @appStoreTagDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get appStoreTagDatabase;

  /// No description provided for @appStoreTagRuntime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get appStoreTagRuntime;

  /// No description provided for @appStoreTagTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get appStoreTagTool;

  /// No description provided for @appStoreTagDocker.
  ///
  /// In en, this message translates to:
  /// **'Docker'**
  String get appStoreTagDocker;

  /// No description provided for @appStoreTagCICD.
  ///
  /// In en, this message translates to:
  /// **'CI/CD'**
  String get appStoreTagCICD;

  /// No description provided for @appStoreTagMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get appStoreTagMonitoring;

  /// No description provided for @appDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'App Details'**
  String get appDetailTitle;

  /// No description provided for @appStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get appStatusRunning;

  /// No description provided for @appStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get appStatusStopped;

  /// No description provided for @appStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get appStatusError;

  /// No description provided for @appActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get appActionStart;

  /// No description provided for @appActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get appActionStop;

  /// No description provided for @appActionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get appActionRestart;

  /// No description provided for @appActionUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get appActionUninstall;

  /// No description provided for @appServiceList.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get appServiceList;

  /// No description provided for @appBaseInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get appBaseInfo;

  /// No description provided for @appInfoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get appInfoName;

  /// No description provided for @appInfoVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appInfoVersion;

  /// No description provided for @appInfoStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get appInfoStatus;

  /// No description provided for @appInfoCreated.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get appInfoCreated;

  /// No description provided for @appUninstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to uninstall this app? This action cannot be undone.'**
  String get appUninstallConfirm;

  /// No description provided for @appNoPortInfo.
  ///
  /// In en, this message translates to:
  /// **'No port info'**
  String get appNoPortInfo;

  /// No description provided for @appConnInfo.
  ///
  /// In en, this message translates to:
  /// **'Connection Info'**
  String get appConnInfo;

  /// No description provided for @appConnInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load connection info'**
  String get appConnInfoFailed;

  /// No description provided for @appReadmeImageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Image not supported: {url}'**
  String appReadmeImageUnsupported(String url);

  /// No description provided for @appOperateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get appOperateSuccess;

  /// No description provided for @commonPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get commonPort;

  /// No description provided for @commonParams.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get commonParams;

  /// No description provided for @appUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdate;

  /// No description provided for @appUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update App'**
  String get appUpdateTitle;

  /// No description provided for @appUpdateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to update {app} to {version}?'**
  String appUpdateConfirm(String app, String version);

  /// No description provided for @appUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Update started successfully'**
  String get appUpdateSuccess;

  /// No description provided for @appUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String appUpdateFailed(String error);

  /// No description provided for @appOperateFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String appOperateFailed(String error);

  /// No description provided for @appInstallContainerName.
  ///
  /// In en, this message translates to:
  /// **'Container Name'**
  String get appInstallContainerName;

  /// No description provided for @appInstallCpuLimit.
  ///
  /// In en, this message translates to:
  /// **'CPU Limit'**
  String get appInstallCpuLimit;

  /// No description provided for @appInstallMemoryLimit.
  ///
  /// In en, this message translates to:
  /// **'Memory Limit'**
  String get appInstallMemoryLimit;

  /// No description provided for @appInstallPorts.
  ///
  /// In en, this message translates to:
  /// **'Ports'**
  String get appInstallPorts;

  /// No description provided for @appInstallEnv.
  ///
  /// In en, this message translates to:
  /// **'Environment Variables'**
  String get appInstallEnv;

  /// No description provided for @appInstallEnvKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get appInstallEnvKey;

  /// No description provided for @appInstallEnvValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get appInstallEnvValue;

  /// No description provided for @appInstallPortService.
  ///
  /// In en, this message translates to:
  /// **'Service Port'**
  String get appInstallPortService;

  /// No description provided for @appInstallPortHost.
  ///
  /// In en, this message translates to:
  /// **'Host Port'**
  String get appInstallPortHost;

  /// No description provided for @appTabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get appTabInfo;

  /// No description provided for @appTabConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get appTabConfig;

  /// No description provided for @containerTitle.
  ///
  /// In en, this message translates to:
  /// **'Container Management'**
  String get containerTitle;

  /// No description provided for @containerStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get containerStatusRunning;

  /// No description provided for @containerStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get containerStatusStopped;

  /// No description provided for @containerStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get containerStatusPaused;

  /// No description provided for @containerStatusExited.
  ///
  /// In en, this message translates to:
  /// **'Exited'**
  String get containerStatusExited;

  /// No description provided for @containerStatusRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting'**
  String get containerStatusRestarting;

  /// No description provided for @containerStatusRemoving.
  ///
  /// In en, this message translates to:
  /// **'Removing'**
  String get containerStatusRemoving;

  /// No description provided for @containerStatusDead.
  ///
  /// In en, this message translates to:
  /// **'Dead'**
  String get containerStatusDead;

  /// No description provided for @containerStatusCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get containerStatusCreated;

  /// No description provided for @containerActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get containerActionStart;

  /// No description provided for @containerActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get containerActionStop;

  /// No description provided for @containerActionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get containerActionRestart;

  /// No description provided for @containerActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get containerActionDelete;

  /// No description provided for @containerActionLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get containerActionLogs;

  /// No description provided for @containerActionTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get containerActionTerminal;

  /// No description provided for @containerActionStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get containerActionStats;

  /// No description provided for @containerActionInspect.
  ///
  /// In en, this message translates to:
  /// **'Inspect'**
  String get containerActionInspect;

  /// No description provided for @containerInspectJson.
  ///
  /// In en, this message translates to:
  /// **'Inspect JSON'**
  String get containerInspectJson;

  /// No description provided for @containerTabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get containerTabInfo;

  /// No description provided for @containerTabLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get containerTabLogs;

  /// No description provided for @containerTabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get containerTabStats;

  /// No description provided for @containerTabTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get containerTabTerminal;

  /// No description provided for @containerDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Container Details'**
  String get containerDetailTitle;

  /// No description provided for @containerInfoId.
  ///
  /// In en, this message translates to:
  /// **'Container ID'**
  String get containerInfoId;

  /// No description provided for @containerInfoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get containerInfoName;

  /// No description provided for @containerInfoImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get containerInfoImage;

  /// No description provided for @containerInfoStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get containerInfoStatus;

  /// No description provided for @containerInfoCreated.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get containerInfoCreated;

  /// No description provided for @containerInfoCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get containerInfoCommand;

  /// No description provided for @containerInfoPorts.
  ///
  /// In en, this message translates to:
  /// **'Port Bindings'**
  String get containerInfoPorts;

  /// No description provided for @containerInfoEnv.
  ///
  /// In en, this message translates to:
  /// **'Environment Variables'**
  String get containerInfoEnv;

  /// No description provided for @containerInfoLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get containerInfoLabels;

  /// No description provided for @containerInfoProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get containerInfoProject;

  /// No description provided for @containerStatsCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU Usage'**
  String get containerStatsCpu;

  /// No description provided for @containerStatsMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory Usage'**
  String get containerStatsMemory;

  /// No description provided for @containerStatsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network I/O'**
  String get containerStatsNetwork;

  /// No description provided for @containerStatsBlock.
  ///
  /// In en, this message translates to:
  /// **'Block I/O'**
  String get containerStatsBlock;

  /// No description provided for @containerLogsAutoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Auto Refresh'**
  String get containerLogsAutoRefresh;

  /// No description provided for @containerLogsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download Logs'**
  String get containerLogsDownload;

  /// No description provided for @containerDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete container {name}? This action cannot be undone.'**
  String containerDeleteConfirm(Object name);

  /// No description provided for @containerOperateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get containerOperateSuccess;

  /// No description provided for @containerOperateFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String containerOperateFailed(String error);

  /// No description provided for @containerActionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get containerActionRename;

  /// No description provided for @containerActionUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get containerActionUpgrade;

  /// No description provided for @containerActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get containerActionEdit;

  /// No description provided for @containerActionCommit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get containerActionCommit;

  /// No description provided for @containerActionCleanLog.
  ///
  /// In en, this message translates to:
  /// **'Clean Logs'**
  String get containerActionCleanLog;

  /// No description provided for @containerActionDownloadLog.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get containerActionDownloadLog;

  /// No description provided for @containerActionPrune.
  ///
  /// In en, this message translates to:
  /// **'Prune'**
  String get containerActionPrune;

  /// No description provided for @containerActionTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get containerActionTag;

  /// No description provided for @containerActionPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get containerActionPush;

  /// No description provided for @containerActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get containerActionSave;

  /// No description provided for @containerImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get containerImage;

  /// No description provided for @containerUpgradeForcePull.
  ///
  /// In en, this message translates to:
  /// **'Force Pull'**
  String get containerUpgradeForcePull;

  /// No description provided for @containerCommitImage.
  ///
  /// In en, this message translates to:
  /// **'New Image'**
  String get containerCommitImage;

  /// No description provided for @containerCommitAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get containerCommitAuthor;

  /// No description provided for @containerCommitComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get containerCommitComment;

  /// No description provided for @containerCommitPause.
  ///
  /// In en, this message translates to:
  /// **'Pause Container'**
  String get containerCommitPause;

  /// No description provided for @containerCpuShares.
  ///
  /// In en, this message translates to:
  /// **'CPU Shares'**
  String get containerCpuShares;

  /// No description provided for @containerMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get containerMemory;

  /// No description provided for @containerCleanLogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clean logs for {name}?'**
  String containerCleanLogConfirm(String name);

  /// No description provided for @containerPruneType.
  ///
  /// In en, this message translates to:
  /// **'Prune Type'**
  String get containerPruneType;

  /// No description provided for @containerPruneTypeContainer.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get containerPruneTypeContainer;

  /// No description provided for @containerPruneTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get containerPruneTypeImage;

  /// No description provided for @containerPruneTypeVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get containerPruneTypeVolume;

  /// No description provided for @containerPruneTypeNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get containerPruneTypeNetwork;

  /// No description provided for @containerPruneTypeBuildCache.
  ///
  /// In en, this message translates to:
  /// **'Build Cache'**
  String get containerPruneTypeBuildCache;

  /// No description provided for @containerPruneWithTagAll.
  ///
  /// In en, this message translates to:
  /// **'Include All Tags'**
  String get containerPruneWithTagAll;

  /// No description provided for @containerBuildContext.
  ///
  /// In en, this message translates to:
  /// **'Context Directory'**
  String get containerBuildContext;

  /// No description provided for @containerBuildDockerfile.
  ///
  /// In en, this message translates to:
  /// **'Dockerfile Path'**
  String get containerBuildDockerfile;

  /// No description provided for @containerBuildTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get containerBuildTags;

  /// No description provided for @containerBuildArgs.
  ///
  /// In en, this message translates to:
  /// **'Build Args'**
  String get containerBuildArgs;

  /// No description provided for @containerImageLoadPath.
  ///
  /// In en, this message translates to:
  /// **'Image File Path'**
  String get containerImageLoadPath;

  /// No description provided for @containerTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Image'**
  String get containerTagLabel;

  /// No description provided for @containerPushConfirm.
  ///
  /// In en, this message translates to:
  /// **'Push this image?'**
  String get containerPushConfirm;

  /// No description provided for @containerSavePath.
  ///
  /// In en, this message translates to:
  /// **'Save Path'**
  String get containerSavePath;

  /// No description provided for @containerNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs'**
  String get containerNoLogs;

  /// No description provided for @containerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get containerLoading;

  /// No description provided for @containerTerminalConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get containerTerminalConnect;

  /// No description provided for @containerTerminalDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get containerTerminalDisconnect;

  /// No description provided for @commonStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStart;

  /// No description provided for @commonStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get commonStop;

  /// No description provided for @commonRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get commonRestart;

  /// No description provided for @commonLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get commonLogs;

  /// No description provided for @commonDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get commonDeleteConfirm;

  /// No description provided for @orchestrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Orchestration'**
  String get orchestrationTitle;

  /// No description provided for @orchestrationCompose.
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get orchestrationCompose;

  /// No description provided for @orchestrationImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get orchestrationImages;

  /// No description provided for @orchestrationNetworks.
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get orchestrationNetworks;

  /// No description provided for @orchestrationVolumes.
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get orchestrationVolumes;

  /// No description provided for @orchestrationPullImage.
  ///
  /// In en, this message translates to:
  /// **'Pull Image'**
  String get orchestrationPullImage;

  /// No description provided for @orchestrationPullImageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter image name (e.g. nginx:latest)'**
  String get orchestrationPullImageHint;

  /// No description provided for @orchestrationPullSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image pull started'**
  String get orchestrationPullSuccess;

  /// No description provided for @orchestrationPullFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pull image'**
  String get orchestrationPullFailed;

  /// No description provided for @orchestrationComposeCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Compose Project'**
  String get orchestrationComposeCreateTitle;

  /// No description provided for @orchestrationComposeContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Compose Content'**
  String get orchestrationComposeContentLabel;

  /// No description provided for @orchestrationComposeContentHint.
  ///
  /// In en, this message translates to:
  /// **'Paste docker-compose.yml content'**
  String get orchestrationComposeContentHint;

  /// No description provided for @orchestrationComposeUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Compose'**
  String get orchestrationComposeUpdate;

  /// No description provided for @orchestrationComposeTest.
  ///
  /// In en, this message translates to:
  /// **'Test Compose'**
  String get orchestrationComposeTest;

  /// No description provided for @orchestrationComposeCleanLog.
  ///
  /// In en, this message translates to:
  /// **'Clean Compose Logs'**
  String get orchestrationComposeCleanLog;

  /// No description provided for @orchestrationComposeCleanLogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clean logs for {name}?'**
  String orchestrationComposeCleanLogConfirm(String name);

  /// No description provided for @orchestrationComposeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Compose'**
  String get orchestrationComposeDelete;

  /// No description provided for @orchestrationComposeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop and remove all containers in {name}?'**
  String orchestrationComposeDeleteConfirm(String name);

  /// No description provided for @orchestrationComposeForceDelete.
  ///
  /// In en, this message translates to:
  /// **'Force Delete'**
  String get orchestrationComposeForceDelete;

  /// No description provided for @orchestrationComposeDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete Compose File'**
  String get orchestrationComposeDeleteFile;

  /// No description provided for @orchestrationStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get orchestrationStatusUnknown;

  /// No description provided for @orchestrationServicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get orchestrationServicesLabel;

  /// No description provided for @orchestrationImageBuild.
  ///
  /// In en, this message translates to:
  /// **'Build Image'**
  String get orchestrationImageBuild;

  /// No description provided for @orchestrationImageLoad.
  ///
  /// In en, this message translates to:
  /// **'Load Image'**
  String get orchestrationImageLoad;

  /// No description provided for @orchestrationImageSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Images'**
  String get orchestrationImageSearch;

  /// No description provided for @orchestrationImageSearchResult.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get orchestrationImageSearchResult;

  /// No description provided for @orchestrationImageId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get orchestrationImageId;

  /// No description provided for @orchestrationImageDigest.
  ///
  /// In en, this message translates to:
  /// **'Digest'**
  String get orchestrationImageDigest;

  /// No description provided for @orchestrationImageTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get orchestrationImageTags;

  /// No description provided for @orchestrationImageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get orchestrationImageSizeLabel;

  /// No description provided for @orchestrationImageCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get orchestrationImageCreatedLabel;

  /// No description provided for @orchestrationImageInUse.
  ///
  /// In en, this message translates to:
  /// **'In Use'**
  String get orchestrationImageInUse;

  /// No description provided for @appActionWeb.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get appActionWeb;

  /// No description provided for @containerManagement.
  ///
  /// In en, this message translates to:
  /// **'Container Management'**
  String get containerManagement;

  /// No description provided for @orchestration.
  ///
  /// In en, this message translates to:
  /// **'Orchestration'**
  String get orchestration;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @networks.
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get networks;

  /// No description provided for @volumes.
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get volumes;

  /// No description provided for @compose.
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get compose;

  /// No description provided for @ports.
  ///
  /// In en, this message translates to:
  /// **'Ports'**
  String get ports;

  /// No description provided for @env.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get env;

  /// No description provided for @viewContainer.
  ///
  /// In en, this message translates to:
  /// **'View Container'**
  String get viewContainer;

  /// No description provided for @webUI.
  ///
  /// In en, this message translates to:
  /// **'Web UI'**
  String get webUI;

  /// No description provided for @readme.
  ///
  /// In en, this message translates to:
  /// **'README'**
  String get readme;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get appDescription;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting'**
  String get statusRestarting;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get actionRestart;

  /// No description provided for @actionUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get actionUninstall;

  /// No description provided for @logSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get logSearchHint;

  /// No description provided for @logRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh Logs'**
  String get logRefresh;

  /// No description provided for @logScrollToBottom.
  ///
  /// In en, this message translates to:
  /// **'Scroll to Bottom'**
  String get logScrollToBottom;

  /// No description provided for @logSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get logSettings;

  /// No description provided for @logSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Settings'**
  String get logSettingsTitle;

  /// No description provided for @logFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get logFontSize;

  /// No description provided for @logWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap Text'**
  String get logWrap;

  /// No description provided for @logShowTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Show Timestamp'**
  String get logShowTimestamp;

  /// No description provided for @logTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get logTheme;

  /// No description provided for @logNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs available'**
  String get logNoLogs;

  /// No description provided for @logNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get logNoMatches;

  /// No description provided for @logTimestampFormat.
  ///
  /// In en, this message translates to:
  /// **'Timestamp Format'**
  String get logTimestampFormat;

  /// No description provided for @logTimestampAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Absolute'**
  String get logTimestampAbsolute;

  /// No description provided for @logTimestampRelative.
  ///
  /// In en, this message translates to:
  /// **'Relative'**
  String get logTimestampRelative;

  /// No description provided for @logMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} matches'**
  String logMatchCount(int current, int total);

  /// No description provided for @logPreviousMatch.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get logPreviousMatch;

  /// No description provided for @logNextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get logNextMatch;

  /// No description provided for @logEditTheme.
  ///
  /// In en, this message translates to:
  /// **'Edit Theme Rules'**
  String get logEditTheme;

  /// No description provided for @logThemeEditor.
  ///
  /// In en, this message translates to:
  /// **'Theme Editor'**
  String get logThemeEditor;

  /// No description provided for @logRulePattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get logRulePattern;

  /// No description provided for @logRuleType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get logRuleType;

  /// No description provided for @logRuleCaseSensitive.
  ///
  /// In en, this message translates to:
  /// **'Case Sensitive'**
  String get logRuleCaseSensitive;

  /// No description provided for @logRuleCaseInsensitive.
  ///
  /// In en, this message translates to:
  /// **'Case Insensitive'**
  String get logRuleCaseInsensitive;

  /// No description provided for @logRuleColor.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get logRuleColor;

  /// No description provided for @logRuleBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get logRuleBackgroundColor;

  /// No description provided for @logRuleBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get logRuleBold;

  /// No description provided for @logRuleItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get logRuleItalic;

  /// No description provided for @logRuleUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get logRuleUnderline;

  /// No description provided for @logImportTheme.
  ///
  /// In en, this message translates to:
  /// **'Import Theme'**
  String get logImportTheme;

  /// No description provided for @logExportTheme.
  ///
  /// In en, this message translates to:
  /// **'Export Theme'**
  String get logExportTheme;

  /// No description provided for @logImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Theme imported successfully'**
  String get logImportSuccess;

  /// No description provided for @logInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON'**
  String get logInvalidJson;

  /// No description provided for @logLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get logLineHeight;

  /// No description provided for @logViewMode.
  ///
  /// In en, this message translates to:
  /// **'View Mode'**
  String get logViewMode;

  /// No description provided for @logModeWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap'**
  String get logModeWrap;

  /// No description provided for @logModeScrollLine.
  ///
  /// In en, this message translates to:
  /// **'Scroll Line'**
  String get logModeScrollLine;

  /// No description provided for @logModeScrollPage.
  ///
  /// In en, this message translates to:
  /// **'Scroll Page'**
  String get logModeScrollPage;

  /// No description provided for @themeDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color'**
  String get themeDynamicColor;

  /// No description provided for @themeDynamicColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Use wallpaper color as theme color'**
  String get themeDynamicColorDesc;

  /// No description provided for @themeSeedColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get themeSeedColor;

  /// No description provided for @themeSeedColorFallbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Used when dynamic color is unavailable'**
  String get themeSeedColorFallbackDesc;

  /// No description provided for @containerTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get containerTabOverview;

  /// No description provided for @containerTabContainers.
  ///
  /// In en, this message translates to:
  /// **'Containers'**
  String get containerTabContainers;

  /// No description provided for @containerTabOrchestration.
  ///
  /// In en, this message translates to:
  /// **'Orchestration'**
  String get containerTabOrchestration;

  /// No description provided for @containerTabImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get containerTabImages;

  /// No description provided for @containerTabNetworks.
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get containerTabNetworks;

  /// No description provided for @containerTabVolumes.
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get containerTabVolumes;

  /// No description provided for @containerTabRepositories.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get containerTabRepositories;

  /// No description provided for @containerTabTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get containerTabTemplates;

  /// No description provided for @containerTabConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get containerTabConfig;

  /// No description provided for @containerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search containers'**
  String get containerSearch;

  /// No description provided for @containerFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter containers'**
  String get containerFilter;

  /// No description provided for @containerNetworkSubnetLabel.
  ///
  /// In en, this message translates to:
  /// **'Subnet'**
  String get containerNetworkSubnetLabel;

  /// No description provided for @containerNetworkSubnetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 172.20.0.0/16'**
  String get containerNetworkSubnetHint;

  /// No description provided for @containerNetworkGatewayLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get containerNetworkGatewayLabel;

  /// No description provided for @containerNetworkGatewayHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 172.20.0.1'**
  String get containerNetworkGatewayHint;

  /// No description provided for @containerRepoUrlExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://github.com/user/repo'**
  String get containerRepoUrlExample;

  /// No description provided for @containerTemplateContentHint.
  ///
  /// In en, this message translates to:
  /// **'YAML content'**
  String get containerTemplateContentHint;

  /// No description provided for @containerCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Container'**
  String get containerCreate;

  /// No description provided for @containerCreateBasicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Configuration'**
  String get containerCreateBasicSectionTitle;

  /// No description provided for @containerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No containers'**
  String get containerEmptyTitle;

  /// No description provided for @containerEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to create a container'**
  String get containerEmptyDesc;

  /// No description provided for @containerStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Container Stats'**
  String get containerStatsTitle;

  /// No description provided for @containerStatsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed Status'**
  String get containerStatsDetailTitle;

  /// No description provided for @containerStatsImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get containerStatsImages;

  /// No description provided for @containerStatsNetworks.
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get containerStatsNetworks;

  /// No description provided for @containerStatsVolumes.
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get containerStatsVolumes;

  /// No description provided for @containerStatsRepos.
  ///
  /// In en, this message translates to:
  /// **'Repos'**
  String get containerStatsRepos;

  /// No description provided for @containerStatsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get containerStatsTotal;

  /// No description provided for @containerStatsRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get containerStatsRunning;

  /// No description provided for @containerStatsStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get containerStatsStopped;

  /// No description provided for @containerFeatureDeveloping.
  ///
  /// In en, this message translates to:
  /// **'{feature} is under development'**
  String containerFeatureDeveloping(Object feature);

  /// No description provided for @orchestrationCreateProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get orchestrationCreateProject;

  /// No description provided for @orchestrationCreateNetwork.
  ///
  /// In en, this message translates to:
  /// **'Create Network'**
  String get orchestrationCreateNetwork;

  /// No description provided for @orchestrationCreateVolume.
  ///
  /// In en, this message translates to:
  /// **'Create Volume'**
  String get orchestrationCreateVolume;

  /// No description provided for @orchestrationCreateRepo.
  ///
  /// In en, this message translates to:
  /// **'Create Repository'**
  String get orchestrationCreateRepo;

  /// No description provided for @orchestrationCreateTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get orchestrationCreateTemplate;

  /// No description provided for @operationsCenterPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations Center'**
  String get operationsCenterPageTitle;

  /// No description provided for @operationsCenterIntro.
  ///
  /// In en, this message translates to:
  /// **'A unified entry for server operations tools, organized by category.'**
  String get operationsCenterIntro;

  /// No description provided for @operationsCenterServerEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations Center'**
  String get operationsCenterServerEntryTitle;

  /// No description provided for @operationsCenterServerEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automation, runtime, and system control in one place'**
  String get operationsCenterServerEntrySubtitle;

  /// No description provided for @operationsCenterAutomationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get operationsCenterAutomationSectionTitle;

  /// No description provided for @operationsCenterAutomationSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Commands, schedules, scripts, and backup flows'**
  String get operationsCenterAutomationSectionDescription;

  /// No description provided for @operationsCenterRuntimeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime & Delivery'**
  String get operationsCenterRuntimeSectionTitle;

  /// No description provided for @operationsCenterRuntimeSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Shared runtime chains for PHP and Node.js'**
  String get operationsCenterRuntimeSectionDescription;

  /// No description provided for @operationsCenterSystemSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'System Control'**
  String get operationsCenterSystemSectionTitle;

  /// No description provided for @operationsCenterSystemSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Groups, host assets, SSH, processes, logs, and toolbox tools'**
  String get operationsCenterSystemSectionDescription;

  /// No description provided for @operationsCommandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get operationsCommandsTitle;

  /// No description provided for @operationsCommandFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Command Form'**
  String get operationsCommandFormTitle;

  /// No description provided for @operationsHostAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Assets'**
  String get operationsHostAssetsTitle;

  /// No description provided for @operationsHostAssetFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Asset Form'**
  String get operationsHostAssetFormTitle;

  /// No description provided for @operationsSshTitle.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get operationsSshTitle;

  /// No description provided for @operationsSshCertsTitle.
  ///
  /// In en, this message translates to:
  /// **'SSH Certs'**
  String get operationsSshCertsTitle;

  /// No description provided for @operationsSshLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'SSH Logs'**
  String get operationsSshLogsTitle;

  /// No description provided for @operationsSshSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'SSH Sessions'**
  String get operationsSshSessionsTitle;

  /// No description provided for @operationsProcessesTitle.
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get operationsProcessesTitle;

  /// No description provided for @operationsProcessDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Process Detail'**
  String get operationsProcessDetailTitle;

  /// No description provided for @operationsToolboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Toolbox'**
  String get operationsToolboxTitle;

  /// No description provided for @operationsCronjobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cronjobs'**
  String get operationsCronjobsTitle;

  /// No description provided for @operationsCronjobFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Cronjob Form'**
  String get operationsCronjobFormTitle;

  /// No description provided for @operationsCronjobRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cronjob Records'**
  String get operationsCronjobRecordsTitle;

  /// No description provided for @operationsScriptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Script Library'**
  String get operationsScriptsTitle;

  /// No description provided for @toolboxCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Toolbox'**
  String get toolboxCenterTitle;

  /// No description provided for @toolboxCenterIntro.
  ///
  /// In en, this message translates to:
  /// **'A consolidated tools entry for ClamAV, Fail2ban, FTP, and device management.'**
  String get toolboxCenterIntro;

  /// No description provided for @toolboxCommonOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get toolboxCommonOverviewTitle;

  /// No description provided for @toolboxCommonRecentRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Records'**
  String get toolboxCommonRecentRecordsTitle;

  /// No description provided for @toolboxStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get toolboxStatusLabel;

  /// No description provided for @toolboxVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get toolboxVersionLabel;

  /// No description provided for @toolboxStatusEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get toolboxStatusEnabled;

  /// No description provided for @toolboxStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get toolboxStatusDisabled;

  /// No description provided for @toolboxClamTitle.
  ///
  /// In en, this message translates to:
  /// **'ClamAV'**
  String get toolboxClamTitle;

  /// No description provided for @toolboxClamCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan task status and recent scan records'**
  String get toolboxClamCardSubtitle;

  /// No description provided for @toolboxClamTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Tasks'**
  String get toolboxClamTasksTitle;

  /// No description provided for @toolboxClamRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Scan Records'**
  String get toolboxClamRecordsTitle;

  /// No description provided for @toolboxFail2banTitle.
  ///
  /// In en, this message translates to:
  /// **'Fail2ban'**
  String get toolboxFail2banTitle;

  /// No description provided for @toolboxFail2banCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ban policy and blocked IP records'**
  String get toolboxFail2banCardSubtitle;

  /// No description provided for @toolboxFail2banConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Fail2ban Configuration'**
  String get toolboxFail2banConfigTitle;

  /// No description provided for @toolboxFail2banEditConfig.
  ///
  /// In en, this message translates to:
  /// **'Edit Fail2ban Configuration'**
  String get toolboxFail2banEditConfig;

  /// No description provided for @toolboxFail2banBantime.
  ///
  /// In en, this message translates to:
  /// **'Ban Time'**
  String get toolboxFail2banBantime;

  /// No description provided for @toolboxFail2banFindtime.
  ///
  /// In en, this message translates to:
  /// **'Find Time'**
  String get toolboxFail2banFindtime;

  /// No description provided for @toolboxFail2banMaxretry.
  ///
  /// In en, this message translates to:
  /// **'Max Retry'**
  String get toolboxFail2banMaxretry;

  /// No description provided for @toolboxFail2banPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get toolboxFail2banPort;

  /// No description provided for @toolboxFtpTitle.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get toolboxFtpTitle;

  /// No description provided for @toolboxFtpCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FTP service status and user synchronization'**
  String get toolboxFtpCardSubtitle;

  /// No description provided for @toolboxFtpUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'FTP Users'**
  String get toolboxFtpUsersTitle;

  /// No description provided for @toolboxFtpBaseDir.
  ///
  /// In en, this message translates to:
  /// **'Base Directory'**
  String get toolboxFtpBaseDir;

  /// No description provided for @toolboxFtpSyncAction.
  ///
  /// In en, this message translates to:
  /// **'Sync Users'**
  String get toolboxFtpSyncAction;

  /// No description provided for @toolboxFtpSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'FTP users synchronized'**
  String get toolboxFtpSyncSuccess;

  /// No description provided for @toolboxFtpSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to synchronize FTP users'**
  String get toolboxFtpSyncFailed;

  /// No description provided for @toolboxDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Management'**
  String get toolboxDeviceTitle;

  /// No description provided for @toolboxDeviceCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hostname, DNS, NTP, and swap configuration'**
  String get toolboxDeviceCardSubtitle;

  /// No description provided for @toolboxDeviceOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Overview'**
  String get toolboxDeviceOverviewTitle;

  /// No description provided for @toolboxDeviceConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Configuration'**
  String get toolboxDeviceConfigTitle;

  /// No description provided for @toolboxDeviceUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'System Users'**
  String get toolboxDeviceUsersTitle;

  /// No description provided for @toolboxDeviceZoneOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Zone Options'**
  String get toolboxDeviceZoneOptionsTitle;

  /// No description provided for @toolboxDeviceHostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get toolboxDeviceHostname;

  /// No description provided for @toolboxDeviceDns.
  ///
  /// In en, this message translates to:
  /// **'DNS'**
  String get toolboxDeviceDns;

  /// No description provided for @toolboxDeviceNtp.
  ///
  /// In en, this message translates to:
  /// **'NTP'**
  String get toolboxDeviceNtp;

  /// No description provided for @toolboxDeviceSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get toolboxDeviceSwap;

  /// No description provided for @toolboxDeviceTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Local Time'**
  String get toolboxDeviceTimeLabel;

  /// No description provided for @toolboxDeviceSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get toolboxDeviceSystemLabel;

  /// No description provided for @toolboxDeviceCheckDns.
  ///
  /// In en, this message translates to:
  /// **'Check DNS'**
  String get toolboxDeviceCheckDns;

  /// No description provided for @toolboxDeviceEditConfig.
  ///
  /// In en, this message translates to:
  /// **'Edit Configuration'**
  String get toolboxDeviceEditConfig;

  /// No description provided for @toolboxDeviceCheckDnsSuccess.
  ///
  /// In en, this message translates to:
  /// **'DNS check succeeded'**
  String get toolboxDeviceCheckDnsSuccess;

  /// No description provided for @toolboxDeviceCheckDnsFailed.
  ///
  /// In en, this message translates to:
  /// **'DNS check failed'**
  String get toolboxDeviceCheckDnsFailed;

  /// No description provided for @toolboxDeviceDnsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide DNS first'**
  String get toolboxDeviceDnsRequired;

  /// No description provided for @cronjobsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search cronjobs'**
  String get cronjobsSearchHint;

  /// No description provided for @cronjobsFilterAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get cronjobsFilterAllGroups;

  /// No description provided for @cronjobsGroupFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter by group'**
  String get cronjobsGroupFilterAction;

  /// No description provided for @cronjobsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cronjobs'**
  String get cronjobsEmptyTitle;

  /// No description provided for @cronjobsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Your cronjobs will appear here once created.'**
  String get cronjobsEmptyDescription;

  /// No description provided for @cronjobsSpecLabel.
  ///
  /// In en, this message translates to:
  /// **'Spec'**
  String get cronjobsSpecLabel;

  /// No description provided for @cronjobsNextRunLabel.
  ///
  /// In en, this message translates to:
  /// **'Next run'**
  String get cronjobsNextRunLabel;

  /// No description provided for @cronjobsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get cronjobsTypeLabel;

  /// No description provided for @cronjobsLastRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'Last record'**
  String get cronjobsLastRecordLabel;

  /// No description provided for @cronjobsEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get cronjobsEnableAction;

  /// No description provided for @cronjobsDisableAction.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get cronjobsDisableAction;

  /// No description provided for @cronjobsHandleOnceAction.
  ///
  /// In en, this message translates to:
  /// **'Handle once'**
  String get cronjobsHandleOnceAction;

  /// No description provided for @cronjobsRecordsAction.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get cronjobsRecordsAction;

  /// No description provided for @cronjobsStopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get cronjobsStopAction;

  /// No description provided for @cronjobsStatusEnable.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get cronjobsStatusEnable;

  /// No description provided for @cronjobsStatusDisable.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get cronjobsStatusDisable;

  /// No description provided for @cronjobsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get cronjobsStatusPending;

  /// No description provided for @cronjobsTypeShell.
  ///
  /// In en, this message translates to:
  /// **'Shell'**
  String get cronjobsTypeShell;

  /// No description provided for @cronjobsTypeWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get cronjobsTypeWebsite;

  /// No description provided for @cronjobsTypeDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get cronjobsTypeDatabase;

  /// No description provided for @cronjobsTypeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get cronjobsTypeDirectory;

  /// No description provided for @cronjobsTypeSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get cronjobsTypeSnapshot;

  /// No description provided for @cronjobsTypeLog.
  ///
  /// In en, this message translates to:
  /// **'Log Cleanup'**
  String get cronjobsTypeLog;

  /// No description provided for @cronjobsUpdateStatusConfirm.
  ///
  /// In en, this message translates to:
  /// **'Update cronjob {name} to {status}?'**
  String cronjobsUpdateStatusConfirm(String name, String status);

  /// No description provided for @cronjobsHandleOnceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Run cronjob {name} once now?'**
  String cronjobsHandleOnceConfirm(String name);

  /// No description provided for @cronjobsStopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop running cronjob {name}?'**
  String cronjobsStopConfirm(String name);

  /// No description provided for @cronjobRecordsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get cronjobRecordsEmptyTitle;

  /// No description provided for @cronjobRecordsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Execution records will appear here after the cronjob runs.'**
  String get cronjobRecordsEmptyDescription;

  /// No description provided for @cronjobRecordsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get cronjobRecordsStatusAll;

  /// No description provided for @cronjobRecordsStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get cronjobRecordsStatusSuccess;

  /// No description provided for @cronjobRecordsStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get cronjobRecordsStatusWaiting;

  /// No description provided for @cronjobRecordsStatusUnexecuted.
  ///
  /// In en, this message translates to:
  /// **'Unexecuted'**
  String get cronjobRecordsStatusUnexecuted;

  /// No description provided for @cronjobRecordsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get cronjobRecordsStatusFailed;

  /// No description provided for @cronjobRecordsIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get cronjobRecordsIntervalLabel;

  /// No description provided for @cronjobRecordsMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get cronjobRecordsMessageLabel;

  /// No description provided for @cronjobRecordsViewLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Log'**
  String get cronjobRecordsViewLogTitle;

  /// No description provided for @cronjobRecordsCleanAction.
  ///
  /// In en, this message translates to:
  /// **'Clean records'**
  String get cronjobRecordsCleanAction;

  /// No description provided for @cronjobRecordsCleanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clean records for this cronjob?'**
  String get cronjobRecordsCleanConfirm;

  /// No description provided for @cronjobsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete cronjob {name}?'**
  String cronjobsDeleteConfirm(String name);

  /// No description provided for @cronjobFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Cronjob'**
  String get cronjobFormCreateTitle;

  /// No description provided for @cronjobFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Cronjob'**
  String get cronjobFormEditTitle;

  /// No description provided for @cronjobFormBasicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get cronjobFormBasicSectionTitle;

  /// No description provided for @cronjobFormScheduleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get cronjobFormScheduleSectionTitle;

  /// No description provided for @cronjobFormTargetSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get cronjobFormTargetSectionTitle;

  /// No description provided for @cronjobFormPolicySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Policy & Alerts'**
  String get cronjobFormPolicySectionTitle;

  /// No description provided for @cronjobFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get cronjobFormTypeLabel;

  /// No description provided for @cronjobFormUrlTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get cronjobFormUrlTypeLabel;

  /// No description provided for @cronjobFormCustomSpecLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom spec'**
  String get cronjobFormCustomSpecLabel;

  /// No description provided for @cronjobFormPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview next runs'**
  String get cronjobFormPreviewAction;

  /// No description provided for @cronjobFormBuilderModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Use builder'**
  String get cronjobFormBuilderModeLabel;

  /// No description provided for @cronjobFormRawModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Use raw cron spec'**
  String get cronjobFormRawModeLabel;

  /// No description provided for @cronjobFormDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this cronjob?'**
  String get cronjobFormDeleteConfirm;

  /// No description provided for @cronjobFormBackupTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup type'**
  String get cronjobFormBackupTypeLabel;

  /// No description provided for @cronjobFormDatabaseTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Database type'**
  String get cronjobFormDatabaseTypeLabel;

  /// No description provided for @cronjobFormBackupArgsLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup args'**
  String get cronjobFormBackupArgsLabel;

  /// No description provided for @cronjobFormBackupDirectoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup directory'**
  String get cronjobFormBackupDirectoryLabel;

  /// No description provided for @cronjobFormDirectoryPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Directory path'**
  String get cronjobFormDirectoryPathLabel;

  /// No description provided for @cronjobFormSelectedFilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected files'**
  String get cronjobFormSelectedFilesLabel;

  /// No description provided for @cronjobFormExcludePatternsLabel.
  ///
  /// In en, this message translates to:
  /// **'Exclude patterns'**
  String get cronjobFormExcludePatternsLabel;

  /// No description provided for @cronjobFormIncludeImagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Include images'**
  String get cronjobFormIncludeImagesLabel;

  /// No description provided for @cronjobFormSourceAccountsLabel.
  ///
  /// In en, this message translates to:
  /// **'Source accounts'**
  String get cronjobFormSourceAccountsLabel;

  /// No description provided for @cronjobFormDownloadAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Default download path'**
  String get cronjobFormDownloadAccountLabel;

  /// No description provided for @cronjobFormSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get cronjobFormSecretLabel;

  /// No description provided for @cronjobFormExecutorLabel.
  ///
  /// In en, this message translates to:
  /// **'Executor'**
  String get cronjobFormExecutorLabel;

  /// No description provided for @cronjobFormUserLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get cronjobFormUserLabel;

  /// No description provided for @cronjobFormShellInlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Inline'**
  String get cronjobFormShellInlineLabel;

  /// No description provided for @cronjobFormShellLibraryLabel.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get cronjobFormShellLibraryLabel;

  /// No description provided for @cronjobFormShellPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get cronjobFormShellPathLabel;

  /// No description provided for @cronjobFormScriptLibraryLabel.
  ///
  /// In en, this message translates to:
  /// **'Script library'**
  String get cronjobFormScriptLibraryLabel;

  /// No description provided for @cronjobFormScriptPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Script path'**
  String get cronjobFormScriptPathLabel;

  /// No description provided for @cronjobFormScriptLabel.
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get cronjobFormScriptLabel;

  /// No description provided for @cronjobFormRetainCopiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Retain copies'**
  String get cronjobFormRetainCopiesLabel;

  /// No description provided for @cronjobFormRetryTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry times'**
  String get cronjobFormRetryTimesLabel;

  /// No description provided for @cronjobFormTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get cronjobFormTimeoutLabel;

  /// No description provided for @cronjobFormTimeoutUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get cronjobFormTimeoutUnitLabel;

  /// No description provided for @cronjobFormSecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get cronjobFormSecondsLabel;

  /// No description provided for @cronjobFormMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get cronjobFormMinutesLabel;

  /// No description provided for @cronjobFormHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get cronjobFormHoursLabel;

  /// No description provided for @cronjobFormIgnoreErrorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ignore errors'**
  String get cronjobFormIgnoreErrorsLabel;

  /// No description provided for @cronjobFormArgumentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get cronjobFormArgumentsLabel;

  /// No description provided for @cronjobFormEnableAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable alerts'**
  String get cronjobFormEnableAlertsLabel;

  /// No description provided for @cronjobFormAlertCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert count'**
  String get cronjobFormAlertCountLabel;

  /// No description provided for @cronjobFormScheduleModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get cronjobFormScheduleModeLabel;

  /// No description provided for @cronjobFormScheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get cronjobFormScheduleDaily;

  /// No description provided for @cronjobFormScheduleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get cronjobFormScheduleWeekly;

  /// No description provided for @cronjobFormScheduleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get cronjobFormScheduleMonthly;

  /// No description provided for @cronjobFormScheduleEveryHours.
  ///
  /// In en, this message translates to:
  /// **'Every N hours'**
  String get cronjobFormScheduleEveryHours;

  /// No description provided for @cronjobFormScheduleEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every N minutes'**
  String get cronjobFormScheduleEveryMinutes;

  /// No description provided for @cronjobFormScheduleMinuteLabel.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get cronjobFormScheduleMinuteLabel;

  /// No description provided for @cronjobFormScheduleHourLabel.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get cronjobFormScheduleHourLabel;

  /// No description provided for @cronjobFormScheduleWeekdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get cronjobFormScheduleWeekdayLabel;

  /// No description provided for @cronjobFormScheduleDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get cronjobFormScheduleDayLabel;

  /// No description provided for @cronjobFormScheduleIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get cronjobFormScheduleIntervalLabel;

  /// No description provided for @scriptLibrarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search scripts'**
  String get scriptLibrarySearchHint;

  /// No description provided for @scriptLibraryFilterAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get scriptLibraryFilterAllGroups;

  /// No description provided for @scriptLibraryGroupFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter by group'**
  String get scriptLibraryGroupFilterAction;

  /// No description provided for @scriptLibraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No scripts'**
  String get scriptLibraryEmptyTitle;

  /// No description provided for @scriptLibraryEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Scripts will appear here after script library data loads.'**
  String get scriptLibraryEmptyDescription;

  /// No description provided for @scriptLibraryViewCodeAction.
  ///
  /// In en, this message translates to:
  /// **'View code'**
  String get scriptLibraryViewCodeAction;

  /// No description provided for @scriptLibraryRunAction.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get scriptLibraryRunAction;

  /// No description provided for @scriptLibrarySyncAction.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get scriptLibrarySyncAction;

  /// No description provided for @scriptLibraryDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get scriptLibraryDeleteAction;

  /// No description provided for @scriptLibraryInteractiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get scriptLibraryInteractiveLabel;

  /// No description provided for @scriptLibraryInteractiveYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get scriptLibraryInteractiveYes;

  /// No description provided for @scriptLibraryInteractiveNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get scriptLibraryInteractiveNo;

  /// No description provided for @scriptLibraryCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get scriptLibraryCreatedAtLabel;

  /// No description provided for @scriptLibrarySyncConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sync the script library now?'**
  String get scriptLibrarySyncConfirm;

  /// No description provided for @scriptLibraryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete script {name}?'**
  String scriptLibraryDeleteConfirm(String name);

  /// No description provided for @scriptLibraryCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Script Code'**
  String get scriptLibraryCodeTitle;

  /// No description provided for @scriptLibraryRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Run Script'**
  String get scriptLibraryRunTitle;

  /// No description provided for @scriptLibraryRunWaiting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to script output...'**
  String get scriptLibraryRunWaiting;

  /// No description provided for @scriptLibraryRunNoOutput.
  ///
  /// In en, this message translates to:
  /// **'No output yet'**
  String get scriptLibraryRunNoOutput;

  /// No description provided for @scriptLibraryRunDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Run output disconnected'**
  String get scriptLibraryRunDisconnected;

  /// No description provided for @operationsBackupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get operationsBackupsTitle;

  /// No description provided for @operationsBackupAccountFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Account Form'**
  String get operationsBackupAccountFormTitle;

  /// No description provided for @operationsBackupRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Records'**
  String get operationsBackupRecordsTitle;

  /// No description provided for @operationsBackupRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Recover'**
  String get operationsBackupRecoverTitle;

  /// No description provided for @backupAccountsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search backup accounts'**
  String get backupAccountsSearchHint;

  /// No description provided for @backupAccountsFilterAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get backupAccountsFilterAllTypes;

  /// No description provided for @backupAccountsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No backup accounts'**
  String get backupAccountsEmptyTitle;

  /// No description provided for @backupAccountsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a backup account to start using backup flows.'**
  String get backupAccountsEmptyDescription;

  /// No description provided for @backupAccountsScopePublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get backupAccountsScopePublic;

  /// No description provided for @backupAccountsScopePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get backupAccountsScopePrivate;

  /// No description provided for @backupAccountsTokenRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Token refreshed'**
  String get backupAccountsTokenRefreshed;

  /// No description provided for @backupAccountsConnectionOk.
  ///
  /// In en, this message translates to:
  /// **'Connection ok'**
  String get backupAccountsConnectionOk;

  /// No description provided for @backupAccountsConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get backupAccountsConnectionFailed;

  /// No description provided for @backupAccountsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete backup account {name}?'**
  String backupAccountsDeleteConfirm(String name);

  /// No description provided for @backupFilesSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Files'**
  String get backupFilesSheetTitle;

  /// No description provided for @backupAccountCardBucketLabel.
  ///
  /// In en, this message translates to:
  /// **'Bucket'**
  String get backupAccountCardBucketLabel;

  /// No description provided for @backupAccountCardEndpointLabel.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get backupAccountCardEndpointLabel;

  /// No description provided for @backupAccountCardPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get backupAccountCardPathLabel;

  /// No description provided for @backupAccountCardBrowseFilesAction.
  ///
  /// In en, this message translates to:
  /// **'Browse files'**
  String get backupAccountCardBrowseFilesAction;

  /// No description provided for @backupAccountCardRefreshTokenAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh token'**
  String get backupAccountCardRefreshTokenAction;

  /// No description provided for @backupFormBasicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get backupFormBasicSectionTitle;

  /// No description provided for @backupFormCredentialsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get backupFormCredentialsSectionTitle;

  /// No description provided for @backupFormStorageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get backupFormStorageSectionTitle;

  /// No description provided for @backupFormVerifySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get backupFormVerifySectionTitle;

  /// No description provided for @backupFormPublicScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Public scope'**
  String get backupFormPublicScopeLabel;

  /// No description provided for @backupFormProviderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider type'**
  String get backupFormProviderTypeLabel;

  /// No description provided for @backupFormAccessKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Access Key'**
  String get backupFormAccessKeyLabel;

  /// No description provided for @backupFormUsernameAccessKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Username / Access Key'**
  String get backupFormUsernameAccessKeyLabel;

  /// No description provided for @backupFormCredentialLabel.
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get backupFormCredentialLabel;

  /// No description provided for @backupFormAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get backupFormAddressLabel;

  /// No description provided for @backupFormPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get backupFormPortLabel;

  /// No description provided for @backupFormChinaCloudLabel.
  ///
  /// In en, this message translates to:
  /// **'Use China cloud'**
  String get backupFormChinaCloudLabel;

  /// No description provided for @backupFormClientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get backupFormClientIdLabel;

  /// No description provided for @backupFormClientSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get backupFormClientSecretLabel;

  /// No description provided for @backupFormRedirectUriLabel.
  ///
  /// In en, this message translates to:
  /// **'Redirect URI'**
  String get backupFormRedirectUriLabel;

  /// No description provided for @backupFormAuthCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Authorization Code'**
  String get backupFormAuthCodeLabel;

  /// No description provided for @backupFormOpenAuthorizeAction.
  ///
  /// In en, this message translates to:
  /// **'Open authorize page'**
  String get backupFormOpenAuthorizeAction;

  /// No description provided for @backupFormTokenJsonLabel.
  ///
  /// In en, this message translates to:
  /// **'Token JSON'**
  String get backupFormTokenJsonLabel;

  /// No description provided for @backupFormDriveIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Drive ID'**
  String get backupFormDriveIdLabel;

  /// No description provided for @backupFormRefreshTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh Token'**
  String get backupFormRefreshTokenLabel;

  /// No description provided for @backupFormRememberCredentialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Remember credentials'**
  String get backupFormRememberCredentialsLabel;

  /// No description provided for @backupFormRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get backupFormRegionLabel;

  /// No description provided for @backupFormDomainLabel.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get backupFormDomainLabel;

  /// No description provided for @backupFormEndpointLabel.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get backupFormEndpointLabel;

  /// No description provided for @backupFormBucketLabel.
  ///
  /// In en, this message translates to:
  /// **'Bucket'**
  String get backupFormBucketLabel;

  /// No description provided for @backupFormBackupPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup path'**
  String get backupFormBackupPathLabel;

  /// No description provided for @backupFormVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get backupFormVerifiedLabel;

  /// No description provided for @backupFormNotVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get backupFormNotVerifiedLabel;

  /// No description provided for @backupFormTestingLabel.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get backupFormTestingLabel;

  /// No description provided for @backupFormTestConnectionAction.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get backupFormTestConnectionAction;

  /// No description provided for @backupRecordsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No backup records'**
  String get backupRecordsEmptyTitle;

  /// No description provided for @backupRecordsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Backup records will appear here after backups run.'**
  String get backupRecordsEmptyDescription;

  /// No description provided for @backupRecordsFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get backupRecordsFilterAction;

  /// No description provided for @backupRecordsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete backup record {name}?'**
  String backupRecordsDeleteConfirm(String name);

  /// No description provided for @backupRecordsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get backupRecordsTypeLabel;

  /// No description provided for @backupRecordsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get backupRecordsNameLabel;

  /// No description provided for @backupRecordsDetailNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Detail name'**
  String get backupRecordsDetailNameLabel;

  /// No description provided for @backupRecordsApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get backupRecordsApplyAction;

  /// No description provided for @backupRecordsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get backupRecordsStatusLabel;

  /// No description provided for @backupRecordsSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get backupRecordsSizeLabel;

  /// No description provided for @backupRecordsDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get backupRecordsDownloadAction;

  /// No description provided for @backupRecordsRecoverAction.
  ///
  /// In en, this message translates to:
  /// **'Recover'**
  String get backupRecordsRecoverAction;

  /// No description provided for @backupRecoverResourceStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get backupRecoverResourceStepTitle;

  /// No description provided for @backupRecoverRecordStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get backupRecoverRecordStepTitle;

  /// No description provided for @backupRecoverConfirmStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get backupRecoverConfirmStepTitle;

  /// No description provided for @backupRecoverTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get backupRecoverTypeLabel;

  /// No description provided for @backupRecoverAppLabel.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get backupRecoverAppLabel;

  /// No description provided for @backupRecoverWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get backupRecoverWebsiteLabel;

  /// No description provided for @backupRecoverDatabaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get backupRecoverDatabaseLabel;

  /// No description provided for @backupRecoverOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get backupRecoverOtherLabel;

  /// No description provided for @backupRecoverSourceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Source type'**
  String get backupRecoverSourceTypeLabel;

  /// No description provided for @backupRecoverDatabaseTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Database type'**
  String get backupRecoverDatabaseTypeLabel;

  /// No description provided for @backupRecoverDatabaseItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Database item'**
  String get backupRecoverDatabaseItemLabel;

  /// No description provided for @backupRecoverLoadRecordsAction.
  ///
  /// In en, this message translates to:
  /// **'Load records'**
  String get backupRecoverLoadRecordsAction;

  /// No description provided for @backupRecoverNoCandidateRecords.
  ///
  /// In en, this message translates to:
  /// **'No candidate records'**
  String get backupRecoverNoCandidateRecords;

  /// No description provided for @backupRecoverRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup record'**
  String get backupRecoverRecordLabel;

  /// No description provided for @backupRecoverSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get backupRecoverSecretLabel;

  /// No description provided for @backupRecoverTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get backupRecoverTimeoutLabel;

  /// No description provided for @backupRecoverStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start recover'**
  String get backupRecoverStartAction;

  /// No description provided for @backupRecoverConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Start recovery from the selected backup record?'**
  String get backupRecoverConfirmMessage;

  /// No description provided for @backupRecoverUnsupportedTypeHint.
  ///
  /// In en, this message translates to:
  /// **'The current mainline preserves {type} record context, but direct recover is not available yet.'**
  String backupRecoverUnsupportedTypeHint(String type);

  /// No description provided for @backupRecoverUnsupportedTypeSubmitHint.
  ///
  /// In en, this message translates to:
  /// **'Recover submit is currently unavailable for {type} records.'**
  String backupRecoverUnsupportedTypeSubmitHint(String type);

  /// No description provided for @backupResourceTypeUnknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown type: {type}'**
  String backupResourceTypeUnknownLabel(String type);

  /// No description provided for @backupErrorOauthOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the authorization page'**
  String get backupErrorOauthOpenFailed;

  /// No description provided for @backupErrorOauthUnsupportedProvider.
  ///
  /// In en, this message translates to:
  /// **'This backup provider does not support mobile authorization'**
  String get backupErrorOauthUnsupportedProvider;

  /// No description provided for @backupErrorRecordPathEmpty.
  ///
  /// In en, this message translates to:
  /// **'The backup record path is empty'**
  String get backupErrorRecordPathEmpty;

  /// No description provided for @backupErrorRecordDownloadEmpty.
  ///
  /// In en, this message translates to:
  /// **'The downloaded backup file is empty'**
  String get backupErrorRecordDownloadEmpty;

  /// No description provided for @cronjobFormErrorImportInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'The imported cronjob file must be a JSON array.'**
  String get cronjobFormErrorImportInvalidJson;

  /// No description provided for @cronjobFormErrorExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'The exported cronjob file is empty.'**
  String get cronjobFormErrorExportEmpty;

  /// No description provided for @cronjobFormErrorSpecRequired.
  ///
  /// In en, this message translates to:
  /// **'Cronjob spec is required.'**
  String get cronjobFormErrorSpecRequired;

  /// No description provided for @cronjobFormErrorUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'This cronjob type is not supported in the mobile form yet.'**
  String get cronjobFormErrorUnsupportedType;

  /// No description provided for @backupTypeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get backupTypeLocal;

  /// No description provided for @backupTypeSftp.
  ///
  /// In en, this message translates to:
  /// **'SFTP'**
  String get backupTypeSftp;

  /// No description provided for @backupTypeWebdav.
  ///
  /// In en, this message translates to:
  /// **'WebDAV'**
  String get backupTypeWebdav;

  /// No description provided for @backupTypeS3.
  ///
  /// In en, this message translates to:
  /// **'S3'**
  String get backupTypeS3;

  /// No description provided for @backupTypeMinio.
  ///
  /// In en, this message translates to:
  /// **'MINIO'**
  String get backupTypeMinio;

  /// No description provided for @backupTypeOss.
  ///
  /// In en, this message translates to:
  /// **'OSS'**
  String get backupTypeOss;

  /// No description provided for @backupTypeCos.
  ///
  /// In en, this message translates to:
  /// **'COS'**
  String get backupTypeCos;

  /// No description provided for @backupTypeKodo.
  ///
  /// In en, this message translates to:
  /// **'KODO'**
  String get backupTypeKodo;

  /// No description provided for @backupTypeUpyun.
  ///
  /// In en, this message translates to:
  /// **'UPYUN'**
  String get backupTypeUpyun;

  /// No description provided for @backupTypeOneDrive.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get backupTypeOneDrive;

  /// No description provided for @backupTypeGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get backupTypeGoogleDrive;

  /// No description provided for @backupTypeAliyun.
  ///
  /// In en, this message translates to:
  /// **'Aliyun Drive'**
  String get backupTypeAliyun;

  /// No description provided for @backupTypeApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get backupTypeApp;

  /// No description provided for @backupTypeWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get backupTypeWebsite;

  /// No description provided for @backupTypeDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get backupTypeDatabase;

  /// No description provided for @backupTypeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get backupTypeDirectory;

  /// No description provided for @backupTypeSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get backupTypeSnapshot;

  /// No description provided for @backupTypeLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get backupTypeLog;

  /// No description provided for @backupTypeContainer.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get backupTypeContainer;

  /// No description provided for @backupTypeCompose.
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get backupTypeCompose;

  /// No description provided for @backupTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get backupTypeOther;

  /// No description provided for @databaseTypeMysql.
  ///
  /// In en, this message translates to:
  /// **'MySQL'**
  String get databaseTypeMysql;

  /// No description provided for @databaseTypeMysqlCluster.
  ///
  /// In en, this message translates to:
  /// **'MySQL Cluster'**
  String get databaseTypeMysqlCluster;

  /// No description provided for @databaseTypeMariadb.
  ///
  /// In en, this message translates to:
  /// **'MariaDB'**
  String get databaseTypeMariadb;

  /// No description provided for @databaseTypePostgresql.
  ///
  /// In en, this message translates to:
  /// **'PostgreSQL'**
  String get databaseTypePostgresql;

  /// No description provided for @databaseTypePostgresqlCluster.
  ///
  /// In en, this message translates to:
  /// **'PostgreSQL Cluster'**
  String get databaseTypePostgresqlCluster;

  /// No description provided for @databaseTypeRedis.
  ///
  /// In en, this message translates to:
  /// **'Redis'**
  String get databaseTypeRedis;

  /// No description provided for @cronjobFormAppsLabel.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get cronjobFormAppsLabel;

  /// No description provided for @cronjobFormWebsitesLabel.
  ///
  /// In en, this message translates to:
  /// **'Websites'**
  String get cronjobFormWebsitesLabel;

  /// No description provided for @cronjobFormDatabasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Databases'**
  String get cronjobFormDatabasesLabel;

  /// No description provided for @cronjobFormIgnoreAppsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ignore apps'**
  String get cronjobFormIgnoreAppsLabel;

  /// No description provided for @cronjobFormShellModeInline.
  ///
  /// In en, this message translates to:
  /// **'Inline'**
  String get cronjobFormShellModeInline;

  /// No description provided for @cronjobFormShellModeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get cronjobFormShellModeLibrary;

  /// No description provided for @cronjobFormShellModePath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get cronjobFormShellModePath;

  /// No description provided for @cronjobFormUrlItemLabel.
  ///
  /// In en, this message translates to:
  /// **'URL {index}'**
  String cronjobFormUrlItemLabel(int index);

  /// No description provided for @cronjobFormAddUrlAction.
  ///
  /// In en, this message translates to:
  /// **'Add URL'**
  String get cronjobFormAddUrlAction;

  /// No description provided for @cronjobFormAlertMethodMail.
  ///
  /// In en, this message translates to:
  /// **'Mail'**
  String get cronjobFormAlertMethodMail;

  /// No description provided for @cronjobFormAlertMethodWecom.
  ///
  /// In en, this message translates to:
  /// **'WeCom'**
  String get cronjobFormAlertMethodWecom;

  /// No description provided for @cronjobFormAlertMethodDingtalk.
  ///
  /// In en, this message translates to:
  /// **'DingTalk'**
  String get cronjobFormAlertMethodDingtalk;

  /// No description provided for @cronjobFormCustomSpecItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom spec {index}'**
  String cronjobFormCustomSpecItemLabel(int index);

  /// No description provided for @cronjobFormImportInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'The imported cronjob file must be a JSON array'**
  String get cronjobFormImportInvalidJson;

  /// No description provided for @cronjobFormExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'The exported cronjob file is empty'**
  String get cronjobFormExportEmpty;

  /// No description provided for @cronjobFormSpecRequired.
  ///
  /// In en, this message translates to:
  /// **'Cronjob spec is required'**
  String get cronjobFormSpecRequired;

  /// No description provided for @cronjobFormUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'This cronjob type is not supported in mobile yet'**
  String get cronjobFormUnsupportedType;

  /// No description provided for @cronjobFormUnknownBackupType.
  ///
  /// In en, this message translates to:
  /// **'Unknown backup type: {type}'**
  String cronjobFormUnknownBackupType(String type);

  /// No description provided for @cronjobFormUnknownDatabaseType.
  ///
  /// In en, this message translates to:
  /// **'Unknown database type: {type}'**
  String cronjobFormUnknownDatabaseType(String type);

  /// No description provided for @cronjobFormUnknownAlertMethod.
  ///
  /// In en, this message translates to:
  /// **'Unknown alert method: {method}'**
  String cronjobFormUnknownAlertMethod(String method);

  /// No description provided for @cronjobFormUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected cronjob form error: {message}'**
  String cronjobFormUnknownError(String message);

  /// No description provided for @operationsLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs Center'**
  String get operationsLogsTitle;

  /// No description provided for @operationsSystemLogViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'System Log Viewer'**
  String get operationsSystemLogViewerTitle;

  /// No description provided for @operationsTaskLogDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Log Detail'**
  String get operationsTaskLogDetailTitle;

  /// No description provided for @logsCenterTabOperation.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get logsCenterTabOperation;

  /// No description provided for @logsCenterTabLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get logsCenterTabLogin;

  /// No description provided for @logsCenterTabTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get logsCenterTabTask;

  /// No description provided for @logsCenterTabSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get logsCenterTabSystem;

  /// No description provided for @logsOperationSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get logsOperationSourceLabel;

  /// No description provided for @logsOperationActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get logsOperationActionLabel;

  /// No description provided for @logsOperationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No operation logs'**
  String get logsOperationEmptyTitle;

  /// No description provided for @logsOperationEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Operation logs will appear here after the server records actions.'**
  String get logsOperationEmptyDescription;

  /// No description provided for @logsLoginIpLabel.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get logsLoginIpLabel;

  /// No description provided for @logsLoginEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No login logs'**
  String get logsLoginEmptyTitle;

  /// No description provided for @logsLoginEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Login logs will appear here after the server records authentication activity.'**
  String get logsLoginEmptyDescription;

  /// No description provided for @logsTaskTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Task type'**
  String get logsTaskTypeLabel;

  /// No description provided for @logsTaskExecutingCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Executing: {count}'**
  String logsTaskExecutingCountLabel(int count);

  /// No description provided for @logsTaskOpenDetailAction.
  ///
  /// In en, this message translates to:
  /// **'View log'**
  String get logsTaskOpenDetailAction;

  /// No description provided for @logsTaskEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No task logs'**
  String get logsTaskEmptyTitle;

  /// No description provided for @logsTaskEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Task logs will appear here after the server runs background tasks.'**
  String get logsTaskEmptyDescription;

  /// No description provided for @logsSystemFilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Log files'**
  String get logsSystemFilesLabel;

  /// No description provided for @logsSystemSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get logsSystemSourceLabel;

  /// No description provided for @logsSystemSourceAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get logsSystemSourceAgent;

  /// No description provided for @logsSystemSourceCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get logsSystemSourceCore;

  /// No description provided for @logsSystemOpenViewerAction.
  ///
  /// In en, this message translates to:
  /// **'Open viewer'**
  String get logsSystemOpenViewerAction;

  /// No description provided for @logsSystemEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No system log files'**
  String get logsSystemEmptyTitle;

  /// No description provided for @logsSystemEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'System log files will appear here after the server exposes log output.'**
  String get logsSystemEmptyDescription;

  /// No description provided for @logsSystemViewerNoFileSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a log file to view.'**
  String get logsSystemViewerNoFileSelected;

  /// No description provided for @logsSystemWatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get logsSystemWatchLabel;

  /// No description provided for @logsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logsStatusAll;

  /// No description provided for @logsStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get logsStatusSuccess;

  /// No description provided for @logsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get logsStatusFailed;

  /// No description provided for @logsStatusExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing'**
  String get logsStatusExecuting;

  /// No description provided for @logsTaskDetailIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Task ID'**
  String get logsTaskDetailIdLabel;

  /// No description provided for @logsTaskDetailTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Task type'**
  String get logsTaskDetailTypeLabel;

  /// No description provided for @logsTaskDetailStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get logsTaskDetailStatusLabel;

  /// No description provided for @logsTaskDetailCurrentStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Current step'**
  String get logsTaskDetailCurrentStepLabel;

  /// No description provided for @logsTaskDetailCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get logsTaskDetailCreatedAtLabel;

  /// No description provided for @logsTaskDetailLogFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Log file'**
  String get logsTaskDetailLogFileLabel;

  /// No description provided for @logsTaskDetailErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logsTaskDetailErrorLabel;

  /// No description provided for @logsOperationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load operation logs.'**
  String get logsOperationLoadFailed;

  /// No description provided for @logsLoginLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load login logs.'**
  String get logsLoginLoadFailed;

  /// No description provided for @logsTaskLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load task logs.'**
  String get logsTaskLoadFailed;

  /// No description provided for @logsTaskDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load task log content.'**
  String get logsTaskDetailLoadFailed;

  /// No description provided for @logsTaskMissingTaskId.
  ///
  /// In en, this message translates to:
  /// **'Task ID is required to load task log content.'**
  String get logsTaskMissingTaskId;

  /// No description provided for @logsSystemFilesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load system log files.'**
  String get logsSystemFilesLoadFailed;

  /// No description provided for @logsSystemContentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load system log content.'**
  String get logsSystemContentLoadFailed;

  /// No description provided for @operationsRuntimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtimes'**
  String get operationsRuntimesTitle;

  /// No description provided for @operationsRuntimeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime Detail'**
  String get operationsRuntimeDetailTitle;

  /// No description provided for @operationsRuntimeFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime Form'**
  String get operationsRuntimeFormTitle;

  /// No description provided for @runtimeFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Runtime'**
  String get runtimeFormCreateTitle;

  /// No description provided for @runtimeFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Runtime'**
  String get runtimeFormEditTitle;

  /// No description provided for @runtimeOverviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get runtimeOverviewTab;

  /// No description provided for @runtimeConfigTab.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get runtimeConfigTab;

  /// No description provided for @runtimeAdvancedTab.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get runtimeAdvancedTab;

  /// No description provided for @runtimeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search runtimes...'**
  String get runtimeSearchHint;

  /// No description provided for @runtimeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No runtimes'**
  String get runtimeEmptyTitle;

  /// No description provided for @runtimeEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Runtimes in the selected language category will appear here.'**
  String get runtimeEmptyDescription;

  /// No description provided for @runtimeActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get runtimeActionStart;

  /// No description provided for @runtimeActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get runtimeActionStop;

  /// No description provided for @runtimeActionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get runtimeActionRestart;

  /// No description provided for @runtimeActionSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get runtimeActionSync;

  /// No description provided for @runtimeActionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown action: {action}'**
  String runtimeActionUnknown(String action);

  /// No description provided for @runtimeTypePhp.
  ///
  /// In en, this message translates to:
  /// **'PHP'**
  String get runtimeTypePhp;

  /// No description provided for @runtimeTypeNode.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get runtimeTypeNode;

  /// No description provided for @runtimeTypeJava.
  ///
  /// In en, this message translates to:
  /// **'Java'**
  String get runtimeTypeJava;

  /// No description provided for @runtimeTypeGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get runtimeTypeGo;

  /// No description provided for @runtimeTypePython.
  ///
  /// In en, this message translates to:
  /// **'Python'**
  String get runtimeTypePython;

  /// No description provided for @runtimeTypeDotnet.
  ///
  /// In en, this message translates to:
  /// **'.NET'**
  String get runtimeTypeDotnet;

  /// No description provided for @runtimeTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown runtime: {type}'**
  String runtimeTypeUnknown(String type);

  /// No description provided for @runtimeResourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get runtimeResourceLocal;

  /// No description provided for @runtimeResourceAppStore.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get runtimeResourceAppStore;

  /// No description provided for @runtimeResourceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown resource: {resource}'**
  String runtimeResourceUnknown(String resource);

  /// No description provided for @runtimeStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get runtimeStatusAll;

  /// No description provided for @runtimeStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get runtimeStatusRunning;

  /// No description provided for @runtimeStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get runtimeStatusStopped;

  /// No description provided for @runtimeStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get runtimeStatusError;

  /// No description provided for @runtimeStatusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get runtimeStatusStarting;

  /// No description provided for @runtimeStatusBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get runtimeStatusBuilding;

  /// No description provided for @runtimeStatusRecreating.
  ///
  /// In en, this message translates to:
  /// **'Recreating'**
  String get runtimeStatusRecreating;

  /// No description provided for @runtimeStatusSystemRestart.
  ///
  /// In en, this message translates to:
  /// **'System Restart'**
  String get runtimeStatusSystemRestart;

  /// No description provided for @runtimeStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown status: {status}'**
  String runtimeStatusUnknown(String status);

  /// No description provided for @runtimeFieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get runtimeFieldType;

  /// No description provided for @runtimeFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get runtimeFieldStatus;

  /// No description provided for @runtimeFieldVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get runtimeFieldVersion;

  /// No description provided for @runtimeFieldResource.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get runtimeFieldResource;

  /// No description provided for @runtimeFieldImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get runtimeFieldImage;

  /// No description provided for @runtimeFieldCodeDir.
  ///
  /// In en, this message translates to:
  /// **'Code directory'**
  String get runtimeFieldCodeDir;

  /// No description provided for @runtimeFieldExternalPort.
  ///
  /// In en, this message translates to:
  /// **'External port'**
  String get runtimeFieldExternalPort;

  /// No description provided for @runtimeFieldPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get runtimeFieldPath;

  /// No description provided for @runtimeFieldSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get runtimeFieldSource;

  /// No description provided for @runtimeFieldRemark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get runtimeFieldRemark;

  /// No description provided for @runtimeFieldHostIp.
  ///
  /// In en, this message translates to:
  /// **'Host IP'**
  String get runtimeFieldHostIp;

  /// No description provided for @runtimeFieldContainerName.
  ///
  /// In en, this message translates to:
  /// **'Container name'**
  String get runtimeFieldContainerName;

  /// No description provided for @runtimeFieldContainerStatus.
  ///
  /// In en, this message translates to:
  /// **'Container status'**
  String get runtimeFieldContainerStatus;

  /// No description provided for @runtimeFieldExecScript.
  ///
  /// In en, this message translates to:
  /// **'Run script'**
  String get runtimeFieldExecScript;

  /// No description provided for @runtimeFieldPackageManager.
  ///
  /// In en, this message translates to:
  /// **'Package manager'**
  String get runtimeFieldPackageManager;

  /// No description provided for @runtimeFieldCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get runtimeFieldCreatedAt;

  /// No description provided for @runtimeFieldParams.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get runtimeFieldParams;

  /// No description provided for @runtimeFieldRebuild.
  ///
  /// In en, this message translates to:
  /// **'Rebuild on save'**
  String get runtimeFieldRebuild;

  /// No description provided for @runtimeFormBasicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get runtimeFormBasicSectionTitle;

  /// No description provided for @runtimeFormRuntimeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get runtimeFormRuntimeSectionTitle;

  /// No description provided for @runtimeFormAdvancedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get runtimeFormAdvancedSectionTitle;

  /// No description provided for @runtimeFormAppStoreCreateWeek8Hint.
  ///
  /// In en, this message translates to:
  /// **'App Store runtimes should be installed from the App Store. Use this form to create runtimes manually.'**
  String get runtimeFormAppStoreCreateWeek8Hint;

  /// No description provided for @runtimeFormPhpCreateWeek8Hint.
  ///
  /// In en, this message translates to:
  /// **'PHP runtimes are created with this form as well. Fill in the image and startup command as needed.'**
  String get runtimeFormPhpCreateWeek8Hint;

  /// No description provided for @runtimeFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Runtime name is required.'**
  String get runtimeFormNameRequired;

  /// No description provided for @runtimeFormImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Runtime image is required.'**
  String get runtimeFormImageRequired;

  /// No description provided for @runtimeFormCodeDirRequired.
  ///
  /// In en, this message translates to:
  /// **'Code directory is required.'**
  String get runtimeFormCodeDirRequired;

  /// No description provided for @runtimeFormPortInvalid.
  ///
  /// In en, this message translates to:
  /// **'External port must be greater than 0.'**
  String get runtimeFormPortInvalid;

  /// No description provided for @runtimeFormContainerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Container name is required.'**
  String get runtimeFormContainerNameRequired;

  /// No description provided for @runtimeFormExecScriptRequired.
  ///
  /// In en, this message translates to:
  /// **'Run script is required for this runtime type.'**
  String get runtimeFormExecScriptRequired;

  /// No description provided for @runtimeFormPackageManagerRequired.
  ///
  /// In en, this message translates to:
  /// **'Package manager is required for Node runtimes.'**
  String get runtimeFormPackageManagerRequired;

  /// No description provided for @runtimeAdvancedRequiresRunning.
  ///
  /// In en, this message translates to:
  /// **'Advanced runtime-specific capabilities unlock after the runtime is running.'**
  String get runtimeAdvancedRequiresRunning;

  /// No description provided for @runtimeAdvancedSummary.
  ///
  /// In en, this message translates to:
  /// **'Advanced config counts: {ports} ports, {environments} environments, {volumes} volumes, {hosts} extra hosts.'**
  String runtimeAdvancedSummary(
      int ports, int environments, int volumes, int hosts);

  /// No description provided for @runtimeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete runtime {name}?'**
  String runtimeDeleteConfirm(String name);

  /// No description provided for @runtimeOperateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Run {action} on runtime {name}?'**
  String runtimeOperateConfirm(String action, String name);

  /// No description provided for @runtimeListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load runtimes.'**
  String get runtimeListLoadFailed;

  /// No description provided for @runtimeDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load runtime detail.'**
  String get runtimeDetailLoadFailed;

  /// No description provided for @runtimeFormLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load runtime form data.'**
  String get runtimeFormLoadFailed;

  /// No description provided for @runtimeFormSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save runtime.'**
  String get runtimeFormSaveFailed;

  /// No description provided for @runtimeSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync runtime status.'**
  String get runtimeSyncFailed;

  /// No description provided for @runtimeDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete runtime.'**
  String get runtimeDeleteFailed;

  /// No description provided for @runtimeOperateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to operate runtime.'**
  String get runtimeOperateFailed;

  /// No description provided for @runtimeRemarkSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save runtime remark.'**
  String get runtimeRemarkSaveFailed;

  /// No description provided for @runtimeRemarkTooLong.
  ///
  /// In en, this message translates to:
  /// **'Remark must be 128 characters or fewer.'**
  String get runtimeRemarkTooLong;

  /// No description provided for @runtimeNodeScriptExecuting.
  ///
  /// In en, this message translates to:
  /// **'Running script {name}, syncing runtime status...'**
  String runtimeNodeScriptExecuting(String name);

  /// No description provided for @runtimeNodeScriptCompleted.
  ///
  /// In en, this message translates to:
  /// **'Script execution completed'**
  String get runtimeNodeScriptCompleted;

  /// No description provided for @runtimeNodeScriptFailed.
  ///
  /// In en, this message translates to:
  /// **'Script execution failed'**
  String get runtimeNodeScriptFailed;

  /// No description provided for @runtimeNodeScriptRuntimeStatus.
  ///
  /// In en, this message translates to:
  /// **'Runtime status: {status}'**
  String runtimeNodeScriptRuntimeStatus(String status);

  /// No description provided for @runtimeNodeScriptRuntimeMessage.
  ///
  /// In en, this message translates to:
  /// **'Runtime message: {message}'**
  String runtimeNodeScriptRuntimeMessage(String message);

  /// No description provided for @runtimeNodeScriptPollAttempts.
  ///
  /// In en, this message translates to:
  /// **'Status polls: {count}'**
  String runtimeNodeScriptPollAttempts(int count);

  /// No description provided for @runtimeNodeScriptCompletedWithStatus.
  ///
  /// In en, this message translates to:
  /// **'Script execution completed, runtime status: {status}'**
  String runtimeNodeScriptCompletedWithStatus(String status);

  /// No description provided for @runtimeNodeScriptFailedWithStatus.
  ///
  /// In en, this message translates to:
  /// **'Script execution failed, runtime status: {status}'**
  String runtimeNodeScriptFailedWithStatus(String status);

  /// No description provided for @runtimeNodeScriptWaitTimeout.
  ///
  /// In en, this message translates to:
  /// **'Script was triggered, but status confirmation timed out. Please refresh later.'**
  String get runtimeNodeScriptWaitTimeout;

  /// No description provided for @operationsPhpExtensionsTitle.
  ///
  /// In en, this message translates to:
  /// **'PHP Extensions'**
  String get operationsPhpExtensionsTitle;

  /// No description provided for @operationsPhpConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'PHP Config'**
  String get operationsPhpConfigTitle;

  /// No description provided for @runtimePhpTabBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get runtimePhpTabBasic;

  /// No description provided for @runtimePhpTabFpm.
  ///
  /// In en, this message translates to:
  /// **'FPM'**
  String get runtimePhpTabFpm;

  /// No description provided for @runtimePhpTabContainer.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get runtimePhpTabContainer;

  /// No description provided for @runtimePhpTabPhpFile.
  ///
  /// In en, this message translates to:
  /// **'PHP File'**
  String get runtimePhpTabPhpFile;

  /// No description provided for @runtimePhpTabFpmFile.
  ///
  /// In en, this message translates to:
  /// **'FPM File'**
  String get runtimePhpTabFpmFile;

  /// No description provided for @runtimePhpFpmConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'FPM Parameters'**
  String get runtimePhpFpmConfigTitle;

  /// No description provided for @runtimePhpFpmMode.
  ///
  /// In en, this message translates to:
  /// **'Process manager mode'**
  String get runtimePhpFpmMode;

  /// No description provided for @runtimePhpFpmMaxChildren.
  ///
  /// In en, this message translates to:
  /// **'pm.max_children'**
  String get runtimePhpFpmMaxChildren;

  /// No description provided for @runtimePhpFpmStartServers.
  ///
  /// In en, this message translates to:
  /// **'pm.start_servers'**
  String get runtimePhpFpmStartServers;

  /// No description provided for @runtimePhpFpmMinSpareServers.
  ///
  /// In en, this message translates to:
  /// **'pm.min_spare_servers'**
  String get runtimePhpFpmMinSpareServers;

  /// No description provided for @runtimePhpFpmMaxSpareServers.
  ///
  /// In en, this message translates to:
  /// **'pm.max_spare_servers'**
  String get runtimePhpFpmMaxSpareServers;

  /// No description provided for @runtimePhpContainerExtraHosts.
  ///
  /// In en, this message translates to:
  /// **'Extra hosts'**
  String get runtimePhpContainerExtraHosts;

  /// No description provided for @runtimePhpContainerPort.
  ///
  /// In en, this message translates to:
  /// **'Container Port'**
  String get runtimePhpContainerPort;

  /// No description provided for @runtimePhpHostPort.
  ///
  /// In en, this message translates to:
  /// **'Host Port'**
  String get runtimePhpHostPort;

  /// No description provided for @runtimePhpHostIp.
  ///
  /// In en, this message translates to:
  /// **'Host IP'**
  String get runtimePhpHostIp;

  /// No description provided for @runtimePhpVolumeTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get runtimePhpVolumeTarget;

  /// No description provided for @operationsSupervisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get operationsSupervisorTitle;

  /// No description provided for @runtimeSupervisorStatusWarning.
  ///
  /// In en, this message translates to:
  /// **'Partially running'**
  String get runtimeSupervisorStatusWarning;

  /// No description provided for @operationsNodeModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Node Modules'**
  String get operationsNodeModulesTitle;

  /// No description provided for @operationsNodeScriptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Node Scripts'**
  String get operationsNodeScriptsTitle;

  /// No description provided for @commandsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Command'**
  String get commandsCreateTitle;

  /// No description provided for @commandsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Command'**
  String get commandsEditTitle;

  /// No description provided for @commandsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search commands'**
  String get commandsSearchHint;

  /// No description provided for @commandsFilterAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get commandsFilterAllGroups;

  /// No description provided for @commandsGroupFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter by group'**
  String get commandsGroupFilterAction;

  /// No description provided for @commandsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No commands'**
  String get commandsEmptyTitle;

  /// No description provided for @commandsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a quick command or import a CSV to start building your command library.'**
  String get commandsEmptyDescription;

  /// No description provided for @commandsGroupFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get commandsGroupFieldLabel;

  /// No description provided for @commandsCommandFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get commandsCommandFieldLabel;

  /// No description provided for @commandsPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Command Preview'**
  String get commandsPreviewLabel;

  /// No description provided for @commandsImportPreviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to import'**
  String get commandsImportPreviewEmptyTitle;

  /// No description provided for @commandsImportPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'The CSV preview returned no commands.'**
  String get commandsImportPreviewEmpty;

  /// No description provided for @commandsImportingLabel.
  ///
  /// In en, this message translates to:
  /// **'Import preview ready'**
  String get commandsImportingLabel;

  /// No description provided for @commandsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get commandsSelectAll;

  /// No description provided for @commandsApplyGroup.
  ///
  /// In en, this message translates to:
  /// **'Apply group'**
  String get commandsApplyGroup;

  /// No description provided for @commandsExportSaved.
  ///
  /// In en, this message translates to:
  /// **'Command export saved to {path}'**
  String commandsExportSaved(String path);

  /// No description provided for @commandsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete command {name}?'**
  String commandsDeleteConfirm(String name);

  /// No description provided for @commandsDeleteSelectedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected commands?'**
  String commandsDeleteSelectedConfirm(int count);

  /// No description provided for @hostAssetsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Host Asset'**
  String get hostAssetsCreateTitle;

  /// No description provided for @hostAssetsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Host Asset'**
  String get hostAssetsEditTitle;

  /// No description provided for @hostAssetsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search hosts'**
  String get hostAssetsSearchHint;

  /// No description provided for @hostAssetsFilterAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get hostAssetsFilterAllGroups;

  /// No description provided for @hostAssetsGroupFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter by group'**
  String get hostAssetsGroupFilterAction;

  /// No description provided for @hostAssetsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No hosts'**
  String get hostAssetsEmptyTitle;

  /// No description provided for @hostAssetsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a host asset to manage SSH targets and grouped connections from your phone.'**
  String get hostAssetsEmptyDescription;

  /// No description provided for @hostAssetsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete host {name}?'**
  String hostAssetsDeleteConfirm(String name);

  /// No description provided for @hostAssetsDeleteSelectedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected hosts?'**
  String hostAssetsDeleteSelectedConfirm(int count);

  /// No description provided for @hostAssetsBasicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get hostAssetsBasicSectionTitle;

  /// No description provided for @hostAssetsAuthSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get hostAssetsAuthSectionTitle;

  /// No description provided for @hostAssetsConnectionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Check'**
  String get hostAssetsConnectionSectionTitle;

  /// No description provided for @hostAssetsAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get hostAssetsAddressLabel;

  /// No description provided for @hostAssetsPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get hostAssetsPortLabel;

  /// No description provided for @hostAssetsGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get hostAssetsGroupLabel;

  /// No description provided for @hostAssetsUserLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get hostAssetsUserLabel;

  /// No description provided for @hostAssetsPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get hostAssetsPasswordLabel;

  /// No description provided for @hostAssetsPrivateKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get hostAssetsPrivateKeyLabel;

  /// No description provided for @hostAssetsPassPhraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get hostAssetsPassPhraseLabel;

  /// No description provided for @hostAssetsRememberPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Remember Password'**
  String get hostAssetsRememberPasswordLabel;

  /// No description provided for @hostAssetsPasswordMode.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get hostAssetsPasswordMode;

  /// No description provided for @hostAssetsKeyMode.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get hostAssetsKeyMode;

  /// No description provided for @hostAssetsTestAction.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get hostAssetsTestAction;

  /// No description provided for @hostAssetsMoveGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Move Group'**
  String get hostAssetsMoveGroupAction;

  /// No description provided for @hostAssetsStatusNotTested.
  ///
  /// In en, this message translates to:
  /// **'Not tested'**
  String get hostAssetsStatusNotTested;

  /// No description provided for @hostAssetsStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get hostAssetsStatusSuccess;

  /// No description provided for @hostAssetsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get hostAssetsStatusFailed;

  /// No description provided for @hostAssetsConnectionVerified.
  ///
  /// In en, this message translates to:
  /// **'Connection verified'**
  String get hostAssetsConnectionVerified;

  /// No description provided for @hostAssetsConnectionNeedsTest.
  ///
  /// In en, this message translates to:
  /// **'Run a connection test before saving'**
  String get hostAssetsConnectionNeedsTest;

  /// No description provided for @hostAssetsTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection test failed'**
  String get hostAssetsTestFailed;

  /// No description provided for @sshSettingsServiceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get sshSettingsServiceSectionTitle;

  /// No description provided for @sshSettingsAuthenticationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get sshSettingsAuthenticationSectionTitle;

  /// No description provided for @sshSettingsNetworkSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get sshSettingsNetworkSectionTitle;

  /// No description provided for @sshSettingsRawFileSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Raw File'**
  String get sshSettingsRawFileSectionTitle;

  /// No description provided for @sshAutoStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto start'**
  String get sshAutoStartLabel;

  /// No description provided for @sshPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get sshPortLabel;

  /// No description provided for @sshListenAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Listen address'**
  String get sshListenAddressLabel;

  /// No description provided for @sshPermitRootLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Permit root login'**
  String get sshPermitRootLoginLabel;

  /// No description provided for @sshPasswordAuthenticationLabel.
  ///
  /// In en, this message translates to:
  /// **'Password authentication'**
  String get sshPasswordAuthenticationLabel;

  /// No description provided for @sshPubkeyAuthenticationLabel.
  ///
  /// In en, this message translates to:
  /// **'Public key authentication'**
  String get sshPubkeyAuthenticationLabel;

  /// No description provided for @sshUseDnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Use DNS'**
  String get sshUseDnsLabel;

  /// No description provided for @sshCurrentUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Current user'**
  String get sshCurrentUserLabel;

  /// No description provided for @sshRawFilePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'# The SSH configuration file is empty.'**
  String get sshRawFilePlaceholder;

  /// No description provided for @sshReloadAction.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get sshReloadAction;

  /// No description provided for @sshSaveRawFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Overwrite the SSH configuration file with the current content?'**
  String get sshSaveRawFileConfirm;

  /// No description provided for @sshOperateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Run SSH action {operation}?'**
  String sshOperateConfirm(String operation);

  /// No description provided for @sshUpdateSettingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Update {label} to {value}?'**
  String sshUpdateSettingConfirm(String label, String value);

  /// No description provided for @sshCertsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No SSH certs'**
  String get sshCertsEmptyTitle;

  /// No description provided for @sshCertsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create or sync an SSH certificate to manage key login from the panel.'**
  String get sshCertsEmptyDescription;

  /// No description provided for @sshCertSyncConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sync SSH certs from the current server?'**
  String get sshCertSyncConfirm;

  /// No description provided for @sshCertDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete SSH cert {name}?'**
  String sshCertDeleteConfirm(String name);

  /// No description provided for @sshCertCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create SSH Cert'**
  String get sshCertCreateTitle;

  /// No description provided for @sshCertEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit SSH Cert'**
  String get sshCertEditTitle;

  /// No description provided for @sshCertEncryptionModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Encryption mode'**
  String get sshCertEncryptionModeLabel;

  /// No description provided for @sshCertPassPhraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get sshCertPassPhraseLabel;

  /// No description provided for @sshCertPublicKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get sshCertPublicKeyLabel;

  /// No description provided for @sshCertPrivateKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get sshCertPrivateKeyLabel;

  /// No description provided for @sshCertModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Create mode'**
  String get sshCertModeLabel;

  /// No description provided for @sshCertModeGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get sshCertModeGenerate;

  /// No description provided for @sshCertModeInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get sshCertModeInput;

  /// No description provided for @sshCertModeImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get sshCertModeImport;

  /// No description provided for @sshCertCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get sshCertCreatedAtLabel;

  /// No description provided for @sshAuthModePassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get sshAuthModePassword;

  /// No description provided for @sshAuthModeKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get sshAuthModeKey;

  /// No description provided for @sshLogsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No SSH logs'**
  String get sshLogsEmptyTitle;

  /// No description provided for @sshLogsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'SSH login logs will appear here after the server records activity.'**
  String get sshLogsEmptyDescription;

  /// No description provided for @sshLogsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search IP, user, or message'**
  String get sshLogsSearchHint;

  /// No description provided for @sshLogsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sshLogsStatusAll;

  /// No description provided for @sshLogsStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get sshLogsStatusSuccess;

  /// No description provided for @sshLogsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get sshLogsStatusFailed;

  /// No description provided for @sshLogsIpLabel.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get sshLogsIpLabel;

  /// No description provided for @sshLogsAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get sshLogsAreaLabel;

  /// No description provided for @sshLogsAuthModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Auth mode'**
  String get sshLogsAuthModeLabel;

  /// No description provided for @sshLogsTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get sshLogsTimeLabel;

  /// No description provided for @sshLogsMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get sshLogsMessageLabel;

  /// No description provided for @sshLogsExportSaved.
  ///
  /// In en, this message translates to:
  /// **'SSH logs exported to {path}'**
  String sshLogsExportSaved(String path);

  /// No description provided for @sshLogCopied.
  ///
  /// In en, this message translates to:
  /// **'SSH log copied'**
  String get sshLogCopied;

  /// No description provided for @sshSessionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No SSH sessions'**
  String get sshSessionsEmptyTitle;

  /// No description provided for @sshSessionsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Active SSH sessions will appear here.'**
  String get sshSessionsEmptyDescription;

  /// No description provided for @sshSessionsLoginUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Login user'**
  String get sshSessionsLoginUserLabel;

  /// No description provided for @sshSessionsLoginIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Login IP'**
  String get sshSessionsLoginIpLabel;

  /// No description provided for @sshSessionsTerminalLabel.
  ///
  /// In en, this message translates to:
  /// **'TTY'**
  String get sshSessionsTerminalLabel;

  /// No description provided for @sshSessionsHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get sshSessionsHostLabel;

  /// No description provided for @sshSessionsLoginTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Login time'**
  String get sshSessionsLoginTimeLabel;

  /// No description provided for @terminalWorkbenchSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminal Sessions'**
  String get terminalWorkbenchSessionsTitle;

  /// No description provided for @terminalWorkbenchNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No terminal sessions'**
  String get terminalWorkbenchNoSessions;

  /// No description provided for @terminalWorkbenchOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Open or create a terminal session'**
  String get terminalWorkbenchOpenHint;

  /// No description provided for @terminalWorkbenchLocalLabel.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get terminalWorkbenchLocalLabel;

  /// No description provided for @terminalWorkbenchStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get terminalWorkbenchStatusConnected;

  /// No description provided for @terminalWorkbenchStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get terminalWorkbenchStatusClosed;

  /// No description provided for @terminalWorkbenchStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get terminalWorkbenchStatusIdle;

  /// No description provided for @terminalWorkbenchKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get terminalWorkbenchKeyboard;

  /// No description provided for @terminalWorkbenchCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get terminalWorkbenchCommand;

  /// No description provided for @terminalWorkbenchQuickCommand.
  ///
  /// In en, this message translates to:
  /// **'Quick Command'**
  String get terminalWorkbenchQuickCommand;

  /// No description provided for @terminalWorkbenchSearchHost.
  ///
  /// In en, this message translates to:
  /// **'Search host'**
  String get terminalWorkbenchSearchHost;

  /// No description provided for @terminalWorkbenchPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get terminalWorkbenchPaste;

  /// No description provided for @terminalWorkbenchSessionClosed.
  ///
  /// In en, this message translates to:
  /// **'Session closed'**
  String get terminalWorkbenchSessionClosed;

  /// No description provided for @sshSessionDisconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect SSH session for {username}?'**
  String sshSessionDisconnectConfirm(String username);

  /// No description provided for @processesSearchPidLabel.
  ///
  /// In en, this message translates to:
  /// **'PID'**
  String get processesSearchPidLabel;

  /// No description provided for @processesSearchNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get processesSearchNameLabel;

  /// No description provided for @processesSearchUserLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get processesSearchUserLabel;

  /// No description provided for @processesFilterStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get processesFilterStatusLabel;

  /// No description provided for @processesSortCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get processesSortCpu;

  /// No description provided for @processesSortMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get processesSortMemory;

  /// No description provided for @processesSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get processesSortName;

  /// No description provided for @processesSortPid.
  ///
  /// In en, this message translates to:
  /// **'PID'**
  String get processesSortPid;

  /// No description provided for @processesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No processes'**
  String get processesEmptyTitle;

  /// No description provided for @processesEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Process data will appear here after the websocket feed returns rows.'**
  String get processesEmptyDescription;

  /// No description provided for @processesListeningPortsLabel.
  ///
  /// In en, this message translates to:
  /// **'Listening ports'**
  String get processesListeningPortsLabel;

  /// No description provided for @processesConnectionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get processesConnectionsLabel;

  /// No description provided for @processesStartTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get processesStartTimeLabel;

  /// No description provided for @processesThreadsLabel.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get processesThreadsLabel;

  /// No description provided for @processesStopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop process {name}?'**
  String processesStopConfirm(String name);

  /// No description provided for @processesStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get processesStatusRunning;

  /// No description provided for @processesStatusSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleeping'**
  String get processesStatusSleep;

  /// No description provided for @processesStatusStop.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get processesStatusStop;

  /// No description provided for @processesStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get processesStatusIdle;

  /// No description provided for @processesStatusWait.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get processesStatusWait;

  /// No description provided for @processesStatusLock.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get processesStatusLock;

  /// No description provided for @processesStatusZombie.
  ///
  /// In en, this message translates to:
  /// **'Zombie'**
  String get processesStatusZombie;

  /// No description provided for @processDetailOverviewSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get processDetailOverviewSectionTitle;

  /// No description provided for @processDetailMemorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get processDetailMemorySectionTitle;

  /// No description provided for @processDetailOpenFilesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Files'**
  String get processDetailOpenFilesSectionTitle;

  /// No description provided for @processDetailConnectionsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get processDetailConnectionsSectionTitle;

  /// No description provided for @processDetailEnvironmentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get processDetailEnvironmentSectionTitle;

  /// No description provided for @processDetailParentPidLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent PID'**
  String get processDetailParentPidLabel;

  /// No description provided for @processDetailDiskReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Disk read'**
  String get processDetailDiskReadLabel;

  /// No description provided for @processDetailDiskWriteLabel.
  ///
  /// In en, this message translates to:
  /// **'Disk write'**
  String get processDetailDiskWriteLabel;

  /// No description provided for @processDetailCommandLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Command line'**
  String get processDetailCommandLineLabel;

  /// No description provided for @processDetailNoEnvironment.
  ///
  /// In en, this message translates to:
  /// **'No environment variables'**
  String get processDetailNoEnvironment;

  /// No description provided for @processDetailNoConnections.
  ///
  /// In en, this message translates to:
  /// **'No network connections'**
  String get processDetailNoConnections;

  /// No description provided for @processDetailNoOpenFiles.
  ///
  /// In en, this message translates to:
  /// **'No open files'**
  String get processDetailNoOpenFiles;

  /// No description provided for @operationsPlaceholderBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back to Operations Center'**
  String get operationsPlaceholderBackAction;

  /// No description provided for @operationsPlaceholderDescription.
  ///
  /// In en, this message translates to:
  /// **'{moduleName} is scheduled for Week {week}. Week 1 only wires the route, shared infrastructure, and reviewable skeleton.'**
  String operationsPlaceholderDescription(String moduleName, int week);

  /// No description provided for @operationsGroupSelectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get operationsGroupSelectorTitle;

  /// No description provided for @operationsGroupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get operationsGroupCreateTitle;

  /// No description provided for @operationsGroupRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get operationsGroupRenameTitle;

  /// No description provided for @operationsGroupCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Center'**
  String get operationsGroupCenterTitle;

  /// No description provided for @operationsGroupCenterDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage reusable groups across core and agent namespaces.'**
  String get operationsGroupCenterDescription;

  /// No description provided for @operationsGroupScopeCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get operationsGroupScopeCore;

  /// No description provided for @operationsGroupScopeAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get operationsGroupScopeAgent;

  /// No description provided for @operationsGroupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a group name'**
  String get operationsGroupNameHint;

  /// No description provided for @operationsGroupEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No groups are available for this module yet. Create one to keep items organized.'**
  String get operationsGroupEmptyDescription;

  /// No description provided for @operationsGroupDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get operationsGroupDefaultLabel;

  /// No description provided for @operationsGroupDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get operationsGroupDeleteConfirmTitle;

  /// No description provided for @operationsGroupDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete group {groupName}? Existing module items will need a new group assignment later.'**
  String operationsGroupDeleteConfirmMessage(String groupName);

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @aiTabMcp.
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get aiTabMcp;

  /// No description provided for @aiMcpSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search MCP servers'**
  String get aiMcpSearchHint;

  /// No description provided for @aiMcpCreate.
  ///
  /// In en, this message translates to:
  /// **'Create server'**
  String get aiMcpCreate;

  /// No description provided for @aiMcpEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit server'**
  String get aiMcpEdit;

  /// No description provided for @aiMcpBindDomain.
  ///
  /// In en, this message translates to:
  /// **'Bind domain'**
  String get aiMcpBindDomain;

  /// No description provided for @aiMcpBindingTitle.
  ///
  /// In en, this message translates to:
  /// **'MCP domain binding'**
  String get aiMcpBindingTitle;

  /// No description provided for @aiMcpNoServers.
  ///
  /// In en, this message translates to:
  /// **'No MCP servers'**
  String get aiMcpNoServers;

  /// No description provided for @aiMcpConfigPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Config Preview'**
  String get aiMcpConfigPreviewTitle;

  /// No description provided for @aiMcpDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete MCP server {name}?'**
  String aiMcpDeleteConfirm(String name);

  /// No description provided for @aiMcpDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create MCP Server'**
  String get aiMcpDialogCreateTitle;

  /// No description provided for @aiMcpDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit MCP Server'**
  String get aiMcpDialogEditTitle;

  /// No description provided for @aiMcpCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get aiMcpCommandLabel;

  /// No description provided for @aiMcpTransportLabel.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get aiMcpTransportLabel;

  /// No description provided for @aiMcpTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get aiMcpTypeLabel;

  /// No description provided for @aiMcpPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get aiMcpPortLabel;

  /// No description provided for @aiMcpBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get aiMcpBaseUrlLabel;

  /// No description provided for @aiMcpHostIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Host IP'**
  String get aiMcpHostIpLabel;

  /// No description provided for @aiMcpContainerLabel.
  ///
  /// In en, this message translates to:
  /// **'Container Name'**
  String get aiMcpContainerLabel;

  /// No description provided for @aiMcpSsePathLabel.
  ///
  /// In en, this message translates to:
  /// **'SSE Path'**
  String get aiMcpSsePathLabel;

  /// No description provided for @aiMcpStreamablePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Streamable HTTP Path'**
  String get aiMcpStreamablePathLabel;

  /// No description provided for @aiMcpExternalUrl.
  ///
  /// In en, this message translates to:
  /// **'External URL'**
  String get aiMcpExternalUrl;

  /// No description provided for @aiMcpStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get aiMcpStatusLabel;

  /// No description provided for @aiMcpNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a server name'**
  String get aiMcpNameRequired;

  /// No description provided for @aiMcpCommandRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a command'**
  String get aiMcpCommandRequired;

  /// No description provided for @aiMcpTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a type'**
  String get aiMcpTypeRequired;

  /// No description provided for @aiMcpTransportRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a transport'**
  String get aiMcpTransportRequired;

  /// No description provided for @aiMcpPortRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid port'**
  String get aiMcpPortRequired;

  /// No description provided for @aiMcpDomainDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Update MCP Domain'**
  String get aiMcpDomainDialogTitle;

  /// No description provided for @aiMcpDomainRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a domain'**
  String get aiMcpDomainRequired;

  /// No description provided for @menuSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu Settings'**
  String get menuSettingsTitle;

  /// No description provided for @menuSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the default menu order returned by the panel.'**
  String get menuSettingsDescription;

  /// No description provided for @menuSettingsAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Menu item'**
  String get menuSettingsAddLabel;

  /// No description provided for @menuSettingsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Menu Item'**
  String get menuSettingsEditTitle;

  /// No description provided for @menuSettingsSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Menu settings saved'**
  String get menuSettingsSaveSuccess;

  /// No description provided for @toolboxDiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Disk Management'**
  String get toolboxDiskTitle;

  /// No description provided for @toolboxDiskCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect disks, partitions, and mount state'**
  String get toolboxDiskCardSubtitle;

  /// No description provided for @toolboxDiskOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Disk Overview'**
  String get toolboxDiskOverviewTitle;

  /// No description provided for @toolboxDiskTotalDisksLabel.
  ///
  /// In en, this message translates to:
  /// **'Total disks'**
  String get toolboxDiskTotalDisksLabel;

  /// No description provided for @toolboxDiskTotalCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Total capacity'**
  String get toolboxDiskTotalCapacityLabel;

  /// No description provided for @toolboxDiskUnpartitionedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpartitioned disks'**
  String get toolboxDiskUnpartitionedSectionTitle;

  /// No description provided for @toolboxDiskSystemSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'System disks'**
  String get toolboxDiskSystemSectionTitle;

  /// No description provided for @toolboxDiskDataSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data disks'**
  String get toolboxDiskDataSectionTitle;

  /// No description provided for @toolboxDiskMountAction.
  ///
  /// In en, this message translates to:
  /// **'Mount'**
  String get toolboxDiskMountAction;

  /// No description provided for @toolboxDiskUnmountAction.
  ///
  /// In en, this message translates to:
  /// **'Unmount'**
  String get toolboxDiskUnmountAction;

  /// No description provided for @toolboxDiskPartitionAction.
  ///
  /// In en, this message translates to:
  /// **'Partition'**
  String get toolboxDiskPartitionAction;

  /// No description provided for @toolboxDiskFilesystemLabel.
  ///
  /// In en, this message translates to:
  /// **'Filesystem'**
  String get toolboxDiskFilesystemLabel;

  /// No description provided for @toolboxDiskMountPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Mount point'**
  String get toolboxDiskMountPointLabel;

  /// No description provided for @toolboxDiskAutoMountLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto mount'**
  String get toolboxDiskAutoMountLabel;

  /// No description provided for @toolboxDiskNoFailLabel.
  ///
  /// In en, this message translates to:
  /// **'No fail'**
  String get toolboxDiskNoFailLabel;

  /// No description provided for @toolboxDiskLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get toolboxDiskLabelLabel;

  /// No description provided for @toolboxDiskMountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Disk mounted'**
  String get toolboxDiskMountSuccess;

  /// No description provided for @toolboxDiskPartitionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Disk partitioned'**
  String get toolboxDiskPartitionSuccess;

  /// No description provided for @toolboxDiskUnmountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Disk unmounted'**
  String get toolboxDiskUnmountSuccess;

  /// No description provided for @toolboxDiskSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get toolboxDiskSizeLabel;

  /// No description provided for @toolboxDiskModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get toolboxDiskModelLabel;

  /// No description provided for @toolboxDiskUnmounted.
  ///
  /// In en, this message translates to:
  /// **'Unmounted'**
  String get toolboxDiskUnmounted;

  /// No description provided for @toolboxDiskSystemDiskTag.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get toolboxDiskSystemDiskTag;

  /// No description provided for @toolboxHostToolTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Tool'**
  String get toolboxHostToolTitle;

  /// No description provided for @toolboxHostToolCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage supervisord service and process files'**
  String get toolboxHostToolCardSubtitle;

  /// No description provided for @toolboxHostToolServiceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Service'**
  String get toolboxHostToolServiceSectionTitle;

  /// No description provided for @toolboxHostToolConfigSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Config'**
  String get toolboxHostToolConfigSectionTitle;

  /// No description provided for @toolboxHostToolProcessSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Processes'**
  String get toolboxHostToolProcessSectionTitle;

  /// No description provided for @toolboxHostToolStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get toolboxHostToolStatusLabel;

  /// No description provided for @toolboxHostToolVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get toolboxHostToolVersionLabel;

  /// No description provided for @toolboxHostToolConfigPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Config path'**
  String get toolboxHostToolConfigPathLabel;

  /// No description provided for @toolboxHostToolServiceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get toolboxHostToolServiceNameLabel;

  /// No description provided for @toolboxHostToolInitAction.
  ///
  /// In en, this message translates to:
  /// **'Initialize'**
  String get toolboxHostToolInitAction;

  /// No description provided for @toolboxHostToolStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get toolboxHostToolStartAction;

  /// No description provided for @toolboxHostToolStopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get toolboxHostToolStopAction;

  /// No description provided for @toolboxHostToolSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Host tool updated'**
  String get toolboxHostToolSaveSuccess;

  /// No description provided for @toolboxHostToolCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get toolboxHostToolCommandLabel;

  /// No description provided for @toolboxHostToolNumprocsLabel.
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get toolboxHostToolNumprocsLabel;

  /// No description provided for @toolboxHostToolUserLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get toolboxHostToolUserLabel;

  /// No description provided for @toolboxHostToolDirLabel.
  ///
  /// In en, this message translates to:
  /// **'Working directory'**
  String get toolboxHostToolDirLabel;

  /// No description provided for @toolboxHostToolEnvironmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get toolboxHostToolEnvironmentLabel;

  /// No description provided for @toolboxHostToolAutoStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto start'**
  String get toolboxHostToolAutoStartLabel;

  /// No description provided for @toolboxHostToolAutoRestartLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto restart'**
  String get toolboxHostToolAutoRestartLabel;

  /// No description provided for @toolboxHostToolProcessCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Supervisor Process'**
  String get toolboxHostToolProcessCreateTitle;

  /// No description provided for @toolboxHostToolProcessEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Supervisor Process'**
  String get toolboxHostToolProcessEditTitle;

  /// No description provided for @toolboxHostToolConfigFileAction.
  ///
  /// In en, this message translates to:
  /// **'Config file'**
  String get toolboxHostToolConfigFileAction;

  /// No description provided for @toolboxHostToolOutLogAction.
  ///
  /// In en, this message translates to:
  /// **'stdout log'**
  String get toolboxHostToolOutLogAction;

  /// No description provided for @toolboxHostToolErrLogAction.
  ///
  /// In en, this message translates to:
  /// **'stderr log'**
  String get toolboxHostToolErrLogAction;

  /// No description provided for @aiTabAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get aiTabAgents;

  /// No description provided for @aiAgentsSubTabAgent.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get aiAgentsSubTabAgent;

  /// No description provided for @aiAgentsSubTabModel.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get aiAgentsSubTabModel;

  /// No description provided for @aiAgentsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search agents'**
  String get aiAgentsSearchHint;

  /// No description provided for @aiAgentsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Agent'**
  String get aiAgentsCreate;

  /// No description provided for @aiAgentsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get aiAgentsDeleteConfirm;

  /// No description provided for @aiAgentsNoAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents found'**
  String get aiAgentsNoAgents;

  /// No description provided for @aiAgentsNoSelection.
  ///
  /// In en, this message translates to:
  /// **'Select an agent to view details'**
  String get aiAgentsNoSelection;

  /// No description provided for @aiAgentsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get aiAgentsOverview;

  /// No description provided for @aiAgentsChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get aiAgentsChannels;

  /// No description provided for @aiAgentsSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get aiAgentsSkills;

  /// No description provided for @aiAgentsSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get aiAgentsSettings;

  /// No description provided for @aiAgentsSkillSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search skills'**
  String get aiAgentsSkillSearchHint;

  /// No description provided for @aiAgentsInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get aiAgentsInstall;

  /// No description provided for @aiAgentsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get aiAgentsEnabled;

  /// No description provided for @aiAgentsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get aiAgentsDisabled;

  /// No description provided for @aiAgentsNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get aiAgentsNotInstalled;

  /// No description provided for @aiAgentsAllowedOrigins.
  ///
  /// In en, this message translates to:
  /// **'Allowed origins'**
  String get aiAgentsAllowedOrigins;

  /// No description provided for @aiAgentsTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get aiAgentsTimezone;

  /// No description provided for @aiAgentsNpmRegistry.
  ///
  /// In en, this message translates to:
  /// **'NPM Registry'**
  String get aiAgentsNpmRegistry;

  /// No description provided for @aiAgentsBrowserEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable browser tool'**
  String get aiAgentsBrowserEnabled;

  /// No description provided for @aiAgentsConfigFile.
  ///
  /// In en, this message translates to:
  /// **'Config file'**
  String get aiAgentsConfigFile;

  /// No description provided for @aiAgentsSaveConfig.
  ///
  /// In en, this message translates to:
  /// **'Save config'**
  String get aiAgentsSaveConfig;

  /// No description provided for @aiAgentsAgentType.
  ///
  /// In en, this message translates to:
  /// **'Agent type'**
  String get aiAgentsAgentType;

  /// No description provided for @aiAgentsOpenclaw.
  ///
  /// In en, this message translates to:
  /// **'OpenClaw'**
  String get aiAgentsOpenclaw;

  /// No description provided for @aiAgentsCopaw.
  ///
  /// In en, this message translates to:
  /// **'CoPaw'**
  String get aiAgentsCopaw;

  /// No description provided for @aiAgentsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get aiAgentsAppVersion;

  /// No description provided for @aiAgentsVersionRequired.
  ///
  /// In en, this message translates to:
  /// **'App version is required'**
  String get aiAgentsVersionRequired;

  /// No description provided for @aiAgentsWebUiPort.
  ///
  /// In en, this message translates to:
  /// **'WebUI port'**
  String get aiAgentsWebUiPort;

  /// No description provided for @aiAgentsPortRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid port'**
  String get aiAgentsPortRequired;

  /// No description provided for @aiAgentsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get aiAgentsAccount;

  /// No description provided for @aiAgentsAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get aiAgentsAccountRequired;

  /// No description provided for @aiAgentsModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiAgentsModel;

  /// No description provided for @aiAgentsModelRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a model'**
  String get aiAgentsModelRequired;

  /// No description provided for @aiAgentsTokenOptional.
  ///
  /// In en, this message translates to:
  /// **'Token (optional)'**
  String get aiAgentsTokenOptional;

  /// No description provided for @aiAgentsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get aiAgentsNameRequired;

  /// No description provided for @aiAgentsProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiAgentsProvider;

  /// No description provided for @aiAgentsProviderRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a provider'**
  String get aiAgentsProviderRequired;

  /// No description provided for @aiAgentsApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get aiAgentsApiKey;

  /// No description provided for @aiAgentsApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API key is required'**
  String get aiAgentsApiKeyRequired;

  /// No description provided for @aiAgentsBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get aiAgentsBaseUrl;

  /// No description provided for @aiAgentsApiType.
  ///
  /// In en, this message translates to:
  /// **'API Type'**
  String get aiAgentsApiType;

  /// No description provided for @aiAgentsApiTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'API type is required'**
  String get aiAgentsApiTypeRequired;

  /// No description provided for @aiAgentsRememberApiKey.
  ///
  /// In en, this message translates to:
  /// **'Remember API key'**
  String get aiAgentsRememberApiKey;

  /// No description provided for @aiAgentsSyncAgents.
  ///
  /// In en, this message translates to:
  /// **'Sync associated agents'**
  String get aiAgentsSyncAgents;

  /// No description provided for @aiAgentsVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get aiAgentsVerify;

  /// No description provided for @aiAgentsVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get aiAgentsVerified;

  /// No description provided for @aiAgentsUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get aiAgentsUnverified;

  /// No description provided for @aiAgentsAllProviders.
  ///
  /// In en, this message translates to:
  /// **'All providers'**
  String get aiAgentsAllProviders;

  /// No description provided for @aiAgentsBrowserConfig.
  ///
  /// In en, this message translates to:
  /// **'Browser config'**
  String get aiAgentsBrowserConfig;

  /// No description provided for @aiAgentsBrowserDefaultProfile.
  ///
  /// In en, this message translates to:
  /// **'Default profile'**
  String get aiAgentsBrowserDefaultProfile;

  /// No description provided for @aiAgentsBrowserExecutablePath.
  ///
  /// In en, this message translates to:
  /// **'Executable path'**
  String get aiAgentsBrowserExecutablePath;

  /// No description provided for @aiAgentsBrowserHeadless.
  ///
  /// In en, this message translates to:
  /// **'Headless mode'**
  String get aiAgentsBrowserHeadless;

  /// No description provided for @aiAgentsBrowserNoSandbox.
  ///
  /// In en, this message translates to:
  /// **'Disable sandbox'**
  String get aiAgentsBrowserNoSandbox;

  /// No description provided for @aiAgentsSaveBrowserConfig.
  ///
  /// In en, this message translates to:
  /// **'Save browser config'**
  String get aiAgentsSaveBrowserConfig;

  /// No description provided for @aiAgentsBrowserDefaultProfileRequired.
  ///
  /// In en, this message translates to:
  /// **'Default profile is required'**
  String get aiAgentsBrowserDefaultProfileRequired;

  /// No description provided for @aiAgentsFeishuPairing.
  ///
  /// In en, this message translates to:
  /// **'Feishu pairing'**
  String get aiAgentsFeishuPairing;

  /// No description provided for @aiAgentsPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get aiAgentsPairingCode;

  /// No description provided for @aiAgentsApprovePairing.
  ///
  /// In en, this message translates to:
  /// **'Approve pairing'**
  String get aiAgentsApprovePairing;

  /// No description provided for @aiAgentsPairingCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Pairing code is required'**
  String get aiAgentsPairingCodeRequired;

  /// No description provided for @aiAgentsPairingApproveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pairing approved'**
  String get aiAgentsPairingApproveSuccess;

  /// No description provided for @containerNetworkIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get containerNetworkIdLabel;

  /// No description provided for @containerNetworkDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get containerNetworkDriverLabel;

  /// No description provided for @containerNetworkScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get containerNetworkScopeLabel;

  /// No description provided for @containerNetworkInternalLabel.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get containerNetworkInternalLabel;

  /// No description provided for @containerNetworkAttachableLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachable'**
  String get containerNetworkAttachableLabel;

  /// No description provided for @containerNetworkDriverChip.
  ///
  /// In en, this message translates to:
  /// **'Driver: {driver}'**
  String containerNetworkDriverChip(String driver);

  /// No description provided for @containerNetworkSystemChip.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get containerNetworkSystemChip;

  /// No description provided for @containerNetworkEnableIPv6.
  ///
  /// In en, this message translates to:
  /// **'Enable IPv6'**
  String get containerNetworkEnableIPv6;

  /// No description provided for @containerNetworkLabelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get containerNetworkLabelsLabel;

  /// No description provided for @containerNetworkLabelsHint.
  ///
  /// In en, this message translates to:
  /// **'key1=value1,key2=value2'**
  String get containerNetworkLabelsHint;

  /// No description provided for @volumeDetailDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get volumeDetailDriver;

  /// No description provided for @volumeDetailMountpoint.
  ///
  /// In en, this message translates to:
  /// **'Mountpoint'**
  String get volumeDetailMountpoint;

  /// No description provided for @volumeDetailLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get volumeDetailLabels;

  /// No description provided for @volumeDetailOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get volumeDetailOptions;

  /// No description provided for @volumeFormLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get volumeFormLabels;

  /// No description provided for @volumeFormLabelsHint.
  ///
  /// In en, this message translates to:
  /// **'key=value, one per line'**
  String get volumeFormLabelsHint;

  /// No description provided for @volumeFormOptions.
  ///
  /// In en, this message translates to:
  /// **'Mount Options'**
  String get volumeFormOptions;

  /// No description provided for @volumeFormOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'key=value, one per line'**
  String get volumeFormOptionsHint;

  /// No description provided for @securityGatewayPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & Gateway'**
  String get securityGatewayPageTitle;

  /// No description provided for @securityGatewayUnifiedSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Unified security summary'**
  String get securityGatewayUnifiedSummaryTitle;

  /// No description provided for @securityGatewaySummarySection.
  ///
  /// In en, this message translates to:
  /// **'Security Summary'**
  String get securityGatewaySummarySection;

  /// No description provided for @securityGatewayEntryFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry Focus'**
  String get securityGatewayEntryFocusLabel;

  /// No description provided for @securityGatewayAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get securityGatewayAvailable;

  /// No description provided for @securityGatewayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get securityGatewayUnavailable;

  /// No description provided for @securityGatewayWebsiteExpiringLabel.
  ///
  /// In en, this message translates to:
  /// **'Website Expiring'**
  String get securityGatewayWebsiteExpiringLabel;

  /// No description provided for @securityGatewayCertificateCount.
  ///
  /// In en, this message translates to:
  /// **'{count} certificate(s)'**
  String securityGatewayCertificateCount(int count);

  /// No description provided for @securityGatewayLatestApplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest Apply'**
  String get securityGatewayLatestApplyLabel;

  /// No description provided for @securityGatewayQuickActionsSection.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get securityGatewayQuickActionsSection;

  /// No description provided for @securityGatewayCertificateCenterAction.
  ///
  /// In en, this message translates to:
  /// **'Certificate Center'**
  String get securityGatewayCertificateCenterAction;

  /// No description provided for @securityGatewayOpenRestyHttpsAction.
  ///
  /// In en, this message translates to:
  /// **'OpenResty HTTPS'**
  String get securityGatewayOpenRestyHttpsAction;

  /// No description provided for @securityGatewayRollbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rolled back the latest local snapshot.'**
  String get securityGatewayRollbackSuccess;

  /// No description provided for @securityGatewayRollbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rollback snapshot available.'**
  String get securityGatewayRollbackEmpty;

  /// No description provided for @securityGatewayRollbackLatestAction.
  ///
  /// In en, this message translates to:
  /// **'Rollback Latest'**
  String get securityGatewayRollbackLatestAction;

  /// No description provided for @securityGatewayPanelTlsSection.
  ///
  /// In en, this message translates to:
  /// **'Panel TLS'**
  String get securityGatewayPanelTlsSection;

  /// No description provided for @securityGatewayStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get securityGatewayStatusLabel;

  /// No description provided for @securityGatewayLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get securityGatewayLoaded;

  /// No description provided for @securityGatewayRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get securityGatewayRiskLabel;

  /// No description provided for @securityGatewayNoPanelTlsRisk.
  ///
  /// In en, this message translates to:
  /// **'No panel TLS risk detected'**
  String get securityGatewayNoPanelTlsRisk;

  /// No description provided for @securityGatewayRecentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get securityGatewayRecentLabel;

  /// No description provided for @securityGatewayOpenPanelTlsAction.
  ///
  /// In en, this message translates to:
  /// **'Open Panel TLS details'**
  String get securityGatewayOpenPanelTlsAction;

  /// No description provided for @securityGatewayWebsiteCertsSection.
  ///
  /// In en, this message translates to:
  /// **'Website Certificates'**
  String get securityGatewayWebsiteCertsSection;

  /// No description provided for @securityGatewaySummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get securityGatewaySummaryLabel;

  /// No description provided for @securityGatewayCertsLoadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} certificates loaded'**
  String securityGatewayCertsLoadedCount(int count);

  /// No description provided for @securityGatewayExpiringSoonCount.
  ///
  /// In en, this message translates to:
  /// **'{count} expiring soon'**
  String securityGatewayExpiringSoonCount(int count);

  /// No description provided for @securityGatewayOpenCertCenterAction.
  ///
  /// In en, this message translates to:
  /// **'Open certificate center'**
  String get securityGatewayOpenCertCenterAction;

  /// No description provided for @securityGatewayOpenWebsiteStrategyAction.
  ///
  /// In en, this message translates to:
  /// **'Open current website strategy'**
  String get securityGatewayOpenWebsiteStrategyAction;

  /// No description provided for @securityGatewayOpenRestyGatewaySection.
  ///
  /// In en, this message translates to:
  /// **'OpenResty Gateway'**
  String get securityGatewayOpenRestyGatewaySection;

  /// No description provided for @securityGatewayOpenOpenRestyAction.
  ///
  /// In en, this message translates to:
  /// **'Open OpenResty console'**
  String get securityGatewayOpenOpenRestyAction;

  /// No description provided for @securityGatewayEntryPanelTls.
  ///
  /// In en, this message translates to:
  /// **'Panel TLS'**
  String get securityGatewayEntryPanelTls;

  /// No description provided for @securityGatewayEntryWebsiteCerts.
  ///
  /// In en, this message translates to:
  /// **'Website Certificates'**
  String get securityGatewayEntryWebsiteCerts;

  /// No description provided for @securityGatewayEntryOpenResty.
  ///
  /// In en, this message translates to:
  /// **'OpenResty Gateway'**
  String get securityGatewayEntryOpenResty;

  /// No description provided for @securityGatewayOpenRestyLabel.
  ///
  /// In en, this message translates to:
  /// **'OpenResty'**
  String get securityGatewayOpenRestyLabel;

  /// No description provided for @securityGatewayRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get securityGatewayRunning;

  /// No description provided for @securityGatewayInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get securityGatewayInactive;

  /// No description provided for @securityGatewayEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get securityGatewayEnabled;

  /// No description provided for @securityGatewayDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get securityGatewayDisabled;

  /// No description provided for @securityGatewayRiskPanelTlsExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Panel TLS expired'**
  String get securityGatewayRiskPanelTlsExpiredTitle;

  /// No description provided for @securityGatewayRiskPanelTlsExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'The panel TLS certificate is expired and should be replaced.'**
  String get securityGatewayRiskPanelTlsExpiredMessage;

  /// No description provided for @securityGatewayRiskWebsiteCertsExpiringTitle.
  ///
  /// In en, this message translates to:
  /// **'Website certificates expiring'**
  String get securityGatewayRiskWebsiteCertsExpiringTitle;

  /// No description provided for @securityGatewayRiskWebsiteCertsExpiringMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} website certificate(s) expire within 30 days.'**
  String securityGatewayRiskWebsiteCertsExpiringMessage(int count);

  /// No description provided for @securityGatewayRiskOpenRestyUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenResty status unavailable'**
  String get securityGatewayRiskOpenRestyUnavailableTitle;

  /// No description provided for @securityGatewayRiskOpenRestyUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The gateway is not reporting as active.'**
  String get securityGatewayRiskOpenRestyUnavailableMessage;

  /// No description provided for @securityGatewayNoRecentSnapshot.
  ///
  /// In en, this message translates to:
  /// **'No recent local snapshot'**
  String get securityGatewayNoRecentSnapshot;

  /// No description provided for @websiteSiteSslPageTitle.
  ///
  /// In en, this message translates to:
  /// **'HTTPS Strategy'**
  String get websiteSiteSslPageTitle;

  /// No description provided for @websiteSiteSslPageTitleWithDomain.
  ///
  /// In en, this message translates to:
  /// **'HTTPS Strategy · {domain}'**
  String websiteSiteSslPageTitleWithDomain(String domain);

  /// No description provided for @websiteSiteSslRiskNoticesTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk notices'**
  String get websiteSiteSslRiskNoticesTitle;

  /// No description provided for @websiteSiteSslCurrentCertSection.
  ///
  /// In en, this message translates to:
  /// **'Current Certificate'**
  String get websiteSiteSslCurrentCertSection;

  /// No description provided for @websiteSiteSslNoCertificateBound.
  ///
  /// In en, this message translates to:
  /// **'No certificate bound'**
  String get websiteSiteSslNoCertificateBound;

  /// No description provided for @websiteSiteSslProviderRow.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get websiteSiteSslProviderRow;

  /// No description provided for @websiteSiteSslExpirationRow.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get websiteSiteSslExpirationRow;

  /// No description provided for @websiteSiteSslCurrentModeRow.
  ///
  /// In en, this message translates to:
  /// **'Current Mode'**
  String get websiteSiteSslCurrentModeRow;

  /// No description provided for @websiteSiteSslStrategySection.
  ///
  /// In en, this message translates to:
  /// **'HTTPS Strategy'**
  String get websiteSiteSslStrategySection;

  /// No description provided for @websiteSiteSslHttpModeRow.
  ///
  /// In en, this message translates to:
  /// **'HTTP Mode'**
  String get websiteSiteSslHttpModeRow;

  /// No description provided for @websiteSiteSslCertTypeRow.
  ///
  /// In en, this message translates to:
  /// **'Certificate Type'**
  String get websiteSiteSslCertTypeRow;

  /// No description provided for @websiteSiteSslEditStrategyAction.
  ///
  /// In en, this message translates to:
  /// **'Edit strategy'**
  String get websiteSiteSslEditStrategyAction;

  /// No description provided for @websiteSiteSslPreviewDiffAction.
  ///
  /// In en, this message translates to:
  /// **'Preview diff'**
  String get websiteSiteSslPreviewDiffAction;

  /// No description provided for @websiteSiteSslStrategyDiffTitle.
  ///
  /// In en, this message translates to:
  /// **'Strategy diff preview'**
  String get websiteSiteSslStrategyDiffTitle;

  /// No description provided for @websiteSiteSslCertActionsSection.
  ///
  /// In en, this message translates to:
  /// **'Certificate Actions'**
  String get websiteSiteSslCertActionsSection;

  /// No description provided for @websiteSiteSslSelectedCertRow.
  ///
  /// In en, this message translates to:
  /// **'Selected Certificate'**
  String get websiteSiteSslSelectedCertRow;

  /// No description provided for @websiteSiteSslOpenCertCenterAction.
  ///
  /// In en, this message translates to:
  /// **'Open certificate center'**
  String get websiteSiteSslOpenCertCenterAction;

  /// No description provided for @websiteSiteSslRollbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rolled back last successful HTTPS strategy.'**
  String get websiteSiteSslRollbackSuccess;

  /// No description provided for @websiteSiteSslRollbackAction.
  ///
  /// In en, this message translates to:
  /// **'Rollback last change'**
  String get websiteSiteSslRollbackAction;

  /// No description provided for @websiteSiteSslAdvancedSection.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get websiteSiteSslAdvancedSection;

  /// No description provided for @websiteSiteSslAdvancedDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the advanced page for certificate obtain/upload/update flows that are outside the binding strategy path.'**
  String get websiteSiteSslAdvancedDescription;

  /// No description provided for @websiteSiteSslOpenAdvancedAction.
  ///
  /// In en, this message translates to:
  /// **'Open advanced SSL page'**
  String get websiteSiteSslOpenAdvancedAction;

  /// No description provided for @websiteSiteSslUpdateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Update HTTPS strategy'**
  String get websiteSiteSslUpdateDialogTitle;

  /// No description provided for @websiteSiteSslEnableHttpsLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable HTTPS'**
  String get websiteSiteSslEnableHttpsLabel;

  /// No description provided for @websiteSiteSslNoCertificate.
  ///
  /// In en, this message translates to:
  /// **'No certificate'**
  String get websiteSiteSslNoCertificate;

  /// No description provided for @websiteSiteSslPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get websiteSiteSslPreviewAction;

  /// No description provided for @websiteSiteSslRiskNoCertTitle.
  ///
  /// In en, this message translates to:
  /// **'HTTPS enabled without certificate'**
  String get websiteSiteSslRiskNoCertTitle;

  /// No description provided for @websiteSiteSslRiskNoCertMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable HTTPS only after selecting a valid certificate.'**
  String get websiteSiteSslRiskNoCertMessage;

  /// No description provided for @websiteSiteSslRiskDomainMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Domain mismatch'**
  String get websiteSiteSslRiskDomainMismatchTitle;

  /// No description provided for @websiteSiteSslRiskDomainMismatchMessage.
  ///
  /// In en, this message translates to:
  /// **'The selected certificate primary domain does not match the current website domain.'**
  String get websiteSiteSslRiskDomainMismatchMessage;

  /// No description provided for @websiteSiteSslRiskExpiredCertTitle.
  ///
  /// In en, this message translates to:
  /// **'Expired certificate'**
  String get websiteSiteSslRiskExpiredCertTitle;

  /// No description provided for @websiteSiteSslRiskExpiredCertMessage.
  ///
  /// In en, this message translates to:
  /// **'The selected certificate is already expired.'**
  String get websiteSiteSslRiskExpiredCertMessage;

  /// No description provided for @websiteSiteSslRiskExpiringSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate expiring soon'**
  String get websiteSiteSslRiskExpiringSoonTitle;

  /// No description provided for @websiteSiteSslRiskExpiringSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'The selected certificate should be rotated soon.'**
  String get websiteSiteSslRiskExpiringSoonMessage;

  /// No description provided for @websiteSiteSslDiffLabelHttps.
  ///
  /// In en, this message translates to:
  /// **'HTTPS'**
  String get websiteSiteSslDiffLabelHttps;

  /// No description provided for @websiteSiteSslDiffLabelHttpMode.
  ///
  /// In en, this message translates to:
  /// **'HTTP Mode'**
  String get websiteSiteSslDiffLabelHttpMode;

  /// No description provided for @websiteSiteSslDiffLabelCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get websiteSiteSslDiffLabelCertificate;

  /// No description provided for @websiteSiteSslDiffLabelExpiration.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get websiteSiteSslDiffLabelExpiration;

  /// No description provided for @websiteSiteSslDiffLabelProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get websiteSiteSslDiffLabelProvider;

  /// No description provided for @phpExtensionsRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} Records'**
  String phpExtensionsRecordsTitle(String title);

  /// No description provided for @phpExtensionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get phpExtensionsLabel;

  /// No description provided for @commonUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get commonUpdated;

  /// No description provided for @commonUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get commonUpdateFailed;

  /// No description provided for @commonOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get commonOperationFailed;

  /// No description provided for @commonDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get commonDeleted;

  /// No description provided for @commonDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get commonDeleteFailed;

  /// No description provided for @commonTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get commonTestConnection;

  /// No description provided for @commonTestPassed.
  ///
  /// In en, this message translates to:
  /// **'Connection test passed'**
  String get commonTestPassed;

  /// No description provided for @commonTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection test failed'**
  String get commonTestFailed;

  /// No description provided for @commonAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get commonAddress;

  /// No description provided for @commonVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get commonVersion;

  /// No description provided for @commonStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// No description provided for @commonSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get commonSize;

  /// No description provided for @commonType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get commonType;

  /// No description provided for @commonCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get commonCommand;

  /// No description provided for @commonImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get commonImage;

  /// No description provided for @commonTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get commonTimeout;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get commonAction;

  /// No description provided for @commonEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get commonEnable;

  /// No description provided for @commonWebsiteIds.
  ///
  /// In en, this message translates to:
  /// **'Website IDs (comma separated)'**
  String get commonWebsiteIds;

  /// No description provided for @commonTimeoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'Timeout (s)'**
  String get commonTimeoutSeconds;

  /// No description provided for @websiteHttpsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update HTTPS config'**
  String get websiteHttpsUpdateFailed;

  /// No description provided for @websiteHttpsHsts.
  ///
  /// In en, this message translates to:
  /// **'HSTS'**
  String get websiteHttpsHsts;

  /// No description provided for @websiteHttpsSslCertificate.
  ///
  /// In en, this message translates to:
  /// **'SSL Certificate'**
  String get websiteHttpsSslCertificate;

  /// No description provided for @websiteRedirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Redirect'**
  String get websiteRedirectTitle;

  /// No description provided for @websiteRedirectEmpty.
  ///
  /// In en, this message translates to:
  /// **'No redirect rules'**
  String get websiteRedirectEmpty;

  /// No description provided for @websiteCorsTitle.
  ///
  /// In en, this message translates to:
  /// **'CORS'**
  String get websiteCorsTitle;

  /// No description provided for @websiteLeechTitle.
  ///
  /// In en, this message translates to:
  /// **'Anti-Leech'**
  String get websiteLeechTitle;

  /// No description provided for @websiteLeechProtection.
  ///
  /// In en, this message translates to:
  /// **'Anti-Leech Protection'**
  String get websiteLeechProtection;

  /// No description provided for @websiteLogClear.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get websiteLogClear;

  /// No description provided for @websiteLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs'**
  String get websiteLogEmpty;

  /// No description provided for @websiteAuthBasicTitle.
  ///
  /// In en, this message translates to:
  /// **'Auth'**
  String get websiteAuthBasicTitle;

  /// No description provided for @websiteAuthBasicEmpty.
  ///
  /// In en, this message translates to:
  /// **'No auth users'**
  String get websiteAuthBasicEmpty;

  /// No description provided for @websiteResourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get websiteResourceTitle;

  /// No description provided for @websiteLoadBalancerTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Balancer'**
  String get websiteLoadBalancerTitle;

  /// No description provided for @websiteLoadBalancerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No load balancers'**
  String get websiteLoadBalancerEmpty;

  /// No description provided for @routingRulesBatchActions.
  ///
  /// In en, this message translates to:
  /// **'Batch Actions'**
  String get routingRulesBatchActions;

  /// No description provided for @routingRulesBatchProxyStatus.
  ///
  /// In en, this message translates to:
  /// **'Batch Proxy Status'**
  String get routingRulesBatchProxyStatus;

  /// No description provided for @routingRulesBatchDeleteProxy.
  ///
  /// In en, this message translates to:
  /// **'Batch Delete Proxy'**
  String get routingRulesBatchDeleteProxy;

  /// No description provided for @routingRulesBatchRedirectFile.
  ///
  /// In en, this message translates to:
  /// **'Batch Redirect File'**
  String get routingRulesBatchRedirectFile;

  /// No description provided for @routingRulesBatchLoadBalancerFile.
  ///
  /// In en, this message translates to:
  /// **'Batch Load Balancer File'**
  String get routingRulesBatchLoadBalancerFile;

  /// No description provided for @routingRulesBatchInvalidIds.
  ///
  /// In en, this message translates to:
  /// **'No valid website IDs.'**
  String get routingRulesBatchInvalidIds;

  /// No description provided for @routingRulesBatchResult.
  ///
  /// In en, this message translates to:
  /// **'Batch done: success {success}, failed {failed}.'**
  String routingRulesBatchResult(int success, int failed);

  /// No description provided for @fileShareTitle.
  ///
  /// In en, this message translates to:
  /// **'File Shares'**
  String get fileShareTitle;

  /// No description provided for @fileShareEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shares'**
  String get fileShareEmpty;

  /// No description provided for @wgetTitle.
  ///
  /// In en, this message translates to:
  /// **'WGET Downloads'**
  String get wgetTitle;

  /// No description provided for @wgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active downloads'**
  String get wgetEmpty;

  /// No description provided for @wgetStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Stop failed'**
  String get wgetStopFailed;

  /// No description provided for @wgetStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get wgetStopped;

  /// No description provided for @fileHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get fileHistoryEmpty;

  /// No description provided for @fileHistoryRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get fileHistoryRestore;

  /// No description provided for @fileHistoryRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get fileHistoryRestored;

  /// No description provided for @fileHistoryRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get fileHistoryRestoreFailed;

  /// No description provided for @filePermissionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filePermissionApply;

  /// No description provided for @filePermissionRecursive.
  ///
  /// In en, this message translates to:
  /// **'Recursive'**
  String get filePermissionRecursive;

  /// No description provided for @filePermissionOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner (e.g. root)'**
  String get filePermissionOwner;

  /// No description provided for @filePermissionGroup.
  ///
  /// In en, this message translates to:
  /// **'Group (e.g. root)'**
  String get filePermissionGroup;

  /// No description provided for @filePermissionMode.
  ///
  /// In en, this message translates to:
  /// **'Mode (e.g. 0644, 0755)'**
  String get filePermissionMode;

  /// No description provided for @filePermissionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Permissions updated'**
  String get filePermissionUpdated;

  /// No description provided for @recycleBinStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin Status'**
  String get recycleBinStatusTitle;

  /// No description provided for @recycleBinTitle.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get recycleBinTitle;

  /// No description provided for @aiGpuHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'GPU History'**
  String get aiGpuHistoryTitle;

  /// No description provided for @aiGpuHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No GPU data'**
  String get aiGpuHistoryEmpty;

  /// No description provided for @mcpServerDetailServerName.
  ///
  /// In en, this message translates to:
  /// **'Server Name'**
  String get mcpServerDetailServerName;

  /// No description provided for @mcpServerDetailSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get mcpServerDetailSyncStatus;

  /// No description provided for @mcpServerDetailSynced.
  ///
  /// In en, this message translates to:
  /// **'Status synced'**
  String get mcpServerDetailSynced;

  /// No description provided for @mcpServerDetailSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get mcpServerDetailSyncFailed;

  /// No description provided for @mcpServerDetailTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Test failed'**
  String get mcpServerDetailTestFailed;

  /// No description provided for @aiAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Accounts'**
  String get aiAccountsTitle;

  /// No description provided for @aiAccountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get aiAccountsEmpty;

  /// No description provided for @aiOllamaTitle.
  ///
  /// In en, this message translates to:
  /// **'Ollama Models'**
  String get aiOllamaTitle;

  /// No description provided for @aiOllamaEmpty.
  ///
  /// In en, this message translates to:
  /// **'No models'**
  String get aiOllamaEmpty;

  /// No description provided for @aiOllamaSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get aiOllamaSync;

  /// No description provided for @aiOllamaSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get aiOllamaSynced;

  /// No description provided for @aiOllamaSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get aiOllamaSyncFailed;

  /// No description provided for @aiOllamaLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get aiOllamaLoadFailed;

  /// No description provided for @aiOllamaLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get aiOllamaLoading;

  /// No description provided for @aiOllamaModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get aiOllamaModified;

  /// No description provided for @aiAgentsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Agents'**
  String get aiAgentsTitle;

  /// No description provided for @databaseMongodbEmpty.
  ///
  /// In en, this message translates to:
  /// **'No databases'**
  String get databaseMongodbEmpty;

  /// No description provided for @databaseMysqlVariablesTitle.
  ///
  /// In en, this message translates to:
  /// **'MySQL Variables'**
  String get databaseMysqlVariablesTitle;

  /// No description provided for @databaseMysqlVariablesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No variables'**
  String get databaseMysqlVariablesEmpty;

  /// No description provided for @databasePgPrivilegesTitle.
  ///
  /// In en, this message translates to:
  /// **'PostgreSQL Privileges'**
  String get databasePgPrivilegesTitle;

  /// No description provided for @databasePgPrivilegesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No privileges'**
  String get databasePgPrivilegesEmpty;

  /// No description provided for @databaseRedisRdbTitle.
  ///
  /// In en, this message translates to:
  /// **'RDB Persistence'**
  String get databaseRedisRdbTitle;

  /// No description provided for @databaseRedisRdbDesc.
  ///
  /// In en, this message translates to:
  /// **'RDB snapshot'**
  String get databaseRedisRdbDesc;

  /// No description provided for @databaseRedisAofTitle.
  ///
  /// In en, this message translates to:
  /// **'AOF Persistence'**
  String get databaseRedisAofTitle;

  /// No description provided for @databaseRedisAofDesc.
  ///
  /// In en, this message translates to:
  /// **'Append-only file'**
  String get databaseRedisAofDesc;

  /// No description provided for @databaseSlowLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Slow Query Log'**
  String get databaseSlowLogTitle;

  /// No description provided for @databaseSlowLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No slow queries'**
  String get databaseSlowLogEmpty;

  /// No description provided for @databaseSlowLogDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get databaseSlowLogDuration;

  /// No description provided for @databaseRemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get databaseRemoteTitle;

  /// No description provided for @databaseRemoteTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeout (s)'**
  String get databaseRemoteTimeoutLabel;

  /// No description provided for @databaseRemoteTestBeforeSave.
  ///
  /// In en, this message translates to:
  /// **'Test connection before saving'**
  String get databaseRemoteTestBeforeSave;

  /// No description provided for @containerInspectEntrypoint.
  ///
  /// In en, this message translates to:
  /// **'Entrypoint'**
  String get containerInspectEntrypoint;

  /// No description provided for @containerInspectWorkingDir.
  ///
  /// In en, this message translates to:
  /// **'Working Dir'**
  String get containerInspectWorkingDir;

  /// No description provided for @containerInspectGateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get containerInspectGateway;

  /// No description provided for @dockerConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Docker Configuration'**
  String get dockerConfigTitle;

  /// No description provided for @containerMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Container Maintenance'**
  String get containerMaintenanceTitle;

  /// No description provided for @containerMaintenanceCommitTitle.
  ///
  /// In en, this message translates to:
  /// **'Commit Container'**
  String get containerMaintenanceCommitTitle;

  /// No description provided for @containerMaintenanceCommitMessage.
  ///
  /// In en, this message translates to:
  /// **'Commit Message (optional)'**
  String get containerMaintenanceCommitMessage;

  /// No description provided for @containerMaintenanceNewImageName.
  ///
  /// In en, this message translates to:
  /// **'New Image Name (e.g. myimage:v1)'**
  String get containerMaintenanceNewImageName;

  /// No description provided for @containerMaintenanceCommit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get containerMaintenanceCommit;

  /// No description provided for @containerMaintenanceCommitted.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get containerMaintenanceCommitted;

  /// No description provided for @containerMaintenanceCommitFailed.
  ///
  /// In en, this message translates to:
  /// **'Commit failed'**
  String get containerMaintenanceCommitFailed;

  /// No description provided for @containerMaintenancePruneTitle.
  ///
  /// In en, this message translates to:
  /// **'Prune Stopped Containers'**
  String get containerMaintenancePruneTitle;

  /// No description provided for @containerMaintenancePrune.
  ///
  /// In en, this message translates to:
  /// **'Prune'**
  String get containerMaintenancePrune;

  /// No description provided for @containerMaintenancePruneFailed.
  ///
  /// In en, this message translates to:
  /// **'Prune failed'**
  String get containerMaintenancePruneFailed;

  /// No description provided for @containerMaintenanceContainerId.
  ///
  /// In en, this message translates to:
  /// **'Container ID'**
  String get containerMaintenanceContainerId;

  /// No description provided for @containerFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get containerFilesTitle;

  /// No description provided for @containerFilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get containerFilesEmpty;

  /// No description provided for @containerFilesDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get containerFilesDirectory;

  /// No description provided for @containerFilesSizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{size} bytes'**
  String containerFilesSizeBytes(String size);

  /// No description provided for @imageOpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Operations'**
  String get imageOpsTitle;

  /// No description provided for @imageOpsPushImage.
  ///
  /// In en, this message translates to:
  /// **'Push Image'**
  String get imageOpsPushImage;

  /// No description provided for @imageOpsPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get imageOpsPush;

  /// No description provided for @imageOpsPushStarted.
  ///
  /// In en, this message translates to:
  /// **'Push started'**
  String get imageOpsPushStarted;

  /// No description provided for @imageOpsPushFailed.
  ///
  /// In en, this message translates to:
  /// **'Push failed'**
  String get imageOpsPushFailed;

  /// No description provided for @imageOpsSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save Image to Tar'**
  String get imageOpsSaveImage;

  /// No description provided for @imageOpsImageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get imageOpsImageSaved;

  /// No description provided for @imageOpsTagImage.
  ///
  /// In en, this message translates to:
  /// **'Tag Image'**
  String get imageOpsTagImage;

  /// No description provided for @imageOpsTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get imageOpsTag;

  /// No description provided for @imageOpsTagged.
  ///
  /// In en, this message translates to:
  /// **'Tagged'**
  String get imageOpsTagged;

  /// No description provided for @imageOpsTagFailed.
  ///
  /// In en, this message translates to:
  /// **'Tag failed'**
  String get imageOpsTagFailed;

  /// No description provided for @imageOpsSourceImage.
  ///
  /// In en, this message translates to:
  /// **'Source image'**
  String get imageOpsSourceImage;

  /// No description provided for @imageOpsTargetTag.
  ///
  /// In en, this message translates to:
  /// **'Target tag'**
  String get imageOpsTargetTag;

  /// No description provided for @imageOpsImageName.
  ///
  /// In en, this message translates to:
  /// **'Image name'**
  String get imageOpsImageName;

  /// No description provided for @imageOpsImageNameHint.
  ///
  /// In en, this message translates to:
  /// **'Image name (e.g. registry/myimage:v1)'**
  String get imageOpsImageNameHint;

  /// No description provided for @toolboxSupervisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get toolboxSupervisorTitle;

  /// No description provided for @toolboxSupervisorStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Status'**
  String get toolboxSupervisorStatusTitle;

  /// No description provided for @toolboxSupervisorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No processes'**
  String get toolboxSupervisorEmpty;

  /// No description provided for @toolboxSupervisorNotInit.
  ///
  /// In en, this message translates to:
  /// **'Not initialized'**
  String get toolboxSupervisorNotInit;

  /// No description provided for @monitorSettingsStatus.
  ///
  /// In en, this message translates to:
  /// **'Monitor Status'**
  String get monitorSettingsStatus;

  /// No description provided for @fileHistoryTitleWith.
  ///
  /// In en, this message translates to:
  /// **'History: {path}'**
  String fileHistoryTitleWith(String path);

  /// No description provided for @filePermissionTitleWith.
  ///
  /// In en, this message translates to:
  /// **'Permissions ({count} files)'**
  String filePermissionTitleWith(int count);

  /// No description provided for @aiOllamaSizeWith.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String aiOllamaSizeWith(String size);

  /// No description provided for @aiAgentsTypeWith.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String aiAgentsTypeWith(String type);

  /// No description provided for @databaseMongodbSizeWith.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String databaseMongodbSizeWith(String size);

  /// No description provided for @databasePgPrivilegeWith.
  ///
  /// In en, this message translates to:
  /// **'Privileges: {privileges}'**
  String databasePgPrivilegeWith(String privileges);

  /// No description provided for @databaseSlowLogTimeWith.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String databaseSlowLogTimeWith(String time);

  /// No description provided for @containerInspectIpWith.
  ///
  /// In en, this message translates to:
  /// **'IP: {ip}'**
  String containerInspectIpWith(String ip);

  /// No description provided for @monitorSettingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit {key}'**
  String monitorSettingsEdit(String key);

  /// No description provided for @containerInspectTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect'**
  String get containerInspectTitle;

  /// No description provided for @orchestrationTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get orchestrationTemplates;

  /// No description provided for @composeTemplateCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get composeTemplateCreate;

  /// No description provided for @composeTemplateEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get composeTemplateEdit;

  /// No description provided for @composeTemplateContent.
  ///
  /// In en, this message translates to:
  /// **'Template Content'**
  String get composeTemplateContent;

  /// No description provided for @composeTemplateNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Template name is required'**
  String get composeTemplateNameRequired;

  /// No description provided for @composeTemplateEmpty.
  ///
  /// In en, this message translates to:
  /// **'No templates'**
  String get composeTemplateEmpty;

  /// No description provided for @containerTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get containerTerminal;

  /// No description provided for @composeTemplateDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete template {name}?'**
  String composeTemplateDeleteConfirm(String name);

  /// No description provided for @toolboxClamFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Config Files'**
  String get toolboxClamFilesTitle;

  /// No description provided for @toolboxClamFileContent.
  ///
  /// In en, this message translates to:
  /// **'File Content'**
  String get toolboxClamFileContent;

  /// No description provided for @toolboxClamFileReadonly.
  ///
  /// In en, this message translates to:
  /// **'Log Content (read-only)'**
  String get toolboxClamFileReadonly;

  /// No description provided for @toolboxClamCronExpression.
  ///
  /// In en, this message translates to:
  /// **'Cron expression'**
  String get toolboxClamCronExpression;

  /// No description provided for @toolboxClamInfectedDirectory.
  ///
  /// In en, this message translates to:
  /// **'Infected directory'**
  String get toolboxClamInfectedDirectory;

  /// No description provided for @logsCenterTabWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website Logs'**
  String get logsCenterTabWebsite;

  /// No description provided for @logsWebsiteSelectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Website'**
  String get logsWebsiteSelectorLabel;

  /// No description provided for @databaseUserListTitle.
  ///
  /// In en, this message translates to:
  /// **'Database Users'**
  String get databaseUserListTitle;

  /// No description provided for @databaseUserChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get databaseUserChangePassword;

  /// No description provided for @databaseUserDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete user {name}?'**
  String databaseUserDeleteConfirm(String name);

  /// No description provided for @databaseUserNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get databaseUserNewPasswordLabel;

  /// No description provided for @aiAgentPluginsTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent Plugins'**
  String get aiAgentPluginsTitle;

  /// No description provided for @aiAgentInstalledPlugins.
  ///
  /// In en, this message translates to:
  /// **'Installed Plugins'**
  String get aiAgentInstalledPlugins;

  /// No description provided for @aiAgentPluginMarket.
  ///
  /// In en, this message translates to:
  /// **'Plugin Market'**
  String get aiAgentPluginMarket;

  /// No description provided for @aiAgentPluginSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search market plugins'**
  String get aiAgentPluginSearchHint;

  /// No description provided for @aiAgentPluginMarketEmpty.
  ///
  /// In en, this message translates to:
  /// **'Search the market to find plugins'**
  String get aiAgentPluginMarketEmpty;

  /// No description provided for @aiAgentPluginInstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Install this plugin?'**
  String get aiAgentPluginInstallConfirm;

  /// No description provided for @aiAgentPluginUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get aiAgentPluginUninstall;

  /// No description provided for @aiAgentPluginUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get aiAgentPluginUpgrade;

  /// No description provided for @hostDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime Diagnostics'**
  String get hostDiagnosticsTitle;

  /// No description provided for @hostDiagnosticsSummary.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics Summary'**
  String get hostDiagnosticsSummary;

  /// No description provided for @hostDiagnosticsCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture Profile'**
  String get hostDiagnosticsCaptureTitle;

  /// No description provided for @hostDiagnosticsDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get hostDiagnosticsDuration;

  /// No description provided for @hostDiagnosticsCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get hostDiagnosticsCapture;

  /// No description provided for @hostDiagnosticsGoroutines.
  ///
  /// In en, this message translates to:
  /// **'Goroutine Dump'**
  String get hostDiagnosticsGoroutines;

  /// No description provided for @hostDiagnosticsCaptureDone.
  ///
  /// In en, this message translates to:
  /// **'Profile captured'**
  String get hostDiagnosticsCaptureDone;

  /// No description provided for @toolboxClamFreshStart.
  ///
  /// In en, this message translates to:
  /// **'Freshclam Start'**
  String get toolboxClamFreshStart;

  /// No description provided for @toolboxClamFreshStop.
  ///
  /// In en, this message translates to:
  /// **'Freshclam Stop'**
  String get toolboxClamFreshStop;

  /// No description provided for @toolboxClamFreshRestart.
  ///
  /// In en, this message translates to:
  /// **'Freshclam Restart'**
  String get toolboxClamFreshRestart;

  /// No description provided for @websiteRoutingProxyStatusDelete.
  ///
  /// In en, this message translates to:
  /// **'Proxy Status / Delete'**
  String get websiteRoutingProxyStatusDelete;

  /// No description provided for @databaseSourceAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get databaseSourceAll;

  /// No description provided for @databaseSourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get databaseSourceLocal;

  /// No description provided for @databaseSourceRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get databaseSourceRemote;

  /// No description provided for @databaseFormPgSuperuser.
  ///
  /// In en, this message translates to:
  /// **'PostgreSQL Superuser'**
  String get databaseFormPgSuperuser;

  /// No description provided for @filePreviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load file'**
  String get filePreviewLoadFailed;

  /// No description provided for @filePreviewSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save file'**
  String get filePreviewSaveFailed;

  /// No description provided for @filePreviewLoadSuccess.
  ///
  /// In en, this message translates to:
  /// **'File loaded'**
  String get filePreviewLoadSuccess;

  /// No description provided for @dashboardRefreshInterval.
  ///
  /// In en, this message translates to:
  /// **'Refresh interval'**
  String get dashboardRefreshInterval;

  /// No description provided for @dashboardInterval3s.
  ///
  /// In en, this message translates to:
  /// **'3 seconds'**
  String get dashboardInterval3s;

  /// No description provided for @dashboardInterval5s.
  ///
  /// In en, this message translates to:
  /// **'5 seconds (default)'**
  String get dashboardInterval5s;

  /// No description provided for @dashboardInterval10s.
  ///
  /// In en, this message translates to:
  /// **'10 seconds'**
  String get dashboardInterval10s;

  /// No description provided for @dashboardInterval30s.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get dashboardInterval30s;

  /// No description provided for @dashboardInterval1m.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get dashboardInterval1m;

  /// No description provided for @filePreviewLoadImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get filePreviewLoadImageFailed;

  /// No description provided for @filePreviewLoadPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load PDF'**
  String get filePreviewLoadPdfFailed;

  /// No description provided for @filePreviewVideoNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Video player not initialized'**
  String get filePreviewVideoNotInitialized;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsSystemBackdrop.
  ///
  /// In en, this message translates to:
  /// **'System backdrop'**
  String get settingsSystemBackdrop;

  /// No description provided for @settingsRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Restart required'**
  String get settingsRestartRequired;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @hostServersRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh servers.'**
  String get hostServersRefreshFailed;

  /// No description provided for @hostServersActions.
  ///
  /// In en, this message translates to:
  /// **'Server actions'**
  String get hostServersActions;

  /// No description provided for @hostServersSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get hostServersSwitch;

  /// No description provided for @hostServersDeleteCurrentBlocked.
  ///
  /// In en, this message translates to:
  /// **'The current server cannot be deleted. Switch to another server first.'**
  String get hostServersDeleteCurrentBlocked;

  /// No description provided for @hostServersNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'My server'**
  String get hostServersNamePlaceholder;

  /// No description provided for @hostServersUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required.'**
  String get hostServersUrlRequired;

  /// No description provided for @hostServersUrlHttpRequired.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://.'**
  String get hostServersUrlHttpRequired;

  /// No description provided for @hostServersApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API key is required.'**
  String get hostServersApiKeyRequired;

  /// No description provided for @hostFilesPathPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a path and press Enter'**
  String get hostFilesPathPlaceholder;

  /// No description provided for @hostFilesFolderNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get hostFilesFolderNamePlaceholder;

  /// No description provided for @hostFilesFolderNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder name cannot be empty.'**
  String get hostFilesFolderNameEmpty;

  /// No description provided for @hostContainersRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh containers.'**
  String get hostContainersRefreshFailed;

  /// No description provided for @hostContainersStopContainer.
  ///
  /// In en, this message translates to:
  /// **'Stop container'**
  String get hostContainersStopContainer;

  /// No description provided for @hostContainersStartContainer.
  ///
  /// In en, this message translates to:
  /// **'Start container'**
  String get hostContainersStartContainer;

  /// No description provided for @hostContainersRestartContainer.
  ///
  /// In en, this message translates to:
  /// **'Restart container'**
  String get hostContainersRestartContainer;

  /// No description provided for @hostContainersDeleteContainer.
  ///
  /// In en, this message translates to:
  /// **'Delete container'**
  String get hostContainersDeleteContainer;

  /// No description provided for @hostContainersDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Container'**
  String get hostContainersDeleteConfirm;

  /// No description provided for @hostAppsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh apps.'**
  String get hostAppsRefreshFailed;

  /// No description provided for @hostAppsInstallOpenresty.
  ///
  /// In en, this message translates to:
  /// **'Install OpenResty'**
  String get hostAppsInstallOpenresty;

  /// No description provided for @hostAppsStopApp.
  ///
  /// In en, this message translates to:
  /// **'Stop app'**
  String get hostAppsStopApp;

  /// No description provided for @hostAppsStartApp.
  ///
  /// In en, this message translates to:
  /// **'Start app'**
  String get hostAppsStartApp;

  /// No description provided for @hostAppsUninstallApp.
  ///
  /// In en, this message translates to:
  /// **'Uninstall app'**
  String get hostAppsUninstallApp;

  /// No description provided for @hostAppsUninstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Uninstall App'**
  String get hostAppsUninstallConfirm;

  /// No description provided for @hostAppsOpenrestyInstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'OpenResty will be downloaded and installed from the app store. This may take a few minutes. Continue?'**
  String get hostAppsOpenrestyInstallConfirm;

  /// No description provided for @hostAppsOpenrestyInstallSubmitted.
  ///
  /// In en, this message translates to:
  /// **'OpenResty install task submitted.'**
  String get hostAppsOpenrestyInstallSubmitted;

  /// No description provided for @hostWebsitesRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh websites.'**
  String get hostWebsitesRefreshFailed;

  /// No description provided for @hostWebsitesStopWebsite.
  ///
  /// In en, this message translates to:
  /// **'Stop website'**
  String get hostWebsitesStopWebsite;

  /// No description provided for @hostWebsitesStartWebsite.
  ///
  /// In en, this message translates to:
  /// **'Start website'**
  String get hostWebsitesStartWebsite;

  /// No description provided for @hostWebsitesPrimaryDomainHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. example.com'**
  String get hostWebsitesPrimaryDomainHint;

  /// No description provided for @hostWebsitesAliasHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-derived from domain if empty'**
  String get hostWebsitesAliasHint;

  /// No description provided for @hostWebsitesAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add website.'**
  String get hostWebsitesAddFailed;

  /// No description provided for @hostCommonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get hostCommonOptional;

  /// No description provided for @hostCommonPortNumeric.
  ///
  /// In en, this message translates to:
  /// **'Port must be a number.'**
  String get hostCommonPortNumeric;

  /// No description provided for @hostOpenrestyRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh the OpenResty snapshot.'**
  String get hostOpenrestyRefreshFailed;

  /// No description provided for @hostOpenrestyConfigEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'# The OpenResty configuration source is empty or unavailable (/etc/nginx/nginx.conf)'**
  String get hostOpenrestyConfigEmptyHint;

  /// No description provided for @hostOpenrestyConfigSource.
  ///
  /// In en, this message translates to:
  /// **'Configuration source (/etc/nginx/nginx.conf)'**
  String get hostOpenrestyConfigSource;

  /// No description provided for @hostOpenrestySaveConfig.
  ///
  /// In en, this message translates to:
  /// **'Save OpenResty configuration'**
  String get hostOpenrestySaveConfig;

  /// No description provided for @hostOpenrestySaveConfigConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite /etc/nginx/nginx.conf with the edited content.\nAn invalid configuration may make hosted websites unavailable. Continue?'**
  String get hostOpenrestySaveConfigConfirm;

  /// No description provided for @hostOpenrestySaveConfigFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the OpenResty configuration.'**
  String get hostOpenrestySaveConfigFailed;

  /// No description provided for @hostDatabaseCreate.
  ///
  /// In en, this message translates to:
  /// **'Create database'**
  String get hostDatabaseCreate;

  /// No description provided for @hostDatabaseRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh databases.'**
  String get hostDatabaseRefreshFailed;

  /// No description provided for @hostDatabaseActions.
  ///
  /// In en, this message translates to:
  /// **'Database actions'**
  String get hostDatabaseActions;

  /// No description provided for @hostDatabasePasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get hostDatabasePasswordRequired;

  /// No description provided for @hostDatabaseDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Database'**
  String get hostDatabaseDeleteTitle;

  /// No description provided for @hostDatabaseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. app_db'**
  String get hostDatabaseNameHint;

  /// No description provided for @hostDatabaseAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.1.10'**
  String get hostDatabaseAddressHint;

  /// No description provided for @hostDatabasePortHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3306'**
  String get hostDatabasePortHint;

  /// No description provided for @hostDatabaseCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create database.'**
  String get hostDatabaseCreateFailed;

  /// No description provided for @hostDatabaseCreateRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Create failed. Adjust the inputs and try again.'**
  String get hostDatabaseCreateRetryHint;

  /// No description provided for @hostDatabaseRemoteAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required for remote databases.'**
  String get hostDatabaseRemoteAddressRequired;

  /// No description provided for @hostDatabaseRemotePortRequired.
  ///
  /// In en, this message translates to:
  /// **'Port is required for remote databases.'**
  String get hostDatabaseRemotePortRequired;

  /// No description provided for @hostDatabaseRemoteUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required for remote databases.'**
  String get hostDatabaseRemoteUsernameRequired;

  /// No description provided for @hostDatabaseRemotePasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required for remote databases.'**
  String get hostDatabaseRemotePasswordRequired;

  /// No description provided for @hostOrchestrationRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh composes.'**
  String get hostOrchestrationRefreshFailed;

  /// No description provided for @hostOrchestrationActions.
  ///
  /// In en, this message translates to:
  /// **'Compose actions'**
  String get hostOrchestrationActions;

  /// No description provided for @hostOrchestrationUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get hostOrchestrationUp;

  /// No description provided for @hostOrchestrationDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get hostOrchestrationDown;

  /// No description provided for @hostOrchestrationDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Down Compose'**
  String get hostOrchestrationDownTitle;

  /// No description provided for @hostOrchestrationNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. my-app'**
  String get hostOrchestrationNamePlaceholder;

  /// No description provided for @hostOrchestrationCreateFrom.
  ///
  /// In en, this message translates to:
  /// **'Create from'**
  String get hostOrchestrationCreateFrom;

  /// No description provided for @hostOrchestrationFromPath.
  ///
  /// In en, this message translates to:
  /// **'From path'**
  String get hostOrchestrationFromPath;

  /// No description provided for @hostOrchestrationFromContent.
  ///
  /// In en, this message translates to:
  /// **'From content'**
  String get hostOrchestrationFromContent;

  /// No description provided for @hostOrchestrationFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From template'**
  String get hostOrchestrationFromTemplate;

  /// No description provided for @hostOrchestrationComposeFilePath.
  ///
  /// In en, this message translates to:
  /// **'Compose file path'**
  String get hostOrchestrationComposeFilePath;

  /// No description provided for @hostOrchestrationPathPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. /opt/1panel/docker/compose/my-app/docker-compose.yml'**
  String get hostOrchestrationPathPlaceholder;

  /// No description provided for @hostOrchestrationNewComposeContent.
  ///
  /// In en, this message translates to:
  /// **'New compose content (YAML)'**
  String get hostOrchestrationNewComposeContent;

  /// No description provided for @hostOrchestrationFullReplacementHint.
  ///
  /// In en, this message translates to:
  /// **'Full replacement: paste the complete new config; empty content will be rejected'**
  String get hostOrchestrationFullReplacementHint;

  /// No description provided for @hostOrchestrationTemplateId.
  ///
  /// In en, this message translates to:
  /// **'Template ID'**
  String get hostOrchestrationTemplateId;

  /// No description provided for @hostOrchestrationTemplateIdPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1'**
  String get hostOrchestrationTemplateIdPlaceholder;

  /// No description provided for @hostOrchestrationCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create compose.'**
  String get hostOrchestrationCreateFailed;

  /// No description provided for @hostOrchestrationContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Compose content is required.'**
  String get hostOrchestrationContentRequired;

  /// No description provided for @hostOrchestrationEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Compose'**
  String get hostOrchestrationEditTitle;

  /// No description provided for @hostOrchestrationReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get hostOrchestrationReplace;

  /// No description provided for @hostOrchestrationSaveFailedReopen.
  ///
  /// In en, this message translates to:
  /// **'Save failed. The editor reopens with your content; try again.'**
  String get hostOrchestrationSaveFailedReopen;

  /// No description provided for @hostOrchestrationPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Compose file path is required.'**
  String get hostOrchestrationPathRequired;

  /// No description provided for @hostOrchestrationTemplateIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Template ID is required.'**
  String get hostOrchestrationTemplateIdRequired;

  /// No description provided for @hostOrchestrationTemplateIdInteger.
  ///
  /// In en, this message translates to:
  /// **'Template ID must be an integer.'**
  String get hostOrchestrationTemplateIdInteger;

  /// No description provided for @hostCommonCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Create failed. Adjust the inputs and try again.'**
  String get hostCommonCreateFailed;

  /// No description provided for @hostCommonSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed. Adjust the inputs and try again.'**
  String get hostCommonSaveFailed;

  /// No description provided for @hostCronJobsCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get hostCronJobsCreateTask;

  /// No description provided for @hostCronJobsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh cron jobs.'**
  String get hostCronJobsRefreshFailed;

  /// No description provided for @hostCronJobsLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last run'**
  String get hostCronJobsLastRun;

  /// No description provided for @hostCronJobsTaskActions.
  ///
  /// In en, this message translates to:
  /// **'Task actions'**
  String get hostCronJobsTaskActions;

  /// No description provided for @hostCronJobsDeleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get hostCronJobsDeleteTaskTitle;

  /// No description provided for @hostCronJobsNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cleanup logs'**
  String get hostCronJobsNamePlaceholder;

  /// No description provided for @hostCronJobsScriptReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Optional; submitting replaces the stored script'**
  String get hostCronJobsScriptReplaceHint;

  /// No description provided for @hostCronJobsScriptPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Optional shell script'**
  String get hostCronJobsScriptPlaceholder;

  /// No description provided for @hostCronJobsEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get hostCronJobsEditTask;

  /// No description provided for @hostCronJobsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the task.'**
  String get hostCronJobsSaveFailed;

  /// No description provided for @hostCronJobsCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the task.'**
  String get hostCronJobsCreateFailed;

  /// No description provided for @hostBackupsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh backup records.'**
  String get hostBackupsRefreshFailed;

  /// No description provided for @hostBackupsActions.
  ///
  /// In en, this message translates to:
  /// **'Backup actions'**
  String get hostBackupsActions;

  /// No description provided for @hostBackupsRestoreUnavailableFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore is unavailable for failed backup records.'**
  String get hostBackupsRestoreUnavailableFailed;

  /// No description provided for @hostBackupsRestoreUnavailableSize.
  ///
  /// In en, this message translates to:
  /// **'Restore is unavailable while the file size is unknown.'**
  String get hostBackupsRestoreUnavailableSize;

  /// No description provided for @hostBackupsDeleteUnavailableWaiting.
  ///
  /// In en, this message translates to:
  /// **'Delete is unavailable while the backup is still waiting.'**
  String get hostBackupsDeleteUnavailableWaiting;

  /// No description provided for @hostBackupsRestoreOverwriteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite the current data and cannot be undone.'**
  String get hostBackupsRestoreOverwriteWarning;

  /// No description provided for @hostBackupsDeleteRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup Record'**
  String get hostBackupsDeleteRecordTitle;

  /// No description provided for @hostHostSshTitle.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get hostHostSshTitle;

  /// No description provided for @hostHostSshRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh the SSH information.'**
  String get hostHostSshRefreshFailed;

  /// No description provided for @hostHostSshNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'SSH service is not installed on this server.'**
  String get hostHostSshNotInstalled;

  /// No description provided for @hostHostSshConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the configuration file.'**
  String get hostHostSshConfigLoadFailed;

  /// No description provided for @hostHostSshConfigEmptyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'# The SSH configuration file does not exist or is empty (/etc/ssh/sshd_config)'**
  String get hostHostSshConfigEmptyPlaceholder;

  /// No description provided for @hostHostSshConfigFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration file (/etc/ssh/sshd_config)'**
  String get hostHostSshConfigFileTitle;

  /// No description provided for @hostHostSshSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save SSH configuration'**
  String get hostHostSshSaveTitle;

  /// No description provided for @hostHostSshSaveMessage.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite /etc/ssh/sshd_config with the edited content.\nAn invalid configuration may make the SSH service unavailable. Continue?'**
  String get hostHostSshSaveMessage;

  /// No description provided for @hostHostSshSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the SSH configuration.'**
  String get hostHostSshSaveFailed;

  /// No description provided for @hostToolboxSnapshotRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh device snapshot.'**
  String get hostToolboxSnapshotRefreshFailed;

  /// No description provided for @hostToolboxKernelLabel.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get hostToolboxKernelLabel;

  /// No description provided for @hostToolboxProductLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get hostToolboxProductLabel;

  /// No description provided for @hostToolboxTimeZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Zone'**
  String get hostToolboxTimeZoneLabel;

  /// No description provided for @hostToolboxNtpServerLabel.
  ///
  /// In en, this message translates to:
  /// **'NTP Server'**
  String get hostToolboxNtpServerLabel;

  /// No description provided for @hostToolboxSwapOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get hostToolboxSwapOff;

  /// No description provided for @hostToolboxSwapOffHint.
  ///
  /// In en, this message translates to:
  /// **'Swap is disabled on this host.'**
  String get hostToolboxSwapOffHint;

  /// No description provided for @hostToolboxSwapTotalHint.
  ///
  /// In en, this message translates to:
  /// **'Total swap size.'**
  String get hostToolboxSwapTotalHint;

  /// No description provided for @hostToolboxDnsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8.8.8.8'**
  String get hostToolboxDnsPlaceholder;

  /// No description provided for @hostToolboxDnsVerifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get hostToolboxDnsVerifyAction;

  /// No description provided for @hostToolboxDnsReachable.
  ///
  /// In en, this message translates to:
  /// **'DNS reachable'**
  String get hostToolboxDnsReachable;

  /// No description provided for @hostToolboxDnsEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Enter a DNS server to verify.'**
  String get hostToolboxDnsEmptyError;

  /// No description provided for @hostToolboxUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get hostToolboxUsersTitle;

  /// No description provided for @hostAiModelsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh AI models.'**
  String get hostAiModelsRefreshFailed;

  /// No description provided for @hostAiModelUnknownName.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get hostAiModelUnknownName;

  /// No description provided for @hostAiConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get hostAiConnectionTitle;

  /// No description provided for @hostAiOllamaNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Ollama not detected on this server.'**
  String get hostAiOllamaNotDetected;

  /// No description provided for @hostAiDomainBoundHint.
  ///
  /// In en, this message translates to:
  /// **'Domain bound. Refresh to see connection details.'**
  String get hostAiDomainBoundHint;

  /// No description provided for @hostAiIpAllowlistLabel.
  ///
  /// In en, this message translates to:
  /// **'IP allowlist (optional, comma-separated)'**
  String get hostAiIpAllowlistLabel;

  /// No description provided for @hostAiBindDomainFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to bind domain.'**
  String get hostAiBindDomainFailed;

  /// No description provided for @hostAiBindFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Bind failed. Adjust the input and try again.'**
  String get hostAiBindFailedRetry;

  /// No description provided for @hostAiModelActions.
  ///
  /// In en, this message translates to:
  /// **'Model actions'**
  String get hostAiModelActions;

  /// No description provided for @hostAiModelRecreateAction.
  ///
  /// In en, this message translates to:
  /// **'Recreate'**
  String get hostAiModelRecreateAction;

  /// No description provided for @hostAiModelDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete AI Model'**
  String get hostAiModelDeleteTitle;

  /// No description provided for @hostAiModelCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create model.'**
  String get hostAiModelCreateFailed;

  /// No description provided for @hostAiCreateFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Create failed. Adjust the input and try again.'**
  String get hostAiCreateFailedRetry;

  /// No description provided for @hostCommandsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh commands.'**
  String get hostCommandsRefreshFailed;

  /// No description provided for @hostCommandsRowActions.
  ///
  /// In en, this message translates to:
  /// **'Command actions'**
  String get hostCommandsRowActions;

  /// No description provided for @hostCommandsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Command'**
  String get hostCommandsDeleteTitle;

  /// No description provided for @hostCommandsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cleanup logs'**
  String get hostCommandsNameHint;

  /// No description provided for @hostCommandsCommandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. docker ps -a'**
  String get hostCommandsCommandHint;

  /// No description provided for @hostCommandsDefaultGroup.
  ///
  /// In en, this message translates to:
  /// **'Default group'**
  String get hostCommandsDefaultGroup;

  /// No description provided for @hostCommandsCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the command.'**
  String get hostCommandsCreateFailed;

  /// No description provided for @hostCommandsCreateFormError.
  ///
  /// In en, this message translates to:
  /// **'Create failed. Adjust the inputs and try again.'**
  String get hostCommandsCreateFormError;

  /// No description provided for @hostCommandsCommandRequired.
  ///
  /// In en, this message translates to:
  /// **'Command is required.'**
  String get hostCommandsCommandRequired;

  /// No description provided for @hostScriptLibraryRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh scripts.'**
  String get hostScriptLibraryRefreshFailed;

  /// No description provided for @hostScriptLibraryDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get hostScriptLibraryDeleteSelected;

  /// No description provided for @hostScriptLibraryRowActions.
  ///
  /// In en, this message translates to:
  /// **'Script actions'**
  String get hostScriptLibraryRowActions;

  /// No description provided for @hostScriptLibraryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Script'**
  String get hostScriptLibraryDeleteTitle;

  /// No description provided for @hostScriptLibraryDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Scripts'**
  String get hostScriptLibraryDeleteSelectedTitle;

  /// No description provided for @hostLogsRefreshOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh operation logs.'**
  String get hostLogsRefreshOperationFailed;

  /// No description provided for @hostLogsRefreshLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh login logs.'**
  String get hostLogsRefreshLoginFailed;

  /// No description provided for @hostLogsFileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'File name is required.'**
  String get hostLogsFileNameRequired;

  /// No description provided for @hostLogsRefreshTab.
  ///
  /// In en, this message translates to:
  /// **'Refresh current tab'**
  String get hostLogsRefreshTab;

  /// No description provided for @hostLogsFileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get hostLogsFileNameLabel;

  /// No description provided for @hostLogsCoreToggle.
  ///
  /// In en, this message translates to:
  /// **'Core logs'**
  String get hostLogsCoreToggle;

  /// No description provided for @hostLogsSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a log file name and click Load to view its content.'**
  String get hostLogsSystemHint;

  /// No description provided for @hostSecurityRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh firewall rules.'**
  String get hostSecurityRefreshFailed;

  /// No description provided for @hostSecurityAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get hostSecurityAddRule;

  /// No description provided for @hostSecurityDeleteRule.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get hostSecurityDeleteRule;

  /// No description provided for @hostSecurityPortHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8080'**
  String get hostSecurityPortHint;

  /// No description provided for @hostSecurityAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for all addresses'**
  String get hostSecurityAddressHint;

  /// No description provided for @hostSecurityAddRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Rule'**
  String get hostSecurityAddRuleTitle;

  /// No description provided for @hostSecurityPortNumeric.
  ///
  /// In en, this message translates to:
  /// **'Port must be a number.'**
  String get hostSecurityPortNumeric;

  /// No description provided for @hostSecurityDeleteRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Rule'**
  String get hostSecurityDeleteRuleTitle;

  /// No description provided for @hostGatewayRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh the security gateway snapshot.'**
  String get hostGatewayRefreshFailed;

  /// No description provided for @hostGatewayOpenrestyStatus.
  ///
  /// In en, this message translates to:
  /// **'OpenResty Status'**
  String get hostGatewayOpenrestyStatus;

  /// No description provided for @hostGatewayHttpsRedirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Default HTTPS redirect'**
  String get hostGatewayHttpsRedirectTitle;

  /// No description provided for @hostGatewayHttpsRedirectDescription.
  ///
  /// In en, this message translates to:
  /// **'Redirect HTTP to HTTPS for all websites'**
  String get hostGatewayHttpsRedirectDescription;

  /// No description provided for @hostGatewayStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Current state unknown'**
  String get hostGatewayStateUnknown;

  /// No description provided for @hostGatewayDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get hostGatewayDisable;

  /// No description provided for @hostGatewayHttpsRedirectEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Default HTTPS Redirect'**
  String get hostGatewayHttpsRedirectEnableTitle;

  /// No description provided for @hostGatewayHttpsRedirectDisableTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable Default HTTPS Redirect'**
  String get hostGatewayHttpsRedirectDisableTitle;

  /// No description provided for @hostGatewayHttpsRedirectEnableMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable HTTP→HTTPS redirect for all websites?'**
  String get hostGatewayHttpsRedirectEnableMessage;

  /// No description provided for @hostGatewayHttpsRedirectDisableMessage.
  ///
  /// In en, this message translates to:
  /// **'Disable HTTP→HTTPS redirect?'**
  String get hostGatewayHttpsRedirectDisableMessage;

  /// No description provided for @hostGatewayHttpsRedirectEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable the default HTTPS redirect.'**
  String get hostGatewayHttpsRedirectEnableFailed;

  /// No description provided for @hostGatewayHttpsRedirectDisableFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to disable the default HTTPS redirect.'**
  String get hostGatewayHttpsRedirectDisableFailed;

  /// No description provided for @hostGatewayCertificatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste the full PEM certificate chain'**
  String get hostGatewayCertificatePlaceholder;

  /// No description provided for @hostGatewayPrivateKeyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste the matching PEM private key'**
  String get hostGatewayPrivateKeyPlaceholder;

  /// No description provided for @hostGatewayDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get hostGatewayDescriptionOptional;

  /// No description provided for @hostGatewayDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. *.example.com issued 2026-09'**
  String get hostGatewayDescriptionPlaceholder;

  /// No description provided for @hostGatewayCertificateRequired.
  ///
  /// In en, this message translates to:
  /// **'Certificate is required.'**
  String get hostGatewayCertificateRequired;

  /// No description provided for @hostGatewayUploadConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The certificate will be imported into the panel and becomes available to websites. Continue?'**
  String get hostGatewayUploadConfirmMessage;

  /// No description provided for @hostGatewayUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload the certificate.'**
  String get hostGatewayUploadFailed;

  /// No description provided for @hostGatewayUploadFormError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. The form reopens with your content; try again.'**
  String get hostGatewayUploadFormError;

  /// No description provided for @hostGatewayRenewNoId.
  ///
  /// In en, this message translates to:
  /// **'This certificate has no id and cannot be renewed.'**
  String get hostGatewayRenewNoId;

  /// No description provided for @hostGatewayRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get hostGatewayRenew;

  /// No description provided for @hostGatewayRenewalRequested.
  ///
  /// In en, this message translates to:
  /// **'Renewal requested.'**
  String get hostGatewayRenewalRequested;

  /// No description provided for @hostGatewayExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get hostGatewayExpiresToday;

  /// No description provided for @hostGatewayValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get hostGatewayValid;

  /// No description provided for @hostDashboardRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh dashboard.'**
  String get hostDashboardRefreshFailed;

  /// No description provided for @hostDashboardKernelLabel.
  ///
  /// In en, this message translates to:
  /// **'Kernel'**
  String get hostDashboardKernelLabel;

  /// No description provided for @hostDashboardCpuCoresLabel.
  ///
  /// In en, this message translates to:
  /// **'CPU Cores'**
  String get hostDashboardCpuCoresLabel;

  /// No description provided for @hostDashboardPanelVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Panel Version'**
  String get hostDashboardPanelVersionLabel;

  /// No description provided for @hostMonitoringRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh monitoring data.'**
  String get hostMonitoringRefreshFailed;

  /// No description provided for @hostMonitoringLoadAverage.
  ///
  /// In en, this message translates to:
  /// **'Load Average'**
  String get hostMonitoringLoadAverage;

  /// No description provided for @hostMonitoringLoad1.
  ///
  /// In en, this message translates to:
  /// **'Load 1'**
  String get hostMonitoringLoad1;

  /// No description provided for @hostMonitoringLoad5.
  ///
  /// In en, this message translates to:
  /// **'Load 5'**
  String get hostMonitoringLoad5;

  /// No description provided for @hostMonitoringLoad15.
  ///
  /// In en, this message translates to:
  /// **'Load 15'**
  String get hostMonitoringLoad15;

  /// No description provided for @hostMonitoringLoadWindows.
  ///
  /// In en, this message translates to:
  /// **'1/5/15 min'**
  String get hostMonitoringLoadWindows;

  /// No description provided for @hostAuthDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this basic authentication user? This cannot be undone.'**
  String get hostAuthDeleteConfirm;

  /// No description provided for @hostAuthDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the basic authentication user.'**
  String get hostAuthDeleteFailed;

  /// No description provided for @hostAuthDisableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disable basic authentication for this website?'**
  String get hostAuthDisableConfirm;

  /// No description provided for @hostAuthEditHelper.
  ///
  /// In en, this message translates to:
  /// **'The password cannot be echoed. Editing resets the password.'**
  String get hostAuthEditHelper;

  /// No description provided for @hostAuthEnableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enable basic authentication for \'{0}\'?'**
  String get hostAuthEnableConfirm;

  /// No description provided for @hostAuthEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the basic authentication switch.'**
  String get hostAuthEnableFailed;

  /// No description provided for @hostAuthEnableSwitch.
  ///
  /// In en, this message translates to:
  /// **'Enable basic authentication'**
  String get hostAuthEnableSwitch;

  /// No description provided for @hostAuthLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the basic authentication configuration.'**
  String get hostAuthLoadFailed;

  /// No description provided for @hostAuthNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get hostAuthNameRequired;

  /// No description provided for @hostAuthPasswordInvalid.
  ///
  /// In en, this message translates to:
  /// **'Password may only contain letters, digits and _-.@\$!%*?& (max 72 characters).'**
  String get hostAuthPasswordInvalid;

  /// No description provided for @hostAuthPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get hostAuthPasswordRequired;

  /// No description provided for @hostAuthPathDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete path authentication rule \'{0}\'? This cannot be undone.'**
  String get hostAuthPathDeleteConfirm;

  /// No description provided for @hostAuthPathEmpty.
  ///
  /// In en, this message translates to:
  /// **'No path authentication rules'**
  String get hostAuthPathEmpty;

  /// No description provided for @hostAuthPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Path is required.'**
  String get hostAuthPathRequired;

  /// No description provided for @hostAuthRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get hostAuthRandom;

  /// No description provided for @hostAuthRemark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get hostAuthRemark;

  /// No description provided for @hostAuthSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the basic authentication.'**
  String get hostAuthSaveFailed;

  /// No description provided for @hostAuthSaved.
  ///
  /// In en, this message translates to:
  /// **'Basic authentication updated.'**
  String get hostAuthSaved;

  /// No description provided for @hostAuthScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get hostAuthScopeGlobal;

  /// No description provided for @hostAuthUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required.'**
  String get hostAuthUsernameRequired;

  /// No description provided for @hostCorsAllowCredentials.
  ///
  /// In en, this message translates to:
  /// **'Allow cookies to be sent'**
  String get hostCorsAllowCredentials;

  /// No description provided for @hostCorsAllowHeaders.
  ///
  /// In en, this message translates to:
  /// **'Allowed request headers'**
  String get hostCorsAllowHeaders;

  /// No description provided for @hostCorsAllowMethods.
  ///
  /// In en, this message translates to:
  /// **'Allowed request methods'**
  String get hostCorsAllowMethods;

  /// No description provided for @hostCorsAllowOrigins.
  ///
  /// In en, this message translates to:
  /// **'Allowed domains'**
  String get hostCorsAllowOrigins;

  /// No description provided for @hostCorsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable CORS'**
  String get hostCorsEnable;

  /// No description provided for @hostCorsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the CORS configuration.'**
  String get hostCorsLoadFailed;

  /// No description provided for @hostCorsOriginsRequired.
  ///
  /// In en, this message translates to:
  /// **'Allowed domains is required when CORS is enabled.'**
  String get hostCorsOriginsRequired;

  /// No description provided for @hostCorsPreflight.
  ///
  /// In en, this message translates to:
  /// **'Preflight request fast response'**
  String get hostCorsPreflight;

  /// No description provided for @hostCorsPreflightHelper.
  ///
  /// In en, this message translates to:
  /// **'Answers cross-origin OPTIONS preflight requests automatically with 204 and the CORS headers'**
  String get hostCorsPreflightHelper;

  /// No description provided for @hostCorsSaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save the CORS configuration for \'{0}\'?'**
  String get hostCorsSaveConfirm;

  /// No description provided for @hostCorsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the CORS configuration.'**
  String get hostCorsSaveFailed;

  /// No description provided for @hostCorsSaved.
  ///
  /// In en, this message translates to:
  /// **'CORS configuration saved.'**
  String get hostCorsSaved;

  /// No description provided for @hostDomainsActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get hostDomainsActionsLabel;

  /// No description provided for @hostDomainsAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add domains.'**
  String get hostDomainsAddFailed;

  /// No description provided for @hostDomainsAddSuccess.
  ///
  /// In en, this message translates to:
  /// **'Domains added.'**
  String get hostDomainsAddSuccess;

  /// No description provided for @hostDomainsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete domain \'{0}\'? This action cannot be undone.'**
  String get hostDomainsDeleteConfirm;

  /// No description provided for @hostDomainsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete domain.'**
  String get hostDomainsDeleteFailed;

  /// No description provided for @hostDomainsDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Domain deleted.'**
  String get hostDomainsDeleteSuccess;

  /// No description provided for @hostDomainsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete domain'**
  String get hostDomainsDeleteTitle;

  /// No description provided for @hostDomainsInputHint.
  ///
  /// In en, this message translates to:
  /// **'One domain per line. All entries share the port and SSL option below.'**
  String get hostDomainsInputHint;

  /// No description provided for @hostDomainsInputRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one domain.'**
  String get hostDomainsInputRequired;

  /// No description provided for @hostDomainsLastDeleteDisabled.
  ///
  /// In en, this message translates to:
  /// **'At least one domain must remain.'**
  String get hostDomainsLastDeleteDisabled;

  /// No description provided for @hostDomainsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load domains.'**
  String get hostDomainsLoadFailed;

  /// No description provided for @hostHttpsAlgorithmLabel.
  ///
  /// In en, this message translates to:
  /// **'Encryption algorithm'**
  String get hostHttpsAlgorithmLabel;

  /// No description provided for @hostHttpsAlgorithmRequired.
  ///
  /// In en, this message translates to:
  /// **'Encryption algorithm is required.'**
  String get hostHttpsAlgorithmRequired;

  /// No description provided for @hostHttpsCertEmpty.
  ///
  /// In en, this message translates to:
  /// **'No certificates available. Import one from the SSL certificate page first.'**
  String get hostHttpsCertEmpty;

  /// No description provided for @hostHttpsCertLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load certificates.'**
  String get hostHttpsCertLoadFailed;

  /// No description provided for @hostHttpsCertRequired.
  ///
  /// In en, this message translates to:
  /// **'Certificate and private key are required.'**
  String get hostHttpsCertRequired;

  /// No description provided for @hostHttpsCertSelectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select certificate'**
  String get hostHttpsCertSelectPlaceholder;

  /// No description provided for @hostHttpsCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get hostHttpsCertificateLabel;

  /// No description provided for @hostHttpsDisableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disabling HTTPS will delete the certificate related configuration. Continue?'**
  String get hostHttpsDisableConfirm;

  /// No description provided for @hostHttpsDisableTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable HTTPS'**
  String get hostHttpsDisableTitle;

  /// No description provided for @hostHttpsHelper.
  ///
  /// In en, this message translates to:
  /// **'Note: Do not use SSL certificates for illegal websites.\nIf HTTPS access cannot be used after enabling, check whether the firewall has released port 443.'**
  String get hostHttpsHelper;

  /// No description provided for @hostHttpsHstsHelper.
  ///
  /// In en, this message translates to:
  /// **'Enabling HSTS can increase website security'**
  String get hostHttpsHstsHelper;

  /// No description provided for @hostHttpsHstsSubDomainsLabel.
  ///
  /// In en, this message translates to:
  /// **'HSTS include subdomains'**
  String get hostHttpsHstsSubDomainsLabel;

  /// No description provided for @hostHttpsHttp3Helper.
  ///
  /// In en, this message translates to:
  /// **'HTTP/3 offers faster connections, but not all browsers support it; enabling it may make the site unreachable for some browsers.'**
  String get hostHttpsHttp3Helper;

  /// No description provided for @hostHttpsHttp3Label.
  ///
  /// In en, this message translates to:
  /// **'HTTP3'**
  String get hostHttpsHttp3Label;

  /// No description provided for @hostHttpsHttpConfigAlso.
  ///
  /// In en, this message translates to:
  /// **'Allow direct HTTP requests'**
  String get hostHttpsHttpConfigAlso;

  /// No description provided for @hostHttpsHttpConfigLabel.
  ///
  /// In en, this message translates to:
  /// **'HTTP options'**
  String get hostHttpsHttpConfigLabel;

  /// No description provided for @hostHttpsHttpConfigOnly.
  ///
  /// In en, this message translates to:
  /// **'Block HTTP requests'**
  String get hostHttpsHttpConfigOnly;

  /// No description provided for @hostHttpsHttpConfigToHttps.
  ///
  /// In en, this message translates to:
  /// **'Redirect to HTTPS'**
  String get hostHttpsHttpConfigToHttps;

  /// No description provided for @hostHttpsInsecureSuffix.
  ///
  /// In en, this message translates to:
  /// **'(not safe)'**
  String get hostHttpsInsecureSuffix;

  /// No description provided for @hostHttpsIpWarn.
  ///
  /// In en, this message translates to:
  /// **'Websites with IP as domain names need to be set as default site to be accessed normally.'**
  String get hostHttpsIpWarn;

  /// No description provided for @hostHttpsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load HTTPS configuration.'**
  String get hostHttpsLoadFailed;

  /// No description provided for @hostHttpsPortLabel.
  ///
  /// In en, this message translates to:
  /// **'HTTPS port'**
  String get hostHttpsPortLabel;

  /// No description provided for @hostHttpsPrivateKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get hostHttpsPrivateKeyLabel;

  /// No description provided for @hostHttpsProtocolLabel.
  ///
  /// In en, this message translates to:
  /// **'Protocol version'**
  String get hostHttpsProtocolLabel;

  /// No description provided for @hostHttpsProtocolRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one TLS protocol version.'**
  String get hostHttpsProtocolRequired;

  /// No description provided for @hostHttpsSaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Apply the HTTPS configuration to \'{0}\'?'**
  String get hostHttpsSaveConfirm;

  /// No description provided for @hostHttpsSaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Save HTTPS settings'**
  String get hostHttpsSaveConfirmTitle;

  /// No description provided for @hostHttpsSectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Protocol settings'**
  String get hostHttpsSectionAdvanced;

  /// No description provided for @hostHttpsSectionBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get hostHttpsSectionBasic;

  /// No description provided for @hostHttpsSectionCert.
  ///
  /// In en, this message translates to:
  /// **'Certificate settings'**
  String get hostHttpsSectionCert;

  /// No description provided for @hostHttpsSelectCertRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a certificate.'**
  String get hostHttpsSelectCertRequired;

  /// No description provided for @hostHttpsTypeExisted.
  ///
  /// In en, this message translates to:
  /// **'Existing certificate'**
  String get hostHttpsTypeExisted;

  /// No description provided for @hostHttpsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'SSL options'**
  String get hostHttpsTypeLabel;

  /// No description provided for @hostHttpsTypeManual.
  ///
  /// In en, this message translates to:
  /// **'Import certificate manually'**
  String get hostHttpsTypeManual;

  /// No description provided for @hostLeechAccessDomains.
  ///
  /// In en, this message translates to:
  /// **'Allowed domains'**
  String get hostLeechAccessDomains;

  /// No description provided for @hostLeechBlockedHelper.
  ///
  /// In en, this message translates to:
  /// **'When \'Allow empty referrer\' is on, requests without a Referer are not blocked; this also allows any Referer not starting with http/https'**
  String get hostLeechBlockedHelper;

  /// No description provided for @hostLeechBlockedRef.
  ///
  /// In en, this message translates to:
  /// **'Allow non-standard Referer'**
  String get hostLeechBlockedRef;

  /// No description provided for @hostLeechBrowserCache.
  ///
  /// In en, this message translates to:
  /// **'Browser Cache'**
  String get hostLeechBrowserCache;

  /// No description provided for @hostLeechCacheControl.
  ///
  /// In en, this message translates to:
  /// **'Cache control'**
  String get hostLeechCacheControl;

  /// No description provided for @hostLeechCacheTime.
  ///
  /// In en, this message translates to:
  /// **'Browser Cache Time'**
  String get hostLeechCacheTime;

  /// No description provided for @hostLeechCacheTimeHelper.
  ///
  /// In en, this message translates to:
  /// **'The time static resources are cached locally in the browser, reducing redundant requests'**
  String get hostLeechCacheTimeHelper;

  /// No description provided for @hostLeechCacheTimeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Cache time must be an integer between 1 and 65535.'**
  String get hostLeechCacheTimeInvalid;

  /// No description provided for @hostLeechDomainsHelper.
  ///
  /// In en, this message translates to:
  /// **'One domain per line'**
  String get hostLeechDomainsHelper;

  /// No description provided for @hostLeechDomainsRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one allowed domain is required when enabled.'**
  String get hostLeechDomainsRequired;

  /// No description provided for @hostLeechEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get hostLeechEnable;

  /// No description provided for @hostLeechExtends.
  ///
  /// In en, this message translates to:
  /// **'File extensions'**
  String get hostLeechExtends;

  /// No description provided for @hostLeechLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the anti-leech configuration.'**
  String get hostLeechLoadFailed;

  /// No description provided for @hostLeechLogEnable.
  ///
  /// In en, this message translates to:
  /// **'Log static asset requests'**
  String get hostLeechLogEnable;

  /// No description provided for @hostLeechLogHelper.
  ///
  /// In en, this message translates to:
  /// **'Logs static asset requests; usually disabled in production to avoid noisy logs'**
  String get hostLeechLogHelper;

  /// No description provided for @hostLeechNoneRef.
  ///
  /// In en, this message translates to:
  /// **'Allow empty referrer'**
  String get hostLeechNoneRef;

  /// No description provided for @hostLeechReturn.
  ///
  /// In en, this message translates to:
  /// **'Response resource'**
  String get hostLeechReturn;

  /// No description provided for @hostLeechReturnHelper.
  ///
  /// In en, this message translates to:
  /// **'HTTP status code returned after blocking hotlinking requests'**
  String get hostLeechReturnHelper;

  /// No description provided for @hostLeechSaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save the anti-leech configuration for \'{0}\'?'**
  String get hostLeechSaveConfirm;

  /// No description provided for @hostLeechSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the anti-leech configuration.'**
  String get hostLeechSaveFailed;

  /// No description provided for @hostLeechSaved.
  ///
  /// In en, this message translates to:
  /// **'Anti-leech configuration saved.'**
  String get hostLeechSaved;

  /// No description provided for @hostLogsAccessLog.
  ///
  /// In en, this message translates to:
  /// **'Website logs'**
  String get hostLogsAccessLog;

  /// No description provided for @hostLogsErrorLog.
  ///
  /// In en, this message translates to:
  /// **'Error log'**
  String get hostLogsErrorLog;

  /// No description provided for @hostLogsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the website log.'**
  String get hostLogsLoadFailed;

  /// No description provided for @hostLogsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh the website log.'**
  String get hostLogsRefreshFailed;

  /// No description provided for @hostLogsStateHint.
  ///
  /// In en, this message translates to:
  /// **'Log switch state (read-only in this release)'**
  String get hostLogsStateHint;

  /// No description provided for @hostProxyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Proxy'**
  String get hostProxyAdd;

  /// No description provided for @hostProxyAddressPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 127.0.0.1:8080'**
  String get hostProxyAddressPlaceholder;

  /// No description provided for @hostProxyAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Target address is required.'**
  String get hostProxyAddressRequired;

  /// No description provided for @hostProxyAllowCredentials.
  ///
  /// In en, this message translates to:
  /// **'Allow credentials'**
  String get hostProxyAllowCredentials;

  /// No description provided for @hostProxyAllowHeaders.
  ///
  /// In en, this message translates to:
  /// **'Allow headers'**
  String get hostProxyAllowHeaders;

  /// No description provided for @hostProxyAllowMethods.
  ///
  /// In en, this message translates to:
  /// **'Allow methods'**
  String get hostProxyAllowMethods;

  /// No description provided for @hostProxyAllowOrigins.
  ///
  /// In en, this message translates to:
  /// **'Allow origins'**
  String get hostProxyAllowOrigins;

  /// No description provided for @hostProxyBrowserCache.
  ///
  /// In en, this message translates to:
  /// **'Browser cache'**
  String get hostProxyBrowserCache;

  /// No description provided for @hostProxyBrowserCacheNoModify.
  ///
  /// In en, this message translates to:
  /// **'No modify'**
  String get hostProxyBrowserCacheNoModify;

  /// No description provided for @hostProxyBrowserCacheTime.
  ///
  /// In en, this message translates to:
  /// **'Cache time'**
  String get hostProxyBrowserCacheTime;

  /// No description provided for @hostProxyBrowserCacheTimeHelper.
  ///
  /// In en, this message translates to:
  /// **'How long browsers may cache responses.'**
  String get hostProxyBrowserCacheTimeHelper;

  /// No description provided for @hostProxyCacheSection.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get hostProxyCacheSection;

  /// No description provided for @hostProxyCacheTimeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Cache time must be a number between 1 and 65535.'**
  String get hostProxyCacheTimeInvalid;

  /// No description provided for @hostProxyCancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel edit'**
  String get hostProxyCancelEdit;

  /// No description provided for @hostProxyCors.
  ///
  /// In en, this message translates to:
  /// **'Enable CORS'**
  String get hostProxyCors;

  /// No description provided for @hostProxyCorsSection.
  ///
  /// In en, this message translates to:
  /// **'CORS'**
  String get hostProxyCorsSection;

  /// No description provided for @hostProxyDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete proxy \'{0}\'? The proxy config file will be removed.'**
  String get hostProxyDeleteConfirmMessage;

  /// No description provided for @hostProxyDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete proxy'**
  String get hostProxyDeleteConfirmTitle;

  /// No description provided for @hostProxyDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the proxy.'**
  String get hostProxyDeleteFailed;

  /// No description provided for @hostProxyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Proxy deleted.'**
  String get hostProxyDeleted;

  /// No description provided for @hostProxyDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get hostProxyDisable;

  /// No description provided for @hostProxyDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get hostProxyDisabled;

  /// No description provided for @hostProxyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Proxy'**
  String get hostProxyEditTitle;

  /// No description provided for @hostProxyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No proxy rules yet.'**
  String get hostProxyEmpty;

  /// No description provided for @hostProxyHost.
  ///
  /// In en, this message translates to:
  /// **'Proxy host'**
  String get hostProxyHost;

  /// No description provided for @hostProxyHostHelper.
  ///
  /// In en, this message translates to:
  /// **'Host header sent upstream; \$host keeps the original domain.'**
  String get hostProxyHostHelper;

  /// No description provided for @hostProxyHostRequired.
  ///
  /// In en, this message translates to:
  /// **'Proxy host is required.'**
  String get hostProxyHostRequired;

  /// No description provided for @hostProxyListTitle.
  ///
  /// In en, this message translates to:
  /// **'Proxy rules'**
  String get hostProxyListTitle;

  /// No description provided for @hostProxyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the proxy list.'**
  String get hostProxyLoadFailed;

  /// No description provided for @hostProxyMatch.
  ///
  /// In en, this message translates to:
  /// **'Proxy path'**
  String get hostProxyMatch;

  /// No description provided for @hostProxyMatchRequired.
  ///
  /// In en, this message translates to:
  /// **'Proxy path is required.'**
  String get hostProxyMatchRequired;

  /// No description provided for @hostProxyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get hostProxyNameRequired;

  /// No description provided for @hostProxyOriginsRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow origins is required when CORS is enabled.'**
  String get hostProxyOriginsRequired;

  /// No description provided for @hostProxyPass.
  ///
  /// In en, this message translates to:
  /// **'Target address'**
  String get hostProxyPass;

  /// No description provided for @hostProxyPassHelper.
  ///
  /// In en, this message translates to:
  /// **'Upstream address the requests are forwarded to.'**
  String get hostProxyPassHelper;

  /// No description provided for @hostProxyPreflight.
  ///
  /// In en, this message translates to:
  /// **'Preflight'**
  String get hostProxyPreflight;

  /// No description provided for @hostProxySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the proxy.'**
  String get hostProxySaveFailed;

  /// No description provided for @hostProxyServerCache.
  ///
  /// In en, this message translates to:
  /// **'Server cache'**
  String get hostProxyServerCache;

  /// No description provided for @hostProxyServerCacheTime.
  ///
  /// In en, this message translates to:
  /// **'Cache time'**
  String get hostProxyServerCacheTime;

  /// No description provided for @hostProxyServerCacheTimeHelper.
  ///
  /// In en, this message translates to:
  /// **'How long upstream responses stay in the server cache.'**
  String get hostProxyServerCacheTimeHelper;

  /// No description provided for @hostProxySni.
  ///
  /// In en, this message translates to:
  /// **'SNI'**
  String get hostProxySni;

  /// No description provided for @hostProxySniHelper.
  ///
  /// In en, this message translates to:
  /// **'Send the server name to the HTTPS upstream (proxy_ssl_server_name).'**
  String get hostProxySniHelper;

  /// No description provided for @hostProxySslVerify.
  ///
  /// In en, this message translates to:
  /// **'SSL verify'**
  String get hostProxySslVerify;

  /// No description provided for @hostProxySslVerifyHelper.
  ///
  /// In en, this message translates to:
  /// **'Verify the upstream certificate when proxying over HTTPS.'**
  String get hostProxySslVerifyHelper;

  /// No description provided for @hostProxyStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the proxy status.'**
  String get hostProxyStatusFailed;

  /// No description provided for @hostProxyStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Proxy status updated.'**
  String get hostProxyStatusUpdated;

  /// No description provided for @hostRedirectAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Redirect'**
  String get hostRedirectAdd;

  /// No description provided for @hostRedirectCancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel edit'**
  String get hostRedirectCancelEdit;

  /// No description provided for @hostRedirectDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete redirect \'{0}\'?'**
  String get hostRedirectDeleteConfirmMessage;

  /// No description provided for @hostRedirectDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete redirect'**
  String get hostRedirectDeleteConfirmTitle;

  /// No description provided for @hostRedirectDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the redirect.'**
  String get hostRedirectDeleteFailed;

  /// No description provided for @hostRedirectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Redirect deleted.'**
  String get hostRedirectDeleted;

  /// No description provided for @hostRedirectDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get hostRedirectDisable;

  /// No description provided for @hostRedirectDomains.
  ///
  /// In en, this message translates to:
  /// **'Domains'**
  String get hostRedirectDomains;

  /// No description provided for @hostRedirectDomainsHelper.
  ///
  /// In en, this message translates to:
  /// **'One domain per line.'**
  String get hostRedirectDomainsHelper;

  /// No description provided for @hostRedirectDomainsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'One domain per line, e.g. old.example.com'**
  String get hostRedirectDomainsPlaceholder;

  /// No description provided for @hostRedirectDomainsRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one domain is required.'**
  String get hostRedirectDomainsRequired;

  /// No description provided for @hostRedirectEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Redirect'**
  String get hostRedirectEditTitle;

  /// No description provided for @hostRedirectEmpty.
  ///
  /// In en, this message translates to:
  /// **'No redirect rules yet.'**
  String get hostRedirectEmpty;

  /// No description provided for @hostRedirectKeep.
  ///
  /// In en, this message translates to:
  /// **'keep path'**
  String get hostRedirectKeep;

  /// No description provided for @hostRedirectKeepPath.
  ///
  /// In en, this message translates to:
  /// **'Keep path'**
  String get hostRedirectKeepPath;

  /// No description provided for @hostRedirectKeepPathHelper.
  ///
  /// In en, this message translates to:
  /// **'Append the original request path to the target URL.'**
  String get hostRedirectKeepPathHelper;

  /// No description provided for @hostRedirectListTitle.
  ///
  /// In en, this message translates to:
  /// **'Redirect rules'**
  String get hostRedirectListTitle;

  /// No description provided for @hostRedirectLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the redirect list.'**
  String get hostRedirectLoadFailed;

  /// No description provided for @hostRedirectNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get hostRedirectNameRequired;

  /// No description provided for @hostRedirectNotKeep.
  ///
  /// In en, this message translates to:
  /// **'drop path'**
  String get hostRedirectNotKeep;

  /// No description provided for @hostRedirectPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Path is required.'**
  String get hostRedirectPathRequired;

  /// No description provided for @hostRedirectSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the redirect.'**
  String get hostRedirectSaveFailed;

  /// No description provided for @hostRedirectStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the redirect status.'**
  String get hostRedirectStatusFailed;

  /// No description provided for @hostRedirectStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Redirect status updated.'**
  String get hostRedirectStatusUpdated;

  /// No description provided for @hostRedirectTarget.
  ///
  /// In en, this message translates to:
  /// **'Target URL'**
  String get hostRedirectTarget;

  /// No description provided for @hostRedirectTargetRequired.
  ///
  /// In en, this message translates to:
  /// **'Target URL is required.'**
  String get hostRedirectTargetRequired;

  /// No description provided for @hostRedirectTypeDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get hostRedirectTypeDomain;

  /// No description provided for @hostRedirectTypePath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get hostRedirectTypePath;

  /// No description provided for @hostRedirectWay.
  ///
  /// In en, this message translates to:
  /// **'Redirect'**
  String get hostRedirectWay;

  /// No description provided for @hostRedirectWayHelper.
  ///
  /// In en, this message translates to:
  /// **'301 is permanent, 302 is temporary.'**
  String get hostRedirectWayHelper;

  /// No description provided for @hostRewriteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewrite rules'**
  String get hostRewriteCardTitle;

  /// No description provided for @hostRewriteContentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'# nginx rewrite rules'**
  String get hostRewriteContentPlaceholder;

  /// No description provided for @hostRewriteCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get hostRewriteCurrent;

  /// No description provided for @hostRewriteHelper.
  ///
  /// In en, this message translates to:
  /// **'Saved rules take effect once nginx reloads, which happens automatically after saving.'**
  String get hostRewriteHelper;

  /// No description provided for @hostRewriteHelper2.
  ///
  /// In en, this message translates to:
  /// **'Modifying rewrite rules may affect how the website resolves.'**
  String get hostRewriteHelper2;

  /// No description provided for @hostRewriteLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the rewrite content.'**
  String get hostRewriteLoadFailed;

  /// No description provided for @hostRewriteMode.
  ///
  /// In en, this message translates to:
  /// **'Rewrite mode'**
  String get hostRewriteMode;

  /// No description provided for @hostRewriteSaveAndReload.
  ///
  /// In en, this message translates to:
  /// **'Save and reload'**
  String get hostRewriteSaveAndReload;

  /// No description provided for @hostRewriteSaveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Save the rewrite rules for \'{0}\' and reload nginx?'**
  String get hostRewriteSaveConfirmMessage;

  /// No description provided for @hostRewriteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the rewrite rules.'**
  String get hostRewriteSaveFailed;

  /// No description provided for @hostRewriteSaved.
  ///
  /// In en, this message translates to:
  /// **'Rewrite rules saved and nginx reloaded.'**
  String get hostRewriteSaved;

  /// No description provided for @hostWebsiteConfigBack.
  ///
  /// In en, this message translates to:
  /// **'Back to websites'**
  String get hostWebsiteConfigBack;

  /// No description provided for @hostWebsiteTabPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This module will be provided in a later batch.'**
  String get hostWebsiteTabPlaceholder;

  /// No description provided for @hostWebsitesConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get hostWebsitesConfig;

  /// No description provided for @hostWebsitesConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Website configuration'**
  String get hostWebsitesConfigHint;

  /// No description provided for @hostHttpsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'HTTPS'**
  String get hostHttpsTabTitle;

  /// No description provided for @hostDomainsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Domains'**
  String get hostDomainsTabTitle;

  /// No description provided for @hostWebsiteTabProxy.
  ///
  /// In en, this message translates to:
  /// **'Reverse Proxy'**
  String get hostWebsiteTabProxy;

  /// No description provided for @hostWebsiteTabRedirect.
  ///
  /// In en, this message translates to:
  /// **'Redirect'**
  String get hostWebsiteTabRedirect;

  /// No description provided for @hostWebsiteTabRewrite.
  ///
  /// In en, this message translates to:
  /// **'Rewrite'**
  String get hostWebsiteTabRewrite;

  /// No description provided for @hostWebsiteTabCors.
  ///
  /// In en, this message translates to:
  /// **'CORS'**
  String get hostWebsiteTabCors;

  /// No description provided for @hostWebsiteTabAntiLeech.
  ///
  /// In en, this message translates to:
  /// **'Anti-Leech'**
  String get hostWebsiteTabAntiLeech;

  /// No description provided for @hostWebsiteTabBasicAuth.
  ///
  /// In en, this message translates to:
  /// **'Basic Auth'**
  String get hostWebsiteTabBasicAuth;

  /// No description provided for @hostWebsiteTabLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get hostWebsiteTabLogs;

  /// No description provided for @hostFilesEditorBack.
  ///
  /// In en, this message translates to:
  /// **'Back to files'**
  String get hostFilesEditorBack;

  /// No description provided for @hostFilesEditorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load file content.'**
  String get hostFilesEditorLoadFailed;

  /// No description provided for @hostFilesEditorSaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save changes to \'{0}\'?'**
  String get hostFilesEditorSaveConfirm;

  /// No description provided for @hostFilesSearchNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching files.'**
  String get hostFilesSearchNoMatch;

  /// No description provided for @hostFilesPasteAction.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get hostFilesPasteAction;

  /// No description provided for @hostFilesCutAction.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get hostFilesCutAction;

  /// No description provided for @hostFilesPermissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get hostFilesPermissionLabel;

  /// No description provided for @hostFilesFileNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get hostFilesFileNamePlaceholder;

  /// No description provided for @hostFilesFileNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'File name cannot be empty.'**
  String get hostFilesFileNameEmpty;

  /// No description provided for @hostFilesCreateFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create file \'{0}\'.'**
  String get hostFilesCreateFileFailed;

  /// No description provided for @hostFilesRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename \'{0}\'.'**
  String get hostFilesRenameFailed;

  /// No description provided for @hostFilesCutToast.
  ///
  /// In en, this message translates to:
  /// **'Cut. Paste it in the target directory.'**
  String get hostFilesCutToast;

  /// No description provided for @hostFilesCopyToast.
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste it in the target directory.'**
  String get hostFilesCopyToast;

  /// No description provided for @hostFilesPasteFailed.
  ///
  /// In en, this message translates to:
  /// **'Paste failed.'**
  String get hostFilesPasteFailed;

  /// No description provided for @hostFilesDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination directory'**
  String get hostFilesDestinationLabel;

  /// No description provided for @hostFilesCompressFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to compress \'{0}\'.'**
  String get hostFilesCompressFailed;

  /// No description provided for @hostFilesModePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 755'**
  String get hostFilesModePlaceholder;

  /// No description provided for @hostFilesModeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 3-digit octal permission (e.g. 755).'**
  String get hostFilesModeInvalid;

  /// No description provided for @hostFilesModeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change permissions of \'{0}\'.'**
  String get hostFilesModeFailed;

  /// No description provided for @hostFilesFavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add favorite.'**
  String get hostFilesFavoriteFailed;

  /// No description provided for @hostAiAccountsAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get hostAiAccountsAddAction;

  /// No description provided for @hostAiAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent Accounts'**
  String get hostAiAccountsTitle;

  /// No description provided for @hostAiAccountProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get hostAiAccountProviderLabel;

  /// No description provided for @hostAiAccountApiTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'API Type'**
  String get hostAiAccountApiTypeLabel;

  /// No description provided for @hostAiAccountBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get hostAiAccountBaseUrlLabel;

  /// No description provided for @hostAiAccountApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get hostAiAccountApiKeyLabel;

  /// No description provided for @hostAiAccountRemarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get hostAiAccountRemarkLabel;

  /// No description provided for @hostAiAccountsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh agent accounts.'**
  String get hostAiAccountsRefreshFailed;

  /// No description provided for @hostAiAccountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No agent accounts yet.'**
  String get hostAiAccountsEmpty;

  /// No description provided for @hostAiAccountProviderRequired.
  ///
  /// In en, this message translates to:
  /// **'Provider is required.'**
  String get hostAiAccountProviderRequired;

  /// No description provided for @hostAiAccountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get hostAiAccountNameRequired;

  /// No description provided for @hostAiAccountApiTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'API type is required.'**
  String get hostAiAccountApiTypeRequired;

  /// No description provided for @hostAiAccountBaseUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Base URL is required.'**
  String get hostAiAccountBaseUrlRequired;

  /// No description provided for @hostAiAccountApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API Key is required.'**
  String get hostAiAccountApiKeyRequired;

  /// No description provided for @hostAiAccountsSaved.
  ///
  /// In en, this message translates to:
  /// **'Agent account saved.'**
  String get hostAiAccountsSaved;

  /// No description provided for @hostAiAccountsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update the agent account.'**
  String get hostAiAccountsUpdateFailed;

  /// No description provided for @hostAiAccountsCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the agent account.'**
  String get hostAiAccountsCreateFailed;

  /// No description provided for @hostAiAccountsSaveFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Save failed. Adjust the input and try again.'**
  String get hostAiAccountsSaveFailedRetry;

  /// No description provided for @hostAiAccountDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete agent account \'{0}\'? This cannot be undone.'**
  String get hostAiAccountDeleteConfirm;

  /// No description provided for @hostAiAccountsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Agent account deleted.'**
  String get hostAiAccountsDeleted;

  /// No description provided for @hostAiAccountsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the agent account.'**
  String get hostAiAccountsDeleteFailed;

  /// No description provided for @hostAiAccountsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load agent accounts.'**
  String get hostAiAccountsLoadFailed;

  /// No description provided for @hostAiGpuEmpty.
  ///
  /// In en, this message translates to:
  /// **'No GPU detected on this server.'**
  String get hostAiGpuEmpty;

  /// No description provided for @hostAiGpuRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh the GPU status.'**
  String get hostAiGpuRefreshFailed;

  /// No description provided for @hostAiGpuDriverVersion.
  ///
  /// In en, this message translates to:
  /// **'Driver Version'**
  String get hostAiGpuDriverVersion;

  /// No description provided for @hostAiGpuCudaVersion.
  ///
  /// In en, this message translates to:
  /// **'CUDA Version'**
  String get hostAiGpuCudaVersion;

  /// No description provided for @hostAiGpuTitle.
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get hostAiGpuTitle;

  /// No description provided for @hostAiGpuUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get hostAiGpuUnknownDevice;

  /// No description provided for @hostAiGpuUtilization.
  ///
  /// In en, this message translates to:
  /// **'GPU Utilization'**
  String get hostAiGpuUtilization;

  /// No description provided for @hostAiGpuTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get hostAiGpuTemperature;

  /// No description provided for @hostAiGpuPerformanceState.
  ///
  /// In en, this message translates to:
  /// **'Performance State'**
  String get hostAiGpuPerformanceState;

  /// No description provided for @hostAiGpuPowerUsage.
  ///
  /// In en, this message translates to:
  /// **'Power Usage'**
  String get hostAiGpuPowerUsage;

  /// No description provided for @hostAiGpuMemoryUsage.
  ///
  /// In en, this message translates to:
  /// **'Memory Usage'**
  String get hostAiGpuMemoryUsage;

  /// No description provided for @hostAiGpuFanSpeed.
  ///
  /// In en, this message translates to:
  /// **'Fan Speed'**
  String get hostAiGpuFanSpeed;

  /// No description provided for @hostAiGpuBusId.
  ///
  /// In en, this message translates to:
  /// **'Bus ID'**
  String get hostAiGpuBusId;

  /// No description provided for @hostAiGpuPersistenceMode.
  ///
  /// In en, this message translates to:
  /// **'Persistence Mode'**
  String get hostAiGpuPersistenceMode;

  /// No description provided for @hostAiGpuDisplayActive.
  ///
  /// In en, this message translates to:
  /// **'Display Active'**
  String get hostAiGpuDisplayActive;

  /// No description provided for @hostAiGpuEcc.
  ///
  /// In en, this message translates to:
  /// **'Uncorr. ECC'**
  String get hostAiGpuEcc;

  /// No description provided for @hostAiGpuComputeMode.
  ///
  /// In en, this message translates to:
  /// **'Compute Mode'**
  String get hostAiGpuComputeMode;

  /// No description provided for @hostAiGpuMigMode.
  ///
  /// In en, this message translates to:
  /// **'MIG Mode'**
  String get hostAiGpuMigMode;

  /// No description provided for @hostAiGpuMemoryUtilization.
  ///
  /// In en, this message translates to:
  /// **'Memory Utilization'**
  String get hostAiGpuMemoryUtilization;

  /// No description provided for @hostAiGpuFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get hostAiGpuFrequency;

  /// No description provided for @hostAiGpuProcesses.
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get hostAiGpuProcesses;

  /// No description provided for @hostAiGpuShr.
  ///
  /// In en, this message translates to:
  /// **'Shared Mem'**
  String get hostAiGpuShr;

  /// No description provided for @hostAiGpuProcessName.
  ///
  /// In en, this message translates to:
  /// **'Process Name'**
  String get hostAiGpuProcessName;

  /// No description provided for @hostAiGpuProcessMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory Usage'**
  String get hostAiGpuProcessMemory;

  /// No description provided for @hostAiGpuProcessTypeC.
  ///
  /// In en, this message translates to:
  /// **'Compute'**
  String get hostAiGpuProcessTypeC;

  /// No description provided for @hostAiGpuProcessTypeG.
  ///
  /// In en, this message translates to:
  /// **'Graphics'**
  String get hostAiGpuProcessTypeG;

  /// No description provided for @hostAiGpuProcessTypeCG.
  ///
  /// In en, this message translates to:
  /// **'Compute+Graphics'**
  String get hostAiGpuProcessTypeCG;

  /// No description provided for @hostAiGpuLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the GPU status.'**
  String get hostAiGpuLoadFailed;

  /// No description provided for @hostAiMcpLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load MCP servers.'**
  String get hostAiMcpLoadFailed;

  /// No description provided for @hostAiMcpTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get hostAiMcpTestConnection;

  /// No description provided for @hostAiMcpOperateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to \'{0}\' the MCP server \'{1}\'?'**
  String get hostAiMcpOperateConfirm;

  /// No description provided for @hostAiMcpOperationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation completed.'**
  String get hostAiMcpOperationSuccess;

  /// No description provided for @hostAiMcpOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'MCP server operation failed.'**
  String get hostAiMcpOperationFailed;

  /// No description provided for @hostAiMcpTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection test passed.'**
  String get hostAiMcpTestSuccess;

  /// No description provided for @hostAiMcpTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection test failed.'**
  String get hostAiMcpTestFailed;

  /// No description provided for @hostAiMcpDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the MCP server.'**
  String get hostAiMcpDeleteFailed;

  /// No description provided for @hostAiMcpUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the base URL.'**
  String get hostAiMcpUrlRequired;

  /// No description provided for @hostAiMcpPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the transport path.'**
  String get hostAiMcpPathRequired;

  /// No description provided for @hostAiMcpContainerRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a container name.'**
  String get hostAiMcpContainerRequired;

  /// No description provided for @hostAiMcpImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the gateway image.'**
  String get hostAiMcpImageRequired;

  /// No description provided for @hostAiMcpCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the MCP server.'**
  String get hostAiMcpCreateFailed;

  /// No description provided for @hostAiMcpStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get hostAiMcpStatusError;

  /// No description provided for @hostAiAgentTypeHermes.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent'**
  String get hostAiAgentTypeHermes;

  /// No description provided for @hostAiAgentCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Agent creation failed or timed out. The installation may still be running on the server - wait patiently or check the server task list.'**
  String get hostAiAgentCreateFailed;

  /// No description provided for @hostAiAgentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load agents.'**
  String get hostAiAgentLoadFailed;

  /// No description provided for @hostAiAgentOverviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the agent overview.'**
  String get hostAiAgentOverviewFailed;

  /// No description provided for @hostAiAgentDefaultModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Default model'**
  String get hostAiAgentDefaultModelLabel;

  /// No description provided for @hostAiAgentJobCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get hostAiAgentJobCountLabel;

  /// No description provided for @hostAiAgentSessionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get hostAiAgentSessionCountLabel;

  /// No description provided for @hostAiAgentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete agent \'{0}\'? This action cannot be undone.'**
  String get hostAiAgentDeleteConfirm;

  /// No description provided for @hostAiAgentOperationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation completed.'**
  String get hostAiAgentOperationSuccess;

  /// No description provided for @hostAiAgentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the agent.'**
  String get hostAiAgentDeleteFailed;

  /// No description provided for @hostAiAgentStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get hostAiAgentStatusError;

  /// No description provided for @hostAiTabModels.
  ///
  /// In en, this message translates to:
  /// **'Local Models'**
  String get hostAiTabModels;

  /// No description provided for @hostAiTabAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get hostAiTabAccounts;

  /// No description provided for @hostAiTabMcp.
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get hostAiTabMcp;

  /// No description provided for @hostAiTabAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get hostAiTabAgents;

  /// No description provided for @hostAiTabGpu.
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get hostAiTabGpu;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
