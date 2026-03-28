import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';

class SshSessionFilterSheetWidget extends StatefulWidget {
  const SshSessionFilterSheetWidget({
    super.key,
    required this.initialQuery,
  });

  final SshSessionQuery initialQuery;

  @override
  State<SshSessionFilterSheetWidget> createState() =>
      _SshSessionFilterSheetWidgetState();
}

class _SshSessionFilterSheetWidgetState
    extends State<SshSessionFilterSheetWidget> {
  late final TextEditingController _loginUserController;
  late final TextEditingController _loginIpController;

  @override
  void initState() {
    super.initState();
    _loginUserController =
        TextEditingController(text: widget.initialQuery.loginUser);
    _loginIpController =
        TextEditingController(text: widget.initialQuery.loginIP);
  }

  @override
  void dispose() {
    _loginUserController.dispose();
    _loginIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.commonSearch,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _loginUserController,
              decoration:
                  InputDecoration(labelText: l10n.sshSessionsLoginUserLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginIpController,
              decoration:
                  InputDecoration(labelText: l10n.sshSessionsLoginIpLabel),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    SshSessionQuery(
                      loginUser: _loginUserController.text.trim(),
                      loginIP: _loginIpController.text.trim(),
                    ),
                  );
                },
                child: Text(l10n.commonConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
