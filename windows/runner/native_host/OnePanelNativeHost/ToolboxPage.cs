using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Markup;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Toolbox (device snapshot) page: system information, swap size,
/// DNS servers with a non-destructive connectivity check and the login user
/// list. All data flows through WindowsBridge (Dart business core over the
/// method channel); no direct HTTP from the native layer.
///
/// Upstream semantic reference: the 1Panel web frontend views/toolbox/device
/// page renders a read-only device form (DNS, hosts, swap, hostname, NTP sync
/// site, time zone, local time) where every row opens an edit drawer. The DNS
/// drawer offers a "check" button (dnsCheck) that reports success/failure
/// without saving - the client maps that to VerifyToolboxDnsAsync with an
/// inline success InfoBar on success and an error toast on failure, matching
/// the upstream MsgSuccess/MsgError feedback. Client simplifications forced by
/// the bridge contract: no save/apply operations (only the non-destructive
/// DNS check is exposed), no hosts-file editing, no password change and no
/// local-time sync button. The system row merges systemName + systemVersion
/// into a single "Ubuntu 24.04" style line; kernel renders productVersion;
/// swap off (total &lt;= 0) renders "Off" like the upstream swapOff hint; an
/// empty NTP value renders "--".
///
/// Bridge semantics: null means the bridge itself failed (error state on
/// initial load, toast on refresh); an empty JSON object means no active
/// server is configured (empty state).
/// </summary>
public sealed class ToolboxPage : ModulePageBase
{
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads, refresh and the DNS check.</summary>
    private bool _isBusy;

    public ToolboxPage()
    {
        PageTitle = L10n.T("toolboxCenterTitle", "Toolbox");
    }

    protected override async void OnPageShown()
    {
        await LoadSnapshotAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadSnapshotAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadSnapshotAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadSnapshotCoreAsync(showLoadingState);
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
    private async Task LoadSnapshotCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetDeviceSnapshotAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostToolboxSnapshotRefreshFailed", "Failed to refresh device snapshot."));
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

        BuildContent(ParseSnapshot(result.Value));
        SetState(PageState.Content);
    }

    private static DeviceSnapshotEntry ParseSnapshot(JsonElement json)
    {
        var entry = new DeviceSnapshotEntry();

        if (json.ValueKind == JsonValueKind.Object)
        {
            entry.Hostname = TryGetString(json, "hostname") ?? "";
            entry.SystemName = TryGetString(json, "systemName") ?? "";
            entry.SystemVersion = TryGetString(json, "systemVersion") ?? "";
            entry.ProductVersion = TryGetString(json, "productVersion") ?? "";
            entry.ProductName = TryGetString(json, "productName") ?? "";
            entry.TimeZone = TryGetString(json, "timeZone") ?? "";
            entry.LocalTime = TryGetString(json, "localTime") ?? "";
            entry.Ntp = TryGetString(json, "ntp") ?? "";
            entry.Dns = TryGetString(json, "dns") ?? "";
            entry.SwapMemoryTotal = TryGetLong(json, "swapMemoryTotal");
            entry.Users = ParseUsers(json);
        }

        return entry;
    }

    private static List<string> ParseUsers(JsonElement json)
    {
        var users = new List<string>();

        if (json.ValueKind == JsonValueKind.Object &&
            json.TryGetProperty("users", out var prop) &&
            prop.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in prop.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.String &&
                    !string.IsNullOrWhiteSpace(item.GetString()))
                {
                    users.Add(item.GetString()!.Trim());
                }
            }
        }

        return users;
    }

    private void BuildContent(DeviceSnapshotEntry entry)
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

        content.Children.Add(BuildSystemInfoCard(entry));
        content.Children.Add(BuildSwapDnsRow(entry));
        content.Children.Add(BuildUsersCard(entry.Users));

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
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadSnapshotAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    /// <summary>
    /// Card shell shared by all cards: rounded border with a faint translucent
    /// tint of the theme card stroke plus a semi-bold title line. The caller
    /// fills <paramref name="panel"/> with the card body.
    /// </summary>
    private FrameworkElement CreateCard(string title, out StackPanel panel)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = CreateSubtleFill(),
        };

        panel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 10,
        };

        panel.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        });

        card.Child = panel;
        return card;
    }

    /// <summary>
    /// System information card with an InfoBag-style two-column label+value
    /// grid: hostname, system (name + version merged), kernel (product
    /// version), product name, time zone, local time and the NTP sync site.
    /// </summary>
    private FrameworkElement BuildSystemInfoCard(DeviceSnapshotEntry entry)
    {
        var card = CreateCard(L10n.T("systemSettingsSystemSection", "System Info"), out var panel);

        // Two label+value pairs per row; relative columns only. Spacer column
        // separates the pair columns, Star columns share the value space.
        var bag = new Grid();
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(24) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        for (var i = 0; i < 4; i++)
        {
            bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        }

        AddInfoPair(bag, 0, 0, L10n.T("toolboxDeviceHostname", "Hostname"), entry.Hostname);
        AddInfoPair(bag, 0, 1, L10n.T("toolboxDeviceSystemLabel", "System"), JoinNonEmpty(" ", entry.SystemName, entry.SystemVersion));
        AddInfoPair(bag, 1, 0, L10n.T("hostToolboxKernelLabel", "Kernel"), entry.ProductVersion);
        AddInfoPair(bag, 1, 1, L10n.T("hostToolboxProductLabel", "Product"), entry.ProductName);
        AddInfoPair(bag, 2, 0, L10n.T("hostToolboxTimeZoneLabel", "Time Zone"), entry.TimeZone);
        AddInfoPair(bag, 2, 1, L10n.T("toolboxDeviceTimeLabel", "Local Time"), entry.LocalTime);
        AddInfoPair(bag, 3, 0, L10n.T("hostToolboxNtpServerLabel", "NTP Server"), entry.Ntp);

        panel.Children.Add(bag);
        return card;
    }

    /// <summary>
    /// Swap and DNS cards share one row of two equal Star columns so both
    /// scale with the window on high-DPI screens; the caller-applied gutter
    /// margin keeps them separated.
    /// </summary>
    private FrameworkElement BuildSwapDnsRow(DeviceSnapshotEntry entry)
    {
        var row = new Grid();
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var swapCard = BuildSwapCard(entry);
        swapCard.Margin = new Thickness(0, 0, 12, 0);
        Grid.SetColumn(swapCard, 0);
        row.Children.Add(swapCard);

        var dnsCard = BuildDnsCard(entry);
        Grid.SetColumn(dnsCard, 1);
        row.Children.Add(dnsCard);

        return row;
    }

    /// <summary>
    /// Swap card: human-readable total size (1024-based, matching the
    /// upstream computeSize helper). A total of zero or less renders "Off",
    /// mirroring the upstream swapOff hint.
    /// </summary>
    private FrameworkElement BuildSwapCard(DeviceSnapshotEntry entry)
    {
        var card = CreateCard(L10n.T("toolboxDeviceSwap", "Swap"), out var panel);

        var off = entry.SwapMemoryTotal <= 0;
        panel.Children.Add(new TextBlock
        {
            Text = off ? L10n.T("hostToolboxSwapOff", "Off") : FormatBytes(entry.SwapMemoryTotal),
            FontSize = 24,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        });

        panel.Children.Add(new TextBlock
        {
            Text = off ? L10n.T("hostToolboxSwapOffHint", "Swap is disabled on this host.") : L10n.T("hostToolboxSwapTotalHint", "Total swap size."),
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        });

        return card;
    }

    /// <summary>
    /// DNS card: the current value, an edit box with a "Verify" button and an
    /// inline success InfoBar. Verification is non-destructive (no save),
    /// matching the upstream dnsCheck action; success shows the inline bar
    /// while failure surfaces through the error toast like the upstream
    /// MsgError. Empty input is validated inline.
    /// </summary>
    private FrameworkElement BuildDnsCard(DeviceSnapshotEntry entry)
    {
        var card = CreateCard(L10n.T("toolboxDeviceDns", "DNS"), out var panel);

        if (!string.IsNullOrWhiteSpace(entry.Dns))
        {
            panel.Children.Add(new TextBlock
            {
                Text = "Current: " + entry.Dns,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
            });
        }

        var input = new TextBox
        {
            PlaceholderText = L10n.T("hostToolboxDnsPlaceholder", "e.g. 8.8.8.8"),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Margin = new Thickness(0, 0, 8, 0),
        };

        var verifyButton = new Button
        {
            Content = L10n.T("hostToolboxDnsVerifyAction", "Verify"),
            VerticalAlignment = VerticalAlignment.Stretch,
        };

        var inputRow = new Grid();
        inputRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        inputRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(input, 0);
        inputRow.Children.Add(input);
        Grid.SetColumn(verifyButton, 1);
        inputRow.Children.Add(verifyButton);
        panel.Children.Add(inputRow);

        // Inline validation error for empty input; cleared on any edit.
        var errorText = new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
            Visibility = Visibility.Collapsed,
        };
        panel.Children.Add(errorText);

        // Inline success feedback, matching the upstream MsgSuccess.
        var successBar = new InfoBar
        {
            Severity = InfoBarSeverity.Success,
            Message = L10n.T("hostToolboxDnsReachable", "DNS reachable"),
            IsClosable = true,
            IsOpen = false,
        };
        panel.Children.Add(successBar);

        // Any edit clears the pending inline error and the success bar.
        input.TextChanged += (s, e) =>
        {
            SetInlineError(errorText, null);
            successBar.IsOpen = false;
        };

        verifyButton.Click += (s, e) =>
            _ = VerifyDnsAsync(input, verifyButton, errorText, successBar);

        return card;
    }

    /// <summary>
    /// Non-destructive DNS check with inline validation and per-call button
    /// disable. Shares the page-level _isBusy guard so a refresh cannot run
    /// concurrently with a verification.
    /// </summary>
    private async Task VerifyDnsAsync(
        TextBox input, Button verifyButton, TextBlock errorText, InfoBar successBar)
    {
        if (_isBusy) return;
        _isBusy = true;
        verifyButton.IsEnabled = false;

        try
        {
            successBar.IsOpen = false;

            var dns = input.Text.Trim();
            if (dns.Length == 0)
            {
                SetInlineError(errorText, L10n.T("hostToolboxDnsEmptyError", "Enter a DNS server to verify."));
                return;
            }
            SetInlineError(errorText, null);

            var reachable = await WindowsBridge.VerifyToolboxDnsAsync(dns);
            if (reachable)
            {
                successBar.IsOpen = true;
            }
            else
            {
                _errorToast.Show($"DNS check failed: {dns} is not reachable.");
            }
        }
        finally
        {
            verifyButton.IsEnabled = true;
            _isBusy = false;
        }
    }

    /// <summary>
    /// Login user card: the snapshot user array rendered as tag pills inside
    /// an ItemsControl with a wrapping panel. The whole card is hidden when
    /// the array is empty.
    /// </summary>
    private FrameworkElement BuildUsersCard(List<string> users)
    {
        var card = CreateCard(L10n.T("hostToolboxUsersTitle", "Users"), out var panel);

        if (users.Count == 0)
        {
            card.Visibility = Visibility.Collapsed;
            return card;
        }

        var items = new ItemsControl();
        items.ItemsPanel = CreateWrapPanelTemplate();
        foreach (var user in users)
        {
            items.Items.Add(CreateUserTag(user));
        }

        panel.Children.Add(items);
        return card;
    }

    /// <summary>
    /// Wrapping items panel for the user tags. WrapPanel is not part of the
    /// framework, so the template is loaded from a minimal XAML string using
    /// VariableSizedWrapGrid, which wraps at the available width.
    /// </summary>
    private static ItemsPanelTemplate CreateWrapPanelTemplate()
    {
        const string xaml =
            "<ItemsPanelTemplate xmlns=\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\">"
            + "<VariableSizedWrapGrid Orientation=\"Horizontal\" />"
            + "</ItemsPanelTemplate>";
        return (ItemsPanelTemplate)XamlReader.Load(xaml);
    }

    /// <summary>Neutral pill tag for one login user name.</summary>
    private static FrameworkElement CreateUserTag(string user)
    {
        var accentBrush = TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray);
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            Margin = new Thickness(0, 0, 8, 8),
            VerticalAlignment = VerticalAlignment.Top,
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            Child = new TextBlock
            {
                Text = user,
                FontSize = 12,
                Foreground = accentBrush,
                VerticalAlignment = VerticalAlignment.Center,
            },
        };
    }

    /// <summary>
    /// Places one label+value pair into the InfoBag grid.
    /// <paramref name="pairIndex"/> 0 uses columns 0/1, 1 uses columns 3/4.
    /// Empty values render "--".
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

    /// <summary>Joins the non-empty parts with <paramref name="separator"/>.</summary>
    private static string JoinNonEmpty(string separator, params string[] parts)
    {
        return string.Join(separator, System.Array.FindAll(parts, p => !string.IsNullOrWhiteSpace(p)));
    }

    /// <summary>
    /// 1024-based byte formatting ("B" through "TB"), mirroring the upstream
    /// computeSize helper.
    /// </summary>
    private static string FormatBytes(long bytes)
    {
        string[] units = { "B", "KB", "MB", "GB", "TB" };
        double size = bytes;
        var unit = 0;
        while (size >= 1024 && unit < units.Length - 1)
        {
            size /= 1024;
            unit++;
        }

        return size.ToString(unit == 0 ? "F0" : "F1", CultureInfo.InvariantCulture) + " " + units[unit];
    }

    private static void SetInlineError(TextBlock target, string? message)
    {
        if (string.IsNullOrEmpty(message))
        {
            target.Text = string.Empty;
            target.Visibility = Visibility.Collapsed;
        }
        else
        {
            target.Text = message;
            target.Visibility = Visibility.Visible;
        }
    }

    /// <summary>
    /// Translucent card fill derived from the theme card stroke (~4% alpha)
    /// so cards read over Mica/LayerFill in both light and dark themes
    /// without an opaque background.
    /// </summary>
    private static Brush CreateSubtleFill()
    {
        var stroke = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray);
        var color = GetBrushColor(stroke, Microsoft.UI.Colors.Gray);
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
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

    private static bool HasAnyProperty(JsonElement json)
    {
        if (json.ValueKind != JsonValueKind.Object) return false;

        using var enumerator = json.EnumerateObject();
        return enumerator.MoveNext();
    }

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

    private static long TryGetLong(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number &&
            prop.TryGetInt64(out var value))
        {
            return value;
        }
        return -1;
    }
}

/// <summary>Immutable view over one device snapshot from the bridge.</summary>
internal sealed class DeviceSnapshotEntry
{
    public string Hostname { get; set; } = "";
    public string SystemName { get; set; } = "";
    public string SystemVersion { get; set; } = "";
    public string ProductVersion { get; set; } = "";
    public string ProductName { get; set; } = "";
    public string TimeZone { get; set; } = "";
    public string LocalTime { get; set; } = "";
    public string Ntp { get; set; } = "";
    public string Dns { get; set; } = "";
    public long SwapMemoryTotal { get; set; } = -1;
    public List<string> Users { get; set; } = new();
}
