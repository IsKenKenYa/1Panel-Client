import 'package:equatable/equatable.dart';

class DiskBasicInfo extends Equatable {
  const DiskBasicInfo({
    this.device = '',
    this.size = '',
    this.model = '',
    this.diskType = '',
    this.isRemovable = false,
    this.isSystem = false,
    this.filesystem = '',
    this.used = '',
    this.avail = '',
    this.usePercent = 0,
    this.mountPoint = '',
    this.isMounted = false,
    this.serial = '',
  });

  final String device;
  final String size;
  final String model;
  final String diskType;
  final bool isRemovable;
  final bool isSystem;
  final String filesystem;
  final String used;
  final String avail;
  final int usePercent;
  final String mountPoint;
  final bool isMounted;
  final String serial;

  factory DiskBasicInfo.fromJson(Map<String, dynamic> json) {
    return DiskBasicInfo(
      device: json['device'] as String? ?? '',
      size: json['size'] as String? ?? '',
      model: json['model'] as String? ?? '',
      diskType: json['diskType'] as String? ?? '',
      isRemovable: json['isRemovable'] as bool? ?? false,
      isSystem: json['isSystem'] as bool? ?? false,
      filesystem: json['filesystem'] as String? ?? '',
      used: json['used'] as String? ?? '',
      avail: json['avail'] as String? ?? '',
      usePercent: json['usePercent'] as int? ?? 0,
      mountPoint: json['mountPoint'] as String? ?? '',
      isMounted: json['isMounted'] as bool? ?? false,
      serial: json['serial'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'device': device,
        'size': size,
        'model': model,
        'diskType': diskType,
        'isRemovable': isRemovable,
        'isSystem': isSystem,
        'filesystem': filesystem,
        'used': used,
        'avail': avail,
        'usePercent': usePercent,
        'mountPoint': mountPoint,
        'isMounted': isMounted,
        'serial': serial,
      };

  @override
  List<Object?> get props => <Object?>[
        device,
        size,
        model,
        diskType,
        isRemovable,
        isSystem,
        filesystem,
        used,
        avail,
        usePercent,
        mountPoint,
        isMounted,
        serial,
      ];
}

class DiskInfo extends DiskBasicInfo {
  const DiskInfo({
    super.device = '',
    super.size = '',
    super.model = '',
    super.diskType = '',
    super.isRemovable = false,
    super.isSystem = false,
    super.filesystem = '',
    super.used = '',
    super.avail = '',
    super.usePercent = 0,
    super.mountPoint = '',
    super.isMounted = false,
    super.serial = '',
    this.partitions = const <DiskBasicInfo>[],
  });

  final List<DiskBasicInfo> partitions;

  factory DiskInfo.fromJson(Map<String, dynamic> json) {
    return DiskInfo(
      device: json['device'] as String? ?? '',
      size: json['size'] as String? ?? '',
      model: json['model'] as String? ?? '',
      diskType: json['diskType'] as String? ?? '',
      isRemovable: json['isRemovable'] as bool? ?? false,
      isSystem: json['isSystem'] as bool? ?? false,
      filesystem: json['filesystem'] as String? ?? '',
      used: json['used'] as String? ?? '',
      avail: json['avail'] as String? ?? '',
      usePercent: json['usePercent'] as int? ?? 0,
      mountPoint: json['mountPoint'] as String? ?? '',
      isMounted: json['isMounted'] as bool? ?? false,
      serial: json['serial'] as String? ?? '',
      partitions: (json['partitions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DiskBasicInfo.fromJson)
              .toList(growable: false) ??
          const <DiskBasicInfo>[],
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        ...super.toJson(),
        'partitions':
            partitions.map((DiskBasicInfo item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[...super.props, partitions];
}

class CompleteDiskInfo extends Equatable {
  const CompleteDiskInfo({
    this.disks = const <DiskInfo>[],
    this.systemDisks = const <DiskInfo>[],
    this.unpartitionedDisks = const <DiskBasicInfo>[],
    this.totalDisks = 0,
    this.totalCapacity = 0,
  });

  final List<DiskInfo> disks;
  final List<DiskInfo> systemDisks;
  final List<DiskBasicInfo> unpartitionedDisks;
  final int totalDisks;
  final int totalCapacity;

  factory CompleteDiskInfo.fromJson(Map<String, dynamic> json) {
    return CompleteDiskInfo(
      disks: (json['disks'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DiskInfo.fromJson)
              .toList(growable: false) ??
          const <DiskInfo>[],
      systemDisks: (json['systemDisks'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DiskInfo.fromJson)
              .toList(growable: false) ??
          const <DiskInfo>[],
      unpartitionedDisks: (json['unpartitionedDisks'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DiskBasicInfo.fromJson)
              .toList(growable: false) ??
          const <DiskBasicInfo>[],
      totalDisks: json['totalDisks'] as int? ?? 0,
      totalCapacity: json['totalCapacity'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        disks,
        systemDisks,
        unpartitionedDisks,
        totalDisks,
        totalCapacity,
      ];
}

class DiskMountRequest extends Equatable {
  const DiskMountRequest({
    required this.device,
    required this.filesystem,
    required this.mountPoint,
    this.autoMount = true,
    this.noFail = true,
  });

  final String device;
  final String filesystem;
  final String mountPoint;
  final bool autoMount;
  final bool noFail;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'device': device,
        'filesystem': filesystem,
        'mountPoint': mountPoint,
        'autoMount': autoMount,
        'noFail': noFail,
      };

  @override
  List<Object?> get props => <Object?>[
        device,
        filesystem,
        mountPoint,
        autoMount,
        noFail,
      ];
}

class DiskPartitionRequest extends Equatable {
  const DiskPartitionRequest({
    required this.device,
    required this.filesystem,
    required this.mountPoint,
    this.label = '',
    this.autoMount = true,
  });

  final String device;
  final String filesystem;
  final String mountPoint;
  final String label;
  final bool autoMount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'device': device,
        'filesystem': filesystem,
        'mountPoint': mountPoint,
        'label': label,
        'autoMount': autoMount,
      };

  @override
  List<Object?> get props => <Object?>[
        device,
        filesystem,
        mountPoint,
        label,
        autoMount,
      ];
}

class DiskUnmountRequest extends Equatable {
  const DiskUnmountRequest({required this.mountPoint});

  final String mountPoint;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mountPoint': mountPoint,
      };

  @override
  List<Object?> get props => <Object?>[mountPoint];
}
