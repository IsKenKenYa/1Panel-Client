// entry/src/main/ets/widget/pages/AnimationWithFallback.ets
// ArkTS卡片动画降级处理示例

@Entry
@Component
struct AnimationWithFallback {
  @State rotateAngle: number = 0;
  @State cardType: string = 'dynamic';  // 'dynamic' or 'static'
  
  build() {
    Row() {
      if (this.cardType === 'dynamic') {
        // 动态卡片支持动效
        Button('animation (dynamic card)')
          .height('20%')
          .width('90%')
          .margin('5%')
          .onClick(() => {
            // 动态卡片:状态变化触发动画
            this.rotateAngle = (this.rotateAngle === 0 ? 90 : 0);
            console.info('Dynamic card animation triggered');
          })
          .rotate({ angle: this.rotateAngle })
          .animation({
            curve: Curve.EaseOut,
            playMode: PlayMode.Normal,
          })
      } else {
        // 静态卡片降级方案:直接改变属性,无动画
        Button('static change (static card)')
          .height('20%')
          .width('90%')
          .margin('5%')
          .onClick(() => {
            // 静态卡片不支持动画的降级方案
            console.warn('Static card does not support animation');
            console.warn('Using fallback: direct property change without animation');
            
            // 直接改变属性值,无动画过渡
            // 用户会看到直接的跳变效果,而不是平滑过渡
            this.rotateAngle = (this.rotateAngle === 0 ? 90 : 0);
          })
          .rotate({ angle: this.rotateAngle })  // 直接旋转,无动画过渡
          // 注意:静态卡片不调用animation方法
      }
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
  }
}

// 降级处理要点:
// 1. 根据卡片类型选择不同的实现方案
// 2. 动态卡片:使用完整动画效果
// 3. 静态卡片:降级为直接属性改变,无动画过渡
// 4. 提供明确的警告日志,告知用户降级原因
// 5. 静态卡片仍然可以实现功能,但失去动画体验
// 6. 建议用户使用动态卡片以获得更好的动画效果