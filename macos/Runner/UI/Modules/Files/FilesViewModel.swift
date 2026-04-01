import Foundation

struct FileModel: Identifiable {
    let name: String
    let isDir: Bool
    let path: String
    let size: Int

    var id: String { path }
}

class FilesViewModel: ObservableObject {
    @Published var files: [FileModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var currentPath: String = "/"
    @Published var errorMessage: String?

    func fetchFiles(path: String? = nil) {
        let targetPath = path ?? currentPath
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getFiles", arguments: ["path": targetPath]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.currentPath = targetPath
                guard let dictArray = result as? [[String: Any]] else { return }
                self?.files = dictArray.compactMap { dict in
                    guard let name = dict["name"] as? String else { return nil }
                    let isDir = dict["isDir"] as? Bool ?? false
                    let size = dict["size"] as? Int ?? 0
                    let fullPath = (targetPath as NSString).appendingPathComponent(name)
                    return FileModel(name: name, isDir: isDir, path: fullPath, size: size)
                }
            }
        }
    }

    func deleteFile(path: String, isDir: Bool = false) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod(
            "deleteFile",
            arguments: ["path": path, "isDir": isDir]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchFiles()
            }
        }
    }

    func createFolder(name: String) async {
        let newPath = (currentPath as NSString).appendingPathComponent(name)
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("createFolder", arguments: ["path": newPath]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Create folder failed"
                }
                self?.fetchFiles()
            }
        }
    }
}
