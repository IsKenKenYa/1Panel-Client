import SwiftUI
import AppleSharedUI

/// 文件内容页：文本预览、编辑与保存。二进制文件只读展示并提示不支持编辑。
struct FileContentView: View {
    @EnvironmentObject var translations: TranslationsManager
    let path: String

    @State private var content = ""
    @State private var originalContent = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var loadFailed = false
    @State private var isBinary = false
    @State private var toastText: String?

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
                    message: translations.get("filePreviewUnsupported", fallback: "This file type cannot be previewed")
                )
            } else {
                editor
            }
        }
        .navigationTitle(fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text(translations.get("commonSave", fallback: "Save"))
                    }
                }
                .disabled(isBinary || !isDirty || isSaving)
            }
        }
        .operationNotice(toastText)
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
            .textInputAutocapitalization(.never)
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
                // 含 NUL 字节按二进制处理，退回到不支持预览的提示。
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
                    showToast(translations.get("fileSaveSuccess", fallback: "File saved"))
                } else {
                    showToast(translations.get("fileSaveFailed", fallback: "Failed to save file"))
                }
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
