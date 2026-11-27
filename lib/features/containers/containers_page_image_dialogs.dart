import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onepanel_client/features/containers/dialogs/containers_ops_guard.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

/// 镜像操作对话框入口（pull/build/load/search）。
/// 全部写操作经 [ContainersOpsGuard] 互斥，防重复提交。
class ContainersPageImageDialogs {
  static Future<void> showPullDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('image-pull')) return;
    try {
      final l10n = context.l10n;
      final result = await showAppTextInputDialog(
        context,
        title: l10n.orchestrationPullImage,
        hintText: l10n.orchestrationPullImageHint,
        trim: false,
        allowEmpty: true,
      );

      if (result != null && result.isNotEmpty && context.mounted) {
        final provider = context.read<DockerImageProvider>();

        // Image references can contain colons in the tag portion (e.g.,
        // registry.io/image:v1.2.3), so split only on the first ':'.
        String image = result;
        String? tag;
        if (result.contains(':')) {
          final parts = result.split(':');
          image = parts[0];
          tag = parts.sublist(1).join(':');
        }

        final success = await provider.pullImage(image, tag: tag);
        if (context.mounted) {
          if (success) {
            SnackBarUtils.showSuccess(context, l10n.orchestrationPullSuccess);
          } else {
            SnackBarUtils.showError(context, l10n.orchestrationPullFailed);
          }
        }
      }
    } finally {
      ContainersOpsGuard.end('image-pull');
    }
  }

  static Future<void> showBuildImageDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('image-build')) return;
    try {
      final l10n = context.l10n;
      final request = await showAdaptiveFormPanel<ImageBuild>(
        context,
        builder: (_) => const _ImageBuildForm(),
      );

      if (request != null && context.mounted) {
        final provider = context.read<DockerImageProvider>();
        final success = await provider.buildImage(request);
        if (context.mounted) {
          if (success) {
            SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
          } else {
            SnackBarUtils.showError(
              context,
              l10n.containerOperateFailed(
                provider.error ?? l10n.commonUnknownError,
              ),
            );
          }
        }
      }
    } finally {
      ContainersOpsGuard.end('image-build');
    }
  }

  static Future<void> showLoadImageDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('image-load')) return;
    try {
      final l10n = context.l10n;
      final result = await showAppTextInputDialog(
        context,
        title: l10n.orchestrationImageLoad,
        labelText: l10n.containerImageLoadPath,
        autofocus: false,
        trim: false,
        allowEmpty: true,
      );

      if (result != null && result.isNotEmpty && context.mounted) {
        final provider = context.read<DockerImageProvider>();
        final success = await provider.loadImage(ImageLoad(filePath: result));
        if (context.mounted) {
          if (success) {
            SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
          } else {
            SnackBarUtils.showError(
              context,
              l10n.containerOperateFailed(
                provider.error ?? l10n.commonUnknownError,
              ),
            );
          }
        }
      }
    } finally {
      ContainersOpsGuard.end('image-load');
    }
  }

  static Future<void> showSearchImageDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('image-search')) return;
    try {
      final l10n = context.l10n;
      final keyword = await showAppTextInputDialog(
        context,
        title: l10n.orchestrationImageSearch,
        labelText: l10n.commonSearch,
        autofocus: false,
        trim: false,
        allowEmpty: true,
      );

      if (keyword == null || keyword.isEmpty || !context.mounted) return;
      final provider = context.read<DockerImageProvider>();
      final result = await provider.searchImages(keyword);
      if (!context.mounted) return;
      final jsonText = const JsonEncoder.withIndent('  ').convert(result.items);

      await TextPreviewSheet.show(
        context,
        title: l10n.orchestrationImageSearchResult,
        content: jsonText,
      );
    } finally {
      ContainersOpsGuard.end('image-search');
    }
  }
}

class _ImageBuildForm extends StatefulWidget {
  const _ImageBuildForm();

  @override
  State<_ImageBuildForm> createState() => _ImageBuildFormState();
}

class _ImageBuildFormState extends State<_ImageBuildForm> {
  final _contextController = TextEditingController();
  final _dockerfileController = TextEditingController();
  final _tagsController = TextEditingController();
  final _buildArgsController = TextEditingController();

  @override
  void dispose() {
    _contextController.dispose();
    _dockerfileController.dispose();
    _tagsController.dispose();
    _buildArgsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.orchestrationImageBuild,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _contextController,
            decoration: InputDecoration(
              labelText: l10n.containerBuildContext,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dockerfileController,
            decoration: InputDecoration(
              labelText: l10n.containerBuildDockerfile,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: l10n.containerBuildTags,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buildArgsController,
            decoration: InputDecoration(
              labelText: l10n.containerBuildArgs,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      onConfirm: () async {
        final tags = _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        Navigator.of(context).pop(
          ImageBuild(
            contextDir: _contextController.text,
            dockerfile: _dockerfileController.text.isEmpty
                ? null
                : _dockerfileController.text,
            tags: tags.isEmpty ? null : tags,
            buildArgs: _buildArgsController.text.isEmpty
                ? null
                : _buildArgsController.text,
          ),
        );
      },
    );
  }
}
