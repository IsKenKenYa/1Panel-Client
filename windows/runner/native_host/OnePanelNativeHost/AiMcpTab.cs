using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native AI module - MCP servers tab (upstream
/// frontend/src/views/ai/mcp/server/index.vue + operate/index.vue).
///
/// One transparent list card (name / external URL / status / operations):
/// start|stop with the label following the current status, restart, a
/// connection test whose result surfaces in an InfoBar, and a destructive
/// delete confirmation, plus the "sync status" bulk action over all listed
/// ids. The collapsible create form mirrors the upstream drawer: name,
/// type (npx|uvx), multi-line run script, protocol+url base address,
/// output transport (sse|streamableHttp with the matching path field),
/// gateway image, container name, port and host IP. Typing a name
/// auto-fills the container name and both transport paths and switching
/// the type keeps the default gateway image (upstream watchers).
///
/// Data flows through WindowsBridge (GetMcpServersAsync /
/// CreateMcpServerAsync / OperateMcpServerAsync / TestMcpConnectionAsync /
/// DeleteMcpServerAsync / SyncMcpStatusAsync). Self-contained: helpers
/// carry the McpTab prefix. Bridge contract notes: the Dart channel maps
/// the bridge "url" field straight to the upstream baseUrl and ignores
/// "protocol", so the tab concatenates protocol+url before the call;
/// test-connection returns a bool only, so the result InfoBar shows a
/// generic localized message instead of the server-provided text
/// (upstream shows res.data.message).
/// </summary>
public static class AiMcpTab
{
    private const string GatewayImageNpx = "supercorp/supergateway:3.4.3";
    private const string GatewayImageUvx = "supercorp/supergateway:uvx";
    private const int PageSize = 100;

    public static FrameworkElement Build()
    {
        var errorToast = new ErrorToast();
        var busyGuard = false;
        var servers = new List<McpTabServerEntry>();

        // ── Status surfaces ──────────────────────────────────────────────
        var noticeBar = new InfoBar
        {
            Severity = InfoBarSeverity.Success,
            IsClosable = true,
            IsOpen = false,
            Margin = new Thickness(8, 8, 8, 0),
        };
        var errorRow = McpTabErrorRow(out var loadErrorBar, out var retryButton);
        var loadingRing = new ProgressRing
        {
            IsActive = true,
            Width = 36,
            Height = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Visibility = Visibility.Collapsed,
        };
        var testBar = new InfoBar
        {
            IsClosable = true,
            IsOpen = false,
        };

        // ── List card ────────────────────────────────────────────────────
        var listPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 6 };
        var createButton = McpTabSmallButton(L10n.T("aiMcpCreate", "Create server"), "\uE710");
        var syncButton = McpTabSmallButton(L10n.T("mcpServerDetailSyncStatus", "Sync status"), "\uE895");
        var refreshButton = McpTabSmallButton(L10n.T("commonRefresh", "Refresh"), "\uE72C");
        var listCard = McpTabCard(L10n.T("aiTabMcp", "MCP"), out var listCardPanel,
            createButton, syncButton, refreshButton);
        listCardPanel.Children.Add(testBar);

        // ── Create form (upstream operate drawer, create mode) ───────────
        var nameBox = new TextBox { PlaceholderText = "mcp-github" };
        var typeCombo = McpTabCombo(new[] { "npx", "uvx" }, 0);
        var commandBox = new TextBox
        {
            AcceptsReturn = true,
            Height = 84,
            TextWrapping = TextWrapping.Wrap,
            PlaceholderText = "npx -y @modelcontextprotocol/server-github",
        };
        var protocolCombo = McpTabCombo(new[] { "http://", "https://" }, 0);
        var urlBox = new TextBox { PlaceholderText = "127.0.0.1:8000" };
        var transportCombo = McpTabCombo(new[] { "sse", "streamableHttp" }, 0);
        var ssePathBox = new TextBox();
        var streamablePathBox = new TextBox();
        var imageBox = new TextBox { Text = GatewayImageNpx };
        var containerBox = new TextBox();
        var portBox = new TextBox { Text = "8000" };
        var hostIpCombo = McpTabCombo(new[] { "127.0.0.1", "0.0.0.0" }, 0);
        var formError = McpTabErrorText();
        var formBusyRing = new ProgressRing
        {
            IsActive = true,
            Width = 20,
            Height = 20,
            VerticalAlignment = VerticalAlignment.Center,
            Visibility = Visibility.Collapsed,
        };
        var formConfirmButton = McpTabSmallButton(L10n.T("commonConfirm", "Confirm"), null);
        var formCancelButton = McpTabSmallButton(L10n.T("commonCancel", "Cancel"), null);

        var urlRow = new Grid { ColumnSpacing = 8 };
        urlRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        urlRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        Grid.SetColumn(protocolCombo, 0);
        Grid.SetColumn(urlBox, 1);
        urlRow.Children.Add(protocolCombo);
        urlRow.Children.Add(urlBox);

        var ssePathRow = McpTabFieldRow(L10n.T("aiMcpSsePathLabel", "SSE Path"), ssePathBox);
        var streamablePathRow = McpTabFieldRow(
            L10n.T("aiMcpStreamablePathLabel", "Streamable HTTP Path"), streamablePathBox);

        void UpdateTransportRows()
        {
            var transport = transportCombo.SelectedItem as string;
            var isSse = transport == "sse";
            ssePathRow.Visibility = isSse ? Visibility.Visible : Visibility.Collapsed;
            streamablePathRow.Visibility = isSse ? Visibility.Collapsed : Visibility.Visible;
        }

        var formTitle = new TextBlock
        {
            Text = L10n.T("aiMcpDialogCreateTitle", "Create MCP Server"),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        };
        var formPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        formPanel.Children.Add(formTitle);
        formPanel.Children.Add(McpTabFieldRow(L10n.T("commonName", "Name"), nameBox));
        formPanel.Children.Add(McpTabFieldRow(L10n.T("aiMcpTypeLabel", "Type"), typeCombo));
        formPanel.Children.Add(McpTabFieldRow(L10n.T("aiMcpCommandLabel", "Command"), commandBox));
        formPanel.Children.Add(McpTabFieldRow(L10n.T("aiMcpBaseUrlLabel", "Base URL"), urlRow));
        formPanel.Children.Add(McpTabFieldRow(L10n.T("aiMcpTransportLabel", "Transport"), transportCombo));
        formPanel.Children.Add(ssePathRow);
        formPanel.Children.Add(streamablePathRow);
        formPanel.Children.Add(McpTabFieldRow(L10n.T("containerImage", "Image"), imageBox));
        formPanel.Children.Add(McpTabFieldRow(L10n.T("aiMcpContainerLabel", "Container Name"), containerBox));
        formPanel.Children.Add(McpTabFieldRow(L10n.T("aiMcpPortLabel", "Port"), portBox));
        formPanel.Children.Add(McpTabFieldRow(L10n.T("aiMcpHostIpLabel", "Host IP"), hostIpCombo));
        formPanel.Children.Add(formError);
        formPanel.Children.Add(McpTabButtonRow(formBusyRing, formConfirmButton, formCancelButton));

        var formHost = new Border
        {
            Visibility = Visibility.Collapsed,
            Padding = new Thickness(12),
            CornerRadius = new CornerRadius(6),
            BorderBrush = McpTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = McpTabSubtleFill(),
            Child = formPanel,
        };

        listCardPanel.Children.Add(formHost);
        listCardPanel.Children.Add(listPanel);

        // ── Root layout ──────────────────────────────────────────────────
        var contentHost = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 12,
            Margin = new Thickness(8),
        };
        contentHost.Children.Add(listCard);

        var scroll = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Content = contentHost,
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
        Grid.SetRow(noticeBar, 0);
        Grid.SetRow(errorRow, 1);
        Grid.SetRow(scroll, 2);
        Grid.SetRow(loadingRing, 2);
        Grid.SetRow(errorToast, 2);
        errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        root.Children.Add(noticeBar);
        root.Children.Add(errorRow);
        root.Children.Add(scroll);
        root.Children.Add(loadingRing);
        root.Children.Add(errorToast);

        // ── Upstream watchers (create mode) ──────────────────────────────
        // Name input fills containerName and both transport paths; the type
        // switch keeps the default gateway image while untouched.
        nameBox.TextChanged += (s, e) =>
        {
            var name = nameBox.Text.Trim();
            if (name.Length == 0) return;
            containerBox.Text = name;
            ssePathBox.Text = "/" + name;
            streamablePathBox.Text = "/" + name;
        };

        typeCombo.SelectionChanged += (s, e) =>
        {
            var type = typeCombo.SelectedItem as string ?? "npx";
            if (imageBox.Text.Length == 0 || imageBox.Text == GatewayImageNpx || imageBox.Text == GatewayImageUvx)
            {
                imageBox.Text = type == "uvx" ? GatewayImageUvx : GatewayImageNpx;
            }
            commandBox.PlaceholderText = type == "uvx"
                ? "uvx mcp-server-fetch"
                : "npx -y @modelcontextprotocol/server-github";
        };

        transportCombo.SelectionChanged += (s, e) => UpdateTransportRows();
        UpdateTransportRows();

        // ── Data load ────────────────────────────────────────────────────
        async Task LoadAsync(bool showLoading)
        {
            if (busyGuard) return;
            busyGuard = true;

            if (showLoading)
            {
                loadingRing.Visibility = Visibility.Visible;
                contentHost.Visibility = Visibility.Collapsed;
            }

            JsonElement? result;
            try
            {
                result = await WindowsBridge.GetMcpServersAsync(1, PageSize, null);
            }
            finally
            {
                busyGuard = false;
            }

            JsonElement items = default;
            var failed = result is not JsonElement json
                || json.ValueKind != JsonValueKind.Object
                || !json.TryGetProperty("items", out items)
                || items.ValueKind != JsonValueKind.Array;
            McpTabShowError(loadErrorBar, retryButton, failed);
            if (failed)
            {
                loadingRing.Visibility = Visibility.Collapsed;
                if (!showLoading)
                {
                    errorToast.Show(L10n.T("hostAiMcpLoadFailed", "Failed to load MCP servers."));
                }
                return;
            }

            servers.Clear();
            foreach (var item in items.EnumerateArray())
            {
                if (item.ValueKind != JsonValueKind.Object) continue;
                servers.Add(new McpTabServerEntry
                {
                    Id = McpTabInt64(item, "id"),
                    Name = McpTabString(item, "name") ?? "--",
                    BaseUrl = McpTabString(item, "baseUrl") ?? "",
                    OutputTransport = McpTabString(item, "outputTransport") ?? "sse",
                    SsePath = McpTabString(item, "ssePath") ?? "",
                    StreamableHttpPath = McpTabString(item, "streamableHttpPath") ?? "",
                    Status = McpTabString(item, "status") ?? "",
                    Message = McpTabString(item, "message") ?? "",
                    Port = McpTabInt64(item, "port"),
                });
            }

            RenderList();
            loadingRing.Visibility = Visibility.Collapsed;
            contentHost.Visibility = Visibility.Visible;
        }

        void RenderList()
        {
            listPanel.Children.Clear();
            if (servers.Count == 0)
            {
                listPanel.Children.Add(McpTabEmptyText(L10n.T("aiMcpNoServers", "No MCP servers")));
                return;
            }
            foreach (var entry in servers)
            {
                listPanel.Children.Add(BuildServerRow(entry));
            }
        }

        // ── Server row ───────────────────────────────────────────────────
        FrameworkElement BuildServerRow(McpTabServerEntry entry)
        {
            var externalUrl = McpTabExternalUrl(entry);
            var running = entry.Status.Equals("Running", StringComparison.OrdinalIgnoreCase);

            var infoPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 2 };
            var nameBlock = new TextBlock
            {
                Text = entry.Name,
                FontSize = 14,
                FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            };
            ToolTipService.SetToolTip(nameBlock, entry.Name);
            var urlBlock = new TextBlock
            {
                Text = externalUrl.Length == 0 ? "--" : externalUrl,
                FontSize = 12,
                Foreground = McpTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            };
            ToolTipService.SetToolTip(urlBlock, externalUrl);
            infoPanel.Children.Add(nameBlock);
            infoPanel.Children.Add(urlBlock);

            var startStopButton = McpTabSmallButton(
                running ? L10n.T("commonStop", "Stop") : L10n.T("commonStart", "Start"),
                running ? "\uE71A" : "\uE768");
            startStopButton.Click += (s, e) => _ = OperateAsync(entry, running ? "stop" : "start");

            var restartButton = McpTabSmallButton(L10n.T("commonRestart", "Restart"), "\uE72C");
            restartButton.Click += (s, e) => _ = OperateAsync(entry, "restart");

            var testButton = McpTabSmallButton(L10n.T("hostAiMcpTestConnection", "Test connection"), null);
            testButton.Click += (s, e) => _ = TestConnectionAsync(entry);

            var deleteButton = McpTabSmallButton(L10n.T("commonDelete", "Delete"), "\uE74D");
            deleteButton.Click += (s, e) => _ = DeleteAsync(entry);

            var row = new Grid { ColumnSpacing = 8 };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var statusChip = McpTabStatusChip(entry.Status, entry.Message);
            Grid.SetColumn(infoPanel, 0);
            Grid.SetColumn(statusChip, 1);
            Grid.SetColumn(startStopButton, 2);
            Grid.SetColumn(restartButton, 3);
            Grid.SetColumn(testButton, 4);
            Grid.SetColumn(deleteButton, 5);
            row.Children.Add(infoPanel);
            row.Children.Add(statusChip);
            row.Children.Add(startStopButton);
            row.Children.Add(restartButton);
            row.Children.Add(testButton);
            row.Children.Add(deleteButton);

            return new Border
            {
                Padding = new Thickness(10, 6, 10, 6),
                CornerRadius = new CornerRadius(6),
                BorderBrush = McpTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
                BorderThickness = new Thickness(1),
                Background = McpTabSubtleFill(),
                Child = row,
            };
        }

        // ── Row write actions ────────────────────────────────────────────
        async Task OperateAsync(McpTabServerEntry entry, string operate)
        {
            if (busyGuard || root.XamlRoot == null) return;
            var opLabel = operate switch
            {
                "stop" => L10n.T("commonStop", "Stop"),
                "restart" => L10n.T("commonRestart", "Restart"),
                _ => L10n.T("commonStart", "Start"),
            };
            // Upstream confirms every operate via ElMessageBox (operatorHelper).
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                opLabel,
                string.Format(
                    L10n.T("hostAiMcpOperateConfirm", "Are you sure to {0} the MCP server \"{1}\"?"),
                    opLabel, entry.Name),
                L10n.T("commonConfirm", "Confirm"),
                L10n.T("commonCancel", "Cancel"));
            if (!confirmed) return;

            busyGuard = true;
            bool success;
            try
            {
                success = await WindowsBridge.OperateMcpServerAsync(entry.Id, operate);
            }
            finally
            {
                busyGuard = false;
            }

            if (success)
            {
                ShowNotice(L10n.T("hostAiMcpOperationSuccess", "Operation completed."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAiMcpOperationFailed", "MCP server operation failed."));
            }
        }

        async Task TestConnectionAsync(McpTabServerEntry entry)
        {
            if (busyGuard) return;
            busyGuard = true;
            bool success;
            try
            {
                success = await WindowsBridge.TestMcpConnectionAsync(entry.Id);
            }
            finally
            {
                busyGuard = false;
            }

            // The bridge contract returns a bool only, so the upstream
            // server-provided message degrades to a generic localized text.
            testBar.Severity = success ? InfoBarSeverity.Success : InfoBarSeverity.Error;
            testBar.Title = success
                ? L10n.T("hostAiMcpTestSuccess", "Connection test passed.")
                : L10n.T("hostAiMcpTestFailed", "Connection test failed.");
            testBar.Message = $"{entry.Name}: {McpTabExternalUrl(entry)}";
            testBar.IsOpen = true;
        }

        async Task DeleteAsync(McpTabServerEntry entry)
        {
            if (busyGuard || root.XamlRoot == null) return;
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                L10n.T("commonDelete", "Delete"),
                L10n.T("aiMcpDeleteConfirm", "Delete MCP server {name}?").Replace("{name}", entry.Name),
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);
            if (!confirmed) return;

            busyGuard = true;
            bool success;
            try
            {
                success = await WindowsBridge.DeleteMcpServerAsync(entry.Id);
            }
            finally
            {
                busyGuard = false;
            }

            if (success)
            {
                ShowNotice(L10n.T("hostAiMcpOperationSuccess", "Operation completed."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAiMcpDeleteFailed", "Failed to delete the MCP server."));
            }
        }

        async Task SyncStatusAsync()
        {
            if (busyGuard || servers.Count == 0) return;
            var ids = new List<object>();
            foreach (var entry in servers)
            {
                ids.Add(entry.Id);
            }

            busyGuard = true;
            bool success;
            try
            {
                success = await WindowsBridge.SyncMcpStatusAsync(ids);
            }
            finally
            {
                busyGuard = false;
            }

            if (success)
            {
                ShowNotice(L10n.T("mcpServerDetailSynced", "Status synced"));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("mcpServerDetailSyncFailed", "Sync failed"));
            }
        }

        // ── Create form flow ─────────────────────────────────────────────
        void ShowCreateForm()
        {
            if (busyGuard) return;
            McpTabSetError(formError, null);
            testBar.IsOpen = false;
            // Upstream openCreate prefills port = max(existing ports) + 1
            // with a 7999 floor (so the default lands on 8000).
            long maxPort = 7999;
            foreach (var entry in servers)
            {
                if (entry.Port > maxPort) maxPort = entry.Port;
            }
            portBox.Text = (maxPort + 1).ToString(CultureInfo.InvariantCulture);
            formHost.Visibility = Visibility.Visible;
        }

        formConfirmButton.Click += (s, e) => _ = SubmitCreateAsync();
        formCancelButton.Click += (s, e) => formHost.Visibility = Visibility.Collapsed;
        createButton.Click += (s, e) => ShowCreateForm();
        syncButton.Click += (s, e) => _ = SyncStatusAsync();
        refreshButton.Click += (s, e) => _ = LoadAsync(showLoading: false);
        retryButton.Click += (s, e) => _ = LoadAsync(showLoading: false);

        async Task SubmitCreateAsync()
        {
            if (busyGuard) return;
            McpTabSetError(formError, null);

            var name = nameBox.Text.Trim();
            var type = typeCombo.SelectedItem as string ?? "npx";
            var command = commandBox.Text.Trim();
            var protocol = protocolCombo.SelectedItem as string ?? "http://";
            var url = urlBox.Text.Trim();
            var transport = transportCombo.SelectedItem as string ?? "sse";
            var ssePath = ssePathBox.Text.Trim();
            var streamablePath = streamablePathBox.Text.Trim();
            var image = imageBox.Text.Trim();
            var container = containerBox.Text.Trim();
            var hostIp = hostIpCombo.SelectedItem as string ?? "127.0.0.1";
            var portValid = int.TryParse(
                portBox.Text.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var port);

            // Upstream form rules (name/command/url/container/image required,
            // valid port, the path matching the selected transport).
            if (name.Length == 0)
            {
                McpTabSetError(formError, L10n.T("aiMcpNameRequired", "Enter a server name"));
                return;
            }
            if (command.Length == 0)
            {
                McpTabSetError(formError, L10n.T("aiMcpCommandRequired", "Enter a command"));
                return;
            }
            if (url.Length == 0)
            {
                McpTabSetError(formError, L10n.T("hostAiMcpUrlRequired", "Enter the base URL."));
                return;
            }
            if (transport == "sse" && ssePath.Length == 0)
            {
                McpTabSetError(formError, L10n.T("hostAiMcpPathRequired", "Enter the transport path."));
                return;
            }
            if (transport == "streamableHttp" && streamablePath.Length == 0)
            {
                McpTabSetError(formError, L10n.T("hostAiMcpPathRequired", "Enter the transport path."));
                return;
            }
            if (container.Length == 0)
            {
                McpTabSetError(formError, L10n.T("hostAiMcpContainerRequired", "Enter a container name."));
                return;
            }
            if (image.Length == 0)
            {
                McpTabSetError(formError, L10n.T("hostAiMcpImageRequired", "Enter the gateway image."));
                return;
            }
            if (!portValid)
            {
                McpTabSetError(formError, L10n.T("aiMcpPortRequired", "Enter a valid port"));
                return;
            }

            busyGuard = true;
            formConfirmButton.IsEnabled = false;
            formBusyRing.Visibility = Visibility.Visible;
            bool success;
            try
            {
                // Bridge contract: the Dart channel reads only "url" and maps
                // it to the upstream baseUrl, so protocol+url are joined here.
                success = await WindowsBridge.CreateMcpServerAsync(
                    name, type, command, protocol, protocol + url, transport,
                    ssePath.Length == 0 ? null : ssePath,
                    streamablePath.Length == 0 ? null : streamablePath,
                    image, container, port, hostIp);
            }
            finally
            {
                busyGuard = false;
                formConfirmButton.IsEnabled = true;
                formBusyRing.Visibility = Visibility.Collapsed;
            }

            if (success)
            {
                formHost.Visibility = Visibility.Collapsed;
                ShowNotice(L10n.T("commonCreateSuccess", "Created successfully"));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAiMcpCreateFailed", "Failed to create the MCP server."));
                McpTabSetError(formError,
                    L10n.T("hostAiCreateFailedRetry", "Create failed. Adjust the input and try again."));
            }
        }

        root.Loaded += (s, e) => _ = LoadAsync(showLoading: true);
        return root;

        void ShowNotice(string message)
        {
            noticeBar.Title = message;
            noticeBar.IsOpen = true;
        }
    }

    // ── Self-contained UI helpers (McpTab prefix) ────────────────────────

    /// <summary>Transparent card with a CardStroke border and rounded
    /// corners; the trailing header actions sit right-aligned.</summary>
    private static FrameworkElement McpTabCard(string title, out StackPanel panel, params FrameworkElement[] actions)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = McpTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
        };

        panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };

        var header = new Grid { ColumnSpacing = 8 };
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var titleBlock = new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(titleBlock, 0);
        header.Children.Add(titleBlock);

        var column = 2;
        foreach (var action in actions)
        {
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            action.VerticalAlignment = VerticalAlignment.Center;
            Grid.SetColumn(action, column);
            header.Children.Add(action);
            column++;
        }

        panel.Children.Add(header);
        card.Child = panel;
        return card;
    }

    /// <summary>Status pill: Running green, Stopped gray, Error red, other
    /// states caution; the tooltip carries the server error message.</summary>
    private static FrameworkElement McpTabStatusChip(string status, string message)
    {
        var raw = status ?? string.Empty;
        Brush accentBrush;
        string label;
        if (raw.Equals("Running", StringComparison.OrdinalIgnoreCase))
        {
            accentBrush = McpTabThemeBrush("SystemFillColorSuccessBrush", Colors.SeaGreen);
            label = L10n.T("statusRunning", "Running");
        }
        else if (raw.Equals("Stopped", StringComparison.OrdinalIgnoreCase))
        {
            accentBrush = McpTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray);
            label = L10n.T("statusStopped", "Stopped");
        }
        else if (raw.IndexOf("Error", StringComparison.OrdinalIgnoreCase) >= 0)
        {
            accentBrush = McpTabThemeBrush("SystemFillColorCriticalBrush", Colors.IndianRed);
            label = L10n.T("hostAiMcpStatusError", "Error");
        }
        else if (raw.Length == 0)
        {
            accentBrush = McpTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray);
            label = "--";
        }
        else
        {
            accentBrush = McpTabThemeBrush("SystemFillColorCautionBrush", Colors.DarkOrange);
            label = raw.Equals("Restarting", StringComparison.OrdinalIgnoreCase)
                ? L10n.T("statusRestarting", "Restarting")
                : raw;
        }

        var color = McpTabBrushColor(accentBrush, Colors.Gray);
        var chip = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
            VerticalAlignment = VerticalAlignment.Center,
        };
        chip.Children.Add(new Ellipse
        {
            Width = 8,
            Height = 8,
            Fill = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });
        chip.Children.Add(new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });

        var pill = new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            Background = new SolidColorBrush(ColorHelper.FromArgb(26, color.R, color.G, color.B)),
            HorizontalAlignment = HorizontalAlignment.Left,
            VerticalAlignment = VerticalAlignment.Center,
            Child = chip,
        };
        if (!string.IsNullOrEmpty(message))
        {
            ToolTipService.SetToolTip(pill, message);
        }
        return pill;
    }

    /// <summary>External URL as shown upstream: baseUrl + the path of the
    /// selected output transport.</summary>
    private static string McpTabExternalUrl(McpTabServerEntry entry)
    {
        var path = entry.OutputTransport == "streamableHttp"
            ? entry.StreamableHttpPath
            : entry.SsePath;
        return entry.BaseUrl + path;
    }

    private static ComboBox McpTabCombo(string[] options, int selectedIndex)
    {
        var combo = new ComboBox
        {
            SelectedIndex = selectedIndex,
            MinWidth = 140,
            VerticalAlignment = VerticalAlignment.Center,
        };
        foreach (var option in options)
        {
            combo.Items.Add(option);
        }
        return combo;
    }

    /// <summary>Labeled form field row (label 140px, control stretches).</summary>
    private static FrameworkElement McpTabFieldRow(string label, FrameworkElement control)
    {
        var row = new Grid { ColumnSpacing = 12 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(140) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 13,
            VerticalAlignment = VerticalAlignment.Center,
            TextWrapping = TextWrapping.Wrap,
        };
        Grid.SetColumn(labelBlock, 0);
        control.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(control, 1);
        row.Children.Add(labelBlock);
        row.Children.Add(control);
        return row;
    }

    private static FrameworkElement McpTabButtonRow(FrameworkElement busyRing, Button confirm, Button cancel)
    {
        var row = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            HorizontalAlignment = HorizontalAlignment.Right,
        };
        confirm.Padding = new Thickness(18, 4, 18, 4);
        cancel.Padding = new Thickness(18, 4, 18, 4);
        row.Children.Add(busyRing);
        row.Children.Add(cancel);
        row.Children.Add(confirm);
        return row;
    }

    private static Button McpTabSmallButton(string label, string? glyph)
    {
        var button = new Button
        {
            Padding = new Thickness(10, 4, 10, 4),
            VerticalAlignment = VerticalAlignment.Center,
        };
        if (glyph == null)
        {
            button.Content = new TextBlock { Text = label, FontSize = 12 };
        }
        else
        {
            button.Content = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Spacing = 6,
                Children =
                {
                    new FontIcon { Glyph = glyph, FontSize = 14 },
                    new TextBlock
                    {
                        Text = label,
                        FontSize = 12,
                        VerticalAlignment = VerticalAlignment.Center,
                    },
                },
            };
        }
        return button;
    }

    private static TextBlock McpTabEmptyText(string text)
    {
        return new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = McpTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        };
    }

    /// <summary>Load-error surface: an error InfoBar paired with a trailing
    /// Retry button; visibility toggled via McpTabShowError.</summary>
    private static FrameworkElement McpTabErrorRow(out InfoBar bar, out Button retryButton)
    {
        var row = new Grid { ColumnSpacing = 8, Margin = new Thickness(8, 8, 8, 0) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        bar = new InfoBar
        {
            Title = L10n.T("hostAiMcpLoadFailed", "Failed to load MCP servers."),
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
    private static void McpTabShowError(InfoBar bar, Button retryButton, bool show)
    {
        bar.IsOpen = show;
        retryButton.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
    }

    private static TextBlock McpTabErrorText()
    {
        return new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = McpTabThemeBrush("SystemFillColorCriticalBrush", Colors.Red),
            Visibility = Visibility.Collapsed,
        };
    }

    private static void McpTabSetError(TextBlock target, string? message)
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

    private static Brush McpTabThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Color McpTabBrushColor(Brush brush, Color fallback)
    {
        return brush is SolidColorBrush solid ? solid.Color : fallback;
    }

    private static Brush McpTabSubtleFill()
    {
        var stroke = McpTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }

    private static string? McpTabString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static long McpTabInt64(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number)
        {
            return prop.TryGetInt64(out var value) ? value : (long)prop.GetDouble();
        }
        return 0;
    }

    /// <summary>View over one McpServerDTO item from the bridge.</summary>
    private sealed class McpTabServerEntry
    {
        public long Id { get; set; }
        public string Name { get; set; } = "";
        public string BaseUrl { get; set; } = "";
        public string OutputTransport { get; set; } = "sse";
        public string SsePath { get; set; } = "";
        public string StreamableHttpPath { get; set; } = "";
        public string Status { get; set; } = "";
        public string Message { get; set; } = "";
        public long Port { get; set; }
    }
}
