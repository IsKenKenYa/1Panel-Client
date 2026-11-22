// entry/src/main/ets/widget/pages/AnimationWithErrorHandling.ets
// ArkTS卡片动画错误处理示例

@Entry
@Component
struct AnimationWithErrorHandling {
  @State rotateAngle: number = 0;
  
  build() {
    Row() {
      Button('animation')
        .height('20%')
        .width('90%')
        .margin('5%')
        .onClick(() => {
          try {
            // 动画参数校验
            const duration = 1500;  // 确保不超过2000ms
            
            // 校验动画时长限制
            if (duration > 2000) {
              console.warn('Animation duration exceeds limit, will be clamped to 2000ms');
              // 注意:超过2000ms会自动限制为2000ms,不会报错
            }
            
            // 状态变化触发动画
            this.rotateAngle = (this.rotateAngle === 0 ? 90 : 0);
            
            console.info('Animation triggered successfully, rotateAngle: ' + this.rotateAngle);
            
          } catch (error) {
            // 错误处理
            console.error('Animation error:', error.message);
            
            // 根据错误类型提供解决建议
            if (error.message.includes('duration')) {
              console.error('Solution: Set duration <= 2000ms');
            } else if (error.message.includes('forbidden')) {
              console.error('Solution: Remove forbidden parameters (tempo/delay/iterations)');
            }
          }
        })
        .rotate({ angle: this.rotateAngle })
        .animation({
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal,
        })
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
  }
}

// 错误处理要点:
// 1. 使用try-catch捕获动画执行错误
// 2. 校验动画时长不超过限制(2000ms)
// 3. 提供友好的错误提示和解决建议
// 4. 记录动画执行日志便于调试
// 5. duration超过限制会自动降级,不会抛出错误