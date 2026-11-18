using System;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native SSH management page (host module). Mirrors the upstream 1Panel web
/// frontend semantics (views/host/ssh/ssh):
/// - a service status card with a large Running/Stopped badge, an explicit
///   "service not installed" info line when the upstream isExist flag is
///   false, and the sshd settings as a key/value grid (port, listen address,
///   password authentication, public key authentication, root login policy,
///   DNS lookup, autostart, current user, plus the upstream status message
///   when present);
/// - Start / Stop / Restart service operations without a confirmation dialog
///   (matching the upstream buttons), guarded against re-entrancy; success
///   stays silent because the refreshed status card shows the new state;
/// - the raw sshd configuration file inside an Expander: a read-only
///   monospace viewer prefilled from the bridge, an Edit toggle and a Save
///   action that confirms before overwriting the remote file; a save failure
///   surfaces the error toast and keeps the editing state.
/// All data flows through WindowsBridge (method channel to the Dart core);
/// no direct HTTP from the native layer.
/// </summary>
public sealed class HostPage : ModulePageBase
{
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads, service operations and the config save.</summary>
    private bool _isBusy;

    /// <summary>Server-side sshd_config snapshot; null when the load failed.</summary>
    private string? _configText;

    // Config editor controls, recreated together with the page content.
    private TextBox? _configBox;
    private Button? _editConfigButton;
    private Button? _saveConfigButton;

    public HostPage()
    {
        PageTitle = L10n.T("hostHostSshTitle", "SSH");
    }

    protected override async void OnPageShown()
    {
        await LoadSshAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadSshAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadSshAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadSshCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body; also used as the silent refresh after successful
    /// service operations or config saves. With
    /// <paramref name="showLoadingState"/> the page swaps to the loading
    /// spinner; otherwise the current content stays visible and failures
    /// surface via the error toast.
    /// </summary>
    private async Task LoadSshCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var info = await WindowsBridge.GetSshInfoAsync();

        if (info == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostHostSshRefreshFailed", "Failed to refresh the SSH information."));
            }
            return;
        }

        // Bridge semantics: an empty object means no active server is
        // configured, which maps to the empty state (same as DashboardPage).
        if (!HasAnyProperty(info.Value))
        {
            SetState(PageState.Empty);
            return;
        }

        var entry = ParseSshInfo(info.Value);

        // The raw sshd_config text arrives as a JSON string; null marks a
        // failed load (the config editor then shows a failure placeholder).
        var config = await WindowsBridge.GetSshConfigAsync();
        _configText = config?.ValueKind == JsonValueKind.String ? config.Value.GetString() : null;

        BuildContent(entry);
        SetState(PageState.Content);
    }

    private static SshInfoEntry ParseSshInfo(JsonElement json)
    {
        var entry = new SshInfoEntry();

        if (json.ValueKind != JsonValueKind.Object) return entry;

        entry.AutoStart = TryGetBool(json, "autoStart");
        entry.IsExist = TryGetBool(json, "isExist");
        entry.IsActive = TryGetBool(json, "isActive");
        entry.Message = TryGetStringValue(json, "message") ?? "";
        entry.Port = TryGetStringValue(json, "port") ?? "";
        entry.ListenAddress = TryGetStringValue(json, "listenAddress") ?? "";
        entry.PasswordAuthentication = TryGetStringValue(json, "passwordAuthentication") ?? "";
        entry.PubkeyAuthentication = TryGetStringValue(json, "pubkeyAuthentication") ?? "";
        entry.PermitRootLogin = TryGetStringValue(json, "permitRootLogin") ?? "";
        entry.UseDns = TryGetStringValue(json, "useDNS") ?? "";
        entry.CurrentUser = TryGetStringValue(json, "currentUser") ?? "";
        return entry;
    }

    private void BuildContent(SshInfoEntry entry)
    {
        // Root layout: CommandBar on top, scrollable content below (relative rows).
        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var commandBar = BuildCommandBar(entry);
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
        };
        content.Children.Add(BuildStatusCard(entry));
        content.Children.Add(BuildConfigExpander());
        scrollViewer.Content = content;
        root.Children.Add(scrollViewer);

        // Failure toast floats above the content, bottom-aligned (kept in the
        // visual tree so Show() actually renders).
        _errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(_errorToast, 1);
        AttachToast(root, _errorToast);

        ModuleContentPresenter.Content = root;
    }

    private CommandBar BuildCommandBar(SshInfoEntry entry)
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
        refreshButton.Click += (s, e) => _ = LoadSshAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        // Service operations follow the upstream visibility semantics: the
        // buttons stay visible but only apply when the service exists, and
        // Start targets a stopped service while Stop/Restart target a
        // running one (upstream shows Stop when active, Start when not).
        bool canOperate = entry.IsExist;

        var startButton = new AppBarButton
        {
            Label = L10n.T("commonStart", "Start"),
            Icon = new FontIcon { Glyph = "\uE768" }, // Play.
            IsEnabled = canOperate && !entry.IsActive,
        };
        startButton.Click += (s, e) => _ = OperateServiceAsync("start");
        bar.SecondaryCommands.Add(startButton);

        var stopButton = new AppBarButton
        {
            Label = L10n.T("commonStop", "Stop"),
            Icon = new FontIcon { Glyph = "\uE71A" }, // Stop.
            IsEnabled = canOperate && entry.IsActive,
        };
        stopButton.Click += (s, e) => _ = OperateServiceAsync("stop");
        bar.SecondaryCommands.Add(stopButton);

        var restartButton = new AppBarButton
        {
            Label = L10n.T("commonRestart", "Restart"),
            Icon = new FontIcon { Glyph = "\uE777" }, // Sync.
            IsEnabled = canOperate,
        };
        restartButton.Click += (s, e) => _ = OperateServiceAsync("restart");
        bar.SecondaryCommands.Add(restartButton);

        return bar;
    }

    /// <summary>Status card: large Running/Stopped badge plus the sshd settings grid.</summary>
    private FrameworkElement BuildStatusCard(SshInfoEntry entry)
    {
        var card = new StackPanel { Orientation = Orientation.Vertical };

        // Header: big status badge, with a "not installed" info line below it
        // when the upstream payload reports a missing SSH service.
        var header = new Grid { Margin = new Thickness(0, 0, 0, 12) };
        header.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        header.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var badge = BuildStatusBadge(entry.IsActive);
        badge.HorizontalAlignment = HorizontalAlignment.Left;
        Grid.SetRow(badge, 0);
        header.Children.Add(badge);

        if (!entry.IsExist)
        {
            var notInstalled = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Spacing = 6,
                Margin = new Thickness(0, 8, 0, 0),
            };
            notInstalled.Children.Add(new FontIcon
            {
                Glyph = "\uE7BA", // Info.
                FontSize = 14,
                Foreground = TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
            });
            notInstalled.Children.Add(new TextBlock
            {
                Text = L10n.T("hostHostSshNotInstalled", "SSH service is not installed on this server."),
                FontSize = 13,
                Foreground = TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
                VerticalAlignment = VerticalAlignment.Center,
            });
            Grid.SetRow(notInstalled, 1);
            header.Children.Add(notInstalled);
        }

        card.Children.Add(header);

        // Key/value grid over two relative columns (label Auto, value Star).
        var kvGrid = new Grid
        {
            ColumnSpacing = 12,
            RowSpacing = 6,
            Margin = new Thickness(0, 0, 0, 16),
        };
        kvGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        kvGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        AddKvRow(kvGrid, L10n.T("sshPortLabel", "Port"), CreateValueText(string.IsNullOrEmpty(entry.Port) ? "-" : entry.Port));
        AddKvRow(kvGrid, L10n.T("sshListenAddressLabel", "Listen address"), CreateValueText(GetListenAddressDisplay(entry)));
        AddKvRow(kvGrid, L10n.T("sshPasswordAuthenticationLabel", "Password authentication"), CreateYesNoBadge(entry.PasswordAuthentication));
        AddKvRow(kvGrid, L10n.T("sshPubkeyAuthenticationLabel", "Public key authentication"), CreateValueText(GetRawOrDash(entry.PubkeyAuthentication)));
        AddKvRow(kvGrid, L10n.T("sshPermitRootLoginLabel", "Permit root login"), CreateValueText(GetRawOrDash(entry.PermitRootLogin)));
        AddKvRow(kvGrid, L10n.T("sshUseDnsLabel", "Use DNS"), CreateValueText(GetRawOrDash(entry.UseDns)));
        AddKvRow(kvGrid, L10n.T("sshAutoStartLabel", "Auto start"), CreateValueText(entry.AutoStart ? L10n.T("commonYes", "Yes") : L10n.T("commonNo", "No")));
        AddKvRow(kvGrid, L10n.T("sshCurrentUserLabel", "Current user"), CreateValueText(GetRawOrDash(entry.CurrentUser)));

        // The upstream status message only renders when it carries a value.
        if (!string.IsNullOrWhiteSpace(entry.Message))
        {
            var messageText = new TextBlock
            {
                Text = entry.Message,
                FontSize = 13,
                Foreground = TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
                TextWrapping = TextWrapping.Wrap,
                VerticalAlignment = VerticalAlignment.Center,
            };
            AddKvRow(kvGrid, L10n.T("sshLogsMessageLabel", "Message"), messageText);
        }

        card.Children.Add(kvGrid);
        return card;
    }

    /// <summary>Large status pill: Running = success green, Stopped = critical red.</summary>
    private static FrameworkElement BuildStatusBadge(bool active)
    {
        var accentBrush = active
            ? TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.SeaGreen)
            : TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.IndianRed);
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        var badgeContent = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
        badgeContent.Children.Add(new Ellipse
        {
            Width = 10,
            Height = 10,
            Fill = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });
        badgeContent.Children.Add(new TextBlock
        {
            Text = active ? L10n.T("statusRunning", "Running") : L10n.T("statusStopped", "Stopped"),
            FontSize = 15,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            Foreground = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });

        // Translucent tint keeps the pill readable over Mica/LayerFill.
        return new Border
        {
            CornerRadius = new CornerRadius(14),
            Padding = new Thickness(14, 6, 14, 6),
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            VerticalAlignment = VerticalAlignment.Center,
            Child = badgeContent,
        };
    }

    /// <summary>
    /// Raw sshd_config area inside an expandable section: a read-only
    /// monospace viewer prefilled from the bridge, an Edit toggle and a
    /// confirmed Save. Recreated on every content rebuild, so each load
    /// resets back to the read-only mode.
    /// </summary>
    private FrameworkElement BuildConfigExpander()
    {
        bool configFailed = _configText == null;

        _configBox = new TextBox
        {
            IsReadOnly = true,
            AcceptsReturn = true,
            Height = 320,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 12,
            TextWrapping = TextWrapping.NoWrap,
            Text = _configText ?? "",
            PlaceholderText = configFailed
                ? L10n.T("hostHostSshConfigLoadFailed", "Failed to load the configuration file.")
                : L10n.T("hostHostSshConfigEmptyPlaceholder", "# The SSH configuration file does not exist or is empty (/etc/ssh/sshd_config)"),
        };
        ScrollViewer.SetHorizontalScrollBarVisibility(_configBox, ScrollBarVisibility.Auto);

        _editConfigButton = new Button
        {
            Content = L10n.T("commonEdit", "Edit"),
            IsEnabled = !configFailed,
        };
        _editConfigButton.Click += OnEditConfigClicked;

        _saveConfigButton = new Button
        {
            Content = L10n.T("commonSave", "Save"),
            IsEnabled = false, // Saving is only allowed in edit mode.
        };
        _saveConfigButton.Click += (s, e) => _ = SaveConfigAsync();

        var actions = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            Margin = new Thickness(0, 8, 0, 0),
        };
        actions.Children.Add(_editConfigButton);
        actions.Children.Add(_saveConfigButton);

        var configPanel = new StackPanel { Orientation = Orientation.Vertical };
        configPanel.Children.Add(_configBox);
        configPanel.Children.Add(actions);

        return new Expander
        {
            Header = new TextBlock
            {
                Text = L10n.T("hostHostSshConfigFileTitle", "Configuration file (/etc/ssh/sshd_config)"),
                FontSize = 14,
            },
            Content = configPanel,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Margin = new Thickness(0, 4, 0, 0),
        };
    }

    private void OnEditConfigClicked(object sender, RoutedEventArgs e)
    {
        if (_configBox == null || _configText == null) return;

        _configBox.IsReadOnly = false;
        _editConfigButton!.IsEnabled = false;
        _saveConfigButton!.IsEnabled = true;
        _configBox.Focus(FocusState.Programmatic);
    }

    /// <summary>
    /// Saves the edited sshd_config after a confirmation naming the target
    /// file. Success silently reloads the page (the editor is rebuilt in
    /// read-only mode with the persisted content); failure shows the toast
    /// and keeps the editing state so the user can retry.
    /// </summary>
    private async Task SaveConfigAsync()
    {
        if (_isBusy || _configBox == null) return;

        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                L10n.T("hostHostSshSaveTitle", "Save SSH configuration"),
                L10n.T("hostHostSshSaveMessage", "This will overwrite /etc/ssh/sshd_config with the edited content.\nAn invalid configuration may make the SSH service unavailable. Continue?"),
                L10n.T("commonSave", "Save"),
                L10n.T("commonCancel", "Cancel"));

            if (!confirmed) return;

            var success = await WindowsBridge.SaveSshConfigAsync(_configBox.Text);
            if (success)
            {
                // Silent refresh rebuilds the editor in read-only mode.
                await LoadSshCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show(L10n.T("hostHostSshSaveFailed", "Failed to save the SSH configuration."));
                // Keep the editing state: the buttons are untouched.
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Start/stop/restart service operation without a confirmation (upstream
    /// buttons behave the same). Success silently refreshes so the status
    /// card shows the new state; failure shows the toast.
    /// </summary>
    private async Task OperateServiceAsync(string operation)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var success = await WindowsBridge.OperateSshAsync(operation);
            if (success)
            {
                await LoadSshCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to {operation} the SSH service.");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Listen address for display, mirroring the Dart presentation helper:
    /// an empty address or the upstream all-interfaces value renders as
    /// "0.0.0.0,::" plus the port when available.
    /// </summary>
    private static string GetListenAddressDisplay(SshInfoEntry entry)
    {
        var address = entry.ListenAddress.Trim();
        if (address.Length == 0 || address == "0.0.0.0,::")
        {
            return string.IsNullOrEmpty(entry.Port) ? "0.0.0.0,::" : $"0.0.0.0,::{entry.Port}";
        }
        return address;
    }

    private static string GetRawOrDash(string value)
        => string.IsNullOrWhiteSpace(value) ? "-" : value;

    private static void AddKvRow(Grid grid, string label, FrameworkElement value)
    {
        var rowIndex = grid.RowDefinitions.Count;
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetRow(labelBlock, rowIndex);
        Grid.SetColumn(labelBlock, 0);
        grid.Children.Add(labelBlock);

        value.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetRow(value, rowIndex);
        Grid.SetColumn(value, 1);
        grid.Children.Add(value);
    }

    private static TextBlock CreateValueText(string text)
    {
        return new TextBlock
        {
            Text = text,
            FontSize = 13,
            Foreground = TryGetThemeBrush("TextFillColorPrimaryBrush", Microsoft.UI.Colors.Gray),
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
        };
    }

    /// <summary>Yes/No pill for the authentication switches: "yes" renders a
    /// green Yes badge, "no" a red No badge, anything else a neutral pill
    /// with the raw value (theme-resource brushes, hardcoded fallbacks).</summary>
    private static FrameworkElement CreateYesNoBadge(string rawValue)
    {
        var value = rawValue.Trim().ToLowerInvariant();

        Brush accentBrush;
        string text;
        if (value == "yes")
        {
            accentBrush = TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.SeaGreen);
            text = L10n.T("commonYes", "Yes");
        }
        else if (value == "no")
        {
            accentBrush = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.IndianRed);
            text = L10n.T("commonNo", "No");
        }
        else
        {
            accentBrush = TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray);
            text = GetRawOrDash(rawValue);
        }
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        var badgeContent = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        badgeContent.Children.Add(new Ellipse
        {
            Width = 8,
            Height = 8,
            Fill = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });
        badgeContent.Children.Add(new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });

        // Translucent tint keeps the pill readable over Mica/LayerFill.
        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            VerticalAlignment = VerticalAlignment.Center,
            Child = badgeContent,
        };
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

    private static bool TryGetBool(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop))
        {
            if (prop.ValueKind == JsonValueKind.True) return true;
            if (prop.ValueKind == JsonValueKind.False) return false;
        }
        return false;
    }

    /// <summary>String payload reader that also tolerates numeric values
    /// (e.g. a port arriving as a JSON number).</summary>
    private static string? TryGetStringValue(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop))
        {
            if (prop.ValueKind == JsonValueKind.String) return prop.GetString();
            if (prop.ValueKind == JsonValueKind.Number) return prop.GetRawText();
        }
        return null;
    }

    /// <summary>Row model straight from the bridge payload; field kinds match
    /// the Dart SshInfo model (booleans + strings).</summary>
    private sealed class SshInfoEntry
    {
        public bool AutoStart { get; set; }
        public bool IsExist { get; set; }
        public bool IsActive { get; set; }
        public string Message { get; set; } = "";
        public string Port { get; set; } = "";
        public string ListenAddress { get; set; } = "";
        public string PasswordAuthentication { get; set; } = "";
        public string PubkeyAuthentication { get; set; } = "";
        public string PermitRootLogin { get; set; } = "";
        public string UseDns { get; set; } = "";
        public string CurrentUser { get; set; } = "";
    }
}
