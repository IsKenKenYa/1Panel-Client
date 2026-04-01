import Foundation

struct FileModel: Identifiable {
    let name: String
    let isDir: Bool
    let path: String
    
    var id: String { path }
}

class FilesViewModel: ObservableObject {
    @Published var files: [FileModel] = []
    @Published var isLoading = false
    @Published var currentPath: String = "/"
    
    func fetchFiles(path: String? = nil) {
        let targetPath = path ?? currentPath
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getFiles", arguments: ["path": targetPath]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.currentPath = targetPath
                if let dictArray = result as? [[String: Any]] {
                    self?.files = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String else { return nil }
                        let isDir = dict["isDir"] as? Bool ?? false
                        let fullPath = (targetPath as NSString).appendingPathComponent(name)
                        return FileModel(name: name, isDir: isDir, path: fullPath)
                    }
                }
            }
        }
    }
    
    func deleteFile(path: String) async {
        // The Dart-side handler for deleting a file is not implemented.
        // Do not attempt to call an unsupported method-channel action.
        print("deleteFile is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchFiles()
        }
    }
    
    func createFolder(name: String) async {
        // The Dart-side handler for creating a folder is not implemented.
        // Do not attempt to call an unsupported method-channel action.
        print("createFolder is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchFiles()
        }
    }
}
