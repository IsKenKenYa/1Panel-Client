# 碰一碰 API 要点

## 能力与版本

| 项 | 值 |
|----|-----|
| SysCap | `SystemCapability.Collaboration.HarmonyShare` |
| `on/off('knockShare')` | 起始 **6.0.0(20)** |
| 2in1 `windowId` | **6.0.0(20)** |
| `dataReceive` | 文件侧；模板按 **6.0.2(22)** |
| `clarifyNonShare` | **6.0.2(22)+** |
| `getInfo().coordinate` | API **26.0.0** 字面量检测，仅文件侧精准命中 |

检测：`canIUse('SystemCapability.Collaboration.HarmonyShare')`  
精准命中：`deviceInfo.apiAvailable('26.0.0')`（**必须字面量**，禁止变量间接传入）

本 Skill 注入时的 SDK 下限（与上表起始版本对齐后的交付档）：

| 本次接入 | 工程目标 |
|----------|----------|
| 仅链接 | **API 20+**（`6.0.0(20)`）；20 上无内容用 `reject`，不用 `clarifyNonShare` |
| 含文件、不要精准 | **API 22+**（`6.0.2(22)`）；文件侧不要落到 20 |
| 含文件、要精准 | **API 26+**，写入 **`"26.0.0"`**（SemVer；见 [sdk-version.md](sdk-version.md)） |

## 注册 / 注销

手机/平板：`harmonyShare.on('knockShare', cb)` / `off('knockShare')`  
2in1：带 `{ windowId }`。可分享页显示时 `on`，隐藏时 `off`。

## 回调内尽快结束

约 3 秒内：`share`（有内容）/ `clarifyNonShare`（无内容，6.0.2+）/ `reject`（异常或旧 SDK）。  
**不要**把 `clarifyNonShare` 用到隔空传送。

## SharedData

文件：每条 **`utd` + `uri`** 必填；多文件 `addRecord`；不可与链接混传。  
`uri` 必须是可访问的文件 URI；若手头是 path，先 `fileUri.getUriFromPath`。  
具体 path 以宿主为准（`filesDir` / `cacheDir` / 业务子目录 / 选择器 URI 等），**不要照抄示例目录**。  
链接：`utd = HYPERLINK`，`content` 为真实 https App Linking。卡片字段未确认不写。

```ts
const path = /* 替换为宿主真实 path */;
const uri = fileUri.getUriFromPath(path);
new systemShare.SharedData({ utd, uri });
// 链接
new systemShare.SharedData({
  utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
  content: 'your uri'
});
```

资产按 Q1：`assets/file` / `assets/link` / `assets/both`。接线只打开对应的 `wiring-snippet-file|link|both.ets`，不要拷进工程。  
`getFileShareData` / `getLinkShareData` 返回 `SharedData | undefined`（对照模板；失败时返回 undefined）。

## 电脑端 dataReceive（仅文件）

仅 2in1；`maxSupportedCount` ≤ 5；`off` 与 `on` 同一 `windowId` + **同一** `capabilities`。  
未注册 `dataReceive`、碰的不是该应用窗口、或电脑不在已 `enable(pcReceive)` 的页面时：文件走系统图库/文件管理，**不会**进应用沙箱。

**发送与接收监听必须一致**：`capabilities.utd` 与 `getFileShareData` 每条记录的 `utd` 用同一套规则（Q3 确认的那些）。对不上则系统回退默认接收，`receive()` / `onDataReceived` 都不会走。  
Q7=yes 时由宿主 `getReceiveCapabilities()` 按发送侧同样的 utd 声明；Manager 不内置某几种类型。

插入页面数据时：`onDataReceived` 里改 `@State` 须 `UIContext.runScopedTask`（或 `AppStorage`）。  
`insertIndex` 是命中下标。宿主按确认的落点策略解释。未确认不要写死某一种插入写法。

## 精准碰一碰（仅文件，API 26+ 2in1）

`target.getInfo().coordinate`；可命中项 `.id()`。  
**先** `getFileShareDataAt`；未命中再 `getFileShareData`；两者都没有才 `clarifyNonShare`。  
不要为走精准而让 `canShare()` 在 2in1 上恒为 false。  
Q7+Q8 都 yes 时：先读宿主实际 UI 再确认接收落点（选项从该结构推导，含自定义）；`hitTestReceiveIndex` 只返回命中项，插入由页面按确认策略做。

系统 Kit，一般无需改 `oh-package.json5` 第三方依赖。
