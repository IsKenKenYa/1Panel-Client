/**
 * 示例3：自定义无障碍文本与特殊场景处理
 * 功能：展示如何自定义播报文本、处理子组件突破分组、优先使用无障碍文本等高级用法
 */

@Entry
@Component
export struct CustomAccessibilityTextExample {
  title: string = '自定义无障碍文本示例';
  
  // 示例1：纯图片组件的自定义播报
  @Builder
  pureImageExample() {
    Column() {
      Text('示例1：纯图片组件')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
      
      Column() {
        Image($r("app.media.gesture_icon"))
          .width(100)
          .height(100)
          .alt('手势图标')
      }
      .accessibilityGroup(true)
      .accessibilityText("手势图标：向左然后向上滑动") // 必须设置，否则无法播报
      .accessibilityDescription("该图标表示执行向左然后向上滑动操作")
      .margin({ bottom: 20 })
    }
  }
  
  // 示例2：子组件突破分组约束
  @Builder
  childOverrideExample() {
    Column() {
      Text('示例2：子组件突破分组')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
      
      Column() {
        Image($r("app.media.main_image"))
          .width(200)
          .height(150)
        
        Text("主要图片描述")
          .fontSize(16)
        
        Button("查看详情")
          .width(120)
          .height(40)
          .accessibilityLevel("yes") // 该按钮可独立聚焦，不受父组件分组约束
      }
      .accessibilityGroup(true) // 图片和描述文本组合为一个焦点，按钮独立
      .margin({ bottom: 20 })
    }
  }
  
  // 示例3：优先使用无障碍文本朗读（API version 14+）
  @Builder
  preferredAccessibilityTextExample() {
    Column() {
      Text('示例3：优先无障碍文本朗读（API 14+）')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
      
      Column() {
        Text("显示文本内容")
          .fontSize(16)
          .accessibilityText("播报时使用此文本") // 无障碍文本
        
        Text("另一段显示文本")
          .fontSize(16)
          .accessibilityText("第二段播报文本")
      }
      .accessibilityGroup(true, { accessibilityPreferred: true }) // 优先朗读无障碍文本
      .margin({ bottom: 20 })
    }
  }
  
  // 示例4：多元素组合的自定义播报
  @Builder
  multiElementCustomExample() {
    Column() {
      Text('示例4：多元素自定义播报')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
      
      Row() {
        Image($r("app.media.video_thumbnail"))
          .width(80)
          .height(60)
          .alt('视频缩略图')
        
        Column() {
          Text("视频标题")
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
          
          Text("视频描述信息")
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .accessibilityGroup(true)
      .accessibilityText("视频：视频标题，时长10分钟") // 精简的自定义播报内容
      .accessibilityDescription("点击观看视频详情")
      .width('90%')
      .height(80)
      .borderRadius(8)
      .backgroundColor('#F5F5F5')
      .padding(10)
      .margin({ bottom: 20 })
    }
  }
  
  build() {
    NavDestination() {
      Scroll() {
        Column() {
          this.pureImageExample()
          this.childOverrideExample()
          this.preferredAccessibilityTextExample()
          this.multiElementCustomExample()
        }
        .width('100%')
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
    }
    .title(this.title)
  }
}

/**
 * 使用说明：
 * 
 * 1. 纯图片组件：
 *    - 必须设置accessibilityText，否则无法播报
 *    - 可配合accessibilityDescription提供详细说明
 * 
 * 2. 子组件突破分组：
 *    - 子组件设置accessibilityLevel("yes")可独立聚焦
 *    - 适用场景：组合项中有需要独立操作的按钮
 * 
 * 3. 优先无障碍文本朗读：
 *    - 需API version 14+
 *    - 设置accessibilityPreferred: true
 *    - 播报优先使用accessibilityText而非显示文本
 * 
 * 4. 多元素自定义播报：
 *    - 可精简播报内容，避免冗长
 *    - 使用accessibilityText自定义核心信息
 *    - 使用accessibilityDescription补充操作说明
 * 
 * 播报效果对比：
 * - 默认拼接："视频缩略图，视频标题，视频描述信息"（冗长）
 * - 自定义播报："视频：视频标题，时长10分钟"（精简）
 */