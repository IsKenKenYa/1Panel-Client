using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace OnePanelNativeHost;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        RootNavigationView.SelectionChanged += OnNavigationSelectionChanged;
        RootNavigationView.SelectedItem = RootNavigationView.MenuItems[0];
    }

    private void OnNavigationSelectionChanged(
        NavigationView sender,
        NavigationViewSelectionChangedEventArgs args)
    {
        if (args.SelectedItem is not NavigationViewItem item)
        {
            return;
        }

        ContentFrame.Content = new TextBlock
        {
            Text = $"WinUI3 Native Module: {item.Content}",
            Margin = new Thickness(24),
            FontSize = 20,
        };
    }
}
