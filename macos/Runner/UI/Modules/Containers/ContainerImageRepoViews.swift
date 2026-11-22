import AppleSharedUI
import SwiftUI

struct ContainerImageRow: Identifiable {
    let id: String
    let tags: [String]
    let size: Int
    let createdAt: String
    let isUsed: Bool

    var displayName: String {
        if let first = tags.first, !first.isEmpty { return first }
        return id.hasPrefix("sha256:") ? String(id.prefix(19)) : id
    }
}

/// macOS 镜像分区：列表、拉取、构建、推送与删除。
struct ContainerImagesSectionView: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var images: [ContainerImageRow] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var actionError: String?
    @State private var statusMessage: String?
    @State private var pendingDelete: ContainerImageRow?
    @State private var showPullSheet = false
    @State private var showBuildSheet = false
    @State private var pushTarget: ContainerImageRow?

    var body: some View {
        Group {
            if isLoading && images.isEmpty {
                LoadingView()
            } else if let loadError, images.isEmpty {
                ErrorView(message: loadError) {
                    Task { await fetch() }
                }
            } else if images.isEmpty {
                EmptyStateView(
                    icon: "square.stack.3d.down.right",
                    message: t("commonEmpty", "No data")
                )
            } else {
                List {
                    ForEach(images) { image in
                        row(image)
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
                Menu {
                    Button {
                        showPullSheet = true
                    } label: {
                        Label(t("orchestrationPullImage", "Pull Image"),
                              systemImage: "arrow.down.circle")
                    }
                    Button {
                        showBuildSheet = true
                    } label: {
                        Label(t("orchestrationImageBuild", "Build Image"),
                              systemImage: "hammer")
                    }
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
                deleteImage()
            }
            Button(t("commonCancel", "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(t("deleteCannotUndoMessage", "This action cannot be undone."))
        }
        .sheet(isPresented: $showPullSheet) {
            ContainerImagePullSheet {
                Task { await fetch() }
            }
            .environmentObject(translations)
        }
        .sheet(isPresented: $showBuildSheet) {
            ContainerImageBuildSheet {
                Task { await fetch() }
            }
            .environmentObject(translations)
        }
        .sheet(item: $pushTarget) { image in
            ContainerImagePushSheet(imageName: image.displayName) {
                Task { await fetch() }
            }
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

    private func row(_ image: ContainerImageRow) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(image.displayName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if image.isUsed {
                        StatusBadge(text: t("containerImageInUse", "In Use"),
                                    color: .orange)
                    }
                }
                if let second = image.tags.dropFirst().first {
                    Text(second)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 12) {
                    Label(ByteCountFormatter.string(fromByteCount: Int64(image.size),
                                                    countStyle: .file),
                          systemImage: "internaldrive")
                    if !image.createdAt.isEmpty {
                        Label(TimestampFormat.display(image.createdAt),
                              systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button {
                    pushTarget = image
                } label: {
                    Label(t("containerActionPush", "Push"),
                          systemImage: "arrow.up.circle")
                }
                Button(role: .destructive) {
                    pendingDelete = image
                } label: {
                    Label(t("commonDelete", "Delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                pushTarget = image
            } label: {
                Label(t("containerActionPush", "Push"),
                      systemImage: "arrow.up.circle")
            }
            Button(role: .destructive) {
                pendingDelete = image
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
                "getContainerImages"
            )
            images = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let id = item["id"] as? String, !id.isEmpty else { return nil }
                return ContainerImageRow(
                    id: id,
                    tags: (item["tags"] as? [Any] ?? []).map { "\($0)" },
                    size: item["size"] as? Int ?? 0,
                    createdAt: item["createdAt"] as? String ?? "",
                    isUsed: item["isUsed"] as? Bool ?? false
                )
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteImage() {
        guard let image = pendingDelete else { return }
        pendingDelete = nil
        Task {
            do {
                let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                    "deleteContainerImage",
                    arguments: ["id": image.id]
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

/// 拉取镜像。
struct ContainerImagePullSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCompleted: () -> Void

    @State private var imageName = ""
    @State private var tagName = ""
    @State private var submitting = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(t("orchestrationPullImageHint",
                                "Image name (e.g. nginx:latest)"),
                              text: $imageName)
                    TextField(t("orchestrationImageTagHint", "Tag"), text: $tagName)
                } footer: {
                    Text(t("orchestrationPullImageHint",
                           "Image name (e.g. nginx:latest)"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                Button(t("commonConfirm", "Confirm")) {
                    Task { await submit() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(imageName.trimmingCharacters(in: .whitespaces).isEmpty
                          || submitting)
            }
            .padding(16)
        }
        .frame(width: 520, height: 320)
    }

    private func submit() async {
        let reference = imageName.trimmingCharacters(in: .whitespaces)
        guard !reference.isEmpty else { return }
        submitting = true
        errorText = nil
        var image = reference
        var tag = tagName.trimmingCharacters(in: .whitespaces)
        if tag.isEmpty,
           let colon = reference.lastIndex(of: ":"),
           !reference[reference.index(after: colon)...].contains("/") {
            image = String(reference[..<colon])
            tag = String(reference[reference.index(after: colon)...])
        }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "pullContainerImage",
                arguments: ["image": image, "tag": tag]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onCompleted()
                dismiss()
            } else {
                errorText = payload["error"] as? String
                    ?? t("orchestrationPullFailed", "Pull failed")
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

/// 构建镜像。
struct ContainerImageBuildSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCompleted: () -> Void

    @State private var imageName = ""
    @State private var fromMode = "path"
    @State private var dockerfile = ""
    @State private var tagsText = ""
    @State private var argsText = ""
    @State private var submitting = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(t("commonName", "Name"), text: $imageName)
                    Picker("", selection: $fromMode) {
                        Text(t("hostRedirectTypePath", "Path")).tag("path")
                        Text(t("commonEdit", "Edit")).tag("edit")
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(t("containerImageNameHelper", "Image name, e.g. myapp"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section {
                    if fromMode == "path" {
                        TextField(t("containerBuildDockerfile", "Dockerfile path"),
                                  text: $dockerfile)
                    } else {
                        TextEditor(text: $dockerfile)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(minHeight: 180)
                    }
                } header: {
                    Text("Dockerfile")
                }
                Section {
                    TextField(t("containerBuildTags", "Tags"),
                              text: $tagsText, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(t("containerBuildArgs", "Build args"),
                              text: $argsText, axis: .vertical)
                        .lineLimit(2...4)
                } footer: {
                    Text(t("containerBuildTagsHelper", "One value per line"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                Button(t("commonConfirm", "Confirm")) {
                    Task { await submit() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit || submitting)
            }
            .padding(16)
        }
        .frame(width: 560, height: 620)
    }

    private var canSubmit: Bool {
        !imageName.trimmingCharacters(in: .whitespaces).isEmpty
            && !dockerfile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() async {
        guard canSubmit else { return }
        submitting = true
        errorText = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "buildContainerImage",
                arguments: [
                    "name": imageName.trimmingCharacters(in: .whitespaces),
                    "from": fromMode,
                    "dockerfile": dockerfile,
                    "tags": splitLines(tagsText),
                    "args": splitLines(argsText),
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onCompleted()
                dismiss()
            } else {
                errorText = payload["error"] as? String
                    ?? t("commonOperationFailed", "Operation failed")
            }
        } catch {
            errorText = error.localizedDescription
        }
        submitting = false
    }

    private func splitLines(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}

struct ContainerRepoPickRow: Identifiable {
    let id: Int
    let name: String
    let downloadUrl: String
}

/// 推送镜像到仓库。
struct ContainerImagePushSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let imageName: String
    let onCompleted: () -> Void

    @State private var repositories: [ContainerRepoPickRow] = []
    @State private var repository = ""
    @State private var name = ""
    @State private var tagName = "latest"
    @State private var sourceImageBase = ""
    @State private var submitting = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(t("commonName", "Name"), text: $name)
                    TextField(t("containerTagLabel", "Tag"), text: $tagName)
                }
                Section {
                    if repositories.isEmpty {
                        Text(t("containerReposEmpty", "No repositories"))
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(t("containerRepoLabel", "Repository"),
                               selection: $repository) {
                            ForEach(repositories) { repo in
                                Text(repo.name).tag("\(repo.id)")
                            }
                        }
                    }
                } footer: {
                    Text(t("containerActionPushHelper",
                           "The image is pushed to the selected registry."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                Button(t("commonConfirm", "Confirm")) {
                    Task { await submit() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit || submitting)
            }
            .padding(16)
        }
        .frame(width: 520, height: 420)
        .onAppear {
            if let colon = imageName.lastIndex(of: ":"),
               !imageName[imageName.index(after: colon)...].contains("/") {
                name = String(imageName[..<colon])
                tagName = String(imageName[imageName.index(after: colon)...])
            } else {
                name = imageName
            }
            sourceImageBase = name
        }
        .task {
            await fetchRepositories()
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !tagName.trimmingCharacters(in: .whitespaces).isEmpty
            && !repository.isEmpty
    }

    private func fetchRepositories() async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getContainerRepos"
            )
            repositories = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let id = item["id"] as? Int else { return nil }
                return ContainerRepoPickRow(
                    id: id,
                    name: item["name"] as? String ?? "",
                    downloadUrl: item["downloadUrl"] as? String ?? ""
                )
            }
            if repository.isEmpty, let first = repositories.first {
                repository = "\(first.id)"
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        submitting = true
        errorText = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "pushContainerImage",
                arguments: [
                    "image": "\(sourceImageBase):\(tagName.trimmingCharacters(in: .whitespaces))",
                    "name": name.trimmingCharacters(in: .whitespaces),
                    "repository": repository,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onCompleted()
                dismiss()
            } else {
                errorText = payload["error"] as? String
                    ?? t("commonOperationFailed", "Operation failed")
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

struct ContainerRepoRow: Identifiable {
    let id: Int
    let name: String
    let downloadUrl: String
    let username: String
    let status: String
}

/// macOS 仓库分区：列表、新建与删除。
struct ContainerReposSectionView: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var repos: [ContainerRepoRow] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var actionError: String?
    @State private var statusMessage: String?
    @State private var pendingDelete: ContainerRepoRow?
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if isLoading && repos.isEmpty {
                LoadingView()
            } else if let loadError, repos.isEmpty {
                ErrorView(message: loadError) {
                    Task { await fetch() }
                }
            } else if repos.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    message: t("containerReposEmpty", "No repositories")
                )
            } else {
                List {
                    ForEach(repos) { repo in
                        row(repo)
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
                    Label(t("containerCreateRepo", "Create Repository"),
                          systemImage: "plus")
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
                deleteRepo()
            }
            Button(t("commonCancel", "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            ContainerRepoCreateSheet {
                Task { await fetch() }
            }
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

    private func row(_ repo: ContainerRepoRow) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(repo.name)
                        .font(.subheadline.weight(.medium))
                    if !repo.status.isEmpty {
                        StatusBadge(text: repo.status, color: .gray)
                    }
                }
                Label(repo.downloadUrl, systemImage: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !repo.username.isEmpty {
                    Label(repo.username, systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Menu {
                Button(role: .destructive) {
                    pendingDelete = repo
                } label: {
                    Label(t("commonDelete", "Delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(role: .destructive) {
                pendingDelete = repo
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
                "getContainerRepos"
            )
            repos = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let id = item["id"] as? Int else { return nil }
                return ContainerRepoRow(
                    id: id,
                    name: item["name"] as? String ?? "",
                    downloadUrl: item["downloadUrl"] as? String ?? "",
                    username: item["username"] as? String ?? "",
                    status: item["status"] as? String ?? ""
                )
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteRepo() {
        guard let repo = pendingDelete else { return }
        pendingDelete = nil
        Task {
            do {
                let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                    "deleteContainerRepo",
                    arguments: ["id": repo.id]
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

/// 新建镜像仓库。
struct ContainerRepoCreateSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCompleted: () -> Void

    @State private var name = ""
    @State private var downloadUrl = ""
    @State private var username = ""
    @State private var password = ""
    @State private var submitting = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(t("commonName", "Name"), text: $name)
                    TextField(t("containerRepoUrlExample",
                                "e.g. https://github.com/user/repo"),
                              text: $downloadUrl)
                    TextField(t("commonUsername", "Username"), text: $username)
                    SecureField(t("commonPassword", "Password"), text: $password)
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
                          || downloadUrl.trimmingCharacters(in: .whitespaces).isEmpty
                          || submitting)
            }
            .padding(16)
        }
        .frame(width: 520, height: 380)
    }

    private func submit() async {
        submitting = true
        errorText = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "createContainerRepo",
                arguments: [
                    "name": name.trimmingCharacters(in: .whitespaces),
                    "downloadUrl": downloadUrl.trimmingCharacters(in: .whitespaces),
                    "username": username,
                    "password": password,
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