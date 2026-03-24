import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/image_card.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DockerImageProvider>().loadImages();
    });
  }

  // _showPullDialog removed

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<DockerImageProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.images.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.commonLoadFailedTitle),
                Text(provider.error!),
                ElevatedButton(
                  onPressed: () => provider.loadImages(),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        if (provider.images.isEmpty) {
          return Center(child: Text(l10n.commonEmpty));
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadImages(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.images.length,
            itemBuilder: (context, index) {
              final image = provider.images[index];
              return ImageCard(image: image);
            },
          ),
        );
      },
    );
  }
}
