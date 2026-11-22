# B-S5 验证工程：aboutToAppear JS 异常（throw new Error）

## 场景
BadPage 的 aboutToAppear 无条件 `throw new Error` → 框架 `panda::TryCatch` 捕获 → 不白屏不闪退 → 页面正常渲染。

## 工程要点
- EntryAbility：onCreate 注册 `errorManager.on('error', { onUnhandledException: (errMsg) => console.error(...) })`
- Index：入口说明页，按钮 push 到 BadPage
- BadPage：`aboutToAppear` → `console.error('BEFORE throw')` → `throw new Error('...')` → `console.error('AFTER throw')`（不可达）

## skill 预期（实测达成）
- A-5b：框架 catch 异常不白屏（全链锚点齐+首帧已上屏佐证）
- errorManager 回调输出 JS 栈（`BadPage.ets:8:11` 文件+行号+列号）——**作为 jscrash 信息丢失时的协助手段（非必选项）**
- `System.err: NoClassDefFoundError ... no stack trace available`（未注册 errorManager 时）

## 异常定位能力矩阵（实测）

| 配置 | JS 栈 | 定位粒度 |
|------|-------|---------|
| release/debug + 未注册 errorManager | ❌ 无 | 页面级（`startUrl=pages/BadPage`） |
| debug + 注册 errorManager | ✅ `BadPage.ets:8:11` | 行级 |

## 实测关键日志（2026-10 实证）
```
E/Ace: RealJSException: BadPage aboutToAppear BEFORE throw
W/System.err: java.lang.NoClassDefFoundError: ... no stack trace available   ← 未注册时
—— 或注册 errorManager 后 ——
E/Ace: RealJSException [errorManager] caught error: Error name:Error
E/Ace: Error message:Cannot read property value of undefined at aboutToAppear (BadPage.ets:7)
E/Ace:     at aboutToAppear entry (entry/src/main/ets/pages/BadPage.ets:8:11)   ← 行级定位
```
（全链锚点：Create UIContent→AttachView→RunPage→ON_SHOW→first vsync→first frame 均齐）

## 复现
```powershell
ace build apk --debug   # debug 含 sourceMaps.map
adb install -r <apk>; adb shell am start -n com.example.real_js_exception/.EntryEntryAbilityActivity
```
