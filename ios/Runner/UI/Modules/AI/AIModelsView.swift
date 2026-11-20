import SwiftUI
import AppleSharedUI

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

    /// 拉取模型（createAIModel 通道）。参数：`{name: String}`。
    func create(name: String, completion: @escaping (Bool, String?) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "createAIModel",
            arguments: ["name": name]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                completion(dict?["success"] as? Bool ?? false, dict?["error"] as? String)
            }
        }
    }

    /// 重建模型（recreateAIModel 通道）。参数：`{name: String}`。
    func recreate(name: String, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "recreateAIModel",
            arguments: ["name": name]
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
    @State private var showCreateSheet = false
    @State private var newModelName = ""
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
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                recreate(model)
                            } label: {
                                Label(translations.get("commonRestart", fallback: "Restart"),
                                      systemImage: "arrow.clockwise")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetch()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label(translations.get("aiModelCreate", fallback: "Create Model"), systemImage: "plus")
                }
                Button {
                    viewModel.fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            createSheet
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

    private func recreate(_ model: AIModelRow) {
        viewModel.recreate(name: model.name) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetch()
        }
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("aiModelName", fallback: "Model Name"),
                              text: $newModelName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text(translations.get("aiModelName", fallback: "Model Name") + ": llama3, qwen2.5 ...")
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("aiModelCreate", fallback: "Create Model"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("aiModelCreate", fallback: "Create Model")) {
                        let name = newModelName.trimmingCharacters(in: .whitespaces)
                        viewModel.create(name: name) { success, error in
                            if success {
                                showCreateSheet = false
                                newModelName = ""
                                viewModel.fetch()
                                showToast(translations.get("commonSaveSuccess", fallback: "Saved"))
                            } else {
                                let template = translations.get("appOperateFailed", fallback: "Operation failed: {error}")
                                showToast(template.replacingOccurrences(of: "{error}", with: error ?? ""))
                            }
                        }
                    }
                    .disabled(newModelName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
