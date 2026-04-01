import SwiftUI

struct FilesView: View {
    @StateObject private var viewModel = FilesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    @State private var showingNewFolderDialog = false
    @State private var newFolderName = ""
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.files.isEmpty {
                Text("No files found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.files) {
                    TableColumn(translations.get("server_name", fallback: "Name")) { file in
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
                                    Text(translations.get("open", fallback: "Open"))
                                    Image(systemName: "folder")
                                }
                                Divider()
                            }
                            Button(action: {
                                Task {
                                    await viewModel.deleteFile(path: file.path)
                                }
                            }) {
                                Text(translations.get("delete", fallback: "Delete"))
                                Image(systemName: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("file_type", fallback: "Type")) { file in
                        Text(file.isDir ? translations.get("folder", fallback: "Folder") : translations.get("file", fallback: "File"))
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
                .help("Up")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showingNewFolderDialog = true
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("New Folder")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchFiles()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchFiles()
        }
        .sheet(isPresented: $showingNewFolderDialog) {
            VStack(spacing: 16) {
                Text(translations.get("create_folder", fallback: "New Folder"))
                    .font(.headline)
                TextField("Folder Name", text: $newFolderName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button("Cancel") {
                        showingNewFolderDialog = false
                        newFolderName = ""
                    }
                    Button("Create") {
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
    }
}
