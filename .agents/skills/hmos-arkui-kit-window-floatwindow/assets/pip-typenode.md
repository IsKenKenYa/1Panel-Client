# 画中画骨架：typeNode（迁节点，不是一镜到底）

仅用户明确要迁自定义节点才读本文件。默认走 [pip-xcomponent.md](pip-xcomponent.md)。

`create(config, contentNode)`。`ABOUT_TO_START` `removeNode()`。系统不取源矩形，**不是一镜到底**。模板仍只改 [pip.md](pip.md) 表，不要给 typeNode 填 `navigationId`。

```text
Jump Page1
  → NavDestination.onShown：init = create(config, node)（不写 navigationId）+ setAutoStartEnabled(true)
  → 按钮 startPiP
  → ABOUT_TO_START：removeNode（官方可选 pop 回首页）
  → ABOUT_TO_STOP：addNode
  → ABOUT_TO_RESTORE：若 pop 过则再 push Page1
  → onHidden：setAutoStartEnabled(false) + removeNode
```

落点（对照官方目录，不要并进 XComponent 那个 Index）：

| 官方 | 作用 |
|------|------|
| `ets/util/XCNodeController.ets` | `typeNode.createNode('XComponent', SURFACE)`；`makeNode` 每次 new FrameNode |
| `ets/util/PipManager.ets` | 单例；`create(config, node)`；`CustomXComponentController.onSurfaceCreated` 绑播放器 |
| `ets/navigation/Page1.ets` | **根节点必须是 `NavDestination()`**；`NodeContainer` 高 `800px` |
| `ets/pages/NavigationImplementPage.ets` | 入口 Navigation；`PageMap` 直接 `Page1()`，不要再包一层 `NavDestination` |
| `ets/model/AVPlayer.ets` | `onSurfaceCreated` 里设 `surfaceID` 再 `avPlayerFdSrc`；片源 `rawfile/test.mp4` |

`config` **不要** `navigationId`。`PageMap` 只返回 `Page1()`（它自己已是 `NavDestination`），否则白屏。

## `ets/util/XCNodeController.ets`

```ts
export class XCNodeController extends NodeController {
  public xComponent: typeNode.XComponent | null = null;
  private node: FrameNode | null = null;
  private canAddNode: boolean = true;

  makeNode(context: UIContext): FrameNode | null {
    this.node = new FrameNode(context);
    if (this.xComponent === null || this.xComponent === undefined) {
      this.xComponent = typeNode.createNode(context, 'XComponent', {
        type: XComponentType.SURFACE,
        controller: PipManager.getInstance().getXComponentController(),
      });
    }
    if (this.canAddNode) {
      try {
        this.xComponent.getParent()?.removeChild(this.xComponent);
      } catch (error) {
      }
      try {
        this.node.appendChild(this.xComponent);
      } catch (error) {
      }
    }
    return this.node;
  }

  addNode(): void {
    if (this.node !== null && this.node !== undefined) {
      try {
        this.node.appendChild(this.xComponent);
      } catch (error) {
      }
    }
  }

  removeNode(): void {
    if (this.node !== null && this.node !== undefined) {
      try {
        this.node.removeChild(this.xComponent);
      } catch (error) {
      }
    }
  }

  getNode(): typeNode.XComponent | null {
    return this.xComponent;
  }
}
```

## `ets/util/PipManager.ets`（create / 生命周期）

```ts
export class CustomXComponentController extends XComponentController {
  onSurfaceCreated(surfaceId: string): void {
    if (PipManager.getInstance().player.surfaceID === surfaceId) {
      return;
    }
    PipManager.getInstance().player.surfaceID = surfaceId;
    PipManager.getInstance().player.avPlayerFdSrc();
  }
}

const config: PiPWindow.PiPConfiguration = {
  context: ctx,
  componentController: this.getXComponentController(),
  templateType: PiPWindow.PiPTemplateType.VIDEO_PLAY,
  contentWidth: 1920,
  contentHeight: 1080,
};
PiPWindow.create(config, node).then((controller: PiPWindow.PiPController) => {
  this.pipController = controller;
  this.pipController.setAutoStartEnabled(true);
  this.pipController.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
    this.onStateChange(state, reason);
  });
  this.pipController.on('controlEvent', (control: PiPWindow.ControlEventParam) => {
    this.onActionEvent(control);
  });
});

onStateChange(state: PiPWindow.PiPState, reason: string): void {
  this.xcNodeController.setCanAddNode(
    state === PiPWindow.PiPState.ABOUT_TO_STOP || state === PiPWindow.PiPState.STOPPED);
  this.lifeCycleCallback.forEach((fun) => { fun(state); });
  if (state === PiPWindow.PiPState.ABOUT_TO_START) {
    this.xcNodeController.removeNode();
  }
}
```

## `ets/navigation/Page1.ets`

```ts
@Component
export struct Page1 {
  build() {
    NavDestination() {
      Column() {
        NodeContainer(PipManager.getInstance().getNodeController())
          .size({ width: '100%', height: '800px' })
        Row({ space: 20 }) {
          Button('startPip').onClick(() => { PipManager.getInstance().startPip(); })
          Button('stopPip').onClick(() => { PipManager.getInstance().stopPip(); })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('page1')
    .onShown(() => {
      PipManager.getInstance().init(this.getUIContext().getHostContext() as Context);
      PipManager.getInstance().setAutoStartEnabled(true); // 封装内必须调 controller.setAutoStartEnabled
    })
    .onHidden(() => {
      PipManager.getInstance().setAutoStartEnabled(false);
      PipManager.getInstance().removeNode();
    })
  }
}
```

## `ets/pages/NavigationImplementPage.ets`

```ts
@Builder
PageMap(name: string) {
  if (name === 'Page1') {
    Page1();
  }
}

private callback: Function = (state: PiPWindow.PiPState) => {
  if (state === PiPWindow.PiPState.ABOUT_TO_START) {
    this.pageInfos.pop();
  } else if (state === PiPWindow.PiPState.ABOUT_TO_STOP) {
    PipManager.getInstance().addNode();
  } else if (state === PiPWindow.PiPState.ABOUT_TO_RESTORE) {
    this.jumpNext();
  }
};

Navigation(this.pageInfos) { /* Jump Page1 */ }
  .navDestination(this.PageMap)
```

`EntryAbility` 里 `AppStorage.setOrCreate('UIContext', window.getUIContext())`，播放器从这里取 context。片源改官方 `xxx.mp4` 为工程里的 `test.mp4`。
