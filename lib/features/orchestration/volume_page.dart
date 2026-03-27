import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/volume_card.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class VolumePage extends StatefulWidget {
  const VolumePage({super.key});

  @override
  State<VolumePage> createState() => _VolumePageState();
}

class _VolumePageState extends State<VolumePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolumeProvider>().loadVolumes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<VolumeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.volumes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.volumes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.commonLoadFailedTitle),
                Text(provider.error!),
                ElevatedButton(
                  onPressed: () => provider.loadVolumes(),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        if (provider.volumes.isEmpty) {
          return Center(child: Text(l10n.commonEmpty));
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadVolumes(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(l10n.commonLoadFailedTitle),
                      subtitle: Text(provider.error!),
                      trailing: TextButton(
                        onPressed: () => provider.loadVolumes(),
                        child: Text(l10n.commonRetry),
                      ),
                    ),
                  ),
                ),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ...provider.volumes.map((volume) => VolumeCard(volume: volume)),
            ],
          ),
        );
      },
    );
  }
}
