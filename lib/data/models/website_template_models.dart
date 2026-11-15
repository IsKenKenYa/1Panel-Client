import 'package:equatable/equatable.dart';

class WebsiteTemplateIdReq extends Equatable {
  final int id;

  const WebsiteTemplateIdReq({required this.id});

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id};

  @override
  List<Object?> get props => [id];
}

class WebsiteTemplateCreate extends Equatable {
  final String name;
  final String type;
  final String? content;
  final String? filePath;
  final String? remark;
  final String? variables;

  const WebsiteTemplateCreate({
    required this.name,
    required this.type,
    this.content,
    this.filePath,
    this.remark,
    this.variables,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name, 'type': type};
    if (content != null) json['content'] = content;
    if (filePath != null) json['filePath'] = filePath;
    if (remark != null) json['remark'] = remark;
    if (variables != null) json['variables'] = variables;
    return json;
  }

  @override
  List<Object?> get props => [name, type, content, filePath, remark, variables];
}

class WebsiteTemplateUpdate extends Equatable {
  final int id;
  final String name;
  final String type;
  final String? content;
  final String? filePath;
  final String? remark;
  final String? variables;

  const WebsiteTemplateUpdate({
    required this.id,
    required this.name,
    required this.type,
    this.content,
    this.filePath,
    this.remark,
    this.variables,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'id': id, 'name': name, 'type': type};
    if (content != null) json['content'] = content;
    if (filePath != null) json['filePath'] = filePath;
    if (remark != null) json['remark'] = remark;
    if (variables != null) json['variables'] = variables;
    return json;
  }

  @override
  List<Object?> get props =>
      [id, name, type, content, filePath, remark, variables];
}

class WebsiteTemplateSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? name;
  final String? type;

  const WebsiteTemplateSearch({
    required this.page,
    required this.pageSize,
    this.name,
    this.type,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (name != null) json['name'] = name;
    if (type != null) json['type'] = type;
    return json;
  }

  @override
  List<Object?> get props => [page, pageSize, name, type];
}

class WebsiteTemplateDto extends Equatable {
  final int id;
  final String name;
  final String type;
  final String content;
  final String filePath;
  final String remark;
  final String variables;
  final String createdAt;
  final String updatedAt;

  const WebsiteTemplateDto({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.filePath,
    required this.remark,
    required this.variables,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WebsiteTemplateDto.fromJson(Map<String, dynamic> json) {
    return WebsiteTemplateDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      variables: json['variables'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, name, type, content, filePath, remark, variables, createdAt, updatedAt];
}

class WebsitePreviewReq extends Equatable {
  final int templateID;
  final Map<String, String>? variableValues;

  const WebsitePreviewReq({required this.templateID, this.variableValues});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'templateID': templateID};
    if (variableValues != null) json['variableValues'] = variableValues;
    return json;
  }

  @override
  List<Object?> get props => [templateID, variableValues];
}

class WebsitePreviewDto extends Equatable {
  final String html;

  const WebsitePreviewDto({required this.html});

  factory WebsitePreviewDto.fromJson(Map<String, dynamic> json) {
    return WebsitePreviewDto(html: json['html'] as String? ?? '');
  }

  @override
  List<Object?> get props => [html];
}

class WebsiteTemplateOutputCreate extends Equatable {
  final String name;
  final int templateID;
  final Map<String, String>? variableValues;

  const WebsiteTemplateOutputCreate({
    required this.name,
    required this.templateID,
    this.variableValues,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name, 'templateID': templateID};
    if (variableValues != null) json['variableValues'] = variableValues;
    return json;
  }

  @override
  List<Object?> get props => [name, templateID, variableValues];
}

class WebsiteTemplateOutputSearch extends Equatable {
  final int page;
  final int pageSize;
  final int? templateID;

  const WebsiteTemplateOutputSearch({
    required this.page,
    required this.pageSize,
    this.templateID,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (templateID != null) json['templateID'] = templateID;
    return json;
  }

  @override
  List<Object?> get props => [page, pageSize, templateID];
}

class WebsiteTemplateOutputDto extends Equatable {
  final int id;
  final String name;
  final int templateID;
  final String templateName;
  final String templateType;
  final String outputPath;
  final String variableValues;
  final String createdAt;
  final String updatedAt;

  const WebsiteTemplateOutputDto({
    required this.id,
    required this.name,
    required this.templateID,
    required this.templateName,
    required this.templateType,
    required this.outputPath,
    required this.variableValues,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WebsiteTemplateOutputDto.fromJson(Map<String, dynamic> json) {
    return WebsiteTemplateOutputDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      templateID: json['templateID'] as int? ?? 0,
      templateName: json['templateName'] as String? ?? '',
      templateType: json['templateType'] as String? ?? '',
      outputPath: json['outputPath'] as String? ?? '',
      variableValues: json['variableValues'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        templateID,
        templateName,
        templateType,
        outputPath,
        variableValues,
        createdAt,
        updatedAt,
      ];
}
