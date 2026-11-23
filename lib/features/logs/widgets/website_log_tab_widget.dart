import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/data/models/website_log_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/data/repositories/website_config_repository.dart';
import 'package:onepanel_client/features/websites/services/websites_service.dart';

/// Website log viewer tab for the logs center.
/// Mirrors frontend's `log/website` page: website selector + log list.
class WebsiteLogTabWidget extends StatefulWidget {
  const WebsiteLogTabWidget({super.key, this.websiteId});

  /// When provided (e.g. embedded inside a website detail), the selector is
  /// skipped and logs load directly for this website.
  final int? websiteId;

  @override
  State<WebsiteLogTabWidget> createState() => _WebsiteLogTabWidgetState();
}

class _WebsiteLogTabWidgetState extends State<WebsiteLogTabWidget> {
  final WebsiteConfigRepository _repo = WebsiteConfigRepository();
  final WebsitesService _websiteService = WebsitesService();
  WebsiteLogContent _logContent = const WebsiteLogContent();
  List<WebsiteInfo> _websites = [];
  int? _selectedWebsiteId;
  String _logType = 'access.log';
  bool _isLoading = true;
  bool _isLoadingWebsites = false;
  String? _error;

  bool get _standalone => widget.websiteId == null;

  @override
  void initState() {
    super.initState();
    _selectedWebsiteId = widget.websiteId;
    if (_standalone) {
      _loadWebsites();
    } else {
      _load();
    }
  }

  Future<void> _loadWebsites() async {
    setState(() { _isLoadingWebsites = true; _error = null; });
    try {
      final websites = await _websiteService.fetchWebsites();
      if (!mounted) return;
      setState(() {
        _websites = websites;
        _isLoadingWebsites = false;
        _selectedWebsiteId ??= websites.isNotEmpty ? websites.first.id : null;
      });
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMessageUtils.userFacingMessage(e);
          _isLoadingWebsites = false;
        });
      }
    }
  }

  Future<void> _load() async {
    final websiteId = _selectedWebsiteId;
    if (websiteId == null) {
      if (mounted) {
        setState(() {
          _logContent = const WebsiteLogContent();
          _isLoading = false;
        });
      }
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final content = await _repo.loadWebsiteLog(
        websiteId: websiteId,
        logType: _logType,
      );
      if (mounted) {
        setState(() { _logContent = content; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMessageUtils.userFacingMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoadingWebsites) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        if (_standalone)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<int>(
              initialValue: _selectedWebsiteId,
              decoration: InputDecoration(
                labelText: l10n.logsWebsiteSelectorLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: _websites
                  .where((w) => w.id != null)
                  .map((w) => DropdownMenuItem<int>(
                        value: w.id,
                        child: Text(w.alias ?? w.primaryDomain ?? w.id.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null || value == _selectedWebsiteId) return;
                setState(() => _selectedWebsiteId = value);
                _load();
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'access.log', label: Text('access.log')),
              ButtonSegment(value: 'error.log', label: Text('error.log')),
            ],
            selected: {_logType},
            onSelectionChanged: (selection) {
              final type = selection.first;
              if (type == _logType) return;
              setState(() => _logType = type);
              _load();
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _load,
                            child: Text(l10n.commonRetry),
                          ),
                        ],
                      ),
                    )
                  : !_logContent.enable
                      ? Center(child: Text(l10n.websiteLogEmpty))
                      : _logContent.lines.isEmpty
                          ? Center(child: Text(l10n.websiteLogEmpty))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                itemCount: _logContent.lines.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                      _logContent.lines[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                    dense: true,
                                  );
                                },
                              ),
                            ),
        ),
      ],
    );
  }
}
