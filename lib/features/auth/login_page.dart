import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/l10n_x.dart';
import 'auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _mfaController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AuthProvider>();
      provider.loadLoginSettings();
      provider.checkDemoMode();
      provider.checkPasskeyAvailability();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _mfaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, provider, child) {
          if (provider.status == AuthStatus.checking) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == AuthStatus.mfaRequired) {
            return _buildMfaForm(context, provider, l10n, colorScheme);
          }

          return _buildLoginForm(context, provider, l10n, colorScheme);
        },
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    AuthProvider provider,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, l10n, colorScheme),
                const SizedBox(height: 32),
                _buildUsernameField(l10n, colorScheme),
                const SizedBox(height: 16),
                _buildPasswordField(l10n, colorScheme),
                if (provider.loginSettings?.captcha == true) ...[
                  const SizedBox(height: 16),
                  _buildCaptchaField(provider, l10n, colorScheme),
                ],
                const SizedBox(height: 24),
                _buildLoginButton(provider, l10n, colorScheme),
                const SizedBox(height: 12),
                _buildPasskeyLoginButton(provider, l10n, colorScheme),
                if (provider.isPasskeyChecking) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(minHeight: 2),
                ] else if (!provider.isPasskeySupported &&
                    (provider.passkeyUnsupportedReason?.trim().isNotEmpty ??
                        false)) ...[
                  const SizedBox(height: 8),
                  _buildPasskeyHint(
                    provider.passkeyUnsupportedReason!,
                    l10n,
                    colorScheme,
                  ),
                ],
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(provider, colorScheme),
                ],
                if (provider.isDemoMode) ...[
                  const SizedBox(height: 16),
                  _buildDemoModeBanner(l10n, colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMfaForm(
    BuildContext context,
    AuthProvider provider,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.authMfaTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.authMfaDesc,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _mfaController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: l10n.authMfaHint,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    provider.isLoading ? null : () => _handleMfaLogin(provider),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.authMfaVerify),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => provider.resetMfaState(),
                child: Text(l10n.authMfaCancel),
              ),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(provider, colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Icon(
          Icons.dns_rounded,
          size: 64,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.authLoginTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.authLoginSubtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField(dynamic l10n, ColorScheme colorScheme) {
    return TextFormField(
      controller: _usernameController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
      decoration: InputDecoration(
        labelText: l10n.authUsername,
        prefixIcon: const Icon(Icons.person_outline),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.authUsernameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(dynamic l10n, ColorScheme colorScheme) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: l10n.authPassword,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.authPasswordRequired;
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleLogin(context.read<AuthProvider>()),
    );
  }

  Widget _buildCaptchaField(
    AuthProvider provider,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _captchaController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.authCaptcha,
              prefixIcon: const Icon(Icons.verified_user_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (provider.loginSettings?.captcha == true &&
                  (value == null || value.isEmpty)) {
                return l10n.authCaptchaRequired;
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => provider.loadCaptcha(),
          child: Container(
            width: 100,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: provider.captcha?.base64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _decodeBase64(provider.captcha!.base64!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.refresh,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(
    AuthProvider provider,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    return FilledButton(
      onPressed: provider.isLoading ? null : () => _handleLogin(provider),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: provider.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.authLogin),
    );
  }

  Widget _buildPasskeyLoginButton(
    AuthProvider provider,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    return OutlinedButton.icon(
      onPressed: provider.isLoading ||
              provider.isPasskeyChecking ||
              !provider.isPasskeySupported
          ? null
          : () => _handlePasskeyLogin(provider),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: const Icon(Icons.phonelink_lock_outlined),
      label: Text(l10n.authPasskeyLogin),
    );
  }

  Widget _buildPasskeyHint(
    String reason,
    dynamic l10n,
    ColorScheme colorScheme,
  ) {
    return Text(
      '${l10n.authPasskeyUnsupported}: $reason',
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage(AuthProvider provider, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoModeBanner(dynamic l10n, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.authDemoMode,
              style: TextStyle(color: colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(AuthProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final locale = Localizations.localeOf(context);
    await provider.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      language: _resolveLanguageTag(locale),
      captcha: _captchaController.text.trim(),
      captchaId: provider.captcha?.captchaId,
    );
  }

  Future<void> _handleMfaLogin(AuthProvider provider) async {
    final code = _mfaController.text.trim();
    if (code.length != 6) return;

    await provider.mfaLogin(code);
  }

  Future<void> _handlePasskeyLogin(AuthProvider provider) async {
    await provider.passkeyLogin();
  }

  Uint8List _decodeBase64(String base64) {
    try {
      String normalized = base64;
      if (base64.startsWith('data:image')) {
        normalized = base64.split(',').last;
      }
      return Uint8List.fromList(
        const Base64Decoder().convert(normalized),
      );
    } catch (e) {
      return Uint8List(0);
    }
  }

  String _resolveLanguageTag(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    final scriptCode = locale.scriptCode;
    final countryCode = locale.countryCode?.toUpperCase();

    if (languageCode == 'zh' && scriptCode == 'Hant') {
      return 'zh-Hant';
    }
    if (languageCode == 'pt' && countryCode == 'BR') {
      return 'pt-BR';
    }
    if (languageCode == 'es' && countryCode == 'ES') {
      return 'es-ES';
    }

    return languageCode;
  }
}
