using System;
using System.Collections.Generic;
using System.Text.Json;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace OnePanelNativeHost;

/// <summary>
/// Native Settings page. Renders the key/value settings returned by the Dart
/// core (via WindowsBridge) plus a dedicated "Appearance" group at the top:
/// system backdrop (applied locally), render mode and language (persisted
/// through the Dart core). All data flows through WindowsBridge; the native
/// layer never talks HTTP directly.
/// </summary>
public sealed class SettingsPage : ModulePageBase
{
    private readonly ErrorToast _errorToast = new();

    // Suppresses SelectionChanged handling while reverting a ComboBox after a
    // failed write, so the revert itself does not trigger another update.
    private bool _suppressComboWrite;

    public SettingsPage()
    {
        PageTitle = L10n.T("settingsPageTitle", "Settings");
    }

    protected override async void OnPageShown()
    {
        SetState(PageState.Loading);
        await LoadSettingsAsync();
    }

    protected override async void OnRefreshClicked()
    {
        SetState(PageState.Loading);
        await LoadSettingsAsync();
    }

    private async System.Threading.Tasks.Task LoadSettingsAsync()
    {
        var result = await WindowsBridge.GetSettingsAsync();

        if (result == null)
        {
            SetState(PageState.Error);
            return;
        }

        var settings = ParseSettings(result.Value);
        if (settings.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        // Raw values for the dedicated Appearance ComboBoxes.
        var renderMode = TryGetStringValue(result.Value, "renderMode");
        var language = TryGetStringValue(result.Value, "language");

        BuildSettingsPanel(settings, renderMode, language);
        SetState(PageState.Content);
    }

    private List<SettingEntry> ParseSettings(JsonElement json)
    {
        var settings = new List<SettingEntry>();

        if (json.ValueKind == JsonValueKind.Object)
        {
            foreach (var prop in json.EnumerateObject())
            {
                // renderMode/language are presented by the dedicated
                // Appearance ComboBoxes; skip them to avoid rendering the
                // same keys twice.
                if (prop.Name is "renderMode" or "language")
                {
                    continue;
                }

                settings.Add(new SettingEntry
                {
                    RawKey = prop.Name,
                    Key = FormatLabel(prop.Name),
                    Value = FormatValue(prop.Value),
                    Category = Categorize(prop.Name),
                    IsBool = prop.Value.ValueKind is JsonValueKind.True or JsonValueKind.False,
                    BoolValue = prop.Value.ValueKind == JsonValueKind.True,
                });
            }
        }

        return settings;
    }

    private void BuildSettingsPanel(List<SettingEntry> settings, string? renderMode, string? language)
    {
        // Root grid overlays the failure toast on the scrollable content; the
        // toast must stay in the visual tree for Show() to actually render.
        var rootGrid = new Grid();

        var scrollViewer = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
        };

        var rootPanel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Margin = new Thickness(24, 16, 24, 16),
            Spacing = 4,
        };

        // Appearance group first: dedicated backdrop/render-mode/language
        // controls above the generic key/value list.
        BuildAppearanceGroup(rootPanel, renderMode, language);

        var currentCategory = "";
        foreach (var setting in settings)
        {
            if (setting.Category != currentCategory)
            {
                currentCategory = setting.Category;
                var categoryHeader = new TextBlock
                {
                    Text = currentCategory,
                    FontSize = 18,
                    FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                    Margin = new Thickness(0, 16, 0, 8),
                };
                rootPanel.Children.Add(categoryHeader);

                var separator = new StackPanel
                {
                    Height = 1,
                    Background = new Microsoft.UI.Xaml.Media.SolidColorBrush(
                        Microsoft.UI.Colors.LightGray),
                    Margin = new Thickness(0, 0, 0, 8),
                };
                rootPanel.Children.Add(separator);
            }

            var row = new Grid
            {
                Padding = new Thickness(0, 8, 0, 8),
            };

            row.ColumnDefinitions.Add(new ColumnDefinition
                { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition
                { Width = GridLength.Auto });

            var keyBlock = new TextBlock
            {
                Text = setting.Key,
                FontSize = 14,
                VerticalAlignment = VerticalAlignment.Center,
            };
            Grid.SetColumn(keyBlock, 0);
            row.Children.Add(keyBlock);

            if (setting.IsBool)
            {
                var toggle = new ToggleSwitch
                {
                    IsOn = setting.BoolValue,
                    Tag = setting.RawKey,
                    OnContent = "",
                    OffContent = "",
                };
                toggle.Toggled += OnSettingToggled;
                Grid.SetColumn(toggle, 1);
                row.Children.Add(toggle);
            }
            else
            {
                var valueBlock = new TextBlock
                {
                    Text = setting.Value,
                    FontSize = 14,
                    VerticalAlignment = VerticalAlignment.Center,
                    Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(
                        Microsoft.UI.Colors.Gray),
                };
                Grid.SetColumn(valueBlock, 1);
                row.Children.Add(valueBlock);
            }

            rootPanel.Children.Add(row);
        }

        scrollViewer.Content = rootPanel;
        rootGrid.Children.Add(scrollViewer);

        // Same overlay pattern as ServersPage: keep the toast in the visual
        // tree, bottom-aligned over the content.
        _errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        AttachToast(rootGrid, _errorToast);

        ModuleContentPresenter.Content = rootGrid;
    }

    /// <summary>
    /// Adds the "Appearance" group above the generic key/value list: system
    /// backdrop, render mode and language. The header/separator styling
    /// matches the generated category headers below.
    /// </summary>
    private void BuildAppearanceGroup(StackPanel rootPanel, string? renderMode, string? language)
    {
        rootPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("settingsAppearance", "Appearance"),
            FontSize = 18,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            Margin = new Thickness(0, 16, 0, 8),
        });

        rootPanel.Children.Add(new StackPanel
        {
            Height = 1,
            Background = new Microsoft.UI.Xaml.Media.SolidColorBrush(
                Microsoft.UI.Colors.LightGray),
            Margin = new Thickness(0, 0, 0, 8),
        });

        rootPanel.Children.Add(CreateComboRow(
            L10n.T("settingsSystemBackdrop", "System backdrop"),
            caption: null,
            combo: CreateBackdropCombo()));

        rootPanel.Children.Add(CreateComboRow(
            L10n.T("settingsUIRenderMode", "Render mode"),
            caption: L10n.T("settingsRestartRequired", "Restart required"),
            combo: CreateStringSettingCombo(
                new[] { L10n.T("settingsUIRenderModeNative", "Native (WinUI3)"), L10n.T("settingsUIRenderModeMD3", "Flutter MDUI3") },
                new[] { "native", "md3" },
                renderMode,
                key: "renderMode",
                title: "Render mode")));

        rootPanel.Children.Add(CreateComboRow(
            L10n.T("settingsLanguage", "Language"),
            caption: null,
            combo: CreateStringSettingCombo(
                new[] { L10n.T("languageSystem", "System"), "中文", "English" },
                new[] { "system", "zh", "en" },
                language,
                key: "language",
                title: "Language",
                onPersisted: async () =>
                {
                    // 即时生效：重拉译文整表 + 导航标签重设 + 全部缓存页按新语言重建。
                    await L10n.LoadAsync();
                    (App.MainWindow as MainWindow)?.ApplyLanguage();
                })));
    }

    /// <summary>
    /// Backdrop ComboBox. Item order matches the AppBackdropKind enum so the
    /// selected index maps directly onto the enum value. Selecting applies
    /// and persists the backdrop immediately (no failure path, no revert).
    /// </summary>
    private ComboBox CreateBackdropCombo()
    {
        var combo = new ComboBox
        {
            MinWidth = 160,
            HorizontalAlignment = HorizontalAlignment.Right,
        };
        combo.Items.Add("Mica");
        combo.Items.Add("Mica Alt");
        combo.Items.Add("Acrylic");
        combo.Items.Add(L10n.T("commonNone", "None"));

        combo.SelectedIndex = (int)WindowsBridge.LoadWindowBackdrop();

        combo.SelectionChanged += (sender, e) =>
        {
            if (sender is ComboBox box && box.SelectedIndex >= 0)
            {
                WindowsBridge.ApplyWindowBackdrop((AppBackdropKind)box.SelectedIndex);
            }
        };

        return combo;
    }

    /// <summary>
    /// ComboBox bound to a string preference (renderMode/language). Selecting
    /// an item writes through WindowsBridge.UpdateSettingAsync; on failure the
    /// toast shows and the selection reverts to the last persisted value.
    /// onPersisted runs after a successful write (language switch reloads L10n).
    /// </summary>
    private ComboBox CreateStringSettingCombo(
        string[] labels, string[] values, string? currentValue, string key, string title,
        Action? onPersisted = null)
    {
        var combo = new ComboBox
        {
            MinWidth = 160,
            HorizontalAlignment = HorizontalAlignment.Right,
        };
        foreach (var label in labels)
        {
            combo.Items.Add(label);
        }

        // Unknown/missing values leave the combo unselected instead of
        // pretending a default was chosen.
        var persistedIndex = Array.IndexOf(values, currentValue);
        combo.SelectedIndex = persistedIndex;

        combo.SelectionChanged += async (sender, e) =>
        {
            if (_suppressComboWrite) return;
            if (sender is not ComboBox box) return;

            var index = box.SelectedIndex;
            if (index < 0 || index >= values.Length) return;

            var success = await WindowsBridge.UpdateSettingAsync(key, values[index]);

            if (success)
            {
                persistedIndex = index;
                onPersisted?.Invoke();
            }
            else if (box.SelectedIndex == index)
            {
                // Revert only if the user has not picked another item while
                // the write was in flight.
                _errorToast.Show($"Failed to update \"{title}\".");
                _suppressComboWrite = true;
                box.SelectedIndex = persistedIndex;
                _suppressComboWrite = false;
            }
        };

        return combo;
    }

    /// <summary>
    /// Settings row: title with optional secondary caption on the left,
    /// ComboBox on the right. Relative widths only; no opaque background so
    /// the Mica/Acrylic layer shows through.
    /// </summary>
    private static FrameworkElement CreateComboRow(string title, string? caption, ComboBox combo)
    {
        var row = new Grid { Padding = new Thickness(0, 8, 0, 8) };
        row.ColumnDefinitions.Add(new ColumnDefinition
            { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition
            { Width = GridLength.Auto });

        var labelPanel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
        };
        labelPanel.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 14,
            TextWrapping = TextWrapping.Wrap,
        });

        if (!string.IsNullOrEmpty(caption))
        {
            labelPanel.Children.Add(new TextBlock
            {
                Text = caption,
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = ThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            });
        }

        Grid.SetColumn(labelPanel, 0);
        row.Children.Add(labelPanel);

        Grid.SetColumn(combo, 1);
        row.Children.Add(combo);

        return row;
    }

    /// <summary>Theme-aware secondary brush with a hardcoded fallback.</summary>
    private static Microsoft.UI.Xaml.Media.Brush ThemeBrush(string key, Windows.UI.Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) &&
            value is Microsoft.UI.Xaml.Media.Brush brush)
        {
            return brush;
        }
        return new Microsoft.UI.Xaml.Media.SolidColorBrush(fallback);
    }

    private static string? TryGetStringValue(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static string FormatLabel(string key)
    {
        if (string.IsNullOrEmpty(key)) return key;

        var result = new System.Text.StringBuilder();
        for (int i = 0; i < key.Length; i++)
        {
            var c = key[i];
            if (i > 0 && char.IsUpper(c))
            {
                result.Append(' ');
            }
            result.Append(i == 0 ? char.ToUpper(c) : c);
        }

        return result.ToString();
    }

    private static string FormatValue(JsonElement value)
    {
        return value.ValueKind switch
        {
            JsonValueKind.String => value.GetString() ?? "",
            JsonValueKind.Number => value.TryGetInt64(out var l) ? l.ToString() : value.GetDouble().ToString("F2"),
            JsonValueKind.True => L10n.T("commonYes", "Yes"),
            JsonValueKind.False => L10n.T("commonNo", "No"),
            JsonValueKind.Null => "—",
            JsonValueKind.Array => $"[{value.GetArrayLength()} items]",
            JsonValueKind.Object => $"{{{value.EnumerateObject().Count()} properties}}",
            _ => value.ToString(),
        };
    }

    private static string Categorize(string key)
    {
        return key switch
        {
            "renderMode" or "language" or "theme" => L10n.T("settingsAppearance", "Appearance"),
            "version" or "buildNumber" or "channel" => L10n.T("settingsAbout", "About"),
            _ => L10n.T("settingsGeneral", "General"),
        };
    }

    private async void OnSettingToggled(object? sender, RoutedEventArgs e)
    {
        if (sender is not ToggleSwitch toggle) return;
        var key = toggle.Tag as string;
        if (string.IsNullOrEmpty(key)) return;

        var success = await WindowsBridge.UpdateSettingAsync(key, toggle.IsOn);
        if (!success)
        {
            _errorToast.Show($"Failed to update \"{FormatLabel(key)}\".");
            toggle.IsOn = !toggle.IsOn;
        }
    }

    private sealed class SettingEntry
    {
        public string RawKey { get; set; } = "";
        public string Key { get; set; } = "";
        public string Value { get; set; } = "";
        public string Category { get; set; } = L10n.T("settingsGeneral", "General");
        public bool IsBool { get; set; }
        public bool BoolValue { get; set; }
    }
}
