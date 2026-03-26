import 'package:equatable/equatable.dart';

class SshCertOperate extends Equatable {
  const SshCertOperate({
    this.id = 0,
    required this.name,
    required this.mode,
    required this.encryptionMode,
    this.passPhrase = '',
    this.publicKey = '',
    this.privateKey = '',
    this.description = '',
  });

  final int id;
  final String name;
  final String mode;
  final String encryptionMode;
  final String passPhrase;
  final String publicKey;
  final String privateKey;
  final String description;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'mode': mode,
        'encryptionMode': encryptionMode,
        'passPhrase': passPhrase,
        'publicKey': publicKey,
        'privateKey': privateKey,
        'description': description,
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        mode,
        encryptionMode,
        passPhrase,
        publicKey,
        privateKey,
        description,
      ];
}

class SshCertInfo extends Equatable {
  const SshCertInfo({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.encryptionMode,
    required this.passPhrase,
    required this.publicKey,
    required this.privateKey,
    required this.description,
  });

  final int id;
  final DateTime? createdAt;
  final String name;
  final String encryptionMode;
  final String passPhrase;
  final String publicKey;
  final String privateKey;
  final String description;

  factory SshCertInfo.fromJson(Map<String, dynamic> json) {
    return SshCertInfo(
      id: json['id'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      name: json['name'] as String? ?? '',
      encryptionMode: json['encryptionMode'] as String? ?? '',
      passPhrase: json['passPhrase'] as String? ?? '',
      publicKey: json['publicKey'] as String? ?? '',
      privateKey: json['privateKey'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        createdAt,
        name,
        encryptionMode,
        passPhrase,
        publicKey,
        privateKey,
        description,
      ];
}

class SshCertSearchRequest extends Equatable {
  const SshCertSearchRequest({
    this.page = 1,
    this.pageSize = 20,
  });

  final int page;
  final int pageSize;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

  @override
  List<Object?> get props => <Object?>[page, pageSize];
}
