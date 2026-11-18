using System.Text.Json;
using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge B4 数据库深度 23 个桥方法的 payload 组装契约测试
/// （契约单一事实源：docs/development/modules/b4_database_channel_contract.md，11 读 + 12 写）。
/// - 读通道 golden：EncodeMethodCall 字节独立手写对齐 Dart StandardMethodCodec
///   （格式基准同 GoldenVectors.g.cs：string=0x07+变长 size+UTF8、map=0x0d、list=0x0c、null=0x00）；
/// - 含数组参数的写：variables 为 List&lt;object&gt;（字典列表），PrepareArgs 保留实例由 codec 直传；
/// - 写通道 bool 判定：无通道时 InvokeAsync 返回 null → IsSuccess=false；
///   成功/失败信封语义经 internal ErrorTextOf 实证（null=成功）；
/// - 缺参行为：契约实现约定 1 规定必填缺失快速失败在 Dart handler 层，
///   C# 桥层只做扁平键透传不做校验（本文件缺参透传用例实证不抛异常）；
///   可选键为 null 时显式保留不丢键（updateRedisPersistence / createDatabaseUser 实证）。
/// 期望值独立手写，防止自证。
/// </summary>
public class DatabaseDeepBridgeContractTests
{
    // ── 读通道 golden（真实通道字节） ─────────────────────────────────

    [Fact]
    public void EncodeMethodCall_getDatabaseBaseInfo_matches_Dart_StandardMethodCodec_bytes()
    {
        // 与 WindowsBridge.GetDatabaseBaseInfoAsync 调用点同形（读通道 {type, name}）。
        var args = new Dictionary<string, object?> { ["type"] = "mysql", ["name"] = "app_db" };

        var encoded = WindowsBridge.Codec.EncodeMethodCall(
            "getDatabaseBaseInfo", WindowsBridge.PrepareArgs(args));

        Assert.Equal(
            "0713" + "676574446174616261736542617365496e666f" // string "getDatabaseBaseInfo"
            + "0d02" // map(2)
            + "070474797065" + "07056d7973716c" // type: "mysql"
            + "07046e616d65" + "07066170705f6462", // name: "app_db"
            Convert.ToHexString(encoded).ToLowerInvariant());
    }

    // ── 写通道 golden（含数组参数） ───────────────────────────────────

    [Fact]
    public void EncodeMethodCall_updateMysqlVariables_matches_Dart_StandardMethodCodec_bytes()
    {
        // 与 WindowsBridge.UpdateMysqlVariablesAsync 调用点同形（契约实现约定 1：
        // variables 为 List<object> 字典列表，字典内 value 为字符串）。
        var args = new Dictionary<string, object?>
        {
            ["type"] = "mysql",
            ["database"] = "app_db",
            ["variables"] = new List<object>
            {
                new Dictionary<string, object?>
                {
                    ["param"] = "max_connections",
                    ["value"] = "1000",
                },
            },
        };

        var encoded = WindowsBridge.Codec.EncodeMethodCall(
            "updateMysqlVariables", WindowsBridge.PrepareArgs(args));

        Assert.Equal(
            "0714" + "7570646174654d7973716c5661726961626c6573" // string "updateMysqlVariables"
            + "0d03" // map(3)
            + "070474797065" + "07056d7973716c" // type: "mysql"
            + "07086461746162617365" + "07066170705f6462" // database: "app_db"
            + "07097661726961626c6573" // "variables"
            + "0c01" // list(1)
            + "0d02" // map(2)
            + "0705706172616d" + "070f6d61785f636f6e6e656374696f6e73" // param: "max_connections"
            + "070576616c7565" + "070431303030", // value: "1000"
            Convert.ToHexString(encoded).ToLowerInvariant());
    }

    // ── 读通道扁平键 shape ────────────────────────────────────────────

    [Fact]
    public void PrepareArgs_getDatabaseUsers_keeps_single_database_key()
    {
        // 与 WindowsBridge.GetDatabaseUsersAsync 调用点同形（database 为 lookupName）。
        var args = new Dictionary<string, object?> { ["database"] = "app_db" };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.NotSame(args, dict);
        Assert.Single(dict);
        Assert.Equal("app_db", dict["database"]);
    }

    [Fact]
    public void PrepareArgs_getDatabaseBackups_keeps_3_keys()
    {
        // 与 WindowsBridge.GetDatabaseBackupsAsync 调用点同形（detailName 为库名）。
        var args = new Dictionary<string, object?>
        {
            ["type"] = "mysql",
            ["name"] = "app_db",
            ["detailName"] = "app_db",
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.Equal(3, dict.Count);
        Assert.Equal("mysql", dict["type"]);
        Assert.Equal("app_db", dict["name"]);
        Assert.Equal("app_db", dict["detailName"]);
    }

    // ── 写通道扁平键 shape ────────────────────────────────────────────

    [Fact]
    public void PrepareArgs_updateMysqlVariables_keeps_variables_list_instances()
    {
        // 与 WindowsBridge.UpdateMysqlVariablesAsync 调用点同形：List<object> 与
        // 内层字典实例原样保留（ConvertDictionary 只复制顶层），codec 直传。
        var item = new Dictionary<string, object?> { ["param"] = "wait_timeout", ["value"] = "600" };
        var variables = new List<object> { item };
        var args = new Dictionary<string, object?>
        {
            ["type"] = "mysql",
            ["database"] = "app_db",
            ["variables"] = variables,
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.Equal(3, dict.Count);
        Assert.Same(variables, dict["variables"]);
        var list = Assert.IsType<List<object>>(dict["variables"]);
        Assert.Same(item, list[0]);
        Assert.Equal("wait_timeout", ((Dictionary<string, object?>)list[0])["param"]);
    }

    [Fact]
    public void PrepareArgs_updateRedisPersistence_preserves_optional_null_keys()
    {
        // 与 WindowsBridge.UpdateRedisPersistenceAsync 调用点同形：aof 形态
        // （appendonly/appendfsync 有值、save 为 null）；rbd 形态反之。
        // 可空键 null 时显式保留，Dart handler 按 type 取用。
        var args = new Dictionary<string, object?>
        {
            ["database"] = "redis_db",
            ["type"] = "aof",
            ["appendonly"] = "yes",
            ["appendfsync"] = "everysec",
            ["save"] = null,
            ["dbType"] = "mysql",
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.Equal(6, dict.Count);
        Assert.Equal("redis_db", dict["database"]);
        Assert.Equal("aof", dict["type"]);
        Assert.Equal("yes", dict["appendonly"]);
        Assert.Equal("everysec", dict["appendfsync"]);
        Assert.True(dict.ContainsKey("save"));
        Assert.Null(dict["save"]);
        Assert.Equal("mysql", dict["dbType"]);
    }

    [Fact]
    public void PrepareArgs_updateDatabaseAccess_keeps_5_keys_with_boxed_int_id()
    {
        // 与 WindowsBridge.UpdateDatabaseAccessAsync 调用点同形（id 契约为 int，
        // value 仅允许 '%'|'localhost'，from 为原权限值）。
        var args = new Dictionary<string, object?>
        {
            ["id"] = 3,
            ["from"] = "%",
            ["type"] = "mysql",
            ["database"] = "app_db",
            ["value"] = "localhost",
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.Equal(5, dict.Count);
        Assert.Equal(typeof(int), dict["id"]!.GetType());
        Assert.Equal(3, (int)dict["id"]!);
        Assert.Equal("%", dict["from"]);
        Assert.Equal("localhost", dict["value"]);
    }

    [Fact]
    public void PrepareArgs_grantAndRevoke_keeps_db_and_database_distinct_keys()
    {
        // 与 WindowsBridge.GrantDatabaseUserAsync / RevokeDatabaseGrantAsync 调用点同形：
        // db（被授权库名）与 database（lookupName）是两个并存键，防混用回归。
        foreach (var method in new[] { "grantDatabaseUser", "revokeDatabaseGrant" })
        {
            var args = new Dictionary<string, object?>
            {
                ["database"] = "app_db",
                ["db"] = "other_db",
                ["username"] = "dev",
                ["host"] = "%",
            };

            var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

            Assert.Equal(4, dict.Count);
            Assert.Equal("app_db", dict["database"]);
            Assert.Equal("other_db", dict["db"]);
            Assert.Equal("dev", dict["username"]);
            Assert.Equal("%", dict["host"]);
        }
    }

    [Fact]
    public void PrepareArgs_createDatabaseUser_keeps_5_keys_with_null_description()
    {
        // 与 WindowsBridge.CreateDatabaseUserAsync 调用点同形：
        // password 明文透传（base64 由 Dart 底层负责，契约实现约定 2），
        // description 可选键 null 保留。
        var args = new Dictionary<string, object?>
        {
            ["database"] = "app_db",
            ["username"] = "dev",
            ["host"] = "%",
            ["password"] = "N3wPass!",
            ["description"] = null,
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.Equal(5, dict.Count);
        Assert.Equal("N3wPass!", dict["password"]);
        Assert.True(dict.ContainsKey("description"));
        Assert.Null(dict["description"]);
    }

    // ── 缺参行为：桥层透传不校验（快速失败在 Dart handler 层，契约实现约定 1） ──

    [Fact]
    public void PrepareArgs_missing_required_keys_passes_through_without_validation()
    {
        // 桥层无必填校验：缺 type/name 等键的字典原样复制不抛异常，
        // 由 Dart handler 侧按契约快速失败。
        var args = new Dictionary<string, object?> { ["database"] = "app_db" };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.Single(dict);
        Assert.Equal("app_db", dict["database"]);
    }

    // ── 写通道 bool 判定 ──────────────────────────────────────────────

    [Fact]
    public async Task UpdateRedisConfAsync_without_live_channel_returns_false()
    {
        // 无 Flutter messenger（未 Initialize）时 InvokeAsync 返回 null，
        // IsSuccess(null)=false：写通道 bool 判定对 null 结果必须收敛为失败而非异常。
        var success = await WindowsBridge.UpdateRedisConfAsync(
            "mysql", "app_db", "300", "10000", "512mb");

        Assert.False(success);
    }

    [Theory]
    [InlineData("""{"success":true}""", null)]
    [InlineData("""{"success":false,"error":"mysql variable update failed"}""",
        "mysql variable update failed")]
    [InlineData("""{"error":"missing success flag"}""", "missing success flag")]
    public void ErrorTextOf_write_envelope_semantics(string envelope, string? expectedError)
    {
        // 写通道 IsSuccess=true ⇔ ErrorTextOf=null（既有写方法共用该信封语义，
        // 失败时向原生 UI 透出真实服务端 error 文本）。
        using var doc = JsonDocument.Parse(envelope);

        Assert.Equal(expectedError, WindowsBridge.ErrorTextOf(doc.RootElement.Clone()));
    }
}
