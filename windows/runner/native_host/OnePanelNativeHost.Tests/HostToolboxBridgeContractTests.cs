using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 主机/工具箱桥接方法参数字典的契约测试（B15：
/// operateSsh / saveSshConfig / verifyToolboxDns，null args 覆盖
/// getSshInfo / getSshConfig / getDeviceSnapshot 无参调用点）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型
/// IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转
/// string、装箱值原样保留。期望值独立手写，防止自证。
/// </summary>
public class HostToolboxBridgeContractTests
{
    [Fact]
    public void PrepareArgs_operateSsh_dictionary_preserves_single_operation_key_with_exact_value()
    {
        // 与 WindowsBridge.OperateSshAsync(operation) 调用点同形：单键 operation。
        var args = new Dictionary<string, object?>
        {
            ["operation"] = "restart",
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("operation", single.Key);
        Assert.Equal("restart", single.Value);
    }

    [Fact]
    public void PrepareArgs_saveSshConfig_dictionary_preserves_single_value_key_with_newline_exact()
    {
        // 与 WindowsBridge.SaveSshConfigAsync(value) 调用点同形：单键 value，
        // 值为含换行的原始 SSH 配置片段（输入用拼接构造，期望值独立手写字面量）。
        var args = new Dictionary<string, object?>
        {
            ["value"] = "Port 2222" + "\n",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("value", single.Key);
        // 换行符逐字符精确保留，不做归一化（不丢 \n、不补 \r）。
        var value = Assert.IsType<string>(single.Value);
        Assert.Equal("Port 2222\n", value);
        Assert.Equal('\n', value[^1]);
    }

    [Fact]
    public void PrepareArgs_verifyToolboxDns_dictionary_preserves_single_dns_key_with_exact_value()
    {
        // 与 WindowsBridge.VerifyToolboxDnsAsync(dns) 调用点同形：单键 dns。
        var args = new Dictionary<string, object?>
        {
            ["dns"] = "1.1.1.1",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("dns", single.Key);
        Assert.Equal("1.1.1.1", single.Value);
    }

    [Theory]
    [InlineData("getSshInfo")]
    [InlineData("getSshConfig")]
    [InlineData("getDeviceSnapshot")]
    public void PrepareArgs_null_args_returns_null(string method)
    {
        // 与 GetSshInfoAsync() / GetSshConfigAsync() / GetDeviceSnapshotAsync()
        // 无参调用点同形：InvokeWithRetryAsync(method) 不携带 args，
        // PrepareArgs(null) 原样返回 null。
        Assert.Contains(method, new[] { "getSshInfo", "getSshConfig", "getDeviceSnapshot" });
        Assert.Null(WindowsBridge.PrepareArgs(null));
    }
}
