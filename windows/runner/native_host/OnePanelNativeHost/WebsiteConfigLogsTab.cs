using System;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Website config center - Website logs tab (upstream
/// frontend/src/views/website/website/config/log/index.vue with the
/// log-fiile pane).
///
/// Two sub-tabs (access.log / error.log) mirror the upstream el-tabs. The
/// upstream pane also carries a live enable switch and a "Clear" action;
/// the channel contract has no website-log switch/clear handler this
/// release, so this batch renders content viewing only: the log switch
/// state from the log/search payload is shown as a read-only (disabled)
/// switch and the body is the fetched log content in a read-only monospace
/// view with a per-pane Refresh action. Each pane loads lazily on first
/// selection (upstream v-if per active index); load failures surface as a
/// per-pane error InfoBar with retry.
///
/// Data flows through WindowsBridge.GetWebsiteLogsAsync (getWebsiteLogs,
/// POST /websites/log/search); the response carries {enable, content, end,
/// path} and null means the bridge failed. Self-contained: helpers carry
/// the LogsTab prefix.
/// </summary>
public static class WebsiteConfigLogsTab
{
    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        var errorToast = new ErrorToast();

        var pivot = new Pivot
        {
            Visibility = Visibility.Collapsed,
            LeftHeader = new TextBlock
            {
                Text = websiteName,
                FontSize = 12,
                Foreground = LogsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(8, 0, 8, 0),
            },
        };

        var accessPane = LogsTabBuildPane(websiteId, "access.log",
            L10n.T("hostLogsAccessLog", "Website logs"), errorToast);
        var errorPane = LogsTabBuildPane(websiteId, "error.log",
            L10n.T("hostLogsErrorLog", "Error log"), errorToast);

        pivot.Items.Add(accessPane.Item);
        pivot.Items.Add(errorPane.Item);

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
                new RowDefinition { Height = new GridLength(1, GridUnitType.Star) },
            },
        };
        Grid.SetRow(pivot, 0);
        Grid.SetRow(loadingRing, 0);
        errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(errorToast, 0);
        root.Children.Add(pivot);
        root.Children.Add(loadingRing);
        root.Children.Add(errorToast);

        var initialPaneLoaded = false;

        async Task InitialLoadAsync()
        {
            loadingRing.Visibility = Visibility.Visible;
            pivot.Visibility = Visibility.Collapsed;
            await accessPane.EnsureLoaded();
            initialPaneLoaded = true;
            loadingRing.Visibility = Visibility.Collapsed;
            pivot.Visibility = Visibility.Visible;
        }

        // Lazy per-pane loading (upstream renders only the active pane).
        pivot.SelectionChanged += (s, e) =>
        {
            if (!initialPaneLoaded) return;
            if (pivot.SelectedItem == accessPane.Item)
            {
                _ = accessPane.EnsureLoaded();
            }
            else if (pivot.SelectedItem == errorPane.Item)
            {
                _ = errorPane.EnsureLoaded();
            }
        };

        root.Loaded += (s, e) =>
        {
            if (!initialPaneLoaded)
            {
                _ = InitialLoadAsync();
            }
        };
        return root;
    }

    /// <summary>
    /// One log pane: a card with the log title, the read-only enable state
    /// (the channel has no log switch write this release) and a Refresh
    /// action in the header, over a read-only monospace log body. Loads once
    /// on first demand; later EnsureLoaded calls refresh silently.
    /// </summary>
    private static (PivotItem Item, Func<Task> EnsureLoaded) LogsTabBuildPane(
        int websiteId, string logType, string title, ErrorToast errorToast)
    {
        var busyGuard = false;
        var loaded = false;

        var statusSwitch = new ToggleSwitch
        {
            OnContent = L10n.T("commonEnable", "Enable"),
            OffContent = L10n.T("hostGatewayDisable", "Disable"),
            IsEnabled = false, // read-only display: no log switch handler this release
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(statusSwitch, L10n.T("hostLogsStateHint",
            "Log switch state (read-only in this release)"));

        var refreshButton = new Button
        {
            Padding = new Thickness(10, 4, 10, 4),
            VerticalAlignment = VerticalAlignment.Center,
            Content = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Spacing = 6,
                Children =
                {
                    new FontIcon { Glyph = "\uE72C", FontSize = 14 },
                    new TextBlock
                    {
                        Text = L10n.T("commonRefresh", "Refresh"),
                        FontSize = 12,
                        VerticalAlignment = VerticalAlignment.Center,
                    },
                },
            },
        };

        var errorRow = LogsTabErrorRow(out var errorBar, out var retryButton);

        var emptyText = new TextBlock
        {
            Text = L10n.T("websiteLogEmpty", "No logs"),
            FontSize = 12,
            Foreground = LogsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            Visibility = Visibility.Collapsed,
            Margin = new Thickness(0, 8, 0, 0),
        };

        var logBox = new TextBox
        {
            AcceptsReturn = true,
            IsReadOnly = true,
            IsSpellCheckEnabled = false,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 12,
            MinHeight = 360,
            TextWrapping = TextWrapping.NoWrap,
            PlaceholderText = string.Empty,
        };
        ScrollViewer.SetVerticalScrollBarVisibility(logBox, ScrollBarVisibility.Auto);
        ScrollViewer.SetHorizontalScrollBarVisibility(logBox, ScrollBarVisibility.Auto);

        var bodyPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 8 };
        bodyPanel.Children.Add(errorRow);
        bodyPanel.Children.Add(logBox);
        bodyPanel.Children.Add(emptyText);

        var paneLoading = new ProgressRing
        {
            IsActive = true,
            Width = 28,
            Height = 28,
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0, 24, 0, 0),
        };

        // Header: title + status caption/switch + trailing refresh.
        var card = LogsTabCard(title, out var cardPanel, refreshButton);
        var statusRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            VerticalAlignment = VerticalAlignment.Center,
        };
        statusRow.Children.Add(new TextBlock
        {
            Text = L10n.T("commonStatus", "Status"),
            FontSize = 12,
            Foreground = LogsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            VerticalAlignment = VerticalAlignment.Center,
        });
        statusRow.Children.Add(statusSwitch);
        cardPanel.Children.Add(statusRow);
        cardPanel.Children.Add(bodyPanel);

        var paneHost = new Grid();
        paneHost.Children.Add(card);
        paneHost.Children.Add(paneLoading);

        var item = new PivotItem
        {
            Header = title,
            Content = new ScrollViewer
            {
                HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
                VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                Padding = new Thickness(0, 0, 8, 8),
                Content = paneHost,
            },
        };

        async Task LoadCoreAsync(bool showLoading)
        {
            if (busyGuard) return;
            busyGuard = true;

            if (showLoading)
            {
                paneLoading.Visibility = Visibility.Visible;
                card.Visibility = Visibility.Collapsed;
                LogsTabShowError(errorBar, retryButton, false);
            }

            JsonElement? payload = null;
            try
            {
                payload = await WindowsBridge.GetWebsiteLogsAsync(websiteId, logType);
            }
            finally
            {
                busyGuard = false;
            }

            paneLoading.Visibility = Visibility.Collapsed;
            card.Visibility = Visibility.Visible;

            if (payload == null || payload.Value.ValueKind != JsonValueKind.Object)
            {
                if (showLoading || !loaded)
                {
                    LogsTabShowError(errorBar, retryButton, true);
                }
                else
                {
                    errorToast.Show(
                        L10n.T("hostLogsRefreshFailed", "Failed to refresh the website log."));
                }
                return;
            }

            var map = payload.Value;
            // Read-only switch state from the same payload; unknown keeps Off.
            var statusOn = map.TryGetProperty("enable", out var enableProp) &&
                enableProp.ValueKind == JsonValueKind.True;
            statusSwitch.IsOn = statusOn;

            var content = map.TryGetProperty("content", out var contentProp) &&
                contentProp.ValueKind == JsonValueKind.String
                    ? contentProp.GetString() ?? string.Empty
                    : string.Empty;
            logBox.Text = content;
            emptyText.Visibility = content.Length == 0 ? Visibility.Visible : Visibility.Collapsed;
            LogsTabShowError(errorBar, retryButton, false);
            loaded = true;
        }

        refreshButton.Click += (s, e) => _ = LoadCoreAsync(showLoading: !loaded);
        retryButton.Click += (s, e) => _ = LoadCoreAsync(showLoading: true);

        // First EnsureLoaded shows the pane spinner, later calls refresh.
        return (item, () => LoadCoreAsync(showLoading: !loaded));
    }

    /// <summary>
    /// Load-error surface: an error InfoBar paired with a trailing Retry
    /// button (typed as Button); visibility toggled via LogsTabShowError.
    /// </summary>
    private static FrameworkElement LogsTabErrorRow(out InfoBar bar, out Button retryButton)
    {
        var row = new Grid { ColumnSpacing = 8 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        bar = new InfoBar
        {
            Title = L10n.T("hostLogsLoadFailed", "Failed to load the website log."),
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

    /// <summary>Toggles the InfoBar/Retry pair together.</summary>
    private static void LogsTabShowError(InfoBar bar, Button retryButton, bool show)
    {
        bar.IsOpen = show;
        retryButton.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
    }

    /// <summary>
    /// Card shell with a semi-bold title and an optional trailing header
    /// action; visual parity with SecurityGatewayPage cards.
    /// </summary>
    private static FrameworkElement LogsTabCard(
        string title, out StackPanel panel, FrameworkElement? headerAction = null)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = LogsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = LogsTabSubtleFill(),
        };

        panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };

        var titleBlock = new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
        };

        if (headerAction != null)
        {
            var header = new Grid { ColumnSpacing = 8 };
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            Grid.SetColumn(titleBlock, 0);
            Grid.SetColumn(headerAction, 1);
            header.Children.Add(titleBlock);
            header.Children.Add(headerAction);
            panel.Children.Add(header);
        }
        else
        {
            panel.Children.Add(titleBlock);
        }

        card.Child = panel;
        return card;
    }

    private static Brush LogsTabThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Brush LogsTabSubtleFill()
    {
        var stroke = LogsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}
