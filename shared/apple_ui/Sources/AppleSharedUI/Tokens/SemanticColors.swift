import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// 语义色：把平台色彩 API 收在包内，共享组件只引用语义名。
public enum SemanticColors {
    /// 页面背景
    public static var background: Color {
        #if os(iOS)
        Color(UIColor.systemBackground)
        #elseif os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color.white
        #endif
    }

    /// 卡片与分组背景
    public static var surface: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color.gray.opacity(0.1)
        #endif
    }

    public static let success: Color = .green
    public static let danger: Color = .red
    public static let warning: Color = .orange
    public static let info: Color = .blue
    public static let neutral: Color = .gray
}
