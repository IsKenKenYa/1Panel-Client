# hidumper 命令完整参考

基于 HarmonyOS 官方文档，hidumper 是系统诊断数据采集工具。

> Windows 路径转换问题 → `references/collection-workflow.md` "Windows (Git Bash) 路径转换问题"

## 堆内存命令（文件在设备上生成，需 hdc file recv 拉取）

所有堆快照文件存放于 `/data/log/reliability/resource_leak/memory_leak/` 目录。

### --mem-jsheap (ArkTS JS堆)

| 命令 | 说明 | 文件命名 | API版本 |
|------|------|---------|---------|
| `hidumper --mem-jsheap <pid>` | 默认：触发GC+导出JS堆快照 | `hidumper-jsheap-{pid}-{tid}-{ts}` | - |
| `hidumper --mem-jsheap <pid> -T <tid>` | 仅指定JS线程 | `hidumper-jsheap-{pid}-{tid}-{ts}` | - |
| `hidumper --mem-jsheap <pid> --gc` | 仅触发GC，不导出快照 | 无文件 | - |
| `hidumper --mem-jsheap <pid> --leakobj` | 泄漏对象列表（需先调用jsLeakWatcher.enable） | `hidumper-leaklist-{pid}-{ts}` | - |
| `hidumper --mem-jsheap <pid> --clean` | 导出后清理nodeId | `hidumper-jsheap-{pid}-{tid}-{ts}` | 24+ |

**注意事项：**
- 必需debug签名应用（API 26+ release应用需profileable标签+enterprise类型+开发者模式）
- 导出快照时应用应处于亮屏场景
- 默认行为（无--gc）同时触发GC和导出快照
- --gc仅触发GC，不导出快照文件
- --leakobj需应用先调用@ohos.hiviewdfx.jsLeakWatcher接口开启泄漏检测

### --mem-heap (其他堆类型)

| 命令 | 说明 | 文件命名 | API版本 |
|------|------|---------|---------|
| `hidumper --mem-heap <pid> --jsvm` | JSVM堆快照 | `hidumper-jsvmheap-{pid}-{tid}-{ts}` | 26+ |
| `hidumper --mem-heap <pid> --jsvm -T <tid>` | 指定JS线程JSVM堆 | `hidumper-jsvmheap-{pid}-{tid}-{ts}` | 26+ |
| `hidumper --mem-heap <pid> --arkweb-js` | ArkWeb JS堆快照 | `hidumper-arkweb_jsheap-{pid}-{ts}` | - |
| `hidumper --mem-heap <pid> --arkweb-js --gc` | 仅触发ArkWeb GC | 无文件 | - |
| `hidumper --mem-heap <pid> --kotlin` | Kotlin堆快照 | `hidumper-kotlinheap-{pid}-{ts}.kdump` | - |

## 内存相关命令

| 命令 | 说明 | 需要PID | 需要debug签名 |
|------|------|---------|---------------|
| `hidumper --mem` | 系统内存总览 | 否 | 否 |
| `hidumper --mem <pid>` | 进程内存概览 (PSS/RSS/VSS) | 是 | 否 |
| `hidumper --mem <pid> --show-ashmem` | 进程ashmem共享内存详情 | 是 | 否 |
| `hidumper --mem <pid> --show-dmabuf` | 进程DMA buffer详情 | 是 | 否 |
| `hidumper --mem <pid> --show-gpumem` | 进程GPU内存详情 | 是 | 否 |
| `hidumper --mem-smaps <pid>` | 进程smaps详细映射 | 是 | **是** |
| `hidumper --mem-smaps <pid> -v` | verbose smaps输出 | 是 | **是** |

## 数据分类映射

| hidumper输出 | 对应分类 |
|-------------|---------|
| `--mem` showmap数据 | process_measure (RSS/PSS/VSS) |
| `--mem-smaps` smaps数据 | smaps表 → 10类分类 |
| `--mem-jsheap` ArkTS heap | arkts_heap 分类 |
| `--mem-heap --jsvm` JSVM heap | arkts_heap 分类 |
| `--mem-heap --arkweb-js` ArkWeb heap | arkts_heap 分类 |
| `--mem-heap --kotlin` Kotlin heap | native_heap 分类 |
