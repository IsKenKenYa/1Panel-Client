import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class HostAssetFormBasicSectionWidget extends StatelessWidget {
  const HostAssetFormBasicSectionWidget({
    super.key,
    required this.nameController,
    required this.addrController,
    required this.portController,
    required this.descriptionController,
    required this.groupLabel,
    required this.onPickGroup,
    required this.onNameChanged,
    required this.onAddrChanged,
    required this.onPortChanged,
    required this.onDescriptionChanged,
  });

  final TextEditingController nameController;
  final TextEditingController addrController;
  final TextEditingController portController;
  final TextEditingController descriptionController;
  final String groupLabel;
  final VoidCallback onPickGroup;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onAddrChanged;
  final ValueChanged<String> onPortChanged;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: nameController,
          onChanged: onNameChanged,
          decoration: InputDecoration(
            labelText: l10n.commonName,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.hostAssetsGroupLabel),
          subtitle: Text(groupLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: onPickGroup,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addrController,
          onChanged: onAddrChanged,
          decoration: InputDecoration(
            labelText: l10n.hostAssetsAddressLabel,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: portController,
          keyboardType: TextInputType.number,
          onChanged: onPortChanged,
          decoration: InputDecoration(
            labelText: l10n.hostAssetsPortLabel,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          onChanged: onDescriptionChanged,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.commonDescription,
          ),
        ),
      ],
    );
  }
}
