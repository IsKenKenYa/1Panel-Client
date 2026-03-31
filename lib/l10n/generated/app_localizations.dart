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

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

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
  /// **'Preview'**
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

  /// No description provided for @aboutChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get aboutChannelLabel;

  /// No description provided for @aboutPreviewSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Experimental Preview'**
  String get aboutPreviewSectionTitle;

  /// No description provided for @aboutPreviewSummary.
  ///
  /// In en, this message translates to:
  /// **'This Android preview build is for early access and collecting user feedback.'**
  String get aboutPreviewSummary;

  /// No description provided for @aboutPreviewNoAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Automatic updates are not available in this preview. Download newer builds from GitHub Pre-release.'**
  String get aboutPreviewNoAutoUpdate;

  /// No description provided for @aboutPreviewFeedback.
  ///
  /// In en, this message translates to:
  /// **'Official feedback channel: GitHub Issues.'**
  String get aboutPreviewFeedback;

  /// No description provided for @aboutFeedbackSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get aboutFeedbackSectionTitle;

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
  /// **'Current preview notes'**
  String get aboutReleaseNotesSectionTitle;

  /// No description provided for @aboutReleaseNotesBody.
  ///
  /// In en, this message translates to:
  /// **'This preview focuses on multi-server management, onboarding polish, and early website management workflows.'**
  String get aboutReleaseNotesBody;

  /// No description provided for @aboutRepositorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get aboutRepositorySectionTitle;

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
  /// **'Open Preview Releases'**
  String get aboutReleaseAction;

  /// No description provided for @aboutLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get aboutLinkOpenFailed;

  /// No description provided for @aboutExperimentalModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Experimental modules'**
  String get aboutExperimentalModulesTitle;

  /// No description provided for @aboutExperimentalModulesDescription.
  ///
  /// In en, this message translates to:
  /// **'Some modules are still being refined for the preview channel and may change based on feedback.'**
  String get aboutExperimentalModulesDescription;

  /// No description provided for @aboutExperimentalModulesList.
  ///
  /// In en, this message translates to:
  /// **'Websites, OpenResty, Databases, Firewall, Terminal, Monitoring'**
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
  /// **'Phase 1 capabilities will be delivered here week by week so server operations stay in one mobile-first entry.'**
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
  /// **'Cronjobs will appear here after the Week 4 mainline flow loads data.'**
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
  /// **'App Store runtime creation stays in the Week 8 wizard. Week 7 only supports the manual runtime skeleton.'**
  String get runtimeFormAppStoreCreateWeek8Hint;

  /// No description provided for @runtimeFormPhpCreateWeek8Hint.
  ///
  /// In en, this message translates to:
  /// **'PHP creation keeps its dedicated flow for Week 8. Week 7 focuses on the shared runtime skeleton.'**
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
  /// **'Active SSH sessions will appear here after the websocket feed returns data.'**
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
