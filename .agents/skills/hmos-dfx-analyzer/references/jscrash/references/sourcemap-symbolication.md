# JS Crash SourceMap 反解

仅在 JS Crash 堆栈未还原到源码，或用户提供 SourceMap 构建产物时读取本文件。

## 输入要求

使用 Skill 内置的 `scripts/hstack/` 工具还原 release/混淆后的 ArkTS/JS 堆栈。该工具包跨平台共用，无需另外下载 DevEco Studio 命令行工具。执行前确认：

1. `node --version` 能正常运行，并使用当前系统对应的内置入口执行 `--help`：Windows 使用 `"<skill-root>\scripts\hstack\bin\hstack.bat" --help`，Linux/macOS 使用 `"<skill-root>/scripts/hstack/bin/hstack" --help`。
2. SourceMap 来自故障应用的同一版本、VersionCode、product、模块和构建模式。
3. `sourceMaps.json` 通常位于模块构建目录的 `build/default/cache/default@CompileArkTS/esmodule/release/` 下；`hstack` 实际读取该目录下后缀为 `.map` 的映射文件。
4. 启用名称混淆时，同时提供同一次构建生成的 `nameCache.json`；只需要恢复文件和行列号时可以不提供。
5. 不覆盖原始 crash 日志，反解结果写入独立输出目录。
6. UUID / 构建指纹校验（必须）：
   - 故障日志必须包含构建指纹/UUID 字段（faultlogger 中一般为 `Fingerprint`），SourceMap 构建产物必须携带同一次构建的指纹（例如产物目录中的 `build-info.json` 或 sourcemap 元数据 `fingerprint` 字段）。
   - 反解前先比对：日志 `Fingerprint` 与产物指纹一致才允许使用该产物反解；不一致时不得使用，视为“匹配版本的 SourceMap 缺失”，并要求用户补充与故障版本一致（版本、VersionCode、product、模块、构建模式、构建指纹均匹配）的映射产物。
   - 只有 UUID/指纹一致仍不够，还必须同时满足第 2 条（版本等字段一致）；UUID 校验用于防止“同版本号但不同构建”的产物混用。

## 执行命令

Windows PowerShell 或 CMD 使用：

```text
"<skill-root>\scripts\hstack\bin\hstack.bat" -i "<crash-dir>" -o "<output-dir>" -s "<source-map-dir>"
```

Linux/macOS 使用：

```text
"<skill-root>/scripts/hstack/bin/hstack" -i "<crash-dir>" -o "<output-dir>" -s "<source-map-dir>"
```

对归档目录中的 crash 文件进行反解：

```text
<hstack-command> -i "<crash-dir>" -o "<output-dir>" -s "<source-map-dir>"
```

需要同时还原混淆方法名时：

```text
<hstack-command> -i "<crash-dir>" -o "<output-dir>" -s "<source-map-dir>" -n "<name-cache-dir>"
```

只反解一段 raw stack 时：

```text
<hstack-command> -c "<raw-stack>" -o "<output-file>" -s "<source-map-dir>" -n "<name-cache-dir>"
```

`<hstack-command>` 表示上方当前系统对应的完整 `<skill-root>` 命令。`-i` 和 `-c` 只能选择一个。输入只有单个日志文件时，可将其放入独立临时目录后使用 `-i`，避免同目录其他日志混入结果。

## 结果校验

1. 反解前先完成 UUID / 构建指纹校验：日志 `Fingerprint`（或 UUID 字段）与产物 `build-info.json` / sourcemap 元数据的指纹必须一致，不一致的结果一律不得作为证据。
2. 对照原始栈和反解结果，确认至少一个关键应用帧被还原为可识别的源码文件、函数或行列号。
3. 使用反解后的第一个应用帧定位责任代码，同时在证据链保留对应原始栈帧。
4. 反解结果为空、仍只有构建缓存路径，或行列号无法对应源码时，标记为“反解失败”，优先核对映射文件版本、构建模式和构建指纹。
5. SourceMap 版本无法确认时，不得把映射结果作为确定性根因证据。

## 降级处理

- 内置 `hstack` 文件缺失：标记工具不完整，重新获取完整 Skill 仓库；Node.js 缺失时先安装或配置 Node.js。
- 未提供 SourceMap：基于 raw stack 初步定界，源码位置可信度降低，第一项建议要求补充匹配版本的 `sourceMaps.json`。
- 日志缺少 `Fingerprint`/UUID 字段或产物缺少构建指纹：无法完成 UUID 校验，标记“无法校验”，不得将映射结果作为确定性证据，并要求补充可核对指纹的产物。
- 日志与产物指纹不一致：标记“UUID/构建指纹不匹配”，禁止使用该产物反解；即使 hstack 能输出映射，也按“未提供匹配 SourceMap”处理，要求补充与故障构建指纹一致的产物。
- 已启用名称混淆但缺少 `nameCache.json`：可以恢复文件和行列号，但方法名保持未还原状态，报告中必须明确说明。
