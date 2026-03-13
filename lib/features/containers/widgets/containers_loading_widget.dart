import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';

class ContainersLoadingView extends StatelessWidget {
  const ContainersLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.commonLoading),
        ],
      ),
    );
  }
}
