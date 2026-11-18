using System;
using System.IO;
using System.Runtime.InteropServices;

namespace OnePanelNativeHost;

/// <summary>
/// 定位并以进程内 headless 方式启动 Flutter 引擎（经 flutter_headless_host
/// 胶水 DLL，引擎资源由 OnePanelNativeHost.csproj 构建期复制到宿主输出目录）。
/// </summary>
public static class FlutterEngineHost
{
    /// <summary>宿主输出目录下的固定相对布局。</summary>
    public readonly record struct EnginePaths(string EngineDll, string AssetsPath, string IcuDataPath);

    public static EnginePaths ResolveEnginePaths(string hostDirectory)
    {
        var dataDirectory = Path.Combine(hostDirectory, "data");
        return new EnginePaths(
            EngineDll: Path.Combine(hostDirectory, "flutter_windows.dll"),
            AssetsPath: Path.Combine(dataDirectory, "flutter_assets"),
            IcuDataPath: Path.Combine(dataDirectory, "icudtl.dat"));
    }

    public static bool IsEnginePresent(string hostDirectory)
    {
        var paths = ResolveEnginePaths(hostDirectory);
        return File.Exists(paths.EngineDll) && Directory.Exists(paths.AssetsPath);
    }

    /// <summary>阻塞启动引擎（胶水 DLL 内部等待就绪），返回 messenger 句柄；失败返回 IntPtr.Zero。</summary>
    public static IntPtr Start(string hostDirectory)
    {
        var paths = ResolveEnginePaths(hostDirectory);
        var messenger = StartHeadlessEngine(paths.AssetsPath, paths.IcuDataPath);
        return new IntPtr(messenger);
    }

    [DllImport("flutter_headless_host.dll", EntryPoint = "StartHeadlessEngine")]
    private static extern long StartHeadlessEngine(
        [MarshalAs(UnmanagedType.LPWStr)] string assetsPath,
        [MarshalAs(UnmanagedType.LPWStr)] string icuDataPath);
}
