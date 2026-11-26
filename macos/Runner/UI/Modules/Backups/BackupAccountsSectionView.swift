import AppleSharedUI
import SwiftUI

struct BackupAccountRow: Identifiable {
    let id: Int
    let name: String
    let type: String
    let isPublic: Bool
    let bucket: String
    let backupPath: String
}

/// macOS 备份账户分区：列表、新建、删除与连通性检测。
///
/// 复用备份记录页的通道集：`getBackupAccounts`、`createBackupAccount`、
/// `deleteBackupAccount` 与 `checkBackupAccount`。
struct BackupAccountsSectionView: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var accounts: [BackupAccountRow] = []
    @State private var isLoading = false
    @State private var actionError: String?
    @State private var statusMessage: String?
    @State private var pendingDelete: BackupAccountRow?
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if isLoading && accounts.isEmpty {
                LoadingView()
            } else if accounts.isEmpty {
                EmptyStateView(
                    icon: "tray.full",
                    message: t("backupAccountsEmptyTitle", "No backup accounts")
                )
            } else {
                List {
                    ForEach(accounts) { account in
                        row(account)
                    }
                }
                .listStyle(.inset)
            }
        }
        .operationNotice(statusMessage)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    Task { await fetch() }
                } label: {
                    Label(t("commonRefresh", "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
                Button {
                    showCreateSheet = true
                } label: {
                    Label(t("backupAccountsCreateTitle", "New backup account"),
                          systemImage: "plus")
                }
            }
        }
        .confirmationDialog(
            t("deleteConfirmTitle", "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(t("commonDelete", "Delete"), role: .destructive) {
                deleteSelected()
            }
            Button(t("commonCancel", "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(t("deleteCannotUndoMessage", "This action cannot be undone."))
        }
        .sheet(isPresented: $showCreateSheet) {
            BackupAccountCreateSheet { Task { await fetch() } }
                .environmentObject(translations)
        }
        .alert(
            t("commonError", "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(t("commonOk", "OK"), role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
        .task {
            await fetch()
        }
    }

    private func row(_ account: BackupAccountRow) -> some View {
        ModuleRow(
            icon: account.isPublic ? "cloud" : "tray",
            iconColor: account.isPublic ? .blue : .secondary,
            title: account.name,
            subtitle: [account.type,
                       account.isPublic
                       ? t("backupAccountsScopePublic", "Public")
                       : t("backupAccountsScopePrivate", "Private"),
                       account.bucket]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        ) {
            RowActionsMenu {
                Button {
                    check(account)
                } label: {
                    Label(t("backupAccountsCheckAction", "Check connection"),
                          systemImage: "checkmark.seal")
                }
                Divider()
                Button(role: .destructive) {
                    pendingDelete = account
                } label: {
                    Label(t("commonDelete", "Delete"), systemImage: "trash")
                }
            }
        }
        .contextMenu {
            Button {
                check(account)
            } label: {
                Label(t("backupAccountsCheckAction", "Check connection"),
                      systemImage: "checkmark.seal")
            }
            Button(role: .destructive) {
                pendingDelete = account
            } label: {
                Label(t("commonDelete", "Delete"), systemImage: "trash")
            }
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getBackupAccounts",
                arguments: ["page": 1, "pageSize": 100]
            )
            let payload = raw as? [String: Any] ?? [:]
            accounts = (payload["items"] as? [[String: Any]] ?? []).compactMap { item in
                guard let id = item["id"] as? Int,
                      let name = item["name"] as? String,
                      !name.isEmpty else { return nil }
                return BackupAccountRow(
                    id: id,
                    name: name,
                    type: item["type"] as? String ?? "",
                    isPublic: item["isPublic"] as? Bool ?? false,
                    bucket: item["bucket"] as? String ?? "",
                    backupPath: item["backupPath"] as? String ?? ""
                )
            }
        } catch {
            actionError = error.localizedDescription
        }
        isLoading = false
    }

    private func check(_ account: BackupAccountRow) {
        Task {
            do {
                let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                    "checkBackupAccount",
                    arguments: [
                        "name": account.name,
                        "type": account.type,
                        "isPublic": account.isPublic,
                        "bucket": account.bucket,
                        "backupPath": account.backupPath,
                    ]
                )
                let payload = raw as? [String: Any] ?? [:]
                if payload["success"] as? Bool == true {
                    showStatus(t("backupAccountsConnectionOk", "Connection ok"))
                } else {
                    actionError = payload["message"] as? String
                        ?? payload["error"] as? String
                        ?? t("commonOperationFailed", "Operation failed")
                }
            } catch {
                actionError = error.localizedDescription
            }
        }
    }

    private func deleteSelected() {
        guard let account = pendingDelete else { return }
        pendingDelete = nil
        Task {
            do {
                let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                    "deleteBackupAccount",
                    arguments: ["id": account.id]
                )
                let payload = raw as? [String: Any] ?? [:]
                if payload["success"] as? Bool == true {
                    showStatus(t("commonDeleted", "Deleted"))
                    await fetch()
                } else {
                    actionError = payload["error"] as? String
                        ?? t("commonDeleteFailed", "Delete failed")
                }
            } catch {
                actionError = error.localizedDescription
            }
        }
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if statusMessage == text { statusMessage = nil }
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}

/// 新建备份账户。
struct BackupAccountCreateSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var name = ""
    @State private var type = "sftp"
    @State private var isPublic = false
    @State private var accessKey = ""
    @State private var credential = ""
    @State private var bucket = ""
    @State private var backupPath = ""
    @State private var submitting = false
    @State private var errorText: String?

    private static let types = ["sftp", "local", "minio", "aws-s3", "aliyun-oss"]

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(t("backupAccountsNameLabel", "Account name"), text: $name)
                    Picker(t("backupAccountsTypeLabel", "Account type"), selection: $type) {
                        ForEach(Self.types, id: \.self) { value in
                            Text(value).tag(value)
                        }
                    }
                    Toggle(t("backupAccountsScopePublic", "Public"), isOn: $isPublic)
                }
                Section {
                    if type != "local" {
                        TextField(t("backupFormAccessKeyLabel", "Access key"),
                                  text: $accessKey)
                        SecureField(t("backupFormCredentialLabel", "Credential"),
                                    text: $credential)
                    }
                    TextField(t("backupFormBucketLabel", "Bucket"), text: $bucket)
                    TextField(t("backupFormBackupPathLabel", "Backup path"),
                              text: $backupPath)
                }
                if let errorText {
                    Section {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                if submitting { ProgressView().controlSize(.small) }
                Spacer()
                Button(t("commonCancel", "Cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(t("commonSave", "Save")) { Task { await submit() } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || submitting)
            }
            .padding(16)
        }
        .frame(width: 520, height: 560)
    }

    private func submit() async {
        submitting = true
        errorText = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "createBackupAccount",
                arguments: [
                    "name": name.trimmingCharacters(in: .whitespaces),
                    "type": type,
                    "isPublic": isPublic,
                    "accessKey": accessKey,
                    "credential": credential,
                    "bucket": bucket,
                    "backupPath": backupPath,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onCreated()
                dismiss()
            } else {
                errorText = payload["error"] as? String
                    ?? t("commonSaveFailed", "Save failed")
            }
        } catch {
            errorText = error.localizedDescription
        }
        submitting = false
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}