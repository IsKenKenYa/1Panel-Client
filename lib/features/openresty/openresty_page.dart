import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/features/openresty/pages/openresty_center_page.dart';
import 'package:onepanelapp_app/features/openresty/providers/openresty_provider.dart';

class OpenRestyPage extends StatelessWidget {
  const OpenRestyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OpenRestyProvider()..loadAll(),
      child: const OpenRestyCenterPage(),
    );
  }
}
