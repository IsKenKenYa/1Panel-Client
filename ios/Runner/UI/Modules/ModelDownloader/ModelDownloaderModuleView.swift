import AppleSharedUI
import SwiftUI

/// iOS 模型下载器：推荐、市场搜索、下载任务与本地模型四个分区。
struct ModelDownloaderModuleView: View {
    @StateObject private var store = ModelDownloaderStore(
        channel: IOSDataChannel(channelManager: .shared)
    )
    @EnvironmentObject private var translations: TranslationsManager

    /// 走查钩子：`ONEPANEL_DOWNLOADER_TAB=featured|search|tasks|local`。
    @State private var section = ModelDownloaderStore.Section(
        rawValue: ProcessInfo.processInfo.environment["ONEPANEL_DOWNLOADER_TAB"] ?? ""
    ) ?? .featured
    @State private var featuredFamily = ""
    @State private var searchText = ""
    @State private var taskStatus = "all"
    @State private var showSettings = false
    @State private var pendingTask: DownloadTaskAction?
    @State private var pendingLocal: DownloadedModelItem?
    @State private var toastText: String?
    @State private var hasSearched = false

    var body: some View {
        Group {
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(ModelDownloaderStore.Section.allCases) { item in
                        Button {
                            section = item
                        } label: {
                            if item == section {
                                Label(sectionTitle(item), systemImage: "checkmark")
                            } else {
                                Text(sectionTitle(item))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sectionTitle(section))
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                }
                .accessibilityIdentifier("downloader-section-menu")
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Label(translations.get("modelDownloaderSettingsAction",
                                            fallback: "Download settings"),
                          systemImage: "gearshape")
                }
                Button {
                    Task { await refresh() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                ModuleSwitcherMenu(current: .modelDownloader)
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
        .operationNotice(toastText)
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
                                    let error = await store.syncFeatured()
                                    showToast(error == nil
                                        ? translations.get("commonOperationSuccess",
                                                           fallback: "Operation succeeded")
                                        : error!)
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
                            FeaturedModelRow(model: model, isBusy: store.isBusy) {
                                Task { await downloadFeatured(model) }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
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
                                MarketModelRow(model: model, isBusy: store.isBusy) { downloadType in
                                    Task { await downloadMarket(model, downloadType: downloadType) }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await runSearch()
                    }
                }
            }
        }
        .task {
            guard !hasSearched else { return }
            hasSearched = true
            await runSearch()
        }
    }

    private var searchHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField(translations.get("modelDownloaderSearchHint",
                                           fallback: "Enter a model name or repository ID"),
                          text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
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
                            DownloadTaskRow(task: task) { action in
                                pendingTask = action
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
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
                            DownloadedModelRow(model: model, isBusy: store.isBusy) {
                                pendingLocal = model
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
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
        let error = await store.downloadFeatured(model)
        showToast(error == nil
            ? translations.get("modelDownloaderDownloadStarted", fallback: "Download task submitted")
            : error!)
    }

    private func downloadMarket(_ model: MarketModelItem, downloadType: String) async {
        let error = await store.downloadModel(
            repoID: model.repoID,
            source: store.searchSource,
            downloadType: downloadType
        )
        showToast(error == nil
            ? translations.get("modelDownloaderDownloadStarted", fallback: "Download task submitted")
            : error!)
    }

    private func deleteLocal(_ model: DownloadedModelItem, withFile: Bool) {
        pendingLocal = nil
        Task {
            let error = await store.deleteLocalModel(
                name: model.name.isEmpty ? model.repoID : model.name,
                downloadType: model.downloadType,
                withFile: withFile
            )
            showToast(error == nil
                ? translations.get("commonDeleted", fallback: "Deleted")
                : error!)
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
            showToast(error == nil
                ? translations.get("commonOperationSuccess", fallback: "Operation succeeded")
                : error!)
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