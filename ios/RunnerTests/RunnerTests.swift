import Foundation
import XCTest
import AppleSharedUI
@testable import Runner

class FirewallRuleModelTests: XCTestCase {
    func testUsesInventoryIdentityForAllowedModernRow() throws {
        let rule = try XCTUnwrap(FirewallRuleModel(payload: [
            "id": "display-id", "inventoryId": "inventory-id", "serverId": "server-id",
            "canDelete": true, "port": "443", "protocol": "tcp", "strategy": "accept",
        ]))

        XCTAssertEqual(rule.deletionArguments, ["inventoryId": "inventory-id", "serverId": "server-id"])
    }

    func testModernRowRequiresPermissionAndServer() throws {
        let blocked = try XCTUnwrap(FirewallRuleModel(payload: [
            "id": "row", "inventoryId": "inventory-id", "serverId": "server-id", "canDelete": false,
        ]))
        let missingServer = try XCTUnwrap(FirewallRuleModel(payload: [
            "id": "row", "inventoryId": "inventory-id", "canDelete": true, "supportsLegacyChanges": true,
        ]))

        XCTAssertNil(blocked.deletionArguments)
        XCTAssertNil(missingServer.deletionArguments)
    }

    func testLegacyRowKeepsTupleAndUsesServerWhenAvailable() throws {
        let payload: [String: Any] = [
            "id": 1, "supportsLegacyChanges": true,
            "port": "443", "protocol": "tcp", "address": "192.0.2.1", "strategy": "accept",
        ]
        let oldRow = try XCTUnwrap(FirewallRuleModel(payload: payload))
        let serverRow = try XCTUnwrap(FirewallRuleModel(payload: payload.merging([
            "serverId": "server-id",
        ]) { _, value in value }))
        let blocked = try XCTUnwrap(FirewallRuleModel(payload: payload.merging([
            "canDelete": false,
        ]) { _, value in value }))

        let tuple = ["port": "443", "protocol": "tcp", "address": "192.0.2.1", "strategy": "accept"]
        XCTAssertEqual(oldRow.deletionArguments, tuple)
        XCTAssertEqual(serverRow.deletionArguments, tuple.merging(["serverId": "server-id"]) { _, value in value })
        XCTAssertNil(blocked.deletionArguments)
    }
}

class RunnerTests: XCTestCase {
    func testImplicitModePreservesExistingAppLockSettings() {
        XCTAssertEqual(UIRenderMode.resolve(nil, appLockEnabled: false), .native)
        XCTAssertEqual(UIRenderMode.resolve(nil, appLockEnabled: true), .liquidGlass)
        XCTAssertEqual(UIRenderMode.resolve("unknown", appLockEnabled: true), .liquidGlass)
    }

    func testExplicitRenderModeTakesPrecedence() {
        for mode: UIRenderMode in [.native, .md3, .liquidGlass] {
            XCTAssertEqual(UIRenderMode.resolve(mode.rawValue, appLockEnabled: true), mode)
            XCTAssertEqual(UIRenderMode.resolve(mode.rawValue, appLockEnabled: false), mode)
        }
    }

    func testInstalledAppIdentityDistinguishesInstallationsOfOneCatalogApp() {
        let catalog: [String: Any] = ["appId": 7, "name": "Redis", "status": "Running", "version": "8.0"]
        func installation(_ id: Any) -> [String: Any] {
            catalog.merging(["installId": id]) { _, newValue in newValue }
        }

        XCTAssertEqual(AppModel(payload: installation(41))?.id, 41)
        XCTAssertEqual(AppModel(payload: installation(42))?.id, 42)
        XCTAssertNil(AppModel(payload: catalog))
        XCTAssertNil(AppModel(payload: installation(0)))
        XCTAssertNil(AppModel(payload: installation(-1)))
        XCTAssertNil(AppModel(payload: installation("41")))
    }

    @MainActor
    func testSwitchingModulesKeepsServerAsPreviousPage() {
        let server = ServerModel(originalId: "1", revision: "first", name: "1Panel", url: "https://panel.example",
                                 isCurrent: true, cpu: 0, memory: 0)
        let navigation = ServerNavigation()
        navigation.openServer(server, module: .containers)

        navigation.switchModule(to: .websites)
        navigation.switchModule(to: .apps)

        XCTAssertEqual(navigation.path, [.server(server), .module(.apps)])
        navigation.path.removeLast()
        XCTAssertEqual(navigation.path, [.server(server)])
    }

    @MainActor
    func testSwitchingModulesFromDetailDropsDetailPage() {
        let server = ServerModel(originalId: "1", revision: "first", name: "1Panel", url: "https://panel.example",
                                 isCurrent: true, cpu: 0, memory: 0)
        let navigation = ServerNavigation()
        navigation.openServer(server, module: .apps)
        navigation.path.append(.appInstall(id: 16))

        navigation.switchModule(to: .containers)

        // 模块切换退回到服务器首页下的目标模块，详情页不留在新的模块层级里。
        XCTAssertEqual(navigation.path, [.server(server), .module(.containers)])
    }

    func testAppModelKeepsIconFromListPayload() throws {
        let model = try XCTUnwrap(AppModel(payload: [
            "installId": 16, "name": "OpenResty", "status": "Running",
            "version": "1.31.1", "icon": "https://example.test/logo.png",
        ]))
        let withoutIcon = try XCTUnwrap(AppModel(payload: [
            "installId": 18, "name": "MySQL", "status": "Running", "version": "8.4.11",
        ]))

        XCTAssertEqual(model.icon, "https://example.test/logo.png")
        XCTAssertEqual(withoutIcon.icon, "")
    }
}

class VirtualMachineModelTests: XCTestCase {
    func testSummaryPayloadDecodesCapabilitiesAndStatusTone() {
        let payload: [String: Any] = [
            "id": 7,
            "name": "demo",
            "status": "shut off",
            "statusKey": "shut off",
            "statusTone": "neutral",
            "cpu": 2,
            "memoryMiB": 2048,
            "diskSize": 1073741824,
            "network": "default",
            "autoStart": true,
            "capabilities": [
                "canStart": true,
                "canShutdown": false,
                "canCreateSnapshot": true,
                "canMonitor": false,
            ],
        ]

        let model = VMInstanceModel(payload: payload)

        XCTAssertEqual(model.name, "demo")
        XCTAssertEqual(model.serverId, 7)
        XCTAssertEqual(model.statusTone, "neutral")
        XCTAssertTrue(model.capabilities.canStart)
        XCTAssertFalse(model.capabilities.canShutdown)
        XCTAssertTrue(model.capabilities.canCreateSnapshot)
        XCTAssertFalse(model.capabilities.canMonitor)
    }

    func testDetailPayloadDecodesDisksInterfacesAndGraphics() {
        let payload: [String: Any] = [
            "name": "detail",
            "status": "running",
            "statusTone": "positive",
            "uuid": "uuid-1",
            "bootOrder": "cdrom,hd",
            "isoPaths": ["/iso/a.iso"],
            "disks": [
                ["target": "vda", "capacity": 20, "bus": "virtio", "format": "qcow2"],
            ],
            "interfaces": [
                ["source": "default", "mac": "52:54:00:00:00:01", "ip": "192.168.1.10"],
            ],
            "graphics": ["type": "vnc", "port": "5900", "listen": "127.0.0.1"],
            "capabilities": ["canMonitor": true, "canOpenConsole": true],
        ]

        let model = VMInstanceModel(payload: payload)

        XCTAssertEqual(model.uuid, "uuid-1")
        XCTAssertEqual(model.isoPaths, ["/iso/a.iso"])
        XCTAssertEqual(model.disks.first?.target, "vda")
        XCTAssertEqual(model.disks.first?.bus, "virtio")
        XCTAssertEqual(model.interfaces.first?.ip, "192.168.1.10")
        XCTAssertEqual(model.graphics?.port, "5900")
        XCTAssertTrue(model.capabilities.canMonitor)
        XCTAssertTrue(model.capabilities.canOpenConsole)
    }

    func testSnapshotPayloadUsesMillisecondsAndRecoverFlag() {
        let snapshot = VMSnapshotModel(payload: [
            "name": "snap-1",
            "createdAtMillis": 1730000000000,
            "current": true,
            "canRecover": false,
            "size": 4096,
        ])

        XCTAssertEqual(snapshot.name, "snap-1")
        XCTAssertEqual(snapshot.createdAtMillis, 1730000000000)
        XCTAssertTrue(snapshot.current)
        XCTAssertFalse(snapshot.canRecover)
    }

    func testStatsSampleDecodesComputedPercentages() {
        let sample = VMStatsSample(payload: [
            "cpuPercent": 42.5,
            "memoryPercent": 61.0,
            "diskBytesPerSecond": 2048.0,
            "networkBytesPerSecond": 512.0,
            "hasDelta": true,
            "isRunning": true,
        ])

        XCTAssertEqual(sample.cpuPercent, 42.5)
        XCTAssertEqual(sample.memoryPercent, 61.0)
        XCTAssertTrue(sample.hasDelta)
        XCTAssertTrue(sample.isRunning)
    }

    func testModuleRouteExposesVirtualMachinesEntry() {
        XCTAssertTrue(ModuleRoute.allCases.contains(.virtualMachines))
        XCTAssertEqual(ModuleRoute(rawValue: "virtualMachines"), .virtualMachines)
    }
}

class AlertModelTests: XCTestCase {
    func testRulePayloadDecodesStatusAndMethods() {
        let rule = AlertRuleModel(payload: [
            "id": 3,
            "type": "cpu",
            "title": "CPU alert",
            "status": "Enable",
            "statusTone": "positive",
            "enabled": true,
            "cycle": 30,
            "count": 80,
            "interval": 5,
            "sendCount": 2,
            "sendMethod": ["mail", "hook"],
            "alertTriggerMode": "failed",
        ])

        XCTAssertEqual(rule.ruleId, 3)
        XCTAssertEqual(rule.title, "CPU alert")
        XCTAssertTrue(rule.enabled)
        XCTAssertEqual(rule.statusTone, "positive")
        XCTAssertEqual(rule.sendMethod, ["mail", "hook"])
        XCTAssertEqual(rule.interval, 5)
    }

    func testLogPayloadDecodesFlattenedFields() {
        let log = AlertLogModel(payload: [
            "id": 9,
            "alertId": 3,
            "title": "Disk warning",
            "type": "disk",
            "message": "Usage above threshold",
            "status": "Error",
            "statusTone": "negative",
            "method": "mail",
            "count": 4,
            "createdAt": "2026-11-23 00:00:00",
        ])

        XCTAssertEqual(log.title, "Disk warning")
        XCTAssertEqual(log.statusTone, "negative")
        XCTAssertEqual(log.count, 4)
        XCTAssertEqual(log.message, "Usage above threshold")
    }

    func testChannelPayloadDecodesCapabilityFlags() {
        let channel = AlertChannelModel(payload: [
            "id": 5,
            "type": "custom",
            "title": "Hook",
            "config": "{\"url\":\"https://example.test\"}",
            "configSummary": "{\"url\":\"https://example.test\"}",
            "status": "Enable",
            "enabled": true,
            "statusTone": "positive",
            "isEmail": false,
            "isWebhook": true,
            "supportsTest": true,
        ])

        XCTAssertEqual(channel.channelId, 5)
        XCTAssertTrue(channel.enabled)
        XCTAssertTrue(channel.isWebhook)
        XCTAssertTrue(channel.supportsTest)
        XCTAssertFalse(channel.isEmail)
        XCTAssertEqual(channel.formInput["type"] as? String, "custom")
    }

    func testOptionsDecodeRuleAndChannelTypes() {
        let options = AlertOptions(payload: [
            "ruleTypes": [
                ["type": "cpu", "needsThreshold": true, "needsInterval": true],
                ["type": "ssl", "needsCycleDays": true, "needsCertificate": true],
            ],
            "channelTypes": [
                ["type": "email", "isEmail": true, "supportsTest": true],
                ["type": "custom", "isWebhook": true, "isCustom": true, "supportsTest": true],
            ],
            "encryptions": ["NONE", "SSL", "TLS"],
            "webhookPresets": [
                ["key": "genericJson", "template": "{\"title\":\"{{title}}\"}"],
            ],
        ])

        XCTAssertTrue(options.ruleType("cpu")?.needsThreshold == true)
        XCTAssertTrue(options.ruleType("ssl")?.needsCertificate == true)
        XCTAssertTrue(options.channelType("email")?.isEmail == true)
        XCTAssertTrue(options.channelType("custom")?.isCustom == true)
        XCTAssertEqual(options.preset("genericJson")?.template, "{\"title\":\"{{title}}\"}")
    }

    func testModuleRouteExposesAlertsEntry() {
        XCTAssertTrue(ModuleRoute.allCases.contains(.alerts))
        XCTAssertEqual(ModuleRoute(rawValue: "alerts"), .alerts)
    }
}

class ModelDownloaderModelTests: XCTestCase {
    func testFeaturedPayloadDecodesPreferredSource() {
        let model = FeaturedModelItem(payload: [
            "key": "qwen",
            "repoID": "Qwen/Qwen3",
            "family": "Qwen",
            "architecture": "Transformer",
            "weightGB": 8.5,
            "sources": ["modelScope", "hf"],
            "preferredSource": "modelScope",
            "preferredRepoID": "Qwen/Qwen3-ms",
            "description": ["en": "General model", "zh": "通用模型"],
        ])

        XCTAssertEqual(model.id, "qwen")
        XCTAssertEqual(model.preferredSource, "modelScope")
        XCTAssertEqual(model.preferredRepoID, "Qwen/Qwen3-ms")
        XCTAssertEqual(model.weightGB, 8.5)
        XCTAssertFalse(model.localizedDescription().isEmpty)
    }

    func testTaskPayloadDecodesProgressAndActions() {
        let task = DownloadTaskItem(payload: [
            "id": 12,
            "modelName": "qwen",
            "status": "running",
            "statusTone": "info",
            "progressRatio": 0.42,
            "downloadedSize": 1024,
            "totalSize": 4096,
            "canCancel": true,
            "canRetry": false,
            "canRemoveRecord": true,
        ])

        XCTAssertEqual(task.taskId, 12)
        XCTAssertEqual(task.progressRatio, 0.42)
        XCTAssertEqual(task.statusTone, "info")
        XCTAssertTrue(task.canCancel)
        XCTAssertTrue(task.canRemoveRecord)
    }

    func testSettingsPayloadDecodesSyncFlag() {
        let settings = DownloaderSettingsModel(payload: [
            "modelDir": "/models",
            "featuredSyncEnabled": true,
            "hfEndpoint": "https://hf.example.test",
            "hfToken": "token",
        ])

        XCTAssertEqual(settings.modelDir, "/models")
        XCTAssertTrue(settings.featuredSyncEnabled)
        XCTAssertEqual(settings.hfEndpoint, "https://hf.example.test")
    }

    func testOptionsDecodeSourcesAndStatuses() {
        let options = DownloaderOptions(payload: [
            "sources": ["hf", "modelScope"],
            "sorts": ["trending", "downloads"],
            "downloadTypes": ["all", "tokenizer"],
            "taskStatuses": ["running", "completed"],
        ])

        XCTAssertEqual(options.sources, ["hf", "modelScope"])
        XCTAssertEqual(options.downloadTypes, ["all", "tokenizer"])
        XCTAssertTrue(options.taskStatuses.contains("running"))
    }

    func testModuleRouteExposesModelDownloaderEntry() {
        XCTAssertTrue(ModuleRoute.allCases.contains(.modelDownloader))
        XCTAssertEqual(ModuleRoute(rawValue: "modelDownloader"), .modelDownloader)
    }
}

class MonitorHistoryModelTests: XCTestCase {
    func testSeriesPayloadDecodesPointsAndAggregates() {
        let series = MonitorSeries(payload: [
            "name": "cpu",
            "min": 10.0,
            "max": 30.0,
            "avg": 20.0,
            "count": 2,
            "points": [
                ["time": 1000, "value": 10.0],
                ["time": 2000, "value": 30.0],
            ],
        ])

        XCTAssertEqual(series.points.count, 2)
        XCTAssertEqual(series.points.first?.timeMillis, 1000)
        XCTAssertEqual(series.points.last?.value, 30)
        XCTAssertEqual(series.min, 10)
        XCTAssertEqual(series.avg, 20)
    }

    func testHistoryPayloadDecodesThreeSeries() {
        let empty: [String: Any] = ["points": [[String: Any]()], "min": 0, "max": 0, "avg": 0]
        let history = MonitorHistory(payload: [
            "cpu": empty,
            "memory": empty,
            "load": empty,
        ])

        XCTAssertEqual(history.cpu.points.count, 1)
        XCTAssertEqual(history.memory.points.count, 1)
        XCTAssertEqual(history.load.points.count, 1)
    }

    func testSettingsPayloadDecodesFields() {
        let settings = MonitorSettingsModel(payload: [
            "enabled": true,
            "interval": 30,
            "retention": 7,
            "defaultNetwork": "eth0",
            "defaultIO": "sda",
        ])

        XCTAssertTrue(settings.enabled)
        XCTAssertEqual(settings.interval, 30)
        XCTAssertEqual(settings.retention, 7)
        XCTAssertEqual(settings.defaultNetwork, "eth0")
    }
}

class OperationsRouteTests: XCTestCase {
    func testModuleRouteExposesOperationsEntries() {
        let routes: [ModuleRoute] = [
            .runtime, .toolbox, .processes, .ssh, .disk, .openresty, .group, .hostAssets,
        ]
        for route in routes {
            XCTAssertTrue(ModuleRoute.allCases.contains(route))
            XCTAssertEqual(ModuleRoute(rawValue: route.rawValue), route)
        }
    }

    func testModuleRouteTitleKeysResolve() {
        let translations = TranslationsManager.shared
        for route in ModuleRoute.allCases {
            XCTAssertFalse(route.title(translations).isEmpty)
        }
    }
}

class ReleaseManifestTests: XCTestCase {
    func testInfoPlistContainsReleaseKeys() throws {
        let info = try XCTUnwrap(Bundle.main.infoDictionary)
        XCTAssertEqual(info["ITSAppUsesNonExemptEncryption"] as? Bool, false)
        XCTAssertFalse((info["NSLocalNetworkUsageDescription"] as? String ?? "").isEmpty)
        let scene = try XCTUnwrap(info["UIApplicationSceneManifest"] as? [String: Any])
        XCTAssertEqual(scene["UIApplicationSupportsMultipleScenes"] as? Bool, false)
    }

    func testPrivacyManifestDeclaresUserDefaultsReason() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        )
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        let manifest = try XCTUnwrap(plist as? [String: Any])
        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        let apis = try XCTUnwrap(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let declared = apis.contains { entry in
            (entry["NSPrivacyAccessedAPIType"] as? String)
                == "NSPrivacyAccessedAPICategoryUserDefaults"
        }
        XCTAssertTrue(declared)
    }
}

class OperationsDetailModelTests: XCTestCase {
    func testBackupModelPreservesDetailFields() {
        let backup = BackupModel(
            id: 7,
            name: "site-backup",
            type: "website",
            size: "4096",
            status: "Success",
            createdAt: "2026-11-23 00:00:00",
            detailName: "example.test",
            fileName: "backup.tar.gz",
            fileDir: "/opt/1panel/backup",
            downloadAccountID: 3
        )

        XCTAssertEqual(backup.detailName, "example.test")
        XCTAssertEqual(backup.fileName, "backup.tar.gz")
        XCTAssertEqual(backup.fileDir, "/opt/1panel/backup")
        XCTAssertEqual(backup.downloadAccountID, 3)
    }

    func testCronjobDetailLabelsResolve() {
        let translations = TranslationsManager.shared
        for key in [
            "cronjobsDetailTitle", "cronjobsGroupLabel", "cronjobsCommandLabel",
            "cronjobsSpecLabel", "cronjobsNextRunLabel", "cronjobsRecordsAction",
        ] {
            XCTAssertFalse(translations.get(key, fallback: "").isEmpty)
        }
    }

    func testBackupDetailLabelsResolve() {
        let translations = TranslationsManager.shared
        for key in [
            "backupRecordsDetailTitle", "backupRecordsFileNameLabel",
            "backupRecordsFilePathLabel", "backupRecordsAccountLabel",
        ] {
            XCTAssertFalse(translations.get(key, fallback: "").isEmpty)
        }
    }
}

class LogAndSecurityDetailModelTests: XCTestCase {
    func testOperationLogRowCarriesMessageForDetail() {
        let row = OperationLogRow(
            id: 1,
            source: "1Panel",
            ip: "192.0.2.10",
            path: "/api/v2/hosts",
            method: "GET",
            status: "200",
            message: "request completed"
        )

        XCTAssertEqual(row.path, "/api/v2/hosts")
        XCTAssertEqual(row.method, "GET")
        XCTAssertEqual(row.message, "request completed")
    }

    func testLoginLogRowCarriesMessageForDetail() {
        let row = LoginLogRow(
            id: 2,
            ip: "192.0.2.11",
            address: "Fuzhou",
            status: "Success",
            createdAt: "2026-11-23 00:00:00",
            message: "login succeeded"
        )

        XCTAssertEqual(row.ip, "192.0.2.11")
        XCTAssertEqual(row.address, "Fuzhou")
        XCTAssertEqual(row.message, "login succeeded")
    }

    func testLogAndSecurityDetailLabelsResolve() {
        let translations = TranslationsManager.shared
        for key in [
            "logsOperationDetailTitle", "logsLoginDetailTitle",
            "logsDetailMessageLabel", "logsOperationPathLabel",
            "securitySshDetailTitle", "securityPanelSslDetailTitle",
            "securityPanelSslExpireDateLabel",
        ] {
            XCTAssertFalse(translations.get(key, fallback: "").isEmpty)
        }
    }
}

private final class RecordingFirewallChannel: DataChannel {
    private(set) var calls: [(method: String, arguments: [String: Any]?)] = []

    func invoke(_ method: String, arguments: Any?) async throws -> Any? {
        calls.append((method, arguments as? [String: Any]))
        return ["success": true]
    }
}

@MainActor
final class FirewallV2StoreMutationTests: XCTestCase {
    func testUpdateForwardRuleSendsRemoveAndAdd() async throws {
        let channel = RecordingFirewallChannel()
        let store = FirewallV2Store(channel: channel)
        let rule = try XCTUnwrap(FirewallForwardRule(payload: [
            "id": 1,
            "port": "8080",
            "protocol": "tcp",
            "targetIP": "10.0.0.2",
            "targetPort": "80",
            "strategy": "accept",
        ]))

        try await store.updateForwardRule(
            rule,
            port: "9090",
            protocolName: "udp",
            targetIP: "10.0.0.3",
            targetPort: "90",
            interfaceName: "eth0"
        )

        let call = try XCTUnwrap(channel.calls.first)
        XCTAssertEqual(call.method, "operateFirewallForwardRules")
        let rules = try XCTUnwrap(call.arguments?["rules"] as? [[String: Any]])
        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules.first?["operation"] as? String, "remove")
        XCTAssertEqual(rules.first?["port"] as? String, "8080")
        XCTAssertEqual(rules.last?["operation"] as? String, "add")
        XCTAssertEqual(rules.last?["port"] as? String, "9090")
        XCTAssertEqual(rules.last?["targetIP"] as? String, "10.0.0.3")
        XCTAssertEqual(rules.last?["interface"] as? String, "eth0")
    }

    func testBatchDockerPoliciesApplyModeToAll() async throws {
        let channel = RecordingFirewallChannel()
        let store = FirewallV2Store(channel: channel)
        let first = try XCTUnwrap(FirewallDockerPolicy(payload: [
            "id": "policy-a",
            "hostIP": "0.0.0.0",
            "hostPort": "8080",
            "family": "ipv4",
            "protocol": "tcp",
            "mode": "deny_sources",
        ]))
        let second = try XCTUnwrap(FirewallDockerPolicy(payload: [
            "id": "policy-b",
            "hostIP": "::",
            "hostPort": "8443",
            "family": "ipv6",
            "protocol": "tcp",
            "mode": "deny_all",
        ]))

        try await store.updateDockerPolicies(
            [first, second],
            mode: "allow_sources",
            sources: ["10.0.0.0/8"]
        )

        let call = try XCTUnwrap(channel.calls.first)
        XCTAssertEqual(call.method, "upsertFirewallDockerPolicies")
        let policies = try XCTUnwrap(call.arguments?["policies"] as? [[String: Any]])
        XCTAssertEqual(policies.count, 2)
        XCTAssertTrue(policies.allSatisfy { $0["mode"] as? String == "allow_sources" })
        XCTAssertTrue(policies.allSatisfy {
            ($0["sources"] as? [String]) == ["10.0.0.0/8"]
        })
        XCTAssertEqual(policies.first?["hostPort"] as? Int, 8080)
        XCTAssertEqual(policies.last?["hostPort"] as? Int, 8443)
    }

    func testBackendOperationSendsInitialize() async throws {
        let channel = RecordingFirewallChannel()
        let store = FirewallV2Store(channel: channel)

        try await store.operateBackend(
            subsystem: "system",
            backend: "nftables",
            operation: "initialize"
        )

        let call = try XCTUnwrap(channel.calls.first)
        XCTAssertEqual(call.method, "operateFirewallBackend")
        XCTAssertEqual(call.arguments?["subsystem"] as? String, "system")
        XCTAssertEqual(call.arguments?["backend"] as? String, "nftables")
        XCTAssertEqual(call.arguments?["operation"] as? String, "initialize")
    }

    func testBackendOperationRejectsUnknownOperation() async {
        let channel = RecordingFirewallChannel()
        let store = FirewallV2Store(channel: channel)

        do {
            try await store.operateBackend(
                subsystem: "system",
                backend: "nftables",
                operation: "restart"
            )
            XCTFail("Expected unsupported operation to throw")
        } catch {
            XCTAssertTrue(channel.calls.isEmpty)
        }
    }
}

class DockerPolicyImportTests: XCTestCase {
    func testPreviewRemovesDuplicateEndpoints() throws {
        let data = try XCTUnwrap("""
        [
          {"family":"ipv4","hostIP":"0.0.0.0","hostPort":8080,"protocol":"tcp",
           "mode":"deny_sources","sources":["10.0.0.0/8"]},
          {"family":"ipv4","hostIP":"0.0.0.0","hostPort":8080,"protocol":"tcp",
           "mode":"allow_sources","sources":["192.0.2.0/24"]},
          {"family":"ipv6","hostIP":"::","hostPort":8443,"protocol":"tcp",
           "mode":"accept_all","sources":[]}
        ]
        """.data(using: .utf8))

        let rows = try XCTUnwrap(DockerPolicyBatchFormView.parseImportRows(data))

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows.first?.hostPort, 8080)
        XCTAssertEqual(rows.first?.sources, ["10.0.0.0/8"])
        XCTAssertEqual(rows.last?.family, "ipv6")
    }

    func testPreviewReportsInvalidReasonAndDuplicateCount() throws {
        let data = try XCTUnwrap("""
        [
          {"hostIP":"0.0.0.0","hostPort":70000,"protocol":"tcp","mode":"deny_all"},
          {"family":"ipv4","hostIP":"127.0.0.1","hostPort":9090,"protocol":"udp",
           "mode":"deny_all","sources":[]},
          {"family":"ipv4","hostIP":"127.0.0.1","hostPort":9090,"protocol":"udp",
           "mode":"allow_sources","sources":["10.0.0.0/8"]}
        ]
        """.data(using: .utf8))

        let result = try XCTUnwrap(DockerPolicyBatchFormView.parseImportResult(data))

        XCTAssertEqual(result.totalCount, 3)
        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.duplicateCount, 1)
        XCTAssertEqual(result.issues.count, 1)
        XCTAssertEqual(result.issues.first?.id, 0)
        if case .invalidPort = result.issues.first?.reason {
        } else {
            XCTFail("Expected invalid port reason")
        }
    }

    func testImportLimitsUseBatchAndFileSizeCaps() {
        XCTAssertFalse(DockerPolicyBatchFormView.exceedsImportLimits(
            fileSize: DockerPolicyBatchFormView.maxImportFileSize,
            policyCount: DockerPolicyBatchFormView.maxBatchLimit
        ))
        XCTAssertTrue(DockerPolicyBatchFormView.exceedsImportLimits(
            fileSize: DockerPolicyBatchFormView.maxImportFileSize + 1,
            policyCount: 0
        ))
        XCTAssertTrue(DockerPolicyBatchFormView.exceedsImportLimits(
            fileSize: 1024,
            policyCount: DockerPolicyBatchFormView.maxBatchLimit + 1
        ))
    }

    func testPreviewSkipsInvalidPoliciesAndAcceptsPoliciesObject() throws {
        let data = try XCTUnwrap("""
        {"policies":[
          {"hostIP":"0.0.0.0","hostPort":70000,"protocol":"tcp","mode":"deny_all"},
          {"family":"ipv4","hostIP":"127.0.0.1","hostPort":9090,"protocol":"udp",
           "mode":"deny_all","sources":[]}
        ]}
        """.data(using: .utf8))

        let rows = try XCTUnwrap(DockerPolicyBatchFormView.parseImportRows(data))

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.hostIP, "127.0.0.1")
        XCTAssertEqual(rows.first?.protocolName, "udp")
        XCTAssertEqual(rows.first?.payload["hostPort"] as? Int, 9090)
    }
}

class WebsiteLoadBalancerTests: XCTestCase {
    func testParsesServersAndSkipsZeroParameters() throws {
        let balancer = try XCTUnwrap(WebsiteLoadBalancer(payload: [
            "name": "lb-main",
            "algorithm": "least_conn",
            "servers": [
                ["server": "127.0.0.1:8080", "weight": 3, "flag": "down",
                 "maxFails": 0, "maxConns": 12, "failTimeout": 0,
                 "failTimeoutUnit": "s"],
            ],
        ]))

        XCTAssertEqual(balancer.name, "lb-main")
        XCTAssertEqual(balancer.algorithm, "least_conn")
        XCTAssertEqual(balancer.servers.count, 1)
        let server = try XCTUnwrap(balancer.servers.first)
        XCTAssertEqual(server.weight, 3)
        XCTAssertNil(server.maxFails)
        XCTAssertEqual(server.maxConns, 12)
        XCTAssertEqual(server.flag, "down")
        XCTAssertEqual(server.payload["maxFails"] as? Int, 0)
    }

    func testValidationRejectsDuplicateAndOutOfRangeParameters() {
        let duplicate = WebsiteLoadBalancerValidator.validate(
            name: "lb",
            algorithm: "default",
            servers: [
                WebsiteLoadBalancerServer(server: "10.0.0.1:80"),
                WebsiteLoadBalancerServer(server: "10.0.0.1:80"),
            ]
        )
        XCTAssertEqual(duplicate, .duplicateServer)

        let weight = WebsiteLoadBalancerValidator.validate(
            name: "lb",
            algorithm: "default",
            servers: [WebsiteLoadBalancerServer(server: "10.0.0.2:80", weight: 101)]
        )
        XCTAssertEqual(weight, .invalidWeight)

        let timeout = WebsiteLoadBalancerValidator.validate(
            name: "lb",
            algorithm: "default",
            servers: [
                WebsiteLoadBalancerServer(
                    server: "10.0.0.3:80",
                    failTimeout: 301
                ),
            ]
        )
        XCTAssertEqual(timeout, .invalidFailTimeout)

        XCTAssertNil(WebsiteLoadBalancerValidator.validate(
            name: "lb",
            algorithm: "least_conn",
            servers: [
                WebsiteLoadBalancerServer(
                    server: "10.0.0.4:80",
                    weight: 100,
                    flag: "backup",
                    maxFails: 1000,
                    maxConns: 10000,
                    failTimeout: 300
                ),
            ]
        ))
    }

    func testIpHashRejectsBackupServer() {
        let issue = WebsiteLoadBalancerValidator.validate(
            name: "lb",
            algorithm: "ip_hash",
            servers: [
                WebsiteLoadBalancerServer(server: "10.0.0.5:80", flag: "backup"),
            ]
        )
        XCTAssertEqual(issue, .ipHashBackup)
    }

    func testLoadBalanceLabelsResolve() {
        let translations = TranslationsManager.shared
        for key in [
            "websitesLoadBalanceTitle", "websitesLoadBalanceEmpty",
            "websitesLoadBalanceCreateTitle", "websitesLoadBalanceEditTitle",
            "websitesLoadBalanceAlgorithmLabel",
            "websitesLoadBalanceAlgorithmDefault",
            "websitesLoadBalanceAlgorithmIpHash",
            "websitesLoadBalanceAlgorithmLeastConn",
            "websitesLoadBalanceServerLabel", "websitesLoadBalanceWeightLabel",
            "websitesLoadBalanceFlagLabel", "websitesLoadBalanceFlagNone",
            "websitesLoadBalanceFlagDown", "websitesLoadBalanceFlagBackup",
            "websitesLoadBalanceMaxFailsLabel",
            "websitesLoadBalanceFailTimeoutLabel",
            "websitesLoadBalanceMaxConnsLabel",
            "websitesLoadBalanceAddServer",
            "websitesLoadBalanceRemoveServer",
            "websitesLoadBalanceWeightRange",
            "websitesLoadBalanceIpHashBackup",
            "websiteSourceFileLabel",
            "websitesLoadBalanceFileEmpty",
            "websitesUpstreamServersEmpty",
            "websitesUpstreamServersHint",
        ] {
            XCTAssertFalse(translations.get(key, fallback: "").isEmpty)
        }
    }

    func testBalancerCarriesSourceFileContent() throws {
        let balancer = try XCTUnwrap(WebsiteLoadBalancer(payload: [
            "name": "upstream-main",
            "algorithm": "default",
            "servers": [],
            "content": "upstream upstream-main {\n    server 127.0.0.1:8080;\n}",
        ]))

        XCTAssertTrue(balancer.content.contains("127.0.0.1:8080"))
    }

    func testServerKeepsIdentityAcrossFieldEdits() {
        let original = WebsiteLoadBalancerServer(
            server: "10.0.0.1:80",
            weight: 4
        )
        let edited = WebsiteLoadBalancerServer(
            id: original.id,
            server: "10.0.0.2:80",
            weight: 4,
            flag: "backup",
            maxFails: nil,
            maxConns: nil,
            failTimeout: nil,
            failTimeoutUnit: "s"
        )

        XCTAssertEqual(edited.id, original.id)
        XCTAssertEqual(edited.server, "10.0.0.2:80")
        XCTAssertEqual(edited.flag, "backup")
        XCTAssertEqual(edited.payload["weight"] as? Int, 4)
    }
}

/// 真实通道探针：确认测试宿主里 Flutter 引擎与 Dart 通道可用。
@MainActor
final class ChannelProbeTests: XCTestCase {
    func testDartTranslationChannelResponds() async throws {
        let translations = try await ChannelManager.shared.invokeDataMethodAsync("getTranslations")
        let payload = translations as? [String: Any]
        XCTAssertNotNil(payload)
        XCTAssertFalse((payload ?? [:]).isEmpty)
    }
}