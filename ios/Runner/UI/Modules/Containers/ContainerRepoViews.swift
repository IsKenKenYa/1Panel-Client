import SwiftUI
import AppleSharedUI

struct ContainerRepoRow: Identifiable {
    let id: Int
    let name: String
    let downloadUrl: String
    let username: String
    let status: String
}

/// 镜像仓库：列表、新建与删除。
struct ContainerReposView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var repos: [ContainerRepoRow] = []
    @State private var isLoading = false
    @State private var pendingDelete: ContainerRepoRow?
    @State private var showCreateSheet = false
    @State private var newName = ""
    @State private var newUrl = ""
    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && repos.isEmpty {
                LoadingView()
            } else if repos.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    message: translations.get("containerReposEmpty", fallback: "No repositories")
                )
            } else {
                List {
                    ForEach(repos) { repo in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(repo.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                if !repo.status.isEmpty {
                                    StatusBadge(
                                        text: repo.status,
                                        color: StatusPalette.cronjobStatus(repo.status)
                                    )
                                }
                            }
                            Label(repo.downloadUrl, systemImage: "link")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            if !repo.username.isEmpty {
                                Label(repo.username, systemImage: "person")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = repo
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newName = ""
                    newUrl = ""
                    newUsername = ""
                    newPassword = ""
                    showCreateSheet = true
                } label: {
                    Label(translations.get("containerCreateRepo", fallback: "Create Repository"),
                          systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            createSheet
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteRepo()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        }
        .operationNotice(toastText)
        .onAppear {
            if repos.isEmpty {
                fetch()
            }
        }
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $newName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("containerRepoUrlExample",
                                               fallback: "e.g. https://github.com/user/repo"),
                              text: $newUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField(translations.get("commonUsername", fallback: "Username"),
                              text: $newUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField(translations.get("commonPassword", fallback: "Password"),
                                text: $newPassword)
                }
            }
            .navigationTitle(translations.get("containerCreateRepo", fallback: "Create Repository"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        createRepo()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty
                              || newUrl.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getContainerRepos") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                repos = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return ContainerRepoRow(
                        id: id,
                        name: item["name"] as? String ?? "",
                        downloadUrl: item["downloadUrl"] as? String ?? "",
                        username: item["username"] as? String ?? "",
                        status: item["status"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func createRepo() {
        ChannelManager.shared.invokeDataMethod(
            "createContainerRepo",
            arguments: [
                "name": newName.trimmingCharacters(in: .whitespaces),
                "downloadUrl": newUrl.trimmingCharacters(in: .whitespaces),
                "username": newUsername,
                "password": newPassword,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showCreateSheet = false
                showToast(success
                    ? translations.get("commonCreateSuccess", fallback: "Created")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                if success { fetch() }
            }
        }
    }

    private func deleteRepo() {
        guard let repo = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteContainerRepo",
            arguments: ["id": repo.id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                fetch()
            }
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

struct ContainerTemplateRow: Identifiable {
    let id: Int
    let name: String
    let description: String
    let content: String
}

/// 编排模版：列表、新建、内容查看与删除。
struct ContainerTemplatesView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var templates: [ContainerTemplateRow] = []
    @State private var isLoading = false
    @State private var pendingDelete: ContainerTemplateRow?
    @State private var showCreateSheet = false
    @State private var selectedTemplate: ContainerTemplateRow?
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var newContent = "services:\n"
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && templates.isEmpty {
                LoadingView()
            } else if templates.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                List {
                    ForEach(templates) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(template.name)
                                    .font(.subheadline.weight(.medium))
                                if !template.description.isEmpty {
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = template
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newName = ""
                    newDescription = ""
                    newContent = "services:\n"
                    showCreateSheet = true
                } label: {
                    Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            createSheet
        }
        .sheet(item: $selectedTemplate) { template in
            NavigationStack {
                ScrollView {
                    Text(template.content)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle(template.name)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteTemplate()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        }
        .operationNotice(toastText)
        .onAppear {
            if templates.isEmpty {
                fetch()
            }
        }
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $newName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("commonDescription", fallback: "Description"),
                              text: $newDescription)
                    TextEditor(text: $newContent)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(minHeight: 200)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text(translations.get("containerTemplateContentHint", fallback: "YAML content"))
                }
            }
            .navigationTitle(translations.get("containerTemplateCreateTitle",
                                              fallback: "New Template"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        createTemplate()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty
                              || newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getContainerTemplates") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                templates = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return ContainerTemplateRow(
                        id: id,
                        name: item["name"] as? String ?? "",
                        description: item["description"] as? String ?? "",
                        content: item["content"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func createTemplate() {
        ChannelManager.shared.invokeDataMethod(
            "createContainerTemplate",
            arguments: [
                "name": newName.trimmingCharacters(in: .whitespaces),
                "description": newDescription,
                "content": newContent,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showCreateSheet = false
                showToast(success
                    ? translations.get("commonCreateSuccess", fallback: "Created")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                if success { fetch() }
            }
        }
    }

    private func deleteTemplate() {
        guard let template = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteContainerTemplate",
            arguments: ["id": template.id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                fetch()
            }
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