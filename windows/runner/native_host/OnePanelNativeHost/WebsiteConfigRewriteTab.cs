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
/// Website config center - "Rewrite" tab, desktop layout adaptation of the
/// upstream 1Panel website rewrite view
/// (frontend/src/views/website/website/config/basic/rewrite/index.vue): a
/// rewrite-mode selector ("current" plus the preset template names from the
/// upstream Rewrites constant) that loads the nginx rewrite content through
/// the bridge into a monospace multi-line editor, with a single
/// "save and reload" action.
///
/// Bridge mapping (contract: docs/development/modules/b1_website_channel_contract.md):
/// content loads via GetWebsiteRewriteAsync(websiteId, name) - the server
/// resolves name "current" to the site's applied rewrite file and any other
/// name to a preset/custom template; saving calls
/// UpdateWebsiteRewriteAsync(websiteId, name, content) which writes the file
/// and reloads nginx (server-side). Saving is confirmed with ConfirmDialog
/// (cancel is the default button) and both load and save results surface as
/// an in-page InfoBar (red error / green success) because the shared
/// ErrorToast needs a page base class the tabs do not have.
///
/// Known contract deviations (documented, not fixable client-side):
/// - The upstream "current" selection is kept, but the initial mode cannot
///   mirror the upstream getWebsite probe (the channel exposes no single
///   website getter here), so the tab always starts on "current".
/// - Custom rewrite templates (listCustomRewrite / saveCustom /
///   delete-custom) are not part of the channel contract; only "current"
///   and the built-in preset names are offered.
/// - Mirroring upstream, the save sends the selected name as-is; selecting
///   "current" stores the content under the website's rewrite file.
/// </summary>
public static class WebsiteConfigRewriteTab
{
    /// <summary>Preset rewrite template names, upstream Rewrites constant
    /// (frontend/src/global/mimetype.ts).</summary>
    private static readonly string[] Rewrites =
    {
        "default", "wordpress", "wp2", "typecho", "typecho2", "thinkphp",
        "yii2", "laravel5", "discuz", "discuzx", "discuzx2", "discuzx3",
        "EduSoho", "EmpireCMS", "ShopWind", "crmeb", "dabr", "dbshop",
        "dedecms", "drupal", "ecshop", "emlog", "maccms", "mvc", "niushop",
        "phpcms", "sablog", "seacms", "shopex", "zblog",
    };

    private const string CurrentName = "current";

    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        // ── Shared state (closure-captured; the tab is rebuilt per website) ──
        bool busy = false;
        string selectedName = CurrentName;

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

        // ── Card with the mode selector, editor and save action ──
        var modeCombo = new ComboBox { MinWidth = 220, HorizontalAlignment = HorizontalAlignment.Left };
        modeCombo.Items.Add(new ComboBoxItem { Content = L10n.T("hostRewriteCurrent", "Current"), Tag = CurrentName });
        foreach (var rewrite in Rewrites)
        {
            modeCombo.Items.Add(new ComboBoxItem { Content = rewrite, Tag = rewrite });
        }

        var contentBox = new TextBox
        {
            AcceptsReturn = true,
            Height = 360,
            FontFamily = new FontFamily("Consolas"),
            IsSpellCheckEnabled = false,
            TextWrapping = TextWrapping.NoWrap,
            PlaceholderText = L10n.T("hostRewriteContentPlaceholder", "# nginx rewrite rules"),
        };
        // WinUI3 TextBox exposes scrollbars only as ScrollViewer attached
        // properties; they cannot be set in an object initializer.
        ScrollViewer.SetVerticalScrollBarVisibility(contentBox, ScrollBarVisibility.Auto);
        ScrollViewer.SetHorizontalScrollBarVisibility(contentBox, ScrollBarVisibility.Auto);

        var saveButton = new Button { Padding = new Thickness(16, 5, 16, 5), Content = L10n.T("hostRewriteSaveAndReload", "Save and reload") };
        if (Application.Current.Resources.TryGetValue("AccentButtonStyle", out var accentStyle) && accentStyle is Style accent)
        {
            saveButton.Style = accent;
        }

        var card = RewriteCreateCard(L10n.T("hostRewriteCardTitle", "Rewrite rules"), out var cardPanel);

        cardPanel.Children.Add(RewriteFieldRow(L10n.T("hostRewriteMode", "Rewrite mode"), modeCombo));
        cardPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostRewriteHelper2", "Modifying rewrite rules may affect how the website resolves."),
            FontSize = 11,
            Foreground = RewriteThemeBrush("TextFillColorTertiaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        });
        cardPanel.Children.Add(contentBox);
        cardPanel.Children.Add(new TextBlock
        {
            Text = L10n.T("hostRewriteHelper", "Saved rules take effect once nginx reloads, which happens automatically after saving."),
            FontSize = 11,
            Foreground = RewriteThemeBrush("TextFillColorTertiaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        });
        cardPanel.Children.Add(saveButton);

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
        content.Children.Add(new TextBlock
        {
            Text = websiteName,
            FontSize = 12,
            Foreground = RewriteThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        });
        content.Children.Add(status);
        content.Children.Add(loadingPanel);
        content.Children.Add(card);
        root.Content = content;

        // ── Local flows ──

        void SetBusy(bool value)
        {
            busy = value;
            modeCombo.IsEnabled = !value;
            contentBox.IsEnabled = !value;
            saveButton.IsEnabled = !value;
        }

        async Task LoadAsync(string name)
        {
            if (busy) return;
            SetBusy(true);
            loadingPanel.Visibility = Visibility.Visible;

            JsonElement? result = await WindowsBridge.GetWebsiteRewriteAsync(websiteId, name);

            SetBusy(false);
            loadingPanel.Visibility = Visibility.Collapsed;

            if (result is not JsonElement json || json.ValueKind != JsonValueKind.Object ||
                !json.TryGetProperty("content", out var contentElement) ||
                contentElement.ValueKind != JsonValueKind.String)
            {
                RewriteSetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostRewriteLoadFailed", "Failed to load the rewrite content."));
                return;
            }

            contentBox.Text = contentElement.GetString() ?? "";
        }

        async Task SaveAsync()
        {
            if (busy) return;
            var xamlRoot = root.XamlRoot;
            if (xamlRoot == null) return;

            var confirmed = await ConfirmDialog.ShowAsync(
                xamlRoot,
                L10n.T("hostRewriteSaveAndReload", "Save and reload"),
                string.Format(
                    L10n.T("hostRewriteSaveConfirmMessage",
                        "Save the rewrite rules for \"{0}\" and reload nginx?"),
                    selectedName == CurrentName
                        ? L10n.T("hostRewriteCurrent", "Current").ToLowerInvariant()
                        : selectedName),
                L10n.T("commonSave", "Save"),
                L10n.T("commonCancel", "Cancel"));
            if (!confirmed) return;

            SetBusy(true);
            bool ok;
            try
            {
                ok = await WindowsBridge.UpdateWebsiteRewriteAsync(websiteId, selectedName, contentBox.Text);
            }
            finally
            {
                SetBusy(false);
            }

            if (ok)
            {
                RewriteSetStatus(status, InfoBarSeverity.Success,
                    L10n.T("hostRewriteSaved", "Rewrite rules saved and nginx reloaded."));
            }
            else
            {
                RewriteSetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostRewriteSaveFailed", "Failed to save the rewrite rules."));
            }
        }

        modeCombo.SelectionChanged += (s, e) =>
        {
            var name = RewriteComboTag(modeCombo);
            if (name == null || name == selectedName) return;
            selectedName = name;
            _ = LoadAsync(name);
        };
        saveButton.Click += async (s, e) => await SaveAsync();

        // Initial selection: the website's current rewrite content, matching
        // the upstream "current" mode semantics.
        RewriteSelectComboByTag(modeCombo, CurrentName);
        _ = LoadAsync(CurrentName);
        return root;
    }

    private static void RewriteSetStatus(InfoBar bar, InfoBarSeverity severity, string message)
    {
        bar.Severity = severity;
        bar.Message = message;
        bar.IsOpen = true;
    }

    private static string? RewriteComboTag(ComboBox combo)
    {
        return (combo.SelectedItem as ComboBoxItem)?.Tag as string;
    }

    private static void RewriteSelectComboByTag(ComboBox combo, string tag)
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

    /// <summary>Label-over-control row (upstream label-position form item).</summary>
    private static FrameworkElement RewriteFieldRow(string label, FrameworkElement control)
    {
        var panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 4 };
        panel.Children.Add(new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = RewriteThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
        });
        panel.Children.Add(control);
        return panel;
    }

    /// <summary>Card shell shared with SecurityGatewayPage: transparent-ish
    /// fill, CardStroke border, rounded corners and a semi-bold title.</summary>
    private static FrameworkElement RewriteCreateCard(string title, out StackPanel panel)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = RewriteThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = RewriteSubtleFill(),
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

    private static Brush RewriteThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Brush RewriteSubtleFill()
    {
        var stroke = RewriteThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}
