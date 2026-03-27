import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_draft.dart';

class CronjobFormScheduleSectionWidget extends StatelessWidget {
  const CronjobFormScheduleSectionWidget({
    super.key,
    required this.useRawSpec,
    required this.rawSpecs,
    required this.schedule,
    required this.isPreviewLoading,
    required this.previewItems,
    required this.onToggleRawSpec,
    required this.onRawSpecChanged,
    required this.onAddRawSpec,
    required this.onRemoveRawSpec,
    required this.onScheduleChanged,
    required this.onPreview,
    required this.customSpecLabel,
    required this.previewLabel,
    required this.builderModeLabel,
    required this.rawModeLabel,
  });

  final bool useRawSpec;
  final List<String> rawSpecs;
  final CronjobScheduleBuilder schedule;
  final bool isPreviewLoading;
  final List<String> previewItems;
  final ValueChanged<bool> onToggleRawSpec;
  final void Function(int index, String value) onRawSpecChanged;
  final VoidCallback onAddRawSpec;
  final void Function(int index) onRemoveRawSpec;
  final ValueChanged<CronjobScheduleBuilder> onScheduleChanged;
  final VoidCallback onPreview;
  final String customSpecLabel;
  final String previewLabel;
  final String builderModeLabel;
  final String rawModeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: <Widget>[
        SwitchListTile(
          value: useRawSpec,
          onChanged: onToggleRawSpec,
          contentPadding: EdgeInsets.zero,
          title: Text(customSpecLabel),
          subtitle: Text(useRawSpec ? rawModeLabel : builderModeLabel),
        ),
        const SizedBox(height: 8),
        if (useRawSpec) ...<Widget>[
          for (var index = 0; index < rawSpecs.length; index++) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: ValueKey<String>(
                        'cronjob-spec-$index-${rawSpecs[index]}'),
                    initialValue: rawSpecs[index],
                    onChanged: (value) => onRawSpecChanged(index, value),
                    decoration: InputDecoration(
                      labelText: l10n.cronjobFormCustomSpecItemLabel(index + 1),
                    ),
                  ),
                ),
                if (rawSpecs.length > 1)
                  IconButton(
                    onPressed: () => onRemoveRawSpec(index),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddRawSpec,
              icon: const Icon(Icons.add),
              label: Text(customSpecLabel),
            ),
          ),
        ] else ...<Widget>[
          DropdownButtonFormField<String>(
            initialValue: schedule.mode,
            decoration:
                InputDecoration(labelText: l10n.cronjobFormScheduleModeLabel),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(
                  value: 'daily', child: Text(l10n.cronjobFormScheduleDaily)),
              DropdownMenuItem(
                  value: 'weekly', child: Text(l10n.cronjobFormScheduleWeekly)),
              DropdownMenuItem(
                  value: 'monthly',
                  child: Text(l10n.cronjobFormScheduleMonthly)),
              DropdownMenuItem(
                  value: 'every_hours',
                  child: Text(l10n.cronjobFormScheduleEveryHours)),
              DropdownMenuItem(
                  value: 'every_minutes',
                  child: Text(l10n.cronjobFormScheduleEveryMinutes)),
            ],
            onChanged: (value) {
              if (value == null) return;
              onScheduleChanged(schedule.copyWith(mode: value));
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              SizedBox(
                width: 120,
                child: TextFormField(
                  key: ValueKey<String>('schedule-minute-${schedule.minute}'),
                  initialValue: schedule.minute.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => onScheduleChanged(
                    schedule.copyWith(minute: int.tryParse(value) ?? 0),
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.cronjobFormScheduleMinuteLabel,
                  ),
                ),
              ),
              if (schedule.mode != 'every_minutes')
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    key: ValueKey<String>('schedule-hour-${schedule.hour}'),
                    initialValue: schedule.hour.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => onScheduleChanged(
                      schedule.copyWith(hour: int.tryParse(value) ?? 0),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.cronjobFormScheduleHourLabel,
                    ),
                  ),
                ),
              if (schedule.mode == 'weekly')
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    key:
                        ValueKey<String>('schedule-week-${schedule.dayOfWeek}'),
                    initialValue: schedule.dayOfWeek.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => onScheduleChanged(
                      schedule.copyWith(dayOfWeek: int.tryParse(value) ?? 1),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.cronjobFormScheduleWeekdayLabel,
                    ),
                  ),
                ),
              if (schedule.mode == 'monthly')
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    key:
                        ValueKey<String>('schedule-day-${schedule.dayOfMonth}'),
                    initialValue: schedule.dayOfMonth.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => onScheduleChanged(
                      schedule.copyWith(dayOfMonth: int.tryParse(value) ?? 1),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.cronjobFormScheduleDayLabel,
                    ),
                  ),
                ),
              if (schedule.mode == 'every_hours' ||
                  schedule.mode == 'every_minutes')
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    key: ValueKey<String>(
                        'schedule-interval-${schedule.interval}'),
                    initialValue: schedule.interval.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => onScheduleChanged(
                      schedule.copyWith(interval: int.tryParse(value) ?? 1),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.cronjobFormScheduleIntervalLabel,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: isPreviewLoading ? null : onPreview,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(previewLabel),
          ),
        ),
        if (previewItems.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: previewItems
                .map((item) => Chip(label: Text(item)))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
