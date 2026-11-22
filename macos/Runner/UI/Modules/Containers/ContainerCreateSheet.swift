import AppleSharedUI
import SwiftUI

/// 新建容器表单：镜像、名称、端口、环境变量、存储卷与重启策略。
struct ContainerCreateSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var image = ""
    @State private var name = ""
    @State private var portsText = ""
    @State private var envText = ""
    @State private var volumesText = ""
    @State private var restartPolicy = "unless-stopped"
    @State private var autoRemove = false
    @State private var privileged = false
    @State private var publishAllPorts = false
    @State private var submitting = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(t("containerImage", "Image"), text: $image)
                    TextField(t("commonName", "Name"), text: $name)
                    Picker(t("containerCreateRestartLabel", "Restart policy"),
                           selection: $restartPolicy) {
                        Text("no").tag("no")
                        Text("always").tag("always")
                        Text("unless-stopped").tag("unless-stopped")
                        Text("on-failure").tag("on-failure")
                    }
                } header: {
                    Text(t("containerCreateBasicSectionTitle", "Basic"))
                }
                Section {
                    TextField(t("containerCreatePortsHint", "One per line, e.g. 8080:80"),
                              text: $portsText, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text(t("containerInfoPorts", "Ports"))
                }
                Section {
                    TextField(t("containerCreateEnvHint", "One KEY=VALUE per line"),
                              text: $envText, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text(t("containerInfoEnv", "Environment"))
                }
                Section {
                    TextField(t("containerCreateVolumesHint",
                                "One per line, e.g. /host:/container"),
                              text: $volumesText, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text(t("containerTabVolumes", "Volumes"))
                }
                Section {
                    Toggle(t("containerCreateAutoRemove", "Auto remove"), isOn: $autoRemove)
                    Toggle(t("containerCreatePrivileged", "Privileged"), isOn: $privileged)
                    Toggle(t("containerCreatePublishAllPorts", "Publish all ports"),
                           isOn: $publishAllPorts)
                } header: {
                    Text(t("containerCreateAdvancedSectionTitle", "Advanced"))
                }
                if let errorText {
                    Section {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                if submitting {
                    ProgressView().controlSize(.small)
                }
                Spacer()
                Button(t("commonCancel", "Cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(t("commonSave", "Save")) {
                    Task { await submit() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit || submitting)
            }
            .padding(16)
        }
        .frame(width: 560, height: 640)
    }

    private var canSubmit: Bool {
        !image.trimmingCharacters(in: .whitespaces).isEmpty
            && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() async {
        guard canSubmit else { return }
        submitting = true
        errorText = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "createContainer",
                arguments: [
                    "image": image.trimmingCharacters(in: .whitespaces),
                    "name": name.trimmingCharacters(in: .whitespaces),
                    "env": parseEnv(),
                    "exposedPorts": parsePorts(),
                    "volumes": parseVolumes(),
                    "restartPolicy": restartPolicy,
                    "autoRemove": autoRemove,
                    "privileged": privileged,
                    "publishAllPorts": publishAllPorts,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onCreated()
                dismiss()
            } else {
                errorText = payload["error"] as? String
                    ?? t("containerOperateFailed", "Operation failed")
            }
        } catch {
            errorText = error.localizedDescription
        }
        submitting = false
    }

    private func splitLines(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func parseEnv() -> [String] {
        splitLines(envText).filter { $0.contains("=") }
    }

    /// 端口行支持 `容器端口`、`主机端口:容器端口`、`IP:主机端口:容器端口/协议`。
    private func parsePorts() -> [[String: Any]] {
        splitLines(portsText).compactMap { line in
            var working = line
            var proto = "tcp"
            if let slash = working.lastIndex(of: "/") {
                proto = String(working[working.index(after: slash)...])
                working = String(working[..<slash])
            }
            let parts = working.split(separator: ":").map(String.init)
            switch parts.count {
            case 1:
                return ["containerPort": parts[0], "protocol": proto]
            case 2:
                return [
                    "hostPort": parts[0],
                    "containerPort": parts[1],
                    "protocol": proto,
                ]
            case 3:
                return [
                    "hostIP": parts[0],
                    "hostPort": parts[1],
                    "containerPort": parts[2],
                    "protocol": proto,
                ]
            default:
                return nil
            }
        }
    }

    /// 卷行支持 `主机目录:容器目录[:rw|ro]`，也接受单个容器目录。
    private func parseVolumes() -> [[String: Any]] {
        splitLines(volumesText).compactMap { line in
            let parts = line.split(separator: ":").map(String.init)
            if parts.count == 1 {
                return [
                    "sourceDir": parts[0],
                    "containerDir": parts[0],
                    "mode": "rw",
                    "type": "bind",
                ]
            }
            let mode = parts.count >= 3 ? parts[2] : "rw"
            return [
                "sourceDir": parts[0],
                "containerDir": parts[1],
                "mode": mode,
                "type": "bind",
            ]
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}