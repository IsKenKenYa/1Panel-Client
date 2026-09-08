using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace OnePanelNativeHost;

public static class WindowsBridge
{
    // 与 Dart 侧 NativeChannelManager 同一通道（iOS/macOS 原生轨道共用）。
    private const string ChannelName = "com.onepanel.client/method";
    private static readonly TimeSpan DefaultTimeout = TimeSpan.FromSeconds(30);
    private const int MaxRetries = 2;

    private static IntPtr _messengerHandle;
    private static bool _flutterAvailable = true;

    private static readonly HashSet<string> RetryableMethods = new()
    {
        "getServers",
        "getFiles",
        "getSettings",
        "getContainers",
        "getApps",
        "getWebsites",
        "getFirewallRules",
        "getAIModels",
        "getDashboard",
        "getMonitoring",
        "getSshInfo",
        "getSshConfig",
        "getDeviceSnapshot",
        "getOperationLogs",
        "getLoginLogs",
        "getOpenrestySnapshot",
        "getCommands",
        "getGroups",
        "getComposes",
        "getPanelSslInfo",
        "getWebsiteCertificates",
        "getScripts",
    };

    public static void Initialize(IntPtr messengerHandle)
    {
        _messengerHandle = messengerHandle;
        _flutterAvailable = true;
    }

    public static async Task<string?> InvokeAsync(string method, object? args = null)
    {
        if (!_flutterAvailable || _messengerHandle == IntPtr.Zero)
        {
            return null;
        }

        byte[] encoded;
        try
        {
            encoded = Codec.EncodeMethodCall(method, PrepareArgs(args));
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[WindowsBridge] Encode failed for {method}: {ex.Message}");
            return null;
        }

        var responseBytes = await SendWithReplyAsync(encoded);
        if (responseBytes == null)
        {
            return null;
        }

        try
        {
            return Codec.DecodeResponse(responseBytes);
        }
        catch (Exception ex)
        {
            System.IO.File.AppendAllText(
                System.IO.Path.Combine(AppContext.BaseDirectory, "bridge_decode_errors.log"),
                $"{DateTime.Now:HH:mm:ss} {method}: {ex.Message}\n");
            return null;
        }
    }

    public static async Task<JsonElement?> GetServersAsync()
    {
        return await InvokeWithRetryAsync("getServers");
    }

    /// <summary>切换当前服务器（Dart 侧方法名 connectServer）。</summary>
    public static async Task<bool> SwitchServerAsync(string serverId)
    {
        var result = await InvokeWithRetryAsync(
            "connectServer", new Dictionary<string, object?> { ["id"] = serverId });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetFilesAsync(string path)
    {
        return await InvokeWithRetryAsync("getFiles", new Dictionary<string, object?> { ["path"] = path });
    }

    public static async Task<JsonElement?> GetSettingsAsync()
    {
        return await InvokeWithRetryAsync("getSettings");
    }

    /// <summary>宿主 L10n 数据源：当前 locale 整份 arb 字典（getTranslations）。</summary>
    public static async Task<JsonElement?> GetTranslationsAsync()
    {
        return await InvokeWithRetryAsync("getTranslations");
    }

    /// <summary>写客户端偏好（renderMode/language 等，Dart 侧 updateSetting）。</summary>
    public static async Task<bool> UpdateSettingAsync(string key, object? value)
    {
        var result = await InvokeAsync(
            "updateSetting", new Dictionary<string, object?> { ["key"] = key, ["value"] = value });
        return IsSuccess(result);
    }

    // ── 模块数据方法集（C# Presentation 层专用，全部经 Dart 业务核心） ──────

    public static async Task<JsonElement?> GetDashboardAsync()
    {
        return await InvokeWithRetryAsync("getDashboard");
    }

    public static async Task<JsonElement?> GetMonitoringAsync()
    {
        return await InvokeWithRetryAsync("getMonitoring");
    }

    public static async Task<JsonElement?> GetContainersAsync()
    {
        return await InvokeWithRetryAsync("getContainers");
    }

    public static async Task<bool> ToggleContainerStateAsync(string id, string state)
    {
        var result = await InvokeAsync("toggleContainerState",
            new Dictionary<string, object?> { ["id"] = id, ["state"] = state });
        return IsSuccess(result);
    }

    public static async Task<bool> RestartContainerAsync(string id)
    {
        var result = await InvokeAsync("restartContainer",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    public static async Task<bool> DeleteContainerAsync(string id)
    {
        var result = await InvokeAsync("deleteContainer",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetAppsAsync()
    {
        return await InvokeWithRetryAsync("getApps");
    }

    public static async Task<bool> StartAppAsync(string appId)
    {
        var result = await InvokeAsync("startApp",
            new Dictionary<string, object?> { ["appId"] = appId });
        return IsSuccess(result);
    }

    public static async Task<bool> StopAppAsync(string appId)
    {
        var result = await InvokeAsync("stopApp",
            new Dictionary<string, object?> { ["appId"] = appId });
        return IsSuccess(result);
    }

    public static async Task<bool> UninstallAppAsync(string appId)
    {
        var result = await InvokeAsync("uninstallApp",
            new Dictionary<string, object?> { ["appId"] = appId });
        return IsSuccess(result);
    }

    /// <summary>安装应用商店应用（appKey 如 openresty）。成功返回 null，
    /// 失败返回服务端/通道错误描述（与 CreateWebsiteAsync 错误透出同型）。</summary>
    public static async Task<string?> InstallAppAsync(
        string appKey, string? version, string? name)
    {
        var result = await InvokeJsonAsync("installApp", new Dictionary<string, object?>
        {
            ["appKey"] = appKey,
            ["version"] = version,
            ["name"] = name,
        });
        return ErrorTextOf(result);
    }

    public static async Task<JsonElement?> GetWebsitesAsync()
    {
        return await InvokeWithRetryAsync("getWebsites");
    }

    /// <summary>新建网站（deployment 缺省路径；Dart 侧 createWebsite）。
    /// 成功返回 null，失败返回服务端错误描述（建站对话框内联展示）。</summary>
    public static async Task<string?> CreateWebsiteAsync(
        string primaryDomain, string alias, long port, string? remark)
    {
        var result = await InvokeJsonAsync("createWebsite", new Dictionary<string, object?>
        {
            ["primaryDomain"] = primaryDomain,
            ["alias"] = alias,
            ["port"] = port,
            ["remark"] = remark,
        });
        return ErrorTextOf(result);
    }

    public static async Task<bool> ToggleWebsiteStatusAsync(long id, string currentStatus)
    {
        var result = await InvokeAsync("toggleWebsiteStatus",
            new Dictionary<string, object?> { ["id"] = id, ["currentStatus"] = currentStatus });
        return IsSuccess(result);
    }

    public static async Task<bool> DeleteWebsiteAsync(long id)
    {
        var result = await InvokeAsync("deleteWebsite",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    public static async Task<bool> CreateFolderAsync(string path)
    {
        var result = await InvokeAsync("createFolder",
            new Dictionary<string, object?> { ["path"] = path });
        return IsSuccess(result);
    }

    public static async Task<bool> DeleteFileAsync(string path)
    {
        var result = await InvokeAsync("deleteFile",
            new Dictionary<string, object?> { ["path"] = path });
        return IsSuccess(result);
    }

    /// <summary>新建数据库（本地部署最小集；remote 需连接信息）。</summary>
    public static async Task<bool> CreateDatabaseAsync(
        string name, string type, string? description,
        string? address, long? port, string? username, string? password)
    {
        var result = await InvokeAsync("createDatabase", new Dictionary<string, object?>
        {
            ["name"] = name,
            ["type"] = type,
            ["description"] = description,
            ["address"] = address,
            ["port"] = port,
            ["username"] = username,
            ["password"] = password,
        });
        return IsSuccess(result);
    }

    /// <summary>删除数据库。</summary>
    public static async Task<bool> DeleteDatabaseAsync(long id)
    {
        var result = await InvokeAsync("deleteDatabase",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    /// <summary>修改数据库描述（行字典字段回传，供 Dart 侧重建条目）。</summary>
    public static async Task<bool> UpdateDatabaseDescriptionAsync(
        string scope, string? lookupName, string? name,
        string? engine, string? source, long? id, string description)
    {
        var result = await InvokeAsync("updateDatabaseDescription", new Dictionary<string, object?>
        {
            ["scope"] = scope,
            ["lookupName"] = lookupName,
            ["name"] = name,
            ["engine"] = engine,
            ["source"] = source,
            ["id"] = id,
            ["description"] = description,
        });
        return IsSuccess(result);
    }

    /// <summary>修改数据库密码（行字典字段回传）。</summary>
    public static async Task<bool> ChangeDatabasePasswordAsync(
        string scope, string? lookupName, string? name,
        string? engine, string? source, long? id, string password)
    {
        var result = await InvokeAsync("changeDatabasePassword", new Dictionary<string, object?>
        {
            ["scope"] = scope,
            ["lookupName"] = lookupName,
            ["name"] = name,
            ["engine"] = engine,
            ["source"] = source,
            ["id"] = id,
            ["password"] = password,
        });
        return IsSuccess(result);
    }

    /// <summary>数据库列表（Dart 侧 getDatabases 合并所有 scope）。</summary>
    public static async Task<JsonElement?> GetDatabasesAsync()
    {
        return await InvokeWithRetryAsync("getDatabases");
    }

    public static async Task<JsonElement?> GetFirewallRulesAsync()
    {
        return await InvokeWithRetryAsync("getFirewallRules");
    }

    public static async Task<bool> AddFirewallRuleAsync(
        string port, string protocol, string address, string strategy)
    {
        var result = await InvokeAsync("addFirewallRule", new Dictionary<string, object?>
        {
            ["port"] = port,
            ["protocol"] = protocol,
            ["address"] = address,
            ["strategy"] = strategy,
        });
        return IsSuccess(result);
    }

    public static async Task<bool> DeleteFirewallRuleAsync(
        string port, string protocol, string address, string strategy)
    {
        var result = await InvokeAsync("deleteFirewallRule", new Dictionary<string, object?>
        {
            ["port"] = port,
            ["protocol"] = protocol,
            ["address"] = address,
            ["strategy"] = strategy,
        });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetCronJobsAsync()
    {
        return await InvokeWithRetryAsync("getCronJobs");
    }

    /// <summary>启停定时任务（Dart 侧按 currentStatus 取反）。</summary>
    public static async Task<bool> ToggleCronJobStatusAsync(long id, string currentStatus)
    {
        var result = await InvokeAsync("toggleCronJobStatus",
            new Dictionary<string, object?> { ["id"] = id, ["currentStatus"] = currentStatus });
        return IsSuccess(result);
    }

    /// <summary>删除定时任务。</summary>
    public static async Task<bool> DeleteCronJobAsync(long id)
    {
        var result = await InvokeAsync("deleteCronJob",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    /// <summary>绑定 AI 服务域名（消费 getOllamaContext 的 appInstallId）。</summary>
    public static async Task<bool> BindAIDomainAsync(
        long appInstallID, string domain, string? ipList)
    {
        var result = await InvokeAsync("bindAIDomain", new Dictionary<string, object?>
        {
            ["appInstallID"] = appInstallID,
            ["domain"] = domain,
            ["ipList"] = ipList,
        });
        return IsSuccess(result);
    }

    /// <summary>应用（申请/续签）证书。</summary>
    public static async Task<bool> ApplyCertificateAsync(long id)
    {
        var result = await InvokeAsync("applyCertificate",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    /// <summary>上传证书（粘贴形态：certificate + privateKey）。</summary>
    public static async Task<bool> UploadCertificateAsync(
        string certificate, string privateKey, string? description)
    {
        var result = await InvokeAsync("uploadCertificate", new Dictionary<string, object?>
        {
            ["certificate"] = certificate,
            ["privateKey"] = privateKey,
            ["description"] = description,
        });
        return IsSuccess(result);
    }

    /// <summary>新建 shell 定时任务（spec 为原生 cron 表达式）。</summary>
    public static async Task<bool> CreateCronJobAsync(
        string name, string spec, string? script, long groupID)
    {
        var result = await InvokeAsync("createCronJob", new Dictionary<string, object?>
        {
            ["name"] = name,
            ["spec"] = spec,
            ["script"] = script,
            ["groupID"] = groupID,
        });
        return IsSuccess(result);
    }

    /// <summary>编辑 shell 定时任务。</summary>
    public static async Task<bool> UpdateCronJobAsync(
        long id, string name, string spec, string? script, long groupID)
    {
        var result = await InvokeAsync("updateCronJob", new Dictionary<string, object?>
        {
            ["id"] = id,
            ["name"] = name,
            ["spec"] = spec,
            ["script"] = script,
            ["groupID"] = groupID,
        });
        return IsSuccess(result);
    }

    /// <summary>立即执行一次定时任务。</summary>
    public static async Task<bool> HandleCronJobOnceAsync(long id)
    {
        var result = await InvokeAsync("handleCronJobOnce",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    /// <summary>创建（拉取）Ollama 模型。</summary>
    public static async Task<bool> CreateAIModelAsync(string name)
    {
        var result = await InvokeAsync("createAIModel",
            new Dictionary<string, object?> { ["name"] = name });
        return IsSuccess(result);
    }

    /// <summary>重建 Ollama 模型。</summary>
    public static async Task<bool> RecreateAIModelAsync(string name)
    {
        var result = await InvokeAsync("recreateAIModel",
            new Dictionary<string, object?> { ["name"] = name });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetOperationLogsAsync()
    {
        return await InvokeWithRetryAsync("getOperationLogs");
    }

    public static async Task<JsonElement?> GetLoginLogsAsync()
    {
        return await InvokeWithRetryAsync("getLoginLogs");
    }

    /// <summary>系统日志文件内容（fileName 必填）。</summary>
    public static async Task<JsonElement?> GetSystemLogContentAsync(
        string fileName, bool useCoreLogs)
    {
        var json = await InvokeAsync("getSystemLogContent", new Dictionary<string, object?>
        {
            ["fileName"] = fileName,
            ["useCoreLogs"] = useCoreLogs,
        });
        if (json == null)
        {
            return null;
        }
        using var doc = JsonDocument.Parse(json);
        return doc.RootElement.Clone();
    }

    public static async Task<JsonElement?> GetOpenrestySnapshotAsync()
    {
        return await InvokeWithRetryAsync("getOpenrestySnapshot");
    }

    /// <summary>保存 OpenResty 配置源文本。</summary>
    public static async Task<bool> UpdateOpenrestyConfigAsync(string content)
    {
        var result = await InvokeAsync("updateOpenrestyConfig",
            new Dictionary<string, object?> { ["content"] = content });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetSshInfoAsync()
    {
        return await InvokeWithRetryAsync("getSshInfo");
    }

    public static async Task<JsonElement?> GetSshConfigAsync()
    {
        return await InvokeWithRetryAsync("getSshConfig");
    }

    public static async Task<JsonElement?> GetDeviceSnapshotAsync()
    {
        return await InvokeWithRetryAsync("getDeviceSnapshot");
    }

    /// <summary>SSH 服务操作（start/stop/restart）。</summary>
    public static async Task<bool> OperateSshAsync(string operation)
    {
        var result = await InvokeAsync("operateSsh",
            new Dictionary<string, object?> { ["operation"] = operation });
        return IsSuccess(result);
    }

    /// <summary>保存 SSH 原始配置。</summary>
    public static async Task<bool> SaveSshConfigAsync(string value)
    {
        var result = await InvokeAsync("saveSshConfig",
            new Dictionary<string, object?> { ["value"] = value });
        return IsSuccess(result);
    }

    /// <summary>DNS 连通性校验（非破坏）。</summary>
    public static async Task<bool> VerifyToolboxDnsAsync(string dns)
    {
        var result = await InvokeAsync("verifyToolboxDns",
            new Dictionary<string, object?> { ["dns"] = dns });
        return IsSuccess(result);
    }

    /// <summary>把 InvokeAsync 的 JSON 文本解析为 JsonElement（null 透传）。</summary>
    private static async Task<JsonElement?> InvokeJsonAsync(
        string method, object? args = null)
    {
        var json = await InvokeAsync(method, args);
        if (json == null)
        {
            return null;
        }
        using var doc = JsonDocument.Parse(json);
        return doc.RootElement.Clone();
    }

    public static async Task<JsonElement?> GetCommandsAsync()
    {
        return await InvokeWithRetryAsync("getCommands");
    }

    /// <summary>新建命令库条目。</summary>
    public static async Task<bool> CreateCommandAsync(
        string name, string command, long groupID)
    {
        var result = await InvokeAsync("createCommand", new Dictionary<string, object?>
        {
            ["name"] = name,
            ["command"] = command,
            ["groupID"] = groupID,
        });
        return IsSuccess(result);
    }

    /// <summary>删除命令库条目。</summary>
    public static async Task<bool> DeleteCommandAsync(long id)
    {
        var result = await InvokeAsync("deleteCommand",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetGroupsAsync(string type)
    {
        return await InvokeJsonAsync("getGroups",
            new Dictionary<string, object?> { ["type"] = type });
    }

    /// <summary>发现 Ollama 安装实例（AI 域名绑定前置）。</summary>
    public static async Task<JsonElement?> GetOllamaContextAsync()
    {
        return await InvokeJsonAsync("getOllamaContext");
    }

    public static async Task<JsonElement?> GetComposesAsync()
    {
        return await InvokeWithRetryAsync("getComposes");
    }

    /// <summary>Compose 项目操作。服务端 ComposeOperation 契约（2026-09-08
    /// swagger 实证）：{name 必填, operation∈up|start|restart|stop|down|delete|rebuild,
    /// path?} —— 无 id 字段，字段名为 operation。</summary>
    public static async Task<bool> ComposeOperateAsync(
        string name, string operation, string? path)
    {
        var result = await InvokeAsync("composeOperate", new Dictionary<string, object?>
        {
            ["name"] = name,
            ["operation"] = operation,
            ["path"] = path,
        });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetPanelSslInfoAsync()
    {
        return await InvokeWithRetryAsync("getPanelSslInfo");
    }

    public static async Task<JsonElement?> GetWebsiteCertificatesAsync()
    {
        return await InvokeWithRetryAsync("getWebsiteCertificates");
    }

    /// <summary>新建 Compose（from=path 需 path；from=raw 需 file 内容）。</summary>
    public static async Task<bool> CreateComposeAsync(
        string name, string from, string? path, string? file, long? templateId = null)
    {
        var result = await InvokeAsync("createCompose", new Dictionary<string, object?>
        {
            ["name"] = name,
            ["from"] = from,
            ["path"] = path,
            ["file"] = file,
            ["template"] = templateId,
        });
        return IsSuccess(result);
    }

    /// <summary>编辑 Compose 配置。</summary>
    public static async Task<bool> UpdateComposeAsync(
        string name, string path, string content)
    {
        var result = await InvokeAsync("updateCompose", new Dictionary<string, object?>
        {
            ["name"] = name,
            ["path"] = path,
            ["content"] = content,
        });
        return IsSuccess(result);
    }

    /// <summary>OpenResty 默认 HTTPS 跳转开关。</summary>
    public static async Task<bool> UpdateOpenrestyHttpsAsync(
        string operate, bool? sslRejectHandshake)
    {
        var result = await InvokeAsync("updateOpenrestyHttps", new Dictionary<string, object?>
        {
            ["operate"] = operate,
            ["sslRejectHandshake"] = sslRejectHandshake,
        });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetScriptsAsync()
    {
        return await InvokeWithRetryAsync("getScripts");
    }

    /// <summary>批量删除脚本。</summary>
    public static async Task<bool> DeleteScriptsAsync(IReadOnlyList<long> ids)
    {
        var result = await InvokeAsync("deleteScripts", new Dictionary<string, object?>
        {
            ["ids"] = ids,
        });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetBackupsAsync()
    {
        return await InvokeWithRetryAsync("getBackups");
    }

    /// <summary>删除备份记录（行字典整行回传，Dart 侧重建记录）。</summary>
    public static async Task<bool> DeleteBackupAsync(
        long id, string name, string type, string status)
    {
        var result = await InvokeAsync("deleteBackup", new Dictionary<string, object?>
        {
            ["id"] = id,
            ["name"] = name,
            ["type"] = type,
            ["status"] = status,
        });
        return IsSuccess(result);
    }

    /// <summary>恢复备份记录（行字典整行回传，含 fileName/fileDir）。</summary>
    public static async Task<bool> RestoreBackupAsync(
        long id, string name, string type, string? detailName,
        string fileName, string? fileDir, long downloadAccountID)
    {
        var result = await InvokeAsync("restoreBackup", new Dictionary<string, object?>
        {
            ["id"] = id,
            ["name"] = name,
            ["type"] = type,
            ["detailName"] = detailName,
            ["fileName"] = fileName,
            ["fileDir"] = fileDir,
            ["downloadAccountID"] = downloadAccountID,
        });
        return IsSuccess(result);
    }

    public static async Task<JsonElement?> GetAIModelsAsync()
    {
        return await InvokeWithRetryAsync("getAIModels");
    }

    public static async Task<bool> DeleteAIModelAsync(long id)
    {
        var result = await InvokeAsync("deleteAIModel",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    public static async Task<bool> AddServerAsync(string name, string url, string apiKey)
    {
        var result = await InvokeAsync("addServer", new Dictionary<string, object?>
        {
            ["name"] = name,
            ["url"] = url,
            ["apiKey"] = apiKey,
        });
        return IsSuccess(result);
    }

    public static async Task<bool> DeleteServerAsync(string id)
    {
        var result = await InvokeAsync("deleteServer",
            new Dictionary<string, object?> { ["id"] = id });
        return IsSuccess(result);
    }

    /// <summary>应用窗口底衬（Mica/云母Alt/亚克力/无）并持久化偏好。</summary>
    public static void ApplyWindowBackdrop(AppBackdropKind kind)
    {
        WindowBackdrop.SavePreferred(kind);
        if (App.MainWindow is { } window)
        {
            WindowBackdrop.Apply(window, kind);
        }
    }

    /// <summary>读取当前底衬偏好。</summary>
    public static AppBackdropKind LoadWindowBackdrop() => WindowBackdrop.LoadPreferred();

    private static bool IsSuccess(JsonElement? result)
    {
        return result?.ValueKind == JsonValueKind.Object &&
               result.Value.TryGetProperty("success", out var ok) &&
               ok.ValueKind == JsonValueKind.True;
    }

    /// <summary>null 表示成功信封；否则取 error 字段文本作为失败原因，
    /// 供表单对话框内联展示真实服务端错误而非通用提示。
    /// internal 供契约测试经 InternalsVisibleTo 直测信封语义。</summary>
    internal static string? ErrorTextOf(JsonElement? result)
    {
        if (IsSuccess(result))
        {
            return null;
        }
        if (result?.ValueKind == JsonValueKind.Object &&
            result.Value.TryGetProperty("error", out var err) &&
            err.ValueKind == JsonValueKind.String)
        {
            return err.GetString();
        }
        return "Method channel call failed.";
    }

    private static bool IsSuccess(string? json)
    {
        if (json == null) return false;
        try
        {
            using var doc = JsonDocument.Parse(json);
            return doc.RootElement.ValueKind == JsonValueKind.Object &&
                   doc.RootElement.TryGetProperty("success", out var ok) &&
                   ok.ValueKind == JsonValueKind.True;
        }
        catch
        {
            return false;
        }
    }

    private static async Task<JsonElement?> InvokeWithRetryAsync(string method, object? args = null)
    {
        for (int attempt = 0; attempt <= MaxRetries; attempt++)
        {
            try
            {
                var json = await InvokeAsync(method, args);
                if (json != null)
                {
                    using var doc = JsonDocument.Parse(json);
                    return doc.RootElement.Clone();
                }
            }
            catch (Exception ex)
            {
                System.IO.File.AppendAllText(
                    System.IO.Path.Combine(AppContext.BaseDirectory, "bridge_decode_errors.log"),
                    $"{DateTime.Now:HH:mm:ss} {method} attempt {attempt}: {ex.Message}\n");
            }

            if (attempt < MaxRetries && RetryableMethods.Contains(method))
            {
                await Task.Delay(500 * (attempt + 1));
            }
            else if (!RetryableMethods.Contains(method))
            {
                break;
            }
        }

        return null;
    }

    internal static object? PrepareArgs(object? args)
    {
        if (args == null) return null;
        if (args is IDictionary dict) return ConvertDictionary(dict);
        if (args is IDictionary<string, object?> sd) return sd;
        var json = JsonSerializer.Serialize(args);
        using var doc = JsonDocument.Parse(json);
        return ConvertJsonElement(doc.RootElement);
    }

    private static Dictionary<string, object?> ConvertDictionary(IDictionary dict)
    {
        var result = new Dictionary<string, object?>();
        foreach (DictionaryEntry entry in dict)
        {
            result[entry.Key?.ToString() ?? ""] = entry.Value;
        }
        return result;
    }

    private static object? ConvertJsonElement(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.Null => null,
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            // (object?) 防止三元分支把 long 统一成 double
            JsonValueKind.Number => element.TryGetInt64(out var l) ? (object?)l : element.GetDouble(),
            JsonValueKind.String => element.GetString(),
            JsonValueKind.Array => element.EnumerateArray().Select(ConvertJsonElement).ToList(),
            JsonValueKind.Object => element.EnumerateObject()
                .ToDictionary(p => p.Name, p => ConvertJsonElement(p.Value)),
            _ => null,
        };
    }

    private static async Task<byte[]?> SendWithReplyAsync(byte[] message)
    {
        if (!_flutterAvailable || _messengerHandle == IntPtr.Zero)
        {
            return null;
        }

        var pending = new PendingCall();

        pending.Callback = (data, dataSize, userData) =>
        {
            try
            {
                if (data == IntPtr.Zero || dataSize == 0)
                {
                    pending.Tcs.TrySetResult(null);
                    return;
                }

                var bytes = new byte[dataSize];
                Marshal.Copy(data, bytes, 0, (int)dataSize);
                pending.Tcs.TrySetResult(bytes);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[WindowsBridge] Reply callback error: {ex.Message}");
                pending.Tcs.TrySetResult(null);
            }
            finally
            {
                if (userData != IntPtr.Zero)
                {
                    GCHandle.FromIntPtr(userData).Free();
                }
            }
        };

        var handle = GCHandle.Alloc(pending);

        try
        {
            bool sent = FlutterDesktopMessengerSendWithReply(
                _messengerHandle,
                ChannelName,
                message,
                (ulong)message.Length,
                pending.Callback,
                GCHandle.ToIntPtr(handle));

            if (!sent)
            {
                handle.Free();
                return null;
            }
        }
        catch (DllNotFoundException)
        {
            _flutterAvailable = false;
            handle.Free();
            System.Diagnostics.Debug.WriteLine("[WindowsBridge] Flutter engine DLL not found.");
            return null;
        }
        catch (EntryPointNotFoundException)
        {
            _flutterAvailable = false;
            handle.Free();
            System.Diagnostics.Debug.WriteLine("[WindowsBridge] FlutterMessengerSendWithReply not found.");
            return null;
        }
        catch (Exception ex)
        {
            handle.Free();
            System.Diagnostics.Debug.WriteLine($"[WindowsBridge] Send failed: {ex.Message}");
            return null;
        }

        using var cts = new CancellationTokenSource(DefaultTimeout);
        using (cts.Token.Register(() => pending.Tcs.TrySetResult(null)))
        {
            var result = await pending.Tcs.Task;
            return result;
        }
    }

    private sealed class PendingCall
    {
        public TaskCompletionSource<byte[]?> Tcs { get; } = new();
        public FlutterDesktopBinaryReply? Callback { get; set; }
    }

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void FlutterDesktopBinaryReply(IntPtr data, ulong dataSize, IntPtr userData);

    [DllImport("flutter_windows.dll", CallingConvention = CallingConvention.Cdecl)]
    private static extern bool FlutterDesktopMessengerSendWithReply(
        IntPtr messenger,
        [MarshalAs(UnmanagedType.LPStr)] string channel,
        byte[] message,
        ulong messageSize,
        FlutterDesktopBinaryReply callback,
        IntPtr userData);

    internal static class Codec
    {
        private const byte TypeNull = 0;
        private const byte TypeTrue = 1;
        private const byte TypeFalse = 2;
        private const byte TypeInt32 = 3;
        private const byte TypeInt64 = 4;
        private const byte TypeFloat64 = 6;
        private const byte TypeString = 7;
        private const byte TypeUInt8List = 8;
        private const byte TypeInt32List = 9;
        private const byte TypeInt64List = 10;
        private const byte TypeFloat64List = 11;
        private const byte TypeList = 12;
        private const byte TypeMap = 13;

        private const byte EnvelopeSuccess = 0;
        private const byte EnvelopeError = 1;
        private const byte EnvelopeNotImplemented = 2;

        public static byte[] EncodeMethodCall(string method, object? args)
        {
            using var stream = new MemoryStream();
            using var writer = new BinaryWriter(stream);
            WriteValue(writer, method);
            WriteValue(writer, args);
            return stream.ToArray();
        }

        public static string? DecodeResponse(byte[] data)
        {
            using var stream = new MemoryStream(data);
            using var reader = new BinaryReader(stream);
            var type = reader.ReadByte();
            void LogDecode(string path)
            {
                System.IO.File.AppendAllText(
                    System.IO.Path.Combine(AppContext.BaseDirectory, "bridge_decode_errors.log"),
                    $"{DateTime.Now:HH:mm:ss} {path}\n");
            }
            switch (type)
            {
                case EnvelopeSuccess:
                    var result = ReadValue(reader);
                    LogDecode($"success {result?.ToString()?.Substring(0, Math.Min(80, result?.ToString()?.Length ?? 0))}");
                    return JsonSerializer.Serialize(ToJsonSerializable(result));
                case EnvelopeError:
                    var code = ReadValue(reader) as string ?? "unknown";
                    var message = ReadValue(reader) as string;
                    LogDecode($"error envelope code={code} message={message}");
                    return null;
                case EnvelopeNotImplemented:
                    System.Diagnostics.Debug.WriteLine("[WindowsBridge] Method not implemented.");
                    return null;
                default:
                    return null;
            }
        }

        private static void WriteValue(BinaryWriter writer, object? value)
        {
            switch (value)
            {
                case null:
                    writer.Write(TypeNull);
                    break;
                case bool b:
                    writer.Write(b ? TypeTrue : TypeFalse);
                    break;
                case int i:
                    writer.Write(TypeInt32);
                    writer.Write(i);
                    break;
                case long l:
                    writer.Write(TypeInt64);
                    writer.Write(l);
                    break;
                case double d:
                    writer.Write(TypeFloat64);
                    WriteAlignment(writer, 8);
                    writer.Write(d);
                    break;
                case string s:
                    writer.Write(TypeString);
                    var bytes = Encoding.UTF8.GetBytes(s);
                    WriteSize(writer, bytes.Length);
                    writer.Write(bytes);
                    break;
                case byte[] arr:
                    writer.Write(TypeUInt8List);
                    WriteSize(writer, arr.Length);
                    writer.Write(arr);
                    break;
                case int[] intArray:
                    writer.Write(TypeInt32List);
                    WriteSize(writer, intArray.Length);
                    foreach (var item in intArray)
                    {
                        writer.Write(item);
                    }
                    break;
                case long[] longArray:
                    writer.Write(TypeInt64List);
                    WriteSize(writer, longArray.Length);
                    foreach (var item in longArray)
                    {
                        writer.Write(item);
                    }
                    break;
                case double[] doubleArray:
                    writer.Write(TypeFloat64List);
                    WriteSize(writer, doubleArray.Length);
                    WriteAlignment(writer, 8);
                    foreach (var item in doubleArray)
                    {
                        writer.Write(item);
                    }
                    break;
                case IDictionary<string, object?> dict:
                    writer.Write(TypeMap);
                    WriteSize(writer, dict.Count);
                    foreach (var kvp in dict)
                    {
                        WriteValue(writer, kvp.Key);
                        WriteValue(writer, kvp.Value);
                    }
                    break;
                case IDictionary dict:
                    writer.Write(TypeMap);
                    WriteSize(writer, dict.Count);
                    foreach (DictionaryEntry entry in dict)
                    {
                        WriteValue(writer, entry.Key?.ToString());
                        WriteValue(writer, entry.Value);
                    }
                    break;
                case IList list:
                    writer.Write(TypeList);
                    WriteSize(writer, list.Count);
                    foreach (var item in list)
                    {
                        WriteValue(writer, item);
                    }
                    break;
                default:
                    writer.Write(TypeNull);
                    break;
            }
        }

        private static object? ReadValue(BinaryReader reader)
        {
            var type = reader.ReadByte();
            switch (type)
            {
                case TypeNull:
                    return null;
                case TypeTrue:
                    return true;
                case TypeFalse:
                    return false;
                case TypeInt32:
                    return reader.ReadInt32();
                case TypeInt64:
                    return reader.ReadInt64();
                case TypeFloat64:
                    ReadAlignment(reader, 8);
                    return reader.ReadDouble();
                case TypeString:
                    var strLen = ReadSize(reader);
                    return Encoding.UTF8.GetString(reader.ReadBytes(strLen));
                case TypeUInt8List:
                    var byteLen = ReadSize(reader);
                    return reader.ReadBytes(byteLen);
                case TypeInt32List:
                    var intLen = ReadSize(reader);
                    var ints = new int[intLen];
                    for (int i = 0; i < intLen; i++)
                        ints[i] = reader.ReadInt32();
                    return ints;
                case TypeInt64List:
                    var longLen = ReadSize(reader);
                    var longs = new long[longLen];
                    for (int i = 0; i < longLen; i++)
                        longs[i] = reader.ReadInt64();
                    return longs;
                case TypeFloat64List:
                    var doubleLen = ReadSize(reader);
                    ReadAlignment(reader, 8);
                    var doubles = new double[doubleLen];
                    for (int i = 0; i < doubleLen; i++)
                        doubles[i] = reader.ReadDouble();
                    return doubles;
                case TypeList:
                    var listLen = ReadSize(reader);
                    var list = new List<object?>(listLen);
                    for (int i = 0; i < listLen; i++)
                        list.Add(ReadValue(reader));
                    return list;
                case TypeMap:
                    var mapLen = ReadSize(reader);
                    var map = new Dictionary<string, object?>(mapLen);
                    for (int i = 0; i < mapLen; i++)
                    {
                        var key = ReadValue(reader)?.ToString() ?? "";
                        var val = ReadValue(reader);
                        map[key] = val;
                    }
                    return map;
                default:
                    return null;
            }
        }

        private static object? ToJsonSerializable(object? value)
        {
            return value switch
            {
                null => null,
                IDictionary<string, object?> dict => dict.ToDictionary(
                    kvp => kvp.Key,
                    kvp => ToJsonSerializable(kvp.Value)),
                IDictionary dict => dict.Keys.Cast<object?>()
                    .ToDictionary(k => k?.ToString() ?? "", k => ToJsonSerializable(dict[k!])),
                IList list => list.Cast<object?>().Select(ToJsonSerializable).ToList(),
                _ => value,
            };
        }

        // 对齐 Dart StandardMessageCodec 的字节布局：size 为变长编码
        // （<254 单字节；0xFE+uint16；0xFF+uint32），int32/int64/float64 为小端，
        // float64 按 8 字节对齐流位置。
        private static void WriteSize(BinaryWriter writer, int size)
        {
            if (size < 254)
            {
                writer.Write((byte)size);
            }
            else if (size <= 0xFFFF)
            {
                writer.Write((byte)254);
                writer.Write((ushort)size);
            }
            else
            {
                writer.Write((byte)255);
                writer.Write((uint)size);
            }
        }

        private static int ReadSize(BinaryReader reader)
        {
            var marker = reader.ReadByte();
            if (marker < 254)
            {
                return marker;
            }
            if (marker == 254)
            {
                return reader.ReadUInt16();
            }
            return checked((int)reader.ReadUInt32());
        }

        private static void WriteAlignment(BinaryWriter writer, int alignment)
        {
            while (writer.BaseStream.Position % alignment != 0)
            {
                writer.Write((byte)0);
            }
        }

        private static void ReadAlignment(BinaryReader reader, int alignment)
        {
            while (reader.BaseStream.Position % alignment != 0)
            {
                reader.ReadByte();
            }
        }
    }
}
