import Foundation

struct WebsiteModel: Identifiable {
    let originalId: String
    let primaryDomain: String
    let status: String
    let remark: String
    
    var id: String { originalId }
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
        // The corresponding Dart-side handler for toggling websites is not implemented yet.
        print("toggleWebsiteStatus is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchWebsites()
        }
    }
    
    func deleteWebsite(id: String) async {
        // The corresponding Dart-side handler for deleting websites is not implemented yet.
        print("deleteWebsite is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchWebsites()
        }
    }
}
