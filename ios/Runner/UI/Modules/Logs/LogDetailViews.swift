import AppleSharedUI
import SwiftUI

/// 操作日志详情：请求路径、方法、来源、地址、状态与消息。
struct OperationLogDetailView: View {
    let log: OperationLogRow
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(translations.get("logsOperationDetailTitle",
                                         fallback: "Operation Log Details")) {
                    HStack {
                        Text(log.path.isEmpty ? "--" : log.path)
                            .font(.subheadline.weight(.medium))
                            .textSelection(.enabled)
                        Spacer()
                        if !log.status.isEmpty {
                            StatusBadge(text: log.status, color: .gray)
                        }
                    }
                    InfoLine(label: translations.get("logsOperationPathLabel",
                                                     fallback: "Request path"),
                             value: log.path.isEmpty ? "--" : log.path)
                    InfoLine(label: translations.get("logsOperationActionLabel",
                                                     fallback: "Method"),
                             value: log.method.isEmpty ? "--" : log.method)
                    InfoLine(label: translations.get("logsOperationSourceLabel",
                                                     fallback: "Source"),
                             value: log.source.isEmpty ? "--" : log.source)
                    InfoLine(label: translations.get("logsLoginIpLabel", fallback: "IP"),
                             value: log.ip.isEmpty ? "--" : log.ip)
                    InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                             value: log.status.isEmpty ? "--" : log.status)
                }
                Section(translations.get("logsDetailMessageLabel", fallback: "Message")) {
                    Text(log.message.isEmpty ? "--" : log.message)
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(translations.get("logsOperationDetailTitle",
                                              fallback: "Operation Log Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonClose", fallback: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 登录日志详情：地址、归属、状态、时间与消息。
struct LoginLogDetailView: View {
    let log: LoginLogRow
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(translations.get("logsLoginDetailTitle",
                                         fallback: "Login Log Details")) {
                    HStack {
                        Text(log.ip.isEmpty ? "--" : log.ip)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if !log.status.isEmpty {
                            StatusBadge(
                                text: log.status,
                                color: StatusPalette.cronjobStatus(log.status)
                            )
                        }
                    }
                    InfoLine(label: translations.get("logsLoginIpLabel", fallback: "IP"),
                             value: log.ip.isEmpty ? "--" : log.ip)
                    InfoLine(label: translations.get("logsSystemSourceLabel",
                                                     fallback: "Source"),
                             value: log.address.isEmpty ? "--" : log.address)
                    InfoLine(label: translations.get("logsTaskDetailCreatedAtLabel",
                                                     fallback: "Created"),
                             value: log.createdAt.isEmpty
                                 ? "--"
                                 : TimestampFormat.display(log.createdAt))
                    InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                             value: log.status.isEmpty ? "--" : log.status)
                }
                Section(translations.get("logsDetailMessageLabel", fallback: "Message")) {
                    Text(log.message.isEmpty ? "--" : log.message)
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(translations.get("logsLoginDetailTitle",
                                              fallback: "Login Log Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonClose", fallback: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}