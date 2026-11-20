import Foundation

/// 已安装应用列表行。
struct AppModel: Identifiable {
    let installId: Int
    let name: String
    let status: String
    let version: String
    let icon: String

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
        self.icon = payload["icon"] as? String ?? ""
    }
}

/// 已安装应用详情（/apps/installed/info/:id）。
struct AppInstallInfoModel {
    let installId: Int
    let name: String
    let appName: String
    let appKey: String
    let version: String
    let status: String
    let message: String
    let httpPort: Int?
    let httpsPort: Int?
    let container: String
    let appType: String
    let createdAt: String
    let icon: String
}

/// 已安装应用参数行（/apps/installed/params/:id 的 params 数组）。
struct AppInstallParam: Identifiable {
    let key: String
    let labelZh: String
    let labelEn: String
    let type: String
    let value: String
    let isEditable: Bool

    var id: String { key }

    func label(chinese: Bool) -> String {
        let text = chinese ? labelZh : labelEn
        return text.isEmpty ? key : text
    }
}

/// 已安装应用参数完整载荷。
struct AppInstallConfig {
    let containerName: String
    let cpuQuota: Double
    let memoryLimit: Double
    let memoryUnit: String
    let webUI: String
    let type: String
    let params: [AppInstallParam]
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
    let icon: String
}

/// 应用目录详情（/apps/:key），用于商店详情页。
struct AppCatalogDetail {
    let id: Int
    let name: String
    let key: String
    let type: String
    let icon: String
    let summaryZh: String
    let summaryEn: String
    let readMe: String
    let website: String
    let github: String
    let versions: [String]
    let installed: Bool
    let gpuSupport: Bool
    let memoryRequired: Int
    let architectures: String
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

    @Published var installInfo: AppInstallInfoModel?
    @Published var installConfig: AppInstallConfig?
    @Published var detailLoading = false
    @Published var catalogDetail: AppCatalogDetail?
    @Published var catalogLoading = false

    /// 已安装应用列表（getApps 通道）。
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

    /// 已安装应用详情与参数（getAppInstallInfo + getAppInstallParams）。
    func fetchInstallDetail(installId: Int) {
        detailLoading = true
        installInfo = nil
        installConfig = nil
        let group = DispatchGroup()
        group.enter()
        ChannelManager.shared.invokeDataMethod(
            "getAppInstallInfo",
            arguments: ["installId": installId]
        ) { [weak self] result in
            DispatchQueue.main.async {
                if let dict = result as? [String: Any] {
                    self?.installInfo = AppInstallInfoModel(
                        installId: dict["id"] as? Int ?? installId,
                        name: dict["name"] as? String ?? "",
                        appName: dict["appName"] as? String ?? "",
                        appKey: dict["appKey"] as? String ?? "",
                        version: dict["version"] as? String ?? "",
                        status: dict["status"] as? String ?? "",
                        message: dict["message"] as? String ?? "",
                        httpPort: dict["httpPort"] as? Int,
                        httpsPort: dict["httpsPort"] as? Int,
                        container: dict["container"] as? String ?? "",
                        appType: dict["appType"] as? String ?? "",
                        createdAt: dict["createdAt"] as? String ?? "",
                        icon: dict["icon"] as? String ?? ""
                    )
                }
                group.leave()
            }
        }
        group.enter()
        ChannelManager.shared.invokeDataMethod(
            "getAppInstallParams",
            arguments: ["installId": installId]
        ) { [weak self] result in
            DispatchQueue.main.async {
                if let dict = result as? [String: Any] {
                    let params = (dict["params"] as? [[String: Any]] ?? []).compactMap { item -> AppInstallParam? in
                        guard let key = item["key"] as? String, !key.isEmpty else { return nil }
                        return AppInstallParam(
                            key: key,
                            labelZh: item["labelZh"] as? String ?? "",
                            labelEn: item["labelEn"] as? String ?? "",
                            type: item["type"] as? String ?? "text",
                            value: item["value"] as? String ?? "",
                            isEditable: item["edit"] as? Bool ?? false
                        )
                    }
                    self?.installConfig = AppInstallConfig(
                        containerName: dict["containerName"] as? String ?? "",
                        cpuQuota: dict["cpuQuota"] as? Double ?? 0,
                        memoryLimit: dict["memoryLimit"] as? Double ?? 0,
                        memoryUnit: dict["memoryUnit"] as? String ?? "",
                        webUI: dict["webUI"] as? String ?? "",
                        type: dict["type"] as? String ?? "",
                        params: params
                    )
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.detailLoading = false
        }
    }

    /// 应用目录详情（getAppDetailByKey 通道）。
    func fetchCatalogDetail(key: String) {
        catalogLoading = true
        catalogDetail = nil
        ChannelManager.shared.invokeDataMethod(
            "getAppDetailByKey",
            arguments: ["key": key]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.catalogLoading = false
                guard let dict = result as? [String: Any] else { return }
                self?.catalogDetail = AppCatalogDetail(
                    id: dict["id"] as? Int ?? 0,
                    name: dict["name"] as? String ?? "",
                    key: dict["key"] as? String ?? key,
                    type: dict["type"] as? String ?? "",
                    icon: dict["icon"] as? String ?? "",
                    summaryZh: dict["shortDescZh"] as? String ?? "",
                    summaryEn: dict["shortDescEn"] as? String ?? "",
                    readMe: dict["readMe"] as? String ?? "",
                    website: dict["website"] as? String ?? "",
                    github: dict["github"] as? String ?? "",
                    versions: (dict["versions"] as? [Any])?.compactMap { $0 as? String } ?? [],
                    installed: dict["installed"] as? Bool ?? false,
                    gpuSupport: dict["gpuSupport"] as? Bool ?? false,
                    memoryRequired: dict["memoryRequired"] as? Int ?? 0,
                    architectures: dict["architectures"] as? String ?? ""
                )
            }
        }
    }

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
                        summary: item["description"] as? String ?? "",
                        icon: item["icon"] as? String ?? ""
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

    /// 启动/停止/重启应用（startApp / stopApp / restartApp 通道）。
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
}
