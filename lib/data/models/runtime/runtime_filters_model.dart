part of '../runtime_models.dart';

class RuntimeSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? type;
  final String? name;
  final String? status;

  const RuntimeSearch({
    this.page = 1,
    this.pageSize = 20,
    this.type,
    this.name,
    this.status,
  });

  factory RuntimeSearch.fromJson(Map<String, dynamic> json) {
    return RuntimeSearch(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      type: json['type'] as String?,
      name: json['name'] as String? ?? json['search'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'type': type,
      'name': name,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, type, name, status];
}

/// Runtime operation model
class RuntimeOperate extends Equatable {
  final int id;
  final String operate;

  const RuntimeOperate({
    required this.id,
    required this.operate,
  });

  factory RuntimeOperate.fromJson(Map<String, dynamic> json) {
    return RuntimeOperate(
      id: json['ID'] as int? ?? json['id'] as int? ?? 0,
      operate: json['operate'] as String? ?? json['operation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'operate': operate,
    };
  }

  @override
  List<Object?> get props => [id, operate];
}

class RuntimeDelete extends Equatable {
  final int id;
  final bool forceDelete;

  const RuntimeDelete({
    required this.id,
    this.forceDelete = false,
  });

  factory RuntimeDelete.fromJson(Map<String, dynamic> json) {
    return RuntimeDelete(
      id: json['id'] as int? ?? 0,
      forceDelete: json['forceDelete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'forceDelete': forceDelete,
      };

  @override
  List<Object?> get props => [id, forceDelete];
}

/// Runtime update request model
