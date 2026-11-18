using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Servers module page: full CRUD over the client's managed 1Panel
/// instances (add, switch current, delete). All data flows through
/// WindowsBridge (Dart business core over the method channel); no direct
/// HTTP from the native layer.
///
/// Upstream semantic reference: the 1Panel web frontend (views/home) renders
/// a single connected instance and surfaces CPU/memory utilization on its
/// dashboard. The client multi-machine enhancement lists every instance as a
/// row and mirrors those dashboard metrics per row. Switching is
/// non-destructive but still confirmed, since it changes which instance every
/// module talks to; deleting follows the destructive-confirmation pattern
/// shared across upstream views, and the current server cannot be deleted
/// directly - the user is asked to switch first.
/// </summary>
public sealed class ServersPage : ModulePageBase
{
    private readonly List<ServerEntry> _servers = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads, the add dialog and row operations.</summary>
    private bool _isBusy;

    public ServersPage()
    {
        PageTitle = L10n.T("serverPageTitle", "Servers");
    }

    protected override async void OnPageShown()
    {
        await LoadServersAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadServersAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadServersAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadServersCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body; also used as the silent refresh after successful
    /// operations. With <paramref name="showLoadingState"/> the page swaps to
    /// the loading spinner; otherwise the current content stays visible and
    /// failures surface via the error toast.
    /// </summary>
    private async Task LoadServersCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetServersAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostServersRefreshFailed", "Failed to refresh servers."));
            }
            return;
        }

        var servers = ParseServers(result.Value);
        if (servers.Count == 0)
        {
            _servers.Clear();
            SetState(PageState.Empty);
            return;
        }

        _servers.Clear();
        _servers.AddRange(servers);
        BuildContent(_servers);
        SetState(PageState.Content);
    }

    private List<ServerEntry> ParseServers(JsonElement json)
    {
        var servers = new List<ServerEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                servers.Add(new ServerEntry
                {
                    Id = TryGetString(item, "id"),
                    Name = TryGetString(item, "name") ?? L10n.T("systemSettingsUnknown", "Unknown"),
                    Url = TryGetString(item, "url") ?? "",
                    IsCurrent = TryGetBool(item, "isCurrent"),
                    Cpu = TryGetDouble(item, "cpu"),
                    Memory = TryGetDouble(item, "memory"),
                });
            }
        }

        return servers;
    }

    private void BuildContent(List<ServerEntry> servers)
    {
        // Root layout: CommandBar on top, scrollable list below (relative rows).
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

        var list = new ListView
        {
            // Row click triggers the switch flow; buttons inside an item
            // handle their own clicks, so the "more" button stays isolated.
            SelectionMode = ListViewSelectionMode.None,
            IsItemClickEnabled = true,
            Margin = new Thickness(8, 0, 8, 0),
        };
        list.ItemClick += OnServerClicked;

        foreach (var server in servers)
        {
            list.Items.Add(CreateServerItem(server));
        }

        scrollViewer.Content = list;
        root.Children.Add(scrollViewer);

        // Failure toast floats above the list, bottom-aligned (kept in the
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

        var addButton = new AppBarButton
        {
            Label = L10n.T("serverFormTitle", "Add server"),
            Icon = new FontIcon { Glyph = "\uE710" },
        };
        addButton.Click += (s, e) => _ = ShowAddServerDialogAsync();
        bar.PrimaryCommands.Add(addButton);

        var refreshButton = new AppBarButton
        {
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadServersAsync(showLoadingState: true);
        bar.SecondaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateServerItem(ServerEntry server)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = server,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Info column: name (+ current badge), URL, optional usage bars.
        var info = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var nameRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
        };
        nameRow.Children.Add(new TextBlock
        {
            Text = server.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        if (server.IsCurrent)
        {
            nameRow.Children.Add(CreateCurrentBadge());
        }
        info.Children.Add(nameRow);

        if (!string.IsNullOrWhiteSpace(server.Url))
        {
            info.Children.Add(new TextBlock
            {
                Text = server.Url,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            });
        }

        // Dashboard-style utilization bars; hidden entirely when no value.
        if (server.Cpu >= 0)
        {
            info.Children.Add(BuildUsageBar(L10n.T("serverCpuLabel", "CPU"), server.Cpu));
        }
        if (server.Memory >= 0)
        {
            info.Children.Add(BuildUsageBar(L10n.T("serverMemoryLabel", "Memory"), server.Memory));
        }

        Grid.SetColumn(info, 0);
        grid.Children.Add(info);

        // Per-row "more" actions (upstream: row dropdown menu).
        var moreButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE712", FontSize = 14 },
            Background = null,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(6, 2, 6, 2),
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(moreButton, L10n.T("hostServersActions", "Server actions"));
        moreButton.Flyout = BuildRowFlyout(server);
        Grid.SetColumn(moreButton, 1);
        grid.Children.Add(moreButton);

        return grid;
    }

    private MenuFlyout BuildRowFlyout(ServerEntry server)
    {
        var flyout = new MenuFlyout();

        var deleteItem = new MenuFlyoutItem
        {
            Text = L10n.T("commonDelete", "Delete"),
            Icon = new FontIcon { Glyph = "\uE74D" },
        };
        deleteItem.Click += (s, e) => _ = DeleteServerAsync(server);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    /// <summary>"Current" pill badge with a success-colored dot.</summary>
    private static FrameworkElement CreateCurrentBadge()
    {
        var accentBrush = TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green);
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Green);

        var content = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        content.Children.Add(new Ellipse
        {
            Width = 8,
            Height = 8,
            Fill = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });
        content.Children.Add(new TextBlock
        {
            Text = L10n.T("serverCurrent", "Current"),
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
            Child = content,
        };
    }

    /// <summary>Label + ProgressBar + percent readout; relative widths only.</summary>
    private static FrameworkElement BuildUsageBar(string label, double percent)
    {
        var row = new Grid { Margin = new Thickness(0, 4, 0, 0) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 12,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(0, 0, 8, 0),
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
        };
        Grid.SetColumn(labelBlock, 0);
        row.Children.Add(labelBlock);

        var bar = new ProgressBar
        {
            Minimum = 0,
            Maximum = 100,
            Value = Math.Clamp(percent, 0, 100),
            MinWidth = 80,
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(bar, 1);
        row.Children.Add(bar);

        var valueBlock = new TextBlock
        {
            Text = percent.ToString("F1", CultureInfo.InvariantCulture) + "%",
            FontSize = 12,
            MinWidth = 48,
            VerticalAlignment = VerticalAlignment.Center,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
        };
        Grid.SetColumn(valueBlock, 2);
        row.Children.Add(valueBlock);

        return row;
    }

    private async void OnServerClicked(object? sender, ItemClickEventArgs e)
    {
        if (e.ClickedItem is FrameworkElement { Tag: ServerEntry server })
        {
            await SwitchToServerAsync(server);
        }
    }

    /// <summary>
    /// Row click = switch current server. Non-destructive but confirmed,
    /// since it changes which instance every module talks to. Clicking the
    /// already-current server is a no-op.
    /// </summary>
    private async Task SwitchToServerAsync(ServerEntry server)
    {
        if (_isBusy) return;
        if (server.IsCurrent) return;

        // _isBusy is held across the whole flow so no second dialog or
        // operation can start while the confirmation is pending.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                L10n.T("serverActionSwitch", "Switch Server"),
                $"Switch to \"{server.Name}\"?\n\nURL: {server.Url}",
                L10n.T("hostServersSwitch", "Switch"),
                L10n.T("commonCancel", "Cancel"));

            if (!confirmed) return;

            var success = await WindowsBridge.SwitchServerAsync(server.Id ?? string.Empty);
            if (success)
            {
                // Silent refresh keeps the list visible (no success toast).
                await LoadServersCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to switch to \"{server.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Destructive row action; the current server must be switched away first.</summary>
    private async Task DeleteServerAsync(ServerEntry server)
    {
        if (_isBusy) return;

        if (server.IsCurrent)
        {
            _errorToast.Show(L10n.T("hostServersDeleteCurrentBlocked", "The current server cannot be deleted. Switch to another server first."));
            return;
        }

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                L10n.T("serverDeleteConfirmTitle", "Delete Server"),
                $"Delete server \"{server.Name}\" ({server.Url})?\nThis action cannot be undone.",
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.DeleteServerAsync(server.Id ?? string.Empty);
            if (success)
            {
                await LoadServersCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{server.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Add-server form dialog with inline validation. _isBusy is held while
    /// the dialog is open so the CommandBar button cannot open a second
    /// dialog and row operations stay blocked until it closes.
    /// </summary>
    private async Task ShowAddServerDialogAsync()
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var nameBox = new TextBox { Header = L10n.T("commonName", "Name"), PlaceholderText = L10n.T("hostServersNamePlaceholder", "My server") };
            var urlBox = new TextBox { Header = L10n.T("commonUrl", "URL"), PlaceholderText = "http://host:port/" };
            var apiKeyBox = new TextBox { Header = L10n.T("serverFormApiKey", "API key") };

            var errorText = new TextBlock
            {
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                Visibility = Visibility.Collapsed,
            };

            // Any edit clears the pending inline validation error.
            void ClearError() => SetFormError(errorText, null);
            nameBox.TextChanged += (s, e) => ClearError();
            urlBox.TextChanged += (s, e) => ClearError();
            apiKeyBox.TextChanged += (s, e) => ClearError();

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(nameBox);
            form.Children.Add(urlBox);
            form.Children.Add(apiKeyBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = L10n.T("serverFormTitle", "Add Server"),
                Content = form,
                PrimaryButtonText = L10n.T("commonAdd", "Add"),
                CloseButtonText = L10n.T("commonCancel", "Cancel"),
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            // Inline validation: on invalid input cancel the close so the
            // dialog stays open and the error shows next to the fields.
            dialog.Closing += (s, args) =>
            {
                if (args.Result != ContentDialogResult.Primary) return;

                var error = ValidateServerInput(nameBox.Text, urlBox.Text, apiKeyBox.Text);
                if (error != null)
                {
                    args.Cancel = true;
                    SetFormError(errorText, error);
                }
            };

            var result = await dialog.ShowAsync();
            if (result != ContentDialogResult.Primary) return;

            var success = await WindowsBridge.AddServerAsync(
                nameBox.Text.Trim(), urlBox.Text.Trim(), apiKeyBox.Text.Trim());
            if (!success)
            {
                _errorToast.Show($"Failed to add server \"{nameBox.Text.Trim()}\".");
                return;
            }

            // Silent refresh (no loading swap, no success toast).
            await LoadServersCoreAsync(showLoadingState: false);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Returns the first validation error, or null when the input is valid.</summary>
    private static string? ValidateServerInput(string name, string url, string apiKey)
    {
        if (string.IsNullOrWhiteSpace(name)) return L10n.T("websitesSslAccountsValidationNameRequired", "Name is required.");

        var trimmedUrl = url.Trim();
        if (trimmedUrl.Length == 0) return L10n.T("hostServersUrlRequired", "URL is required.");
        if (!trimmedUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
            !trimmedUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return L10n.T("hostServersUrlHttpRequired", "URL must start with http:// or https://.");
        }

        if (string.IsNullOrWhiteSpace(apiKey)) return L10n.T("hostServersApiKeyRequired", "API key is required.");
        return null;
    }

    private static void SetFormError(TextBlock target, string? message)
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

    private static bool TryGetBool(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.True)
        {
            return true;
        }
        return false;
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

    private sealed class ServerEntry
    {
        public string? Id { get; set; }
        public string Name { get; set; } = "";
        public string Url { get; set; } = "";
        public bool IsCurrent { get; set; }
        public double Cpu { get; set; } = -1;
        public double Memory { get; set; } = -1;
    }
}
