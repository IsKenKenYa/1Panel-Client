// entry/src/main/ets/widget/pages/AnimationCard.ets
// ArkTS卡片组件旋转动画示例

@Entry
@Component
struct AnimationCard {
  @State rotateAngle: number = 0;
  
  build() {
    Row() {
      Button('change rotate angle')
        .height('20%')
        .width('90%')
        .margin('5%')
        .onClick(() => {
          // 点击按钮改变旋转角度
          // 从0度旋转到90度,或从90度旋转回0度
          this.rotateAngle = (this.rotateAngle === 0 ? 90 : 0);
        })
        // 定义旋转属性(必须在animation之前定义)
        .rotate({ angle: this.rotateAngle })
        // 设置属性动画
        // 注意:不设置禁止参数(tempo/delay/iterations)
        .animation({
          curve: Curve.EaseOut,        // 动画曲线:缓出效果
          playMode: PlayMode.Normal,   // 播放模式:正常播放
        })
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
  }
}

// 关键要点:
// 1. 属性定义必须在animation之前
// 2. rotate属性定义后立即调用animation
// 3. 状态变化(rotateAngle)触发动画
// 4. 动画参数中不设置禁止参数(tempo/delay/iterations)
// 5. duration未指定时使用默认值1000ms,符合限制要求
// 6. 仅适用于动态卡片,静态卡片不支持动效