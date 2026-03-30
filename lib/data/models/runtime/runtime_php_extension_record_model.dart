part of '../runtime_models.dart';

class PHPExtensionRecord extends Equatable {
  const PHPExtensionRecord({
    this.id = 0,
    this.name = '',
    this.extensions = '',
  });

  final int id;
  final String name;
  final String extensions;

  factory PHPExtensionRecord.fromJson(Map<String, dynamic> json) {
    return PHPExtensionRecord(
      id: json['id'] as int? ?? json['ID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      extensions: json['extensions'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extensions': extensions,
    };
  }

  @override
  List<Object?> get props => [id, name, extensions];
}

class PHPExtensionRecordSearch extends Equatable {
  const PHPExtensionRecordSearch({
    this.page = 1,
    this.pageSize = 20,
    this.all = false,
  });

  final int page;
  final int pageSize;
  final bool all;

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'all': all,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, all];
}

class PHPExtensionRecordCreate extends Equatable {
  const PHPExtensionRecordCreate({
    required this.name,
    required this.extensions,
  });

  final String name;
  final String extensions;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'extensions': extensions,
    };
  }

  @override
  List<Object?> get props => [name, extensions];
}

class PHPExtensionRecordUpdate extends Equatable {
  const PHPExtensionRecordUpdate({
    required this.id,
    required this.extensions,
  });

  final int id;
  final String extensions;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'extensions': extensions,
    };
  }

  @override
  List<Object?> get props => [id, extensions];
}

class PHPExtensionRecordDelete extends Equatable {
  const PHPExtensionRecordDelete({
    required this.id,
  });

  final int id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }

  @override
  List<Object?> get props => [id];
}
