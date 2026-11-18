using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;

namespace OnePanelNativeHost;

/// <summary>
/// Native Files module page: directory listing with an editable address bar,
/// toolbar (new folder / new file / paste), local name search and per-row
/// operations (rename, copy/cut, compress, decompress, permissions, edit,
/// favorite, delete). All data flows through WindowsBridge (Dart business core
/// over the method channel); no direct HTTP from the native layer.
///
/// Upstream semantic reference: 1Panel web frontend "host/file-management":
/// - Address bar shows the current path and can be edited to jump (breadcrumb ⇄ input),
///   flanked by "up" and "refresh" buttons.
/// - "Create" toolbar action opens a name-input dialog anchored at the current directory.
/// - Row dropdown exposes copy/cut (clipboard lives in this page, paste moves via
///   moveFilesHandler type=copy|cut), rename, compress/decompress dialogs, role
///   (mode) editing, favorite and a destructive delete confirmation.
/// </summary>
public sealed class FilesPage : ModulePageBase
{
    private const double SizeColumnWidth = 100;
    private const double DateColumnWidth = 150;
    private const double RowActionColumnWidth = 44;

    private string _currentPath = "/";
    private ListView? _listView;
    private TextBox? _addressBox;
    private TextBox? _searchBox;
    private AppBarButton? _pasteButton;
    private TextBlock? _noMatchText;
    private List<FileEntry> _allFiles = new();
    private string _searchText = "";
    private readonly ErrorToast _errorToast = new();
    private readonly ClipboardState _clipboard = new();

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

        _allFiles = ParseFiles(result.Value);
        if (_allFiles.Count == 0)
        {
            SetState(PageState.Empty);
            return;
        }

        BuildFileList();
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
                    Mode = TryGetString(item, "mode") ?? "",
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

    private void BuildFileList()
    {
        var root = new Grid();
        var layout = new StackPanel { Orientation = Orientation.Vertical };

        layout.Children.Add(BuildCommandBar());
        layout.Children.Add(BuildAddressBar());
        layout.Children.Add(BuildListHeader());
        layout.Children.Add(BuildFileListView());

        // Local search hides every row of a non-empty directory: show a hint row.
        _noMatchText = new TextBlock
        {
            Text = L10n.T("hostFilesSearchNoMatch", "No matching files."),
            FontSize = 13,
            Margin = new Thickness(24, 8, 24, 8),
            Foreground = new SolidColorBrush(Microsoft.UI.Colors.Gray),
            Visibility = Visibility.Collapsed,
        };
        layout.Children.Add(_noMatchText);

        root.Children.Add(layout);

        // Transient feedback toast overlaid at the bottom of the content card.
        AttachToast(root, _errorToast);

        ModuleContentPresenter.Content = root;
        PopulateListItems();
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

        // Upstream toolbar "Create" dropdown also offers an empty file.
        var newFileButton = new AppBarButton
        {
            Label = L10n.T("filesActionNewFile", "New file"),
            Icon = new FontIcon { Glyph = "\uE7C3" },
        };
        newFileButton.Click += (s, e) => _ = ShowCreateFileDialogAsync(_currentPath);
        bar.PrimaryCommands.Add(newFileButton);

        // Paste the page-level copy/cut clipboard into the current directory
        // (upstream: paste button enabled once something was copied/cut).
        _pasteButton = new AppBarButton
        {
            Label = L10n.T("hostFilesPasteAction", "Paste"),
            Icon = new FontIcon { Glyph = "\uE77F" },
            IsEnabled = _clipboard.Paths.Count > 0,
        };
        _pasteButton.Click += (s, e) => _ = PasteClipboardAsync();
        bar.PrimaryCommands.Add(_pasteButton);

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

        // Local name filter over the loaded listing (upstream search box);
        // filters as you type, no server round-trip.
        _searchBox = new TextBox
        {
            Text = _searchText,
            PlaceholderText = L10n.T("filesSearchHint", "Search files"),
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(16, 0, 0, 0),
            Width = 220,
        };
        _searchBox.TextChanged += OnSearchTextChanged;
        Grid.SetColumn(_searchBox, 3);
        row.Children.Add(_searchBox);

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

    private FrameworkElement BuildFileListView()
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

        scrollViewer.Content = _listView;
        return scrollViewer;
    }

    /// <summary>Rebuild the visible rows from <see cref="_allFiles"/> through the local search filter.</summary>
    private void PopulateListItems()
    {
        if (_listView == null) return;

        var filtered = string.IsNullOrWhiteSpace(_searchText)
            ? _allFiles
            : _allFiles.Where(f => f.Name.Contains(_searchText, StringComparison.OrdinalIgnoreCase)).ToList();

        _listView.Items.Clear();
        foreach (var file in filtered)
        {
            _listView.Items.Add(CreateFileItem(file));
        }

        if (_noMatchText != null)
        {
            _noMatchText.Visibility = filtered.Count == 0 && _allFiles.Count > 0
                ? Visibility.Visible
                : Visibility.Collapsed;
        }
    }

    private void OnSearchTextChanged(object sender, TextChangedEventArgs e)
    {
        _searchText = _searchBox?.Text?.Trim() ?? "";
        PopulateListItems();
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

    /// <summary>
    /// Per-row dropdown (upstream row "more" menu). Folder-only: New folder.
    /// File-only: Edit. Archive-only (.zip/.tar.gz/.gz): Decompress.
    /// Delete stays last behind a separator as the destructive action.
    /// </summary>
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

        var copyItem = new MenuFlyoutItem
        {
            Text = L10n.T("filesActionCopy", "Copy"),
            Icon = new FontIcon { Glyph = "\uE8C8" },
        };
        copyItem.Click += (s, e) => StageClipboard(file, cut: false);
        flyout.Items.Add(copyItem);

        var cutItem = new MenuFlyoutItem
        {
            Text = L10n.T("hostFilesCutAction", "Cut"),
            Icon = new FontIcon { Glyph = "\uE8C6" },
        };
        cutItem.Click += (s, e) => StageClipboard(file, cut: true);
        flyout.Items.Add(cutItem);

        var renameItem = new MenuFlyoutItem
        {
            Text = L10n.T("filesActionRename", "Rename"),
            Icon = new FontIcon { Glyph = "\uE8AC" },
        };
        renameItem.Click += (s, e) => _ = ShowRenameDialogAsync(file);
        flyout.Items.Add(renameItem);

        if (!file.IsDir)
        {
            var editItem = new MenuFlyoutItem
            {
                Text = L10n.T("filesEditFile", "Edit File"),
                Icon = new FontIcon { Glyph = "\uE70F" },
            };
            editItem.Click += (s, e) =>
                (App.MainWindow as MainWindow)?.OpenFileEditor(ResolvePath(file), file.Name);
            flyout.Items.Add(editItem);
        }

        var compressItem = new MenuFlyoutItem
        {
            Text = L10n.T("filesActionCompress", "Compress"),
            Icon = new FontIcon { Glyph = "\uE8C5" },
        };
        compressItem.Click += (s, e) => _ = ShowCompressDialogAsync(file);
        flyout.Items.Add(compressItem);

        var archiveType = DetectArchiveType(file.Name);
        if (!file.IsDir && archiveType != null)
        {
            var decompressItem = new MenuFlyoutItem
            {
                Text = L10n.T("filesActionExtract", "Extract"),
                Icon = new FontIcon { Glyph = "\uE8B7" },
            };
            decompressItem.Click += (s, e) => _ = ShowDecompressDialogAsync(file, archiveType);
            flyout.Items.Add(decompressItem);
        }

        var modeItem = new MenuFlyoutItem
        {
            Text = L10n.T("hostFilesPermissionLabel", "Permissions"),
            Icon = new FontIcon { Glyph = "\uE72E" },
        };
        modeItem.Click += (s, e) => _ = ShowChangeModeDialogAsync(file);
        flyout.Items.Add(modeItem);

        var favoriteItem = new MenuFlyoutItem
        {
            Text = L10n.T("filesAddToFavorites", "Add to Favorites"),
            Icon = new FontIcon { Glyph = "\uE734" },
        };
        favoriteItem.Click += (s, e) => _ = AddFavoriteAsync(file);
        flyout.Items.Add(favoriteItem);

        flyout.Items.Add(new MenuFlyoutSeparator());

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

        var success = await WindowsBridge.DeleteFileAsync(ResolvePath(file), file.IsDir);
        if (!success)
        {
            _errorToast.Show($"Failed to delete \"{file.Name}\".");
            return;
        }

        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    /// <summary>Name-input dialog (upstream "create" drawer, file variant) followed by createFile.</summary>
    private async Task ShowCreateFileDialogAsync(string targetDir)
    {
        var nameBox = new TextBox
        {
            PlaceholderText = L10n.T("hostFilesFileNamePlaceholder", "File name"),
        };

        var confirmed = await ShowFormDialogAsync(
            L10n.T("filesActionNewFile", "New file"), nameBox, L10n.T("commonCreate", "Create"));
        if (!confirmed) return;

        var name = nameBox.Text.Trim();
        if (name.Length == 0)
        {
            _errorToast.Show(L10n.T("hostFilesFileNameEmpty", "File name cannot be empty."));
            return;
        }

        var success = await WindowsBridge.CreateFileAsync(JoinPath(targetDir, name));
        if (!success)
        {
            _errorToast.Show(string.Format(
                L10n.T("hostFilesCreateFileFailed", "Failed to create file \"{0}\"."), name));
            return;
        }

        SetState(PageState.Loading);
        await LoadFilesAsync(targetDir);
    }

    /// <summary>Rename within the current directory (upstream rename dialog, name prefilled).</summary>
    private async Task ShowRenameDialogAsync(FileEntry file)
    {
        var nameBox = new TextBox { Text = file.Name };

        var confirmed = await ShowFormDialogAsync(
            L10n.T("filesActionRename", "Rename"), nameBox, L10n.T("commonConfirm", "Confirm"));
        if (!confirmed) return;

        var name = nameBox.Text.Trim();
        if (name.Length == 0 || name == file.Name) return;

        var success = await WindowsBridge.RenameFileAsync(ResolvePath(file), JoinPath(_currentPath, name));
        if (!success)
        {
            _errorToast.Show(string.Format(
                L10n.T("hostFilesRenameFailed", "Failed to rename \"{0}\"."), file.Name));
            return;
        }

        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    /// <summary>
    /// Stage a row into the page-level clipboard (upstream copy/cut buttons);
    /// the toolbar Paste button becomes enabled and moveFiles runs on paste.
    /// </summary>
    private void StageClipboard(FileEntry file, bool cut)
    {
        _clipboard.Paths.Clear();
        _clipboard.Paths.Add(ResolvePath(file));
        _clipboard.IsCut = cut;
        if (_pasteButton != null) _pasteButton.IsEnabled = true;

        _errorToast.Show(cut
            ? L10n.T("hostFilesCutToast", "Cut. Paste it in the target directory.")
            : L10n.T("hostFilesCopyToast", "Copied. Paste it in the target directory."));
    }

    /// <summary>moveFiles(type=copy|cut) into the current directory, then clear the clipboard.</summary>
    private async Task PasteClipboardAsync()
    {
        if (_clipboard.Paths.Count == 0) return;

        var success = await WindowsBridge.MoveFilesAsync(
            new List<string>(_clipboard.Paths), _currentPath, _clipboard.IsCut ? "cut" : "copy");
        if (!success)
        {
            _errorToast.Show(L10n.T("hostFilesPasteFailed", "Paste failed."));
            return;
        }

        _clipboard.Paths.Clear();
        if (_pasteButton != null) _pasteButton.IsEnabled = false;

        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    /// <summary>
    /// Compress dialog (upstream compress drawer): archive name defaults to
    /// "&lt;name&gt;.zip" and follows the selected type, destination defaults to
    /// the current directory.
    /// </summary>
    private async Task ShowCompressDialogAsync(FileEntry file)
    {
        var nameBox = new TextBox { Text = file.Name + ".zip" };
        var typeBox = new ComboBox
        {
            ItemsSource = CompressTypes,
            SelectedIndex = 0,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        typeBox.SelectionChanged += (s, e) =>
        {
            if (typeBox.SelectedItem is string type)
            {
                nameBox.Text = WithArchiveExtension(nameBox.Text.Trim(), type);
            }
        };
        var dstBox = new TextBox { Text = _currentPath };

        var form = new StackPanel { Spacing = 8, MinWidth = 360 };
        form.Children.Add(BuildLabeledField(L10n.T("filesCompressType", "Type"), typeBox));
        form.Children.Add(BuildLabeledField(L10n.T("filesNameLabel", "Name"), nameBox));
        form.Children.Add(BuildLabeledField(
            L10n.T("hostFilesDestinationLabel", "Destination directory"), dstBox));

        var confirmed = await ShowFormDialogAsync(
            L10n.T("filesActionCompress", "Compress"), form, L10n.T("commonConfirm", "Confirm"));
        if (!confirmed) return;

        var name = nameBox.Text.Trim();
        var dst = NormalizePath(dstBox.Text);
        var selectedType = typeBox.SelectedItem as string ?? CompressTypes[0];
        if (name.Length == 0)
        {
            _errorToast.Show(L10n.T("hostFilesFileNameEmpty", "File name cannot be empty."));
            return;
        }

        var success = await WindowsBridge.CompressFilesAsync(
            new List<string> { ResolvePath(file) }, selectedType, dst, name);
        if (!success)
        {
            _errorToast.Show(string.Format(
                L10n.T("hostFilesCompressFailed", "Failed to compress \"{0}\"."), file.Name));
            return;
        }

        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    /// <summary>Decompress dialog (upstream decompress drawer): destination defaults to the current directory.</summary>
    private async Task ShowDecompressDialogAsync(FileEntry file, string archiveType)
    {
        var dstBox = new TextBox { Text = _currentPath };
        var form = new StackPanel { Spacing = 8, MinWidth = 360 };
        form.Children.Add(BuildLabeledField(
            L10n.T("hostFilesDestinationLabel", "Destination directory"), dstBox));

        var confirmed = await ShowFormDialogAsync(
            L10n.T("filesActionExtract", "Extract"), form, L10n.T("commonConfirm", "Confirm"));
        if (!confirmed) return;

        var success = await WindowsBridge.DecompressFileAsync(
            ResolvePath(file), NormalizePath(dstBox.Text), archiveType);
        if (!success)
        {
            _errorToast.Show(L10n.T("filesExtractFailed", "Extract failed"));
            return;
        }

        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    /// <summary>
    /// Octal permission dialog (upstream role dialog): prefilled from the entry's
    /// rwx mode string when the listing carries one, otherwise left for input.
    /// </summary>
    private async Task ShowChangeModeDialogAsync(FileEntry file)
    {
        var modeBox = new TextBox
        {
            Text = ModeToOctal(file.Mode),
            PlaceholderText = L10n.T("hostFilesModePlaceholder", "e.g. 755"),
        };

        var confirmed = await ShowFormDialogAsync(
            L10n.T("hostFilesPermissionLabel", "Permissions"), modeBox, L10n.T("commonConfirm", "Confirm"));
        if (!confirmed) return;

        var text = modeBox.Text.Trim();
        if (!IsOctalMode(text))
        {
            _errorToast.Show(L10n.T("hostFilesModeInvalid", "Enter a 3-digit octal permission (e.g. 755)."));
            return;
        }

        var success = await WindowsBridge.ChangeFileModeAsync(ResolvePath(file), Convert.ToInt32(text, 8));
        if (!success)
        {
            _errorToast.Show(string.Format(
                L10n.T("hostFilesModeFailed", "Failed to change permissions of \"{0}\"."), file.Name));
            return;
        }

        SetState(PageState.Loading);
        await LoadFilesAsync(_currentPath);
    }

    private async Task AddFavoriteAsync(FileEntry file)
    {
        var success = await WindowsBridge.AddFavoriteAsync(ResolvePath(file));
        _errorToast.Show(success
            ? L10n.T("filesFavoritesAdded", "Added to favorites")
            : L10n.T("hostFilesFavoriteFailed", "Failed to add favorite."));
    }

    /// <summary>Shared ContentDialog shell for the small form dialogs above.</summary>
    private async Task<bool> ShowFormDialogAsync(string title, FrameworkElement content, string primaryText)
    {
        var dialog = new ContentDialog
        {
            Title = title,
            Content = content,
            PrimaryButtonText = primaryText,
            CloseButtonText = L10n.T("commonCancel", "Cancel"),
            DefaultButton = ContentDialogButton.Primary,
            XamlRoot = XamlRoot,
        };
        return await dialog.ShowAsync() == ContentDialogResult.Primary;
    }

    private static StackPanel BuildLabeledField(string label, FrameworkElement field)
    {
        var panel = new StackPanel { Spacing = 4 };
        panel.Children.Add(new TextBlock { Text = label, FontSize = 12 });
        panel.Children.Add(field);
        return panel;
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

    // Compress type choices (upstream compress dialog options subset); order = dialog order.
    private static readonly string[] CompressTypes = { "zip", "gz", "tar.gz" };

    // Longest suffix first so ".tar.gz" is matched before ".gz".
    private static readonly string[] ArchiveSuffixes = { ".tar.gz", ".gz", ".zip" };

    /// <summary>Decompress type for archive rows; null for non-archives (menu item hidden).</summary>
    private static string? DetectArchiveType(string name)
    {
        foreach (var suffix in ArchiveSuffixes)
        {
            if (name.EndsWith(suffix, StringComparison.OrdinalIgnoreCase))
            {
                return suffix[1..];
            }
        }
        return null;
    }

    /// <summary>Swap a known archive suffix on <paramref name="name"/> for the selected compress type.</summary>
    private static string WithArchiveExtension(string name, string type)
    {
        foreach (var suffix in ArchiveSuffixes)
        {
            if (name.EndsWith(suffix, StringComparison.OrdinalIgnoreCase))
            {
                name = name[..^suffix.Length];
                break;
            }
        }
        return name + "." + type;
    }

    /// <summary>"drwxr-xr-x" / "rwxr-xr-x" → "755"; empty when the mode string is unavailable.</summary>
    private static string ModeToOctal(string mode)
    {
        if (mode.Length < 9) return "";
        var bits = mode[^9..];
        var value = 0;
        for (var i = 0; i < 9; i++)
        {
            if (bits[i] != '-') value |= 1 << (8 - i);
        }
        return Convert.ToString(value, 8).PadLeft(3, '0');
    }

    /// <summary>3 or 4 octal digits (e.g. 755, 0644).</summary>
    private static bool IsOctalMode(string text)
    {
        if (text.Length is < 3 or > 4) return false;
        foreach (var c in text)
        {
            if (c < '0' || c > '7') return false;
        }
        return true;
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
        /// <summary>rwx mode string from the listing when present (currently not carried by getFiles).</summary>
        public string Mode { get; set; } = "";
    }

    /// <summary>Page-level copy/cut buffer consumed by the toolbar Paste action.</summary>
    private sealed class ClipboardState
    {
        public List<string> Paths { get; } = new();
        public bool IsCut { get; set; }
    }
}
