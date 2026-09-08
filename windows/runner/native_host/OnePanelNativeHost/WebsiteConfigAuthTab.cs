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
/// Website config center - Basic Authentication tab (upstream
/// frontend/src/views/website/website/config/basic/auth-basic/index.vue with
/// the shared create drawer).
///
/// Two sub-tabs mirror the upstream el-tabs: Global (root scope) and Path.
/// Global shows the master enable switch (disabled while no users exist,
/// upstream parity) plus the user list (username / remark) with Edit and
/// Delete actions; Path shows the path list (name / path / username) with
/// the same actions. Each sub-tab carries an inline add/edit form (username,
/// password with a 16-character random generator over
/// [a-zA-Z0-9_-.@$!%*?&], remark) that writes through UpdateWebsiteAuthAsync
/// (operate create/edit/enable/disable, scope root) or
/// UpdateWebsitePathAuthAsync (operate create/edit/delete). Deletes confirm
/// through a destructive ConfirmDialog; the master switch confirms before
/// writing. Success refreshes both lists (upstream searchAll) and surfaces a
/// dismissible notice; failures show the error toast (writes) or per-source
/// error InfoBars with retry (loads).
///
/// Data flows through WindowsBridge (getWebsiteAuths / getWebsitePathAuths);
/// null per source degrades only that sub-tab. Self-contained: helpers carry
/// the AuthTab prefix. Note the path-auth bridge call has no remark
/// parameter (channel contract), so the path form omits the remark field.
/// </summary>
public static class WebsiteConfigAuthTab
{
    /// <summary>Upstream authBasicPassword rule charset, 16 chars by default.</summary>
    private const string PasswordChars =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.@$!%*?&";
    private const int GeneratedPasswordLength = 16;

    public static FrameworkElement Build(int websiteId, string websiteName)
    {
        var errorToast = new ErrorToast();
        var busyGuard = false;

        // ── Global (root) state ──────────────────────────────────────────
        var globalEnableSwitch = new ToggleSwitch
        {
            OnContent = L10n.T("commonEnable", "Enable"),
            OffContent = L10n.T("hostGatewayDisable", "Disable"),
            IsEnabled = false, // upstream: disabled while the user list is empty
        };
        var globalListPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 6 };
        var globalUserBox = new TextBox();
        var globalPasswordBox = new PasswordBox();
        var globalRemarkBox = new TextBox();
        var globalFormError = AuthTabErrorText();
        var globalFormPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        var globalMode = "create";
        var globalSuppressToggle = false;

        // ── Path state ───────────────────────────────────────────────────
        var pathListPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 6 };
        var pathNameBox = new TextBox();
        var pathPathBox = new TextBox();
        var pathUserBox = new TextBox();
        var pathPasswordBox = new PasswordBox();
        var pathFormError = AuthTabErrorText();
        var pathFormPanel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };
        var pathMode = "create";

        // ── Status surfaces ──────────────────────────────────────────────
        var noticeBar = new InfoBar
        {
            Severity = InfoBarSeverity.Success,
            IsClosable = true,
            IsOpen = false,
            Margin = new Thickness(8, 8, 8, 0),
        };
        var globalErrorRow = AuthTabErrorRow(out var globalErrorBar, out var globalRetryButton);
        var pathErrorRow = AuthTabErrorRow(out var pathErrorBar, out var pathRetryButton);
        var loadingRing = new ProgressRing
        {
            IsActive = true,
            Width = 36,
            Height = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // ── Cards ────────────────────────────────────────────────────────
        var globalAddButton = AuthTabSmallButton(L10n.T("commonAdd", "Add"), "\uE710");
        var globalCard = AuthTabCard(
            L10n.T("websiteAuthBasicTitle", "Auth"),
            L10n.T("hostAuthScopeGlobal", "Global"),
            out var globalCardPanel,
            globalAddButton);
        globalCardPanel.Children.Add(AuthTabSwitchRow(
            L10n.T("hostAuthEnableSwitch", "Enable basic authentication"), globalEnableSwitch));
        globalCardPanel.Children.Add(globalListPanel);

        var globalFormHost = AuthTabFormHost();
        globalFormHost.Child = globalFormPanel;
        globalCardPanel.Children.Add(globalFormHost);

        var pathAddButton = AuthTabSmallButton(L10n.T("commonAdd", "Add"), "\uE710");
        var pathCard = AuthTabCard(
            L10n.T("websiteAuthBasicTitle", "Auth"),
            L10n.T("commonPath", "Path"),
            out var pathCardPanel,
            pathAddButton);
        pathCardPanel.Children.Add(pathListPanel);

        var pathFormHost = AuthTabFormHost();
        pathFormHost.Child = pathFormPanel;
        pathCardPanel.Children.Add(pathFormHost);

        // ── Sub-tab pivot (upstream el-tabs Global / Path) ──────────────
        var pivot = new Pivot
        {
            Margin = new Thickness(0, 4, 0, 0),
            Visibility = Visibility.Collapsed,
            LeftHeader = new TextBlock
            {
                Text = websiteName,
                FontSize = 12,
                Foreground = AuthTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(8, 0, 8, 0),
            },
        };
        pivot.Items.Add(new PivotItem
        {
            Header = L10n.T("hostAuthScopeGlobal", "Global"),
            Content = WrapInScroll(globalCard),
        });
        pivot.Items.Add(new PivotItem
        {
            Header = L10n.T("commonPath", "Path"),
            Content = WrapInScroll(pathCard),
        });

        var root = new Grid
        {
            RowDefinitions =
            {
                new RowDefinition { Height = GridLength.Auto },
                new RowDefinition { Height = GridLength.Auto },
                new RowDefinition { Height = GridLength.Auto },
                new RowDefinition { Height = new GridLength(1, GridUnitType.Star) },
            },
        };
        Grid.SetRow(noticeBar, 0);
        Grid.SetRow(globalErrorRow, 1);
        Grid.SetRow(pathErrorRow, 2);
        Grid.SetRow(pivot, 3);
        Grid.SetRow(loadingRing, 3);
        errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(errorToast, 3);
        root.Children.Add(noticeBar);
        root.Children.Add(globalErrorRow);
        root.Children.Add(pathErrorRow);
        root.Children.Add(pivot);
        root.Children.Add(loadingRing);
        root.Children.Add(errorToast);

        // ── Form construction (hidden until Add/Edit) ───────────────────
        var globalPasswordRow = AuthTabPasswordRow(globalPasswordBox, () =>
        {
            globalPasswordBox.Password = AuthTabRandomPassword();
        });
        var globalConfirmButton = AuthTabSmallButton(L10n.T("commonConfirm", "Confirm"), null);
        var globalCancelButton = AuthTabSmallButton(L10n.T("commonCancel", "Cancel"), null);
        var globalEditHelper = new InfoBar
        {
            Title = L10n.T("hostAuthEditHelper",
                "The password cannot be echoed. Editing resets the password."),
            Severity = InfoBarSeverity.Informational,
            IsClosable = false,
            IsOpen = true,
            Visibility = Visibility.Collapsed, // upstream: edit-mode alert only
        };
        globalFormPanel.Children.Add(globalEditHelper);
        globalFormPanel.Children.Add(AuthTabFieldRow(
            L10n.T("commonUsername", "Username"), globalUserBox));
        globalFormPanel.Children.Add(AuthTabFieldRow(
            L10n.T("commonPassword", "Password"), globalPasswordRow));
        globalFormPanel.Children.Add(AuthTabFieldRow(
            L10n.T("hostAuthRemark", "Remark"), globalRemarkBox));
        globalFormPanel.Children.Add(globalFormError);
        globalFormPanel.Children.Add(AuthTabButtonRow(globalConfirmButton, globalCancelButton));
        HideGlobalForm();

        var pathPasswordRow = AuthTabPasswordRow(pathPasswordBox, () =>
        {
            pathPasswordBox.Password = AuthTabRandomPassword();
        });
        var pathConfirmButton = AuthTabSmallButton(L10n.T("commonConfirm", "Confirm"), null);
        var pathCancelButton = AuthTabSmallButton(L10n.T("commonCancel", "Cancel"), null);
        var pathEditHelper = new InfoBar
        {
            Title = L10n.T("hostAuthEditHelper",
                "The password cannot be echoed. Editing resets the password."),
            Severity = InfoBarSeverity.Informational,
            IsClosable = false,
            IsOpen = true,
            Visibility = Visibility.Collapsed, // upstream: edit-mode alert only
        };
        pathFormPanel.Children.Add(pathEditHelper);
        pathFormPanel.Children.Add(AuthTabFieldRow(L10n.T("commonName", "Name"), pathNameBox));
        pathFormPanel.Children.Add(AuthTabFieldRow(L10n.T("commonPath", "Path"), pathPathBox));
        pathFormPanel.Children.Add(AuthTabFieldRow(L10n.T("commonUsername", "Username"), pathUserBox));
        pathFormPanel.Children.Add(AuthTabFieldRow(L10n.T("commonPassword", "Password"), pathPasswordRow));
        pathFormPanel.Children.Add(pathFormError);
        pathFormPanel.Children.Add(AuthTabButtonRow(pathConfirmButton, pathCancelButton));
        HidePathForm();

        // ── Data load ────────────────────────────────────────────────────
        async Task LoadAsync(bool showLoading)
        {
            if (busyGuard) return;
            busyGuard = true;

            if (showLoading)
            {
                loadingRing.Visibility = Visibility.Visible;
                pivot.Visibility = Visibility.Collapsed;
            }

            Task<JsonElement?> globalTask;
            Task<JsonElement?> pathTask;
            try
            {
                globalTask = WindowsBridge.GetWebsiteAuthsAsync(websiteId);
                pathTask = WindowsBridge.GetWebsitePathAuthsAsync(websiteId);
                await Task.WhenAll(globalTask, pathTask);
            }
            finally
            {
                busyGuard = false;
            }

            var global = globalTask.Result;
            var path = pathTask.Result;

            AuthTabShowError(globalErrorBar, globalRetryButton, global == null);
            AuthTabShowError(pathErrorBar, pathRetryButton, path == null);

            if (global == null && path == null)
            {
                // Both sources failed: error InfoBars carry the retry, the
                // current UI stays as-is (initial load keeps the spinner
                // hidden and the pivot collapsed).
                loadingRing.Visibility = Visibility.Collapsed;
                if (!showLoading)
                {
                    errorToast.Show(L10n.T("hostAuthLoadFailed",
                        "Failed to load the basic authentication configuration."));
                }
                return;
            }

            // A failed source degrades alone (retry InfoBar) without
            // overwriting the current list with a misleading empty state.
            if (global != null) RenderGlobal(global);
            if (path != null) RenderPath(path);
            loadingRing.Visibility = Visibility.Collapsed;
            pivot.Visibility = Visibility.Visible;
        }

        void RenderGlobal(JsonElement? global)
        {
            var enable = false;
            var items = new List<JsonElement>();
            if (global is JsonElement map && map.ValueKind == JsonValueKind.Object)
            {
                enable = AuthTabBool(map, "enable");
                if (map.TryGetProperty("items", out var arr) && arr.ValueKind == JsonValueKind.Array)
                {
                    foreach (var item in arr.EnumerateArray())
                    {
                        if (item.ValueKind == JsonValueKind.Object) items.Add(item);
                    }
                }
            }

            globalSuppressToggle = true;
            globalEnableSwitch.IsOn = enable;
            globalEnableSwitch.IsEnabled = items.Count > 0;
            globalSuppressToggle = false;

            globalListPanel.Children.Clear();
            if (items.Count == 0)
            {
                globalListPanel.Children.Add(AuthTabEmptyText(
                    L10n.T("websiteAuthBasicEmpty", "No auth users")));
                return;
            }

            foreach (var item in items)
            {
                var username = AuthTabString(item, "username") ?? "--";
                var remark = AuthTabString(item, "remark") ?? string.Empty;
                globalListPanel.Children.Add(AuthTabListRow(
                    username,
                    remark,
                    L10n.T("hostAuthRemark", "Remark"),
                    editAction: () => ShowGlobalForm("edit", username, remark),
                    deleteAction: () => _ = DeleteGlobalAsync(username)));
            }
        }

        void RenderPath(JsonElement? path)
        {
            var items = new List<JsonElement>();
            if (path is JsonElement arr && arr.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in arr.EnumerateArray())
                {
                    if (item.ValueKind == JsonValueKind.Object) items.Add(item);
                }
            }

            pathListPanel.Children.Clear();
            if (items.Count == 0)
            {
                pathListPanel.Children.Add(AuthTabEmptyText(
                    L10n.T("hostAuthPathEmpty", "No path authentication rules")));
                return;
            }

            foreach (var item in items)
            {
                var name = AuthTabString(item, "name") ?? "--";
                var pathValue = AuthTabString(item, "path") ?? "--";
                var username = AuthTabString(item, "username") ?? "--";
                pathListPanel.Children.Add(AuthTabListRow(
                    name,
                    $"{pathValue} \u00B7 {username}",
                    null,
                    editAction: () => ShowPathForm("edit", name, pathValue, username),
                    deleteAction: () => _ = DeletePathAsync(name)));
            }
        }

        // ── Global form flow ─────────────────────────────────────────────
        void ShowGlobalForm(string mode, string? username, string? remark)
        {
            if (busyGuard) return;
            globalMode = mode;
            AuthTabSetError(globalFormError, null);
            globalEditHelper.Visibility = mode == "edit" ? Visibility.Visible : Visibility.Collapsed;
            globalUserBox.Text = username ?? string.Empty;
            globalUserBox.IsEnabled = mode != "edit"; // upstream: username fixed on root edit
            globalPasswordBox.Password = string.Empty;
            globalRemarkBox.Text = remark ?? string.Empty;
            globalFormHost.Visibility = Visibility.Visible;
        }

        void HideGlobalForm()
        {
            globalFormHost.Visibility = Visibility.Collapsed;
        }

        globalAddButton.Click += (s, e) => ShowGlobalForm("create", null, null);
        globalCancelButton.Click += (s, e) => HideGlobalForm();
        globalConfirmButton.Click += (s, e) => _ = SaveGlobalAsync();

        async Task SaveGlobalAsync()
        {
            if (busyGuard) return;
            AuthTabSetError(globalFormError, null);

            var username = globalUserBox.Text.Trim();
            var password = globalPasswordBox.Password;
            var remark = globalRemarkBox.Text.Trim();

            if (string.IsNullOrWhiteSpace(username))
            {
                AuthTabSetError(globalFormError,
                    L10n.T("hostAuthUsernameRequired", "Username is required."));
                return;
            }
            if (string.IsNullOrEmpty(password))
            {
                AuthTabSetError(globalFormError,
                    L10n.T("hostAuthPasswordRequired", "Password is required."));
                return;
            }
            if (!AuthTabPasswordValid(password))
            {
                AuthTabSetError(globalFormError, L10n.T("hostAuthPasswordInvalid",
                    "Password may only contain letters, digits and _-.@$!%*?& (max 72 characters)."));
                return;
            }

            busyGuard = true;
            globalConfirmButton.IsEnabled = false;
            bool success;
            try
            {
                success = await WindowsBridge.UpdateWebsiteAuthAsync(
                    websiteId, globalMode, "root", username, password,
                    string.IsNullOrEmpty(remark) ? null : remark);
            }
            finally
            {
                busyGuard = false;
                globalConfirmButton.IsEnabled = true;
            }

            if (success)
            {
                HideGlobalForm();
                ShowNotice(L10n.T("hostAuthSaved", "Basic authentication updated."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAuthSaveFailed", "Failed to update the basic authentication."));
            }
        }

        // ── Path form flow ───────────────────────────────────────────────
        void ShowPathForm(string mode, string? name, string? path, string? username)
        {
            if (busyGuard) return;
            pathMode = mode;
            AuthTabSetError(pathFormError, null);
            pathEditHelper.Visibility = mode == "edit" ? Visibility.Visible : Visibility.Collapsed;
            pathNameBox.Text = name ?? string.Empty;
            pathNameBox.IsEnabled = mode != "edit"; // upstream: name/path fixed on edit
            pathPathBox.Text = path ?? string.Empty;
            pathPathBox.IsEnabled = mode != "edit";
            pathUserBox.Text = username ?? string.Empty;
            pathPasswordBox.Password = string.Empty;
            pathFormHost.Visibility = Visibility.Visible;
        }

        void HidePathForm()
        {
            pathFormHost.Visibility = Visibility.Collapsed;
        }

        pathAddButton.Click += (s, e) => ShowPathForm("create", null, null, null);
        pathCancelButton.Click += (s, e) => HidePathForm();
        pathConfirmButton.Click += (s, e) => _ = SavePathAsync();

        async Task SavePathAsync()
        {
            if (busyGuard) return;
            AuthTabSetError(pathFormError, null);

            var name = pathNameBox.Text.Trim();
            var path = pathPathBox.Text.Trim();
            var username = pathUserBox.Text.Trim();
            var password = pathPasswordBox.Password;

            if (string.IsNullOrWhiteSpace(name))
            {
                AuthTabSetError(pathFormError, L10n.T("hostAuthNameRequired", "Name is required."));
                return;
            }
            if (string.IsNullOrWhiteSpace(path))
            {
                AuthTabSetError(pathFormError, L10n.T("hostAuthPathRequired", "Path is required."));
                return;
            }
            if (string.IsNullOrWhiteSpace(username))
            {
                AuthTabSetError(pathFormError,
                    L10n.T("hostAuthUsernameRequired", "Username is required."));
                return;
            }
            if (string.IsNullOrEmpty(password))
            {
                AuthTabSetError(pathFormError,
                    L10n.T("hostAuthPasswordRequired", "Password is required."));
                return;
            }
            if (!AuthTabPasswordValid(password))
            {
                AuthTabSetError(pathFormError, L10n.T("hostAuthPasswordInvalid",
                    "Password may only contain letters, digits and _-.@$!%*?& (max 72 characters)."));
                return;
            }

            busyGuard = true;
            pathConfirmButton.IsEnabled = false;
            bool success;
            try
            {
                success = await WindowsBridge.UpdateWebsitePathAuthAsync(
                    websiteId, pathMode, path, username, password, name);
            }
            finally
            {
                busyGuard = false;
                pathConfirmButton.IsEnabled = true;
            }

            if (success)
            {
                HidePathForm();
                ShowNotice(L10n.T("hostAuthSaved", "Basic authentication updated."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAuthSaveFailed", "Failed to update the basic authentication."));
            }
        }

        // ── Row write actions ────────────────────────────────────────────
        async Task DeleteGlobalAsync(string username)
        {
            if (busyGuard || root.XamlRoot == null) return;
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                L10n.T("commonDelete", "Delete"),
                string.Format(L10n.T(
                    "hostAuthDeleteConfirm", "Delete basic authentication user \"{0}\"? This cannot be undone."),
                    username),
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);
            if (!confirmed) return;

            busyGuard = true;
            bool success;
            try
            {
                success = await WindowsBridge.UpdateWebsiteAuthAsync(
                    websiteId, "delete", "root", username, null, null);
            }
            finally
            {
                busyGuard = false;
            }

            if (success)
            {
                ShowNotice(L10n.T("hostAuthSaved", "Basic authentication updated."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAuthDeleteFailed", "Failed to delete the basic authentication user."));
            }
        }

        async Task DeletePathAsync(string name)
        {
            if (busyGuard || root.XamlRoot == null) return;
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                L10n.T("commonDelete", "Delete"),
                string.Format(L10n.T(
                    "hostAuthPathDeleteConfirm", "Delete path authentication rule \"{0}\"? This cannot be undone."),
                    name),
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);
            if (!confirmed) return;

            busyGuard = true;
            bool success;
            try
            {
                success = await WindowsBridge.UpdateWebsitePathAuthAsync(
                    websiteId, "delete", null, null, null, name);
            }
            finally
            {
                busyGuard = false;
            }

            if (success)
            {
                ShowNotice(L10n.T("hostAuthSaved", "Basic authentication updated."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAuthDeleteFailed", "Failed to delete the basic authentication user."));
            }
        }

        // Master switch: confirm, write enable/disable (scope root), then
        // refresh; failure rolls the switch back (upstream writes directly,
        // the client adds the confirmation for parity with other toggles).
        globalEnableSwitch.Toggled += (s, e) =>
        {
            if (globalSuppressToggle) return;
            _ = ToggleGlobalEnableAsync(globalEnableSwitch.IsOn);
        };

        async Task ToggleGlobalEnableAsync(bool enable)
        {
            if (busyGuard || root.XamlRoot == null) return;
            var confirmed = await ConfirmDialog.ShowAsync(
                root.XamlRoot,
                enable
                    ? L10n.T("commonEnable", "Enable")
                    : L10n.T("hostGatewayDisable", "Disable"),
                string.Format(
                    enable
                        ? L10n.T("hostAuthEnableConfirm", "Enable basic authentication for \"{0}\"?")
                        : L10n.T("hostAuthDisableConfirm", "Disable basic authentication for \"{0}\"?"),
                    websiteName),
                enable ? L10n.T("commonEnable", "Enable") : L10n.T("hostGatewayDisable", "Disable"),
                L10n.T("commonCancel", "Cancel"));
            if (!confirmed)
            {
                globalSuppressToggle = true;
                globalEnableSwitch.IsOn = !enable;
                globalSuppressToggle = false;
                return;
            }

            busyGuard = true;
            bool success;
            try
            {
                success = await WindowsBridge.UpdateWebsiteAuthAsync(
                    websiteId, enable ? "enable" : "disable", "root", null, null, null);
            }
            finally
            {
                busyGuard = false;
            }

            if (success)
            {
                ShowNotice(L10n.T("hostAuthSaved", "Basic authentication updated."));
                await LoadAsync(showLoading: false);
            }
            else
            {
                errorToast.Show(L10n.T("hostAuthEnableFailed",
                    "Failed to update the basic authentication switch."));
                globalSuppressToggle = true;
                globalEnableSwitch.IsOn = !enable;
                globalSuppressToggle = false;
            }
        }

        globalRetryButton.Click += (s, e) => _ = LoadAsync(showLoading: false);
        pathRetryButton.Click += (s, e) => _ = LoadAsync(showLoading: false);

        root.Loaded += (s, e) => _ = LoadAsync(showLoading: true);
        return root;

        void ShowNotice(string message)
        {
            noticeBar.Title = message;
            noticeBar.IsOpen = true;
        }
    }

    // ── Self-contained UI helpers (AuthTab prefix) ───────────────────────

    private static FrameworkElement WrapInScroll(FrameworkElement content)
    {
        return new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Padding = new Thickness(0, 0, 8, 8),
            Content = content,
        };
    }

    /// <summary>Card with a title line, an optional scope tag and a trailing
    /// header action; visual parity with SecurityGatewayPage cards.</summary>
    private static FrameworkElement AuthTabCard(
        string title, string tag, out StackPanel panel, FrameworkElement headerAction)
    {
        var card = new Border
        {
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(16, 12, 16, 12),
            BorderBrush = AuthTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = AuthTabSubtleFill(),
        };

        panel = new StackPanel { Orientation = Orientation.Vertical, Spacing = 10 };

        var titleBlock = new TextBlock
        {
            Text = title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
        };
        var tagPill = new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            VerticalAlignment = VerticalAlignment.Center,
            Background = AuthTabSubtleFill(),
            BorderBrush = AuthTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Child = new TextBlock { Text = tag, FontSize = 12 },
        };

        var header = new Grid { ColumnSpacing = 8 };
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(titleBlock, 0);
        Grid.SetColumn(tagPill, 1);
        Grid.SetColumn(headerAction, 3);
        header.Children.Add(titleBlock);
        header.Children.Add(tagPill);
        header.Children.Add(headerAction);
        panel.Children.Add(header);

        card.Child = panel;
        return card;
    }

    /// <summary>Switch row: caption on the leading edge, switch trailing.</summary>
    private static FrameworkElement AuthTabSwitchRow(string label, ToggleSwitch toggle)
    {
        var row = new Grid { ColumnSpacing = 8 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var labelBlock = new TextBlock
        {
            Text = label,
            FontSize = 13,
            VerticalAlignment = VerticalAlignment.Center,
            TextWrapping = TextWrapping.Wrap,
        };
        Grid.SetColumn(labelBlock, 0);
        toggle.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(toggle, 1);
        row.Children.Add(labelBlock);
        row.Children.Add(toggle);
        return row;
    }

    /// <summary>One list entry: primary text, optional secondary text and
    /// trailing Edit / Delete actions (the row's write operations).</summary>
    private static FrameworkElement AuthTabListRow(
        string primary,
        string secondary,
        string? secondaryLabel,
        Action editAction,
        Action deleteAction)
    {
        var row = new Grid { ColumnSpacing = 6, RowSpacing = 2 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        row.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        row.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var primaryBlock = new TextBlock
        {
            Text = primary,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetRow(primaryBlock, 0);
        Grid.SetColumn(primaryBlock, 0);
        row.Children.Add(primaryBlock);

        var editButton = AuthTabSmallButton(L10n.T("commonEdit", "Edit"), "\uE70F");
        editButton.Click += (s, e) => editAction();
        Grid.SetRow(editButton, 0);
        Grid.SetColumn(editButton, 1);
        row.Children.Add(editButton);

        var deleteButton = AuthTabSmallButton(L10n.T("commonDelete", "Delete"), "\uE74D");
        deleteButton.Click += (s, e) => deleteAction();
        Grid.SetRow(deleteButton, 0);
        Grid.SetColumn(deleteButton, 2);
        row.Children.Add(deleteButton);

        if (!string.IsNullOrEmpty(secondary))
        {
            var secondaryBlock = new TextBlock
            {
                Text = string.IsNullOrEmpty(secondaryLabel)
                    ? secondary
                    : $"{secondaryLabel}: {secondary}",
                FontSize = 12,
                Foreground = AuthTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
            };
            Grid.SetRow(secondaryBlock, 1);
            Grid.SetColumn(secondaryBlock, 0);
            Grid.SetColumnSpan(secondaryBlock, 3);
            row.Children.Add(secondaryBlock);
        }

        var host = new Border
        {
            Padding = new Thickness(10, 6, 10, 6),
            CornerRadius = new CornerRadius(6),
            BorderBrush = AuthTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = AuthTabSubtleFill(),
            Child = row,
        };
        return host;
    }

    private static FrameworkElement AuthTabEmptyText(string text)
    {
        return new TextBlock
        {
            Text = text,
            FontSize = 12,
            Foreground = AuthTabThemeBrush("TextFillColorSecondaryBrush", Colors.Gray),
            TextWrapping = TextWrapping.Wrap,
        };
    }

    /// <summary>Labeled form field row (label 180px, control stretches).</summary>
    private static FrameworkElement AuthTabFieldRow(string label, FrameworkElement control)
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

    /// <summary>Password entry with the trailing random generator button.</summary>
    private static FrameworkElement AuthTabPasswordRow(PasswordBox box, Action onRandom)
    {
        var randomButton = AuthTabSmallButton(L10n.T("hostAuthRandom", "Random"), "\uE8D7");
        randomButton.Click += (s, e) => onRandom();

        var row = new Grid { ColumnSpacing = 8 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        box.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(box, 0);
        Grid.SetColumn(randomButton, 1);
        row.Children.Add(box);
        row.Children.Add(randomButton);
        return row;
    }

    private static FrameworkElement AuthTabButtonRow(Button confirm, Button cancel)
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

    private static Button AuthTabSmallButton(string label, string? glyph)
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

    private static Border AuthTabFormHost()
    {
        return new Border
        {
            Visibility = Visibility.Collapsed,
            Padding = new Thickness(12),
            CornerRadius = new CornerRadius(6),
            BorderBrush = AuthTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray),
            BorderThickness = new Thickness(1),
            Background = AuthTabSubtleFill(),
        };
    }

    /// <summary>
    /// Load-error surface: an error InfoBar paired with a trailing Retry
    /// button (typed as Button); visibility toggled via AuthTabShowError.
    /// </summary>
    private static FrameworkElement AuthTabErrorRow(out InfoBar bar, out Button retryButton)
    {
        var row = new Grid { ColumnSpacing = 8, Margin = new Thickness(8, 8, 8, 0) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        bar = new InfoBar
        {
            Title = L10n.T("hostAuthLoadFailed", "Failed to load the basic authentication configuration."),
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
    private static void AuthTabShowError(InfoBar bar, Button retryButton, bool show)
    {
        bar.IsOpen = show;
        retryButton.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
    }

    private static TextBlock AuthTabErrorText()
    {
        return new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = AuthTabThemeBrush("SystemFillColorCriticalBrush", Colors.Red),
            Visibility = Visibility.Collapsed,
        };
    }

    private static void AuthTabSetError(TextBlock target, string? message)
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

    /// <summary>16-character random password over the upstream
    /// authBasicPassword charset (a-zA-Z0-9_-\.@$!%*?&).</summary>
    private static string AuthTabRandomPassword()
    {
        var chars = new char[GeneratedPasswordLength];
        for (var i = 0; i < chars.Length; i++)
        {
            chars[i] = PasswordChars[Random.Shared.Next(PasswordChars.Length)];
        }
        return new string(chars);
    }

    /// <summary>Upstream authBasicPassword rule: ^[a-zA-Z0-9_\-\.@$!%*?&]{1,72}$.</summary>
    private static bool AuthTabPasswordValid(string password)
    {
        if (password.Length is < 1 or > 72) return false;
        foreach (var ch in password)
        {
            var ok = (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9')
                || ch == '_' || ch == '-' || ch == '.' || ch == '@' || ch == '$'
                || ch == '!' || ch == '%' || ch == '*' || ch == '?' || ch == '&';
            if (!ok) return false;
        }
        return true;
    }

    private static string? AuthTabString(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.String)
        {
            return prop.GetString();
        }
        return null;
    }

    private static bool AuthTabBool(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop))
        {
            if (prop.ValueKind == JsonValueKind.True) return true;
            if (prop.ValueKind == JsonValueKind.False) return false;
        }
        return false;
    }

    private static Brush AuthTabThemeBrush(string key, Color fallback)
    {
        if (Application.Current.Resources.TryGetValue(key, out var value) && value is Brush brush)
        {
            return brush;
        }
        return new SolidColorBrush(fallback);
    }

    private static Brush AuthTabSubtleFill()
    {
        var stroke = AuthTabThemeBrush("CardStrokeColorDefaultBrush", Colors.Gray);
        var color = stroke is SolidColorBrush solid ? solid.Color : Colors.Gray;
        return new SolidColorBrush(ColorHelper.FromArgb(10, color.R, color.G, color.B));
    }
}
