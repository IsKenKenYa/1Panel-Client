import Foundation

struct CronJobModel: Identifiable {
    let id = UUID()
    let name: String
    let schedule: String
    let status: String
}

class CronJobsViewModel: ObservableObject {
    @Published var cronJobs: [CronJobModel] = []
    @Published var isLoading = false
    
    func fetchCronJobs() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getCronJobs") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.cronJobs = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let schedule = dict["schedule"] as? String,
                              let status = dict["status"] as? String else {
                            return nil
                        }
                        return CronJobModel(name: name, schedule: schedule, status: status)
                    }
                }
            }
        }
    }
}
