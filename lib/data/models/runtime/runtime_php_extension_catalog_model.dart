part of '../runtime_models.dart';

class PHPExtensionSupport extends Equatable {
  final String name;
  final String? description;
  final bool installed;
  final String? check;
  final List<String> versions;
  final String? file;

  const PHPExtensionSupport({
    required this.name,
    this.description,
    this.installed = false,
    this.check,
    this.versions = const <String>[],
    this.file,
  });

  factory PHPExtensionSupport.fromJson(Map<String, dynamic> json) {
    return PHPExtensionSupport(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      installed: json['installed'] as bool? ?? false,
      check: json['check'] as String?,
      versions: (json['versions'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      file: json['file'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'installed': installed,
        'check': check,
        'versions': versions,
        'file': file,
      };

  @override
  List<Object?> get props =>
      [name, description, installed, check, versions, file];
}

class PHPExtensionsRes extends Equatable {
  final List<String> extensions;
  final List<PHPExtensionSupport> supportExtensions;

  const PHPExtensionsRes({
    this.extensions = const <String>[],
    this.supportExtensions = const <PHPExtensionSupport>[],
  });

  factory PHPExtensionsRes.fromJson(Map<String, dynamic> json) {
    return PHPExtensionsRes(
      extensions: (json['extensions'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      supportExtensions: (json['supportExtensions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PHPExtensionSupport.fromJson)
              .toList() ??
          const <PHPExtensionSupport>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'extensions': extensions,
        'supportExtensions':
            supportExtensions.map((item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => [extensions, supportExtensions];
}
