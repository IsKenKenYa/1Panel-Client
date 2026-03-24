import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

class UploadHistoryPage extends StatefulWidget {
  const UploadHistoryPage({super.key});

  @override
  State<UploadHistoryPage> createState() => _UploadHistoryPageState();
}

class _UploadHistoryPageState extends State<UploadHistoryPage> {
  final List<FileInfo> _files = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    if (!_hasMore) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<FilesProvider>();
      final files = await provider.searchUploadedFiles(
        page: _page,
        pageSize: _pageSize,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          if (_page == 1) {
            _files.clear();
          }
          _files.addAll(files);
          _hasMore = files.length >= _pageSize;
          if (_hasMore) {
            _page++;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
      _page = 1;
      _hasMore = true;
      _files.clear();
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.filesUploadHistory),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.filesSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              onSubmitted: _performSearch,
            ),
          ),
        ),
      ),
      body: _buildBody(context, l10n, theme),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    if (_files.isEmpty && !_isLoading) {
      if (_error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadData,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        );
      }
      return Center(child: Text(l10n.commonEmpty));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _files.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _files.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final file = _files[index];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(
            file.name,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            file.path,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Text(
            _formatSize(file.size),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
