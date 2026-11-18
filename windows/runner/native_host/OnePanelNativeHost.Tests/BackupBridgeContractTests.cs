using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 备份方法参数字典的契约测试（B13：deleteBackup / restoreBackup，
/// null args 覆盖 getBackups / getDashboard 无参调用点）。Dictionary&lt;string, object?&gt; 命中
/// 非泛型 IDictionary 分支（分支顺序在泛型 IDictionary&lt;string, object?&gt; 之前），经
/// ConvertDictionary 复制为新字典：键转 string、null 值键保留、装箱类型原样（long 装箱为
/// Int64，不做数值提升）。期望值独立手写，防止自证。
/// </summary>
public class BackupBridgeContractTests
{
    [Fact]
    public void PrepareArgs_deleteBackup_dictionary_preserves_four_keys_with_long_id_and_non_null_strings()
    {
        // 与 WindowsBridge.DeleteBackupAsync(id, name, type, status) 调用点同形：
        // id 装箱为 Int64，name/type/status 为非空字符串。
        var args = new Dictionary<string, object?>
        {
            ["id"] = 6L,
            ["name"] = "db-app-20240601120000",
            ["type"] = "database",
            ["status"] = "Success",
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(4, dict.Count);
        Assert.Equal(typeof(long), dict["id"]!.GetType());
        Assert.Equal(6L, (long)dict["id"]!);
        Assert.Equal("db-app-20240601120000", dict["name"]);
        Assert.Equal("database", dict["type"]);
        Assert.Equal("Success", dict["status"]);
    }

    [Fact]
    public void PrepareArgs_restoreBackup_dictionary_preserves_seven_keys_with_null_detailName_and_long_ids()
    {
        // 与 WindowsBridge.RestoreBackupAsync(id, name, type, detailName, fileName, fileDir,
        // downloadAccountID) 调用点同形：detailName 为可空引用传 null，id / downloadAccountID
        // 装箱为 Int64。
        var args = new Dictionary<string, object?>
        {
            ["id"] = 6L,
            ["name"] = "app-1panel-v1",
            ["type"] = "app",
            ["detailName"] = null,
            ["fileName"] = "app_1panel_20240601120000.tar.gz",
            ["fileDir"] = "/opt/1panel/backups/app",
            ["downloadAccountID"] = 2L,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(7, dict.Count);
        Assert.Equal(typeof(long), dict["id"]!.GetType());
        Assert.Equal(6L, (long)dict["id"]!);
        Assert.Equal("app-1panel-v1", dict["name"]);
        Assert.Equal("app", dict["type"]);
        Assert.True(dict.ContainsKey("detailName"));
        Assert.Null(dict["detailName"]);
        Assert.Equal("app_1panel_20240601120000.tar.gz", dict["fileName"]);
        Assert.Equal("/opt/1panel/backups/app", dict["fileDir"]);
        Assert.Equal(typeof(long), dict["downloadAccountID"]!.GetType());
        Assert.Equal(2L, (long)dict["downloadAccountID"]!);
    }

    [Theory]
    [InlineData("getBackups")]
    [InlineData("getDashboard")]
    public void PrepareArgs_null_args_returns_null(string method)
    {
        // 与 GetBackupsAsync() / GetDashboardAsync() 无参调用点同形：
        // InvokeWithRetryAsync(method) 不携带 args，PrepareArgs(null) 原样返回 null。
        Assert.Contains(method, new[] { "getBackups", "getDashboard" });
        Assert.Null(WindowsBridge.PrepareArgs(null));
    }
}
