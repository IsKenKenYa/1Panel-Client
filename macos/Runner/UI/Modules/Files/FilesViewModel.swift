import Foundation

struct FileModel: Identifiable {
    let name: String
    let isDir: Bool
    let path: String
    let size: Int

    var id: String { path }
}

struct FileDirectory {
    let path: String
    let files: [FileModel]

    init?(path: String, payload: Any?) {
        guard let rows = payload as? [[String: Any]] else { return nil }
        var entries: [FileModel] = []
        for row in rows {
            guard let name = row["name"] as? String, !name.isEmpty,
                  let isDir = row["isDir"] as? Bool else { return nil }
            entries.append(FileModel(
                name: name,
                isDir: isDir,
                path: (path as NSString).appendingPathComponent(name),
                size: row["size"] as? Int ?? 0
            ))
        }
        self.path = path
        self.files = entries
    }
}

@MainActor
final class FilesViewModel: ObservableObject {
    @Published private(set) var directory: FileDirectory?
    @Published private(set) var isLoading = false
    @Published private(set) var isProcessing = false
    @Published private(set) var loadError: String?
    @Published var operationError: String?

    var currentPath: String { directory?.path ?? "/" }
    var isBusy: Bool { isLoading || isProcessing }

    func fetchFiles(path: String? = nil) async {
        guard !isBusy else { return }
        let targetPath = path ?? currentPath
        let failure = TranslationsManager.shared.get("commonLoadFailedTitle", fallback: "Failed to load")
        isLoading = true
        loadError = nil
        operationError = nil
        defer { isLoading = false }
        do {
            let result = try await ChannelManager.shared.invokeDataMethodAsync("getFiles", arguments: ["path": targetPath])
            guard let listing = FileDirectory(path: targetPath, payload: result) else {
                showLoadFailure(failure)
                return
            }
            directory = listing
        } catch {
            showLoadFailure(error.localizedDescription)
        }
    }

    func deleteFile(_ file: FileModel) async -> Bool {
        await performWrite(
            "deleteFile",
            arguments: ["path": file.path, "isDir": file.isDir],
            failureKey: "filesDeleteFailed",
            fallback: "Delete failed"
        )
    }

    func renameFile(_ file: FileModel, newName: String) async -> Bool {
        let parent = (file.path as NSString).deletingLastPathComponent
        let newPath = (parent as NSString).appendingPathComponent(newName)
        return await performWrite(
            "renameFile",
            arguments: ["oldPath": file.path, "newPath": newPath],
            failureKey: "filesRenameFailed",
            fallback: "Rename failed"
        )
    }

    func createFolder(name: String) async -> Bool {
        let newPath = (currentPath as NSString).appendingPathComponent(name)
        return await performWrite(
            "createFolder",
            arguments: ["path": newPath],
            failureKey: "filesCreateFailed",
            fallback: "Create failed"
        )
    }

    private func showLoadFailure(_ message: String) {
        if directory == nil {
            loadError = message
        } else {
            operationError = message
        }
    }

    private func performWrite(
        _ method: String,
        arguments: [String: Any],
        failureKey: String,
        fallback: String
    ) async -> Bool {
        guard !isBusy else { return false }
        isProcessing = true
        operationError = nil
        defer { isProcessing = false }
        do {
            let result = try await ChannelManager.shared.invokeDataMethodAsync(method, arguments: arguments) as? [String: Any]
            guard result?["success"] as? Bool == true else {
                operationError = result?["error"] as? String ?? TranslationsManager.shared.get(failureKey, fallback: fallback)
                return false
            }
            return true
        } catch {
            operationError = error.localizedDescription
            return false
        }
    }
}
