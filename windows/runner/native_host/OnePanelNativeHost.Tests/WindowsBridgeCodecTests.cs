using System.Text.Json;
using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.Codec 的 golden 向量测试。
/// 期望字节来自 Dart StandardMethodCodec 的真实编码产物
/// （test/core/channel/winui_codec_golden_test.dart 生成），独立于 C# 实现。
/// </summary>
public class WindowsBridgeCodecTests
{
    [Theory]
    [MemberData(nameof(MethodCallNames))]
    public void EncodeMethodCall_matches_Dart_StandardMethodCodec_bytes(string name)
    {
        var vector = GoldenVectors.MethodCalls.First(v => v.Name == name);

        var actual = WindowsBridge.Codec.EncodeMethodCall(name, TestArgs.For(name));

        Assert.Equal(vector.Hex, ToHex(actual));
    }

    public static TheoryData<string> MethodCallNames() =>
        new(GoldenVectors.MethodCalls.Select(v => v.Name));

    [Theory]
    [MemberData(nameof(SuccessResponseNames))]
    public void DecodeResponse_success_vectors_produce_expected_json(string name)
    {
        var vector = GoldenVectors.SuccessResponses.First(v => v.Name == name);

        var json = WindowsBridge.Codec.DecodeResponse(FromHex(vector.Hex));

        Assert.Equal(vector.ExpectedJson, json);
    }

    public static TheoryData<string> SuccessResponseNames() =>
        new(GoldenVectors.SuccessResponses.Select(v => v.Name));

    [Theory]
    [MemberData(nameof(ErrorResponseNames))]
    public void DecodeResponse_error_vectors_return_null(string name)
    {
        var vector = GoldenVectors.ErrorResponses.First(v => v.Name == name);

        Assert.Null(WindowsBridge.Codec.DecodeResponse(FromHex(vector.Hex)));
    }

    public static TheoryData<string> ErrorResponseNames() =>
        new(GoldenVectors.ErrorResponses.Select(v => v.Name));

    [Fact]
    public void PrepareArgs_converts_JsonElement_into_codec_values()
    {
        using var doc = JsonDocument.Parse(
            """{"str":"/x","int":5,"double":1.5,"flag":true,"nul":null,"arr":[1,"a"],"nested":{"k":"v"}}""");

        var args = WindowsBridge.PrepareArgs(doc.RootElement.Clone());

        var dict = Assert.IsType<Dictionary<string, object?>>(args);
        Assert.Equal("/x", dict["str"]);
        Assert.Equal(typeof(long), dict["int"]!.GetType());
        Assert.Equal(5L, (long)dict["int"]!);
        Assert.Equal(typeof(double), dict["double"]!.GetType());
        Assert.Equal(1.5, (double)dict["double"]!);
        Assert.Equal(true, dict["flag"]);
        Assert.Null(dict["nul"]);

        var list = Assert.IsType<List<object?>>(dict["arr"]);
        Assert.Equal(2, list.Count);
        Assert.Equal(1L, (long)list[0]!);
        Assert.Equal("a", list[1]);

        var nested = Assert.IsType<Dictionary<string, object?>>(dict["nested"]);
        Assert.Equal("v", nested["k"]);
    }

    private static string ToHex(byte[] bytes) =>
        Convert.ToHexString(bytes).ToLowerInvariant();

    private static byte[] FromHex(string hex) => Convert.FromHexString(hex);
}

/// <summary>独立手写的参数构造，与 Dart golden 用例一一对应。</summary>
internal static class TestArgs
{
    public static object? For(string method) => method switch
    {
        "getServers" => null,
        "getFiles" => new Dictionary<string, object?> { ["path"] = "/" },
        "getCurrentServer" => null,
        "switchServer" => new Dictionary<string, object?> { ["id"] = "srv-001" },
        "updateSetting" => new Dictionary<string, object?>
        {
            ["key"] = "app_lock_enabled",
            ["value"] = true,
        },
        "codec.complex" => new Dictionary<string, object?>
        {
            ["list"] = new List<object?> { 1, -5, 3000000000L, 3.14, "text", true, null },
            ["nested"] = new Dictionary<string, object?>
            {
                ["inner"] = new List<object?> { 2, 3 },
                ["flag"] = false,
            },
        },
        _ => throw new ArgumentOutOfRangeException(nameof(method), method),
    };
}
