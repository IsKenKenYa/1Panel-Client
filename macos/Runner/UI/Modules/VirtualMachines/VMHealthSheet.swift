import AppleSharedUI
import SwiftUI

/// macOS 健康检查：汇总与逐项结果。
struct VMHealthSheet: View {
    let instanceName: String
    @ObservedObject var store: VirtualMachineStore
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    @State private var health: VMHealthModel?
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(translations.get("vmHealthCheckTitle", fallback: "Health Check"))
                    .font(.headline)
                Text(instanceName)
                    .foregroundStyle(.secondary)
                Spacer()
                if isLoading && health != nil {
                    ProgressView().controlSize(.small)
                }
                Button {
                    Task { await reload() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }

            Group {
                if isLoading && health == nil {
                    LoadingView()
                } else if let health {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: health.fail > 0
                                      ? "exclamationmark.octagon.fill"
                                      : (health.warn > 0 ? "exclamationmark.triangle.fill"
                                                         : "checkmark.circle.fill"))
                                    .foregroundStyle(health.fail > 0
                                                     ? .red
                                                     : (health.warn > 0 ? .orange : .green))
                                Text(health.fail > 0 || health.warn > 0
                                     ? translations.get("vmHealthCheckNeedAttention",
                                                        fallback: "Some checks need attention")
                                     : translations.get("vmHealthCheckAllPassed",
                                                        fallback: "All checks passed"))
                                    .font(.subheadline.weight(.medium))
                            }
                            Text(summary(health))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(health.items) { item in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(item.check).font(.subheadline.weight(.medium))
                                        Spacer()
                                        Text(item.level)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(levelColor(item.level))
                                    }
                                    if !item.reason.isEmpty {
                                        Text(item.reason).font(.caption)
                                    }
                                    if !item.detail.isEmpty {
                                        Text(item.detail)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !item.fixCommand.isEmpty {
                                        Text(item.fixCommand)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ErrorView(
                        message: loadError ?? translations.get("commonLoadFailedTitle",
                                                               fallback: "Failed to load")
                    ) {
                        Task { await reload() }
                    }
                }
            }

            HStack {
                Spacer()
                Button(translations.get("commonClose", fallback: "Close")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 640, height: 480)
        .task {
            await reload()
        }
    }

    private func reload() async {
        isLoading = true
        do {
            health = try await store.fetchHealth(name: instanceName)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func summary(_ health: VMHealthModel) -> String {
        translations.get("vmHealthCheckSummary",
                         fallback: "{pass} passed, {warn} warnings, {fail} failures")
            .replacingOccurrences(of: "{pass}", with: "\(health.pass)")
            .replacingOccurrences(of: "{warn}", with: "\(health.warn)")
            .replacingOccurrences(of: "{fail}", with: "\(health.fail)")
    }

    private func levelColor(_ level: String) -> Color {
        switch level.uppercased() {
        case "PASS": return .green
        case "WARN": return .orange
        case "FAIL": return .red
        default: return .blue
        }
    }
}