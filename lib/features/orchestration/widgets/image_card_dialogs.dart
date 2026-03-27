import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/image_card_actions.dart';
import 'package:onepanel_client/features/orchestration/widgets/image_card_prompts.dart';
import 'package:onepanel_client/features/orchestration/widgets/orchestration_detail_line_widget.dart';

class ImageCardDialogs {
  static Future<void> showDetailsSheet(
    BuildContext context, {
    required DockerImage image,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ImageCardActions.imageReference(image),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              OrchestrationDetailLineWidget(
                label: 'ID',
                value: image.id,
                labelWidth: 90,
              ),
              OrchestrationDetailLineWidget(
                label: 'Digest',
                value: image.digest,
                labelWidth: 90,
              ),
              OrchestrationDetailLineWidget(
                label: 'Created',
                value: image.created,
                labelWidth: 90,
              ),
              OrchestrationDetailLineWidget(
                label: 'Size',
                value: '${image.size} B',
                labelWidth: 90,
              ),
              if (image.tags.isNotEmpty)
                OrchestrationDetailLineWidget(
                  label: 'Tags',
                  value: image.tags.join(', '),
                  labelWidth: 90,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showTagDialog(
    BuildContext context,
    DockerImageProvider provider, {
    required DockerImage image,
  }) async {
    final l10n = context.l10n;
    final value = await ImageCardPrompts.showTextInputDialog(
      context,
      title: l10n.containerActionTag,
      label: l10n.containerTagLabel,
    );

    if (value == null || value.trim().isEmpty || !context.mounted) return;

    final targetRef = value.trim();
    final sourceImage = ImageCardActions.imageReference(image);
    await ImageCardActions.runAction(
      context,
      provider,
      () => provider.tagImage(
        ImageTag(
          sourceImage: sourceImage,
          targetImage: ImageCardActions.imageName(targetRef),
          tag: ImageCardActions.imageTag(targetRef),
        ),
      ),
    );
  }

  static Future<void> showPushDialog(
    BuildContext context,
    DockerImageProvider provider, {
    required DockerImage image,
  }) async {
    final l10n = context.l10n;
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

    if (confirm != true || !context.mounted) return;

    final imageRef = ImageCardActions.imageReference(image);

    await ImageCardActions.runAction(
      context,
      provider,
      () => provider.pushImage(
        ImagePush(
          image: ImageCardActions.imageName(imageRef),
          tag: ImageCardActions.imageTag(imageRef),
        ),
      ),
    );
  }

  static Future<void> showSaveDialog(
    BuildContext context,
    DockerImageProvider provider, {
    required DockerImage image,
  }) async {
    final l10n = context.l10n;
    final value = await ImageCardPrompts.showTextInputDialog(
      context,
      title: l10n.containerActionSave,
      label: l10n.containerSavePath,
    );

    if (value == null || value.trim().isEmpty || !context.mounted) return;

    final imageRef = ImageCardActions.imageReference(image);
    await ImageCardActions.runAction(
      context,
      provider,
      () => provider.saveImage(
        ImageSave(images: [imageRef], filePath: value.trim()),
      ),
    );
  }

  static Future<void> confirmDelete(
    BuildContext context,
    DockerImageProvider provider, {
    required DockerImage image,
  }) async {
    final force = await ImageCardPrompts.showDeleteDialog(context);
    if (force == null || !context.mounted) return;
    await ImageCardActions.runAction(
      context,
      provider,
      () => provider.removeImage(image.id, force: force),
    );
  }
}
