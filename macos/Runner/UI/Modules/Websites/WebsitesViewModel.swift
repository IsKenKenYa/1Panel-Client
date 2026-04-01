import Foundation

struct WebsiteModel: Identifiable {
    let id = UUID()
    let originalId: String
    let primaryDomain: String
    let status: String
    let remark: String
}

class WebsitesViewModel: ObservableObject {
    @Published var websites: [WebsiteModel] = []
    @Published var isLoading = false
    
    func fetchWebsites() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getWebsites") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.websites = dictArray.compactMap { dict in
                        guard let primaryDomain = dict["primaryDomain"] as? String,
                              let status = dict["status"] as? String,
                              let remark = dict["remark"] as? String else {
                            return nil
                        }
                        let originalId = dict["id"] as? String ?? ""
                        return WebsiteModel(originalId: originalId, primaryDomain: primaryDomain, status: status, remark: remark)
                    }
                }
            }
        }
    }
    
    func toggleWebsiteStatus(id: String, currentStatus: String) async {
        let action = currentStatus.lowercased() == "running" ? "stopWebsite" : "startWebsite"
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync(action, arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchWebsites()
            }
        } catch {
            print("Failed to toggle website status: \(error)")
        }
    }
    
    func deleteWebsite(id: String) async {
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync("deleteWebsite", arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchWebsites()
            }
        } catch {
            print("Failed to delete website: \(error)")
        }
    }
}
