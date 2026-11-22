import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/data/models/container_image_models.dart';

/// Image build/push/save/tag operations page.
/// Mirrors frontend's container image operations.
class ImageOperationsPage extends StatefulWidget {
  const ImageOperationsPage({super.key});

  @override
  State<ImageOperationsPage> createState() => _ImageOperationsPageState();
}

class _ImageOperationsPageState extends State<ImageOperationsPage> {
  final _tagNameController = TextEditingController();
  final _pushNameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _targetController = TextEditingController();
  bool _isPushing = false;
  bool _isSaving = false;
  bool _isTagging = false;

  @override
  void dispose() {
    _tagNameController.dispose();
    _pushNameController.dispose();
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<ContainerV2Api> _getApi() async {
    return ContainerV2Api(await ApiClientManager.instance.getCurrentClient());
  }

  Future<void> _pushImage() async {
    if (_pushNameController.text.isEmpty) return;
    setState(() => _isPushing = true);
    try {
      final api = await _getApi();
      await api.pushImage(ImagePush(image: _pushNameController.text));
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.imageOpsPushStarted);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.imageOpsPushFailed);
    } finally {
      if (mounted) setState(() => _isPushing = false);
    }
  }

  Future<void> _saveImage() async {
    if (_tagNameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final api = await _getApi();
      await api.saveImage(ImageSave(images: [_tagNameController.text], filePath: '/tmp/${_tagNameController.text}.tar'));
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.imageOpsImageSaved);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.commonSaveFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _tagImage() async {
    if (_sourceController.text.isEmpty || _targetController.text.isEmpty) return;
    setState(() => _isTagging = true);
    try {
      final api = await _getApi();
      await api.tagImage(ImageTag(
        sourceImage: _sourceController.text,
        targetImage: _targetController.text,
      ));
      if (mounted) SnackBarUtils.showSuccess(context, context.l10n.imageOpsTagged);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, context.l10n.imageOpsTagFailed);
    } finally {
      if (mounted) setState(() => _isTagging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title:  Text(context.l10n.imageOpsTitle)),
      body: ListView(
        padding: AppDesignTokens.cardPadding,
        children: [
          // Push
          Card(
            child: Padding(
              padding: AppDesignTokens.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.imageOpsPushImage, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pushNameController,
                    decoration:  InputDecoration(
                      labelText: context.l10n.imageOpsImageNameHint,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _isPushing ? null : _pushImage,
                    icon: _isPushing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload),
                    label:  Text(context.l10n.imageOpsPush),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Save
          Card(
            child: Padding(
              padding: AppDesignTokens.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.imageOpsSaveImage, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tagNameController,
                    decoration:  InputDecoration(
                      labelText: context.l10n.imageOpsImageName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _isSaving ? null : _saveImage,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label:  Text(context.l10n.commonSave),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tag
          Card(
            child: Padding(
              padding: AppDesignTokens.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.imageOpsTagImage, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sourceController,
                    decoration:  InputDecoration(
                      labelText: context.l10n.imageOpsSourceImage,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetController,
                    decoration:  InputDecoration(
                      labelText: context.l10n.imageOpsTargetTag,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _isTagging ? null : _tagImage,
                    icon: _isTagging
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.label),
                    label:  Text(context.l10n.imageOpsTag),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
