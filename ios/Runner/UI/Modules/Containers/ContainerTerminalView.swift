import SwiftUI

/// 容器终端：等宽文本输出 + 底部输入框，回车发送，支持清屏与断开。
/// 连接建立在 Dart 侧 `NativeTerminalBridge`，原生层只负责渲染与输入。
struct ContainerTerminalView: View {
    @EnvironmentObject var translations: TranslationsManager
    @StateObject private var session: TerminalSessionModel
    @State private var input = ""
    @FocusState private var inputFocused: Bool

    init(containerName: String) {
        _session = StateObject(wrappedValue: TerminalSessionModel(containerName: containerName))
    }

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            outputArea
            inputBar
        }
        .onAppear {
            session.connect()
        }
        .onDisappear {
            session.close()
        }
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                session.clearOutput()
            } label: {
                Label(translations.get("containerActionCleanLog", fallback: "Clear"),
                      systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .disabled(session.output.isEmpty)
            .accessibilityLabel(translations.get("containerActionCleanLog", fallback: "Clear"))
            if session.sessionId != nil {
                Button {
                    session.close()
                } label: {
                    Label(translations.get("containerTerminalDisconnect", fallback: "Disconnect"),
                          systemImage: "xmark.circle")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(translations.get("containerTerminalDisconnect", fallback: "Disconnect"))
            } else {
                Button {
                    session.connect()
                } label: {
                    Label(translations.get("containerTerminalConnect", fallback: "Connect"),
                          systemImage: "bolt.horizontal.circle")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(translations.get("containerTerminalConnect", fallback: "Connect"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var statusColor: Color {
        switch session.status {
        case "connected": return .green
        case "connecting": return .orange
        case "closed": return .red
        default: return .gray
        }
    }

    private var statusText: String {
        switch session.status {
        case "connected":
            return translations.get("terminalWorkbenchStatusConnected", fallback: "Connected")
        case "connecting":
            return translations.get("commonLoading", fallback: "Loading...")
        case "closed":
            return translations.get("terminalWorkbenchStatusClosed", fallback: "Closed")
        default:
            return translations.get("terminalWorkbenchStatusIdle", fallback: "Idle")
        }
    }

    private var outputArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if session.isConnecting && session.output.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else if let error = session.errorMessage, session.output.isEmpty {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else if session.output.isEmpty {
                        Text(translations.get("terminalWorkbenchOpenHint",
                                              fallback: "Open or create a terminal session"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else {
                        Text(session.output)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                            .id("terminal-output")
                    }
                }
            }
            .onChange(of: session.output) { _ in
                withAnimation(.linear(duration: 0.1)) {
                    proxy.scrollTo("terminal-output", anchor: .bottom)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField(translations.get("terminalWorkbenchCommand", fallback: "Command"),
                      text: $input)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.subheadline, design: .monospaced))
                .focused($inputFocused)
                .onSubmit {
                    submit()
                }
                .disabled(session.sessionId == nil)
            Button {
                submit()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(session.sessionId == nil || input.isEmpty)
            .accessibilityLabel(translations.get("containerTerminalConnect", fallback: "Connect"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func submit() {
        let text = input
        input = ""
        session.send(text)
        session.sendReturn()
    }
}
