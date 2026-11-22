# 接口适配临场判断指引（unmapped / ④⑤ 围栏适配建议）

> 读者：运行本 Skill 的 agent（编排方或使用方）。触发条件：bridge 产物 `unmapped_native_apis` 非空，
> 或④⑤围栏 TODO 需要适配方案时。目标：**agent 临场给出高质量适配建议 → 开发者逐项拍板 → 按决策落地**
> （落地两档：写围栏注释，或应开发者要求代填围栏内实现并编译验证，见 §二A/§二B）。
> 红线：本指引不回写 Skill 内任何规则文件；未过证据校验的候选不得标"已验证"；**未经开发者明确要求，
> agent 不得擅自生成可编译实现**——明确要求时代码必须落围栏内、过编译自检、diff 呈报确认（§二B）。

## 一、判断框架（四步）

### 第 1 步：接口语义归类

| 类别 | 典型 | 适配难度特征 |
|---|---|---|
| 系统服务 | 电量/传感器/定位/剪贴板/通知 | 多有直替或近似 API |
| 平台硬件 | 蓝牙/摄像头/NFC/电话 | 签名差异大，常需换算或库替代 |
| UI 能力 | 组件/动效/窗口 | ArkUI-X 大多已覆盖，残余多走裁剪 |
| 三方闭源生态 | HMS ScanKit/Push | 官方跨平台 SDK 或开源库替代 |
| 纯业务逻辑 | 自有协议/算法 | 直接迁 .ets，无需桥接（检查是否误入③④） |

### 第 2 步：四条适配路径

| 路径 | 判断要素 |
|---|---|
| **等价直替** | 双平台均有同名同义 API，签名/量纲/返回语义对齐——证据齐全可直接建议 |
| **近似 + 换算** | 能力相近但签名/量纲/语义有差——**必须逐项列换算要点与边界差异**（如电量 0~1 vs 百分比） |
| **平台库替代** | 系统无、成熟库有（zxing 替 ScanKit、MLKit 替识图）——列库坐标/引入方式与许可证 |
| **裁剪降级** | 无可行等价——给降级 UX 建议（入口隐藏/提示语/平台判断跳过） |

### 第 3 步：证据红线（防幻觉）

候选 API **必须过存在性校验**后才能标"已验证"，二选一：

```bash
# Android：本地 android.jar 符号校验（SDK 路径按本机调整，取 platforms 最高版本）
javap -classpath ~/Library/Android/Sdk/platforms/android-35/android.jar android.content.Intent
javap -classpath .../android.jar android.telephony.TelephonyManager 2>&1 | grep getCallState

# iOS：Xcode SDK 头文件 grep
grep -rn "openURL" /Applications/Xcode.app/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/UIKit.framework/Headers/UIApplication.h
```

- 引用官方文档页（developer.android.com / developer.apple.com 具体页面）同等有效。
- **禁止凭记忆断言"应该有"**；未验证候选一律标 `未验证` 并注明原因。

### 第 4 步：标准呈报表（对话呈报，开发者逐项拍板）

| 字段 | 说明 |
|---|---|
| 接口 | `@模块::符号`（源调用形态） |
| 候选 API | 双平台各一列，含类#方法/URL Scheme |
| 路径 | 直替 / 近似+换算 / 库替代 / 裁剪 |
| 等价度 | 等价 / 近似 / 部分（能力清单差异） |
| 换算要点 | 参数/量纲/返回语义差异逐项 |
| 风险 | 权限、系统版本、审核政策（如 iOS 电话） |
| 证据 | 已验证（javap/文档页）/ 未验证 |
| 建议 | agent 倾向 + 理由一句 |
| 决策 | ☐直替 ☐近似 ☐库替代 ☐裁剪（开发者勾选） |

## 二、拍板后落地动作（两档，按开发者要求选）

### 二A. 默认档：决策落围栏注释

- **直替/近似/库替代**：agent 把决策（候选 API + 换算要点）写入对应④⑤文件的 `ARKUIX-BRIDGE-HANDOFF` 围栏**内**注释（围栏是手改区，增量再生成保留）；平台实现仍由开发者完成。
- **裁剪**：走 F4 决策项（`--answer bd:<接口>=裁剪`）重跑编排， 自动改写源码。

### 二B. 代填档：开发者明确要求 agent 同时生成实现（建议→填入→编译验证→diff 确认）

开发者拍板并明确要求代填（如"按这个决策把实现写掉"）时，agent 按四步执行：

1. **按决策生成实现**——只写入围栏 `BEGIN/END` 之间（手改区，增量再生成保留）；签名沿用①契约派生的现有方法头，不改围栏外骨架；涉及新 import 写入围栏内注释声明的位置或文件头（与围栏外生成区冲突时呈报开发者而非绕开）。
2. **编译自检**——生成后必须实际编译验证，不得以"应该能编译"收工：
   ```bash
   # Android 侧（或整体）：在 scaffold 输出根目录
   JAVA_HOME=<jdk17> ace build apk
   # 已知环境坑防护：
   #   ① gradle.properties 追加 org.gradle.java.home 须防无尾换行粘连
   #   ② Android Studio JBR(Java 25) 常驻 GradleDaemon 被复用 → class file 69：
   #      pkill -f org.gradle.launcher.daemon.bootstrap.GradleDaemon && rm -rf .hvigor
   # 验收线：ArkTS 零 Error Message + APK 产出（产物判定，不信 exit code——ace 失败仍 exit 0）
   ```
3. **diff 呈报**——逐文件列出围栏内新增代码（接口/平台/要点一行摘要），标注编译结果；运行时仍未验证的部分（真机行为/权限弹窗）显式声明。
4. **开发者确认**——开发者 review diff 后收工；要求修改则回到第 1 步。

### 代填示例：telephony.call（接 §三 示范的拍板结果）

Android ④围栏内（按拍板：ACTION_DIAL 免权限 + ActivityNotFoundException 表达失败）：

```java
// ARKUIX-BRIDGE-HANDOFF BEGIN
// 降级说明：拨号 UI 层等价（Android Intent.ACTION_CALL / iOS tel: URL+CallKit 受限）；通话状态等高级能力无等价
// 【开发者已拍板+要求代填 2026-10-12】dial → ACTION_DIAL（免 CALL_PHONE 权限）；失败经 ActivityNotFoundException 回调
    public String call(String p0) {
        try {
            android.content.Intent intent = new android.content.Intent(
                android.content.Intent.ACTION_DIAL, android.net.Uri.parse("tel:" + p0));
            getContext().startActivity(intent);
            return "true";
        } catch (android.content.ActivityNotFoundException e) {
            return "false";
        }
    }
// ARKUIX-BRIDGE-HANDOFF END
```

iOS ⑤围栏内（.m，tel: URL 拨号盘跳转）：

```objc
// ARKUIX-BRIDGE-HANDOFF BEGIN
// 【开发者已拍板+要求代填 2026-10-12】dial → tel: URL（拨号盘跳转，免 CallKit 审核）
- (NSString*)call:(NSString*)p0 {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", p0]];
    BOOL ok = [[UIApplication sharedApplication] openURL:url];
    return ok ? @"true" : @"false";
}
// ARKUIX-BRIDGE-HANDOFF END
```

编译自检记录（随 diff 呈报）：

```
ace build apk → BUILD SUCCESSFUL；Error Message=0；app-release.apk 产出 ✅
运行时注记：Android 实机拨号盘拉起、iOS 弹确认框——需真机回归（agent 未验证）
```

## 三、示范：@ohos.telephony.call（真实桥接产物 + 呈报表）

源工程调用：`import { call } from '@ohos.telephony.call'; call.dial('10086', cb); call.hasCallCapability();`
F2 判定：④degraded_bridge（"拨号 UI 层等价（Android Intent.ACTION_CALL / iOS tel: URL + CallKit 受限）；通话状态/录音管理等高级能力无等价"）。F3 已生成五件套，④围栏内自动带入上述降级说明。

### 呈报表（agent 产出 → 开发者拍板）

| 字段 | 内容 |
|---|---|
| 接口 | `@ohos.telephony.call::call`（dial / hasCallCapability） |
| Android 候选 | `Intent(ACTION_DIAL, Uri.parse("tel:10086"))` + `startActivity`（免权限）；`ACTION_CALL` 需 `CALL_PHONE` 权限 |
| iOS 候选 | `UIApplication.openURL(URL(string:"tel:10086")!)`（拨号盘跳转）；直接呼叫需 CallKit 且 App Store 审核受限 |
| 路径 | **近似+换算**（dial）/ **裁剪**（hasCallCapability） |
| 等价度 | 部分：dial=拉起系统拨号 UI 等价；通话状态管理无等价 |
| 换算要点 | OH `dial(number, callback)` 的布尔返回 → Android `startActivity` 无同步返回，以 `ActivityNotFoundException` try-catch 表达失败；iOS `openURL` 返回 `Bool` 可对齐回调 |
| 风险 | iOS 直拨（不走拨号盘）需 CallKit 权限与审核说明；Android ACTION_CALL 需运行时权限 |
| 证据 | 已验证：`javap -classpath android.jar android.content.Intent` ✅；UIKit `openURL:` 头文件 ✅ |
| 建议 | dial 走 ACTION_DIAL/tel: URL（免权限、双平台行为一致）；hasCallCapability 裁剪为平台判断 |
| 决策 | ☐直替 ☑近似+换算 ☐库替代 ☑裁剪(hasCallCapability) |

### 拍板后④围栏内注释（默认档落地形态；代填档的完整代码示例见 §二B）

```java
// ARKUIX-BRIDGE-HANDOFF BEGIN
// 降级说明：双源一致（SDK 无标记 + 规则表）: 拨号 UI 层等价（Android Intent.ACTION_CALL / iOS tel: URL+CallKit 受限）；通话状态/录音管理等高级能力无等价
// 【开发者已拍板 2026-10-12】dial → Intent(ACTION_DIAL, Uri.parse("tel:"+p0))，startActivity 外层 try-catch(ActivityNotFoundException) 回调失败；
//   不用 ACTION_CALL（免 CALL_PHONE 权限）；hasCallCapability → 裁剪（调用方平台判断）
// TODO(ARKUIX-BRIDGE): interface=CallCall platform=android category=degraded_bridge — 按上述决策实现
// ARKUIX-BRIDGE-HANDOFF END
```

## 四、证据校验实测记录（本示范）

```bash
$ javap -classpath ~/Library/Android/Sdk/platforms/android-35/android.jar android.content.Intent
class android.content.Intent { ... public static final String ACTION_DIAL ... }   # ✅
$ grep -c "openURL" .../UIKit.framework/Headers/UIApplication.h
1                                                                                  # ✅
```
