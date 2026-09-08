using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// B1 网站配置中心 · 域名 Tab。语义照搬上游
/// views/website/website/config/basic/domain/index.vue 与 domain-create/index.vue：
/// - 域名列表（domain / port / ssl 三列），仅剩一条域名时禁用删除（上游
///   data.length == 1 的禁用语义）；删除走 ConfirmDialog → DeleteWebsiteDomainAsync；
/// - 「添加域名」表单：多行文本框（每行一个域名，共享 port / ssl，对应上游
///   批量输入语义的简化版）+ 端口（默认 80）+ SSL 开关 → AddWebsiteDomainsAsync。
/// 与上游的偏差：列表 SSL 列为只读展示（通道契约未提供 updateWebsiteDomain），
/// 不提供行内打开站点按钮（不在本批能力范围）。
/// </summary>
public static class WebsiteConfigDomainsTab
{
    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        var toast = new ErrorToast();
        var statusText = WebsiteConfigHelpers.StatusText();
        var loadErrorInfo = new InfoBar
        {
            Severity = InfoBarSeverity.Error,
            IsClosable = false,
            IsOpen = false,
            Message = L10n.T("hostDomainsLoadFailed", "Failed to load domains."),
        };
        var listHost = new StackPanel { Orientation = Orientation.Vertical, Spacing = 4 };
        bool isBusy = false;

        // ── 添加域名表单（批量：每行一个域名，共享 port/ssl） ──
        var batchBox = WebsiteConfigHelpers.BuildTextBox(
            L10n.T("websitesDomainBatchInputLabel", "Domains"),
            multiline: true,
            minHeight: 96);
        batchBox.PlaceholderText = L10n.T("hostDomainsInputHint",
            "One domain per line. All entries share the port and SSL option below.");

        var portBox = new TextBox { Header = L10n.T("commonPort", "Port"), Text = "80", Width = 140 };
        var sslToggle = WebsiteConfigHelpers.BuildToggle(false);
        var sslHeader = new TextBlock
        {
            Text = L10n.T("websitesDomainSslLabel", "SSL"),
            FontSize = 12,
            Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Colors.Gray),
        };
        var sslHost = new StackPanel { Orientation = Orientation.Vertical, Spacing = 4 };
        sslHost.Children.Add(sslHeader);
        sslHost.Children.Add(sslToggle);

        var portSslRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 24 };
        portSslRow.Children.Add(portBox);
        portSslRow.Children.Add(sslHost);

        var addButton = new Button
        {
            Content = L10n.T("commonAdd", "Add"),
            Style = (Style)Application.Current.Resources["AccentButtonStyle"],
        };
        addButton.Click += async (s, e) => await AddDomainsAsync();

        async Task AddDomainsAsync()
        {
            if (isBusy) return;

            // 校验：至少一个域名 + 端口 1-65535（复用既有 arb 文案键）。
            var lines = new List<string>();
            foreach (var raw in batchBox.Text.Split(new[] { '\r', '\n' }))
            {
                var line = raw.Trim();
                if (line.Length > 0)
                {
                    lines.Add(line);
                }
            }
            if (lines.Count == 0)
            {
                WebsiteConfigHelpers.SetStatus(
                    statusText,
                    L10n.T("hostDomainsInputRequired", "Enter at least one domain."),
                    error: true);
                return;
            }
            var portText = portBox.Text.Trim();
            if (!long.TryParse(portText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var port) ||
                port < 1 || port > 65535)
            {
                WebsiteConfigHelpers.SetStatus(
                    statusText,
                    L10n.T("websitesDomainValidationPort", "Port must be between 1 and 65535."),
                    error: true);
                return;
            }
            WebsiteConfigHelpers.SetStatus(statusText, null);

            // 契约扁平结构：domains 元素形如 {domain, port, ssl}。
            var domains = new List<object>();
            foreach (var line in lines)
            {
                domains.Add(new Dictionary<string, object?>
                {
                    ["domain"] = line,
                    ["port"] = port,
                    ["ssl"] = sslToggle.IsOn,
                });
            }

            var xamlRoot = WebsiteConfigHelpers.GetXamlRoot(addButton);
            if (xamlRoot == null) return;

            isBusy = true;
            addButton.IsEnabled = false;
            try
            {
                var ok = await WindowsBridge.AddWebsiteDomainsAsync(websiteId, domains);
                if (ok)
                {
                    batchBox.Text = string.Empty;
                    sslToggle.IsOn = false;
                    WebsiteConfigHelpers.SetStatus(
                        statusText, L10n.T("hostDomainsAddSuccess", "Domains added."));
                    await LoadDomainsAsync(firstLoad: false);
                }
                else
                {
                    toast.Show(L10n.T("hostDomainsAddFailed", "Failed to add domains."));
                }
            }
            finally
            {
                isBusy = false;
                addButton.IsEnabled = true;
            }
        }

        // ── 域名列表（domain / port / ssl 三列 + 行删除） ──
        FrameworkElement BuildHeaderRow()
        {
            var header = new Grid { Margin = new Thickness(12, 0, 12, 4) };
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(72) });

            AddHeaderText(header, 0, L10n.T("websitesDomainLabel", "Domain"));
            AddHeaderText(header, 1, L10n.T("commonPort", "Port"));
            AddHeaderText(header, 2, L10n.T("websitesDomainSslLabel", "SSL"));
            AddHeaderText(header, 3, L10n.T("hostDomainsActionsLabel", "Actions"));
            return header;
        }

        FrameworkElement BuildDomainRow(DomainEntry entry, bool isLastRow)
        {
            var row = new Grid { Padding = new Thickness(12, 6, 12, 6) };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(72) });

            var domainBlock = new TextBlock
            {
                Text = entry.Domain,
                FontSize = 13,
                VerticalAlignment = VerticalAlignment.Center,
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            };
            Grid.SetColumn(domainBlock, 0);
            row.Children.Add(domainBlock);

            var portBlock = new TextBlock
            {
                Text = entry.Port.ToString(CultureInfo.InvariantCulture),
                FontSize = 13,
                VerticalAlignment = VerticalAlignment.Center,
            };
            Grid.SetColumn(portBlock, 1);
            row.Children.Add(portBlock);

            var sslBlock = new TextBlock
            {
                Text = entry.Ssl ? L10n.T("commonYes", "Yes") : L10n.T("commonNo", "No"),
                FontSize = 13,
                VerticalAlignment = VerticalAlignment.Center,
            };
            Grid.SetColumn(sslBlock, 2);
            row.Children.Add(sslBlock);

            var deleteButton = new Button
            {
                Content = new FontIcon { Glyph = "\uE74D", FontSize = 14 },
                Padding = new Thickness(8, 4, 8, 4),
                VerticalAlignment = VerticalAlignment.Center,
                IsEnabled = !isLastRow, // 上游语义：仅剩一条域名时禁用删除
            };
            ToolTipService.SetToolTip(
                deleteButton,
                isLastRow
                    ? L10n.T("hostDomainsLastDeleteDisabled", "At least one domain must remain.")
                    : L10n.T("hostDomainsDeleteTitle", "Delete domain"));
            deleteButton.Click += async (s, e) => await DeleteDomainAsync(entry);
            Grid.SetColumn(deleteButton, 3);
            row.Children.Add(deleteButton);

            return row;
        }

        async Task DeleteDomainAsync(DomainEntry entry)
        {
            if (isBusy) return;

            var xamlRoot = WebsiteConfigHelpers.GetXamlRoot(listHost);
            if (xamlRoot == null) return;

            // 上游 opDialog 语义：删除前确认并点名域名。
            var confirmed = await ConfirmDialog.ShowAsync(
                xamlRoot,
                L10n.T("hostDomainsDeleteTitle", "Delete domain"),
                string.Format(
                    L10n.T("hostDomainsDeleteConfirm", "Delete domain \"{0}\"? This action cannot be undone."),
                    entry.Domain),
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);
            if (!confirmed) return;

            isBusy = true;
            try
            {
                var ok = await WindowsBridge.DeleteWebsiteDomainAsync((int)entry.Id);
                if (ok)
                {
                    WebsiteConfigHelpers.SetStatus(
                        statusText, L10n.T("hostDomainsDeleteSuccess", "Domain deleted."));
                    await LoadDomainsAsync(firstLoad: false);
                }
                else
                {
                    toast.Show(L10n.T("hostDomainsDeleteFailed", "Failed to delete domain."));
                }
            }
            finally
            {
                isBusy = false;
            }
        }

        async Task LoadDomainsAsync(bool firstLoad)
        {
            if (firstLoad)
            {
                loadErrorInfo.IsOpen = false;
            }

            var result = await WindowsBridge.GetWebsiteDomainsAsync(websiteId);
            if (result == null)
            {
                if (firstLoad)
                {
                    loadErrorInfo.IsOpen = true;
                }
                else
                {
                    toast.Show(L10n.T("hostDomainsLoadFailed", "Failed to load domains."));
                }
                return;
            }

            var entries = new List<DomainEntry>();
            if (result.Value.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in result.Value.EnumerateArray())
                {
                    if (item.ValueKind != JsonValueKind.Object) continue;
                    entries.Add(new DomainEntry
                    {
                        Id = WebsiteConfigHelpers.TryGetLong(item, "id", 0),
                        Domain = WebsiteConfigHelpers.TryGetString(item, "domain") ?? "",
                        Port = WebsiteConfigHelpers.TryGetLong(item, "port", 80),
                        Ssl = WebsiteConfigHelpers.TryGetBool(item, "ssl", false),
                    });
                }
            }

            listHost.Children.Clear();
            if (entries.Count == 0)
            {
                listHost.Children.Add(new TextBlock
                {
                    Text = L10n.T("websitesDomainEmpty", "No domains"),
                    FontSize = 13,
                    Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Colors.Gray),
                    Margin = new Thickness(12, 4, 0, 4),
                });
            }
            else
            {
                listHost.Children.Add(BuildHeaderRow());
                for (int i = 0; i < entries.Count; i++)
                {
                    // 行间分隔线：第一行不加（表头自带下边距）。
                    if (i > 0)
                    {
                        listHost.Children.Add(new Border
                        {
                            BorderBrush = new Microsoft.UI.Xaml.Media.SolidColorBrush(Colors.Gray),
                            Opacity = 0.2,
                            BorderThickness = new Thickness(0, 0, 0, 1),
                        });
                    }
                    listHost.Children.Add(BuildDomainRow(entries[i], isLastRow: entries.Count == 1));
                }
            }
        }

        // ── 布局：添加表单卡片 + 列表卡片 ──
        var addCard = WebsiteConfigHelpers.BuildCard(
            L10n.T("websitesDomainAddTitle", "Add domain"), out var addPanel);
        addPanel.Children.Add(batchBox);
        addPanel.Children.Add(portSslRow);
        var addRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
        addRow.Children.Add(addButton);
        addRow.Children.Add(statusText);
        addPanel.Children.Add(addRow);

        var listCard = WebsiteConfigHelpers.BuildCard(
            L10n.T("websitesDomainsPageTitle", "Domains"), out var listPanel);
        listPanel.Children.Add(loadErrorInfo);
        // 表头由 LoadDomainsAsync 连同行一起重建（空态不显示表头）。
        listPanel.Children.Add(listHost);

        var column = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
        column.Children.Add(listCard);
        column.Children.Add(addCard);

        var scroll = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(4, 0, 12, 12),
            Content = column,
        };

        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        Grid.SetRow(scroll, 0);
        root.Children.Add(scroll);
        toast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(toast, 1);
        root.Children.Add(toast);

        _ = LoadDomainsAsync(firstLoad: true);
        return root;
    }

    /// <summary>表头单元格文本。</summary>
    private static void AddHeaderText(Grid header, int column, string text)
    {
        var block = new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Colors.Gray),
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(block, column);
        header.Children.Add(block);
    }

    /// <summary>一行域名记录（GetWebsiteDomainsAsync 数组元素）。</summary>
    private sealed class DomainEntry
    {
        public long Id { get; init; }
        public string Domain { get; init; } = "";
        public long Port { get; init; } = 80;
        public bool Ssl { get; init; }
    }
}
