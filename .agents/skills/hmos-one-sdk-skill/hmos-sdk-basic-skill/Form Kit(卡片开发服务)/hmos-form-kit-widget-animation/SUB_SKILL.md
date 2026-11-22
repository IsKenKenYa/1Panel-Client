---
name: hmos-form-kit-widget-animation
description: 为ArkTS卡片组件添加动效,支持显式动画/属性动画/组件内转场,最长播放时长2000ms(API version 10+),静态卡片不支持,适用于卡片UI界面动效实现
---

# ArkTS卡片为组件添加动效技能

## 功能描述

本技能用于在ArkTS动态卡片中为组件添加动画效果,提升用户交互体验。支持三种动画类型:显式动画(animateTo)、属性动画(animation)、组件内转场(transition)。每种动画类型都有特定的使用场景和限制条件。

### 支持的动画类型

1. **显式动画(animateTo)**:全局显式动画接口,用于在闭包代码中插入过渡动效
2. **属性动画(animation)**:组件属性变化时的渐变过渡效果,如旋转、缩放、透明度变化
3. **组件内转场(transition)**:组件插入和删除时的过渡动效,主要用于容器组件中的子组件

### 动效参数限制

| 参数名 | 说明 | 限制描述 |
|-------|------|---------|
| duration | 动画播放时长 | 最长2000ms(API version 10+),超过则固定为2000ms。API version 9最长1000ms |
| tempo | 动画播放速度 | 卡片中禁止设置,使用默认值1 |
| delay | 动画延迟时长 | 卡片中禁止设置,使用默认值0ms |
| iterations | 动画播放次数 | 卡片中禁止设置,使用默认值1次 |

**重要限制**:静态卡片不支持使用动效能力,仅适用于动态卡片。

## 使用场景

### 触发词
- "添加卡片动效"
- "卡片动画"
- "ArkTS卡片动效"
- "卡片组件动画"
- "卡片转场效果"
- "卡片旋转动画"

### 能做
- 为动态卡片中的组件添加旋转、缩放、透明度等属性动画
- 实现组件插入和删除时的转场动效
- 创建渐变过渡动画效果提升用户体验
- 实现按钮点击时的交互动画
- 实现图片出现和消失的动画效果

### 绝不做
- 为静态卡片添加动效(静态卡片不支持动效)
- 设置duration超过2000ms(会被限制为2000ms)
- 设置tempo参数(禁止设置,使用默认值1)
- 设置delay参数(禁止设置,使用默认值0ms)
- 设置iterations参数(禁止设置,使用默认值1次)
- 在组件构造器中使用属性动画(对构造器属性不生效)
- 在animation之后定义的属性上应用动画(只对animation之前的属性生效)

### 补充
- 仅适用于ArkTS动态卡片,静态卡片不支持
- 动画时长有严格限制,最长2000ms(API version 10+)
- 属性动画只对写在animation前面的属性生效
- 组件转场通过if条件、ForEach新增删除或visibility属性改变触发

## 调用规范和规则

### 输入约束
- 动画时长:最大2000ms(API version 10+),超过则自动限制为2000ms
- 动画曲线:支持Curve枚举值或自定义曲线字符串
- 播放模式:支持PlayMode.Normal、PlayMode.Alternate等
- 动画类型:仅支持属性动画(animation)和组件转场(transition)

### 执行约束
- 最大动画时长:2000ms(API version 10+),1000ms(API version 9)
- 禁止设置tempo、delay、iterations参数
- 属性动画必须在属性定义之后立即调用
- 组件转场必须通过状态变化触发(if/ForEach/visibility)

### 内容约束
- 禁止为静态卡片添加动效
- 禁止使用超过2000ms的动画时长
- 禁止设置tempo/delay/iterations参数
- 禁止在animation之后定义需要动画的属性
- 禁止对组件构造器中的属性应用动画

### 降级约束
- 动画时长超过限制:自动降级为2000ms(API version 10+)
- 静态卡片请求动效:提示用户静态卡片不支持,建议使用动态卡片
- 参数设置违规:提示用户禁止设置该参数,使用默认值

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 确认卡片类型为动态卡片(静态卡片不支持动效)
2. 确认目标组件支持动画属性(width/height/backgroundColor/opacity/scale/rotate/translate等)
3. 确认动画时长不超过2000ms(API version 10+)
4. 确认不设置禁止参数(tempo/delay/iterations)

**参数准备**:
```typescript
// ArkTS示例 - 属性动画参数准备
const animationParams = {
  duration: 1000,           // 动画时长,最长2000ms
  curve: Curve.EaseOut,     // 动画曲线
  playMode: PlayMode.Normal // 播放模式
};

// ArkTS示例 - 组件转场参数准备
const transitionEffect = TransitionEffect.OPACITY
  .animation({ duration: 1000, curve: Curve.Ease })
  .combine(TransitionEffect.rotate({ z: 1, angle: 180 }));
```

### 步骤2:实现组件自身动效(属性动画)

**示例代码**:
```typescript
// entry/src/main/ets/widget/pages/AnimationCard.ets
@Entry
@Component
struct AnimationCard {
  @State rotateAngle: number = 0;
  
  build() {
    Row() {
      Button('change rotate angle')
        .height('20%')
        .width('90%')
        .margin('5%')
        .onClick(() => {
          // 点击按钮改变旋转角度
          this.rotateAngle = (this.rotateAngle === 0 ? 90 : 0);
        })
        .rotate({ angle: this.rotateAngle })  // 定义旋转属性(必须在animation之前)
        .animation({
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal,
        })
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
  }
}
```

**关键要点**:
1. 属性定义必须在animation之前
2. rotate属性定义后立即调用animation
3. 状态变化触发动画(rotateAngle从0变为90)
4. 动画参数中不设置禁止参数(tempo/delay/iterations)

### 步骤3:实现组件转场动效

**示例代码**:
```typescript
// entry/src/main/ets/widget/pages/TransitionEffectExample.ets
@Entry
@Component
struct TransitionEffectExample {
  @State flag: boolean = true;
  @State show: string = 'show';
  
  build() {
    Column() {
      Button(this.show)
        .width(80)
        .height(30)
        .margin(30)
        .onClick(() => {
          // 点击按钮控制图片显示和消失
          if (this.flag) {
            this.show = 'hide';
          } else {
            this.show = 'show';
          }
          this.flag = !this.flag;  // 状态变化触发转场
        })
      
      if (this.flag) {
        // 图片出现和消失的转场效果
        // 出现时:透明度从0到1,绕z轴旋转180°到0°
        // 消失时:透明度从1到0,绕z轴旋转0°到180°
        Image($r('app.media.testImg'))
          .width(200)
          .height(200)
          .transition(
            TransitionEffect.OPACITY
              .animation({ duration: 1000, curve: Curve.Ease })
              .combine(TransitionEffect.rotate({ z: 1, angle: 180 }))
          )
      }
    }
    .width('100%')
  }
}
```

**关键要点**:
1. 通过if条件改变触发组件转场
2. TransitionEffect定义出现和消失的效果
3. 使用combine组合多个转场效果
4. animation参数对OPACITY和rotate均生效
5. 动画时长1000ms,符合限制要求

### 步骤4:错误处理

```typescript
// 错误处理示例
@Entry
@Component
struct AnimationWithErrorHandling {
  @State rotateAngle: number = 0;
  
  build() {
    Row() {
      Button('animation')
        .onClick(() => {
          try {
            // 动画参数校验
            const duration = 1500;  // 确保不超过2000ms
            
            if (duration > 2000) {
              console.warn('Animation duration exceeds limit, will be clamped to 2000ms');
            }
            
            this.rotateAngle = (this.rotateAngle === 0 ? 90 : 0);
          } catch (error) {
            console.error('Animation error:', error.message);
          }
        })
        .rotate({ angle: this.rotateAngle })
        .animation({
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal,
        })
    }
    .height('100%')
  }
}
```

### 步骤5:降级处理

```typescript
// 降级处理示例
@Entry
@Component
struct AnimationWithFallback {
  @State rotateAngle: number = 0;
  @State cardType: string = 'dynamic';  // 'dynamic' or 'static'
  
  build() {
    Row() {
      if (this.cardType === 'dynamic') {
        // 动态卡片支持动效
        Button('animation')
          .onClick(() => {
            this.rotateAngle = (this.rotateAngle === 0 ? 90 : 0);
          })
          .rotate({ angle: this.rotateAngle })
          .animation({
            curve: Curve.EaseOut,
            playMode: PlayMode.Normal,
          })
      } else {
        // 静态卡片降级方案:直接改变属性,无动画
        Button('static change')
          .onClick(() => {
            console.warn('Static card does not support animation');
            this.rotateAngle = (this.rotateAngle === 0 ? 90 : 0);
          })
          .rotate({ angle: this.rotateAngle })  // 直接旋转,无动画过渡
      }
    }
    .height('100%')
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| CARD_STATIC_NOT_SUPPORT | 静态卡片不支持动效 | 使用动态卡片或移除动效需求 |
| DURATION_EXCEED_LIMIT | 动画时长超过2000ms | 设置duration≤2000ms,超过会自动限制 |
| PARAM_FORBIDDEN | 设置了禁止参数(tempo/delay/iterations) | 移除该参数设置,使用默认值 |
| ANIMATION_ORDER_ERROR | 属性定义在animation之后 | 将属性定义移到animation之前 |
| CONSTRUCTOR_ANIMATION_ERROR | 对组件构造器属性应用动画 | 移除构造器属性的动画,仅对通用属性应用 |
| TRANSITION_TRIGGER_ERROR | 组件转场未触发 | 确保通过if/ForEach/visibility改变触发 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@ohos/arkui": ">=10.0.0"
  }
}
```

### 环境要求
- API version: 9+ (支持卡片动画)
- API version: 10+ (duration限制为2000ms)
- 开发环境:DevEco Studio 3.1+
- 运行环境:HarmonyOS 3.0+

### 常见编译问题

**问题1:动画时长设置超过限制**
```
Property 'duration' with value 3000 exceeds maximum limit 2000ms
```
**解决方法**:将duration设置为≤2000ms的值,如1000或2000

**问题2:设置禁止参数**
```
Parameter 'tempo' is forbidden in ArkTS card animation
```
**解决方法**:移除tempo参数设置,使用默认值1

**问题3:属性定义顺序错误**
```
Animation defined before property, animation will not apply
```
**解决方法**:将需要动画的属性定义移到animation之前

**问题4:静态卡片使用动效**
```
Static card does not support animation capability
```
**解决方法**:将卡片改为动态卡片或移除动效需求

## 常见问题与解决方法

### Q1:动画时长设置3000ms,实际播放只有2000ms?
**原因**:卡片动画时长有严格限制,超过2000ms会自动限制为2000ms(API version 10+)
**解决方法**:
- 明确了解时长限制,设置≤2000ms的值
- API version 9限制为1000ms,API version 10+限制为2000ms
- 根据目标API版本设置合适的时长

### Q2:为什么设置了tempo参数但动画没有变化?
**原因**:卡片中禁止设置tempo参数,使用默认值1
**解决方法**:
- 移除tempo参数设置
- 接受默认播放速度(tempo=1)
- 如果需要调整动画速度,可通过调整duration实现

### Q3:属性定义在animation之后,动画不生效?
**原因**:属性动画只对写在animation前面的属性生效
**解决方法**:
- 将需要动画的属性定义移到animation之前
- 按照正确的顺序:属性定义 → animation调用
- 示例:.rotate({ angle: this.rotateAngle }).animation({ ... })

### Q4:组件转场动画没有触发?
**原因**:组件转场需要通过特定方式触发(if/ForEach/visibility)
**解决方法**:
- 使用if条件改变触发组件出现和消失
- 使用ForEach新增删除组件触发转场
- 改变visibility属性在Visible和Hidden之间触发
- 确保组件确实被插入或删除

### Q5:静态卡片能否使用动效?
**原因**:静态卡片不支持动效能力
**解决方法**:
- 确认卡片类型,静态卡片无法使用动效
- 如需动效,将卡片改为动态卡片
- 或直接改变属性值,接受无动画过渡的直接跳变

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "animationType": "属性动画|组件转场",
  "durationUsed": "1000ms",
  "curveUsed": "Curve.EaseOut",
  "playModeUsed": "PlayMode.Normal",
  "apiUsed": [
    "animation(AnimateParam)",
    "transition(TransitionEffect)"
  ],
  "cardType": "dynamic",
  "notes": [
    "动画时长符合限制要求",
    "未设置禁止参数",
    "属性定义顺序正确",
    "转场触发方式正确"
  ]
}
```

## 参考文档

- [API开发指南](references/arkts-ui-widget-page-animation.md)
- [属性动画API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-animatorproperty)
- [组件转场API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-transition-animation-component)
- [显式动画API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-explicit-animation)

## 完整示例代码

- [组件旋转动画示例](assets/AnimationCard.ets)
- [组件转场动效示例](assets/TransitionEffectExample.ets)
- [错误处理示例](assets/AnimationWithErrorHandling.ets)
- [降级处理示例](assets/AnimationWithFallback.ets)

## 测试用例

### 正向测试用例
- [组件旋转动画测试](tests/test_animation_positive.py):验证按钮旋转动画正确实现
- [组件转场动效测试](tests/test_transition_positive.py):验证图片出现消失转场效果
- [参数符合限制测试](tests/test_params_positive.py):验证duration≤2000ms且未设置禁止参数

### 边界测试用例
- [动画时长2000ms测试](tests/test_duration_boundary.py):验证最大允许时长
- [API version 9限制测试](tests/test_version9_boundary.py):验证API version 9最长1000ms

### 异常测试用例
- [静态卡片动效测试](tests/test_static_card_exception.py):验证静态卡片不支持动效
- [禁止参数测试](tests/test_forbidden_params_exception.py):验证禁止设置tempo/delay/iterations
- [属性顺序错误测试](tests/test_property_order_exception.py):验证属性定义必须在animation之前