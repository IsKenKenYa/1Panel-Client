import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';

class ImageCardActions {
  static String imageReference(DockerImage image) {
    return image.tags.isNotEmpty ? image.tags.first : image.id;
  }

  static String imageName(String imageRef) {
    if (!imageRef.contains(':')) return imageRef;
    return imageRef.split(':').first;
  }

  static String? imageTag(String imageRef) {
    if (!imageRef.contains(':')) return null;
    final parts = imageRef.split(':');
    return parts.sublist(1).join(':');
  }

  static Future<void> runAction(
    BuildContext context,
    DockerImageProvider provider,
    Future<bool> Function() action,
  ) async {
    final l10n = context.l10n;
    final success = await action();
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerOperateSuccess)),
      );
      return;
    }

    final error = provider.error ?? l10n.commonUnknownError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.containerOperateFailed(error)),
        action: SnackBarAction(
          label: l10n.commonRetry,
          onPressed: () {
            action();
          },
        ),
      ),
    );
  }
}
