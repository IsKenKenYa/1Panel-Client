import SwiftUI
import UIKit

/// 关于页：版本信息、项目简介与仓库入口。
struct AboutView: View {
    @EnvironmentObject var translations: TranslationsManager

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "--"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "--"
    }

    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? "--"
    }

    private static let officialUrl = "https://onepanel.iskenkenya.com"
    private static let repoUrl = "https://github.com/IsKenKenYa/1Panel-Client"
    private static let issuesUrl = "https://github.com/IsKenKenYa/1Panel-Client/issues"
    private static let releasesUrl = "https://github.com/IsKenKenYa/1Panel-Client/releases"

    var body: some View {
        List {
            Section(translations.get("aboutBuildSectionTitle", fallback: "Version")) {
                InfoLine(label: translations.get("aboutVersionLabel", fallback: "Version"),
                         value: "v\(appVersion)")
                InfoLine(label: translations.get("aboutBuildLabel", fallback: "Build"),
                         value: buildNumber)
                InfoLine(label: translations.get("aboutPackageNameLabel", fallback: "Bundle ID"),
                         value: bundleId)
                Button {
                    open(Self.officialUrl)
                } label: {
                    HStack {
                        Text(translations.get("aboutOfficialDomainLabel", fallback: "Official Domain"))
                        Spacer()
                        Text("onepanel.iskenkenya.com")
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(translations.get("aboutProjectSectionTitle", fallback: "About")) {
                Text(translations.get("aboutProjectSummary",
                                      fallback: "1Panel Client is a mobile client for managing 1Panel servers."))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section(translations.get("aboutRepositorySectionTitle", fallback: "Repository")) {
                Button {
                    open(Self.repoUrl)
                } label: {
                    Label(translations.get("aboutRepositoryOpenAction", fallback: "Open Repository"),
                          systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Button {
                    open(Self.issuesUrl)
                } label: {
                    Label(translations.get("aboutFeedbackAction", fallback: "Open GitHub Issues"),
                          systemImage: "bubble.left.and.bubble.right")
                }
                Button {
                    open(Self.releasesUrl)
                } label: {
                    Label(translations.get("aboutReleaseNotesSectionTitle", fallback: "Releases"),
                          systemImage: "tag")
                }
            }
        }
        .navigationTitle(translations.get("aboutPageTitle", fallback: "About"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}