import 'package:flutter/material.dart';
import 'package:onepanel_client/features/backups/pages/backup_accounts_page.dart';
import 'package:onepanel_client/features/backups/providers/backup_accounts_provider.dart';
import 'package:provider/provider.dart';

/// 设置页入口包装：复用 backups 模块的分层实现，避免页面直接调用 API。
class BackupAccountPage extends StatelessWidget {
  const BackupAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BackupAccountsProvider>(
      create: (_) => BackupAccountsProvider(),
      child: const BackupAccountsPage(),
    );
  }
}
