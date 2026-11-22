# B-S4 验证工程：modules.abc 缺失（assets 漏拷贝白屏）

## 场景
删除 APK 中 `assets/arkui-x/entry/ets/modules.abc`（module.json 保留）→ abc 加载失败 → Ability 对象获取不到 → 白屏（进程存活，不闪退）。

## skill 预期
- 症状：白屏（Ability 无法创建，`didn't commit buffer`）
- FAQ：**A-8** 扩展签名命中（`RunScriptBuffer failed path: entry/ets/entryability/EntryAbility.abc` + `Failed to get Ability object`）
- 维度①：链断点 #7 Ability 段（`LoadJsModule assetPath .../modules.abc` 后失败）
- 注意：此场景 `bundleInfo_ is nullptr` **不出现**（module.json 在，bundleInfo 正常解析）——A-8 原签名匹配不到，靠扩展签名

## 复现步骤
同 B-S3，但删除的目标是 `assets/arkui-x/entry/ets/modules.abc`（zip内路径），重打包+签名+安装。

## 实测关键日志（2026-10 实证）
```
I/Ace: LoadJsModule assetPath /data/storage/el1/bundle/entry/ets/modules.abc
I/Ace: LoadJsModule moduleName_ entry
E/Ace: RunScriptBuffer failed path: entry/ets/entryability/EntryAbility.abc
E/Ace: Failed to get Ability object
W/Ace: Not found Ability.js
```
