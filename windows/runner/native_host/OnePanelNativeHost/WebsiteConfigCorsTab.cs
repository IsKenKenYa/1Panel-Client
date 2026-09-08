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
/// Website config center - CORS tab (upstream
/// frontend/src/views/website/website/config/basic/cors/index.vue over the
/// shared website/cors CorsSetting component).
///
/// One card mirrors the upstream form: the "Enable CORS" master switch, and
/// while enabled the allowOrigins (required, placeholder "*"), allowMethods
/// (placeholder "GET,POST,OPTIONS,PUT,DELETE"), allowHeaders text fields and
/// the allowCredentials / preflight switches. Save confirms through
/// ConfirmDialog (cancel-focused) and writes via UpdateWebsiteCorsAsync;
/// success shows a dismissible notice and failure the error toast. Read
/// failures surface as an error InfoBar with an inline retry.
///
/// Data flows through WindowsBridge (getWebsiteCors / updateWebsiteCors);
/// null means the bridge failed, an empty object renders the upstream
/// defaults. Self-contained: all helpers carry the CorsTab prefix.
/// </summary>
public static class WebsiteConfigCorsTab
{
    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        var errorToast = new ErrorToast();
        var busyGuard = false;

        // Form controls (closure state; the tab never rebuilds its tree).
        var corsSwitch = new ToggleSwitch
        {
            OnContent = L10n.T("commonEnable", "Enable"),
            OffContent = L10n.T("hostGatewayDisable", "Disable"),
        };
        var originsBox = new TextBox
        {
            AcceptsReturn = true,
            Height = 72,
            PlaceholderText = "*",
            TextWrapping = TextWrapping.Wrap,
        };
        var methodsBox = new TextBox
        {
            PlaceholderText = "GET,POST,OPTIONS,PUT,DELETE",
        };
        var headersBox = new TextBox();
        var credentialsSwitch = new ToggleSwitch
        {
            OnContent = L10n.T("commonYes", "Yes"),
            OffContent = L10n.T("commonNo", "No"),
        };
        var preflightSwitch = new ToggleSwitch
        {
            OnContent = L10n.T("commonYes", "Yes"),
            OffContent = L10n.T("commonNo", "No"),
        };

        // The details form only shows while CORS is enabled (upstream
        // collapse-transition). Toggling reseeds the fields with the
        // upstream defaults (enable) or clears them (disable).
        var formPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 0 };
        var suppressSwitchEvents = false;

        formPanel.Children.Add(CorsTabFormRow(
            L10n.T("hostCorsAllowOrigins", "Allowed domains"), originsBox));
        formPanel.Children.Add(CorsTabFormRow(
            L10n.T("hostCorsAllowMethods", "Allowed request methods"), methodsBox));
        formPanel.Children.Add(CorsTabFormRow(
            L10n.T("hostCorsAllowHeaders", "Allowed request headers"), headersBox));
        formPanel.Children.Add(CorsTabFormRow(
            L10n.T("hostCorsAllowCredentials", "Allow cookies to be sent"), credentialsSwitch));
        formPanel.Children.Add(CorsTabFormRow(
            L10n.T("hostCorsPreflight", "Preflight request fast response"),
            preflightSwitch,
            L10n.T("hostCorsPreflightHelper",
                "Answers cross-origin OPTIONS preflight requests automatically with 204 and the CORS headers")));

        corsSwitch.Toggled += (s, e) =>
        {
            if (suppressSwitchEvents) return;
            formPanel.Visibility = corsSwitch.IsOn ? Visibility.Visible : Visibility.Collapsed;
            if (corsSwitch.IsOn)
            {
                suppressSwitchEvents = true;
                originsBox.Text = "*";
                methodsBox.Text = "GET,POST,OPTIONS,PUT,DELETE";
                headersBox.Text = string.Empty;
                credentialsSwitch.IsOn = false;
                preflightSwitch.IsOn = true;
                suppressSwitchEvents = false;
            }
            else
            {
                suppressSwitchEvents = true;
                originsBox.Text = string.Empty;
                methodsBox.Text = string.Empty;
                headersBox.Text = string.Empty;
                credentialsSwitch.IsOn = false;
                preflightSwitch.IsOn = true;
                suppressSwitchEvents = false;
            }
        };

        // Status surface: dismissible success notice above the card.
        var noticeBar = new InfoBar
        {
            Severity = InfoBarSeverity.Success,
            IsClosable = true,
            IsOpen = false,
            Margin = new Thickness(8, 8, 8, 0),
        };

        // Load-error surface with inline retry (InfoBar + retry pair).
        var loadErrorRow = CorsTabErrorRow(out var loadErrorBar, out var loadRetryButton);

        var saveErrorText = new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = CorsTabThemeBrush("SystemFillColorCriticalBrush", Colors.Red),
            Visibility = Visibility.Collapsed,
        };

        var saveButton = new Button
        {
            Content = L10n.T("commonSave", "Save"),
            Padding = new Thickness(24, 6, 24, 6),
            HorizontalAlignment = HorizontalAlignment.Left,
        };

        var card = CorsTabCard(L10n.T("websiteCorsTitle", "CORS"), out var cardPanel);
        cardPanel.Children.Add(CorsTabFormRow(
            L10n.T("hostCorsEnable", "Enable CORS"), corsSwitch));
        cardPanel.Children.Add(formPanel);
        cardPanel.Children.Add(saveErrorText);

        var saveRow = new StackPanel { Orientation = Orientation.Vertical, Spacing = 8 };
        saveRow.Children.Add(saveButton);
        cardPanel.Children.Add(saveRow);

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
            Foreground = CorsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
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
        }

        void ApplyConfig(JsonElement map)
        {
            suppressSwitchEvents = true;
            corsSwitch.IsOn = CorsTabBool(map, "cors");
            originsBox.Text = CorsTabString(map, "allowOrigins") ?? "*";
            methodsBox.Text = CorsTabString(map, "allowMethods") ?? "GET,POST,OPTIONS,PUT,DELETE";
            headersBox.Text = CorsTabString(map, "allowHeaders") ?? string.Empty;
            credentialsSwitch.IsOn = CorsTabBool(map, "allowCredentials");
            // preflight defaults to true when the payload omits it (upstream default).
            var preflight = true;
            if (map.ValueKind == JsonValueKind.Object &&
                map.TryGetProperty("preflight", out var preflightProp) &&
                preflightProp.ValueKind is JsonValueKind.True or JsonValueKind.False)
            {
                preflight = preflightProp.ValueKind == JsonValueKind.True;
            }
            preflightSwitch.IsOn = preflight;
            suppressSwitchEvents = false;
            formPanel.Visibility = corsSwitch.IsOn ? Visibility.Visible : Visibility.Collapsed;
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
                config = await WindowsBridge.GetWebsiteCorsAsync(websiteId);
            }
            finally
            {
                busyGuard = false;
            }

            if (config == null)
            {
                // Bridge failure: error InfoBar on initial load, toast on refresh.
                if (showLoading)
                {
                    loadingRing.Visibility = Visibility.Collapsed;
                    ShowLoadError(true);
                }
                else
                {
                    errorToast.Show(L10n.T("hostCorsLoadFailed", "Failed to load the CORS configuration."));
                }
                return;
            }

            ApplyConfig(config.Value);
            loadingRing.Visibility = Visibility.Collapsed;
            ShowLoadError(false);
            contentScroll.Visibility = Visibility.Visible;
        }

        loadRetryButton.Click += (s, e) => _ = LoadAsync(showLoading: true);

        saveButton.Click += (s, e) => _ = SaveAsync();

        async Task SaveAsync()
        {
            if (busyGuard) return;
            SetFormError(saveErrorText, null);

            var cors = corsSwitch.IsOn;
            var origins = originsBox.Text.Trim();
            var methods = methodsBox.Text.Trim();
            var headers = headersBox.Text.Trim();

            // Upstream marks allowOrigins required; enforced only while the
            // feature is enabled so a disabled config stays savable as-is.
            if (cors && string.IsNullOrWhiteSpace(origins))
            {
                SetFormError(saveErrorText,
                    L10n.T("hostCorsOriginsRequired", "Allowed domains is required when CORS is enabled."));
                return;
            }

            if (root.XamlRoot == null) return;
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                L10n.T("commonSave", "Save"),
                string.Format(
                    L10n.T("hostCorsSaveConfirm", "Save the CORS configuration for \"{0}\"?"), websiteName),
                L10n.T("commonSave", "Save"),
                L10n.T("commonCancel", "Cancel"));
            if (!confirmed) return;

            SetBusy(true);
            bool success;
            try
            {
                success = await WindowsBridge.UpdateWebsiteCorsAsync(
                    websiteId,
                    cors,
                    origins,
                    methods,
                    string.IsNullOrEmpty(headers) ? null : headers,
                    credentialsSwitch.IsOn,
                    preflightSwitch.IsOn);
            }
            finally
            {
                SetBusy(false);
            }

            if (success)
            {
                noticeBar.Title = L10n.T("hostCorsSaved", "CORS configuration saved.");
                noticeBar.IsOpen = true;
            }
            else
            {
                errorToast.Show(L10n.T("hostCorsSaveFailed", "Failed to save the CORS configuration."));
            }
        }

        root.Loaded += (s, e) => _ = LoadAsync(showLoading: true);
        return root;
    }

    /// <summary>Shows or hides the inline form validation error.</summary>
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
    private static FrameworkElement CorsTabErrorRow(out InfoBar bar, out Button retryButton)
    {
        var row = new Grid { ColumnSpacing = 8, Margin = new Thickness(8, 8, 8, 0) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        bar = new InfoBar
        {
            Title = L10n.T("hostCorsLoadFailed", "Failed to load the CORS configuration."),
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

    /// <summary>
    /// Card shell mirroring SecurityGatewayPage: rounded CardStroke border
    /// with a faint translucent tint so it reads over Mica in both themes.
    /// </summary>
    private static FrameworkElement CorsTabCard(string title, out StackPanel panel)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = CorsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = CorsTabSubtleFill(),
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

    /// <summary>
    /// Upstream label-width form row: fixed label column on the leading
    /// edge, the control stretching behind it, optional helper text below.
    /// </summary>
    private static FrameworkElement CorsTabFormRow(string label, FrameworkElement control, string? helpText = null)
    {
        var body = new StackPanel { Orientation = Orientation.Vertical, Spacing = 4 };

        var row = new Grid { ColumnSpacing = 12, Margin = new Thickness(0, 0, 0, 10) };
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
        body.Children.Add(row);

        if (!string.IsNullOrEmpty(helpText))
        {
            body.Children.Add(new TextBlock
            {
                Text = helpText,
                FontSize = 12,
                Foreground = CorsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
                Margin = new Thickness(192, 0, 0, 10),
            });
        }

        return body;
    }

    private static string? CorsTabString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static bool CorsTabBool(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop))
        {
            if (prop.ValueKind == JsonValueKind.True) return true;
            if (prop.ValueKind == JsonValueKind.False) return false;
        }
        return false;
    }

    private static Brush CorsTabThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Brush CorsTabSubtleFill()
    {
        var stroke = CorsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}
