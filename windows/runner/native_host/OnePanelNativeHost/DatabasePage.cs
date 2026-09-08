using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Databases module page. Lists every database surfaced by the
/// client's Dart business core across all scopes
/// (mysql / postgresql / mongodb / redis / remote) and mirrors the upstream
/// 1Panel web frontend semantics:
/// - list shows name, type, version, status (when present) and description;
/// - create form takes name + type, and expands connection info
///   (address/port/username/password) for the "remote database" flavor,
///   matching the upstream remote-DB dialog;
/// - row actions edit the description, change the password and delete;
///   description/password updates re-send the row's original dictionary
///   fields so the Dart side can rebuild the entry the same way the web
///   frontend does.
/// All data flows through WindowsBridge (method channel to the Dart core);
/// no direct HTTP from the native layer.
/// </summary>
public sealed class DatabasePage : ModulePageBase
{
    private readonly List<DatabaseEntry> _databases = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads, the create dialog and row operations.</summary>
    private bool _isBusy;

    public DatabasePage()
    {
        PageTitle = "Databases";

        // Empty-state primary action: opens the create dialog so users can
        // add the first database. Registered once here; the button only shows
        // inside the base Empty panel, so the Content state needs no cleanup.
        SetEmptyPrimaryAction(L10n.T("hostDatabaseCreate", "Create database"), (s, e) => _ = ShowCreateDatabaseDialogAsync());
    }

    protected override async void OnPageShown()
    {
        await LoadDatabasesAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadDatabasesAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadDatabasesAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadDatabasesCoreAsync(showLoadingState);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Unguarded load body; also used as the silent refresh after successful
    /// operations. With <paramref name="showLoadingState"/> the page swaps to
    /// the loading spinner; otherwise the current content stays visible and
    /// failures surface via the error toast.
    /// </summary>
    private async Task LoadDatabasesCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetDatabasesAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostDatabaseRefreshFailed", "Failed to refresh databases."));
            }
            return;
        }

        var databases = ParseDatabases(result.Value);
        if (databases.Count == 0)
        {
            _databases.Clear();
            SetState(PageState.Empty);
            return;
        }

        _databases.Clear();
        _databases.AddRange(databases);
        BuildContent(_databases);
        SetState(PageState.Content);
    }

    private static List<DatabaseEntry> ParseDatabases(JsonElement json)
    {
        var databases = new List<DatabaseEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                databases.Add(new DatabaseEntry
                {
                    Id = TryGetInt64(item, "id"),
                    Name = TryGetString(item, "name") ?? L10n.T("systemSettingsUnknown", "Unknown"),
                    Type = TryGetString(item, "type") ?? "",
                    Version = TryGetString(item, "version") ?? "",
                    Status = TryGetString(item, "status") ?? "",
                    Username = TryGetString(item, "username") ?? "",
                    Description = TryGetString(item, "description") ?? "",
                });
            }
        }

        return databases;
    }

    private void BuildContent(List<DatabaseEntry> databases)
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
            SelectionMode = ListViewSelectionMode.None,
            IsItemClickEnabled = false,
            Margin = new Thickness(8, 0, 8, 0),
        };

        foreach (var database in databases)
        {
            list.Items.Add(CreateDatabaseItem(database));
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

        var createButton = new AppBarButton
        {
            Label = L10n.T("hostDatabaseCreate", "Create database"),
            Icon = new FontIcon { Glyph = "\uE710" },
        };
        createButton.Click += (s, e) => _ = ShowCreateDatabaseDialogAsync();
        bar.PrimaryCommands.Add(createButton);

        var refreshButton = new AppBarButton
        {
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadDatabasesAsync(showLoadingState: true);
        bar.SecondaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateDatabaseItem(DatabaseEntry database)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = database,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Info column: name + type badge + optional status badge, then the
        // secondary lines (version, remote username, description).
        var info = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var nameRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
        };
        nameRow.Children.Add(new TextBlock
        {
            Text = database.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        nameRow.Children.Add(CreateTypeBadge(database.Type));
        if (!string.IsNullOrWhiteSpace(database.Status))
        {
            nameRow.Children.Add(CreateStatusBadge(database.Status));
        }
        info.Children.Add(nameRow);

        if (!string.IsNullOrWhiteSpace(database.Version))
        {
            info.Children.Add(CreateSecondaryText(database.Version));
        }

        // Connection username only matters for remote databases.
        if (database.IsRemote && !string.IsNullOrWhiteSpace(database.Username))
        {
            info.Children.Add(CreateSecondaryText("Username: " + database.Username));
        }

        if (!string.IsNullOrWhiteSpace(database.Description))
        {
            info.Children.Add(CreateSecondaryText(database.Description));
        }

        Grid.SetColumn(info, 0);
        grid.Children.Add(info);

        // Per-row "more" actions (upstream: row dropdown menu).
        var moreButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE712", FontSize = 14 },
            Background = null,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(6, 2, 6, 2),
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(moreButton, L10n.T("hostDatabaseActions", "Database actions"));
        moreButton.Flyout = BuildRowFlyout(database);
        Grid.SetColumn(moreButton, 1);
        grid.Children.Add(moreButton);

        return grid;
    }

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

    private MenuFlyout BuildRowFlyout(DatabaseEntry database)
    {
        var flyout = new MenuFlyout();

        var descriptionItem = new MenuFlyoutItem
        {
            Text = L10n.T("commonDescription", "Description"),
            Icon = new FontIcon { Glyph = "\uE70F" },
        };
        descriptionItem.Click += (s, e) => _ = EditDescriptionAsync(database);
        flyout.Items.Add(descriptionItem);

        var passwordItem = new MenuFlyoutItem
        {
            Text = L10n.T("databaseChangePasswordAction", "Change password"),
            Icon = new FontIcon { Glyph = "\uE72E" },
        };
        passwordItem.Click += (s, e) => _ = ChangePasswordAsync(database);
        flyout.Items.Add(passwordItem);

        var deleteItem = new MenuFlyoutItem
        {
            Text = L10n.T("commonDelete", "Delete"),
            Icon = new FontIcon { Glyph = "\uE74D" },
        };
        deleteItem.Click += (s, e) => _ = DeleteDatabaseAsync(database);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    /// <summary>Type pill badge; each database type gets its own accent color
    /// with a theme-resource brush and a hardcoded fallback.</summary>
    private static FrameworkElement CreateTypeBadge(string type)
    {
        var (brushKey, fallbackColor) = GetDbTypeAccent(type);
        var accentBrush = TryGetThemeBrush(brushKey, fallbackColor);
        var accentColor = GetBrushColor(accentBrush, fallbackColor);

        var badgeContent = new TextBlock
        {
            Text = string.IsNullOrEmpty(type) ? L10n.T("systemSettingsUnknown", "Unknown") : type,
            FontSize = 12,
            Foreground = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // Translucent tint keeps the pill readable over Mica/LayerFill.
        return new Border
        {
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10, 3, 10, 3),
            Background = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(26, accentColor.R, accentColor.G, accentColor.B)),
            VerticalAlignment = VerticalAlignment.Center,
            Child = badgeContent,
        };
    }

    /// <summary>Status pill badge with a colored dot; hidden by the caller
    /// when the row carries no status value.</summary>
    private static FrameworkElement CreateStatusBadge(string status)
    {
        var lower = status.ToLowerInvariant();
        bool positive = lower.Contains("run") || (lower.Contains("health") && !lower.Contains("unhealth"));
        bool negative = lower.Contains("stop") || lower.Contains("unhealth") ||
                        lower.Contains("error") || lower.Contains("fail");

        var accentBrush = positive
            ? TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green)
            : negative
                ? TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange)
                : TryGetThemeBrush("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray);
        var accentColor = GetBrushColor(accentBrush, Microsoft.UI.Colors.Gray);

        var badgeContent = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        badgeContent.Children.Add(new Ellipse
        {
            Width = 8,
            Height = 8,
            Fill = accentBrush,
            VerticalAlignment = VerticalAlignment.Center,
        });
        badgeContent.Children.Add(new TextBlock
        {
            Text = status,
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
            Child = badgeContent,
        };
    }

    /// <summary>Accent brush key + fallback color per database type.</summary>
    private static (string BrushKey, Color FallbackColor) GetDbTypeAccent(string type)
    {
        return type?.ToLowerInvariant() switch
        {
            "mysql" => ("SystemFillColorSuccessBrush", Microsoft.UI.Colors.SeaGreen),
            "postgresql" => ("AccentFillColorDefaultBrush", Microsoft.UI.Colors.RoyalBlue),
            "mongodb" => ("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
            "redis" => ("SystemFillColorCriticalBrush", Microsoft.UI.Colors.IndianRed),
            _ => ("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray), // remote and unknown types.
        };
    }

    /// <summary>
    /// Edits the row description in a single-textbox dialog (prefilled with
    /// the current value; the field is optional so no validation). On success
    /// the list is silently refreshed; _isBusy is held across the whole flow.
    /// </summary>
    private async Task EditDescriptionAsync(DatabaseEntry database)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var nameText = new TextBlock
            {
                Text = database.Name,
                FontSize = 14,
                FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                Margin = new Thickness(0, 0, 0, 12),
                TextWrapping = TextWrapping.Wrap,
            };
            var descriptionBox = new TextBox
            {
                Header = L10n.T("commonDescription", "Description"),
                PlaceholderText = L10n.T("hostCommonOptional", "Optional"),
                Text = database.Description,
            };

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(nameText);
            form.Children.Add(descriptionBox);

            var dialog = new ContentDialog
            {
                Title = L10n.T("snapshotEditDesc", "Edit description"),
                Content = form,
                PrimaryButtonText = L10n.T("commonSave", "Save"),
                CloseButtonText = L10n.T("commonCancel", "Cancel"),
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            var result = await dialog.ShowAsync();
            if (result != ContentDialogResult.Primary) return;

            var success = await WindowsBridge.UpdateDatabaseDescriptionAsync(
                database.Type, database.Name, database.Name,
                database.Type, database.Source, database.Id,
                descriptionBox.Text.Trim());
            if (success)
            {
                // Silent refresh keeps the list visible (no success toast).
                await LoadDatabasesCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to update the description of \"{database.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Changes the row password. The new password is required (inline
    /// validation keeps the dialog open until non-empty); success silently
    /// refreshes the list. _isBusy is held across the whole flow.
    /// </summary>
    private async Task ChangePasswordAsync(DatabaseEntry database)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var nameText = new TextBlock
            {
                Text = database.Name,
                FontSize = 14,
                FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                Margin = new Thickness(0, 0, 0, 12),
                TextWrapping = TextWrapping.Wrap,
            };
            var passwordBox = new TextBox { Header = L10n.T("securitySettingsNewPassword", "New password") };

            var errorText = new TextBlock
            {
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                Visibility = Visibility.Collapsed,
            };

            // Any edit clears the pending inline validation error.
            passwordBox.TextChanged += (s, e) => SetFormError(errorText, null);

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(nameText);
            form.Children.Add(passwordBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = L10n.T("databaseChangePasswordAction", "Change password"),
                Content = form,
                PrimaryButtonText = L10n.T("commonSave", "Save"),
                CloseButtonText = L10n.T("commonCancel", "Cancel"),
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            // Inline validation: on an empty password cancel the close so the
            // dialog stays open and the error shows next to the field.
            dialog.Closing += (s, args) =>
            {
                if (args.Result != ContentDialogResult.Primary) return;

                if (string.IsNullOrWhiteSpace(passwordBox.Text))
                {
                    args.Cancel = true;
                    SetFormError(errorText, L10n.T("hostDatabasePasswordRequired", "Password is required."));
                }
            };

            var result = await dialog.ShowAsync();
            if (result != ContentDialogResult.Primary) return;

            var success = await WindowsBridge.ChangeDatabasePasswordAsync(
                database.Type, database.Name, database.Name,
                database.Type, database.Source, database.Id,
                passwordBox.Text.Trim());
            if (success)
            {
                await LoadDatabasesCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to change the password of \"{database.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Destructive row action with a confirmation naming the database.</summary>
    private async Task DeleteDatabaseAsync(DatabaseEntry database)
    {
        if (_isBusy) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                L10n.T("hostDatabaseDeleteTitle", "Delete Database"),
                $"Are you sure you want to delete database \"{database.Name}\" ({database.Type})?\nThis action cannot be undone.",
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.DeleteDatabaseAsync(database.Id);
            if (success)
            {
                await LoadDatabasesCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{database.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Create-database form dialog with inline validation, mirroring the
    /// upstream create form: name + type for the built-in flavors, and an
    /// extra connection-info section (address/port/username/password) that
    /// expands when the remote type is selected. _isBusy is held across the
    /// whole dialog lifetime so the CommandBar button cannot open a second
    /// dialog and row operations stay blocked. The dialog stays open while
    /// the bridge call runs and only closes on success; on failure the toast
    /// shows and the form stays editable.
    /// </summary>
    private async Task ShowCreateDatabaseDialogAsync()
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var nameBox = new TextBox { Header = L10n.T("commonName", "Name"), PlaceholderText = L10n.T("hostDatabaseNameHint", "e.g. app_db") };

            var typeCombo = new ComboBox { Header = L10n.T("commonType", "Type"), SelectedIndex = 0, MinWidth = 200 };
            foreach (var type in DatabaseEntry.KnownTypes)
            {
                typeCombo.Items.Add(type);
            }

            var descriptionBox = new TextBox { Header = L10n.T("commonDescription", "Description"), PlaceholderText = L10n.T("hostCommonOptional", "Optional") };

            // Connection-info section, only visible for the remote type.
            var addressBox = new TextBox { Header = L10n.T("databaseAddressLabel", "Address"), PlaceholderText = L10n.T("hostDatabaseAddressHint", "e.g. 192.168.1.10") };
            var portBox = new TextBox { Header = L10n.T("databasePortLabel", "Port"), PlaceholderText = L10n.T("hostDatabasePortHint", "e.g. 3306") };
            var usernameBox = new TextBox { Header = L10n.T("databaseUsernameLabel", "Username") };
            var passwordBox = new TextBox { Header = L10n.T("databasePasswordLabel", "Password") };
            var connectionPanel = new StackPanel
            {
                Orientation = Orientation.Vertical,
                Spacing = 12,
                Visibility = Visibility.Collapsed,
            };
            connectionPanel.Children.Add(addressBox);
            connectionPanel.Children.Add(portBox);
            connectionPanel.Children.Add(usernameBox);
            connectionPanel.Children.Add(passwordBox);

            var errorText = new TextBlock
            {
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                Visibility = Visibility.Collapsed,
            };

            // Any edit clears the pending inline validation error.
            void ClearError() => SetFormError(errorText, null);
            nameBox.TextChanged += (s, e) => ClearError();
            descriptionBox.TextChanged += (s, e) => ClearError();
            addressBox.TextChanged += (s, e) => ClearError();
            portBox.TextChanged += (s, e) => ClearError();
            usernameBox.TextChanged += (s, e) => ClearError();
            passwordBox.TextChanged += (s, e) => ClearError();

            // Expanding/collapsing the remote section also drops stale errors.
            typeCombo.SelectionChanged += (s, e) =>
            {
                ClearError();
                connectionPanel.Visibility = IsRemoteType(typeCombo.SelectedItem as string)
                    ? Visibility.Visible
                    : Visibility.Collapsed;
            };

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(nameBox);
            form.Children.Add(typeCombo);
            form.Children.Add(connectionPanel);
            form.Children.Add(descriptionBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = L10n.T("hostDatabaseCreate", "Create database"),
                Content = form,
                PrimaryButtonText = L10n.T("commonCreate", "Create"),
                CloseButtonText = L10n.T("commonCancel", "Cancel"),
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            bool submitting = false;
            bool createSucceeded = false;

            async Task SubmitCreateAsync()
            {
                // Validation already guaranteed the remote section is complete
                // and carries a numeric 1-65535 port when visible.
                var selectedType = (typeCombo.SelectedItem as string) ?? "mysql";
                string? address = null;
                long? port = null;
                string? username = null;
                string? password = null;
                if (IsRemoteType(selectedType))
                {
                    address = addressBox.Text.Trim();
                    port = long.Parse(portBox.Text.Trim(), CultureInfo.InvariantCulture);
                    username = usernameBox.Text.Trim();
                    password = passwordBox.Text.Trim();
                }

                var success = await WindowsBridge.CreateDatabaseAsync(
                    nameBox.Text.Trim(),
                    selectedType,
                    string.IsNullOrWhiteSpace(descriptionBox.Text) ? null : descriptionBox.Text.Trim(),
                    address, port, username, password);
                if (success)
                {
                    createSucceeded = true;
                    dialog.Hide(); // Closing lets this programmatic close pass.
                }
                else
                {
                    submitting = false;
                    _errorToast.Show(L10n.T("hostDatabaseCreateFailed", "Failed to create database."));
                    SetFormError(errorText, L10n.T("hostDatabaseCreateRetryHint", "Create failed. Adjust the inputs and try again."));
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

                // Inline validation: on invalid input cancel the close so the
                // dialog stays open and the error shows next to the fields.
                var error = ValidateCreateInput(
                    nameBox.Text,
                    IsRemoteType(typeCombo.SelectedItem as string),
                    addressBox.Text, portBox.Text, usernameBox.Text, passwordBox.Text);
                if (error != null)
                {
                    args.Cancel = true;
                    SetFormError(errorText, error);
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
            await LoadDatabasesAsync(showLoadingState: false);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Returns the first create-database validation error, or null when the input is valid.</summary>
    private static string? ValidateCreateInput(
        string name, bool isRemote, string address, string port, string username, string password)
    {
        if (string.IsNullOrWhiteSpace(name)) return L10n.T("websitesSslAccountsValidationNameRequired", "Name is required.");
        if (!isRemote) return null;

        // Remote databases additionally need full connection info,
        // matching the upstream "remote database" form.
        if (string.IsNullOrWhiteSpace(address)) return L10n.T("hostDatabaseRemoteAddressRequired", "Address is required for remote databases.");

        var trimmedPort = port.Trim();
        if (trimmedPort.Length == 0) return L10n.T("hostDatabaseRemotePortRequired", "Port is required for remote databases.");
        foreach (var ch in trimmedPort)
        {
            if (!char.IsDigit(ch)) return L10n.T("hostCommonPortNumeric", "Port must be a number.");
        }
        if (!long.TryParse(trimmedPort, NumberStyles.None, CultureInfo.InvariantCulture, out var value) ||
            value < 1 || value > 65535)
        {
            return L10n.T("websitesDomainValidationPort", "Port must be between 1 and 65535.");
        }

        if (string.IsNullOrWhiteSpace(username)) return L10n.T("hostDatabaseRemoteUsernameRequired", "Username is required for remote databases.");
        if (string.IsNullOrWhiteSpace(password)) return L10n.T("hostDatabaseRemotePasswordRequired", "Password is required for remote databases.");
        return null;
    }

    private static bool IsRemoteType(string? type)
        => string.Equals(type, "remote", StringComparison.OrdinalIgnoreCase);

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

    /// <summary>Row model straight from the bridge payload; update/delete
    /// calls re-send these original dictionary fields.</summary>
    private sealed class DatabaseEntry
    {
        /// <summary>Known database type scopes, in upstream tab order.</summary>
        public static readonly string[] KnownTypes = { "mysql", "postgresql", "mongodb", "redis", "remote" };

        public long Id { get; set; }
        public string Name { get; set; } = "";
        public string Type { get; set; } = "";
        public string Version { get; set; } = "";
        public string Status { get; set; } = "";
        public string Username { get; set; } = "";
        public string Description { get; set; } = "";

        public bool IsRemote => IsRemoteType(Type);

        /// <summary>source=remote only for remote rows; every built-in scope is local.</summary>
        public string Source => IsRemote ? "remote" : "local";
    }
}
