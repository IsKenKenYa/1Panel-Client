import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/app_models.dart';
import '../app_service.dart';

class AppIcon extends StatefulWidget {
  final AppItem? app;
  final int? appId;
  final String? appKey;
  final String? iconUrl;
  final double size;

  const AppIcon({
    super.key,
    this.app,
    this.appId,
    this.appKey,
    this.iconUrl,
    this.size = 40,
  });

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> with AutomaticKeepAliveClientMixin {
  static final Map<String, Uint8List> _cache = {};
  Uint8List? _iconBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(covariant AppIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_getKey(oldWidget) != _getKey(widget) || _getId(oldWidget) != _getId(widget)) {
      _loadIcon();
    }
  }

  String? _getKey(AppIcon widget) => widget.app?.key ?? widget.appKey;
  String? _getId(AppIcon widget) => widget.app?.id?.toString() ?? widget.appId?.toString();

  Future<void> _loadIcon() async {
    final key = _getKey(widget);
    final id = _getId(widget);

    if (key == null && id == null) {
      return;
    }

    // 1. Check static cache
    if (key != null && _cache.containsKey(key)) {
      setState(() {
        _iconBytes = _cache[key];
        _isLoading = false;
      });
      return;
    }

    if (id != null && _cache.containsKey(id)) {
      setState(() {
        _iconBytes = _cache[id];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appService = context.read<AppService>();
      // 2. Fetch from service
      // Use key first, then id
      
      Uint8List? bytes;
      
      try {
        if (key != null) {
          final response = await appService.getAppIcon(key);
          if (response.data != null && response.data!.isNotEmpty) {
            bytes = Uint8List.fromList(response.data!);
          }
        }
      } catch (e) {
        // If key fetch fails, we will try ID below if available
      }

      try {
        if ((bytes == null || bytes.isEmpty) && id != null) {
          final response = await appService.getAppIcon(id);
          if (response.data != null && response.data!.isNotEmpty) {
            bytes = Uint8List.fromList(response.data!);
          }
        }
      } catch (e) {
        // Ignore and fallback to default icon
      }

      if (bytes != null && bytes.isNotEmpty) {
        // 3. Cache bytes
        if (key != null) _cache[key] = bytes;
        if (id != null) _cache[id] = bytes;

        if (mounted) {
          setState(() {
            _iconBytes = bytes;
            _isLoading = false;
          });
        }
      } else {
        // 4. Fetch failed or null data
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_iconBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8), // Optional: rounded corners for icon
        child: Image.memory(
          _iconBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
        ),
      );
    }

    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    final name = widget.app?.name ?? widget.appKey ?? '?';
    final letter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: widget.size * 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
