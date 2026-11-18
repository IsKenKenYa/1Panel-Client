using Microsoft.UI.Xaml;

namespace OnePanelNativeHost;

public partial class App : Application
{
    private Window? _window;

    /// <summary>供设置页等对主窗口施加视效（底衬）。</summary>
    public static Window? MainWindow { get; private set; }

    public App()
    {
        InitializeComponent();
        UnhandledException += (_, e) =>
        {
            try
            {
                System.IO.File.WriteAllText(
                    Path.Combine(AppContext.BaseDirectory, "crash.log"),
                    $"{e.Message}\n{e.Exception}");
            }
            catch
            {
                // 诊断兜底失败时无进一步处理
            }
        };
    }

    protected override async void OnLaunched(LaunchActivatedEventArgs args)
    {
        // Dart 业务核心（headless 引擎）先行；引擎未就绪或启动失败时，
        // 页面按既有四态降级（Loading → 错误态 + 重试）。
        var hostDirectory = AppContext.BaseDirectory;
        if (FlutterEngineHost.IsEnginePresent(hostDirectory))
        {
            // Dart 侧 main.dart 依据该环境变量进入 headless/引擎-only 模式。
            Environment.SetEnvironmentVariable("ONEPANEL_NATIVE_HOST_ACTIVE", "1");
            var messenger = FlutterEngineHost.Start(hostDirectory);
            WindowsBridge.Initialize(messenger);

            // 语言确定性：建窗前拉取当前语言整份 arb 字典（locale 决策在
            // Dart 侧）。5s 超时或失败回落英文，不阻塞宿主启动。
            try
            {
                await L10n.LoadAsync().WaitAsync(TimeSpan.FromSeconds(5));
            }
            catch
            {
                // 页面文案经 L10n.T 以英文原样兜底。
            }
        }

        _window = new MainWindow();
        MainWindow = _window;
        _window.Activate();
    }
}
