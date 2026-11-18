import SwiftUI

/// 容器详情：信息（inspect JSON）与日志两个分栏，等宽文本只读展示。
struct ContainerDetailView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject var translations: TranslationsManager
    let containerName: String

    @State private var tab = ProcessInfo.processInfo.environment["ONEPANEL_CONTAINER_TAB"] == "logs"
        ? "logs"
        : "info"

    var body: some View {
        VStack(spacing: 0) {
            Picker(translations.get("containerDetailTitle", fallback: "Container details"), selection: $tab) {
                Text(translations.get("containerTabInfo", fallback: "Info")).tag("info")
                Text(translations.get("containerTabLogs", fallback: "Logs")).tag("logs")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if tab == "info" {
                inspectContent
            } else {
                logsContent
            }
        }
        .navigationTitle(containerName)
        .navigationBarTitleDisplayMode(.inline)
        .operationNotice(refreshFailed
            ? translations.get("commonLoadFailedTitle", fallback: "Failed to load")
            : nil)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if tab == "info" {
                        viewModel.fetchInspect(name: containerName)
                    } else {
                        viewModel.fetchLogs(name: containerName)
                    }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoadingInspect || viewModel.isLoadingLogs)
            }
        }
        .onAppear {
            if tab == "logs" {
                viewModel.fetchLogs(name: containerName)
            } else {
                viewModel.fetchInspect(name: containerName)
            }
        }
        .onChange(of: tab) { newValue in
            if newValue == "logs" && viewModel.logs.isEmpty {
                viewModel.fetchLogs(name: containerName)
            }
            if newValue == "info" && viewModel.inspectText.isEmpty {
                viewModel.fetchInspect(name: containerName)
            }
        }
    }

    private var refreshFailed: Bool {
        if tab == "logs" {
            return viewModel.logsFailed && !viewModel.logs.isEmpty
        }
        return viewModel.inspectFailed && !viewModel.inspectText.isEmpty
    }

    @ViewBuilder
    private var inspectContent: some View {
        if viewModel.isLoadingInspect && viewModel.inspectText.isEmpty {
            LoadingView()
        } else if viewModel.inspectFailed && viewModel.inspectText.isEmpty {
            ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                viewModel.fetchInspect(name: containerName)
            }
        } else if viewModel.inspectText.isEmpty {
            EmptyStateView(
                icon: "doc.text.magnifyingglass",
                message: translations.get("commonEmpty", fallback: "No data available")
            )
        } else {
            ScrollView {
                Text(viewModel.inspectText)
                    .font(.system(.caption2, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }

    @ViewBuilder
    private var logsContent: some View {
        if viewModel.isLoadingLogs && viewModel.logs.isEmpty {
            LoadingView()
        } else if viewModel.logsFailed && viewModel.logs.isEmpty {
            ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                viewModel.fetchLogs(name: containerName)
            }
        } else if viewModel.logs.isEmpty {
            EmptyStateView(
                icon: "doc.text",
                message: translations.get("containerLogsEmpty", fallback: "No logs")
            )
        } else {
            ScrollView {
                Text(viewModel.logs)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }
}
