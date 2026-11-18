using OnePanelNativeHost;
using Xunit;

namespace OnePanelNativeHost.Tests;

/// <summary>
/// WindowsBridge.PrepareArgs 文件方法参数字典的契约测试（B2 文件管理深度：
/// moveFilesHandler / compressFilesHandler / changeFileModeHandler / renameFileHandler）。
/// Dictionary&lt;string, object?&gt; 命中非泛型 IDictionary 分支（分支顺序在泛型 IDictionary&lt;string, object?&gt; 之前），
/// 经 ConvertDictionary 复制为新字典：键转 string、List&lt;string&gt; 实例原样保留（StandardMessageCodec 直传）、
/// int/long 装箱类型原样（不做数值提升）。
/// 期望值独立手写，防止自证。
/// </summary>
public class FilesBridgeContractTests
{
    [Fact]
    public void PrepareArgs_moveFiles_keeps_3_keys_and_oldPaths_list_instance()
    {
        // 与 WindowsBridge.MoveFilesAsync 调用点同形（契约实现约定 2：oldPaths 为 List<String> 直传）。
        var oldPaths = new List<string> { "/opt/a.log", "/opt/b.log" };
        var args = new Dictionary<string, object?>
        {
            ["oldPaths"] = oldPaths,
            ["newPath"] = "/var/backups",
            ["type"] = "cut",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(3, dict.Count);
        Assert.Same(oldPaths, dict["oldPaths"]);
        var list = Assert.IsType<List<string>>(dict["oldPaths"]);
        Assert.Equal(2, list.Count);
        Assert.Equal("/opt/a.log", list[0]);
        Assert.Equal("/opt/b.log", list[1]);
        Assert.Equal("/var/backups", dict["newPath"]);
        Assert.Equal("cut", dict["type"]);
    }

    [Fact]
    public void PrepareArgs_compressFiles_keeps_4_keys_and_files_list_instance()
    {
        // 与 WindowsBridge.CompressFilesAsync 调用点同形（契约实现约定 2：files 为 List<String> 直传）。
        var files = new List<string> { "/opt/app.log", "/opt/conf.d" };
        var args = new Dictionary<string, object?>
        {
            ["files"] = files,
            ["type"] = "zip",
            ["dst"] = "/var/backups",
            ["name"] = "app_logs",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(4, dict.Count);
        Assert.Same(files, dict["files"]);
        Assert.Equal("zip", dict["type"]);
        Assert.Equal("/var/backups", dict["dst"]);
        Assert.Equal("app_logs", dict["name"]);
    }

    [Fact]
    public void PrepareArgs_changeFileMode_mode_stays_boxed_int()
    {
        // 与 WindowsBridge.ChangeFileModeAsync(string path, int mode) 调用点同形：
        // mode 以 int 装箱（0755 → 493），ConvertDictionary 不做数值提升。
        var args = new Dictionary<string, object?>
        {
            ["path"] = "/opt/run.sh",
            ["mode"] = 493,
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(2, dict.Count);
        Assert.Equal("/opt/run.sh", dict["path"]);
        Assert.Equal(typeof(int), dict["mode"]!.GetType());
        Assert.Equal(493, (int)dict["mode"]!);
    }

    [Fact]
    public void PrepareArgs_renameFile_keeps_2_keys_with_full_paths()
    {
        // 与 WindowsBridge.RenameFileAsync 调用点同形（契约：oldName/newName 均为完整路径）。
        var args = new Dictionary<string, object?>
        {
            ["oldName"] = "/opt/old_name.conf",
            ["newName"] = "/opt/new_name.conf",
        };

        var result = WindowsBridge.PrepareArgs(args);

        var dict = Assert.IsType<Dictionary<string, object?>>(result);
        Assert.NotSame(args, dict);
        Assert.Equal(2, dict.Count);
        Assert.Equal("/opt/old_name.conf", dict["oldName"]);
        Assert.Equal("/opt/new_name.conf", dict["newName"]);
    }
}
