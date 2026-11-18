using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs AI 桥接方法参数字典的契约测试（B14：createAIModel /
/// recreateAIModel / deleteAIModel，null args 覆盖 getAIModels / getDashboard 无参调用点）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型
/// IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转 string、
/// 装箱类型原样（long 装箱为 Int64，不做数值提升）。期望值独立手写，防止自证。
/// </summary>
public class AIBridgeContractTests
{
    [Fact]
    public void PrepareArgs_createAIModel_dictionary_preserves_single_name_key_with_exact_value()
    {
        // 与 WindowsBridge.CreateAIModelAsync(name) 调用点同形：单键 name。
        var args = new Dictionary<string, object?>
        {
            ["name"] = "llama3:8b",
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("name", single.Key);
        Assert.Equal("llama3:8b", single.Value);
    }

    [Fact]
    public void PrepareArgs_recreateAIModel_dictionary_preserves_single_name_key_with_exact_value()
    {
        // 与 WindowsBridge.RecreateAIModelAsync(name) 调用点同形：单键 name。
        var args = new Dictionary<string, object?>
        {
            ["name"] = "qwen2:7b",
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("name", single.Key);
        Assert.Equal("qwen2:7b", single.Value);
    }

    [Fact]
    public void PrepareArgs_deleteAIModel_dictionary_preserves_single_id_key_as_boxed_long()
    {
        // 与 WindowsBridge.DeleteAIModelAsync(id) 调用点同形：id 装箱为 Int64。
        var args = new Dictionary<string, object?>
        {
            ["id"] = 11L,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("id", single.Key);
        // 装箱类型原样保持 Int64，不做数值提升（不变成 int / double）。
        Assert.Equal(typeof(long), single.Value!.GetType());
        Assert.Equal(11L, (long)single.Value);
    }

    [Theory]
    [InlineData("getAIModels")]
    [InlineData("getDashboard")]
    public void PrepareArgs_null_args_returns_null(string method)
    {
        // 与 GetAIModelsAsync() / GetDashboardAsync() 无参调用点同形：
        // InvokeWithRetryAsync(method) 不携带 args，PrepareArgs(null) 原样返回 null。
        Assert.Contains(method, new[] { "getAIModels", "getDashboard" });
        Assert.Null(WindowsBridge.PrepareArgs(null));
    }
}
