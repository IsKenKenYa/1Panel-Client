import SwiftUI

/// 文件浏览：目录钻取 + 搜索 + 新建文件夹 + 重命名 + 删除。
/// 根目录与子目录共用同一页面组件（FilesListPage）。
struct FilesView: View {
    var body: some View {
        FilesListPage(path: "/", isRoot: true)
    }
}

struct FilesListPage: View {
    @StateObject private var viewModel = FilesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    let path: String
    let isRoot: Bool

    @State private var searchText = ""
    @State private var showNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var fileToRename: FileModel?
    @State private var renameDraft = ""
    @State private var fileToDelete: FileModel?
    @State private var showDeleteConfirm = false
    @State private var toastText: String?

    private var filteredFiles: [FileModel] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return viewModel.files }
        return viewModel.files.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.files.isEmpty {
                LoadingView()
            } else if viewModel.files.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    message: translations.get("filesEmptyTitle", fallback: "No files found")
                )
            } else {
                List {
                    ForEach(filteredFiles) { file in
                        fileRow(file)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    fileToDelete = file
                                    showDeleteConfirm = true
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    renameDraft = file.name
                                    fileToRename = file
                                } label: {
                                    Label(translations.get("filesActionRename", fallback: "Rename"),
                                          systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetchFiles(path: path)
                }
            }
        }
        .navigationTitle(isRoot
            ? translations.get("navFiles", fallback: "Files")
            : (path as NSString).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: translations.get("filesActionSearch", fallback: "Search")
        )
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    newFolderName = ""
                    showNewFolderAlert = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                Button {
                    viewModel.fetchFiles(path: path)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .alert(translations.get("filesActionNewFolder", fallback: "New Folder"),
               isPresented: $showNewFolderAlert) {
            TextField(translations.get("filesFolderNameLabel", fallback: "Folder Name"),
                      text: $newFolderName)
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
            Button(translations.get("commonSave", fallback: "Save")) {
                let name = newFolderName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                viewModel.createFolder(in: path, name: name) { success in
                    showToast(success
                        ? translations.get("commonSaveSuccess", fallback: "Saved")
                        : translations.get("commonSaveFailed", fallback: "Save failed"))
                    viewModel.fetchFiles(path: path)
                }
            }
        }
        .alert(translations.get("filesActionRename", fallback: "Rename"),
               isPresented: Binding(
                get: { fileToRename != nil },
                set: { if !$0 { fileToRename = nil } }
               )) {
            TextField(translations.get("commonName", fallback: "Name"), text: $renameDraft)
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                fileToRename = nil
            }
            Button(translations.get("commonSave", fallback: "Save")) {
                guard let file = fileToRename else { return }
                let name = renameDraft.trimmingCharacters(in: .whitespaces)
                fileToRename = nil
                guard !name.isEmpty, name != file.name else { return }
                viewModel.rename(oldPath: file.path, newName: name) { success in
                    showToast(success
                        ? translations.get("commonSaveSuccess", fallback: "Saved")
                        : translations.get("commonSaveFailed", fallback: "Save failed"))
                    viewModel.fetchFiles(path: path)
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                guard let file = fileToDelete else { return }
                fileToDelete = nil
                viewModel.deleteFile(path: file.path, isDir: file.isDir) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                    viewModel.fetchFiles(path: path)
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                fileToDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .overlay(alignment: .bottom) {
            if let toastText {
                Text(toastText)
                    .font(.footnote)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            viewModel.fetchFiles(path: path)
        }
    }

    @ViewBuilder
    private func fileRow(_ file: FileModel) -> some View {
        if file.isDir {
            NavigationLink {
                FilesListPage(path: file.path, isRoot: false)
            } label: {
                FileRowContent(file: file)
            }
        } else {
            FileRowContent(file: file)
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

private struct FileRowContent: View {
    let file: FileModel

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: file.isDir ? "folder.fill" : "doc")
                .foregroundStyle(file.isDir ? Color.blue : Color.secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.body)
                HStack(spacing: 10) {
                    if !file.isDir && file.size > 0 {
                        Text(formatSize(file.size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if file.modTime > 0 {
                        Text(formatDate(file.modTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
