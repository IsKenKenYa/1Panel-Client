import SwiftUI
import AppleSharedUI

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
    @EnvironmentObject var translations: TranslationsManager

    let containerId: String

    @State private var path = "/"
    @State private var files: [ContainerFileRow] = []
    @State private var isLoading = false
    @State private var preview: ContainerFilePreview?

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
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
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
                                        .foregroundColor(file.isDir ? .blue : .secondary)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        if !file.isDir {
                                            Text(ByteCountFormatter.string(fromByteCount: Int64(file.size),
                                                                           countStyle: .file))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if file.isDir {
                                        Image(systemName: "chevron.forward")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        fetch()
                    }
                }
            }
        }
        .navigationTitle(translations.get("containerTabFiles", fallback: "Files"))
        .navigationBarTitleDisplayMode(.inline)
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
                .navigationBarTitleDisplayMode(.inline)
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