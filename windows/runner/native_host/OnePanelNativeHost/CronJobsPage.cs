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
/// Native CronJobs (scheduled tasks) module page. Mirrors the upstream 1Panel
/// web frontend list semantics (views/cronjob/cronjob):
/// - list shows name, type badge, status badge, the cron spec in a monospace
///   face and the schedule lines (last run colored by record status, next run);
/// - row actions: run once, edit, enable/disable toggle and a confirmed
///   destructive delete, matching the upstream row operations;
/// - create/edit share one form dialog for the shell-script minimal set
///   (name + cron expression + optional script; group stays at the upstream
///   default 0 with no control exposed). The upstream create flow is a complex
///   wizard across many task flavors; this batch intentionally covers the
///   shell type only.
/// All data flows through WindowsBridge (method channel to the Dart core);
/// no direct HTTP from the native layer.
/// </summary>
public sealed class CronJobsPage : ModulePageBase
{
    private readonly List<CronJobEntry> _cronJobs = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads, the create/edit dialog and row operations.</summary>
    private bool _isBusy;

    public CronJobsPage()
    {
        PageTitle = "CronJobs";

        // Empty-state primary action: opens the create dialog so users can
        // add the first task. Registered once here; the button only shows
        // inside the base Empty panel, so the Content state needs no cleanup.
        SetEmptyPrimaryAction("Create task", (s, e) => _ = ShowTaskDialogAsync(existing: null));
    }

    protected override async void OnPageShown()
    {
        await LoadCronJobsAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadCronJobsAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadCronJobsAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadCronJobsCoreAsync(showLoadingState);
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
    private async Task LoadCronJobsCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetCronJobsAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show("Failed to refresh cron jobs.");
            }
            return;
        }

        var cronJobs = ParseCronJobs(result.Value);
        _cronJobs.Clear();
        if (cronJobs.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        _cronJobs.AddRange(cronJobs);
        BuildContent(_cronJobs);
        SetState(PageState.Content);
    }

    private static List<CronJobEntry> ParseCronJobs(JsonElement json)
    {
        var cronJobs = new List<CronJobEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                cronJobs.Add(new CronJobEntry
                {
                    Id = TryGetInt64(item, "id"),
                    Name = TryGetString(item, "name") ?? "Unknown",
                    Type = TryGetString(item, "type") ?? "",
                    Status = TryGetString(item, "status") ?? "",
                    Spec = TryGetString(item, "spec") ?? "",
                    LastRecordStatus = TryGetString(item, "lastRecordStatus") ?? "",
                    LastRecordTime = TryGetString(item, "lastRecordTime") ?? "",
                    NextHandle = TryGetString(item, "nextHandle") ?? "",
                });
            }
        }

        return cronJobs;
    }

    private void BuildContent(List<CronJobEntry> cronJobs)
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

        foreach (var job in cronJobs)
        {
            list.Items.Add(CreateCronJobItem(job));
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

        var createButton = new AppBarButton
        {
            Label = "Create task",
            Icon = new FontIcon { Glyph = "\uE710" },
        };
        createButton.Click += (s, e) => _ = ShowTaskDialogAsync(existing: null);
        bar.PrimaryCommands.Add(createButton);

        var refreshButton = new AppBarButton
        {
            Label = "Refresh",
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadCronJobsAsync(showLoadingState: true);
        bar.SecondaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateCronJobItem(CronJobEntry job)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = job,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Info column: name + type badge + status badge, then the cron spec
        // and the schedule lines (last run / next run).
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
            Text = job.Name,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        nameRow.Children.Add(CreateTypeBadge(job.Type));
        if (!string.IsNullOrWhiteSpace(job.Status))
        {
            nameRow.Children.Add(CreateStatusBadge(job.Status));
        }
        info.Children.Add(nameRow);

        // Cron spec in a monospace face, matching the upstream raw-expression
        // rendering in the spec column.
        if (!string.IsNullOrWhiteSpace(job.Spec))
        {
            info.Children.Add(new TextBlock
            {
                Text = job.Spec,
                FontFamily = new FontFamily("Consolas"),
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            });
        }

        // Last run: colored by the record status (success green / failed red /
        // waiting caution / unexecuted and unknown neutral), shown only when
        // the upstream payload carries a record time.
        var lastRun = FormatDateString(job.LastRecordTime);
        if (!string.IsNullOrWhiteSpace(job.LastRecordTime))
        {
            info.Children.Add(BuildScheduleLine("Last run", lastRun, GetRecordStatusBrush(job.LastRecordStatus)));
        }

        // Next run: neutral line, omitted when the payload carries no value.
        if (!string.IsNullOrWhiteSpace(job.NextHandle))
        {
            info.Children.Add(BuildScheduleLine(
                "Next run", FormatDateString(job.NextHandle),
                TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray)));
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
        ToolTipService.SetToolTip(moreButton, "Task actions");
        moreButton.Flyout = BuildRowFlyout(job);
        Grid.SetColumn(moreButton, 1);
        grid.Children.Add(moreButton);

        return grid;
    }

    /// <summary>Label + value line used for the last-run / next-run rows; the
    /// value carries the record-status color, the label stays secondary.</summary>
    private static FrameworkElement BuildScheduleLine(string label, string value, Brush valueBrush)
    {
        var row = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
        };
        row.Children.Add(new TextBlock
        {
            Text = label + ":",
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Center,
        });
        row.Children.Add(new TextBlock
        {
            Text = value,
            FontSize = 12,
            Foreground = valueBrush,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
        });
        return row;
    }

    private MenuFlyout BuildRowFlyout(CronJobEntry job)
    {
        var flyout = new MenuFlyout();

        // Upstream "handle": run the task immediately, no confirmation needed.
        var runItem = new MenuFlyoutItem
        {
            Text = "Run once",
            Icon = new FontIcon { Glyph = "\uE768" }, // Play.
        };
        runItem.Click += (s, e) => _ = RunOnceAsync(job);
        flyout.Items.Add(runItem);

        var editItem = new MenuFlyoutItem
        {
            Text = "Edit",
            Icon = new FontIcon { Glyph = "\uE70F" }, // Edit.
        };
        editItem.Click += (s, e) => _ = ShowTaskDialogAsync(job);
        flyout.Items.Add(editItem);

        // Label (and icon) follow the current status, matching the upstream
        // status badge that toggles enable/disable on click.
        var enabled = IsJobEnabled(job.Status);
        var toggleItem = new MenuFlyoutItem
        {
            Text = enabled ? "Disable" : "Enable",
            Icon = new FontIcon { Glyph = enabled ? "\uE711" : "\uE73E" }, // Cancel / CheckMark.
        };
        toggleItem.Click += (s, e) => _ = ToggleStatusAsync(job);
        flyout.Items.Add(toggleItem);

        var deleteItem = new MenuFlyoutItem
        {
            Text = "Delete",
            Icon = new FontIcon { Glyph = "\uE74D" }, // Delete.
        };
        deleteItem.Click += (s, e) => _ = DeleteCronJobAsync(job);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    /// <summary>Type pill badge; shell tasks get the accent blue, every other
    /// (out-of-scope) type stays neutral, with theme-resource brushes and a
    /// hardcoded fallback.</summary>
    private static FrameworkElement CreateTypeBadge(string type)
    {
        var (brushKey, fallbackColor) = GetTypeAccent(type);
        var accentBrush = TryGetThemeBrush(brushKey, fallbackColor);
        var accentColor = GetBrushColor(accentBrush, fallbackColor);

        var badgeContent = new TextBlock
        {
            Text = string.IsNullOrEmpty(type) ? "Unknown" : type,
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

    /// <summary>Status pill badge with a colored dot: Enable = success green,
    /// Disable = muted caution tone (caution theme brush, gray fallback).</summary>
    private static FrameworkElement CreateStatusBadge(string status)
    {
        var accentBrush = IsJobEnabled(status)
            ? TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green)
            : TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.Gray);
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
            Text = string.IsNullOrEmpty(status) ? "Unknown" : status,
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

    /// <summary>Accent brush key + fallback color per task type.</summary>
    private static (string BrushKey, Color FallbackColor) GetTypeAccent(string type)
        => type?.ToLowerInvariant() switch
        {
            "shell" => ("AccentFillColorDefaultBrush", Microsoft.UI.Colors.RoyalBlue),
            _ => ("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray), // Out-of-scope flavors stay neutral.
        };

    /// <summary>Brush for the last-run value, keyed by the upstream record
    /// status (Success/Failed/Waiting/Unexecuted).</summary>
    private static Brush GetRecordStatusBrush(string status)
        => status?.ToLowerInvariant() switch
        {
            "success" => TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green),
            "failed" => TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red),
            "waiting" => TryGetThemeBrush("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
            _ => TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
        };

    /// <summary>Named IsJobEnabled to avoid hiding the inherited Control.IsEnabled.</summary>
    private static bool IsJobEnabled(string status)
        => string.Equals(status, "Enable", StringComparison.OrdinalIgnoreCase);

    /// <summary>
    /// Upstream "handle": runs the task once immediately, without a
    /// confirmation. Success silently refreshes; failure shows the toast.
    /// </summary>
    private async Task RunOnceAsync(CronJobEntry job)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var success = await WindowsBridge.HandleCronJobOnceAsync(job.Id);
            if (success)
            {
                await LoadCronJobsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to run \"{job.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Enable/disable toggle. The bridge maps Enable to Disable and any other
    /// status to Enable, matching the upstream badge click semantics. Success
    /// silently refreshes; failure shows the toast.
    /// </summary>
    private async Task ToggleStatusAsync(CronJobEntry job)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            var enabling = !IsJobEnabled(job.Status);
            var success = await WindowsBridge.ToggleCronJobStatusAsync(job.Id, job.Status);
            if (success)
            {
                await LoadCronJobsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to {(enabling ? "enable" : "disable")} \"{job.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Destructive row action with a confirmation naming the task.</summary>
    private async Task DeleteCronJobAsync(CronJobEntry job)
    {
        if (_isBusy) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                "Delete Task",
                $"Are you sure you want to delete task \"{job.Name}\"?\nThis action cannot be undone.",
                "Delete",
                "Cancel",
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.DeleteCronJobAsync(job.Id);
            if (success)
            {
                await LoadCronJobsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{job.Name}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Shared create/edit form dialog for the shell minimal set. Create mode
    /// opens empty ("Create task"); edit mode prefills the row values and
    /// submits through the update bridge ("Edit task"). Name and the cron
    /// expression are required (inline Closing validation); the script is
    /// optional multi-line input. The group stays at the upstream default 0
    /// with no control exposed. _isBusy is held across the whole dialog
    /// lifetime so the CommandBar button cannot open a second dialog and row
    /// operations stay blocked. The dialog stays open while the bridge call
    /// runs and only closes on success; on failure the toast shows and the
    /// form stays editable.
    /// </summary>
    private async Task ShowTaskDialogAsync(CronJobEntry? existing)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            bool isEdit = existing != null;

            var nameBox = new TextBox { Header = "Name", PlaceholderText = "e.g. Cleanup logs" };
            var specBox = new TextBox { Header = "Cron expression", PlaceholderText = "*/5 * * * *" };
            var scriptBox = new TextBox
            {
                Header = "Script",
                PlaceholderText = isEdit
                    ? "Optional; submitting replaces the stored script"
                    : "Optional shell script",
                AcceptsReturn = true,
                Height = 120,
                TextWrapping = TextWrapping.Wrap,
            };

            if (isEdit)
            {
                // The list payload carries no script content, so only name and
                // spec can be prefilled; the placeholder warns about the
                // replace-on-submit semantics of the update channel.
                nameBox.Text = existing!.Name;
                specBox.Text = existing.Spec;
            }

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
            specBox.TextChanged += (s, e) => ClearError();
            scriptBox.TextChanged += (s, e) => ClearError();

            var form = new StackPanel { Orientation = Orientation.Vertical, Spacing = 12 };
            form.Children.Add(nameBox);
            form.Children.Add(specBox);
            form.Children.Add(scriptBox);
            form.Children.Add(errorText);

            var dialog = new ContentDialog
            {
                Title = isEdit ? "Edit task" : "Create task",
                Content = form,
                PrimaryButtonText = isEdit ? "Save" : "Create",
                CloseButtonText = "Cancel",
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };

            bool submitting = false;
            bool submitSucceeded = false;

            async Task SubmitAsync()
            {
                // Validation already guaranteed non-empty name and spec; an
                // empty script is sent as null (the Dart core maps it to an
                // empty script for the shell type).
                string? script = string.IsNullOrWhiteSpace(scriptBox.Text)
                    ? null
                    : scriptBox.Text.Trim();

                var success = isEdit
                    ? await WindowsBridge.UpdateCronJobAsync(
                        existing!.Id, nameBox.Text.Trim(), specBox.Text.Trim(), script, groupID: 0)
                    : await WindowsBridge.CreateCronJobAsync(
                        nameBox.Text.Trim(), specBox.Text.Trim(), script, groupID: 0);

                if (success)
                {
                    submitSucceeded = true;
                    dialog.Hide(); // Closing lets this programmatic close pass.
                }
                else
                {
                    submitting = false;
                    _errorToast.Show(isEdit ? "Failed to save the task." : "Failed to create the task.");
                    SetFormError(errorText, isEdit
                        ? "Save failed. Adjust the inputs and try again."
                        : "Create failed. Adjust the inputs and try again.");
                }
            }

            dialog.Closing += (s, args) =>
            {
                // Programmatic close after a successful submit passes through.
                if (submitSucceeded) return;

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
                var error = ValidateTaskInput(nameBox.Text, specBox.Text);
                if (error != null)
                {
                    args.Cancel = true;
                    SetFormError(errorText, error);
                    return;
                }

                // Keep the dialog open during submission; close only on success.
                args.Cancel = true;
                submitting = true;
                _ = SubmitAsync();
            };

            await dialog.ShowAsync();
            if (!submitSucceeded) return;

            // The dialog is closed; release the dialog-lifetime guard so the
            // _isBusy-guarded silent refresh below can actually run.
            _isBusy = false;
            await LoadCronJobsAsync(showLoadingState: false);
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>Returns the first form validation error, or null when the input is valid.</summary>
    private static string? ValidateTaskInput(string name, string spec)
    {
        if (string.IsNullOrWhiteSpace(name)) return "Name is required.";
        if (string.IsNullOrWhiteSpace(spec)) return "Cron expression is required.";
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

    /// <summary>Row model straight from the bridge payload.</summary>
    private sealed class CronJobEntry
    {
        public long Id { get; set; }
        public string Name { get; set; } = "";
        public string Type { get; set; } = "";
        public string Status { get; set; } = "";
        public string Spec { get; set; } = "";
        public string LastRecordStatus { get; set; } = "";
        public string LastRecordTime { get; set; } = "";
        public string NextHandle { get; set; } = "";
    }
}
