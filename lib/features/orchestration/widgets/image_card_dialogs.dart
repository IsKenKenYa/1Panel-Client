import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_sheet.dart';
import 'package:intl/intl.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/image_card_actions.dart';
import 'package:onepanel_client/features/orchestration/widgets/image_card_prompts.dart';
import 'package:onepanel_client/features/orchestration/widgets/orchestration_detail_line_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

class ImageCardDialogs {
  /// 创建时间本地化短格式；无法解析时回退原始串（created 可能为空）。
  static String createdLabel(DockerImage image) {
    final parsed = image.createdDateTime;
    if (parsed == null) {
      return image.created.isEmpty ? '-' : image.created;
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal());
  }

  static Future<void> showDetailsSheet(
    BuildContext context, {
    required DockerImage image,
  }) async {
    final l10n = context.l10n;
    await showAppDetailsSheet(
      context,
      title: ImageCardActions.imageReference(image),
      children: [
        OrchestrationDetailLineWidget(
          label: l10n.orchestrationImageId, value: image.id, labelWidth: 90,
        ),
        OrchestrationDetailLineWidget(
          label: l10n.orchestrationImageDigest, value: image.digest, labelWidth: 90,
        ),
        OrchestrationDetailLineWidget(
          label: l10n.orchestrationImageCreatedLabel, value: createdLabel(image), labelWidth: 90,
        ),
        OrchestrationDetailLineWidget(
          label: l10n.orchestrationImageSizeLabel, value: '${image.size} B', labelWidth: 90,
        ),
        if (image.tags.isNotEmpty)
          OrchestrationDetailLineWidget(
            label: l10n.orchestrationImageTags, value: image.tags.join(', '), labelWidth: 90,
          ),
      ],
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
    final confirm = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.containerActionPush,
      message: l10n.containerPushConfirm,
      confirmLabel: l10n.commonConfirm,
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
