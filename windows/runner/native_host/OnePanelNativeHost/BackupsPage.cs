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
/// Native Backups module page: a unified backup-record list across resource
/// types (app / website / database / directory / snapshot), mirroring the
/// upstream 1Panel web backup-record semantics
/// (frontend/src/components/backup/index.vue):
/// - list shows fileName (monospace), the resource type badge, the file size
///   in human readable units ("-" when 0, like the upstream size column) and
///   the record status badge (Success green / Failed red / other neutral),
///   plus a secondary line with the resource name and the backup time
///   (createdAt as the fallback when no dedicated backup time exists);
/// - row actions: restore (destructive, confirmed, disabled for failed
///   records or records whose size is 0, matching the upstream recover
///   button rules) and delete (destructive, confirmed, disabled while a
///   record is still "Waiting", matching upstream);
/// - backups themselves are produced by cron jobs / the panel, so the page
///   exposes no create entry — refresh only.
/// All data flows through WindowsBridge (method channel to the Dart core);
/// no direct HTTP from the native layer.
/// </summary>
public sealed class BackupsPage : ModulePageBase
{
    private readonly List<BackupEntry> _backups = new();
    private readonly ErrorToast _errorToast = new();

    /// <summary>Re-entrancy guard shared by loads and the row operations.</summary>
    private bool _isBusy;

    public BackupsPage()
    {
        PageTitle = "Backups";
    }

    protected override async void OnPageShown()
    {
        await LoadBackupsAsync(showLoadingState: true);
    }

    protected override async void OnRefreshClicked()
    {
        await LoadBackupsAsync(showLoadingState: true);
    }

    /// <summary>Guarded entry point used by page shown and the refresh action.</summary>
    private async Task LoadBackupsAsync(bool showLoadingState)
    {
        if (_isBusy) return;
        _isBusy = true;

        try
        {
            await LoadBackupsCoreAsync(showLoadingState);
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
    private async Task LoadBackupsCoreAsync(bool showLoadingState)
    {
        if (showLoadingState) SetState(PageState.Loading);

        var result = await WindowsBridge.GetBackupsAsync();

        if (result == null)
        {
            // Bridge failure: full error state on initial load, toast on refresh.
            if (showLoadingState)
            {
                SetState(PageState.Error);
            }
            else
            {
                _errorToast.Show(L10n.T("hostBackupsRefreshFailed", "Failed to refresh backup records."));
            }
            return;
        }

        var backups = ParseBackups(result.Value);
        _backups.Clear();
        if (backups.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        _backups.AddRange(backups);
        BuildContent(_backups);
        SetState(PageState.Content);
    }

    private static List<BackupEntry> ParseBackups(JsonElement json)
    {
        var backups = new List<BackupEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                backups.Add(new BackupEntry
                {
                    Id = TryGetInt64(item, "id"),
                    Name = TryGetString(item, "name") ?? "Unknown",
                    Type = TryGetString(item, "type") ?? "",
                    Size = TryGetInt64(item, "size"),
                    Status = TryGetString(item, "status") ?? "",
                    CreatedAt = TryGetString(item, "createdAt") ?? "",
                    BackupTime = TryGetString(item, "backupTime") ?? "",
                    DetailName = TryGetString(item, "detailName"),
                    FileName = TryGetString(item, "fileName") ?? "",
                    FileDir = TryGetString(item, "fileDir"),
                    DownloadAccountID = TryGetInt64(item, "downloadAccountID"),
                });
            }
        }

        return backups;
    }

    private void BuildContent(List<BackupEntry> backups)
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

        foreach (var backup in backups)
        {
            list.Items.Add(CreateBackupItem(backup));
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

    /// <summary>
    /// Backups are generated by cron jobs / the panel itself, so the bar only
    /// carries the refresh action (no create entry, like the upstream drawer).
    /// </summary>
    private CommandBar BuildCommandBar()
    {
        var bar = new CommandBar
        {
            HorizontalAlignment = HorizontalAlignment.Left,
            DefaultLabelPosition = CommandBarDefaultLabelPosition.Right,
            Background = null, // Stay transparent on the LayerFill card surface.
        };

        var refreshButton = new AppBarButton
        {
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = LoadBackupsAsync(showLoadingState: true);
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement CreateBackupItem(BackupEntry backup)
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 10, 16, 10),
            Tag = backup,
        };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Info column: fileName + type badge + size + status badge, then the
        // secondary line (resource name, backup time).
        var info = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 2,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var titleRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
        };
        // File name in a monospace face, like a path/name column entry.
        titleRow.Children.Add(new TextBlock
        {
            Text = string.IsNullOrEmpty(backup.FileName) ? L10n.T("orchestrationStatusUnknown", "Unknown") : backup.FileName,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
            MaxLines = 1,
        });
        titleRow.Children.Add(CreateTypeBadge(backup.Type));
        titleRow.Children.Add(CreateSizeText(backup.Size));
        if (!string.IsNullOrWhiteSpace(backup.Status))
        {
            titleRow.Children.Add(CreateStatusBadge(backup.Status));
        }
        info.Children.Add(titleRow);

        // Secondary line: resource name, then the record time — the dedicated
        // backup time when present, createdAt as the fallback (omitted when
        // neither carries a value).
        var secondaryRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
        };
        secondaryRow.Children.Add(new TextBlock
        {
            Text = backup.Name,
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
        });

        var displayTime = FormatDateString(backup.BackupTime);
        if (string.IsNullOrWhiteSpace(displayTime))
        {
            displayTime = FormatDateString(backup.CreatedAt);
        }
        if (!string.IsNullOrWhiteSpace(displayTime))
        {
            secondaryRow.Children.Add(new TextBlock
            {
                Text = "\u00B7", // Middle dot separator.
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                VerticalAlignment = VerticalAlignment.Center,
            });
            secondaryRow.Children.Add(new TextBlock
            {
                Text = displayTime,
                FontSize = 12,
                Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
                VerticalAlignment = VerticalAlignment.Center,
                TextTrimming = TextTrimming.CharacterEllipsis,
                TextWrapping = TextWrapping.NoWrap,
            });
        }
        info.Children.Add(secondaryRow);

        Grid.SetColumn(info, 0);
        grid.Children.Add(info);

        // Per-row "more" actions (upstream: row operations column).
        var moreButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE712", FontSize = 14 },
            Background = null,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(6, 2, 6, 2),
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
        };
        ToolTipService.SetToolTip(moreButton, L10n.T("hostBackupsActions", "Backup actions"));
        moreButton.Flyout = BuildRowFlyout(backup);
        Grid.SetColumn(moreButton, 1);
        grid.Children.Add(moreButton);

        return grid;
    }

    /// <summary>
    /// Row flyout with the upstream operations: recover (restore) and delete.
    /// Upstream disables recover for failed records or records with no size,
    /// and delete while the record is still "Waiting"; those rules carry over.
    /// </summary>
    private MenuFlyout BuildRowFlyout(BackupEntry backup)
    {
        var flyout = new MenuFlyout();

        var restoreItem = new MenuFlyoutItem
        {
            Text = L10n.T("backupRecordsRecoverAction", "Restore"),
            Icon = new FontIcon { Glyph = "\uE7A7" }, // Undo — roll data back to the backup.
            IsEnabled = CanRestore(backup),
        };
        if (!restoreItem.IsEnabled)
        {
            ToolTipService.SetToolTip(restoreItem,
                backup.Status.Equals("Failed", StringComparison.OrdinalIgnoreCase)
                    ? L10n.T("hostBackupsRestoreUnavailableFailed", "Restore is unavailable for failed backup records.")
                    : L10n.T("hostBackupsRestoreUnavailableSize", "Restore is unavailable while the file size is unknown."));
        }
        restoreItem.Click += (s, e) => _ = RestoreBackupAsync(backup);
        flyout.Items.Add(restoreItem);

        var deleteItem = new MenuFlyoutItem
        {
            Text = L10n.T("commonDelete", "Delete"),
            Icon = new FontIcon { Glyph = "\uE74D" }, // Delete.
            IsEnabled = !IsWaiting(backup),
        };
        if (!deleteItem.IsEnabled)
        {
            ToolTipService.SetToolTip(deleteItem, L10n.T("hostBackupsDeleteUnavailableWaiting", "Delete is unavailable while the backup is still waiting."));
        }
        deleteItem.Click += (s, e) => _ = DeleteBackupAsync(backup);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    /// <summary>Upstream recover rule: size must be known/non-zero and the record must not be failed.</summary>
    private static bool CanRestore(BackupEntry backup)
        => backup.Size > 0 && !backup.Status.Equals("Failed", StringComparison.OrdinalIgnoreCase);

    /// <summary>Upstream delete rule: records still "Waiting" cannot be removed.</summary>
    private static bool IsWaiting(BackupEntry backup)
        => backup.Status.Equals("Waiting", StringComparison.OrdinalIgnoreCase);

    /// <summary>Type pill badge; every known resource type gets its own accent
    /// color with a theme-resource brush and a hardcoded fallback.</summary>
    private static FrameworkElement CreateTypeBadge(string type)
    {
        var (brushKey, fallbackColor) = GetTypeAccent(type);
        var accentBrush = TryGetThemeBrush(brushKey, fallbackColor);
        var accentColor = GetBrushColor(accentBrush, fallbackColor);

        var badgeContent = new TextBlock
        {
            Text = string.IsNullOrEmpty(type) ? L10n.T("orchestrationStatusUnknown", "Unknown") : type,
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

    /// <summary>Status pill badge with a colored dot: Success = green,
    /// Failed = red, everything else (e.g. Waiting) = neutral.</summary>
    private static FrameworkElement CreateStatusBadge(string status)
    {
        var accentBrush = status.Equals("Success", StringComparison.OrdinalIgnoreCase)
            ? TryGetThemeBrush("SystemFillColorSuccessBrush", Microsoft.UI.Colors.Green)
            : status.Equals("Failed", StringComparison.OrdinalIgnoreCase)
                ? TryGetThemeBrush("SystemFillColorCriticalBrush", Microsoft.UI.Colors.Red)
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
            Text = string.IsNullOrEmpty(status) ? L10n.T("orchestrationStatusUnknown", "Unknown") : status,
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

    /// <summary>Human readable size text ("12.3 MB"); a dash when the record
    /// carries no size, matching the upstream size column.</summary>
    private static FrameworkElement CreateSizeText(long size)
    {
        return new TextBlock
        {
            Text = size > 0 ? FormatFileSize(size) : "-",
            FontSize = 12,
            Foreground = TryGetThemeBrush("TextFillColorSecondaryBrush", Microsoft.UI.Colors.Gray),
            VerticalAlignment = VerticalAlignment.Center,
        };
    }

    /// <summary>Accent brush key + fallback color per backup resource type.</summary>
    private static (string BrushKey, Color FallbackColor) GetTypeAccent(string type)
        => type?.ToLowerInvariant() switch
        {
            "app" => ("AccentFillColorDefaultBrush", Microsoft.UI.Colors.RoyalBlue),
            "website" => ("SystemFillColorSuccessBrush", Microsoft.UI.Colors.SeaGreen),
            "database" => ("SystemFillColorCautionBrush", Microsoft.UI.Colors.DarkOrange),
            "directory" => ("SystemFillColorAttentionBrush", Microsoft.UI.Colors.Goldenrod),
            "snapshot" => ("SystemFillColorCriticalBrush", Microsoft.UI.Colors.IndianRed),
            _ => ("SystemFillColorNeutralBrush", Microsoft.UI.Colors.Gray), // Unknown types stay neutral.
        };

    private static string FormatFileSize(long bytes)
    {
        string[] units = { "B", "KB", "MB", "GB", "TB" };
        var size = (double)bytes;
        var unitIndex = 0;

        while (size >= 1024 && unitIndex < units.Length - 1)
        {
            size /= 1024;
            unitIndex++;
        }

        return $"{size:F1} {units[unitIndex]}";
    }

    /// <summary>
    /// Destructive row action: restore the record. The confirmation names the
    /// backup file and warns that restoring overwrites the current data, then
    /// the whole row dictionary is re-sent to the Dart core. Success silently
    /// refreshes; failure shows the toast.
    /// </summary>
    private async Task RestoreBackupAsync(BackupEntry backup)
    {
        if (_isBusy) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                L10n.T("databaseBackupRestoreAction", "Restore Backup"),
                $"Are you sure you want to restore backup \"{backup.FileName}\" for \"{backup.Name}\"?\n" +
                L10n.T("hostBackupsRestoreOverwriteWarning", "This will overwrite the current data and cannot be undone."),
                L10n.T("backupRecordsRecoverAction", "Restore"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.RestoreBackupAsync(
                backup.Id, backup.Name, backup.Type, backup.DetailName,
                backup.FileName, backup.FileDir, backup.DownloadAccountID);
            if (success)
            {
                await LoadBackupsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to restore \"{backup.FileName}\".");
            }
        }
        finally
        {
            _isBusy = false;
        }
    }

    /// <summary>
    /// Destructive row action: delete the record. The confirmation names the
    /// backup file; the row dictionary fields required by the Dart core are
    /// re-sent. Success silently refreshes; failure shows the toast.
    /// </summary>
    private async Task DeleteBackupAsync(BackupEntry backup)
    {
        if (_isBusy) return;

        // Hold the guard across confirmation + call so no other flow starts.
        _isBusy = true;
        try
        {
            var confirmed = await ConfirmDialog.ShowAsync(
                XamlRoot,
                L10n.T("hostBackupsDeleteRecordTitle", "Delete Backup Record"),
                $"Are you sure you want to delete backup record \"{backup.FileName}\"?\nThis action cannot be undone.",
                L10n.T("commonDelete", "Delete"),
                L10n.T("commonCancel", "Cancel"),
                isDestructive: true);

            if (!confirmed) return;

            var success = await WindowsBridge.DeleteBackupAsync(
                backup.Id, backup.Name, backup.Type, backup.Status);
            if (success)
            {
                await LoadBackupsCoreAsync(showLoadingState: false);
            }
            else
            {
                _errorToast.Show($"Failed to delete \"{backup.FileName}\".");
            }
        }
        finally
        {
            _isBusy = false;
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

    /// <summary>Row model straight from the bridge payload; restore/delete
    /// calls re-send these original dictionary fields.</summary>
    private sealed class BackupEntry
    {
        public long Id { get; set; }
        public string Name { get; set; } = "";
        public string Type { get; set; } = "";
        public long Size { get; set; }
        public string Status { get; set; } = "";
        public string CreatedAt { get; set; } = "";
        public string BackupTime { get; set; } = "";
        public string? DetailName { get; set; }
        public string FileName { get; set; } = "";
        public string? FileDir { get; set; }
        public long DownloadAccountID { get; set; }
    }
}
