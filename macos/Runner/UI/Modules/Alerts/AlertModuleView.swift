import AppleSharedUI
import SwiftUI

/// macOS 告警中心：任务、日志、渠道三个分区。
struct AlertModuleView: View {
    @StateObject private var store = AlertStore(
        channel: MacOSDataChannel(channelManager: .shared)
    )
    @EnvironmentObject private var translations: TranslationsManager

    @State private var section = AlertStore.Section(
        rawValue: ProcessInfo.processInfo.environment["ONEPANEL_ALERT_TAB"] ?? ""
    ) ?? .rules
    @State private var ruleStatus = "all"
    @State private var ruleType = "all"
    @State private var logStatus = "all"
    @State private var ruleEditor: AlertRuleEditor?
    @State private var channelEditor: AlertChannelEditor?
    @State private var rulePending: AlertRulePending?
    @State private var channelPending: AlertChannelPending?
    @State private var showCleanConfirm = false
    @State private var actionError: String?

    var body: some View {
        VStack(spacing: 0) {
            switch section {
            case .rules:
                rulesContent
            case .logs:
                logsContent
            case .channels:
                channelsContent
            }
        }
        .navigationTitle(translations.get("alertPageTitle", fallback: "Alert Center"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("", selection: $section) {
                    ForEach(AlertStore.Section.allCases) { item in
                        Text(sectionTitle(item)).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            ToolbarItem(placement: .automatic) {
                if section == .rules {
                    Button {
                        ruleEditor = AlertRuleEditor()
                    } label: {
                        Label(translations.get("alertRuleCreateAction", fallback: "Create Alert"),
                              systemImage: "plus")
                    }
                } else if section == .channels {
                    Button {
                        channelEditor = AlertChannelEditor()
                    } label: {
                        Label(translations.get("alertChannelCreateAction", fallback: "New Channel"),
                              systemImage: "plus")
                    }
                }
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
        .sheet(item: $ruleEditor) { editor in
            AlertRuleFormView(store: store, editor: editor)
        }
        .sheet(item: $channelEditor) { editor in
            AlertChannelFormView(store: store, editor: editor)
        }
        .confirmationDialog(
            rulePendingTitle,
            isPresented: Binding(
                get: { rulePending != nil },
                set: { if !$0 { rulePending = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pending = rulePending {
                Button(rulePendingButton(pending),
                       role: pending.isDestructive ? .destructive : nil) {
                    run(pending)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    rulePending = nil
                }
            }
        } message: {
            Text(rulePendingMessage)
        }
        .confirmationDialog(
            channelPendingTitle,
            isPresented: Binding(
                get: { channelPending != nil },
                set: { if !$0 { channelPending = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pending = channelPending {
                Button(channelPendingButton(pending),
                       role: pending.isDestructive ? .destructive : nil) {
                    runChannel(pending)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    channelPending = nil
                }
            }
        } message: {
            Text(channelPendingMessage)
        }
        .confirmationDialog(
            translations.get("alertLogCleanAction", fallback: "Clear logs"),
            isPresented: $showCleanConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("alertLogCleanAction", fallback: "Clear logs"),
                   role: .destructive) {
                Task {
                    if let error = await store.cleanLogs() {
                        actionError = error
                    }
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("alertLogCleanConfirm", fallback: "Clear all alert logs?"))
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

    private var rulesContent: some View {
        Group {
            if store.isLoading && store.rules.isEmpty {
                LoadingView()
            } else if store.rulesError != nil && store.rules.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await store.loadRules(type: nil, status: nil) }
                }
            } else if store.rules.isEmpty {
                EmptyStateView(
                    icon: "bell.badge",
                    message: translations.get("alertRuleEmptyTitle", fallback: "No alert rules"),
                    description: translations.get("alertRuleEmptyDescription",
                                                 fallback: "Create an alert rule to start monitoring")
                )
            } else {
                List {
                    Section {
                        HStack(spacing: 12) {
                            Menu {
                                Button(translations.get("alertRuleFilterAllStatuses", fallback: "All statuses")) {
                                    ruleStatus = "all"
                                    Task { await store.loadRules(type: ruleTypeFilter, status: nil) }
                                }
                                Button(translations.get("alertRuleStatusEnable", fallback: "Enabled")) {
                                    ruleStatus = "Enable"
                                    Task { await store.loadRules(type: ruleTypeFilter, status: "Enable") }
                                }
                                Button(translations.get("alertRuleStatusDisable", fallback: "Disabled")) {
                                    ruleStatus = "Disable"
                                    Task { await store.loadRules(type: ruleTypeFilter, status: "Disable") }
                                }
                            } label: {
                                Label(ruleStatusLabel, systemImage: "power")
                            }
                            Menu {
                                Button(translations.get("alertRuleFilterAllTypes", fallback: "All types")) {
                                    ruleType = "all"
                                    Task { await store.loadRules(type: nil, status: ruleStatusFilter) }
                                }
                                ForEach(store.options.ruleTypes) { option in
                                    Button(AlertLabels.ruleType(option.type, translations: translations)) {
                                        ruleType = option.type
                                        Task { await store.loadRules(type: option.type, status: ruleStatusFilter) }
                                    }
                                }
                            } label: {
                                Label(ruleTypeLabel, systemImage: "tag")
                            }
                            Spacer()
                            Text("\(store.ruleTotal)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    if let error = store.rulesError {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section {
                        ForEach(store.rules) { rule in
                            MacAlertRuleRow(rule: rule) { enable in
                                rulePending = .toggle(rule, enable)
                            }
                            .contextMenu {
                                Button {
                                    ruleEditor = AlertRuleEditor(rule: rule)
                                } label: {
                                    Label(translations.get("commonEdit", fallback: "Edit"),
                                          systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    rulePending = .delete(rule)
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.loadRules(type: ruleTypeFilter, status: ruleStatusFilter)
                }
            }
        }
    }

    private var logsContent: some View {
        Group {
            if store.isLoading && store.logs.isEmpty {
                LoadingView()
            } else if store.logsError != nil && store.logs.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await store.loadLogs(status: nil) }
                }
            } else if store.logs.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("alertLogEmptyTitle", fallback: "No alert logs"),
                    description: translations.get("alertLogEmptyDescription",
                                                 fallback: "Triggered alerts appear here")
                )
            } else {
                List {
                    Section {
                        HStack {
                            Menu {
                                Button(translations.get("alertLogFilterAllStatuses", fallback: "All statuses")) {
                                    logStatus = "all"
                                    Task { await store.loadLogs(status: nil) }
                                }
                                Button(translations.get("alertLogStatusSuccess", fallback: "Success")) {
                                    logStatus = "Success"
                                    Task { await store.loadLogs(status: "Success") }
                                }
                                Button(translations.get("alertLogStatusError", fallback: "Error")) {
                                    logStatus = "Error"
                                    Task { await store.loadLogs(status: "Error") }
                                }
                            } label: {
                                Label(alertLogStatusLabel(logStatus), systemImage: "line.3.horizontal.decrease.circle")
                            }
                            Spacer()
                            Button(role: .destructive) {
                                showCleanConfirm = true
                            } label: {
                                Label(translations.get("alertLogCleanAction", fallback: "Clear logs"),
                                      systemImage: "trash")
                            }
                            .disabled(store.isBusy)
                        }
                    }
                    if let error = store.logsError {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section {
                        ForEach(store.logs) { log in
                            MacAlertLogRow(log: log)
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.loadLogs(status: logStatusFilter)
                }
            }
        }
    }

    private var channelsContent: some View {
        Group {
            if store.isLoading && store.channels.isEmpty {
                LoadingView()
            } else if store.channelsError != nil && store.channels.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await store.loadChannels() }
                }
            } else if store.channels.isEmpty {
                EmptyStateView(
                    icon: "envelope.badge",
                    message: translations.get("alertChannelEmptyTitle", fallback: "No channels"),
                    description: translations.get("alertChannelEmptyDescription",
                                                 fallback: "Add a notification channel to receive alerts")
                )
            } else {
                List {
                    if let error = store.channelsError {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section {
                        ForEach(store.channels) { channel in
                            MacAlertChannelRow(channel: channel) { enable in
                                channelPending = .toggle(channel, enable)
                            }
                            .contextMenu {
                                Button {
                                    channelEditor = AlertChannelEditor(channel: channel)
                                } label: {
                                    Label(translations.get("commonEdit", fallback: "Edit"),
                                          systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    channelPending = .delete(channel)
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.loadChannels()
                }
            }
        }
    }

    private var ruleStatusFilter: String? {
        ruleStatus == "all" ? nil : ruleStatus
    }

    private var ruleTypeFilter: String? {
        ruleType == "all" ? nil : ruleType
    }

    private var logStatusFilter: String? {
        logStatus == "all" ? nil : logStatus
    }

    private var ruleStatusLabel: String {
        switch ruleStatus {
        case "Enable": return translations.get("alertRuleStatusEnable", fallback: "Enabled")
        case "Disable": return translations.get("alertRuleStatusDisable", fallback: "Disabled")
        default: return translations.get("alertRuleFilterAllStatuses", fallback: "All statuses")
        }
    }

    private var ruleTypeLabel: String {
        ruleType == "all"
            ? translations.get("alertRuleFilterAllTypes", fallback: "All types")
            : AlertLabels.ruleType(ruleType, translations: translations)
    }

    private func alertLogStatusLabel(_ value: String) -> String {
        switch value {
        case "Success": return translations.get("alertLogStatusSuccess", fallback: "Success")
        case "Error": return translations.get("alertLogStatusError", fallback: "Error")
        default: return translations.get("alertLogFilterAllStatuses", fallback: "All statuses")
        }
    }

    private func refresh() async {
        switch section {
        case .rules:
            await store.loadRules(type: ruleTypeFilter, status: ruleStatusFilter)
        case .logs:
            await store.loadLogs(status: logStatusFilter)
        case .channels:
            await store.loadChannels()
        }
    }

    private func sectionTitle(_ section: AlertStore.Section) -> String {
        switch section {
        case .rules:
            return translations.get("alertTabRules", fallback: "Alert Rules")
        case .logs:
            return translations.get("alertTabLogs", fallback: "Alert Logs")
        case .channels:
            return translations.get("alertTabChannels", fallback: "Channels")
        }
    }

    private var rulePendingTitle: String {
        guard let pending = rulePending else { return "" }
        switch pending {
        case .toggle(_, let enable):
            return enable
                ? translations.get("alertRuleStatusEnable", fallback: "Enabled")
                : translations.get("alertRuleStatusDisable", fallback: "Disabled")
        case .delete:
            return translations.get("commonDelete", fallback: "Delete")
        }
    }

    private var rulePendingMessage: String {
        guard let pending = rulePending else { return "" }
        switch pending {
        case .toggle(let rule, let enable):
            let action = enable
                ? translations.get("alertRuleStatusEnable", fallback: "Enabled")
                : translations.get("alertRuleStatusDisable", fallback: "Disabled")
            return translations.get("alertRuleToggleConfirm",
                                    fallback: "Change the status of {0}?")
                .replacingOccurrences(of: "{0}", with: rule.title)
                .replacingOccurrences(of: "{name}", with: rule.title)
                .replacingOccurrences(of: "{action}", with: action)
        case .delete(let rule):
            return translations.get("alertRuleDeleteConfirm",
                                    fallback: "Delete alert rule {0}?")
                .replacingOccurrences(of: "{0}", with: rule.title)
                .replacingOccurrences(of: "{name}", with: rule.title)
                .replacingOccurrences(of: "{title}", with: rule.title)
        }
    }

    private func rulePendingButton(_ pending: AlertRulePending) -> String {
        switch pending {
        case .toggle(_, let enable):
            return enable
                ? translations.get("alertRuleStatusEnable", fallback: "Enabled")
                : translations.get("alertRuleStatusDisable", fallback: "Disabled")
        case .delete:
            return translations.get("commonDelete", fallback: "Delete")
        }
    }

    private func run(_ pending: AlertRulePending) {
        rulePending = nil
        Task {
            switch pending {
            case .toggle(let rule, let enable):
                if let error = await store.toggleRule(id: rule.ruleId, enable: enable) {
                    actionError = error
                }
            case .delete(let rule):
                if let error = await store.deleteRule(id: rule.ruleId) {
                    actionError = error
                }
            }
        }
    }

    private var channelPendingTitle: String {
        guard let pending = channelPending else { return "" }
        switch pending {
        case .toggle(_, let enable):
            return enable
                ? translations.get("alertChannelEnabledLabel", fallback: "Channel enabled")
                : translations.get("alertChannelDisabledLabel", fallback: "Channel disabled")
        case .delete:
            return translations.get("commonDelete", fallback: "Delete")
        }
    }

    private var channelPendingMessage: String {
        guard let pending = channelPending else { return "" }
        switch pending {
        case .toggle(let channel, _):
            return channel.title
        case .delete(let channel):
            return translations.get("alertChannelDeleteConfirm",
                                    fallback: "Delete channel {0}?")
                .replacingOccurrences(of: "{0}", with: channel.title)
                .replacingOccurrences(of: "{name}", with: channel.title)
                .replacingOccurrences(of: "{title}", with: channel.title)
        }
    }

    private func channelPendingButton(_ pending: AlertChannelPending) -> String {
        switch pending {
        case .toggle(_, let enable):
            return enable
                ? translations.get("alertChannelEnabledLabel", fallback: "Enable")
                : translations.get("alertChannelDisabledLabel", fallback: "Disable")
        case .delete:
            return translations.get("commonDelete", fallback: "Delete")
        }
    }

    private func runChannel(_ pending: AlertChannelPending) {
        channelPending = nil
        Task {
            switch pending {
            case .toggle(let channel, let enable):
                if let error = await store.toggleChannel(id: channel.channelId, enable: enable) {
                    actionError = error
                }
            case .delete(let channel):
                if let error = await store.deleteChannel(id: channel.channelId) {
                    actionError = error
                }
            }
        }
    }
}

enum AlertRulePending: Identifiable {
    case toggle(AlertRuleModel, Bool)
    case delete(AlertRuleModel)

    var id: String {
        switch self {
        case .toggle(let rule, let enable): return "toggle-\(rule.id)-\(enable)"
        case .delete(let rule): return "delete-\(rule.id)"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .toggle: return false
        case .delete: return true
        }
    }
}

enum AlertChannelPending: Identifiable {
    case toggle(AlertChannelModel, Bool)
    case delete(AlertChannelModel)

    var id: String {
        switch self {
        case .toggle(let channel, let enable): return "toggle-\(channel.id)-\(enable)"
        case .delete(let channel): return "delete-\(channel.id)"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .toggle: return false
        case .delete: return true
        }
    }
}

struct MacAlertRuleRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let rule: AlertRuleModel
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(rule.title.isEmpty
                         ? AlertLabels.ruleType(rule.type, translations: translations)
                         : rule.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    StatusBadge(text: rule.status, color: alertToneColor(rule.statusTone))
                }
                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .accessibilityLabel(rule.title)
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items = [AlertLabels.ruleType(rule.type, translations: translations)]
        if !rule.sendMethod.isEmpty {
            items.append(rule.sendMethod.joined(separator: " / "))
        }
        if rule.cycle > 0 {
            items.append("\(translations.get("alertRuleCycleDaysLabel", fallback: "Days")) \(rule.cycle)")
        }
        return items.joined(separator: " · ")
    }
}

struct MacAlertLogRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let log: AlertLogModel

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(log.title.isEmpty
                     ? AlertLabels.ruleType(log.type, translations: translations)
                     : log.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: log.status, color: alertToneColor(log.statusTone))
            }
            if !log.message.isEmpty {
                Text(log.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(metadata)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items: [String] = []
        if !log.method.isEmpty { items.append(log.method) }
        if log.count > 0 { items.append("×\(log.count)") }
        if !log.createdAt.isEmpty { items.append(log.createdAt) }
        return items.joined(separator: " · ")
    }
}

struct MacAlertChannelRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let channel: AlertChannelModel
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(channel.title.isEmpty
                         ? AlertLabels.channelType(channel.type, translations: translations)
                         : channel.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    StatusBadge(text: channel.status, color: alertToneColor(channel.statusTone))
                }
                Text(AlertLabels.channelType(channel.type, translations: translations))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !channel.configSummary.isEmpty {
                    Text(channel.configSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { channel.enabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .accessibilityLabel(channel.title)
        }
        .padding(.vertical, 2)
    }
}

private func alertToneColor(_ tone: String) -> Color {
    switch tone {
    case "positive": return .green
    case "warning": return .orange
    case "negative": return .red
    case "info": return .blue
    default: return .secondary
    }
}