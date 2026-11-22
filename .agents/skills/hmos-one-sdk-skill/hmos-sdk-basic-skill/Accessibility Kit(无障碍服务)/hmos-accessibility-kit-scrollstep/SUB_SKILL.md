---
name: hmos-accessibility-kit-scrollstep
description: 配置Slider组件的无障碍滚动步数，支持屏幕朗读模式下通过上下扫动手势调节滑动条，仅对Slider组件生效，取值范围为[1, (max-min)/step]，适用于视频进度、音量调节等需要精细控制的场景
---

# 自定义无障碍滚动步数技能

## 功能描述

本技能用于配置Slider组件的无障碍滚动步数（scrollStep），为视障用户提供更友好的滑动条调节体验。当屏幕朗读功能开启时，用户可通过上下扫动手势调节已聚焦的滑动条，每次调节的实际步长为scrollStep×step，避免连续调节时重复播报相同状态值。

**核心能力**：
- 设置无障碍滚动操作步数（scrollStep）
- 控制屏幕朗读模式下的滑动条调节步长
- 避免重复播报相同状态值，提升用户体验

**适用范围**：
- 仅对Slider组件生效
- 需配合Slider组件的min、max、step参数使用
- 适用于屏幕朗读开启的场景

**技术限制**：
- scrollStep取值范围：[1, (max-min)/step]
- 默认值为1，超出范围时取默认值1
- 非整数时向下取整

## 使用场景

### 触发词
- "自定义无障碍滚动步数"
- "设置scrollStep"
- "配置滑动条无障碍操作步数"
- "屏幕朗读滑动条调节"
- "无障碍滑动条步数"

### 能做
- 为Slider组件配置无障碍滚动步数
- 设置屏幕朗读模式下的调节步长
- 避免连续调节时重复播报相同状态值
- 提升视障用户的滑动条使用体验

### 绝不做
- 不适用于其他组件（如List、Grid等）
- 不替代Slider组件的step属性
- 不处理非屏幕朗读场景的交互
- 不支持超出取值范围的scrollStep设置

### 补充
- 仅在屏幕朗读模式下生效
- 实际调节步长 = scrollStep × step
- 需确保每次调节步长 ≥ 取值范围的1%
- 推荐用于视频进度、音量调节等精细控制场景

## 调用规范和规则

### 输入约束
- scrollStep类型：number
- scrollStep取值范围：[1, (max-min)/step]
- 必须配合Slider组件使用
- Slider组件必须设置min、max、step参数

### 执行约束
- 仅在屏幕朗读模式下触发
- 通过上下扫动手势触发调节
- 每次调节后自动播报当前状态值
- 调节步长 = scrollStep × step

### 内容约束
- 禁止对非Slider组件配置scrollStep
- 禁止超出取值范围设置scrollStep
- 禁止使用负数或0作为scrollStep值
- 禁止使用非数值类型的scrollStep

### 降级约束
- scrollStep超出范围时自动取默认值1
- scrollStep为非整数时向下取整
- Slider组件未设置step时，step默认为1
- 网络异常不影响本地配置生效

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认使用Slider组件
2. 确认Slider组件已设置min、max、step参数
3. 计算scrollStep的取值范围上限：(max-min)/step
4. 确认scrollStep值在有效范围内

**参数准备**：
```typescript
// ArkTS示例
@State scrollStep: number = 3; // 自定义滚动步数

// Slider组件参数
Slider({
  min: 0,      // 最小值
  max: 100,    // 最大值
  value: 10,   // 当前值
  step: 10,    // 基础步长
  style: SliderStyle.OutSet
})
```

### 步骤2：调用API

**示例代码**：
```typescript
// 导入必要模块（无需额外导入，Slider为内置组件）

@Entry
@Component
struct AccessibilitySliderExample {
  @State scrollStep: number = 3;
  @State currentValue: number = 10;

  build() {
    NavDestination() {
      Column() {
        // 创建滑动条并配置无障碍滚动步数
        Slider({
          min: 0,
          max: 100,
          value: this.currentValue,
          step: 10,
          style: SliderStyle.OutSet
        })
          // 配置无障碍滚动步数
          .accessibilityActionOptions({ scrollStep: this.scrollStep })
          .onChange((value: number, mode: SliderChangeMode) => {
            this.currentValue = value;
            console.info(`Slider value changed: ${value}, mode: ${mode}`);
          })
      }
      .width('100%')
      .height('100%')
    }
    .title('Accessibility Slider Example')
  }
}
```

### 步骤3：错误处理

```typescript
// 参数校验和错误处理
@Entry
@Component
struct SafeAccessibilitySlider {
  @State scrollStep: number = 3;
  @State sliderValue: number = 10;
  private min: number = 0;
  private max: number = 100;
  private step: number = 10;

  // 计算scrollStep最大值
  getScrollStepMax(): number {
    return Math.floor((this.max - this.min) / this.step);
  }

  // 校验scrollStep值
  validateScrollStep(value: number): number {
    const maxScrollStep = this.getScrollStepMax();
    
    if (value < 1 || value > maxScrollStep) {
      console.warn(`scrollStep ${value} is out of range [1, ${maxScrollStep}], using default value 1`);
      return 1;
    }
    
    if (!Number.isInteger(value)) {
      const flooredValue = Math.floor(value);
      console.warn(`scrollStep ${value} is not integer, using floor value ${flooredValue}`);
      return flooredValue;
    }
    
    return value;
  }

  build() {
    Column() {
      Slider({
        min: this.min,
        max: this.max,
        value: this.sliderValue,
        step: this.step,
        style: SliderStyle.OutSet
      })
        .accessibilityActionOptions({ 
          scrollStep: this.validateScrollStep(this.scrollStep) 
        })
        .onChange((value: number, mode: SliderChangeMode) => {
          this.sliderValue = value;
          console.info(`Value: ${value}, Mode: ${mode}`);
        })
    }
  }
}
```

### 步骤4：降级处理

```typescript
// 降级处理示例
@Entry
@Component
struct FallbackAccessibilitySlider {
  @State scrollStep: number = 500; // 超出范围的值
  @State actualScrollStep: number = 1; // 实际生效的值

  aboutToAppear() {
    // 降级处理：超出范围时使用默认值
    const maxScrollStep = Math.floor(100 / 10); // (max-min)/step = 10
    if (this.scrollStep < 1 || this.scrollStep > maxScrollStep) {
      console.warn(`scrollStep ${this.scrollStep} is invalid, fallback to 1`);
      this.actualScrollStep = 1;
    } else {
      this.actualScrollStep = Math.floor(this.scrollStep);
    }
  }

  build() {
    Column() {
      Text(`Configured scrollStep: ${this.scrollStep}`)
      Text(`Actual scrollStep: ${this.actualScrollStep}`)
      
      Slider({
        min: 0,
        max: 100,
        value: 40,
        step: 10
      })
        .accessibilityActionOptions({ scrollStep: this.actualScrollStep })
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| INVALID_SCROLL_STEP | scrollStep值超出取值范围 | 使用默认值1或调整到有效范围[1, (max-min)/step] |
| NON_INTEGER_SCROLL_STEP | scrollStep为非整数 | 向下取整处理 |
| INVALID_SLIDER_CONFIG | Slider组件未正确配置min/max/step | 确保Slider组件设置了min、max、step参数 |
| COMPONENT_NOT_SLIDER | 尝试对非Slider组件配置scrollStep | 仅对Slider组件使用accessibilityActionOptions |

## 编译和修复问题

### 依赖声明
无需额外依赖，Slider和accessibilityActionOptions为ArkUI内置组件和属性。

### 环境要求
- HarmonyOS API Version 10+
- DevEco Studio 3.0+
- ArkTS语言支持

### 常见编译问题

**问题1：accessibilityActionOptions未定义**
```
Error: Property 'accessibilityActionOptions' does not exist on type 'SliderAttribute'
```
**解决方法**：确保使用最新的HarmonyOS SDK版本（API 10+），accessibilityActionOptions在较新版本中引入。

**问题2：scrollStep类型错误**
```
Error: Type 'string' is not assignable to type 'number'
```
**解决方法**：确保scrollStep为number类型，不要使用字符串。

**问题3：Slider组件参数缺失**
```
Warning: Slider component missing required parameters
```
**解决方法**：确保Slider组件设置了min、max、value、step等必要参数。

## 常见问题与解决方法

### Q1：scrollStep设置后没有生效？
**原因**：
- scrollStep值超出取值范围
- 未在屏幕朗读模式下测试
- 对非Slider组件配置

**解决方法**：
- 检查scrollStep值是否在[1, (max-min)/step]范围内
- 开启屏幕朗读功能后测试
- 确保配置在Slider组件上

### Q2：调节步长不符合预期？
**原因**：
- 实际步长 = scrollStep × step，需要综合考虑
- scrollStep被向下取整处理
- 超出范围被降级为默认值1

**解决方法**：
- 根据期望的实际步长反推scrollStep值
- 使用整数scrollStep值
- 确保scrollStep在有效范围内

### Q3：屏幕朗读未播报状态值？
**原因**：
- Slider组件未设置onChange事件
- 屏幕朗读功能未开启
- 组件未获得焦点

**解决方法**：
- 为Slider组件添加onChange回调
- 确保屏幕朗读功能已开启
- 通过扫动手势聚焦Slider组件

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "component": "Slider",
  "accessibilityConfig": {
    "scrollStep": 3,
    "actualStepLength": 30,
    "effectiveRange": {
      "min": 1,
      "max": 10
    }
  },
  "sliderConfig": {
    "min": 0,
    "max": 100,
    "step": 10,
    "currentValue": 10
  },
  "apiUsed": [
    "Slider",
    "accessibilityActionOptions"
  ]
}
```

## 参考文档

- [API开发指南](references/accessibilityactionoptions-scrollstep-guide.md)
- [Slider组件参考](references/ts-basic-components-slider.md)
- [无障碍属性参考](references/ts-universal-attributes-accessibility.md)

**在线文档**：
- [Slider组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-slider)
- [无障碍属性](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)

## 完整示例代码

- [ArkTS示例](assets/accessibility_slider_example.ets)
- [参数校验示例](assets/safe_accessibility_slider.ets)
- [降级处理示例](assets/fallback_accessibility_slider.ets)

## 测试用例

### 正向测试用例
- [正常配置scrollStep](tests/test_positive_scrollstep.ets)：在有效范围内设置scrollStep值
- [整数scrollStep配置](tests/test_integer_scrollstep.ets)：使用整数scrollStep值
- [动态scrollStep调整](tests/test_dynamic_scrollstep.ets)：动态改变scrollStep值

### 边界测试用例
- [最小scrollStep值](tests/test_min_scrollstep.ets)：设置scrollStep为1
- [最大scrollStep值](tests/test_max_scrollstep.ets)：设置scrollStep为(max-min)/step
- [临界值测试](tests/test_boundary_scrollstep.ets)：测试scrollStep边界值

### 异常测试用例
- [超出范围scrollStep](tests/test_out_of_range_scrollstep.ets)：设置超出范围的scrollStep值
- [非整数scrollStep](tests/test_non_integer_scrollstep.ets)：设置非整数scrollStep值
- [负数scrollStep](tests/test_negative_scrollstep.ets)：设置负数scrollStep值
- [零值scrollStep](tests/test_zero_scrollstep.ets)：设置scrollStep为0