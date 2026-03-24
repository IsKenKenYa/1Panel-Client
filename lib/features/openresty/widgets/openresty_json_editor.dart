import 'package:flutter/material.dart';

class OpenRestyJsonEditor extends StatefulWidget {
  final String initialText;
  final String saveLabel;
  final String hintText;
  final bool isSaving;
  final Future<void> Function(String value) onSave;

  const OpenRestyJsonEditor({
    super.key,
    required this.initialText,
    required this.saveLabel,
    required this.hintText,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  State<OpenRestyJsonEditor> createState() => _OpenRestyJsonEditorState();
}

class _OpenRestyJsonEditorState extends State<OpenRestyJsonEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant OpenRestyJsonEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText == oldWidget.initialText || _focusNode.hasFocus) {
      return;
    }
    _controller.text = widget.initialText;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.onSave(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: widget.isSaving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(widget.saveLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
