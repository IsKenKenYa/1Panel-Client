# HAP 包体积优化指南（ArkTS 编译器 abc 去冗余）

## 适用场景

- HAP 包体积相比上一版本明显增长，且增长主要来自 `ets/modules.abc`（ArkTS 字节码）。
- smaps/包分析显示 `.hap` 映射 Pss 增大，根因为 abc 体积膨胀。
- 编译打包使用的 Command Line Tools / DevEco Studio 版本低于 6.1.1 Release，未享受到 ArkTS 编译器的 abc 去冗余优化。

## 背景：6.1.1 的 abc 去冗余优化

ArkTS 编译器在 **6.1.1** 版本对编译器进行了优化，对 **string section** 及 **code section** 进行了大幅的去冗余优化，对 abc size 的减小有不错的效果。

该优化完全在编译器（es2abc）内部实现，**全程无需修改应用代码**——只需用带优化的工具链版本编译打包即可生效。

## 升级方案一：整体升级工具链（推荐）

升级 **6.1.1 Release 或以上最新版本**的 Command Line Tools / DevEco Studio，使用该版本编译打包应用即可享受到优化效果。

下载地址：

- DevEco Studio：<https://developer.huawei.com/consumer/cn/download/deveco-studio>
- Command Line Tools：<https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos>

**操作步骤**：

1. 下载安装 6.1.1 Release 或以上最新版本（DevEco Studio 或 Command Line Tools 均可）。
2. 用新版本工具链对应用执行编译打包（IDE 出包或 `hvigorw` 命令行出包均可）。
3. 对比新旧产物中 `ets/modules.abc` 体积，确认优化生效。

**优点**：最简单、最稳妥，开发与出包环境一致，无兼容性风险。

## 升级方案二：仅替换 es2abc 二进制

不升级整套工具链，只把新版本的 **es2abc** 编译器二进制替换进现有 Command Line Tools / DevEco Studio 使用的 SDK 中。

**操作步骤**：

1. 下载对应平台（macOS/Windows/Linux）的 Command Line Tools **6.1.1 Release 或以上最新版本**（无需安装，解压即可）。
2. 从中拷贝编译器二进制：

   ```text
   sdk/default/openharmony/ets/build-tools/ets-loader/bin/ark/build-mac/bin/es2abc
   ```

   （Windows 为 `build-win/bin/es2abc.exe`，Linux 为 `build-linux/bin/es2abc`）

3. 替换当前 Command Line Tools / DevEco Studio **正在使用的** SDK 中同路径的 es2abc（本机 DevEco Studio 默认路径示例：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/build-tools/ets-loader/bin/ark/build-mac/bin/es2abc`）。
4. 对应用进行编译打包，对比 `ets/modules.abc` 体积确认效果。

**注意（重要限制）**：

- a. 本方案**只适用于出包场景**；开发场景替换会影响预览器（previewer 依赖 SDK 内配套版本，混用可能导致预览异常）。
- b. **FA 工程出包场景不适合**使用本方法（仅适用于 Stage 工程出包）。

**适用判断**：临时需要出瘦身包、但开发环境暂时无法整体升级时使用；条件允许时优先方案一。

## 效果验证方法

abc 体积在 HAP（zip 格式）内可直接量化对比：

```bash
# 列出 hap 内 abc 与 so 体积
unzip -l app-old.hap | grep -E "\.abc"

# 汇总 abc 总体积（字节）
unzip -l app-old.hap | grep "\.abc" | awk '{sum+=$1} END {print sum/1024 " KB"}'

# 新旧包对比：重点看 ets/modules.abc 一行
unzip -l app-new.hap | grep -E "\.abc"
```

重点观察 `ets/modules.abc`（应用自身字节码，通常占 abc 绝大部分）。`widgets.abc` 等其他 abc 体积较小，变化不大属正常。

## 劣化排查步骤（hap/abc 变大时）

1. **定位增长来源**：`unzip -l new.hap` 对比 `old.hap`，区分增长来自 `ets/*.abc`（ArkTS 字节码，本指南适用）、`libs/*.so`（原生库，见 so_size_optimization.md）、`resources/`（资源文件，检查图片/rawfile 是否新增大文件）。
2. **确认工具链版本**：检查当前出包所用 Command Line Tools / DevEco Studio 版本是否 ≥ 6.1.1 Release；`es2abc --bc-version` 可确认二进制可用性。
3. **确认工程模型**：FA 工程不适用方案二，只能走方案一整体升级。
4. **替换/升级后回归**：重新出包，对比 `ets/modules.abc` 体积；运行应用确认功能正常（abc 去冗余理论上不影响运行语义，仍需常规回归）。
5. **保留出包与开发环境隔离**（方案二）：出包机替换 es2abc，开发机保持原版，避免预览器受影响。

## 与其他体积优化手段的关系

| 手段 | 作用对象 | 生效方式 | 关系 |
|---|---|---|---|
| 6.1.1 es2abc 去冗余（本指南） | `ets/modules.abc` 的 string/code section | 升级工具链，无需改代码 | abc 体积优化的首选，先做 |
| so 编译选项（见 so_size_optimization.md） | `libs/*.so` | CMake 编译/链接选项 | 作用对象不同，可叠加 |
| 资源压缩（图片压缩、rawfile 清理等） | `resources/`、`rawfile` | 资源治理 | 作用对象不同，可叠加 |

## 验证记录（本机实测，2026-09）

以下为本机环境验证的工具链事实，供参考：

| 项目 | 实测结论 |
|---|---|
| es2abc 路径存在性 | `sdk/default/openharmony/ets/build-tools/ets-loader/bin/ark/build-mac/bin/es2abc` 存在，Mach-O arm64 可执行文件，与讨论帖方案二路径一致（Windows/Linux 对应 `build-win`/`build-linux` 目录） |
| es2abc 可独立执行 | `--bc-version` 输出 `24.0.0.00.0.0.2`；`--merge-abc` 等选项可用，二进制自包含可替换 |
| 本机 DevEco Studio 版本 | 26.0.0（build 26.0.0.461），高于 6.1.1，理论上已包含该优化；若 abc 仍异常偏大，优先排查业务代码量/依赖增长 |
| 本机 HAP 验证方法 | 对本机 `app-hongguo-signed.hap`（222MB）实测：`unzip -l` 可直接看到 `ets/modules.abc` 为 106,438,040 字节（约 101.5MB），abc 汇总 104,253KB——验证命令可用 |

## 核心约束

- ArkTS 编译器在 **6.1.1** 对 string section 与 code section 做了大幅去冗余优化，可有效减小 abc size；优化在编译器（es2abc）内部实现，**无需修改应用代码**。
- **方案一（推荐）**：升级 6.1.1 Release 或以上最新版本的 Command Line Tools / DevEco Studio 后直接编译打包，开发与出包环境一致，无兼容性风险。
- **方案二（仅替换 es2abc）**：从新版 Command Line Tools 拷贝 `sdk/default/openharmony/ets/build-tools/ets-loader/bin/ark/build-mac/bin/es2abc`（Windows 为 `build-win`、Linux 为 `build-linux`），替换当前工具链同路径文件后出包。
- **方案二限制 a**：只适用于**出包场景**；开发场景替换会影响预览器（previewer 依赖 SDK 配套版本）。
- **方案二限制 b**：**FA 工程出包场景不适用**，仅 Stage 工程可用；FA 工程只能走方案一整体升级。
- 效果验证：`unzip -l app.hap | grep abc` 对比 `ets/modules.abc` 体积（hap 为 zip 格式，可直接量化）。
- hap 劣化排查先区分增长来源：`ets/*.abc` 增长走本指南方案；`libs/*.so` 增长走 SO 编译选项方案（so_size_optimization.md）；`resources/`/`rawfile` 增长走资源治理。三者作用对象不同，可叠加。
