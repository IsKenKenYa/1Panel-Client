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
    @Published private(set) var loadFailed = false

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

    /// 新建空文件（createFileHandler 通道）。
    func createFile(in directory: String, name: String, completion: @escaping (Bool) -> Void) {
        let filePath = directory == "/" ? "/\(name)" : "\(directory)/\(name)"
        ChannelManager.shared.invokeDataMethod(
            "createFileHandler",
            arguments: ["path": filePath]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 压缩文件（compressFilesHandler 通道：files + dst + name + type）。
    func compress(paths: [String], destination: String, name: String, type: String,
                  completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "compressFilesHandler",
            arguments: ["files": paths, "dst": destination, "name": name, "type": type]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 解压文件（decompressFileHandler 通道：path + dst + type）。
    func extract(path: String, destination: String, type: String,
                 completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "decompressFileHandler",
            arguments: ["path": path, "dst": destination, "type": type]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 修改权限（changeFileModeHandler 通道：path + mode，八进制文本转十进制）。
    func changeMode(path: String, octalMode: String, completion: @escaping (Bool) -> Void) {
        guard let mode = Int(octalMode, radix: 8) else {
            completion(false)
            return
        }
        ChannelManager.shared.invokeDataMethod(
            "changeFileModeHandler",
            arguments: ["path": path, "mode": mode]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 修改所有者（changeFileOwnerHandler 通道：path + user + group）。
    func changeOwner(path: String, user: String, group: String,
                     completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "changeFileOwnerHandler",
            arguments: ["path": path, "user": user, "group": group]
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
        loadFailed = false
        ChannelManager.shared.invokeDataMethod("getFiles", arguments: ["path": targetPath]) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    self.loadFailed = true
                    return
                }
                self.currentPath = targetPath
                self.files = dictArray.compactMap { dict in
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
