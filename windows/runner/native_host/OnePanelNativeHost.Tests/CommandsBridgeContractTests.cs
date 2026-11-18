using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 命令库/Ollama 发现流桥接方法参数字典的契约测试（B17：
/// createCommand / deleteCommand，null args 覆盖 getCommands / getOllamaContext 无参
/// 调用点；getGroups 经 InvokeJsonAsync 以单键 type 字典走同一复制路径并返回
/// JsonElement?）。Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在
/// 泛型 IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转
/// string、装箱值原样保留（long 装箱为 Int64，不做数值提升）。期望值独立手写，防止自证。
/// </summary>
public class CommandsBridgeContractTests
{
    [Fact]
    public void PrepareArgs_createCommand_dictionary_preserves_three_keys_with_long_groupID()
    {
        // 与 WindowsBridge.CreateCommandAsync(name, command, groupID) 调用点同形：
        // 三键 name + command + groupID，groupID 装箱为 Int64。输入用拼接构造，
        // 期望值独立手写字面量。
        var args = new Dictionary<string, object?>
        {
            ["name"] = "back" + "up",
            ["command"] = "tar" + " czf",
            ["groupID"] = 1L + 1L,
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(3, dict.Count);
        Assert.Equal("backup", dict["name"]);
        Assert.Equal("tar czf", dict["command"]);
        // long 装箱值原样保留：仍为 Int64 类型且值为 2，不被转成 double 或字符串。
        Assert.Equal(typeof(long), dict["groupID"]!.GetType());
        Assert.Equal(2L, (long)dict["groupID"]!);
        Assert.Equal("2", dict["groupID"]!.ToString());
    }

    [Fact]
    public void PrepareArgs_deleteCommand_dictionary_preserves_single_long_id()
    {
        // 与 WindowsBridge.DeleteCommandAsync(id) 调用点同形：单键 id，装箱为 Int64。
        var args = new Dictionary<string, object?>
        {
            ["id"] = 12L + 1L,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("id", single.Key);
        Assert.Equal(typeof(long), single.Value!.GetType());
        Assert.Equal(13L, (long)single.Value);
    }

    [Theory]
    [InlineData("getCommands")]
    [InlineData("getOllamaContext")]
    public void PrepareArgs_null_args_returns_null(string method)
    {
        // 与 GetCommandsAsync() / GetOllamaContextAsync() 无参调用点同形：
        // 不携带 args，PrepareArgs(null) 原样返回 null。
        Assert.Contains(method, new[] { "getCommands", "getOllamaContext" });
        Assert.Null(WindowsBridge.PrepareArgs(null));
    }
}
