using System.Text.Json;
using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge installApp 桥接契约测试（与 Dart 侧 installApp handler 契约钉死：
/// 参数 {appKey, version?, name?}，返回 {success, appId?, error?}）。
/// 编码侧调用 Codec.EncodeMethodCall 断言 Dart StandardMessageCodec 规范级 golden
/// 字节（方法名与全部参数键均在字节流中，期望字节独立按规范手算，防止自证）；
/// 可选参数 null 时键仍保留（PrepareArgs 路径，与 B22 断言风格一致）。
/// </summary>
public class AppInstallBridgeContractTests
{
    [Fact]
    public void EncodeMethodCall_installApp_full_args_matches_StandardMessageCodec_bytes()
    {
        // 与 WindowsBridge.InstallAppAsync(appKey, version, name) 调用点同形：
        // 三键齐全，version/name 为非空字符串。
        var encoded = WindowsBridge.Codec.EncodeMethodCall("installApp", new Dictionary<string, object?>
        {
            ["appKey"] = "openresty",
            ["version"] = "1.27.0",
            ["name"] = "OpenResty",
        });

        // 分段独立手算（07=string 0d=map 00=null，长度为变长编码）：
        // "installApp" | map×3 | "appKey":"openresty" | "version":"1.27.0" | "name":"OpenResty"
        Assert.Equal(
            "070a696e7374616c6c417070" +
            "0d03" +
            "07066170704b6579" +
            "07096f70656e7265737479" +
            "070776657273696f6e" +
            "0706312e32372e30" +
            "07046e616d65" +
            "07094f70656e5265737479",
            Convert.ToHexString(encoded).ToLowerInvariant());
    }

    [Fact]
    public void EncodeMethodCall_installApp_optional_args_null_keeps_keys_in_bytes()
    {
        // version/name 传 null 时键不丢失（null 值编码为 00），Dart 侧按键存在与否取缺省。
        var encoded = WindowsBridge.Codec.EncodeMethodCall("installApp", new Dictionary<string, object?>
        {
            ["appKey"] = "redis",
            ["version"] = null,
            ["name"] = null,
        });

        Assert.Equal(
            "070a696e7374616c6c417070" +
            "0d03" +
            "07066170704b6579" +
            "07057265646973" +
            "070776657273696f6e" +
            "00" +
            "07046e616d65" +
            "00",
            Convert.ToHexString(encoded).ToLowerInvariant());
    }

    [Fact]
    public void PrepareArgs_installApp_dictionary_keeps_optional_keys_with_null_values()
    {
        // 与 InstallAppAsync 调用点同形：Dictionary<string, object?> 命中非泛型
        // IDictionary 分支，经 ConvertDictionary 复制为新字典，null 值键保留。
        var args = new Dictionary<string, object?>
        {
            ["appKey"] = "openresty",
            ["version"] = null,
            ["name"] = null,
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.NotSame(args, dict);
        Assert.Equal(3, dict.Count);
        Assert.Equal("openresty", dict["appKey"]);
        Assert.True(dict.ContainsKey("version"));
        Assert.Null(dict["version"]);
        Assert.True(dict.ContainsKey("name"));
        Assert.Null(dict["name"]);
    }
}

/// <summary>
/// WindowsBridge.ErrorTextOf 信封语义契约测试（internal，经 InternalsVisibleTo 直测）。
/// InstallAppAsync 与 CreateWebsiteAsync 错误透出同型：成功信封返回 null，
/// 失败信封取 error 文本，通道级 null 结果回退通用文案。
/// </summary>
public class ErrorTextOfContractTests
{
    [Fact]
    public void ErrorTextOf_failure_envelope_returns_error_text()
    {
        using var doc = JsonDocument.Parse("""{"success":false,"error":"x"}""");

        Assert.Equal("x", WindowsBridge.ErrorTextOf(doc.RootElement.Clone()));
    }

    [Fact]
    public void ErrorTextOf_success_envelope_returns_null()
    {
        // 契约成功形态：{success:true, appId:N}——ErrorTextOf 只看 success。
        using var doc = JsonDocument.Parse("""{"success":true,"appId":3}""");

        Assert.Null(WindowsBridge.ErrorTextOf(doc.RootElement.Clone()));
    }

    [Fact]
    public void ErrorTextOf_null_result_returns_fallback_text()
    {
        // 通道不可用/超时/错误信封时 InvokeJsonAsync 返回 null，回退通用文案。
        Assert.Equal("Method channel call failed.", WindowsBridge.ErrorTextOf(null));
    }
}
