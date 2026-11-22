import AppleSharedUI
import SwiftUI

/// 文件内容页：文本预览、编辑与保存。二进制文件只读展示并提示不支持编辑。
struct FileContentView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let path: String

    @State private var content = ""
    @State private var originalContent = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var loadFailed = false
    @State private var isBinary = false
    @State private var statusText: String?

    private var fileName: String {
        (path as NSString).lastPathComponent
    }

    private var isDirty: Bool {
        content != originalContent
    }

    var body: some View {
        Group {
            if isLoading && content.isEmpty && !isBinary {
                LoadingView()
            } else if loadFailed {
                ErrorView(message: translations.get("filePreviewLoadFailed", fallback: "Failed to load file")) {
                    load()
                }
            } else if isBinary {
                EmptyStateView(
                    icon: "doc",
                    message: translations.get("filePreviewUnsupported",
                                             fallback: "This file type cannot be previewed")
                )
            } else {
                editor
            }
        }
        .navigationTitle(fileName)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(translations.get("commonClose", fallback: "Close")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(translations.get("commonSave", fallback: "Save"))
                    }
                }
                .disabled(isBinary || !isDirty || isSaving)
                .help(translations.get("commonSave", fallback: "Save"))
            }
        }
        .overlay(alignment: .bottom) {
            if let statusText {
                Text(statusText)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(20)
            }
        }
        .onAppear {
            if originalContent.isEmpty && content.isEmpty {
                load()
            }
        }
    }

    private var editor: some View {
        TextEditor(text: $content)
            .font(.system(.caption, design: .monospaced))
            .autocorrectionDisabled()
            .scrollContentBackground(.visible)
    }

    private func load() {
        isLoading = true
        loadFailed = false
        ChannelManager.shared.invokeDataMethod(
            "getFileContentHandler",
            arguments: ["path": path]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any],
                      let text = dict["content"] as? String else {
                    loadFailed = true
                    return
                }
                if text.contains("\u{0}") {
                    isBinary = true
                    return
                }
                content = text
                originalContent = text
            }
        }
    }

    private func save() {
        isSaving = true
        ChannelManager.shared.invokeDataMethod(
            "saveFileContentHandler",
            arguments: ["path": path, "content": content]
        ) { result in
            DispatchQueue.main.async {
                isSaving = false
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                if success {
                    originalContent = content
                    showStatus(translations.get("fileSaveSuccess", fallback: "File saved"))
                } else {
                    showStatus(translations.get("fileSaveFailed", fallback: "Failed to save file"))
                }
            }
        }
    }

    private func showStatus(_ text: String) {
        statusText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if statusText == text {
                statusText = nil
            }
        }
    }
}