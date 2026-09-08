using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;

namespace OnePanelNativeHost;

/// <summary>
/// 宿主 UI 文案运行时查表：启动/语言切换时经 getTranslations 通道拉取
/// 当前语言整份 arb 字典（locale 决策在 Dart 侧：偏好优先、缺省跟随系统），
/// 未加载/缺键一律回落调用点提供的英文原样，T 永不抛异常。
/// </summary>
public static class L10n
{
    private static IReadOnlyDictionary<string, string> _strings =
        new Dictionary<string, string>();

    public static bool IsLoaded => _strings.Count > 0;

    /// <summary>应用 getTranslations 返回的 string→string map（整体替换）。</summary>
    public static void Apply(JsonElement? element)
    {
        var dict = new Dictionary<string, string>(StringComparer.Ordinal);
        if (element is JsonElement e && e.ValueKind == JsonValueKind.Object)
        {
            foreach (var prop in e.EnumerateObject())
            {
                if (prop.Value.ValueKind == JsonValueKind.String)
                {
                    dict[prop.Name] = prop.Value.GetString() ?? string.Empty;
                }
            }
        }

        _strings = dict;
    }

    /// <summary>从宿主通道拉取字典并应用（失败/空 → 回落英文）。</summary>
    public static async Task LoadAsync()
    {
        Apply(await WindowsBridge.GetTranslationsAsync());
    }

    /// <summary>查表；命中返回译文，否则返回英文原样。</summary>
    public static string T(string key, string fallback)
    {
        return _strings.TryGetValue(key, out var value) && value.Length > 0
            ? value
            : fallback;
    }

    /// <summary>测试用：清空字典回到英文回落态。</summary>
    public static void Reset()
    {
        _strings = new Dictionary<string, string>();
    }
}
