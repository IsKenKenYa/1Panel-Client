import Foundation

struct FileModel: Identifiable {
    let id = UUID()
    let name: String
    let isDir: Bool
    let path: String
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
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync("deleteFile", arguments: ["path": path])
            DispatchQueue.main.async {
                self.fetchFiles()
            }
        } catch {
            print("Failed to delete file: \(error)")
        }
    }
    
    func createFolder(name: String) async {
        do {
            let newPath = (currentPath as NSString).appendingPathComponent(name)
            _ = try await ChannelManager.shared.invokeDataMethodAsync("createFolder", arguments: ["path": newPath])
            DispatchQueue.main.async {
                self.fetchFiles()
            }
        } catch {
            print("Failed to create folder: \(error)")
        }
    }
}
