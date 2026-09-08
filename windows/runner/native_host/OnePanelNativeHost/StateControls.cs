using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace OnePanelNativeHost;

public sealed class LoadingStateControl : UserControl
{
    public LoadingStateControl()
    {
        var stack = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Spacing = 12,
            Orientation = Orientation.Vertical,
        };

        var ring = new ProgressRing
        {
            IsActive = true,
            Width = 40,
            Height = 40,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var text = new TextBlock
        {
            Text = L10n.T("commonLoading", "Loading..."),
            FontSize = 14,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        stack.Children.Add(ring);
        stack.Children.Add(text);
        Content = stack;
    }
}

public sealed class EmptyStateControl : UserControl
{
    public event RoutedEventHandler? RefreshClicked;

    public EmptyStateControl()
    {
        var stack = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Spacing = 12,
            Orientation = Orientation.Vertical,
        };

        var icon = new FontIcon
        {
            Glyph = "\uE894",
            FontSize = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var text = new TextBlock
        {
            Text = L10n.T("commonEmpty", "No data available"),
            FontSize = 16,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var button = new Button
        {
            Content = L10n.T("commonRefresh", "Refresh"),
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        button.Click += (s, e) => RefreshClicked?.Invoke(this, e);

        stack.Children.Add(icon);
        stack.Children.Add(text);
        stack.Children.Add(button);
        Content = stack;
    }
}

public sealed class ErrorStateControl : UserControl
{
    public event RoutedEventHandler? RetryClicked;

    public ErrorStateControl()
    {
        var stack = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Spacing = 12,
            Orientation = Orientation.Vertical,
        };

        var icon = new FontIcon
        {
            Glyph = "\uE783",
            FontSize = 36,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var text = new TextBlock
        {
            Text = L10n.T("commonLoadFailedTitle", "Failed to load data"),
            FontSize = 16,
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var button = new Button
        {
            Content = L10n.T("commonRetry", "Retry"),
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        button.Click += (s, e) => RetryClicked?.Invoke(this, e);

        stack.Children.Add(icon);
        stack.Children.Add(text);
        stack.Children.Add(button);
        Content = stack;
    }
}
