import SwiftUI

/// 防火墙端口规则表单：端口、协议、来源地址与策略。
struct FirewallAddSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FirewallViewModel

    @State private var port = ""
    @State private var protocolName = "tcp"
    @State private var address = ""
    @State private var strategy = "accept"
    @State private var isSaving = false
    @State private var errorText: String?

    private var canSave: Bool {
        !port.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("firewallPortLabel", fallback: "Port"), text: $port)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker(translations.get("firewallProtocolLabel", fallback: "Protocol"), selection: $protocolName) {
                        Text("TCP").tag("tcp")
                        Text("UDP").tag("udp")
                    }
                    TextField(translations.get("firewallAddressLabel", fallback: "Address"), text: $address)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker(translations.get("firewallStrategyLabel", fallback: "Strategy"), selection: $strategy) {
                        Text(translations.get("firewallStrategyAccept", fallback: "Accept")).tag("accept")
                        Text(translations.get("firewallStrategyDrop", fallback: "Drop")).tag("drop")
                    }
                } footer: {
                    if let errorText {
                        Text(errorText)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(translations.get("firewallCreatePortRuleAction", fallback: "Create Port Rule"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(translations.get("commonSave", fallback: "Save")) { save() }
                            .disabled(!canSave)
                    }
                }
            }
        }
    }

    private func save() {
        errorText = nil
        isSaving = true
        viewModel.addRule(
            port: port.trimmingCharacters(in: .whitespaces),
            protocolName: protocolName,
            address: address.trimmingCharacters(in: .whitespaces),
            strategy: strategy
        ) { success, error in
            isSaving = false
            if success {
                viewModel.fetch()
                dismiss()
            } else {
                let template = translations.get("appOperateFailed", fallback: "Operation failed: {error}")
                errorText = template.replacingOccurrences(of: "{error}", with: error ?? "")
            }
        }
    }
}