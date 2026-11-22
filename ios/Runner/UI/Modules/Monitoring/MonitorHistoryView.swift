import AppleSharedUI
import SwiftUI

struct MonitorPoint: Identifiable {
    let timeMillis: Int
    let value: Double

    var id: Int { timeMillis }
}

struct MonitorSeries {
    let points: [MonitorPoint]
    let min: Double
    let max: Double
    let avg: Double

    static let empty = MonitorSeries(points: [], min: 0, max: 0, avg: 0)

    init(payload: [String: Any]) {
        points = (payload["points"] as? [[String: Any]] ?? []).map { item in
            MonitorPoint(
                timeMillis: (item["time"] as? NSNumber)?.intValue
                    ?? (item["time"] as? Int) ?? 0,
                value: (item["value"] as? NSNumber)?.doubleValue ?? 0
            )
        }
        min = (payload["min"] as? NSNumber)?.doubleValue ?? 0
        max = (payload["max"] as? NSNumber)?.doubleValue ?? 0
        avg = (payload["avg"] as? NSNumber)?.doubleValue ?? 0
    }

    private init(points: [MonitorPoint], min: Double, max: Double, avg: Double) {
        self.points = points
        self.min = min
        self.max = max
        self.avg = avg
    }
}

struct MonitorHistory {
    let cpu: MonitorSeries
    let memory: MonitorSeries
    let load: MonitorSeries

    init(payload: [String: Any]) {
        cpu = MonitorSeries(payload: payload["cpu"] as? [String: Any] ?? [:])
        memory = MonitorSeries(payload: payload["memory"] as? [String: Any] ?? [:])
        load = MonitorSeries(payload: payload["load"] as? [String: Any] ?? [:])
    }
}

struct MonitorSettingsModel {
    let enabled: Bool
    let interval: Int
    let retention: Int
    let defaultNetwork: String
    let defaultIO: String

    init(payload: [String: Any]) {
        enabled = payload["enabled"] as? Bool ?? false
        interval = payload["interval"] as? Int ?? 0
        retention = payload["retention"] as? Int ?? 0
        defaultNetwork = payload["defaultNetwork"] as? String ?? ""
        defaultIO = payload["defaultIO"] as? String ?? ""
    }
}

@MainActor
final class MonitorHistoryViewModel: ObservableObject {
    @Published var history = MonitorHistory(payload: [:])
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch(hours: Int) async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getMonitoringHistory",
                arguments: ["hours": hours]
            )
            history = MonitorHistory(payload: raw as? [String: Any] ?? [:])
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// 历史曲线分区：CPU、内存与负载三条折线。
struct MonitorHistorySection: View {
    @EnvironmentObject private var translations: TranslationsManager
    let history: MonitorHistory
    let isLoading: Bool

    var body: some View {
        Section(translations.get("monitorHistoryTitle", fallback: "History")) {
            if isLoading && history.cpu.points.isEmpty {
                ProgressView().controlSize(.small)
            } else if history.cpu.points.isEmpty {
                Text(translations.get("monitorHistoryEmpty", fallback: "No history samples"))
                    .foregroundStyle(.secondary)
            } else {
                MonitorChartRow(
                    title: translations.get("dashboardCpuUsage", fallback: "CPU"),
                    series: history.cpu,
                    unit: "%",
                    upperBound: 100,
                    color: .blue
                )
                MonitorChartRow(
                    title: translations.get("dashboardMemoryUsage", fallback: "Memory"),
                    series: history.memory,
                    unit: "%",
                    upperBound: 100,
                    color: .purple
                )
                MonitorChartRow(
                    title: translations.get("monitorLoadAverageTitle", fallback: "Load Average"),
                    series: history.load,
                    unit: "",
                    upperBound: nil,
                    color: .orange
                )
            }
        }
    }
}

struct MonitorChartRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let title: String
    let series: MonitorSeries
    let unit: String
    let upperBound: Double?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.1f%@", series.points.last?.value ?? 0, unit))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            MonitorSparkline(
                values: series.points.map(\.value),
                upperBound: upperBound,
                color: color
            )
            .frame(height: 64)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title) \(series.points.last?.value ?? 0)\(unit)")
            HStack {
                Text("\(translations.get("monitorHistoryMinLabel", fallback: "Min")) \(String(format: "%.1f", series.min))")
                Text("\(translations.get("monitorHistoryAvgLabel", fallback: "Avg")) \(String(format: "%.1f", series.avg))")
                Text("\(translations.get("monitorHistoryMaxLabel", fallback: "Max")) \(String(format: "%.1f", series.max))")
                Spacer()
                Text("\(series.points.count)")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}

struct MonitorSparkline: View {
    let values: [Double]
    let upperBound: Double?
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else {
                var dot = Path()
                let midY = size.height / 2
                dot.addEllipse(in: CGRect(x: 0, y: midY - 2, width: 4, height: 4))
                context.fill(dot, with: .color(color))
                return
            }
            let scale = upperBound ?? max(values.max() ?? 0, 1)
            var path = Path()
            for (index, value) in values.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
                let ratio = min(max(value / scale, 0), 1)
                let y = size.height * (1 - CGFloat(ratio))
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(path, with: .color(color), lineWidth: 1.5)
        }
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// 监控设置表单：启用开关、采样间隔、保留天数、默认网卡与磁盘、清理数据。
struct MonitoringSettingsSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    @State private var enabled = true
    @State private var interval = "30"
    @State private var retention = "7"
    @State private var defaultNetwork = ""
    @State private var defaultIO = ""
    @State private var networks: [String] = []
    @State private var ios: [String] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showCleanConfirm = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(translations.get("monitorSettingEnabledLabel", fallback: "Enable monitoring"),
                           isOn: $enabled)
                    TextField(translations.get("monitorSettingIntervalLabel",
                                               fallback: "Interval (seconds)"),
                              text: $interval)
                    TextField(translations.get("monitorSettingRetentionLabel",
                                               fallback: "Retention (days)"),
                              text: $retention)
                }
                Section(translations.get("monitorSettingDefaultsTitle", fallback: "Defaults")) {
                    Picker(translations.get("monitorSettingNetworkLabel", fallback: "Network"),
                           selection: $defaultNetwork) {
                        Text(translations.get("monitorSettingNone", fallback: "None")).tag("")
                        ForEach(networks, id: \.self) { network in
                            Text(network).tag(network)
                        }
                    }
                    Picker(translations.get("monitorSettingIOLabel", fallback: "Disk"),
                           selection: $defaultIO) {
                        Text(translations.get("monitorSettingNone", fallback: "None")).tag("")
                        ForEach(ios, id: \.self) { io in
                            Text(io).tag(io)
                        }
                    }
                }
                Section {
                    Button(role: .destructive) {
                        showCleanConfirm = true
                    } label: {
                        Label(translations.get("monitorSettingCleanAction",
                                               fallback: "Clean history data"),
                              systemImage: "trash")
                    }
                }
                if isLoading {
                    Section {
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .navigationTitle(translations.get("monitorSettingTitle", fallback: "Monitoring Settings"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await save() }
                    }
                    .disabled(isLoading || isSaving || !valid)
                }
            }
            .confirmationDialog(
                translations.get("monitorSettingCleanConfirmTitle",
                                fallback: "Clean monitoring data?"),
                isPresented: $showCleanConfirm,
                titleVisibility: .visible
            ) {
                Button(translations.get("monitorSettingCleanAction",
                                        fallback: "Clean history data"),
                       role: .destructive) {
                    Task { await clean() }
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
            } message: {
                Text(translations.get("monitorSettingCleanConfirmMessage",
                                      fallback: "Historical monitoring samples will be removed."))
            }
            .alert(
                translations.get("commonError", fallback: "Error"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .overlay(alignment: .bottom) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                        .padding(20)
                }
            }
            .task {
                await load()
            }
        }
    }

    private var valid: Bool {
        (Int(interval.trimmingCharacters(in: .whitespaces)) ?? 0) > 0
            && (Int(retention.trimmingCharacters(in: .whitespaces)) ?? 0) > 0
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getMonitoringSettings"
            )
            let settings = MonitorSettingsModel(payload: raw as? [String: Any] ?? [:])
            enabled = settings.enabled
            interval = settings.interval > 0 ? "\(settings.interval)" : "30"
            retention = settings.retention > 0 ? "\(settings.retention)" : "7"
            defaultNetwork = settings.defaultNetwork
            defaultIO = settings.defaultIO
            let optionsRaw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getMonitoringOptions"
            )
            let options = optionsRaw as? [String: Any] ?? [:]
            networks = options["networks"] as? [String] ?? []
            ios = options["ios"] as? [String] ?? []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateMonitoringSettings",
                arguments: [
                    "enabled": enabled,
                    "interval": Int(interval.trimmingCharacters(in: .whitespaces)) ?? 30,
                    "retention": Int(retention.trimmingCharacters(in: .whitespaces)) ?? 7,
                    "defaultNetwork": defaultNetwork,
                    "defaultIO": defaultIO,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                showStatus(translations.get("commonSaveSuccess", fallback: "Saved"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonSaveFailed", fallback: "Save failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func clean() async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "cleanMonitoringData"
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                showStatus(translations.get("monitorSettingCleaned",
                                             fallback: "Monitoring data cleaned"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if statusMessage == text {
                statusMessage = nil
            }
        }
    }
}