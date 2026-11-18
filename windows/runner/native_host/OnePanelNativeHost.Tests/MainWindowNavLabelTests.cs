using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// B25 导航标签映射表一致性：路由 Tag 集与 L10n 键集一一对应（21 项），
/// 键唯一且英文回落非空。映射缺失时该项标签永远停留英文（静默回落），
/// 此测试保证新增导航项必须同步补映射。
/// </summary>
public class MainWindowNavLabelTests
{
    [Fact]
    public void NavLabelKeys_covers_exactly_21_tags_with_unique_non_empty_entries()
    {
        Assert.Equal(21, MainWindow.NavLabelKeys.Count);

        var keys = new HashSet<string>();
        foreach (var (tag, label) in MainWindow.NavLabelKeys)
        {
            Assert.False(string.IsNullOrWhiteSpace(tag));
            Assert.False(string.IsNullOrWhiteSpace(label.Key));
            Assert.False(string.IsNullOrWhiteSpace(label.English));
            Assert.True(keys.Add(label.Key), $"duplicate L10n key: {label.Key}");
        }
    }

    [Theory]
    [InlineData("Dashboard")]
    [InlineData("ScriptLibrary")]
    [InlineData("Servers")]
    [InlineData("Files")]
    [InlineData("Containers")]
    [InlineData("Orchestration")]
    [InlineData("Apps")]
    [InlineData("Websites")]
    [InlineData("OpenResty")]
    [InlineData("Databases")]
    [InlineData("CronJobs")]
    [InlineData("Backups")]
    [InlineData("Host")]
    [InlineData("Toolbox")]
    [InlineData("Monitoring")]
    [InlineData("AI")]
    [InlineData("Commands")]
    [InlineData("Logs")]
    [InlineData("Security")]
    [InlineData("Gateway")]
    [InlineData("Settings")]
    public void NavLabelKeys_covers_every_navigation_tag(string tag)
    {
        Assert.True(MainWindow.NavLabelKeys.ContainsKey(tag), $"missing nav label mapping: {tag}");
    }
}
