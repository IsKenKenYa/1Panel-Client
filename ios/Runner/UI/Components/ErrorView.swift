import SwiftUI
import UIKit

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                ContentUnavailableView {
                    Label(message, systemImage: "exclamationmark.triangle")
                } actions: {
                    retryButton
                }
            } else {
                VStack(spacing: 16) {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .multilineTextAlignment(.center)
                    retryButton
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var retryButton: some View {
        Button(translations.get("commonRetry", fallback: "Retry"), action: onRetry)
            .buttonStyle(.borderedProminent)
    }
}

extension View {
    func operationNotice(_ message: String?) -> some View {
        overlay(alignment: .bottom) {
            if let message {
                Text(message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .id(message)
                    .onAppear {
                        UIAccessibility.post(notification: .announcement, argument: message)
                    }
            }
        }
    }
}
