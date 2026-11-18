using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 脚本库桥接方法参数字典的契约测试（B20：
/// deleteScripts 字典复制语义，getScripts / getDashboard 无参调用点）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型
/// IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转
/// string、装箱值原样保留（List&lt;long&gt; 引用不序列化、不被降级为 double）。期望值
/// 独立手写，防止自证。
/// </summary>
public class ScriptLibraryBridgeContractTests
{
    [Fact]
    public void PrepareArgs_deleteScripts_dictionary_preserves_single_ids_key_with_exact_list_elements()
    {
        // 与 WindowsBridge.DeleteScriptsAsync(IReadOnlyList<long> ids) 调用点同形：
        // 单键 ids。输入元素用算式构造，期望值独立手写字面量。
        var ids = new List<long> { 3L + 4L, 8L + 1L };
        var args = new Dictionary<string, object?>
        {
            ["ids"] = ids,
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("ids", single.Key);
        // List<long> 装箱值原样保留：仍为 List<long>，不序列化为数组、不降级为 double。
        var value = Assert.IsType<List<long>>(single.Value);
        Assert.Equal(2, value.Count);
        Assert.Equal(7L, value[0]);
        Assert.Equal(9L, value[1]);
    }

    [Theory]
    [InlineData("getScripts")]
    [InlineData("getDashboard")]
    public void PrepareArgs_null_args_returns_null(string method)
    {
        // 与 GetScriptsAsync() / GetDashboardAsync() 无参调用点同形：
        // InvokeWithRetryAsync(method) 不携带 args，PrepareArgs(null) 原样返回 null。
        Assert.Contains(method, new[] { "getScripts", "getDashboard" });
        Assert.Null(WindowsBridge.PrepareArgs(null));
    }
}
