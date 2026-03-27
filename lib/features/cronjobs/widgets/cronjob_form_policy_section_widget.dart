import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class CronjobFormPolicySectionWidget extends StatelessWidget {
  const CronjobFormPolicySectionWidget({
    super.key,
    required this.retainCopies,
    required this.retryTimes,
    required this.timeoutValue,
    required this.timeoutUnit,
    required this.ignoreErr,
    required this.alertEnabled,
    required this.alertCount,
    required this.alertMethods,
    required this.argItems,
    required this.onChanged,
  });

  final int retainCopies;
  final int retryTimes;
  final int timeoutValue;
  final String timeoutUnit;
  final bool ignoreErr;
  final bool alertEnabled;
  final int alertCount;
  final List<String> alertMethods;
  final List<String> argItems;
  final void Function({
    int? retainCopies,
    int? retryTimes,
    int? timeoutValue,
    String? timeoutUnit,
    bool? ignoreErr,
    List<String>? argItems,
    bool? alertEnabled,
    int? alertCount,
    List<String>? alertMethods,
  }) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: 120,
              child: TextFormField(
                key: ValueKey<String>('retain-$retainCopies'),
                initialValue: retainCopies.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    onChanged(retainCopies: int.tryParse(value) ?? 1),
                decoration: InputDecoration(
                  labelText: l10n.cronjobFormRetainCopiesLabel,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: TextFormField(
                key: ValueKey<String>('retry-$retryTimes'),
                initialValue: retryTimes.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    onChanged(retryTimes: int.tryParse(value) ?? 0),
                decoration: InputDecoration(
                  labelText: l10n.cronjobFormRetryTimesLabel,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: TextFormField(
                key: ValueKey<String>('timeout-value-$timeoutValue'),
                initialValue: timeoutValue.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    onChanged(timeoutValue: int.tryParse(value) ?? 3600),
                decoration:
                    InputDecoration(labelText: l10n.cronjobFormTimeoutLabel),
              ),
            ),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                initialValue: timeoutUnit,
                decoration:
                    InputDecoration(labelText: l10n.cronjobFormTimeoutUnitLabel),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                      value: 's', child: Text(l10n.cronjobFormSecondsLabel)),
                  DropdownMenuItem(
                      value: 'm', child: Text(l10n.cronjobFormMinutesLabel)),
                  DropdownMenuItem(
                      value: 'h', child: Text(l10n.cronjobFormHoursLabel)),
                ],
                onChanged: (value) => onChanged(timeoutUnit: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: ignoreErr,
          onChanged: (value) => onChanged(ignoreErr: value),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.cronjobFormIgnoreErrorsLabel),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey<String>('cronjob-args-${argItems.join(",")}'),
          initialValue: argItems.join(','),
          onChanged: (value) => onChanged(
            argItems: value
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false),
          ),
          decoration:
              InputDecoration(labelText: l10n.cronjobFormArgumentsLabel),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: alertEnabled,
          onChanged: (value) => onChanged(alertEnabled: value),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.cronjobFormEnableAlertsLabel),
        ),
        if (alertEnabled) ...<Widget>[
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey<String>('alert-count-$alertCount'),
            initialValue: alertCount.toString(),
            keyboardType: TextInputType.number,
            onChanged: (value) =>
                onChanged(alertCount: int.tryParse(value) ?? 3),
            decoration:
                InputDecoration(labelText: l10n.cronjobFormAlertCountLabel),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <String>['mail', 'weCom', 'dingTalk']
                .map((item) => FilterChip(
                      label: Text(item),
                      selected: alertMethods.contains(item),
                      onSelected: (value) {
                        final next = List<String>.from(alertMethods);
                        if (value) {
                          next.add(item);
                        } else {
                          next.remove(item);
                        }
                        onChanged(
                          alertMethods: next.toSet().toList(growable: false),
                        );
                      },
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
