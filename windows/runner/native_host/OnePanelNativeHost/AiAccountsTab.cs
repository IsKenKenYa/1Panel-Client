using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// WinUI3 AI 管理 - 渠道账号 Tab（上游 frontend/src/views/ai/agents/model/
/// index.vue + add/index.vue 的桌面高保真还原）。
///
/// 账号列表：name / provider / apiType / baseUrl / apiKey 掩码（上游 maskKey
/// 语义：空值不显示、≤6 位原样、其余前 3 + "****" + 后 3）/ 备注；行操作为
/// Edit 与 Delete（破坏性 ConfirmDialog，默认焦点在取消按钮）。「添加账号」
/// 表单：provider（默认 custom）、name、apiType（默认 openai-completions）、
/// baseURL、apiKey（密码框）、备注；创建走 CreateAgentAccountAsync
/// （authMode 传 null、validateAvailability 传 true、verifyModel 传 null）；
/// 编辑沿用上游 "form.id > 0 时 provider/apiType 固定" 语义（输入框禁用、
/// 原值透传），走 UpdateAgentAccountAsync；删除走 DeleteAgentAccountAsync。
/// 读取固定 GetAgentAccountsAsync(1, 100, null)（客户端简化：上游为可分页
/// 表格 + apiType 过滤 + 名称搜索）。写成功经 notice InfoBar + 静默刷新；
/// 写失败经 ErrorToast + 表单内联错误（表单保持可编辑）。
///
/// 与上游的已知偏差（登记为后续批次）：provider/apiType 为自由文本输入
/// （上游为 getAgentProviders 驱动的下拉 + 默认值联动）、模型池入口
/// （ModelPoolDialog）、authMode 选择、模型发现/校验模型区块、verified/
/// createdAt 列。
///
/// 数据全部经 WindowsBridge（Dart 业务核心）转发，原生层不直连 API。
/// 自包含：helper 方法名统一 AiAccountsTab 前缀防冲突。
/// </summary>
public static class AiAccountsTab
{
    public static FrameworkElement Build()
    {
        var errorToast = new ErrorToast();
        var busyGuard = false;
        var isEditMode = false;
        long editId = -1;

        // ── 表单状态（Build 内闭包共享；显示前由 ShowForm 填充） ──────
        var providerBox = new TextBox { Text = "custom" };
        var nameBox = new TextBox();
        var apiTypeBox = new TextBox { Text = "openai-completions" };
        var baseURLBox = new TextBox();
        var apiKeyBox = new PasswordBox();
        var remarkBox = new TextBox();
        var formError = AiAccountsTabErrorText();
        var formPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        var formHost = new Border
        {
            Visibility = Visibility.Collapsed,
            Padding = new Thickness(12),
            CornerRadius = new CornerRadius(6),
            BorderBrush = AiAccountsTabThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = AiAccountsTabSubtleFill(),
        };
        formHost.Child = formPanel;

        var listPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 6 };

        // ── 卡片壳（SecurityGatewayPage 风格：透明填充 + CardStroke + 圆角） ──
        var addButton = AiAccountsTabSmallButton(L10n.T("hostAiAccountsAddAction", "Add account"), "\uE710");
        var refreshButton = AiAccountsTabSmallButton(L10n.T("commonRefresh", "Refresh"), "\uE72C");
        var card = AiAccountsTabCard(
            L10n.T("hostAiAccountsTitle", "Agent Accounts"), out var cardPanel, addButton, refreshButton);
        cardPanel.Children.Add(listPanel);
        cardPanel.Children.Add(formHost);

        var scroll = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(8, 8, 8, 8),
            Content = card,
            Visibility = Visibility.Collapsed,
        };

        // ── 状态面：成功 notice / 加载错误 + 重试 / 加载圈 / 错误 Toast ──
        var noticeBar = new InfoBar
        {
            Severity = InfoBarSeverity.Success,
            IsClosable = true,
            IsOpen = false,
            Margin = new Thickness(8, 8, 8, 0),
        };
        var errorRow = AiAccountsTabErrorRow(out var errorBar, out var retryButton);
        var loadingRing = new ProgressRing
        {
            IsActive = true,
            Width = 36,
            Height = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Visibility = Visibility.Collapsed,
        };

        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        Grid.SetRow(noticeBar, 0);
        Grid.SetRow(errorRow, 1);
        Grid.SetRow(scroll, 2);
        Grid.SetRow(loadingRing, 2);
        errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(errorToast, 2);
        root.Children.Add(noticeBar);
        root.Children.Add(errorRow);
        root.Children.Add(scroll);
        root.Children.Add(loadingRing);
        root.Children.Add(errorToast);

        // ── 表单构造（Add/Edit 时才显示） ─────────────────────────────
        formPanel.Children.Add(AiAccountsTabFieldRow(L10n.T("hostAiAccountProviderLabel", "Provider"), providerBox));
        formPanel.Children.Add(AiAccountsTabFieldRow(L10n.T("commonName", "Name"), nameBox));
        formPanel.Children.Add(AiAccountsTabFieldRow(L10n.T("hostAiAccountApiTypeLabel", "API Type"), apiTypeBox));
        formPanel.Children.Add(AiAccountsTabFieldRow(L10n.T("hostAiAccountBaseUrlLabel", "Base URL"), baseURLBox));
        formPanel.Children.Add(AiAccountsTabFieldRow(L10n.T("hostAiAccountApiKeyLabel", "API Key"), apiKeyBox));
        formPanel.Children.Add(AiAccountsTabFieldRow(L10n.T("hostAiAccountRemarkLabel", "Remark"), remarkBox));
        formPanel.Children.Add(formError);
        var confirmButton = AiAccountsTabSmallButton(L10n.T("commonConfirm", "Confirm"), null);
        var cancelButton = AiAccountsTabSmallButton(L10n.T("commonCancel", "Cancel"), null);
        formPanel.Children.Add(AiAccountsTabButtonRow(confirmButton, cancelButton));

        // ── 数据加载 ─────────────────────────────────────────────────
        async Task LoadAsync(bool showLoading)
        {
            if (busyGuard) return;
            busyGuard = true;

            if (showLoading)
            {
                loadingRing.Visibility = Visibility.Visible;
                scroll.Visibility = Visibility.Collapsed;
            }

            JsonElement? result;
            try
            {
                result = await WindowsBridge.GetAgentAccountsAsync(1, 100, null);
            }
            finally
            {
                busyGuard = false;
            }

            if (result == null)
            {
                // 桥失败：初始加载保持折叠 + 错误 InfoBar 承载重试；静默刷新
                // 保留现有内容 + 错误 Toast。
                loadingRing.Visibility = Visibility.Collapsed;
                AiAccountsTabShowError(errorBar, retryButton, true);
                if (!showLoading)
                {
                    errorToast.Show(L10n.T("hostAiAccountsRefreshFailed", "Failed to refresh agent accounts."));
                }
                return;
            }

            AiAccountsTabShowError(errorBar, retryButton, false);
            RenderAccounts(result.Value);
            loadingRing.Visibility = Visibility.Collapsed;
            scroll.Visibility = Visibility.Visible;
        }

        void RenderAccounts(JsonElement json)
        {
            // 通道透传上游分页响应 {items:[...], total}；宽松兼容裸数组。
            var items = new List<JsonElement>();
            if (json.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in json.EnumerateArray())
                {
                    if (item.ValueKind == JsonValueKind.Object) items.Add(item);
                }
            }
            else if (json.ValueKind == JsonValueKind.Object &&
                     json.TryGetProperty("items", out var arr) &&
                     arr.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in arr.EnumerateArray())
                {
                    if (item.ValueKind == JsonValueKind.Object) items.Add(item);
                }
            }

            listPanel.Children.Clear();
            if (items.Count == 0)
            {
                listPanel.Children.Add(AiAccountsTabEmptyText(
                    L10n.T("hostAiAccountsEmpty", "No agent accounts yet.")));
                return;
            }

            foreach (var item in items)
            {
                listPanel.Children.Add(BuildRow(ToEntry(item)));
            }
        }

        static AiAccountsTabEntry ToEntry(JsonElement item) => new()
        {
            Id = AiAccountsTabLong(item, "id"),
            Name = AiAccountsTabString(item, "name") ?? "",
            Provider = AiAccountsTabString(item, "provider") ?? "",
            ApiType = AiAccountsTabString(item, "apiType") ?? "",
            BaseUrl = AiAccountsTabString(item, "baseUrl") ?? AiAccountsTabString(item, "baseURL") ?? "",
            ApiKey = AiAccountsTabString(item, "apiKey") ?? "",
            Remark = AiAccountsTabString(item, "remark") ?? "",
        };

        // ── 账号行：name + provider/apiType 徽标 + Edit/Delete，副行为
        //    baseUrl 与 掩码 Key · 备注 ─────────────────────────────────
        FrameworkElement BuildRow(AiAccountsTabEntry entry)
        {
            var row = new Grid { ColumnSpacing = 6, RowSpacing = 2 };
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

            if (!string.IsNullOrWhiteSpace(entry.Provider))
            {
                var providerPill = AiAccountsTabPill(entry.Provider.Trim());
                Grid.SetRow(providerPill, 0);
                Grid.SetColumn(providerPill, 1);
                row.Children.Add(providerPill);
            }

            if (!string.IsNullOrWhiteSpace(entry.ApiType))
            {
                var apiTypePill = AiAccountsTabPill(entry.ApiType.Trim());
                Grid.SetRow(apiTypePill, 0);
                Grid.SetColumn(apiTypePill, 2);
                row.Children.Add(apiTypePill);
            }

            var editButton = AiAccountsTabSmallButton(L10n.T("commonEdit", "Edit"), "\uE70F");
            editButton.Click += (s, e) => ShowForm("edit", entry);
            Grid.SetRow(editButton, 0);
            Grid.SetColumn(editButton, 3);
            row.Children.Add(editButton);

            var deleteButton = AiAccountsTabSmallButton(L10n.T("commonDelete", "Delete"), "\uE74D");
            deleteButton.Click += (s, e) => _ = DeleteAsync(entry);
            Grid.SetRow(deleteButton, 0);
            Grid.SetColumn(deleteButton, 4);
            row.Children.Add(deleteButton);

            var baseBlock = new TextBlock
            {
                Text = string.IsNullOrWhiteSpace(entry.BaseUrl) ? "--" : entry.BaseUrl.Trim(),
                FontSize = 12,
                Foreground = AiAccountsTabThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
            };
            Grid.SetRow(baseBlock, 1);
            Grid.SetColumn(baseBlock, 0);
            Grid.SetColumnSpan(baseBlock, 5);
            row.Children.Add(baseBlock);

            var keyPart = $"{L10n.T("hostAiAccountApiKeyLabel", "API Key")}: {AiAccountsTabMaskKey(entry.ApiKey)}";
            var detail = string.IsNullOrWhiteSpace(entry.Remark)
                ? keyPart
                : $"{keyPart} \u00B7 {entry.Remark.Trim()}";
            var detailBlock = new TextBlock
            {
                Text = detail,
                FontSize = 12,
                Foreground = AiAccountsTabThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
            };
            Grid.SetRow(detailBlock, 2);
            Grid.SetColumn(detailBlock, 0);
            Grid.SetColumnSpan(detailBlock, 5);
            row.Children.Add(detailBlock);

            return new Border
            {
                Padding = new Thickness(10, 6, 10, 6),
                CornerRadius = new CornerRadius(6),
                BorderBrush = AiAccountsTabThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
                BorderThickness = new Thickness(1),
                Background = AiAccountsTabSubtleFill(),
                Child = row,
            };
        }

        // ── 表单流 ───────────────────────────────────────────────────
        void ShowForm(string mode, AiAccountsTabEntry? entry)
        {
            if (busyGuard) return;
            isEditMode = mode == "edit";
            editId = entry?.Id ?? -1;
            AiAccountsTabSetError(formError, null);

            // 编辑模式：原值透传（含空值，不做创建态默认值替换）。
            providerBox.Text = isEditMode ? entry?.Provider ?? "" : "custom";
            nameBox.Text = entry?.Name ?? "";
            apiTypeBox.Text = isEditMode ? entry?.ApiType ?? "" : "openai-completions";
            baseURLBox.Text = entry?.BaseUrl ?? "";
            apiKeyBox.Password = entry?.ApiKey ?? "";
            remarkBox.Text = entry?.Remark ?? "";

            // 上游语义：编辑时 provider/apiType 固定（禁用输入、原值透传）。
            providerBox.IsEnabled = !isEditMode;
            apiTypeBox.IsEnabled = !isEditMode;
            formHost.Visibility = Visibility.Visible;
        }

        async Task SaveAsync()
        {
            if (busyGuard) return;
            AiAccountsTabSetError(formError, null);

            var provider = providerBox.Text.Trim();
            var name = nameBox.Text.Trim();
            var apiType = apiTypeBox.Text.Trim();
            var baseURL = baseURLBox.Text.Trim();
            var apiKey = apiKeyBox.Password;
            var remark = remarkBox.Text.Trim();

            // 上游 rules：provider/name/apiKey/baseURL/apiType 全部必填。
            if (provider.Length == 0)
            {
                AiAccountsTabSetError(formError, L10n.T("hostAiAccountProviderRequired", "Provider is required."));
                return;
            }
            if (name.Length == 0)
            {
                AiAccountsTabSetError(formError, L10n.T("hostAiAccountNameRequired", "Name is required."));
                return;
            }
            if (apiType.Length == 0)
            {
                AiAccountsTabSetError(formError, L10n.T("hostAiAccountApiTypeRequired", "API type is required."));
                return;
            }
            if (baseURL.Length == 0)
            {
                AiAccountsTabSetError(formError, L10n.T("hostAiAccountBaseUrlRequired", "Base URL is required."));
                return;
            }
            if (apiKey.Length == 0)
            {
                AiAccountsTabSetError(formError, L10n.T("hostAiAccountApiKeyRequired", "API Key is required."));
                return;
            }

            busyGuard = true;
            confirmButton.IsEnabled = false;
            bool success;
            try
            {
                var remarkOrNull = remark.Length == 0 ? null : remark;
                success = isEditMode
                    ? await WindowsBridge.UpdateAgentAccountAsync(
                        editId, provider, name, apiKey, baseURL, apiType, remarkOrNull)
                    : await WindowsBridge.CreateAgentAccountAsync(
                        provider, name, apiKey, baseURL, apiType, null, true, null, remarkOrNull);
            }
            finally
            {
                busyGuard = false;
                confirmButton.IsEnabled = true;
            }

            if (success)
            {
                formHost.Visibility = Visibility.Collapsed;
                ShowNotice(L10n.T("hostAiAccountsSaved", "Agent account saved."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(isEditMode
                    ? L10n.T("hostAiAccountsUpdateFailed", "Failed to update the agent account.")
                    : L10n.T("hostAiAccountsCreateFailed", "Failed to create the agent account."));
                AiAccountsTabSetError(formError, L10n.T(
                    "hostAiAccountsSaveFailedRetry", "Save failed. Adjust the input and try again."));
            }
        }

        async Task DeleteAsync(AiAccountsTabEntry entry)
        {
            if (busyGuard || root.XamlRoot == null) return;

            // 破坏性确认：命名账号（无名时回退 id），默认焦点在取消。
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                L10n.T("commonDelete", "Delete"),
                string.Format(
                    L10n.T("hostAiAccountDeleteConfirm", "Delete agent account \"{0}\"? This cannot be undone."),
                    string.IsNullOrWhiteSpace(entry.Name) ? "#" + entry.Id : entry.Name),
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);
            if (!confirmed) return;

            busyGuard = true;
            bool success;
            try
            {
                success = await WindowsBridge.DeleteAgentAccountAsync(entry.Id);
            }
            finally
            {
                busyGuard = false;
            }

            if (success)
            {
                ShowNotice(L10n.T("hostAiAccountsDeleted", "Agent account deleted."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAiAccountsDeleteFailed", "Failed to delete the agent account."));
            }
        }

        void ShowNotice(string message)
        {
            noticeBar.Title = message;
            noticeBar.IsOpen = true;
        }

        addButton.Click += (s, e) => ShowForm("create", null);
        refreshButton.Click += (s, e) => _ = LoadAsync(showLoading: false);
        cancelButton.Click += (s, e) => formHost.Visibility = Visibility.Collapsed;
        confirmButton.Click += (s, e) => _ = SaveAsync();
        retryButton.Click += (s, e) => _ = LoadAsync(showLoading: false);
        root.Loaded += (s, e) => _ = LoadAsync(showLoading: true);
        return root;
    }

    // ── 自包含 UI helper（AiAccountsTab 前缀防冲突） ─────────────────────

    /// <summary>卡片壳：透明填充 + CardStroke 描边 + 8px 圆角（SecurityGatewayPage
    /// 风格）；标题行尾部携带 Refresh 与 Add 两个动作。</summary>
    private static FrameworkElement AiAccountsTabCard(
        string title, out StackPanel panel, FrameworkElement addAction, FrameworkElement refreshAction)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = AiAccountsTabThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = AiAccountsTabSubtleFill(),
        };

        panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };

        var titleBlock = new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var header = new Grid { ColumnSpacing = 8 };
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(titleBlock, 0);
        Grid.SetColumn(refreshAction, 1);
        Grid.SetColumn(addAction, 2);
        header.Children.Add(titleBlock);
        header.Children.Add(refreshAction);
        header.Children.Add(addAction);
        panel.Children.Add(header);

        card.Child = panel;
        return card;
    }

    /// <summary>中性徽标：强调色低透明度底 + 圆角（SecurityGatewayPage.CreatePill 同型）。</summary>
    private static FrameworkElement AiAccountsTabPill(string text)
    {
        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            VerticalAlignment = VerticalAlignment.Center,
            Background = AiAccountsTabSubtleFill(),
            BorderBrush = AiAccountsTabThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Child = new TextBlock { Text = text, FontSize = 12 },
        };
    }

    /// <summary>带标签的表单行（标签 140px，控件拉伸）。</summary>
    private static FrameworkElement AiAccountsTabFieldRow(string label, FrameworkElement control)
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

    private static FrameworkElement AiAccountsTabButtonRow(Button confirm, Button cancel)
    {
        var row = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            HorizontalAlignment = HorizontalAlignment.Right,
        };
        confirm.Padding = new Thickness(18, 4, 18, 4);
        cancel.Padding = new Thickness(18, 4, 18, 4);
        row.Children.Add(cancel);
        row.Children.Add(confirm);
        return row;
    }

    private static Button AiAccountsTabSmallButton(string label, string? glyph)
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

    /// <summary>加载错误面：错误 InfoBar + 尾部 Retry 按钮（配合 AiAccountsTabShowError）。</summary>
    private static FrameworkElement AiAccountsTabErrorRow(out InfoBar bar, out Button retryButton)
    {
        var row = new Grid { ColumnSpacing = 8, Margin = new Thickness(8, 8, 8, 0) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        bar = new InfoBar
        {
            Title = L10n.T("hostAiAccountsLoadFailed", "Failed to load agent accounts."),
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

    private static void AiAccountsTabShowError(InfoBar bar, Button retryButton, bool show)
    {
        bar.IsOpen = show;
        retryButton.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
    }

    private static TextBlock AiAccountsTabErrorText()
    {
        return new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = AiAccountsTabThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
            Visibility = Visibility.Collapsed,
        };
    }

    private static void AiAccountsTabSetError(TextBlock target, string? message)
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

    private static FrameworkElement AiAccountsTabEmptyText(string text)
    {
        return new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = AiAccountsTabThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        };
    }

    /// <summary>上游 maskKey：空值返回空串（行内回退 "--"）、≤6 位原样、
    /// 其余前 3 + "****" + 后 3。</summary>
    private static string AiAccountsTabMaskKey(string value)
    {
        if (string.IsNullOrEmpty(value)) return "";
        if (value.Length <= 6) return value;
        return $"{value[..3]}****{value[^3..]}";
    }

    private static string? AiAccountsTabString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static long AiAccountsTabLong(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number &&
            prop.TryGetInt64(out var value))
        {
            return value;
        }
        return -1;
    }

    private static Brush AiAccountsTabThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    /// <summary>CardStroke 约 4% 透明度着色填充，Mica/LayerFill 上两种主题均可读
    /// （SecurityGatewayPage.CreateSubtleFill 同型实现）。</summary>
    private static Brush AiAccountsTabSubtleFill()
    {
        var stroke = AiAccountsTabThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Microsoft.UI.Colors.Gray;
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}

/// <summary>桥返回的单个渠道账号条目视图（上游 AgentAccountItem 的客户端子集）。</summary>
internal sealed class AiAccountsTabEntry
{
    public long Id { get; init; }
    public string Name { get; init; } = "";
    public string Provider { get; init; } = "";
    public string ApiType { get; init; } = "";
    public string BaseUrl { get; init; } = "";
    public string ApiKey { get; init; } = "";
    public string Remark { get; init; } = "";
}
