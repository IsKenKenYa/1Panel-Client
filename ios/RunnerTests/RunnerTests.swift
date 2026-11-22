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
