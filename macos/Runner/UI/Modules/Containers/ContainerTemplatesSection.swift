import AppleSharedUI
import SwiftUI

struct ContainerTemplateRow: Identifiable {
    let id: Int
    let name: String
    let description: String
    let content: String
}

/// macOS 编排模版分区：列表、内容查看、新建与删除。
struct ContainerTemplatesSectionView: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var templates: [ContainerTemplateRow] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var actionError: String?
    @State private var statusMessage: String?
    @State private var pendingDelete: ContainerTemplateRow?
    @State private var selectedTemplate: ContainerTemplateRow?
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if isLoading && templates.isEmpty {
                LoadingView()
            } else if let loadError, templates.isEmpty {
                ErrorView(message: loadError) {
                    Task { await fetch() }
                }
            } else if templates.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: t("commonEmpty", "No data")
                )
            } else {
                List {
                    ForEach(templates) { template in
                        row(template)
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await fetch()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 10)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    Task { await fetch() }
                } label: {
                    Label(t("commonRefresh", "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
                Button {
                    showCreateSheet = true
                } label: {
                    Label(t("commonAdd", "Add"), systemImage: "plus")
                }
            }
        }
        .confirmationDialog(
            t("deleteConfirmTitle", "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(t("commonDelete", "Delete"), role: .destructive) {
                deleteTemplate()
            }
            Button(t("commonCancel", "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            ContainerTemplateCreateSheet {
                Task { await fetch() }
            }
            .environmentObject(translations)
        }
        .sheet(item: $selectedTemplate) { template in
            ContainerTemplateContentSheet(template: template)
                .environmentObject(translations)
        }
        .alert(
            t("commonError", "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(t("commonOk", "OK"), role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
        .task {
            await fetch()
        }
    }

    private func row(_ template: ContainerTemplateRow) -> some View {
        Button {
            selectedTemplate = template
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline.weight(.medium))
                    if !template.description.isEmpty {
                        Text(template.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                selectedTemplate = template
            } label: {
                Label(t("containerTemplateViewContent", "View Content"),
                      systemImage: "doc.text.magnifyingglass")
            }
            Button(role: .destructive) {
                pendingDelete = template
            } label: {
                Label(t("commonDelete", "Delete"), systemImage: "trash")
            }
        }
    }

    private func fetch() async {
        isLoading = true
        loadError = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getContainerTemplates"
            )
            templates = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let id = item["id"] as? Int else { return nil }
                return ContainerTemplateRow(
                    id: id,
                    name: item["name"] as? String ?? "",
                    description: item["description"] as? String ?? "",
                    content: item["content"] as? String ?? ""
                )
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteTemplate() {
        guard let template = pendingDelete else { return }
        pendingDelete = nil
        Task {
            do {
                let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                    "deleteContainerTemplate",
                    arguments: ["id": template.id]
                )
                let payload = raw as? [String: Any] ?? [:]
                if payload["success"] as? Bool == true {
                    showStatus(t("commonDeleted", "Deleted"))
                    await fetch()
                } else {
                    actionError = payload["error"] as? String
                        ?? t("commonDeleteFailed", "Delete failed")
                }
            } catch {
                actionError = error.localizedDescription
            }
        }
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if statusMessage == text { statusMessage = nil }
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}

/// 模版内容查看。
struct ContainerTemplateContentSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let template: ContainerTemplateRow

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(template.name)
                    .font(.headline)
                Spacer()
                Button(t("commonClose", "Close")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            Divider()
            ScrollView {
                Text(verbatim: template.content)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
        }
        .frame(width: 640, height: 520)
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}

/// 新建编排模版。
struct ContainerTemplateCreateSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCompleted: () -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var content = "services:\n"
    @State private var submitting = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(t("commonName", "Name"), text: $name)
                    TextField(t("commonDescription", "Description"),
                              text: $description)
                }
                Section {
                    TextEditor(text: $content)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(minHeight: 240)
                } header: {
                    Text(t("containerTemplateContentHint", "YAML content"))
                }
                if let errorText {
                    Section {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                if submitting {
                    ProgressView().controlSize(.small)
                }
                Spacer()
                Button(t("commonCancel", "Cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(t("commonSave", "Save")) {
                    Task { await submit() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                          || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || submitting)
            }
            .padding(16)
        }
        .frame(width: 620, height: 560)
    }

    private func submit() async {
        submitting = true
        errorText = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "createContainerTemplate",
                arguments: [
                    "name": name.trimmingCharacters(in: .whitespaces),
                    "description": description,
                    "content": content,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onCompleted()
                dismiss()
            } else {
                errorText = payload["error"] as? String
                    ?? t("commonSaveFailed", "Save failed")
            }
        } catch {
            errorText = error.localizedDescription
        }
        submitting = false
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}