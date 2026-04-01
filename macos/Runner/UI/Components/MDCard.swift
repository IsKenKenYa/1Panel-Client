import SwiftUI

struct MDCard<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    
    var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(theme.surfaceColor)
            .cornerRadius(theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
