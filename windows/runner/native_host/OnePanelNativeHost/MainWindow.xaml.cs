using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;

namespace OnePanelNativeHost;

public sealed partial class MainWindow : Window
{
    private static readonly Dictionary<string, Func<Page>> _pageFactories = new()
    {
        { "Dashboard", () => new DashboardPage() },
        { "Servers", () => new ServersPage() },
        { "Files", () => new FilesPage() },
        { "Containers", () => new ContainersPage() },
        { "Orchestration", () => new OrchestrationPage() },
        { "Apps", () => new AppsPage() },
        { "Websites", () => new WebsitesPage() },
        { "OpenResty", () => new OpenRestyPage() },
        { "Databases", () => new DatabasePage() },
        { "CronJobs", () => new CronJobsPage() },
        { "Backups", () => new BackupsPage() },
        { "Host", () => new HostPage() },
        { "Toolbox", () => new ToolboxPage() },
        { "Monitoring", () => new MonitoringPage() },
        { "AI", () => new AIPage() },
        { "Commands", () => new CommandsPage() },
        { "ScriptLibrary", () => new ScriptLibraryPage() },
        { "Logs", () => new LogsPage() },
        { "Security", () => new SecurityPage() },
        { "Gateway", () => new SecurityGatewayPage() },
        { "Settings", () => new SettingsPage() },
    };

    /// <summary>
    /// 导航路由 Tag → L10n 键（键集与 Dart arb 同源，缺键回落英文）。
    /// Tag 承担路由标识（语言无关），Content 只承担显示标签。
    /// </summary>
    public static readonly Dictionary<string, (string Key, string English)> NavLabelKeys = new()
    {
        { "Dashboard", ("dashboardTitle", "Dashboard") },
        { "ScriptLibrary", ("hostNavScriptLibrary", "Script Library") },
        { "Servers", ("navServer", "Servers") },
        { "Files", ("navFiles", "Files") },
        { "Containers", ("containerManagement", "Containers") },
        { "Orchestration", ("orchestrationTitle", "Orchestration") },
        { "Apps", ("appsPageTitle", "Apps") },
        { "Websites", ("websitesPageTitle", "Websites") },
        { "OpenResty", ("openrestyPageTitle", "OpenResty") },
        { "Databases", ("hostNavDatabases", "Databases") },
        { "CronJobs", ("hostNavCronJobs", "CronJobs") },
        { "Backups", ("hostNavBackups", "Backups") },
        { "Host", ("hostNavHost", "Host") },
        { "Toolbox", ("toolboxCenterTitle", "Toolbox") },
        { "Monitoring", ("serverModuleMonitoring", "Monitoring") },
        { "AI", ("serverModuleAi", "AI") },
        { "Commands", ("hostNavCommands", "Commands") },
        { "Logs", ("hostNavLogs", "Logs") },
        { "Security", ("navSecurity", "Security") },
        { "Gateway", ("hostNavGateway", "Gateway") },
        { "Settings", ("navSettings", "Settings") },
    };

    private readonly Dictionary<string, Page> _pageCache = new();
    private string? _currentTag;

    // B1 网站配置中心子页面：独立字段持有（不进 _pageCache），同一实例跨网站复用。
    private WebsiteConfigPage? _websiteConfigPage;

    public MainWindow()
    {
        InitializeComponent();
        WindowBackdrop.Apply(this, WindowBackdrop.LoadPreferred());

        // Extend content into the title bar: AppTitleBar becomes the system drag
        // region and the caption buttons overlay its right edge (no content overlap).
        ExtendsContentIntoTitleBar = true;
        SetTitleBar(AppTitleBar);

        ApplyNavLabels();
        RootNavigationView.SelectionChanged += OnNavigationSelectionChanged;
        // Adaptive pane: fold to an icon rail on narrow windows.
        RootNavigationView.SizeChanged += OnRootNavigationViewSizeChanged;
        // 导航必须在模板应用(Frame 就绪)后触发，构造期间赋值会触发 native 崩溃。
        RootNavigationView.Loaded += (sender, _) =>
        {
            if (RootNavigationView.SelectedItem == null)
            {
                RootNavigationView.SelectedItem = RootNavigationView.MenuItems[0];
            }
        };
    }

    /// <summary>
    /// 语言切换后由设置页调用：重设导航标签，并按新文案重建全部缓存页
    /// （单例缓存页不会随字典刷新，整体重建是唯一的全量生效路径）。
    /// 网站配置中心子页面同样按新文案整体重建（下次打开时）。
    /// </summary>
    public void ApplyLanguage()
    {
        ApplyNavLabels();
        _pageCache.Clear();
        _websiteConfigPage = null;
        if (_currentTag != null && _pageFactories.ContainsKey(_currentTag))
        {
            ShowPage(_currentTag);
        }
    }

    private void ApplyNavLabels()
    {
        foreach (var item in GetSelectableNavItems())
        {
            var tag = item.Tag?.ToString();
            if (tag != null && NavLabelKeys.TryGetValue(tag, out var label))
            {
                item.Content = L10n.T(label.Key, label.English);
            }
        }
    }

    // Adaptive pane: icon-only compact rail below 720px width, expanded left pane above.
    private void OnRootNavigationViewSizeChanged(object sender, SizeChangedEventArgs args)
    {
        ((NavigationView)sender).PaneDisplayMode = args.NewSize.Width < 720
            ? NavigationViewPaneDisplayMode.LeftCompact
            : NavigationViewPaneDisplayMode.Left;
    }

    // F5: refresh the currently hosted module page (no-op when content is not a module page).
    private void OnRefreshAccelerator(KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        if (ContentFrame.Content is ModulePageBase modulePage)
        {
            modulePage.RefreshPage();
            args.Handled = true;
        }
    }

    // Ctrl+1..8: select the Nth navigation item; SelectionChanged drives the page switch.
    private void OnNavIndexAccelerator(KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        var index = args.KeyboardAccelerator.Key - Windows.System.VirtualKey.Number1;
        var items = GetSelectableNavItems();
        if (index >= 0 && index < items.Count)
        {
            RootNavigationView.SelectedItem = items[index];
            args.Handled = true;
        }
    }

    // Selectable items in shortcut order (workspace items, then footer); separators skipped.
    private List<NavigationViewItem> GetSelectableNavItems()
    {
        var items = new List<NavigationViewItem>();
        foreach (var item in RootNavigationView.MenuItems)
        {
            if (item is NavigationViewItem navItem)
            {
                items.Add(navItem);
            }
        }
        foreach (var item in RootNavigationView.FooterMenuItems)
        {
            if (item is NavigationViewItem navItem)
            {
                items.Add(navItem);
            }
        }
        return items;
    }

    // 本环境(self-contained unpackaged)下 Frame.Navigate 存在 native 崩溃缺陷，
    // 采用单例页面 + Content 直赋：桌面左导航场景无需 back stack，页面自身缓存。
    private void OnNavigationSelectionChanged(
        NavigationView sender,
        NavigationViewSelectionChangedEventArgs args)
    {
        if (args.SelectedItem is not NavigationViewItem item)
        {
            return;
        }

        // 路由键取语言无关的 Tag（Content 已被本地化标签占用）。
        var tag = item.Tag?.ToString();
        if (tag is null || !_pageFactories.ContainsKey(tag))
        {
            return;
        }

        ShowPage(tag);
    }

    private void ShowPage(string tag)
    {
        _currentTag = tag;

        if (!_pageCache.TryGetValue(tag, out var page))
        {
            page = _pageFactories[tag]();
            _pageCache[tag] = page;
        }

        ContentFrame.Content = page;
        if (page is ModulePageBase modulePage)
        {
            modulePage.ActivatePage();
        }
    }

    /// <summary>
    /// 返回网站列表（B1 网站配置中心子页面的返回动作）。
    /// 配置中心打开期间 _currentTag 仍为 Websites，直接走 ShowPage 即可命中缓存并触发刷新。
    /// </summary>
    public void NavigateBackToWebsites() => ShowPage("Websites");

    /// <summary>
    /// 打开 B1 网站配置中心子页面：创建/复用独立持有的 WebsiteConfigPage
    /// （不进 _pageCache），切换网站时经 Initialize 重绑目标网站并回到首个 Tab。
    /// 导航选中态保持在 Websites，子页面由返回按钮显式退出。
    /// </summary>
    public void OpenWebsiteConfig(int websiteId, string websiteName)
    {
        if (_websiteConfigPage == null)
        {
            _websiteConfigPage = new WebsiteConfigPage(websiteId, websiteName);
        }
        else
        {
            _websiteConfigPage.Initialize(websiteId, websiteName);
        }
        ContentFrame.Content = _websiteConfigPage;
    }
}
