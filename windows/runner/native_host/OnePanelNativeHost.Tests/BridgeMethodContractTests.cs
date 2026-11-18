using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 直传字典路径的方法契约测试（createWebsite / getDashboard / getMonitoring）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型 IDictionary&lt;string, object?&gt; 之前），
/// 经 ConvertDictionary 复制为新字典：值原样保留，不做 int→long 数值提升。
/// 期望值独立手写，防止自证。
/// </summary>
public class BridgeMethodContractTests
{
    [Fact]
    public void PrepareArgs_createWebsite_dictionary_preserves_values_and_boxed_types()
    {
        var args = new Dictionary<string, object?>
        {
            ["primaryDomain"] = "a.com",
            ["alias"] = "",
            ["port"] = 80L,
            ["remark"] = null,
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(4, dict.Count);
        Assert.Equal("a.com", dict["primaryDomain"]);
        Assert.Equal(string.Empty, dict["alias"]);
        Assert.Equal(typeof(long), dict["port"]!.GetType());
        Assert.Equal(80L, (long)dict["port"]!);
        Assert.True(dict.ContainsKey("remark"));
        Assert.Null(dict["remark"]);
    }

    [Fact]
    public void PrepareArgs_int_value_passed_directly_stays_boxed_int()
    {
        // ConvertDictionary 只复制不提升：int 直传后仍为 Int32 装箱，
        // 编码层由 Codec.WriteValue 的 case int 分支按 Int32 写入（与 long 分支区分）。
        var args = new Dictionary<string, object?> { ["port"] = 80 };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.Equal(typeof(int), dict["port"]!.GetType());
        Assert.Equal(80, (int)dict["port"]!);
    }

    [Theory]
    [InlineData("getDashboard")]
    [InlineData("getMonitoring")]
    public void PrepareArgs_null_args_return_null(string method)
    {
        // 两类只读方法在 C# 调用点均无参（InvokeWithRetryAsync 的 args 默认 null）。
        var args = method switch
        {
            "getDashboard" or "getMonitoring" => (object?)null,
            _ => throw new ArgumentOutOfRangeException(nameof(method), method),
        };

        Assert.Null(WindowsBridge.PrepareArgs(args));
    }
}
