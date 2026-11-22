// ArkTS锁屏卡片完整示例代码
// 文件路径: entry/src/main/ets/widget/pages/WidgetCard.ets

import { formBindingData, FormExtensionAbility } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

// 锁屏卡片UI组件
@Entry
@Component
struct WidgetCard {
  // 使用LocalStorageProp接收卡片数据
  @LocalStorageProp('temperature') temperature: string = '20c';
  @LocalStorageProp('time') time: string = '12:00';
  @LocalStorageProp('weatherIcon') weatherIcon: string = '☀️';
  
  build() {
    Column() {
      // 天气图标
      Text(this.weatherIcon)
        .fontSize(32)
        .margin({ top: 10 })
      
      // 温度信息
      Text(this.temperature)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 5 })
      
      // 时间信息
      Text(this.time)
        .fontSize(16)
        .margin({ top: 5 })
      
      // 快捷操作按钮(可选)
      Button('刷新')
        .fontSize(12)
        .height(30)
        .margin({ top: 10 })
        .onClick(() => {
          // 点击事件处理
          postCardAction(this, {
            action: 'message',
            params: {
              msg: 'refresh'
            }
          });
        })
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

// 锁屏卡片数据更新函数
function updateWidgetData(formId: string, data: Record<string, string>) {
  let formData = formBindingData.createFormBindingData(data);
  formProvider.updateForm(formId, formData).then(() => {
    console.info('锁屏卡片数据更新成功');
  }).catch((error: BusinessError) => {
    console.error('锁屏卡片数据更新失败:', error.code, error.message);
  });
}

// 点击事件处理
function postCardAction(component: Object, action: Object) {
  // 实现卡片点击事件逻辑
  console.info('卡片点击事件触发');
}