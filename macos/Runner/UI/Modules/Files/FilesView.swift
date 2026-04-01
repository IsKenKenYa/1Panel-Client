import SwiftUI

struct FilesView: View {
    @StateObject private var viewModel = FilesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(translations.get("navFiles", fallback: "Files"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
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
                    }
                    TableColumn(translations.get("file_type", fallback: "Type")) { file in
                        Text(file.isDir ? translations.get("folder", fallback: "Folder") : translations.get("file", fallback: "File"))
                            .foregroundColor(.secondary)
                    }
                }
                .tableStyle(.inset)
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchFiles()
        }
    }
}
