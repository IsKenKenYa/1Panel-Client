import Foundation

/// 虚拟机通道返回值的解码结构。
///
/// 状态语义、操作可用性与监控百分比由 Dart 侧通道计算，本层只负责把字段
/// 转成界面可直接消费的值类型。

struct VMCapabilities: Hashable {
    let canStart: Bool
    let canShutdown: Bool
    let canReboot: Bool
    let canSuspend: Bool
    let canResume: Bool
    let canDestroy: Bool
    let canMonitor: Bool
    let canOpenConsole: Bool
    let canCreateSnapshot: Bool
    let canHealthCheck: Bool
    let canResizeDisk: Bool

    static let none = VMCapabilities(
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

    init(
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

    init(payload: [String: Any]) {
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

struct VMDiskModel: Identifiable, Hashable {
    let target: String
    let device: String
    let capacity: Int
    let format: String
    let bus: String
    let source: String
    let readOnly: Bool

    var id: String { "\(target)-\(device)-\(source)" }

    init(payload: [String: Any]) {
        target = VMValue.string(payload["target"])
        device = VMValue.string(payload["device"])
        capacity = VMValue.int(payload["capacity"])
        format = VMValue.string(payload["format"])
        bus = VMValue.string(payload["bus"])
        source = VMValue.string(payload["source"])
        readOnly = VMValue.bool(payload["readOnly"])
    }
}

struct VMInterfaceModel: Identifiable, Hashable {
    let type: String
    let source: String
    let model: String
    let mac: String
    let ip: String

    var id: String { "\(mac)-\(source)-\(ip)" }

    init(payload: [String: Any]) {
        type = VMValue.string(payload["type"])
        source = VMValue.string(payload["source"])
        model = VMValue.string(payload["model"])
        mac = VMValue.string(payload["mac"])
        ip = VMValue.string(payload["ip"])
    }
}

struct VMGraphicsModel: Hashable {
    let type: String
    let port: String
    let listen: String

    init(payload: [String: Any]) {
        type = VMValue.string(payload["type"])
        port = VMValue.string(payload["port"])
        listen = VMValue.string(payload["listen"])
    }
}

struct VMInstanceModel: Identifiable, Hashable {
    let name: String
    let serverId: Int
    let uuid: String
    let status: String
    let statusKey: String
    let statusTone: String
    let cpu: Int
    let memoryMiB: Int
    let diskSize: Int
    let diskBus: String
    let diskPath: String
    let storagePool: String
    let network: String
    let bootOrder: String
    let autoStart: Bool
    let description: String
    let graphicsType: String
    let capabilities: VMCapabilities
    let disks: [VMDiskModel]
    let interfaces: [VMInterfaceModel]
    let isoPaths: [String]
    let graphics: VMGraphicsModel?

    var id: String { name }

    init(payload: [String: Any]) {
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

struct VMEnvironmentModel {
    let arch: String
    let archSupported: Bool
    let ready: Bool
    let helperExist: Bool
    let helperMessage: String
    let kvmExist: Bool
    let kvmMessage: String
    let libvirtExist: Bool
    let libvirtActive: Bool
    let libvirtMessage: String
    let storageExist: Bool
    let storageMessage: String

    static let empty = VMEnvironmentModel(
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

    init(
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

    init(payload: [String: Any]) {
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

struct VMSnapshotModel: Identifiable, Hashable {
    let name: String
    let description: String
    let createdAtMillis: Int
    let state: String
    let size: Int
    let current: Bool
    let canRecover: Bool

    var id: String { name }

    init(payload: [String: Any]) {
        name = VMValue.string(payload["name"])
        description = VMValue.string(payload["description"])
        createdAtMillis = VMValue.int(payload["createdAtMillis"])
        state = VMValue.string(payload["state"])
        size = VMValue.int(payload["size"])
        current = VMValue.bool(payload["current"])
        canRecover = VMValue.bool(payload["canRecover"])
    }
}

struct VMSnapshotResult {
    let canCreate: Bool
    let canRecover: Bool
    let items: [VMSnapshotModel]

    init(payload: [String: Any]) {
        canCreate = VMValue.bool(payload["canCreate"])
        canRecover = VMValue.bool(payload["canRecover"])
        items = (payload["items"] as? [[String: Any]] ?? []).map(VMSnapshotModel.init)
    }
}

struct VMIsoModel: Identifiable, Hashable {
    let isoId: Int
    let type: String
    let name: String
    let path: String
    let isExist: Bool
    let size: Int
    let status: String
    let error: String

    var id: Int { isoId }

    init(payload: [String: Any]) {
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

struct VMTemplateModel: Identifiable, Hashable {
    let templateId: Int
    let name: String
    let sourceVM: String
    let cpu: Int
    let memoryMiB: Int
    let diskSize: Int
    let storagePool: String
    let isExist: Bool
    let size: Int
    let status: String
    let error: String

    var id: Int { templateId }

    init(payload: [String: Any]) {
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

struct VMNetworkUsageModel: Identifiable, Hashable {
    let ip: String
    let vmName: String
    let mac: String
    let source: String

    var id: String { "\(ip)-\(mac)-\(vmName)" }

    init(payload: [String: Any]) {
        ip = VMValue.string(payload["ip"])
        vmName = VMValue.string(payload["vmName"])
        mac = VMValue.string(payload["mac"])
        source = VMValue.string(payload["source"])
    }
}

struct VMNetworkModel: Identifiable, Hashable {
    let networkId: Int
    let name: String
    let type: String
    let bridgeName: String
    let cidr: String
    let gateway: String
    let autoStart: Bool
    let status: String
    let error: String
    let vmCount: Int
    let registered: Bool
    let usedIPs: [VMNetworkUsageModel]

    var id: Int { networkId }

    init(payload: [String: Any]) {
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

struct VMStorageModel: Identifiable, Hashable {
    let storageId: Int
    let name: String
    let type: String
    let path: String
    let autoStart: Bool
    let status: String
    let error: String
    let capacity: Int
    let available: Int
    let usedPercent: Double
    let vmCount: Int

    var id: Int { storageId }

    init(payload: [String: Any]) {
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

struct VMHealthItemModel: Identifiable, Hashable {
    let level: String
    let check: String
    let reason: String
    let detail: String
    let fixCommand: String

    var id: String { "\(level)-\(check)-\(reason)" }

    init(payload: [String: Any]) {
        level = VMValue.string(payload["level"])
        check = VMValue.string(payload["check"])
        reason = VMValue.string(payload["reason"])
        detail = VMValue.string(payload["detail"])
        fixCommand = VMValue.string(payload["fixCommand"])
    }
}

struct VMHealthModel {
    let pass: Int
    let warn: Int
    let fail: Int
    let items: [VMHealthItemModel]

    init(payload: [String: Any]) {
        pass = VMValue.int(payload["pass"])
        warn = VMValue.int(payload["warn"])
        fail = VMValue.int(payload["fail"])
        items = (payload["items"] as? [[String: Any]] ?? [])
            .map(VMHealthItemModel.init)
    }
}

struct VMStatsSample {
    let cpuPercent: Double
    let memoryPercent: Double
    let diskBytesPerSecond: Double
    let networkBytesPerSecond: Double
    let hasDelta: Bool
    let isRunning: Bool

    init(payload: [String: Any]) {
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

enum VMFormatting {
    static func bytes(_ value: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(value))
    }

    static func mib(_ value: Int) -> String {
        bytes(value * 1024 * 1024)
    }

    static func rate(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }

    static func timestamp(_ millis: Int) -> String {
        guard millis > 0 else { return "--" }
        let date = Date(timeIntervalSince1970: Double(millis) / 1000)
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}