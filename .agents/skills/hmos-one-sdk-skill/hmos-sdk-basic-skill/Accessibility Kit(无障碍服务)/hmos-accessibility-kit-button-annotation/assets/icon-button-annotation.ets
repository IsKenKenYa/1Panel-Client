// 图标按钮标注示例
// 本示例展示如何为图标按钮设置无障碍标注

import { AccessibilityRoleType } from '@kit.ArkUI';

@Entry
@Component
struct IconButtonAnnotation {
  @State searchQuery: string = '';
  
  build() {
    NavDestination() {
      Column() {
        // 示例1: 搜索图标按钮
        Text('示例1: 搜索按钮')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Row() {
          TextInput({ placeholder: '输入搜索内容' })
            .width('70%')
            .height(40)
            .onChange((value) => {
              this.searchQuery = value;
            })
          
          // 搜索图标按钮
          Image($r('sys.media.ohos_ic_public_search'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('执行搜索: ' + this.searchQuery);
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('搜索')
            .margin({ left: 10 })
        }
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        // 示例2: 工具栏按钮组
        Text('示例2: 工具栏按钮组')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Row() {
          // 复制按钮
          Image($r('sys.media.ohos_ic_public_copy'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('复制内容');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('复制')
          
          // 粘贴按钮
          Image($r('sys.media.ohos_ic_public_paste'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('粘贴内容');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('粘贴')
            .margin({ left: 10 })
          
          // 剪切按钮
          Image($r('sys.media.ohos_ic_public_cut'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('剪切内容');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('剪切')
            .margin({ left: 10 })
          
          // 分享按钮
          Image($r('sys.media.ohos_ic_public_share'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('分享内容');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('分享')
            .margin({ left: 10 })
        }
        .padding(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        // 示例3: 导航按钮
        Text('示例3: 导航按钮')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Row() {
          // 返回按钮
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('返回上一页');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('返回')
          
          Text('页面标题')
            .fontSize(16)
            .margin({ left: 20, right: 20 })
          
          // 前进按钮
          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('前进下一页');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('前进')
          
          // 菜单按钮
          Image($r('sys.media.ohos_ic_public_more'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('打开菜单');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('菜单')
            .margin({ left: 10 })
        }
        .padding(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        // 示例4: 操作按钮组
        Text('示例4: 操作按钮组')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Row() {
          // 编辑按钮
          Image($r('sys.media.ohos_ic_public_edit'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('编辑内容');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('编辑')
          
          // 删除按钮
          Image($r('sys.media.ohos_ic_public_delete'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('删除内容');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('删除')
            .margin({ left: 10 })
          
          // 保存按钮
          Image($r('sys.media.ohos_ic_public_save'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('保存内容');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('保存')
            .margin({ left: 10 })
        }
        .padding(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
      }
      .width('100%')
      .padding(20)
    }
    .title('图标按钮标注示例')
  }
}