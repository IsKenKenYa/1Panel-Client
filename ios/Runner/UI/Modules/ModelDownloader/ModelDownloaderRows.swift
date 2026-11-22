import AppleSharedUI
import SwiftUI

struct FeaturedModelRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let model: FeaturedModelItem
    let isBusy: Bool
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(model.repoID.isEmpty ? model.key : model.repoID)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button {
                    onDownload()
                } label: {
                    Label(translations.get("modelDownloaderDownloadAction", fallback: "Download"),
                          systemImage: "arrow.down.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isBusy)
            }
            Text(metadata)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            let description = model.localizedDescription()
            if !description.isEmpty {
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items: [String] = []
        if !model.family.isEmpty { items.append(model.family) }
        if !model.architecture.isEmpty { items.append(model.architecture) }
        if !model.backboneParams.isEmpty { items.append(model.backboneParams) }
        if model.weightGB > 0 {
            items.append(String(format: "%.1f GB", model.weightGB))
        }
        if !model.sources.isEmpty {
            items.append(model.sources.joined(separator: " / "))
        }
        return items.joined(separator: " · ")
    }
}

struct MarketModelRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let model: MarketModelItem
    let isBusy: Bool
    let onDownload: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name.isEmpty ? model.repoID : model.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(model.repoID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(metadata)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button(translations.get("modelDownloaderDownloadTypeAll", fallback: "Full model")) {
                    onDownload("all")
                }
                Button(translations.get("modelDownloaderDownloadTypeTokenizer",
                                        fallback: "Tokenizer only")) {
                    onDownload("tokenizer")
                }
            } label: {
                Label(translations.get("modelDownloaderDownloadAction", fallback: "Download"),
                      systemImage: "arrow.down.circle")
                    .labelStyle(.iconOnly)
            }
            .menuStyle(.borderlessButton)
            .disabled(isBusy)
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items: [String] = []
        if model.sizeFormatted.isEmpty == false { items.append(model.sizeFormatted) }
        items.append("↓ \(model.downloads)")
        items.append("♥ \(model.likes)")
        return items.joined(separator: " · ")
    }
}

struct DownloadTaskRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let task: DownloadTaskItem
    let onAction: (DownloadTaskAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(task.modelName.isEmpty ? task.repoID : task.modelName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: task.status, color: toneColor)
            }
            ProgressView(value: min(max(task.progressRatio, 0), 1), total: 1)
                .tint(toneColor)
            HStack {
                Text(String(format: "%.0f%%", task.progressRatio * 100))
                    .monospacedDigit()
                if task.totalSize > 0 {
                    Text("· \(VMFormatting.bytes(task.downloadedSize)) / \(VMFormatting.bytes(task.totalSize))")
                }
                Spacer()
                Menu {
                    if task.canCancel {
                        Button {
                            onAction(.cancel(task))
                        } label: {
                            Label(translations.get("modelDownloaderTaskCancelAction", fallback: "Cancel"),
                                  systemImage: "xmark.circle")
                        }
                    }
                    if task.canRetry {
                        Button {
                            onAction(.retry(task))
                        } label: {
                            Label(translations.get("modelDownloaderTaskRetryAction", fallback: "Retry"),
                                  systemImage: "arrow.clockwise")
                        }
                    }
                    if task.canRemoveRecord {
                        Button(role: .destructive) {
                            onAction(.remove(task))
                        } label: {
                            Label(translations.get("modelDownloaderTaskRemoveAction",
                                                   fallback: "Remove record"),
                                  systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            if !task.errorMessage.isEmpty {
                Text(task.errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private var toneColor: Color {
        switch task.statusTone {
        case "positive": return .green
        case "negative": return .red
        case "info": return .blue
        default: return .secondary
        }
    }
}

struct DownloadedModelRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let model: DownloadedModelItem
    let isBusy: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(model.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .disabled(isBusy)
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items: [String] = []
        if !model.sizeFormatted.isEmpty { items.append(model.sizeFormatted) }
        if !model.source.isEmpty { items.append(model.source) }
        if !model.downloadType.isEmpty {
            items.append(translations.get(
                model.downloadType == "tokenizer"
                    ? "modelDownloaderDownloadTypeTokenizer"
                    : "modelDownloaderDownloadTypeAll",
                fallback: model.downloadType
            ))
        }
        return items.joined(separator: " · ")
    }
}

