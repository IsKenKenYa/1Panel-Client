using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Website config center - Anti-Leech tab (upstream
/// frontend/src/views/website/website/config/basic/anti-Leech/index.vue).
///
/// One card mirrors the upstream form: the shared file-extension list, an
/// "Anti-Leech Protection" section (enable switch; when enabled the allowed
/// domains multi-line box, the empty-referer / non-standard-referer switches
/// and the blocked-request status code dropdown), a "Cache control" section
/// (browser-cache switch with time + unit, the static-asset request log
/// switch) and a single Save action. Enabling the protection prefills the
/// domain box from the website domain list (upstream changeEnable). Save
/// confirms through ConfirmDialog (cancel-focused) and writes via
/// UpdateWebsiteLeechAsync (the blocked status code travels as the C#
/// returnCode parameter; the bridge maps it to the return_ channel key);
/// success refreshes the form from the server like the upstream submit.
///
/// Read failures surface as an error InfoBar with an inline retry; null from
/// the bridge means failure while an empty object keeps the upstream
/// defaults (the upstream search() also skips populating when the feature is
/// fully off). Self-contained: helpers carry the LeechTab prefix.
/// </summary>
public static class WebsiteConfigLeechTab
{
    private const string DefaultExtends =
        "js,css,png,jpg,jpeg,gif,webp,webm,avif,ico,bmp,swf,eot,svg,ttf,woff,woff2";

    /// <summary>Blocked-request status codes; upstream default 404.</summary>
    private static readonly string[] ReturnCodes = { "404", "403", "400" };
    private static readonly string[] ReturnLabels =
        { "404 Not Found", "403 Forbidden", "400 Bad Request" };

    /// <summary>Cache time units (upstream Units); default day.</summary>
    private static readonly string[] CacheUnits = { "s", "m", "h", "d", "w", "M", "y" };

    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        var errorToast = new ErrorToast();
        var busyGuard = false;
        var suppressSwitchEvents = false;

        // Section 1: shared file extensions.
        var extendsBox = new TextBox { Text = DefaultExtends };

        // Section 2: anti-leech protection.
        var enableSwitch = new ToggleSwitch
        {
            OnContent = L10n.T("commonEnable", "Enable"),
            OffContent = L10n.T("hostGatewayDisable", "Disable"),
        };
        var serverNamesBox = new TextBox
        {
            AcceptsReturn = true,
            Height = 88,
            TextWrapping = TextWrapping.NoWrap,
            FontFamily = new FontFamily("Consolas"),
            IsSpellCheckEnabled = false,
        };
        ScrollViewer.SetVerticalScrollBarVisibility(serverNamesBox, ScrollBarVisibility.Auto);
        var noneRefSwitch = CreateBoolSwitch(true);
        var blockedSwitch = CreateBoolSwitch(false);

        var returnCombo = new ComboBox { Width = 200, HorizontalAlignment = HorizontalAlignment.Left };
        for (var i = 0; i < ReturnLabels.Length; i++)
        {
            returnCombo.Items.Add(new ComboBoxItem { Content = ReturnLabels[i], Tag = ReturnCodes[i] });
        }
        returnCombo.SelectedIndex = 0;

        var leechForm = new StackPanel { Orientation = Orientation.Vertical, Spacing = 0 };
        leechForm.Children.Add(LeechTabFormRow(
            L10n.T("hostLeechAccessDomains", "Allowed domains"),
            serverNamesBox,
            L10n.T("hostLeechDomainsHelper", "One domain per line")));
        leechForm.Children.Add(LeechTabFormRow(
            L10n.T("hostLeechNoneRef", "Allow empty referrer"), noneRefSwitch));
        leechForm.Children.Add(LeechTabFormRow(
            L10n.T("hostLeechBlockedRef", "Allow non-standard Referer"),
            blockedSwitch,
            L10n.T("hostLeechBlockedHelper",
                "When 'Allow empty referrer' is on, requests without a Referer are not blocked; this also allows any Referer not starting with http/https")));
        leechForm.Children.Add(LeechTabFormRow(
            L10n.T("hostLeechReturn", "Response resource"),
            StackBelow(returnCombo,
                L10n.T("hostLeechReturnHelper", "HTTP status code returned after blocking hotlinking requests"))));

        // Section 3: cache control.
        var cacheSwitch = CreateBoolSwitch(false);
        var cacheTimeBox = new TextBox { Text = "30" };
        var unitCombo = new ComboBox { Width = 100 };
        foreach (var unit in CacheUnits)
        {
            unitCombo.Items.Add(new ComboBoxItem { Content = unit, Tag = unit });
        }
        unitCombo.SelectedIndex = 3; // 'd'

        var cacheTimeRow = LeechTabFormRow(
            L10n.T("hostLeechCacheTime", "Browser Cache Time"),
            LeechTabCacheTimeInput(cacheTimeBox, unitCombo),
            L10n.T("hostLeechCacheTimeHelper",
                "The time static resources are cached locally in the browser, reducing redundant requests"));

        var logEnableSwitch = CreateBoolSwitch(false);
        var logEnableRow = LeechTabFormRow(
            L10n.T("hostLeechLogEnable", "Log static asset requests"),
            logEnableSwitch,
            L10n.T("hostLeechLogHelper",
                "Logs static asset requests; usually disabled in production to avoid noisy logs"));

        var cacheForm = new StackPanel { Orientation = Orientation.Vertical, Spacing = 0 };
        cacheForm.Children.Add(cacheTimeRow);
        cacheForm.Children.Add(logEnableRow);

        // Status surfaces.
        var noticeBar = new InfoBar
        {
            Severity = InfoBarSeverity.Success,
            IsClosable = true,
            IsOpen = false,
            Margin = new Thickness(8, 8, 8, 0),
        };
        // Load-error surface with inline retry (InfoBar + retry pair).
        var loadErrorRow = LeechTabErrorRow(out var loadErrorBar, out var loadRetryButton);
        var saveErrorText = new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = LeechTabThemeBrush("SystemFillColorCriticalBrush", Colors.Red),
            Visibility = Visibility.Collapsed,
        };
        var saveButton = new Button
        {
            Content = L10n.T("commonSave", "Save"),
            Padding = new Thickness(24, 6, 24, 6),
            HorizontalAlignment = HorizontalAlignment.Left,
        };

        var card = LeechTabCard(L10n.T("websiteLeechTitle", "Anti-Leech"), out var cardPanel);
        cardPanel.Children.Add(LeechTabFormRow(
            L10n.T("hostLeechExtends", "File extensions"), extendsBox));
        cardPanel.Children.Add(LeechTabDivider(
            L10n.T("websiteLeechProtection", "Anti-Leech Protection")));
        cardPanel.Children.Add(LeechTabFormRow(
            L10n.T("hostLeechEnable", "Enable"), enableSwitch));
        cardPanel.Children.Add(leechForm);
        cardPanel.Children.Add(LeechTabDivider(L10n.T("hostLeechCacheControl", "Cache control")));
        cardPanel.Children.Add(LeechTabFormRow(
            L10n.T("hostLeechBrowserCache", "Browser Cache"), cacheSwitch));
        cardPanel.Children.Add(cacheForm);
        cardPanel.Children.Add(saveErrorText);
        cardPanel.Children.Add(saveButton);

        var content = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 12,
            Margin = new Thickness(8, 0, 8, 0),
        };
        content.Children.Add(new TextBlock
        {
            Text = websiteName,
            FontSize = 12,
            Foreground = LeechTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextTrimming = TextTrimming.CharacterEllipsis,
            Margin = new Thickness(0, 4, 0, 0),
        });
        content.Children.Add(card);

        var loadingRing = new ProgressRing
        {
            IsActive = true,
            Width = 36,
            Height = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var root = new Grid
        {
            RowDefinitions =
            {
                new RowDefinition { Height = GridLength.Auto },
                new RowDefinition { Height = GridLength.Auto },
                new RowDefinition { Height = new GridLength(1, GridUnitType.Star) },
            },
        };

        var contentScroll = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 0, 8),
            Content = content,
        };

        Grid.SetRow(noticeBar, 0);
        Grid.SetRow(loadErrorRow, 1);
        Grid.SetRow(contentScroll, 2);
        Grid.SetRow(loadingRing, 2);
        errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(errorToast, 2);
        root.Children.Add(noticeBar);
        root.Children.Add(loadErrorRow);
        root.Children.Add(contentScroll);
        root.Children.Add(loadingRing);
        root.Children.Add(errorToast);

        void ShowLoadError(bool show)
        {
            loadErrorBar.IsOpen = show;
            loadRetryButton.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
        }

        void SetBusy(bool busy)
        {
            busyGuard = busy;
            saveButton.IsEnabled = !busy;
            enableSwitch.IsEnabled = !busy;
        }

        // Expands/collapses the conditional sub-forms (upstream template
        // v-ifs: leech details while enabled, cache time and the
        // request-log switch while cache or protection is on).
        void UpdateVisibility()
        {
            leechForm.Visibility = enableSwitch.IsOn ? Visibility.Visible : Visibility.Collapsed;
            cacheTimeRow.Visibility = cacheSwitch.IsOn ? Visibility.Visible : Visibility.Collapsed;
            logEnableRow.Visibility = enableSwitch.IsOn || cacheSwitch.IsOn
                ? Visibility.Visible
                : Visibility.Collapsed;
        }

        void ApplyConfig(JsonElement map)
        {
            var enable = LeechTabBool(map, "enable");
            var cache = LeechTabBool(map, "cache");

            // Upstream search(): a fully disabled response keeps the form at
            // its defaults instead of populating.
            if (!enable && !cache)
            {
                suppressSwitchEvents = true;
                enableSwitch.IsOn = false;
                cacheSwitch.IsOn = false;
                suppressSwitchEvents = false;
                UpdateVisibility();
                return;
            }

            suppressSwitchEvents = true;
            enableSwitch.IsOn = enable;
            cacheSwitch.IsOn = cache;
            extendsBox.Text = LeechTabString(map, "extends") ?? DefaultExtends;
            noneRefSwitch.IsOn = !map.TryGetProperty("noneRef", out _) || LeechTabBool(map, "noneRef");
            blockedSwitch.IsOn = LeechTabBool(map, "blocked");
            serverNamesBox.Text = LeechTabJoinLines(LeechTabStringArray(map, "serverNames"));
            SelectByTag(returnCombo, LeechTabString(map, "return") ?? "404");
            if (cache)
            {
                cacheTimeBox.Text = LeechTabLongOr(map, "cacheTime", 30).ToString(CultureInfo.InvariantCulture);
                SelectByTag(unitCombo, LeechTabString(map, "cacheUint") ?? "d");
            }
            logEnableSwitch.IsOn = LeechTabBool(map, "logEnable");
            suppressSwitchEvents = false;
            UpdateVisibility();
        }

        async Task LoadAsync(bool showLoading)
        {
            if (busyGuard) return;
            busyGuard = true;

            if (showLoading)
            {
                loadingRing.Visibility = Visibility.Visible;
                contentScroll.Visibility = Visibility.Collapsed;
                ShowLoadError(false);
            }

            JsonElement? config = null;
            try
            {
                config = await WindowsBridge.GetWebsiteLeechAsync(websiteId);
            }
            finally
            {
                busyGuard = false;
            }

            if (config == null)
            {
                if (showLoading)
                {
                    loadingRing.Visibility = Visibility.Collapsed;
                    ShowLoadError(true);
                }
                else
                {
                    errorToast.Show(L10n.T("hostLeechLoadFailed", "Failed to load the anti-leech configuration."));
                }
                return;
            }

            ApplyConfig(config.Value);
            loadingRing.Visibility = Visibility.Collapsed;
            ShowLoadError(false);
            contentScroll.Visibility = Visibility.Visible;
        }

        // Enabling the protection prefills the domain box from the website
        // domain list (upstream changeEnable); silent when unavailable.
        enableSwitch.Toggled += (s, e) =>
        {
            if (suppressSwitchEvents) return;
            UpdateVisibility();
            if (enableSwitch.IsOn && string.IsNullOrWhiteSpace(serverNamesBox.Text))
            {
                _ = PrefillDomainsAsync();
            }
        };

        async Task PrefillDomainsAsync()
        {
            if (busyGuard) return;
            busyGuard = true;
            JsonElement? domains = null;
            try
            {
                domains = await WindowsBridge.GetWebsiteDomainsAsync(websiteId);
            }
            finally
            {
                busyGuard = false;
            }

            if (domains == null || domains.Value.ValueKind != JsonValueKind.Array) return;
            var lines = new List<string>();
            foreach (var item in domains.Value.EnumerateArray())
            {
                var domain = LeechTabString(item, "domain");
                if (!string.IsNullOrWhiteSpace(domain))
                {
                    lines.Add(domain.Trim());
                }
            }
            if (lines.Count > 0 && string.IsNullOrWhiteSpace(serverNamesBox.Text))
            {
                serverNamesBox.Text = string.Join(Environment.NewLine, lines);
            }
        }

        cacheSwitch.Toggled += (s, e) =>
        {
            if (suppressSwitchEvents) return;
            UpdateVisibility();
        };

        loadRetryButton.Click += (s, e) => _ = LoadAsync(showLoading: true);

        saveButton.Click += (s, e) => _ = SaveAsync();

        async Task SaveAsync()
        {
            if (busyGuard) return;
            SetFormError(saveErrorText, null);

            var enable = enableSwitch.IsOn;
            var serverNames = ParseServerNames();
            if (enable && serverNames.Count == 0)
            {
                SetFormError(saveErrorText,
                    L10n.T("hostLeechDomainsRequired", "At least one allowed domain is required when enabled."));
                return;
            }

            long? cacheTime = null;
            if (cacheSwitch.IsOn)
            {
                if (!long.TryParse(cacheTimeBox.Text.Trim(), NumberStyles.Integer,
                        CultureInfo.InvariantCulture, out var parsed) || parsed < 1 || parsed > 65535)
                {
                    SetFormError(saveErrorText, L10n.T(
                        "hostLeechCacheTimeInvalid", "Cache time must be an integer between 1 and 65535."));
                    return;
                }
                cacheTime = parsed;
            }

            if (root.XamlRoot == null) return;
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                L10n.T("commonSave", "Save"),
                string.Format(
                    L10n.T("hostLeechSaveConfirm", "Save the anti-leech configuration for \"{0}\"?"), websiteName),
                L10n.T("commonSave", "Save"),
                L10n.T("commonCancel", "Cancel"));
            if (!confirmed) return;

            SetBusy(true);
            bool success;
            try
            {
                success = await WindowsBridge.UpdateWebsiteLeechAsync(
                    websiteId,
                    enable,
                    extendsBox.Text.Trim(),
                    serverNames,
                    TagOfSelectedItem(returnCombo) ?? "404",
                    noneRefSwitch.IsOn,
                    blockedSwitch.IsOn,
                    cacheSwitch.IsOn,
                    cacheTime,
                    TagOfSelectedItem(unitCombo) ?? "d",
                    logEnableSwitch.IsOn);
            }
            finally
            {
                SetBusy(false);
            }

            if (success)
            {
                noticeBar.Title = L10n.T("hostLeechSaved", "Anti-leech configuration saved.");
                noticeBar.IsOpen = true;
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostLeechSaveFailed", "Failed to save the anti-leech configuration."));
            }
        }

        List<object> ParseServerNames()
        {
            var names = new List<object>();
            foreach (var raw in serverNamesBox.Text.Split('\n'))
            {
                var line = raw.Trim();
                if (line.Length > 0)
                {
                    names.Add(line);
                }
            }
            return names;
        }

        root.Loaded += (s, e) => _ = LoadAsync(showLoading: true);
        return root;
    }

    private static ToggleSwitch CreateBoolSwitch(bool initial)
    {
        return new ToggleSwitch
        {
            OnContent = L10n.T("commonYes", "Yes"),
            OffContent = L10n.T("commonNo", "No"),
            IsOn = initial,
        };
    }

    /// <summary>Stacks a helper caption directly under a control.</summary>
    private static FrameworkElement StackBelow(FrameworkElement control, string helpText)
    {
        var panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 4 };
        panel.Children.Add(control);
        panel.Children.Add(new TextBlock
        {
            Text = helpText,
            FontSize = 12,
            Foreground = LeechTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        });
        return panel;
    }

    /// <summary>Cache time entry: numeric box with the unit combo appended.</summary>
    private static FrameworkElement LeechTabCacheTimeInput(TextBox numberBox, ComboBox unitCombo)
    {
        var row = new Grid { ColumnSpacing = 8 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(160) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        numberBox.VerticalAlignment = VerticalAlignment.Center;
        unitCombo.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(numberBox, 0);
        Grid.SetColumn(unitCombo, 1);
        row.Children.Add(numberBox);
        row.Children.Add(unitCombo);
        return row;
    }

    /// <summary>Left-aligned section caption (upstream el-divider).</summary>
    private static FrameworkElement LeechTabDivider(string text)
    {
        return new TextBlock
        {
            Text = text,
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            Foreground = LeechTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            Margin = new Thickness(0, 8, 0, 2),
        };
    }

    private static void SelectByTag(ComboBox combo, string tag)
    {
        foreach (var item in combo.Items)
        {
            if (item is ComboBoxItem comboItem && string.Equals(comboItem.Tag as string, tag, StringComparison.Ordinal))
            {
                combo.SelectedItem = comboItem;
                return;
            }
        }
    }

    private static string? TagOfSelectedItem(ComboBox combo)
    {
        return combo.SelectedItem is ComboBoxItem item ? item.Tag as string : null;
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

    /// <summary>
    /// Load-error surface: an error InfoBar paired with a trailing Retry
    /// button (typed as Button, toggled together via ShowLoadError).
    /// </summary>
    private static FrameworkElement LeechTabErrorRow(out InfoBar bar, out Button retryButton)
    {
        var row = new Grid { ColumnSpacing = 8, Margin = new Thickness(8, 8, 8, 0) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        bar = new InfoBar
        {
            Title = L10n.T("hostLeechLoadFailed", "Failed to load the anti-leech configuration."),
            Severity = InfoBarSeverity.Error,
            IsClosable = false,
            IsOpen = false,
        };
        retryButton = new Button
        {
            Content = L10n.T("commonRetry", "Retry"),
            Padding = new Thickness(10, 2, 10, 2),
            VerticalAlignment = VerticalAlignment.Center,
            Visibility = Visibility.Collapsed,
        };

        Grid.SetColumn(bar, 0);
        Grid.SetColumn(retryButton, 1);
        row.Children.Add(bar);
        row.Children.Add(retryButton);
        return row;
    }

    private static FrameworkElement LeechTabCard(string title, out StackPanel panel)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = LeechTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = LeechTabSubtleFill(),
        };

        panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        panel.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        });
        card.Child = panel;
        return card;
    }

    private static FrameworkElement LeechTabFormRow(string label, FrameworkElement control, string? helpText = null)
    {
        var row = new Grid { ColumnSpacing = 12 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(180) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        control.VerticalAlignment = VerticalAlignment.Center;
        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 13,
            VerticalAlignment = VerticalAlignment.Center,
            TextWrapping = TextWrapping.Wrap,
        };
        Grid.SetColumn(labelBlock, 0);
        row.Children.Add(labelBlock);
        Grid.SetColumn(control, 1);
        row.Children.Add(control);

        var body = new StackPanel { Orientation = Orientation.Vertical, Spacing = 0 };
        body.Children.Add(row);
        if (!string.IsNullOrEmpty(helpText))
        {
            body.Children.Add(new TextBlock
            {
                Text = helpText,
                FontSize = 12,
                Foreground = LeechTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
                Margin = new Thickness(192, 0, 0, 10),
            });
        }
        body.Margin = new Thickness(0, 0, 0, 10);
        return body;
    }

    private static string LeechTabJoinLines(List<string> lines)
    {
        return string.Join(Environment.NewLine, lines);
    }

    private static List<string> LeechTabStringArray(JsonElement element, string property)
    {
        var result = new List<string>();
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in prop.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.String)
                {
                    result.Add(item.GetString() ?? string.Empty);
                }
            }
        }
        return result;
    }

    private static string? LeechTabString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static bool LeechTabBool(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop))
        {
            if (prop.ValueKind == JsonValueKind.True) return true;
            if (prop.ValueKind == JsonValueKind.False) return false;
        }
        return false;
    }

    private static long LeechTabLongOr(JsonElement element, string property, long fallback)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number &&
            prop.TryGetInt64(out var value))
        {
            return value;
        }
        return fallback;
    }

    private static Brush LeechTabThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Brush LeechTabSubtleFill()
    {
        var stroke = LeechTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}
