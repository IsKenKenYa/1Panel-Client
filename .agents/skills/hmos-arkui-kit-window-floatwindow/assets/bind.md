# 窗 + 球绑定（本地）

细节：[misuse-float-view.md](../references/misuse/misuse-float-view.md) 绑定节。两边都 `create` 且**都未 start**，再 bind，再 start 其中一个。权限：`FLOAT_VIEW` 弹窗 + `USE_FLOAT_BALL` 不弹窗（[permissions.md](permissions.md)）。

**怎么拼（只出一套 Index）：**

1. 抄 [float-view.md](float-view.md) 的 `pages/Index.ets` 外壳 + `pages/FloatPanel.ets`
2. 把 Index 里的 `start()` **整段换成**下面的 `bindAndStart`
3. `requestPerms` 抄 [permissions.md](permissions.md)
4. **不要**抄 [floating-ball.md](floating-ball.md) 整页，也**不要**再调 `startFloatingBall`

未说球样式用 `EMPHATIC`（用户说只要一行标题才 `SIMPLE`）。

```ts
import { floatView, floatingBall } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function bindAndStart(ctx: common.UIAbilityContext): Promise<void> {
  if (!canIUse('SystemCapability.Window.SessionManager') ||
    !floatView.isFloatViewEnabled() || !floatingBall.isFloatingBallEnabled()) {
    return;
  }
  if (!await requestPerms(ctx, ['ohos.permission.FLOAT_VIEW'])) {
    return;
  }
  const fv = await floatView.create({
    context: ctx,
    templateType: floatView.FloatViewTemplateType.ROUNDED_RECTANGLE
  });
  const fb = await floatingBall.create({ context: ctx });
  const ballParams: floatingBall.FloatingBallParams = {
    template: floatingBall.FloatingBallTemplate.EMPHATIC,
    title: '会议',
    content: '进行中'
  };
  await floatView.bind(fv, fb, ballParams);
  fv.onStateChange((info: floatView.FloatViewStateChangeInfo) => {
    if (info.state === floatView.FloatViewState.STARTED) {
      // 窗在前台
    } else if (info.state === floatView.FloatViewState.IN_FLOATING_BALL) {
      // 已切到球，点球由系统展开窗
    } else if (info.state === floatView.FloatViewState.STOPPED ||
      info.state === floatView.FloatViewState.ERROR) {
      // 停了或异常；失败要上屏
    }
  });
  await fv.setUIContext('pages/FloatPanel');
  await fv.start();
}
```

`create` 一次。听 `STARTED` / `IN_FLOATING_BALL`。`stop` 任一即两边一起停。不要在 `aboutToDisappear` 里 `stop`。`offStateChange` 要 try/catch。

禁止：先 `startFloatingBall` 再 `bind`；自己 start 两套手动切。若还要防窥：读 [peep.md](peep.md)。
