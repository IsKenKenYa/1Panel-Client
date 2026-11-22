import AppKit
import FlutterMacOS
import XCTest
@testable import onepanel_client

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
  func testRenderModeSelectsAppleShellOnlyForNative() {
    XCTAssertTrue(MacOSRenderMode(storedValue: "native").usesNativeShell)
    XCTAssertFalse(MacOSRenderMode(storedValue: "md3").usesNativeShell)
    XCTAssertFalse(MacOSRenderMode(storedValue: "liquidGlass").usesNativeShell)
  }

  func testRenderModeDefaultsToAppleShell() {
    XCTAssertEqual(MacOSRenderMode(storedValue: nil), .native)
    XCTAssertEqual(MacOSRenderMode(storedValue: "unknown"), .native)
  }

  @MainActor
  func testWindowUsesTheStoredRenderMode() throws {
    let delegate = try XCTUnwrap(NSApp.delegate as? AppDelegate)
    let window = try XCTUnwrap(delegate.mainFlutterWindow)
    if MacOSRenderMode.stored.usesNativeShell {
      XCTAssertTrue(window.contentViewController is MainShellViewController)
      XCTAssertTrue(window.styleMask.contains(.fullSizeContentView))
    } else {
      XCTAssertTrue(window.contentViewController is FlutterViewController)
      XCTAssertFalse(window.styleMask.contains(.fullSizeContentView))
    }
  }

  @MainActor
  func testSettingsMenuSelectsTheNativeSettingsPage() throws {
    let delegate = try XCTUnwrap(NSApp.delegate as? AppDelegate)
    let controller = delegate.mainFlutterWindow?.contentViewController
    try XCTSkipUnless(controller is MainShellViewController)
    let shell = try XCTUnwrap(controller as? MainShellViewController)
    try XCTSkipUnless(shell.canShowSettings)
    let appMenu = try XCTUnwrap(NSApp.mainMenu?.items.first?.submenu)
    let index = try XCTUnwrap(appMenu.items.firstIndex { $0.keyEquivalent == "," })
    let originalSelection = shell.rootView.navigation.selectedModule
    defer { shell.rootView.navigation.selectedModule = originalSelection }
    appMenu.performActionForItem(at: index)
    XCTAssertEqual(shell.rootView.navigation.selectedModule, "settings")
  }

  @MainActor
  func testSettingsShortcutSelectsTheFlutterSettingsPage() throws {
    try XCTSkipUnless(Bundle.main.bundleIdentifier == "com.iskenkenya.onepanel.cachetest")
    try XCTSkipUnless(!MacOSRenderMode.stored.usesNativeShell)
    let delegate = try XCTUnwrap(NSApp.delegate as? AppDelegate)
    let window = try XCTUnwrap(delegate.mainFlutterWindow)
    let controller = try XCTUnwrap(window.contentViewController as? FlutterViewController)
    let engine = controller.engine
    // 通过 Flutter 引擎启用真实的 macOS 无障碍树。
    let previousSemantics = engine.value(forKey: "semanticsEnabled")
    engine.setValue(true, forKey: "semanticsEnabled")
    defer { engine.setValue(previousSemantics, forKey: "semanticsEnabled") }

    waitForAccessibilityText(["Add Server", "添加服务器"], in: controller.view)

    let menu = try XCTUnwrap(NSApp.mainMenu)
    let appMenu = try XCTUnwrap(menu.items.first?.submenu)
    let settings = try XCTUnwrap(appMenu.items.first { $0.keyEquivalent == "," })
    XCTAssertEqual(settings.keyEquivalentModifierMask, .command)
    let shortcut = try XCTUnwrap(NSEvent.keyEvent(
      with: .keyDown,
      location: .zero,
      modifierFlags: .command,
      timestamp: 0,
      windowNumber: window.windowNumber,
      context: nil,
      characters: ",",
      charactersIgnoringModifiers: ",",
      isARepeat: false,
      keyCode: 43
    ))
    XCTAssertTrue(menu.performKeyEquivalent(with: shortcut))
    waitForAccessibilityText(["Interface style", "界面风格"], in: controller.view)
    XCTAssertTrue(delegate.mainFlutterWindow === window)
    XCTAssertTrue(window.contentViewController === controller)
  }

  @MainActor
  private func waitForAccessibilityText(_ labels: [String], in view: NSView) {
    let rendered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
      self.accessibilityText(in: view).contains { value in labels.contains(where: value.contains) }
    }, object: nil)
    XCTAssertEqual(XCTWaiter.wait(for: [rendered], timeout: 10), .completed,
                   "Expected \(labels), found \(accessibilityText(in: view))")
  }

  @MainActor
  private func accessibilityText(in element: NSAccessibilityProtocol) -> [String] {
    let text = [element.accessibilityLabel(), element.accessibilityTitle(), element.accessibilityValue() as? String]
    let children = (element.accessibilityChildren() ?? []).compactMap { $0 as? NSAccessibilityProtocol }
    return text.compactMap { $0 } + children.flatMap { accessibilityText(in: $0) }
  }

  @MainActor
  func testPersistedAppLockCannotBeDisabledFromTheGate() throws {
    let suite = "onepanel.app-lock.tests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let key = MacOSAppLockController.enabledPreferenceKey
    XCTAssertFalse(MacOSAppLockController(defaults: defaults).isLocked)
    defaults.set(true, forKey: key)

    let controller = MacOSAppLockController(defaults: defaults)
    XCTAssertTrue(controller.isLocked)
    controller.setEnabled(false)
    XCTAssertTrue(defaults.bool(forKey: key))
    XCTAssertTrue(controller.isLocked)
  }

  @MainActor
  func testScopedAppLockAllowsOpeningTheShellAndProtectsSelectedModules() throws {
    let suite = "onepanel.app-lock.tests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(true, forKey: MacOSAppLockController.enabledPreferenceKey)
    defaults.set(false, forKey: "flutter.app_lock_on_open")
    defaults.set(["files"], forKey: "flutter.app_lock_protected_modules")

    let controller = MacOSAppLockController(defaults: defaults)
    XCTAssertFalse(controller.isLocked)
    XCTAssertFalse(controller.requiresUnlock(for: "dashboard"))
    XCTAssertTrue(controller.requiresUnlock(for: "files"))
    XCTAssertFalse(controller.requiresUnlock(for: "containers"))
  }
}

class DatabaseUnbindTests: XCTestCase {
  func testOnlyRemoteConnectionsWithValidIdentityCanBeUnbound() throws {
    let remote = database(scope: "remote", recordId: 12, serverId: "panel-a")
    let arguments = try XCTUnwrap(remote.unbindArguments)
    XCTAssertEqual(arguments["id"] as? Int, 12)
    XCTAssertEqual(arguments["serverId"] as? String, "panel-a")
    XCTAssertNil(database(scope: "redis", recordId: 12, serverId: "panel-a").unbindArguments)
    XCTAssertNil(database(scope: "remote", recordId: 0, serverId: "panel-a").unbindArguments)
    XCTAssertNil(database(scope: "remote", recordId: 12, serverId: "").unbindArguments)
    XCTAssertNotEqual(remote.id, database(scope: "redis", recordId: 12, serverId: "panel-a").id)
    XCTAssertNotEqual(remote.id, database(scope: "remote", recordId: 12, serverId: "panel-b").id)
  }

  private func database(scope: String, recordId: Int, serverId: String) -> DatabaseModel {
    DatabaseModel(recordId: recordId, serverId: serverId, scope: scope, name: "connection",
                  lookupName: "connection", source: "", type: "redis", engine: "redis",
                  version: "", status: "", description: "")
  }
}

class FileDirectoryTests: XCTestCase {
  func testEmptyDirectoryRequiresAListResponse() throws {
    let path = "/"
    let listing = try XCTUnwrap(FileDirectory(path: path, payload: [[String: Any]]()))
    XCTAssertEqual(listing.path, path)
    XCTAssertTrue(listing.files.isEmpty)
    XCTAssertNil(FileDirectory(path: path, payload: nil))
    XCTAssertNil(FileDirectory(path: path, payload: [[:]]))
  }

  func testDirectoryEntryRetainsPathAndType() throws {
    let bundle = Bundle(for: Self.self).bundleURL
    let parent = bundle.deletingLastPathComponent().path
    let values = try bundle.resourceValues(forKeys: [.isDirectoryKey])
    let row: [String: Any] = [
      "name": bundle.lastPathComponent,
      "isDir": try XCTUnwrap(values.isDirectory)
    ]
    let listing = try XCTUnwrap(FileDirectory(path: parent, payload: [row]))
    let entry = try XCTUnwrap(listing.files.first)
    XCTAssertEqual(entry.path, bundle.path)
    XCTAssertTrue(entry.isDir)
  }
}

class InstalledAppsResponseTests: XCTestCase {
  func testInstallationsOfTheSameCatalogAppHaveDistinctIdentities() throws {
    let rows = [
      appRow(installId: 101),
      appRow(installId: 102),
    ]
    let response = FlutterStandardMessageCodec.sharedInstance().encode(rows)
    let decoded = FlutterStandardMessageCodec.sharedInstance().decode(response)
    let apps = try XCTUnwrap(AppModel.readInstalledApps(decoded))
    XCTAssertEqual(apps.map(\.id), [101, 102])
    XCTAssertEqual(apps.map(\.installId), [101, 102])
  }

  func testMissingAndInvalidInstallIdsRejectTheResponse() {
    XCTAssertNil(AppModel.readInstalledApps([["appId": 5, "name": "redis"]]))
    for invalid: Any in [NSNull(), 0, -7, true, 7.25, "7"] {
      XCTAssertNil(AppModel.readInstalledApps([appRow(installId: invalid)]))
    }
    XCTAssertNil(AppModel.readInstalledApps([appRow(installId: 7), appRow(installId: 7)]))
    XCTAssertEqual(AppModel.readInstalledApps([[String: Any]]())?.count, 0)
  }

  private func appRow(installId: Any) -> [String: Any] {
    [
      "appId": 5,
      "installId": installId,
      "name": "redis",
      "status": "Running",
      "version": "7.4",
    ]
  }
}

class NativeMutationOutcomeTests: XCTestCase {
  func testOnlyAnExplicitBooleanSuccessCanTriggerARefresh() {
    XCTAssertEqual(NativeMutationOutcome(["success": true]), .succeeded)
    XCTAssertEqual(NativeMutationOutcome(["success": 1]), .failed(nil))
    XCTAssertEqual(NativeMutationOutcome(["success": "true"]), .failed(nil))
    XCTAssertEqual(NativeMutationOutcome(nil), .failed(nil))
  }

  func testNativeAndFlutterFailuresRetainTheirMessage() {
    XCTAssertEqual(
      NativeMutationOutcome(["success": false, "error": "Operation rejected"]),
      .failed("Operation rejected")
    )
    let error = FlutterError(code: "operation_failed", message: "Connection unavailable", details: nil)
    XCTAssertEqual(NativeMutationOutcome(error), .failed("Connection unavailable"))
  }
}

class NativeFormSubmissionTests: XCTestCase {
  func testSubmissionBlocksDuplicatesAndClosesOnlyAfterExplicitSuccess() {
    var submission = NativeFormSubmission.idle

    XCTAssertTrue(submission.begin())
    XCTAssertTrue(submission.isSubmitting)
    XCTAssertFalse(submission.begin())

    let codec = FlutterStandardMessageCodec.sharedInstance()
    let malformed = codec.decode(codec.encode(["success": 1]))
    XCTAssertFalse(submission.finish(NativeMutationOutcome(malformed)))
    XCTAssertEqual(submission, .failed(nil))

    XCTAssertTrue(submission.begin())
    let success = codec.decode(codec.encode(["success": true]))
    XCTAssertTrue(submission.finish(NativeMutationOutcome(success)))
    XCTAssertEqual(submission, .succeeded)
    XCTAssertFalse(submission.begin())
  }

  func testFailedSubmissionRetainsAnErrorAndAllowsRetry() {
    var submission = NativeFormSubmission.idle
    XCTAssertTrue(submission.begin())

    let error = FlutterError(code: "operation_failed", message: "Request rejected", details: nil)
    XCTAssertFalse(submission.finish(NativeMutationOutcome(error)))
    XCTAssertEqual(submission, .failed("Request rejected"))
    XCTAssertFalse(submission.isSubmitting)
    XCTAssertTrue(submission.begin())
    XCTAssertFalse(submission.finish(.failed(" \n ")))
    XCTAssertEqual(submission, .failed(nil))
  }
}

class ContainerSectionModelTests: XCTestCase {
  func testComposeProjectUsesRunningContainerCount() {
    let project = ContainerComposeProject(
      id: "web", name: "web", path: "/opt/web/docker-compose.yml",
      status: "exited", createTime: "", containerCount: 3, runningCount: 1
    )

    XCTAssertTrue(project.isRunning)
  }

  func testComposeProjectFallsBackToStatusKeyword() {
    let running = ContainerComposeProject(
      id: "api", name: "api", path: "", status: "running", createTime: "",
      containerCount: 0, runningCount: 0
    )
    let stopped = ContainerComposeProject(
      id: "job", name: "job", path: "", status: "exited", createTime: "",
      containerCount: 0, runningCount: 0
    )

    XCTAssertTrue(running.isRunning)
    XCTAssertFalse(stopped.isRunning)
  }

  func testNetworkSystemClassification() {
    XCTAssertTrue(ContainerNetworkItem(
      id: "bridge", name: "bridge", driver: "bridge", subnet: "", gateway: "",
      createdAt: "", attachable: false
    ).isSystem)
    XCTAssertFalse(ContainerNetworkItem(
      id: "custom", name: "custom", driver: "bridge", subnet: "", gateway: "",
      createdAt: "", attachable: true
    ).isSystem)
  }

  func testContainerSectionTitlesMapToExistingKeys() {
    XCTAssertEqual(ContainerSection.containers.titleKey, "containerTabContainers")
    XCTAssertEqual(ContainerSection.compose.titleKey, "orchestrationCompose")
    XCTAssertEqual(ContainerSection.networks.titleKey, "containerTabNetworks")
    XCTAssertEqual(ContainerSection.volumes.titleKey, "containerTabVolumes")
  }
}

class MacReleaseManifestTests: XCTestCase {
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

class MacContainerDetailModelTests: XCTestCase {
  func testComposeContainerCarriesStateAndImage() {
    let container = ContainerComposeContainer(
      id: "abc",
      name: "web-1",
      image: "nginx:latest",
      state: "running",
      status: "Up 2 hours",
      ports: []
    )

    XCTAssertEqual(container.name, "web-1")
    XCTAssertEqual(container.image, "nginx:latest")
    XCTAssertEqual(container.state, "running")
  }

  func testNetworkAndVolumeDetailFields() {
    let network = ContainerNetworkItem(
      id: "net-1", name: "custom", driver: "bridge",
      subnet: "172.20.0.0/16", gateway: "172.20.0.1",
      createdAt: "2026-11-23 00:00:00", attachable: true
    )
    let volume = ContainerVolumeItem(
      name: "data", driver: "local", mountpoint: "/var/lib/docker/volumes/data",
      createdAt: "2026-11-23 00:00:00"
    )

    XCTAssertTrue(network.attachable)
    XCTAssertEqual(network.subnet, "172.20.0.0/16")
    XCTAssertEqual(volume.mountpoint, "/var/lib/docker/volumes/data")
    XCTAssertFalse(volume.createdAt.isEmpty)
  }

  func testComposeDetailLabelsResolve() {
    let translations = TranslationsManager.shared
    for key in [
      "containerComposeDetailTitle", "containerComposeFileTitle",
      "containerComposeValidateSuccess", "containerNetworkDetailTitle",
      "containerResourceCreatedAtLabel", "containerVolumeDetailTitle",
      "containerVolumeMountpointLabel",
    ] {
      XCTAssertFalse(translations.get(key, fallback: "").isEmpty)
    }
  }
}
