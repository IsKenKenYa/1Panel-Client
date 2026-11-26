import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import Accessibility
#endif

/// 底部瞬时提示：操作成功或失败后短暂显示一行文案。
///
/// iOS / iPadOS 与 macOS 共用同一实现，渲染在内容底部，不拦截点击，
/// 并把文案交给系统朗读给 VoiceOver。
public extension View {
    func operationNotice(_ message: String?) -> some View {
        overlay(alignment: .bottom) {
            if let message {
                Text(message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    // 提示通过公告朗读，隐藏自身可避免 VoiceOver 再读一次。
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .id(message)
                    .onAppear {
                        announce(message)
                    }
            }
        }
    }
}

private func announce(_ message: String) {
    #if os(iOS)
    UIAccessibility.post(notification: .announcement, argument: message)
    #elseif os(macOS)
    if #available(macOS 14.0, *) {
        AccessibilityNotification.Announcement(message).post()
    }
    #endif
}

public extension Binding where Value == String? {
    /// 显示提示并在固定时长后清空。
    ///
    /// 计时开始时记下待清除文案，只有当前文案仍是它才清空；
    /// 后出现的提示不会被前一次计时提前清掉。
    @MainActor
    func showOperationNotice(_ text: String, duration: Duration = .milliseconds(2500)) {
        wrappedValue = text
        let expected = text
        Task { @MainActor in
            try? await Task.sleep(for: duration)
            if wrappedValue == expected { wrappedValue = nil }
        }
    }
}
