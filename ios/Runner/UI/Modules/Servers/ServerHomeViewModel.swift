import Foundation

/// 服务器首页指标模型（来自 getDashboard 通道）。
struct ServerDashboardMetrics {
    var cpu: Double = 0
    var memory: Double = 0
    var disk: Double = 0
    var uptime: String = ""
    var hostname: String = ""
    var osInfo: String = ""
    var kernelVersion: String = ""
    var cpuCores: Int = 0
    var panelVersion: String = ""
}

class ServerHomeViewModel: ObservableObject {
    @Published var metrics = ServerDashboardMetrics()
    @Published var isLoading = false

    func fetchDashboard() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getDashboard", arguments: nil) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dict = result as? [String: Any] else { return }
                var m = ServerDashboardMetrics()
                m.cpu = dict["cpu"] as? Double ?? 0
                m.memory = dict["memory"] as? Double ?? 0
                m.disk = dict["disk"] as? Double ?? 0
                m.uptime = dict["uptime"] as? String ?? ""
                m.hostname = dict["hostname"] as? String ?? ""
                m.osInfo = dict["os"] as? String ?? ""
                m.kernelVersion = dict["kernelVersion"] as? String ?? ""
                m.cpuCores = dict["cpuCores"] as? Int ?? 0
                m.panelVersion = dict["panelVersion"] as? String ?? ""
                self?.metrics = m
            }
        }
    }

    /// 切换当前服务器（connectServer 通道），首页指标随当前服务器上下文加载。
    func connectServer(id: String) {
        ChannelManager.shared.invokeDataMethod("connectServer", arguments: ["id": id]) { _ in }
    }
}
