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
/// Native Compose orchestration module page. Mirrors the upstream 1Panel web
/// frontend list semantics (views/container/compose/index.vue):
/// - list shows the compose name with a status pill (running green / exited
///   red / anything else neutral), the version, the compose file path in a
///   monospace face and the create time;
/// - row actions map to the bridge ComposeOperate actions: Start/Stop toggle
///   availability by status (only one of the pair is enabled at a time),
///   Restart and Up run directly (Up re-creates the project, non-destructive),
///   Down takes the containers down keeping the files behind a non-destructive
///   confirmation, and Delete removes the compose plus its containers behind a
///   destructive confirmation naming the compose.
/// Create opens the new-compose dialog (name + "From path"/"From content"/
/// "From template" source + editor) and Edit opens
/// a full-replacement config editor: the list payload carries no compose
/// content, so the editor starts empty and the pasted content replaces the
/// whole file behind an explicit confirmation. All data flows through
/// WindowsBridge (method channel to the Dart core); no direct HTTP from the
/// native layer. The create action doubles as the Empty-state primary button
/// (shared handler with the CommandBar command) so the first compose can be
/// created with no list content.
/// </summary>
public sealed class OrchestrationPage : ModulePageBase
{
    private readonly List<ComposeEntry> _composes = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads and row operations.</summary>
    private bool _isBusy;

    /// <summary>
    /// Guards the shared create entry while it waits for an in-flight flow
    /// to settle; repeats during that window are swallowed.
    /// </summary>
    private bool _createDialogPending;

    public OrchestrationPage()
    {
        PageTitle = "Compose";

        // Empty-state primary action: opens the create dialog so users can
        // add the first compose. Registered once here; the button only shows
        // inside the base Empty panel, so the Content state needs no cleanup.
        SetEmptyPrimaryAction("Create compose", OnCreateComposeClicked);
    }

    protected override async void OnPageShown()
    {
        await LoadComposesAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadComposesAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadComposesAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadComposesCoreAsync(showLoadingState);
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
    private async Task LoadComposesCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetComposesAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show("Failed to refresh composes.");
            }
            return;
        }

        var composes = ParseComposes(result.Value);
        _composes.Clear();
        if (composes.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        _composes.AddRange(composes);
        BuildContent(_composes);
        SetState(PageState.Content);
    }

    private static List<ComposeEntry> ParseComposes(JsonElement json)
    {
        var composes = new List<ComposeEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                composes.Add(new ComposeEntry
                {
                    Id = TryGetIdString(item, "id") ?? "",
                    Name = TryGetString(item, "name") ?? "Unknown",
                    Path = TryGetString(item, "path") ?? "",
                    Version = TryGetString(item, "version") ?? "",
                    Status = TryGetString(item, "status") ?? "",
                    CreateTime = TryGetString(item, "createTime") ?? "",
                });
            }
        }

        return composes;
    }

    private void BuildContent(List<ComposeEntry> composes)
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

        foreach (var compose in composes)
        {
            list.Items.Add(CreateComposeItem(compose));
        }

        scrollViewer.Content = list;
        root.Children.Add(scrollViewer);

        // Failure toast floats above the list, bottom-aligned (kept in the
        // visual tree so Show() actually renders).
        _errorToast.VerticalAlignment = VerticalAlignment.Bottom;
        Grid.SetRow(_errorToast, 1);
        root.Children.Add(_errorToast);

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

        // Primary create command (upstream toolbar "create" button), then
        // refresh. The create command shares its handler with the Empty-state
        // primary button so both entry points stay in sync.
        var createButton = new AppBarButton
        {
            Label = "Create compose",
            Icon = new FontIcon { Glyph = "\uE710" }, // Add.
        };
        createButton.Click += OnCreateComposeClicked;
        bar.PrimaryCommands.Add(createButton);

        var refreshButton = new AppBarButton
        {
            Label = "Refresh",
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadComposesAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateComposeItem(ComposeEntry compose)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = compose,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Info column: name + status pill, then version, the compose file path
        // in a monospace face and the create time.
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
            Text = compose.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        if (!string.IsNullOrWhiteSpace(compose.Status))
        {
            nameRow.Children.Add(CreateStatusBadge(compose.Status));
        }
        info.Children.Add(nameRow);

        if (!string.IsNullOrWhiteSpace(compose.Version))
        {
            info.Children.Add(new TextBlock
            {
                Text = compose.Version,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            });
        }

        // Compose file path in a monospace face; the full value stays on the
        // tooltip so truncation never hides the real location.
        if (!string.IsNullOrWhiteSpace(compose.Path))
        {
            var pathText = new TextBlock
            {
                Text = compose.Path,
                FontFamily = new FontFamily("Consolas"),
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            };
            ToolTipService.SetToolTip(pathText, compose.Path);
            info.Children.Add(pathText);
        }

        if (!string.IsNullOrWhiteSpace(compose.CreateTime))
        {
            info.Children.Add(new TextBlock
            {
                Text = FormatDateString(compose.CreateTime),
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            });
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
        ToolTipService.SetToolTip(moreButton, "Compose actions");
        moreButton.Flyout = BuildRowFlyout(compose);
        Grid.SetColumn(moreButton, 1);
        grid.Children.Add(moreButton);

        return grid;
    }

    /// <summary>
    /// Row menu: Start/Stop availability follows the status (only one of the
    /// pair is enabled), Restart and Up run directly, Down confirms
    /// non-destructively, Delete confirms destructively.
    /// </summary>
    private MenuFlyout BuildRowFlyout(ComposeEntry compose)
    {
        var flyout = new MenuFlyout();
        var running = IsRunning(compose.Status);

        var startItem = new MenuFlyoutItem
        {
            Text = "Start",
            Icon = new FontIcon { Glyph = "\uE768" }, // Play.
            IsEnabled = !running,
        };
        startItem.Click += (s, e) => _ = OperateAsync(compose, "start");
        flyout.Items.Add(startItem);

        var stopItem = new MenuFlyoutItem
        {
            Text = "Stop",
            Icon = new FontIcon { Glyph = "\uE71A" }, // Stop square.
            IsEnabled = running,
        };
        stopItem.Click += (s, e) => _ = OperateAsync(compose, "stop");
        flyout.Items.Add(stopItem);

        var restartItem = new MenuFlyoutItem
        {
            Text = "Restart",
            Icon = new FontIcon { Glyph = "\uE777" }, // Sync.
        };
        restartItem.Click += (s, e) => _ = OperateAsync(compose, "restart");
        flyout.Items.Add(restartItem);

        flyout.Items.Add(new MenuFlyoutSeparator());

        // Up re-creates the project from the compose file; non-destructive,
        // matching the upstream "start/up" operation without confirmation.
        var upItem = new MenuFlyoutItem
        {
            Text = "Up",
            Icon = new FontIcon { Glyph = "\uE74A" }, // Up arrow.
        };
        upItem.Click += (s, e) => _ = OperateAsync(compose, "up");
        flyout.Items.Add(upItem);

        // Down removes the containers but keeps the compose files, so a
        // plain (non-destructive) confirmation is enough.
        var downItem = new MenuFlyoutItem
        {
            Text = "Down",
            Icon = new FontIcon { Glyph = "\uE74B" }, // Down arrow.
        };
        downItem.Click += (s, e) => _ = DownComposeAsync(compose);
        flyout.Items.Add(downItem);

        flyout.Items.Add(new MenuFlyoutSeparator());

        // Edit opens the config editor. The list payload has no compose
        // content, so the dialog works in full-replacement mode (see
        // ShowEditComposeDialogAsync for the contract boundary).
        var editItem = new MenuFlyoutItem
        {
            Text = "Edit",
            Icon = new FontIcon { Glyph = "\uE70F" }, // Edit pencil.
        };
        editItem.Click += (s, e) => _ = ShowEditComposeDialogAsync(compose);
        flyout.Items.Add(editItem);

        var deleteItem = new MenuFlyoutItem
        {
            Text = "Delete",
            Icon = new FontIcon { Glyph = "\uE74D" }, // Delete.
        };
        deleteItem.Click += (s, e) => _ = DeleteComposeAsync(compose);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    /// <summary>Status pill badge with a colored dot: running = success green,
    /// exited = critical red, anything else neutral, with theme-resource
    /// brushes and hardcoded fallbacks.</summary>
    private static FrameworkElement CreateStatusBadge(string status)
    {
        Brush accentBrush;
        if (IsRunning(status))
        {
            accentBrush = TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green);
        }
        else if (IsExited(status))
        {
            accentBrush = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red);
        }
        else
        {
            accentBrush = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray);
        }
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

    /// <summary>Running = fully up (matches the upstream running status text).</summary>
    private static bool IsRunning(string status)
        => string.Equals(status?.Trim(), "running", StringComparison.OrdinalIgnoreCase);

    /// <summary>Exited covers both the "Exit" and "exited" upstream spellings.</summary>
    private static bool IsExited(string status)
    {
        var normalized = status?.Trim().ToLowerInvariant();
        return normalized is "exit" or "exited";
    }

    /// <summary>
    /// Direct row operation (start/stop/restart/up, no confirmation). Success
    /// silently refreshes; failure shows the toast.
    /// </summary>
    private async Task OperateAsync(ComposeEntry compose, string action)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var success = await WindowsBridge.ComposeOperateAsync(compose.Id, compose.Name, action);
            if (success)
            {
                await LoadComposesCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to {GetActionVerb(action)} \"{compose.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Confirmed "down" (containers removed, files kept). The guard is
    /// held across confirmation + call so no other flow starts meanwhile.</summary>
    private async Task DownComposeAsync(ComposeEntry compose)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                "Down Compose",
                $"Take down compose \"{compose.Name}\"?\nIts containers will be removed; the compose files are kept.",
                "Down",
                "Cancel",
                isDestructive: false);

            if (!confirmed) return;

            var success = await WindowsBridge.ComposeOperateAsync(compose.Id, compose.Name, "down");
            if (success)
            {
                await LoadComposesCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to take down \"{compose.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Destructive row action with a confirmation naming the compose
    /// and stating that the compose plus its containers will be deleted.</summary>
    private async Task DeleteComposeAsync(ComposeEntry compose)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                "Delete Compose",
                $"Are you sure you want to delete compose \"{compose.Name}\"?\nThis will delete the compose and all of its containers. This action cannot be undone.",
                "Delete",
                "Cancel",
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.ComposeOperateAsync(compose.Id, compose.Name, "delete");
            if (success)
            {
                await LoadComposesCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{compose.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Past-tense-safe verb for operation failure toasts.</summary>
    private static string GetActionVerb(string action) => action switch
    {
        "up" => "bring up",
        "down" => "take down",
        _ => action.ToLowerInvariant(),
    };

    /// <summary>
    /// Shared "Create compose" click handler for the CommandBar button and
    /// the Empty-state primary action; opens the create dialog once any
    /// in-flight flow has settled.
    /// </summary>
    private async void OnCreateComposeClicked(object sender, RoutedEventArgs e)
    {
        if (_createDialogPending) return;
        _createDialogPending = true;
        try
        {
            // ModulePageBase co-wires the Empty primary button to a guarded
            // refresh whose handler runs before this one and holds _isBusy
            // for the whole load; wait for it to settle or the dialog's own
            // guard would silently drop the request. For the CommandBar
            // button the loop is a no-op in the common idle case.
            while (_isBusy)
            {
                await Task.Delay(50);
            }
            await ShowCreateComposeDialogAsync();
        }
        finally
        {
            _createDialogPending = false;
        }
    }

    /// <summary>
    /// New-compose form dialog mirroring the upstream create form (name +
    /// source selector + editor): "From path" takes an existing compose file
    /// path, "From content" takes the YAML inline, "From template" takes a
    /// numeric template id validated inline and resolved Dart-side.
    /// _isBusy is held across the whole dialog lifetime so no other flow can
    /// start meanwhile. Closing is intercepted for inline validation; the
    /// dialog stays open while the bridge call runs and only closes on
    /// success, after which the guard is released before the silent refresh
    /// (DatabasePage paradigm).
    /// </summary>
    private async Task ShowCreateComposeDialogAsync()
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var nameBox = new TextBox { Header = "Name", PlaceholderText = "e.g. my-app" };

            var sourceCombo = new ComboBox { Header = "Create from", SelectedIndex = 0, MinWidth = 200 };
            sourceCombo.Items.Add("From path");
            sourceCombo.Items.Add("From content");
            sourceCombo.Items.Add("From template");

            var pathBox = new TextBox
            {
                Header = "Compose file path",
                PlaceholderText = "e.g. /opt/1panel/docker/compose/my-app/docker-compose.yml",
            };

            var contentBox = new TextBox
            {
                Header = "Compose content (YAML)",
                PlaceholderText = "services:\n  web:\n    image: nginx",
                AcceptsReturn = true,
                Height = 220,
                FontFamily = new FontFamily("Consolas"),
                IsSpellCheckEnabled = false,
                TextWrapping = TextWrapping.NoWrap,
                Visibility = Visibility.Collapsed,
            };
            ScrollViewer.SetVerticalScrollBarVisibility(contentBox, ScrollBarVisibility.Auto);

            // Template source: mirrors the upstream create form where a compose
            // is resolved from a template; only the numeric id is captured
            // here and the template lookup happens Dart-side.
            var templateBox = new TextBox
            {
                Header = "Template ID",
                PlaceholderText = "e.g. 1",
                IsSpellCheckEnabled = false,
                Visibility = Visibility.Collapsed,
            };

            var errorText = new TextBlock
            {
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                Visibility = Visibility.Collapsed,
            };

            // Any edit clears the pending inline validation error; switching
            // the source toggles the path field / editor / template id field
            // visibility (exactly one source control shown at a time).
            void ClearError() => SetFormError(errorText, null);
            nameBox.TextChanged += (s, e) => ClearError();
            pathBox.TextChanged += (s, e) => ClearError();
            contentBox.TextChanged += (s, e) => ClearError();
            templateBox.TextChanged += (s, e) => ClearError();
            sourceCombo.SelectionChanged += (s, e) =>
            {
                ClearError();
                var selected = sourceCombo.SelectedIndex;
                pathBox.Visibility = selected == 0 ? Visibility.Visible : Visibility.Collapsed;
                contentBox.Visibility = selected == 1 ? Visibility.Visible : Visibility.Collapsed;
                templateBox.Visibility = selected == 2 ? Visibility.Visible : Visibility.Collapsed;
            };

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(nameBox);
            form.Children.Add(sourceCombo);
            form.Children.Add(pathBox);
            form.Children.Add(contentBox);
            form.Children.Add(templateBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = "Create compose",
                Content = form,
                PrimaryButtonText = "Create",
                CloseButtonText = "Cancel",
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            bool submitting = false;
            bool createSucceeded = false;

            async Task SubmitCreateAsync()
            {
                var from = FromSelection(sourceCombo.SelectedIndex);
                // The template id already passed the integer check in Closing,
                // so this parse cannot fail on the submit path.
                long? templateId = from == "template"
                    ? long.Parse(templateBox.Text.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture)
                    : null;
                var success = await WindowsBridge.CreateComposeAsync(
                    nameBox.Text.Trim(),
                    from,
                    from == "path" ? pathBox.Text.Trim() : null,
                    from == "raw" ? contentBox.Text : null,
                    templateId);
                if (success)
                {
                    createSucceeded = true;
                    dialog.Hide(); // Closing lets this programmatic close pass.
                }
                else
                {
                    submitting = false;
                    _errorToast.Show("Failed to create compose.");
                    SetFormError(errorText, "Create failed. Adjust the inputs and try again.");
                }
            }

            dialog.Closing += (s, args) =>
            {
                // Programmatic close after a successful create passes through.
                if (createSucceeded) return;

                // Swallow close attempts while the bridge call is in flight
                // so the dialog cannot outlive the submit result.
                if (submitting)
                {
                    args.Cancel = true;
                    return;
                }

                if (args.Result != ContentDialogResult.Primary) return;

                // Inline validation: cancel the close so the dialog stays
                // open and the error shows next to the fields.
                var error = ValidateCreateInput(
                    nameBox.Text,
                    FromSelection(sourceCombo.SelectedIndex),
                    pathBox.Text,
                    contentBox.Text,
                    templateBox.Text);
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

            // Dialog closed: release the dialog-lifetime guard so the guarded
            // silent refresh below can actually run.
            _isBusy = false;
            await LoadComposesAsync(showLoadingState: false);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Config editor dialog for one compose. Contract boundary: the list
    /// payload carries no compose content, so the editor starts empty and the
    /// update is a full replacement — the placeholder says so, empty content
    /// is rejected, and the row path (read-only, monospace) locates the file.
    /// Because two ContentDialogs cannot stack, a valid save first closes this
    /// dialog, an explicit confirmation states the full-replacement semantics
    /// (upstream onSubmitEdit), and a declined confirmation or a failed update
    /// reopens the same form with the pasted content intact.
    /// </summary>
    private async Task ShowEditComposeDialogAsync(ComposeEntry compose)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            // The path locates the compose for the update call, so it is
            // shown read-only instead of being editable alongside the content.
            var pathBox = new TextBox
            {
                Header = "Compose file path",
                Text = compose.Path,
                IsReadOnly = true,
                FontFamily = new FontFamily("Consolas"),
                IsSpellCheckEnabled = false,
            };
            ToolTipService.SetToolTip(pathBox, compose.Path);

            var contentBox = new TextBox
            {
                Header = "New compose content (YAML)",
                PlaceholderText = "Full replacement: paste the complete new config; empty content will be rejected",
                AcceptsReturn = true,
                Height = 260,
                FontFamily = new FontFamily("Consolas"),
                IsSpellCheckEnabled = false,
                TextWrapping = TextWrapping.NoWrap,
            };
            ScrollViewer.SetVerticalScrollBarVisibility(contentBox, ScrollBarVisibility.Auto);

            var errorText = new TextBlock
            {
                FontSize = 12,
                TextWrapping = TextWrapping.Wrap,
                Foreground = TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
                Visibility = Visibility.Collapsed,
            };

            // Any edit clears the pending inline validation error.
            contentBox.TextChanged += (s, e) => SetFormError(errorText, null);

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(pathBox);
            form.Children.Add(contentBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = $"Edit compose \"{compose.Name}\"",
                Content = form,
                PrimaryButtonText = "Save",
                CloseButtonText = "Cancel",
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            bool confirmPending = false;

            dialog.Closing += (s, args) =>
            {
                // Programmatic close on the way to the confirmation passes through.
                if (confirmPending) return;
                if (args.Result != ContentDialogResult.Primary) return;

                // Inline validation: empty content means "nothing to save".
                if (string.IsNullOrWhiteSpace(contentBox.Text))
                {
                    args.Cancel = true;
                    SetFormError(errorText, "Compose content is required.");
                    return;
                }

                // Close first so the confirmation dialog can open on top.
                args.Cancel = true;
                confirmPending = true;
                dialog.Hide();
            };

            while (true)
            {
                confirmPending = false;
                await dialog.ShowAsync();
                if (!confirmPending) return; // Closed via Cancel.

                var confirmed = await ConfirmDialog.ShowAsync(
                    XamlRoot,
                    "Edit Compose",
                    $"Replace the whole config of compose \"{compose.Name}\" with the pasted content?\nThe compose file will be fully overwritten. This action cannot be undone.",
                    "Replace",
                    "Cancel",
                    isDestructive: true);
                if (!confirmed) continue; // Back to the editor, content kept.

                var success = await WindowsBridge.UpdateComposeAsync(
                    compose.Name, compose.Path, contentBox.Text);
                if (success)
                {
                    // Release the dialog-lifetime guard so the guarded silent
                    // refresh below can actually run.
                    _isBusy = false;
                    await LoadComposesAsync(showLoadingState: false);
                    return;
                }

                _errorToast.Show($"Failed to save the config of \"{compose.Name}\".");
                SetFormError(errorText, "Save failed. The editor reopens with your content; try again.");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Maps the create-source combo index to the bridge "from" value.</summary>
    private static string FromSelection(int selectedIndex) => selectedIndex switch
    {
        1 => "raw",
        2 => "template",
        _ => "path",
    };

    /// <summary>Returns the first create-compose validation error, or null when the input is valid.</summary>
    private static string? ValidateCreateInput(string name, string from, string path, string file, string templateIdText)
    {
        if (string.IsNullOrWhiteSpace(name)) return "Name is required.";
        if (from == "path" && string.IsNullOrWhiteSpace(path)) return "Compose file path is required.";
        if (from == "raw" && string.IsNullOrWhiteSpace(file)) return "Compose content is required.";
        if (from == "template")
        {
            if (string.IsNullOrWhiteSpace(templateIdText)) return "Template ID is required.";
            if (!long.TryParse(templateIdText.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out _))
            {
                return "Template ID must be an integer.";
            }
        }
        return null;
    }

    /// <summary>Shows or clears the inline form error text under the fields.</summary>
    private static void SetFormError(TextBlock target, string? message)
    {
        target.Text = message ?? string.Empty;
        target.Visibility = string.IsNullOrEmpty(message)
            ? Visibility.Collapsed
            : Visibility.Visible;
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

    /// <summary>The compose id is a string in the bridge payload; numeric ids
    /// are accepted too by taking their raw JSON text.</summary>
    private static string? TryGetIdString(JsonElement element, string property)
    {
        if (element.ValueKind != JsonValueKind.Object ||
            !element.TryGetProperty(property, out var prop))
        {
            return null;
        }
        return prop.ValueKind switch
        {
            JsonValueKind.String => prop.GetString(),
            JsonValueKind.Number => prop.GetRawText(),
            _ => null,
        };
    }

    /// <summary>Row model straight from the bridge payload.</summary>
    private sealed class ComposeEntry
    {
        public string Id { get; set; } = "";
        public string Name { get; set; } = "";
        public string Path { get; set; } = "";
        public string Version { get; set; } = "";
        public string Status { get; set; } = "";
        public string CreateTime { get; set; } = "";
    }
}
