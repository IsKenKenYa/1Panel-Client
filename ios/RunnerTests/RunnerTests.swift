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
        let server = ServerModel(originalId: "1", name: "1Panel", url: "https://panel.example",
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
        let server = ServerModel(originalId: "1", name: "1Panel", url: "https://panel.example",
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
