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
/// Website config center - "Redirect" tab, desktop layout adaptation of the
/// upstream 1Panel website redirect views
/// (frontend/src/views/website/website/config/basic/redirect/index.vue +
/// create/index.vue): a redirect rule list (name, type, source, redirect
/// code, target, keep-path, status toggle, edit, delete) plus an inline
/// add/edit form with a type selector (domain | path | 404), the redirect
/// code (301 | 302), the type-dependent source fields (multi-line domains
/// for domain, path input for path), the target URL and the keep-path
/// switch (hidden for 404). Editing disables name and type like upstream;
/// a 404 redirect pins its name to "404".
///
/// Bridge mapping (contract: docs/development/modules/b1_website_channel_contract.md):
/// list via GetWebsiteRedirectsAsync, every mutation (create, edit, enable,
/// disable, delete) via UpdateWebsiteRedirectAsync with the matching
/// operate - exactly how the upstream index.vue reuses operateRedirectConfig
/// for all five operations. Writes are confirmed with ConfirmDialog (cancel
/// is the default button) and surface as an in-page InfoBar (red error /
/// green success) because the shared ErrorToast needs a page base class the
/// tabs do not have.
///
/// Known contract deviations (documented, not fixable client-side):
/// - The upstream 404 "redirect root" switch is not rendered: the channel
///   contract carries no redirectRoot field, so the state could not be
///   persisted; this tab keeps the upstream initData default
///   (redirectRoot=false) semantics and always shows the target input.
/// - Domains are entered as free text lines instead of the upstream
///   multiselect over the website domain list (desktop adaptation; the
///   upstream "exclude domains used by other redirects" refinement is not
///   reproducible without an extra domains fetch in the form).
/// </summary>
public static class WebsiteConfigRedirectTab
{
    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        // ── Shared state (closure-captured; the tab is rebuilt per website) ──
        bool busy = false;
        bool suppressToggle = false;
        string? editingName = null; // null = create mode
        WebsiteConfigRedirectEntry? editingEntry = null;

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

        // ── List card ──
        var refreshButton = new Button
        {
            Padding = new Thickness(8, 2, 8, 2),
            VerticalAlignment = VerticalAlignment.Center,
            Content = new FontIcon { Glyph = "\uE72C", FontSize = 14 },
        };
        ToolTipService.SetToolTip(refreshButton, L10n.T("commonRefresh", "Refresh"));
        // Click wiring intentionally deferred: the lambda reaches LoadAsync and
        // the form flows, so every local they capture must already be
        // definitely assigned here or CS0165 fires (wired below, after all
        // declarations).
        var listCard = RedirectCreateCard(L10n.T("hostRedirectListTitle", "Redirect rules"), out var listPanel, refreshButton);

        // ── Form controls (shared by create and edit) ──
        var typeCombo = new ComboBox { MinWidth = 160, HorizontalAlignment = HorizontalAlignment.Left };
        typeCombo.Items.Add(new ComboBoxItem { Content = L10n.T("hostRedirectTypeDomain", "Domain"), Tag = "domain" });
        typeCombo.Items.Add(new ComboBoxItem { Content = L10n.T("hostRedirectTypePath", "Path"), Tag = "path" });
        typeCombo.Items.Add(new ComboBoxItem { Content = "404", Tag = "404" });
        typeCombo.SelectedIndex = 0;

        var nameBox = new TextBox();
        var redirectCombo = new ComboBox { MinWidth = 120, HorizontalAlignment = HorizontalAlignment.Left };
        redirectCombo.Items.Add(new ComboBoxItem { Content = "301", Tag = "301" });
        redirectCombo.Items.Add(new ComboBoxItem { Content = "302", Tag = "302" });
        redirectCombo.SelectedIndex = 0;

        var domainsBox = new TextBox
        {
            AcceptsReturn = true,
            Height = 88,
            PlaceholderText = L10n.T("hostRedirectDomainsPlaceholder", "One domain per line, e.g. old.example.com"),
            TextWrapping = TextWrapping.NoWrap,
        };
        ScrollViewer.SetVerticalScrollBarVisibility(domainsBox, ScrollBarVisibility.Auto);

        var pathBox = new TextBox { PlaceholderText = "/old-path" };
        var targetBox = new TextBox { PlaceholderText = "https://new.example.com" };
        var keepPathSwitch = new ToggleSwitch
        {
            OnContent = "",
            OffContent = "",
            IsOn = true,
            HorizontalAlignment = HorizontalAlignment.Left,
            Margin = new Thickness(0, -8, 0, -8),
        };

        var saveButton = new Button { Padding = new Thickness(16, 5, 16, 5), Content = L10n.T("commonSave", "Save") };
        if (Application.Current.Resources.TryGetValue("AccentButtonStyle", out var accentStyle) && accentStyle is Style accent)
        {
            saveButton.Style = accent;
        }
        var cancelEditButton = new Button
        {
            Padding = new Thickness(12, 5, 12, 5),
            Content = L10n.T("hostRedirectCancelEdit", "Cancel edit"),
            Visibility = Visibility.Collapsed,
        };

        // ── Form card (title swaps between add and edit) ──
        var formTitle = new TextBlock
        {
            Text = L10n.T("hostRedirectAdd", "Add Redirect"),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
        };
        var formCard = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = RedirectThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = RedirectSubtleFill(),
        };
        var formPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        formPanel.Children.Add(formTitle);
        formPanel.Children.Add(RedirectFieldRow(L10n.T("commonType", "Type"), typeCombo));
        formPanel.Children.Add(RedirectFieldRow(L10n.T("commonName", "Name"), nameBox));
        formPanel.Children.Add(RedirectFieldRow(
            L10n.T("hostRedirectWay", "Redirect"),
            redirectCombo,
            L10n.T("hostRedirectWayHelper", "301 is permanent, 302 is temporary.")));
        var domainsField = RedirectFieldRow(
            L10n.T("hostRedirectDomains", "Domains"),
            domainsBox,
            L10n.T("hostRedirectDomainsHelper", "One domain per line."));
        formPanel.Children.Add(domainsField);
        var pathField = RedirectFieldRow(L10n.T("commonPath", "Path"), pathBox);
        formPanel.Children.Add(pathField);
        formPanel.Children.Add(RedirectFieldRow(L10n.T("hostRedirectTarget", "Target URL"), targetBox));
        var keepPathRow = RedirectSwitchRow(
            L10n.T("hostRedirectKeepPath", "Keep path"),
            L10n.T("hostRedirectKeepPathHelper", "Append the original request path to the target URL."),
            keepPathSwitch);
        formPanel.Children.Add(keepPathRow);

        var buttonRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, Margin = new Thickness(0, 4, 0, 0) };
        buttonRow.Children.Add(saveButton);
        buttonRow.Children.Add(cancelEditButton);
        formPanel.Children.Add(buttonRow);
        formCard.Child = formPanel;

        content.Children.Add(new TextBlock
        {
            Text = websiteName,
            FontSize = 12,
            Foreground = RedirectThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        });
        content.Children.Add(status);
        content.Children.Add(loadingPanel);
        content.Children.Add(listCard);
        content.Children.Add(formCard);
        root.Content = content;

        // ── Field interactions ──
        typeCombo.SelectionChanged += (s, e) =>
        {
            var type = RedirectComboTag(typeCombo) ?? "domain";
            UpdateTypeVisibility();
            if (type == "404")
            {
                // Upstream changeType: a 404 redirect is pinned to name "404".
                nameBox.Text = "404";
                nameBox.IsEnabled = false;
            }
            else if (editingName == null)
            {
                nameBox.Text = "";
                nameBox.IsEnabled = true;
            }
        };
        cancelEditButton.Click += (s, e) => ResetForm();

        void UpdateTypeVisibility()
        {
            var type = RedirectComboTag(typeCombo) ?? "domain";
            domainsField.Visibility = type == "domain" ? Visibility.Visible : Visibility.Collapsed;
            pathField.Visibility = type == "path" ? Visibility.Visible : Visibility.Collapsed;
            keepPathRow.Visibility = type == "404" ? Visibility.Collapsed : Visibility.Visible;
        }

        // ── Local handlers / flows ──

        void SetToggleSilently(ToggleSwitch toggle, bool isOn)
        {
            suppressToggle = true;
            try
            {
                toggle.IsOn = isOn;
            }
            finally
            {
                suppressToggle = false;
            }
        }

        async Task LoadAsync(bool showLoading)
        {
            if (busy) return;
            busy = true;
            if (showLoading)
            {
                loadingPanel.Visibility = Visibility.Visible;
                listCard.Visibility = Visibility.Collapsed;
            }

            var entries = RedirectParseList(await WindowsBridge.GetWebsiteRedirectsAsync(websiteId));

            busy = false;
            loadingPanel.Visibility = Visibility.Collapsed;
            listCard.Visibility = Visibility.Visible;
            listPanel.Children.Clear();

            if (entries == null)
            {
                RedirectSetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostRedirectLoadFailed", "Failed to load the redirect list."));
                listPanel.Children.Add(RedirectEmptyHint());
                return;
            }

            if (entries.Count == 0)
            {
                listPanel.Children.Add(RedirectEmptyHint());
                return;
            }

            for (int i = 0; i < entries.Count; i++)
            {
                listPanel.Children.Add(BuildRow(entries[i]));
                if (i < entries.Count - 1)
                {
                    listPanel.Children.Add(new Border
                    {
                        Height = 1,
                        Background = RedirectThemeBrush("DividerStrokeColorDefaultBrush", Colors.Gray),
                        Opacity = 0.5,
                    });
                }
            }
        }

        /// <summary>Bridge payload for one row mutation: upstream passes the
        /// full row with a changed operate/enable, so type-dependent fields
        /// are sent only for the matching type (Dart omits null keys).</summary>
        List<object>? EntryDomains(WebsiteConfigRedirectEntry entry)
        {
            if (entry.Type != "domain") return null;
            var domains = new List<object>();
            foreach (var domain in entry.Domains)
            {
                domains.Add(domain);
            }
            return domains;
        }

        FrameworkElement BuildRow(WebsiteConfigRedirectEntry entry)
        {
            var row = new Grid { ColumnSpacing = 8, RowSpacing = 2, Margin = new Thickness(0, 2, 0, 2) };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
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

            var typePill = RedirectPill(RedirectTypeLabel(entry.Type));
            Grid.SetRow(typePill, 0);
            Grid.SetColumn(typePill, 1);
            row.Children.Add(typePill);

            // Edit is disabled for a disabled redirect (upstream buttons list).
            var editButton = new Button
            {
                Padding = new Thickness(8, 2, 8, 2),
                VerticalAlignment = VerticalAlignment.Center,
                FontSize = 12,
                Content = L10n.T("commonEdit", "Edit"),
                IsEnabled = entry.Enable,
            };
            editButton.Click += (s, e) => FillForm(entry);
            Grid.SetRow(editButton, 0);
            Grid.SetColumn(editButton, 2);
            row.Children.Add(editButton);

            var deleteButton = new Button
            {
                Padding = new Thickness(8, 2, 8, 2),
                VerticalAlignment = VerticalAlignment.Center,
                FontSize = 12,
                Content = L10n.T("commonDelete", "Delete"),
            };
            deleteButton.Click += async (s, e) =>
            {
                if (busy) return;
                var xamlRoot = root.XamlRoot;
                if (xamlRoot == null) return;

                var confirmed = await ConfirmDialog.ShowAsync(
                    xamlRoot,
                    L10n.T("hostRedirectDeleteConfirmTitle", "Delete redirect"),
                    string.Format(
                        L10n.T("hostRedirectDeleteConfirmMessage", "Delete redirect \"{0}\"?"),
                        entry.Name),
                    L10n.T("commonDelete", "Delete"),
                    L10n.T("commonCancel", "Cancel"),
                    isDestructive: true);
                if (!confirmed) return;

                busy = true;
                var ok = await WindowsBridge.UpdateWebsiteRedirectAsync(
                    websiteId,
                    "delete",
                    entry.Enable,
                    entry.Name,
                    entry.Type,
                    string.IsNullOrEmpty(entry.Redirect) ? "301" : entry.Redirect,
                    entry.Type != "404" ? entry.KeepPath : null,
                    entry.Type == "path" ? entry.Path : null,
                    entry.Target,
                    EntryDomains(entry));
                busy = false;
                if (ok)
                {
                    RedirectSetStatus(status, InfoBarSeverity.Success,
                        L10n.T("hostRedirectDeleted", "Redirect deleted."));
                    await LoadAsync(showLoading: false);
                }
                else
                {
                    RedirectSetStatus(status, InfoBarSeverity.Error,
                        L10n.T("hostRedirectDeleteFailed", "Failed to delete the redirect."));
                }
            };
            Grid.SetRow(deleteButton, 0);
            Grid.SetColumn(deleteButton, 3);
            row.Children.Add(deleteButton);

            var toggle = new ToggleSwitch
            {
                OnContent = "",
                OffContent = "",
                IsOn = entry.Enable,
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(8, -8, 0, -8),
            };
            ToolTipService.SetToolTip(toggle, entry.Enable
                ? L10n.T("hostRedirectDisable", "Disable")
                : L10n.T("commonEnable", "Enable"));
            toggle.Toggled += async (s, e) =>
            {
                if (suppressToggle) return;
                var enable = toggle.IsOn;
                if (busy)
                {
                    SetToggleSilently(toggle, !enable);
                    return;
                }
                var xamlRoot = root.XamlRoot;
                if (xamlRoot == null) return;

                var confirmed = await ConfirmDialog.ShowAsync(
                    xamlRoot,
                    L10n.T(enable ? "hostRedirectEnableConfirmTitle" : "hostRedirectDisableConfirmTitle",
                        enable ? "Enable redirect" : "Disable redirect"),
                    string.Format(
                        L10n.T(enable ? "hostRedirectEnableConfirmMessage" : "hostRedirectDisableConfirmMessage",
                            enable ? "Enable redirect \"{0}\"?" : "Disable redirect \"{0}\"?"),
                        entry.Name),
                    L10n.T(enable ? "commonEnable" : "hostRedirectDisable", enable ? "Enable" : "Disable"),
                    L10n.T("commonCancel", "Cancel"));
                if (!confirmed)
                {
                    SetToggleSilently(toggle, !enable);
                    return;
                }

                busy = true;
                var ok = await WindowsBridge.UpdateWebsiteRedirectAsync(
                    websiteId,
                    enable ? "enable" : "disable",
                    enable,
                    entry.Name,
                    entry.Type,
                    string.IsNullOrEmpty(entry.Redirect) ? "301" : entry.Redirect,
                    entry.Type != "404" ? entry.KeepPath : null,
                    entry.Type == "path" ? entry.Path : null,
                    entry.Target,
                    EntryDomains(entry));
                busy = false;
                if (ok)
                {
                    RedirectSetStatus(status, InfoBarSeverity.Success,
                        L10n.T("hostRedirectStatusUpdated", "Redirect status updated."));
                    await LoadAsync(showLoading: false);
                }
                else
                {
                    SetToggleSilently(toggle, !enable);
                    RedirectSetStatus(status, InfoBarSeverity.Error,
                        L10n.T("hostRedirectStatusFailed", "Failed to update the redirect status."));
                }
            };
            Grid.SetRow(toggle, 0);
            Grid.SetColumn(toggle, 4);
            row.Children.Add(toggle);

            // Second line: "source → target" with the keep-path suffix for
            // non-404 types (upstream sourceDomain/target/keepPath columns).
            var source = entry.Type == "domain"
                ? string.Join(", ", entry.Domains)
                : entry.Type == "path" ? entry.Path : "";
            if (string.IsNullOrWhiteSpace(source)) source = "--";
            var target = string.IsNullOrWhiteSpace(entry.Target) ? "--" : entry.Target;
            var line = $"{source} \u2192 {target}";
            if (entry.Type != "404")
            {
                line += entry.KeepPath
                    ? $" \u00B7 {L10n.T("hostRedirectKeep", "keep path")}"
                    : $" \u00B7 {L10n.T("hostRedirectNotKeep", "drop path")}";
            }
            var detailBlock = new TextBlock
            {
                Text = line,
                FontSize = 12,
                Foreground = RedirectThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
            };
            Grid.SetRow(detailBlock, 1);
            Grid.SetColumn(detailBlock, 0);
            Grid.SetColumnSpan(detailBlock, 5);
            row.Children.Add(detailBlock);

            return row;
        }

        void FillForm(WebsiteConfigRedirectEntry entry)
        {
            editingName = entry.Name;
            editingEntry = entry;
            formTitle.Text = L10n.T("hostRedirectEditTitle", "Edit Redirect");
            cancelEditButton.Visibility = Visibility.Visible;

            RedirectSelectComboByTag(typeCombo, entry.Type);
            typeCombo.IsEnabled = false; // upstream disables the type select while editing
            nameBox.Text = entry.Name;
            nameBox.IsEnabled = false;   // upstream disables the name input while editing
            RedirectSelectComboByTag(redirectCombo, string.IsNullOrEmpty(entry.Redirect) ? "301" : entry.Redirect);
            domainsBox.Text = string.Join(Environment.NewLine, entry.Domains);
            pathBox.Text = entry.Path;
            targetBox.Text = entry.Target;
            keepPathSwitch.IsOn = entry.KeepPath;
            UpdateTypeVisibility();
        }

        void ResetForm()
        {
            editingName = null;
            editingEntry = null;
            formTitle.Text = L10n.T("hostRedirectAdd", "Add Redirect");
            cancelEditButton.Visibility = Visibility.Collapsed;

            typeCombo.IsEnabled = true;
            RedirectSelectComboByTag(typeCombo, "domain");
            nameBox.Text = "";
            nameBox.IsEnabled = true;
            RedirectSelectComboByTag(redirectCombo, "301");
            domainsBox.Text = "";
            pathBox.Text = "";
            targetBox.Text = "";
            keepPathSwitch.IsOn = true;
            UpdateTypeVisibility();
        }

        async Task SaveAsync()
        {
            if (busy) return;
            var xamlRoot = root.XamlRoot;
            if (xamlRoot == null) return;

            var type = RedirectComboTag(typeCombo) ?? "domain";
            var name = type == "404" ? "404" : nameBox.Text.Trim();
            var redirectCode = RedirectComboTag(redirectCombo) ?? "301";
            var target = targetBox.Text.Trim();

            if (name.Length == 0)
            {
                RedirectSetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostRedirectNameRequired", "Name is required."));
                return;
            }

            List<object>? domains = null;
            if (type == "domain")
            {
                var parsed = new List<object>();
                foreach (var line in domainsBox.Text.Split('\n'))
                {
                    var domain = line.Trim();
                    if (domain.Length > 0) parsed.Add(domain);
                }
                if (parsed.Count == 0)
                {
                    RedirectSetStatus(status, InfoBarSeverity.Error,
                        L10n.T("hostRedirectDomainsRequired", "At least one domain is required."));
                    return;
                }
                domains = parsed;
            }

            string? path = null;
            if (type == "path")
            {
                path = pathBox.Text.Trim();
                if (path.Length == 0)
                {
                    RedirectSetStatus(status, InfoBarSeverity.Error,
                        L10n.T("hostRedirectPathRequired", "Path is required."));
                    return;
                }
            }

            if (target.Length == 0)
            {
                RedirectSetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostRedirectTargetRequired", "Target URL is required."));
                return;
            }

            bool? keepPath = type == "404" ? null : keepPathSwitch.IsOn;
            var operate = editingName == null ? "create" : "edit";
            // Editing keeps the row's enable state; new rules start enabled
            // (upstream initData enable=true).
            var enable = operate == "edit" && editingEntry != null ? editingEntry.Enable : true;

            busy = true;
            saveButton.IsEnabled = false;
            bool ok;
            try
            {
                ok = await WindowsBridge.UpdateWebsiteRedirectAsync(
                    websiteId, operate, enable, name, type, redirectCode,
                    keepPath, path, target, domains);
            }
            finally
            {
                busy = false;
                saveButton.IsEnabled = true;
            }

            if (ok)
            {
                RedirectSetStatus(status, InfoBarSeverity.Success,
                    L10n.T(operate == "create" ? "hostRedirectCreated" : "hostRedirectSaved",
                        operate == "create" ? "Redirect created." : "Redirect saved."));
                ResetForm();
                await LoadAsync(showLoading: false);
            }
            else
            {
                RedirectSetStatus(status, InfoBarSeverity.Error,
                    L10n.T("hostRedirectSaveFailed", "Failed to save the redirect."));
            }
        }

        saveButton.Click += async (s, e) => await SaveAsync();
        refreshButton.Click += (s, e) => _ = LoadAsync(showLoading: true);

        ResetForm();
        _ = LoadAsync(showLoading: true);
        return root;
    }

    private static string RedirectTypeLabel(string type)
    {
        return type switch
        {
            "domain" => L10n.T("hostRedirectTypeDomain", "Domain"),
            "path" => L10n.T("hostRedirectTypePath", "Path"),
            _ => string.IsNullOrWhiteSpace(type) ? "--" : type,
        };
    }

    private static FrameworkElement RedirectPill(string text)
    {
        var stroke = RedirectThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            VerticalAlignment = VerticalAlignment.Center,
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, color.R, color.G, color.B)),
            Child = new TextBlock
            {
                Text = text,
                FontSize = 12,
                Foreground = RedirectThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                VerticalAlignment = VerticalAlignment.Center,
            },
        };
    }

    private static FrameworkElement RedirectEmptyHint()
    {
        return new TextBlock
        {
            Text = L10n.T("hostRedirectEmpty", "No redirect rules yet."),
            FontSize = 12,
            Foreground = RedirectThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        };
    }

    private static void RedirectSetStatus(InfoBar bar, InfoBarSeverity severity, string message)
    {
        bar.Severity = severity;
        bar.Message = message;
        bar.IsOpen = true;
    }

    private static string? RedirectComboTag(ComboBox combo)
    {
        return (combo.SelectedItem as ComboBoxItem)?.Tag as string;
    }

    private static void RedirectSelectComboByTag(ComboBox combo, string tag)
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

    private static List<WebsiteConfigRedirectEntry>? RedirectParseList(JsonElement? element)
    {
        if (element is not JsonElement json || json.ValueKind != JsonValueKind.Array)
        {
            return null;
        }

        var list = new List<WebsiteConfigRedirectEntry>();
        foreach (var item in json.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.Object) continue;

            var domains = new List<string>();
            if (item.TryGetProperty("domains", out var domainsElement) &&
                domainsElement.ValueKind == JsonValueKind.Array)
            {
                foreach (var domain in domainsElement.EnumerateArray())
                {
                    if (domain.ValueKind == JsonValueKind.String)
                    {
                        var value = domain.GetString();
                        if (!string.IsNullOrWhiteSpace(value)) domains.Add(value);
                    }
                }
            }

            list.Add(new WebsiteConfigRedirectEntry
            {
                Name = RedirectTryGetString(item, "name") ?? "",
                Type = RedirectTryGetString(item, "type") ?? "domain",
                Redirect = RedirectTryGetString(item, "redirect") ?? "301",
                Path = RedirectTryGetString(item, "path") ?? "",
                Target = RedirectTryGetString(item, "target") ?? "",
                KeepPath = RedirectTryGetBool(item, "keepPath", true),
                Enable = RedirectTryGetBool(item, "enable", false),
                Domains = domains,
            });
        }

        return list;
    }

    private static string? RedirectTryGetString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static bool RedirectTryGetBool(JsonElement element, string property, bool fallback)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop))
        {
            if (prop.ValueKind == JsonValueKind.True) return true;
            if (prop.ValueKind == JsonValueKind.False) return false;
        }
        return fallback;
    }

    /// <summary>Label-over-control row with optional helper line (upstream
    /// label-position top form items with input-help).</summary>
    private static FrameworkElement RedirectFieldRow(string label, FrameworkElement control, string? help = null)
    {
        var panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 4 };
        panel.Children.Add(new TextBlock
        {
            Text = label,
            FontSize = 12,
            Foreground = RedirectThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
        });
        panel.Children.Add(control);
        if (help != null)
        {
            panel.Children.Add(new TextBlock
            {
                Text = help,
                FontSize = 11,
                Foreground = RedirectThemeBrush("TextFillColorTertiaryBrush", Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
            });
        }
        return panel;
    }

    /// <summary>Title+help caption on the left, switch on the trailing edge.</summary>
    private static FrameworkElement RedirectSwitchRow(string title, string? help, ToggleSwitch toggle)
    {
        var textPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 2 };
        textPanel.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.Medium,
            TextWrapping = TextWrapping.Wrap,
        });
        if (help != null)
        {
            textPanel.Children.Add(new TextBlock
            {
                Text = help,
                FontSize = 11,
                Foreground = RedirectThemeBrush("TextFillColorTertiaryBrush", Colors.Gray),
                TextWrapping = TextWrapping.Wrap,
            });
        }

        var grid = new Grid { ColumnSpacing = 8 };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(textPanel, 0);
        Grid.SetColumn(toggle, 1);
        grid.Children.Add(textPanel);
        grid.Children.Add(toggle);
        return grid;
    }

    /// <summary>Card shell shared with SecurityGatewayPage: transparent-ish
    /// fill, CardStroke border, rounded corners, semi-bold title and an
    /// optional trailing header action.</summary>
    private static FrameworkElement RedirectCreateCard(
        string title, out StackPanel panel, FrameworkElement? headerAction = null)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = RedirectThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = RedirectSubtleFill(),
        };

        panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };

        var titleBlock = new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
        };

        if (headerAction != null)
        {
            var header = new Grid { ColumnSpacing = 8 };
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            Grid.SetColumn(titleBlock, 0);
            Grid.SetColumn(headerAction, 1);
            header.Children.Add(titleBlock);
            header.Children.Add(headerAction);
            panel.Children.Add(header);
        }
        else
        {
            panel.Children.Add(titleBlock);
        }

        card.Child = panel;
        return card;
    }

    private static Brush RedirectThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Brush RedirectSubtleFill()
    {
        var stroke = RedirectThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}

/// <summary>Immutable view over one redirect config row from the bridge.</summary>
internal sealed class WebsiteConfigRedirectEntry
{
    public string Name { get; init; } = "";
    public string Type { get; init; } = "domain";
    public string Redirect { get; init; } = "301";
    public string Path { get; init; } = "";
    public string Target { get; init; } = "";
    public bool KeepPath { get; init; } = true;
    public bool Enable { get; init; }
    public List<string> Domains { get; init; } = new();
}
