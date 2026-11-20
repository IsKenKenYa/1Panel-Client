import SwiftUI

/// 构建镜像。
struct ContainerBuildSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var imageName = ""
    @State private var fromMode = "path"
    @State private var dockerfile = ""
    @State private var tagsText = ""
    @State private var argsText = ""
    @State private var submitting = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $imageName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("", selection: $fromMode) {
                        Text(translations.get("hostRedirectTypePath", fallback: "Path"))
                            .tag("path")
                        Text(translations.get("commonEdit", fallback: "Edit"))
                            .tag("edit")
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(translations.get("containerImageNameHelper",
                                          fallback: "Image name, e.g. myapp"))
                        .font(.footnote)
                }
                Section {
                    if fromMode == "path" {
                        TextField(translations.get("containerBuildDockerfile",
                                                   fallback: "Dockerfile path"),
                                  text: $dockerfile)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        TextEditor(text: $dockerfile)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(minHeight: 160)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Dockerfile")
                }
                Section {
                    TextField(translations.get("containerBuildTags", fallback: "Tags"),
                              text: $tagsText, axis: .vertical)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("containerBuildArgs", fallback: "Build args"),
                              text: $argsText, axis: .vertical)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text(translations.get("containerBuildTagsHelper",
                                          fallback: "One value per line"))
                        .font(.footnote)
                }
                if let errorText {
                    Section {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(translations.get("orchestrationImageBuild", fallback: "Build Image"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonConfirm", fallback: "Confirm")) {
                        submit()
                    }
                    .disabled(!canSubmit || submitting)
                }
            }
        }
    }

    private var canSubmit: Bool {
        !imageName.trimmingCharacters(in: .whitespaces).isEmpty
            && !dockerfile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        guard canSubmit else { return }
        submitting = true
        errorText = nil
        ChannelManager.shared.invokeDataMethod(
            "buildContainerImage",
            arguments: [
                "name": imageName.trimmingCharacters(in: .whitespaces),
                "from": fromMode,
                "dockerfile": dockerfile,
                "tags": splitLines(tagsText),
                "args": splitLines(argsText),
            ]
        ) { result in
            DispatchQueue.main.async {
                submitting = false
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                if success {
                    onCreated()
                    dismiss()
                } else {
                    errorText = dict?["error"] as? String
                        ?? translations.get("commonOperationFailed", fallback: "Operation failed")
                }
            }
        }
    }

    private func splitLines(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

struct ContainerRepoPickRow: Identifiable {
    let id: Int
    let name: String
    let downloadUrl: String
}

/// 推送镜像到仓库。
struct ContainerPushSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let imageName: String
    let onPushed: () -> Void

    @State private var repositories: [ContainerRepoPickRow] = []
    @State private var repository = ""
    @State private var name = ""
    @State private var tagName = "latest"
    @State private var sourceImageBase = ""
    @State private var submitting = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("containerTagLabel", fallback: "Tag"),
                              text: $tagName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    if repositories.isEmpty {
                        Text(translations.get("containerReposEmpty", fallback: "No repositories"))
                            .foregroundColor(.secondary)
                    } else {
                        Picker(translations.get("containerRepoLabel", fallback: "Repository"),
                               selection: $repository) {
                            ForEach(repositories) { repo in
                                Text(repo.name).tag("\(repo.id)")
                            }
                        }
                    }
                } footer: {
                    Text(translations.get("containerActionPushHelper",
                                          fallback: "The image is pushed to the selected registry."))
                        .font(.footnote)
                }
                if let errorText {
                    Section {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(translations.get("containerActionPush", fallback: "Push"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonConfirm", fallback: "Confirm")) {
                        submit()
                    }
                    .disabled(!canSubmit || submitting)
                }
            }
            .onAppear {
                if let colon = imageName.lastIndex(of: ":"),
                   !imageName[imageName.index(after: colon)...].contains("/") {
                    name = String(imageName[..<colon])
                    tagName = String(imageName[imageName.index(after: colon)...])
                } else {
                    name = imageName
                }
                sourceImageBase = name
                fetchRepositories()
            }
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !tagName.trimmingCharacters(in: .whitespaces).isEmpty
            && !repository.isEmpty
    }

    private func fetchRepositories() {
        guard repositories.isEmpty else { return }
        ChannelManager.shared.invokeDataMethod("getContainerRepos") { result in
            DispatchQueue.main.async {
                guard let items = result as? [[String: Any]] else { return }
                repositories = items.compactMap { item in
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
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        submitting = true
        errorText = nil
        ChannelManager.shared.invokeDataMethod(
            "pushContainerImage",
            arguments: [
                "image": "\(sourceImageBase):\(tagName.trimmingCharacters(in: .whitespaces))",
                "name": name.trimmingCharacters(in: .whitespaces),
                "repository": repository,
            ]
        ) { result in
            DispatchQueue.main.async {
                submitting = false
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                if success {
                    onPushed()
                    dismiss()
                } else {
                    errorText = dict?["error"] as? String
                        ?? translations.get("commonOperationFailed", fallback: "Operation failed")
                }
            }
        }
    }
}