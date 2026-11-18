using System;
using System.Collections.Generic;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace OnePanelNativeHost;

/// <summary>
/// B1 网站配置中心壳（独立子页面，非 ModulePageBase，不经 Frame 导航栈）。
/// 语义对照上游 frontend/src/views/website/website/config/basic/index.vue 的
/// 左侧 Tab 布局（九项），桌面端适配为顶部返回行 + 横向 Tab 列表 + 内容区。
/// 本批仅接入 HTTPS 与域名两个 Tab；其余 Tab 显示「后续批次提供」占位 InfoBar。
/// 同一实例可跨网站复用（MainWindow.OpenWebsiteConfig 持有），切换网站时
/// 通过 <see cref="Initialize"/> 重建布局并回到首个 Tab。
/// </summary>
public sealed partial class WebsiteConfigPage : Page
{
    private int _websiteId;
    private string _websiteName = "";

    private ContentPresenter? _contentHost;
    private readonly List<Button> _tabButtons = new();

    /// <summary>
    /// 九个 Tab 的静态注册表（顺序与上游 basic/index.vue 的网站配置 Tab 对应）。
    /// Builder 全部已接入（B1）。
    /// 键为 hostWebsiteTab* 前缀，缺键回落英文。
    /// </summary>
    private static readonly (string Key, string English, Func<int, string, FrameworkElement>? Builder)[] Tabs =
    {
        ("hostHttpsTabTitle", "HTTPS", WebsiteConfigHttpsTab.Build),
        ("hostDomainsTabTitle", "Domains", WebsiteConfigDomainsTab.Build),
        ("hostWebsiteTabProxy", "Reverse Proxy", WebsiteConfigProxyTab.Build),
        ("hostWebsiteTabRedirect", "Redirect", WebsiteConfigRedirectTab.Build),
        ("hostWebsiteTabRewrite", "Rewrite", WebsiteConfigRewriteTab.Build),
        ("hostWebsiteTabCors", "CORS", WebsiteConfigCorsTab.Build),
        ("hostWebsiteTabAntiLeech", "Anti-Leech", WebsiteConfigLeechTab.Build),
        ("hostWebsiteTabBasicAuth", "Basic Auth", WebsiteConfigAuthTab.Build),
        ("hostWebsiteTabLogs", "Logs", WebsiteConfigLogsTab.Build),
    };

    public WebsiteConfigPage(int websiteId, string websiteName)
    {
        Initialize(websiteId, websiteName);
    }

    /// <summary>绑定目标网站并整体重建布局（选中态回到首个 Tab）。</summary>
    public void Initialize(int websiteId, string websiteName)
    {
        _websiteId = websiteId;
        _websiteName = websiteName;
        BuildLayout();
    }

    private void BuildLayout()
    {
        _tabButtons.Clear();

        var root = new Grid { RowSpacing = 8 };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // 返回行
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // Tab 行
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }); // 内容区

        // ── 返回行：「← {websiteName}」，点击回到网站列表 ──
        var backButton = new Button
        {
            HorizontalAlignment = HorizontalAlignment.Left,
            Padding = new Thickness(8, 5, 12, 5),
            Background = null,
            BorderThickness = new Thickness(0),
        };
        var backContent = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            VerticalAlignment = VerticalAlignment.Center,
        };
        backContent.Children.Add(new FontIcon { Glyph = "\uE72B", FontSize = 14 });
        backContent.Children.Add(new TextBlock
        {
            Text = _websiteName,
            FontSize = 18,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            MaxWidth = 640,
        });
        backButton.Content = backContent;
        ToolTipService.SetToolTip(backButton, L10n.T("hostWebsiteConfigBack", "Back to websites"));
        backButton.Click += (s, e) => (App.MainWindow as MainWindow)?.NavigateBackToWebsites();
        Grid.SetRow(backButton, 0);
        root.Children.Add(backButton);

        // ── Tab 行：横向按钮列表，选中项以 AccentButtonStyle 标识 ──
        var tabStrip = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
        };
        for (int i = 0; i < Tabs.Length; i++)
        {
            var index = i;
            var tab = Tabs[index];
            var button = new Button
            {
                Content = L10n.T(tab.Key, tab.English),
                Padding = new Thickness(12, 6, 12, 6),
                CornerRadius = new CornerRadius(6),
            };
            button.Click += (s, e) => SelectTab(index);
            _tabButtons.Add(button);
            tabStrip.Children.Add(button);
        }

        var tabScroll = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollMode = ScrollMode.Enabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Disabled,
            Content = tabStrip,
        };
        Grid.SetRow(tabScroll, 1);
        root.Children.Add(tabScroll);

        // ── 内容区：Tab 切换时替换 Child（各 Tab 自建 ScrollViewer） ──
        _contentHost = new ContentPresenter
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
            Margin = new Thickness(0, 4, 0, 0),
        };
        Grid.SetRow(_contentHost, 2);
        root.Children.Add(_contentHost);

        Content = root;
        SelectTab(0);
    }

    private void SelectTab(int index)
    {
        for (int i = 0; i < _tabButtons.Count; i++)
        {
            _tabButtons[i].Style = i == index
                ? (Style)Application.Current.Resources["AccentButtonStyle"]
                : null;
        }

        if (_contentHost == null)
        {
            return;
        }

        var tab = Tabs[index];
        if (tab.Builder != null)
        {
            _contentHost.Content = tab.Builder(_websiteId, _websiteName);
        }
        else
        {
            // 未实现批次占位（上游同位置为完整 Tab，客户端分批交付）。
            _contentHost.Content = new InfoBar
            {
                Severity = InfoBarSeverity.Informational,
                IsClosable = false,
                IsOpen = true,
                Title = L10n.T(tab.Key, tab.English),
                Message = L10n.T(
                    "hostWebsiteTabPlaceholder", "This module will be provided in a later batch."),
                HorizontalAlignment = HorizontalAlignment.Stretch,
                VerticalAlignment = VerticalAlignment.Top,
            };
        }
    }
}
