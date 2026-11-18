import Foundation
import LocalAuthentication

/// 应用锁状态管理：与 Flutter / macOS 共用 `flutter.app_lock_enabled` 偏好键。
class SecurityViewModel: ObservableObject {
    static let appLockDefaultsKey = "flutter.app_lock_enabled"

    @Published var appLockEnabled: Bool
    @Published var isAuthenticating = false
    @Published var authErrorMessage: String?

    /// 设备是否支持本机认证（Face ID / Touch ID / 设备密码）。
    static func deviceAuthSupported() -> Bool {
        var error: NSError?
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    init() {
        self.appLockEnabled = UserDefaults.standard.bool(forKey: SecurityViewModel.appLockDefaultsKey)
    }

    /// 开启应用锁前先完成一次本机认证，认证通过才写入开关。
    func enableAppLock() {
        authenticate(reasonKey: "appLockUnlockReasonEnable",
                     fallback: "Authenticate to enable App Lock") { [weak self] success in
            guard let self else { return }
            self.appLockEnabled = success
            if success {
                self.persistAppLock(true)
            }
        }
    }

    func disableAppLock() {
        appLockEnabled = false
        persistAppLock(false)
    }

    /// 启动门禁：本机认证通过才解锁应用。
    func unlockApp(onSuccess: @escaping () -> Void) {
        authenticate(reasonKey: "appLockUnlockReasonAppOpen",
                     fallback: "Authenticate to open 1Panel Client") { success in
            if success {
                onSuccess()
            }
        }
    }

    private func persistAppLock(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: SecurityViewModel.appLockDefaultsKey)
        UserDefaults.standard.synchronize()
    }

    private func authenticate(reasonKey: String,
                              fallback: String,
                              completion: @escaping (Bool) -> Void) {
        guard !isAuthenticating else { return }
        authErrorMessage = nil
        var error: NSError?
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authErrorMessage = error?.localizedDescription
            completion(false)
            return
        }
        isAuthenticating = true
        let reason = TranslationsManager.shared.get(reasonKey, fallback: fallback)
        context.evaluatePolicy(.deviceOwnerAuthentication,
                               localizedReason: reason) { [weak self] success, evaluateError in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                if let evaluateError, !success {
                    self?.authErrorMessage = evaluateError.localizedDescription
                }
                completion(success)
            }
        }
    }
}
