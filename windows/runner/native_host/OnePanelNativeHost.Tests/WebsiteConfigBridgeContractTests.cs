using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs B1 网站配置中心写方法参数字典的契约测试
/// （契约单一事实源：docs/development/modules/b1_website_channel_contract.md）。
/// 覆盖 updateWebsiteHttpsConfig / updateWebsiteProxy / updateWebsiteLeech /
/// deleteWebsiteProxy / updateWebsiteRedirect 五个调用点同形字典：
/// 键数、null 键保留、long? 装箱 Int64 / int 装箱 Int32 不做数值提升、
/// List&lt;object&gt; 原样保留、输入字典不被原样返回。
/// 期望值独立手写，防止自证。
/// </summary>
public class WebsiteConfigBridgeContractTests
{
    [Fact]
    public void PrepareArgs_updateWebsiteHttpsConfig_keeps_12_keys_null_keys_and_sslProtocol_list()
    {
        // 与 WindowsBridge.UpdateWebsiteHttpsAsync 调用点同形（契约 12 字段）：
        // 必填 websiteId/enable/type/httpConfig/algorithm/sslProtocol + 可空 6 键传 null。
        var sslProtocol = new List<object> { "TLSv1.3", "TLSv1.2" };
        var args = new Dictionary<string, object?>
        {
            ["websiteId"] = 42L,
            ["enable"] = true,
            ["websiteSSLId"] = null,
            ["type"] = "existed",
            ["certificate"] = null,
            ["privateKey"] = null,
            ["httpConfig"] = "HTTPToHTTPS",
            ["sslProtocol"] = sslProtocol,
            ["algorithm"] = "RSA",
            ["hsts"] = null,
            ["hstsIncludeSubDomains"] = null,
            ["http3"] = null,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(12, dict.Count);
        Assert.Equal(typeof(long), dict["websiteId"]!.GetType());
        Assert.Equal(42L, (long)dict["websiteId"]!);
        Assert.Equal(true, dict["enable"]);
        Assert.Equal("existed", dict["type"]);
        Assert.Equal("HTTPToHTTPS", dict["httpConfig"]);
        Assert.Equal("RSA", dict["algorithm"]);
        foreach (var nullKey in new[]
                 {
                     "websiteSSLId", "certificate", "privateKey",
                     "hsts", "hstsIncludeSubDomains", "http3",
                 })
        {
            Assert.True(dict.ContainsKey(nullKey), $"optional key {nullKey} must be preserved");
            Assert.Null(dict[nullKey]);
        }

        Assert.Same(sslProtocol, dict["sslProtocol"]);
    }

    [Fact]
    public void PrepareArgs_updateWebsiteProxy_keeps_22_keys_and_boxed_types()
    {
        // 与 WindowsBridge.UpdateWebsiteProxyAsync 调用点同形（契约 7 必填 + 15 可空 = 22 键）：
        // websiteID 大写 ID、serverCacheTime long? 装箱 Int64、可空布尔键 null 保留。
        var args = new Dictionary<string, object?>
        {
            ["websiteID"] = 7L,
            ["operate"] = "edit",
            ["name"] = "static",
            ["match"] = "^/static/.*$",
            ["proxyProtocol"] = "http",
            ["proxyAddress"] = "127.0.0.1:8080",
            ["proxyHost"] = "$host",
            ["sni"] = null,
            ["proxySSLName"] = null,
            ["sslVerify"] = null,
            ["cache"] = true,
            ["serverCacheTime"] = 300L,
            ["serverCacheUnit"] = "s",
            ["browserCache"] = "enable",
            ["cacheTime"] = null,
            ["cacheUnit"] = null,
            ["cors"] = null,
            ["allowOrigins"] = null,
            ["allowMethods"] = null,
            ["allowHeaders"] = null,
            ["allowCredentials"] = null,
            ["preflight"] = null,
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.NotSame(args, dict);
        Assert.Equal(22, dict.Count);
        Assert.Equal(typeof(long), dict["websiteID"]!.GetType());
        Assert.Equal(7L, (long)dict["websiteID"]!);
        Assert.Equal("edit", dict["operate"]);
        Assert.Equal("^/static/.*$", dict["match"]);
        Assert.Equal("127.0.0.1:8080", dict["proxyAddress"]);
        Assert.Equal(typeof(long), dict["serverCacheTime"]!.GetType());
        Assert.Equal(300L, (long)dict["serverCacheTime"]!);
        Assert.Equal("enable", dict["browserCache"]);
        Assert.True(dict.ContainsKey("sni"));
        Assert.Null(dict["sni"]);
        Assert.True(dict.ContainsKey("allowCredentials"));
        Assert.Null(dict["allowCredentials"]);
    }

    [Fact]
    public void PrepareArgs_updateWebsiteLeech_keeps_return_underscore_key_and_serverNames_list()
    {
        // 与 WindowsBridge.UpdateWebsiteLeechAsync 调用点同形（契约 5 必填 + 6 可空 = 11 键）：
        // return 是 Dart 保留字，通道键名为 return_（Dart 侧映射回 return）；
        // serverNames 为 List<object> 原样保留。
        var serverNames = new List<object> { "example.com", "*.example.com" };
        var args = new Dictionary<string, object?>
        {
            ["websiteID"] = 9L,
            ["enable"] = true,
            ["extends"] = "jpg|png",
            ["serverNames"] = serverNames,
            ["return_"] = "404",
            ["noneRef"] = null,
            ["blocked"] = null,
            ["cache"] = null,
            ["cacheTime"] = null,
            ["cacheUint"] = null,
            ["logEnable"] = null,
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.NotSame(args, dict);
        Assert.Equal(11, dict.Count);
        Assert.True(dict.ContainsKey("return_"), "channel key must be return_");
        Assert.Equal("404", dict["return_"]);
        var names = Assert.IsType<List<object>>(dict["serverNames"]);
        Assert.Equal(2, names.Count);
        Assert.Equal("example.com", names[0]);
        Assert.Equal("*.example.com", names[1]);
        Assert.Equal(typeof(long), dict["websiteID"]!.GetType());
        Assert.Equal(9L, (long)dict["websiteID"]!);
        Assert.True(dict.ContainsKey("cacheTime"));
        Assert.Null(dict["cacheTime"]);
    }

    [Fact]
    public void PrepareArgs_deleteWebsiteProxy_exact_two_keys_with_exact_values()
    {
        // 与 WindowsBridge.DeleteWebsiteProxyAsync(int id, string name) 调用点同形：
        // 仅 2 键精确值；int 签名装箱 Int32（编码走 TypeInt32，Dart 侧解码一致）。
        var args = new Dictionary<string, object?> { ["id"] = 12, ["name"] = "legacy-proxy" };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.NotSame(args, dict);
        Assert.Equal(2, dict.Count);
        Assert.Equal(typeof(int), dict["id"]!.GetType());
        Assert.Equal(12, (int)dict["id"]!);
        Assert.Equal("legacy-proxy", dict["name"]);
    }

    [Fact]
    public void PrepareArgs_updateWebsiteRedirect_keeps_10_keys_and_domains_list()
    {
        // 与 WindowsBridge.UpdateWebsiteRedirectAsync 调用点同形（契约 6 必填 + 4 可空 = 10 键）：
        // domains 为 List<object>? 原样保留（同实例），keepPath/path 可空键 null 保留。
        var domains = new List<object> { "a.example.com", "b.example.com" };
        var args = new Dictionary<string, object?>
        {
            ["websiteID"] = 3L,
            ["operate"] = "create",
            ["enable"] = true,
            ["name"] = "to-https",
            ["type"] = "domain",
            ["redirect"] = "301",
            ["keepPath"] = null,
            ["path"] = null,
            ["target"] = "https://example.com",
            ["domains"] = domains,
        };

        var dict = Assert.IsType<Dictionary<string, object?>>(WindowsBridge.PrepareArgs(args));

        Assert.NotSame(args, dict);
        Assert.Equal(10, dict.Count);
        Assert.Same(domains, dict["domains"]);
        Assert.Equal("301", dict["redirect"]);
        Assert.True(dict.ContainsKey("keepPath"));
        Assert.Null(dict["keepPath"]);
    }
}
