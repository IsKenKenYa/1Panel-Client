import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';

class ContainersPageImageDialogs {
  static Future<void> showPullDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orchestrationPullImage),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.orchestrationPullImageHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      final provider = context.read<DockerImageProvider>();

      String image = result;
      String? tag;
      if (result.contains(':')) {
        final parts = result.split(':');
        image = parts[0];
        tag = parts.sublist(1).join(':');
      }

      final success = await provider.pullImage(image, tag: tag);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.orchestrationPullSuccess
                  : l10n.orchestrationPullFailed,
            ),
          ),
        );
      }
    }
  }

  static Future<void> showBuildImageDialog(BuildContext context) async {
    final l10n = context.l10n;
    final contextController = TextEditingController();
    final dockerfileController = TextEditingController();
    final tagsController = TextEditingController();
    final buildArgsController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orchestrationImageBuild),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contextController,
                decoration: InputDecoration(
                  labelText: l10n.containerBuildContext,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dockerfileController,
                decoration: InputDecoration(
                  labelText: l10n.containerBuildDockerfile,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController,
                decoration: InputDecoration(
                  labelText: l10n.containerBuildTags,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: buildArgsController,
                decoration: InputDecoration(
                  labelText: l10n.containerBuildArgs,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
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

    if (result == true && context.mounted) {
      final provider = context.read<DockerImageProvider>();
      final tags = tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final request = ImageBuild(
        contextDir: contextController.text,
        dockerfile:
            dockerfileController.text.isEmpty ? null : dockerfileController.text,
        tags: tags.isEmpty ? null : tags,
        buildArgs: buildArgsController.text.isEmpty
            ? null
            : buildArgsController.text,
      );
      final success = await provider.buildImage(request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.containerOperateSuccess
                  : l10n.containerOperateFailed(
                      provider.error ?? l10n.commonUnknownError,
                    ),
            ),
          ),
        );
      }
    }
  }

  static Future<void> showLoadImageDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orchestrationImageLoad),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.containerImageLoadPath,
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

    if (result != null && result.isNotEmpty && context.mounted) {
      final provider = context.read<DockerImageProvider>();
      final success = await provider.loadImage(ImageLoad(filePath: result));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.containerOperateSuccess
                  : l10n.containerOperateFailed(
                      provider.error ?? l10n.commonUnknownError,
                    ),
            ),
          ),
        );
      }
    }
  }

  static Future<void> showSearchImageDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final keyword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orchestrationImageSearch),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.commonSearch,
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

    if (keyword == null || keyword.isEmpty || !context.mounted) return;
    final provider = context.read<DockerImageProvider>();
    final result = await provider.searchImages(keyword);
    if (!context.mounted) return;
    final jsonText = const JsonEncoder.withIndent('  ').convert(result.items);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orchestrationImageSearchResult),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(jsonText),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }
}
