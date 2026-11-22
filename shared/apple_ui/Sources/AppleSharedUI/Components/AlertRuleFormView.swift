import SwiftUI

/// 告警任务表单的呈现载荷：新建时 rule 为空。
public struct AlertRuleEditor: Identifiable {
    public let id = UUID()
    public let rule: AlertRuleModel?

    public init(rule: AlertRuleModel? = nil) {
        self.rule = rule
    }
}

/// 告警任务创建/编辑表单，两端共用。
public struct AlertRuleFormView: View {
    @ObservedObject private var store: AlertStore
    private let editor: AlertRuleEditor

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var title: String
    @State private var type: String
    @State private var cycle: String
    @State private var threshold: String
    @State private var sendCount: String
    @State private var advancedParams: String
    @State private var interval: Int
    @State private var methods: Set<String>
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: AlertStore, editor: AlertRuleEditor = AlertRuleEditor()) {
        self.store = store
        self.editor = editor
        let rule = editor.rule
        _title = State(initialValue: rule?.title ?? "")
        _type = State(initialValue: rule?.type ?? "cpu")
        _cycle = State(initialValue: "\(rule?.cycle ?? 30)")
        _threshold = State(initialValue: "\(rule?.count ?? 80)")
        _sendCount = State(initialValue: "\(rule?.sendCount ?? 1)")
        _advancedParams = State(initialValue: rule?.advancedParams ?? "")
        _interval = State(initialValue: rule.map { $0.interval <= 0 ? 1 : $0.interval } ?? 1)
        _methods = State(initialValue: Set(rule?.sendMethod ?? []))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(t("alertRuleTitleLabel", "Title"), text: $title)
                    Picker(t("alertRuleTypeLabel", "Type"), selection: $type) {
                        ForEach(store.options.ruleTypes) { option in
                            Text(AlertLabels.ruleType(option.type, translations: translations)).tag(option.type)
                        }
                    }
                }

                if let option = store.options.ruleType(type) {
                    if option.needsCycleDays {
                        Section {
                            TextField(t("alertRuleCycleDaysLabel", "Remaining days"),
                                      text: $cycle)
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                        }
                    }
                    if option.needsThreshold {
                        Section {
                            TextField(t("alertRuleThresholdLabel", "Threshold"),
                                      text: $threshold)
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                        }
                    }
                    if option.needsInterval {
                        Section {
                            Picker(t("alertRuleIntervalLabel", "Interval"),
                                   selection: $interval) {
                                Text(t("alertRuleIntervalMinute1", "1 minute")).tag(1)
                                Text(t("alertRuleIntervalMinute5", "5 minutes")).tag(5)
                                Text(t("alertRuleIntervalMinute15", "15 minutes")).tag(15)
                            }
                        }
                    }
                }

                Section {
                    TextField(t("alertRuleSendCountLabel", "Send count"), text: $sendCount)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }

                Section(t("alertRuleMethodsLabel", "Notification channels")) {
                    if store.channels.isEmpty {
                        Text(t("alertRuleMethodsEmpty", "Create a notification channel first"))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.channels) { channel in
                        Toggle(channel.title.isEmpty ? channel.type : channel.title,
                               isOn: binding(for: channel)) 
                            .disabled(!channel.enabled)
                    }
                }

                Section {
                    TextField(t("alertRuleAdvancedParamsLabel", "Advanced parameters"),
                              text: $advancedParams, axis: .vertical)
                        .lineLimit(3...6)
                } footer: {
                    Text(t("alertRuleAdvancedParamsHint",
                           "Optional parameters passed to the alert runner"))
                        .font(.caption)
                }
            }
            .navigationTitle(editor.rule == nil
                             ? t("alertRuleCreateAction", "Create Alert")
                             : t("commonEdit", "Edit"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("commonSave", "Save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .task {
                if store.options.ruleTypes.isEmpty {
                    await store.loadOptions()
                }
                if store.channels.isEmpty {
                    await store.loadChannels()
                }
                if methods.isEmpty, let first = store.enabledChannels.first {
                    methods.insert(first.title)
                }
            }
            .alert(
                t("commonError", "Error"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(t("commonOk", "OK"), role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 520, minHeight: 620)
            #endif
        }
    }

    private func binding(for channel: AlertChannelModel) -> Binding<Bool> {
        Binding(
            get: { methods.contains(channel.title) },
            set: { include in
                if include { methods.insert(channel.title) } else { methods.remove(channel.title) }
            }
        )
    }

    private func save() async {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !methods.isEmpty else { return }
        isSaving = true
        var arguments: [String: Any] = [
            "type": type,
            "title": name,
            "methods": Array(methods),
            "sendCount": Int(sendCount.trimmingCharacters(in: .whitespaces)) ?? 1,
            "advancedParams": advancedParams.trimmingCharacters(in: .whitespacesAndNewlines),
            "cycle": Int(cycle.trimmingCharacters(in: .whitespaces)) ?? 30,
            "count": Int(threshold.trimmingCharacters(in: .whitespaces)) ?? 80,
            "interval": interval,
        ]
        if let rule = editor.rule {
            arguments["id"] = rule.ruleId
            arguments["status"] = rule.status
        }
        let error = editor.rule == nil
            ? await store.createRule(arguments)
            : await store.updateRule(arguments)
        isSaving = false
        if let error {
            errorMessage = error
        } else {
            dismiss()
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}