# 自定义属性动画案例集

## 适用场景

| 场景 | 推荐方案 | 选型理由 |
|---|---|---|
| Tab 指示器滑动 | 两个 `@AnimatableExtend` 分别驱动 width + translate | width 是布局属性，标准 `.animation()` 无法驱动，必须扩展 |
| 多元素同步变形 | `AnimatableArithmetic` 自定义类型 + 多个 `@AnimatableExtend` | 多个视觉元素共享同一数据源，一次赋值驱动全部 |
| 图表/数组逐项过渡 | `ChartData` 数组型 `AnimatableArithmetic` | 每个柱子独立插值，差值不同过渡时长自然不同 |

## 核心动画 API 枚举值参考

### @AnimatableExtend 使用说明

| 特性 | 说明 |
|---|---|
| 作用域 | 可修饰 `Column`、`Row`、`Text`、`Image` 等自定义组件 |
| 参数类型 | 支持基础类型 `number`，也支持实现 `AnimatableArithmetic<T>` 的自定义类型 |
| 动画驱动 | 绑定 `.animation()` 后，状态变化自动逐帧插值 |
| 与 `.animation()` 配合 | `@AnimatableExtend` 定义的属性需在其调用后紧跟 `.animation()` 指定曲线和时长 |

### AnimatableArithmetic\<T\> 接口方法

| 方法 | 签名 | 说明 |
|---|---|---|
| `plus()` | `(rhs: T) => T` | 当前值加上目标值 |
| `subtract()` | `(rhs: T) => T` | 当前值减去目标值（计算差值） |
| `multiply()` | `(scale: number) => T` | 当前值乘以插值系数（0~1） |
| `equals()` | `(rhs: T) => boolean` | 判断两值是否相等（决定动画结束） |

> **设计原则：** 自定义可动画类型中只包含需要参与逐帧插值的 `number` 字段。颜色等不可数值插值的属性（`string`、`Resource` 等）不要放入类型中，应拆分为独立的 `@State` 变量单独管理。

### Curve 枚举值（自定义动画常用）

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `Curve.EaseInOut` | 慢-快-慢，两端缓动 | Tab 指示器滑动、天气变形、柱状图切换 |

---

## 场景1：标签下划线滑动

**场景描述：** 仿今日头条 Tab 栏，点击不同标签时底部下划线指示器平滑滑动到对应标签下方，下划线宽度同时逐帧变化，跟手滑动切换。

**解决方案：** 使用 **`@AnimatableExtend(Column)` 扩展 `width` 逐帧布局** + **`@AnimatableExtend(Row)` 扩展 `translate` 位移** + **`.animation()` 隐式动画** + **`onAreaChange` 测量 Tab 栏宽度**

### 步骤 1：定义两个 @AnimatableExtend

```ts
@AnimatableExtend(Column)
function animatableIndicatorWidth(w: number) {
  .width(w)
}

@AnimatableExtend(Row)
function animatableTranslateX(x: number) {
  .translate({ x: x })
}
```

关键点：`animatableIndicatorWidth` 用 `number` 类型驱动 Column 的 `width` 属性逐帧布局变化；`animatableTranslateX` 驱动 Row 的 `translate` 位移。两个装饰器分别作用在不同组件上，实现下划线宽度 + 位置的联动动画。

### 步骤 2：测量宽度 + 计算偏移

```ts
Row() {
  ForEach(this.tabs, (tab: string, index: number) => {
    Column() { Text(tab) }
      .layoutWeight(1)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.currentTab = index
        if (this.tabBarWidth > 0) {
          let tabWidth = this.tabBarWidth / this.tabs.length
          this.indicatorOffsetX = tabWidth * index
        }
      })
  })
}
.width('100%')
.onAreaChange((_oldArea: Area, newArea: Area) => {
  this.tabBarWidth = newArea.width as number
  let tabWidth = (newArea.width as number) / this.tabs.length
  this.indicatorOffsetX = tabWidth * this.currentTab
})
```

关键点：`onAreaChange` 在首次布局完成时获取 Tab 栏实际宽度，据此计算每个 Tab 的等分宽度和下划线初始偏移量。

### 步骤 3：下划线指示器 — 两个 @AnimatableExtend 联动

```ts
Stack() {
  Row() {
    Column() {}
      .animatableIndicatorWidth(this.indicatorWidth)
      .height(3)
      .borderRadius(2)
      .backgroundColor('#007dff')
      .animation({ duration: 300, curve: Curve.EaseInOut })
  }
  .width(this.tabBarWidth > 0 ? this.tabBarWidth / this.tabs.length : '25%')
  .justifyContent(FlexAlign.Center)
  .animatableTranslateX(this.indicatorOffsetX)
  .animation({ duration: 300, curve: Curve.EaseInOut })
}
.width('100%')
.alignContent(Alignment.Start)
```

关键点：
- 内层 Column 通过 `animatableIndicatorWidth` 控制下划线实际宽度
- 外层 Row 通过 `animatableTranslateX` 控制下划线所在 Tab 格子的水平偏移
- 两个 `.animation()` 绑定在各自的 `@AnimatableExtend` 调用之后，驱动逐帧插值

---

## 场景2：天气图标变形

**场景描述：** 仿天气 App，点击不同天气类型（晴/多云/雨/阴）时，太阳半径、云朵透明度、雨滴透明度等图标元素通过 `@AnimatableExtend` 逐帧插值平滑变形过渡，背景渐变色同步切换。

**解决方案：** 使用 **`AnimatableArithmetic` 只含 `number` 字段的 `WeatherAnimData`** + **独立的 `WeatherStyle` 管理颜色等不可插值数据** + **多个 `@AnimatableExtend` 分别驱动不同元素** + **`.animation()` 隐式动画**

> **设计原则：** 将数据拆分为两个 class —— `WeatherAnimData` 只包含参与逐帧插值的 `number` 字段（`sunRadius`、`cloudOpacity`、`rainOpacity`），实现 `AnimatableArithmetic` 接口；`WeatherStyle` 包含颜色、温度、名称等不可数值插值的字段，作为普通 class 单独管理。这样 `@AnimatableExtend` 函数只接收 `WeatherAnimData`，不会误读不可插值字段。

### 步骤 1：定义两个 class — 可动画数据与不可动画数据分离

```ts
// 可动画数据：只含 number 字段，实现 AnimatableArithmetic
class WeatherAnimData implements AnimatableArithmetic<WeatherAnimData> {
  sunRadius: number = 30
  cloudOpacity: number = 0
  rainOpacity: number = 0

  constructor(sunRadius: number = 30, cloudOpacity: number = 0, rainOpacity: number = 0) {
    this.sunRadius = sunRadius
    this.cloudOpacity = cloudOpacity
    this.rainOpacity = rainOpacity
  }

  plus(rhs: WeatherAnimData): WeatherAnimData {
    return new WeatherAnimData(
      this.sunRadius + rhs.sunRadius,
      this.cloudOpacity + rhs.cloudOpacity,
      this.rainOpacity + rhs.rainOpacity
    )
  }

  subtract(rhs: WeatherAnimData): WeatherAnimData {
    return new WeatherAnimData(
      this.sunRadius - rhs.sunRadius,
      this.cloudOpacity - rhs.cloudOpacity,
      this.rainOpacity - rhs.rainOpacity
    )
  }

  multiply(scale: number): WeatherAnimData {
    return new WeatherAnimData(
      this.sunRadius * scale,
      this.cloudOpacity * scale,
      this.rainOpacity * scale
    )
  }

  equals(rhs: WeatherAnimData): boolean {
    return this.sunRadius === rhs.sunRadius &&
           this.cloudOpacity === rhs.cloudOpacity &&
           this.rainOpacity === rhs.rainOpacity
  }
}

// 不可动画数据：颜色、温度、名称等，普通 class 不实现接口
class WeatherStyle {
  bgColor1: string = '#87CEEB'
  bgColor2: string = '#E0F0FF'
  temp: string = '26°'
  name: string = '晴'
  icon: string = '☀️'
}
```

关键点：
- **`WeatherAnimData` 全部是 `number`**：`plus/subtract/multiply` 对每个字段做精确的数值运算，不存在类型混合问题
- **`WeatherStyle` 不实现 `AnimatableArithmetic`**：颜色等 `string` 字段无法数值插值，放在独立 class 中通过直接赋值 + `.animation()` 隐式动画过渡
- 拆分后 `@AnimatableExtend` 函数的参数类型是 `WeatherAnimData`，编译期就杜绝了误读 `string` 字段的可能性

### 步骤 2：状态与天气配置

```ts
@State animData: WeatherAnimData = new WeatherAnimData(30, 0, 0)
@State style: WeatherStyle = new WeatherStyle()
@State weatherIndex: number = 0

// 天气配置数组：每组同时包含可动画数据和不可动画数据
private weatherConfigs: [WeatherAnimData, WeatherStyle][] = [
  [new WeatherAnimData(30, 0,   0  ), { bgColor1: '#87CEEB', bgColor2: '#E0F0FF', temp: '26°', name: '晴',   icon: '☀️' } as WeatherStyle],
  [new WeatherAnimData(30, 0.6, 0  ), { bgColor1: '#B0C4DE', bgColor2: '#D6EAF8', temp: '22°', name: '多云', icon: '⛅' } as WeatherStyle],
  [new WeatherAnimData(0,  0.8, 1  ), { bgColor1: '#778899', bgColor2: '#B0C4DE', temp: '18°', name: '雨',   icon: '🌧️' } as WeatherStyle],
  [new WeatherAnimData(0,  1,   0  ), { bgColor1: '#A9A9A9', bgColor2: '#D3D3D3', temp: '15°', name: '阴',   icon: '☁️' } as WeatherStyle],
]
```

### 步骤 3：定义 @AnimatableExtend — 参数类型为 WeatherAnimData

```ts
@AnimatableExtend(Column)
function animatableSunSize(data: WeatherAnimData) {
  .width(data.sunRadius > 0 ? data.sunRadius * 2 : 0)
  .height(data.sunRadius > 0 ? data.sunRadius * 2 : 0)
  .borderRadius(data.sunRadius > 0 ? data.sunRadius : 0)
}

@AnimatableExtend(Column)
function animatableCloudOpacity(data: WeatherAnimData) {
  .opacity(data.cloudOpacity)
}

@AnimatableExtend(Row)
function animatableRainOpacity(data: WeatherAnimData) {
  .opacity(data.rainOpacity)
}
```

关键点：每个 `@AnimatableExtend` 的参数是 `WeatherAnimData`（纯 `number`），函数内只读取 `number` 字段。框架逐帧调用 `subtract → multiply` 得到中间值后传入，每个字段都是精确的数值插值结果。

### 步骤 4：切换天气 — 可动画数据赋值触发插值，不可动画数据单独赋值

```ts
switchWeather(index: number) {
  this.weatherIndex = index
  let [animData, style] = this.weatherConfigs[index]

  // 可动画数据：赋值后框架自动逐帧插值
  this.animData = animData

  // 不可动画数据：直接赋值，由组件上的 .animation() 隐式动画过渡
  this.style = style
}
```

关键点：`this.animData = animData` 赋值后，框架对旧 `WeatherAnimData` 和新 `WeatherAnimData` 调用 `subtract/multiply` 逐帧插值。`this.style = style` 是普通对象赋值，颜色变化由 Stack 上的 `.animation()` 处理。

### 步骤 5：UI 布局 — @AnimatableExtend 驱动图标，.animation() 驱动背景色

```ts
Stack() {
  // 太阳 — animatableSunSize 驱动 width/height/borderRadius
  Column() {}
    .animatableSunSize(this.animData)
    .linearGradient({ angle: 135, colors: [['#FFD700', 0], ['#FFA500', 1]] })
    .shadow({ radius: 20, color: '#FFD70066' })
    .animation({ duration: 600, curve: Curve.EaseInOut })

  // 云朵 — animatableCloudOpacity 驱动 opacity
  Column() {}
    .width(60).height(30).borderRadius(15)
    .backgroundColor('#ffffff')
    .animatableCloudOpacity(this.animData)
    .animation({ duration: 600, curve: Curve.EaseInOut })

  // 雨滴 — animatableRainOpacity 驱动 opacity
  Row({ space: 10 }) { /* 雨滴元素 */ }
    .animatableRainOpacity(this.animData)
    .animation({ duration: 600, curve: Curve.EaseInOut })
}
.width('100%').height(280)
.linearGradient({
  angle: 180,
  colors: [[this.style.bgColor1, 0], [this.style.bgColor2, 1]]
})
.animation({ duration: 600, curve: Curve.EaseInOut })  // 背景色隐式动画
```

关键点：
- **三个 `@AnimatableExtend` 绑定同一个 `this.animData`**：框架对 `WeatherAnimData` 做整体插值，每帧将中间值分别传入三个函数，太阳尺寸、云朵透明度、雨滴透明度同步变化
- **背景色绑定 `this.style` + `.animation()`**：`WeatherStyle` 不参与 `AnimatableArithmetic` 运算，`.animation({ duration: 600 })` 让 `linearGradient` 的颜色变化平滑过渡

---

## 场景3：图表数据切换

**场景描述：** 仿数据看板，点击切换不同数据集（营收/用户/订单）时，柱状图柱高通过 `ChartData` 自定义类型逐帧插值平滑变化到新值。

**解决方案：** 使用 **自定义 `ChartData` 类实现 `AnimatableArithmetic<ChartData>` 接口** + **`@AnimatableExtend(Column)` 扩展 `height`** + **`.animation()` 驱动逐帧柱高变化**

### 步骤 1：定义 ChartData 自定义可动画类型

> **设计原则：** 自定义可动画类型中**只包含需要参与逐帧插值的 `number` 字段**。颜色等不可数值插值的属性（`string`、`Resource` 等）不要放入类型中，应拆分为独立的 `@State` 变量单独管理，避免 `plus/subtract/multiply` 中处理无意义的原样返回。

```ts
class ChartData implements AnimatableArithmetic<ChartData> {
  values: number[] = []

  constructor(values: number[]) {
    this.values = values
  }

  plus(rhs: ChartData): ChartData {
    let newValues: number[] = []
    for (let i = 0; i < this.values.length; i++) {
      newValues.push(this.values[i] + rhs.values[i])
    }
    return new ChartData(newValues)
  }

  subtract(rhs: ChartData): ChartData { /* 对应元素相减 */ }
  multiply(rhs: number): ChartData { /* 所有元素乘以系数 */ }
  equals(rhs: ChartData): boolean { /* 逐元素比较 */ }
}
```

关键点：
- `values` 数组中的每个元素独立参与插值运算，动画框架会对 `ChartData` 整体做 `subtract → multiply` 逐帧计算
- `@State animatableData: ChartData` 状态变化时，框架自动对 ChartData 做插值
- **不包含 `color` 字段**：颜色是 `string` 类型无法数值插值，柱子颜色由独立的 `@State chartColor` 在步骤 4 中单独赋值驱动

### 步骤 2：@AnimatableExtend 驱动柱高

```ts
@AnimatableExtend(Column)
function animatableBarHeight(h: number) {
  .height(h)
}
```

### 步骤 3：柱状图 ForEach — 每个柱子绑定 animatableData.values

```ts
Row() {
  ForEach([0, 1, 2, 3, 4, 5, 6], (index: number) => {
    Column() {
      Column() {}
        .width(24)
        .borderRadius({ topLeft: 4, topRight: 4 })
        .backgroundColor(this.chartColor)
        .animatableBarHeight(this.animatableData.values[index] * 2)
        .animation({ duration: 500, curve: Curve.EaseInOut })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .height(200)
  })
}
.width('100%')
.height(200)
.alignItems(VerticalAlign.Bottom)
```

关键点：
- `animatableData.values[index] * 2` — 从 `ChartData` 的 values 数组中取对应索引的值乘以系数作为柱高
- 动画框架逐帧计算 `ChartData` 的中间值，每帧的 `values[index]` 都在变化，驱动 `animatableBarHeight` 逐帧更新 Column 的 height
- 所有 7 根柱子共享同一个 `animatableData` 状态，数据集切换时所有柱子同步平滑过渡

### 步骤 4：切换数据集

```ts
switchDataSet(index: number) {
  this.animatableData = new ChartData([...this.dataSets[index].values])
  this.chartColor = this.dataSets[index].color
  this.selectedBar = -1
}
```

关键点：`new ChartData([...this.dataSets[index].values])` 使用展开运算符创建新数组，确保 ArkUI 检测到 `values` 引用变化。`chartColor` 作为独立的 `@State string` 单独赋值，不参与 `AnimatableArithmetic` 运算。赋值 `this.animatableData` 后，框架对旧 `ChartData` 和新 `ChartData` 调用 `subtract/multiply` 逐帧插值。

---
