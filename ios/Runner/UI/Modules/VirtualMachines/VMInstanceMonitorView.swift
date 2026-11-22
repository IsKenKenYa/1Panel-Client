import SwiftUI
import AppleSharedUI

/// 虚拟机实时监控：每 5 秒采样一次，绘制 CPU、内存、磁盘与网络曲线。
struct VMInstanceMonitorView: View {
    let instanceName: String
    @ObservedObject var viewModel: VirtualMachinesViewModel
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    @State private var cpuSamples: [Double] = []
    @State private var memorySamples: [Double] = []
    @State private var diskSamples: [Double] = []
    @State private var networkSamples: [Double] = []
    @State private var latest: VMStatsSample?
    @State private var stoppedMessage: String?

    private let maxSamples = 50
    private let pollInterval: UInt64 = 5_000_000_000

    var body: some View {
        List {
            if let stoppedMessage {
                Section {
                    Text(stoppedMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            if latest == nil && cpuSamples.isEmpty {
                Section {
                    Text(translations.get("vmMonitorWaitingSamples",
                                          fallback: "Waiting for the first sample"))
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                VMChartRow(
                    title: translations.get("vmMonitorCpuChart", fallback: "CPU"),
                    current: latest.map { String(format: "%.1f%%", $0.cpuPercent) } ?? "--",
                    samples: cpuSamples,
                    upperBound: 100,
                    color: .blue
                )
                VMChartRow(
                    title: translations.get("vmMonitorMemoryChart", fallback: "Memory"),
                    current: latest.map { String(format: "%.1f%%", $0.memoryPercent) } ?? "--",
                    samples: memorySamples,
                    upperBound: 100,
                    color: .purple
                )
                VMChartRow(
                    title: translations.get("vmMonitorDiskChart", fallback: "Disk I/O"),
                    current: latest.map { VMFormatting.rate($0.diskBytesPerSecond) } ?? "--",
                    samples: diskSamples,
                    upperBound: nil,
                    color: .orange
                )
                VMChartRow(
                    title: translations.get("vmMonitorNetworkChart", fallback: "Network"),
                    current: latest.map { VMFormatting.rate($0.networkBytesPerSecond) } ?? "--",
                    samples: networkSamples,
                    upperBound: nil,
                    color: .green
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(translations.get("vmMonitorTitle", fallback: "Monitor") + " · " + instanceName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(translations.get("commonClose", fallback: "Close")) {
                    dismiss()
                }
            }
        }
        .task {
            await poll()
        }
    }

    private func poll() async {
        while !Task.isCancelled {
            do {
                let sample = try await viewModel.fetchStats(name: instanceName)
                latest = sample
                cpuSamples = trimmed(cpuSamples + [sample.cpuPercent])
                memorySamples = trimmed(memorySamples + [sample.memoryPercent])
                diskSamples = trimmed(diskSamples + [sample.diskBytesPerSecond])
                networkSamples = trimmed(networkSamples + [sample.networkBytesPerSecond])
                stoppedMessage = nil
                if !sample.isRunning {
                    stoppedMessage = translations.get("vmMonitorStopped",
                                                      fallback: "The virtual machine is not running")
                    return
                }
            } catch {
                stoppedMessage = error.localizedDescription
                return
            }
            try? await Task.sleep(nanoseconds: pollInterval)
        }
    }

    private func trimmed(_ values: [Double]) -> [Double] {
        values.count > maxSamples ? Array(values.suffix(maxSamples)) : values
    }
}

/// 单条监控曲线：标题、当前值与折线图。
struct VMChartRow: View {
    let title: String
    let current: String
    let samples: [Double]
    let upperBound: Double?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(current)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            VMSparkline(samples: samples, upperBound: upperBound, color: color)
                .frame(height: 64)
                .accessibilityLabel("\(title) \(current)")
                .accessibilityElement(children: .ignore)
        }
        .padding(.vertical, 4)
    }
}

/// 折线图：以采样值绘制路径，未给出上界时按当前窗口最大值归一。
struct VMSparkline: View {
    let samples: [Double]
    let upperBound: Double?
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard samples.count > 1 else {
                var dot = Path()
                let midY = size.height / 2
                dot.addEllipse(in: CGRect(x: 0, y: midY - 2, width: 4, height: 4))
                context.fill(dot, with: .color(color))
                return
            }
            let scale = upperBound ?? max(samples.max() ?? 0, 1)
            var path = Path()
            for (index, value) in samples.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(samples.count - 1)
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