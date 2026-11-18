using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 日志/OpenResty 桥接方法参数字典的契约测试（B16：
/// getSystemLogContent / updateOpenrestyConfig，null args 覆盖
/// getOperationLogs / getLoginLogs / getOpenrestySnapshot / getDashboard 无参调用点）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型
/// IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转
/// string、装箱值原样保留（bool 不被字符串化）。期望值独立手写，防止自证。
/// </summary>
public class LogsOpenrestyBridgeContractTests
{
    [Fact]
    public void PrepareArgs_getSystemLogContent_dictionary_preserves_two_keys_with_exact_typed_values()
    {
        // 与 WindowsBridge.GetSystemLogContentAsync(fileName, useCoreLogs) 调用点同形：
        // 双键 fileName + useCoreLogs。
        var args = new Dictionary<string, object?>
        {
            ["fileName"] = "1Panel.log",
            ["useCoreLogs"] = true,
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(2, dict.Count);
        Assert.Equal("1Panel.log", Assert.IsType<string>(dict["fileName"]));
        // bool 装箱值原样保留：仍为 bool 类型且值为 true，不被转成字符串。
        Assert.IsType<bool>(dict["useCoreLogs"]);
        Assert.True((bool)dict["useCoreLogs"]!);
        Assert.NotEqual("True", dict["useCoreLogs"]);
    }

    [Fact]
    public void PrepareArgs_updateOpenrestyConfig_dictionary_preserves_single_content_key_with_exact_value()
    {
        // 与 WindowsBridge.UpdateOpenrestyConfigAsync(content) 调用点同形：单键 content，
        // 值为 OpenResty 配置源文本片段（输入用拼接构造，期望值独立手写字面量）。
        var args = new Dictionary<string, object?>
        {
            ["content"] = "user" + " root;",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("content", single.Key);
        var value = Assert.IsType<string>(single.Value);
        Assert.Equal("user root;", value);
        // 分号逐字符精确保留，末尾不补换行。
        Assert.Equal(';', value[^1]);
    }

    [Theory]
    [InlineData("getOperationLogs")]
    [InlineData("getLoginLogs")]
    [InlineData("getOpenrestySnapshot")]
    [InlineData("getDashboard")]
    public void PrepareArgs_null_args_returns_null(string method)
    {
        // 与 GetOperationLogsAsync() / GetLoginLogsAsync() / GetOpenrestySnapshotAsync() /
        // GetDashboardAsync() 无参调用点同形：InvokeWithRetryAsync(method) 不携带 args，
        // PrepareArgs(null) 原样返回 null。
        Assert.Contains(method, new[] { "getOperationLogs", "getLoginLogs", "getOpenrestySnapshot", "getDashboard" });
        Assert.Null(WindowsBridge.PrepareArgs(null));
    }
}
