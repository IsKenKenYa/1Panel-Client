import 'package:flutter/widgets.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';

Future<bool> saveAppPreference(
  BuildContext context,
  Future<void> Function() save,
) async {
  try {
    await save();
    return true;
  } catch (error, stackTrace) {
    appLogger.eWithPackage(
      'settings.preferences',
      '保存应用设置失败',
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      SnackBarUtils.showErrorWithDebugDetails(
        context,
        context.l10n.commonSaveFailed,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return false;
  }
}
