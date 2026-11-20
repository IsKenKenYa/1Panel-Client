import SwiftUI
import AppleSharedUI

/// 容器模块：容器 / 镜像 / 网络 / 存储卷 / 编排 / 仓库 / 模版。
/// 子页签通过标题菜单切换，镜像、网络、存储卷复用各自渲染骨架。
struct ContainersModuleView: View {
    @EnvironmentObject var translations: TranslationsManager

    /// 走查钩子：`ONEPANEL_CONTAINERS_TAB=images|networks|volumes` 直接进入子页签。
    @State private var tab = ProcessInfo.processInfo.environment["ONEPANEL_CONTAINERS_TAB"] ?? "containers"

    var body: some View {
        Group {
            switch tab {
            case "images":
                ContainerImagesView()
            case "networks":
                ContainerNetworksView()
            case "volumes":
                ContainerVolumesView()
            case "compose":
                ContainerComposeListView()
            case "repos":
                ContainerReposView()
            case "templates":
                ContainerTemplatesView()
            default:
                ContainersView()
            }
        }
        .navigationTitle(translations.get("serverModuleContainers", fallback: "Containers"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(Self.tabs, id: \.key) { item in
                        Button {
                            tab = item.key
                        } label: {
                            if tab == item.key {
                                Label(item.title(translations), systemImage: "checkmark")
                            } else {
                                Text(item.title(translations))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currentTitle)
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .containers)
            }
        }
    }

    private struct TabItem {
        let key: String
        let title: (TranslationsManager) -> String
    }

    private static let tabs: [TabItem] = [
        TabItem(key: "containers") {
            $0.get("containerTabContainers", fallback: "Containers")
        },
        TabItem(key: "images") {
            $0.get("containerTabImages", fallback: "Images")
        },
        TabItem(key: "networks") {
            $0.get("containerTabNetworks", fallback: "Networks")
        },
        TabItem(key: "volumes") {
            $0.get("containerTabVolumes", fallback: "Volumes")
        },
        TabItem(key: "compose") {
            $0.get("containerTabOrchestration", fallback: "Compose")
        },
        TabItem(key: "repos") {
            $0.get("containerTabRepositories", fallback: "Repositories")
        },
        TabItem(key: "templates") {
            $0.get("containerTabTemplates", fallback: "Templates")
        },
    ]

    private var currentTitle: String {
        Self.tabs.first(where: { $0.key == tab })?.title(translations) ?? tab
    }
}

/// 镜像列表：标签、大小与创建时间，支持删除。
struct ContainerImageRow: Identifiable {
    let id: String
    let tags: [String]
    let size: Int
    let createdAt: String
    let isUsed: Bool

    var displayName: String {
        tags.first ?? (id.hasPrefix("sha256:") ? String(id.prefix(19)) : id)
    }
}

struct ContainerImagesView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var images: [ContainerImageRow] = []
    @State private var isLoading = false
    @State private var pendingDelete: ContainerImageRow?
    @State private var showPullSheet = false
    @State private var showBuildSheet = false
    @State private var pushTarget: ContainerImageRow?
    @State private var pullImageName = ""
    @State private var pullTag = ""
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && images.isEmpty {
                LoadingView()
            } else if images.isEmpty {
                EmptyStateView(
                    icon: "square.stack.3d.down.right",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                List {
                    ForEach(images) { image in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(image.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                if image.isUsed {
                                    StatusBadge(
                                        text: translations.get("containerImageInUse", fallback: "In Use"),
                                        color: .orange
                                    )
                                }
                            }
                            if let second = image.tags.dropFirst().first {
                                Text(second)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            HStack(spacing: 12) {
                                Label(ByteCountFormatter.string(fromByteCount: Int64(image.size), countStyle: .file),
                                      systemImage: "internaldrive")
                                if !image.createdAt.isEmpty {
                                    Label(TimestampFormat.display(image.createdAt), systemImage: "clock")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            Button {
                                pushTarget = image
                            } label: {
                                Label(translations.get("containerActionPush", fallback: "Push"),
                                      systemImage: "arrow.up.circle")
                            }
                            Button(role: .destructive) {
                                pendingDelete = image
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = image
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
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteImage()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        pullImageName = ""
                        pullTag = ""
                        showPullSheet = true
                    } label: {
                        Label(translations.get("orchestrationPullImage", fallback: "Pull Image"),
                              systemImage: "arrow.down.circle")
                    }
                    Button {
                        showBuildSheet = true
                    } label: {
                        Label(translations.get("orchestrationImageBuild", fallback: "Build Image"),
                              systemImage: "hammer")
                    }
                } label: {
                    Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showPullSheet) {
            pullSheet
        }
        .sheet(isPresented: $showBuildSheet) {
            ContainerBuildSheet(onCreated: {
                fetch()
            })
        }
        .sheet(item: $pushTarget) { image in
            ContainerPushSheet(imageName: image.displayName, onPushed: {
                fetch()
            })
        }
        .onAppear {
            if images.isEmpty {
                fetch()
            }
        }
    }

    private var pullSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("orchestrationPullImageHint",
                                               fallback: "Image name (e.g. nginx:latest)"),
                              text: $pullImageName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("orchestrationImageTagHint", fallback: "Tag"),
                              text: $pullTag)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text(translations.get("orchestrationPullImageHint",
                                          fallback: "Image name (e.g. nginx:latest)"))
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("orchestrationPullImage", fallback: "Pull Image"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showPullSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonConfirm", fallback: "Confirm")) {
                        pullImage()
                    }
                    .disabled(pullImageName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func pullImage() {
        let reference = pullImageName.trimmingCharacters(in: .whitespaces)
        guard !reference.isEmpty else { return }
        var image = reference
        var tag = pullTag.trimmingCharacters(in: .whitespaces)
        if tag.isEmpty,
           let colon = reference.lastIndex(of: ":"),
           !reference[reference.index(after: colon)...].contains("/") {
            image = String(reference[..<colon])
            tag = String(reference[reference.index(after: colon)...])
        }
        ChannelManager.shared.invokeDataMethod(
            "pullContainerImage",
            arguments: ["image": image, "tag": tag]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showPullSheet = false
                showToast(success
                    ? translations.get("orchestrationPullSuccess", fallback: "Pull started")
                    : translations.get("orchestrationPullFailed", fallback: "Pull failed"))
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        fetch()
                    }
                }
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getContainerImages") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                images = items.compactMap { item in
                    guard let id = item["id"] as? String, !id.isEmpty else { return nil }
                    return ContainerImageRow(
                        id: id,
                        tags: (item["tags"] as? [Any])?.compactMap { $0 as? String } ?? [],
                        size: item["size"] as? Int ?? 0,
                        createdAt: item["createdAt"] as? String ?? "",
                        isUsed: item["isUsed"] as? Bool ?? false
                    )
                }
            }
        }
    }

    private func deleteImage() {
        guard let image = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteContainerImage",
            arguments: ["id": image.id]
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

/// 网络列表：驱动、子网与网关，支持创建与删除。
struct ContainerNetworkRow: Identifiable {
    let id: String
    let name: String
    let driver: String
    let subnet: String
    let gateway: String
}

struct ContainerNetworksView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var networks: [ContainerNetworkRow] = []
    @State private var isLoading = false
    @State private var pendingDelete: ContainerNetworkRow?
    @State private var showCreateSheet = false
    @State private var newName = ""
    @State private var newSubnet = ""
    @State private var newGateway = ""
    @State private var toastText: String?

    private static let systemNetworks: Set<String> = ["host", "none", "bridge"]

    var body: some View {
        Group {
            if isLoading && networks.isEmpty {
                LoadingView()
            } else if networks.isEmpty {
                EmptyStateView(
                    icon: "network",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                List {
                    ForEach(networks) { network in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(network.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                if Self.systemNetworks.contains(network.name) {
                                    StatusBadge(
                                        text: translations.get("containerNetworkSystemChip", fallback: "System"),
                                        color: .gray
                                    )
                                }
                            }
                            HStack(spacing: 12) {
                                if !network.driver.isEmpty {
                                    Label(network.driver, systemImage: "square.stack.3d.up")
                                }
                                if !network.subnet.isEmpty {
                                    Label(network.subnet, systemImage: "point.3.connected.trianglepath.dotted")
                                }
                                if !network.gateway.isEmpty {
                                    Label(network.gateway, systemImage: "arrow.triangle.branch")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !Self.systemNetworks.contains(network.name) {
                                Button(role: .destructive) {
                                    pendingDelete = network
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
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
                    newSubnet = ""
                    newGateway = ""
                    showCreateSheet = true
                } label: {
                    Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
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
                deleteNetwork()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            if networks.isEmpty {
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
                    TextField(translations.get("containerNetworkSubnetHint", fallback: "Subnet"),
                              text: $newSubnet)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("containerNetworkGatewayHint", fallback: "Gateway"),
                              text: $newGateway)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("bridge")
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("containerNetworkDriverLabel", fallback: "Network"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        createNetwork()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getContainerNetworks") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                networks = items.compactMap { item in
                    guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                    return ContainerNetworkRow(
                        id: item["id"] as? String ?? name,
                        name: name,
                        driver: item["driver"] as? String ?? "",
                        subnet: item["subnet"] as? String ?? "",
                        gateway: item["gateway"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func createNetwork() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        ChannelManager.shared.invokeDataMethod(
            "createContainerNetwork",
            arguments: [
                "name": name,
                "subnet": newSubnet.trimmingCharacters(in: .whitespaces),
                "gateway": newGateway.trimmingCharacters(in: .whitespaces),
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showCreateSheet = false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                if success { fetch() }
            }
        }
    }

    private func deleteNetwork() {
        guard let network = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteContainerNetwork",
            arguments: ["name": network.name]
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

/// 存储卷列表：名称、驱动与挂载点，支持创建与删除。
struct ContainerVolumeRow: Identifiable {
    let name: String
    let driver: String
    let mountpoint: String

    var id: String { name }
}

struct ContainerVolumesView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var volumes: [ContainerVolumeRow] = []
    @State private var isLoading = false
    @State private var pendingDelete: ContainerVolumeRow?
    @State private var showCreateSheet = false
    @State private var newName = ""
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && volumes.isEmpty {
                LoadingView()
            } else if volumes.isEmpty {
                EmptyStateView(
                    icon: "externaldrive",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                List {
                    ForEach(volumes) { volume in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(volume.name)
                                .font(.subheadline.weight(.medium))
                            HStack(spacing: 12) {
                                if !volume.driver.isEmpty {
                                    Label(volume.driver, systemImage: "square.stack.3d.up")
                                }
                                if !volume.mountpoint.isEmpty {
                                    Label(volume.mountpoint, systemImage: "folder")
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = volume
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
                    showCreateSheet = true
                } label: {
                    Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
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
                deleteVolume()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            if volumes.isEmpty {
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
                } footer: {
                    Text("local")
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("containerTabVolumes", fallback: "Volumes"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        createVolume()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getContainerVolumes") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                volumes = items.compactMap { item in
                    guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                    return ContainerVolumeRow(
                        name: name,
                        driver: item["driver"] as? String ?? "",
                        mountpoint: item["mountpoint"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func createVolume() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        ChannelManager.shared.invokeDataMethod(
            "createContainerVolume",
            arguments: ["name": name]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showCreateSheet = false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                if success { fetch() }
            }
        }
    }

    private func deleteVolume() {
        guard let volume = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteContainerVolume",
            arguments: ["name": volume.name]
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
