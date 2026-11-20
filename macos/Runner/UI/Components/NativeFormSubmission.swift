import Accessibility
import SwiftUI

enum NativeFormSubmission: Equatable {
    case idle
    case submitting
    case failed(String?)
    case succeeded

    var isSubmitting: Bool { self == .submitting }

    mutating func begin() -> Bool {
        guard !isSubmitting, self != .succeeded else { return false }
        self = .submitting
        return true
    }

    mutating func finish(_ outcome: NativeMutationOutcome) -> Bool {
        guard isSubmitting else { return false }
        switch outcome {
        case .succeeded:
            self = .succeeded
            return true
        case .failed(let message):
            let detail = message?.trimmingCharacters(in: .whitespacesAndNewlines)
            self = .failed(detail?.isEmpty == false ? detail : nil)
            return false
        }
    }
}

struct NativeFormSubmissionFeedback: View {
    let submission: NativeFormSubmission
    let errorFallback: String

    @EnvironmentObject private var translations: TranslationsManager
    @AccessibilityFocusState private var isErrorFocused: Bool

    var body: some View {
        switch submission {
        case .idle, .succeeded:
            EmptyView()
        case .submitting:
            ProgressView(translations.get("commonLoading", fallback: "Loading..."))
                .controlSize(.small)
        case .failed(let detail):
            let message = detail ?? errorFallback
            Label {
                Text(message)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.circle")
                    .accessibilityHidden(true)
            }
            .font(.callout)
            .foregroundStyle(.red)
            .accessibilityElement(children: .combine)
            .accessibilityFocused($isErrorFocused)
            .onAppear {
                if #available(macOS 14.0, *) {
                    AccessibilityNotification.Announcement(message).post()
                } else {
                    isErrorFocused = true
                }
            }
        }
    }
}
