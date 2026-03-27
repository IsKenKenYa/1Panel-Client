import 'package:flutter/material.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';

class CronjobRecordCardWidget extends StatelessWidget {
  const CronjobRecordCardWidget({
    super.key,
    required this.item,
    required this.statusLabel,
    required this.onTap,
  });

  final CronjobRecordInfo item;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(item.startTime),
        subtitle: Text('$statusLabel · ${item.message}'),
        trailing: Text(item.interval == 0 ? '-' : '${item.interval} ms'),
      ),
    );
  }
}
