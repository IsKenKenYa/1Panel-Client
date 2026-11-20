import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/features/alert/alert_types.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';

/// 告警任务创建/编辑表单。
Future<void> showAlertRuleForm(BuildContext context, {AlertInfo? editing}) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (_) => AlertRuleForm(editing: editing),
  );
}

class AlertRuleForm extends StatefulWidget {
  const AlertRuleForm({super.key, this.editing});

  final AlertInfo? editing;

  @override
  State<AlertRuleForm> createState() => _AlertRuleFormState();
}

class _AlertRuleFormState extends State<AlertRuleForm> {
  final _titleController = TextEditingController();
  final _cycleController = TextEditingController(text: '30');
  final _thresholdController = TextEditingController(text: '80');
  final _sendCountController = TextEditingController(text: '1');
  final _advancedParamsController = TextEditingController();

  String _type = AlertRuleTypes.cpu;
  String _triggerMode = 'failed';
  int _interval = 1;
  String? _thresholdUnit = 'percent';
  String? _taskName;
  final Set<String> _methods = <String>{};
  bool _saving = false;
  bool _optionsLoaded = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final rule = widget.editing;
    if (rule != null) {
      _titleController.text = rule.title;
      _type = rule.type.isEmpty ? AlertRuleTypes.cpu : rule.type;
      _cycleController.text = '${rule.cycle}';
      if (rule.count > 0) _thresholdController.text = '${rule.count}';
      _sendCountController.text = '${rule.sendCount}';
      _advancedParamsController.text = rule.advancedParams;
      _interval = rule.interval <= 0 ? 1 : rule.interval;
      _triggerMode = rule.alertTriggerMode ?? 'failed';
      _taskName = rule.taskName;
      _methods.addAll(rule.sendMethod);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  Future<void> _loadOptions() async {
    await context.read<AlertProvider>().loadTargetOptions();
    if (!mounted) return;
    setState(() => _optionsLoaded = true);
    final provider = context.read<AlertProvider>();
    // 新建时默认选中第一个可用渠道，减少一次手动操作。
    if (_methods.isEmpty && provider.enabledChannels.isNotEmpty) {
      setState(() => _methods.add(provider.enabledChannels.first.title));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cycleController.dispose();
    _thresholdController.dispose();
    _sendCountController.dispose();
    _advancedParamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<AlertProvider>();
    final channels = provider.channels;

    return AppFormPanel(
      title: _isEditing ? l10n.commonEdit : l10n.alertRuleCreateAction,
      isSaving: _saving,
      confirmLabel: l10n.commonSave,
      onConfirm: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: l10n.alertRuleTitleLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l10n.alertRuleTypeLabel),
            items: <DropdownMenuItem<String>>[
              for (final type in AlertRuleTypes.values)
                DropdownMenuItem(
                  value: type,
                  child: Text(AlertTypeLabels.label(l10n, type)),
                ),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          if (AlertRuleTypes.needsCycleDays(_type)) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _cycleController,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: l10n.alertRuleCycleDaysLabel),
            ),
          ],
          if (AlertRuleTypes.needsThreshold(_type)) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: l10n.alertRuleThresholdLabel),
            ),
            if (_type == AlertRuleTypes.disk) ...[
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: <ButtonSegment<String>>[
                  ButtonSegment(
                    value: 'percent',
                    label: Text(l10n.alertRuleThresholdUnitPercent),
                  ),
                  ButtonSegment(
                    value: 'gb',
                    label: Text(l10n.alertRuleThresholdUnitGb),
                  ),
                ],
                selected: <String>{_thresholdUnit ?? 'percent'},
                onSelectionChanged: (values) =>
                    setState(() => _thresholdUnit = values.first),
              ),
            ],
          ],
          if (AlertRuleTypes.needsInterval(_type)) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _interval,
              decoration:
                  InputDecoration(labelText: l10n.alertRuleIntervalLabel),
              items: <DropdownMenuItem<int>>[
                DropdownMenuItem(
                  value: 1,
                  child: Text(l10n.alertRuleIntervalMinute1),
                ),
                DropdownMenuItem(
                  value: 5,
                  child: Text(l10n.alertRuleIntervalMinute5),
                ),
                DropdownMenuItem(
                  value: 15,
                  child: Text(l10n.alertRuleIntervalMinute15),
                ),
              ],
              onChanged: (value) => setState(() => _interval = value ?? 1),
            ),
          ],
          if (AlertRuleTypes.needsDisk(_type) && _optionsLoaded) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: null,
              decoration:
                  InputDecoration(labelText: l10n.alertRuleDiskTargetsLabel),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: '',
                  child: Text(l10n.alertRuleDiskAll),
                ),
                for (final disk in provider.disks)
                  DropdownMenuItem(
                    value: disk.path,
                    child: Text(disk.path),
                  ),
              ],
              onChanged: (_) {},
            ),
          ],
          if (AlertRuleTypes.needsClam(_type) && _optionsLoaded) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: null,
              decoration:
                  InputDecoration(labelText: l10n.alertRuleClamTargetLabel),
              items: <DropdownMenuItem<String>>[
                for (final clam in provider.clams)
                  DropdownMenuItem(
                    value: clam.name,
                    child: Text(clam.name),
                  ),
              ],
              onChanged: (_) {},
            ),
          ],
          if (AlertRuleTypes.needsCronJob(_type) && _optionsLoaded) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _taskName,
              decoration:
                  InputDecoration(labelText: l10n.alertRuleCronjobTaskLabel),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.alertRuleCronjobTaskNone),
                ),
                for (final task in provider.cronJobs)
                  DropdownMenuItem(
                    value: task.name,
                    child: Text(task.name),
                  ),
              ],
              onChanged: (value) => setState(() => _taskName = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _triggerMode,
              decoration:
                  InputDecoration(labelText: l10n.alertRuleCronjobTriggerModeLabel),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: 'failed',
                  child: Text(l10n.alertRuleCronjobTriggerFailed),
                ),
                DropdownMenuItem(
                  value: 'success',
                  child: Text(l10n.alertRuleCronjobTriggerSuccess),
                ),
                DropdownMenuItem(
                  value: 'both',
                  child: Text(l10n.alertRuleCronjobTriggerBoth),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _triggerMode = value ?? 'failed'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _sendCountController,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: l10n.alertRuleSendCountLabel),
          ),
          const SizedBox(height: 16),
          Text(l10n.alertRuleMethodsLabel,
              style: Theme.of(context).textTheme.titleSmall),
          if (channels.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.alertRuleMethodsEmpty,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            Column(
              children: <Widget>[
                for (final channel in channels)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _methods.contains(channel.title),
                    title: Text(
                      channel.title.isEmpty
                          ? channel.type
                          : '${channel.title} (${channel.type})',
                    ),
                    onChanged: channel.status == 'Disable'
                        ? null
                        : (value) => setState(() {
                              if (value == true) {
                                _methods.add(channel.title);
                              } else {
                                _methods.remove(channel.title);
                              }
                            }),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _advancedParamsController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.alertRuleAdvancedParamsLabel,
              helperText: l10n.alertRuleAdvancedParamsHint,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final provider = context.read<AlertProvider>();
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
      return;
    }
    if (_methods.isEmpty) {
      SnackBarUtils.showError(context, l10n.alertRuleMethodsEmpty);
      return;
    }
    setState(() => _saving = true);
    final cycle = int.tryParse(_cycleController.text.trim());
    final threshold = int.tryParse(_thresholdController.text.trim());
    final sendCount = int.tryParse(_sendCountController.text.trim());
    final advancedParams = _advancedParamsController.text.trim();
    final method = _methods.join(',');
    try {
      if (_isEditing) {
        await provider.updateRule(AlertUpdate(
          id: widget.editing!.id,
          type: _type,
          method: method,
          cycle: cycle,
          count: AlertRuleTypes.needsThreshold(_type) ? threshold : null,
          interval: AlertRuleTypes.needsInterval(_type) ? _interval : null,
          status: widget.editing!.status,
          title: title,
          sendCount: sendCount,
          advancedParams:
              advancedParams.isEmpty ? null : advancedParams,
        ));
      } else {
        await provider.createRule(AlertCreate(
          type: _type,
          method: method,
          cycle: AlertRuleTypes.needsCycleDays(_type) ? cycle : null,
          count: AlertRuleTypes.needsThreshold(_type) ? threshold : null,
          interval: AlertRuleTypes.needsInterval(_type) ? _interval : null,
          status: 'Enable',
          title: title,
          sendCount: sendCount,
          advancedParams:
              advancedParams.isEmpty ? null : advancedParams,
        ));
      }
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
}
