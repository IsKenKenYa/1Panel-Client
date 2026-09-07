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

    private readonly Dictionary<string, Page> _pageCache = new();

    public MainWindow()
    {
        InitializeComponent();
        WindowBackdrop.Apply(this, WindowBackdrop.LoadPreferred());

        // Extend content into the title bar: AppTitleBar becomes the system drag
        // region and the caption buttons overlay its right edge (no content overlap).
        ExtendsContentIntoTitleBar = true;
        SetTitleBar(AppTitleBar);

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

        var tag = item.Content?.ToString();
        if (tag is null || !_pageFactories.TryGetValue(tag, out var factory))
        {
            return;
        }

        if (!_pageCache.TryGetValue(tag, out var page))
        {
            page = factory();
            _pageCache[tag] = page;
        }

        ContentFrame.Content = page;
        if (page is ModulePageBase modulePage)
        {
            modulePage.ActivatePage();
        }
    }
}
