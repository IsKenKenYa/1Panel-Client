using System;
using System.Collections.Generic;
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
/// Native OpenResty management page (website module). Mirrors the upstream
/// 1Panel web frontend semantics (views/website):
/// - the OpenResty load status, build modules and HTTPS defaults are dynamic
///   key/value maps on the server side, so the page renders them generically
///   as key/value grids without strong-typed assumptions (status and HTTPS as
///   InfoBag label/value pairs, build modules as colored key-name tag pills
///   for boolean entries and plain pairs for everything else);
/// - views/website/website/nginx/source: the raw nginx.conf configuration
///   source inside an Expander with an Edit toggle and a Save action that
///   confirms before overwriting the remote file (upstream loads the content
///   and saves it back, then reloads the editor).
/// All data flows through WindowsBridge (method channel to the Dart core);
/// no direct HTTP from the native layer.
/// </summary>
public sealed class OpenRestyPage : ModulePageBase
{
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads and the config save.</summary>
    private bool _isBusy;

    /// <summary>Server-side nginx.conf source text; empty when unavailable.</summary>
    private string _configContent = "";

    // Config editor controls, recreated together with the page content.
    private TextBox? _configBox;
    private Button? _editConfigButton;
    private Button? _saveConfigButton;

    public OpenRestyPage()
    {
        PageTitle = "OpenResty";
    }

    protected override async void OnPageShown()
    {
        await LoadOpenRestyAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadOpenRestyAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadOpenRestyAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadOpenRestyCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body; also used as the silent refresh after a
    /// successful config save. With <paramref name="showLoadingState"/> the
    /// page swaps to the loading spinner; otherwise the current content stays
    /// visible and failures surface via the error toast.
    /// </summary>
    private async Task LoadOpenRestyCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var snapshot = await WindowsBridge.GetOpenrestySnapshotAsync();

        if (snapshot == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostOpenrestyRefreshFailed", "Failed to refresh the OpenResty snapshot."));
            }
            return;
        }

        // Bridge semantics: an empty object means no active server is
        // configured, which maps to the empty state (same as DashboardPage).
        if (!HasAnyProperty(snapshot.Value))
        {
            SetState(PageState.Empty);
            return;
        }

        var status = GetMapProperty(snapshot.Value, "status");
        var modules = GetMapProperty(snapshot.Value, "modules");
        var https = GetMapProperty(snapshot.Value, "https");
        _configContent = TryGetString(snapshot.Value, "configContent") ?? "";

        BuildContent(status, modules, https);
        SetState(PageState.Content);
    }

    private void BuildContent(JsonElement status, JsonElement modules, JsonElement https)
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
        content.Children.Add(BuildStatusCard(status));
        content.Children.Add(BuildHttpsCard(https));
        content.Children.Add(BuildModulesCard(modules));
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
        refreshButton.Click += (s, e) => _ = LoadOpenRestyAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    /// <summary>
    /// Load status card: the dynamic status map rendered as an InfoBag-style
    /// label/value grid. The whole card collapses when the map is empty.
    /// </summary>
    private FrameworkElement BuildStatusCard(JsonElement statusMap)
    {
        var card = CreateCard(L10n.T("openrestyTabStatus", "Status"), out var panel);

        if (!HasAnyProperty(statusMap))
        {
            card.Visibility = Visibility.Collapsed;
            return card;
        }

        panel.Children.Add(BuildInfoBag(statusMap));
        return card;
    }

    /// <summary>
    /// HTTPS defaults card: the dynamic https map rendered the same way as
    /// the status card. The whole card collapses when the map is empty.
    /// </summary>
    private FrameworkElement BuildHttpsCard(JsonElement httpsMap)
    {
        var card = CreateCard(L10n.T("openrestyTabHttps", "HTTPS"), out var panel);

        if (!HasAnyProperty(httpsMap))
        {
            card.Visibility = Visibility.Collapsed;
            return card;
        }

        panel.Children.Add(BuildInfoBag(httpsMap));
        return card;
    }

    /// <summary>
    /// Build modules card: boolean entries render as colored key-name tag
    /// pills (green = enabled, red = disabled); any non-boolean entry falls
    /// back to a plain label/value pair. The whole card collapses when the
    /// map is empty.
    /// </summary>
    private FrameworkElement BuildModulesCard(JsonElement modulesMap)
    {
        var card = CreateCard(L10n.T("openrestyTabModules", "Modules"), out var panel);

        if (!HasAnyProperty(modulesMap))
        {
            card.Visibility = Visibility.Collapsed;
            return card;
        }

        ItemsControl? pillList = null;
        Grid? pairBag = null;

        foreach (var property in EnumerateMapProperties(modulesMap))
        {
            if (property.Value.ValueKind == JsonValueKind.True ||
                property.Value.ValueKind == JsonValueKind.False)
            {
                pillList ??= new ItemsControl { ItemsPanel = CreateWrapPanelTemplate() };
                pillList.Items.Add(CreateModuleTag(property.Name, property.Value.ValueKind == JsonValueKind.True));
            }
            else
            {
                pairBag ??= new Grid { ColumnSpacing = 12, RowSpacing = 6 };
                pairBag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                pairBag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                AddFullRowPair(pairBag, property.Name, FormatScalar(property.Value));
            }
        }

        if (pillList != null) panel.Children.Add(pillList);
        if (pairBag != null) panel.Children.Add(pairBag);
        return card;
    }

    /// <summary>
    /// Raw nginx.conf source inside an expandable section: a read-only
    /// monospace viewer prefilled from the bridge, an Edit toggle and a
    /// confirmed Save. Recreated on every content rebuild, so each load
    /// resets back to the read-only mode. An empty source shows a
    /// placeholder and keeps Edit/Save disabled.
    /// </summary>
    private FrameworkElement BuildConfigExpander()
    {
        bool configEmpty = string.IsNullOrWhiteSpace(_configContent);

        _configBox = new TextBox
        {
            IsReadOnly = true,
            AcceptsReturn = true,
            Height = 320,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 12,
            TextWrapping = TextWrapping.NoWrap,
            Text = configEmpty ? "" : _configContent,
            PlaceholderText = L10n.T("hostOpenrestyConfigEmptyHint", "# The OpenResty configuration source is empty or unavailable (/etc/nginx/nginx.conf)"),
        };
        ScrollViewer.SetHorizontalScrollBarVisibility(_configBox, ScrollBarVisibility.Auto);

        _editConfigButton = new Button
        {
            Content = L10n.T("commonEdit", "Edit"),
            IsEnabled = !configEmpty,
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
                Text = L10n.T("hostOpenrestyConfigSource", "Configuration source (/etc/nginx/nginx.conf)"),
                FontSize = 14,
            },
            Content = configPanel,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Margin = new Thickness(0, 4, 0, 0),
        };
    }

    private void OnEditConfigClicked(object sender, RoutedEventArgs e)
    {
        if (_configBox == null || string.IsNullOrWhiteSpace(_configContent)) return;

        _configBox.IsReadOnly = false;
        _editConfigButton!.IsEnabled = false;
        _saveConfigButton!.IsEnabled = true;
        _configBox.Focus(FocusState.Programmatic);
    }

    /// <summary>
    /// Saves the edited nginx.conf source after a confirmation naming the
    /// target file. Success silently reloads the snapshot (the editor is
    /// rebuilt in read-only mode with the persisted content); failure shows
    /// the toast and keeps the editing state so the user can retry.
    /// </summary>
    private async Task SaveConfigAsync()
    {
        if (_isBusy || _configBox == null) return;

        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                L10n.T("hostOpenrestySaveConfig", "Save OpenResty configuration"),
                L10n.T("hostOpenrestySaveConfigConfirm", "This will overwrite /etc/nginx/nginx.conf with the edited content.\nAn invalid configuration may make hosted websites unavailable. Continue?"),
                L10n.T("commonSave", "Save"),
                L10n.T("commonCancel", "Cancel"));

            if (!confirmed) return;

            var success = await WindowsBridge.UpdateOpenrestyConfigAsync(_configBox.Text);
            if (success)
            {
                // Silent refresh rebuilds the editor in read-only mode.
                await LoadOpenRestyCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show(L10n.T("hostOpenrestySaveConfigFailed", "Failed to save the OpenResty configuration."));
                // Keep the editing state: the buttons are untouched.
            }
        }
        finally
        {
            _isBusy = false;
        }
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
    /// InfoBag grid over a dynamic map: two label+value pairs per row with
    /// relative columns only. Empty values render "--".
    /// </summary>
    private static Grid BuildInfoBag(JsonElement map)
    {
        var bag = new Grid();
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(24) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var entries = new List<KeyValuePair<string, string>>();
        foreach (var property in EnumerateMapProperties(map))
        {
            entries.Add(new KeyValuePair<string, string>(property.Name, FormatScalar(property.Value)));
        }

        for (int i = 0; i < entries.Count; i += 2)
        {
            var rowIndex = bag.RowDefinitions.Count;
            bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            AddInfoPair(bag, rowIndex, 0, entries[i].Key, entries[i].Value);
            if (i + 1 < entries.Count)
            {
                AddInfoPair(bag, rowIndex, 1, entries[i + 1].Key, entries[i + 1].Value);
            }
        }

        return bag;
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

    /// <summary>Single label/value row appended to a two-column grid.</summary>
    private static void AddFullRowPair(Grid grid, string label, string value)
    {
        var rowIndex = grid.RowDefinitions.Count;
        grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 0, 12, 0),
        };
        Grid.SetRow(labelBlock, rowIndex);
        Grid.SetColumn(labelBlock, 0);
        grid.Children.Add(labelBlock);

        var valueBlock = new TextBlock
        {
            Text = string.IsNullOrWhiteSpace(value) ? "--" : value,
            FontSize = 13,
            TextWrapping = TextWrapping.Wrap,
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Top,
        };
        Grid.SetRow(valueBlock, rowIndex);
        Grid.SetColumn(valueBlock, 1);
        grid.Children.Add(valueBlock);
    }

    /// <summary>
    /// Colored tag pill for one build module key: green accent when the
    /// boolean value is enabled, red when disabled, with a translucent tint
    /// that stays readable over Mica/LayerFill.
    /// </summary>
    private static FrameworkElement CreateModuleTag(string name, bool enabled)
    {
        var accentBrush = enabled
            ? TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.SeaGreen)
            : TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.IndianRed);
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        var tagContent = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        tagContent.Children.Add(new Ellipse
        {
            Width = 8,
            Height = 8,
            Fill = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });
        tagContent.Children.Add(new TextBlock
        {
            Text = name,
            FontSize = 12,
            Foreground = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });

        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            Margin = new Thickness(0, 0, 8, 8),
            VerticalAlignment = VerticalAlignment.Top,
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            Child = tagContent,
        };
    }

    /// <summary>
    /// Wrapping items panel for the module tags. WrapPanel is not part of the
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

    /// <summary>Scalar rendering for dynamic map values: strings pass through
    /// ("--" when blank), numbers use their raw text, booleans render as
    /// Yes/No, and nested arrays/objects fall back to their raw JSON text.</summary>
    private static string FormatScalar(JsonElement value)
    {
        switch (value.ValueKind)
        {
            case JsonValueKind.String:
                var text = value.GetString();
                return string.IsNullOrWhiteSpace(text) ? "--" : text.Trim();
            case JsonValueKind.Number:
                return value.GetRawText();
            case JsonValueKind.True:
                return L10n.T("commonYes", "Yes");
            case JsonValueKind.False:
                return L10n.T("commonNo", "No");
            case JsonValueKind.Array:
            case JsonValueKind.Object:
                return value.GetRawText();
            default:
                return "--";
        }
    }

    /// <summary>Returns the named object property, or a default (Undefined)
    /// element when absent or malformed. Callers guard on HasAnyProperty /
    /// EnumerateMapProperties, so an Undefined element simply collapses the
    /// card instead of being dereferenced.</summary>
    private static JsonElement GetMapProperty(JsonElement root, string property)
    {
        if (root.ValueKind == JsonValueKind.Object &&
            root.TryGetProperty(property, out var value) &&
            value.ValueKind == JsonValueKind.Object)
        {
            return value;
        }
        return default;
    }

    /// <summary>Enumerates the map as dynamic key/value pairs; safe on non-objects.</summary>
    private static IEnumerable<JsonProperty> EnumerateMapProperties(JsonElement map)
    {
        if (map.ValueKind != JsonValueKind.Object) yield break;

        using var enumerator = map.EnumerateObject();
        while (enumerator.MoveNext())
        {
            yield return enumerator.Current;
        }
    }

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
}
