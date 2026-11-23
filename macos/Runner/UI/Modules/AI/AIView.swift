import SwiftUI
import AppleSharedUI

struct AIView: View {
    @StateObject private var viewModel = AIViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var modelToDelete: AIModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.models.isEmpty {
                EmptyStateView(
                    icon: "cpu.fill",
                    message: translations.get("aiModelsEmptyTitle", fallback: "No AI models found")
                )
            } else {
                List {
                    ForEach(viewModel.models) { model in
                        row(model)
                    }
                }
                .listStyle(.inset)
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
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Delete model \"\(modelToDelete?.name ?? "")\"?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let m = modelToDelete { Task { await viewModel.deleteModel(id: m.originalId) } }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "The model weights will be permanently deleted."))
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchModels() }
    }

    private func row(_ model: AIModel) -> some View {
        ModuleRow(
            icon: "cpu.fill",
            iconColor: .purple,
            title: model.name,
            subtitle: [model.size, model.modified]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        ) {
            RowActionsMenu {
                Button(role: .destructive) {
                    modelToDelete = model
                    showDeleteConfirm = true
                } label: {
                    Label(translations.get("commonDelete", fallback: "Delete"),
                          systemImage: "trash")
                }
            }
            .disabled(viewModel.isProcessing)
        }
        .contextMenu {
            Button(role: .destructive) {
                modelToDelete = model
                showDeleteConfirm = true
            } label: {
                Label(translations.get("commonDelete", fallback: "Delete"),
                      systemImage: "trash")
            }
        }
    }
}
