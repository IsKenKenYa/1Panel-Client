import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/openresty/providers/openresty_provider.dart';

class OpenRestySourceEditorPage extends StatefulWidget {
  final String? initialContent;

  const OpenRestySourceEditorPage({super.key, this.initialContent});

  @override
  State<OpenRestySourceEditorPage> createState() => _OpenRestySourceEditorPageState();
}

class _OpenRestySourceEditorPageState extends State<OpenRestySourceEditorPage> {
  late final TextEditingController _controller;
  bool _didInitFromProvider = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromProvider || widget.initialContent != null) {
      return;
    }
    _controller.text = context.read<OpenRestyProvider>().configContent;
    _didInitFromProvider = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    try {
      await context.read<OpenRestyProvider>().updateConfigSource(_controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonSaveSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSaving = context.watch<OpenRestyProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.openrestyTabConfig),
        actions: [
          IconButton(
            onPressed: isSaving ? null : _save,
            icon: const Icon(Icons.save),
            tooltip: l10n.commonSave,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isSaving) const LinearProgressIndicator(),
            if (isSaving) const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: l10n.openrestyTabConfig,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
