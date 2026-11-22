# 固定旋转策略改造为智感旋转策略（项目扫描与迁移指南）

存量应用若使用**固定方向策略**（`PORTRAIT`/`LANDSCAPE` 等），无法参与智感旋转。本文提供「扫描 → 评估 → 改造 → 验证」四步流程，将固定策略改造为支持智感旋转的**自动旋转类策略**。

改造后收益：OH 7.0.0+ 支持智感传感器的设备上自动获得智感旋转体验；不支持时自动回退重力传感器旋转，一套代码全设备覆盖。

## 第一步：扫描当前项目

固定策略只有两个来源：module.json5 静态配置、运行时 API 调用。两者都要扫。

### 1.1 扫描 module.json5 静态配置

用 Grep 工具（或 `rg`）搜索：

```
pattern: "orientation"\s*:
include:  module.json5
```

命令行等价：

```bash
rg -n '"orientation"\s*:' --glob '**/module.json5'
```

命中行形如 `"orientation": "portrait"`，按取值分类：

| module.json5 取值 | 分类 | 是否改造候选 |
| --- | --- | --- |
| "portrait" / "landscape" / "portrait_inverted" / "landscape_inverted" | **固定方向**，不跟随传感器 | ✅ 改造候选 |
| "unspecified" | 未定义（默认），系统判定；OH 7.0.0+ 参与智感旋转；直板机默认竖屏不可旋转 | ❌ 已支持智感，无需改造（直板机如需旋转再显式改 auto 类） |
| "locked" | 锁定模式，不跟随传感器 | ⚠️ 按业务评估 |
| "follow_desktop" | 跟随桌面方向，OH 7.0.0+ 参与智感旋转 | ❌ 已支持智感，无需改造 |
| "auto_rotation" 及 "auto_rotation_*"（含 restricted/unspecified） | 自动旋转类 | ❌ 已支持智感，无需改造 |
| "user_rotation_*" | 临时方向类 | ❌ 已支持智感，无需改造 |

### 1.2 扫描运行时 API 调用

```
pattern: setPreferredOrientation
include:  *.ets, *.ts
```

命令行等价：

```bash
rg -n 'setPreferredOrientation' --glob '*.ets' --glob '*.ts'
```

命中行形如 `win.setPreferredOrientation(window.Orientation.PORTRAIT)`，按枚举分类（分类结论同上表，枚举名大写驼峰）。可进一步精确扫描固定方向调用：

```bash
rg -n 'setPreferredOrientation(WithResult)?\(\s*window\.Orientation\.(PORTRAIT|LANDSCAPE|PORTRAIT_INVERTED|LANDSCAPE_INVERTED)\b' --glob '*.ets' --glob '*.ts'
```

### 1.3 输出扫描清单

汇总为报告（文件:行号 → 策略 → 分类 → 建议），模板：

```markdown
| # | 位置 | 当前策略 | 分类 | 改造建议 |
| --- | --- | --- | --- | --- |
| 1 | entry/src/main/module.json5:12 | "portrait"（静态） | 固定方向 | 改为 "auto_rotation_portrait_restricted" |
| 2 | ets/pages/Video.ets:58 | LANDSCAPE（运行时，全屏时设置） | 固定方向 | 改为 USER_ROTATION_LANDSCAPE |
```

> 注意：module.json5 与运行时两处可能同时存在（运行时覆盖静态），**改造时两处都要改**，避免遗漏一处导致行为不一致。

## 第二步：逐项评估是否可改造

不是所有固定策略都应改造，先过决策清单：

1. **业务是否真的需要固定方向？** 游戏、相机取景等强依赖固定布局的场景应保持固定策略（无法参与智感旋转属预期行为），在报告中标注"保持不变"。
2. **布局能否响应方向变化？** 固定 → 自动后，方向会随握持变化，UI 必须适配两个（竖向类：竖屏/反向竖屏）或四个方向。检查：
   - 写死的宽高假设（如假设 `宽 < 高`）、绝对定位；
   - 使用断点（`WidthBreakpoint`，600/0.8 边界值）、`on('windowSizeChange')`、Grid/RelativeContainer 等响应式手段替代；
   - 摄像机预览、Canvas、手势坐标系等对反向方向（反向竖屏/反向横屏）敏感的逻辑。
3. **逻辑是否依赖方向恒定？** 若代码假设当前方向固定（如启动时判断一次），需改为监听 `rotationChange`/`windowSizeChange` 动态响应。

## 第三步：按映射表改造

| 原固定策略 | 业务诉求 | 改造目标（静态 / 运行时一致） | 行为变化 |
| --- | --- | --- | --- |
| "portrait" / PORTRAIT | 竖向页面希望跟随握持 | "auto_rotation_portrait_restricted" / `AUTO_ROTATION_PORTRAIT_RESTRICTED` | 竖屏 ⇄ 反向竖屏，受旋转锁定开关控制 |
| "landscape" / LANDSCAPE | 横向页面希望跟随握持 | "auto_rotation_landscape_restricted" / `AUTO_ROTATION_LANDSCAPE_RESTRICTED` | 横屏 ⇄ 反向横屏，受旋转锁定开关控制 |
| "portrait" / "landscape" | 不限方向、四方向自由跟随 | "auto_rotation_restricted" / `AUTO_ROTATION_RESTRICTED` | 四方向旋转，受旋转锁定开关控制 |
| "landscape"（进视频全屏时设置） | 立即横屏且后续跟随握持 | "user_rotation_landscape" / `USER_ROTATION_LANDSCAPE` | 临时横屏后自动旋转（含智感），不再锁死横屏 |
| 任意固定策略 | 必须固定（游戏/取景器等） | **保持不变** | 不参与智感旋转，属预期 |

> 不希望受旋转锁定开关控制的场景，选不带 RESTRICTED 的 `AUTO_ROTATION`/`AUTO_ROTATION_PORTRAIT`/`AUTO_ROTATION_LANDSCAPE`（含义差异见 [orientation-strategies.md](orientation-strategies.md)）。

### 改造前后对比示例

静态配置：

```json5
// module.json5 → abilities
// 改造前（固定竖屏，不参与智感旋转）
"orientation": "portrait"
// 改造后（竖向跟随传感器，OH 7.0.0+ 参与智感旋转）
"orientation": "auto_rotation_portrait_restricted"
```

运行时（普通页面）：

```typescript
// 改造前
mainWindow.setPreferredOrientation(window.Orientation.LANDSCAPE);
// 改造后
mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_LANDSCAPE_RESTRICTED);
```

运行时（视频进全屏）：

```typescript
// 改造前（锁死横屏，退出全屏前方向不变）
mainWindow.setPreferredOrientation(window.Orientation.LANDSCAPE);
// 改造后（立即转横屏，之后跟随握持，支持智感旋转）
mainWindow.setPreferredOrientation(window.Orientation.USER_ROTATION_LANDSCAPE);
// 退出全屏时恢复竖向跟随
mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_PORTRAIT_RESTRICTED);
```

## 第四步：验证

| 验证项 | 方法 / 预期 |
| --- | --- |
| 智感旋转生效 | OH 7.0.0+ 支持智感传感器的设备，开启 设置 > 系统 > 智感旋转，改变握持姿态，方向跟随应更精准 |
| 不支持设备回退 | 无智感传感器/未开启开关的设备，重力传感器跟随正常 |
| 旋转锁定交互 | 控制中心开启旋转锁定：RESTRICTED 类固定在锁定方向（重力、智感均不跟随）；关闭后恢复 |
| 方向覆盖 | 竖向类确认反向竖屏、横向类确认反向横屏下布局正常 |
| 特殊场景 | 分屏/智慧多窗悬浮窗/自由多窗/后台：策略被系统忽略（方向不变）属预期，用 `setPreferredOrientationWithResult` 返回 IGNORED/PENDING 可确认 |
| 行为限制 | 仅主窗口生效；无传感器设备（TV 等）不生效 |

## 回滚策略

改造仅涉及策略枚举值的替换，回滚成本低：保留原策略值于扫描清单中，逐项还原即可。建议改造前后各执行一次第一步的扫描，确认无遗漏的固定策略残留。
