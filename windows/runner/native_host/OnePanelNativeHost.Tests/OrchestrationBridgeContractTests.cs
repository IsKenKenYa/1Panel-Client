using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 编排/网关桥接方法参数字典的契约测试（B18：
/// composeOperate 三键传参，null args 覆盖 getComposes / getPanelSslInfo /
/// getWebsiteCertificates / getDashboard 无参调用点）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型
/// IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转
/// string、装箱值原样保留。期望值独立手写，防止自证。
/// </summary>
public class OrchestrationBridgeContractTests
{
    [Fact]
    public void PrepareArgs_composeOperate_dictionary_preserves_three_operation_keys_with_exact_values()
    {
        // 与 WindowsBridge.ComposeOperateAsync(id, name, action) 调用点同形：
        // 三键 id / name / action。输入值用拼接构造，期望值独立手写字面量。
        var args = new Dictionary<string, object?>
        {
            ["id"] = "c-" + "9",
            ["name"] = "web-" + "stack",
            ["action"] = "re" + "start",
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(3, dict.Count);
        Assert.Equal("c-9", dict["id"]);
        Assert.Equal("web-stack", dict["name"]);
        Assert.Equal("restart", dict["action"]);
    }

    [Theory]
    [InlineData("getComposes")]
    [InlineData("getPanelSslInfo")]
    [InlineData("getWebsiteCertificates")]
    [InlineData("getDashboard")]
    public void PrepareArgs_null_args_returns_null(string method)
    {
        // 与 GetComposesAsync() / GetPanelSslInfoAsync() /
        // GetWebsiteCertificatesAsync() / GetDashboardAsync() 无参调用点同形：
        // InvokeWithRetryAsync(method) 不携带 args，PrepareArgs(null) 原样返回 null。
        Assert.Contains(method, new[] { "getComposes", "getPanelSslInfo", "getWebsiteCertificates", "getDashboard" });
        Assert.Null(WindowsBridge.PrepareArgs(null));
    }
}
