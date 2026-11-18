using System.Text.Json;
using System.Threading.Tasks;

namespace OnePanelNativeHost;

/// <summary>
/// WindowsBridge B4 数据库深度部分类
/// （契约单一事实源：docs/development/modules/b4_database_channel_contract.md，11 读 + 12 写）。
/// 读方法 GetXxxAsync 返回 Task&lt;JsonElement?&gt;（InvokeWithRetryAsync 风格，透传 Dart 信封）；
/// 写方法 XxxAsync 返回 Task&lt;bool&gt;（InvokeAsync + IsSuccess，{success, error?} 信封）。
/// 密码一律以明文透传，base64 编码由 Dart 底层/Handler 负责（契约实现约定 2）；
/// 必填缺失快速失败同样在 Dart handler 层，C# 桥层只做扁平键透传（契约实现约定 1）。
/// </summary>
public static partial class WindowsBridge
{
    // ── B4 读通道（11 个） ──────────────────────────────────────────────

    /// <summary>数据库基础信息（POST /databases/common/info）。</summary>
    public static async Task<JsonElement?> GetDatabaseBaseInfoAsync(string type, string name)
    {
        return await InvokeWithRetryAsync("getDatabaseBaseInfo",
            new Dictionary<string, object?> { ["type"] = type, ["name"] = name });
    }

    /// <summary>数据库配置文件内容（POST /databases/common/load/file；
    /// conf 类型的 type+'-conf' 变换在 Dart 底层 loadDatabaseConfigFile 内完成）。</summary>
    public static async Task<JsonElement?> GetDatabaseConfFileAsync(string type, string name)
    {
        return await InvokeWithRetryAsync("getDatabaseConfFile",
            new Dictionary<string, object?> { ["type"] = type, ["name"] = name });
    }

    /// <summary>MySQL 运行变量（POST /databases/variables）。</summary>
    public static async Task<JsonElement?> GetMysqlVariablesAsync(string type, string name)
    {
        return await InvokeWithRetryAsync("getMysqlVariables",
            new Dictionary<string, object?> { ["type"] = type, ["name"] = name });
    }

    /// <summary>MySQL 运行状态（POST /databases/status）。</summary>
    public static async Task<JsonElement?> GetMysqlStatusAsync(string type, string name)
    {
        return await InvokeWithRetryAsync("getMysqlStatus",
            new Dictionary<string, object?> { ["type"] = type, ["name"] = name });
    }

    /// <summary>Redis 配置（POST /databases/redis/conf）。</summary>
    public static async Task<JsonElement?> GetRedisConfAsync(string type, string name)
    {
        return await InvokeWithRetryAsync("getRedisConf",
            new Dictionary<string, object?> { ["type"] = type, ["name"] = name });
    }

    /// <summary>Redis 运行状态（POST /databases/redis/status）。</summary>
    public static async Task<JsonElement?> GetRedisStatusAsync(string type, string name)
    {
        return await InvokeWithRetryAsync("getRedisStatus",
            new Dictionary<string, object?> { ["type"] = type, ["name"] = name });
    }

    /// <summary>Redis 持久化配置（POST /databases/redis/persistence/conf）。</summary>
    public static async Task<JsonElement?> GetRedisPersistenceAsync(string type, string name)
    {
        return await InvokeWithRetryAsync("getRedisPersistence",
            new Dictionary<string, object?> { ["type"] = type, ["name"] = name });
    }

    /// <summary>数据库远程访问配置（POST /databases/remote）。</summary>
    public static async Task<JsonElement?> GetDatabaseRemoteAccessAsync(string type, string name)
    {
        return await InvokeWithRetryAsync("getDatabaseRemoteAccess",
            new Dictionary<string, object?> { ["type"] = type, ["name"] = name });
    }

    /// <summary>数据库用户列表（POST /databases/users/search，database 为 lookupName）。</summary>
    public static async Task<JsonElement?> GetDatabaseUsersAsync(string database)
    {
        return await InvokeWithRetryAsync("getDatabaseUsers",
            new Dictionary<string, object?> { ["database"] = database });
    }

    /// <summary>数据库授权列表（POST /databases/grants/search，database 为 lookupName）。</summary>
    public static async Task<JsonElement?> GetDatabaseGrantsAsync(string database)
    {
        return await InvokeWithRetryAsync("getDatabaseGrants",
            new Dictionary<string, object?> { ["database"] = database });
    }

    /// <summary>数据库备份记录（POST /backups/record/search，detailName 为库名）。</summary>
    public static async Task<JsonElement?> GetDatabaseBackupsAsync(
        string type, string name, string detailName)
    {
        return await InvokeWithRetryAsync("getDatabaseBackups", new Dictionary<string, object?>
        {
            ["type"] = type,
            ["name"] = name,
            ["detailName"] = detailName,
        });
    }

    // ── B4 写通道（12 个） ─────────────────────────────────────────────

    /// <summary>保存数据库配置文件（POST /databases/common/update/conf）。</summary>
    public static async Task<bool> UpdateDatabaseConfFileAsync(
        string type, string database, string file)
    {
        var result = await InvokeAsync("updateDatabaseConfFile", new Dictionary<string, object?>
        {
            ["type"] = type,
            ["database"] = database,
            ["file"] = file,
        });
        return IsSuccess(result);
    }

    /// <summary>更新 MySQL 运行变量（POST /databases/variables/update；
    /// variables 为 [{param, value}] 字典列表，实例直传由 StandardMessageCodec 编码）。</summary>
    public static async Task<bool> UpdateMysqlVariablesAsync(
        string type, string database, List<object> variables)
    {
        var result = await InvokeAsync("updateMysqlVariables", new Dictionary<string, object?>
        {
            ["type"] = type,
            ["database"] = database,
            ["variables"] = variables,
        });
        return IsSuccess(result);
    }

    /// <summary>更新 Redis 配置（POST /databases/redis/conf/update，值均为字符串）。</summary>
    public static async Task<bool> UpdateRedisConfAsync(
        string dbType, string database, string timeout, string maxclients, string maxmemory)
    {
        var result = await InvokeAsync("updateRedisConf", new Dictionary<string, object?>
        {
            ["dbType"] = dbType,
            ["database"] = database,
            ["timeout"] = timeout,
            ["maxclients"] = maxclients,
            ["maxmemory"] = maxmemory,
        });
        return IsSuccess(result);
    }

    /// <summary>更新 Redis 持久化（POST /databases/redis/persistence/update；
    /// type 为 aof|rbd，appendonly/appendfsync/save 按类型二选一，可空键显式保留）。</summary>
    public static async Task<bool> UpdateRedisPersistenceAsync(
        string database, string type, string? appendonly, string? appendfsync,
        string? save, string dbType)
    {
        var result = await InvokeAsync("updateRedisPersistence", new Dictionary<string, object?>
        {
            ["database"] = database,
            ["type"] = type,
            ["appendonly"] = appendonly,
            ["appendfsync"] = appendfsync,
            ["save"] = save,
            ["dbType"] = dbType,
        });
        return IsSuccess(result);
    }

    /// <summary>修改 Redis 密码（POST /databases/redis/password；
    /// password 明文透传，base64 编码在 Dart 底层完成）。</summary>
    public static async Task<bool> ChangeRedisPasswordAsync(string database, string password)
    {
        var result = await InvokeAsync("changeRedisPassword",
            new Dictionary<string, object?> { ["database"] = database, ["password"] = password });
        return IsSuccess(result);
    }

    /// <summary>更新数据库远程访问（POST /databases/change/access；
    /// from 为原权限值，value 仅允许 '%'|'localhost'）。</summary>
    public static async Task<bool> UpdateDatabaseAccessAsync(
        int id, string from, string type, string database, string value)
    {
        var result = await InvokeAsync("updateDatabaseAccess", new Dictionary<string, object?>
        {
            ["id"] = id,
            ["from"] = from,
            ["type"] = type,
            ["database"] = database,
            ["value"] = value,
        });
        return IsSuccess(result);
    }

    /// <summary>修改数据库用户密码（POST /databases/users/password；
    /// password 明文透传，base64 编码在 Dart 底层完成）。</summary>
    public static async Task<bool> UpdateDatabaseUserPasswordAsync(
        string database, string username, string host, string password)
    {
        var result = await InvokeAsync("updateDatabaseUserPassword", new Dictionary<string, object?>
        {
            ["database"] = database,
            ["username"] = username,
            ["host"] = host,
            ["password"] = password,
        });
        return IsSuccess(result);
    }

    /// <summary>新建数据库用户（POST /databases/users；
    /// password 明文透传由 Dart 层 base64，description 可选键 null 保留）。</summary>
    public static async Task<bool> CreateDatabaseUserAsync(
        string database, string username, string host, string password, string? description)
    {
        var result = await InvokeAsync("createDatabaseUser", new Dictionary<string, object?>
        {
            ["database"] = database,
            ["username"] = username,
            ["host"] = host,
            ["password"] = password,
            ["description"] = description,
        });
        return IsSuccess(result);
    }

    /// <summary>删除数据库用户（POST /databases/users/del）。</summary>
    public static async Task<bool> DeleteDatabaseUserAsync(
        string database, string username, string host)
    {
        var result = await InvokeAsync("deleteDatabaseUser", new Dictionary<string, object?>
        {
            ["database"] = database,
            ["username"] = username,
            ["host"] = host,
        });
        return IsSuccess(result);
    }

    /// <summary>编辑数据库用户（POST /databases/users/update，host→newHost 迁移 + 描述）。</summary>
    public static async Task<bool> UpdateDatabaseUserAsync(
        string database, string username, string host, string newHost, string description)
    {
        var result = await InvokeAsync("updateDatabaseUser", new Dictionary<string, object?>
        {
            ["database"] = database,
            ["username"] = username,
            ["host"] = host,
            ["newHost"] = newHost,
            ["description"] = description,
        });
        return IsSuccess(result);
    }

    /// <summary>授权数据库给用户（POST /databases/grants；db 为被授权库名，database 为 lookupName）。</summary>
    public static async Task<bool> GrantDatabaseUserAsync(
        string database, string db, string username, string host)
    {
        var result = await InvokeAsync("grantDatabaseUser", new Dictionary<string, object?>
        {
            ["database"] = database,
            ["db"] = db,
            ["username"] = username,
            ["host"] = host,
        });
        return IsSuccess(result);
    }

    /// <summary>撤销用户数据库授权（POST /databases/grants/del；db 与 database 键并存）。</summary>
    public static async Task<bool> RevokeDatabaseGrantAsync(
        string database, string db, string username, string host)
    {
        var result = await InvokeAsync("revokeDatabaseGrant", new Dictionary<string, object?>
        {
            ["database"] = database,
            ["db"] = db,
            ["username"] = username,
            ["host"] = host,
        });
        return IsSuccess(result);
    }
}
