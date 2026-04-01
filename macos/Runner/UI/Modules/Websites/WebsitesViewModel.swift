import Foundation

struct WebsiteModel: Identifiable {
    let id = UUID()
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
                        return WebsiteModel(primaryDomain: primaryDomain, status: status, remark: remark)
                    }
                }
            }
        }
    }
}
