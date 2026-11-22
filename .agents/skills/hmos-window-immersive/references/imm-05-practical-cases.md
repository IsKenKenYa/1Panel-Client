# 实战场景（IMM-05）

## 场景一：滚动容器沉浸

父容器是滚动容器时，子组件 `expandSafeArea` 无效。有两种方法实现沉浸式效果。

### 方法一：父容器设 expandSafeArea

设置父容器滚动容器和子组件相同的背景色，给父容器设置 `expandSafeArea`。

```typescript
@Entry
@Component
struct ScrollExample {
  scroller: Scroller = new Scroller()
  private arr: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9]

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.scroller) {
        Column() {
          ForEach(this.arr, (item: number) => {
            Stack() {
              Text('Display Content ' + item.toString()).fontSize(30)
            }
            .width('80%').padding(20).borderRadius(15).backgroundColor(Color.White).margin({ top: 30, bottom: 30 })
          }, (item: string) => item)
        }.width('100%').backgroundColor('rgb(213,213,213)')
      }.backgroundColor('rgb(213,213,213)')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }.width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
```

### 方法二：父容器设 clipContent

设置父容器滚动容器和子组件相同的背景色，设置滚动容器的 `clipContent(ContentClipMode.SAFE_AREA)`，将内容层裁剪区域扩展至避让区。

```typescript
@Entry
@Component
struct ScrollClipExample {
  scroller: Scroller = new Scroller()
  private arr: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9]

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.scroller) {
        Column() {
          ForEach(this.arr, (item: number) => {
            Stack() {
              Text('Display Content ' + item.toString()).fontSize(30)
            }
            .width('80%').padding(20).borderRadius(15).backgroundColor(Color.White).margin({ top: 30, bottom: 30 })
          }, (item: string) => item)
        }.width('100%').backgroundColor('rgb(213,213,213)')
      }.backgroundColor('rgb(213,213,213)')
      .clipContent(ContentClipMode.SAFE_AREA)
    }.width('100%').height('100%')
  }
}
```

## 场景二：底部页签沉浸

要求页签背景色延伸到导航区域，但页签内部可操作元素需要在导航区域之上。

**Navigation/Tabs 组件**默认实现了页签的延伸处理，只需保证组件底部边界和底部导航区域重合即可。

若使用自定义方式实现页签，可针对底部元素设置 `expandSafeArea`：

```typescript
@Entry
@Component
struct CustomTabExample {
  build() {
    Column() {
      // 顶部延伸至状态栏
      Row() {
        Text('Top Content').fontSize(40).textAlign(TextAlign.Center).width('100%')
      }.backgroundColor('#2786d9')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 中间内容
      Column() {
        Text('Content').fontSize(30)
      }.layoutWeight(1).width('100%')

      // 底部页签延伸至导航区域
      Row() {
        Text('Tab Bar').fontSize(40).textAlign(TextAlign.Center).width('100%')
      }.backgroundColor('#96dffa')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%').height('100%')
  }
}
```

## 场景三：图文场景（Swiper + 不同色背景）

状态栏元素和底部导航区域颜色不同时，对顶部和底部元素分别配置 `expandSafeArea`。

```typescript
@Entry
@Component
struct SwiperExample {
  build() {
    Swiper() {
      Column() {
        Image($r('app.media.start'))
          .height('50%').width('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])  // 图片延伸至状态栏
        Column() {
          Text('HarmonyOS 第一课').fontSize(32).margin(30)
          Text('描述文本').fontSize(20).margin(20)
        }.height('50%').width('100%').backgroundColor(Color.White)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])  // 背景延伸至导航栏
      }
    }
    .width('100%').height('100%')
    .clip(false)  // 关闭 Swiper 默认裁剪，子节点可绘制在外
  }
}
```

## 场景四：视频全屏沉浸（隐藏系统栏）

视频全屏场景无需调用 `setWindowLayoutFullScreen`，只需隐藏状态栏和导航条即可实现沉浸式全屏播放。

```typescript
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

// 进入视频全屏（仅隐藏系统栏，无需 setWindowLayoutFullScreen）
const enterVideoFullscreen = async (mainWindow: window.Window): Promise<void> => {
  try {
    await mainWindow.setSpecificSystemBarEnabled('status', false);
    await mainWindow.setSpecificSystemBarEnabled('navigationIndicator', false);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed: Code ${error.code}, message: ${error.message}`);
  }
};

// 退出视频全屏（恢复显示）
const exitVideoFullscreen = async (mainWindow: window.Window): Promise<void> => {
  try {
    await mainWindow.setSpecificSystemBarEnabled('status', true);
    await mainWindow.setSpecificSystemBarEnabled('navigationIndicator', true);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed: Code ${error.code}, message: ${error.message}`);
  }
};

// 注意：setSpecificSystemBarEnabled 仅主窗口生效；
// 非全屏/最大化模式（自由悬浮窗、分屏等）下不生效，进入全屏后才生效。
```

## 场景五：自由窗口标题栏沉浸

PC 设备及平板和折叠屏的自由多窗模式下，隐藏标题栏实现窗口沉浸式。组件沉浸策略不适用于此场景，需单独适配。

### 实现步骤

```typescript
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

interface MainWindowInfo {
  titleButtonRect: window.TitleButtonRect | null = null;
  isImmersive: boolean = false;
}

// 以下接口均为同步 void 返回，需在 loadContent/setUIContent 生效后调用
// 1. 隐藏标题栏，仅保留右上角三键区
mainWindow.setWindowDecorVisible(false);

// 2. 设置标题栏高度（范围 [37, 112] vp，控制三键区显示高度）
mainWindow.setWindowDecorHeight(56);

// 3. 设置三键样式（注意参数名为 dectorStyle）
mainWindow.setDecorButtonStyle({ buttonIconSize: 24 });

// 4. 监听三键区大小变化
const onWindowButtonRectChange = (titleButtonRect: window.TitleButtonRect): void => {
  mainWindowInfo.titleButtonRect = titleButtonRect;
};
mainWindow.on('windowTitleButtonRectChange', onWindowButtonRectChange);

// 5. 获取三键区位置（坐标相对窗口右上角，同步返回）
const rect = mainWindow.getTitleButtonRect();

// 6. 布局中避让三键区
```

### 布局避让三键区

```typescript
@Entry
@Component
struct FreeWindowExample {
  @StorageProp('titleButtonWidth') titleButtonWidth: number = 0;
  @StorageProp('isImmersive') isImmersive: boolean = false;

  build() {
    Column() {
      // 页面内容
    }
    .padding({
      right: this.isImmersive ? this.getUIContext().px2vp(this.titleButtonWidth) : 0
    })
  }
}
```

### 自由窗口标题栏 API

| 接口 | 说明 | API 版本 |
| --- | --- | --- |
| setWindowDecorVisible(isVisible: boolean): void | 设置标题栏显隐（同步） | API 11+ |
| setWindowDecorHeight(height: number): void | 设置标题栏高度（范围 [37, 112] vp，同步） | API 11+ |
| setDecorButtonStyle(dectorStyle: DecorButtonStyle): void | 设置三键样式（参数名 dectorStyle，同步） | API 14+ |
| getTitleButtonRect(): TitleButtonRect | 获取三键区位置和大小（坐标相对窗口右上角，同步） | API 11+ |
| on('windowTitleButtonRectChange', callback): void | 监听三键区变化 | API 11+ |
| off('windowTitleButtonRectChange', callback?): void | 注销三键区监听 | API 11+ |

> 自由窗口标题栏沉浸仅适用于自由多窗模式（PC/平板/折叠屏），普通手机全屏模式不涉及。以上接口需在 `loadContent()` / `setUIContent()` 生效后调用。
