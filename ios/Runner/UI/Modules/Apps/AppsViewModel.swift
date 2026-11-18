import Foundation

struct AppModel: Identifiable {
    let installId: Int
    let name: String
    let status: String
    let version: String

    var id: Int { installId }

    init?(payload: [String: Any]) {
        guard let installId = payload["installId"] as? Int, installId > 0,
              let name = payload["name"] as? String,
              let status = payload["status"] as? String,
              let version = payload["version"] as? String else { return nil }
        self.installId = installId
        self.name = name
        self.status = status
        self.version = version
    }
}

/// 应用商店条目。
struct StoreApp: Identifiable, Hashable {
    let id: Int
    let name: String
    let key: String
    let type: String
    let versions: [String]
    let installed: Bool
    let summary: String
}

/// 安装表单动态字段。
struct AppInstallField: Identifiable, Hashable {
    struct Option: Hashable {
        let label: String
        let value: String
    }

    let envKey: String
    let labelZh: String
    let labelEn: String
    let type: String
    let required: Bool
    let defaultValue: String?
    let values: [Option]

    var id: String { envKey }
}

/// 安装表单预载结果。
struct AppInstallForm {
    let appDetailId: Int
    let fields: [AppInstallField]
}

class AppsViewModel: ObservableObject {
    @Published var apps: [AppModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    @Published var storeApps: [StoreApp] = []
    @Published var isStoreLoading = false
    @Published var installForm: AppInstallForm?
    @Published var isFormLoading = false

    /// 应用商店列表（getAppStore 通道）。
    func fetchStore(search: String = "") {
        isStoreLoading = true
        var args: [String: Any] = [:]
        if !search.isEmpty { args["search"] = search }
        ChannelManager.shared.invokeDataMethod("getAppStore", arguments: args) { [weak self] result in
            DispatchQueue.main.async {
                self?.isStoreLoading = false
                guard let items = result as? [[String: Any]] else { return }
                self?.storeApps = items.compactMap { item in
                    guard let id = item["id"] as? Int,
                          let name = item["name"] as? String else { return nil }
                    let versions = (item["versions"] as? [Any])?.compactMap { $0 as? String } ?? []
                    return StoreApp(
                        id: id,
                        name: name,
                        key: item["key"] as? String ?? "",
                        type: item["type"] as? String ?? "app",
                        versions: versions,
                        installed: item["installed"] as? Bool ?? false,
                        summary: item["description"] as? String ?? ""
                    )
                }
            }
        }
    }

    /// 应用版本列表（getAppVersions 通道）。
    func fetchAppVersions(key: String, completion: @escaping ([String]) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "getAppVersions",
            arguments: ["key": key]
        ) { result in
            DispatchQueue.main.async {
                guard let dict = result as? [String: Any] else {
                    completion([])
                    return
                }
                let versions = (dict["versions"] as? [Any])?.compactMap { $0 as? String } ?? []
                completion(versions)
            }
        }
    }

    /// 安装表单（getAppInstallForm 通道）：appDetailId + 动态字段。
    func fetchInstallForm(appId: Int, version: String, type: String, completion: ((Bool) -> Void)? = nil) {
        isFormLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getAppInstallForm",
            arguments: ["appId": appId, "version": version, "type": type]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFormLoading = false
                guard let dict = result as? [String: Any],
                      let appDetailId = dict["appDetailId"] as? Int else {
                    completion?(false)
                    return
                }
                let rawFields = dict["fields"] as? [[String: Any]] ?? []
                let fields = rawFields.map { field in
                    let options = (field["values"] as? [[String: Any]] ?? []).compactMap { item -> AppInstallField.Option? in
                        guard let value = item["value"] as? String, !value.isEmpty else { return nil }
                        return AppInstallField.Option(
                            label: item["label"] as? String ?? value,
                            value: value
                        )
                    }
                    return AppInstallField(
                        envKey: field["envKey"] as? String ?? "",
                        labelZh: field["labelZh"] as? String ?? "",
                        labelEn: field["labelEn"] as? String ?? "",
                        type: field["type"] as? String ?? "text",
                        required: field["required"] as? Bool ?? false,
                        defaultValue: field["defaultValue"] as? String,
                        values: options
                    )
                }
                self?.installForm = AppInstallForm(appDetailId: appDetailId, fields: fields)
                completion?(true)
            }
        }
    }

    /// 安装应用（installApp 通道）。
    func installApp(
        appDetailId: Int,
        name: String,
        type: String,
        params: [String: String],
        advanced: Bool,
        containerName: String?,
        cpuQuota: String?,
        memoryLimit: String?,
        services: [String: String],
        completion: @escaping (Bool, String?) -> Void
    ) {
        var args: [String: Any] = [
            "appDetailId": appDetailId,
            "name": name,
            "type": type,
            "advanced": advanced,
        ]
        if !params.isEmpty { args["params"] = params }
        if advanced {
            if let containerName, !containerName.isEmpty { args["containerName"] = containerName }
            if let cpuQuota, !cpuQuota.isEmpty { args["cpuQuota"] = cpuQuota }
            if let memoryLimit, !memoryLimit.isEmpty {
                args["memoryLimit"] = memoryLimit
                args["memoryUnit"] = "MB"
            }
            if !services.isEmpty { args["services"] = services }
        }
        ChannelManager.shared.invokeDataMethod("installApp", arguments: args) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                completion(success, dict?["error"] as? String)
            }
        }
    }

    /// 启动/停止应用（startApp / stopApp 通道，installId 为键）。
    func operateApp(installId: Int, operate: String, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            operate,
            arguments: ["installId": installId]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 更新应用（updateApp 通道）。
    func updateApp(installId: Int, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "updateApp",
            arguments: ["installId": String(installId)]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 卸载应用（uninstallApp 通道）。
    func uninstallApp(installId: Int, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "uninstallApp",
            arguments: ["installId": String(installId)]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    func fetchApps() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getApps") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else { return }
                self?.apps = dictArray.compactMap(AppModel.init(payload:))
            }
        }
    }
}
