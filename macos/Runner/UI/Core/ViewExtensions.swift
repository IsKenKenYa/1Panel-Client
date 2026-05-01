import SwiftUI

extension View {
    /// Disables alternating row backgrounds on macOS 14+; no-op on earlier versions.
    @ViewBuilder
    func disableAlternatingRowBackgrounds() -> some View {
        if #available(macOS 14.0, *) {
            self.alternatingRowBackgrounds(.disabled)
        } else {
            self
        }
    }
}
