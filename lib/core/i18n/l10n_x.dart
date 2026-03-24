import 'package:flutter/widgets.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

export 'package:onepanel_client/l10n/generated/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
