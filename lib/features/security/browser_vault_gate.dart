import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onepanel_client/core/config/api_config_migration.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/storage/browser_vault.dart';
import 'package:onepanel_client/core/platform/services/browser_document_service.dart';
import 'package:onepanel_client/core/platform/services/browser_password_autofill.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

class BrowserVaultGate extends StatefulWidget {
  const BrowserVaultGate({super.key, required this.child});

  final Widget child;

  @override
  State<BrowserVaultGate> createState() => _BrowserVaultGateState();
}

class _BrowserVaultGateState extends State<BrowserVaultGate> {
  final _vault = BrowserVault.instance;
  final _autofillAccount = TextEditingController(text: '1Panel Client');
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  bool _loading = true;
  bool _ready = false;
  bool _saving = false;
  bool _usePassword = true;
  bool _obscure = true;
  bool _storageError = false;
  bool _unlockError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _storageError = false;
    });
    try {
      await _vault.initialize();
      if (_vault.usesBrowserKey) {
        await _vault.unlockWithBrowserKey();
        await ApiConfigMigration.runMigrationIfNeeded();
        if (!mounted) return;
        setState(() => _ready = true);
      }
    } catch (error, stackTrace) {
      appLogger.eWithPackage('security.browser_vault',
          '浏览器存储初始化失败',
          error: error, stackTrace: stackTrace);
      if (mounted) setState(() => _storageError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unlock() async {
    if (_saving) return;
    if (_usePassword && !_formKey.currentState!.validate()) {
      if (_password.text.isEmpty) {
        _passwordFocus.requestFocus();
      } else {
        _confirmationFocus.requestFocus();
      }
      return;
    }
    setState(() {
      _saving = true;
      _unlockError = false;
    });
    try {
      if (_usePassword) {
        await _vault.unlock(_password.text);
      } else {
        await _vault.unlockWithBrowserKey();
      }
      await _vault.requestPersistence();
      await ApiConfigMigration.runMigrationIfNeeded();
      if (_usePassword) {
        if (kIsWeb) BrowserPasswordAutofill.commit();
        TextInput.finishAutofillContext(shouldSave: true);
      }
      _password.clear();
      _confirmation.clear();
      if (mounted) setState(() => _ready = true);
    } catch (error, stackTrace) {
      appLogger.eWithPackage('security.browser_vault', '浏览器本地存储解锁失败',
          error: error, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _unlockError = true);
        _passwordFocus.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _autofillAccount.dispose();
    _password.dispose();
    _confirmation.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    return MaterialApp(
      title: '1Panel Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      home: Builder(builder: (context) {
        if (kIsWeb) {
          BrowserDocumentService.updateLanguage(
              Localizations.localeOf(context).toLanguageTag());
        }
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        if (_loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (_storageError) {
          return Scaffold(
            body: ModuleErrorStateWidget(
              message: l10n.webVaultStorageError,
              onRetry: _initialize,
            ),
          );
        }
        final creating = !_vault.isConfigured;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      onDisposeAction: AutofillContextAction.cancel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Icon(Icons.dns_outlined, size: 40),
                          ),
                          const SizedBox(height: 24),
                          Semantics(
                            header: true,
                            child: Text(l10n.webVaultTitle,
                                style: theme.textTheme.headlineMedium),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.webVaultDescription),
                          const SizedBox(height: 24),
                          if (creating) ...[
                            LayoutBuilder(builder: (context, constraints) =>
                            SegmentedButton<bool>(
                              direction: constraints.maxWidth < 400
                                  ? Axis.vertical : Axis.horizontal,
                              style: const ButtonStyle(
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                                visualDensity: VisualDensity.standard,
                              ),
                              segments: [
                                ButtonSegment(
                                    value: true,
                                    label: Text(l10n.webVaultPasswordMode)),
                                ButtonSegment(
                                    value: false,
                                    label: Text(l10n.webVaultBrowserMode)),
                              ],
                              selected: {_usePassword},
                              onSelectionChanged: _saving
                                  ? null
                                  : (value) => setState(
                                      () => _usePassword = value.single),
                            )),
                            const SizedBox(height: 16),
                          ],
                          Text(_usePassword
                              ? l10n.webVaultPasswordModeHelp
                              : l10n.webVaultBrowserModeHelp),
                          const SizedBox(height: 24),
                          if (_usePassword) ...[
                            Offstage(
                              child: TextField(
                                controller: _autofillAccount,
                                readOnly: true,
                                autofillHints: const [AutofillHints.username],
                              ),
                            ),
                            TextFormField(
                              controller: _password,
                              focusNode: _passwordFocus,
                              obscureText: _obscure,
                              enableSuggestions: false,
                              autocorrect: false,
                              enabled: !_saving,
                              keyboardType: TextInputType.visiblePassword,
                              textInputAction: creating
                                  ? TextInputAction.next : TextInputAction.done,
                              autofillHints: [
                                creating
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: l10n.webVaultPassword,
                                errorText: _unlockError
                                    ? l10n.webVaultUnlockError
                                    : null,
                                errorMaxLines: 4,
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 48, minHeight: 48),
                                suffixIcon: IconButton(
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    visualDensity: VisualDensity.standard,
                                  ),
                                  tooltip: _obscure
                                      ? l10n.commonShow
                                      : l10n.commonHide,
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                              validator: (value) =>
                                  (value ?? '').isEmpty
                                      ? l10n.webVaultPasswordRequired
                                      : null,
                              onFieldSubmitted: creating
                                  ? (_) => _confirmationFocus.requestFocus()
                                  : (_) => _unlock(),
                            ),
                            if (creating) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmation,
                                focusNode: _confirmationFocus,
                                obscureText: _obscure,
                                enabled: !_saving,
                                enableSuggestions: false,
                                autocorrect: false,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.newPassword],
                                decoration: InputDecoration(
                                  labelText: l10n.webVaultConfirmPassword,
                                ),
                                validator: (value) => value != _password.text
                                    ? l10n.webVaultPasswordMismatch
                                    : null,
                                onFieldSubmitted: (_) => _unlock(),
                              ),
                            ],
                          ] else if (_unlockError)
                            Semantics(
                              liveRegion: true,
                              child: Text(l10n.webVaultUnlockError,
                                  style: TextStyle(color: theme.colorScheme.error)),
                            ),
                          const SizedBox(height: 24),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              visualDensity: VisualDensity.standard,
                            ),
                            onPressed: _saving ? null : _unlock,
                            child: _saving
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(creating
                                    ? l10n.webVaultCreate
                                    : l10n.webVaultUnlock),
                          ),
                          const SizedBox(height: 24),
                          Text(l10n.webVaultRetention,
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 16),
                          Text(l10n.webVaultInstallHint,
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
