---
name: hmos-accessibility-kit-card-auto-center
description: 实现横向滚动容器中卡片无障碍聚焦时自动居中显示，支持屏幕朗读场景，适用于无障碍体验提升
---

# 卡片自动居中技能

## 功能描述

本技能用于在横向滚动容器中实现卡片自动居中功能，确保屏幕朗读场景下聚焦卡片的可访问性。当用户通过无障碍服务聚焦到卡片时，卡片会自动居中显示，以凸显其重要性和详细信息。

**核心能力**：
- 监听卡片无障碍聚焦事件
- 自动滚动容器使聚焦卡片居中显示
- 支持ForEach和LazyForEach渲染方式
- 配合滚动容器居中限位功能

**适用范围**：
- 横向滚动容器（List、Grid等）
- 卡片式布局界面
- 无障碍服务开启场景

**限制条件**：
- 需使用Scroller控制器
- 卡片需支持无障碍聚焦
- 需配合scrollSnapAlign居中对齐

**典型场景**：
- 屏幕朗读模式下的卡片浏览
- 无障碍用户体验优化
- 横向卡片列表的焦点管理

## 使用场景

### 触发词
- "卡片自动居中"
- "无障碍聚焦居中"
- "屏幕朗读卡片居中"
- "Accessibility聚焦"
- "横向滚动居中"
- "卡片焦点管理"

### 能做
- 为横向滚动容器中的卡片添加无障碍聚焦监听
- 实现聚焦卡片自动居中滚动效果
- 配合LazyForEach或ForEach获取卡片索引
- 使用scrollToIndex接口实现精确滚动定位
- 设置ScrollAlign.CENTER实现居中对齐

### 绝不做
- 不用于纵向滚动容器（仅支持横向）
- 不处理普通点击事件（仅处理无障碍聚焦）
- 不替代滚动容器的基本滚动功能
- 不用于非卡片式布局场景

### 补充
- 必须配合scrollSnapAlign设置居中对齐才能实现完美居中效果
- 使用LazyForEach时需实现IDataSource接口
- onAccessibilityFocus回调需正确判断isFocus参数
- scrollToIndex的align参数建议使用ScrollAlign.CENTER

## 调用规范和规则

### 输入约束
- 卡片数量：无限制，建议使用LazyForEach优化大数据量场景
- 卡片索引：必须为有效索引值（0到totalCount-1）
- Scroller控制器：必须正确绑定到滚动容器组件
- 组件类型：必须为List、Grid、WaterFlow等支持的滚动组件

### 执行约束
- 最大滚动耗时：取决于卡片数量和动画设置
- 聚焦回调执行：异步执行，不影响主线程
- 滚动动画：smooth参数控制是否启用动画（建议false避免性能问题）
- 数据刷新：LazyForEach/ForEach刷新后需等待完成再调用scrollToIndex

### 内容约束
- 禁止使用：不支持ArcList以外的自定义滚动组件
- 禁止操作：不能在onAccessibilityFocus回调中修改状态变量（可能导致渲染异常）
- 禁止参数：scrollToIndex的value参数不能为负数或超出最大索引值
- 禁止高危函数：不建议在keyGenerator中使用JSON.stringify（性能问题）

### 降级约束
- 数据源异常：使用try-catch捕获getData异常，返回默认数据
- 索引超出范围：scrollToIndex不生效，保持当前滚动位置
- Scroller未绑定：捕获错误码100004，提示用户检查绑定关系
- 无障碍服务未开启：回调不触发，不影响普通用户使用体验

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认滚动容器为横向布局（listDirection设置为Axis.Horizontal）
2. 确认Scroller控制器已正确初始化
3. 确认scrollSnapAlign已设置为ScrollSnapAlign.CENTER
4. 确认数据源已准备好（实现IDataSource接口或数组数据）

**参数准备**：

```typescript
// ArkTS示例 - 数据源实现
class ListDataSource implements IDataSource {
  private list: number[] = [];
  
  constructor(list: number[]) {
    this.list = list;
  }
  
  totalCount(): number {
    return this.list.length;
  }
  
  getData(index: number): number {
    if (index < 0 || index >= this.list.length) {
      console.warn('Invalid index: ' + index);
      return 0; // 降级返回默认值
    }
    return this.list[index];
  }
  
  registerDataChangeListener(listener: DataChangeListener): void {
    // 注册数据变化监听器（可选实现）
  }
  
  unregisterDataChangeListener(listener: DataChangeListener): void {
    // 注销数据变化监听器（可选实现）
  }
}
```

### 步骤2：创建滚动容器和Scroller

**示例代码**：

```typescript
// 导入必要组件
import { IDataSource, DataChangeListener } from '@ohos.arkui';

// 组件定义
@Entry
@Component
struct CardAutoCenterExample {
  // 初始化数据源
  private arr: ListDataSource = new ListDataSource([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  
  // 初始化Scroller控制器
  private scrollerForList: Scroller = new Scroller();
  
  build() {
    NavDestination() {
      Column() {
        List({ 
          space: 20, 
          initialIndex: 0, 
          scroller: this.scrollerForList 
        }) {
          LazyForEach(this.arr, (index: number) => {
            ListItem() {
              Text('' + index)
                .width('100%')
                .height(100)
                .fontSize(16)
                .textAlign(TextAlign.Center)
                .borderRadius(10)
                .backgroundColor(0xFFFFFF)
            }
            .width('60%') // 设置卡片宽度占比
            .onClick(() => {
              // 设置点击事件，使组件可被无障碍聚焦
              console.info('Card clicked: ' + index);
            })
            // 步骤3中添加无障碍聚焦回调
          }, (item: string) => item.toString())
        }
        .width('90%')
        .scrollBar(BarState.Off)
        .scrollSnapAlign(ScrollSnapAlign.CENTER) // 设置居中对齐
        .listDirection(Axis.Horizontal) // 设置横向滚动
      }
      .width('100%')
      .height('100%')
      .backgroundColor(0xDCDCDC)
      .padding({ top: 5 })
    }
    .title('卡片自动居中示例')
  }
}
```

### 步骤3：注册无障碍聚焦回调

**示例代码**：

```typescript
// 在ListItem组件上添加onAccessibilityFocus回调
.onAccessibilityFocus((isFocus: boolean) => {
  if (isFocus) {
    // 卡片获得焦点时，滚动到居中位置
    this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER);
    console.info('Card focused and centered: ' + index);
  } else {
    // 卡片失去焦点时（可选处理）
    console.info('Card lost focus: ' + index);
  }
})
```

**完整示例代码**：

```typescript
import { IDataSource, DataChangeListener } from '@ohos.arkui';

class ListDataSource implements IDataSource {
  private list: number[] = [];
  
  constructor(list: number[]) {
    this.list = list;
  }
  
  totalCount(): number {
    return this.list.length;
  }
  
  getData(index: number): number {
    try {
      if (index < 0 || index >= this.list.length) {
        console.warn('getData: Invalid index ' + index + ', returning default value');
        return 0;
      }
      return this.list[index];
    } catch (error) {
      console.error('getData error:', error.message);
      return 0;
    }
  }
  
  registerDataChangeListener(listener: DataChangeListener): void {}
  unregisterDataChangeListener(listener: DataChangeListener): void {}
}

@Entry
@Component
struct CardAutoCenterComplete {
  title: string = '卡片自动居中完整示例';
  private arr: ListDataSource = new ListDataSource([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  private scrollerForList: Scroller = new Scroller();
  
  build() {
    NavDestination() {
      Column() {
        List({ space: 20, initialIndex: 0, scroller: this.scrollerForList }) {
          LazyForEach(this.arr, (index: number) => {
            ListItem() {
              Text('' + index)
                .width('100%')
                .height(100)
                .fontSize(16)
                .textAlign(TextAlign.Center)
                .borderRadius(10)
                .backgroundColor(0xFFFFFF)
            }
            .width('60%')
            .onClick(() => {
              console.info('Card clicked: ' + index);
            })
            .onAccessibilityFocus((isFocus: boolean) => {
              if (isFocus) {
                try {
                  this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER);
                  console.info('Accessibility focus: Card ' + index + ' centered successfully');
                } catch (error) {
                  console.error('scrollToIndex failed:', error.message);
                }
              }
            })
          }, (item: string) => item.toString())
        }
        .width('90%')
        .scrollBar(BarState.Off)
        .scrollSnapAlign(ScrollSnapAlign.CENTER)
        .listDirection(Axis.Horizontal)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(0xDCDCDC)
      .padding({ top: 5 })
    }
    .title(this.title)
  }
}
```

### 步骤4：错误处理

```typescript
// 错误处理代码示例
.onAccessibilityFocus((isFocus: boolean) => {
  if (isFocus) {
    try {
      // 参数校验
      if (index < 0 || index >= this.arr.totalCount()) {
        console.warn('Invalid index ' + index + ', scrollToIndex skipped');
        return;
      }
      
      // 执行滚动
      this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER);
      
    } catch (error) {
      // 错误码处理
      if (error.code === 100004) {
        console.error('Scroller not bound to component');
      } else if (error.code === 401) {
        console.error('Parameter error:', error.message);
      } else {
        console.error('Unknown error:', error.message);
      }
    }
  }
})
```

### 步骤5：降级处理

```typescript
// 降级处理代码示例
class SafeListDataSource implements IDataSource {
  private list: number[] = [];
  private fallbackValue: number = -1;
  
  constructor(list: number[], fallback?: number) {
    this.list = list;
    if (fallback !== undefined) {
      this.fallbackValue = fallback;
    }
  }
  
  totalCount(): number {
    // 降级处理：返回最小值0
    return Math.max(0, this.list.length);
  }
  
  getData(index: number): number {
    try {
      // 边界检查和降级处理
      if (this.list.length === 0) {
        console.warn('Empty data source, returning fallback value');
        return this.fallbackValue;
      }
      
      const safeIndex = Math.max(0, Math.min(index, this.list.length - 1));
      return this.list[safeIndex];
      
    } catch (error) {
      console.error('getData failed, using fallback:', error.message);
      return this.fallbackValue;
    }
  }
  
  registerDataChangeListener(listener: DataChangeListener): void {}
  unregisterDataChangeListener(listener: DataChangeListener): void {}
}

// 使用降级方案的数据源
private safeArr: SafeListDataSource = new SafeListDataSource(
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 
  0 // 降级默认值
);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误、参数验证失败 | 检查scrollToIndex的参数：value必须为有效索引，align必须为ScrollAlign枚举值 |
| 100004 | 控制器未绑定到组件 | 确认Scroller已通过scroller参数绑定到List组件 |
| -1 | 索引超出范围 | 确认index值在[0, totalCount()-1]范围内 |
| Invalid index | getData获取数据失败 | 实现IDataSource接口的getData方法，添加边界检查和异常处理 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@ohos.arkui": "latest"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 18+（onAccessibilityFocus支持）
- DevEco Studio：3.1+
- ArkTS语言支持：需要支持LazyForEach和Scroller

### 常见编译问题

**问题1：IDataSource接口未实现**
```
Error: Class 'ListDataSource' incorrectly implements interface 'IDataSource'.
Property 'totalCount' is missing in type 'ListDataSource'.
```
**解决方法**：完整实现IDataSource的所有方法：totalCount、getData、registerDataChangeListener、unregisterDataChangeListener

**问题2：Scroller未绑定**
```
Error code 100004: Controller not bound to component.
```
**解决方法**：在List组件构造函数中传入scroller参数：`List({ scroller: this.scrollerForList })`

**问题3：ScrollAlign类型错误**
```
Error: 'ScrollAlign' is not defined.
```
**解决方法**：导入或使用完整枚举路径：`ScrollAlign.CENTER`

**问题4：LazyForEach性能警告**
```
Warning: Avoid using JSON.stringify in keyGenerator for performance.
```
**解决方法**：使用简单的键值生成函数：`(item: string) => item.toString()`

## 常见问题与解决方法

### Q1：聚焦后卡片没有居中显示
**原因**：
1. scrollSnapAlign未设置为CENTER
2. scrollToIndex的align参数未设置为ScrollAlign.CENTER
3. List的listDirection未设置为Axis.Horizontal

**解决方法**：
- 检查List组件配置：`.scrollSnapAlign(ScrollSnapAlign.CENTER).listDirection(Axis.Horizontal)`
- 检查scrollToIndex调用：`scrollToIndex(index, false, ScrollAlign.CENTER)`
- 确认卡片宽度占比合理（建议60%-80%）

### Q2：无障碍聚焦回调不触发
**原因**：
1. 无障碍服务未开启
2. ListItem组件不支持聚焦（未设置onClick等可交互事件）
3. API版本低于18

**解决方法**：
- 确认设备已开启屏幕朗读等无障碍服务
- 为ListItem添加onClick事件，使其可被聚焦
- 升级到API version 18及以上版本

### Q3：LazyForEach数据刷新后scrollToIndex失效
**原因**：数据源刷新未完成就调用scrollToIndex

**解决方法**：
- 等待数据刷新完成后再调用scrollToIndex
- 使用DataChangeListener监听数据变化完成事件
- 在onDataReloaded回调后再执行滚动操作

### Q4：横向滚动时卡片间距不一致
**原因**：space参数设置不合适，或卡片宽度占比设置有问题

**解决方法**：
- 调整List的space参数：`List({ space: 20 })`
- 统一设置ListItem宽度：`.width('60%')`
- 确认卡片内容布局不会影响间距

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "feature": "卡片自动居中功能已实现",
  "componentsUsed": [
    "List组件",
    "LazyForEach渲染",
    "Scroller控制器",
    "onAccessibilityFocus回调"
  ],
  "apiUsed": [
    "IDataSource.totalCount()",
    "IDataSource.getData()",
    "Scroller.scrollToIndex()",
    "onAccessibilityFocus()",
    "ScrollAlign.CENTER"
  ],
  "accessibilityEnabled": true,
  "scrollDirection": "horizontal",
  "centerAlignment": true,
  "performanceOptimized": "使用LazyForEach实现懒加载，smooth=false避免性能问题"
}
```

## 参考文档

- [API开发指南 - 卡片自动居中的场景](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-card-automatically-centered)
- [API参考 - ForEach循环渲染](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-rendering-control-foreach)
- [API参考 - LazyForEach懒加载](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-rendering-control-lazyforeach)
- [API参考 - onAccessibilityFocus无障碍聚焦](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-accessibility-event)
- [API参考 - scrollToIndex滚动定位](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-scroll)
- [API参考 - List组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-list)

## 完整示例代码

- [ArkTS完整示例 - 卡片自动居中](assets/card-auto-center-example.ets)
- [数据源实现示例](assets/list-data-source.ets)
- [配置文件示例](assets/list-config.json)

## 测试用例

### 正向测试用例
- [测试：卡片聚焦后自动居中](tests/test_focus_center.py) - 验证无障碍聚焦后卡片居中效果
- [测试：LazyForEach数据渲染](tests/test_lazyforeach_render.py) - 验证数据源正确渲染
- [测试：横向滚动布局](tests/test_horizontal_scroll.py) - 验证横向滚动和居中对齐

### 边界测试用例
- [测试：最小数据量（1个卡片）](tests/test_min_cards.py) - 验证最小场景的正确性
- [测试：最大数据量（1000个卡片）](tests/test_max_cards.py) - 验证性能和稳定性
- [测试：边界索引（0和maxIndex）](tests/test_boundary_index.py) - 验证边界索引处理

### 异常测试用例
- [测试：空数据源](tests/test_empty_data.py) - 验证空数据降级处理
- [测试：无效索引](tests/test_invalid_index.py) - 验证索引超出范围处理
- [测试：Scroller未绑定](tests/test_scroller_unbound.py) - 验证错误码100004处理
- [测试：无障碍服务未开启](tests/test_accessibility_disabled.py) - 验证降级不影响普通用户