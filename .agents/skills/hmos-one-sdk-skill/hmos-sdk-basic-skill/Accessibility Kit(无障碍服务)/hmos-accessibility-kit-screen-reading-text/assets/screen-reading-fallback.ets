/**
 * 降级处理示例：处理Resource不可用等异常情况
 * 本示例演示如何实现友好的降级方案
 */

@Entry
@Component
struct ScreenReadingFallbackExample {
  @State isResourceAvailable: boolean = true;
  @State apiVersion: number = 12; // 假设当前API版本
  @State networkAvailable: boolean = true;
  
  build() {
    Column({ space: 20 }) {
      Text('降级处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      // 示例1：Resource不可用时的降级方案
      Button('Resource降级示例')
        .accessibilityText(
          this.isResourceAvailable 
            ? $r('app.string.action_button_accessibility')
            : '执行操作的按钮，点击后开始执行'
        )
        .onClick(() => {
          if (!this.isResourceAvailable) {
            console.warn('Resource不可用，使用备用文本');
          }
        })
      
      // 示例2：API版本不兼容时的降级方案
      if (this.apiVersion >= 12) {
        Button('Resource格式')
          .accessibilityText($r('app.string.new_feature_accessibility'))
      } else if (this.apiVersion >= 10) {
        Button('String格式')
          .accessibilityText('新功能按钮（API版本限制，使用string格式）')
      } else {
        Text('当前API版本不支持accessibilityText')
          .fontColor(Color.Red)
      }
      
      // 示例3：动态文本降级
      Button('动态文本示例')
        .accessibilityText(this.getDynamicAccessibilityText())
        .onClick(() => {
          this.networkAvailable = !this.networkAvailable;
        })
      
      // 示例4：多语言降级
      Button('多语言降级')
        .accessibilityText(this.getLocalizedAccessibilityText())
      
      // 示例5：分段文本处理（文本过长时的降级）
      Column() {
        Text('分段文本示例')
          .fontSize(18)
        
        Row({ space: 10 }) {
          Button('第1部分')
            .accessibilityText('操作步骤第1部分')
          Button('第2部分')
            .accessibilityText('操作步骤第2部分')
          Button('第3部分')
            .accessibilityText('操作步骤第3部分')
        }
      }
      .accessibilityGroup(true)
      .accessibilityText('完整操作流程，包含3个步骤')
      
      // 示例6：综合降级方案
      Button('综合示例')
        .accessibilityText(this.getComprehensiveAccessibilityText())
        .onClick(() => {
          // 模拟资源不可用
          this.isResourceAvailable = false;
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
  
  /**
   * 获取动态无障碍文本
   * 根据网络状态动态选择文本
   */
  private getDynamicAccessibilityText(): string {
    if (this.networkAvailable) {
      return '网络正常，可以执行在线操作';
    } else {
      return '网络不可用，只能执行本地操作';
    }
  }
  
  /**
   * 获取本地化无障碍文本
   * Resource不可用时使用硬编码备用文本
   */
  private getLocalizedAccessibilityText(): string | Resource {
    try {
      if (this.isResourceAvailable && this.apiVersion >= 12) {
        return $r('app.string.localized_accessibility');
      } else {
        // Resource不可用时的降级方案
        return '多语言按钮（Resource不可用，使用默认文本）';
      }
    } catch (error) {
      console.error('Resource引用失败，使用降级文本');
      return '降级文本：执行操作';
    }
  }
  
  /**
   * 综合降级方案
   * 根据多个条件选择最优文本
   */
  private getComprehensiveAccessibilityText(): string | Resource {
    // 优先使用Resource（API ≥ 12且资源可用）
    if (this.apiVersion >= 12 && this.isResourceAvailable && this.networkAvailable) {
      try {
        return $r('app.string.comprehensive_accessibility');
      } catch (error) {
        console.warn('Resource引用失败');
      }
    }
    
    // 降级方案1：使用string格式（API ≥ 10）
    if (this.apiVersion >= 10) {
      return '综合示例按钮（Resource不可用，使用string格式）';
    }
    
    // 最终降级：不设置无障碍文本（API < 10）
    return '';
  }
}