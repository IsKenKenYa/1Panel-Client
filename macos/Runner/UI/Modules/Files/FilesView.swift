import SwiftUI

struct FilesView: View {
    @StateObject private var viewModel = FilesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(TranslationsManager.shared.get("navFiles", fallback: "Files"))
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
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.files) { file in
                            MDListItem(
                                title: file.name,
                                subtitle: file.isDir ? TranslationsManager.shared.get("folder", fallback: "Folder") : TranslationsManager.shared.get("file", fallback: "File"),
                                icon: file.isDir ? "folder.fill" : "doc.fill"
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchFiles()
        }
    }
}
