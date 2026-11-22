# 悬停态适配验证

命令基于 foundation/window/window_manager 的 `ScreenSessionDumper`（`window_scene/screen_session_manager/src/screen_session_dumper.cpp`）。**执行任何修改设备状态的命令前先征得用户同意；验证后恢复设备物理状态。**

## 1. 前置确认

```bash
hdc list targets                      # 设备连接
hdc shell param get const.security.developermode.state   # 开发者模式（-z/-y/-p 需要）
hdc shell param get dms.hidumper.supportdebug            # -ln 强制设定需要，false 时先开
```

## 2. 模拟折叠形态（核心手段）

SA 说明：合一架构下 ScreenSessionManager 的 dump 由 SA 4607（`libscreen_session_manager.z.so`）承载；部分版本也可用名称调用；分离架构走 DMS 3308。若 `-s 4607` 无输出，先跑帮助命令确认入口。

```bash
# 查看帮助（确认 dump 入口与参数可用性）
hdc shell hidumper -s 4607 -a "-h"

# —— 开发者模式命令（const.security.developermode.state = true）——
hdc shell hidumper -s 4607 -a "-z"    # 切换到半折叠(HALF_FOLD) ← 悬停态测试用这条
hdc shell hidumper -s 4607 -a "-y"    # 展开(EXPAND)
hdc shell hidumper -s 4607 -a "-p"    # 折叠(FOLDED)
hdc shell hidumper -s 4607 -a "-yy"   # 双轴全展开（三折设备）

# —— 调试参数命令（需 dms.hidumper.supportdebug = true）——
hdc shell param set dms.hidumper.supportdebug true        # 临时开启（如默认 false）
hdc shell hidumper -s 4607 -a "-ln,3"  # 强制设定为 HALF_FOLD 并锁定（不受物理折叠影响）
hdc shell hidumper -s 4607 -a "-un"   # 恢复物理折叠状态（验证完必须执行）
hdc shell hidumper -s 4607 -a "-l"    # 锁定当前折叠状态
hdc shell hidumper -s 4607 -a "-u"    # 解锁
```

FoldStatus 数值映射（`-ln,<value>`）：`1`=EXPAND、`2`=FOLDED、`3`=HALF_FOLD、`11/21/12/22/13/23`=双轴组合态。

注意：

- `-z` 走 `NotifyFoldStatusChanged`，设备需支持对应形态（非折叠屏报错属预期）。
- `-ln,3` 锁定后物理折叠不再改变状态，适合稳定复现；**用完务必 `-un` 恢复**。
- 不同产品分支 SA 号可能不同；`-s 3308`（DMS）在分离架构设备上等价。

## 3. 状态与日志观测

```bash
# dump 全部屏幕信息（折叠状态、折痕等）
hdc shell hidumper -s 4607 -a "-a"

# 实时日志：悬停态翻转与事件分发（TAG: WMS_ATTRIBUTE / DEFAULT）
hdc shell hilog | grep -iE "HoverState|PostureMode|hoverState"

# 应用内自查（临时埋点或调试工具里）
#   display.getFoldStatus()          → 3 表示 HALF_FOLD
#   win.isInWindowPostureMode(...)   → 标准路径下与日志一致
#   display.getDefaultDisplaySync().getLiveCreaseRegion().creaseRects → 折痕坐标
```

**页面内验证徽标（推荐）**：在操作区顶部加状态徽标行——`悬停模式/常规模式` 徽标 + `折痕上沿 Xvp · 避让带 Yvp` 数值，真机反复折叠/旋转时直读布局事实源，反馈循环最直观（发布前移除）。

## 4. 边界用例清单

按序执行并记录结果（✅/❌/N/A）：

| # | 用例 | 操作 | 预期 |
| --- | --- | --- | --- |
| 1 | 初始态查询 | 全屏应用启动于悬停形态 | `isInWindowPostureMode` = true |
| 2 | 进入悬停 | 全屏应用下 `-z` | 回调 true，UI 切上下分区 |
| 3 | 退出悬停 | 悬停态下 `-y` | 回调 false，UI 恢复 |
| 4 | 折叠不触发 | 全屏应用下 `-p` | **无回调**（FOLDED 非 HALF_FOLD） |
| 5 | 非全屏不触发 | 分屏/悬浮窗下 `-z` | 无回调（系统判定不满足） |
| 6 | 重复进出 | `-z` → `-y` 快速交替 ≥3 次 | 事件成对、无丢失、无重复同值 |
| 7 | 事件顺序 | 进入悬停时观察窗口尺寸事件 | 布局变化与悬停回调先后稳定，无布局抖动残留 |
| 8 | 折痕避让 | 进入悬停后检查 UI | 折痕带内无可交互/文字元素 |
| 9 | 页面切换 | 悬停态下跳转新页面再返回 | 监听不重复注册、状态正确恢复 |
| 10 | 后台返回 | 悬停态下应用退后台再回前台 | 状态与 UI 一致 |
| 11 | 降级路径 | （降级方案）重复 1–6 | foldStatus 推断行为一致，无崩溃 |
| 12 | 恢复现场 | `-un` 解除锁定 | 物理折叠状态恢复正常响应 |
| 13 | 横屏悬停进入（书本型核心场景） | 横屏窗口（系统旋转或手动全屏）下 `-z` 或物理半折叠（铰链水平） | 回调 true，UI 切上下分区；**不得因横屏方向压制悬停布局** |
| 14 | 悬停 × 旋转退出 | 悬停态下旋转至折痕相对窗口为纵向（如书本型转竖屏）或展平 | 回调 false，UI 平滑回横屏/常规布局，无悬停布局残留 |
| 15 | 手动全屏 × 半折叠 | 竖屏半折叠（书本形态）下调 `setPreferredOrientation(LANDSCAPE)` | 产品允许旋转时：窗口转横屏 → 折痕转横向 → 进入悬停态；旋转被产品锁定时 no-op 不崩溃 |
| 16 | 系统栏避让动态刷新 | 页面内旋转（横↔竖）/ 折叠展开 / 进出悬停后检查 HUD 与底部操作区 | 交互/HUD 元素不被状态栏、导航指示条遮挡；一次性查询过期即本用例失败（`avoidAreaChange` 生效，见 adaptation-patterns.md 第 9.3 节） |

方向性说明：书本型折叠屏竖屏半折叠（折痕纵向）系统**不进入**悬停态属预期行为（用例 13 的镜像场景）；应用侧不要为该形态自行推断"悬停"与系统判定打架。涉及旋转的应用按 adaptation-patterns.md 第 8 节实现三态优先级，用例 13–15 必测。

## 5. 无真机时的静态验证

无法连接设备时，至少完成：

1. 代码走查：对照 api-reference.md 核对 API 名称/参数/错误处理（尤其 mode 参数与 off 对称解注册）。
2. SDK 声明检查：`grep -r "WindowPostureMode" <SDK>/ets/api/`，确认导入可编译。
3. 边界逻辑审查：非折叠屏分支、API 缺失分支、折痕数据缺失兜底分支均有处理。
4. 明确报告"未在真机验证"，列出待验证用例（上表）。

## 6. 报告要求

验证结果按用例表逐项给出：命令、现象（日志摘录/截图说明）、结论。出现"预期触发但未触发"时，按 wms-internals.md 第 8 节排查决策树逐项归因后记录。
