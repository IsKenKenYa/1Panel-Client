import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class VolumeCard extends StatelessWidget {
  final DockerVolume volume;

  const VolumeCard({super.key, required this.volume});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<VolumeProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    volume.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Driver: ${volume.driver}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (volume.mountpoint != null)
                    Text(
                      'Mountpoint: ${volume.mountpoint}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.commonDelete),
                    content: Text(l10n.commonDeleteConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.commonCancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.commonConfirm),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await provider.removeVolume(volume.name);
                }
              },
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
