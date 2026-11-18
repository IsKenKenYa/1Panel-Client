import SwiftUI

/// 安全页：应用锁开关（本机认证：Face ID / Touch ID / 设备密码）。
struct SecurityView: View {
    @StateObject private var viewModel = SecurityViewModel()
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.appLockEnabled },
                    set: { enabled in
                        if enabled {
                            viewModel.enableAppLock()
                        } else {
                            viewModel.disableAppLock()
                        }
                    }
                )) {
                    Label(translations.get("appLockEnable", fallback: "Enable App Lock"),
                          systemImage: "lock.shield")
                }
                .disabled(viewModel.isAuthenticating || !SecurityViewModel.deviceAuthSupported())
            } header: {
                Text(translations.get("appLockTitle", fallback: "App Lock"))
            } footer: {
                Text(translations.get("appLockEnableDesc", fallback: "Local authentication is required before opening protected content."))
            }

            if let error = viewModel.authErrorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(translations.get("navSecurity", fallback: "Security"))
    }
}

/// 启动门禁：应用锁开启时阻塞内容，本机认证通过后解锁。
struct AppLockGateView: View {
    let onUnlock: () -> Void
    @StateObject private var viewModel = SecurityViewModel()
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(translations.get("appLockUnlockReasonAppOpen",
                                  fallback: "Authenticate to open 1Panel Client"))
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if !SecurityViewModel.deviceAuthSupported() {
                Button {
                    onUnlock()
                } label: {
                    Label(translations.get("appLockUnlockReasonAppOpen", fallback: "Unlock"),
                          systemImage: "faceid")
                }
                .buttonStyle(.borderedProminent)
            }
            if let error = viewModel.authErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .onAppear {
            guard SecurityViewModel.deviceAuthSupported() else { return }
            viewModel.unlockApp {
                onUnlock()
            }
        }
    }
}
