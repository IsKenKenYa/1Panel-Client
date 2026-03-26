import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/process_models.dart';

class ProcessFilterSheetWidget extends StatefulWidget {
  const ProcessFilterSheetWidget({
    super.key,
    required this.initialQuery,
  });

  final ProcessListQuery initialQuery;

  @override
  State<ProcessFilterSheetWidget> createState() =>
      _ProcessFilterSheetWidgetState();
}

class _ProcessFilterSheetWidgetState extends State<ProcessFilterSheetWidget> {
  late final TextEditingController _pidController;
  late final TextEditingController _nameController;
  late final TextEditingController _userController;
  late Set<String> _selectedStatuses;

  @override
  void initState() {
    super.initState();
    _pidController = TextEditingController(
      text: widget.initialQuery.pid?.toString() ?? '',
    );
    _nameController = TextEditingController(text: widget.initialQuery.name);
    _userController = TextEditingController(text: widget.initialQuery.username);
    _selectedStatuses = widget.initialQuery.statuses.toSet();
  }

  @override
  void dispose() {
    _pidController.dispose();
    _nameController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = <({String value, String label})>[
      (value: 'running', label: l10n.processesStatusRunning),
      (value: 'sleep', label: l10n.processesStatusSleep),
      (value: 'stop', label: l10n.processesStatusStop),
      (value: 'idle', label: l10n.processesStatusIdle),
      (value: 'wait', label: l10n.processesStatusWait),
      (value: 'lock', label: l10n.processesStatusLock),
      (value: 'zombie', label: l10n.processesStatusZombie),
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.commonSearch, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _pidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.processesSearchPidLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.processesSearchNameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userController,
                decoration: InputDecoration(labelText: l10n.processesSearchUserLabel),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.processesFilterStatusLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((option) {
                  final selected = _selectedStatuses.contains(option.value);
                  return FilterChip(
                    label: Text(option.label),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedStatuses.add(option.value);
                        } else {
                          _selectedStatuses.remove(option.value);
                        }
                      });
                    },
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      ProcessListQuery(
                        pid: int.tryParse(_pidController.text.trim()),
                        name: _nameController.text.trim(),
                        username: _userController.text.trim(),
                        statuses: _selectedStatuses.toList(growable: false),
                      ),
                    );
                  },
                  child: Text(l10n.commonConfirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
