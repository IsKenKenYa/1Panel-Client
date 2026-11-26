import 'package:equatable/equatable.dart';

class ACMEAccount extends Equatable {
  final int? id;
  final String? email;
  final String? server;
  final String? status;
  final bool? registered;
  final String? kid;
  final String? createdAt;

  const ACMEAccount({
    this.id,
    this.email,
    this.server,
    this.status,
    this.registered,
    this.kid,
    this.createdAt,
  });

  factory ACMEAccount.fromJson(Map<String, dynamic> json) {
    return ACMEAccount(
      id: json['id'] as int?,
      email: json['email'] as String?,
      server: json['server'] as String?,
      status: json['status'] as String?,
      registered: json['registered'] as bool?,
      kid: json['kid'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'server': server,
      'status': status,
      'registered': registered,
      'kid': kid,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props =>
      [id, email, server, status, registered, kid, createdAt];
}

/// SSL certificate challenge model
class SSLCertificateChallenge extends Equatable {
  final String? type;
  final String? token;
  final String? keyAuthorization;
  final String? url;
  final String? status;

  const SSLCertificateChallenge({
    this.type,
    this.token,
    this.keyAuthorization,
    this.url,
    this.status,
  });

  factory SSLCertificateChallenge.fromJson(Map<String, dynamic> json) {
    return SSLCertificateChallenge(
      type: json['type'] as String?,
      token: json['token'] as String?,
      keyAuthorization: json['keyAuthorization'] as String?,
      url: json['url'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'token': token,
      'keyAuthorization': keyAuthorization,
      'url': url,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [type, token, keyAuthorization, url, status];
}

/// SSL 申请模型
class SSLApply extends Equatable {
  final List<String> domains;
  final int? acmeAccountId;
  final String? provider;
  final String? keyType;
  final String? organization;
  final String? email;
  final String? phone;
  final String? country;
  final String? state;
  final String? city;
  final String? street;
  final bool? skipDNS;
  final String? dnsAccountId;
  final String? nameserver1;
  final String? nameserver2;

  const SSLApply({
    required this.domains,
    this.acmeAccountId,
    this.provider,
    this.keyType,
    this.organization,
    this.email,
    this.phone,
    this.country,
    this.state,
    this.city,
    this.street,
    this.skipDNS,
    this.dnsAccountId,
    this.nameserver1,
    this.nameserver2,
  });

  factory SSLApply.fromJson(Map<String, dynamic> json) {
    return SSLApply(
      domains: (json['domains'] as List?)?.cast<String>() ?? [],
      acmeAccountId: json['acmeAccountId'] as int?,
      provider: json['provider'] as String?,
      keyType: json['keyType'] as String?,
      organization: json['organization'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      street: json['street'] as String?,
      skipDNS: json['skipDNS'] as bool?,
      dnsAccountId: json['dnsAccountId'] as String?,
      nameserver1: json['nameserver1'] as String?,
      nameserver2: json['nameserver2'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domains': domains,
      'acmeAccountId': acmeAccountId,
      'provider': provider,
      'keyType': keyType,
      'organization': organization,
      'email': email,
      'phone': phone,
      'country': country,
      'state': state,
      'city': city,
      'street': street,
      'skipDNS': skipDNS,
      'dnsAccountId': dnsAccountId,
      'nameserver1': nameserver1,
      'nameserver2': nameserver2,
    };
  }

  @override
  List<Object?> get props => [
        domains,
        acmeAccountId,
        provider,
        keyType,
        organization,
        email,
        phone,
        country,
        state,
        city,
        street,
        skipDNS,
        dnsAccountId,
        nameserver1,
        nameserver2,
      ];
}

/// DNS 账户模型
class DNSAccount extends Equatable {
  final int? id;
  final String? name;
  final String? type;
  final String? createdAt;
  final String? updatedAt;

  const DNSAccount({
    this.id,
    this.name,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory DNSAccount.fromJson(Map<String, dynamic> json) {
    return DNSAccount(
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [id, name, type, createdAt, updatedAt];
}

/// Website 模型
class Website extends Equatable {
  final int? id;
  final String? primaryDomain;
  final List<String>? domains;
  final String? protocol;
  final bool? ssl;

  const Website({
    this.id,
    this.primaryDomain,
    this.domains,
    this.protocol,
    this.ssl,
  });

  factory Website.fromJson(Map<String, dynamic> json) {
    final domains = json['domains'] as List?;
    return Website(
      id: json['id'] as int?,
      primaryDomain: json['primaryDomain'] as String?,
      domains: domains?.map((item) {
        return item is String ? item : (item as Map<String, dynamic>)['domain'] as String;
      }).toList(),
      protocol: json['protocol'] as String?,
      ssl: json['ssl'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryDomain': primaryDomain,
      'domains': domains,
      'protocol': protocol,
      'ssl': ssl,
    };
  }

  @override
  List<Object?> get props => [id, primaryDomain, domains, protocol, ssl];
}
