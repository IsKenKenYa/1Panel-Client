using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// WinUI3 AI 管理 - GPU 只读 Tab（上游 frontend/src/views/ai/gpu/current/
/// index.vue 的桌面高保真还原）。
///
/// GetGpuLoadAsync() 透传 GET /ai/gpu/load 响应。概览卡按存在性渲染
/// 驱动版本 / CUDA 版本 / 类型；设备卡上游分 nvidia（gpu[]：利用率/温度/
/// 性能状态/功耗/显存/风扇/Bus ID/持久模式/显示激活/ECC/计算模式/MIG）与
/// xpu（xpu[]：basic.deviceName + stats 温度/功耗/显存/频率 + Bus ID）两条
/// 分支，客户端按 type 宽松分派（响应字段名以服务端实际返回为准，一律
/// TryGetString/TryGetDouble 取值，缺失/未知字段整行跳过，枚举字段
/// （持久模式/计算模式等）原样透传不做翻译）。每设备附进程表（nvidia:
/// pid/type/processName/usedMemory；xpu: pid/command/shr/memory），无进程时
/// 整段隐藏（上游语义）。driverVersion 缺失且无设备 → 空态文本。
/// 刷新按钮整体重载；桥失败为错误 InfoBar + 重试（静默刷新走 Toast）。
///
/// 与上游的已知偏差（登记）：枚举值（computeMode/persistenceMode/
/// displayActive/ecc/migMode）与进程类型 C/G/C+G 之外的值原样显示、温度
/// "C" 后缀本地化为 "°C"（上游 replaceAll('C','°C') 的收尾版本）；GPU 历史
/// 监控（searchGpuHistory）与设置入口不在此 Tab 范围。
///
/// 数据经 WindowsBridge（Dart 业务核心）转发，原生层不直连 API。
/// 自包含：helper 方法名统一 AiGpuTab 前缀防冲突。
/// </summary>
public static class AiGpuTab
{
    public static FrameworkElement Build()
    {
        var errorToast = new ErrorToast();
        var busyGuard = false;

        // ── 头部：刷新按钮右对齐（只读 Tab，无其他写操作） ───────────
        var refreshButton = AiGpuTabSmallButton(L10n.T("commonRefresh", "Refresh"), "\uE72C");
        var header = new Grid { ColumnSpacing = 8 };
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        refreshButton.HorizontalAlignment = HorizontalAlignment.Right;
        Grid.SetColumn(refreshButton, 1);
        header.Children.Add(refreshButton);

        // ── 内容面：卡片流 / 空态文本 ─────────────────────────────────
        var contentPanel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 12,
            Visibility = Visibility.Collapsed,
        };
        var emptyText = new TextBlock
        {
            Text = L10n.T("hostAiGpuEmpty", "No GPU detected on this server."),
            FontSize = 13,
            Foreground = AiGpuTabThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(8, 32, 8, 8),
            TextWrapping = TextWrapping.Wrap,
            Visibility = Visibility.Collapsed,
        };
        var scroll = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(8, 8, 8, 8),
            Content = contentPanel,
            Visibility = Visibility.Collapsed,
        };

        // ── 状态面：加载错误 + 重试 / 加载圈 / 错误 Toast ─────────────
        var errorRow = AiGpuTabErrorRow(out var errorBar, out var retryButton);
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
        Grid.SetRow(header, 0);
        Grid.SetRow(errorRow, 1);
        Grid.SetRow(scroll, 2);
        Grid.SetRow(emptyText, 2);
        Grid.SetRow(loadingRing, 2);
        errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(errorToast, 2);
        root.Children.Add(header);
        root.Children.Add(errorRow);
        root.Children.Add(scroll);
        root.Children.Add(emptyText);
        root.Children.Add(loadingRing);
        root.Children.Add(errorToast);

        // ── 数据加载 ─────────────────────────────────────────────────
        async Task LoadAsync(bool showLoading)
        {
            if (busyGuard) return;
            busyGuard = true;

            if (showLoading)
            {
                loadingRing.Visibility = Visibility.Visible;
                scroll.Visibility = Visibility.Collapsed;
                emptyText.Visibility = Visibility.Collapsed;
            }

            JsonElement? result;
            try
            {
                result = await WindowsBridge.GetGpuLoadAsync();
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
                AiGpuTabShowError(errorBar, retryButton, true);
                if (!showLoading)
                {
                    errorToast.Show(L10n.T("hostAiGpuRefreshFailed", "Failed to refresh the GPU status."));
                }
                return;
            }

            AiGpuTabShowError(errorBar, retryButton, false);
            Render(result.Value);
            loadingRing.Visibility = Visibility.Collapsed;
            scroll.Visibility = Visibility.Visible;
        }

        void Render(JsonElement json)
        {
            contentPanel.Children.Clear();

            var driverVersion = AiGpuTabValue(json, "driverVersion");
            var type = AiGpuTabValue(json, "type");
            var isXpu = !string.IsNullOrWhiteSpace(type) &&
                        type.Contains("xpu", StringComparison.OrdinalIgnoreCase);

            // 设备数组宽松探测：按 type 选 "gpu"/"xpu"，缺失时用另一分支兜底。
            var arrayName = isXpu ? "xpu" : "gpu";
            if (!AiGpuTabTryGetArray(json, arrayName, out var devices))
            {
                var fallbackName = isXpu ? "gpu" : "xpu";
                if (AiGpuTabTryGetArray(json, fallbackName, out var fallback))
                {
                    devices = fallback;
                    isXpu = fallbackName == "xpu";
                }
            }

            var hasDevices = devices.ValueKind == JsonValueKind.Array && devices.GetArrayLength() > 0;

            // 上游空态：driverVersion 为空且无设备 → 未检测到 GPU。
            if (string.IsNullOrWhiteSpace(driverVersion) && !hasDevices)
            {
                contentPanel.Visibility = Visibility.Collapsed;
                emptyText.Visibility = Visibility.Visible;
                return;
            }

            emptyText.Visibility = Visibility.Collapsed;
            contentPanel.Visibility = Visibility.Visible;

            // ── 概览卡：驱动版本 / CUDA 版本 / 类型（存在才渲染该行） ──
            var summaryPairs = new List<KeyValuePair<string, string>>();
            AiGpuTabAddPair(summaryPairs, L10n.T("hostAiGpuDriverVersion", "Driver Version"), driverVersion);
            AiGpuTabAddPair(summaryPairs, L10n.T("hostAiGpuCudaVersion", "CUDA Version"),
                AiGpuTabValue(json, "cudaVersion"));
            AiGpuTabAddPair(summaryPairs, L10n.T("commonType", "Type"), type);
            if (summaryPairs.Count > 0)
            {
                var summaryCard = AiGpuTabCard(L10n.T("hostAiGpuTitle", "GPU"), out var summaryPanel);
                summaryPanel.Children.Add(AiGpuTabInfoBag(summaryPairs));
                contentPanel.Children.Add(summaryCard);
            }

            if (devices.ValueKind == JsonValueKind.Array)
            {
                foreach (var device in devices.EnumerateArray())
                {
                    if (device.ValueKind != JsonValueKind.Object) continue;
                    contentPanel.Children.Add(isXpu ? BuildXpuDeviceCard(device) : BuildGpuDeviceCard(device));
                }
            }
        }

        // ── 设备卡（nvidia gpu[] 条目；字段宽松取值、缺失跳过） ───────
        FrameworkElement BuildGpuDeviceCard(JsonElement item)
        {
            var index = AiGpuTabValue(item, "index");
            var productName = AiGpuTabValue(item, "productName");
            var title = (string.IsNullOrEmpty(index) ? "" : index + ". ") +
                        (productName ?? L10n.T("hostAiGpuUnknownDevice", "GPU"));

            var pairs = new List<KeyValuePair<string, string>>();
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuUtilization", "GPU Utilization"), AiGpuTabValue(item, "gpuUtil"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuTemperature", "Temperature"),
                AiGpuTabFormatTemperature(AiGpuTabValue(item, "temperature")));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuPerformanceState", "Performance State"),
                AiGpuTabValue(item, "performanceState"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuPowerUsage", "Power Usage"),
                AiGpuTabJoin(AiGpuTabValue(item, "powerDraw"), AiGpuTabValue(item, "maxPowerLimit")));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuMemoryUsage", "Memory Usage"),
                AiGpuTabJoin(AiGpuTabValue(item, "memUsed"), AiGpuTabValue(item, "memTotal")));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuFanSpeed", "Fan Speed"), AiGpuTabValue(item, "fanSpeed"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuBusId", "Bus ID"), AiGpuTabValue(item, "busID"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuPersistenceMode", "Persistence Mode"),
                AiGpuTabValue(item, "persistenceMode"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuDisplayActive", "Display Active"),
                AiGpuTabValue(item, "displayActive"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuEcc", "Uncorr. ECC"), AiGpuTabValue(item, "ecc"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuComputeMode", "Compute Mode"),
                AiGpuTabValue(item, "computeMode"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuMigMode", "MIG Mode"), AiGpuTabValue(item, "migMode"));

            return BuildDeviceCard(title, pairs, item, xpu: false);
        }

        // ── 设备卡（xpu xpu[] 条目：basic + stats 两段宽松取值） ──────
        FrameworkElement BuildXpuDeviceCard(JsonElement item)
        {
            var basic = AiGpuTabObject(item, "basic");
            var stats = AiGpuTabObject(item, "stats");

            var deviceId = AiGpuTabValue(basic, "deviceID");
            var deviceName = AiGpuTabValue(basic, "deviceName");
            var title = (string.IsNullOrEmpty(deviceId) ? "" : deviceId + ". ") +
                        (deviceName ?? L10n.T("hostAiGpuUnknownDevice", "XPU"));

            var pairs = new List<KeyValuePair<string, string>>();
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuTemperature", "Temperature"),
                AiGpuTabFormatTemperature(AiGpuTabValue(stats, "temperature")));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuPowerUsage", "Power Usage"), AiGpuTabValue(stats, "power"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuMemoryUsage", "Memory Usage"),
                AiGpuTabJoin(AiGpuTabValue(stats, "memoryUsed"), AiGpuTabValue(basic, "memory")));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuMemoryUtilization", "Memory Utilization"),
                AiGpuTabValue(stats, "memoryUtil"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuFrequency", "Frequency"), AiGpuTabValue(stats, "frequency"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuBusId", "Bus ID"), AiGpuTabValue(basic, "pciBdfAddress"));
            AiGpuTabAddPair(pairs, L10n.T("hostAiGpuDriverVersion", "Driver Version"),
                AiGpuTabValue(basic, "driverVersion"));

            return BuildDeviceCard(title, pairs, item, xpu: true);
        }

        FrameworkElement BuildDeviceCard(
            string title, List<KeyValuePair<string, string>> pairs, JsonElement device, bool xpu)
        {
            var card = AiGpuTabCard(title, out var panel);
            if (pairs.Count > 0)
            {
                panel.Children.Add(AiGpuTabInfoBag(pairs));
            }

            var processTable = BuildProcessTable(device, xpu);
            if (processTable != null)
            {
                panel.Children.Add(processTable);
            }
            return card;
        }

        // ── GPU 进程表（上游：无进程时整段隐藏） ─────────────────────
        FrameworkElement? BuildProcessTable(JsonElement device, bool xpu)
        {
            if (!device.TryGetProperty("processes", out var processes) ||
                processes.ValueKind != JsonValueKind.Array ||
                processes.GetArrayLength() == 0)
            {
                return null;
            }

            var section = new StackPanel { Orientation = Orientation.Vertical, Spacing = 6 };
            section.Children.Add(new TextBlock
            {
                Text = L10n.T("hostAiGpuProcesses", "Processes"),
                FontSize = 13,
                FontWeight = Microsoft.UI.Text.FontWeights.Medium,
            });

            // 表头（nvidia: PID/Type/Name/Memory；xpu: PID/Shared Mem/Name/Memory）。
            var headerGrid = new Grid { ColumnSpacing = 12 };
            headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(56) });
            headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(96) });
            headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            AddProcessCell(headerGrid, 0, "PID", isHeader: true);
            AddProcessCell(headerGrid, 1,
                xpu ? L10n.T("hostAiGpuShr", "Shared Mem") : L10n.T("commonType", "Type"), isHeader: true);
            AddProcessCell(headerGrid, 2, L10n.T("hostAiGpuProcessName", "Process Name"), isHeader: true);
            AddProcessCell(headerGrid, 3, L10n.T("hostAiGpuProcessMemory", "Memory Usage"), isHeader: true);
            section.Children.Add(headerGrid);

            foreach (var process in processes.EnumerateArray())
            {
                if (process.ValueKind != JsonValueKind.Object) continue;

                string pid;
                string extra;
                string name;
                string memory;
                if (xpu)
                {
                    pid = AiGpuTabValue(process, "pid") ?? "--";
                    extra = AiGpuTabValue(process, "shr") ?? "--";
                    name = AiGpuTabValue(process, "command") ?? "--";
                    memory = AiGpuTabValue(process, "memory") ?? "--";
                }
                else
                {
                    pid = AiGpuTabValue(process, "pid") ?? "--";
                    extra = AiGpuTabProcessType(AiGpuTabValue(process, "type") ?? "");
                    name = AiGpuTabValue(process, "processName") ?? "--";
                    memory = AiGpuTabValue(process, "usedMemory") ?? "--";
                }

                var row = new Grid { ColumnSpacing = 12 };
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(56) });
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(96) });
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                AddProcessCell(row, 0, pid);
                AddProcessCell(row, 1, extra);
                AddProcessCell(row, 2, name);
                AddProcessCell(row, 3, memory);
                section.Children.Add(row);
            }

            return section;
        }

        void AddProcessCell(Grid grid, int column, string text, bool isHeader = false)
        {
            var block = new TextBlock
            {
                Text = text,
                FontSize = 12,
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
                VerticalAlignment = VerticalAlignment.Center,
                Foreground = isHeader
                    ? AiGpuTabThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray)
                    : AiGpuTabThemeBrush("TextFillColorPrimaryBrush", Microsoft.UI.Colors.Gray),
            };
            Grid.SetColumn(block, column);
            grid.Children.Add(block);
        }

        refreshButton.Click += (s, e) => _ = LoadAsync(showLoading: false);
        retryButton.Click += (s, e) => _ = LoadAsync(showLoading: false);
        root.Loaded += (s, e) => _ = LoadAsync(showLoading: true);
        return root;
    }

    // ── 自包含 helper（AiGpuTab 前缀防冲突） ─────────────────────────────

    /// <summary>卡片壳：透明填充 + CardStroke 描边 + 8px 圆角（SecurityGatewayPage
    /// 风格），标题行 + 调用方填充的内容 StackPanel。</summary>
    private static FrameworkElement AiGpuTabCard(string title, out StackPanel panel)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = AiGpuTabThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = AiGpuTabSubtleFill(),
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

    /// <summary>两列 label/value 网格（每行两组），空值已在 AddPair 阶段过滤。</summary>
    private static Grid AiGpuTabInfoBag(List<KeyValuePair<string, string>> pairs)
    {
        var bag = new Grid();
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(24) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        for (int i = 0; i < pairs.Count; i += 2)
        {
            var row = bag.RowDefinitions.Count;
            bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            AiGpuTabAddInfoPair(bag, row, 0, pairs[i].Key, pairs[i].Value);
            if (i + 1 < pairs.Count)
            {
                AiGpuTabAddInfoPair(bag, row, 1, pairs[i + 1].Key, pairs[i + 1].Value);
            }
        }

        return bag;
    }

    private static void AiGpuTabAddInfoPair(Grid bag, int row, int pairIndex, string label, string value)
    {
        var labelColumn = pairIndex == 0 ? 0 : 3;
        var valueColumn = pairIndex == 0 ? 1 : 4;

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = AiGpuTabThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 0, 12, 0),
        };
        Grid.SetRow(labelBlock, row);
        Grid.SetColumn(labelBlock, labelColumn);
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
        Grid.SetColumn(valueBlock, valueColumn);
        bag.Children.Add(valueBlock);
    }

    /// <summary>仅当取值非空时收进 InfoBag 列表（未知字段跳过语义）。</summary>
    private static void AiGpuTabAddPair(List<KeyValuePair<string, string>> pairs, string label, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            pairs.Add(new KeyValuePair<string, string>(label, value));
        }
    }

    /// <summary>宽松标量取值：字符串去空白（空白 → null）；数字经
    /// TryGetDouble 以不变文化格式化；其余类型返回 null（调用方跳过）。</summary>
    private static string? AiGpuTabValue(JsonElement element, string property)
    {
        if (element.ValueKind != JsonValueKind.Object ||
            !element.TryGetProperty(property, out var prop))
        {
            return null;
        }

        if (prop.ValueKind == JsonValueKind.String)
        {
            var text = prop.GetString();
            return string.IsNullOrWhiteSpace(text) ? null : text.Trim();
        }
        if (prop.ValueKind == JsonValueKind.Number && prop.TryGetDouble(out var number))
        {
            return number.ToString(CultureInfo.InvariantCulture);
        }
        return null;
    }

    /// <summary>取嵌套对象属性；缺失/非对象返回 default（调用方以 ValueKind 判断）。</summary>
    private static JsonElement AiGpuTabObject(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var value) &&
            value.ValueKind == JsonValueKind.Object)
        {
            return value;
        }
        return default;
    }

    private static bool AiGpuTabTryGetArray(JsonElement element, string property, out JsonElement array)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var value) &&
            value.ValueKind == JsonValueKind.Array)
        {
            array = value;
            return true;
        }
        array = default;
        return false;
    }

    /// <summary>温度 "C" 后缀本地化为 "°C"（上游 replaceAll('C','°C') 的收尾
    /// 保守版：仅处理结尾 C 且未含 ° 的值）。</summary>
    private static string? AiGpuTabFormatTemperature(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;

        var text = value.Trim();
        if (text.EndsWith("C", StringComparison.Ordinal) && !text.Contains('\u00B0'))
        {
            text = text[..^1] + "\u00B0C";
        }
        return text;
    }

    /// <summary>"used / total" 组合值：两者齐全才组合，单值原样。</summary>
    private static string? AiGpuTabJoin(string? used, string? total)
    {
        if (used != null && total != null) return $"{used} / {total}";
        return used ?? total;
    }

    /// <summary>上游 loadProcessType：C/G/C+G 翻译，其余原样。</summary>
    private static string AiGpuTabProcessType(string raw)
    {
        return raw switch
        {
            "C" => L10n.T("hostAiGpuProcessTypeC", "Compute"),
            "G" => L10n.T("hostAiGpuProcessTypeG", "Graphics"),
            "C+G" => L10n.T("hostAiGpuProcessTypeCG", "Compute+Graphics"),
            _ => raw,
        };
    }

    private static Button AiGpuTabSmallButton(string label, string glyph)
    {
        return new Button
        {
            Padding = new Thickness(10, 4, 10, 4),
            VerticalAlignment = VerticalAlignment.Center,
            Content = new StackPanel
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
            },
        };
    }

    /// <summary>加载错误面：错误 InfoBar + 尾部 Retry 按钮（配合 AiGpuTabShowError）。</summary>
    private static FrameworkElement AiGpuTabErrorRow(out InfoBar bar, out Button retryButton)
    {
        var row = new Grid { ColumnSpacing = 8, Margin = new Thickness(8, 8, 8, 0) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        bar = new InfoBar
        {
            Title = L10n.T("hostAiGpuLoadFailed", "Failed to load the GPU status."),
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

    private static void AiGpuTabShowError(InfoBar bar, Button retryButton, bool show)
    {
        bar.IsOpen = show;
        retryButton.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
    }

    private static Brush AiGpuTabThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    /// <summary>CardStroke 约 4% 透明度着色填充，Mica/LayerFill 上两种主题均可读
    /// （SecurityGatewayPage.CreateSubtleFill 同型实现）。</summary>
    private static Brush AiGpuTabSubtleFill()
    {
        var stroke = AiGpuTabThemeBrush("CardStrokeColorDefaultBrush", Microsoft.UI.Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Microsoft.UI.Colors.Gray;
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}
