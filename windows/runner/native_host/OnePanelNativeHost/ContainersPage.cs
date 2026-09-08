using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Containers module page: list containers with per-row start/stop,
/// restart and delete. All data flows through WindowsBridge (Dart business
/// core over the method channel); no direct HTTP from the native layer.
///
/// Upstream semantic reference: 1Panel web frontend (views/container/container)
/// colors each row by the docker state (running = success, exited = critical),
/// shows the human-readable status text, surfaces CPU/memory usage when the
/// backend reports it, toggles Start/Stop depending on the current state and
/// confirms destructive operations.
/// </summary>
public sealed class ContainersPage : ModulePageBase
{
    private readonly List<ContainerEntry> _containers = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads and row operations.</summary>
    private bool _isBusy;

    public ContainersPage()
    {
        PageTitle = L10n.T("serverModuleContainers", "Containers");
    }

    protected override async void OnPageShown()
    {
        await LoadContainersAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadContainersAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadContainersAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadContainersCoreAsync(showLoadingState);
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
    private async Task LoadContainersCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetContainersAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostContainersRefreshFailed", "Failed to refresh containers."));
            }
            return;
        }

        var containers = ParseContainers(result.Value);
        if (containers.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        _containers.Clear();
        _containers.AddRange(containers);
        BuildContent(containers);
        SetState(PageState.Content);
    }

    private List<ContainerEntry> ParseContainers(JsonElement json)
    {
        var containers = new List<ContainerEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                containers.Add(new ContainerEntry
                {
                    Id = TryGetString(item, "id") ?? TryGetNumberAsString(item, "id"),
                    Name = TryGetString(item, "name") ?? L10n.T("systemSettingsUnknown", "Unknown"),
                    Image = TryGetString(item, "image") ?? "",
                    Status = TryGetString(item, "status") ?? "",
                    State = TryGetString(item, "state") ?? "",
                    CpuUsage = TryGetUsageDouble(item, "cpuUsage"),
                    MemoryUsage = TryGetUsageDouble(item, "memoryUsage"),
                });
            }
        }

        return containers;
    }

    private void BuildContent(List<ContainerEntry> containers)
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

        foreach (var container in containers)
        {
            list.Items.Add(CreateContainerItem(container));
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
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadContainersAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateContainerItem(ContainerEntry container)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = container,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // State pill: docker state drives the color (running green / exited
        // red / others caution), status text is the human-readable label.
        var badge = CreateStateBadge(container);
        Grid.SetColumn(badge, 0);
        grid.Children.Add(badge);

        // Info column: name (primary), image (secondary), optional usage bars.
        var info = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(12, 0, 0, 0),
        };
        info.Children.Add(new TextBlock
        {
            Text = container.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        if (!string.IsNullOrWhiteSpace(container.Image))
        {
            info.Children.Add(new TextBlock
            {
                Text = container.Image,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            });
        }

        // Dashboard-style utilization bars; hidden entirely when no value.
        if (container.CpuUsage >= 0)
        {
            info.Children.Add(BuildUsageBar(L10n.T("serverCpuLabel", "CPU"), container.CpuUsage));
        }
        if (container.MemoryUsage >= 0)
        {
            info.Children.Add(BuildUsageBar(L10n.T("serverMemoryLabel", "Memory"), container.MemoryUsage));
        }

        Grid.SetColumn(info, 1);
        grid.Children.Add(info);

        // Row actions: start/stop toggle (label/icon follow the state),
        // restart, delete (destructive confirmation).
        var actions = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(16, 0, 0, 0),
        };

        var isRunning = container.IsRunning;
        var toggleButton = new Button
        {
            MinWidth = 92,
            VerticalAlignment = VerticalAlignment.Center,
        };
        toggleButton.Content = BuildToggleContent(isRunning);
        ToolTipService.SetToolTip(toggleButton, isRunning ? L10n.T("hostContainersStopContainer", "Stop container") : L10n.T("hostContainersStartContainer", "Start container"));
        toggleButton.Click += async (s, e) => await ToggleContainerAsync(container);
        actions.Children.Add(toggleButton);

        var restartButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE777", FontSize = 14 },
            Padding = new Thickness(8, 4, 8, 4),
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(restartButton, L10n.T("hostContainersRestartContainer", "Restart container"));
        restartButton.Click += async (s, e) => await RestartContainerAsync(container);
        actions.Children.Add(restartButton);

        var deleteButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE74D", FontSize = 14 },
            Padding = new Thickness(8, 4, 8, 4),
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(deleteButton, L10n.T("hostContainersDeleteContainer", "Delete container"));
        deleteButton.Click += async (s, e) => await DeleteContainerAsync(container);
        actions.Children.Add(deleteButton);

        Grid.SetColumn(actions, 2);
        grid.Children.Add(actions);

        return grid;
    }

    /// <summary>Start/Stop button content: icon + label follow the state.</summary>
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
            Text = isRunning ? L10n.T("containerActionStop", "Stop") : L10n.T("containerActionStart", "Start"),
            FontSize = 14,
            VerticalAlignment = VerticalAlignment.Center,
        });
        return content;
    }

    /// <summary>State pill badge with a translucent tint readable over Mica.</summary>
    private Border CreateStateBadge(ContainerEntry container)
    {
        // Color comes from the docker state first (canonical), status text
        // from the human-readable status (e.g. "Up 2 hours").
        Brush accentBrush;
        if (container.IsRunning)
        {
            accentBrush = TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green);
        }
        else if (container.IsExited)
        {
            accentBrush = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red);
        }
        else
        {
            accentBrush = TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange);
        }
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        var badgeText = new TextBlock
        {
            Text = container.DisplayStatus,
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

    private async Task ToggleContainerAsync(ContainerEntry container)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            // Bridge semantics: state "running" -> stop, anything else -> start.
            var success = await WindowsBridge.ToggleContainerStateAsync(
                container.Id ?? string.Empty, container.StateKey);
            if (success)
            {
                // Silent refresh keeps the list visible (no success toast).
                await LoadContainersCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to {(container.IsRunning ? "stop" : "start")} \"{container.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    private async Task RestartContainerAsync(ContainerEntry container)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var success = await WindowsBridge.RestartContainerAsync(container.Id ?? string.Empty);
            if (success)
            {
                await LoadContainersCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to restart \"{container.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Destructive row action behind a red primary-button dialog.</summary>
    private async Task DeleteContainerAsync(ContainerEntry container)
    {
        if (_isBusy) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                L10n.T("hostContainersDeleteConfirm", "Delete Container"),
                $"Delete container \"{container.Name}\"?\nThis action cannot be undone.",
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.DeleteContainerAsync(container.Id ?? string.Empty);
            if (success)
            {
                await LoadContainersCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{container.Name}\".");
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

    /// <summary>
    /// Usage values are doubles per the bridge contract; numeric strings
    /// (optionally suffixed with "%") are tolerated. Returns -1 when absent
    /// or unparsable so callers can hide the bar entirely.
    /// </summary>
    private static double TryGetUsageDouble(JsonElement element, string property)
    {
        if (element.ValueKind != JsonValueKind.Object ||
            !element.TryGetProperty(property, out var prop))
        {
            return -1;
        }

        if (prop.ValueKind == JsonValueKind.Number)
        {
            return prop.GetDouble();
        }

        if (prop.ValueKind == JsonValueKind.String)
        {
            var raw = prop.GetString()?.Trim().TrimEnd('%').Trim();
            if (!string.IsNullOrEmpty(raw) &&
                double.TryParse(raw, NumberStyles.Float, CultureInfo.InvariantCulture, out var value))
            {
                return value;
            }
        }

        return -1;
    }

    private sealed class ContainerEntry
    {
        public string? Id { get; set; }
        public string Name { get; set; } = "";
        public string Image { get; set; } = "";
        public string Status { get; set; } = "";
        public string State { get; set; } = "";
        public double CpuUsage { get; set; } = -1;
        public double MemoryUsage { get; set; } = -1;

        /// <summary>Canonical state key: docker state first, status fallback.</summary>
        public string StateKey =>
            !string.IsNullOrWhiteSpace(State) ? State.Trim() : Status.Trim();

        /// <summary>Badge label: human-readable status first, state fallback.</summary>
        public string DisplayStatus =>
            !string.IsNullOrWhiteSpace(Status) ? Status.Trim()
                : !string.IsNullOrWhiteSpace(State) ? State.Trim()
                : L10n.T("systemSettingsUnknown", "Unknown");

        public bool IsRunning =>
            string.Equals(StateKey, "running", StringComparison.OrdinalIgnoreCase);

        public bool IsExited =>
            string.Equals(StateKey, "exited", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(StateKey, "stopped", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(StateKey, "dead", StringComparison.OrdinalIgnoreCase);
    }
}
