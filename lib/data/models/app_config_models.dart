import 'package:json_annotation/json_annotation.dart';

part 'app_config_models.g.dart';

@JsonSerializable()
class AppConfig {
  final List<InstallParams> params;
  final String? rawCompose;
  final double cpuQuota;
  final double memoryLimit;
  final String memoryUnit;
  final String containerName;
  final bool allowPort;
  final String dockerCompose;
  final bool? hostMode;
  final String type;
  final String webUI;
  final String? specifyIP;
  final String? restartPolicy;

  AppConfig({
    required this.params,
    this.rawCompose,
    required this.cpuQuota,
    required this.memoryLimit,
    required this.memoryUnit,
    required this.containerName,
    required this.allowPort,
    required this.dockerCompose,
    this.hostMode,
    required this.type,
    required this.webUI,
    this.specifyIP,
    this.restartPolicy,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}

@JsonSerializable()
class InstallParams {
  final String labelZh;
  final String labelEn;
  final dynamic value; // Using dynamic because it can be various types
  final bool edit;
  final String key;
  final String? rule;
  final String type;
  final dynamic values;
  final String? showValue;
  final bool? required;
  final bool? multiple;
  final Locale? label;
  final bool? showPassword;

  InstallParams({
    required this.labelZh,
    required this.labelEn,
    this.value,
    required this.edit,
    required this.key,
    this.rule,
    required this.type,
    this.values,
    this.showValue,
    this.required,
    this.multiple,
    this.label,
    this.showPassword,
  });

  factory InstallParams.fromJson(Map<String, dynamic> json) =>
      _$InstallParamsFromJson(json);
  Map<String, dynamic> toJson() => _$InstallParamsToJson(this);
}

@JsonSerializable()
class Locale {
  final String zh;
  final String en;
  @JsonKey(name: 'zh-Hant')
  final String? zhHant;
  final String? ja;
  final String? ms;
  @JsonKey(name: 'pt-br')
  final String? ptBr;
  final String? ru;
  final String? ko;
  final String? tr;
  @JsonKey(name: 'es-es')
  final String? esEs;

  Locale({
    required this.zh,
    required this.en,
    this.zhHant,
    this.ja,
    this.ms,
    this.ptBr,
    this.ru,
    this.ko,
    this.tr,
    this.esEs,
  });

  factory Locale.fromJson(Map<String, dynamic> json) => _$LocaleFromJson(json);
  Map<String, dynamic> toJson() => _$LocaleToJson(this);
}
