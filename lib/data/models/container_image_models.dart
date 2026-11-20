import 'package:equatable/equatable.dart';

class ImageBuild extends Equatable {
  final String contextDir;
  final String? dockerfile;
  final List<String>? tags;
  final String? buildArgs;
  final bool? pull;
  final bool? noCache;
  final bool? rm;
  final String? label;

  const ImageBuild({
    required this.contextDir,
    this.dockerfile,
    this.tags,
    this.buildArgs,
    this.pull,
    this.noCache,
    this.rm,
    this.label,
  });

  factory ImageBuild.fromJson(Map<String, dynamic> json) {
    return ImageBuild(
      contextDir: json['contextDir'] as String,
      dockerfile: json['dockerfile'] as String?,
      tags: (json['tags'] as List?)?.cast<String>(),
      buildArgs: json['buildArgs'] as String?,
      pull: json['pull'] as bool?,
      noCache: json['noCache'] as bool?,
      rm: json['rm'] as bool?,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contextDir': contextDir,
      'dockerfile': dockerfile,
      'tags': tags,
      'buildArgs': buildArgs,
      'pull': pull,
      'noCache': noCache,
      'rm': rm,
      'label': label,
    };
  }

  @override
  List<Object?> get props => [
        contextDir,
        dockerfile,
        tags,
        buildArgs,
        pull,
        noCache,
        rm,
        label,
      ];
}

/// 镜像加载模型
class ImageLoad extends Equatable {
  final String filePath;
  final bool? quiet;

  const ImageLoad({
    required this.filePath,
    this.quiet,
  });

  factory ImageLoad.fromJson(Map<String, dynamic> json) {
    return ImageLoad(
      filePath: json['filePath'] as String,
      quiet: json['quiet'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'quiet': quiet,
    };
  }

  @override
  List<Object?> get props => [filePath, quiet];
}

/// 镜像拉取模型
class ImagePull extends Equatable {
  final String image;
  final String? tag;
  final bool? allTags;
  final String? platform;

  const ImagePull({
    required this.image,
    this.tag,
    this.allTags,
    this.platform,
  });

  factory ImagePull.fromJson(Map<String, dynamic> json) {
    final imageNames = json['imageName'];
    return ImagePull(
      image: json['image'] as String? ??
          (imageNames is List && imageNames.isNotEmpty
              ? imageNames.first.toString()
              : ''),
      tag: json['tag'] as String?,
      allTags: json['allTags'] as bool?,
      platform: json['platform'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final reference = (tag == null || tag!.isEmpty || image.endsWith(':$tag'))
        ? image
        : '$image:$tag';
    return {
      'imageName': <String>[reference],
      'taskID': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }

  @override
  List<Object?> get props => [image, tag, allTags, platform];
}

/// 镜像推送模型
class ImagePush extends Equatable {
  final String image;
  final String? tag;
  final String? registry;

  const ImagePush({
    required this.image,
    this.tag,
    this.registry,
  });

  factory ImagePush.fromJson(Map<String, dynamic> json) {
    return ImagePush(
      image: json['image'] as String,
      tag: json['tag'] as String?,
      registry: json['registry'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'tag': tag,
      'registry': registry,
    };
  }

  @override
  List<Object?> get props => [image, tag, registry];
}

/// 镜像保存模型
class ImageSave extends Equatable {
  final List<String> images;
  final String filePath;

  const ImageSave({
    required this.images,
    required this.filePath,
  });

  factory ImageSave.fromJson(Map<String, dynamic> json) {
    return ImageSave(
      images: (json['images'] as List?)?.cast<String>() ?? [],
      filePath: json['filePath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'images': images,
      'filePath': filePath,
    };
  }

  @override
  List<Object?> get props => [images, filePath];
}

/// 镜像标记模型
class ImageTag extends Equatable {
  final String sourceImage;
  final String targetImage;
  final String? tag;

  const ImageTag({
    required this.sourceImage,
    required this.targetImage,
    this.tag,
  });

  factory ImageTag.fromJson(Map<String, dynamic> json) {
    return ImageTag(
      sourceImage: json['sourceImage'] as String,
      targetImage: json['targetImage'] as String,
      tag: json['tag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceImage': sourceImage,
      'targetImage': targetImage,
      'tag': tag,
    };
  }

  @override
  List<Object?> get props => [sourceImage, targetImage, tag];
}

/// 网络创建模型

