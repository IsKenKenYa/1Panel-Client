import SwiftUI

struct MDListItem<Content: View>: View {
    @EnvironmentObject var theme: ThemeManager
    var title: String
    var subtitle: String?
    var icon: String?
    var trailingContent: Content?
    
    init(title: String, subtitle: String? = nil, icon: String? = nil, @ViewBuilder trailingContent: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.trailingContent = trailingContent()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let trailingContent = trailingContent {
                trailingContent
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(theme.surfaceColor)
        .cornerRadius(8)
    }
}

extension MDListItem where Content == EmptyView {
    init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.trailingContent = nil
    }
}
