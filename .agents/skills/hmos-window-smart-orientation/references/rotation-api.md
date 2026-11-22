# 旋转接口速查与开发步骤

```typescript
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
```

获取主窗口（**仅主窗口支持旋转策略**）：

```typescript
// EntryAbility.ets → onWindowStageCreate
const mainWindow = windowStage.getMainWindowSync();

// 页面内获取当前窗口
import { common } from '@kit.AbilityKit';
const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
const mainWindow = context.windowStage.getMainWindowSync();
// 或
window.getLastWindow(context).then((win) => { /* win */ });
```

## 设置旋转策略的两种方式（总览）

| 方式 | 配置位置 | 适用场景 | 详见 |
| --- | --- | --- | --- |
| 方式一：静态配置 | module.json5 → `abilities` 标签 → `"orientation"` 字段 | 应用启动即固定/跟随某方向（如游戏固定横屏、设置初始方向） | 第 7 节 |
| 方式二：运行时 API | 主窗口调用 `setPreferredOrientation()` 等 | 动态切换方向（视频全屏/退出、按断点适配设备形态、锁定当前方向） | 第 1~6 节 |

- 两种方式设置的 `window.Orientation` 枚举含义完全一致，均受"仅主窗口、前台全屏生效、有传感器设备"等行为限制约束；
- 运行时接口可覆盖静态配置（对当前窗口会话生效）；
- **推荐组合**：module.json5 配置初始方向 + 运行时按页面/场景动态切换。

## 1. 设置旋转策略 setPreferredOrientation（API 9+）【方式二】

```typescript
// Promise 形式
try {
  const promise = mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_RESTRICTED);
  promise.then(() => {
    console.info('Succeeded in setting orientation.');
  }).catch((err: BusinessError) => {
    console.error(`Failed to set orientation. Code: ${err.code}, message: ${err.message}`);
  });
} catch (exception) {
  console.error(`Failed to set orientation. Code: ${exception.code}, message: ${exception.message}`);
}

// Callback 形式
mainWindow.setPreferredOrientation(window.Orientation.LANDSCAPE, (err: BusinessError) => {
  if (err.code) {
    console.error(`Failed. Code: ${err.code}, message: ${err.message}`);
    return;
  }
  console.info('Succeeded.');
});
```

说明：
- callback/Promise 只表示**接口调用结果**，不代表旋转动画结束。
- OH 6.1 前：仅主窗口生效；OH 6.1 起：主窗口和 `TYPE_WALLET_SWIPE_CARD` 系统窗口生效（系统窗口有高层窗口已设方向时不立即生效，仅记录，待无高层请求时恢复最后一次请求）。

## 2. 带结果设置 setPreferredOrientationWithResult（API 26+）

返回实际执行结果，用于判断策略是否被系统采纳（如处于分屏/悬浮窗等被忽略场景）：

```typescript
const result: window.OrientationResult =
  await mainWindow.setPreferredOrientationWithResult(window.Orientation.LANDSCAPE);
switch (result.executionResult) {
  case window.OrientationExecutionResult.ORIENTATION_APPLIED:  // 0 策略已生效
    break;
  case window.OrientationExecutionResult.ORIENTATION_IGNORED:  // 1 策略被忽略（如分屏/悬浮窗/自由多窗场景）
    break;
  case window.OrientationExecutionResult.ORIENTATION_PENDING:  // 2 策略暂缓，即将生效（如未全屏，进入全屏后生效）
    break;
}
```

## 3. 查询当前策略 getPreferredOrientation（API 12+）

```typescript
const orientation = mainWindow.getPreferredOrientation(); // 未设置过时返回 UNSPECIFIED
```

## 4. 监听旋转事件 rotationChange（API 19+）

```typescript
mainWindow.on('rotationChange', (info: window.RotationChangeInfo) => {
  if (info.type === window.RotationChangeType.WINDOW_WILL_ROTATE) {
    // 即将旋转：可返回 RotationChangeResult 干预旋转后的窗口矩形（仅对子窗口/系统窗口生效，主窗口返回值被忽略）
    const result: window.RotationChangeResult = {
      rectType: window.RectType.RELATIVE_TO_SCREEN,
      windowRect: { left: 0, top: 0, width: info.displayRect.width, height: info.displayRect.height }
    };
    return result;
  }
  // WINDOW_DID_ROTATE：旋转完成
});
mainWindow.off('rotationChange'); // 销毁时注销
```

`RotationChangeInfo` 结构：

| 字段 | 说明 |
| --- | --- |
| type | WINDOW_WILL_ROTATE（即将旋转）/ WINDOW_DID_ROTATE（旋转完成） |
| orientation | 窗口方向数字编码：**0 竖屏 / 1 反向横屏 / 2 反向竖屏 / 3 横屏**（注意与 `window.Orientation` 枚举值不同） |
| displayId | 窗口所在屏幕 ID |
| displayRect | 屏幕旋转后的矩形 |

## 5. 屏幕方向与窗口方向互转 convertOrientationAndRotation（API 23+）

`display.orientation`/`display.rotation` 不能直接判断窗口方向（多设备形态下并非一一对应），需用本接口换算：

```typescript
// displayOrientation（display.orientation 数字）→ 窗口方向数字编码
const windowOrientation: number = mainWindow.convertOrientationAndRotation(
  window.RotationInfoType.DISPLAY_ORIENTATION,  // from：屏幕方向
  window.RotationInfoType.WINDOW_ORIENTATION,   // to：窗口方向
  displayOrientation
);
```

`RotationInfoType` 取值：WINDOW_ORIENTATION（窗口方向，0竖/1反横/2反竖/3横）、DISPLAY_ORIENTATION（屏幕方向）、DISPLAY_ROTATION（屏幕物理角度，顺时针度数）。value 取值范围 [0, 3]，浮点数向下取整，越界抛 401。

数字编码 → `window.Orientation` 枚举映射（再用 `setPreferredOrientation` 锁定方向）：

| 窗口方向数字 | window.Orientation |
| --- | --- |
| 0（竖屏） | PORTRAIT |
| 1（反向横屏） | LANDSCAPE_INVERTED |
| 2（反向竖屏） | PORTRAIT_INVERTED |
| 3（横屏） | LANDSCAPE |

完整示例见 [rotation-practical-cases.md](rotation-practical-cases.md) 案例 3。

## 6. 系统窗口旋转锁 setRotationLocked / getRotationLocked（API 22+，@systemapi）

```typescript
await windowObj.setRotationLocked(true);   // 锁定，窗口方向保持不变
const locked = windowObj.getRotationLocked();
```

**仅系统窗口（系统应用）可用**，非系统窗口调用抛 1300029，非系统应用调用抛 202。锁定期间的传感器方向变化会在解锁后恢复最后一次方向；锁定期间的 `setPreferredOrientation` 请求被记录，解锁回前台后恢复。普通应用不能（也无需）调用，用户侧的旋转锁定由控制中心开关控制。

## 7. 静态配置 module.json5 orientation 字段【方式一】

在 `module.json5` 的 `abilities` 标签中配置 `"orientation"` 字段，应用启动即按该策略显示方向，适合启动即固定/跟随某方向的应用（如游戏固定横屏）：

```json5
// module.json5
{
  "module": {
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "orientation": "auto_rotation_restricted",  // 旋转策略静态配置
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background"
      }
    ]
  }
}
```

字段取值（18 个，与 `window.Orientation` 枚举**一一对应**，小写蛇形命名，默认 `"unspecified"`）：

| module.json5 取值 | 对应 Orientation 枚举 | 值 | 说明 |
| --- | --- | --- | --- |
| "unspecified" | UNSPECIFIED | 0 | 未定义（默认），系统判定（参与智感旋转） |
| "portrait" | PORTRAIT | 1 | 竖屏 |
| "landscape" | LANDSCAPE | 2 | 横屏 |
| "portrait_inverted" | PORTRAIT_INVERTED | 3 | 反向竖屏 |
| "landscape_inverted" | LANDSCAPE_INVERTED | 4 | 反向横屏 |
| "auto_rotation" | AUTO_ROTATION | 5 | 四方向自动旋转（不受旋转锁定控制） |
| "auto_rotation_portrait" | AUTO_ROTATION_PORTRAIT | 6 | 仅竖向两方向 |
| "auto_rotation_landscape" | AUTO_ROTATION_LANDSCAPE | 7 | 仅横向两方向 |
| "auto_rotation_restricted" | AUTO_ROTATION_RESTRICTED | 8 | 四方向，受旋转锁定控制 |
| "auto_rotation_portrait_restricted" | AUTO_ROTATION_PORTRAIT_RESTRICTED | 9 | 仅竖向，受旋转锁定控制 |
| "auto_rotation_landscape_restricted" | AUTO_ROTATION_LANDSCAPE_RESTRICTED | 10 | 仅横向，受旋转锁定控制 |
| "locked" | LOCKED | 11 | 锁定模式（被拉起时保持前一应用方向） |
| "auto_rotation_unspecified" | AUTO_ROTATION_UNSPECIFIED | 12 | 自动旋转，可旋转方向受系统判定 |
| "user_rotation_portrait" | USER_ROTATION_PORTRAIT | 13 | 临时竖屏后自动旋转 |
| "user_rotation_landscape" | USER_ROTATION_LANDSCAPE | 14 | 临时横屏后自动旋转 |
| "user_rotation_portrait_inverted" | USER_ROTATION_PORTRAIT_INVERTED | 15 | 临时反向竖屏后自动旋转 |
| "user_rotation_landscape_inverted" | USER_ROTATION_LANDSCAPE_INVERTED | 16 | 临时反向横屏后自动旋转 |
| "follow_desktop" | FOLLOW_DESKTOP | 17 | 跟随桌面 |

**静态配置与运行时 API 的关系：**

- 两者设置的 orientation 含义完全一致，效果等同；自动旋转类取值（`auto_rotation_*`）、`follow_desktop` 及默认 `unspecified` 在 OH 7.0.0+ 设备上同样参与智感旋转；
- 运行时调用 `setPreferredOrientation()` **覆盖**静态配置（对当前窗口会话生效）；未在运行时设置时按静态配置生效；两者都未设置时默认 `UNSPECIFIED`（系统判定：直板机默认竖屏不可旋转，平板四方向受旋转锁定控制）；
- 临时方向类型（`user_rotation_*`）语义是"调用时临时旋转"，一般用于运行时动态切换，不建议作为静态配置；
- 静态配置同样受行为限制约束：仅对 ability 主窗口生效，分屏/悬浮窗/自由多窗/后台场景被系统忽略，无传感器设备不生效。

**选型建议：**

| 需求 | 建议方式 |
| --- | --- |
| 游戏等全生命周期固定横/竖屏 | 仅静态配置：`"landscape"` / `"portrait"` |
| 启动即跟随传感器旋转（含智感体验） | 静态配置 `"auto_rotation_restricted"`，无需运行时代码 |
| 视频、阅读等页面间动态切换方向 | 静态配置初始方向 + 运行时 API 切换（如进全屏 `USER_ROTATION_LANDSCAPE`，退出恢复） |
| 多设备形态差异化（折叠屏/平板/直板机） | 运行时 API + 断点机制（见 rotation-practical-cases.md 案例 1） |

## 错误码速查

| 错误码 | 含义 |
| --- | --- |
| 401 | 参数错误（如 convertOrientationAndRotation value 越界） |
| 202 | 非系统应用调用系统 API（setRotationLocked 等） |
| 801 | 设备能力不支持 |
| 1300002 | 窗口状态异常（窗口未创建或已销毁） |
| 1300003 | 窗口管理服务异常 |
| 1300029 | 窗口类型无效（setRotationLocked 由非系统窗口调用） |
