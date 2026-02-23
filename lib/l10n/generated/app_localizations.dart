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
  /// **'1Panel Open'**
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

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

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

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

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
  /// **'Verification'**
  String get navSecurity;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

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
  /// **'Verification'**
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

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @securityPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Verification'**
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

  /// No description provided for @settingsServerManagement.
  ///
  /// In en, this message translates to:
  /// **'Server management'**
  String get settingsServerManagement;

  /// No description provided for @settingsResetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Replay onboarding'**
  String get settingsResetOnboarding;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsResetOnboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Onboarding state has been reset'**
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
  /// **'Manage your 1Panel servers'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Unified mobile operations for monitoring, files, and security.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Fast switching and clear status'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'View key metrics and switch servers quickly with a card-based layout.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Built for progressive API integration'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'UI is stable first. Missing APIs are tracked in review docs for follow-up.'**
  String get onboardingDesc3;

  /// No description provided for @coachServerAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first server'**
  String get coachServerAddTitle;

  /// No description provided for @coachServerAddDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap here to create a server profile.'**
  String get coachServerAddDesc;

  /// No description provided for @coachServerCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Open server details'**
  String get coachServerCardTitle;

  /// No description provided for @coachServerCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap a server card to see modules and quick actions.'**
  String get coachServerCardDesc;

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

  /// No description provided for @commonUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get commonUnknownError;

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

  /// No description provided for @appOperateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get appOperateSuccess;

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
