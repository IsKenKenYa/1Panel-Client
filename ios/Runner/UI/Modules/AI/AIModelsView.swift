import SwiftUI

struct AIModelRow: Identifiable {
    let id: Int
    let name: String
    let size: String
    let modified: String
}

class AIModelsViewModel: ObservableObject {
    @Published var models: [AIModelRow] = []
    @Published var isLoading = false

    func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getAIModels") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                self?.models = items.compactMap { item in
                    guard let id = item["id"] as? Int,
                          let name = item["name"] as? String else { return nil }
                    return AIModelRow(
                        id: id,
                        name: name,
                        size: item["size"] as? String ?? "",
                        modified: item["modified"] as? String ?? ""
                    )
                }
            }
        }
    }

    func delete(id: Int, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "deleteAIModel",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
            }
        }
    }
}

/// AI 模型列表：Ollama 模型的名称、大小与更新时间，支持删除。
struct AIModelsView: View {
    @StateObject private var viewModel = AIModelsViewModel()
    @EnvironmentObject var translations: TranslationsManager

    @State private var pendingDelete: AIModelRow?
    @State private var showDeleteConfirm = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.models.isEmpty {
                LoadingView()
            } else if viewModel.models.isEmpty {
                EmptyStateView(
                    icon: "brain",
                    message: translations.get("aiModelsEmptyTitle", fallback: "No models"),
                    description: translations.get("aiModelsEmptyHint",
                                                  fallback: "Models added in 1Panel appear here.")
                )
            } else {
                List {
                    ForEach(viewModel.models) { model in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(model.name)
                                .font(.headline)
                            HStack(spacing: 12) {
                                if !model.size.isEmpty {
                                    Label(model.size, systemImage: "internaldrive")
                                }
                                if !model.modified.isEmpty {
                                    Label(model.modified, systemImage: "clock")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = model
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetch()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleAi", fallback: "AI"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .ai)
                Button {
                    viewModel.fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                guard let model = pendingDelete else { return }
                pendingDelete = nil
                viewModel.delete(id: model.id) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                    viewModel.fetch()
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            viewModel.fetch()
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}
