import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/image_card_dialogs.dart';
import 'package:provider/provider.dart';

class ImageCard extends StatelessWidget {
  const ImageCard({super.key, required this.image});

  final DockerImage image;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<DockerImageProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        image.tags.isNotEmpty ? image.tags.first : image.id,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.orchestrationImageSizeLabel}: ${(image.size / 1024 / 1024).toStringAsFixed(2)} ${l10n.commonMegabyte}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${l10n.orchestrationImageCreatedLabel}: ${image.created}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ImageCardDialogs.showDetailsSheet(context, image: image),
                  icon: const Icon(Icons.info_outline),
                  tooltip: l10n.commonMore,
                ),
                IconButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => ImageCardDialogs.confirmDelete(
                            context,
                            provider,
                            image: image,
                          ),
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.commonMore,
                  onSelected: (value) {
                    if (value == 'tag') {
                      ImageCardDialogs.showTagDialog(
                        context,
                        provider,
                        image: image,
                      );
                    }
                    if (value == 'push') {
                      ImageCardDialogs.showPushDialog(
                        context,
                        provider,
                        image: image,
                      );
                    }
                    if (value == 'save') {
                      ImageCardDialogs.showSaveDialog(
                        context,
                        provider,
                        image: image,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'tag',
                      child: Text(l10n.containerActionTag),
                    ),
                    PopupMenuItem(
                      value: 'push',
                      child: Text(l10n.containerActionPush),
                    ),
                    PopupMenuItem(
                      value: 'save',
                      child: Text(l10n.containerActionSave),
                    ),
                  ],
                ),
              ],
            ),
            if (image.tags.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: image.tags
                      .skip(1)
                      .map(
                        (tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 10),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
