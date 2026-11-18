import SwiftUI

struct FilesView: View {
    @StateObject private var viewModel = FilesViewModel()
    @EnvironmentObject private var translations: TranslationsManager

    @State private var selectedFileID: FileModel.ID?
    @State private var showingNewFolderDialog = false
    @State private var newFolderName = ""
    @State private var renamingFile: FileModel?
    @State private var renameDraft = ""
    @State private var fileToDelete: FileModel?

    var body: some View {
        Group {
            if let directory = viewModel.directory {
                if directory.files.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        message: translations.get("filesEmptyTitle", fallback: "This folder is empty")
                    )
                } else {
                    fileTable(directory.files)
                }
            } else if let error = viewModel.loadError {
                ErrorView(message: error) {
                    Task { await viewModel.fetchFiles() }
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle(translations.get("navFiles", fallback: "Files"))
        .navigationSubtitle(viewModel.currentPath)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    let parent = (viewModel.currentPath as NSString).deletingLastPathComponent
                    Task { await viewModel.fetchFiles(path: parent.isEmpty ? "/" : parent) }
                } label: {
                    Label(translations.get("filesActionUp", fallback: "Up"), systemImage: "arrow.up")
                }
                .disabled(viewModel.isBusy || viewModel.currentPath == "/")
                .keyboardShortcut(.upArrow, modifiers: .command)
                .help(translations.get("filesActionUp", fallback: "Up"))
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    newFolderName = ""
                    viewModel.operationError = nil
                    showingNewFolderDialog = true
                } label: {
                    Label(translations.get("filesActionNewFolder", fallback: "New Folder"), systemImage: "folder.badge.plus")
                }
                .disabled(viewModel.isBusy || viewModel.directory == nil)
                .help(translations.get("filesActionNewFolder", fallback: "New Folder"))
            }
            ToolbarItem(placement: .automatic) {
                let file = viewModel.directory?.files.first { $0.id == selectedFileID }
                Menu {
                    if let file {
                        fileActions(file)
                    }
                } label: {
                    Label(translations.get("commonMore", fallback: "More"), systemImage: "ellipsis.circle")
                }
                .disabled(viewModel.isBusy || file == nil)
                .help(translations.get("commonMore", fallback: "More"))
            }
            ToolbarItem(placement: .automatic) {
                if viewModel.isBusy {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        Task { await viewModel.fetchFiles() }
                    } label: {
                        Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .task {
            await viewModel.fetchFiles()
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { fileToDelete != nil },
                set: { if !$0 { fileToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: fileToDelete
        ) { file in
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                Task {
                    if await viewModel.deleteFile(file) {
                        await viewModel.fetchFiles()
                    }
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: { file in
            Text(file.path)
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.operationError != nil && !showingNewFolderDialog && renamingFile == nil },
            set: { if !$0 { viewModel.operationError = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {}
        } message: {
            Text(viewModel.operationError ?? "")
        }
        .sheet(isPresented: $showingNewFolderDialog) {
            nameSheet(
                title: translations.get("filesActionNewFolder", fallback: "New Folder"),
                fieldTitle: translations.get("filesFolderNameLabel", fallback: "Folder Name"),
                actionTitle: translations.get("commonCreate", fallback: "Create"),
                name: $newFolderName,
                submit: viewModel.createFolder,
                close: { showingNewFolderDialog = false }
            )
        }
        .sheet(item: $renamingFile) { file in
            nameSheet(
                title: translations.get("filesActionRename", fallback: "Rename"),
                fieldTitle: translations.get("commonName", fallback: "Name"),
                actionTitle: translations.get("commonSave", fallback: "Save"),
                name: $renameDraft,
                originalName: file.name,
                submit: { await viewModel.renameFile(file, newName: $0) },
                close: { renamingFile = nil }
            )
        }
    }

    private func fileTable(_ files: [FileModel]) -> some View {
        Table(files, selection: $selectedFileID) {
            TableColumn(translations.get("filesNameLabel", fallback: "Name")) { file in
                Label(file.name, systemImage: file.isDir ? "folder" : "doc")
                    .foregroundStyle(file.isDir ? Color.accentColor : Color.primary)
            }
            TableColumn(translations.get("filesTypeLabel", fallback: "Type")) { file in
                Text(file.isDir ? translations.get("filesTypeFolder", fallback: "Folder") : translations.get("filesTypeFile", fallback: "File"))
                    .foregroundStyle(.secondary)
            }
        }
        .tableStyle(.inset)
        .disableAlternatingRowBackgrounds()
        .contextMenu(forSelectionType: FileModel.ID.self) { selection in
            if let id = selection.first, let file = files.first(where: { $0.id == id }) {
                fileActions(file)
            }
        } primaryAction: { selection in
            if let id = selection.first, let file = files.first(where: { $0.id == id && $0.isDir }) {
                Task { await viewModel.fetchFiles(path: file.path) }
            }
        }
    }

    @ViewBuilder
    private func fileActions(_ file: FileModel) -> some View {
        if file.isDir {
            Button {
                Task { await viewModel.fetchFiles(path: file.path) }
            } label: {
                Label(translations.get("filesActionOpen", fallback: "Open"), systemImage: "folder")
            }
            .disabled(viewModel.isBusy)
            Divider()
        }
        Button {
            viewModel.operationError = nil
            renameDraft = file.name
            renamingFile = file
        } label: {
            Label(translations.get("filesActionRename", fallback: "Rename"), systemImage: "pencil")
        }
        .disabled(viewModel.isBusy)
        Divider()
        Button(role: .destructive) {
            fileToDelete = file
        } label: {
            Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
        }
        .disabled(viewModel.isBusy)
    }

    private func nameSheet(
        title: String,
        fieldTitle: String,
        actionTitle: String,
        name: Binding<String>,
        originalName: String? = nil,
        submit: @escaping (String) async -> Bool,
        close: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)
            TextField(fieldTitle, text: name)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isProcessing)
            if let error = viewModel.operationError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer()
                if viewModel.isProcessing {
                    ProgressView().controlSize(.small)
                }
                Button(translations.get("commonCancel", fallback: "Cancel")) {
                    viewModel.operationError = nil
                    close()
                }
                .keyboardShortcut(.cancelAction)
                .disabled(viewModel.isProcessing)
                Button(actionTitle) {
                    let submittedName = name.wrappedValue
                    Task {
                        if await submit(submittedName) {
                            close()
                            await viewModel.fetchFiles()
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isBusy || name.wrappedValue.isEmpty || name.wrappedValue == originalName)
            }
        }
        .padding(20)
        .frame(width: 360)
        .interactiveDismissDisabled(viewModel.isProcessing)
    }
}
