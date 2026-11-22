import Combine
import SwiftUI

/// 容器终端会话：把 Dart 侧推来的输出、状态、关闭事件转成可渲染的文本。
@MainActor
final class TerminalSessionModel: ObservableObject {
    @Published var output: String = ""
    @Published var status: String = "idle"
    @Published var isConnecting = false
    @Published var errorMessage: String?

    private(set) var sessionId: String?
    private var observer: NSObjectProtocol?
    private var heartbeatTimer: Timer?
    private let containerName: String
    private var columns = 80
    private var rows = 24
    private var isOpening = false

    init(containerName: String) {
        self.containerName = containerName
    }

    func connect(columns: Int = 80, rows: Int = 24) {
        guard sessionId == nil, !isConnecting else { return }
        self.columns = columns
        self.rows = rows
        isConnecting = true
        isOpening = true
        errorMessage = nil
        observeEvents()
        TerminalSessionBridge.shared.open(
            containerName: containerName,
            columns: columns,
            rows: rows
        ) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isConnecting = false
                self.isOpening = false
                switch result {
                case .success(let sessionId):
                    self.sessionId = sessionId
                    self.observeEvents()
                    self.startHeartbeat()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.status = "closed"
                }
            }
        }
    }

    func send(_ text: String) {
        guard let sessionId, !text.isEmpty else { return }
        TerminalSessionBridge.shared.sendInput(sessionId: sessionId, data: text)
    }

    func sendReturn() {
        send("\r")
    }

    func updateSize(columns: Int, rows: Int) {
        guard let sessionId, columns > 0, rows > 0 else { return }
        self.columns = columns
        self.rows = rows
        TerminalSessionBridge.shared.resize(sessionId: sessionId, columns: columns, rows: rows)
    }

    func clearOutput() {
        output = ""
    }

    func close() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        if let sessionId {
            TerminalSessionBridge.shared.close(sessionId: sessionId)
        }
        sessionId = nil
        status = "closed"
    }

    private func observeEvents() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: TerminalSessionBridge.eventName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let payload = notification.userInfo else { return }
            Task { @MainActor in
                self?.handle(payload: payload)
            }
        }
    }

    private func handle(payload: [AnyHashable: Any]) {
        guard let active = sessionId else {
            if isOpening {
                applyEvent(payload: payload)
            }
            return
        }
        guard payload["sessionId"] as? String == active else { return }
        applyEvent(payload: payload)
    }

    private func applyEvent(payload: [AnyHashable: Any]) {
        switch payload["event"] as? String {
        case "output":
            append(payload["data"] as? String ?? "")
        case "status":
            status = payload["status"] as? String ?? status
        case "closed":
            status = "closed"
            sessionId = nil
            heartbeatTimer?.invalidate()
            heartbeatTimer = nil
            if let reason = payload["reason"] as? String, !reason.isEmpty {
                errorMessage = reason
            }
        case "error":
            errorMessage = payload["message"] as? String ?? errorMessage
        default:
            break
        }
    }

    private func append(_ text: String) {
        guard !text.isEmpty else { return }
        output += text
        let limit = 200_000
        if output.count > limit {
            output = String(output.suffix(limit))
        }
    }

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let sessionId = self?.sessionId else { return }
                TerminalSessionBridge.shared.heartbeat(sessionId: sessionId)
            }
        }
    }
}