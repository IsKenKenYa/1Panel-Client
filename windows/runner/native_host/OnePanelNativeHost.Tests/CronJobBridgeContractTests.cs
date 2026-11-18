using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 定时任务方法参数字典的契约测试（B12：createCronJob / updateCronJob /
/// handleCronJobOnce）。Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型
/// IDictionary&lt;string, object?&gt; 之前），经 ConvertDictionary 复制为新字典：键转 string、
/// null 值键保留、装箱类型原样（long 装箱为 Int64，不做数值提升）。
/// 期望值独立手写，防止自证。
/// </summary>
public class CronJobBridgeContractTests
{
    [Theory]
    [InlineData("backup-database", "0 2 * * *")]
    [InlineData("清理任务日志", "*/30 3 * * *")]
    public void PrepareArgs_createCronJob_dictionary_preserves_keys_values_null_script_and_long_groupID(
        string name, string spec)
    {
        // 与 WindowsBridge.CreateCronJobAsync(name, spec, script, groupID) 调用点同形：
        // script 为可空引用传 null，groupID 装箱为 Int64（含 0L 边界值）。
        var args = new Dictionary<string, object?>
        {
            ["name"] = name,
            ["spec"] = spec,
            ["script"] = null,
            ["groupID"] = 0L,
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(4, dict.Count);
        Assert.Equal(name, dict["name"]);
        Assert.Equal(spec, dict["spec"]);
        Assert.True(dict.ContainsKey("script"));
        Assert.Null(dict["script"]);
        Assert.Equal(typeof(long), dict["groupID"]!.GetType());
        Assert.Equal(0L, (long)dict["groupID"]!);
    }

    [Fact]
    public void PrepareArgs_updateCronJob_dictionary_preserves_id_name_spec_null_script_and_long_groupID()
    {
        // 与 WindowsBridge.UpdateCronJobAsync(id, name, spec, script, groupID) 调用点同形：
        // id 装箱为 Int64，script 为可空引用传 null，groupID 装箱为 Int64（含 0L 边界值）。
        var args = new Dictionary<string, object?>
        {
            ["id"] = 9L,
            ["name"] = "renew-website-cert",
            ["spec"] = "0 4 * * 1",
            ["script"] = null,
            ["groupID"] = 0L,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(5, dict.Count);
        Assert.Equal(typeof(long), dict["id"]!.GetType());
        Assert.Equal(9L, (long)dict["id"]!);
        Assert.Equal("renew-website-cert", dict["name"]);
        Assert.Equal("0 4 * * 1", dict["spec"]);
        Assert.True(dict.ContainsKey("script"));
        Assert.Null(dict["script"]);
        Assert.Equal(typeof(long), dict["groupID"]!.GetType());
        Assert.Equal(0L, (long)dict["groupID"]!);
    }

    [Fact]
    public void PrepareArgs_handleCronJobOnce_single_id_key_stays_boxed_long()
    {
        // 与 WindowsBridge.HandleCronJobOnceAsync(long id) 调用点同形：long 装箱为 Int64。
        var args = new Dictionary<string, object?> { ["id"] = 3L };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.NotSame(args, dict);
        Assert.Single(dict);
        Assert.Equal(typeof(long), dict["id"]!.GetType());
        Assert.Equal(3L, (long)dict["id"]!);
    }
}
