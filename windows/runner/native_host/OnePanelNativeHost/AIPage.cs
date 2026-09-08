using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native AI module page: a tab shell mirroring the upstream 1Panel AI
/// sidebar sections, with 「本地模型」 hosting the original Ollama model list
/// plus connection card (upstream model list semantics: name, size, modified
/// date, create by model name, recreate of an existing model, delete with
/// confirmation naming the model; AI domain tab semantics for the connection
/// card: Ollama discovery with domain binding). 账号 / MCP / 智能体 / GPU 四个
/// Tab 委托给并行实现的静态 Tab 类（每次切换重建，数据重载）。
/// </summary>
public sealed class AIPage : ModulePageBase
{
    private readonly List<AIModelEntry> _models = new();
    private readonly ErrorToast _errorToast = new();
    private bool _isBusy;

    // Connection card state: null until the discovery payload arrives; the
    // card falls back to a neutral "--" placeholder while unknown.
    private OllamaContextEntry? _connection;
    private StackPanel? _connectionCardBody;
    private InfoBar? _bindInfoBar;

    // Tab shell state (tab strip row + per-tab content host inside
    // ModuleContentPresenter). Switching tabs clears and rebuilds the host.
    private int _selectedTab;
    private ContentPresenter? _tabContentHost;
    private readonly List<Button> _tabButtons = new();

    /// <summary>
    /// Tab 注册表，顺序对应上游 AI 侧边栏（模型账号 → MCP → 智能体 → GPU →
    /// 本地模型），客户端按任务要求排列：本地模型 → 账号 → MCP → 智能体 → GPU。
    /// 键为 hostAiTab* 前缀，缺键回落英文。
    /// </summary>
    private static readonly (string Key, string English)[] TabItems =
    {
        ("hostAiTabModels", "Local Models"),
        ("hostAiTabAccounts", "Accounts"),
        ("hostAiTabMcp", "MCP"),
        ("hostAiTabAgents", "Agents"),
        ("hostAiTabGpu", "GPU"),
    };

    public AIPage()
    {
        PageTitle = L10n.T("serverModuleAi", "AI");
        BuildTabShell();
    }

    protected override void OnPageShown()
    {
        // 每次显示当前 Tab 都重建内容区（数据重载），与切换 Tab 同语义。
        SelectTab(_selectedTab);
    }

    protected override void OnRefreshClicked()
    {
        SelectTab(_selectedTab);
    }

    /// <summary>
    /// Builds the tab shell once and mounts it into ModuleContentPresenter:
    /// a horizontal tab strip on top (same visual language as the website
    /// config shell: plain buttons, AccentButtonStyle marks the selection)
    /// and a content host below that each tab rebuilds into.
    /// </summary>
    private void BuildTabShell()
    {
        _tabButtons.Clear();

        var root = new Grid { RowSpacing = 8 };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // Tab 行
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }); // 内容区

        var tabStrip = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
            Margin = new Thickness(8, 8, 8, 0),
        };
        for (int i = 0; i < TabItems.Length; i++)
        {
            var index = i;
            var button = new Button
            {
                Content = L10n.T(TabItems[index].Key, TabItems[index].English),
                Padding = new Thickness(12, 6, 12, 6),
                CornerRadius = new CornerRadius(6),
            };
            button.Click += (s, e) => SelectTab(index);
            _tabButtons.Add(button);
            tabStrip.Children.Add(button);
        }

        var tabScroll = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollMode = ScrollMode.Enabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Disabled,
            Content = tabStrip,
        };
        Grid.SetRow(tabScroll, 0);
        root.Children.Add(tabScroll);

        _tabContentHost = new ContentPresenter
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        Grid.SetRow(_tabContentHost, 1);
        root.Children.Add(_tabContentHost);

        ModuleContentPresenter.Content = root;
    }

    /// <summary>
    /// 切换 Tab：更新选中态并清空、重建内容区（每次重新 Build，数据重载）。
    /// 「本地模型」走原有加载流程（页面级 Loading 态 + 桥调用），其余 Tab
    /// 直接挂载对应 Tab 类的新实例内容。
    /// </summary>
    private void SelectTab(int index)
    {
        _selectedTab = index;
        for (int i = 0; i < _tabButtons.Count; i++)
        {
            _tabButtons[i].Style = i == index
                ? (Style)Application.Current.Resources["AccentButtonStyle"]
                : null;
        }

        if (_tabContentHost == null) return;

        // 清空旧内容再重建，避免跨 Tab 残留旧可视树。
        _tabContentHost.Content = null;

        switch (index)
        {
            case 1:
                _tabContentHost.Content = AiAccountsTab.Build();
                break;
            case 2:
                _tabContentHost.Content = AiMcpTab.Build();
                break;
            case 3:
                _tabContentHost.Content = AiAgentsTab.Build();
                break;
            case 4:
                _tabContentHost.Content = AiGpuTab.Build();
                break;
            default:
                _BuildLocalModelContent();
                break;
        }
    }

    /// <summary>
    /// 「本地模型」Tab（改造前的页面全部内容）：Ollama 模型列表 + 连接卡 +
    /// 域名绑定。加载态沿用页面级 SetState，模型数据就绪后由
    /// <see cref="BuildContent"/> 挂载到当前 Tab 内容区。
    /// </summary>
    private void _BuildLocalModelContent()
    {
        SetState(PageState.Loading);
        _ = RefreshAsync();
    }

    private async System.Threading.Tasks.Task RefreshAsync()
    {
        // The page state machine stays owned by the model list; the
        // connection context loads right after so both bridge calls share
        // the _isBusy guard.
        await LoadModelsAsync(showLoadingState: true);
        await LoadConnectionAsync();
    }

    /// <summary>
    /// Loads the model list through the Dart business core. With
    /// <paramref name="showLoadingState"/> the page swaps to the loading
    /// spinner; otherwise the current content stays visible (silent refresh
    /// after row operations) and failures surface via the error toast.
    /// </summary>
    private async System.Threading.Tasks.Task LoadModelsAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            if (showLoadingState) SetState(PageState.Loading);

            var result = await WindowsBridge.GetAIModelsAsync();
            // Tab 壳改造：await 返回时用户可能已切到其他 Tab，丢弃本次结果，
            // 避免把「本地模型」的加载/错误/列表态覆盖到当前 Tab。
            if (_selectedTab != 0) return;
            if (result == null)
            {
                // Bridge failure: full error state on initial load, toast on refresh.
                if (showLoadingState)
                {
                    SetState(PageState.Error);
                }
                else
                {
                    _errorToast.Show(L10n.T("hostAiModelsRefreshFailed", "Failed to refresh AI models."));
                }
                return;
            }

            var models = ParseModels(result.Value);
            if (models.Count == 0)
            {
                // Tab 壳常驻于 _contentPresenter，Empty 态会整页隐藏 Tab 条——
                // 空列表保持 Content 态，由列表区自渲染空态说明。
                SetState(PageState.Content);
                BuildContent(models);
                return;
            }

            _models.Clear();
            _models.AddRange(models);
            BuildContent(models);
            SetState(PageState.Content);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Loads the Ollama discovery context for the connection card. A null
    /// bridge result stays silent by design: the card falls back to the "--"
    /// placeholder instead of surfacing an error (found=false is the neutral
    /// "not installed" information state).
    /// </summary>
    private async System.Threading.Tasks.Task LoadConnectionAsync()
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var result = await WindowsBridge.GetOllamaContextAsync();
            // 同上：切走后不再渲染连接卡（渲染目标属于已丢弃的旧内容树）。
            if (_selectedTab != 0) return;
            _connection = result == null ? null : ParseOllamaContext(result.Value);
            RenderConnectionCard();
        }
        finally
        {
            _isBusy = false;
        }
    }

    private static OllamaContextEntry? ParseOllamaContext(JsonElement json)
    {
        if (json.ValueKind != JsonValueKind.Object) return null;

        var entry = new OllamaContextEntry
        {
            Found = TryGetBool(json, "found"),
            Name = TryGetString(json, "name") ?? "",
            Status = TryGetString(json, "status") ?? "",
            HasAppInstallId = json.TryGetProperty("appInstallId", out var idProp) &&
                              idProp.ValueKind == JsonValueKind.Number,
            AppInstallId = TryGetInt64(json, "appInstallId"),
        };

        if (json.TryGetProperty("candidates", out var candidates) &&
            candidates.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in candidates.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.Number && item.TryGetInt64(out var value))
                {
                    entry.Candidates.Add(value);
                }
            }
        }

        return entry;
    }

    private List<AIModelEntry> ParseModels(JsonElement json)
    {
        var models = new List<AIModelEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                models.Add(new AIModelEntry
                {
                    Id = TryGetInt64(item, "id"),
                    Name = TryGetString(item, "name") ?? L10n.T("hostAiModelUnknownName", "Unknown"),
                    Size = TryGetString(item, "size") ?? "",
                    Modified = TryGetString(item, "modified") ?? "",
                });
            }
        }

        return models;
    }

    private void BuildContent(List<AIModelEntry> models)
    {
        // Root layout: CommandBar on top, scrollable list below (relative rows).
        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        // Create model (upstream add-model drawer): opens the create dialog.
        var createButton = new AppBarButton
        {
            Icon = new FontIcon { Glyph = "\uE710" },
            Label = L10n.T("aiModelCreate", "Create model"),
        };
        createButton.Click += (s, e) => _ = ShowCreateModelDialogAsync();

        var refreshButton = new AppBarButton
        {
            Icon = new FontIcon { Glyph = "\uE72C" },
            Label = L10n.T("commonRefresh", "Refresh"),
        };
        refreshButton.Click += async (s, e) => await RefreshAsync();

        var commandBar = new CommandBar
        {
            DefaultLabelPosition = CommandBarDefaultLabelPosition.Right,
            Margin = new Thickness(4, 0, 4, 0),
        };
        commandBar.PrimaryCommands.Add(createButton);
        commandBar.PrimaryCommands.Add(refreshButton);
        Grid.SetRow(commandBar, 0);
        root.Children.Add(commandBar);

        var scrollViewer = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 0, 8),
        };
        Grid.SetRow(scrollViewer, 1);

        var list = new ListView
        {
            SelectionMode = ListViewSelectionMode.None,
            IsItemClickEnabled = false,
        };

        foreach (var model in models)
        {
            list.Items.Add(CreateModelItem(model));
        }

        // Connection card on top, model list below; the wrapper owns the
        // page gutter so both children stay edge-aligned.
        var content = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Margin = new Thickness(8, 0, 8, 0),
            Spacing = 12,
        };
        content.Children.Add(BuildConnectionCard());
        content.Children.Add(list);

        scrollViewer.Content = content;
        root.Children.Add(scrollViewer);

        // Failure toast floats above the list, bottom-aligned (kept in the
        // visual tree so Show() actually renders).
        _errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(_errorToast, 1);
        AttachToast(root, _errorToast);

        if (_tabContentHost == null) return;
        _tabContentHost.Content = root;
    }

    /// <summary>
    /// Connection card shown above the model list: Ollama discovery details
    /// (instance id, name, status) with the domain binding entry point. Card
    /// chrome matches the dashboard cards (stroke border + faint tinted fill).
    /// </summary>
    private FrameworkElement BuildConnectionCard()
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = CreateSubtleFill(),
        };

        _connectionCardBody = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 10,
        };

        RenderConnectionCard();
        card.Child = _connectionCardBody;
        return card;
    }

    /// <summary>
    /// Rebuilds the connection card body from the current discovery state:
    /// "--" placeholder while unknown or after a bridge failure, a neutral
    /// note when Ollama is not installed, otherwise the instance details
    /// plus the bind-domain entry point and the bind result hint.
    /// </summary>
    private void RenderConnectionCard()
    {
        var body = _connectionCardBody;
        if (body == null) return;

        body.Children.Clear();

        body.Children.Add(new TextBlock
        {
            Text = L10n.T("hostAiConnectionTitle", "Connection"),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        });

        var context = _connection;
        if (context == null)
        {
            // Bridge failure or not loaded yet: neutral placeholder.
            body.Children.Add(new TextBlock
            {
                Text = "--",
                FontSize = 13,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            });
            return;
        }

        if (!context.Found)
        {
            // Neutral information state, not an error: Ollama is optional.
            body.Children.Add(new TextBlock
            {
                Text = L10n.T("hostAiOllamaNotDetected", "Ollama not detected on this server."),
                FontSize = 13,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            });
            return;
        }

        var bag = new Grid();
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        AddConnectionRow(bag, 0, L10n.T("aiAppInstallIdLabel", "App Install ID"),
            context.HasAppInstallId ? context.AppInstallId.ToString(CultureInfo.InvariantCulture) : "");
        AddConnectionRow(bag, 1, L10n.T("commonName", "Name"), context.Name);
        AddConnectionRow(bag, 2, L10n.T("commonStatus", "Status"), context.Status);
        body.Children.Add(bag);

        if (context.Candidates.Count > 1)
        {
            body.Children.Add(new TextBlock
            {
                Text = $"Multiple Ollama instances detected: {string.Join(", ", context.Candidates)} (using first/running)",
                FontSize = 11,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            });
        }

        // Result placeholder for this batch: no read handler exists for the
        // current binding yet, so a successful bind only surfaces this hint.
        _bindInfoBar = new InfoBar
        {
            Severity = InfoBarSeverity.Success,
            Message = L10n.T("hostAiDomainBoundHint", "Domain bound. Refresh to see connection details."),
            IsClosable = true,
            IsOpen = false,
        };
        body.Children.Add(_bindInfoBar);

        if (context.HasAppInstallId)
        {
            var bindButton = new Button { Content = L10n.T("aiBindDomain", "Bind domain") };
            bindButton.Click += (s, e) => _ = ShowBindDomainDialogAsync();
            body.Children.Add(bindButton);
        }
    }

    /// <summary>Places one label+value row into the connection details grid,
    /// matching the dashboard InfoBag look ("--" for missing data).</summary>
    private static void AddConnectionRow(Grid bag, int row, string label, string value)
    {
        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 0, 12, 0),
        };
        Grid.SetRow(labelBlock, row);
        Grid.SetColumn(labelBlock, 0);
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
        Grid.SetColumn(valueBlock, 1);
        bag.Children.Add(valueBlock);
    }

    /// <summary>Opens the success hint after a completed domain bind.</summary>
    private void ShowBindSuccessInfo()
    {
        if (_bindInfoBar != null)
        {
            _bindInfoBar.IsOpen = true;
        }
    }

    /// <summary>
    /// Bind-domain form dialog, mirroring the upstream AI domain tab: a
    /// required domain plus an optional comma-separated IP allowlist passed
    /// through as-is. Domain binding is an overwriting write, so a
    /// ConfirmDialog runs between the form and the bridge call. The dialog
    /// instance is rebuilt for every attempt (a ContentDialog instance can
    /// only be shown once) and previous input is carried over, keeping the
    /// form editable after a failed submit. _isBusy is held across the whole
    /// dialog lifetime so page operations stay blocked.
    /// </summary>
    private async System.Threading.Tasks.Task ShowBindDomainDialogAsync()
    {
        var context = _connection;
        if (_isBusy || context == null || !context.Found || !context.HasAppInstallId) return;
        _isBusy = true;

        try
        {
            string? pendingDomain = null;
            string? pendingIpList = null;
            string? pendingError = null;

            while (true)
            {
                var domainBox = new TextBox
                {
                    Header = L10n.T("aiTabDomain", "Domain"),
                    PlaceholderText = "ai.example.com",
                    Text = pendingDomain ?? "",
                };

                var ipListBox = new TextBox
                {
                    Header = L10n.T("hostAiIpAllowlistLabel", "IP allowlist (optional, comma-separated)"),
                    Text = pendingIpList ?? "",
                };

                var errorText = new TextBlock
                {
                    FontSize = 12,
                    TextWrapping = TextWrapping.Wrap,
                    Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                    Visibility = Visibility.Collapsed,
                };

                // Any edit clears the pending inline validation error.
                domainBox.TextChanged += (s, e) => SetFormError(errorText, null);

                var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
                form.Children.Add(domainBox);
                form.Children.Add(ipListBox);
                form.Children.Add(errorText);

                var dialog = new ContentDialog
                {
                    Title = L10n.T("aiBindDomain", "Bind domain"),
                    Content = form,
                    PrimaryButtonText = L10n.T("firewallBindAction", "Bind"),
                    CloseButtonText = L10n.T("commonCancel", "Cancel"),
                    DefaultButton = ContentDialogButton.Primary,
                    XamlRoot = XamlRoot,
                };

                dialog.Closing += (s, args) =>
                {
                    if (args.Result != ContentDialogResult.Primary) return;

                    // Inline validation: on an empty domain cancel the close
                    // so the dialog stays open and the error shows next to
                    // the field.
                    if (string.IsNullOrWhiteSpace(domainBox.Text))
                    {
                        args.Cancel = true;
                        SetFormError(errorText, L10n.T("websitesDomainValidationRequired", "Domain is required."));
                    }
                };

                if (pendingError != null)
                {
                    SetFormError(errorText, pendingError);
                    pendingError = null;
                }

                var result = await dialog.ShowAsync();
                if (result != ContentDialogResult.Primary) return; // Cancelled.

                var domain = domainBox.Text.Trim();
                var ipList = string.IsNullOrWhiteSpace(ipListBox.Text) ? null : ipListBox.Text;
                pendingDomain = domainBox.Text;
                pendingIpList = ipListBox.Text;

                // Overwriting write: require an explicit second confirmation
                // naming the target instance before touching the bridge.
                var confirmed = await ConfirmDialog.ShowAsync(
                    XamlRoot,
                    L10n.T("aiBindDomain", "Bind Domain"),
                    $"Bind \"{domain}\" to Ollama instance #{context.AppInstallId}?\nThe existing domain binding will be overwritten.",
                    L10n.T("firewallBindAction", "Bind"),
                    L10n.T("commonCancel", "Cancel"),
                    isDestructive: false);

                if (!confirmed) continue; // Back to the form; input carried over.

                var success = await WindowsBridge.BindAIDomainAsync(context.AppInstallId, domain, ipList);
                if (success)
                {
                    ShowBindSuccessInfo();
                    return;
                }

                _errorToast.Show(L10n.T("hostAiBindDomainFailed", "Failed to bind domain."));
                pendingError = L10n.T("hostAiBindFailedRetry", "Bind failed. Adjust the input and try again.");
                // Loop reopens the form so the failure stays editable.
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    private FrameworkElement CreateModelItem(AIModelEntry model)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = model,
        };

        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // AI/robot glyph identifies the row as a local model.
        var icon = new FontIcon
        {
            Glyph = "\uE99A",
            FontSize = 16,
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(icon, 0);
        grid.Children.Add(icon);

        // Model name (primary text, elides instead of forcing wide windows).
        var nameBlock = new TextBlock
        {
            Text = model.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(12, 0, 0, 0),
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
        };
        ToolTipService.SetToolTip(nameBlock, model.Name);
        Grid.SetColumn(nameBlock, 1);
        grid.Children.Add(nameBlock);

        // Model size, "-" when unknown (upstream shows row.size || '-').
        var sizeBlock = new TextBlock
        {
            Text = string.IsNullOrWhiteSpace(model.Size) ? "-" : model.Size,
            FontSize = 12,
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Right,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            Margin = new Thickness(16, 0, 0, 0),
            MinWidth = 64,
        };
        Grid.SetColumn(sizeBlock, 2);
        grid.Children.Add(sizeBlock);

        // Last modified date-time (right aligned, secondary color).
        var modifiedText = FormatDateString(model.Modified);
        if (!string.IsNullOrEmpty(modifiedText))
        {
            var modifiedBlock = new TextBlock
            {
                Text = modifiedText,
                FontSize = 12,
                VerticalAlignment = VerticalAlignment.Center,
                HorizontalAlignment = HorizontalAlignment.Right,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                Margin = new Thickness(16, 0, 0, 0),
                MinWidth = 120,
            };
            Grid.SetColumn(modifiedBlock, 3);
            grid.Children.Add(modifiedBlock);
        }

        // Row actions: "more" menu holding recreate (re-pull, upstream row
        // retry) and the destructive delete, mirroring the upstream row
        // buttons ordering (retry before delete).
        var moreButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE712", FontSize = 14 },
            Background = null,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(8, 4, 8, 4),
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(16, 0, 0, 0),
        };
        ToolTipService.SetToolTip(moreButton, L10n.T("hostAiModelActions", "Model actions"));
        moreButton.Flyout = BuildRowFlyout(model);
        Grid.SetColumn(moreButton, 4);
        grid.Children.Add(moreButton);

        return grid;
    }

    private MenuFlyout BuildRowFlyout(AIModelEntry model)
    {
        var flyout = new MenuFlyout();

        var recreateItem = new MenuFlyoutItem
        {
            Text = L10n.T("hostAiModelRecreateAction", "Recreate"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        recreateItem.Click += (s, e) => _ = RecreateModelAsync(model);
        flyout.Items.Add(recreateItem);

        var deleteItem = new MenuFlyoutItem
        {
            Text = L10n.T("commonDelete", "Delete"),
            Icon = new FontIcon { Glyph = "\uE74D" },
        };
        deleteItem.Click += (s, e) => _ = DeleteModelAsync(model);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    private async System.Threading.Tasks.Task DeleteModelAsync(AIModelEntry model)
    {
        if (_isBusy) return;

        // Destructive confirmation; the message carries the model name,
        // matching the upstream delete dialog that lists selected models.
        var confirmed = await ConfirmDialog.ShowAsync(
            XamlRoot,
            L10n.T("hostAiModelDeleteTitle", "Delete AI Model"),
            $"Are you sure you want to delete model \"{model.Name}\"?\nThis action cannot be undone.",
            L10n.T("commonDelete", "Delete"),
            L10n.T("commonCancel", "Cancel"),
            isDestructive: true);

        if (!confirmed) return;

        _isBusy = true;
        try
        {
            var success = await WindowsBridge.DeleteAIModelAsync(model.Id);
            if (success)
            {
                await LoadModelsAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{model.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Recreates (re-pulls) an existing model. Non-destructive confirmation
    /// naming the model, matching the upstream per-row retry action; success
    /// silently refreshes the list.
    /// </summary>
    private async System.Threading.Tasks.Task RecreateModelAsync(AIModelEntry model)
    {
        if (_isBusy) return;

        // Non-destructive confirmation; the message carries the model name
        // and states that the model will be rebuilt.
        var confirmed = await ConfirmDialog.ShowAsync(
            XamlRoot,
            L10n.T("aiModelRecreate", "Recreate AI Model"),
            $"Are you sure you want to recreate model \"{model.Name}\"?\nThe model will be pulled again and rebuilt.",
            L10n.T("hostAiModelRecreateAction", "Recreate"),
            L10n.T("commonCancel", "Cancel"),
            isDestructive: false);

        if (!confirmed) return;

        _isBusy = true;
        try
        {
            var success = await WindowsBridge.RecreateAIModelAsync(model.Name);
            if (success)
            {
                await LoadModelsAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to recreate \"{model.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Create-model form dialog, mirroring the upstream add-model drawer: a
    /// single required "Ollama model name" input (e.g. llama3:8b). _isBusy is
    /// held across the whole dialog lifetime so the CommandBar button cannot
    /// open a second dialog and row operations stay blocked. The dialog stays
    /// open while the bridge call runs and only closes on success; on failure
    /// the toast shows and the form stays editable.
    /// </summary>
    private async System.Threading.Tasks.Task ShowCreateModelDialogAsync()
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var nameBox = new TextBox
            {
                Header = L10n.T("aiModelNameLabel", "Ollama model name"),
                PlaceholderText = "llama3:8b",
            };

            var errorText = new TextBlock
            {
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                Visibility = Visibility.Collapsed,
            };

            // Any edit clears the pending inline validation error.
            nameBox.TextChanged += (s, e) => SetFormError(errorText, null);

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(nameBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = L10n.T("aiModelCreate", "Create model"),
                Content = form,
                PrimaryButtonText = L10n.T("commonCreate", "Create"),
                CloseButtonText = L10n.T("commonCancel", "Cancel"),
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            bool submitting = false;
            bool createSucceeded = false;

            async System.Threading.Tasks.Task SubmitCreateAsync()
            {
                var success = await WindowsBridge.CreateAIModelAsync(nameBox.Text.Trim());
                if (success)
                {
                    createSucceeded = true;
                    dialog.Hide(); // Closing lets this programmatic close pass.
                }
                else
                {
                    submitting = false;
                    _errorToast.Show(L10n.T("hostAiModelCreateFailed", "Failed to create model."));
                    SetFormError(errorText, L10n.T("hostAiCreateFailedRetry", "Create failed. Adjust the input and try again."));
                }
            }

            dialog.Closing += (s, args) =>
            {
                // Programmatic close after a successful create passes through.
                if (createSucceeded) return;

                // Swallow every close attempt while the bridge call is in
                // flight so the dialog cannot outlive the submit result.
                if (submitting)
                {
                    args.Cancel = true;
                    return;
                }

                if (args.Result != ContentDialogResult.Primary) return;

                // Inline validation: on an empty name cancel the close so the
                // dialog stays open and the error shows next to the field.
                if (string.IsNullOrWhiteSpace(nameBox.Text))
                {
                    args.Cancel = true;
                    SetFormError(errorText, L10n.T("aiModelNameRequired", "Model name is required."));
                    return;
                }

                // Keep the dialog open during submission; close only on success.
                args.Cancel = true;
                submitting = true;
                _ = SubmitCreateAsync();
            };

            await dialog.ShowAsync();
            if (!createSucceeded) return;

            // The dialog is closed; release the dialog-lifetime guard so the
            // _isBusy-guarded silent refresh below can actually run.
            _isBusy = false;
            await LoadModelsAsync(showLoadingState: false);
        }
        finally
        {
            _isBusy = false;
        }
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

    private static Brush TryGetThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    /// <summary>
    /// Translucent card fill derived from the theme card stroke (~4% alpha),
    /// matching the dashboard card visual language over Mica/LayerFill.
    /// </summary>
    private Brush CreateSubtleFill()
    {
        var stroke = TryGetThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Microsoft.UI.Colors.Gray;
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }

    /// <summary>
    /// Formats an ISO-style date string for display; falls back to the raw
    /// value when unparsable (handles Go-style 9-digit fractional seconds).
    /// </summary>
    private static string FormatDateString(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return "";

        if (DateTimeOffset.TryParse(raw, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed))
        {
            return parsed.ToLocalTime().ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture);
        }

        // Normalize ".123456789Z" fractional precision before retrying.
        var dotIndex = raw.IndexOf('.');
        if (dotIndex > 0)
        {
            var end = dotIndex + 1;
            while (end < raw.Length && char.IsDigit(raw[end])) end++;
            var normalized = raw[..dotIndex] + raw[end..];
            if (DateTimeOffset.TryParse(normalized, CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed))
            {
                return parsed.ToLocalTime().ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture);
            }
        }

        return raw;
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

    private static long TryGetInt64(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number)
        {
            return prop.TryGetInt64(out var value) ? value : (long)prop.GetDouble();
        }
        return 0;
    }

    private static bool TryGetBool(JsonElement element, string property)
    {
        return element.ValueKind == JsonValueKind.Object &&
               element.TryGetProperty(property, out var prop) &&
               prop.ValueKind == JsonValueKind.True;
    }

    /// <summary>View over the Ollama discovery payload from the bridge.</summary>
    private sealed class OllamaContextEntry
    {
        public bool Found { get; set; }
        public bool HasAppInstallId { get; set; }
        public long AppInstallId { get; set; }
        public string Name { get; set; } = "";
        public string Status { get; set; } = "";
        public List<long> Candidates { get; set; } = new();
    }

    private sealed class AIModelEntry
    {
        public long Id { get; set; }
        public string Name { get; set; } = "";
        public string Size { get; set; } = "";
        public string Modified { get; set; } = "";
    }
}
