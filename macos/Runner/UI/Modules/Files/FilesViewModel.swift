import Foundation

struct FileModel: Identifiable {
    let id = UUID()
    let name: String
    let isDir: Bool
}

class FilesViewModel: ObservableObject {
    @Published var files: [FileModel] = []
    @Published var isLoading = false
    
    func fetchFiles(path: String = "/") {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getFiles", arguments: ["path": path]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.files = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String else { return nil }
                        let isDir = dict["isDir"] as? Bool ?? false
                        return FileModel(name: name, isDir: isDir)
                    }
                }
            }
        }
    }
}
