# 组件级沉浸实现（IMM-02）

## 方案 A：组件页面沉浸

使用 `.ignoreLayoutSafeArea()` + `.height(LayoutPolicy.matchParent)`，页面背景与布局均扩展至避让区。

```typescript
Column() {
  // 页面内容
}
.ignoreLayoutSafeArea()
.height(LayoutPolicy.matchParent)
```

> 此方案内容易与避让区元素冲突，需配合 `getWindowAvoidArea()` + `on('avoidAreaChange')` 手动处理避让。避让处理方式详见 [imm-04-avoid-area-handling.md](imm-04-avoid-area-handling.md)。

## 方案 B：安全区域拓展

使用 `.expandSafeArea()` 属性，将组件安全区域延伸至状态栏或导航条区域。

### 上下不同色场景

```typescript
@Entry
@Component
struct ExpandSafeAreaExample {
  build() {
    Column() {
      Row() {
        Text('Top Content').fontSize(40).textAlign(TextAlign.Center).width('100%')
      }.backgroundColor('#2786d9')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])  // 顶部延伸至状态栏

      Row() {
        Text('Display Content').fontSize(30)
      }.backgroundColor(Color.White).padding(20).borderRadius(15).width('80%')

      Row() {
        Text('Bottom Content').fontSize(40).textAlign(TextAlign.Center).width('100%')
      }.backgroundColor('#96dffa')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])  // 底部延伸至导航条
    }
    .width('100%').height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#d5d5d5')
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
```

### 背景图场景

```typescript
@Entry
@Component
struct BackgroundImageExample {
  build() {
    Stack() {
      Image($r('app.media.bg'))
        .height('100%').width('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }.height('100%').width('100%')
  }
}
```

### 扩展安全区域原理

1. 布局阶段按照安全区范围大小进行 UI 元素布局
2. 布局完成后查看设置了 expandSafeArea 的组件边界（不包括 margin）是否和安全区边界相交
3. 如果相交，根据 expandSafeArea 传递的属性扩大组件绘制区域覆盖状态栏、导航区域
4. 仅改变组件自身绘制大小，不进行二次布局，不影响子节点和兄弟节点
5. 子节点可单独设置该属性，需确保父组件未设置 clip 等裁剪属性

### safeAreaPadding 属性

组件可设置通用属性 `safeAreaPadding`，给自身添加组件级安全区域。该属性作为一种特殊边距，在提供布局约束的同时作为安全区可被系统组件利用。

- 位于原有的 padding 内侧（border → padding → safeAreaPadding → 内容区）
- 当容器可用空间不足以满足 safeAreaPadding 时，优先分配给左侧和上侧，其次右侧和下侧
- Navigation、List、Scroll、Tabs 等系统组件可利用 safeAreaPadding 实现扩大裁剪范围等能力

## 限制条件

| 限制 | 说明 |
| --- | --- |
| 边界重合要求 | 组件必须与安全区域边界重合（如顶部组件紧贴屏幕顶部） |
| 尺寸限制 | 配置 expandSafeArea 的组件不能设固定宽高（百分比除外） |
| 滚动容器限制 | 父容器是滚动容器时，子组件 expandSafeArea 无效 |
| Video 组件限制 | Video 的 expandSafeArea 仅扩展背景，视频显示内容区域不扩展 |
