using Microsoft.UI.Composition.SystemBackdrops;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using Windows.Storage;

namespace OnePanelNativeHost;

public enum AppBackdropKind
{
    Mica,
    MicaAlt,
    Acrylic,
    None,
}

/// <summary>
/// 窗口系统底衬（Mica / 云母Alt / 亚克力 / 无）的应用与持久化。
/// 底衬要求窗口内容透明，内容以分层表面（LayerFill）呈现。
/// </summary>
public static class WindowBackdrop
{
    private const string SettingsKey = "app_backdrop_kind";

    public static AppBackdropKind LoadPreferred()
    {
        try
        {
            var value = ApplicationData.Current.LocalSettings.Values[SettingsKey] as string;
            return value switch
            {
                nameof(AppBackdropKind.MicaAlt) => AppBackdropKind.MicaAlt,
                nameof(AppBackdropKind.Acrylic) => AppBackdropKind.Acrylic,
                nameof(AppBackdropKind.None) => AppBackdropKind.None,
                _ => AppBackdropKind.Mica,
            };
        }
        catch
        {
            return AppBackdropKind.Mica;
        }
    }

    public static void SavePreferred(AppBackdropKind kind)
    {
        try
        {
            ApplicationData.Current.LocalSettings.Values[SettingsKey] = kind.ToString();
        }
        catch
        {
            // unpackaged ApplicationData 不可用时保持内存态即可
        }
    }

    public static void Apply(Window window, AppBackdropKind kind)
    {
        window.SystemBackdrop = kind switch
        {
            AppBackdropKind.Mica => new MicaBackdrop { Kind = MicaKind.Base },
            AppBackdropKind.MicaAlt => new MicaBackdrop { Kind = MicaKind.BaseAlt },
            AppBackdropKind.Acrylic => new DesktopAcrylicBackdrop(),
            _ => null,
        };
    }
}
