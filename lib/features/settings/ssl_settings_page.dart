import 'package:flutter/material.dart';
import 'package:onepanel_client/features/security_gateway/pages/security_gateway_center_page.dart';
import 'package:onepanel_client/features/security_gateway/providers/security_gateway_center_provider.dart';

class SslSettingsPage extends StatelessWidget {
  const SslSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SecurityGatewayCenterPage(
      initialSection: SecurityGatewaySection.panelTls,
    );
  }
}
