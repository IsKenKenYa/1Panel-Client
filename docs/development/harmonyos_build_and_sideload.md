# HarmonyOS 构建与侧载指南

> 最后验证：2026-11-22

本文用于 HarmonyOS / OHOS HAP 构建、侧载分发与常见问题排障。HarmonyOS 在本项目中按一等平台处理：共享业务逻辑仍在 Dart 层，平台缺口优先通过 ArkTS Platform Bridge 补齐，不为 HarmonyOS 复制业务实现。

## 已验证构建基线

本机已验证命令：

```bash
hflutter build hap --release
```

等效完整路径命令：

```bash
/Volumes/FanXiangMac/DevTools/Flutter_HMOS/flutter_flutter/bin/flutter build hap --release
```

已验证 Flutter-OH：

```text
Flutter 3.44.9+ohos-1.0.0
Framework revision fda3a43c32
Dart 3.12.2
```

输出产物：

```text
build/ohos/hap/entry-default-signed.hap
```

构建前设置 DevEco 工具链：

```bash
export DEVECO_SDK_HOME="/Volumes/FanXiangMac/Applications/DevEco-Studio.app/Contents/sdk"
export PATH="/Volumes/FanXiangMac/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:/Volumes/FanXiangMac/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:/Volumes/FanXiangMac/Applications/DevEco-Studio.app/Contents/tools/node/bin:/Volumes/FanXiangMac/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains:$PATH"
```

`hvigorw` 与 `ohpm` 必须出现在 `PATH`；`DEVECO_SDK_HOME` 指向 DevEco 的 `sdk` 目录。

3.44.9 构建依赖以下项目内兼容件：

- `third_party/patched_packages/chewie`、`xterm`：补充 `TargetPlatform.ohos` 的默认分支，官方 Flutter 与 Flutter-OH 共用。
- `third_party/patched_packages/device_info_plus`：OHOS 适配版 12.3.0，OHOS 判定改为 `Platform.operatingSystem == 'ohos'`。
- `third_party/patched_packages/url_launcher_ohos`：从 `@ohos/flutter_ohos` 公开入口导入。
- `syncfusion_flutter_pdfviewer` 使用 Flutter-OH 适配仓库的 35.1.37 分支。

本机 SDK 补丁（不在仓库内）：

- `packages/flutter_tools/hvigor/src/util/file-util.ts` 的 `relativePath` 解析符号链接，避免 pub cache 跨卷时 hvigor 报 `Path not found`。
- DevEco 公开 SDK 的 `@ohos.app.ability.autoFillManager.d.ts` 补齐 3.44 嵌入层使用的系统 API 声明。

如果最新 Flutter-OH 出现第三方包或 SDK 兼容问题，优先回退到已验证 revision，再对比差异。

## Flutter SIG 版本线（2026-11-22 核对）

上层组织为 Flutter SIG，SDK 仓库在 `gitcode.com/CPF-Flutter/flutter_flutter`，本地 SDK 的 `origin` 仍写 `openharmony-tpc/flutter_flutter`，两者解析到相同提交。参考文档与示例在 `gitcode.com/CPF-Flutter/flutter_samples`。

| 上游基线 | Flutter-OH 版本 | 标签 | 发布日期 | 说明 |
| --- | --- | --- | --- | --- |
| 3.35.7 | 3.35.8-ohos-1.0.7 | `3.35.8-ohos-1.0.7` | 2026-11-13 | 维护线 |
| 3.41.9 | 3.41.9+ohos-1.0.2 | `3.41.9+ohos-1.0.2` | 2026-09-24 | 采用 `+ohos` build metadata 版本格式 |
| 3.41.9 | 3.41.9+ohos-1.0.4 | 只有 `1.0.4-beta` 标签 | 2026-10-24（beta） | 分支 `oh-3.41.9-release` 的 CHANGELOG 已记录 1.0.4 |
| 3.44.9 | 3.44.9+ohos-1.0.0 | `3.44.9+ohos-1.0.0` | 2026-11-13 | 本项目当前基线 |
| 3.47.7 | 3.47.7+ohos-0.0.1-pre | 只有预览标签 | — | 预览状态 |

`1.0.2` 的版本配套要求：DevEco Studio 26.0.0 Release、Command Line Tools 26.0.0 Release、引擎构建最低 SDK 26.0.0、应用编译最低 SDK 26.0.0、应用运行最低 SDK 5.0.5(17)。这些要求与 3.44.9+ohos-1.0.0 一致，因此两套版本线共用同一套 DevEco 环境。

`1.0.2` 的主要变更包括动态 DPI 溢出策略与 PlatformView 坐标修复、`+ohos` 标签格式解析、GPU 资源回收日志、白屏渲染 DFX 日志、LTPO 默认开启、密码保险箱、引擎异步创建与销毁、页面不可见暂停、DMA 零拷贝图像解码，以及 `StandardMessageCodec` 子类覆写、递归数据通道、Ability 重建后插件状态恢复等修复。这些能力在 3.44.9+ohos-1.0.0 的嵌入层源码中均已存在（`OhosAutoFillHelper`、`spawnAsync`/`destroyAsync`、`onVisibleAreaChange`、`ohos_image_generator` 的 DMA 路径、hdc 启动参数中的 `route`）。

版本标签以远端标签为准，不要依赖分支 tip 推算。3.41.9 与 3.44.9 两条线的最后正式版本都在 2026-11-13；`1.0.2` 属于更早的中间版本。

## 参与开发的 HarmonyOS 环境准备

HarmonyOS 构建需要单独的 Flutter-OH SDK，与官方 Flutter 并存，不能共用同一份 checkout 与同一份 `.dart_tool`。

1. 安装 DevEco Studio 26.0.0 Release 与 Command Line Tools 26.0.0 Release。
2. 获取 Flutter-OH SDK：

```bash
git clone -b oh-3.44.9-release https://gitcode.com/CPF-Flutter/flutter_flutter.git
cd flutter_flutter
./bin/flutter --version
```

3. 配置构建环境（macOS 示例，Windows 换成 DevEco 的对应目录并追加到系统环境变量）：

```bash
export DEVECO_SDK_HOME="<DevEco>/Contents/sdk"
export PATH="<DevEco>/Contents/tools/hvigor/bin:<DevEco>/Contents/tools/ohpm/bin:<DevEco>/Contents/tools/node/bin:<DevEco>/Contents/sdk/default/openharmony/toolchains:$PATH"
```

4. 首次使用与切换版本后：

```bash
./bin/flutter precache --ohos
./bin/flutter pub get
./bin/flutter build hap --release
```

5. 检查 `ohos/local.properties` 的 `flutter.sdk`、`hwsdk.dir`、`nodejs.dir` 指向本机实际路径。该文件为本地配置，不随仓库分发。

6. 每次换 SDK 构建前重新执行 `pub get`，并在切换版本时清理 `flutter clean`、`.dart_tool/flutter_build`、`build/ohos`、`ohos/.hvigor`、`ohos/entry/build`。两套 SDK 的 `package_config.json` 互相覆盖，混用会让 framework 指向另一套 SDK。

版本标签缺失时，`flutter --version` 会按距离最近的标签推算版本号，显示结果与目标版本不一致。这种情况下在本机 SDK 仓库的 HEAD 建同名标签，再删除 `bin/cache/flutter.version.json` 与仓库根目录的 `version` 文件重新生成。

## 参考文档

- Flutter OH 环境搭建：`docs/ohos/getting-started/flutter-oh-env-setup.md`
- Flutter OH 版本升级指导：`docs/ohos/version/flutter-oh-upgrade-guide.md`，其中明确 Flutter-OH 未适配 `flutter upgrade`，切换版本必须用 `git checkout`
- Flutter OH 应用构建指导：`docs/ohos/app-development/flutter-oh-app-build-guide.md`
- 三方库适配情况：`ThirdpartyLibrarites.md`（`OpenHarmony-Flutter/docs` 仓库）
- 版本发布说明：SDK 仓库 `release-notes/` 目录下的 `Flutter <版本>+ohos <OHOS 版本> ReleaseNote.md`

## macOS 与官方 Flutter 并存

推荐保留官方 Flutter 与 Flutter-OH 两套 SDK：

```bash
flutter --version
/Volumes/FanXiangMac/DevTools/Flutter_HMOS/flutter_flutter/bin/flutter --version
```

日常 Android/iOS/macOS/Windows/Linux 开发继续使用官方 `flutter`。HarmonyOS 构建必须使用 Flutter-OH，避免把官方 Flutter 的 `.dart_tool`、构建缓存和 OHOS 构建混用。

本机可以通过 shell 函数包装：

```bash
hflutter build hap --release
```

但文档和 CI 脚本应始终支持完整路径命令，避免依赖个人 shell 配置。

## Windows 构建方式

Windows 不要求配置 `hflutter` 函数，直接使用 Flutter-OH 的 `flutter.bat`：

```powershell
D:\Huawei\Flutter\flutter_flutter\bin\flutter.bat --version
D:\Huawei\Flutter\flutter_flutter\bin\flutter.bat pub get
D:\Huawei\Flutter\flutter_flutter\bin\flutter.bat build hap --release
```

同时检查 `ohos\local.properties`：

```properties
flutter.sdk=D:\\Huawei\\Flutter\\flutter_flutter
hwsdk.dir=D:\\Huawei\\DevEco Studio\\sdk
nodejs.dir=D:\\Huawei\\DevEco Studio\\tools\\node
```

`pubspec.lock` 必须随仓库一起使用。不要在排障时随意删除 lock 或升级依赖，否则可能把 `chewie`、`xterm`、`syncfusion_flutter_pdfviewer` 等包带到未验证版本，引发新的 `TargetPlatform.ohos` 编译错误。

## 常用清理与重建

```bash
hflutter clean
rm -rf .dart_tool/flutter_build build/ohos ohos/.hvigor ohos/entry/build
hflutter pub get
hflutter build hap --release
```

Windows 对应 PowerShell：

```powershell
D:\Huawei\Flutter\flutter_flutter\bin\flutter.bat clean
Remove-Item -Recurse -Force .dart_tool\flutter_build, build\ohos, ohos\.hvigor, ohos\entry\build -ErrorAction SilentlyContinue
D:\Huawei\Flutter\flutter_flutter\bin\flutter.bat pub get
D:\Huawei\Flutter\flutter_flutter\bin\flutter.bat build hap --release
```

## TargetPlatform.ohos 编译错误

典型错误：

```text
The type 'TargetPlatform' is not exhaustively matched by the switch cases
since it doesn't match 'TargetPlatform.ohos'.
```

处理顺序：

1. 确认正在使用仓库内 `pubspec.lock`，未隐式升级依赖。
2. 确认 Flutter-OH revision 与已验证基线一致，或记录最新 revision。
3. 如果错误来自项目代码，在 `switch (TargetPlatform)` 中增加 `default` 或显式 OHOS 兼容分支。
4. 如果错误来自第三方包，优先 pin 回 lock 中已验证版本；必要时使用项目自有 facade 或 ArkTS bridge 绕开该插件能力。

当前项目已经为 OHOS 增加 `PlatformCapabilities` 与 `onepanel/ohos_platform` 通道。业务层不得直接散落裸 `MethodChannel`。

## 项目 OHOS Platform Bridge

ArkTS 插件目录：

```text
ohos/entry/src/main/ets/plugins/
```

已注册兼容插件：

- `OhosSharedPreferencesPlugin`
- `OhosPathProviderPlugin`
- `OhosSecureStoragePlugin`
- `OhosPackageInfoPlugin`
- `OhosLocalAuthPlugin`
- `OhosPlatformPlugin`

Flutter 侧 facade：

- `PlatformFileService`
- `PlatformDiagnosticsService`
- `PlatformDownloadService`
- `PlatformMediaService`
- `OhosPlatformChannel`

当前 `OhosPlatformPlugin` 覆盖运行信息、文件保存、路径打开等基础能力。后续文件选择、系统分享、下载任务、媒体预览、终端 I/O、生物认证真机能力继续在该 bridge 下扩展。

## 侧载说明

开发者签名 HAP 位于：

```text
build/ohos/hap/entry-default-signed.hap
```

分发给真机用户时必须同时标注：

- Git commit
- Flutter-OH 版本与 framework revision
- DevEco SDK API 版本
- HAP 文件名和大小
- 已知限制与验证清单

真机验收最小清单：

- 添加服务器成功
- 清后台后重启，当前服务器与 API key 可恢复
- 请求头仍生成 `1Panel-Token` / `1Panel-Timestamp`
- 文件页可加载
- 应用日志可导出并返回有效路径
- 反馈模板包含 HarmonyOS 设备与构建字段

## 401 排障

如果清后台重启后出现 401：

1. 先导出应用日志，确认是否出现 secure storage 或 shared preferences 读取失败。
2. 检查当前服务器 ID 是否恢复，`api_configs` 中不应持久化明文 `apiKey`。
3. 检查 secure store / OHOS fallback 是否能读取对应 key。
4. 检查请求是否带有 `1Panel-Token` 和 `1Panel-Timestamp`。
5. 如果返回 HTML 401，优先排查反代路径、API 网关或登录页重定向。
6. 如果时间偏差超过 5 分钟，校准设备和服务器时间。
7. 检查 1Panel API key 是否重置、IP 白名单是否允许手机网络出口。

反馈时请提供：HAP commit、Flutter-OH 版本、设备型号、系统版本、复现步骤、是否清后台重启、脱敏日志与截图。
