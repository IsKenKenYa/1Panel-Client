using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Security module page: firewall port-rule CRUD (list, add, delete).
/// All data flows through WindowsBridge (Dart business core over the method
/// channel); no direct HTTP from the native layer.
///
/// Upstream semantic reference: the 1Panel web frontend host/firewall port
/// rule table (protocol / port / address / strategy columns) and its create
/// and delete flows. The create form mirrors the upstream protocol + port +
/// address + strategy fields, and the delete confirmation names the rule as
/// "port (protocol)" like the upstream delete message. An empty address is
/// displayed as "Anywhere", matching the upstream edit-mode check. Client
/// simplifications forced by the bridge contract: single numeric port only
/// (upstream also accepts ranges and comma lists), no description input and
/// no edit flow (the bridge exposes add/delete only).
/// </summary>
public sealed class SecurityPage : ModulePageBase
{
    private readonly List<FirewallRuleEntry> _rules = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads, the add dialog and row deletion.</summary>
    private bool _isBusy;

    public SecurityPage()
    {
        PageTitle = L10n.T("navSecurity", "Security");
    }

    protected override async void OnPageShown()
    {
        await LoadRulesAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadRulesAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadRulesAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadRulesCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body; also used as the silent refresh after successful
    /// operations. With showLoadingState the page swaps to the loading
    /// spinner; otherwise the current content stays visible and failures
    /// surface via the error toast.
    /// </summary>
    private async Task LoadRulesCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetFirewallRulesAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostSecurityRefreshFailed", "Failed to refresh firewall rules."));
            }
            return;
        }

        var rules = ParseRules(result.Value);
        if (rules.Count == 0)
        {
            _rules.Clear();
            SetState(PageState.Empty);
            return;
        }

        _rules.Clear();
        _rules.AddRange(rules);
        BuildContent(_rules);
        SetState(PageState.Content);
    }

    private static List<FirewallRuleEntry> ParseRules(JsonElement json)
    {
        var rules = new List<FirewallRuleEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                rules.Add(new FirewallRuleEntry
                {
                    Port = TryGetString(item, "port") ?? "",
                    Protocol = TryGetString(item, "protocol") ?? "",
                    Address = TryGetString(item, "address") ?? "",
                    Strategy = TryGetString(item, "strategy") ?? "",
                    Description = TryGetString(item, "description") ?? "",
                });
            }
        }

        return rules;
    }

    private void BuildContent(List<FirewallRuleEntry> rules)
    {
        // Root layout: CommandBar on top, scrollable list below (relative rows).
        var root = new Grid();
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var commandBar = BuildCommandBar();
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
            // Rules have no row-click action; only the per-row delete button.
            SelectionMode = ListViewSelectionMode.None,
            IsItemClickEnabled = false,
            Margin = new Thickness(8, 0, 8, 0),
        };

        foreach (var rule in rules)
        {
            list.Items.Add(CreateRuleItem(rule));
        }

        scrollViewer.Content = list;
        root.Children.Add(scrollViewer);

        // Failure toast floats above the list, bottom-aligned (kept in the
        // visual tree so Show() actually renders).
        _errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(_errorToast, 1);
        AttachToast(root, _errorToast);

        ModuleContentPresenter.Content = root;
    }

    private CommandBar BuildCommandBar()
    {
        var bar = new CommandBar
        {
            HorizontalAlignment = HorizontalAlignment.Left,
            DefaultLabelPosition = CommandBarDefaultLabelPosition.Right,
            Background = null, // Stay transparent on the LayerFill card surface.
        };

        var addButton = new AppBarButton
        {
            Label = L10n.T("hostSecurityAddRule", "Add rule"),
            Icon = new FontIcon { Glyph = "\uE710" },
        };
        addButton.Click += (s, e) => _ = ShowAddRuleDialogAsync();
        bar.PrimaryCommands.Add(addButton);

        var refreshButton = new AppBarButton
        {
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadRulesAsync(showLoadingState: true);
        bar.SecondaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateRuleItem(FirewallRuleEntry rule)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = rule,
        };

        // Relative columns only: badges and the action hug the edges, the two
        // text columns share the remaining space (Star/Star) so nothing clips
        // on narrow or high-DPI windows.
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Protocol pill (neutral accent).
        var protocolBadge = CreateBadge(
            string.IsNullOrEmpty(rule.Protocol) ? L10n.T("firewallUnknownStrategy", "Unknown") : rule.Protocol,
            TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray),
            showDot: false);
        Grid.SetColumn(protocolBadge, 0);
        grid.Children.Add(protocolBadge);

        // Port (primary) + optional description (secondary, omitted when empty).
        var infoPanel = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(12, 0, 0, 0),
        };
        infoPanel.Children.Add(new TextBlock
        {
            Text = rule.Port,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
        });
        if (!string.IsNullOrWhiteSpace(rule.Description))
        {
            infoPanel.Children.Add(new TextBlock
            {
                Text = rule.Description,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            });
        }
        Grid.SetColumn(infoPanel, 1);
        grid.Children.Add(infoPanel);

        // Address; empty means "Anywhere" (upstream edit-mode semantics). The
        // raw value stays on the entry so deletion sends exactly what the
        // server returned.
        var addressBlock = new TextBlock
        {
            Text = string.IsNullOrWhiteSpace(rule.Address) ? L10n.T("firewallSourceAnywhere", "Anywhere") : rule.Address,
            FontSize = 12,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(12, 0, 0, 0),
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
        };
        Grid.SetColumn(addressBlock, 2);
        grid.Children.Add(addressBlock);

        var strategyBadge = CreateStrategyBadge(rule.Strategy);
        Grid.SetColumn(strategyBadge, 3);
        grid.Children.Add(strategyBadge);

        var deleteButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE74D", FontSize = 14 },
            Padding = new Thickness(8, 4, 8, 4),
            Margin = new Thickness(12, 0, 0, 0),
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(deleteButton, L10n.T("hostSecurityDeleteRule", "Delete rule"));
        deleteButton.Click += async (s, e) => await DeleteRuleAsync(rule);
        Grid.SetColumn(deleteButton, 4);
        grid.Children.Add(deleteButton);

        return grid;
    }

    /// <summary>Strategy pill: Accept = success green, Drop = critical red.</summary>
    private FrameworkElement CreateStrategyBadge(string strategy)
    {
        if (IsAccept(strategy))
        {
            return CreateBadge(
                L10n.T("firewallStrategyAccept", "Accept"),
                TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green),
                showDot: true);
        }
        if (IsDrop(strategy))
        {
            return CreateBadge(
                L10n.T("firewallStrategyDrop", "Drop"),
                TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                showDot: true);
        }
        return CreateBadge(
            string.IsNullOrEmpty(strategy) ? L10n.T("firewallUnknownStrategy", "Unknown") : strategy,
            TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray),
            showDot: false);
    }

    /// <summary>
    /// Pill badge with an optional status dot; the tint derives from the
    /// accent color and stays translucent so it reads over Mica/LayerFill.
    /// </summary>
    private static FrameworkElement CreateBadge(string text, Brush accentBrush, bool showDot)
    {
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        var content = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
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

        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            VerticalAlignment = VerticalAlignment.Center,
            Child = content,
        };
    }

    /// <summary>
    /// Add-rule form dialog with inline validation. _isBusy is held while the
    /// dialog is open so the CommandBar button cannot open a second dialog
    /// and row operations stay blocked until it closes.
    /// </summary>
    private async Task ShowAddRuleDialogAsync()
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var portBox = new TextBox { Header = L10n.T("firewallPortLabel", "Port"), PlaceholderText = L10n.T("hostSecurityPortHint", "e.g. 8080") };

            var protocolBox = new ComboBox
            {
                Header = L10n.T("firewallProtocolLabel", "Protocol"),
                SelectedIndex = 0,
                HorizontalAlignment = HorizontalAlignment.Stretch,
            };
            protocolBox.Items.Add("tcp");
            protocolBox.Items.Add("udp");

            var addressBox = new TextBox { Header = L10n.T("firewallAddressLabel", "Address"), PlaceholderText = L10n.T("hostSecurityAddressHint", "Leave empty for all addresses") };

            var strategyBox = new ComboBox
            {
                Header = L10n.T("firewallStrategyLabel", "Strategy"),
                SelectedValuePath = "Tag",
                SelectedIndex = 0,
                HorizontalAlignment = HorizontalAlignment.Stretch,
            };
            strategyBox.Items.Add(new ComboBoxItem { Content = L10n.T("firewallStrategyAccept", "Accept"), Tag = "accept" });
            strategyBox.Items.Add(new ComboBoxItem { Content = L10n.T("firewallStrategyDrop", "Drop"), Tag = "drop" });

            var errorText = new TextBlock
            {
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                Visibility = Visibility.Collapsed,
            };

            // Any edit clears the pending inline validation error.
            portBox.TextChanged += (s, e) => SetFormError(errorText, null);

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(portBox);
            form.Children.Add(protocolBox);
            form.Children.Add(addressBox);
            form.Children.Add(strategyBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = L10n.T("hostSecurityAddRuleTitle", "Add Rule"),
                Content = form,
                PrimaryButtonText = L10n.T("commonAdd", "Add"),
                CloseButtonText = L10n.T("commonCancel", "Cancel"),
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            // Inline validation: on invalid input cancel the close so the
            // dialog stays open and the error shows next to the fields.
            dialog.Closing += (s, args) =>
            {
                if (args.Result != ContentDialogResult.Primary) return;

                var error = ValidatePort(portBox.Text);
                if (error != null)
                {
                    args.Cancel = true;
                    SetFormError(errorText, error);
                }
            };

            var result = await dialog.ShowAsync();
            if (result != ContentDialogResult.Primary) return;

            var success = await WindowsBridge.AddFirewallRuleAsync(
                portBox.Text.Trim(),
                protocolBox.SelectedItem as string ?? "tcp",
                addressBox.Text.Trim(),
                strategyBox.SelectedValue as string ?? "accept");
            if (!success)
            {
                _errorToast.Show($"Failed to add rule for port {portBox.Text.Trim()}.");
                return;
            }

            // Silent refresh (no loading swap, no success toast).
            await LoadRulesCoreAsync(showLoadingState: false);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Returns the first port validation error, or null when the input is valid.</summary>
    private static string? ValidatePort(string port)
    {
        var trimmed = port.Trim();
        if (trimmed.Length == 0) return L10n.T("firewallPortRequired", "Port is required.");
        foreach (var ch in trimmed)
        {
            if (!char.IsDigit(ch)) return L10n.T("hostSecurityPortNumeric", "Port must be a number.");
        }
        if (!int.TryParse(trimmed, out var value) || value < 1 || value > 65535)
        {
            return L10n.T("websitesDomainValidationPort", "Port must be between 1 and 65535.");
        }
        return null;
    }

    /// <summary>
    /// Destructive row action. Deletes by the rule's four-tuple (port,
    /// protocol, address, strategy), matching the bridge contract.
    /// </summary>
    private async Task DeleteRuleAsync(FirewallRuleEntry rule)
    {
        if (_isBusy) return;

        // Destructive confirmation; the message carries port and protocol,
        // matching the upstream delete dialog naming "port (protocol)".
        var confirmed = await ConfirmDialog.ShowAsync(
            XamlRoot,
            L10n.T("hostSecurityDeleteRuleTitle", "Delete Rule"),
            $"Are you sure you want to delete rule {rule.Port} ({rule.Protocol})?\nThis action cannot be undone.",
            L10n.T("commonDelete", "Delete"),
            L10n.T("commonCancel", "Cancel"),
            isDestructive: true);

        if (!confirmed) return;

        _isBusy = true;
        try
        {
            var success = await WindowsBridge.DeleteFirewallRuleAsync(
                rule.Port, rule.Protocol, rule.Address, rule.Strategy);
            if (success)
            {
                // Silent refresh keeps the list visible (no success toast).
                await LoadRulesCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete rule {rule.Port} ({rule.Protocol}).");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    private static bool IsAccept(string strategy)
        => string.Equals(strategy, "accept", StringComparison.OrdinalIgnoreCase);

    private static bool IsDrop(string strategy)
        => string.Equals(strategy, "drop", StringComparison.OrdinalIgnoreCase);

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

    private sealed class FirewallRuleEntry
    {
        public string Port { get; set; } = "";
        public string Protocol { get; set; } = "";
        public string Address { get; set; } = "";
        public string Strategy { get; set; } = "";
        public string Description { get; set; } = "";
    }
}
