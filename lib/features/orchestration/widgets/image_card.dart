import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/data/models/docker_models.dart';
import 'package:onepanelapp_app/features/orchestration/providers/image_provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';

class ImageCard extends StatelessWidget {
  final DockerImage image;

  const ImageCard({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = context.read<DockerImageProvider>();
    Future<void> showTagDialog() async {
      final controller = TextEditingController();
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.containerActionTag),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.containerTagLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (value != null && value.isNotEmpty) {
        String targetImage = value;
        String? tag;
        if (value.contains(':')) {
          final parts = value.split(':');
          targetImage = parts.first;
          tag = parts.sublist(1).join(':');
        }
        final sourceImage = image.tags.isNotEmpty ? image.tags.first : image.id;
        await provider.tagImage(ImageTag(
          sourceImage: sourceImage,
          targetImage: targetImage,
          tag: tag,
        ));
      }
    }

    Future<void> showPushDialog() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.containerActionPush),
          content: Text(l10n.containerPushConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (confirm == true) {
        String targetImage = image.tags.isNotEmpty ? image.tags.first : image.id;
        String? tag;
        if (targetImage.contains(':')) {
          final parts = targetImage.split(':');
          targetImage = parts.first;
          tag = parts.sublist(1).join(':');
        }
        await provider.pushImage(ImagePush(image: targetImage, tag: tag));
      }
    }

    Future<void> showSaveDialog() async {
      final controller = TextEditingController();
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.containerActionSave),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.containerSavePath,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (value != null && value.isNotEmpty) {
        final imageRef = image.tags.isNotEmpty ? image.tags.first : image.id;
        await provider.saveImage(ImageSave(images: [imageRef], filePath: value));
      }
    }

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
                      if (image.tags.isNotEmpty)
                        Text(
                          image.tags.first,
                          style: theme.textTheme.titleMedium,
                        )
                      else
                        Text(
                          image.id.substring(0, 12),
                          style: theme.textTheme.titleMedium,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          await provider.removeImage(image.id);
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      color: theme.colorScheme.error,
                    ),
                    PopupMenuButton<String>(
                      tooltip: l10n.commonMore,
                      onSelected: (value) {
                        if (value == 'tag') showTagDialog();
                        if (value == 'push') showPushDialog();
                        if (value == 'save') showSaveDialog();
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
              ],
            ),
            if (image.tags.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: image.tags.skip(1).map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
