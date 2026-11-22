import AppleSharedUI
import SwiftUI

struct AlertRuleRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let rule: AlertRuleModel
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(rule.title.isEmpty
                         ? AlertLabels.ruleType(rule.type, translations: translations)
                         : rule.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    StatusBadge(text: rule.status, color: alertToneColor(rule.statusTone))
                }
                Text(metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !rule.advancedParams.isEmpty {
                    Text(rule.advancedParams)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .accessibilityLabel(rule.title)
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items = [AlertLabels.ruleType(rule.type, translations: translations)]
        if !rule.sendMethod.isEmpty {
            items.append(rule.sendMethod.joined(separator: " / "))
        }
        if rule.cycle > 0 {
            items.append("\(translations.get("alertRuleCycleDaysLabel", fallback: "Days")) \(rule.cycle)")
        }
        if rule.count > 0 {
            items.append("\(rule.count)")
        }
        return items.joined(separator: " · ")
    }
}

struct AlertLogRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let log: AlertLogModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(log.title.isEmpty
                     ? AlertLabels.ruleType(log.type, translations: translations)
                     : log.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: log.status, color: alertToneColor(log.statusTone))
            }
            if !log.message.isEmpty {
                Text(log.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(metadata)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items: [String] = []
        if !log.method.isEmpty { items.append(log.method) }
        if log.count > 0 {
            items.append("×\(log.count)")
        }
        if !log.createdAt.isEmpty { items.append(log.createdAt) }
        return items.joined(separator: " · ")
    }
}

struct AlertChannelRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let channel: AlertChannelModel
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(channel.title.isEmpty
                         ? AlertLabels.channelType(channel.type, translations: translations)
                         : channel.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    StatusBadge(text: channel.status, color: alertToneColor(channel.statusTone))
                }
                Text(AlertLabels.channelType(channel.type, translations: translations))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !channel.configSummary.isEmpty {
                    Text(channel.configSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { channel.enabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .accessibilityLabel(channel.title)
        }
        .padding(.vertical, 2)
    }
}

private func alertToneColor(_ tone: String) -> Color {
    switch tone {
    case "positive": return .green
    case "warning": return .orange
    case "negative": return .red
    case "info": return .blue
    default: return .secondary
    }
}