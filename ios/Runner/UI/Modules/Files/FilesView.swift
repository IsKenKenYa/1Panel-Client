import SwiftUI
import AppleSharedUI

/// 文件浏览：目录钻取 + 搜索 + 新建文件夹/文件 + 重命名 + 删除 + 压缩/解压 + 权限。
/// 根目录与子目录共用同一页面组件（FilesListPage）；非目录文件可打开内容页预览编辑。
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
    @State private var showNewFileAlert = false
    @State private var newEntryName = ""
    @State private var fileToRename: FileModel?
    @State private var renameDraft = ""
    @State private var fileToDelete: FileModel?
    @State private var showDeleteConfirm = false
    @State private var fileToCompress: FileModel?
    @State private var archiveName = ""
    @State private var showCompressSheet = false
    @State private var fileToExtract: FileModel?
    @State private var showExtractConfirm = false
    @State private var fileForPermissions: FileModel?
    @State private var permissionMode = "644"
    @State private var permissionUser = ""
    @State private var permissionGroup = ""
    @State private var fileToMove: FileModel?
    @State private var moveDestination = ""
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
            } else if viewModel.loadFailed && viewModel.files.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    viewModel.fetchFiles(path: path)
                }
            } else if viewModel.files.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    message: translations.get("filesEmptyTitle", fallback: "No files found")
                )
            } else if filteredFiles.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    message: translations.get("logNoMatches", fallback: "No matches found")
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
                            .contextMenu {
                                Button {
                                    renameDraft = file.name
                                    fileToRename = file
                                } label: {
                                    Label(translations.get("filesActionRename", fallback: "Rename"),
                                          systemImage: "pencil")
                                }
                                if !file.isDir {
                                    Button {
                                        archiveName = defaultArchiveName(for: file)
                                        fileToCompress = file
                                        showCompressSheet = true
                                    } label: {
                                        Label(translations.get("filesActionCompress", fallback: "Compress"),
                                              systemImage: "archivebox")
                                    }
                                    if archiveType(for: file) != nil {
                                        Button {
                                            fileToExtract = file
                                            showExtractConfirm = true
                                        } label: {
                                            Label(translations.get("filesActionExtract", fallback: "Extract"),
                                                  systemImage: "arrow.up.bin")
                                        }
                                    }
                                }
                                Button {
                                    fileToMove = file
                                    moveDestination = path
                                } label: {
                                    Label(translations.get("filesActionMove", fallback: "Move"),
                                          systemImage: "folder.badge.minus")
                                }
                                if !file.isDir {
                                    Button {
                                        downloadFile(file)
                                    } label: {
                                        Label(translations.get("filesActionDownload", fallback: "Download"),
                                              systemImage: "arrow.down.circle")
                                    }
                                }
                                Button {
                                    fileForPermissions = file
                                    permissionMode = "644"
                                    permissionUser = ""
                                    permissionGroup = ""
                                } label: {
                                    Label(translations.get("fileActionPermissions", fallback: "Permissions"),
                                          systemImage: "lock")
                                }
                                Button(role: .destructive) {
                                    fileToDelete = file
                                    showDeleteConfirm = true
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
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
                Menu {
                    Button {
                        newEntryName = ""
                        showNewFolderAlert = true
                    } label: {
                        Label(translations.get("filesActionNewFolder", fallback: "New Folder"),
                              systemImage: "folder.badge.plus")
                    }
                    Button {
                        newEntryName = ""
                        showNewFileAlert = true
                    } label: {
                        Label(translations.get("filesActionNewFile", fallback: "New File"),
                              systemImage: "doc.badge.plus")
                    }
                    Button {
                        uploadFiles()
                    } label: {
                        Label(translations.get("filesActionUpload", fallback: "Upload"),
                              systemImage: "arrow.up.doc")
                    }
                } label: {
                    Label(translations.get("filesActionNew", fallback: "New"),
                          systemImage: "plus")
                }
                Button {
                    viewModel.fetchFiles(path: path)
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .alert(translations.get("filesActionNewFolder", fallback: "New Folder"),
               isPresented: $showNewFolderAlert) {
            TextField(translations.get("filesFolderNameLabel", fallback: "Folder Name"),
                      text: $newEntryName)
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
            Button(translations.get("commonSave", fallback: "Save")) {
                let name = newEntryName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                viewModel.createFolder(in: path, name: name) { success in
                    showToast(success
                        ? translations.get("commonSaveSuccess", fallback: "Saved")
                        : translations.get("commonSaveFailed", fallback: "Save failed"))
                    viewModel.fetchFiles(path: path)
                }
            }
        }
        .alert(translations.get("filesActionNewFile", fallback: "New File"),
               isPresented: $showNewFileAlert) {
            TextField(translations.get("commonName", fallback: "Name"), text: $newEntryName)
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
            Button(translations.get("commonSave", fallback: "Save")) {
                let name = newEntryName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                viewModel.createFile(in: path, name: name) { success in
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
        .sheet(isPresented: $showCompressSheet) {
            compressSheet
        }
        .alert(permissionsTitle,
               isPresented: Binding(
                get: { fileForPermissions != nil },
                set: { if !$0 { fileForPermissions = nil } }
               )) {
            TextField(translations.get("filePermissionMode", fallback: "Mode"), text: $permissionMode)
            TextField(translations.get("filePermissionOwner", fallback: "Owner"), text: $permissionUser)
            TextField(translations.get("filePermissionGroup", fallback: "Group"), text: $permissionGroup)
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                fileForPermissions = nil
            }
            Button(translations.get("filePermissionApply", fallback: "Apply")) {
                applyPermissions()
            }
        }
        .alert(translations.get("filesActionMove", fallback: "Move"),
               isPresented: Binding(
                get: { fileToMove != nil },
                set: { if !$0 { fileToMove = nil } }
               )) {
            TextField(translations.get("filesMoveDestination", fallback: "Destination directory"),
                      text: $moveDestination)
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                fileToMove = nil
            }
            Button(translations.get("filesActionMove", fallback: "Move")) {
                moveFile()
            }
        }
        .confirmationDialog(
            extractConfirmTitle,
            isPresented: $showExtractConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("filesActionExtract", fallback: "Extract")) {
                extractSelected()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                fileToExtract = nil
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
        .operationNotice(toastText)
        .onChange(of: viewModel.loadFailed) { failed in
            if failed && !viewModel.files.isEmpty {
                showToast(translations.get("commonLoadFailedTitle", fallback: "Failed to load"))
            }
        }
        .onAppear {
            viewModel.fetchFiles(path: path)
        }
    }

    private var permissionsTitle: String {
        let name = fileForPermissions?.name ?? ""
        return "\(translations.get("filePermissionTitle", fallback: "Permissions")) · \(name)"
    }

    private var extractConfirmTitle: String {
        let name = fileToExtract?.name ?? ""
        let target = path == "/" ? "/" : path
        return "\(translations.get("filesActionExtract", fallback: "Extract")) \(name) → \(target)"
    }

    private var compressSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("fileCompressNameLabel", fallback: "Archive Name"),
                              text: $archiveName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("ZIP")
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("filesActionCompress", fallback: "Compress"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCompressSheet = false
                        fileToCompress = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("filesActionCompress", fallback: "Compress")) {
                        performCompress()
                    }
                    .disabled(archiveName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func performCompress() {
        guard let file = fileToCompress else { return }
        var name = archiveName.trimmingCharacters(in: .whitespaces)
        if !name.lowercased().hasSuffix(".zip") {
            name += ".zip"
        }
        showCompressSheet = false
        viewModel.compress(
            paths: [file.path],
            destination: path,
            name: name,
            type: "zip"
        ) { success in
            fileToCompress = nil
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchFiles(path: path)
        }
    }

    private func extractSelected() {
        guard let file = fileToExtract, let type = archiveType(for: file) else {
            fileToExtract = nil
            return
        }
        fileToExtract = nil
        viewModel.extract(path: file.path, destination: path, type: type) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchFiles(path: path)
        }
    }

    private func applyPermissions() {
        guard let file = fileForPermissions else { return }
        let mode = permissionMode.trimmingCharacters(in: .whitespaces)
        let user = permissionUser.trimmingCharacters(in: .whitespaces)
        let group = permissionGroup.trimmingCharacters(in: .whitespaces)
        fileForPermissions = nil
        let dispatch = DispatchGroup()
        var allSucceeded = true
        if !mode.isEmpty {
            dispatch.enter()
            viewModel.changeMode(path: file.path, octalMode: mode) { success in
                allSucceeded = allSucceeded && success
                dispatch.leave()
            }
        }
        if !user.isEmpty && !group.isEmpty {
            dispatch.enter()
            viewModel.changeOwner(path: file.path, user: user, group: group) { success in
                allSucceeded = allSucceeded && success
                dispatch.leave()
            }
        }
        dispatch.notify(queue: .main) {
            showToast(allSucceeded
                ? translations.get("filePermissionUpdated", fallback: "Permissions updated")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchFiles(path: path)
        }
    }

    private func defaultArchiveName(for file: FileModel) -> String {
        let base = (file.name as NSString).deletingPathExtension
        return base.isEmpty ? file.name : base
    }

    /// 从设备选择文件上传到当前目录（uploadFilesFromDevice 通道）。
    private func uploadFiles() {
        ChannelManager.shared.invokeDataMethod(
            "uploadFilesFromDevice",
            arguments: ["dir": path]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                if dict?["cancelled"] as? Bool == true {
                    return
                }
                let success = dict?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("filesUploadSuccess", fallback: "Uploaded")
                    : translations.get("filesUploadFailed", fallback: "Upload failed"))
                if success {
                    viewModel.fetchFiles(path: path)
                }
            }
        }
    }

    /// 下载服务器文件到设备（downloadFileToDevice 通道）。
    private func downloadFile(_ file: FileModel) {
        ChannelManager.shared.invokeDataMethod(
            "downloadFileToDevice",
            arguments: ["path": file.path]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                if dict?["cancelled"] as? Bool == true {
                    showToast(translations.get("filesDownloadCancelled",
                                                fallback: "Download cancelled"))
                    return
                }
                let success = dict?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("filesDownloadSuccess", fallback: "Downloaded")
                    : translations.get("filesDownloadFailed", fallback: "Download failed"))
            }
        }
    }

    /// 移动文件或目录到目标目录（moveFilesHandler 通道）。
    private func moveFile() {
        guard let file = fileToMove else { return }
        let destination = moveDestination.trimmingCharacters(in: .whitespaces)
        fileToMove = nil
        guard !destination.isEmpty else { return }
        ChannelManager.shared.invokeDataMethod(
            "moveFilesHandler",
            arguments: ["oldPaths": [file.path], "newPath": destination]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("filesMoveSuccess", fallback: "Moved")
                    : translations.get("filesMoveFailed", fallback: "Move failed"))
                if success {
                    viewModel.fetchFiles(path: path)
                }
            }
        }
    }

    /// 压缩包类型按扩展名映射到服务端解压类型；非压缩包返回 nil。
    private func archiveType(for file: FileModel) -> String? {
        let lower = file.name.lowercased()
        if lower.hasSuffix(".tar.gz") || lower.hasSuffix(".tgz") {
            return "tar.gz"
        }
        if lower.hasSuffix(".zip") { return "zip" }
        if lower.hasSuffix(".tar") { return "tar" }
        if lower.hasSuffix(".gz") { return "gz" }
        if lower.hasSuffix(".bz2") { return "bz2" }
        if lower.hasSuffix(".xz") { return "xz" }
        if lower.hasSuffix(".7z") { return "7z" }
        if lower.hasSuffix(".rar") { return "rar" }
        return nil
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
            NavigationLink {
                FileContentView(path: file.path)
            } label: {
                FileRowContent(file: file)
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
