import AppleSharedUI
import SwiftUI

/// macOS 快照管理：列表、创建、恢复与删除。
struct VMSnapshotSheet: View {
    let instanceName: String
    @ObservedObject var store: VirtualMachineStore
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    @State private var result: VMSnapshotResult?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var pendingAction: VMSnapshotAction?
    @State private var showCreate = false
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var actionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(translations.get("vmInstanceSnapshotTitle", fallback: "Snapshots"))
                    .font(.headline)
                Text(instanceName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if isLoading && result != nil {
                    ProgressView().controlSize(.small)
                }
                Button {
                    showCreate = true
                } label: {
                    Label(translations.get("vmInstanceSnapshotCreateAction", fallback: "Create Snapshot"),
                          systemImage: "plus")
                }
                .disabled(!(result?.canCreate ?? false) || store.isBusy)
                Button {
                    Task { await reload() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }

            Group {
                if isLoading && result == nil {
                    LoadingView()
                } else if let result {
                    if result.items.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            message: translations.get("vmInstanceSnapshotEmptyMessage",
                                                      fallback: "No snapshots")
                        )
                    } else {
                        List(result.items) { snapshot in
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(snapshot.name).font(.subheadline.weight(.medium))
                                        if snapshot.current {
                                            Text(translations.get("vmInstanceSnapshotCurrentLabel",
                                                                  fallback: "Current"))
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 1)
                                                .background(Color.accentColor.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    if !snapshot.description.isEmpty {
                                        Text(snapshot.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text("\(VMFormatting.timestamp(snapshot.createdAtMillis)) · \(VMFormatting.bytes(snapshot.size))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    pendingAction = .recover(snapshot)
                                } label: {
                                    Image(systemName: "arrow.uturn.backward")
                                }
                                .buttonStyle(.borderless)
                                .disabled(!snapshot.canRecover || store.isBusy)
                                .help(translations.get("vmInstanceSnapshotRecoverAction",
                                                       fallback: "Recover"))
                                Button(role: .destructive) {
                                    pendingAction = .delete(snapshot)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .disabled(store.isBusy)
                                .help(translations.get("vmInstanceSnapshotDeleteAction",
                                                       fallback: "Delete Snapshot"))
                            }
                            .padding(.vertical, 2)
                        }
                        .listStyle(.inset)
                    }
                } else {
                    ErrorView(
                        message: loadError ?? translations.get("commonLoadFailedTitle",
                                                               fallback: "Failed to load")
                    ) {
                        Task { await reload() }
                    }
                }
            }

            HStack {
                if let result, !result.canRecover {
                    Text(translations.get("vmInstanceSnapshotNeedShutOff",
                                          fallback: "Shut down the virtual machine before recovering a snapshot"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(translations.get("commonClose", fallback: "Close")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 680, height: 500)
        .task {
            await reload()
        }
        .alert(
            translations.get("vmInstanceSnapshotCreateAction", fallback: "Create Snapshot"),
            isPresented: $showCreate
        ) {
            TextField(translations.get("vmInstanceSnapshotNameLabel", fallback: "Snapshot Name"),
                      text: $newName)
            TextField(translations.get("vmInstanceDescriptionColumn", fallback: "Description"),
                      text: $newDescription)
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                resetCreateFields()
            }
            Button(translations.get("vmInstanceSnapshotCreateAction", fallback: "Create Snapshot")) {
                create()
            }
            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .confirmationDialog(
            confirmTitle,
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingAction {
                Button(confirmButtonTitle(action),
                       role: action.isDestructive ? .destructive : nil) {
                    run(action)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingAction = nil
                }
            }
        } message: {
            Text(confirmMessage)
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
    }

    private func reload() async {
        isLoading = true
        do {
            result = try await store.fetchSnapshots(name: instanceName)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func create() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = newDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        Task {
            if let error = await store.createSnapshot(
                name: instanceName,
                snapshotName: name,
                description: description
            ) {
                actionError = error
            }
            resetCreateFields()
            await reload()
        }
    }

    private func run(_ action: VMSnapshotAction) {
        pendingAction = nil
        Task {
            let error: String?
            switch action {
            case .recover(let snapshot):
                error = await store.recoverSnapshot(
                    name: instanceName,
                    snapshotName: snapshot.name
                )
            case .delete(let snapshot):
                error = await store.deleteSnapshot(
                    name: instanceName,
                    snapshotName: snapshot.name
                )
            }
            if let error { actionError = error }
            await reload()
        }
    }

    private func resetCreateFields() {
        newName = ""
        newDescription = ""
    }

    private var confirmTitle: String {
        guard let pendingAction else { return "" }
        switch pendingAction {
        case .recover:
            return translations.get("vmInstanceSnapshotRecoverAction", fallback: "Recover")
        case .delete:
            return translations.get("vmInstanceSnapshotDeleteAction", fallback: "Delete Snapshot")
        }
    }

    private var confirmMessage: String {
        guard let pendingAction else { return "" }
        switch pendingAction {
        case .recover(let snapshot):
            return translations.get("vmInstanceSnapshotRecoverConfirm",
                                    fallback: "Recover to snapshot {name}?")
                .replacingOccurrences(of: "{name}", with: snapshot.name)
        case .delete(let snapshot):
            return snapshot.name
        }
    }

    private func confirmButtonTitle(_ action: VMSnapshotAction) -> String {
        switch action {
        case .recover:
            return translations.get("vmInstanceSnapshotRecoverAction", fallback: "Recover")
        case .delete:
            return translations.get("commonDelete", fallback: "Delete")
        }
    }
}

enum VMSnapshotAction: Identifiable {
    case recover(VMSnapshotModel)
    case delete(VMSnapshotModel)

    var id: String {
        switch self {
        case .recover(let snapshot): return "recover-\(snapshot.name)"
        case .delete(let snapshot): return "delete-\(snapshot.name)"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .recover: return false
        case .delete: return true
        }
    }
}