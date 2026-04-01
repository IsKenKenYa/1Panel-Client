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
                            Button(action: {
                                Task {
                                    await viewModel.deleteModel(id: model.originalId)
                                }
                            }) {
                                Text(translations.get("delete", fallback: "Delete"))
                                Image(systemName: "trash")
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
