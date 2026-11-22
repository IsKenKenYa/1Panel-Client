import AppleSharedUI
import SwiftUI

/// macOS 实时监控：每 5 秒采样一次，绘制 CPU、内存、磁盘与网络曲线。
struct VMInstanceMonitorView: View {
    let instanceName: String
    @ObservedObject var store: VirtualMachineStore
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(translations.get("vmMonitorTitle", fallback: "Monitor"))
                    .font(.headline)
                Text(instanceName)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(translations.get("commonClose", fallback: "Close")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }

            if let stoppedMessage {
                Text(stoppedMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if latest == nil && cpuSamples.isEmpty {
                Text(translations.get("vmMonitorWaitingSamples", fallback: "Waiting for the first sample"))
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VMMonitorChartRow(
                        title: translations.get("vmMonitorCpuChart", fallback: "CPU"),
                        current: latest.map { String(format: "%.1f%%", $0.cpuPercent) } ?? "--",
                        samples: cpuSamples,
                        upperBound: 100,
                        color: .blue
                    )
                    VMMonitorChartRow(
                        title: translations.get("vmMonitorMemoryChart", fallback: "Memory"),
                        current: latest.map { String(format: "%.1f%%", $0.memoryPercent) } ?? "--",
                        samples: memorySamples,
                        upperBound: 100,
                        color: .purple
                    )
                    VMMonitorChartRow(
                        title: translations.get("vmMonitorDiskChart", fallback: "Disk I/O"),
                        current: latest.map { VMFormatting.rate($0.diskBytesPerSecond) } ?? "--",
                        samples: diskSamples,
                        upperBound: nil,
                        color: .orange
                    )
                    VMMonitorChartRow(
                        title: translations.get("vmMonitorNetworkChart", fallback: "Network"),
                        current: latest.map { VMFormatting.rate($0.networkBytesPerSecond) } ?? "--",
                        samples: networkSamples,
                        upperBound: nil,
                        color: .green
                    )
                }
            }
        }
        .padding(20)
        .frame(width: 680, height: 500)
        .task {
            await poll()
        }
    }

    private func poll() async {
        while !Task.isCancelled {
            do {
                let sample = try await store.fetchStats(name: instanceName)
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

struct VMMonitorChartRow: View {
    let title: String
    let current: String
    let samples: [Double]
    let upperBound: Double?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text(current)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            VMMonitorSparkline(samples: samples, upperBound: upperBound, color: color)
                .frame(height: 64)
                .accessibilityLabel("\(title) \(current)")
                .accessibilityElement(children: .ignore)
        }
    }
}

struct VMMonitorSparkline: View {
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