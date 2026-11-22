/**
 * 播放/暂停按钮无障碍标注示例
 * 演示如何为Image组件设置无障碍属性，使其能被屏幕朗读识别为按钮
 */

const RESOURCE_STR_PLAY: Resource = $r('sys.media.ohos_ic_public_play');
const RESOURCE_STR_PAUSE: Resource = $r('sys.media.ohos_ic_public_pause');

@Entry
@Component
export struct PlayPauseButtonExample {
  @State isPlaying: boolean = false;
  
  /**
   * 播放音频文件
   */
  play() {
    console.info('play audio file');
    // 实际播放逻辑
  }
  
  /**
   * 暂停音频文件
   */
  pause() {
    console.info('pause playing of audio file');
    // 实际暂停逻辑
  }
  
  build() {
    NavDestination() {
      Column() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center,
        }) {
          Row() {
            // 播放/暂停按钮Image组件
            Image(this.isPlaying ? RESOURCE_STR_PAUSE : RESOURCE_STR_PLAY)
              .width(50)
              .height(50)
              .onClick(() => {
                this.isPlaying = !this.isPlaying;
                if (this.isPlaying) {
                  this.play();
                } else {
                  this.pause();
                }
              })
              // 设置无障碍角色为按钮
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              // 设置无障碍文本，根据状态动态更新
              .accessibilityText(this.isPlaying ? '暂停' : '播放')
            
            // 音频文件名称显示
            Text('Good_morning.mp3')
              .margin({
                left: 10
              })
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }
    .title('Play/Pause Button Accessibility Example')
  }
}

/**
 * 使用说明：
 * 
 * 1. 无障碍属性设置：
 *    - accessibilityRole(AccessibilityRoleType.BUTTON)：声明控件为按钮角色
 *    - accessibilityText(...)：设置无障碍文本，描述按钮功能
 * 
 * 2. 动态状态处理：
 *    - 使用@State变量管理状态（isPlaying）
 *    - 根据状态动态更新accessibilityText内容
 *    - 状态文本应准确描述当前功能（"播放" vs "暂停"）
 * 
 * 3. 屏幕朗读输出：
 *    - accessibilityText设置为"播放"
 *    - 屏幕朗读输出："播放，按钮，单指双击即可打开"
 *    - 注意："按钮"和操作指引由屏幕朗读自动追加
 * 
 * 4. 测试验证：
 *    - 开启设备屏幕朗读功能
 *    - 焦点移动到播放按钮
 *    - 检查朗读内容是否正确
 *    - 测试状态切换后的文本更新
 */

/**
 * 其他常见按钮标注场景：
 * 
 * 场景1：导航按钮
 * Image($r('sys.media.ohos_ic_public_arrow_left'))
 *   .onClick(() => { this.goBack(); })
 *   .accessibilityRole(AccessibilityRoleType.BUTTON)
 *   .accessibilityText('返回')
 * 
 * 场景2：设置按钮
 * Image($r('sys.media.ohos_ic_public_settings'))
 *   .onClick(() => { this.openSettings(); })
 *   .accessibilityRole(AccessibilityRoleType.BUTTON)
 *   .accessibilityText('设置')
 * 
 * 场景3：删除按钮
 * Image($r('sys.media.ohos_ic_public_remove'))
 *   .onClick(() => { this.deleteItem(); })
 *   .accessibilityRole(AccessibilityRoleType.BUTTON)
 *   .accessibilityText('删除')
 * 
 * 场景4：分享按钮
 * Image($r('sys.media.ohos_ic_public_share'))
 *   .onClick(() => { this.shareContent(); })
 *   .accessibilityRole(AccessibilityRoleType.BUTTON)
 *   .accessibilityText('分享')
 */

/**
 * 注意事项：
 * 
 * ❌ 不要包含控件类型描述：
 *    .accessibilityText('播放按钮')  // 错误
 *    ✅ 正确写法：
 *    .accessibilityText('播放')      // 正确
 * 
 * ❌ 不要包含操作指引：
 *    .accessibilityText('点击播放')  // 错误
 *    ✅ 正确写法：
 *    .accessibilityText('播放')      // 正确
 * 
 * ❌ 装饰性图片不应设置无障碍属性：
 *    Image($r('app.media.background_pattern'))
 *      .accessibilityText('背景图案')  // 错误，增加屏幕朗读负担
 * 
 * ✅ 功能性图片必须设置无障碍属性：
 *    Image($r('sys.media.ohos_ic_public_play'))
 *      .onClick(() => { this.play(); })
 *      .accessibilityText('播放')      // 正确
 */