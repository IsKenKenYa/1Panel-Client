import Foundation

struct WebsiteModel: Identifiable, Hashable {
    let originalId: String
    let primaryDomain: String
    let status: String
    let remark: String

    var id: String { originalId }
}

/// 建站表单的可选项（分组 / 运行环境 / 父站点）。
struct WebsiteOption: Identifiable, Hashable {
    let id: Int
    let name: String
}

class WebsitesViewModel: ObservableObject {
    @Published var websites: [WebsiteModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    @Published var createGroups: [WebsiteOption] = []
    @Published var createRuntimes: [WebsiteOption] = []
    @Published var createParents: [WebsiteOption] = []
    @Published var createOptionsLoaded = false

    /// 预载建站表单选项（getWebsiteCreateOptions 通道）。
    func fetchCreateOptions() {
        ChannelManager.shared.invokeDataMethod("getWebsiteCreateOptions") { [weak self] result in
            DispatchQueue.main.async {
                guard let dict = result as? [String: Any] else { return }
                self?.createGroups = Self.parseOptions(dict["groups"], nameKey: "name")
                self?.createRuntimes = Self.parseOptions(dict["runtimes"], nameKey: "name")
                self?.createParents = Self.parseOptions(dict["parentWebsites"], nameKey: "primaryDomain")
                self?.createOptionsLoaded = true
            }
        }
    }

    private static func parseOptions(_ raw: Any?, nameKey: String) -> [WebsiteOption] {
        guard let items = raw as? [[String: Any]] else { return [] }
        return items.compactMap { item in
            guard let id = item["id"] as? Int else { return nil }
            let name = item[nameKey] as? String ?? ""
            return WebsiteOption(id: id, name: name)
        }
    }

    /// 启动/停止网站（toggleWebsiteStatus 通道：id + currentStatus）。
    func toggleStatus(id: Int, currentStatus: String, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "toggleWebsiteStatus",
            arguments: ["id": id, "currentStatus": currentStatus]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 创建网站（createWebsite 通道）。
    func createWebsite(
        alias: String,
        type: String,
        primaryDomain: String,
        groupId: Int,
        remark: String,
        runtimeId: Int?,
        siteDir: String,
        proxyType: String,
        proxy: String,
        port: String,
        parentWebsiteId: Int?,
        completion: @escaping (Bool, String?) -> Void
    ) {
        var args: [String: Any] = [
            "alias": alias,
            "type": type,
            "primaryDomain": primaryDomain,
            "groupId": groupId,
        ]
        if !remark.isEmpty { args["remark"] = remark }
        if let runtimeId { args["runtimeId"] = runtimeId }
        if !siteDir.isEmpty { args["siteDir"] = siteDir }
        if type == "proxy" {
            args["proxyType"] = proxyType
            args["proxy"] = proxy
            if !port.isEmpty { args["port"] = port }
        }
        if let parentWebsiteId { args["parentWebsiteId"] = parentWebsiteId }
        ChannelManager.shared.invokeDataMethod("createWebsite", arguments: args) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                completion(success, dict?["error"] as? String)
            }
        }
    }

    /// 删除网站（deleteWebsite 通道）。
    func deleteWebsite(id: Int, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "deleteWebsite",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    func fetchWebsites() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getWebsites") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else { return }
                self?.websites = dictArray.compactMap { dict in
                    guard let primaryDomain = dict["primaryDomain"] as? String,
                          let status = dict["status"] as? String,
                          let remark = dict["remark"] as? String else { return nil }
                    let rawId = dict["id"]
                    let idStr: String
                    if let intId = rawId as? Int { idStr = String(intId) }
                    else { idStr = rawId as? String ?? "" }
                    return WebsiteModel(originalId: idStr, primaryDomain: primaryDomain, status: status, remark: remark)
                }
            }
        }
    }
}
