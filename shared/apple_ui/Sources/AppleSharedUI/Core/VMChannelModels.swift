import Foundation

/// 虚拟机通道返回值的解码结构。
///
/// 状态语义、操作可用性与监控百分比由 Dart 侧通道计算，本层只负责把字段
/// 转成界面可直接消费的值类型。iOS 与 macOS 共用同一套结构。

public struct VMCapabilities: Hashable {
    public let canStart: Bool
    public let canShutdown: Bool
    public let canReboot: Bool
    public let canSuspend: Bool
    public let canResume: Bool
    public let canDestroy: Bool
    public let canMonitor: Bool
    public let canOpenConsole: Bool
    public let canCreateSnapshot: Bool
    public let canHealthCheck: Bool
    public let canResizeDisk: Bool

    public static let none = VMCapabilities(
        canStart: false,
        canShutdown: false,
        canReboot: false,
        canSuspend: false,
        canResume: false,
        canDestroy: false,
        canMonitor: false,
        canOpenConsole: false,
        canCreateSnapshot: false,
        canHealthCheck: false,
        canResizeDisk: false
    )

    public init(
        canStart: Bool,
        canShutdown: Bool,
        canReboot: Bool,
        canSuspend: Bool,
        canResume: Bool,
        canDestroy: Bool,
        canMonitor: Bool,
        canOpenConsole: Bool,
        canCreateSnapshot: Bool,
        canHealthCheck: Bool,
        canResizeDisk: Bool
    ) {
        self.canStart = canStart
        self.canShutdown = canShutdown
        self.canReboot = canReboot
        self.canSuspend = canSuspend
        self.canResume = canResume
        self.canDestroy = canDestroy
        self.canMonitor = canMonitor
        self.canOpenConsole = canOpenConsole
        self.canCreateSnapshot = canCreateSnapshot
        self.canHealthCheck = canHealthCheck
        self.canResizeDisk = canResizeDisk
    }

    public init(payload: [String: Any]) {
        self.init(
            canStart: VMValue.bool(payload["canStart"]),
            canShutdown: VMValue.bool(payload["canShutdown"]),
            canReboot: VMValue.bool(payload["canReboot"]),
            canSuspend: VMValue.bool(payload["canSuspend"]),
            canResume: VMValue.bool(payload["canResume"]),
            canDestroy: VMValue.bool(payload["canDestroy"]),
            canMonitor: VMValue.bool(payload["canMonitor"]),
            canOpenConsole: VMValue.bool(payload["canOpenConsole"]),
            canCreateSnapshot: VMValue.bool(payload["canCreateSnapshot"]),
            canHealthCheck: VMValue.bool(payload["canHealthCheck"]),
            canResizeDisk: VMValue.bool(payload["canResizeDisk"])
        )
    }
}

public struct VMDiskModel: Identifiable, Hashable {
    public let target: String
    public let device: String
    public let capacity: Int
    public let format: String
    public let bus: String
    public let source: String
    public let readOnly: Bool

    public var id: String { "\(target)-\(device)-\(source)" }

    public init(payload: [String: Any]) {
        target = VMValue.string(payload["target"])
        device = VMValue.string(payload["device"])
        capacity = VMValue.int(payload["capacity"])
        format = VMValue.string(payload["format"])
        bus = VMValue.string(payload["bus"])
        source = VMValue.string(payload["source"])
        readOnly = VMValue.bool(payload["readOnly"])
    }
}

public struct VMInterfaceModel: Identifiable, Hashable {
    public let type: String
    public let source: String
    public let model: String
    public let mac: String
    public let ip: String

    public var id: String { "\(mac)-\(source)-\(ip)" }

    public init(payload: [String: Any]) {
        type = VMValue.string(payload["type"])
        source = VMValue.string(payload["source"])
        model = VMValue.string(payload["model"])
        mac = VMValue.string(payload["mac"])
        ip = VMValue.string(payload["ip"])
    }
}

public struct VMGraphicsModel: Hashable {
    public let type: String
    public let port: String
    public let listen: String

    public init(payload: [String: Any]) {
        type = VMValue.string(payload["type"])
        port = VMValue.string(payload["port"])
        listen = VMValue.string(payload["listen"])
    }
}

public struct VMInstanceModel: Identifiable, Hashable {
    public let name: String
    public let serverId: Int
    public let uuid: String
    public let status: String
    public let statusKey: String
    public let statusTone: String
    public let cpu: Int
    public let memoryMiB: Int
    public let diskSize: Int
    public let diskBus: String
    public let diskPath: String
    public let storagePool: String
    public let network: String
    public let bootOrder: String
    public let autoStart: Bool
    public let description: String
    public let graphicsType: String
    public let capabilities: VMCapabilities
    public let disks: [VMDiskModel]
    public let interfaces: [VMInterfaceModel]
    public let isoPaths: [String]
    public let graphics: VMGraphicsModel?

    public var id: String { name }

    public init(payload: [String: Any]) {
        name = VMValue.string(payload["name"])
        serverId = VMValue.int(payload["id"])
        uuid = VMValue.string(payload["uuid"])
        status = VMValue.string(payload["status"])
        statusKey = VMValue.string(payload["statusKey"])
        statusTone = VMValue.string(payload["statusTone"])
        cpu = VMValue.int(payload["cpu"])
        memoryMiB = VMValue.int(payload["memoryMiB"])
        diskSize = VMValue.int(payload["diskSize"])
        diskBus = VMValue.string(payload["diskBus"])
        diskPath = VMValue.string(payload["diskPath"])
        storagePool = VMValue.string(payload["storagePool"])
        network = VMValue.string(payload["network"])
        bootOrder = VMValue.string(payload["bootOrder"])
        autoStart = VMValue.bool(payload["autoStart"])
        description = VMValue.string(payload["description"])
        graphicsType = VMValue.string(payload["graphicsType"])
        capabilities = VMCapabilities(
            payload: payload["capabilities"] as? [String: Any] ?? [:]
        )
        disks = (payload["disks"] as? [[String: Any]] ?? [])
            .map(VMDiskModel.init)
        interfaces = (payload["interfaces"] as? [[String: Any]] ?? [])
            .map(VMInterfaceModel.init)
        isoPaths = payload["isoPaths"] as? [String] ?? []
        graphics = (payload["graphics"] as? [String: Any]).map(VMGraphicsModel.init)
    }
}

public struct VMEnvironmentModel {
    public let arch: String
    public let archSupported: Bool
    public let ready: Bool
    public let helperExist: Bool
    public let helperMessage: String
    public let kvmExist: Bool
    public let kvmMessage: String
    public let libvirtExist: Bool
    public let libvirtActive: Bool
    public let libvirtMessage: String
    public let storageExist: Bool
    public let storageMessage: String

    public static let empty = VMEnvironmentModel(
        arch: "",
        archSupported: false,
        ready: false,
        helperExist: false,
        helperMessage: "",
        kvmExist: false,
        kvmMessage: "",
        libvirtExist: false,
        libvirtActive: false,
        libvirtMessage: "",
        storageExist: false,
        storageMessage: ""
    )

    public init(
        arch: String,
        archSupported: Bool,
        ready: Bool,
        helperExist: Bool,
        helperMessage: String,
        kvmExist: Bool,
        kvmMessage: String,
        libvirtExist: Bool,
        libvirtActive: Bool,
        libvirtMessage: String,
        storageExist: Bool,
        storageMessage: String
    ) {
        self.arch = arch
        self.archSupported = archSupported
        self.ready = ready
        self.helperExist = helperExist
        self.helperMessage = helperMessage
        self.kvmExist = kvmExist
        self.kvmMessage = kvmMessage
        self.libvirtExist = libvirtExist
        self.libvirtActive = libvirtActive
        self.libvirtMessage = libvirtMessage
        self.storageExist = storageExist
        self.storageMessage = storageMessage
    }

    public init(payload: [String: Any]) {
        arch = VMValue.string(payload["arch"])
        archSupported = VMValue.bool(payload["archSupported"])
        ready = VMValue.bool(payload["ready"])
        helperExist = VMValue.bool(payload["helperExist"])
        helperMessage = VMValue.string(payload["helperMessage"])
        kvmExist = VMValue.bool(payload["kvmExist"])
        kvmMessage = VMValue.string(payload["kvmMessage"])
        libvirtExist = VMValue.bool(payload["libvirtExist"])
        libvirtActive = VMValue.bool(payload["libvirtActive"])
        libvirtMessage = VMValue.string(payload["libvirtMessage"])
        storageExist = VMValue.bool(payload["storageExist"])
        storageMessage = VMValue.string(payload["storageMessage"])
    }
}

public struct VMSnapshotModel: Identifiable, Hashable {
    public let name: String
    public let description: String
    public let createdAtMillis: Int
    public let state: String
    public let size: Int
    public let current: Bool
    public let canRecover: Bool

    public var id: String { name }

    public init(payload: [String: Any]) {
        name = VMValue.string(payload["name"])
        description = VMValue.string(payload["description"])
        createdAtMillis = VMValue.int(payload["createdAtMillis"])
        state = VMValue.string(payload["state"])
        size = VMValue.int(payload["size"])
        current = VMValue.bool(payload["current"])
        canRecover = VMValue.bool(payload["canRecover"])
    }
}

public struct VMSnapshotResult {
    public let canCreate: Bool
    public let canRecover: Bool
    public let items: [VMSnapshotModel]

    public init(payload: [String: Any]) {
        canCreate = VMValue.bool(payload["canCreate"])
        canRecover = VMValue.bool(payload["canRecover"])
        items = (payload["items"] as? [[String: Any]] ?? []).map(VMSnapshotModel.init)
    }
}

public struct VMIsoModel: Identifiable, Hashable {
    public let isoId: Int
    public let type: String
    public let name: String
    public let path: String
    public let isExist: Bool
    public let size: Int
    public let status: String
    public let error: String

    public var id: Int { isoId }

    public init(payload: [String: Any]) {
        isoId = VMValue.int(payload["id"])
        type = VMValue.string(payload["type"])
        name = VMValue.string(payload["name"])
        path = VMValue.string(payload["path"])
        isExist = VMValue.bool(payload["isExist"])
        size = VMValue.int(payload["size"])
        status = VMValue.string(payload["status"])
        error = VMValue.string(payload["error"])
    }
}

public struct VMTemplateModel: Identifiable, Hashable {
    public let templateId: Int
    public let name: String
    public let sourceVM: String
    public let cpu: Int
    public let memoryMiB: Int
    public let diskSize: Int
    public let storagePool: String
    public let isExist: Bool
    public let size: Int
    public let status: String
    public let error: String

    public var id: Int { templateId }

    public init(payload: [String: Any]) {
        templateId = VMValue.int(payload["id"])
        name = VMValue.string(payload["name"])
        sourceVM = VMValue.string(payload["sourceVM"])
        cpu = VMValue.int(payload["cpu"])
        memoryMiB = VMValue.int(payload["memoryMiB"])
        diskSize = VMValue.int(payload["diskSize"])
        storagePool = VMValue.string(payload["storagePool"])
        isExist = VMValue.bool(payload["isExist"])
        size = VMValue.int(payload["size"])
        status = VMValue.string(payload["status"])
        error = VMValue.string(payload["error"])
    }
}

public struct VMNetworkUsageModel: Identifiable, Hashable {
    public let ip: String
    public let vmName: String
    public let mac: String
    public let source: String

    public var id: String { "\(ip)-\(mac)-\(vmName)" }

    public init(payload: [String: Any]) {
        ip = VMValue.string(payload["ip"])
        vmName = VMValue.string(payload["vmName"])
        mac = VMValue.string(payload["mac"])
        source = VMValue.string(payload["source"])
    }
}

public struct VMNetworkModel: Identifiable, Hashable {
    public let networkId: Int
    public let name: String
    public let type: String
    public let bridgeName: String
    public let cidr: String
    public let gateway: String
    public let autoStart: Bool
    public let status: String
    public let error: String
    public let vmCount: Int
    public let registered: Bool
    public let usedIPs: [VMNetworkUsageModel]

    public var id: Int { networkId }

    public init(payload: [String: Any]) {
        networkId = VMValue.int(payload["id"])
        name = VMValue.string(payload["name"])
        type = VMValue.string(payload["type"])
        bridgeName = VMValue.string(payload["bridgeName"])
        cidr = VMValue.string(payload["cidr"])
        gateway = VMValue.string(payload["gateway"])
        autoStart = VMValue.bool(payload["autoStart"])
        status = VMValue.string(payload["status"])
        error = VMValue.string(payload["error"])
        vmCount = VMValue.int(payload["vmCount"])
        registered = VMValue.bool(payload["registered"])
        usedIPs = (payload["usedIPs"] as? [[String: Any]] ?? [])
            .map(VMNetworkUsageModel.init)
    }
}

public struct VMStorageModel: Identifiable, Hashable {
    public let storageId: Int
    public let name: String
    public let type: String
    public let path: String
    public let autoStart: Bool
    public let status: String
    public let error: String
    public let capacity: Int
    public let available: Int
    public let usedPercent: Double
    public let vmCount: Int

    public var id: Int { storageId }

    public init(payload: [String: Any]) {
        storageId = VMValue.int(payload["id"])
        name = VMValue.string(payload["name"])
        type = VMValue.string(payload["type"])
        path = VMValue.string(payload["path"])
        autoStart = VMValue.bool(payload["autoStart"])
        status = VMValue.string(payload["status"])
        error = VMValue.string(payload["error"])
        capacity = VMValue.int(payload["capacity"])
        available = VMValue.int(payload["available"])
        usedPercent = VMValue.double(payload["usedPercent"])
        vmCount = VMValue.int(payload["vmCount"])
    }
}

public struct VMHealthItemModel: Identifiable, Hashable {
    public let level: String
    public let check: String
    public let reason: String
    public let detail: String
    public let fixCommand: String

    public var id: String { "\(level)-\(check)-\(reason)" }

    public init(payload: [String: Any]) {
        level = VMValue.string(payload["level"])
        check = VMValue.string(payload["check"])
        reason = VMValue.string(payload["reason"])
        detail = VMValue.string(payload["detail"])
        fixCommand = VMValue.string(payload["fixCommand"])
    }
}

public struct VMHealthModel {
    public let pass: Int
    public let warn: Int
    public let fail: Int
    public let items: [VMHealthItemModel]

    public init(payload: [String: Any]) {
        pass = VMValue.int(payload["pass"])
        warn = VMValue.int(payload["warn"])
        fail = VMValue.int(payload["fail"])
        items = (payload["items"] as? [[String: Any]] ?? [])
            .map(VMHealthItemModel.init)
    }
}

public struct VMStatsSample {
    public let cpuPercent: Double
    public let memoryPercent: Double
    public let diskBytesPerSecond: Double
    public let networkBytesPerSecond: Double
    public let hasDelta: Bool
    public let isRunning: Bool

    public init(payload: [String: Any]) {
        cpuPercent = VMValue.double(payload["cpuPercent"])
        memoryPercent = VMValue.double(payload["memoryPercent"])
        diskBytesPerSecond = VMValue.double(payload["diskBytesPerSecond"])
        networkBytesPerSecond = VMValue.double(payload["networkBytesPerSecond"])
        hasDelta = VMValue.bool(payload["hasDelta"])
        isRunning = VMValue.bool(payload["isRunning"])
    }
}

enum VMValue {
    static func string(_ value: Any?) -> String {
        if let text = value as? String { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return ""
    }

    static func int(_ value: Any?) -> Int {
        if let number = value as? NSNumber { return number.intValue }
        if let text = value as? String { return Int(text) ?? 0 }
        return 0
    }

    static func double(_ value: Any?) -> Double {
        if let number = value as? NSNumber { return number.doubleValue }
        if let text = value as? String { return Double(text) ?? 0 }
        return 0
    }

    static func bool(_ value: Any?) -> Bool {
        if let flag = value as? Bool { return flag }
        if let number = value as? NSNumber { return number.boolValue }
        return false
    }
}

public enum VMFormatting {
    public static func bytes(_ value: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(value))
    }

    public static func mib(_ value: Int) -> String {
        bytes(value * 1024 * 1024)
    }

    public static func rate(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }

    public static func timestamp(_ millis: Int) -> String {
        guard millis > 0 else { return "--" }
        let date = Date(timeIntervalSince1970: Double(millis) / 1000)
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

/// 电源操作：由通道给出的能力标记决定可用项，文案键与图标两端共用。
public struct VMPowerAction: Identifiable, Equatable {
    public let id: String
    public let titleKey: String
    public let fallback: String
    public let icon: String
    public let destructive: Bool

    public init(
        id: String,
        titleKey: String,
        fallback: String,
        icon: String,
        destructive: Bool = false
    ) {
        self.id = id
        self.titleKey = titleKey
        self.fallback = fallback
        self.icon = icon
        self.destructive = destructive
    }

    public static func available(_ capabilities: VMCapabilities) -> [VMPowerAction] {
        var actions: [VMPowerAction] = []
        if capabilities.canStart {
            actions.append(VMPowerAction(
                id: "start", titleKey: "vmInstanceActionStart",
                fallback: "Start", icon: "play.fill"
            ))
        }
        if capabilities.canShutdown {
            actions.append(VMPowerAction(
                id: "shutdown", titleKey: "vmInstanceActionShutdown",
                fallback: "Shut Down", icon: "power", destructive: true
            ))
        }
        if capabilities.canReboot {
            actions.append(VMPowerAction(
                id: "reboot", titleKey: "vmInstanceActionReboot",
                fallback: "Reboot", icon: "restart"
            ))
        }
        if capabilities.canSuspend {
            actions.append(VMPowerAction(
                id: "suspend", titleKey: "vmInstanceActionSuspend",
                fallback: "Suspend", icon: "pause.fill"
            ))
        }
        if capabilities.canResume {
            actions.append(VMPowerAction(
                id: "resume", titleKey: "vmInstanceActionResume",
                fallback: "Resume", icon: "play.circle"
            ))
        }
        if capabilities.canDestroy {
            actions.append(VMPowerAction(
                id: "destroy", titleKey: "vmInstanceActionDestroy",
                fallback: "Force Off", icon: "bolt.slash.fill", destructive: true
            ))
        }
        return actions
    }
}