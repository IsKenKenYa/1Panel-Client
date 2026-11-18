using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>引擎资源定位：约定宿主输出目录下的固定相对布局（构建期复制保证）。</summary>
public class FlutterEngineHostPathTests
{
    [Fact]
    public void ResolveEnginePaths_uses_fixed_layout_under_host_directory()
    {
        var paths = FlutterEngineHost.ResolveEnginePaths(@"C:\host\dir");

        Assert.Equal(@"C:\host\dir\flutter_windows.dll", paths.EngineDll);
        Assert.Equal(@"C:\host\dir\data\flutter_assets", paths.AssetsPath);
        Assert.Equal(@"C:\host\dir\data\icudtl.dat", paths.IcuDataPath);
    }

    [Fact]
    public void IsEnginePresent_requires_engine_dll_and_assets_directory()
    {
        var temp = Path.Combine(Path.GetTempPath(), "onepanel-host-test-" + Guid.NewGuid().ToString("N"));
        try
        {
            Assert.False(FlutterEngineHost.IsEnginePresent(temp));

            Directory.CreateDirectory(Path.Combine(temp, "data", "flutter_assets"));
            File.WriteAllText(Path.Combine(temp, "flutter_windows.dll"), "stub");
            Assert.True(FlutterEngineHost.IsEnginePresent(temp));
        }
        finally
        {
            if (Directory.Exists(temp))
            {
                Directory.Delete(temp, recursive: true);
            }
        }
    }
}
