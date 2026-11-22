import SwiftUI
import AppleSharedUI

/// 健康检查结果：汇总与逐项结果。
struct VMHealthSheet: View {
    let instanceName: String
    @ObservedObject var viewModel: VirtualMachinesViewModel
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    @State private var health: VMHealthModel?
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        Group {
            if isLoading && health == nil {
                LoadingView()
            } else if let health {
                List {
                    Section {
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
                        }
                        Text(summary(health))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Section(translations.get("vmHealthCheckTitle", fallback: "Health Check")) {
                        ForEach(health.items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.check)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(item.level)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(levelColor(item.level))
                                }
                                if !item.reason.isEmpty {
                                    Text(item.reason)
                                        .font(.caption)
                                }
                                if let detail = optional(item.detail) {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let fix = optional(item.fixCommand) {
                                    Text(fix)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await reload()
                }
            } else {
                ErrorView(
                    message: loadError ?? translations.get("commonLoadFailedTitle", fallback: "Failed to load")
                ) {
                    Task { await reload() }
                }
            }
        }
        .navigationTitle(translations.get("vmHealthCheckTitle", fallback: "Health Check"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(translations.get("commonClose", fallback: "Close")) {
                    dismiss()
                }
            }
        }
        .task {
            await reload()
        }
    }

    private func reload() async {
        isLoading = true
        do {
            health = try await viewModel.fetchHealth(name: instanceName)
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

    private func optional(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}