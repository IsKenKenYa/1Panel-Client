using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs B22 桥接方法参数字典的契约测试
/// （applyCertificate 单键 id；createCompose template 形态——签名扩展
/// templateId 可选参数后，调用点字典含 "template" 键共五键）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型
/// IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转
/// string、装箱值原样保留（long 不被降为 int / double / 字符串），null 值键
/// 不丢失。输入值用拼接/算术构造，期望值独立手写，防止自证。
/// </summary>
public class B22BridgeContractTests
{
    [Fact]
    public void PrepareArgs_applyCertificate_dictionary_preserves_single_id_key_as_exact_long()
    {
        // 与 WindowsBridge.ApplyCertificateAsync(id) 调用点同形：单键 id，
        // 证书 ID 为 long。
        var id = 14L + 1L;
        var args = new Dictionary<string, object?>
        {
            ["id"] = id,
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        var single = Assert.Single(dict);
        Assert.Equal("id", single.Key);
        // long 装箱值原样保留：仍为 long 类型且值精确（15），不被字符串化。
        Assert.IsType<long>(single.Value);
        Assert.Equal(15L, (long)single.Value!);
        Assert.NotEqual("15", single.Value);
    }

    [Fact]
    public void PrepareArgs_createCompose_templateForm_dictionary_preserves_five_keys_with_null_path_and_file()
    {
        // 与 WindowsBridge.CreateComposeAsync(name, from, path, file, templateId)
        // template 形态调用点同形：五键 name / from / path / file / template，
        // path 与 file 为 null 时键仍保留，templateId 装箱后为 long。
        long? templateId = 2L + 1L;
        var args = new Dictionary<string, object?>
        {
            ["name"] = "we" + "b",
            ["from"] = "temp" + "late",
            ["path"] = null,
            ["file"] = null,
            ["template"] = templateId,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(5, dict.Count);
        Assert.Equal("web", Assert.IsType<string>(dict["name"]));
        Assert.Equal("template", Assert.IsType<string>(dict["from"]));
        // null 值键不丢失：键存在且值仍为 null。
        Assert.True(dict.ContainsKey("path"));
        Assert.Null(dict["path"]);
        Assert.True(dict.ContainsKey("file"));
        Assert.Null(dict["file"]);
        // templateId 装箱后仍为 long：类型精确、值独立手写比对，不被字符串化。
        Assert.IsType<long>(dict["template"]);
        Assert.Equal(3L, (long)dict["template"]!);
        Assert.NotEqual("3", dict["template"]);
    }
}
