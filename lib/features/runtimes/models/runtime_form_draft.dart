import 'package:equatable/equatable.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';

class RuntimeFormDraft extends Equatable {
  const RuntimeFormDraft({
    this.id,
    this.appDetailId,
    this.appId,
    this.type = 'php',
    this.name = '',
    this.resource = 'local',
    this.image = '',
    this.version = '',
    this.source = '',
    this.codeDir = '/',
    this.port = 8080,
    this.remark = '',
    this.hostIp = '0.0.0.0',
    this.containerName = '',
    this.execScript = '',
    this.packageManager = 'npm',
    this.rebuild = false,
    this.exposedPorts = const <RuntimeExposedPort>[],
    this.environments = const <RuntimeEnvironment>[],
    this.volumes = const <RuntimeVolume>[],
    this.extraHosts = const <RuntimeExtraHost>[],
  });

  final int? id;
  final int? appDetailId;
  final int? appId;
  final String type;
  final String name;
  final String resource;
  final String image;
  final String version;
  final String source;
  final String codeDir;
  final int port;
  final String remark;
  final String hostIp;
  final String containerName;
  final String execScript;
  final String packageManager;
  final bool rebuild;
  final List<RuntimeExposedPort> exposedPorts;
  final List<RuntimeEnvironment> environments;
  final List<RuntimeVolume> volumes;
  final List<RuntimeExtraHost> extraHosts;

  bool get isEditing => id != null;
  bool get isManualResource => resource == 'local';
  bool get isNode => type == 'node';
  bool get isPhp => type == 'php';

  RuntimeFormDraft copyWith({
    int? id,
    int? appDetailId,
    int? appId,
    String? type,
    String? name,
    String? resource,
    String? image,
    String? version,
    String? source,
    String? codeDir,
    int? port,
    String? remark,
    String? hostIp,
    String? containerName,
    String? execScript,
    String? packageManager,
    bool? rebuild,
    List<RuntimeExposedPort>? exposedPorts,
    List<RuntimeEnvironment>? environments,
    List<RuntimeVolume>? volumes,
    List<RuntimeExtraHost>? extraHosts,
  }) {
    return RuntimeFormDraft(
      id: id ?? this.id,
      appDetailId: appDetailId ?? this.appDetailId,
      appId: appId ?? this.appId,
      type: type ?? this.type,
      name: name ?? this.name,
      resource: resource ?? this.resource,
      image: image ?? this.image,
      version: version ?? this.version,
      source: source ?? this.source,
      codeDir: codeDir ?? this.codeDir,
      port: port ?? this.port,
      remark: remark ?? this.remark,
      hostIp: hostIp ?? this.hostIp,
      containerName: containerName ?? this.containerName,
      execScript: execScript ?? this.execScript,
      packageManager: packageManager ?? this.packageManager,
      rebuild: rebuild ?? this.rebuild,
      exposedPorts: exposedPorts ?? this.exposedPorts,
      environments: environments ?? this.environments,
      volumes: volumes ?? this.volumes,
      extraHosts: extraHosts ?? this.extraHosts,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        appDetailId,
        appId,
        type,
        name,
        resource,
        image,
        version,
        source,
        codeDir,
        port,
        remark,
        hostIp,
        containerName,
        execScript,
        packageManager,
        rebuild,
        exposedPorts,
        environments,
        volumes,
        extraHosts,
      ];
}
