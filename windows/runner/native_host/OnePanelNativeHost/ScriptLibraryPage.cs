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
/// Native Script Library module page (read-only list + batch delete). Mirrors
/// the upstream 1Panel web frontend script library semantics
/// (views/cronjob/library/index.vue in this repo's read-only snapshot):
/// - list shows name (with a System badge for isSystem rows), label, the
///   truncated description, the group tags and the creation time;
/// - system scripts are protected: the row delete menu item is disabled for
///   isSystem rows, matching the upstream per-row disabled state, and the
///   batch delete filters system rows out of the selection;
/// - deletion goes through a destructive confirmation: single mode names the
///   script, batch mode names the count N; success silently refreshes and
///   failure surfaces the error toast;
/// - "Run"-style operations are intentionally out of scope for this batch:
///   script execution goes through the terminal websocket channel upstream
///   (library run dialog), not the list bridge contract.
/// All data flows through WindowsBridge (method channel to the Dart core);
/// no direct HTTP from the native layer.
/// </summary>
public sealed class ScriptLibraryPage : ModulePageBase
{
    private readonly List<ScriptEntry> _scripts = new();
    private readonly ErrorToast _errorToast = new();

    // Rebuilt on every successful load; kept as fields so the batch delete
    // button can track the list selection across rebuilds.
    private ListView? _list;
    private AppBarButton? _deleteSelectedButton;

    /// <summary>Re-entrancy guard shared by loads and the delete flows.</summary>
    private bool _isBusy;

    public ScriptLibraryPage()
    {
        PageTitle = "Script Library";
    }

    protected override async void OnPageShown()
    {
        await LoadScriptsAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadScriptsAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadScriptsAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadScriptsCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body; also used as the silent refresh after successful
    /// deletions. With <paramref name="showLoadingState"/> the page swaps to
    /// the loading spinner; otherwise the current content stays visible and
    /// failures surface via the error toast.
    /// </summary>
    private async Task LoadScriptsCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetScriptsAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show("Failed to refresh scripts.");
            }
            return;
        }

        var scripts = ParseScripts(result.Value);
        _scripts.Clear();
        if (scripts.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        _scripts.AddRange(scripts);
        BuildContent(_scripts);
        SetState(PageState.Content);
    }

    private static List<ScriptEntry> ParseScripts(JsonElement json)
    {
        var scripts = new List<ScriptEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                scripts.Add(new ScriptEntry
                {
                    Id = TryGetInt64(item, "id"),
                    Name = TryGetString(item, "name") ?? "Unknown",
                    Label = TryGetString(item, "label") ?? "",
                    IsSystem = TryGetBool(item, "isSystem"),
                    Description = TryGetString(item, "description") ?? "",
                    GroupBelong = TryGetGroupBelong(item, "groupBelong"),
                    CreatedAt = TryGetString(item, "createdAt") ?? "",
                });
            }
        }

        return scripts;
    }

    private void BuildContent(List<ScriptEntry> scripts)
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

        // Multi-select list: the checkbox column drives the batch delete flow
        // (upstream ComplexTable selection column).
        var list = new ListView
        {
            SelectionMode = ListViewSelectionMode.Multiple,
            IsItemClickEnabled = false,
            Margin = new Thickness(8, 0, 8, 0),
        };
        list.SelectionChanged += OnListSelectionChanged;

        foreach (var script in scripts)
        {
            list.Items.Add(CreateScriptItem(script));
        }

        _list = list;
        if (_deleteSelectedButton != null)
        {
            // Fresh list, nothing selected yet; keep the batch action guarded.
            _deleteSelectedButton.IsEnabled = false;
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
        refreshButton.Click += (s, e) => _ = LoadScriptsAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        var deleteButton = new AppBarButton
        {
            Label = "Delete selected",
            Icon = new FontIcon { Glyph = "\uE74D" }, // Delete.
            IsEnabled = false, // Enabled once at least one deletable row is selected.
        };
        deleteButton.Click += (s, e) => _ = DeleteSelectedAsync();
        bar.SecondaryCommands.Add(deleteButton);
        _deleteSelectedButton = deleteButton;

        return bar;
    }

    private FrameworkElement CreateScriptItem(ScriptEntry script)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = script,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Info column: name + System badge, then label, description, group
        // tags and creation time.
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
            Text = script.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        if (script.IsSystem)
        {
            nameRow.Children.Add(CreateSystemBadge());
        }
        info.Children.Add(nameRow);

        // Secondary label line; omitted when the payload carries no value.
        if (!string.IsNullOrWhiteSpace(script.Label))
        {
            info.Children.Add(CreateSecondaryText(script.Label));
        }

        // Truncated description (upstream show-overflow-tooltip column).
        if (!string.IsNullOrWhiteSpace(script.Description))
        {
            info.Children.Add(new TextBlock
            {
                Text = script.Description,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
                MaxLines = 1,
            });
        }

        // Group tags; omitted when the payload carries no group (upstream
        // renders an empty cell in that case).
        if (!string.IsNullOrWhiteSpace(script.GroupBelong))
        {
            info.Children.Add(CreateSecondaryText("Group: " + script.GroupBelong));
        }

        // Creation time; omitted when absent or unparsable.
        var createdAt = FormatDateString(script.CreatedAt);
        if (!string.IsNullOrWhiteSpace(createdAt))
        {
            info.Children.Add(CreateSecondaryText("Created: " + createdAt));
        }

        Grid.SetColumn(info, 0);
        grid.Children.Add(info);

        // Per-row "more" actions (upstream row operations dropdown). System
        // scripts keep the menu but with delete disabled, matching the
        // upstream per-row protection.
        var moreButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE712", FontSize = 14 },
            Background = null,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(6, 2, 6, 2),
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(moreButton, "Script actions");
        moreButton.Flyout = BuildRowFlyout(script);
        Grid.SetColumn(moreButton, 1);
        grid.Children.Add(moreButton);

        return grid;
    }

    private static TextBlock CreateSecondaryText(string text)
    {
        return new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        };
    }

    /// <summary>Neutral pill badge marking an isSystem row (upstream renders a
    /// small System button in the group cell).</summary>
    private static FrameworkElement CreateSystemBadge()
    {
        var accentBrush = TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray);
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            // Translucent tint keeps the pill readable over Mica/LayerFill.
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            VerticalAlignment = VerticalAlignment.Center,
            Child = new TextBlock
            {
                Text = "System",
                FontSize = 12,
                Foreground = accentBrush,
                VerticalAlignment = VerticalAlignment.Center,
            },
        };
    }

    private MenuFlyout BuildRowFlyout(ScriptEntry script)
    {
        var flyout = new MenuFlyout();

        // Single-row delete; disabled for system scripts (upstream protection
        // semantics: the row delete button is disabled when isSystem).
        var deleteItem = new MenuFlyoutItem
        {
            Text = "Delete",
            Icon = new FontIcon { Glyph = "\uE74D" }, // Delete.
            IsEnabled = !script.IsSystem,
        };
        deleteItem.Click += (s, e) => _ = DeleteScriptAsync(script);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    /// <summary>Selection tracker: enables the batch delete action only when
    /// at least one non-system row is selected (system rows never enter the
    /// deletable set).</summary>
    private void OnListSelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_deleteSelectedButton == null) return;
        _deleteSelectedButton.IsEnabled = GetSelectedDeletableIds().Count > 0;
    }

    /// <summary>Ids of the selected rows, excluding protected system scripts.</summary>
    private List<long> GetSelectedDeletableIds()
    {
        var ids = new List<long>();
        if (_list == null) return ids;

        foreach (var item in _list.SelectedItems)
        {
            if (item is FrameworkElement element && element.Tag is ScriptEntry entry && !entry.IsSystem)
            {
                ids.Add(entry.Id);
            }
        }

        return ids;
    }

    /// <summary>Destructive single-row delete with a confirmation naming the script.</summary>
    private async Task DeleteScriptAsync(ScriptEntry script)
    {
        if (_isBusy) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                "Delete Script",
                $"Are you sure you want to delete script \"{script.Name}\"?\nThis action cannot be undone.",
                "Delete",
                "Cancel",
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.DeleteScriptsAsync(new List<long> { script.Id });
            if (success)
            {
                await LoadScriptsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{script.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Destructive batch delete for the current selection with a confirmation
    /// naming the count. System scripts are filtered out of the selected ids
    /// (upstream protection semantics); the button only enables when at least
    /// one deletable row is selected, so an empty batch cannot be submitted.
    /// Success silently refreshes; failure shows the toast.
    /// </summary>
    private async Task DeleteSelectedAsync()
    {
        if (_isBusy) return;

        var ids = GetSelectedDeletableIds();
        if (ids.Count == 0) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                "Delete Scripts",
                $"Are you sure you want to delete {ids.Count} selected script(s)?\nThis action cannot be undone.",
                "Delete",
                "Cancel",
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.DeleteScriptsAsync(ids);
            if (success)
            {
                await LoadScriptsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete {ids.Count} selected script(s).");
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

    /// <summary>
    /// Formats an ISO-style date string for display; falls back to the raw
    /// value when unparsable (handles Go-style 9-digit fractional seconds).
    /// </summary>
    private static string FormatDateString(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return "";

        if (DateTimeOffset.TryParse(raw, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed))
        {
            return parsed.ToLocalTime().ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture);
        }

        // Normalize ".123456789Z" fractional precision before retrying.
        var dotIndex = raw.IndexOf('.');
        if (dotIndex > 0)
        {
            var end = dotIndex + 1;
            while (end < raw.Length && char.IsDigit(raw[end])) end++;
            var normalized = raw[..dotIndex] + raw[end..];
            if (DateTimeOffset.TryParse(normalized, CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed))
            {
                return parsed.ToLocalTime().ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture);
            }
        }

        return raw;
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

    private static bool TryGetBool(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            (prop.ValueKind == JsonValueKind.True || prop.ValueKind == JsonValueKind.False))
        {
            return prop.GetBoolean();
        }
        return false;
    }

    private static long TryGetInt64(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number)
        {
            return prop.TryGetInt64(out var value) ? value : (long)prop.GetDouble();
        }
        return 0;
    }

    /// <summary>
    /// Tolerant group parser: the Dart model sends an array of group names,
    /// while Swagger declares a plain string (known contract deviation) —
    /// accept both and join array items with commas for display.
    /// </summary>
    private static string TryGetGroupBelong(JsonElement element, string property)
    {
        if (element.ValueKind != JsonValueKind.Object ||
            !element.TryGetProperty(property, out var prop))
        {
            return "";
        }

        switch (prop.ValueKind)
        {
            case JsonValueKind.String:
                return prop.GetString() ?? "";
            case JsonValueKind.Array:
                var names = new List<string>();
                foreach (var item in prop.EnumerateArray())
                {
                    if (item.ValueKind == JsonValueKind.String && !string.IsNullOrWhiteSpace(item.GetString()))
                    {
                        names.Add(item.GetString()!);
                    }
                }
                return string.Join(", ", names);
            default:
                return "";
        }
    }

    /// <summary>Row model straight from the bridge payload.</summary>
    private sealed class ScriptEntry
    {
        public long Id { get; set; }
        public string Name { get; set; } = "";
        public string Label { get; set; } = "";
        public bool IsSystem { get; set; }
        public string Description { get; set; } = "";
        public string GroupBelong { get; set; } = "";
        public string CreatedAt { get; set; } = "";
    }
}
