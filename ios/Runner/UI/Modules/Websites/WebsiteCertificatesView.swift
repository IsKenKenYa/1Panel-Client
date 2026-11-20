import SwiftUI
import AppleSharedUI

/// 网站模块：网站列表与证书中心两个子页签。
struct WebsitesModuleView: View {
    @EnvironmentObject var translations: TranslationsManager

    /// 走查钩子：`ONEPANEL_WEBSITES_TAB=websites|certificates` 直接进入子页签。
    @State private var tab = ProcessInfo.processInfo.environment["ONEPANEL_WEBSITES_TAB"] ?? "websites"

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text(translations.get("serverModuleWebsites", fallback: "Websites")).tag("websites")
                Text(translations.get("websitesTabCertificates", fallback: "Certificates"))
                    .tag("certificates")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if tab == "certificates" {
                WebsiteCertificatesView()
            } else {
                WebsitesView()
            }
        }
        .navigationTitle(translations.get("serverModuleWebsites", fallback: "Websites"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
            }
        }
    }
}

struct WebsiteCertificateRow: Identifiable {
    let id: Int
    let primaryDomain: String
    let domains: [String]
    let provider: String
    let status: String
    let autoRenew: Bool
    let startDate: String
    let expireDate: String

    var allDomains: String {
        domains.isEmpty ? primaryDomain : domains.joined(separator: ", ")
    }
}

/// 证书中心：列表、上传（粘贴）与删除。
struct WebsiteCertificatesView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var certificates: [WebsiteCertificateRow] = []
    @State private var isLoading = false
    @State private var toastText: String?
    @State private var showUploadSheet = false
    @State private var pendingDelete: WebsiteCertificateRow?
    @State private var uploadCertificate = ""
    @State private var uploadPrivateKey = ""
    @State private var uploadRemark = ""

    var body: some View {
        Group {
            if isLoading && certificates.isEmpty {
                LoadingView()
            } else if certificates.isEmpty {
                EmptyStateView(
                    icon: "lock.shield",
                    message: translations.get("websitesSslNoCert", fallback: "No certificate"),
                    description: translations.get("websitesSslUploadAction", fallback: "Upload certificate")
                )
            } else {
                List {
                    ForEach(certificates) { cert in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(cert.primaryDomain)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Spacer()
                                StatusBadge(
                                    text: cert.status.isEmpty
                                        ? translations.get("websitesSslStatus", fallback: "Status")
                                        : cert.status,
                                    color: StatusPalette.cronjobStatus(cert.status)
                                )
                            }
                            if !cert.provider.isEmpty {
                                Label(cert.provider, systemImage: "building.2")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if !cert.expireDate.isEmpty {
                                Label(
                                    "\(translations.get("websitesSslExpireDate", fallback: "Expires")) \(TimestampFormat.display(cert.expireDate))",
                                    systemImage: "calendar"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            if cert.autoRenew {
                                Label(translations.get("websitesSslAutoRenew", fallback: "Auto renew"),
                                      systemImage: "arrow.triangle.2.circlepath")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            Button {
                                applyCertificate(cert)
                            } label: {
                                Label(translations.get("websitesSslApplyAction", fallback: "Apply"),
                                      systemImage: "arrow.clockwise")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = cert
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    uploadCertificate = ""
                    uploadPrivateKey = ""
                    uploadRemark = ""
                    showUploadSheet = true
                } label: {
                    Label(translations.get("websitesSslUploadAction", fallback: "Upload"),
                          systemImage: "square.and.arrow.up")
                }
                Button {
                    fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showUploadSheet) {
            uploadSheet
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteCertificate()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage",
                                  fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            if certificates.isEmpty {
                fetch()
            }
        }
    }

    private var uploadSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $uploadCertificate)
                        .font(.system(.caption2, design: .monospaced))
                        .frame(minHeight: 120)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .overlay(alignment: .topLeading) {
                            if uploadCertificate.isEmpty {
                                Text(translations.get("websitesSslCertificateLabel",
                                                      fallback: "Certificate"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                    TextEditor(text: $uploadPrivateKey)
                        .font(.system(.caption2, design: .monospaced))
                        .frame(minHeight: 120)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .overlay(alignment: .topLeading) {
                            if uploadPrivateKey.isEmpty {
                                Text(translations.get("websitesSslPrivateKeyLabel",
                                                      fallback: "Private key"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                    TextField(translations.get("websitesRemarkLabel", fallback: "Remark"),
                              text: $uploadRemark)
                }
            }
            .navigationTitle(translations.get("websitesSslUploadAction", fallback: "Upload"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showUploadSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        upload()
                    }
                    .disabled(uploadCertificate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || uploadPrivateKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getWebsiteCertificates") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                certificates = items.compactMap { item in
                    guard let id = item["id"] as? Int, id > 0 else { return nil }
                    return WebsiteCertificateRow(
                        id: id,
                        primaryDomain: item["primaryDomain"] as? String ?? "",
                        domains: (item["domains"] as? [Any])?.compactMap { $0 as? String } ?? [],
                        provider: item["provider"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        autoRenew: item["autoRenew"] as? Bool ?? false,
                        startDate: item["startDate"] as? String ?? "",
                        expireDate: item["expireDate"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func upload() {
        ChannelManager.shared.invokeDataMethod(
            "uploadCertificate",
            arguments: [
                "certificate": uploadCertificate,
                "privateKey": uploadPrivateKey,
                "description": uploadRemark,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showUploadSheet = false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                if success {
                    fetch()
                }
            }
        }
    }

    private func applyCertificate(_ cert: WebsiteCertificateRow) {
        ChannelManager.shared.invokeDataMethod(
            "applyCertificate",
            arguments: ["id": cert.id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonOperationSuccess", fallback: "Operation succeeded")
                    : translations.get("commonOperationFailed", fallback: "Operation failed"))
                if success {
                    fetch()
                }
            }
        }
    }

    private func deleteCertificate() {
        guard let cert = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteWebsiteCertificate",
            arguments: ["id": cert.id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                fetch()
            }
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}
