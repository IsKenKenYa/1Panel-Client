import XCTest
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
