import SwiftUI

struct FirewallView: View {
    @StateObject private var viewModel = FirewallViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.rules.isEmpty {
                Text("No firewall rules found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.rules) {
                    TableColumn(translations.get("firewall_port", fallback: "Port/IP")) { rule in
                        HStack {
                            Image(systemName: "network.badge.shield.half.filled")
                                .foregroundColor(.blue)
                            Text(rule.port)
                        }
                        .contextMenu {
                            Button(action: {
                                Task {
                                    await viewModel.deleteRule(id: rule.originalId)
                                }
                            }) {
                                Text(translations.get("delete", fallback: "Delete"))
                                Image(systemName: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("firewall_protocol", fallback: "Protocol")) { rule in
                        Text(rule.protocolType)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("firewall_action", fallback: "Action")) { rule in
                        let isAllow = rule.action.lowercased() == "allow" || rule.action.lowercased() == "accept"
                        Text(rule.action)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isAllow ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .foregroundColor(isAllow ? .green : .red)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
            }
        }
        .navigationTitle(translations.get("navFirewall", fallback: "Firewall"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchRules()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchRules()
        }
    }
}