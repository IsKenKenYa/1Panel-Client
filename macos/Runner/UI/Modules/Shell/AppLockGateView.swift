import LocalAuthentication
import SwiftUI

@MainActor
final class MacOSAppLockController: ObservableObject {
    static let enabledPreferenceKey = "flutter.app_lock_enabled"
    private static let relockMinutesPreferenceKey = "flutter.app_lock_relock_after_minutes"

    @Published private(set) var isEnabled: Bool
    @Published private var sessionUnlocked = false
    @Published private(set) var isAuthenticating = false
    @Published private(set) var errorMessage: String?

    private let defaults: UserDefaults
    private let locksOnOpen: Bool
    private let locksProtectedModules: Bool
    private let protectedModuleIds: Set<String>
    private var context: LAContext?
    private var inactiveAt: Date?

    var isLocked: Bool {
        isEnabled && locksOnOpen && !sessionUnlocked
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Self.enabledPreferenceKey)
        locksOnOpen = defaults.object(forKey: "flutter.app_lock_on_open") as? Bool ?? true
        locksProtectedModules = defaults.object(forKey: "flutter.app_lock_on_protected_module") as? Bool ?? true
        let savedIds = Set((defaults.stringArray(forKey: "flutter.app_lock_protected_modules") ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty })
        protectedModuleIds = savedIds.isEmpty
            ? ["files", "containers", "apps", "websites", "ai", "verification"]
            : savedIds
    }

    func requiresUnlock(for moduleId: String) -> Bool {
        isEnabled && locksProtectedModules && !sessionUnlocked && protectedModuleIds.contains(moduleId)
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled, !isLocked, !isAuthenticating else { return }
        if enabled {
            authenticate(
                reasonKey: "appLockUnlockReasonEnable",
                fallback: "Verify your identity to enable app lock"
            ) { [weak self] in
                guard let self else { return }
                self.sessionUnlocked = true
                self.isEnabled = true
                self.defaults.set(true, forKey: Self.enabledPreferenceKey)
            }
        } else if !sessionUnlocked {
            authenticate(
                reasonKey: "appLockUnlockReasonDisable",
                fallback: "Verify your identity to turn off App Lock"
            ) { [weak self] in
                self?.disable()
            }
        } else {
            disable()
        }
    }

    private func disable() {
        isEnabled = false
        sessionUnlocked = false
        errorMessage = nil
        inactiveAt = nil
        defaults.set(false, forKey: Self.enabledPreferenceKey)
    }

    func unlock(moduleId: String? = nil) {
        guard isLocked || moduleId.map(requiresUnlock(for:)) == true else { return }
        let appGate = isLocked
        authenticate(
            reasonKey: appGate ? "appLockUnlockReasonAppOpen" : "appLockLockOnProtectedModule",
            fallback: appGate ? "Verify your identity to open KenPanel" : "Verify your identity to open this module"
        ) { [weak self] in
            self?.sessionUnlocked = true
        }
    }

    func applicationResignedActive() {
        guard isEnabled, sessionUnlocked, !isAuthenticating else { return }
        inactiveAt = Date()
    }

    func applicationBecameActive() {
        guard let inactiveAt else { return }
        self.inactiveAt = nil
        let storedMinutes = defaults.integer(forKey: Self.relockMinutesPreferenceKey)
        let interval = TimeInterval(storedMinutes > 0 ? storedMinutes : 5) * 60
        if isEnabled, Date().timeIntervalSince(inactiveAt) >= interval {
            sessionUnlocked = false
        }
    }

    private func authenticate(reasonKey: String, fallback: String, onSuccess: @escaping @MainActor @Sendable () -> Void) {
        guard !isAuthenticating else { return }
        errorMessage = nil
        let context = LAContext()
        var availabilityError: NSError?
        let translations = TranslationsManager.shared
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &availabilityError) else {
            errorMessage = availabilityError?.localizedDescription
                ?? translations.get("appLockDeviceAuthUnsupported", fallback: "Device authentication is unavailable.")
            return
        }

        self.context = context
        isAuthenticating = true
        let reason = translations.get(reasonKey, fallback: fallback)
        let defaultError = translations.get("appLockAuthFailed", fallback: "Authentication failed")
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.context = nil
                self.isAuthenticating = false
                if success {
                    onSuccess()
                } else {
                    self.errorMessage = error?.localizedDescription ?? defaultError
                }
            }
        }
    }
}

struct AppLockGateView: View {
    @ObservedObject var appLock: MacOSAppLockController
    @EnvironmentObject var translations: TranslationsManager
    var moduleId: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(translations.get("appLockTitle", fallback: "App Lock"))
                .font(.title2)
                .accessibilityAddTraits(.isHeader)
            if moduleId == nil {
                Text(translations.get("appLockUnlockReasonAppOpen",
                                      fallback: "Verify your identity to open KenPanel"))
                    .foregroundStyle(.secondary)
            } else {
                Text(translations.get("appLockLockOnProtectedModule",
                                      fallback: "Verify your identity to open this module"))
                    .foregroundStyle(.secondary)
            }

            if appLock.isAuthenticating {
                ProgressView()
            } else {
                Button(translations.get("appLockUnlockAction", fallback: "Unlock App")) {
                    appLock.unlock(moduleId: moduleId)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }

            if let error = appLock.errorMessage {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 400)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
