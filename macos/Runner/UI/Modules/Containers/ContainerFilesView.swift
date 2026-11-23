import AppleSharedUI
import SwiftUI

struct ContainerFileRow: Identifiable {
    let name: String
    let path: String
    let isDir: Bool
    let isLink: Bool
    let linkTo: String
    let size: Int
    let mode: String
    let modTime: String

    var id: String { path }
}

/// 容器内文件浏览：目录逐级进入，文本文件预览。
struct ContainerFilesView: View {
    @EnvironmentObject private var translations: TranslationsManager
    let containerId: String

    @State private var path = "/"
    @State private var files: [ContainerFileRow] = []
    @State private var isLoading = false
    @State private var preview: ContainerFilePreview?
    @State private var pendingDelete: ContainerFileRow?
    @State private var actionError: String?
    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    goUp()
                } label: {
                    Label(translations.get("commonBack", fallback: "Back"),
                          systemImage: "chevron.left")
                }
                .disabled(path == "/")
                Spacer()
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if isUploading {
                    ProgressView().controlSize(.small)
                }
                Button {
                    upload()
                } label: {
                    Label(translations.get("containerFileUploadAction",
                                           fallback: "Upload file"),
                          systemImage: "arrow.up.circle")
                }
                .disabled(isUploading)
                .help(translations.get("containerFileUploadAction",
                                       fallback: "Upload file"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Group {
                if isLoading && files.isEmpty {
                    LoadingView()
                } else if files.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        message: translations.get("commonEmpty", fallback: "No data")
                    )
                } else {
                    List {
                        ForEach(files) { file in
                            Button {
                                open(file)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: iconName(file))
                                        .foregroundStyle(file.isDir ? .blue : .secondary)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        if !file.isDir {
                                            Text(ByteCountFormatter.string(
                                                fromByteCount: Int64(file.size),
                                                countStyle: .file
                                            ))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if file.isDir {
                                        Image(systemName: "chevron.forward")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    } else {
                                        RowActionButton(
                                            title: translations.get(
                                                "containerFileDeleteAction",
                                                fallback: "Delete file"
                                            ),
                                            systemImage: "trash",
                                            destructive: true
                                        ) { pendingDelete = file }
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    #if os(macOS)
                    .listStyle(.inset)
                    #else
                    .listStyle(.insetGrouped)
                    #endif
                    .refreshable {
                        fetch()
                    }
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"),
                   role: .destructive) {
                guard let file = pendingDelete else { return }
                pendingDelete = nil
                delete(file)
            }
            Button(translations.get("commonCancel", fallback: "Cancel"),
                   role: .cancel) { pendingDelete = nil }
        } message: {
            Text(translations.get("deleteCannotUndoMessage",
                                  fallback: "This action cannot be undone."))
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                actionError = nil
            }
        } message: {
            Text(actionError ?? "")
        }
        .navigationTitle(translations.get("containerTabFiles", fallback: "Files"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $preview) { item in
            NavigationStack {
                Group {
                    if item.isBinary {
                        EmptyStateView(
                            icon: "doc",
                            message: translations.get("containerFileBinaryHint",
                                                      fallback: "Binary file preview is not supported")
                        )
                    } else {
                        ScrollView {
                            Text(item.content)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                }
                .navigationTitle(item.name)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                #if os(macOS)
                .frame(minWidth: 640, minHeight: 480)
                #endif
            }
        }
        .onAppear {
            if files.isEmpty {
                fetch()
            }
        }
    }

    private func iconName(_ file: ContainerFileRow) -> String {
        if file.isDir { return "folder.fill" }
        if file.isLink { return "link" }
        return "doc"
    }

    private func open(_ file: ContainerFileRow) {
        if file.isDir {
            path = file.path
            files = []
            fetch()
            return
        }
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getContainerFileContent",
            arguments: ["containerId": containerId, "path": file.path]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any] else { return }
                preview = ContainerFilePreview(
                    name: file.name,
                    content: dict["content"] as? String ?? "",
                    isBinary: dict["isBinary"] as? Bool ?? false
                )
            }
        }
    }

    private func upload() {
        isUploading = true
        ChannelManager.shared.invokeDataMethod(
            "uploadFilesToContainer",
            arguments: ["containerId": containerId, "path": path]
        ) { result in
            DispatchQueue.main.async {
                isUploading = false
                let payload = result as? [String: Any] ?? [:]
                if payload["success"] as? Bool == true {
                    fetch()
                    return
                }
                if payload["cancelled"] as? Bool == true { return }
                actionError = payload["error"] as? String
                    ?? translations.get("filesUploadFailed", fallback: "Upload failed")
            }
        }
    }

    private func delete(_ file: ContainerFileRow) {
        ChannelManager.shared.invokeDataMethod(
            "deleteContainerFiles",
            arguments: ["containerId": containerId, "paths": [file.path]]
        ) { result in
            DispatchQueue.main.async {
                let payload = result as? [String: Any] ?? [:]
                if payload["success"] as? Bool == true {
                    files = []
                    fetch()
                    return
                }
                actionError = payload["error"] as? String
                    ?? translations.get("commonDeleteFailed", fallback: "Delete failed")
            }
        }
    }

    private func goUp() {
        guard path != "/" else { return }
        let parent = (path as NSString).deletingLastPathComponent
        path = parent.isEmpty ? "/" : parent
        files = []
        fetch()
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getContainerFiles",
            arguments: ["containerId": containerId, "path": path]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                files = items.compactMap { item in
                    guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                    return ContainerFileRow(
                        name: name,
                        path: item["path"] as? String ?? "\(path == "/" ? "" : path)/\(name)",
                        isDir: item["isDir"] as? Bool ?? false,
                        isLink: item["isLink"] as? Bool ?? false,
                        linkTo: item["linkTo"] as? String ?? "",
                        size: item["size"] as? Int ?? 0,
                        mode: item["mode"] as? String ?? "",
                        modTime: item["modTime"] as? String ?? ""
                    )
                }
            }
        }
    }
}

struct ContainerFilePreview: Identifiable {
    let name: String
    let content: String
    let isBinary: Bool

    var id: String { name + content.prefix(32) }
}