using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Website config center - "Reverse Proxy" tab, desktop layout adaptation of
/// the upstream 1Panel website proxy views
/// (frontend/src/views/website/website/config/basic/proxy/index.vue +
/// create/index.vue): a proxy rule list (name, match, target, status toggle,
/// edit, delete) plus an inline add/edit form with the basic section
/// (name, match, protocol+address composing proxyPass, proxyHost, SNI and
/// SSL verify when proxying over HTTPS), the cache section (server cache
/// switch with time+unit, browser cache enable/disable/noModify with
/// time+unit) and the embedded CORS section (switch, allowOrigins,
/// allowMethods, allowHeaders, allowCredentials, preflight).
///
/// Bridge mapping (contract: docs/development/modules/b1_website_channel_contract.md):
/// list via GetWebsiteProxiesAsync, save via UpdateWebsiteProxyAsync
/// (operate=create|edit), per-row delete via DeleteWebsiteProxyAsync and
/// status toggles via UpdateWebsiteProxyStatusAsync. Every write is
/// confirmed with ConfirmDialog (cancel is the default button) and its
/// result surfaces as an in-page InfoBar (red error / green success) because
/// the shared ErrorToast needs a page base class the tabs do not have.
///
/// Known contract deviations (documented, not fixable client-side):
/// - proxySSLName cannot be edited: the channel types it as bool while the
///   server expects a string; the tab sends null so the Dart handler falls
///   back to the upstream default "" (editing a proxy with a custom proxy
///   SSL name resets it).
/// - The update channel carries no "enable" field, so editing a disabled
///   proxy re-enables it (Dart side defaults enable to true, same as the
///   upstream create initData).
/// - "modifier" and "replaces" are not part of the channel contract and are
///   not editable in this batch.
/// </summary>
public static class WebsiteConfigProxyTab
{
    /// <summary>Upstream Units list (nginx time units, mimetype.ts).</summary>
    private static readonly string[] TimeUnits = { "s", "m", "h", "d", "w", "M", "y" };

    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        // ── Shared state (closure-captured; the tab is rebuilt per website) ──
        bool busy = false;
        bool suppressToggle = false;
        string? editingName = null; // null = create mode, otherwise the edited proxy name
        bool sniTouched = false;

        // ── Status / loading ──
        var status = new InfoBar { IsOpen = false, IsClosable = true };
        var loadingPanel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            Margin = new Thickness(4, 0, 0, 0),
        };
        loadingPanel.Children.Add(new ProgressRing { IsActive = true, Width = 16, Height = 16 });
        loadingPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("commonLoading", "Loading..."),
            FontSize = 12,
            VerticalAlignment = VerticalAlignment.Center,
        });

        // ── Root layout ──
        var root = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 0, 8),
        };
        var content = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Margin = new Thickness(8, 0, 8, 0),
            Spacing = 12,
        };

        // ── List card ──
        var refreshButton = new Button
        {
            Padding = new Thickness(8, 2, 8, 2),
            VerticalAlignment = VerticalAlignment.Center,
            Content = new FontIcon { Glyph = "\uE72C", FontSize = 14 },
        };
        ToolTipService.SetToolTip(refreshButton, L10n.T("commonRefresh", "Refresh"));
        // Click wiring intentionally deferred: the lambda reaches LoadAsync and
        // the form flows, so every local they capture must already be
        // definitely assigned here or CS0165 fires (wired below, after all
        // declarations).
        var listCard = ProxyCreateCard(L10n.T("hostProxyListTitle", "Proxy rules"), out var listPanel, refreshButton);

        // ── Form controls (shared by create and edit) ──
        var nameBox = new TextBox { PlaceholderText = "web-01" };
        var matchBox = new TextBox { Text = "/" };
        var protocolCombo = new ComboBox { MinWidth = 96 };
        protocolCombo.Items.Add(new ComboBoxItem { Content = "http", Tag = "http://" });
        protocolCombo.Items.Add(new ComboBoxItem { Content = "https", Tag = "https://" });
        protocolCombo.SelectedIndex = 0;
        var addressBox = new TextBox
        {
            PlaceholderText = L10n.T("hostProxyAddressPlaceholder", "e.g. 127.0.0.1:8080"),
        };
        var proxyHostBox = new TextBox { Text = "$host" };

        var sniSwitch = new ToggleSwitch { OnContent = "", OffContent = "", IsOn = false, HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, -8, 0, -8) };
        var sslVerifySwitch = new ToggleSwitch { OnContent = "", OffContent = "", IsOn = false, HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, -8, 0, -8) };
        var sniPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        sniPanel.Children.Add(ProxySwitchRow(
            L10n.T("hostProxySni", "SNI"),
            L10n.T("hostProxySniHelper", "Send the server name to the HTTPS upstream (proxy_ssl_server_name)."),
            sniSwitch));
        sniPanel.Children.Add(ProxySwitchRow(
            L10n.T("hostProxySslVerify", "SSL verify"),
            L10n.T("hostProxySslVerifyHelper", "Verify the upstream certificate when proxying over HTTPS."),
            sslVerifySwitch));

        var cacheSwitch = new ToggleSwitch { OnContent = "", OffContent = "", IsOn = false, HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, -8, 0, -8) };
        var serverCacheTimeBox = new TextBox { Text = "10" };
        var serverCacheUnitCombo = ProxyBuildUnitCombo("m");
        var serverCachePanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        serverCachePanel.Children.Add(ProxyFieldRow(
            L10n.T("hostProxyServerCacheTime", "Cache time"),
            ProxyBuildTimeRow(serverCacheTimeBox, serverCacheUnitCombo),
            L10n.T("hostProxyServerCacheTimeHelper", "How long upstream responses stay in the server cache.")));

        var browserCacheCombo = new ComboBox { MinWidth = 140, HorizontalAlignment = HorizontalAlignment.Left };
        browserCacheCombo.Items.Add(new ComboBoxItem { Content = L10n.T("commonEnable", "Enable"), Tag = "enable" });
        browserCacheCombo.Items.Add(new ComboBoxItem { Content = L10n.T("hostProxyDisable", "Disable"), Tag = "disable" });
        browserCacheCombo.Items.Add(new ComboBoxItem { Content = L10n.T("hostProxyBrowserCacheNoModify", "No modify"), Tag = "noModify" });
        browserCacheCombo.SelectedIndex = 2;
        var cacheTimeBox = new TextBox { Text = "4" };
        var cacheUnitCombo = ProxyBuildUnitCombo("h");
        var browserCachePanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        browserCachePanel.Children.Add(ProxyFieldRow(
            L10n.T("hostProxyBrowserCacheTime", "Cache time"),
            ProxyBuildTimeRow(cacheTimeBox, cacheUnitCombo),
            L10n.T("hostProxyBrowserCacheTimeHelper", "How long browsers may cache responses.")));

        var corsSwitch = new ToggleSwitch { OnContent = "", OffContent = "", IsOn = false, HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, -8, 0, -8) };
        var originsBox = new TextBox { Text = "*", PlaceholderText = "*" };
        var methodsBox = new TextBox { PlaceholderText = "GET,POST,OPTIONS,PUT,DELETE" };
        var headersBox = new TextBox { PlaceholderText = "X-Custom-Header" };
        var credentialsSwitch = new ToggleSwitch { OnContent = "", OffContent = "", IsOn = false, HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, -8, 0, -8) };
        var preflightSwitch = new ToggleSwitch { OnContent = "", OffContent = "", IsOn = true, HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, -8, 0, -8) };
        var corsPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        corsPanel.Children.Add(ProxyFieldRow(L10n.T("hostProxyAllowOrigins", "Allow origins"), originsBox));
        corsPanel.Children.Add(ProxyFieldRow(L10n.T("hostProxyAllowMethods", "Allow methods"), methodsBox));
        corsPanel.Children.Add(ProxyFieldRow(L10n.T("hostProxyAllowHeaders", "Allow headers"), headersBox));
        corsPanel.Children.Add(ProxySwitchRow(L10n.T("hostProxyAllowCredentials", "Allow credentials"), null, credentialsSwitch));
        corsPanel.Children.Add(ProxySwitchRow(L10n.T("hostProxyPreflight", "Preflight"), null, preflightSwitch));

        var saveButton = new Button { Padding = new Thickness(16, 5, 16, 5), Content = L10n.T("commonSave", "Save") };
        if (Application.Current.Resources.TryGetValue("AccentButtonStyle", out var accentStyle) && accentStyle is Style accent)
        {
            saveButton.Style = accent;
        }
        var cancelEditButton = new Button
        {
            Padding = new Thickness(12, 5, 12, 5),
            Content = L10n.T("hostProxyCancelEdit", "Cancel edit"),
            Visibility = Visibility.Collapsed,
        };

        // ── Form card (title swaps between add and edit) ──
        var formTitle = new TextBlock
        {
            Text = L10n.T("hostProxyAdd", "Add Proxy"),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        };
        var formCard = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = ProxyThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = ProxySubtleFill(),
        };
        var formPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        formPanel.Children.Add(formTitle);

        var nameMatchGrid = new Grid { ColumnSpacing = 12 };
        nameMatchGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        nameMatchGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        var nameField = ProxyFieldRow(L10n.T("commonName", "Name"), nameBox);
        var matchField = ProxyFieldRow(L10n.T("hostProxyMatch", "Proxy path"), matchBox);
        Grid.SetColumn(nameField, 0);
        Grid.SetColumn(matchField, 1);
        nameMatchGrid.Children.Add(nameField);
        nameMatchGrid.Children.Add(matchField);
        formPanel.Children.Add(nameMatchGrid);

        var protocolGrid = new Grid { ColumnSpacing = 8 };
        protocolGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        protocolGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        Grid.SetColumn(protocolCombo, 0);
        Grid.SetColumn(addressBox, 1);
        protocolGrid.Children.Add(protocolCombo);
        protocolGrid.Children.Add(addressBox);
        formPanel.Children.Add(ProxyFieldRow(
            L10n.T("hostProxyPass", "Target address"),
            protocolGrid,
            L10n.T("hostProxyPassHelper", "Upstream address the requests are forwarded to.")));
        formPanel.Children.Add(ProxyFieldRow(
            L10n.T("hostProxyHost", "Proxy host"),
            proxyHostBox,
            L10n.T("hostProxyHostHelper", "Host header sent upstream; $host keeps the original domain.")));
        formPanel.Children.Add(sniPanel);

        formPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostProxyCacheSection", "Cache"),
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            Margin = new Thickness(0, 6, 0, 0),
        });
        formPanel.Children.Add(ProxySwitchRow(L10n.T("hostProxyServerCache", "Server cache"), null, cacheSwitch));
        formPanel.Children.Add(serverCachePanel);
        formPanel.Children.Add(ProxyFieldRow(L10n.T("hostProxyBrowserCache", "Browser cache"), browserCacheCombo));
        formPanel.Children.Add(browserCachePanel);

        formPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostProxyCorsSection", "CORS"),
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            Margin = new Thickness(0, 6, 0, 0),
        });
        formPanel.Children.Add(ProxySwitchRow(L10n.T("hostProxyCors", "Enable CORS"), null, corsSwitch));
        formPanel.Children.Add(corsPanel);

        var buttonRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, Margin = new Thickness(0, 4, 0, 0) };
        buttonRow.Children.Add(saveButton);
        buttonRow.Children.Add(cancelEditButton);
        formPanel.Children.Add(buttonRow);
        formCard.Child = formPanel;

        content.Children.Add(new TextBlock
        {
            Text = websiteName,
            FontSize = 12,
            Foreground = ProxyThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        });
        content.Children.Add(status);
        content.Children.Add(loadingPanel);
        content.Children.Add(listCard);
        content.Children.Add(formCard);
        root.Content = content;

        // ── Field interactions ──
        protocolCombo.SelectionChanged += (s, e) =>
        {
            var isHttps = ProxyComboTag(protocolCombo) == "https://";
            sniPanel.Visibility = isHttps ? Visibility.Visible : Visibility.Collapsed;
            // Upstream auto-enables SNI when switching to https on create
            // unless the user touched the switch (watch on proxyProtocol).
            if (editingName == null && !sniTouched)
            {
                sniSwitch.IsOn = isHttps;
            }
        };
        addressBox.LostFocus += (s, e) =>
        {
            // Upstream getProxyHost: a domain target becomes the proxy host,
            // anything else falls back to $host.
            var address = addressBox.Text.Trim();
            proxyHostBox.Text = ProxyIsDomainTarget(address) ? address : "$host";
        };
        sniSwitch.Toggled += (s, e) => sniTouched = true;
        cacheSwitch.Toggled += (s, e) =>
        {
            serverCachePanel.Visibility = cacheSwitch.IsOn ? Visibility.Visible : Visibility.Collapsed;
            if (cacheSwitch.IsOn)
            {
                // Upstream changeServerCache(true) resets to 10 m.
                serverCacheTimeBox.Text = "10";
                ProxySelectComboByTag(serverCacheUnitCombo, "m");
            }
        };
        browserCacheCombo.SelectionChanged += (s, e) =>
        {
            var mode = ProxyComboTag(browserCacheCombo) ?? "noModify";
            browserCachePanel.Visibility = mode == "enable" ? Visibility.Visible : Visibility.Collapsed;
            if (mode == "enable")
            {
                // Upstream changeBrowserCache("enable") resets to 4 h.
                cacheTimeBox.Text = "4";
                ProxySelectComboByTag(cacheUnitCombo, "h");
            }
        };
        corsSwitch.Toggled += (s, e) =>
        {
            corsPanel.Visibility = corsSwitch.IsOn ? Visibility.Visible : Visibility.Collapsed;
            if (corsSwitch.IsOn)
            {
                // Upstream CorsSetting resets to its defaults when enabled.
                originsBox.Text = "*";
                methodsBox.Text = "";
                headersBox.Text = "";
                credentialsSwitch.IsOn = false;
                preflightSwitch.IsOn = true;
            }
        };
        cancelEditButton.Click += (s, e) => ResetForm();

        // ── Local handlers / flows ──

        void SetToggleSilently(ToggleSwitch toggle, bool isOn)
        {
            suppressToggle = true;
            try
            {
                toggle.IsOn = isOn;
            }
            finally
            {
                suppressToggle = false;
            }
        }

        async Task LoadAsync(bool showLoading)
        {
            if (busy) return;
            busy = true;
            if (showLoading)
            {
                loadingPanel.Visibility = Visibility.Visible;
                listCard.Visibility = Visibility.Collapsed;
            }

            var entries = ProxyParseList(await WindowsBridge.GetWebsiteProxiesAsync(websiteId));

            busy = false;
            loadingPanel.Visibility = Visibility.Collapsed;
            listCard.Visibility = Visibility.Visible;
            listPanel.Children.Clear();

            if (entries == null)
            {
                ProxySetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostProxyLoadFailed", "Failed to load the proxy list."));
                listPanel.Children.Add(ProxyEmptyHint());
                return;
            }

            if (entries.Count == 0)
            {
                listPanel.Children.Add(ProxyEmptyHint());
                return;
            }

            for (int i = 0; i < entries.Count; i++)
            {
                listPanel.Children.Add(BuildRow(entries[i]));
                if (i < entries.Count - 1)
                {
                    listPanel.Children.Add(new Border
                    {
                        Height = 1,
                        Background = ProxyThemeBrush("DividerStrokeColorDefaultBrush", Colors.Gray),
                        Opacity = 0.5,
                    });
                }
            }
        }

        FrameworkElement BuildRow(WebsiteConfigProxyEntry entry)
        {
            var row = new Grid { ColumnSpacing = 8, RowSpacing = 2, Margin = new Thickness(0, 2, 0, 2) };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            row.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            row.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            var nameBlock = new TextBlock
            {
                Text = string.IsNullOrWhiteSpace(entry.Name) ? "--" : entry.Name,
                FontSize = 14,
                FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                TextTrimming = TextTrimming.CharacterEllipsis,
                VerticalAlignment = VerticalAlignment.Center,
            };
            Grid.SetRow(nameBlock, 0);
            Grid.SetColumn(nameBlock, 0);
            row.Children.Add(nameBlock);

            // Edit is disabled for a disabled proxy, mirroring the upstream
            // buttons list (disabled when !row.enable).
            var editButton = new Button
            {
                Padding = new Thickness(8, 2, 8, 2),
                VerticalAlignment = VerticalAlignment.Center,
                FontSize = 12,
                Content = L10n.T("commonEdit", "Edit"),
                IsEnabled = entry.Enable,
            };
            editButton.Click += (s, e) => FillForm(entry);
            Grid.SetRow(editButton, 0);
            Grid.SetColumn(editButton, 1);
            row.Children.Add(editButton);

            var deleteButton = new Button
            {
                Padding = new Thickness(8, 2, 8, 2),
                VerticalAlignment = VerticalAlignment.Center,
                FontSize = 12,
                Content = L10n.T("commonDelete", "Delete"),
            };
            deleteButton.Click += async (s, e) =>
            {
                if (busy) return;
                var xamlRoot = root.XamlRoot;
                if (xamlRoot == null) return;

                var confirmed = await ConfirmDialog.ShowAsync(
                    xamlRoot,
                    L10n.T("hostProxyDeleteConfirmTitle", "Delete proxy"),
                    string.Format(
                        L10n.T("hostProxyDeleteConfirmMessage", "Delete proxy \"{0}\"? The proxy config file will be removed."),
                        entry.Name),
                    L10n.T("commonDelete", "Delete"),
                    L10n.T("commonCancel", "Cancel"),
                    isDestructive: true);
                if (!confirmed) return;

                busy = true;
                var id = entry.Id < 0 ? websiteId : (int)entry.Id;
                var ok = await WindowsBridge.DeleteWebsiteProxyAsync(id, entry.Name);
                busy = false;
                if (ok)
                {
                    ProxySetStatus(status, InfoBarSeverity.Success,
                        L10n.T("hostProxyDeleted", "Proxy deleted."));
                    await LoadAsync(showLoading: false);
                }
                else
                {
                    ProxySetStatus(status, InfoBarSeverity.Error,
                        L10n.T("hostProxyDeleteFailed", "Failed to delete the proxy."));
                }
            };
            Grid.SetRow(deleteButton, 0);
            Grid.SetColumn(deleteButton, 2);
            row.Children.Add(deleteButton);

            var toggle = new ToggleSwitch
            {
                OnContent = "",
                OffContent = "",
                IsOn = entry.Enable,
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(8, -8, 0, -8),
            };
            ToolTipService.SetToolTip(toggle, entry.Enable
                ? L10n.T("hostProxyDisable", "Disable")
                : L10n.T("commonEnable", "Enable"));
            toggle.Toggled += async (s, e) =>
            {
                if (suppressToggle) return;
                var enable = toggle.IsOn;
                if (busy)
                {
                    SetToggleSilently(toggle, !enable);
                    return;
                }
                var xamlRoot = root.XamlRoot;
                if (xamlRoot == null) return;

                var confirmed = await ConfirmDialog.ShowAsync(
                    xamlRoot,
                    L10n.T(enable ? "hostProxyEnableConfirmTitle" : "hostProxyDisableConfirmTitle",
                        enable ? "Enable proxy" : "Disable proxy"),
                    string.Format(
                        L10n.T(enable ? "hostProxyEnableConfirmMessage" : "hostProxyDisableConfirmMessage",
                            enable ? "Enable proxy \"{0}\"?" : "Disable proxy \"{0}\"?"),
                        entry.Name),
                    L10n.T(enable ? "commonEnable" : "hostProxyDisable", enable ? "Enable" : "Disable"),
                    L10n.T("commonCancel", "Cancel"));
                if (!confirmed)
                {
                    SetToggleSilently(toggle, !enable);
                    return;
                }

                busy = true;
                var id = entry.Id < 0 ? websiteId : (int)entry.Id;
                var ok = await WindowsBridge.UpdateWebsiteProxyStatusAsync(id, entry.Name, enable ? "enable" : "disable");
                busy = false;
                if (ok)
                {
                    ProxySetStatus(status, InfoBarSeverity.Success,
                        L10n.T("hostProxyStatusUpdated", "Proxy status updated."));
                    await LoadAsync(showLoading: false);
                }
                else
                {
                    SetToggleSilently(toggle, !enable);
                    ProxySetStatus(status, InfoBarSeverity.Error,
                        L10n.T("hostProxyStatusFailed", "Failed to update the proxy status."));
                }
            };
            Grid.SetRow(toggle, 0);
            Grid.SetColumn(toggle, 3);
            row.Children.Add(toggle);

            var passBlock = new TextBlock
            {
                Text = $"{(string.IsNullOrWhiteSpace(entry.Match) ? "/" : entry.Match)} \u2192 {(string.IsNullOrWhiteSpace(entry.ProxyPass) ? "--" : entry.ProxyPass)}",
                FontSize = 12,
                Foreground = ProxyThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
            };
            Grid.SetRow(passBlock, 1);
            Grid.SetColumn(passBlock, 0);
            Grid.SetColumnSpan(passBlock, 4);
            row.Children.Add(passBlock);

            var summary = ProxyRowSummary(entry);
            if (summary.Length > 0)
            {
                var summaryBlock = new TextBlock
                {
                    Text = summary,
                    FontSize = 11,
                    Foreground = ProxyThemeBrush("TextFillColorTertiaryBrush", Colors.Gray),
                    TextTrimming = TextTrimming.CharacterEllipsis,
                };
                Grid.SetRow(summaryBlock, 2);
                Grid.SetColumn(summaryBlock, 0);
                Grid.SetColumnSpan(summaryBlock, 4);
                row.Children.Add(summaryBlock);
            }

            return row;
        }

        void FillForm(WebsiteConfigProxyEntry entry)
        {
            editingName = entry.Name;
            formTitle.Text = L10n.T("hostProxyEditTitle", "Edit Proxy");
            cancelEditButton.Visibility = Visibility.Visible;

            nameBox.Text = entry.Name;
            nameBox.IsEnabled = false; // upstream disables the name input while editing
            matchBox.Text = entry.Match;

            // Split proxyPass back into protocol + address (upstream getProtocolAndHost).
            var pass = entry.ProxyPass ?? "";
            if (pass.StartsWith("https://", StringComparison.Ordinal))
            {
                ProxySelectComboByTag(protocolCombo, "https://");
                addressBox.Text = pass["https://".Length..];
            }
            else if (pass.StartsWith("http://", StringComparison.Ordinal))
            {
                ProxySelectComboByTag(protocolCombo, "http://");
                addressBox.Text = pass["http://".Length..];
            }
            else
            {
                ProxySelectComboByTag(protocolCombo, "http://");
                addressBox.Text = pass;
            }
            proxyHostBox.Text = string.IsNullOrWhiteSpace(entry.ProxyHost) ? "$host" : entry.ProxyHost;
            sniSwitch.IsOn = entry.Sni;
            sslVerifySwitch.IsOn = entry.SslVerify;
            sniPanel.Visibility = ProxyComboTag(protocolCombo) == "https://"
                ? Visibility.Visible
                : Visibility.Collapsed;

            cacheSwitch.IsOn = entry.Cache;
            serverCacheTimeBox.Text = entry.ServerCacheTime > 0 ? entry.ServerCacheTime.ToString() : "10";
            ProxySelectComboByTag(serverCacheUnitCombo,
                string.IsNullOrEmpty(entry.ServerCacheUnit) ? "m" : entry.ServerCacheUnit);

            // Upstream acceptParams derives the browser cache mode from the
            // cacheTime sign: >0 enable, =0 noModify, <0 disable.
            var browserMode = entry.CacheTime > 0 ? "enable" : entry.CacheTime == 0 ? "noModify" : "disable";
            ProxySelectComboByTag(browserCacheCombo, browserMode);
            cacheTimeBox.Text = entry.CacheTime > 0 ? entry.CacheTime.ToString() : "4";
            ProxySelectComboByTag(cacheUnitCombo,
                entry.CacheTime > 0 && !string.IsNullOrEmpty(entry.CacheUnit) ? entry.CacheUnit : "h");

            corsSwitch.IsOn = entry.Cors;
            originsBox.Text = entry.AllowOrigins;
            methodsBox.Text = entry.AllowMethods;
            headersBox.Text = entry.AllowHeaders;
            credentialsSwitch.IsOn = entry.AllowCredentials;
            preflightSwitch.IsOn = entry.Preflight;
            corsPanel.Visibility = entry.Cors ? Visibility.Visible : Visibility.Collapsed;
        }

        void ResetForm()
        {
            editingName = null;
            formTitle.Text = L10n.T("hostProxyAdd", "Add Proxy");
            cancelEditButton.Visibility = Visibility.Collapsed;

            nameBox.Text = "";
            nameBox.IsEnabled = true;
            matchBox.Text = "/";
            ProxySelectComboByTag(protocolCombo, "http://");
            addressBox.Text = "";
            proxyHostBox.Text = "$host";
            sniSwitch.IsOn = false;
            sslVerifySwitch.IsOn = false;
            cacheSwitch.IsOn = false;
            serverCacheTimeBox.Text = "10";
            ProxySelectComboByTag(serverCacheUnitCombo, "m");
            ProxySelectComboByTag(browserCacheCombo, "noModify");
            cacheTimeBox.Text = "4";
            ProxySelectComboByTag(cacheUnitCombo, "h");
            corsSwitch.IsOn = false;
            originsBox.Text = "*";
            methodsBox.Text = "";
            headersBox.Text = "";
            credentialsSwitch.IsOn = false;
            preflightSwitch.IsOn = true;
            sniPanel.Visibility = Visibility.Collapsed;
            serverCachePanel.Visibility = Visibility.Collapsed;
            browserCachePanel.Visibility = Visibility.Collapsed;
            corsPanel.Visibility = Visibility.Collapsed;
            // Last: the switch resets above fire Toggled synchronously and
            // would re-mark sniTouched, so clear the touch flag afterwards.
            sniTouched = false;
        }

        async Task SaveAsync()
        {
            if (busy) return;
            var xamlRoot = root.XamlRoot;
            if (xamlRoot == null) return;

            var name = nameBox.Text.Trim();
            var match = matchBox.Text.Trim();
            var address = addressBox.Text.Trim();
            var host = proxyHostBox.Text.Trim();
            var protocol = ProxyComboTag(protocolCombo) ?? "http://";
            var isHttps = protocol == "https://";

            if (name.Length == 0)
            {
                ProxySetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostProxyNameRequired", "Name is required."));
                return;
            }
            if (match.Length == 0)
            {
                ProxySetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostProxyMatchRequired", "Proxy path is required."));
                return;
            }
            if (address.Length == 0)
            {
                ProxySetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostProxyAddressRequired", "Target address is required."));
                return;
            }
            if (host.Length == 0)
            {
                ProxySetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostProxyHostRequired", "Proxy host is required."));
                return;
            }

            long serverCacheTime = 0;
            var serverCacheUnit = "";
            if (cacheSwitch.IsOn)
            {
                if (!ProxyTryParseCacheTime(serverCacheTimeBox.Text, out serverCacheTime))
                {
                    ProxySetStatus(status, InfoBarSeverity.Error,
                        L10n.T("hostProxyCacheTimeInvalid", "Cache time must be a number between 1 and 65535."));
                    return;
                }
                serverCacheUnit = ProxyComboTag(serverCacheUnitCombo) ?? "m";
            }

            var browserCache = ProxyComboTag(browserCacheCombo) ?? "noModify";
            long cacheTime = 0;
            var cacheUnit = "";
            if (browserCache == "enable")
            {
                if (!ProxyTryParseCacheTime(cacheTimeBox.Text, out cacheTime))
                {
                    ProxySetStatus(status, InfoBarSeverity.Error,
                        L10n.T("hostProxyCacheTimeInvalid", "Cache time must be a number between 1 and 65535."));
                    return;
                }
                cacheUnit = ProxyComboTag(cacheUnitCombo) ?? "h";
            }
            else if (browserCache == "disable")
            {
                cacheTime = -1; // upstream changeBrowserCache("disable") stores -1
            }

            var origins = originsBox.Text.Trim();
            var methods = methodsBox.Text.Trim();
            var headers = headersBox.Text.Trim();
            if (corsSwitch.IsOn && origins.Length == 0)
            {
                ProxySetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostProxyOriginsRequired", "Allow origins is required when CORS is enabled."));
                return;
            }

            busy = true;
            saveButton.IsEnabled = false;
            bool ok;
            try
            {
                ok = await WindowsBridge.UpdateWebsiteProxyAsync(
                    websiteId,
                    editingName == null ? "create" : "edit",
                    name,
                    match,
                    protocol,
                    address,
                    host,
                    isHttps && sniSwitch.IsOn,
                    // proxySSLName is typed bool by the channel while the server
                    // expects a string; null lets Dart send the upstream "" default.
                    proxySSLName: null,
                    isHttps && sslVerifySwitch.IsOn,
                    cacheSwitch.IsOn,
                    serverCacheTime,
                    serverCacheUnit,
                    browserCache,
                    cacheTime,
                    cacheUnit,
                    corsSwitch.IsOn,
                    origins,
                    methods,
                    headers,
                    corsSwitch.IsOn && credentialsSwitch.IsOn,
                    corsSwitch.IsOn && preflightSwitch.IsOn);
            }
            finally
            {
                busy = false;
                saveButton.IsEnabled = true;
            }

            if (ok)
            {
                ProxySetStatus(status, InfoBarSeverity.Success,
                    L10n.T(editingName == null ? "hostProxyCreated" : "hostProxySaved",
                        editingName == null ? "Proxy created." : "Proxy saved."));
                ResetForm();
                await LoadAsync(showLoading: false);
            }
            else
            {
                ProxySetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostProxySaveFailed", "Failed to save the proxy."));
            }
        }

        saveButton.Click += async (s, e) => await SaveAsync();
        refreshButton.Click += (s, e) => _ = LoadAsync(showLoading: true);

        ResetForm();
        _ = LoadAsync(showLoading: true);
        return root;
    }

    /// <summary>Third row summary: cache windows and CORS flag, " · " joined.</summary>
    private static string ProxyRowSummary(WebsiteConfigProxyEntry entry)
    {
        var parts = new List<string>();
        if (entry.Cache && entry.ServerCacheTime > 0)
        {
            parts.Add($"{L10n.T("hostProxyServerCache", "Server cache")} {entry.ServerCacheTime}{entry.ServerCacheUnit}");
        }
        if (entry.CacheTime > 0)
        {
            parts.Add($"{L10n.T("hostProxyBrowserCache", "Browser cache")} {entry.CacheTime}{entry.CacheUnit}");
        }
        else if (entry.CacheTime < 0)
        {
            parts.Add($"{L10n.T("hostProxyBrowserCache", "Browser cache")} {L10n.T("hostProxyDisabled", "disabled")}");
        }
        if (entry.Cors)
        {
            parts.Add("CORS");
        }
        return string.Join(" \u00B7 ", parts);
    }

    private static FrameworkElement ProxyEmptyHint()
    {
        return new TextBlock
        {
            Text = L10n.T("hostProxyEmpty", "No proxy rules yet."),
            FontSize = 12,
            Foreground = ProxyThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        };
    }

    private static void ProxySetStatus(InfoBar bar, InfoBarSeverity severity, string message)
    {
        bar.Severity = severity;
        bar.Message = message;
        bar.IsOpen = true;
    }

    private static ComboBox ProxyBuildUnitCombo(string defaultUnit)
    {
        var combo = new ComboBox { MinWidth = 84, HorizontalAlignment = HorizontalAlignment.Left };
        foreach (var unit in TimeUnits)
        {
            combo.Items.Add(new ComboBoxItem { Content = unit, Tag = unit });
        }
        ProxySelectComboByTag(combo, defaultUnit);
        return combo;
    }

    private static FrameworkElement ProxyBuildTimeRow(TextBox box, ComboBox unitCombo)
    {
        var grid = new Grid { ColumnSpacing = 8 };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(160) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(box, 0);
        Grid.SetColumn(unitCombo, 1);
        grid.Children.Add(box);
        grid.Children.Add(unitCombo);
        return grid;
    }

    /// <summary>A domain target keeps dots, has no port/scheme separators and
    /// is not an IPv4 literal (upstream isDomain heuristic, simplified).</summary>
    private static bool ProxyIsDomainTarget(string address)
    {
        if (string.IsNullOrWhiteSpace(address) || !address.Contains('.'))
        {
            return false;
        }
        if (address.Contains(':') || address.Contains('/'))
        {
            return false;
        }
        foreach (var part in address.Split('.'))
        {
            foreach (var ch in part)
            {
                if (!char.IsAsciiDigit(ch))
                {
                    return true;
                }
            }
        }
        return false; // all-numeric dot groups: IPv4 literal
    }

    private static bool ProxyTryParseCacheTime(string text, out long value)
    {
        if (!long.TryParse(text.Trim(), out value))
        {
            return false;
        }
        return value is >= 1 and <= 65535; // upstream checkNumberRange(1, 65535)
    }

    private static string? ProxyComboTag(ComboBox combo)
    {
        return (combo.SelectedItem as ComboBoxItem)?.Tag as string;
    }

    private static void ProxySelectComboByTag(ComboBox combo, string tag)
    {
        foreach (var item in combo.Items)
        {
            if (item is ComboBoxItem box && string.Equals(box.Tag as string, tag, StringComparison.Ordinal))
            {
                combo.SelectedItem = box;
                return;
            }
        }
    }

    private static List<WebsiteConfigProxyEntry>? ProxyParseList(JsonElement? element)
    {
        if (element is not JsonElement json || json.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        var list = new List<WebsiteConfigProxyEntry>();
        foreach (var item in json.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.Object) continue;

            list.Add(new WebsiteConfigProxyEntry
            {
                Id = ProxyTryGetLong(item, "id", -1),
                Name = ProxyTryGetString(item, "name") ?? "",
                Match = ProxyTryGetString(item, "match") ?? "/",
                ProxyPass = ProxyTryGetString(item, "proxyPass") ?? "",
                ProxyHost = ProxyTryGetString(item, "proxyHost") ?? "",
                Enable = ProxyTryGetBool(item, "enable", true),
                Sni = ProxyTryGetBool(item, "sni", false),
                SslVerify = ProxyTryGetBool(item, "sslVerify", false),
                Cache = ProxyTryGetBool(item, "cache", false),
                ServerCacheTime = ProxyTryGetLong(item, "serverCacheTime", 0),
                ServerCacheUnit = ProxyTryGetString(item, "serverCacheUnit") ?? "",
                CacheTime = ProxyTryGetLong(item, "cacheTime", 0),
                CacheUnit = ProxyTryGetString(item, "cacheUnit") ?? "",
                Cors = ProxyTryGetBool(item, "cors", false),
                AllowOrigins = ProxyTryGetString(item, "allowOrigins") ?? "",
                AllowMethods = ProxyTryGetString(item, "allowMethods") ?? "",
                AllowHeaders = ProxyTryGetString(item, "allowHeaders") ?? "",
                AllowCredentials = ProxyTryGetBool(item, "allowCredentials", false),
                Preflight = ProxyTryGetBool(item, "preflight", false),
            });
        }

        return list;
    }

    private static string? ProxyTryGetString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static long ProxyTryGetLong(JsonElement element, string property, long fallback)
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

    private static bool ProxyTryGetBool(JsonElement element, string property, bool fallback)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop))
        {
            if (prop.ValueKind == JsonValueKind.True) return true;
            if (prop.ValueKind == JsonValueKind.False) return false;
        }
        return fallback;
    }

    /// <summary>Label-over-control row with optional helper line (upstream
    /// label-position top form items with input-help).</summary>
    private static FrameworkElement ProxyFieldRow(string label, FrameworkElement control, string? help = null)
    {
        var panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 4 };
        panel.Children.Add(new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = ProxyThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
        });
        panel.Children.Add(control);
        if (help != null)
        {
            panel.Children.Add(new TextBlock
            {
                Text = help,
                FontSize = 11,
                Foreground = ProxyThemeBrush("TextFillColorTertiaryBrush", Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
            });
        }
        return panel;
    }

    /// <summary>Title+help caption on the left, switch on the trailing edge.</summary>
    private static FrameworkElement ProxySwitchRow(string title, string? help, ToggleSwitch toggle)
    {
        var textPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 2 };
        textPanel.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.Medium,
            TextWrapping = TextWrapping.Wrap,
        });
        if (help != null)
        {
            textPanel.Children.Add(new TextBlock
            {
                Text = help,
                FontSize = 11,
                Foreground = ProxyThemeBrush("TextFillColorTertiaryBrush", Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
            });
        }

        var grid = new Grid { ColumnSpacing = 8 };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(textPanel, 0);
        Grid.SetColumn(toggle, 1);
        grid.Children.Add(textPanel);
        grid.Children.Add(toggle);
        return grid;
    }

    /// <summary>Card shell shared with SecurityGatewayPage: transparent-ish
    /// fill, CardStroke border, rounded corners, semi-bold title and an
    /// optional trailing header action.</summary>
    private static FrameworkElement ProxyCreateCard(
        string title, out StackPanel panel, FrameworkElement? headerAction = null)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = ProxyThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = ProxySubtleFill(),
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

    private static Brush ProxyThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Brush ProxySubtleFill()
    {
        var stroke = ProxyThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}

/// <summary>Immutable view over one proxy config row from the bridge.</summary>
internal sealed class WebsiteConfigProxyEntry
{
    public long Id { get; init; } = -1;
    public string Name { get; init; } = "";
    public string Match { get; init; } = "/";
    public string ProxyPass { get; init; } = "";
    public string ProxyHost { get; init; } = "";
    public bool Enable { get; init; } = true;
    public bool Sni { get; init; }
    public bool SslVerify { get; init; }
    public bool Cache { get; init; }
    public long ServerCacheTime { get; init; }
    public string ServerCacheUnit { get; init; } = "";
    public long CacheTime { get; init; }
    public string CacheUnit { get; init; } = "";
    public bool Cors { get; init; }
    public string AllowOrigins { get; init; } = "";
    public string AllowMethods { get; init; } = "";
    public string AllowHeaders { get; init; } = "";
    public bool AllowCredentials { get; init; }
    public bool Preflight { get; init; }
}
