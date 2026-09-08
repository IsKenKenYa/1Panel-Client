using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace OnePanelNativeHost;

public enum PageState
{
    Loading,
    Content,
    Empty,
    Error
}

public class ModulePageBase : Page
{
    private readonly ProgressRing _progressRing;
    private readonly ContentPresenter _contentPresenter;
    private readonly StackPanel _emptyPanel;
    private Button? _emptyPrimaryButton;
    private readonly StackPanel _errorPanel;

    protected ContentPresenter ModuleContentPresenter => _contentPresenter;
    protected string PageTitle { get; set; } = string.Empty;

    public ModulePageBase()
    {
        NavigationCacheMode = Microsoft.UI.Xaml.Navigation.NavigationCacheMode.Enabled;

        var rootGrid = new Grid();

        _progressRing = new ProgressRing
        {
            IsActive = true,
            Width = 40,
            Height = 40,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        _contentPresenter = new ContentPresenter
        {
            Name = "ModuleContent",
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };

        _emptyPanel = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Spacing = 12,
            Orientation = Orientation.Vertical,
            Visibility = Visibility.Collapsed,
        };

        var emptyIcon = new FontIcon
        {
            Glyph = "\uE894",
            FontSize = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        var emptyText = new TextBlock
        {
            Text = L10n.T("commonEmpty", "No data available"),
            FontSize = 16,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        var refreshButton = new Button
        {
            Content = L10n.T("commonRefresh", "Refresh"),
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        refreshButton.Click += (s, e) => OnRefreshClicked();

        _emptyPanel.Children.Add(emptyIcon);
        _emptyPanel.Children.Add(emptyText);
        // Optional primary action (e.g. "Add website") shown above Refresh so
        // users can create the first row on an empty server.
        _emptyPrimaryButton = new Button
        {
            Visibility = Visibility.Collapsed,
            Style = (Style)Application.Current.Resources["AccentButtonStyle"],
        };
        // No default Click wiring: SetEmptyPrimaryAction owns the button once
        // registered; the standalone Refresh button below still covers reloads.
        _emptyPanel.Children.Add(_emptyPrimaryButton);
        _emptyPanel.Children.Add(refreshButton);

        _errorPanel = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Spacing = 12,
            Orientation = Orientation.Vertical,
            Visibility = Visibility.Collapsed,
        };

        var errorIcon = new FontIcon
        {
            Glyph = "\uE783",
            FontSize = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        var errorText = new TextBlock
        {
            Text = L10n.T("commonLoadFailedTitle", "Failed to load data"),
            FontSize = 16,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        var retryButton = new Button
        {
            Content = L10n.T("commonRetry", "Retry"),
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        retryButton.Click += (s, e) => OnRefreshClicked();

        _errorPanel.Children.Add(errorIcon);
        _errorPanel.Children.Add(errorText);
        _errorPanel.Children.Add(retryButton);

        rootGrid.Children.Add(_progressRing);
        rootGrid.Children.Add(_contentPresenter);
        rootGrid.Children.Add(_emptyPanel);
        rootGrid.Children.Add(_errorPanel);

        // Mica/亚克力底衬上的分层内容表面（Windows 设置应用同款视觉语言）。
        // Breathing space is owned by the shell (ContentFrame margin) to avoid double margins.
        var layerBorder = new Border
        {
            Background = (Brush)Application.Current.Resources["LayerFillColorDefaultBrush"],
            BorderBrush = (Brush)Application.Current.Resources["CardStrokeColorDefaultBrush"],
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
        };
        layerBorder.Child = rootGrid;
        Content = layerBorder;
        SetState(PageState.Loading);
    }

    public void SetState(PageState state)
    {
        _progressRing.IsActive = state == PageState.Loading;
        _progressRing.Visibility = state == PageState.Loading ? Visibility.Visible : Visibility.Collapsed;
        _contentPresenter.Visibility = state == PageState.Content ? Visibility.Visible : Visibility.Collapsed;
        _emptyPanel.Visibility = state == PageState.Empty ? Visibility.Visible : Visibility.Collapsed;
        _errorPanel.Visibility = state == PageState.Error ? Visibility.Visible : Visibility.Collapsed;
    }

    protected virtual void OnRefreshClicked()
    {
    }

    /// <summary>
    /// 页面被宿主切换显示时调用（直赋 Content 模式不触发 OnNavigatedTo）。
    /// </summary>
    public void ActivatePage() => OnPageShown();

    /// <summary>Empty 态显示的主操作按钮（如 "Add website"）。传 null 隐藏。</summary>
    protected void SetEmptyPrimaryAction(string label, RoutedEventHandler handler)
    {
        if (_emptyPrimaryButton == null)
        {
            return;
        }
        _emptyPrimaryButton.Content = label;
        _emptyPrimaryButton.Visibility = Visibility.Visible;
        _emptyPrimaryButton.Click -= handler;
        _emptyPrimaryButton.Click += handler;
    }

    /// <summary>
    /// Public refresh entry for host-level shortcuts (e.g. F5 in the shell).
    /// </summary>
    public void RefreshPage() => OnRefreshClicked();

    /// <summary>
    /// Mounts a page-level overlay (the shared ErrorToast) into a freshly
    /// rebuilt content tree. Pages rebuild their content on every load while
    /// the toast field stays alive on the previous tree; WinUI3 forbids one
    /// element having two parents and "Element is already the child of another
    /// element" (stowed exception) kills the host on the second build, so
    /// detach from the previous owner first.
    /// </summary>
    protected static void AttachToast(Panel root, FrameworkElement toast)
    {
        if (toast.Parent is Panel previousOwner)
        {
            previousOwner.Children.Remove(toast);
        }
        root.Children.Add(toast);
    }

    protected virtual void OnPageShown()
    {
    }
}
