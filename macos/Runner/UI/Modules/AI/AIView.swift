import SwiftUI

struct AIView: View {
    @StateObject private var viewModel = AIViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var modelToDelete: AIModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.models.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No AI models found")
                        .foregroundColor(.secondary)
                    Text("Use 1Panel to pull Ollama models")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.models) {
                    TableColumn(translations.get("ai_model_name", fallback: "Model")) { model in
                        HStack {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(.purple)
                            Text(model.name)
                                .fontWeight(.medium)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                modelToDelete = model
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("delete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("ai_model_size", fallback: "Size")) { model in
                        Text(model.size.isEmpty ? "--" : model.size)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("ai_model_modified", fallback: "Modified")) { model in
                        Text(model.modified.isEmpty ? "--" : model.modified)
                            .foregroundColor(.secondary)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(translations.get("serverModuleAi", fallback: "AI"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchModels() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
        }
        .confirmationDialog(
            "Delete model \"\(modelToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let m = modelToDelete { Task { await viewModel.deleteModel(id: m.originalId) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The model weights will be permanently deleted.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchModels() }
    }
}
