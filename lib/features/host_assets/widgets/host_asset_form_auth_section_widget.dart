import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class HostAssetFormAuthSectionWidget extends StatelessWidget {
  const HostAssetFormAuthSectionWidget({
    super.key,
    required this.userController,
    required this.passwordController,
    required this.privateKeyController,
    required this.passPhraseController,
    required this.authMode,
    required this.rememberPassword,
    required this.onUserChanged,
    required this.onAuthModeChanged,
    required this.onPasswordChanged,
    required this.onPrivateKeyChanged,
    required this.onPassPhraseChanged,
    required this.onRememberPasswordChanged,
  });

  final TextEditingController userController;
  final TextEditingController passwordController;
  final TextEditingController privateKeyController;
  final TextEditingController passPhraseController;
  final String authMode;
  final bool rememberPassword;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onAuthModeChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onPrivateKeyChanged;
  final ValueChanged<String> onPassPhraseChanged;
  final ValueChanged<bool> onRememberPasswordChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: userController,
          onChanged: onUserChanged,
          decoration: InputDecoration(
            labelText: l10n.hostAssetsUserLabel,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'password',
              label: Text(l10n.hostAssetsPasswordMode),
            ),
            ButtonSegment<String>(
              value: 'key',
              label: Text(l10n.hostAssetsKeyMode),
            ),
          ],
          selected: <String>{authMode},
          onSelectionChanged: (selection) {
            onAuthModeChanged(selection.first);
          },
        ),
        const SizedBox(height: 12),
        if (authMode == 'password')
          TextField(
            controller: passwordController,
            onChanged: onPasswordChanged,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.hostAssetsPasswordLabel,
            ),
          ),
        if (authMode == 'key') ...<Widget>[
          TextField(
            controller: privateKeyController,
            onChanged: onPrivateKeyChanged,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: l10n.hostAssetsPrivateKeyLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passPhraseController,
            onChanged: onPassPhraseChanged,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.hostAssetsPassPhraseLabel,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SwitchListTile(
          value: rememberPassword,
          onChanged: onRememberPasswordChanged,
          title: Text(l10n.hostAssetsRememberPasswordLabel),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
