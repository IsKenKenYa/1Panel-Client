import Foundation

/// 告警类型标签：键名与 Dart 侧双语 arb 一致。
public enum AlertLabels {
    public static func ruleType(
        _ type: String,
        translations: (any TranslationsProviding)?
    ) -> String {
        switch type {
        case "panelPwdEndTime":
            return text("alertRuleTypePasswordExpiry", "Password expiry", translations)
        case "panelLogin":
            return text("alertRuleTypePanelLogin", "Panel login", translations)
        case "sshLogin":
            return text("alertRuleTypeSshLogin", "SSH login", translations)
        case "ssl":
            return text("alertRuleTypeSsl", "SSL certificate", translations)
        case "siteEndTime":
            return text("alertRuleTypeSiteExpiry", "Website expiry", translations)
        case "cpu":
            return text("alertRuleTypeCpu", "CPU usage", translations)
        case "memory":
            return text("alertRuleTypeMemory", "Memory usage", translations)
        case "disk":
            return text("alertRuleTypeDisk", "Disk usage", translations)
        case "load":
            return text("alertRuleTypeLoad", "Load average", translations)
        case "clams":
            return text("alertRuleTypeClams", "Virus scan", translations)
        case "cronJob":
            return text("alertRuleTypeCronJob", "Scheduled task", translations)
        case "panelUpdate":
            return text("alertRuleTypePanelUpdate", "Panel update", translations)
        case "licenseException":
            return text("alertRuleTypeLicenseException", "License exception", translations)
        case "nodeException":
            return text("alertRuleTypeNodeException", "Node exception", translations)
        default:
            return type
        }
    }

    public static func channelType(
        _ type: String,
        translations: (any TranslationsProviding)?
    ) -> String {
        switch type {
        case "email":
            return text("alertChannelTypeEmail", "Email", translations)
        case "bark":
            return text("alertChannelTypeBark", "Bark", translations)
        case "weCom":
            return text("alertChannelTypeWeCom", "WeCom", translations)
        case "dingTalk":
            return text("alertChannelTypeDingTalk", "DingTalk", translations)
        case "feiShu":
            return text("alertChannelTypeFeiShu", "Feishu", translations)
        case "custom":
            return text("alertChannelTypeCustom", "Custom webhook", translations)
        default:
            return type
        }
    }

    public static func preset(
        _ key: String,
        translations: (any TranslationsProviding)?
    ) -> String {
        switch key {
        case "genericJson":
            return text("alertChannelCustomPresetGeneric", "Generic JSON", translations)
        case "slack":
            return text("alertChannelCustomPresetSlack", "Slack", translations)
        case "discord":
            return text("alertChannelCustomPresetDiscord", "Discord", translations)
        case "teams":
            return text("alertChannelCustomPresetTeams", "Teams Workflows", translations)
        case "custom":
            return text("alertChannelCustomPresetCustom", "Custom", translations)
        default:
            return key
        }
    }

    public static func encryption(
        _ value: String,
        translations: (any TranslationsProviding)?
    ) -> String {
        switch value {
        case "NONE":
            return text("alertChannelEncryptionNone", "None", translations)
        case "SSL":
            return text("alertChannelEncryptionSsl", "SSL", translations)
        case "TLS":
            return text("alertChannelEncryptionTls", "TLS", translations)
        default:
            return value
        }
    }

    private static func text(
        _ key: String,
        _ fallback: String,
        _ translations: (any TranslationsProviding)?
    ) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}