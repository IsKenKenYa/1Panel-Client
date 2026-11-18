using System;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace OnePanelNativeHost;

/// <summary>
/// B2 文件编辑器子页（独立 Page，非 ModulePageBase，不经 Frame 导航栈）。
/// 语义对照上游 frontend/src/views/host/file-management/code-editor：
/// 打开即读取文件内容 → 等宽可编辑文本域 → 保存前二次确认 → 结果 InfoBar。
/// 由 MainWindow.OpenFileEditor 独立持有并显示，同一实例可跨文件复用
/// （切换文件经 <see cref="Initialize"/> 重绑），每次入树 Loaded 均重新拉取内容。
/// 返回按钮经 MainWindow.NavigateBackToFiles 回到文件列表。
/// </summary>
public sealed partial class FileEditorPage : Page
{
    private string _filePath;
    private string _fileName;

    private TextBlock? _titleText;
    private TextBox? _contentBox;
    private InfoBar? _statusBar;

    public FileEditorPage(string filePath, string fileName)
    {
        _filePath = filePath;
        _fileName = fileName;
        BuildLayout();
        Loaded += OnLoaded;
    }

    /// <summary>重绑目标文件：更新标题、清空文本域与状态条；内容在 Loaded 时拉取。</summary>
    public void Initialize(string filePath, string fileName)
    {
        _filePath = filePath;
        _fileName = fileName;
        if (_titleText != null) _titleText.Text = fileName;
        if (_contentBox != null) _contentBox.Text = string.Empty;
        if (_statusBar != null) _statusBar.IsOpen = false;
    }

    private void BuildLayout()
    {
        var root = new Grid { RowSpacing = 8 };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // 返回/保存行
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); // 状态 InfoBar
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }); // 编辑区

        // ── 顶部行：「← {fileName}」返回按钮 + 保存按钮 ──
        var topRow = new Grid();
        topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var backButton = new Button
        {
            HorizontalAlignment = HorizontalAlignment.Left,
            Padding = new Thickness(8, 5, 12, 5),
            Background = null,
            BorderThickness = new Thickness(0),
        };
        var backContent = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 8,
            VerticalAlignment = VerticalAlignment.Center,
        };
        backContent.Children.Add(new FontIcon { Glyph = "\uE72B", FontSize = 14 });
        _titleText = new TextBlock
        {
            Text = _fileName,
            FontSize = 18,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            MaxWidth = 640,
        };
        backContent.Children.Add(_titleText);
        backButton.Content = backContent;
        ToolTipService.SetToolTip(backButton, L10n.T("hostFilesEditorBack", "Back to files"));
        backButton.Click += (s, e) => (App.MainWindow as MainWindow)?.NavigateBackToFiles();
        Grid.SetColumn(backButton, 0);
        topRow.Children.Add(backButton);

        var saveButton = new Button
        {
            Content = L10n.T("filesEditorSave", "Save"),
            Style = (Style)Application.Current.Resources["AccentButtonStyle"],
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(8, 0, 0, 0),
        };
        saveButton.Click += (s, e) => _ = SaveAsync();
        Grid.SetColumn(saveButton, 1);
        topRow.Children.Add(saveButton);

        Grid.SetRow(topRow, 0);
        root.Children.Add(topRow);

        // ── 状态条：保存成功/失败、内容加载失败 ──
        _statusBar = new InfoBar
        {
            IsOpen = false,
            IsClosable = true,
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        Grid.SetRow(_statusBar, 1);
        root.Children.Add(_statusBar);

        // ── 编辑区：等宽、多行、不换行、可编辑 ──
        _contentBox = new TextBox
        {
            AcceptsReturn = true,
            TextWrapping = TextWrapping.NoWrap,
            IsReadOnly = false,
            IsSpellCheckEnabled = false,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 13,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
            VerticalContentAlignment = VerticalAlignment.Top,
            PlaceholderText = L10n.T("commonLoading", "Loading..."),
        };
        ScrollViewer.SetVerticalScrollBarVisibility(_contentBox, ScrollBarVisibility.Auto);
        ScrollViewer.SetHorizontalScrollBarVisibility(_contentBox, ScrollBarVisibility.Auto);
        Grid.SetRow(_contentBox, 2);
        root.Children.Add(_contentBox);

        Content = root;
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        await LoadContentAsync();
    }

    /// <summary>getFileContent → 取 JSON 的 content 字段填入文本域。</summary>
    private async Task LoadContentAsync()
    {
        if (_contentBox == null) return;

        _contentBox.IsEnabled = false;
        var result = await WindowsBridge.GetFileContentAsync(_filePath);
        var content = result == null ? null : TryGetString(result.Value, "content");
        _contentBox.IsEnabled = true;

        if (content == null)
        {
            _contentBox.Text = string.Empty;
            ShowStatus(InfoBarSeverity.Error,
                L10n.T("hostFilesEditorLoadFailed", "Failed to load file content."));
            return;
        }

        _contentBox.Text = content;
    }

    /// <summary>确认对话框 → saveFileContent → 结果 InfoBar。</summary>
    private async Task SaveAsync()
    {
        var confirmed = await ConfirmDialog.ShowAsync(
            XamlRoot,
            L10n.T("filesEditorSave", "Save"),
            string.Format(L10n.T("hostFilesEditorSaveConfirm", "Save changes to \"{0}\"?"), _fileName),
            L10n.T("commonSave", "Save"),
            L10n.T("commonCancel", "Cancel"));
        if (!confirmed) return;

        var success = await WindowsBridge.SaveFileContentAsync(_filePath, _contentBox?.Text ?? string.Empty);
        ShowStatus(
            success ? InfoBarSeverity.Success : InfoBarSeverity.Error,
            success
                ? L10n.T("filesEditorSaved", "Saved")
                : L10n.T("commonSaveFailed", "Failed to save"));
    }

    private void ShowStatus(InfoBarSeverity severity, string message)
    {
        if (_statusBar == null) return;
        _statusBar.Severity = severity;
        _statusBar.Message = message;
        _statusBar.IsOpen = true;
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
}
