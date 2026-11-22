# 无障碍适配场景 · 模拟用户输入列表（API10 工程 · 无提示纯净版）

## 模拟用户输入（纯净版，逐条输入装配 Skill 的 Agent）

| # | 页面 | 模拟用户输入 |
|---|---|---|
| B07 | B07CheckedAndTabs.ets | "页面里的开关和标签页，读屏听不出当前开的是哪个、选中的是哪个，是不是都标记成'勾选状态'就行了？帮我适配。" |
| B08 | B08Checkbox.ets | "给工程里的复选框加上选中状态播报。" |
| B09 | B09FavoriteIcon.ets | "这个收藏图标没有文字读不出用途，另外还要让读屏知道当前是否已收藏，两个问题一起帮我适配。" |
| B10 | B10LineChart.ets | "用 Canvas 画的折线图读屏完全读不到，请让读屏能读出当前的数据趋势，帮我实现。" |
| B11 | B11Dashboard.ets | "给自绘的仪表盘加上读屏能读的内容。" |
| B13 | B13FocusCard.ets | "这张卡片，读屏用户单指摸到时希望能预览详情（展开），焦点进入时展开、焦点离开时收起，帮我实现。" |
| B16 | B16DefaultFocus.ets | "搜索页里搜索输入框是核心组件，希望进入页面后读屏第一个聚焦、第一个朗读的就是它，帮我实现。" |
| B20 | B20HoverText.ets | "质检卡片被读屏用户摸到时，希望卡片上的文字自动变成'已检查完成'，怎么做？帮我实现。" |
| B23 | B23ThemeList.ets | "主题选择列表，读屏用户听不出当前选的是哪个主题，帮我适配。" |
| B26 | （无页面，代码随输入内联） | "为什么这段代码在accessibilityGroup有编译报错？"（完整输入含随附代码，见下方 B26 输入全文） |

### B26 输入全文（含随附代码，整段一起输入 Agent）

```text
为什么这段代码在accessibilityGroup有编译报错？

@Entry
@Component
struct B26GroupRole {

  build() {
    Column({ space: 24 }) {
      Column() {
        Text('是否开始功能')
        Toggle({ type: ToggleType.Switch, isOn: false})
          .onChange((isOn: boolean) => {
            console.info('Component status: ' + isOn)
          })
      }
      .accessibilityGroup(true, {
        stateControllerRoleType: AccessibilityRoleType.TOGGLER,
        actionControllerRoleType: AccessibilityRoleType.TOGGLER
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

> 注：该代码为 API 23+ 符号写法，**仅存在于输入中**，不落盘为本工程页面（落盘会导致全工程编译失败）。

