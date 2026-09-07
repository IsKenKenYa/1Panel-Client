using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace OnePanelNativeHost;

/// <summary>
/// Native Commands (quick command library) module page. Mirrors the upstream
/// 1Panel web frontend semantics (views/terminal/command):
/// - list shows the name, the command body in a monospace face (full text via
///   tooltip, matching the upstream show-overflow-tooltip column) and the
///   group (omitted when the payload carries none);
/// - create form takes name + multi-line command + group, mirroring the
///   upstream DrawerPro operate form; the group selector is filled from the
///   "command" group list with a leading "Default group" option mapped to
///   groupID 0 (the Dart core resolves 0 to the default group);
/// - row action: confirmed destructive delete naming the command, matching
///   the upstream row operation.
/// The upstream page also offers edit, batch delete, import/export, group
/// management and a group filter; this batch intentionally covers the
/// create/delete set exposed by the bridge contract (no update channel yet,
/// so no Edit action is provided).
/// All data flows through WindowsBridge (method channel to the Dart core);
/// no direct HTTP from the native layer.
/// </summary>
public sealed class CommandsPage : ModulePageBase
{
    private readonly List<CommandEntry> _commands = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads, the create dialog and row operations.</summary>
    private bool _isBusy;

    public CommandsPage()
    {
        PageTitle = "Commands";
    }

    protected override async void OnPageShown()
    {
        await LoadCommandsAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadCommandsAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadCommandsAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadCommandsCoreAsync(showLoadingState);
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
    private async Task LoadCommandsCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetCommandsAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show("Failed to refresh commands.");
            }
            return;
        }

        var commands = ParseCommands(result.Value);
        _commands.Clear();
        if (commands.Count == 0)
        {
            SetEmptyPrimaryAction("Create command",
                (s, e) => _ = ShowCreateCommandDialogAsync());
            SetState(PageState.Empty);
            return;
        }

        _commands.AddRange(commands);
        BuildContent(_commands);
        SetState(PageState.Content);
    }

    private static List<CommandEntry> ParseCommands(JsonElement json)
    {
        var commands = new List<CommandEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                commands.Add(new CommandEntry
                {
                    Id = TryGetInt64(item, "id"),
                    Name = TryGetString(item, "name") ?? "Unknown",
                    Command = TryGetString(item, "command") ?? "",
                    GroupBelong = TryGetString(item, "groupBelong") ?? "",
                });
            }
        }

        return commands;
    }

    private void BuildContent(List<CommandEntry> commands)
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

        foreach (var entry in commands)
        {
            list.Items.Add(CreateCommandItem(entry));
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
            Label = "Create command",
            Icon = new FontIcon { Glyph = "\uE710" },
        };
        createButton.Click += (s, e) => _ = ShowCreateCommandDialogAsync();
        bar.PrimaryCommands.Add(createButton);

        var refreshButton = new AppBarButton
        {
            Label = "Refresh",
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadCommandsAsync(showLoadingState: true);
        bar.SecondaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateCommandItem(CommandEntry entry)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = entry,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Info column: name, then the command body in a monospace face and
        // the optional group line. The command carries a tooltip with the
        // full text, matching the upstream show-overflow-tooltip column.
        var info = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
        };

        info.Children.Add(new TextBlock
        {
            Text = entry.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });

        if (!string.IsNullOrWhiteSpace(entry.Command))
        {
            var commandText = new TextBlock
            {
                Text = entry.Command,
                FontFamily = new FontFamily("Consolas"),
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            };
            ToolTipService.SetToolTip(commandText, entry.Command);
            info.Children.Add(commandText);
        }

        // Group line: omitted when the payload carries no group (upstream
        // renders an empty cell in that case).
        if (!string.IsNullOrWhiteSpace(entry.GroupBelong))
        {
            info.Children.Add(CreateSecondaryText("Group: " + entry.GroupBelong));
        }

        Grid.SetColumn(info, 0);
        grid.Children.Add(info);

        // Per-row "more" actions (upstream: row dropdown menu; delete only —
        // the bridge contract has no update channel, so no Edit action).
        var moreButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE712", FontSize = 14 },
            Background = null,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(6, 2, 6, 2),
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(moreButton, "Command actions");
        moreButton.Flyout = BuildRowFlyout(entry);
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

    private MenuFlyout BuildRowFlyout(CommandEntry entry)
    {
        var flyout = new MenuFlyout();

        var deleteItem = new MenuFlyoutItem
        {
            Text = "Delete",
            Icon = new FontIcon { Glyph = "\uE74D" }, // Delete.
        };
        deleteItem.Click += (s, e) => _ = DeleteCommandAsync(entry);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    /// <summary>Destructive row action with a confirmation naming the command.</summary>
    private async Task DeleteCommandAsync(CommandEntry entry)
    {
        if (_isBusy) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                "Delete Command",
                $"Are you sure you want to delete command \"{entry.Name}\"?\nThis action cannot be undone.",
                "Delete",
                "Cancel",
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.DeleteCommandAsync(entry.Id);
            if (success)
            {
                await LoadCommandsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{entry.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Create-command form dialog mirroring the upstream operate form: name +
    /// multi-line command + group selector. Name and command are required
    /// (inline Closing validation); the group selector is preloaded with the
    /// "Default group" option (groupID 0) and enriched from the "command"
    /// group list in the background — a group-load failure silently degrades
    /// to the default-only option. _isBusy is held across the whole dialog
    /// lifetime so the CommandBar button cannot open a second dialog and row
    /// operations stay blocked. The dialog stays open while the bridge call
    /// runs and only closes on success; on failure the toast shows and the
    /// form stays editable.
    /// </summary>
    private async Task ShowCreateCommandDialogAsync()
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var nameBox = new TextBox { Header = "Name", PlaceholderText = "e.g. Cleanup logs" };

            var commandBox = new TextBox
            {
                Header = "Command",
                PlaceholderText = "e.g. docker ps -a",
                AcceptsReturn = true,
                Height = 120,
                TextWrapping = TextWrapping.Wrap,
                FontFamily = new FontFamily("Consolas"),
            };

            // Group selector: the leading option maps to groupID 0, which the
            // Dart core resolves to the default group. Real groups are loaded
            // in the background; entries named "Default" are skipped because
            // the synthetic option already represents them.
            var groupCombo = new ComboBox { Header = "Group", MinWidth = 200, SelectedIndex = 0 };
            groupCombo.Items.Add(new GroupOption { Id = 0, Label = "Default group" });

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
            commandBox.TextChanged += (s, e) => ClearError();
            groupCombo.SelectionChanged += (s, e) => ClearError();

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(nameBox);
            form.Children.Add(commandBox);
            form.Children.Add(groupCombo);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = "Create command",
                Content = form,
                PrimaryButtonText = "Create",
                CloseButtonText = "Cancel",
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            // Enrich the group selector without blocking the dialog open; a
            // failure degrades silently to the default-only option list.
            _ = LoadGroupOptionsAsync(groupCombo);

            bool submitting = false;
            bool createSucceeded = false;

            async Task SubmitCreateAsync()
            {
                // Validation already guaranteed non-empty name and command.
                var selectedGroup = (groupCombo.SelectedItem as GroupOption)?.Id ?? 0;

                var success = await WindowsBridge.CreateCommandAsync(
                    nameBox.Text.Trim(),
                    commandBox.Text.Trim(),
                    selectedGroup);
                if (success)
                {
                    createSucceeded = true;
                    dialog.Hide(); // Closing lets this programmatic close pass.
                }
                else
                {
                    submitting = false;
                    _errorToast.Show("Failed to create the command.");
                    SetFormError(errorText, "Create failed. Adjust the inputs and try again.");
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
                var error = ValidateCommandInput(nameBox.Text, commandBox.Text);
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
            await LoadCommandsAsync(showLoadingState: false);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Fills the group selector from the "command" group list. The synthetic
    /// default option (index 0) always stays in place; entries named
    /// "Default" are skipped because they would duplicate it. Any failure is
    /// swallowed — the selector then only offers the default group.
    /// </summary>
    private static async Task LoadGroupOptionsAsync(ComboBox groupCombo)
    {
        try
        {
            var result = await WindowsBridge.GetGroupsAsync("command");
            if (result == null || result.Value.ValueKind != JsonValueKind.Array) return;

            foreach (var item in result.Value.EnumerateArray())
            {
                var name = TryGetString(item, "name");
                if (string.IsNullOrWhiteSpace(name) ||
                    string.Equals(name, "Default", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                groupCombo.Items.Add(new GroupOption
                {
                    Id = TryGetInt64(item, "id"),
                    Label = name,
                });
            }
        }
        catch
        {
            // Silent degrade: keep the default-only option list.
        }
    }

    /// <summary>Returns the first create-command validation error, or null when the input is valid.</summary>
    private static string? ValidateCommandInput(string name, string command)
    {
        if (string.IsNullOrWhiteSpace(name)) return "Name is required.";
        if (string.IsNullOrWhiteSpace(command)) return "Command is required.";
        return null;
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

    /// <summary>Row model straight from the bridge payload.</summary>
    private sealed class CommandEntry
    {
        public long Id { get; set; }
        public string Name { get; set; } = "";
        public string Command { get; set; } = "";
        public string GroupBelong { get; set; } = "";
    }

    /// <summary>Group selector option; ToString drives the ComboBox display.</summary>
    private sealed class GroupOption
    {
        public long Id { get; set; }
        public string Label { get; set; } = "";

        public override string ToString() => Label;
    }
}
