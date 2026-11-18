import Foundation

struct FileModel: Identifiable {
    let name: String
    let isDir: Bool
    let path: String
    let size: Int64
    let modTime: Int64

    var id: String { path }
}

class FilesViewModel: ObservableObject {
    @Published var files: [FileModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var currentPath: String = "/"
    @Published var errorMessage: String?

    /// 删除文件或目录（deleteFile 通道）。
    func deleteFile(path: String, isDir: Bool, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "deleteFile",
            arguments: ["path": path, "isDir": isDir]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 在指定目录创建文件夹（createFolder 通道）。
    func createFolder(in directory: String, name: String, completion: @escaping (Bool) -> Void) {
        let folderPath = directory == "/" ? "/\(name)" : "\(directory)/\(name)"
        ChannelManager.shared.invokeDataMethod(
            "createFolder",
            arguments: ["path": folderPath]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 重命名（renameFile 通道：原路径同目录 + 新名称）。
    func rename(oldPath: String, newName: String, completion: @escaping (Bool) -> Void) {
        let parent = (oldPath as NSString).deletingLastPathComponent
        let newPath = parent == "/" || parent.isEmpty
            ? "/\(newName)"
            : "\(parent)/\(newName)"
        ChannelManager.shared.invokeDataMethod(
            "renameFile",
            arguments: ["oldPath": oldPath, "newPath": newPath]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

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
                    let size = dict["size"] as? Int64 ?? 0
                    let modTime = dict["modTime"] as? Int64 ?? 0
                    let fullPath = (targetPath as NSString).appendingPathComponent(name)
                    return FileModel(name: name, isDir: isDir, path: fullPath, size: size, modTime: modTime)
                }
            }
        }
    }
}
