using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs B19 Compose/网关桥接方法参数字典的契约测试
/// （createCompose 四键、updateCompose 三键多行 content、
/// updateOpenrestyHttps 两键装箱 bool）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型
/// IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转
/// string、装箱值原样保留，null 值键不丢失。输入值用拼接构造，期望值独立
/// 手写，防止自证。
/// </summary>
public class ComposeGatewayBridgeContractTests
{
    [Fact]
    public void PrepareArgs_createCompose_dictionary_preserves_four_keys_including_null_file()
    {
        // 与 WindowsBridge.CreateComposeAsync(name, from, path, file) 调用点同形：
        // 四键 name / from / path / file，file 为 null 时键仍保留。
        // 输入值用拼接构造，期望值独立手写字面量。
        var args = new Dictionary<string, object?>
        {
            ["name"] = "we" + "b",
            ["from"] = "pa" + "th",
            ["path"] = "/opt/" + "web",
            ["file"] = null,
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(4, dict.Count);
        Assert.Equal("web", dict["name"]);
        Assert.Equal("path", dict["from"]);
        Assert.Equal("/opt/web", dict["path"]);
        // null 值不丢键：file 键存在且值为 null。
        Assert.True(dict.ContainsKey("file"));
        Assert.Null(dict["file"]);
    }

    [Fact]
    public void PrepareArgs_updateCompose_dictionary_preserves_multiline_content_verbatim()
    {
        // 与 WindowsBridge.UpdateComposeAsync(name, path, content) 调用点同形：
        // 三键 name / path / content。content 分段拼接构造，期望值独立手写。
        var args = new Dictionary<string, object?>
        {
            ["name"] = "we" + "b",
            ["path"] = "/opt/" + "web",
            ["content"] = "services:" + "\n" + "  we" + "b:",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(3, dict.Count);
        Assert.Equal("web", dict["name"]);
        Assert.Equal("/opt/web", dict["path"]);

        // 多行 content 逐字符保留：换行原样、无 \r 混入、末字符为 ':'。
        var content = Assert.IsType<string>(dict["content"]);
        Assert.Equal("services:\n  web:", content);
        Assert.Contains('\n', content);
        Assert.DoesNotContain('\r', content);
        Assert.Equal(':', content[^1]);
    }

    [Theory]
    [InlineData("enable", true)]
    [InlineData("disable", false)]
    public void PrepareArgs_updateOpenrestyHttps_dictionary_preserves_operate_and_boxed_bool(
        string operate, bool sslRejectHandshake)
    {
        // 与 WindowsBridge.UpdateOpenrestyHttpsAsync(operate, sslRejectHandshake)
        // 调用点同形：两键 operate / sslRejectHandshake。
        var args = new Dictionary<string, object?>
        {
            ["operate"] = operate,
            ["sslRejectHandshake"] = sslRejectHandshake,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(2, dict.Count);
        Assert.Equal(operate, dict["operate"]);

        // bool 参数在 object? 字典中装箱为 bool，类型与值均保留。
        var boxed = Assert.IsType<bool>(dict["sslRejectHandshake"]);
        Assert.Equal(sslRejectHandshake, boxed);
    }
}
