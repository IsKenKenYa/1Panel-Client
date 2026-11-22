import SwiftUI
import AppleSharedUI

/// ISO 镜像分区。
struct VMIsoSectionView: View {
    @ObservedObject var viewModel: VirtualMachinesViewModel
    @EnvironmentObject private var translations: TranslationsManager

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.isos.isEmpty {
                LoadingView()
            } else if viewModel.isosError != nil && viewModel.isos.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await viewModel.loadIsos() }
                }
            } else if viewModel.isos.isEmpty {
                EmptyStateView(
                    icon: "opticaldisc",
                    message: translations.get("vmIsoEmptyTitle", fallback: "No ISO images"),
                    description: translations.get("vmIsoEmptyDescription",
                                                 fallback: "ISO images registered on the panel appear here")
                )
            } else {
                List {
                    if let error = viewModel.isosError {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("vmTabIso", fallback: "ISO")) {
                        ForEach(viewModel.isos) { iso in
                            VMIsoRow(iso: iso)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.loadIsos()
                }
            }
        }
    }
}

private struct VMIsoRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let iso: VMIsoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(iso.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Text(iso.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(iso.type) · \(VMFormatting.bytes(iso.size))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(iso.path)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            if !iso.isExist {
                Text(translations.get("vmIsoStatusFileMissing", fallback: "File missing"))
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
    }
}

/// 虚拟机模板分区。
struct VMTemplateSectionView: View {
    @ObservedObject var viewModel: VirtualMachinesViewModel
    @EnvironmentObject private var translations: TranslationsManager

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.templates.isEmpty {
                LoadingView()
            } else if viewModel.templatesError != nil && viewModel.templates.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await viewModel.loadTemplates() }
                }
            } else if viewModel.templates.isEmpty {
                EmptyStateView(
                    icon: "square.on.square",
                    message: translations.get("vmTemplateEmptyTitle", fallback: "No templates"),
                    description: translations.get("vmTemplateEmptyDescription",
                                                 fallback: "Templates created from virtual machines appear here")
                )
            } else {
                List {
                    if let error = viewModel.templatesError {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("vmTabTemplates", fallback: "Templates")) {
                        ForEach(viewModel.templates) { template in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(template.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(template.status)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("\(translations.get("vmTemplateSourceVmLabel", fallback: "Source")): \(template.sourceVM)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(template.cpu) \(translations.get("vmOverviewCoresUnit", fallback: "cores")) · \(VMFormatting.mib(template.memoryMiB)) · \(VMFormatting.bytes(template.diskSize))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.loadTemplates()
                }
            }
        }
    }
}

/// 虚拟机网络分区，含已占用 IP 展开列表。
struct VMNetworkSectionView: View {
    @ObservedObject var viewModel: VirtualMachinesViewModel
    @EnvironmentObject private var translations: TranslationsManager

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.networks.isEmpty {
                LoadingView()
            } else if viewModel.networksError != nil && viewModel.networks.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await viewModel.loadNetworks() }
                }
            } else if viewModel.networks.isEmpty {
                EmptyStateView(
                    icon: "network",
                    message: translations.get("vmNetworkEmptyTitle", fallback: "No networks"),
                    description: translations.get("vmNetworkEmptyDescription",
                                                 fallback: "Virtual networks created on the panel appear here")
                )
            } else {
                List {
                    if let error = viewModel.networksError {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("vmTabNetworks", fallback: "Networks")) {
                        ForEach(viewModel.networks) { network in
                            VMNetworkRow(network: network)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.loadNetworks()
                }
            }
        }
    }
}

private struct VMNetworkRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let network: VMNetworkModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(network.name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(network.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !network.cidr.isEmpty {
                Text("\(network.cidr) · \(translations.get("vmNetworkGatewayLabel", fallback: "Gateway")): \(network.gateway)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(translations.get("vmNetworkVmCountLabel", fallback: "Virtual machines")): \(network.vmCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !network.registered {
                Text(translations.get("vmNetworkNotRegistered", fallback: "Not registered"))
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            if !network.usedIPs.isEmpty {
                DisclosureGroup(translations.get("vmNetworkUsedIpTitle", fallback: "Used IP addresses")) {
                    ForEach(network.usedIPs) { usage in
                        HStack {
                            Text(usage.ip)
                                .font(.caption.monospacedDigit())
                            Spacer()
                            Text(usage.vmName.isEmpty ? usage.mac : usage.vmName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

/// 虚拟机存储池分区。
struct VMStorageSectionView: View {
    @ObservedObject var viewModel: VirtualMachinesViewModel
    @EnvironmentObject private var translations: TranslationsManager

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.storages.isEmpty {
                LoadingView()
            } else if viewModel.storagesError != nil && viewModel.storages.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await viewModel.loadStorages() }
                }
            } else if viewModel.storages.isEmpty {
                EmptyStateView(
                    icon: "externaldrive",
                    message: translations.get("vmStorageEmptyTitle", fallback: "No storage pools"),
                    description: translations.get("vmStorageEmptyDescription",
                                                 fallback: "Storage pools usable by virtual machines appear here")
                )
            } else {
                List {
                    if let error = viewModel.storagesError {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("vmTabStorages", fallback: "Storage Pools")) {
                        ForEach(viewModel.storages) { storage in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(storage.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(storage.type)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(storage.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                ProgressView(value: min(max(storage.usedPercent, 0), 100), total: 100)
                                    .tint(storage.usedPercent >= 90 ? .red : .accentColor)
                                HStack {
                                    Text("\(VMFormatting.bytes(storage.available)) \(translations.get("vmStorageAvailableLabel", fallback: "available"))")
                                    Spacer()
                                    Text(String(format: "%.1f%%", storage.usedPercent))
                                        .monospacedDigit()
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.loadStorages()
                }
            }
        }
    }
}