using System.Text.Json;
using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// B25 宿主 L10n 运行时查表契约（数据源 = Dart getTranslations handler，
/// 返回当前 locale 整份 arb 字典）。zh 期望值独立手抄自 lib/l10n/app_zh.arb，
/// 防止自证；缺键/未加载/空字典一律回落英文原样，T 永不抛异常。
/// </summary>
public class L10nBridgeTests : IDisposable
{
    public void Dispose() => L10n.Reset();

    [Fact]
    public void Apply_zh_entries_T_returns_exact_arb_values()
    {
        // golden：手抄自 lib/l10n/app_zh.arb。
        using var doc = JsonDocument.Parse(
            "{\"settingsUIRenderMode\":\"UI 渲染模式\",\"settingsPageTitle\":\"设置\"}");
        L10n.Apply(doc.RootElement);

        Assert.Equal("UI 渲染模式", L10n.T("settingsUIRenderMode", "UI Render Mode"));
        Assert.Equal("设置", L10n.T("settingsPageTitle", "Settings"));
        Assert.True(L10n.IsLoaded);
    }

    [Fact]
    public void T_missing_key_falls_back_to_english_literal()
    {
        using var doc = JsonDocument.Parse("{\"settingsPageTitle\":\"设置\"}");
        L10n.Apply(doc.RootElement);

        Assert.Equal("Create command", L10n.T("hostCommandsCreate", "Create command"));
    }

    [Fact]
    public void T_without_load_or_null_element_falls_back_to_english()
    {
        L10n.Reset();
        Assert.False(L10n.IsLoaded);
        Assert.Equal("Refresh", L10n.T("commonRefresh", "Refresh"));

        L10n.Apply((JsonElement?)null);
        Assert.False(L10n.IsLoaded);
        Assert.Equal("Refresh", L10n.T("commonRefresh", "Refresh"));
    }

    [Fact]
    public void Apply_skips_non_string_values_and_replaces_previous_dictionary()
    {
        using var first = JsonDocument.Parse("{\"a\":\"甲\"}");
        L10n.Apply(first.RootElement);

        using var second = JsonDocument.Parse("{\"b\":123,\"c\":\"丙\"}");
        L10n.Apply(second.RootElement);

        // 旧字典被整体替换（语言切换重载语义），非字符串值被跳过。
        Assert.Equal("fallback", L10n.T("a", "fallback"));
        Assert.Equal("丙", L10n.T("c", "fallback"));
        Assert.True(L10n.IsLoaded);
    }

    [Fact]
    public void EncodeMethodCall_getTranslations_null_args_matches_StandardMessageCodec_bytes()
    {
        // 与 WindowsBridge.GetTranslationsAsync() 无参调用点同形：
        // "getTranslations"（长度 15）+ null args（00），期望字节独立按规范手算。
        var encoded = WindowsBridge.Codec.EncodeMethodCall("getTranslations", null);

        Assert.Equal(
            "070f6765745472616e736c6174696f6e73" +
            "00",
            Convert.ToHexString(encoded).ToLowerInvariant());
    }

    [Fact]
    public async Task GetTranslationsAsync_returns_null_when_bridge_not_initialized()
    {
        // 未 Initialize（无引擎）时 InvokeAsync 直接返回 null，不得抛异常。
        var result = await WindowsBridge.GetTranslationsAsync();
        Assert.Null(result);
    }
}
