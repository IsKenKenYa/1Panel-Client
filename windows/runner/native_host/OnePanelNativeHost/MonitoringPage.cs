using System;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Monitoring module page: a real-time snapshot read view of the
/// active server's core metrics (CPU, memory, disk usage and the three
/// load-average values). Data flows through WindowsBridge (Dart business
/// core over the method channel); no direct HTTP from the native layer.
///
/// Upstream semantic reference: the 1Panel web frontend dashboard surfaces
/// CPU / memory / disk utilization gauges plus load averages on its monitor
/// tab. This page mirrors that snapshot readout; time-series charts belong
/// to a later batch and are intentionally out of scope here. The snapshot is
/// taken when the data loads (page shown or manual refresh) - there is no
/// background polling, matching the manual-refresh interaction of the
/// upstream monitor view.
/// </summary>
public sealed class MonitoringPage : ModulePageBase
{
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by page-shown loads and refreshes.</summary>
    private bool _isBusy;

    public MonitoringPage()
    {
        PageTitle = L10n.T("serverModuleMonitoring", "Monitoring");
    }

    protected override async void OnPageShown()
    {
        await LoadMonitoringAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadMonitoringAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadMonitoringAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadMonitoringCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body. With <paramref name="showLoadingState"/> the page
    /// swaps to the loading spinner; otherwise the current content stays
    /// visible and failures surface via the error toast. A null bridge result
    /// means the bridge call failed (full error state on initial load); an
    /// empty object means there is no active server to monitor (empty state).
    /// </summary>
    private async Task LoadMonitoringCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetMonitoringAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostMonitoringRefreshFailed", "Failed to refresh monitoring data."));
            }
            return;
        }

        if (IsEmptyObject(result.Value))
        {
            SetState(PageState.Empty);
            return;
        }

        BuildContent(ParseSnapshot(result.Value));
        SetState(PageState.Content);
    }

    private static MonitoringSnapshot ParseSnapshot(JsonElement json)
    {
        return new MonitoringSnapshot
        {
            Cpu = TryGetDouble(json, "cpu"),
            Memory = TryGetDouble(json, "memory"),
            Disk = TryGetDouble(json, "disk"),
            Load1 = TryGetDouble(json, "load1"),
            Load5 = TryGetDouble(json, "load5"),
            Load15 = TryGetDouble(json, "load15"),
        };
    }

    /// <summary>An object with no properties (or a non-object payload) means no data.</summary>
    private static bool IsEmptyObject(JsonElement json)
    {
        if (json.ValueKind != JsonValueKind.Object) return true;
        using var enumerator = json.EnumerateObject();
        return !enumerator.MoveNext();
    }

    private void BuildContent(MonitoringSnapshot snapshot)
    {
        // Root layout: CommandBar on top, scrollable metric cards below and a
        // snapshot-time caption pinned at the bottom (relative rows only).
        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var commandBar = BuildCommandBar();
        Grid.SetRow(commandBar, 0);
        root.Children.Add(commandBar);

        // Metric cards sit in a scrollable area so narrow windows stay usable.
        var scrollViewer = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 0, 8),
        };
        Grid.SetRow(scrollViewer, 1);

        var cards = new Grid { Margin = new Thickness(12, 4, 12, 0) };
        // Three equal star columns keep the usage cards relative at any DPI
        // or window size; the load card spans the full width underneath.
        cards.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        cards.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        cards.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        cards.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        cards.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var cpuCard = BuildUsageCard(L10n.T("serverCpuLabel", "CPU"), FormatPercent(snapshot.Cpu), snapshot.Cpu);
        Grid.SetRow(cpuCard, 0);
        Grid.SetColumn(cpuCard, 0);
        cards.Children.Add(cpuCard);

        var memoryCard = BuildUsageCard(L10n.T("serverMemoryLabel", "Memory"), FormatPercent(snapshot.Memory), snapshot.Memory);
        Grid.SetRow(memoryCard, 0);
        Grid.SetColumn(memoryCard, 1);
        cards.Children.Add(memoryCard);

        var diskCard = BuildUsageCard(L10n.T("serverDiskLabel", "Disk"), FormatPercent(snapshot.Disk), snapshot.Disk);
        Grid.SetRow(diskCard, 0);
        Grid.SetColumn(diskCard, 2);
        cards.Children.Add(diskCard);

        var loadCard = BuildLoadCard(snapshot);
        Grid.SetRow(loadCard, 1);
        Grid.SetColumnSpan(loadCard, 3);
        cards.Children.Add(loadCard);

        scrollViewer.Content = cards;
        root.Children.Add(scrollViewer);

        // Snapshot marker: the data was read at this time; refresh updates it.
        var snapshotCaption = new TextBlock
        {
            Text = "Snapshot at " + snapshot.Timestamp.ToString("HH:mm:ss", CultureInfo.InvariantCulture),
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            Margin = new Thickness(16, 4, 16, 10),
        };
        Grid.SetRow(snapshotCaption, 2);
        root.Children.Add(snapshotCaption);

        // Failure toast floats above the content, bottom-aligned (kept in the
        // visual tree so Show() actually renders).
        _errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(_errorToast, 1);
        AttachToast(root, _errorToast);

        ModuleContentPresenter.Content = root;
    }

    private CommandBar BuildCommandBar()
    {
        var bar = new CommandBar
        {
            HorizontalAlignment = HorizontalAlignment.Left,
            DefaultLabelPosition = CommandBarDefaultLabelPosition.Right,
            Background = null, // Stay transparent on the LayerFill card surface.
        };

        var refreshButton = new AppBarButton
        {
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadMonitoringAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    /// <summary>
    /// Card with a metric title, a prominent percent readout and a 0-100
    /// progress bar. Missing values render as "--" with an empty bar.
    /// </summary>
    private static FrameworkElement BuildUsageCard(string title, string valueText, double percent)
    {
        var content = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 8,
        };

        content.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
        });

        content.Children.Add(new TextBlock
        {
            Text = valueText,
            FontSize = 20,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            TextTrimming = TextTrimming.CharacterEllipsis,
        });

        content.Children.Add(new ProgressBar
        {
            Minimum = 0,
            Maximum = 100,
            Value = percent < 0 ? 0 : Math.Clamp(percent, 0, 100),
        });

        return new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            Background = TryGetThemeBrush("CardBackgroundFillColorDefaultBrush", Microsoft.UI.ColorHelper.FromArgb(24, 128, 128, 128)),
            BorderBrush = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.ColorHelper.FromArgb(24, 128, 128, 128)),
            BorderThickness = new Thickness(1),
            Margin = new Thickness(4, 4, 4, 4),
            Child = content,
        };
    }

    /// <summary>
    /// Load-average card: one value row per window (load1/load5/load15) with
    /// a caption explaining the 1/5/15 minute windows.
    /// </summary>
    private static FrameworkElement BuildLoadCard(MonitoringSnapshot snapshot)
    {
        var content = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 6,
        };

        content.Children.Add(new TextBlock
        {
            Text = L10n.T("hostMonitoringLoadAverage", "Load Average"),
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
        });

        content.Children.Add(BuildLoadRow(L10n.T("hostMonitoringLoad1", "Load 1"), snapshot.Load1));
        content.Children.Add(BuildLoadRow(L10n.T("hostMonitoringLoad5", "Load 5"), snapshot.Load5));
        content.Children.Add(BuildLoadRow(L10n.T("hostMonitoringLoad15", "Load 15"), snapshot.Load15));

        content.Children.Add(new TextBlock
        {
            Text = L10n.T("hostMonitoringLoadWindows", "1/5/15 min"),
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorTertiaryBrush", Microsoft.UI.Colors.Gray),
        });

        return new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            Background = TryGetThemeBrush("CardBackgroundFillColorDefaultBrush", Microsoft.UI.ColorHelper.FromArgb(24, 128, 128, 128)),
            BorderBrush = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.ColorHelper.FromArgb(24, 128, 128, 128)),
            BorderThickness = new Thickness(1),
            Margin = new Thickness(4, 4, 4, 4),
            Child = content,
        };
    }

    /// <summary>Label left, load value right-aligned; missing values show "--".</summary>
    private static FrameworkElement BuildLoadRow(string label, double value)
    {
        var row = new Grid();
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 14,
            VerticalAlignment = VerticalAlignment.Center,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
        };
        Grid.SetColumn(labelBlock, 0);
        row.Children.Add(labelBlock);

        var valueBlock = new TextBlock
        {
            Text = FormatLoad(value),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(valueBlock, 1);
        row.Children.Add(valueBlock);

        return row;
    }

    /// <summary>Percent readout; "--" when the value is missing.</summary>
    private static string FormatPercent(double percent)
        => percent < 0 ? "--" : percent.ToString("F1", CultureInfo.InvariantCulture) + "%";

    /// <summary>Load average readout; "--" when the value is missing.</summary>
    private static string FormatLoad(double value)
        => value < 0 ? "--" : value.ToString("F2", CultureInfo.InvariantCulture);

    private static Brush TryGetThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static double TryGetDouble(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number)
        {
            return prop.GetDouble();
        }
        return -1;
    }

    /// <summary>Immutable view of one monitoring snapshot; -1 means "no value".</summary>
    private sealed class MonitoringSnapshot
    {
        public double Cpu { get; init; } = -1;
        public double Memory { get; init; } = -1;
        public double Disk { get; init; } = -1;
        public double Load1 { get; init; } = -1;
        public double Load5 { get; init; } = -1;
        public double Load15 { get; init; } = -1;
        public DateTime Timestamp { get; init; } = DateTime.Now;
    }
}
