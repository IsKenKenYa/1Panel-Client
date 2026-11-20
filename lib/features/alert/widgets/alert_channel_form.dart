import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';
import 'package:onepanel_client/features/alert/tabs/alert_channel_tab.dart';
import 'package:onepanel_client/features/alert/widgets/alert_custom_webhook_editor.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
/// 通知渠道创建/编辑表单。
///
/// 密钥字段采用 keep/replace/clear 三态：编辑时留空表示保持原值，
/// 输入新值表示替换，显式清除表示删除。Webhook 渠道必须测试通过才能保存。
Future<void> showAlertChannelForm(BuildContext context,
    {AlertConfigInfo? editing}) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (_) => AlertChannelForm(editing: editing),
  );
}

/// 密钥字段的编辑意图。
enum SecretIntent { keep, replace, clear }

class AlertChannelForm extends StatefulWidget {
  const AlertChannelForm({super.key, this.editing});

  final AlertConfigInfo? editing;

  @override
  State<AlertChannelForm> createState() => _AlertChannelFormState();
}

class _AlertChannelFormState extends State<AlertChannelForm> {
  final _displayNameController = TextEditingController();
  final _senderController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '465');
  final _recipientController = TextEditingController();
  final _webhookUrlController = TextEditingController();

  String _type = AlertChannelTypes.email;
  String _encryption = 'NONE';
  SecretIntent _secretIntent = SecretIntent.keep;
  bool _saving = false;
  bool _testing = false;
  bool _testPassed = false;

  // 自定义 Webhook 编辑状态
  String _preset = 'genericJson';
  String _bodyType = 'json';
  final _bodyTemplateController = TextEditingController();
  final List<AlertPairController> _headers = <AlertPairController>[];
  final List<AlertPairController> _formPairs = <AlertPairController>[];

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final channel = widget.editing;
    if (channel != null) {
      _type = channel.type.isEmpty ? AlertChannelTypes.email : channel.type;
      _displayNameController.text = channel.title;
      _testPassed = true; // 已存在的渠道允许直接保存
    } else {
      _displayNameController.text =
          'channel-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _senderController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _recipientController.dispose();
    _webhookUrlController.dispose();
    _bodyTemplateController.dispose();
    for (final pair in <AlertPairController>[..._headers, ..._formPairs]) {
      pair.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppFormPanel(
      title: _isEditing ? l10n.commonEdit : l10n.alertChannelCreateAction,
      isSaving: _saving,
      confirmLabel: l10n.commonSave,
      onConfirm: _save,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!_isEditing)
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.alertRuleTypeLabel),
              items: <DropdownMenuItem<String>>[
                for (final type in AlertChannelTypes.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(AlertChannelTypes.label(l10n, type)),
                  ),
              ],
              onChanged: (value) => setState(() {
                _type = value ?? AlertChannelTypes.email;
                _testPassed = false;
              }),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _displayNameController,
            decoration:
                InputDecoration(labelText: l10n.alertChannelDisplayNameLabel),
          ),
          if (AlertChannelTypes.isEmail(_type)) ..._emailFields(context),
          if (AlertChannelTypes.isWebhook(_type) && _type != AlertChannelTypes.custom)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: _webhookUrlController,
                decoration: InputDecoration(
                  labelText: l10n.alertChannelWebhookUrlLabel,
                ),
                onChanged: (_) => setState(() => _testPassed = false),
              ),
            ),
          if (_type == AlertChannelTypes.custom)
            _customWebhookFields(context),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _testing || _saving ? null : _test,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: Text(l10n.alertChannelTestAction),
              ),
              const SizedBox(width: 12),
              if (_testPassed)
                Row(
                  children: <Widget>[
                    Icon(Icons.check_circle,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(l10n.alertChannelTestPassedHint,
                        style: theme.textTheme.bodySmall),
                  ],
                )
              else
                Text(
                  l10n.alertChannelTestRequired,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _emailFields(BuildContext context) {
    final l10n = context.l10n;
    return <Widget>[
      const SizedBox(height: 12),
      TextField(
        controller: _senderController,
        decoration: InputDecoration(labelText: l10n.alertChannelSenderLabel),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _userNameController,
        decoration: InputDecoration(labelText: l10n.alertChannelUsernameLabel),
      ),
      const SizedBox(height: 12),
      _PasswordField(
        controller: _passwordController,
        intent: _secretIntent,
        enabled: _isEditing,
        onIntentChanged: (intent) => setState(() => _secretIntent = intent),
        label: l10n.alertChannelPasswordLabel,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _hostController,
        decoration: InputDecoration(
          labelText: l10n.alertChannelHostLabel,
          hintText: 'smtp.qq.com',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _portController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: l10n.alertChannelPortLabel),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _encryption,
        decoration:
            InputDecoration(labelText: l10n.alertChannelEncryptionLabel),
        items: <DropdownMenuItem<String>>[
          DropdownMenuItem(
            value: 'NONE',
            child: Text(l10n.alertChannelEncryptionNone),
          ),
          DropdownMenuItem(
            value: 'SSL',
            child: Text(l10n.alertChannelEncryptionSsl),
          ),
          DropdownMenuItem(
            value: 'TLS',
            child: Text(l10n.alertChannelEncryptionTls),
          ),
        ],
        onChanged: (value) => setState(() => _encryption = value ?? 'NONE'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _recipientController,
        decoration: InputDecoration(
          labelText: l10n.alertChannelRecipientLabel,
          helperText: l10n.alertChannelRecipientHint,
        ),
      ),
    ];
  }

  Widget _customWebhookFields(BuildContext context) {
    return AlertCustomWebhookEditor(
      preset: _preset,
      bodyType: _bodyType,
      urlController: _webhookUrlController,
      templateController: _bodyTemplateController,
      headers: _headers,
      formPairs: _formPairs,
      onPresetChanged: (preset) => setState(() {
        _preset = preset;
        _testPassed = false;
        final template = AlertWebhookPresets.template(preset);
        if (template != null) {
          _bodyTemplateController.text = template;
        }
      }),
      onBodyTypeChanged: (type) => setState(() {
        _bodyType = type;
        _testPassed = false;
      }),
      onAddHeader: () => setState(
          () => _headers.add(AlertPairController())),
      onRemoveHeader: (index) => setState(() {
        _headers[index].dispose();
        _headers.removeAt(index);
        _testPassed = false;
      }),
      onAddPair: () => setState(
          () => _formPairs.add(AlertPairController())),
      onRemovePair: (index) => setState(() {
        _formPairs[index].dispose();
        _formPairs.removeAt(index);
        _testPassed = false;
      }),
      onTemplateChanged: () => setState(() => _testPassed = false),
      onUrlChanged: () => setState(() => _testPassed = false),
    );
  }

  /// 组装渠道配置：邮箱为 SMTP 字段，Webhook 类为地址与模板。
  Map<String, dynamic> _buildConfig() {
    if (AlertChannelTypes.isEmail(_type)) {
      final password = _passwordController.text;
      final config = <String, dynamic>{
        'displayName': _displayNameController.text.trim(),
        'sender': _senderController.text.trim(),
        'userName': _userNameController.text.trim(),
        'host': _hostController.text.trim(),
        'port': int.tryParse(_portController.text.trim()) ?? 465,
        'encryption': _encryption,
        'recipient': _recipientController.text.trim(),
      };
      if (_isEditing) {
        config['passwordAction'] = _secretIntent.name;
        if (_secretIntent == SecretIntent.replace) {
          config['password'] = password;
        }
      } else {
        config['password'] = password;
      }
      return config;
    }
    if (_type == AlertChannelTypes.custom) {
      return <String, dynamic>{
        'preset': _preset,
        'url': _webhookUrlController.text.trim(),
        'body': <String, dynamic>{
          'type': _bodyType,
          if (_bodyType == 'json' || _bodyType == 'text')
            'template': _bodyTemplateController.text,
          if (_bodyType == 'form')
            'pairs': <Map<String, String>>[
              for (final pair in _formPairs)
                if (pair.key.isNotEmpty)
                  <String, String>{'key': pair.key, 'value': pair.value},
            ],
        },
        'headers': <Map<String, String>>[
          for (final header in _headers)
            if (header.key.isNotEmpty)
              <String, String>{'key': header.key, 'value': header.value},
        ],
      };
    }
    return <String, dynamic>{
      'url': _webhookUrlController.text.trim(),
    };
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_testPassed && AlertChannelTypes.supportsTest(_type)) {
      SnackBarUtils.showError(context, l10n.alertChannelTestRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AlertProvider>().saveChannel(AlertConfigUpdate(
        id: widget.editing?.id ?? 0,
        type: _type,
        title: _displayNameController.text.trim(),
        config: jsonEncode(_buildConfig()),
        status: widget.editing?.status ?? 'Enable',
        displayName: _displayNameController.text.trim(),
      ));
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }

  Future<void> _test() async {
    final l10n = context.l10n;
    setState(() => _testing = true);
    try {
      final provider = context.read<AlertProvider>();
      final result = await provider.testChannel(_testRequest());
      if (!mounted) return;
      setState(() {
        _testPassed = result.success;
        _testing = false;
      });
      if (result.success) {
        SnackBarUtils.showSuccess(context, l10n.alertChannelTestSuccess);
      } else {
        SnackBarUtils.showError(
          context,
          result.message ?? l10n.alertChannelTestFailed,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _testPassed = false;
        _testing = false;
      });
      SnackBarUtils.showError(context, error.toString());
    }
  }

  AlertConfigTest _testRequest() {
    if (AlertChannelTypes.isEmail(_type)) {
      return AlertConfigTest(
        type: _type,
        displayName: _displayNameController.text.trim(),
        sender: _senderController.text.trim(),
        userName: _userNameController.text.trim(),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
        host: _hostController.text.trim(),
        port: int.tryParse(_portController.text.trim()),
        encryption: _encryption,
        recipient: _recipientController.text.trim(),
      );
    }
    return AlertConfigTest(
      type: _type,
      config: jsonEncode(_buildConfig()),
      id: widget.editing?.id,
      displayName: _displayNameController.text.trim(),
    );
  }
}

/// 密钥字段三态选择：编辑时出现，避免把已有密码读回客户端。
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.intent,
    required this.enabled,
    required this.onIntentChanged,
    required this.label,
  });

  final TextEditingController controller;
  final SecretIntent intent;
  final bool enabled;
  final ValueChanged<SecretIntent> onIntentChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!enabled) {
      return TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(labelText: label),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<SecretIntent>(
          segments: <ButtonSegment<SecretIntent>>[
            ButtonSegment(
              value: SecretIntent.keep,
              label: Text(l10n.alertChannelPasswordKeep),
            ),
            ButtonSegment(
              value: SecretIntent.replace,
              label: Text(l10n.alertChannelPasswordReplace),
            ),
            ButtonSegment(
              value: SecretIntent.clear,
              label: Text(l10n.alertChannelPasswordClear),
            ),
          ],
          selected: <SecretIntent>{intent},
          onSelectionChanged: (values) => onIntentChanged(values.first),
        ),
        if (intent == SecretIntent.replace) ...[
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(labelText: label),
          ),
        ],
      ],
    );
  }
}

/// Header 或 Form 键值对的行模型由 [AlertPairController] 承担。
