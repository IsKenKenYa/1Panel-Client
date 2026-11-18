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
/// Native AI module - AI agents tab (upstream
/// frontend/src/views/ai/agents/agent/index.vue + add/index.vue, minimal
/// feature set).
///
/// One transparent list card (name / type / status / operations): the
/// "Overview" row action loads the agent snapshot into an InfoBag
/// (container status, app version, default model, channel/skill/job/session
/// counts) and the destructive delete confirms before the bridge call. The
/// collapsible create form mirrors the upstream drawer's core fields:
/// agent type (openclaw|copaw|hermes-agent), name (auto default per type),
/// app version, WebUI port (defaults follow the type: 18789 / 8088 / 9119)
/// and remark. Creation is a long-running install upstream, so a failure
/// surfaces an InfoBar telling the user to wait or check the server task
/// list instead of a plain error.
///
/// Data flows through WindowsBridge (PageAgentsNativeAsync /
/// GetAgentOverviewNativeAsync / CreateAgentNativeAsync /
/// DeleteAgentNativeAsync). Self-contained: helpers carry the AgentsTab
/// prefix. Bridge contract note: delete always passes forceDelete=true per
/// the batch spec (upstream exposes a checkbox defaulting to false).
/// </summary>
public static class AiAgentsTab
{
    private const int PageSize = 100;

    public static FrameworkElement Build()
    {
        var errorToast = new ErrorToast();
        var busyGuard = false;
        var agents = new List<AgentsTabAgentEntry>();

        // ── Status surfaces ──────────────────────────────────────────────
        var noticeBar = new InfoBar
        {
            Severity = InfoBarSeverity.Success,
            IsClosable = true,
            IsOpen = false,
            Margin = new Thickness(8, 8, 8, 0),
        };
        var errorRow = AgentsTabErrorRow(out var loadErrorBar, out var retryButton);
        var loadingRing = new ProgressRing
        {
            IsActive = true,
            Width = 36,
            Height = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Visibility = Visibility.Collapsed,
        };

        // ── List card ────────────────────────────────────────────────────
        var listPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 6 };
        var createButton = AgentsTabSmallButton(L10n.T("aiAgentsCreate", "Create Agent"), "\uE710");
        var refreshButton = AgentsTabSmallButton(L10n.T("commonRefresh", "Refresh"), "\uE72C");
        var listCard = AgentsTabCard(L10n.T("aiTabAgents", "Agents"), out var listCardPanel,
            createButton, refreshButton);

        // ── Overview panel (per-row "Overview" action target) ────────────
        var overviewTitle = new TextBlock
        {
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
        };
        var overviewCloseButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE711", FontSize = 14 },
            Background = null,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(8, 4, 8, 4),
            VerticalAlignment = VerticalAlignment.Center,
        };
        var overviewBody = new StackPanel { Orientation = Orientation.Vertical, Spacing = 8 };
        var overviewHost = new Border
        {
            Visibility = Visibility.Collapsed,
            Padding = new Thickness(12),
            CornerRadius = new CornerRadius(6),
            BorderBrush = AgentsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = AgentsTabSubtleFill(),
        };
        var overviewHeader = new Grid { ColumnSpacing = 8 };
        overviewHeader.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        overviewHeader.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(overviewTitle, 0);
        Grid.SetColumn(overviewCloseButton, 1);
        overviewHeader.Children.Add(overviewTitle);
        overviewHeader.Children.Add(overviewCloseButton);
        var overviewPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        overviewPanel.Children.Add(overviewHeader);
        overviewPanel.Children.Add(overviewBody);
        overviewHost.Child = overviewPanel;

        // ── Create form (upstream add drawer, minimal set) ───────────────
        var typeCombo = new ComboBox
        {
            SelectedIndex = 0,
            MinWidth = 160,
            VerticalAlignment = VerticalAlignment.Center,
        };
        foreach (var (value, label) in new[]
                 {
                     ("openclaw", L10n.T("aiAgentsOpenclaw", "OpenClaw")),
                     ("copaw", L10n.T("aiAgentsCopaw", "QwenPaw")),
                     ("hermes-agent", L10n.T("hostAiAgentTypeHermes", "Hermes Agent")),
                 })
        {
            typeCombo.Items.Add(new ComboBoxItem { Content = label, Tag = value });
        }

        var nameBox = new TextBox();
        var versionBox = new TextBox { PlaceholderText = "1.0.0" };
        var portBox = new TextBox { Text = "18789" };
        var remarkBox = new TextBox();
        var formError = AgentsTabErrorText();
        var createFailureBar = new InfoBar
        {
            Title = L10n.T("hostAiAgentCreateFailed",
                "Agent creation failed or timed out. The installation may still be running on the server - wait patiently or check the server task list."),
            Severity = InfoBarSeverity.Error,
            IsClosable = true,
            IsOpen = false,
        };
        var formBusyRing = new ProgressRing
        {
            IsActive = true,
            Width = 20,
            Height = 20,
            VerticalAlignment = VerticalAlignment.Center,
            Visibility = Visibility.Collapsed,
        };
        var formConfirmButton = AgentsTabSmallButton(L10n.T("commonConfirm", "Confirm"), null);
        var formCancelButton = AgentsTabSmallButton(L10n.T("commonCancel", "Cancel"), null);

        var formTitle = new TextBlock
        {
            Text = L10n.T("aiAgentsCreate", "Create Agent"),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        };
        var formPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        formPanel.Children.Add(formTitle);
        formPanel.Children.Add(AgentsTabFieldRow(L10n.T("aiAgentsAgentType", "Agent type"), typeCombo));
        formPanel.Children.Add(AgentsTabFieldRow(L10n.T("commonName", "Name"), nameBox));
        formPanel.Children.Add(AgentsTabFieldRow(L10n.T("aiAgentsAppVersion", "App version"), versionBox));
        formPanel.Children.Add(AgentsTabFieldRow(L10n.T("aiAgentsWebUiPort", "WebUI port"), portBox));
        formPanel.Children.Add(AgentsTabFieldRow(L10n.T("websitesRemarkLabel", "Remark"), remarkBox));
        formPanel.Children.Add(formError);
        formPanel.Children.Add(createFailureBar);
        formPanel.Children.Add(AgentsTabButtonRow(formBusyRing, formConfirmButton, formCancelButton));

        var formHost = new Border
        {
            Visibility = Visibility.Collapsed,
            Padding = new Thickness(12),
            CornerRadius = new CornerRadius(6),
            BorderBrush = AgentsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = AgentsTabSubtleFill(),
            Child = formPanel,
        };

        listCardPanel.Children.Add(overviewHost);
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

        // ── Upstream watcher: type change drives default name and port ──
        typeCombo.SelectionChanged += (s, e) =>
        {
            var type = AgentsTabSelectedType(typeCombo);
            portBox.Text = AgentsTabDefaultPort(type).ToString(CultureInfo.InvariantCulture);
            var defaultName = AgentsTabDefaultName(type);
            if (nameBox.Text.Length == 0 || nameBox.Text is "OpenClaw" or "QwenPaw" or "Hermes-Agent")
            {
                nameBox.Text = defaultName;
            }
        };
        nameBox.Text = AgentsTabDefaultName(AgentsTabSelectedType(typeCombo));

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
                result = await WindowsBridge.PageAgentsNativeAsync(1, PageSize);
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
            AgentsTabShowError(loadErrorBar, retryButton, failed);
            if (failed)
            {
                loadingRing.Visibility = Visibility.Collapsed;
                if (!showLoading)
                {
                    errorToast.Show(L10n.T("hostAiAgentLoadFailed", "Failed to load agents."));
                }
                return;
            }

            agents.Clear();
            foreach (var item in items.EnumerateArray())
            {
                if (item.ValueKind != JsonValueKind.Object) continue;
                agents.Add(new AgentsTabAgentEntry
                {
                    Id = AgentsTabInt64(item, "id"),
                    Name = AgentsTabString(item, "name") ?? "--",
                    AgentType = AgentsTabString(item, "agentType") ?? "",
                    Status = AgentsTabString(item, "status") ?? "",
                    Message = AgentsTabString(item, "message") ?? "",
                    AppVersion = AgentsTabString(item, "appVersion") ?? "",
                    WebUiPort = AgentsTabInt64(item, "webUIPort"),
                });
            }

            // The overview is a point-in-time snapshot; drop it on reload.
            overviewHost.Visibility = Visibility.Collapsed;
            RenderList();
            loadingRing.Visibility = Visibility.Collapsed;
            contentHost.Visibility = Visibility.Visible;
        }

        void RenderList()
        {
            listPanel.Children.Clear();
            if (agents.Count == 0)
            {
                listPanel.Children.Add(AgentsTabEmptyText(L10n.T("aiAgentsNoAgents", "No agents found")));
                return;
            }
            foreach (var entry in agents)
            {
                listPanel.Children.Add(BuildAgentRow(entry));
            }
        }

        // ── Agent row ────────────────────────────────────────────────────
        FrameworkElement BuildAgentRow(AgentsTabAgentEntry entry)
        {
            var typeLabel = AgentsTabTypeLabel(entry.AgentType);

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
            var detail = entry.AppVersion.Length == 0
                ? $"{L10n.T("aiAgentsWebUiPort", "WebUI port")}: {entry.WebUiPort}"
                : $"v{entry.AppVersion} \u00B7 {L10n.T("aiAgentsWebUiPort", "WebUI port")}: {entry.WebUiPort}";
            var detailBlock = new TextBlock
            {
                Text = detail,
                FontSize = 12,
                Foreground = AgentsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            };
            infoPanel.Children.Add(nameBlock);
            infoPanel.Children.Add(detailBlock);

            var typePill = new Border
            {
                CornerRadius = new CornerRadius(10),
                Padding = new Thickness(10, 3, 10, 3),
                VerticalAlignment = VerticalAlignment.Center,
                Background = AgentsTabSubtleFill(),
                BorderBrush = AgentsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
                BorderThickness = new Thickness(1),
                Child = new TextBlock { Text = typeLabel, FontSize = 12 },
            };

            var overviewButton = AgentsTabSmallButton(L10n.T("aiAgentsOverview", "Overview"), "\uE80F");
            overviewButton.Click += (s, e) => _ = LoadOverviewAsync(entry);

            var deleteButton = AgentsTabSmallButton(L10n.T("commonDelete", "Delete"), "\uE74D");
            deleteButton.Click += (s, e) => _ = DeleteAsync(entry);

            var row = new Grid { ColumnSpacing = 8 };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var statusChip = AgentsTabStatusChip(entry.Status, entry.Message);
            Grid.SetColumn(infoPanel, 0);
            Grid.SetColumn(typePill, 1);
            Grid.SetColumn(statusChip, 2);
            Grid.SetColumn(overviewButton, 3);
            Grid.SetColumn(deleteButton, 4);
            row.Children.Add(infoPanel);
            row.Children.Add(typePill);
            row.Children.Add(statusChip);
            row.Children.Add(overviewButton);
            row.Children.Add(deleteButton);

            return new Border
            {
                Padding = new Thickness(10, 6, 10, 6),
                CornerRadius = new CornerRadius(6),
                BorderBrush = AgentsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
                BorderThickness = new Thickness(1),
                Background = AgentsTabSubtleFill(),
                Child = row,
            };
        }

        // ── Overview (upstream OverviewDrawer snapshot InfoBag) ─────────
        async Task LoadOverviewAsync(AgentsTabAgentEntry entry)
        {
            if (busyGuard) return;
            busyGuard = true;

            overviewTitle.Text = $"{L10n.T("aiAgentsOverview", "Overview")} - {entry.Name}";
            overviewBody.Children.Clear();
            overviewBody.Children.Add(new ProgressRing
            {
                IsActive = true,
                Width = 24,
                Height = 24,
                HorizontalAlignment = HorizontalAlignment.Left,
            });
            overviewHost.Visibility = Visibility.Visible;

            JsonElement? result;
            try
            {
                result = await WindowsBridge.GetAgentOverviewNativeAsync(entry.Id);
            }
            finally
            {
                busyGuard = false;
            }

            overviewBody.Children.Clear();
            var snapshot = result is JsonElement json
                           && json.ValueKind == JsonValueKind.Object
                           && json.TryGetProperty("snapshot", out var snap)
                           && snap.ValueKind == JsonValueKind.Object
                ? (JsonElement?)snap
                : null;
            if (snapshot == null)
            {
                overviewBody.Children.Add(new TextBlock
                {
                    Text = L10n.T("hostAiAgentOverviewFailed", "Failed to load the agent overview."),
                    FontSize = 12,
                    TextWrapping = TextWrapping.Wrap,
                    Foreground = AgentsTabThemeBrush("SystemFillColorCriticalBrush", Colors.Red),
                });
                return;
            }

            var snapEl = snapshot.Value;
            overviewBody.Children.Add(AgentsTabInfoBag(new[]
            {
                (L10n.T("commonStatus", "Status"), AgentsTabValue(AgentsTabString(snapEl, "containerStatus"))),
                (L10n.T("aiAgentsAppVersion", "App version"), AgentsTabValue(AgentsTabString(snapEl, "appVersion"))),
                (L10n.T("hostAiAgentDefaultModelLabel", "Default model"), AgentsTabValue(AgentsTabString(snapEl, "defaultModel"))),
                (L10n.T("aiAgentsChannels", "Channels"), AgentsTabNumber(snapEl, "channelCount")),
                (L10n.T("aiAgentsSkills", "Skills"), AgentsTabNumber(snapEl, "skillCount")),
                (L10n.T("hostAiAgentJobCountLabel", "Jobs"), AgentsTabNumber(snapEl, "jobCount")),
                (L10n.T("hostAiAgentSessionCountLabel", "Sessions"), AgentsTabNumber(snapEl, "sessionCount")),
            }));
        }

        // ── Row write action ─────────────────────────────────────────────
        async Task DeleteAsync(AgentsTabAgentEntry entry)
        {
            if (busyGuard || root.XamlRoot == null) return;
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                L10n.T("commonDelete", "Delete"),
                string.Format(
                    L10n.T("hostAiAgentDeleteConfirm", "Delete agent \"{0}\"? This action cannot be undone."),
                    entry.Name),
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);
            if (!confirmed) return;

            busyGuard = true;
            bool success;
            try
            {
                // Batch spec: forceDelete is always true on this surface
                // (upstream exposes a checkbox defaulting to false).
                success = await WindowsBridge.DeleteAgentNativeAsync(entry.Id, true);
            }
            finally
            {
                busyGuard = false;
            }

            if (success)
            {
                ShowNotice(L10n.T("hostAiAgentOperationSuccess", "Operation completed."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAiAgentDeleteFailed", "Failed to delete the agent."));
            }
        }

        // ── Create form flow ─────────────────────────────────────────────
        void ShowCreateForm()
        {
            if (busyGuard) return;
            AgentsTabSetError(formError, null);
            createFailureBar.IsOpen = false;
            portBox.Text = AgentsTabDefaultPort(AgentsTabSelectedType(typeCombo))
                .ToString(CultureInfo.InvariantCulture);
            formHost.Visibility = Visibility.Visible;
        }

        formConfirmButton.Click += (s, e) => _ = SubmitCreateAsync();
        formCancelButton.Click += (s, e) => formHost.Visibility = Visibility.Collapsed;
        createButton.Click += (s, e) => ShowCreateForm();
        refreshButton.Click += (s, e) => _ = LoadAsync(showLoading: false);
        retryButton.Click += (s, e) => _ = LoadAsync(showLoading: false);
        overviewCloseButton.Click += (s, e) => overviewHost.Visibility = Visibility.Collapsed;

        async Task SubmitCreateAsync()
        {
            if (busyGuard) return;
            AgentsTabSetError(formError, null);
            createFailureBar.IsOpen = false;

            var type = AgentsTabSelectedType(typeCombo);
            var name = nameBox.Text.Trim();
            var version = versionBox.Text.Trim();
            var remark = remarkBox.Text.Trim();
            var portValid = long.TryParse(
                portBox.Text.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var port);

            // Upstream rules: name/appVersion required, port in 1..65535.
            if (name.Length == 0)
            {
                AgentsTabSetError(formError, L10n.T("aiAgentsNameRequired", "Name is required"));
                return;
            }
            if (version.Length == 0)
            {
                AgentsTabSetError(formError, L10n.T("aiAgentsVersionRequired", "App version is required"));
                return;
            }
            if (!portValid || port < 1 || port > 65535)
            {
                AgentsTabSetError(formError, L10n.T("aiAgentsPortRequired", "Enter a valid port"));
                return;
            }

            // Long-running install upstream: keep the form disabled (and the
            // dialog state frozen) until the bridge answers.
            busyGuard = true;
            formConfirmButton.IsEnabled = false;
            formCancelButton.IsEnabled = false;
            formBusyRing.Visibility = Visibility.Visible;
            bool success;
            try
            {
                success = await WindowsBridge.CreateAgentNativeAsync(
                    type, name, string.IsNullOrEmpty(remark) ? null : remark, version, port);
            }
            finally
            {
                busyGuard = false;
                formConfirmButton.IsEnabled = true;
                formCancelButton.IsEnabled = true;
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
                // The call can time out while the server keeps installing;
                // guide the user to wait / check tasks and refresh quietly
                // so a late success still shows up.
                createFailureBar.IsOpen = true;
                await LoadAsync(showLoading: false);
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

    // ── Self-contained UI helpers (AgentsTab prefix) ─────────────────────

    private static string AgentsTabSelectedType(ComboBox combo)
    {
        return (combo.SelectedItem as ComboBoxItem)?.Tag as string ?? "openclaw";
    }

    /// <summary>Upstream setDefaultWebUIPort per agent type.</summary>
    private static long AgentsTabDefaultPort(string type)
    {
        return type switch
        {
            "copaw" => 8088,
            "hermes-agent" => 9119,
            _ => 18789,
        };
    }

    /// <summary>Upstream getDefaultAgentName per agent type.</summary>
    private static string AgentsTabDefaultName(string type)
    {
        return type switch
        {
            "copaw" => "QwenPaw",
            "hermes-agent" => "Hermes-Agent",
            _ => "OpenClaw",
        };
    }

    private static string AgentsTabTypeLabel(string agentType)
    {
        return agentType switch
        {
            "copaw" => L10n.T("aiAgentsCopaw", "QwenPaw"),
            "hermes-agent" => L10n.T("hostAiAgentTypeHermes", "Hermes Agent"),
            "openclaw" => L10n.T("aiAgentsOpenclaw", "OpenClaw"),
            "" => "--",
            _ => agentType,
        };
    }

    /// <summary>Transparent card with a CardStroke border and rounded
    /// corners; the trailing header actions sit right-aligned.</summary>
    private static FrameworkElement AgentsTabCard(string title, out StackPanel panel, params FrameworkElement[] actions)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = AgentsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
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

    /// <summary>Status pill: Running green, Stopped gray, Error red,
    /// installing/upgrading and other states caution.</summary>
    private static FrameworkElement AgentsTabStatusChip(string status, string message)
    {
        var raw = status ?? string.Empty;
        Brush accentBrush;
        string label;
        if (raw.Equals("Running", StringComparison.OrdinalIgnoreCase))
        {
            accentBrush = AgentsTabThemeBrush("SystemFillColorSuccessBrush", Colors.SeaGreen);
            label = L10n.T("statusRunning", "Running");
        }
        else if (raw.Equals("Stopped", StringComparison.OrdinalIgnoreCase))
        {
            accentBrush = AgentsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray);
            label = L10n.T("statusStopped", "Stopped");
        }
        else if (raw.IndexOf("Error", StringComparison.OrdinalIgnoreCase) >= 0)
        {
            accentBrush = AgentsTabThemeBrush("SystemFillColorCriticalBrush", Colors.IndianRed);
            label = L10n.T("hostAiAgentStatusError", "Error");
        }
        else if (raw.Length == 0)
        {
            accentBrush = AgentsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray);
            label = "--";
        }
        else
        {
            accentBrush = AgentsTabThemeBrush("SystemFillColorCautionBrush", Colors.DarkOrange);
            label = raw.Equals("Restarting", StringComparison.OrdinalIgnoreCase)
                ? L10n.T("statusRestarting", "Restarting")
                : raw;
        }

        var color = AgentsTabBrushColor(accentBrush, Colors.Gray);
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

    /// <summary>Label/value InfoBag rows matching the dashboard card look
    /// ("--" for missing data).</summary>
    private static FrameworkElement AgentsTabInfoBag((string Label, string Value)[] rows)
    {
        var bag = new Grid { ColumnSpacing = 12 };
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(140) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var line = 0;
        foreach (var (label, value) in rows)
        {
            bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            var labelBlock = new TextBlock
            {
                Text = label,
                FontSize = 12,
                Foreground = AgentsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                VerticalAlignment = VerticalAlignment.Top,
            };
            Grid.SetRow(labelBlock, line);
            Grid.SetColumn(labelBlock, 0);
            bag.Children.Add(labelBlock);

            var valueBlock = new TextBlock
            {
                Text = value,
                FontSize = 13,
                TextWrapping = TextWrapping.Wrap,
                TextTrimming = TextTrimming.CharacterEllipsis,
                VerticalAlignment = VerticalAlignment.Top,
            };
            Grid.SetRow(valueBlock, line);
            Grid.SetColumn(valueBlock, 1);
            bag.Children.Add(valueBlock);

            line++;
        }
        return bag;
    }

    private static string AgentsTabValue(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? "--" : value;
    }

    private static string AgentsTabNumber(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number &&
            prop.TryGetInt64(out var value))
        {
            return value.ToString(CultureInfo.InvariantCulture);
        }
        return "--";
    }

    /// <summary>Labeled form field row (label 140px, control stretches).</summary>
    private static FrameworkElement AgentsTabFieldRow(string label, FrameworkElement control)
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

    private static FrameworkElement AgentsTabButtonRow(FrameworkElement busyRing, Button confirm, Button cancel)
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

    private static Button AgentsTabSmallButton(string label, string? glyph)
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

    private static TextBlock AgentsTabEmptyText(string text)
    {
        return new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = AgentsTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        };
    }

    /// <summary>Load-error surface: an error InfoBar paired with a trailing
    /// Retry button; visibility toggled via AgentsTabShowError.</summary>
    private static FrameworkElement AgentsTabErrorRow(out InfoBar bar, out Button retryButton)
    {
        var row = new Grid { ColumnSpacing = 8, Margin = new Thickness(8, 8, 8, 0) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        bar = new InfoBar
        {
            Title = L10n.T("hostAiAgentLoadFailed", "Failed to load agents."),
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
    private static void AgentsTabShowError(InfoBar bar, Button retryButton, bool show)
    {
        bar.IsOpen = show;
        retryButton.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
    }

    private static TextBlock AgentsTabErrorText()
    {
        return new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = AgentsTabThemeBrush("SystemFillColorCriticalBrush", Colors.Red),
            Visibility = Visibility.Collapsed,
        };
    }

    private static void AgentsTabSetError(TextBlock target, string? message)
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

    private static Brush AgentsTabThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Color AgentsTabBrushColor(Brush brush, Color fallback)
    {
        return brush is SolidColorBrush solid ? solid.Color : fallback;
    }

    private static Brush AgentsTabSubtleFill()
    {
        var stroke = AgentsTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }

    private static string? AgentsTabString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static long AgentsTabInt64(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number)
        {
            return prop.TryGetInt64(out var value) ? value : (long)prop.GetDouble();
        }
        return 0;
    }

    /// <summary>View over one AgentItem from the bridge.</summary>
    private sealed class AgentsTabAgentEntry
    {
        public long Id { get; set; }
        public string Name { get; set; } = "";
        public string AgentType { get; set; } = "";
        public string Status { get; set; } = "";
        public string Message { get; set; } = "";
        public string AppVersion { get; set; } = "";
        public long WebUiPort { get; set; }
    }
}
