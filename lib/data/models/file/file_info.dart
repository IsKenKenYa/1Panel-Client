import 'package:equatable/equatable.dart';

class FileSearch extends Equatable {
  final String path;
  final String? search;
  final int page;
  final int pageSize;
  final bool? expand;
  final String? sortBy;
  final String? sortOrder;
  final bool? containSub;
  final bool? dir;
  final bool? showHidden;
  final bool? isDetail;

  const FileSearch({
    required this.path,
    this.search,
    this.page = 1,
    this.pageSize = 100,
    this.expand,
    this.sortBy,
    this.sortOrder,
    this.containSub,
    this.dir,
    this.showHidden,
    this.isDetail,
  });

  factory FileSearch.fromJson(Map<String, dynamic> json) {
    return FileSearch(
      path: json['path'] as String,
      search: json['search'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 100,
      expand: json['expand'] as bool?,
      sortBy: json['sortBy'] as String?,
      sortOrder: json['sortOrder'] as String?,
      containSub: json['containSub'] as bool?,
      dir: json['dir'] as bool?,
      showHidden: json['showHidden'] as bool?,
      isDetail: json['isDetail'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      if (search != null) 'search': search,
      'page': page,
      'pageSize': pageSize,
      if (expand != null) 'expand': expand,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (containSub != null) 'containSub': containSub,
      if (dir != null) 'dir': dir,
      if (showHidden != null) 'showHidden': showHidden,
      if (isDetail != null) 'isDetail': isDetail,
    };
  }

  @override
  List<Object?> get props => [
        path,
        search,
        page,
        pageSize,
        expand,
        sortBy,
        sortOrder,
        containSub,
        dir,
        showHidden,
        isDetail,
      ];
}

class FileSearchResponse extends Equatable {
  final List<FileInfo> items;
  final int total;

  const FileSearchResponse({
    required this.items,
    required this.total,
  });

  factory FileSearchResponse.fromJson(Map<String, dynamic> json) {
    final dataField = json['data'];
    if (dataField is Map<String, dynamic>) {
      final items = (dataField['items'] as List?)
              ?.map((item) => FileInfo.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      final total = dataField['itemTotal'] ?? dataField['total'];
      return FileSearchResponse(
        items: items,
        total: total is num ? total.toInt() : items.length,
      );
    }
    if (dataField is List) {
      final items = dataField
          .map((item) => FileInfo.fromJson(item as Map<String, dynamic>))
          .toList();
      return FileSearchResponse(items: items, total: items.length);
    }
    if (json['items'] is List) {
      final items = (json['items'] as List)
          .map((item) => FileInfo.fromJson(item as Map<String, dynamic>))
          .toList();
      final total = json['itemTotal'] ?? json['total'];
      return FileSearchResponse(
        items: items,
        total: total is num ? total.toInt() : items.length,
      );
    }
    return const FileSearchResponse(items: [], total: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'itemTotal': total,
    };
  }

  @override
  List<Object?> get props => [items, total];
}

class FileInfo extends Equatable {
  final String name;
  final String path;
  final String type;
  final int size;
  final String? permission;
  final String? user;
  final String? group;
  final DateTime? modifiedAt;
  final DateTime? createdAt;
  final String? mimeType;
  final bool isDir;
  final bool isSymlink;
  final String? linkTarget;
  final List<FileInfo>? children;
  final String? extension;
  final bool isHidden;
  final int? itemTotal;
  final int? favoriteID;
  final String? gid;
  final bool isDetail;
  final String? content;
  final String? remark;
  final String? mode;
  final String? from;
  final String? rName;

  const FileInfo({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    this.permission,
    this.user,
    this.group,
    this.modifiedAt,
    this.createdAt,
    this.mimeType,
    this.isDir = false,
    this.isSymlink = false,
    this.linkTarget,
    this.children,
    this.extension,
    this.isHidden = false,
    this.itemTotal,
    this.favoriteID,
    this.gid,
    this.isDetail = false,
    this.content,
    this.remark,
    this.mode,
    this.from,
    this.rName,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? json['sourcePath'] as String? ?? '',
      type: json['type'] as String? ?? 'file',
      size: json['size'] as int? ?? 0,
      permission: json['mode'] as String? ?? json['permission'] as String?,
      user: json['user'] as String?,
      group: json['group'] as String?,
      modifiedAt: json['modTime'] != null
          ? DateTime.tryParse(json['modTime'] as String)
          : (json['modifiedAt'] != null
              ? DateTime.tryParse(json['modifiedAt'] as String)
              : null),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      mimeType: json['mimeType'] as String?,
      isDir: json['isDir'] as bool? ?? false,
      isSymlink: json['isSymlink'] as bool? ?? false,
      linkTarget: json['linkPath'] as String? ?? json['linkTarget'] as String?,
      children: (json['items'] as List?)
              ?.map((item) => FileInfo.fromJson(item as Map<String, dynamic>))
              .toList() ??
          (json['children'] as List?)
              ?.map((item) => FileInfo.fromJson(item as Map<String, dynamic>))
              .toList(),
      extension: json['extension'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      itemTotal: json['itemTotal'] as int?,
      favoriteID: json['favoriteID'] as int?,
      gid: json['gid'] as String?,
      isDetail: json['isDetail'] as bool? ?? false,
      content: json['content'] as String?,
      remark: json['remark'] as String?,
      mode: json['mode'] as String?,
      from: json['from'] as String? ?? json['sourcePath'] as String?,
      rName: json['rName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': type,
      'size': size,
      'mode': permission ?? mode,
      'user': user,
      'group': group,
      'modTime': modifiedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'mimeType': mimeType,
      'isDir': isDir,
      'isSymlink': isSymlink,
      'linkPath': linkTarget,
      'items': children?.map((item) => item.toJson()).toList(),
      'extension': extension,
      'isHidden': isHidden,
      'itemTotal': itemTotal,
      'favoriteID': favoriteID,
      'gid': gid,
      'isDetail': isDetail,
      'content': content,
      'remark': remark,
      'from': from,
      'rName': rName,
    };
  }

  @override
  List<Object?> get props => [
        name,
        path,
        type,
        size,
        permission,
        user,
        group,
        modifiedAt,
        createdAt,
        mimeType,
        isDir,
        isSymlink,
        linkTarget,
        children,
        extension,
        isHidden,
        itemTotal,
        favoriteID,
        gid,
        isDetail,
        content,
        remark,
        mode,
        from,
        rName,
      ];
}
