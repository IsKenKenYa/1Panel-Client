import AppleSharedUI
import SwiftUI

struct ContainerNetworkItem: Identifiable, Equatable {
    let id: String
    let name: String
    let driver: String
    let subnet: String
    let gateway: String

    var isSystem: Bool {
        ["host", "none", "bridge"].contains(name)
    }
}

@MainActor
final class ContainerNetworkStore: ObservableObject {
    @Published var networks: [ContainerNetworkItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getContainerNetworks"
            )
            networks = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let name = item["name"] as? String, !name.isEmpty else {
                    return nil
                }
                return ContainerNetworkItem(
                    id: item["id"] as? String ?? name,
                    name: name,
                    driver: item["driver"] as? String ?? "",
                    subnet: item["subnet"] as? String ?? "",
                    gateway: item["gateway"] as? String ?? ""
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func create(name: String, subnet: String, gateway: String) async -> String? {
        let error = await perform(
            "createContainerNetwork",
            ["name": name, "subnet": subnet, "gateway": gateway]
        )
        if error == nil { await fetch() }
        return error
    }

    func delete(_ network: ContainerNetworkItem) async -> String? {
        let error = await perform("deleteContainerNetwork", ["name": network.name])
        if error == nil { await fetch() }
        return error
    }

    private func perform(_ method: String, _ arguments: [String: Any]) async -> String? {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                method,
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true { return nil }
            return payload["error"] as? String
        } catch {
            return error.localizedDescription
        }
    }
}

/// macOS 容器网络分区：驱动、子网与网关，支持创建与删除。
struct ContainerNetworksSectionView: View {
    @StateObject private var store = ContainerNetworkStore()
    @EnvironmentObject private var translations: TranslationsManager

    @State private var showCreateSheet = false
    @State private var pendingDelete: ContainerNetworkItem?
    @State private var actionError: String?

    var body: some View {
        Group {
            if store.isLoading && store.networks.isEmpty {
                LoadingView()
            } else if let error = store.errorMessage, store.networks.isEmpty {
                ErrorView(message: error) {
                    Task { await store.fetch() }
                }
            } else if store.networks.isEmpty {
                EmptyStateView(
                    icon: "network",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                List {
                    ForEach(store.networks) { network in
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 8) {
                                    Text(network.name)
                                        .font(.subheadline.weight(.medium))
                                    if network.isSystem {
                                        StatusBadge(
                                            text: translations.get("containerNetworkSystemChip",
                                                                   fallback: "System"),
                                            color: .gray
                                        )
                                    }
                                }
                                HStack(spacing: 12) {
                                    if !network.driver.isEmpty {
                                        Label(network.driver, systemImage: "square.stack.3d.up")
                                    }
                                    if !network.subnet.isEmpty {
                                        Label(network.subnet,
                                              systemImage: "point.3.connected.trianglepath.dotted")
                                    }
                                    if !network.gateway.isEmpty {
                                        Label(network.gateway,
                                              systemImage: "arrow.triangle.branch")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            if !network.isSystem {
                                Button(role: .destructive) {
                                    pendingDelete = network
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.fetch()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    Task { await store.fetch() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                Button {
                    showCreateSheet = true
                } label: {
                    Label(translations.get("containerNetworkDriverLabel", fallback: "Driver"),
                          systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            ContainerNetworkCreateSheet(store: store)
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
                Task { await deletePending() }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage",
                                  fallback: "This action cannot be undone."))
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                actionError = nil
            }
        } message: {
            Text(actionError ?? "")
        }
        .task {
            await store.fetch()
        }
    }

    private func deletePending() async {
        guard let network = pendingDelete else { return }
        pendingDelete = nil
        if let error = await store.delete(network) {
            actionError = error.isEmpty
                ? translations.get("commonDeleteFailed", fallback: "Delete failed")
                : error
        }
    }
}

private struct ContainerNetworkCreateSheet: View {
    @ObservedObject var store: ContainerNetworkStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var name = ""
    @State private var subnet = ""
    @State private var gateway = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $name)
                    TextField(translations.get("containerNetworkSubnetHint",
                                               fallback: "Subnet"),
                              text: $subnet)
                    TextField(translations.get("containerNetworkGatewayHint",
                                               fallback: "Gateway"),
                              text: $gateway)
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("bridge")
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("containerTabNetworks", fallback: "Networks"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await submit() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(width: 440, height: 260)
    }

    private func submit() async {
        isSaving = true
        if let error = await store.create(
            name: name.trimmingCharacters(in: .whitespaces),
            subnet: subnet.trimmingCharacters(in: .whitespaces),
            gateway: gateway.trimmingCharacters(in: .whitespaces)
        ) {
            errorMessage = error.isEmpty
                ? translations.get("commonSaveFailed", fallback: "Save failed")
                : error
        } else {
            dismiss()
        }
        isSaving = false
    }
}

struct ContainerVolumeItem: Identifiable, Equatable {
    let name: String
    let driver: String
    let mountpoint: String

    var id: String { name }
}

@MainActor
final class ContainerVolumeStore: ObservableObject {
    @Published var volumes: [ContainerVolumeItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getContainerVolumes"
            )
            volumes = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let name = item["name"] as? String, !name.isEmpty else {
                    return nil
                }
                return ContainerVolumeItem(
                    name: name,
                    driver: item["driver"] as? String ?? "",
                    mountpoint: item["mountpoint"] as? String ?? ""
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func create(name: String) async -> String? {
        let error = await perform("createContainerVolume", ["name": name])
        if error == nil { await fetch() }
        return error
    }

    func delete(_ volume: ContainerVolumeItem) async -> String? {
        let error = await perform("deleteContainerVolume", ["name": volume.name])
        if error == nil { await fetch() }
        return error
    }

    private func perform(_ method: String, _ arguments: [String: Any]) async -> String? {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                method,
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true { return nil }
            return payload["error"] as? String
        } catch {
            return error.localizedDescription
        }
    }
}

/// macOS 容器存储卷分区：名称、驱动与挂载点，支持创建与删除。
struct ContainerVolumesSectionView: View {
    @StateObject private var store = ContainerVolumeStore()
    @EnvironmentObject private var translations: TranslationsManager

    @State private var showCreateSheet = false
    @State private var pendingDelete: ContainerVolumeItem?
    @State private var actionError: String?

    var body: some View {
        Group {
            if store.isLoading && store.volumes.isEmpty {
                LoadingView()
            } else if let error = store.errorMessage, store.volumes.isEmpty {
                ErrorView(message: error) {
                    Task { await store.fetch() }
                }
            } else if store.volumes.isEmpty {
                EmptyStateView(
                    icon: "externaldrive",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                List {
                    ForEach(store.volumes) { volume in
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
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
                            Spacer()
                            Button(role: .destructive) {
                                pendingDelete = volume
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.fetch()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    Task { await store.fetch() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                Button {
                    showCreateSheet = true
                } label: {
                    Label(translations.get("containerTabVolumes", fallback: "Volumes"),
                          systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            ContainerVolumeCreateSheet(store: store)
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
                Task { await deletePending() }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage",
                                  fallback: "This action cannot be undone."))
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                actionError = nil
            }
        } message: {
            Text(actionError ?? "")
        }
        .task {
            await store.fetch()
        }
    }

    private func deletePending() async {
        guard let volume = pendingDelete else { return }
        pendingDelete = nil
        if let error = await store.delete(volume) {
            actionError = error.isEmpty
                ? translations.get("commonDeleteFailed", fallback: "Delete failed")
                : error
        }
    }
}

private struct ContainerVolumeCreateSheet: View {
    @ObservedObject var store: ContainerVolumeStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var name = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $name)
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("local")
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("containerTabVolumes", fallback: "Volumes"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await submit() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(width: 400, height: 200)
    }

    private func submit() async {
        isSaving = true
        if let error = await store.create(name: name.trimmingCharacters(in: .whitespaces)) {
            errorMessage = error.isEmpty
                ? translations.get("commonSaveFailed", fallback: "Save failed")
                : error
        } else {
            dismiss()
        }
        isSaving = false
    }
}