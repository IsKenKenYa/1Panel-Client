using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Logs (log center) module page. Read-only mirror of the upstream
/// 1Panel web frontend log center (frontend/src/views/log) with its three
/// tabs: Operation / Login / System.
/// - Operation tab: one row per API operation log with a status badge
///   (2xx green / 4xx orange / 5xx red, judged by the status prefix),
///   an HTTP method badge (GET blue, POST green, PUT orange, DELETE red,
///   PATCH purple), the request path in a monospace face, source/ip as the
///   secondary line and the truncated message (full text on a tooltip).
/// - Login tab: login status badge (Success green / Failed red), the IP as
///   the primary text, address + formatted createdAt as the secondary line
///   and the truncated message.
/// - System tab: file-name input (required, inline validation) + a
///   "Core logs" switch (maps to the upstream Agent/Core radio: Core- prefixed
///   files) and a Load action; the returned lines render read-only in a
///   monospace view with a line-number gutter. Empty lines surface the Empty
///   state; before the first load a hint text is shown instead.
/// Tab switching uses the native WinUI SelectorBar control (verified available
/// in the installed WindowsAppSDK WinUI metadata). Every tab reloads on switch.
/// All data flows through WindowsBridge (method channel to the Dart core);
/// no direct HTTP from the native layer.
/// </summary>
public sealed class LogsPage : ModulePageBase
{
    private readonly List<OperationLogEntry> _operationLogs = new();
    private readonly List<LoginLogEntry> _loginLogs = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads and the System-tab load action.</summary>
    private bool _isBusy;

    /// <summary>Currently selected tab; Operation is the default on page shown.</summary>
    private LogTab _selectedTab = LogTab.Operation;

    // System-tab form/result state persisted across chrome rebuilds (the
    // whole chrome is rebuilt after every state change, matching the other
    // module pages, so control values are re-seeded from these fields).
    private string _systemFileName = "";
    private bool _systemUseCoreLogs;
    private bool _systemLoaded;
    private string _systemLogText = "";
    private long _systemTotalLines;
    private int _systemLineCount;

    public LogsPage()
    {
        PageTitle = L10n.T("hostNavLogs", "Logs");
    }

    /// <summary>Log center tabs, in upstream tab order.</summary>
    private enum LogTab
    {
        Operation,
        Login,
        System,
    }

    protected override async void OnPageShown()
    {
        // The Operation tab is the default tab on every page show.
        _selectedTab = LogTab.Operation;
        await LoadCurrentTabAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        // Refresh always shows the spinner; it may run from the Empty/Error
        // panels where no chrome (and therefore no toast) is visible.
        await LoadCurrentTabAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point that dispatches to the selected tab's loader.</summary>
    private async Task LoadCurrentTabAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            switch (_selectedTab)
            {
                case LogTab.Operation:
                    await LoadOperationLogsCoreAsync(showLoadingState);
                    break;
                case LogTab.Login:
                    await LoadLoginLogsCoreAsync(showLoadingState);
                    break;
                case LogTab.System:
                    await LoadSystemLogCoreAsync(showLoadingState);
                    break;
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    private async Task LoadOperationLogsCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetOperationLogsAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial/tab-switch load,
            // toast on a silent reload.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostLogsRefreshOperationFailed", "Failed to refresh operation logs."));
            }
            return;
        }

        var logs = ParseOperationLogs(result.Value);
        _operationLogs.Clear();
        if (logs.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        _operationLogs.AddRange(logs);
        BuildChrome();
        SetState(PageState.Content);
    }

    private async Task LoadLoginLogsCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetLoginLogsAsync();

        if (result == null)
        {
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostLogsRefreshLoginFailed", "Failed to refresh login logs."));
            }
            return;
        }

        var logs = ParseLoginLogs(result.Value);
        _loginLogs.Clear();
        if (logs.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        _loginLogs.AddRange(logs);
        BuildChrome();
        SetState(PageState.Content);
    }

    /// <summary>
    /// Loads the system log file. On a first load the spinner replaces the
    /// chrome and a bridge failure surfaces the full Error state; on a reload
    /// (the Load button with content already shown) the current log stays
    /// visible and failures surface via the toast instead.
    /// </summary>
    private async Task LoadSystemLogCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        // The file name is required by the bridge contract; the Load button
        // validates it inline, the guard here only covers programmatic paths.
        var fileName = _systemFileName.Trim();
        if (fileName.Length == 0)
        {
            SetState(PageState.Error);
            return;
        }

        var result = await WindowsBridge.GetSystemLogContentAsync(fileName, _systemUseCoreLogs);

        if (result == null)
        {
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show($"Failed to load log file \"{fileName}\".");
            }
            return;
        }

        var lines = ParseLogLines(result.Value, out var totalLines);
        _systemLoaded = true;
        _systemTotalLines = totalLines;
        _systemLineCount = lines.Count;

        if (lines.Count == 0)
        {
            // Empty file content counts as the Empty state.
            SetState(PageState.Empty);
            return;
        }

        _systemLogText = FormatLogText(lines);
        BuildChrome();
        SetState(PageState.Content);
    }

    /// <summary>
    /// Load-button handler with the required file-name inline validation.
    /// The first load swaps to the spinner; a reload keeps the current log
    /// visible and reports failures through the toast.
    /// </summary>
    private async Task LoadSystemLogFromFormAsync(TextBox fileNameBox, TextBlock errorText)
    {
        if (string.IsNullOrWhiteSpace(fileNameBox.Text))
        {
            SetFormError(errorText, L10n.T("hostLogsFileNameRequired", "File name is required."));
            return;
        }

        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadSystemLogCoreAsync(showLoadingState: !_systemLoaded);
        }
        finally
        {
            _isBusy = false;
        }
    }

    private static List<OperationLogEntry> ParseOperationLogs(JsonElement json)
    {
        var logs = new List<OperationLogEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                logs.Add(new OperationLogEntry
                {
                    Id = TryGetInt64(item, "id"),
                    Source = TryGetString(item, "source") ?? "",
                    Ip = TryGetString(item, "ip") ?? "",
                    Path = TryGetString(item, "path") ?? "",
                    Method = TryGetString(item, "method") ?? "",
                    Status = TryGetString(item, "status") ?? "",
                    Message = TryGetString(item, "message") ?? "",
                });
            }
        }

        return logs;
    }

    private static List<LoginLogEntry> ParseLoginLogs(JsonElement json)
    {
        var logs = new List<LoginLogEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                logs.Add(new LoginLogEntry
                {
                    Id = TryGetInt64(item, "id"),
                    Ip = TryGetString(item, "ip") ?? "",
                    Address = TryGetString(item, "address") ?? "",
                    Status = TryGetString(item, "status") ?? "",
                    Message = TryGetString(item, "message") ?? "",
                    CreatedAt = TryGetString(item, "createdAt") ?? "",
                });
            }
        }

        return logs;
    }

    /// <summary>Parses {lines: string[], totalLines: long} from the system-log payload.</summary>
    private static List<string> ParseLogLines(JsonElement json, out long totalLines)
    {
        var lines = new List<string>();
        totalLines = 0;

        if (json.ValueKind == JsonValueKind.Object)
        {
            if (json.TryGetProperty("totalLines", out var total) &&
                total.ValueKind == JsonValueKind.Number)
            {
                totalLines = total.TryGetInt64(out var value) ? value : (long)total.GetDouble();
            }

            if (json.TryGetProperty("lines", out var array) &&
                array.ValueKind == JsonValueKind.Array)
            {
                foreach (var line in array.EnumerateArray())
                {
                    lines.Add(line.ValueKind == JsonValueKind.String
                        ? line.GetString() ?? ""
                        : line.GetRawText());
                }
            }
        }

        return lines;
    }

    /// <summary>Renders the lines with a right-aligned line-number gutter.</summary>
    private static string FormatLogText(List<string> lines)
    {
        var numberWidth = lines.Count.ToString(CultureInfo.InvariantCulture).Length;
        var builder = new StringBuilder();

        for (var i = 0; i < lines.Count; i++)
        {
            if (i > 0) builder.Append("\r\n");
            builder.Append((i + 1).ToString(CultureInfo.InvariantCulture).PadLeft(numberWidth))
                   .Append("  ")
                   .Append(lines[i]);
        }

        return builder.ToString();
    }

    /// <summary>
    /// Builds the whole chrome: tab header (SelectorBar + refresh) on top and
    /// the selected tab's content below. Called after every successful load,
    /// matching the rebuild-per-load pattern of the other module pages.
    /// </summary>
    private void BuildChrome()
    {
        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var header = BuildHeader();
        Grid.SetRow(header, 0);
        root.Children.Add(header);

        FrameworkElement content = _selectedTab switch
        {
            LogTab.Operation => BuildOperationList(),
            LogTab.Login => BuildLoginList(),
            LogTab.System => BuildSystemTab(),
            _ => BuildOperationList(),
        };
        Grid.SetRow(content, 1);
        root.Children.Add(content);

        // Failure toast floats above the content, bottom-aligned (kept in the
        // visual tree so Show() actually renders).
        _errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(_errorToast, 1);
        AttachToast(root, _errorToast);

        ModuleContentPresenter.Content = root;
    }

    /// <summary>SelectorBar tab switcher plus the header refresh button. The
    /// SelectionChanged handler is attached after the initial selection is
    /// applied so rebuilding the chrome does not re-trigger a load.</summary>
    private FrameworkElement BuildHeader()
    {
        var header = new Grid
        {
            Margin = new Thickness(8, 4, 8, 0),
        };
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var bar = new SelectorBar
        {
            HorizontalAlignment = HorizontalAlignment.Left,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(0, 0, 8, 0),
        };
        bar.Items.Add(new SelectorBarItem { Text = L10n.T("logsCenterTabOperation", "Operation") });
        bar.Items.Add(new SelectorBarItem { Text = L10n.T("logsCenterTabLogin", "Login") });
        bar.Items.Add(new SelectorBarItem { Text = L10n.T("logsCenterTabSystem", "System") });
        ((SelectorBarItem)bar.Items[(int)_selectedTab]).IsSelected = true;

        bar.SelectionChanged += OnTabSelectionChanged;
        Grid.SetColumn(bar, 0);
        header.Children.Add(bar);

        var refreshButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE72C", FontSize = 14 },
            Background = null,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(8, 4, 8, 4),
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(refreshButton, L10n.T("hostLogsRefreshTab", "Refresh current tab"));
        refreshButton.Click += (s, e) => _ = LoadCurrentTabAsync(showLoadingState: true);
        Grid.SetColumn(refreshButton, 1);
        header.Children.Add(refreshButton);

        return header;
    }

    private void OnTabSelectionChanged(SelectorBar sender, SelectorBarSelectionChangedEventArgs args)
    {
        var index = sender.Items.IndexOf(sender.SelectedItem);
        if (index < 0 || index == (int)_selectedTab) return;

        _selectedTab = (LogTab)index;
        _ = LoadCurrentTabAsync(showLoadingState: true);
    }

    private FrameworkElement BuildOperationList()
    {
        var scrollViewer = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 0, 8),
        };

        var list = new ListView
        {
            SelectionMode = ListViewSelectionMode.None,
            IsItemClickEnabled = false,
            Margin = new Thickness(8, 0, 8, 0),
        };

        foreach (var entry in _operationLogs)
        {
            list.Items.Add(CreateOperationLogItem(entry));
        }

        scrollViewer.Content = list;
        return scrollViewer;
    }

    private FrameworkElement BuildLoginList()
    {
        var scrollViewer = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 0, 8),
        };

        var list = new ListView
        {
            SelectionMode = ListViewSelectionMode.None,
            IsItemClickEnabled = false,
            Margin = new Thickness(8, 0, 8, 0),
        };

        foreach (var entry in _loginLogs)
        {
            list.Items.Add(CreateLoginLogItem(entry));
        }

        scrollViewer.Content = list;
        return scrollViewer;
    }

    /// <summary>Operation log row: status badge, method badge, monospace path,
    /// source/ip secondary line and the truncated message. The trailing Auto
    /// column stays empty because the module is read-only (no row actions).</summary>
    private FrameworkElement CreateOperationLogItem(OperationLogEntry entry)
    {
        var grid = new Grid { Padding = new Thickness(16, 10, 16, 10) };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var info = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var titleRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
        };
        if (!string.IsNullOrWhiteSpace(entry.Status))
        {
            titleRow.Children.Add(CreatePillBadge(entry.Status, GetStatusCodeAccent(entry.Status), showDot: true));
        }
        if (!string.IsNullOrWhiteSpace(entry.Method))
        {
            titleRow.Children.Add(CreatePillBadge(entry.Method, GetMethodAccent(entry.Method), showDot: false));
        }
        titleRow.Children.Add(new TextBlock
        {
            Text = string.IsNullOrEmpty(entry.Path) ? L10n.T("systemSettingsUnknown", "Unknown") : entry.Path,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 13,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        info.Children.Add(titleRow);

        // Secondary line: source and ip joined when both are present.
        var metaParts = new List<string>();
        if (!string.IsNullOrWhiteSpace(entry.Source)) metaParts.Add(entry.Source);
        if (!string.IsNullOrWhiteSpace(entry.Ip)) metaParts.Add(entry.Ip);
        if (metaParts.Count > 0)
        {
            info.Children.Add(CreateSecondaryText(string.Join(" · ", metaParts)));
        }

        if (!string.IsNullOrWhiteSpace(entry.Message))
        {
            var message = CreateSecondaryText(entry.Message);
            ToolTipService.SetToolTip(message, entry.Message); // Full text on hover.
            info.Children.Add(message);
        }

        Grid.SetColumn(info, 0);
        grid.Children.Add(info);

        return grid;
    }

    /// <summary>Login log row: status badge, ip primary, address + formatted
    /// createdAt secondary line and the truncated message. The trailing Auto
    /// column stays empty because the module is read-only (no row actions).</summary>
    private FrameworkElement CreateLoginLogItem(LoginLogEntry entry)
    {
        var grid = new Grid { Padding = new Thickness(16, 10, 16, 10) };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var info = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var titleRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
        };
        if (!string.IsNullOrWhiteSpace(entry.Status))
        {
            titleRow.Children.Add(CreatePillBadge(entry.Status, GetLoginStatusAccent(entry.Status), showDot: true));
        }
        titleRow.Children.Add(new TextBlock
        {
            Text = string.IsNullOrEmpty(entry.Ip) ? L10n.T("systemSettingsUnknown", "Unknown") : entry.Ip,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        info.Children.Add(titleRow);

        // Secondary line: address and formatted login time joined when present.
        var metaParts = new List<string>();
        if (!string.IsNullOrWhiteSpace(entry.Address)) metaParts.Add(entry.Address);
        if (!string.IsNullOrWhiteSpace(entry.CreatedAt)) metaParts.Add(FormatDateString(entry.CreatedAt));
        if (metaParts.Count > 0)
        {
            info.Children.Add(CreateSecondaryText(string.Join(" · ", metaParts)));
        }

        if (!string.IsNullOrWhiteSpace(entry.Message))
        {
            var message = CreateSecondaryText(entry.Message);
            ToolTipService.SetToolTip(message, entry.Message); // Full text on hover.
            info.Children.Add(message);
        }

        Grid.SetColumn(info, 0);
        grid.Children.Add(info);

        return grid;
    }

    /// <summary>
    /// System tab: file-name input (required, inline validation), "Core logs"
    /// switch (upstream Agent/Core radio, Core- prefixed files) and the Load
    /// action; below, either the hint text (nothing loaded yet) or the loaded
    /// content in a read-only monospace view with line numbers.
    /// </summary>
    private FrameworkElement BuildSystemTab()
    {
        var root = new Grid
        {
            Margin = new Thickness(16, 8, 16, 8),
        };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // Form.
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // Inline validation error.
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // Loaded-count info.
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }); // Log area.

        // Form state lives in class fields so it survives chrome rebuilds;
        // control edits write back into the fields.
        var fileNameBox = new TextBox
        {
            Header = L10n.T("hostLogsFileNameLabel", "File name"),
            PlaceholderText = "1Panel.log",
            Text = _systemFileName,
        };
        var coreToggle = new CheckBox
        {
            Content = L10n.T("hostLogsCoreToggle", "Core logs"),
            IsChecked = _systemUseCoreLogs,
            VerticalAlignment = VerticalAlignment.Bottom,
            MinWidth = 0,
        };
        var loadButton = new Button
        {
            Content = L10n.T("commonLoad", "Load"),
            VerticalAlignment = VerticalAlignment.Bottom,
        };

        var errorText = new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
            Visibility = Visibility.Collapsed,
            Margin = new Thickness(0, 4, 0, 0),
        };

        fileNameBox.TextChanged += (s, e) =>
        {
            _systemFileName = fileNameBox.Text;
            SetFormError(errorText, null);
        };
        void SyncCoreToggle() => _systemUseCoreLogs = coreToggle.IsChecked == true;
        coreToggle.Checked += (s, e) => SyncCoreToggle();
        coreToggle.Unchecked += (s, e) => SyncCoreToggle();
        loadButton.Click += (s, e) => _ = LoadSystemLogFromFormAsync(fileNameBox, errorText);

        var form = new Grid { ColumnSpacing = 12 };
        form.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        form.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        form.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(fileNameBox, 0);
        Grid.SetColumn(coreToggle, 1);
        Grid.SetColumn(loadButton, 2);
        form.Children.Add(fileNameBox);
        form.Children.Add(coreToggle);
        form.Children.Add(loadButton);
        Grid.SetRow(form, 0);
        root.Children.Add(form);

        Grid.SetRow(errorText, 1);
        root.Children.Add(errorText);

        if (_systemLoaded)
        {
            var infoText = CreateSecondaryText(
                $"Loaded {_systemLineCount} of {_systemTotalLines} lines from \"{_systemFileName.Trim()}\".");
            infoText.Margin = new Thickness(0, 6, 0, 4);
            Grid.SetRow(infoText, 2);
            root.Children.Add(infoText);

            // Read-only monospace log view; the TextBox owns both scrollbars.
            var logBox = new TextBox
            {
                FontFamily = new FontFamily("Consolas"),
                FontSize = 12,
                IsReadOnly = true,
                IsSpellCheckEnabled = false,
                AcceptsReturn = true,
                TextWrapping = TextWrapping.NoWrap,
                Text = _systemLogText,
                VerticalAlignment = VerticalAlignment.Stretch,
                VerticalContentAlignment = VerticalAlignment.Top,
                Margin = new Thickness(0, 0, 0, 8),
            };
            ScrollViewer.SetHorizontalScrollBarVisibility(logBox, ScrollBarVisibility.Auto);
            ScrollViewer.SetVerticalScrollBarVisibility(logBox, ScrollBarVisibility.Auto);
            Grid.SetRow(logBox, 3);
            root.Children.Add(logBox);
        }
        else
        {
            // Nothing loaded yet: hint text instead of the log area.
            var hint = new StackPanel
            {
                Orientation = Orientation.Vertical,
                Spacing = 12,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
            };
            hint.Children.Add(new FontIcon
            {
                Glyph = "\uE7C3", // Page.
                FontSize = 32,
                HorizontalAlignment = HorizontalAlignment.Center,
            });
            hint.Children.Add(new TextBlock
            {
                Text = L10n.T("hostLogsSystemHint", "Enter a log file name and click Load to view its content."),
                FontSize = 14,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                HorizontalAlignment = HorizontalAlignment.Center,
                TextWrapping = TextWrapping.Wrap,
            });
            Grid.SetRow(hint, 3);
            root.Children.Add(hint);
        }

        return root;
    }

    /// <summary>Pill badge shared by every badge flavor: colored text (plus an
    /// optional status dot) on a translucent tint of the same accent, keeping
    /// the pill readable over Mica/LayerFill.</summary>
    private static FrameworkElement CreatePillBadge(string text, Brush accentBrush, bool showDot)
    {
        var content = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
        };
        if (showDot)
        {
            content.Children.Add(new Ellipse
            {
                Width = 8,
                Height = 8,
                Fill = accentBrush,
                VerticalAlignment = VerticalAlignment.Center,
            });
        }
        content.Children.Add(new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });

        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);
        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            VerticalAlignment = VerticalAlignment.Center,
            Child = content,
        };
    }

    /// <summary>Accent for the operation-log status, judged by the status
    /// prefix: 2xx success green, 4xx caution orange, 5xx critical red,
    /// anything else neutral.</summary>
    private static Brush GetStatusCodeAccent(string status)
    {
        var trimmed = status.Trim();
        return (trimmed.Length > 0 ? trimmed[0] : '0') switch
        {
            '2' => TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green),
            '4' => TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
            '5' => TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
            _ => TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray),
        };
    }

    /// <summary>Accent per HTTP method: GET blue, POST green, PUT orange,
    /// DELETE red, PATCH purple, anything else neutral.</summary>
    private static Brush GetMethodAccent(string method)
        => method?.Trim().ToUpperInvariant() switch
        {
            "GET" => TryGetThemeBrush("AccentFillColorDefaultBrush", Microsoft.UI.Colors.RoyalBlue),
            "POST" => TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.SeaGreen),
            "PUT" => TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
            "DELETE" => TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.IndianRed),
            "PATCH" => TryGetThemeBrush("AccentFillColorSecondaryBrush", Microsoft.UI.Colors.Purple),
            _ => TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray),
        };

    /// <summary>Accent for the login status: Success green, Failed red,
    /// anything else neutral (matches the upstream Status component palette).</summary>
    private static Brush GetLoginStatusAccent(string status)
        => status?.ToLowerInvariant() switch
        {
            "success" => TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green),
            "failed" => TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
            _ => TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray),
        };

    private static TextBlock CreateSecondaryText(string text)
    {
        return new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
        };
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

    private static Color GetBrushColor(Brush brush, Color fallback)
        => brush is SolidColorBrush solid ? solid.Color : fallback;

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

    /// <summary>Row model for operation logs, straight from the bridge payload.</summary>
    private sealed class OperationLogEntry
    {
        public long Id { get; set; }
        public string Source { get; set; } = "";
        public string Ip { get; set; } = "";
        public string Path { get; set; } = "";
        public string Method { get; set; } = "";
        public string Status { get; set; } = "";
        public string Message { get; set; } = "";
    }

    /// <summary>Row model for login logs, straight from the bridge payload.</summary>
    private sealed class LoginLogEntry
    {
        public long Id { get; set; }
        public string Ip { get; set; } = "";
        public string Address { get; set; } = "";
        public string Status { get; set; } = "";
        public string Message { get; set; } = "";
        public string CreatedAt { get; set; } = "";
    }
}
