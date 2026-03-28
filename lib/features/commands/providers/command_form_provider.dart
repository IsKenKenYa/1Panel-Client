import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/commands/models/command_form_args.dart';
import 'package:onepanel_client/features/commands/services/command_service.dart';

class CommandFormProvider extends ChangeNotifier with AsyncStateNotifier {
  CommandFormProvider({
    CommandService? service,
  }) : _service = service ?? CommandService();

  final CommandService _service;

  List<GroupInfo> _groups = const <GroupInfo>[];
  int? _commandId;
  String _name = '';
  String _command = '';
  int? _selectedGroupId;
  bool _isSaving = false;

  List<GroupInfo> get groups => _groups;
  int? get selectedGroupId => _selectedGroupId;
  String get name => _name;
  String get command => _command;
  bool get isSaving => _isSaving;
  bool get isEditing => _commandId != null;
  bool get canSave =>
      _name.trim().isNotEmpty &&
      _command.trim().isNotEmpty &&
      _selectedGroupId != null &&
      !_isSaving;

  Future<void> initialize(CommandFormArgs? args) async {
    final initial = args?.initialValue;
    _commandId = initial?.id;
    _name = initial?.name ?? '';
    _command = initial?.command ?? '';
    _selectedGroupId = initial?.groupID;

    setLoading();
    try {
      _groups = await _service.loadGroups();
      if (_groups.isNotEmpty) {
        _selectedGroupId ??= _groups
            .firstWhere(
              (group) => group.isDefault == true,
              orElse: () => _groups.first,
            )
            .id;
      }
      setSuccess(isEmpty: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.commands.providers.form',
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    }
  }

  void updateName(String value) {
    _name = value;
    notifyListeners();
  }

  void updateCommand(String value) {
    _command = value;
    notifyListeners();
  }

  void updateGroupId(int? value) {
    _selectedGroupId = value;
    notifyListeners();
  }

  Future<bool> save() async {
    if (!canSave) {
      return false;
    }

    _isSaving = true;
    clearError(notify: false);
    notifyListeners();
    try {
      final group = _groups.firstWhere(
        (item) => item.id == _selectedGroupId,
        orElse: () => throw Exception('Group not found'),
      );
      final request = CommandOperate(
        id: _commandId,
        name: _name.trim(),
        command: _command.trim(),
        type: 'command',
        groupID: _selectedGroupId,
        groupBelong: group.name,
      );
      if (isEditing) {
        await _service.updateCommand(request);
      } else {
        await _service.createCommand(request);
      }
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.commands.providers.form',
        'save failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
