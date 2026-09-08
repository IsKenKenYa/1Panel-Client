using System;
using System.Collections.Generic;
using System.Text.Json;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// B1 网站配置中心各 Tab 共享的轻量 UI 辅助（静态类）。
/// 卡片视觉对齐 SecurityGatewayPage.CreateCard：Mica 底衬上透明填充 +
/// CardStroke 描边 + 圆角（配置中心统一 12px）。方法名有意区别于
/// SecurityGatewayPage 的 private 实现，两个类型互不引用。
/// 上游对照：frontend/src/views/website/website/config/basic/ 各 Tab 的
/// 表单语义在客户端复用这组 helper 完成桌面布局适配。
/// </summary>
internal static class WebsiteConfigHelpers
{
    /// <summary>
    /// 透明背景卡片：半粗标题行 + 由调用方填充的内容 StackPanel。
    /// 背景取 CardStroke 约 4% 透明度的着色（CreateSubtleFill 同型实现），
    /// 保证浅色/深色主题在 Mica/LayerFill 上均可读。
    /// </summary>
    public static FrameworkElement BuildCard(string title, out StackPanel panel)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(12),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = TryGetThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = CreateSubtleFill(),
        };

        panel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 10,
        };

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
    /// 两列 label/value 网格：每行两组 label+value，空值渲染 "--"。
    /// 与 SecurityGatewayPage.BuildInfoBag 的差异：由键值对列表驱动而非
    /// 原始 JsonElement（调用方自行决定展示哪些字段与文案）。
    /// </summary>
    public static Grid BuildInfoBag(IEnumerable<KeyValuePair<string, string>> pairs)
    {
        var bag = new Grid();
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(24) });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bag.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var entries = new List<KeyValuePair<string, string>>(pairs);
        for (int i = 0; i < entries.Count; i += 2)
        {
            var row = bag.RowDefinitions.Count;
            bag.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            AddInfoPair(bag, row, 0, entries[i].Key, entries[i].Value);
            if (i + 1 < entries.Count)
            {
                AddInfoPair(bag, row, 1, entries[i + 1].Key, entries[i + 1].Value);
            }
        }

        return bag;
    }

    /// <summary>带 Header 的文本框；<paramref name="multiline"/> 时为多行（AcceptsReturn，固定高度）。</summary>
    public static TextBox BuildTextBox(string header, string text = "", bool multiline = false, double minHeight = 0)
    {
        var box = new TextBox
        {
            Header = header,
            Text = text,
        };
        if (multiline)
        {
            box.AcceptsReturn = true;
            box.TextWrapping = TextWrapping.Wrap;
            box.Height = minHeight > 0 ? minHeight : 96;
        }
        return box;
    }

    /// <summary>开关（不设 On/Off 文案，标签由调用方用 Header 表达；Toggled 抑制由调用方处理）。</summary>
    public static ToggleSwitch BuildToggle(bool isOn)
    {
        return new ToggleSwitch
        {
            IsOn = isOn,
            Margin = new Thickness(0),
        };
    }

    /// <summary>
    /// 表单状态行（表单校验错误 / 静默刷新提示共用）：默认折叠，
    /// 配合 <see cref="SetStatus"/> 显示；error=true 时使用危险色。
    /// </summary>
    public static TextBlock StatusText()
    {
        return new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            Visibility = Visibility.Collapsed,
        };
    }

    /// <summary>写入状态行：空消息折叠；error=true 使用危险色，否则次要色。</summary>
    public static void SetStatus(TextBlock target, string? message, bool error = false)
    {
        if (string.IsNullOrEmpty(message))
        {
            target.Text = string.Empty;
            target.Visibility = Visibility.Collapsed;
            return;
        }

        target.Text = message;
        target.Foreground = error
            ? TryGetThemeBrush("SystemFillColorCriticalBrush", Colors.Red)
            : TryGetThemeBrush("SystemFillColorSuccessBrush", Colors.Green);
        target.Visibility = Visibility.Visible;
    }

    /// <summary>
    /// 事件处理器可用的 XamlRoot：优先取触发元素所在树（Tab 内容可能已
    /// 被切换替换），回落主窗口内容树；两者皆不可用时返回 null（调用方跳过弹窗）。
    /// </summary>
    public static Microsoft.UI.Xaml.XamlRoot? GetXamlRoot(FrameworkElement? element)
    {
        if (element?.XamlRoot != null)
        {
            return element.XamlRoot;
        }
        return (App.MainWindow?.Content as FrameworkElement)?.XamlRoot;
    }

    // ── JSON 取值辅助（两个 Tab 共用；缺属性/类型不符一律回落默认值） ──

    public static string? TryGetString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    public static bool TryGetBool(JsonElement element, string property, bool fallback)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            (prop.ValueKind == JsonValueKind.True || prop.ValueKind == JsonValueKind.False))
        {
            return prop.GetBoolean();
        }
        return fallback;
    }

    public static long TryGetLong(JsonElement element, string property, long fallback)
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

    /// <summary>整卡共享的 4% 透明度着色填充（SecurityGatewayPage.CreateSubtleFill 同型）。</summary>
    private static Brush CreateSubtleFill()
    {
        var stroke = TryGetThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }

    private static Brush TryGetThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    /// <summary>放置一组 label+value 到 InfoBag 网格（pairIndex 0 → 列 0/1，1 → 列 3/4）。</summary>
    private static void AddInfoPair(Grid bag, int row, int pairIndex, string label, string value)
    {
        var labelColumn = pairIndex == 0 ? 0 : 3;
        var valueColumn = pairIndex == 0 ? 1 : 4;

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
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
}
