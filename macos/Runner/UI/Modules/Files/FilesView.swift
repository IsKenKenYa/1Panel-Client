import SwiftUI

// `LoadingView` and `EmptyStateView` live in `UI/Components/` and are
// wired into the Xcode project — no need to redeclare them here.

struct FilesView: View {
    @StateObject private var viewModel = FilesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    @State private var showingNewFolderDialog = false
    @State private var newFolderName = ""
    @State private var renamingFile: FileModel?
    @State private var renameDraft = ""
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.files.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    message: translations.get("filesEmptyTitle", fallback: "No files found")
                )
            } else {
                Table(viewModel.files) {
                    TableColumn(translations.get("filesNameLabel", fallback: "Name")) { file in
                        HStack {
                            Image(systemName: file.isDir ? "folder.fill" : "doc.fill")
                                .foregroundColor(file.isDir ? .blue : .secondary)
                            Text(file.name)
                        }
                        .contextMenu {
                            if file.isDir {
                                Button(action: {
                                    viewModel.fetchFiles(path: file.path)
                                }) {
                                    Text(translations.get("filesActionOpen", fallback: "Open"))
                                    Image(systemName: "folder")
                                }
                                Divider()
                            }
                            Button(action: {
                                renameDraft = file.name
                                renamingFile = file
                            }) {
                                Text(translations.get("filesActionRename", fallback: "Rename"))
                                Image(systemName: "pencil")
                            }
                            Button(action: {
                                Task {
                                    await viewModel.deleteFile(path: file.path)
                                }
                            }) {
                                Text(translations.get("commonDelete", fallback: "Delete"))
                                Image(systemName: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("filesTypeLabel", fallback: "Type")) { file in
                        Text(file.isDir ? translations.get("filesTypeFolder", fallback: "Folder") : translations.get("filesTypeFile", fallback: "File"))
                            .foregroundColor(.secondary)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(URL(fileURLWithPath: viewModel.currentPath).lastPathComponent == "/" ? translations.get("navFiles", fallback: "Files") : URL(fileURLWithPath: viewModel.currentPath).lastPathComponent)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    let parent = (viewModel.currentPath as NSString).deletingLastPathComponent
                    viewModel.fetchFiles(path: parent.isEmpty ? "/" : parent)
                }) {
                    Image(systemName: "arrow.up")
                }
                .disabled(viewModel.currentPath == "/")
                .help(translations.get("filesActionUp", fallback: "Up"))
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showingNewFolderDialog = true
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help(translations.get("filesActionNewFolder", fallback: "New Folder"))
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchFiles()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
        }
        .onAppear {
            viewModel.fetchFiles()
        }
        .sheet(isPresented: $showingNewFolderDialog) {
            VStack(spacing: 16) {
                Text(translations.get("filesActionNewFolder", fallback: "New Folder"))
                    .font(.headline)
                TextField(translations.get("filesFolderNameLabel", fallback: "Folder Name"), text: $newFolderName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showingNewFolderDialog = false
                        newFolderName = ""
                    }
                    Button(translations.get("commonCreate", fallback: "Create")) {
                        Task {
                            await viewModel.createFolder(name: newFolderName)
                            showingNewFolderDialog = false
                            newFolderName = ""
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newFolderName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
        .sheet(item: $renamingFile) { file in
            VStack(spacing: 16) {
                Text(translations.get("filesActionRename", fallback: "Rename"))
                    .font(.headline)
                TextField(translations.get("commonName", fallback: "Name"), text: $renameDraft)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        renamingFile = nil
                        renameDraft = ""
                    }
                    Button(translations.get("commonSave", fallback: "Save")) {
                        let name = renameDraft
                        renamingFile = nil
                        Task {
                            if !name.isEmpty && name != file.name {
                                await viewModel.renameFile(oldPath: file.path, newName: name)
                            }
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(renameDraft.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
}
