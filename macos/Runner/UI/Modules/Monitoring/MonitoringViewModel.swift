import Foundation

struct MonitoringModel {
    var cpu: Int = 0
    var memory: Int = 0
    var disk: Int = 0
    var load1: Double = 0.0
    var load5: Double = 0.0
    var load15: Double = 0.0
}

class MonitoringViewModel: ObservableObject {
    @Published var metrics = MonitoringModel()
    @Published var isLoading = false
    
    func fetchMonitoring() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getMonitoring") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dict = result as? [String: Any] {
                    self?.metrics.cpu = dict["cpu"] as? Int ?? 0
                    self?.metrics.memory = dict["memory"] as? Int ?? 0
                    self?.metrics.disk = dict["disk"] as? Int ?? 0
                    
                    if let l1 = dict["load1"] as? Double { self?.metrics.load1 = l1 }
                    else if let l1 = dict["load1"] as? Int { self?.metrics.load1 = Double(l1) }
                    
                    if let l5 = dict["load5"] as? Double { self?.metrics.load5 = l5 }
                    else if let l5 = dict["load5"] as? Int { self?.metrics.load5 = Double(l5) }
                    
                    if let l15 = dict["load15"] as? Double { self?.metrics.load15 = l15 }
                    else if let l15 = dict["load15"] as? Int { self?.metrics.load15 = Double(l15) }
                }
            }
        }
    }
}
