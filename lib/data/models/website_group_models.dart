import 'package:equatable/equatable.dart';

/// Website group model
class WebsiteGroup extends Equatable {
  final int? id;
  final String? name;
  final String? description;
  final int? sort;
  final String? createTime;
  final String? updateTime;

  const WebsiteGroup({
    this.id,
    this.name,
    this.description,
    this.sort,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteGroup.fromJson(Map<String, dynamic> json) {
    return WebsiteGroup(
      id: json['id'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      sort: json['sort'] as int?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sort': sort,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, description, sort, createTime, updateTime];
}

/// Website group create request model
class WebsiteGroupCreate extends Equatable {
  final String name;
  final String? description;
  final int? sort;

  const WebsiteGroupCreate({
    required this.name,
    this.description,
    this.sort,
  });

  factory WebsiteGroupCreate.fromJson(Map<String, dynamic> json) {
    return WebsiteGroupCreate(
      name: json['name'] as String,
      description: json['description'] as String?,
      sort: json['sort'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'sort': sort,
    };
  }

  @override
  List<Object?> get props => [name, description, sort];
}

/// Website group update request model
class WebsiteGroupUpdate extends Equatable {
  final int id;
  final String? name;
  final String? description;
  final int? sort;

  const WebsiteGroupUpdate({
    required this.id,
    this.name,
    this.description,
    this.sort,
  });

  factory WebsiteGroupUpdate.fromJson(Map<String, dynamic> json) {
    return WebsiteGroupUpdate(
      id: json['id'] as int,
      name: json['name'] as String?,
      description: json['description'] as String?,
      sort: json['sort'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sort': sort,
    };
  }

  @override
  List<Object?> get props => [id, name, description, sort];
}

/// Website group search request model
class WebsiteGroupSearch extends Equatable {
  final String? name;
  final int? page;
  final int? pageSize;

  const WebsiteGroupSearch({
    this.name,
    this.page,
    this.pageSize,
  });

  factory WebsiteGroupSearch.fromJson(Map<String, dynamic> json) {
    return WebsiteGroupSearch(
      name: json['name'] as String?,
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [name, page, pageSize];
}
