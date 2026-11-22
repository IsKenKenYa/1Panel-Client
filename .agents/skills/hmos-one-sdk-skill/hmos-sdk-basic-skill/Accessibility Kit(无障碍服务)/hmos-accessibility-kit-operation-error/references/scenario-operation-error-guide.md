# 操作错误场景
---
# 操作错误场景
#### 设计场景
比如网络连接错误，或者其他警告信息，不能仅仅以颜色区分，需要实时告诉用户错误提示和改进方法。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/03/v3/0JwyKvjkReW8yU-U1CFlFQ/zh-cn_image_0000002628700100.png?HW-CC-KV=V1&HW-CC-Date=20260701T104518Z&HW-CC-Expire=86400&HW-CC-Sign=D955C22DA599E83434861BCB7A9C9D9A0CA6A43EE3D57F0E4AC3E29176F369B9)
#### 开发实例
如下是一个将连接中断播报出来的例子。
```
@Entry
@Component
export struct Rule_2_1_9 {
  title: string = 'Rule 2.1.9';
  build() {
    NavDestination() {
      Column() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center,
        }) {
          Row() {
            Text('Connection state').fontSize(30)
          }
          Row() {
            Radio({ value: 'Radio1', group: 'radioGroup' }).checked(true)
              .radioStyle({
                checkedBackgroundColor: Color.Red
              })
              .height(50)
              .width(50)
              .onChange((isChecked: boolean) => {
                console.info('Radio1 status is: ', isChecked);
              })
            Text('Connection interrupted').fontColor(Color.Red)
          }
          .width('80%')
          .accessibilityGroup(true) // 将单选和文本合并到单个对象中。
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }.title(this.title)
  }
}
```