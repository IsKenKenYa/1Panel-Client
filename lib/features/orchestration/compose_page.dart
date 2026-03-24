import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/widgets/compose_card.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComposeProvider>().loadComposes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    return Consumer<ComposeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.composes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.composes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.commonLoadFailedTitle),
                Text(provider.error!),
                ElevatedButton(
                  onPressed: () => provider.loadComposes(),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        if (provider.composes.isEmpty) {
          return Center(child: Text(l10n.commonEmpty));
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadComposes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.composes.length,
            itemBuilder: (context, index) {
              final compose = provider.composes[index];
              return ComposeCard(compose: compose);
            },
          ),
        );
      },
    );
  }
}
