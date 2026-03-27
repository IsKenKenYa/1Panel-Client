import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/websites_provider.dart';
import 'website_list_page_body.dart';

class WebsitesPage extends StatelessWidget {
  const WebsitesPage({
    super.key,
    this.provider,
  });

  final WebsitesProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => provider ?? WebsitesProvider(),
      child: const WebsiteListPageBody(),
    );
  }
}
