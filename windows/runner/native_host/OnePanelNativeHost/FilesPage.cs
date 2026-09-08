using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;

namespace OnePanelNativeHost;

/// <summary>
/// Native Files module page: directory listing with an editable address bar,
/// folder creation and delete operations. All data flows through WindowsBridge
/// (Dart business core over the method channel); no direct HTTP from the native layer.
///
/// Upstream semantic reference: 1Panel web frontend "host/file-management":
/// - Address bar shows the current path and can be edited to jump (breadcrumb ⇄ input),
///   flanked by "up" and "refresh" buttons.
/// - "Create" toolbar action opens a name-input dialog anchored at the current directory.
/// - Row delete opens a destructive confirmation dialog before calling deleteFile.
/// </summary>
public sealed class FilesPage : ModulePageBase
{
    private const double SizeColumnWidth = 100;
    private const double DateColumnWidth = 150;
    private const double RowActionColumnWidth = 44;

    private string _currentPath = "/";
    private ListView? _listView;
    private TextBox? _addressBox;
    private readonly ErrorToast _errorToast = new();

    public FilesPage()
    {
        PageTitle = L10n.T("filesPageTitle", "Files");
    }

    protected override async void OnPageShown()
    {
        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    protected override async void OnRefreshClicked()
    {
        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    private async Task LoadFilesAsync(string path)
    {
        _currentPath = path;
        var result = await WindowsBridge.GetFilesAsync(path);

        if (result == null)
        {
            SetState(PageState.Error);
            return;
        }

        var files = ParseFiles(result.Value);
        if (files.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        BuildFileList(files);
        SetState(PageState.Content);
    }

    private List<FileEntry> ParseFiles(JsonElement json)
    {
        var files = new List<FileEntry>();

        if (json.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in json.EnumerateArray())
            {
                files.Add(new FileEntry
                {
                    Name = TryGetString(item, "name") ?? L10n.T("systemSettingsUnknown", "Unknown"),
                    Path = TryGetString(item, "path") ?? "",
                    IsDir = TryGetBool(item, "isDir"),
                    Size = TryGetInt64(item, "size"),
                    ModTime = TryGetInt64(item, "modTime"),
                });
            }
        }

        // Directories first, then by name (upstream table sorts the same way).
        files.Sort((a, b) =>
        {
            if (a.IsDir != b.IsDir) return a.IsDir ? -1 : 1;
            return string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase);
        });

        return files;
    }

    private void BuildFileList(List<FileEntry> files)
    {
        var root = new Grid();
        var layout = new StackPanel { Orientation = Orientation.Vertical };

        layout.Children.Add(BuildCommandBar());
        layout.Children.Add(BuildAddressBar());
        layout.Children.Add(BuildListHeader());
        layout.Children.Add(BuildFileListView(files));

        root.Children.Add(layout);

        // Transient feedback toast overlaid at the bottom of the content card.
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

        var newFolderButton = new AppBarButton
        {
            Label = L10n.T("filesActionNewFolder", "New folder"),
            Icon = new FontIcon { Glyph = "\uE8B7" },
        };
        newFolderButton.Click += (s, e) => _ = ShowCreateFolderDialogAsync(_currentPath);
        bar.PrimaryCommands.Add(newFolderButton);

        var refreshButton = new AppBarButton
        {
            Label = L10n.T("commonRefresh", "Refresh"),
            Icon = new FontIcon { Glyph = "\uE72C" },
        };
        refreshButton.Click += (s, e) => _ = RefreshCurrentAsync();
        bar.PrimaryCommands.Add(refreshButton);

        return bar;
    }

    private FrameworkElement BuildAddressBar()
    {
        var row = new Grid { Margin = new Thickness(16, 4, 16, 8) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Up (parent directory); disabled at root, mirroring upstream ":disabled".
        var upButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE74A", FontSize = 14 },
            Margin = new Thickness(0, 0, 8, 0),
            VerticalAlignment = VerticalAlignment.Center,
            IsEnabled = _currentPath != "/",
        };
        upButton.Click += OnNavigateUp;
        Grid.SetColumn(upButton, 0);
        row.Children.Add(upButton);

        // Editable address bar: shows the current path, Enter jumps to it.
        _addressBox = new TextBox
        {
            Text = _currentPath,
            PlaceholderText = L10n.T("hostFilesPathPlaceholder", "Enter a path and press Enter"),
            VerticalAlignment = VerticalAlignment.Center,
            MinWidth = 120,
        };
        _addressBox.KeyDown += OnAddressKeyDown;
        Grid.SetColumn(_addressBox, 1);
        row.Children.Add(_addressBox);

        var refreshButton = new Button
        {
            Content = new FontIcon { Glyph = "\uE72C", FontSize = 14 },
            Margin = new Thickness(8, 0, 0, 0),
            VerticalAlignment = VerticalAlignment.Center,
        };
        refreshButton.Click += (s, e) => _ = RefreshCurrentAsync();
        Grid.SetColumn(refreshButton, 2);
        row.Children.Add(refreshButton);

        return row;
    }

    private FrameworkElement BuildListHeader()
    {
        var header = CreateColumnGrid();
        header.Padding = new Thickness(12, 6, 12, 6);
        header.Margin = new Thickness(16, 0, 16, 4);
        header.BorderBrush = (Brush)Application.Current.Resources["CardStrokeColorDefaultBrush"];
        header.BorderThickness = new Thickness(0, 0, 0, 1);

        var nameHeader = new TextBlock
        {
            Text = L10n.T("filesNameLabel", "Name"),
            FontSize = 12,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(8, 0, 0, 0),
            Foreground = new SolidColorBrush(Microsoft.UI.Colors.Gray),
        };
        Grid.SetColumn(nameHeader, 1);
        header.Children.Add(nameHeader);

        var sizeHeader = new TextBlock
        {
            Text = L10n.T("commonSize", "Size"),
            FontSize = 12,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
            Foreground = new SolidColorBrush(Microsoft.UI.Colors.Gray),
        };
        Grid.SetColumn(sizeHeader, 2);
        header.Children.Add(sizeHeader);

        var dateHeader = new TextBlock
        {
            Text = L10n.T("filesModifiedLabel", "Modified"),
            FontSize = 12,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Center,
            Foreground = new SolidColorBrush(Microsoft.UI.Colors.Gray),
        };
        Grid.SetColumn(dateHeader, 3);
        header.Children.Add(dateHeader);

        return header;
    }

    private FrameworkElement BuildFileListView(List<FileEntry> files)
    {
        var scrollViewer = new ScrollViewer
        {
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            VerticalScrollMode = ScrollMode.Enabled,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            HorizontalScrollMode = ScrollMode.Disabled,
        };

        _listView = new ListView
        {
            SelectionMode = ListViewSelectionMode.Single,
            Margin = new Thickness(16, 0, 16, 8),
        };

        _listView.DoubleTapped += OnFileDoubleTapped;

        foreach (var file in files)
        {
            var item = CreateFileItem(file);
            _listView.Items.Add(item);
        }

        scrollViewer.Content = _listView;
        return scrollViewer;
    }

    /// <summary>Shared column layout so the header and every row stay aligned.</summary>
    private static Grid CreateColumnGrid()
    {
        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(32) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(SizeColumnWidth) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(DateColumnWidth) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(RowActionColumnWidth) });
        return grid;
    }

    private Grid CreateFileItem(FileEntry file)
    {
        var grid = CreateColumnGrid();
        grid.Padding = new Thickness(12, 6, 12, 6);
        grid.Tag = file;

        var icon = new FontIcon
        {
            Glyph = file.IsDir ? "\uE8B7" : "\uE7C3",
            FontSize = 18,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Foreground = file.IsDir
                ? new SolidColorBrush(Microsoft.UI.Colors.Goldenrod)
                : new SolidColorBrush(Microsoft.UI.Colors.DimGray),
        };
        Grid.SetColumn(icon, 0);
        grid.Children.Add(icon);

        var nameBlock = new TextBlock
        {
            Text = file.Name,
            FontSize = 14,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(8, 0, 8, 0),
            TextTrimming = TextTrimming.CharacterEllipsis,
        };
        Grid.SetColumn(nameBlock, 1);
        grid.Children.Add(nameBlock);

        var sizeText = !file.IsDir && file.Size >= 0 ? FormatFileSize(file.Size) : "";
        var sizeBlock = new TextBlock
        {
            Text = sizeText,
            FontSize = 12,
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Right,
            Foreground = new SolidColorBrush(Microsoft.UI.Colors.Gray),
        };
        Grid.SetColumn(sizeBlock, 2);
        grid.Children.Add(sizeBlock);

        var dateText = file.ModTime > 0
            ? DateTimeOffset.FromUnixTimeMilliseconds(file.ModTime).ToLocalTime()
                .ToString("yyyy-MM-dd HH:mm")
            : "";
        var dateBlock = new TextBlock
        {
            Text = dateText,
            FontSize = 12,
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Right,
            Foreground = new SolidColorBrush(Microsoft.UI.Colors.Gray),
        };
        Grid.SetColumn(dateBlock, 3);
        grid.Children.Add(dateBlock);

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
        moreButton.Flyout = BuildRowFlyout(file);
        Grid.SetColumn(moreButton, 4);
        grid.Children.Add(moreButton);

        return grid;
    }

    private MenuFlyout BuildRowFlyout(FileEntry file)
    {
        var flyout = new MenuFlyout();

        // Folder rows expose quick "New folder" inside that folder.
        if (file.IsDir)
        {
            var newFolderItem = new MenuFlyoutItem
            {
                Text = L10n.T("filesActionNewFolder", "New folder"),
                Icon = new FontIcon { Glyph = "\uE8B7" },
            };
            newFolderItem.Click += (s, e) => _ = ShowCreateFolderDialogAsync(ResolvePath(file));
            flyout.Items.Add(newFolderItem);
        }

        var deleteItem = new MenuFlyoutItem
        {
            Text = L10n.T("commonDelete", "Delete"),
            Icon = new FontIcon { Glyph = "\uE74D" },
        };
        deleteItem.Click += (s, e) => _ = DeleteEntryAsync(file);
        flyout.Items.Add(deleteItem);

        return flyout;
    }

    /// <summary>
    /// Name-input dialog (upstream "create" drawer) followed by createFolder.
    /// From the CommandBar the target is the current directory (refresh in place);
    /// from a folder row the target is that folder (navigate into it afterwards).
    /// </summary>
    private async Task ShowCreateFolderDialogAsync(string targetDir)
    {
        var nameBox = new TextBox
        {
            PlaceholderText = L10n.T("hostFilesFolderNamePlaceholder", "Folder name"),
        };

        var dialog = new ContentDialog
        {
            Title = L10n.T("filesActionNewFolder", "New folder"),
            Content = nameBox,
            PrimaryButtonText = L10n.T("commonCreate", "Create"),
            CloseButtonText = L10n.T("commonCancel", "Cancel"),
            DefaultButton = ContentDialogButton.Primary,
            XamlRoot = XamlRoot,
        };

        var result = await dialog.ShowAsync();
        if (result != ContentDialogResult.Primary) return;

        var name = nameBox.Text.Trim();
        if (name.Length == 0)
        {
            _errorToast.Show(L10n.T("hostFilesFolderNameEmpty", "Folder name cannot be empty."));
            return;
        }

        var success = await WindowsBridge.CreateFolderAsync(JoinPath(targetDir, name));
        if (!success)
        {
            _errorToast.Show($"Failed to create folder \"{name}\".");
            return;
        }

        SetState(PageState.Loading);
        await LoadFilesAsync(targetDir);
    }

    /// <summary>Destructive confirmation (upstream delete dialog) followed by deleteFile.</summary>
    private async Task DeleteEntryAsync(FileEntry file)
    {
        var confirmed = await ConfirmDialog.ShowAsync(
            XamlRoot,
            L10n.T("commonDelete", "Delete"),
            $"Delete \"{file.Name}\"?\n\n{(file.IsDir ? "Folder" : "File")}: {ResolvePath(file)}\nThis action cannot be undone.",
            L10n.T("commonDelete", "Delete"),
            L10n.T("commonCancel", "Cancel"),
            isDestructive: true);

        if (!confirmed) return;

        var success = await WindowsBridge.DeleteFileAsync(ResolvePath(file));
        if (!success)
        {
            _errorToast.Show($"Failed to delete \"{file.Name}\".");
            return;
        }

        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    private async Task RefreshCurrentAsync()
    {
        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    private async void OnAddressKeyDown(object? sender, KeyRoutedEventArgs e)
    {
        if (e.Key != Windows.System.VirtualKey.Enter) return;
        e.Handled = true;

        var target = NormalizePath(_addressBox?.Text ?? string.Empty);
        if (target == _currentPath) return;

        SetState(PageState.Loading);
        await LoadFilesAsync(target);
    }

    private async void OnFileDoubleTapped(object? sender, DoubleTappedRoutedEventArgs e)
    {
        if (_listView?.SelectedItem is not Grid grid) return;
        if (grid.Tag is not FileEntry file) return;
        if (!file.IsDir) return;

        SetState(PageState.Loading);
        await LoadFilesAsync(ResolvePath(file));
    }

    private async void OnNavigateUp(object? sender, RoutedEventArgs e)
    {
        if (_currentPath == "/") return;

        var parentPath = _currentPath.TrimEnd('/');
        var lastSlash = parentPath.LastIndexOf('/');
        parentPath = lastSlash <= 0 ? "/" : parentPath[..lastSlash];

        SetState(PageState.Loading);
        await LoadFilesAsync(parentPath);
    }

    /// <summary>Item path: prefer the path returned by the API, fall back to joining the current directory.</summary>
    private string ResolvePath(FileEntry file)
    {
        return string.IsNullOrEmpty(file.Path) ? JoinPath(_currentPath, file.Name) : file.Path;
    }

    /// <summary>Join a directory and a child name without producing "//".</summary>
    private static string JoinPath(string dir, string name)
    {
        if (string.IsNullOrEmpty(dir) || dir == "/") return "/" + name;
        return dir.TrimEnd('/') + "/" + name;
    }

    /// <summary>Normalize typed input: leading slash, no trailing slash, "/" for empty.</summary>
    private static string NormalizePath(string input)
    {
        var path = input.Trim();
        if (path.Length == 0) return "/";
        if (!path.StartsWith('/')) path = "/" + path;
        while (path.Length > 1 && path.EndsWith('/')) path = path[..^1];
        return path;
    }

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

    private static bool TryGetBool(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.True)
        {
            return true;
        }
        return false;
    }

    private static long TryGetInt64(JsonElement element, string property)
    {
        if (element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(property, out var prop) &&
            prop.ValueKind == JsonValueKind.Number)
        {
            return prop.TryGetInt64(out var v) ? v : (long)prop.GetDouble();
        }
        return -1;
    }

    private sealed class FileEntry
    {
        public string Name { get; set; } = "";
        public string Path { get; set; } = "";
        public bool IsDir { get; set; }
        public long Size { get; set; } = -1;
        public long ModTime { get; set; }
    }
}
