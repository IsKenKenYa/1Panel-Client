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
/// Native Dashboard (overview) page: resource gauges for CPU / Memory / Disk
/// plus a system information card. All data flows through WindowsBridge
/// (Dart business core over the method channel); no direct HTTP from the
/// native layer.
///
/// Upstream semantic reference: the 1Panel web frontend (views/home) surfaces
/// resource utilization gauges (CPU, memory, disk with used/total bytes)
/// alongside a system info panel (hostname, OS, kernel version, CPU cores,
/// uptime) and the running panel version. The bridge contract maps an empty
/// JSON object to "no active server configured", which renders the empty
/// state; a null result means the bridge itself failed and renders the error
/// state.
/// </summary>
public sealed class DashboardPage : ModulePageBase
{
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads and refresh.</summary>
    private bool _isBusy;

    public DashboardPage()
    {
        PageTitle = "Dashboard";
    }

    protected override async void OnPageShown()
    {
        await LoadDashboardAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadDashboardAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadDashboardAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadDashboardCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body. With <paramref name="showLoadingState"/> the page
    /// swaps to the loading spinner; otherwise the current content stays
    /// visible and failures surface via the error toast.
    /// </summary>
    private async Task LoadDashboardCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetDashboardAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show("Failed to refresh dashboard.");
            }
            return;
        }

        // Bridge semantics: an empty object means no active server is
        // configured, which maps to the empty state.
        if (!HasAnyProperty(result.Value))
        {
            SetState(PageState.Empty);
            return;
        }

        BuildContent(ParseDashboard(result.Value));
        SetState(PageState.Content);
    }

    private DashboardEntry ParseDashboard(JsonElement json)
    {
        var entry = new DashboardEntry();

        if (json.ValueKind == JsonValueKind.Object)
        {
            entry.Cpu = TryGetDouble(json, "cpu");
            entry.Memory = TryGetDouble(json, "memory");
            entry.Disk = TryGetDouble(json, "disk");
            entry.MemoryUsage = TryGetString(json, "memoryUsage") ?? "";
            entry.DiskUsage = TryGetString(json, "diskUsage") ?? "";
            entry.Hostname = TryGetString(json, "hostname") ?? "";
            entry.Os = TryGetString(json, "os") ?? "";
            entry.KernelVersion = TryGetString(json, "kernelVersion") ?? "";
            entry.CpuCores = TryGetInt(json, "cpuCores");
            entry.PanelVersion = TryGetString(json, "panelVersion") ?? "";
            entry.Uptime = FormatUptime(json.GetPropertyOrDefault("uptime"));
        }

        return entry;
    }

    private void BuildContent(DashboardEntry entry)
    {
        // Root layout: CommandBar on top, scrollable content below (relative rows).
        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var commandBar = BuildCommandBar();
        Grid.SetRow(commandBar, 0);
        root.Children.Add(commandBar);

        var scrollViewer = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 0, 8),
        };
        Grid.SetRow(scrollViewer, 1);

        var content = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Margin = new Thickness(8, 0, 8, 0),
            Spacing = 12,
        };

        // Resource gauges: three equal Star columns so cards scale with the
        // window; no fixed widths anywhere.
        var gauges = new Grid();
        gauges.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        gauges.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        gauges.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var cpuCard = BuildResourceCard("CPU", entry.Cpu, detail: "");
        cpuCard.Margin = new Thickness(0, 0, 12, 0);
        Grid.SetColumn(cpuCard, 0);
        gauges.Children.Add(cpuCard);

        var memoryCard = BuildResourceCard("Memory", entry.Memory, entry.MemoryUsage);
        memoryCard.Margin = new Thickness(0, 0, 12, 0);
        Grid.SetColumn(memoryCard, 1);
        gauges.Children.Add(memoryCard);

        var diskCard = BuildResourceCard("Disk", entry.Disk, entry.DiskUsage);
        Grid.SetColumn(diskCard, 2);
        gauges.Children.Add(diskCard);

        content.Children.Add(gauges);
        content.Children.Add(BuildSystemInfoCard(entry));

        scrollViewer.Content = content;
        root.Children.Add(scrollViewer);

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
            Label = "Refresh",
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadDashboardAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    /// <summary>
    /// One resource gauge card: title, large percent readout, progress bar and
    /// an optional secondary detail line (human-readable used/total bytes).
    /// The card fill is a faint translucent tint of the theme card stroke so
    /// it stays readable over Mica/LayerFill without adding an opaque surface.
    /// The caller owns the card margin (gutter between the gauge columns).
    /// </summary>
    private FrameworkElement BuildResourceCard(string title, double percent, string detail)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = CreateSubtleFill(),
        };

        var panel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 8,
        };

        panel.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        });

        panel.Children.Add(new TextBlock
        {
            Text = FormatPercent(percent),
            FontSize = 24,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        });

        panel.Children.Add(new ProgressBar
        {
            Minimum = 0,
            Maximum = 100,
            Value = Math.Clamp(Math.Max(0, percent), 0, 100),
        });

        if (!string.IsNullOrWhiteSpace(detail))
        {
            panel.Children.Add(new TextBlock
            {
                Text = detail,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
                MaxLines = 1,
            });
        }

        card.Child = panel;
        return card;
    }

    /// <summary>
    /// System information card with an InfoBag-style two-column label+value
    /// grid (hostname, OS, kernel version, CPU cores, uptime, panel version).
    /// </summary>
    private FrameworkElement BuildSystemInfoCard(DashboardEntry entry)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = CreateSubtleFill(),
        };

        var panel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 10,
        };

        panel.Children.Add(new TextBlock
        {
            Text = "System Info",
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        });

        // Two label+value pairs per row; relative columns only. Spacer column
        // separates the pair columns, Star columns share the value space.
        var bag = new Grid();
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(24) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        AddInfoPair(bag, 0, 0, "Hostname", entry.Hostname);
        AddInfoPair(bag, 0, 1, "OS", entry.Os);
        AddInfoPair(bag, 1, 0, "Kernel", entry.KernelVersion);
        AddInfoPair(bag, 1, 1, "CPU Cores", entry.CpuCores > 0 ? entry.CpuCores.ToString(CultureInfo.InvariantCulture) : "--");
        AddInfoPair(bag, 2, 0, "Uptime", entry.Uptime);
        AddInfoPair(bag, 2, 1, "Panel Version", entry.PanelVersion);

        panel.Children.Add(bag);
        card.Child = panel;
        return card;
    }

    /// <summary>
    /// Places one label+value pair into the InfoBag grid.
    /// <paramref name="pairIndex"/> 0 uses columns 0/1, 1 uses columns 3/4.
    /// </summary>
    private static void AddInfoPair(Grid bag, int row, int pairIndex, string label, string value)
    {
        var labelColumn = pairIndex == 0 ? 0 : 3;
        var valueColumn = pairIndex == 0 ? 1 : 4;

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 0, 12, 0),
        };
        Grid.SetRow(labelBlock, row);
        Grid.SetColumn(labelBlock, labelColumn);
        bag.Children.Add(labelBlock);

        var valueBlock = new TextBlock
        {
            Text = string.IsNullOrWhiteSpace(value) ? "--" : value,
            FontSize = 13,
            TextWrapping = TextWrapping.Wrap,
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 0, 0, 8),
        };
        Grid.SetRow(valueBlock, row);
        Grid.SetColumn(valueBlock, valueColumn);
        bag.Children.Add(valueBlock);
    }

    /// <summary>
    /// Translucent card fill derived from the theme card stroke (~4% alpha)
    /// so cards read over Mica/LayerFill in both light and dark themes
    /// without an opaque background.
    /// </summary>
    private Brush CreateSubtleFill()
    {
        var stroke = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray);
        var color = GetBrushColor(stroke, Microsoft.UI.Colors.Gray);
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }

    /// <summary>Percent readout; "--" when the metric is absent (-1).</summary>
    private static string FormatPercent(double value)
    {
        return value < 0
            ? "--"
            : value.ToString("F1", CultureInfo.InvariantCulture) + "%";
    }

    /// <summary>
    /// Uptime rendering. The Dart bridge already sends a formatted string;
    /// numeric seconds are tolerated and converted to a compact "Xd Yh Zm"
    /// form. Anything unparsable falls back to "--".
    /// </summary>
    private static string FormatUptime(JsonElement? element)
    {
        if (element == null) return "--";

        if (element.Value.ValueKind == JsonValueKind.Number &&
            element.Value.TryGetInt64(out var seconds) &&
            seconds >= 0)
        {
            var days = seconds / 86400;
            var hours = seconds % 86400 / 3600;
            var minutes = seconds % 3600 / 60;

            if (days > 0) return $"{days}d {hours}h {minutes}m";
            if (hours > 0) return $"{hours}h {minutes}m";
            return $"{minutes}m";
        }

        if (element.Value.ValueKind == JsonValueKind.String &&
            !string.IsNullOrWhiteSpace(element.Value.GetString()))
        {
            return element.Value.GetString()!.Trim();
        }

        return "--";
    }

    private static bool HasAnyProperty(JsonElement json)
    {
        if (json.ValueKind != JsonValueKind.Object) return false;

        using var enumerator = json.EnumerateObject();
        return enumerator.MoveNext();
    }

    private static Brush TryGetThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Color GetBrushColor(Brush brush, Color fallback)
        => brush is SolidColorBrush solid ? solid.Color : fallback;

    private static string? TryGetString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
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

    private static int TryGetInt(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number &&
            prop.TryGetInt32(out var value))
        {
            return value;
        }
        return -1;
    }
}

/// <summary>JsonElement extension helpers local to the dashboard parse.</summary>
internal static class DashboardJsonExtensions
{
    /// <summary>Returns the named property, or a JsonElement of kind Undefined when absent.</summary>
    public static JsonElement? GetPropertyOrDefault(this JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop))
        {
            return prop;
        }
        return null;
    }
}

/// <summary>Immutable view over one dashboard snapshot from the bridge.</summary>
internal sealed class DashboardEntry
{
    public double Cpu { get; set; } = -1;
    public double Memory { get; set; } = -1;
    public double Disk { get; set; } = -1;
    public string MemoryUsage { get; set; } = "";
    public string DiskUsage { get; set; } = "";
    public string Uptime { get; set; } = "";
    public string Hostname { get; set; } = "";
    public string Os { get; set; } = "";
    public string KernelVersion { get; set; } = "";
    public int CpuCores { get; set; } = -1;
    public string PanelVersion { get; set; } = "";
}
