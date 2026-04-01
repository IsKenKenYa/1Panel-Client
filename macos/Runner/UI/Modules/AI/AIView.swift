import SwiftUI

struct AIView: View {
    @StateObject private var viewModel = AIViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.models.isEmpty {
                Text("No AI models found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.models) {
                    TableColumn(translations.get("ai_model_name", fallback: "Model")) { model in
                        HStack {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(.purple)
                            Text(model.name)
                        }
                        .contextMenu {
                            let isReady = model.status.lowercased() == "ready" || model.status.lowercased() == "running"
                            Button(action: {
                                Task {
                                    await viewModel.toggleModelStatus(id: model.originalId, currentStatus: model.status)
                                }
                            }) {
                                Text(isReady ? translations.get("stop", fallback: "Stop") : translations.get("start", fallback: "Start"))
                                Image(systemName: isReady ? "stop.fill" : "play.fill")
                            }
                        }
                    }
                    TableColumn(translations.get("ai_model_description", fallback: "Description")) { model in
                        Text(model.description)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("app_status", fallback: "Status")) { model in
                        let isReady = model.status.lowercased() == "ready" || model.status.lowercased() == "running"
                        Text(model.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isReady ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                            .foregroundColor(isReady ? .green : .orange)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
            }
        }
        .navigationTitle(translations.get("navAi", fallback: "AI"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchModels()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchModels()
        }
    }
}