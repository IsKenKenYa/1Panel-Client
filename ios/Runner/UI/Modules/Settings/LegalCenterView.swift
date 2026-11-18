import SwiftUI
import UIKit

/// 法律中心：隐私政策、服务条款与开源许可文档入口。
struct LegalCenterView: View {
    @EnvironmentObject var translations: TranslationsManager

    private static let repoRoot = "https://github.com/IsKenKenYa/1Panel-Client/blob/main"

    private var isChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
    }

    private var privacyUrl: String {
        isChinese
            ? "\(Self.repoRoot)/docs/PRIVACY_POLICY.zh-CN.md"
            : "\(Self.repoRoot)/docs/PRIVACY_POLICY.md"
    }

    var body: some View {
        List {
            Section {
                Text(translations.get("settingsLegalCenterIntro",
                                      fallback: "Documents describing data handling, terms and open source dependencies."))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section(translations.get("settingsLegalDocumentsTitle", fallback: "Legal Documents")) {
                documentRow(translations.get("settingsLegalPrivacyPolicy", fallback: "Privacy Policy"),
                            url: privacyUrl)
                documentRow(translations.get("settingsLegalTermsOfService", fallback: "Terms of Service"),
                            url: "\(Self.repoRoot)/docs/TERMS_OF_SERVICE.md")
                documentRow(translations.get("settingsLegalThirdPartyNotices", fallback: "Third-Party Notices"),
                            url: "\(Self.repoRoot)/THIRD_PARTY_LICENSES.md")
                documentRow(translations.get("settingsLegalOpenSourceLicense", fallback: "Open Source License"),
                            url: "\(Self.repoRoot)/LICENSE")
            }
        }
        .navigationTitle(translations.get("settingsLegalCenterTitle", fallback: "Legal"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func documentRow(_ title: String, url: String) -> some View {
        Button {
            if let target = URL(string: url) {
                UIApplication.shared.open(target)
            }
        } label: {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
        }
    }
}