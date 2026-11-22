import SwiftUI

/// 通知渠道表单的呈现载荷：新建时 channel 为空。
public struct AlertChannelEditor: Identifiable {
    public let id = UUID()
    public let channel: AlertChannelModel?

    public init(channel: AlertChannelModel? = nil) {
        self.channel = channel
    }
}

struct AlertPair: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
}

/// 通知渠道创建/编辑表单，两端共用。
///
/// 密钥字段采用保留、替换、清除三态；支持服务端测试的渠道必须先测试通过。
public struct AlertChannelFormView: View {
    @ObservedObject private var store: AlertStore
    private let editor: AlertChannelEditor

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var type: String
    @State private var title: String
    @State private var status: String
    @State private var sender = ""
    @State private var userName = ""
    @State private var password = ""
    @State private var passwordAction = "keep"
    @State private var host = ""
    @State private var port = "465"
    @State private var encryption = "NONE"
    @State private var recipient = ""
    @State private var webhookUrl = ""
    @State private var preset = "genericJson"
    @State private var bodyType = "json"
    @State private var template = ""
    @State private var headers: [AlertPair] = []
    @State private var formPairs: [AlertPair] = []
    @State private var isSaving = false
    @State private var isTesting = false
    @State private var testPassed: Bool
    @State private var testMessage: String?
    @State private var errorMessage: String?

    public init(store: AlertStore, editor: AlertChannelEditor = AlertChannelEditor()) {
        self.store = store
        self.editor = editor
        let channel = editor.channel
        _type = State(initialValue: channel?.type ?? "email")
        _title = State(initialValue: channel?.title ?? "channel-\(Int(Date().timeIntervalSince1970))")
        _status = State(initialValue: channel?.status ?? "Enable")
        _testPassed = State(initialValue: channel != nil)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    if editor.channel == nil {
                        Picker(t("alertRuleTypeLabel", "Type"), selection: $type) {
                            ForEach(store.options.channelTypes) { option in
                                Text(AlertLabels.channelType(option.type, translations: translations)).tag(option.type)
                            }
                        }
                        .onChange(of: type) { _ in
                            testPassed = false
                            testMessage = nil
                        }
                    }
                    TextField(t("alertChannelDisplayNameLabel", "Display name"), text: $title)
                }

                if channelOption?.isEmail == true {
                    emailFields
                }
                if channelOption?.isWebhook == true && channelOption?.isCustom != true {
                    Section {
                        TextField(t("alertChannelWebhookUrlLabel", "Webhook URL"), text: $webhookUrl)
                            .onChange(of: webhookUrl) { _ in resetTest() }
                    }
                }
                if channelOption?.isCustom == true {
                    customWebhookFields
                }

                Section {
                    HStack(spacing: 12) {
                        Button {
                            Task { await test() }
                        } label: {
                            Label(t("alertChannelTestAction", "Test"), systemImage: "paperplane")
                        }
                        .disabled(isTesting || isSaving)
                        if isTesting {
                            ProgressView().controlSize(.small)
                        }
                        if testPassed {
                            Label(t("alertChannelTestSuccess", "Channel test passed"),
                                  systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text(t("alertChannelTestRequired", "Test the channel before saving"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let testMessage {
                        Text(testMessage)
                            .font(.caption)
                            .foregroundStyle(testPassed ? Color.secondary : Color.red)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle(editor.channel == nil
                             ? t("alertChannelCreateAction", "Create Channel")
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
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty
                              || (channelOption?.supportsTest == true && !testPassed))
                }
            }
            .task {
                if store.options.channelTypes.isEmpty {
                    await store.loadOptions()
                }
                if template.isEmpty, let presetTemplate = store.options.preset(preset)?.template {
                    template = presetTemplate
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
            .frame(minWidth: 580, minHeight: 680)
            #endif
        }
    }

    private var emailFields: some View {
        Section(t("alertChannelTypeEmail", "Email")) {
            TextField(t("alertChannelSenderLabel", "Sender"), text: $sender)
                .onChange(of: sender) { _ in resetTest() }
            TextField(t("alertChannelUsernameLabel", "Username"), text: $userName)
                .onChange(of: userName) { _ in resetTest() }
            if editor.channel != nil {
                Picker(t("alertChannelPasswordLabel", "Password"), selection: $passwordAction) {
                    Text(t("alertChannelPasswordKeep", "Keep")).tag("keep")
                    Text(t("alertChannelPasswordReplace", "Replace")).tag("replace")
                    Text(t("alertChannelPasswordClear", "Clear")).tag("clear")
                }
                .pickerStyle(.segmented)
                .onChange(of: passwordAction) { _ in resetTest() }
            }
            if editor.channel == nil || passwordAction == "replace" {
                SecureField(t("alertChannelPasswordLabel", "Password"), text: $password)
                    .onChange(of: password) { _ in resetTest() }
            }
            TextField(t("alertChannelHostLabel", "SMTP host"), text: $host)
                .onChange(of: host) { _ in resetTest() }
            TextField(t("alertChannelPortLabel", "Port"), text: $port)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .onChange(of: port) { _ in resetTest() }
            Picker(t("alertChannelEncryptionLabel", "Encryption"), selection: $encryption) {
                ForEach(store.options.encryptions, id: \.self) { value in
                    Text(AlertLabels.encryption(value, translations: translations)).tag(value)
                }
            }
            .onChange(of: encryption) { _ in resetTest() }
            TextField(t("alertChannelRecipientLabel", "Recipients"), text: $recipient)
                .onChange(of: recipient) { _ in resetTest() }
        }
    }

    private var customWebhookFields: some View {
        Group {
            Section(t("alertChannelTypeCustom", "Custom webhook")) {
                TextField(t("alertChannelWebhookUrlLabel", "Webhook URL"), text: $webhookUrl)
                    .onChange(of: webhookUrl) { _ in resetTest() }
                Picker(t("alertChannelCustomPresetLabel", "Preset"), selection: $preset) {
                    ForEach(store.options.webhookPresets) { item in
                        Text(AlertLabels.preset(item.key, translations: translations)).tag(item.key)
                    }
                }
                .onChange(of: preset) { value in
                    if let presetTemplate = store.options.preset(value)?.template {
                        template = presetTemplate
                    }
                    resetTest()
                }
                Picker(t("alertChannelCustomBodyTypeLabel", "Body type"), selection: $bodyType) {
                    Text(t("alertChannelCustomBodyJson", "JSON")).tag("json")
                    Text(t("alertChannelCustomBodyForm", "Form")).tag("form")
                    Text(t("alertChannelCustomBodyText", "Text")).tag("text")
                }
                .pickerStyle(.segmented)
                .onChange(of: bodyType) { _ in resetTest() }
            }

            if bodyType == "form" {
                Section(t("alertChannelCustomFormPairLabel", "Form fields")) {
                    AlertPairEditor(
                        pairs: $formPairs,
                        keyLabel: t("alertChannelCustomHeaderKeyLabel", "Key"),
                        valueLabel: t("alertChannelCustomHeaderValueLabel", "Value"),
                        addLabel: t("alertChannelCustomAddPairAction", "Add field"),
                        onChange: resetTest
                    )
                }
            } else {
                Section(t("alertChannelCustomTemplateLabel", "Body template")) {
                    TextEditor(text: $template)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 160)
                        .onChange(of: template) { _ in resetTest() }
                }
            }

            Section(t("alertChannelCustomHeadersLabel", "Custom headers")) {
                AlertPairEditor(
                    pairs: $headers,
                    keyLabel: t("alertChannelCustomHeaderKeyLabel", "Key"),
                    valueLabel: t("alertChannelCustomHeaderValueLabel", "Value"),
                    addLabel: t("alertChannelCustomAddHeaderAction", "Add header"),
                    onChange: resetTest
                )
            }
        }
    }

    private var channelOption: AlertChannelTypeOption? {
        store.options.channelType(type)
    }

    private func resetTest() {
        testPassed = editor.channel != nil
        testMessage = nil
    }

    private func arguments() -> [String: Any] {
        var values: [String: Any] = [
            "type": type,
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "status": status,
            "sender": sender.trimmingCharacters(in: .whitespacesAndNewlines),
            "userName": userName.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
            "host": host.trimmingCharacters(in: .whitespacesAndNewlines),
            "port": Int(port.trimmingCharacters(in: .whitespaces)) ?? 465,
            "encryption": encryption,
            "recipient": recipient.trimmingCharacters(in: .whitespacesAndNewlines),
            "webhookUrl": webhookUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            "preset": preset,
            "bodyType": bodyType,
            "template": template,
            "headers": headers.map { ["key": $0.key, "value": $0.value] },
            "formPairs": formPairs.map { ["key": $0.key, "value": $0.value] },
        ]
        if let channel = editor.channel {
            values["id"] = channel.channelId
            values["passwordAction"] = passwordAction
        }
        return values
    }

    private func save() async {
        isSaving = true
        let error = await store.saveChannel(arguments())
        isSaving = false
        if let error {
            errorMessage = error
        } else {
            dismiss()
        }
    }

    private func test() async {
        isTesting = true
        let result = await store.testChannel(arguments())
        isTesting = false
        testPassed = result.success
        testMessage = result.message.isEmpty ? result.response : result.message
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}

/// Header 与 Form 键值对编辑器。
struct AlertPairEditor: View {
    @Binding var pairs: [AlertPair]
    let keyLabel: String
    let valueLabel: String
    let addLabel: String
    let onChange: () -> Void

    var body: some View {
        ForEach($pairs) { $pair in
            HStack {
                TextField(keyLabel, text: $pair.key)
                    .onChange(of: pair.key) { _ in onChange() }
                TextField(valueLabel, text: $pair.value)
                    .onChange(of: pair.value) { _ in onChange() }
                Button(role: .destructive) {
                    pairs.removeAll { $0.id == pair.id }
                    onChange()
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
            }
        }
        Button {
            pairs.append(AlertPair(key: "", value: ""))
        } label: {
            Label(addLabel, systemImage: "plus")
        }
    }
}