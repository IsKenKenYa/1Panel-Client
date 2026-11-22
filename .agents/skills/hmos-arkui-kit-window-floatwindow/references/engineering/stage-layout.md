# Stage 工程落点（写程序必读）

权威：[构建第一个 ArkTS 应用（Stage）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/start-with-ets-stage)、[应用程序包结构](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-package-structure-stage)。本页是摘要，不是官网全文。不要用 JS Lite / FA / `config.json`。

仅 Stage 单模块。不生成 HAP/HAR/HSP、hvigor、Native 工程。

## 目录（Empty Ability）

```text
Project/
├── AppScope/
│   └── app.json5                          # bundleName / 版本；写悬浮窗一般不改
├── entry/                                 # 模块名以工程为准，下文用 entry
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/EntryAbility.ets
│   │   │   ├── pages/
│   │   │   │   ├── Index.ets              # 入口；画中画可当宿主，或只做列表
│   │   │   │   ├── PipHost.ets            # 画中画宿主 @Entry（Index 已是列表才建）
│   │   │   │   └── FloatPanel.ets         # 仅闪控窗：setUIContext 加载的页（另一份 @Entry，不是 Index）
│   │   │   ├── xcomponent/Page1.ets       # 画中画视频页：根节点 NavDestination
│   │   │   ├── navigation/Page1.ets       # 仅 typeNode：根节点 NavDestination
│   │   │   ├── util/PipManager.ets        # 官方 typeNode 单例
│   │   │   ├── util/XCNodeController.ets
│   │   │   ├── model/AVPlayer.ets         # 画中画播放器（play/pause/静音）
│   │   │   └── float/PeepGuard.ets        # 仅闪控窗+防窥
│   │   ├── resources/
│   │   │   ├── rawfile/test.mp4           # 画中画片源；没有则黑屏
│   │   │   └── base/
│   │   │       ├── profile/main_pages.json
│   │   │       └── element/string.json    # FLOAT_VIEW 的 reason
│   │   └── module.json5                   # requestPermissions
│   └── build-profile.json5                # 不要编造；用户没要脚手架就别生成
└── build-profile.json5
```

`AppScope` 目录名不要改。模块目录可以不叫 `entry`，落点相对 `src/main/` 不变。

## 改哪些文件

| 路径 | 职责 | 写悬浮窗时 |
|------|------|------------|
| `ets/pages/Index.ets` | `@Entry` 页面 | 球 / 启动闪控窗；画中画可当宿主。已是入口列表则只 `getRouter().pushUrl` 到 `PipHost` |
| `ets/pages/PipHost.ets` | 画中画宿主 `@Entry` | Index 已是列表才建，必须进 `main_pages.json` |
| `ets/model/AVPlayer.ets` | 画中画播放器 | 不要把 AVPlayer 写进页面；须有 `play` / `pause` / `setMuted` |
| `ets/xcomponent/Page1.ets` | XComponent 视频页 | 一镜到底；根节点 `NavDestination()`；不是 `@Entry` |
| `ets/navigation/Page1.ets` | typeNode 视频页 | 迁节点才建；根节点 `NavDestination()` |
| `ets/float/PeepGuard.ets` | 闪控窗防窥 | 含 `showSystemMaskLayer`、`antiPeepCB`；`aboutToAppear` 就监听 |
| `resources/rawfile/test.mp4` | 画中画示例片源 | 默认骨架读这个 rawfile；没有则播放器失败、小窗黑 |
| `ets/pages/FloatPanel.ets` | 闪控窗内容页 | `setUIContext('pages/FloatPanel')` 的目标；也要 `@Entry` |
| `resources/base/profile/main_pages.json` | 页面注册 | 路径须与 `setUIContext` / `loadContent` 的字符串一致，禁止相对路径 |
| `module.json5` | 模块配置 + 权限 | `requestPermissions`；详见 [declare-permissions.md](../permissions/declare-permissions.md) |
| `resources/*/element/string.json` | 字符串 | `FLOAT_VIEW` 的 `reason` |
| 签名 Profile | ACL | 调试签名；详见 [declare-permissions-in-acl.md](../permissions/declare-permissions-in-acl.md) |
| `ets/entryability/EntryAbility.ets` | Ability | `onWindowStageCreate` → `windowStage.loadContent('pages/Index')`。主窗 show 在这之后，不在页面 `aboutToAppear`。防窥：`loadContent` 成功后把主窗写入 `AppStorage` 的 `MAIN_WINDOW` |

`main_pages.json` 示例：

```json
{
  "src": [
    "pages/Index",
    "pages/FloatPanel"
  ]
}
```

`module.json5` 里对应 `"pages": "$profile:main_pages"`。

## 产出规则

默认 **直接改用户工程里的文件**（读现有内容再补丁进去）。禁止只在对话里讲「请把下面代码拷到 Xxx.ets」。对话里可以简述改了哪几处，代码必须以文件修改落地。

禁止往 `window_window_manager/`、`foundation/`、`interface/` 等框架源码里写应用 ArkTS。本 Skill 只改 **应用工程**。

1. **已有应用工程且 `ets/pages/*.ets` 在**：按 [merge.md](../../assets/merge.md) 改现有文件。画中画按 [pip.md](../../assets/pip.md) 建可加载宿主 + `Page1`。闪控窗没有内容页才 **新建** `FloatPanel.ets` 并登记。闪控球不要新建球页。
2. **用户给了应用路径，且已有 `module.json5` + `main_pages.json`，但 `ets/pages` 为空**：按骨架**补文件**，不要问路径。
3. **找不到应用模块**：没有 `module.json5`（常见：工作区是 OHOS 源码仓、只有 WMS，或 CI 只挂 skill 仓）。**停手问用户应用工程路径**。不要在当前仓根下新建 `entry/`，不要把 demo 写进框架目录，不要假装 `CompileArkTS` 通过。
4. **用户明确只要脚手架、且已给应用路径**：按上表在该路径 **创建** `entry/src/main/...`。只建页面 `.ets` + `main_pages.json` + 权限相关 JSON。不要生成 `oh-package.json5` / 工程级 `build-profile.json5` / 全量脚手架，除非用户明确要工程。
5. 每处修改对应真实路径。不要只丢无路径代码块让用户自己贴。

写完后**自己**在应用工程根打 HAP，编不过不算写完。交卷必须带 `CompileArkTS` 通过；不要让用户去 DevEco 点编译来验你刚写的代码。找不到 `module.json5` 或 `hvigorw`：问路径即可，不要假装编过。

```text
export PATH="<DevEco>/Contents/tools/node/bin:<DevEco>/Contents/tools/ohpm/bin:<DevEco>/Contents/tools/hvigor/bin:$PATH"
export DEVECO_SDK_HOME="<DevEco>/Contents/sdk"
export JAVA_HOME="<DevEco>/Contents/jbr/Contents/Home"
cd <应用工程根> && hvigorw assembleHap -p product=default --no-daemon
```

macOS DevEco 常见根目录：`/Applications/DevEco-Studio.app`。`PackageHap` 报 `Unable to locate a Java Runtime` 时只改 `JAVA_HOME`，**不改业务 ets**。`CompileArkTS` 报错改刚写的 ets 再编。

## 生命周期（和铁律对齐）

| 时机 | 在哪 | 能否 start PiP/窗/球 |
|------|------|----------------------|
| `UIAbility.onCreate` | Ability | 否 |
| `aboutToAppear` | 页面组件 | 否（主窗未必已 show） |
| `onWindowStageCreate` → `loadContent` 完成、主窗前台 | Ability | 可以；推荐按钮 / 主窗已显示后的回调 |
