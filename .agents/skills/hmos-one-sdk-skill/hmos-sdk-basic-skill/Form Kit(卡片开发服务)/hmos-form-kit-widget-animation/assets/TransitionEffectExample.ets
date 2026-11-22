// entry/src/main/ets/widget/pages/TransitionEffectExample.ets
// ArkTS卡片组件转场动效示例

@Entry
@Component
struct TransitionEffectExample {
  @State flag: boolean = true;
  @State show: string = 'show';
  
  build() {
    Column() {
      Button(this.show)
        .width(80)
        .height(30)
        .margin(30)
        .onClick(() => {
          // 点击按钮控制图片显示和消失
          if (this.flag) {
            this.show = 'hide';
          } else {
            this.show = 'show';
          }
          // 状态变化触发组件转场(flag从true变为false,或从false变为true)
          this.flag = !this.flag;
        })
      
      // if条件改变触发组件插入和删除
      if (this.flag) {
        // 图片出现和消失的转场效果配置
        // 出现时:透明度从0到1,绕z轴旋转180°到0°
        // 消失时:透明度从1到0,绕z轴旋转0°到180°
        // $r('app.media.testImg')需要替换为开发者实际的图像资源文件
        Image($r('app.media.testImg'))
          .width(200)
          .height(200)
          // 设置组件转场效果
          .transition(
            TransitionEffect.OPACITY  // 透明度转场效果
              .animation({ duration: 1000, curve: Curve.Ease })  // 动画参数:时长1000ms,曲线Ease
              .combine(
                TransitionEffect.rotate({ z: 1, angle: 180 })  // 组合旋转转场效果:绕z轴旋转180°
              )
          )
      }
    }
    .width('100%')
  }
}

// 关键要点:
// 1. 通过if条件改变触发组件转场(flag状态变化)
// 2. TransitionEffect定义组件出现和消失的效果
// 3. OPACITY透明度效果:出现时0→1,消失时1→0
// 4. rotate旋转效果:出现时180°→0°,消失时0°→180°
// 5. 使用combine组合多个转场效果(透明度+旋转)
// 6. animation参数对OPACITY和rotate均生效
// 7. 动画时长1000ms,符合限制要求(最长2000ms)
// 8. 动画曲线Curve.Ease,平滑过渡效果
// 9. 仅适用于动态卡片,静态卡片不支持转场动效
// 10. 图片资源路径$r('app.media.testImg')需要替换为实际资源