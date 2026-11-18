import CoreFoundation
import Foundation

struct AppModel: Identifiable {
    let installId: Int
    let name: String
    let status: String
    let version: String

    var id: Int { installId }
    var isRunning: Bool { status.lowercased() == "running" }

    private init?(row: [String: Any]) {
        guard let number = row["installId"] as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              !["d", "f"].contains(String(cString: number.objCType)),
              let installId = number as? Int, installId > 0,
              let name = row["name"] as? String, !name.isEmpty,
              let status = row["status"] as? String else { return nil }
        self.installId = installId
        self.name = name
        self.status = status
        version = row["version"] as? String ?? ""
    }

    static func readInstalledApps(_ response: Any?) -> [AppModel]? {
        guard let rows = response as? [[String: Any]] else { return nil }
        var apps: [AppModel] = []
        var ids: Set<Int> = []
        for row in rows {
            guard let app = AppModel(row: row), ids.insert(app.id).inserted else { return nil }
            apps.append(app)
        }
        return apps
    }
}

@MainActor
final class AppsViewModel: ObservableObject {
    @Published private(set) var apps: [AppModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?

    func fetchApps() async {
        guard !isLoading, !isProcessing else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await ChannelManager.shared.invokeDataMethodAsync("getApps")
            guard let apps = AppModel.readInstalledApps(result) else {
                errorMessage = TranslationsManager.shared.get("commonLoadFailedTitle", fallback: "Failed to load")
                return
            }
            self.apps = apps
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleAppStatus(_ app: AppModel) async {
        await performMutation(app.isRunning ? "stopApp" : "startApp", installId: app.installId)
    }

    func uninstallApp(installId: Int) async {
        await performMutation("uninstallApp", installId: installId)
    }

    private func performMutation(_ method: String, installId: Int) async {
        guard !isLoading, !isProcessing else { return }
        isProcessing = true
        errorMessage = nil
        let outcome: NativeMutationOutcome
        do {
            let response = try await ChannelManager.shared.invokeDataMethodAsync(
                method, arguments: ["installId": installId]
            )
            outcome = NativeMutationOutcome(response)
        } catch {
            outcome = .failed(error.localizedDescription)
        }
        isProcessing = false
        switch outcome {
        case .succeeded:
            await fetchApps()
        case let .failed(message):
            errorMessage = message
                ?? TranslationsManager.shared.get("commonOperationFailed", fallback: "Operation failed")
        }
    }
}
