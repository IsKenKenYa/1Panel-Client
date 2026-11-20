import SwiftUI
import UIKit

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
