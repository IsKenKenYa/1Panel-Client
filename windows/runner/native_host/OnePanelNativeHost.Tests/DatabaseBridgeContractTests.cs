using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 数据库方法参数字典的契约测试（B11：createDatabase / deleteDatabase /
/// updateDatabaseDescription / changeDatabasePassword）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型 IDictionary&lt;string, object?&gt; 之前），
/// 经 ConvertDictionary 复制为新字典：键转 string、null 值键保留、装箱类型原样（long?/long 装箱为 Int64，不做数值提升）。
/// 期望值独立手写，防止自证。
/// </summary>
public class DatabaseBridgeContractTests
{
    [Fact]
    public void PrepareArgs_createDatabase_dictionary_preserves_keys_values_and_boxed_types()
    {
        // 与 WindowsBridge.CreateDatabaseAsync 调用点同形：
        // (string, string, string?, string?, long?, string?, string?) → 可空引用传 null，long? 装箱为 Int64。
        var args = new Dictionary<string, object?>
        {
            ["name"] = "app_db",
            ["type"] = "mysql",
            ["description"] = null,
            ["address"] = null,
            ["port"] = 3306L,
            ["username"] = "root",
            ["password"] = "secret",
        };

        var result = WindowsBridge.PrepareArgs(args);

        // ConvertDictionary 复制为新字典，输入实例不被原样返回。
        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(7, dict.Count);
        Assert.Equal("app_db", dict["name"]);
        Assert.Equal("mysql", dict["type"]);
        Assert.True(dict.ContainsKey("description"));
        Assert.Null(dict["description"]);
        Assert.True(dict.ContainsKey("address"));
        Assert.Null(dict["address"]);
        Assert.Equal(typeof(long), dict["port"]!.GetType());
        Assert.Equal(3306L, (long)dict["port"]!);
        Assert.Equal("root", dict["username"]);
        Assert.Equal("secret", dict["password"]);
    }

    [Fact]
    public void PrepareArgs_deleteDatabase_id_stays_boxed_long()
    {
        // 与 WindowsBridge.DeleteDatabaseAsync(long id) 调用点同形：long 装箱为 Int64。
        var args = new Dictionary<string, object?> { ["id"] = 5L };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.NotSame(args, dict);
        Assert.Single(dict);
        Assert.Equal(typeof(long), dict["id"]!.GetType());
        Assert.Equal(5L, (long)dict["id"]!);
    }

    [Theory]
    [InlineData("description", "backup before upgrade")]
    [InlineData("password", "N3wPass!")]
    public void PrepareArgs_row_rebuild_dictionary_preserves_null_lookupName_and_long_id(
        string lastKey, string lastValue)
    {
        // 与 WindowsBridge.UpdateDatabaseDescriptionAsync / ChangeDatabasePasswordAsync 调用点同形：
        // 行字典字段回传（scope, lookupName?|name, engine?, source?, id?, description|password），
        // lookupName=null 键保留供 Dart 侧按 scope 选择查询键，long? id 装箱为 Int64。
        var args = new Dictionary<string, object?>
        {
            ["scope"] = "app",
            ["lookupName"] = null,
            ["name"] = "app_db",
            ["engine"] = "mysql",
            ["source"] = "app",
            ["id"] = 7L,
            [lastKey] = lastValue,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(7, dict.Count);
        Assert.Equal("app", dict["scope"]);
        Assert.True(dict.ContainsKey("lookupName"));
        Assert.Null(dict["lookupName"]);
        Assert.Equal("app_db", dict["name"]);
        Assert.Equal("mysql", dict["engine"]);
        Assert.Equal("app", dict["source"]);
        Assert.Equal(typeof(long), dict["id"]!.GetType());
        Assert.Equal(7L, (long)dict["id"]!);
        Assert.Equal(lastValue, dict[lastKey]);
    }

    [Fact]
    public void PrepareArgs_createDatabase_keeps_optional_keys_and_format_permission()
    {
        // B11 回归：与 CreateDatabaseAsync 本地建库调用点同形（9 键）。
        // 服务端 MysqlDBCreate 要求 format/permission 必填（生产 400 实证），
        // C# 侧对齐上游 frontend 表单默认：format=utf8mb4、permission='%'；
        // 本地表单 remote 连接信息为 null 时键保留（PrepareArgs 路径）。
        var args = new Dictionary<string, object?>
        {
            ["name"] = "e2e_winui3_db",
            ["type"] = "mysql",
            ["description"] = null,
            ["address"] = null,
            ["port"] = null,
            ["username"] = null,
            ["password"] = null,
            ["format"] = "utf8mb4",
            ["permission"] = "%",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.Equal(9, dict.Count);
        Assert.Equal("e2e_winui3_db", dict["name"]);
        Assert.Equal("utf8mb4", dict["format"]);
        Assert.Equal("%", dict["permission"]);
        Assert.True(dict.ContainsKey("address"));
        Assert.Null(dict["address"]);
    }
}
