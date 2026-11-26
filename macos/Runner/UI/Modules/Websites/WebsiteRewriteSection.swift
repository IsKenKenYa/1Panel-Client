import AppleSharedUI
import SwiftUI

/// 网站伪静态配置：读取与保存 Nginx rewrite 内容。
struct WebsiteRewriteSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int
    let siteName: String

    @State private var content = ""
    @State private var originalContent = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                LoadingView()
            } else {
                TextEditor(text: $content)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
            }
            HStack {
                Spacer()
                if isSaving {
                    ProgressView().controlSize(.small)
                }
                Button {
                    Task { await save() }
                } label: {
                    Label(translations.get("commonSave", fallback: "Save"),
                          systemImage: "square.and.arrow.down")
                }
                .disabled(isLoading || isSaving || content == originalContent)
            }
            .padding(12)
        }
        .operationNotice(statusMessage)
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteRewrite",
                arguments: ["websiteID": websiteId, "name": siteName]
            )
            let dict = raw as? [String: Any] ?? [:]
            content = dict["content"] as? String ?? ""
            originalContent = content
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteRewrite",
                arguments: ["websiteID": websiteId, "name": siteName, "content": content]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                originalContent = content
                showStatus(translations.get("commonSaveSuccess", fallback: "Saved"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonSaveFailed", fallback: "Save failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if statusMessage == text {
                statusMessage = nil
            }
        }
    }
}