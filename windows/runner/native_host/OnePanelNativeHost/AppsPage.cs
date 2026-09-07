using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Apps module page: lists installed 1Panel apps with per-row
/// start/stop and uninstall. All data flows through WindowsBridge (Dart
/// business core over the method channel); no direct HTTP from the native
/// layer.
///
/// Upstream semantic reference: 1Panel web frontend (views/app-store/installed)
/// shows each installed app with a status tag (Running = success green,
/// everything else neutral) and Start/Stop actions; uninstall is destructive
/// (removes the app together with its data) and therefore always confirmed.
/// </summary>
public sealed class AppsPage : ModulePageBase
{
    private readonly List<AppEntry> _apps = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads and row operations.</summary>
    private bool _isBusy;

    public AppsPage()
    {
        PageTitle = "Apps";
    }

    protected override async void OnPageShown()
    {
        await LoadAppsAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadAppsAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadAppsAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadAppsCoreAsync(showLoadingState);
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
    private async Task LoadAppsCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetAppsAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show("Failed to refresh apps.");
            }
            return;
        }

        var apps = ParseApps(result.Value);
        if (apps.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        _apps.Clear();
        _apps.AddRange(apps);
        BuildContent(apps);
        SetState(PageState.Content);
    }

    private List<AppEntry> ParseApps(JsonElement json)
    {
        var apps = new List<AppEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                apps.Add(new AppEntry
                {
                    AppId = TryGetString(item, "appId") ?? TryGetNumberAsString(item, "appId"),
                    Name = TryGetString(item, "name") ?? "Unknown",
                    Version = TryGetString(item, "version") ?? "",
                    Status = TryGetString(item, "status") ?? "",
                });
            }
        }

        return apps;
    }

    private void BuildContent(List<AppEntry> apps)
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
            SelectionMode = ListViewSelectionMode.None,
            IsItemClickEnabled = false,
            Margin = new Thickness(8, 0, 8, 0),
        };

        foreach (var app in apps)
        {
            list.Items.Add(CreateAppItem(app));
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

        var refreshButton = new AppBarButton
        {
            Label = "Refresh",
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadAppsAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateAppItem(AppEntry app)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = app,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Status pill: Running = success green, everything else neutral.
        var badge = CreateStatusBadge(app);
        Grid.SetColumn(badge, 0);
        grid.Children.Add(badge);

        // Info column: app name (primary), version (secondary, when present).
        var info = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(12, 0, 0, 0),
        };
        info.Children.Add(new TextBlock
        {
            Text = app.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        if (!string.IsNullOrWhiteSpace(app.Version))
        {
            info.Children.Add(new TextBlock
            {
                Text = app.Version,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            });
        }
        Grid.SetColumn(info, 1);
        grid.Children.Add(info);

        // Row actions: start/stop toggle (label follows status) + uninstall
        // (destructive confirmation).
        var actions = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(16, 0, 0, 0),
        };

        var toggleButton = new Button
        {
            MinWidth = 92,
            VerticalAlignment = VerticalAlignment.Center,
        };
        toggleButton.Content = BuildToggleContent(app.IsRunning);
        ToolTipService.SetToolTip(toggleButton, app.IsRunning ? "Stop app" : "Start app");
        toggleButton.Click += async (s, e) => await ToggleAppAsync(app);
        actions.Children.Add(toggleButton);

        var uninstallButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE74D", FontSize = 14 },
            Padding = new Thickness(8, 4, 8, 4),
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(uninstallButton, "Uninstall app");
        uninstallButton.Click += async (s, e) => await UninstallAppAsync(app);
        actions.Children.Add(uninstallButton);

        Grid.SetColumn(actions, 2);
        grid.Children.Add(actions);

        return grid;
    }

    /// <summary>Start/Stop button content: icon + label follow the status.</summary>
    private static StackPanel BuildToggleContent(bool isRunning)
    {
        var content = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
        };
        content.Children.Add(new FontIcon
        {
            Glyph = isRunning ? "\uE71A" : "\uE768", // Stop square / Play triangle.
            FontSize = 14,
        });
        content.Children.Add(new TextBlock
        {
            Text = isRunning ? "Stop" : "Start",
            FontSize = 14,
            VerticalAlignment = VerticalAlignment.Center,
        });
        return content;
    }

    /// <summary>Status pill badge with a translucent tint readable over Mica.</summary>
    private Border CreateStatusBadge(AppEntry app)
    {
        var accentBrush = app.IsRunning
            ? TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green)
            : TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray);
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        var badgeText = new TextBlock
        {
            Text = string.IsNullOrWhiteSpace(app.Status) ? "Unknown" : app.Status.Trim(),
            FontSize = 12,
            Foreground = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var dot = new Microsoft.UI.Xaml.Shapes.Ellipse
        {
            Width = 8,
            Height = 8,
            Fill = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var badgeContent = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
        };
        badgeContent.Children.Add(dot);
        badgeContent.Children.Add(badgeText);

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

    private async Task ToggleAppAsync(AppEntry app)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            // Running apps get stopped, everything else gets started.
            var success = app.IsRunning
                ? await WindowsBridge.StopAppAsync(app.AppId ?? string.Empty)
                : await WindowsBridge.StartAppAsync(app.AppId ?? string.Empty);
            if (success)
            {
                // Silent refresh keeps the list visible (no success toast).
                await LoadAppsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to {(app.IsRunning ? "stop" : "start")} \"{app.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Destructive row action behind a red primary-button dialog.</summary>
    private async Task UninstallAppAsync(AppEntry app)
    {
        if (_isBusy) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            // Upstream uninstall removes the app together with its data.
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                "Uninstall App",
                $"Uninstall app \"{app.Name}\"?\nThis will delete the app and its data. This action cannot be undone.",
                "Uninstall",
                "Cancel",
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.UninstallAppAsync(app.AppId ?? string.Empty);
            if (success)
            {
                await LoadAppsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to uninstall \"{app.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
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

    private static string TryGetNumberAsString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number)
        {
            return prop.GetRawText();
        }
        return string.Empty;
    }

    private sealed class AppEntry
    {
        public string? AppId { get; set; }
        public string Name { get; set; } = "";
        public string Version { get; set; } = "";
        public string Status { get; set; } = "";

        public bool IsRunning =>
            string.Equals(Status.Trim(), "running", StringComparison.OrdinalIgnoreCase);
    }
}
