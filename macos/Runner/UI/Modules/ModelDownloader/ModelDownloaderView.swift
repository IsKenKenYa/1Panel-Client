import AppleSharedUI
import SwiftUI

/// macOS 模型下载器：推荐、市场搜索、下载任务与本地模型四个分区。
struct ModelDownloaderView: View {
    @StateObject private var store = ModelDownloaderStore(
        channel: MacOSDataChannel(channelManager: .shared)
    )
    @EnvironmentObject private var translations: TranslationsManager

    @State private var section = ModelDownloaderStore.Section(
        rawValue: ProcessInfo.processInfo.environment["ONEPANEL_DOWNLOADER_TAB"] ?? ""
    ) ?? .featured
    @State private var featuredFamily = ""
    @State private var searchText = ""
    @State private var taskStatus = "all"
    @State private var showSettings = false
    @State private var pendingTask: DownloadTaskAction?
    @State private var pendingLocal: DownloadedModelItem?
    @State private var actionError: String?

    var body: some View {
        VStack(spacing: 0) {
            switch section {
            case .featured:
                featuredContent
            case .search:
                searchContent
            case .tasks:
                tasksContent
            case .local:
                localContent
            }
        }
        .navigationTitle(translations.get("modelDownloaderTabLabel", fallback: "Model Download"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("", selection: $section) {
                    ForEach(ModelDownloaderStore.Section.allCases) { item in
                        Text(sectionTitle(item)).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showSettings = true
                } label: {
                    Label(translations.get("modelDownloaderSettingsAction",
                                            fallback: "Download settings"),
                          systemImage: "gearshape")
                }
                .help(translations.get("modelDownloaderSettingsAction", fallback: "Download settings"))
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await refresh() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
        }
        .task {
            await store.loadAll()
        }
        .sheet(isPresented: $showSettings) {
            ModelDownloaderSettingsFormView(store: store)
        }
        .confirmationDialog(
            taskPendingTitle,
            isPresented: Binding(
                get: { pendingTask != nil },
                set: { if !$0 { pendingTask = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingTask {
                Button(taskPendingButton(action),
                       role: action.isDestructive ? .destructive : nil) {
                    run(action)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingTask = nil
                }
            }
        } message: {
            Text(taskPendingMessage)
        }
        .confirmationDialog(
            pendingLocal.map { $0.name.isEmpty ? $0.repoID : $0.name } ?? "",
            isPresented: Binding(
                get: { pendingLocal != nil },
                set: { if !$0 { pendingLocal = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let model = pendingLocal {
                Button(translations.get("modelDownloaderLocalDeleteFileLabel",
                                        fallback: "Delete the model files too"),
                       role: .destructive) {
                    deleteLocal(model, withFile: true)
                }
                Button(translations.get("modelDownloaderLocalDeleteAction", fallback: "Delete")) {
                    deleteLocal(model, withFile: false)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingLocal = nil
                }
            }
        } message: {
            Text(translations.get("modelDownloaderLocalDeleteConfirm", fallback: "Delete local model {name}?")
                .replacingOccurrences(of: "{name}", with: pendingLocal?.name ?? "")
                .replacingOccurrences(of: "{0}", with: pendingLocal?.name ?? ""))
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

    private var featuredContent: some View {
        Group {
            if store.isLoading && store.featured.isEmpty {
                LoadingView()
            } else if store.featuredError != nil && store.featured.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await store.loadFeatured() }
                }
            } else if store.featured.isEmpty {
                EmptyStateView(
                    icon: "sparkles",
                    message: translations.get("modelDownloaderFeaturedEmptyTitle",
                                              fallback: "No featured models"),
                    description: translations.get("modelDownloaderFeaturedEmptyDescription",
                                                 fallback: "Sync the featured catalog to browse it.")
                )
            } else {
                List {
                    Section {
                        HStack {
                            Menu {
                                Button(translations.get("alertRuleFilterAllTypes", fallback: "All")) {
                                    featuredFamily = ""
                                    Task { await store.loadFeatured() }
                                }
                                ForEach(store.featuredFamilies, id: \.self) { family in
                                    Button(family) {
                                        featuredFamily = family
                                        Task { await store.loadFeatured(family: family) }
                                    }
                                }
                            } label: {
                                Label(featuredFamily.isEmpty
                                      ? translations.get("modelDownloaderFeaturedSectionTitle",
                                                         fallback: "Featured models")
                                      : featuredFamily,
                                      systemImage: "line.3.horizontal.decrease.circle")
                            }
                            Spacer()
                            Button {
                                Task {
                                    if let error = await store.syncFeatured() {
                                        actionError = error
                                    }
                                }
                            } label: {
                                Label(translations.get("modelDownloaderFeaturedSyncAction",
                                                       fallback: "Sync catalog"),
                                      systemImage: "arrow.triangle.2.circlepath")
                            }
                            .disabled(store.isBusy)
                        }
                    }
                    if let error = store.featuredError {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("modelDownloaderFeaturedSectionTitle",
                                             fallback: "Featured models")) {
                        ForEach(store.featured) { model in
                            MacFeaturedModelRow(model: model, isBusy: store.isBusy) {
                                Task { await downloadFeatured(model) }
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.loadFeatured(family: featuredFamily.isEmpty ? nil : featuredFamily)
                }
            }
        }
    }

    private var searchContent: some View {
        VStack(spacing: 0) {
            searchHeader
            Group {
                if store.searchError != nil && store.searchResults.isEmpty {
                    ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                        Task { await runSearch() }
                    }
                } else if store.searchResults.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        message: translations.get("modelDownloaderSearchHint",
                                                  fallback: "Enter a model name or repository ID")
                    )
                } else {
                    List {
                        Section(translations.get("modelDownloaderSearchSectionTitle",
                                                 fallback: "Model market")) {
                            ForEach(store.searchResults) { model in
                                MacMarketModelRow(model: model, isBusy: store.isBusy) { downloadType in
                                    Task { await downloadMarket(model, downloadType: downloadType) }
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                    .refreshable {
                        await runSearch()
                    }
                }
            }
        }
        .task {
            if store.searchResults.isEmpty {
                await runSearch()
            }
        }
    }

    private var searchHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField(translations.get("modelDownloaderSearchHint",
                                           fallback: "Enter a model name or repository ID"),
                          text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await runSearch() } }
                Button {
                    Task { await runSearch() }
                } label: {
                    Label(translations.get("modelDownloaderSearchAction", fallback: "Search"),
                          systemImage: "magnifyingglass")
                }
                .disabled(store.isLoading)
            }
            HStack(spacing: 10) {
                Picker("", selection: Binding(
                    get: { store.searchSource },
                    set: { value in Task { await store.search(source: value, query: searchText) } }
                )) {
                    Text(translations.get("modelDownloaderSearchSourceHf", fallback: "Hugging Face"))
                        .tag("hf")
                    Text(translations.get("modelDownloaderSearchSourceModelScope",
                                          fallback: "ModelScope"))
                        .tag("modelScope")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 280)

                Menu {
                    ForEach(store.options.sorts, id: \.self) { sort in
                        Button(sortLabel(sort)) {
                            Task { await store.search(query: searchText, sort: sort) }
                        }
                    }
                } label: {
                    Label(sortLabel(store.searchSort), systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                }
                Spacer()
                Text("\(store.searchTotal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var tasksContent: some View {
        Group {
            if store.isLoading && store.tasks.isEmpty {
                LoadingView()
            } else if store.tasksError != nil && store.tasks.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await store.loadTasks() }
                }
            } else if store.tasks.isEmpty {
                EmptyStateView(
                    icon: "arrow.down.circle",
                    message: translations.get("modelDownloaderTaskEmptyTitle",
                                              fallback: "No download tasks"),
                    description: translations.get("modelDownloaderTaskEmptyDescription",
                                                  fallback: "Pick a model in the market to start downloading.")
                )
            } else {
                List {
                    Section {
                        Menu {
                            Button(translations.get("alertRuleFilterAllTypes", fallback: "All")) {
                                taskStatus = "all"
                                Task { await store.loadTasks() }
                            }
                            ForEach(store.options.taskStatuses, id: \.self) { status in
                                Button(taskStatusLabel(status)) {
                                    taskStatus = status
                                    Task { await store.loadTasks(status: status) }
                                }
                            }
                        } label: {
                            Label(taskStatus == "all"
                                  ? translations.get("modelDownloaderTaskStatusLabel",
                                                     fallback: "Status")
                                  : taskStatusLabel(taskStatus),
                                  systemImage: "line.3.horizontal.decrease.circle")
                        }
                        Spacer()
                        Text("\(store.tasks.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    if let error = store.tasksError {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("modelDownloaderTasksSectionTitle",
                                             fallback: "Download tasks")) {
                        ForEach(store.tasks) { task in
                            MacDownloadTaskRow(task: task) { action in
                                pendingTask = action
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.loadTasks(status: taskStatus == "all" ? nil : taskStatus)
                }
            }
        }
    }

    private var localContent: some View {
        Group {
            if store.isLoading && store.localModels.isEmpty {
                LoadingView()
            } else if store.localError != nil && store.localModels.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await store.loadLocal() }
                }
            } else if store.localModels.isEmpty {
                EmptyStateView(
                    icon: "internaldrive",
                    message: translations.get("modelDownloaderLocalEmptyTitle",
                                              fallback: "No local models"),
                    description: translations.get("modelDownloaderLocalEmptyDescription",
                                                  fallback: "Downloaded models appear here.")
                )
            } else {
                List {
                    if let error = store.localError {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("modelDownloaderLocalSectionTitle",
                                             fallback: "Local models")) {
                        ForEach(store.localModels) { model in
                            MacDownloadedModelRow(model: model, isBusy: store.isBusy) {
                                pendingLocal = model
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.loadLocal()
                }
            }
        }
    }

    private func refresh() async {
        switch section {
        case .featured:
            await store.loadFeatured(family: featuredFamily.isEmpty ? nil : featuredFamily)
        case .search:
            await runSearch()
        case .tasks:
            await store.loadTasks(status: taskStatus == "all" ? nil : taskStatus)
        case .local:
            await store.loadLocal()
        }
    }

    private func runSearch() async {
        await store.search(
            source: store.searchSource,
            query: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
            sort: store.searchSort
        )
    }

    private func downloadFeatured(_ model: FeaturedModelItem) async {
        if let error = await store.downloadFeatured(model) {
            actionError = error
        }
    }

    private func downloadMarket(_ model: MarketModelItem, downloadType: String) async {
        if let error = await store.downloadModel(
            repoID: model.repoID,
            source: store.searchSource,
            downloadType: downloadType
        ) {
            actionError = error
        }
    }

    private func deleteLocal(_ model: DownloadedModelItem, withFile: Bool) {
        pendingLocal = nil
        Task {
            if let error = await store.deleteLocalModel(
                name: model.name.isEmpty ? model.repoID : model.name,
                downloadType: model.downloadType,
                withFile: withFile
            ) {
                actionError = error
            }
        }
    }

    private func sectionTitle(_ section: ModelDownloaderStore.Section) -> String {
        switch section {
        case .featured:
            return translations.get("modelDownloaderFeaturedSectionTitle", fallback: "Featured models")
        case .search:
            return translations.get("modelDownloaderSearchSectionTitle", fallback: "Model market")
        case .tasks:
            return translations.get("modelDownloaderTasksSectionTitle", fallback: "Download tasks")
        case .local:
            return translations.get("modelDownloaderLocalSectionTitle", fallback: "Local models")
        }
    }

    private func sortLabel(_ sort: String) -> String {
        switch sort {
        case "trending": return translations.get("modelDownloaderSortTrending", fallback: "Trending")
        case "downloads": return translations.get("modelDownloaderSortDownloads", fallback: "Downloads")
        case "likes": return translations.get("modelDownloaderSortLikes", fallback: "Likes")
        case "updated": return translations.get("modelDownloaderSortUpdated", fallback: "Recently updated")
        default: return sort
        }
    }

    private func taskStatusLabel(_ status: String) -> String {
        switch status {
        case "running": return translations.get("modelDownloaderTaskStatusRunning", fallback: "Downloading")
        case "waiting": return translations.get("modelDownloaderTaskStatusWaiting", fallback: "Waiting")
        case "completed": return translations.get("modelDownloaderTaskStatusCompleted", fallback: "Completed")
        case "failed": return translations.get("modelDownloaderTaskStatusFailed", fallback: "Failed")
        case "cancelled": return translations.get("modelDownloaderTaskStatusCancelled", fallback: "Cancelled")
        default: return status
        }
    }

    private var taskPendingTitle: String {
        guard let action = pendingTask else { return "" }
        switch action {
        case .cancel:
            return translations.get("modelDownloaderTaskCancelAction", fallback: "Cancel")
        case .retry:
            return translations.get("modelDownloaderTaskRetryAction", fallback: "Retry")
        case .remove:
            return translations.get("modelDownloaderTaskRemoveAction", fallback: "Remove record")
        }
    }

    private var taskPendingMessage: String {
        guard let action = pendingTask else { return "" }
        let task: DownloadTaskItem
        let key: String
        let fallback: String
        switch action {
        case .cancel(let item):
            task = item
            key = "modelDownloaderTaskCancelConfirm"
            fallback = "Cancel download task {name}?"
        case .retry(let item):
            task = item
            key = "modelDownloaderTaskRetryConfirm"
            fallback = "Retry download task {name}?"
        case .remove(let item):
            task = item
            key = "modelDownloaderTaskRemoveConfirm"
            fallback = "Remove the record of download task {name}?"
        }
        let name = task.modelName.isEmpty ? task.repoID : task.modelName
        return translations.get(key, fallback: fallback)
            .replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: "{0}", with: name)
    }

    private func taskPendingButton(_ action: DownloadTaskAction) -> String {
        switch action {
        case .cancel:
            return translations.get("modelDownloaderTaskCancelAction", fallback: "Cancel")
        case .retry:
            return translations.get("modelDownloaderTaskRetryAction", fallback: "Retry")
        case .remove:
            return translations.get("modelDownloaderTaskRemoveAction", fallback: "Remove record")
        }
    }

    private func run(_ action: DownloadTaskAction) {
        pendingTask = nil
        Task {
            let error: String?
            switch action {
            case .cancel(let task):
                error = await store.cancelTask(id: task.taskId)
            case .retry(let task):
                error = await store.retryTask(id: task.taskId)
            case .remove(let task):
                error = await store.removeTask(id: task.taskId)
            }
            if let error { actionError = error }
        }
    }
}

struct MacFeaturedModelRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let model: FeaturedModelItem
    let isBusy: Bool
    let onDownload: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.repoID.isEmpty ? model.key : model.repoID)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
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
            Spacer()
            Button {
                onDownload()
            } label: {
                Label(translations.get("modelDownloaderDownloadAction", fallback: "Download"),
                      systemImage: "arrow.down.circle")
            }
            .disabled(isBusy)
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items: [String] = []
        if !model.family.isEmpty { items.append(model.family) }
        if !model.architecture.isEmpty { items.append(model.architecture) }
        if model.weightGB > 0 { items.append(String(format: "%.1f GB", model.weightGB)) }
        if !model.sources.isEmpty { items.append(model.sources.joined(separator: " / ")) }
        return items.joined(separator: " · ")
    }
}

struct MacMarketModelRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let model: MarketModelItem
    let isBusy: Bool
    let onDownload: (String) -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.name.isEmpty ? model.repoID : model.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(model.repoID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(model.sizeFormatted) · ↓ \(model.downloads) · ♥ \(model.likes)")
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
            }
            .disabled(isBusy)
        }
        .padding(.vertical, 2)
    }
}

struct MacDownloadTaskRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let task: DownloadTaskItem
    let onAction: (DownloadTaskAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(task.modelName.isEmpty ? task.repoID : task.modelName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: task.status, color: toneColor)
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
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
            ProgressView(value: min(max(task.progressRatio, 0), 1), total: 1)
                .tint(toneColor)
            Text(progressText)
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

    private var progressText: String {
        var text = String(format: "%.0f%%", task.progressRatio * 100)
        if task.totalSize > 0 {
            text += " · \(VMFormatting.bytes(task.downloadedSize)) / \(VMFormatting.bytes(task.totalSize))"
        }
        return text
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

struct MacDownloadedModelRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let model: DownloadedModelItem
    let isBusy: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            .help(translations.get("modelDownloaderLocalDeleteAction", fallback: "Delete"))
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items: [String] = []
        if !model.sizeFormatted.isEmpty { items.append(model.sizeFormatted) }
        if !model.source.isEmpty { items.append(model.source) }
        if !model.downloadType.isEmpty { items.append(model.downloadType) }
        return items.joined(separator: " · ")
    }
}