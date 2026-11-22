# 测试用例 5：扫描项目并改造固定策略为智感旋转策略

## 场景描述
存量应用使用固定方向策略（module.json5 配置 "portrait"/"landscape" 或运行时设置 PORTRAIT/LANDSCAPE），开发者希望扫描项目定位所有固定策略，改造为支持智感旋转的策略并输出改造清单。

## 前置条件
- 存在一个 HarmonyOS 工程，其中包含以下固定策略样本：
  - entry/src/main/module.json5 的 abilities 配置 "orientation": "portrait"
  - 某页面 ets 文件中调用 setPreferredOrientation(window.Orientation.LANDSCAPE)（视频全屏场景）
- AI 代理具备项目文件检索能力（Grep/Glob 工具）

## 执行步骤
1. AI 代理识别"扫描改造"需求，路由至场景 ROT-05，读取 migrate-to-smart-rotation.md
2. 扫描两个来源：
   - module.json5：搜索模式 `"orientation"\s*:`（include: module.json5）
   - 运行时调用：搜索模式 `setPreferredOrientation`（include: *.ets, *.ts）
3. 按分类表归档：固定方向（portrait/landscape/portrait_inverted/landscape_inverted）为改造候选；auto_rotation_*/user_rotation_*/follow_desktop/unspecified 为已支持智感
4. 输出扫描清单报告（文件位置、当前策略、分类、改造建议）
5. 逐项评估：业务是否必须固定（游戏/取景器保持不变）；布局能否响应方向变化
6. 按映射表改造：
   - "portrait" → "auto_rotation_portrait_restricted"（竖向跟随；评估为不限方向时可选 "auto_rotation_restricted"）
   - "landscape"（普通页面）→ "auto_rotation_landscape_restricted"
   - "landscape"（视频进全屏时设置）→ USER_ROTATION_LANDSCAPE
7. 提醒布局与逻辑适配（断点、windowSizeChange、rotationChange）并给出验证清单

## 预期结果
- 两个来源均被扫描，无遗漏
- 扫描清单报告包含每个命中项的位置（文件:行号）、当前策略、分类、建议
- 改造映射正确，静态与运行时两处同时修改（避免一处遗漏导致行为不一致）
- 评估环节区分"可改造"与"必须保持固定"的场景
- 改造后给出验证步骤：智感设备（设置>系统>智感旋转开启）、回退设备、旋转锁定开关开/关、分屏等特殊场景

## 验证方法
- 检查扫描是否覆盖 module.json5 与 *.ets/*.ts 两类来源
- 检查报告是否为表格/清单形式且包含位置信息
- 检查映射是否符合 migrate-to-smart-rotation.md 的映射表
- 检查是否提醒布局响应式适配（方向改造后会动态变化）
- 检查是否说明"直板机上 FOLLOW_DESKTOP/UNSPECIFIED 等效固定竖屏，需显式改 auto 类才能旋转"

## 备注
扫描改造是本技能的差异化能力。改造仅涉及策略枚举值替换，回滚成本低；改造前后应各执行一次扫描确认无固定策略残留。
