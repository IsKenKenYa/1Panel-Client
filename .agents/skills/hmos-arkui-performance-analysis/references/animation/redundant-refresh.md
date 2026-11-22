# 不可见组件冗余刷新

## 版本与前提

针对动态ArkTS。成立须同时有“当前范围内存在不可见路径”和“不可见期间仍持续执行刷新”的代码或业务依据。缺onPageHide、存在iterations:-1或使用定时器本身都不能证明问题；不假设将来嵌入Tab或进入后台来追加整改。

有限任务已有结束与销毁清理、没有不可见期间继续工作的证据时，不额外报本项，也不输出正常清理的肯定清单。有限时长不自动免责，已确认持续工作时仍按频率、持续时间和业务判断。

| 路径 | 需要核对的停止/恢复方式 |
|---|---|
| 真实销毁或移除 | aboutToDisappear清理定时器和资源；复用另核对回收/复用路径与过期任务 |
| 非活跃Tab | 实际Tabs.onChange路径停止/恢复；Tab切换不等于销毁 |
| 页面后台 | Entry的onPageHide/onPageShow处理当前页面；仅在已确认该路径时建议 |
| 离屏但缓存存活、visibility隐藏 | 适用可见性/状态回调暂停，回到有效显示范围后按业务恢复 |
| 第三方APNG/Lottie | 调用组件真实controller接口，不能拿系统animator.pause代替第三方控停 |

aboutToAppear/aboutToDisappear及Tabs.onChange从API7、Entry的onPageHide/onPageShow与animator.pause从API9支持；onVisibleAreaChange从API7、commonEvent的setOnVisibleAreaApproximateChange从API12支持，按目标版本核对。

## 检查方法

沿定时器、animator或第三方驱动回调，确认可见性变化后实例是否仍存活、状态/解码/绘制是否继续，以及谁负责完成、暂停、恢复与释放。不要要求每个动画片段补齐所有回调。已有系统组件或库内可见性处理时先核对是否覆盖实际工作，再判断父级是否仍需控制；Image的Gif、Swiper自动轮播、LoadingProgress等系统组件默认在不可见时停止，无需重复接入可见性控制。

将定时器改为属性动画只证明原定时器回调被移除；是否停止不可见动画，还须核对所选接口的实际行为或接入控停，不能从“系统动画”直接推断已暂停。恢复要保持业务要求的进度、转速和方向，销毁时释放实际保留的驱动。

复用时避免旧任务和异步结果串到新记录，保留业务身份、恢复进度与资源释放。if下树会改变布局、销毁状态并引入重建，不作为通用“暂停动画”方案；用户已选择条件展示且布局语义允许时才说明其代价。

## 最小修改示例

Tab中需要暂停后继续旋转时，可用animator提供控制句柄。父组件沿用Tabs.onChange更新currentTab，将调用改为`SpinningIcon({ active: this.currentTab === 0 })`。下面覆盖初始active、节点出现后启动、Tab停启和销毁；animator仍通过onFrame更新angle，不声称应用侧逐帧工作全部消失。

```ts
import { AnimatorResult } from '@kit.ArkUI';

@Component
struct SpinningIcon {
  @Prop @Watch('syncActive') active: boolean = true;
  @State angle: number = 0;
  private anim: AnimatorResult | undefined = undefined;
  private playing: boolean = false;

  private syncActive(): void {
    if (!this.anim || this.active === this.playing) { return; }
    if (this.active) { this.anim.play(); } else { this.anim.pause(); }
    this.playing = this.active;
  }

  aboutToDisappear(): void {
    if (this.anim) {
      this.anim.onFrame = () => {};
      this.anim.cancel();
      this.anim = undefined;
    }
    this.playing = false;
  }

  build() {
    Column() {
      Text('旋转')
        .fontSize(20)
        .rotate({ angle: this.angle })
        .onAppear(() => {
          if (!this.anim) {
            this.anim = this.getUIContext().createAnimator({
              duration: 3000, easing: 'linear', delay: 0,
              fill: 'forwards', direction: 'normal', iterations: -1,
              begin: 0, end: 360
            });
            this.anim.onFrame = (value: number) => { this.angle = value; };
          }
          this.syncActive();
        })
    }
  }
}
```

只有当前范围还存在页面后台路径时，才将Entry的页面可见状态并入active。cancel会额外触发终值onFrame，示例先清空回调再取消，避免销毁时继续提交状态。

实例销毁时的定时器清理：

```ts
aboutToDisappear(): void {
  if (this.timer !== -1) {
    clearInterval(this.timer);
    this.timer = -1;
  }
}
```

已确认离屏缓存仍持续解码/渲染，且第三方controller提供pause/play时，可在实际条目上控制：

```ts
apng({ src: $r('app.media.stack'), controller: item })
  .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, ratio: number) => {
    if (isVisible) { item.play(); } else { item.pause(); }
  })
```

按业务选择可见阈值和恢复时机。节点多、层级深时可评估适用的近似可见性回调。controller控制使tick提前返回，减少解码、drawImage/clearRect和位图创建，不替代组件内部的销毁释放。

## 建议与验证

只针对已成立的路径提出控停，说明原有触发、结束、恢复和清理如何保持。验证跟随最终驱动：保留定时器/animator时记录其实际回调，不可见时停止、返回后恢复；删除定时器时其计数始终为零，另观察新动画的停止/恢复。Trace比较相同操作和不可见窗口的实际UI/渲染工作，未实测写预期。

系统动画可按[动效观察](../trace-guidance.md#动效问题观察)选择事件。第三方库不一定产生RSThread::DoAnimation或ViewPU状态事件；APNG等已确认渲染工作在ReceiveVsync中时，可比较该窗口ReceiveVsync累计Duration。不能从缺某个系统动画标签推断第三方没有刷新，也不能直接宣称已测功耗收益。

接口依据：[UIContext.createAnimator](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-uicontext-uicontext/)、[AnimatorResult的play/pause/cancel](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-animator/)。
