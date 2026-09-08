using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs B3 AI 管理深度方法参数字典的契约测试
/// （契约单一事实源：docs/development/modules/b3_ai_channel_contract.md）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支，经 ConvertDictionary
/// 复制为新字典：键转 string、List 实例原样保留（StandardMessageCodec 直传）、
/// int/long 装箱类型原样（不做数值提升）、可空键显式保留（null 值不丢键）。
/// 期望值独立手写，防止自证。
/// </summary>
public class AIConfigBridgeContractTests
{
    [Fact]
    public void PrepareArgs_createAgentAccount_keeps_9_keys_with_nullable_keys_preserved()
    {
        // 与 WindowsBridge.CreateAgentAccountAsync 调用点同形（契约写通道
        // createAgentAccountNative 9 字段；可空 authMode/verifyModel/remark 传 null 时键不丢）。
        var args = new Dictionary<string, object?>
        {
            ["provider"] = "ollama",
            ["name"] = "local-ollama",
            ["apiKey"] = "sk-test",
            ["baseURL"] = "http://192.168.1.10:11434",
            ["apiType"] = "ollama",
            ["authMode"] = null,
            ["validateAvailability"] = true,
            ["verifyModel"] = null,
            ["remark"] = null,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(9, dict.Count);
        Assert.Equal("ollama", dict["provider"]);
        Assert.Equal("local-ollama", dict["name"]);
        Assert.Equal("sk-test", dict["apiKey"]);
        Assert.Equal("http://192.168.1.10:11434", dict["baseURL"]);
        Assert.Equal("ollama", dict["apiType"]);
        Assert.True(dict.ContainsKey("authMode"));
        Assert.Null(dict["authMode"]);
        Assert.Equal(true, dict["validateAvailability"]);
        Assert.True(dict.ContainsKey("verifyModel"));
        Assert.Null(dict["verifyModel"]);
        Assert.True(dict.ContainsKey("remark"));
        Assert.Null(dict["remark"]);
    }

    [Fact]
    public void PrepareArgs_createMcpServer_keeps_12_keys_and_port_stays_boxed_long()
    {
        // 与 WindowsBridge.CreateMcpServerAsync 调用点同形（契约 12 字段；
        // port 以 long 装箱，ConvertDictionary 不做数值提升）。
        var args = new Dictionary<string, object?>
        {
            ["name"] = "filesystem",
            ["type"] = "npx",
            ["command"] = "npx -y @modelcontextprotocol/server-filesystem /opt",
            ["protocol"] = "stdio",
            ["url"] = "",
            ["outputTransport"] = "stdio",
            ["ssePath"] = null,
            ["streamableHttpPath"] = null,
            ["gatewayImage"] = null,
            ["containerName"] = "mcp-filesystem",
            ["port"] = 8080L,
            ["hostIP"] = "192.168.1.10",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(12, dict.Count);
        Assert.Equal("filesystem", dict["name"]);
        Assert.Equal("npx", dict["type"]);
        Assert.Equal("mcp-filesystem", dict["containerName"]);
        Assert.Equal(typeof(long), dict["port"]!.GetType());
        Assert.Equal(8080L, (long)dict["port"]!);
        Assert.Equal("192.168.1.10", dict["hostIP"]);
        Assert.True(dict.ContainsKey("ssePath"));
        Assert.Null(dict["ssePath"]);
    }

    [Fact]
    public void PrepareArgs_createAgentNative_keeps_5_keys()
    {
        // 与 WindowsBridge.CreateAgentNativeAsync 调用点同形（契约写通道
        // createAgentNative 5 字段；webUIPort 以 long 装箱）。
        var args = new Dictionary<string, object?>
        {
            ["agentType"] = "openwebui",
            ["name"] = "openwebui-1",
            ["remark"] = null,
            ["appVersion"] = "v0.6.5",
            ["webUIPort"] = 8080L,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(5, dict.Count);
        Assert.Equal("openwebui", dict["agentType"]);
        Assert.Equal("openwebui-1", dict["name"]);
        Assert.True(dict.ContainsKey("remark"));
        Assert.Null(dict["remark"]);
        Assert.Equal("v0.6.5", dict["appVersion"]);
        Assert.Equal(typeof(long), dict["webUIPort"]!.GetType());
        Assert.Equal(8080L, (long)dict["webUIPort"]!);
    }

    [Fact]
    public void PrepareArgs_syncMcpStatus_keeps_ids_list_instance()
    {
        // 与 WindowsBridge.SyncMcpStatusAsync 调用点同形（契约实现约定 1：
        // 列表参数用 List<object>，实例原样保留由 StandardMessageCodec 直传）。
        var ids = new List<object> { 1L, 2L, 3L };
        var args = new Dictionary<string, object?>
        {
            ["ids"] = ids,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(1, dict.Count);
        Assert.Same(ids, dict["ids"]);
        var list = Assert.IsType<List<object>>(dict["ids"]);
        Assert.Equal(3, list.Count);
        Assert.Equal(1L, list[0]);
        Assert.Equal(2L, list[1]);
        Assert.Equal(3L, list[2]);
    }

    [Fact]
    public void PrepareArgs_getAgentAccounts_keeps_3_keys_with_null_name_preserved()
    {
        // 与 WindowsBridge.GetAgentAccountsAsync 调用点同形（契约读通道
        // getAgentAccounts：page/pageSize 必填 + name 可选；name 为 null 时键不丢）。
        var args = new Dictionary<string, object?>
        {
            ["page"] = 1,
            ["pageSize"] = 20,
            ["name"] = null,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(3, dict.Count);
        Assert.Equal(typeof(int), dict["page"]!.GetType());
        Assert.Equal(1, (int)dict["page"]!);
        Assert.Equal(typeof(int), dict["pageSize"]!.GetType());
        Assert.Equal(20, (int)dict["pageSize"]!);
        Assert.True(dict.ContainsKey("name"));
        Assert.Null(dict["name"]);
    }
}
