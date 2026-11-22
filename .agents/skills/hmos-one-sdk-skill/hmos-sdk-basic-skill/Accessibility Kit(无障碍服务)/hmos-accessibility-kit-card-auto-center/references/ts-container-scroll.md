# Scroll
---
# Scroll
可滚动的容器组件，当子组件的布局尺寸超过父组件的尺寸时，内容可以滚动。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/5f/v3/2VwaloywQeepwriUNr1XrQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=4F3FB0786E3C89129515C1118C212639278910A3177DAC464427FDAAAF3168FF)
- 该组件从API version 7开始支持。后续版本如有新增内容，则采用上角标单独标记该内容的起始版本。
- 该组件嵌套List子组件滚动时，若List不设置宽高，则默认全部加载，在对性能有要求的场景下建议指定List的宽高，最佳实践请参考[懒加载优化性能-Scroll嵌套List导致按需加载失效](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-lazyforeach-optimization#section6296154115367)。
- 该组件滚动的前提是主轴方向大小小于内容大小。
- Scroll组件[通用属性clip](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/通用属性/视效与模糊/ts-universal-attributes-sharp-clipping.md)的默认值为true。
- Scroll组件的高度超出屏幕显示范围时，可以通过设置通用属性[layoutWeight](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/通用属性/布局与边框/ts-universal-attributes-size.md)让Scroll高度适应主轴的剩余空间。
- 手指触摸屏幕时，会停止当前触摸范围内所有滚动组件的滚动动画（[scrollTo](#scrollto)和[scrollToIndex](#scrolltoindex)接口触发的滚动动画除外），包括边缘回弹动画。
- 组件内部已绑定手势实现跟手滚动等功能，需要增加自定义手势操作时请参考[手势拦截增强](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/手势处理/手势控制/ts-gesture-blocking-enhancement.md)进行处理。
#### 子组件
支持单个子组件。
从API version 21开始，Scroll单个子组件的宽高最大为16777216px；API version 20及之前，Scroll单个子组件的宽高最大为1000000px。子组件超出该大小可能导致滚动或显示异常。
#### 接口
Scroll(scroller?: Scroller)
创建Scroll滚动容器。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| scroller | [Scroller](#scroller) | 否 | 可滚动组件的控制器。用于与可滚动组件进行绑定。**说明：**不允许和其他滚动类组件，如：[ArcList](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-arclist.md)、[List](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md)、[Grid](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-grid.md)、[Scroll](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scroll.md)和[WaterFlow](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-waterflow.md)绑定同一个滚动控制对象。 |
#### 属性
除支持 [通用属性](D:/code/APIDevice/output/md_output/harmonyos-references/ts-component-general-attributes.md) 和 [滚动组件通用属性](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) 外，还支持以下属性：
#### scrollable
scrollable(value: ScrollDirection)
设置滚动方向。该值被修改后会重置滚动偏移量。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | [ScrollDirection](#scrolldirection枚举说明) | 是 | 滚动方向。默认值：ScrollDirection.Vertical |
当滚动方向设置为 [ScrollDirection.FREE](#scrolldirection枚举说明) 时，Scroll组件仅支持部分能力，见 [自由滚动模式下支持的能力](#scrolldirection枚举说明) 。
#### scrollBar
scrollBar(barState: BarState)
设置滚动条状态。如果容器组件无法滚动，则滚动条不显示。如果容器组件的子组件大小为无穷大，则滚动条不支持拖动和伴随滚动。
从API version 10开始，当滚动组件存在圆角时，为避免滚动条被圆角截断，滚动条会自动计算距顶部和底部的避让距离。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| barState | [BarState](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md) | 是 | 滚动条状态。默认值：BarState.Auto |
#### scrollBarColor
scrollBarColor(color: Color | number | string)
设置滚动条的颜色。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| color | [Color](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md)| number | string | 是 | 滚动条的颜色。默认值：'#66182431'number为HEX格式颜色，支持rgb或者argb，示例：0xffffff。string为rgb或者argb格式颜色，示例：'#ffffff'。 |
#### scrollBarColor22+
scrollBarColor(color: Color | number | string | Resource)
设置滚动条的颜色。与 [scrollBarColor](#scrollbarcolor) 相比，color参数开始支持Resource类型。
**元服务API：** 从API version 22开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| color | [Color](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md)| number | string |[Resource](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 是 | 滚动条的颜色。默认值：'#66182431'number为HEX格式颜色，支持rgb或者argb，示例：0xffffff。string为rgb或者argb格式颜色，示例：'#ffffff'。 |
#### scrollBarWidth
scrollBarWidth(value: number | string)
设置滚动条的宽度，不支持百分比设置。宽度设置后，滚动条正常状态和按压状态宽度均为滚动条的宽度值。如果滚动条的宽度超过Scroll组件主轴方向的高度，则滚动条的宽度会变为默认值。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | number | string | 是 | 滚动条的宽度。默认值：4单位：vp取值范围：设置为小于0的值时，按默认值处理。设置为0时，不显示滚动条。 |
#### scrollSnap10+
scrollSnap(value: ScrollSnapOptions)
设置Scroll组件的限位滚动模式。
限位动画期间 [onWillScroll](#onwillscroll12) 事件上报的滚动操作来源类型为ScrollSource.FLING。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | [ScrollSnapOptions](#scrollsnapoptions10对象说明) | 是 | Scroll组件的限位滚动模式。 |
#### edgeEffect
edgeEffect(edgeEffect: EdgeEffect, options?: EdgeEffectOptions)
设置边缘滑动效果。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| edgeEffect | [EdgeEffect](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md) | 是 | Scroll组件的边缘滑动效果，支持弹簧效果和阴影效果。默认值：EdgeEffect.None |
| options11+ | [EdgeEffectOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) | 否 | 组件内容大小小于组件自身时，是否开启滑动效果。设置为{ alwaysEnabled: true }会开启滑动效果，{ alwaysEnabled: false }不开启。默认值：{ alwaysEnabled: true } |
#### enableScrollInteraction10+
enableScrollInteraction(value: boolean)
设置是否支持滚动手势。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | boolean | 是 | 是否支持滚动手势。设置为true时可以通过手指或者鼠标滚动，设置为false时无法通过手指或者鼠标滚动，但不影响控制器[Scroller](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scroll.md)的滚动接口。默认值：true |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/12/v3/5n4nLCJMQV-C6PzsPdAb_A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=445574941A593987E630593442FF7AD876C83D5486F96EDCC94FC131DAAC61E0)
组件无法通过鼠标按下拖动操作进行滚动。
#### nestedScroll10+
nestedScroll(value: NestedScrollOptions)
设置前后两个方向的嵌套滚动模式，实现与父组件的滚动联动。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | [NestedScrollOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) | 是 | 嵌套滚动选项。默认值：{ scrollForward: NestedScrollMode.SELF_ONLY, scrollBackward: NestedScrollMode.SELF_ONLY }Scroll设置[enablePaging](#enablepaging11)或者[scrollSnap](#scrollsnap10)，并同时设置父组件优先的嵌套滚动时，嵌套滚动不生效。 |
#### friction10+
friction(value: number | Resource)
设置摩擦系数，手动划动滚动区域时生效，仅影响惯性滚动过程，对惯性滚动过程中的链式效果有间接影响。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | number |[Resource](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 是 | 摩擦系数。默认值：非可穿戴设备为0.6，可穿戴设备为0.9。从API version 11开始，非可穿戴设备默认值为0.7。从API version 12开始，非可穿戴设备默认值为0.75。取值范围：(0, +∞)，设置为小于等于0的值时，按默认值处理。 |
#### enablePaging11+
enablePaging(value: boolean)
设置是否支持划动翻页。如果同时设置了划动翻页enablePaging和限位滚动scrollSnap，则scrollSnap优先生效，enablePaging不生效。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | boolean | 是 | 是否支持划动翻页。设置为true支持滑动翻页，false不支持。默认值：false |
#### initialOffset12+
initialOffset(value: OffsetOptions)
设置初始滚动偏移量。只在首次布局时生效，后续动态修改该属性值不生效。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | [OffsetOptions](#offsetoptions12对象说明) | 是 | 当输入的大小为百分比时，初始滚动偏移量为Scroll组件主轴方向大小与百分比数值之积。 |
#### maxZoomScale20+
maxZoomScale(scale: number)
设置Scroll组件内容的最大手势缩放比例。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| scale | number | 是 | Scroll组件内容的最大手势缩放比例。默认值：1取值范围：(0, +∞)，小于或等于0时按默认值1处理。 |
#### minZoomScale20+
minZoomScale(scale: number)
设置Scroll组件内容的最小手势缩放比例。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| scale | number | 是 | Scroll组件内容的最小手势缩放比例。默认值：1取值范围：(0, maxZoomScale]，小于或等于0时按默认值1处理，大于maxZoomScale时按maxZoomScale处理。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f2/v3/C6732nG0T82UokWgq6R9Xw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=CB561CC415644F16000D4ECE5C6125A7877BFA4F0D39A6BE2B17FAC109710754)
当maxZoomScale和minZoomScale不同时为1时，Scroll组件会启用缩放手势。
#### zoomScale20+
zoomScale(scale: number)
设置Scroll组件内容的缩放比例。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| scale | number | 是 | 设置Scroll组件内容的缩放比例，该参数支持[!!](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/ArkUI（方舟UI框架）/UI开发 (ArkTS声明式开发范式)/学习UI范式状态管理/语法糖/!!语法：双向绑定/arkts-new-binding.md)双向绑定变量。默认值：1取值范围：(0, +∞)，小于或等于0时按默认值1处理。 |
#### enableBouncesZoom20+
enableBouncesZoom(enable: boolean)
启用过缩放回弹效果。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| enable | boolean | 是 | 启用过缩放回弹效果。设置为true表示启用该效果，设置为false表示禁用该效果。默认值：true |
#### ScrollDirection枚举说明
滚动方向枚举。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 值 | 说明 |
| --- | --- | --- |
| Vertical | 0 | 仅支持竖直方向滚动。**元服务API：**从API version 11开始，该接口支持在元服务中使用。 |
| Horizontal | 1 | 仅支持水平方向滚动。**元服务API：**从API version 11开始，该接口支持在元服务中使用。 |
| Free(deprecated) | 2 | 支持竖直或水平方向滚动。**说明：**从API version 7开始支持，从API version 9开始废弃，建议使用FREE替代。FREE枚举值从API version 20开始支持。 |
| None | 3 | 不可滚动。**元服务API：**从API version 11开始，该接口支持在元服务中使用。 |
| FREE20+ | 4 | 自由滚动。**元服务API：**从API version 20开始，该接口支持在元服务中使用。 |
FREE（自由滚动）模式下支持的能力：
| **支持的属性** | **支持的事件** | **支持的[Scroller](#scroller)接口** |
| --- | --- | --- |
| [scrollBar](#scrollbar) | [onWillScroll](#onwillscroll12) | [scrollTo](#scrollto) |
| [scrollBarColor](#scrollbarcolor) | [onDidScroll](#ondidscroll12) | [scrollEdge](#scrolledge) |
| [scrollBarWidth](#scrollbarwidth) | [onScrollEdge](#onscrolledge) | [scrollPage](#scrollpage9) |
| [scrollBarMargin](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) | [onScrollStart](#onscrollstart9) | [currentOffset](#currentoffset) |
| [edgeEffect](#edgeeffect) | [onScrollStop](#onscrollstop9) | [scrollBy](#scrollby9) |
| [enableScrollInteraction](#enablescrollinteraction10) | - | [getItemRect](#getitemrect11) |
| [friction](#friction10) | - | - |
| [clipContent](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) | - | - |
| [initialOffset](#initialoffset12) | - | - |
| [scrollable](#scrollable) | - | - |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4f/v3/T0AGBXtfTc28L25l7-mYVg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=AF9A5DB85303BBC5D94BC93F9C70B15764AC75D9ED991C083BB8F7D1E4D117FE)
- edgeEffect属性仅支持Spring和None边缘滑动效果。
- onWillScroll回调仅支持在跟手滑动阶段重载偏移量。
- onScrollEdge回调只在到达边缘时触发一次，回弹后不会重复触发。
- 在抛滑动画过程中切换边缘模式不会打断动画。
#### ScrollSnapOptions10+对象说明
限位滚动模式对象。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| snapAlign | [ScrollSnapAlign](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) | 否 | 否 | 设置Scroll组件限位滚动时的对齐方式。**说明：**1.该属性默认值为ScrollSnapAlign.NONE。 |
| snapPagination | [Dimension](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md)| Array<Dimension> | 否 | 是 | 设置Scroll组件限位滚动时的分页点。**说明：**1.当属性为Dimension时，Dimension表示每页的大小，系统按照该大小进行分页。2.当属性为Array<Dimension>时，每个Dimension表示分页点，系统按照分页点进行分页。每个Dimension的范围为[0,可滑动距离]。3.当该属性不填或者Dimension为小于等于0的输入时，按异常值，无限位滚动处理。当该属性值为Array<Dimension>数组时，数组中的数值必须为单调递增。4.当输入为百分比时，实际的大小为Scroll组件的视口与百分比数值之积。 |
| enableSnapToStart | boolean | 否 | 是 | 在Scroll组件限位滚动模式下，该属性设置为true后，不允许Scroll在开头和第一页间自由滑动，该属性设置为false后，允许Scroll在开头和第一页间自由滑动。**说明：**1.该属性值默认为true。2.该属性仅当snapPagination属性为Array<Dimension>时生效，不支持Dimension。 |
| enableSnapToEnd | boolean | 否 | 是 | 在Scroll组件限位滚动模式下，该属性设置为true后，不允许Scroll在最后一页和末尾间自由滑动，该属性设置为false后，允许Scroll在最后一页和末尾间自由滑动。**说明：**1.该属性值默认为true。2.该属性仅当snapPagination属性为Array<Dimension>时生效，不支持Dimension。 |
#### 事件
除支持 [通用事件](D:/code/APIDevice/output/md_output/harmonyos-references/ts-component-general-events.md) 和 [滚动组件通用事件](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) 外，还支持以下事件：
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f6/v3/lswRqKrjRxOPicKpXUYxww/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=82A5467E917DAB6A01F361F0684DC3ADE4CB66B0A3A4DF90C96A500D8CA214AA)
不支持滚动组件通用事件中的 [onWillScroll](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) 、 [onDidScroll](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) 事件。
#### onScrollFrameBegin9+
onScrollFrameBegin(event: OnScrollFrameBeginCallback)
该接口回调时，事件参数传入即将发生的滚动量，事件处理函数中可根据应用场景计算实际需要的滚动量并作为事件处理函数的返回值返回，Scroll将按照返回值的实际滚动量进行滚动。
支持 [offsetRemain](#onscrollframebeginhandlerresult18对象说明) 为负值。
若通过onScrollFrameBegin事件和 [scrollBy](#scrollby9) 方法实现容器嵌套滚动，需设置子滚动节点的 [EdgeEffect](#edgeeffect) 为None。如Scroll嵌套List滚动时，List组件的 [edgeEffect](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) 属性需设置为EdgeEffect.None，否则抛滑List，会触发List的边缘回弹动画，导致嵌套滚动失效。
满足以下任一条件时触发该事件：
1. 用户交互（如手指滑动、键鼠操作等）触发滚动。
2. Scroll惯性滚动。
3. 调用[fling](#fling12)接口触发滚动。
不触发该事件的条件：
1. 调用除[fling](#fling12)接口外的其他滚动控制接口。
2. 越界回弹。
3. 拖动滚动条。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| event | [OnScrollFrameBeginCallback](#onscrollframebegincallback18) | 是 | 每帧滚动开始回调函数。 |
#### onScroll(deprecated)
onScroll(event: (xOffset: number, yOffset: number) => void)
滚动事件回调，返回滚动时水平、竖直方向偏移量，单位vp。
触发该事件的条件：
1、滚动组件触发滚动时触发，支持键鼠操作等其他触发滚动的输入设置。
2、通过滚动控制器API接口调用。
3、越界回弹。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d/v3/yVQ4JUNzSb-gwa7mZNq5lA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=3C065436116DC1F33D2EA4F1DC5D2D21FA91BD2B4F6EAF32204D83CD9AD190BC)
从API version 7开始支持，从API version 12开始废弃，建议使用 [onWillScroll](#onwillscroll12) 替代。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| xOffset | number | 是 | 相对于上一帧水平方向的偏移量，Scroll中的内容向左滚动时偏移量为正，向右滚动时偏移量为负。单位vp。 |
| yOffset | number | 是 | 相对于上一帧竖直方向的偏移量，Scroll中的内容向上滚动时偏移量为正，向下滚动时偏移量为负。单位vp。 |
#### onWillScroll12+
onWillScroll(handler: ScrollOnWillScrollCallback)
滚动事件回调，Scroll滚动前触发。
回调当前帧将要滚动的偏移量和当前滚动状态和滚动操作来源，其中回调的偏移量为计算得到的将要滚动的偏移量值，并非最终实际滚动偏移。可以通过该回调返回值指定Scroll将要滚动的偏移。
触发该事件的条件：
1、滚动组件触发滚动时触发，支持键鼠操作等其他触发滚动的输入设置。
2、通过滚动控制器API接口调用。
3、越界回弹。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/69/v3/TgFvShFRRFaW31zwKf5sPw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=EE49F44873092913F857556B7444ECDD574472FFFBF590868901E5494AF232A8)
滚动事件的回调函数在滚动过程中会被频繁触发，因此应避免在该回调函数中执行耗时操作，以防止应用出现卡顿和丢帧的问题。最佳实践请参考 [主线程耗时操作优化指导-高频回调场景](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-time-optimization-of-the-main-thread#section10112623611) 。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| handler | [ScrollOnWillScrollCallback](#scrollonwillscrollcallback12) | 是 | Scroll滚动前触发的回调。 |
#### onDidScroll12+
onDidScroll(handler: ScrollOnScrollCallback)
滚动事件回调，Scroll滚动时触发。
返回当前帧滚动的偏移量和当前滚动状态。
触发该事件的条件：
1、滚动组件触发滚动时触发，支持键鼠操作等其他触发滚动的输入设置。
2、通过滚动控制器API接口调用。
3、越界回弹。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| handler | [ScrollOnScrollCallback](#scrollonscrollcallback12) | 是 | Scroll滚动时触发的回调。 |
#### onScrollEdge
onScrollEdge(event: OnScrollEdgeCallback)
滚动到边缘事件回调。
触发该事件的条件：
1、滚动组件滚动到边缘时触发，支持键鼠操作等其他触发滚动的输入设置。
2、通过滚动控制器API接口调用。
3、越界回弹。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| event | [OnScrollEdgeCallback](#onscrolledgecallback18) | 是 | 滚动到的边缘位置。当Scroll设置为水平方向滚动时，上报[Edge.Center](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md)表示水平方向起始位置，上报[Edge.Baseline](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md)表示水平方向末尾位置。由于[Edge.Center](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md)和[Edge.Baseline](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md)枚举值已经废弃，推荐使用[onReachStart](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md)、[onReachEnd](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md)事件监听是否滚动到边界。 |
#### onScrollEnd(deprecated)
onScrollEnd(event: () => void)
滚动停止事件回调。
触发该事件的条件：
1、滚动组件触发滚动后停止，支持键鼠操作等其他触发滚动的输入设置。
2、通过滚动控制器API接口调用后停止，带过渡动效。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/32/v3/xvQRGGHMRY6CedVqfvD0sw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=940E208B9C24E04D5DAC4CC2234A90B1DBEE7325357D64229EDAD294091CDBF7)
从API version 7开始支持，从API version 9开始废弃，建议使用 [onScrollStop](#onscrollstop9) 替代。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| event | () => void | 是 | 滚动停止事件回调。 |
#### onScrollStart9+
onScrollStart(event: VoidCallback)
滚动开始时触发。手指拖动Scroll或拖动Scroll的滚动条触发的滚动开始时，会触发该事件。使用 [Scroller](#scroller) 滚动控制器触发的带动画的滚动，动画开始时会触发该事件。
触发该事件的条件：
1、滚动组件开始滚动时触发，支持键鼠操作等其他触发滚动的输入设置。
2、通过滚动控制器API接口调用后开始，带过渡动效。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| event | [VoidCallback](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 是 | 滚动开始回调。 |
#### onScrollStop9+
onScrollStop(event: VoidCallback)
滚动停止时触发。手拖动Scroll或拖动Scroll的滚动条触发的滚动，手离开屏幕后滚动停止时会触发该事件。使用 [Scroller](#scroller) 滚动控制器触发的带动画的滚动，动画停止时会触发该事件。
触发该事件的条件：
1、滚动组件触发滚动后停止，支持键鼠操作等其他触发滚动的输入设置。
2、通过滚动控制器API接口调用后开始，带过渡动效。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| event | [VoidCallback](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 是 | 滚动停止回调。 |
#### onDidZoom20+
onDidZoom(event: ScrollOnDidZoomCallback)
每帧缩放完成时触发。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| event | [ScrollOnDidZoomCallback](#scrollondidzoomcallback20) | 是 | 每帧缩放完成时回调。 |
#### onZoomStart20+
onZoomStart(event: VoidCallback)
手势缩放开始触发。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| event | [VoidCallback](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 是 | 缩放开始回调。 |
#### onZoomStop20+
onZoomStop(event: VoidCallback)
手势缩放停止时触发。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| event | [VoidCallback](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 是 | 缩放停止回调。 |
#### ScrollOnScrollCallback12+
type ScrollOnScrollCallback = (xOffset: number, yOffset: number, scrollState: ScrollState) => void
Scroll滚动时触发的回调。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| xOffset | number | 是 | 相对于上一帧水平方向的偏移量，Scroll中的内容向左滚动时偏移量为正，向右滚动时偏移量为负。单位vp。 |
| yOffset | number | 是 | 相对于上一帧竖直方向的偏移量，Scroll中的内容向上滚动时偏移量为正，向下滚动时偏移量为负。单位vp。 |
| scrollState | [ScrollState](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) | 是 | 当前滚动状态。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c0/v3/mFtmz4ZjQheRGXIbE1tJcw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=CAD3550663698EFE7F04D47007D6FA97B672695C3312F65EDE5172F3FA2D7119)
若通过 [onScrollFrameBegin](#onscrollframebegin9) 事件和 [scrollBy](#scrollby9) 方法实现容器嵌套滚动，需设置子滚动节点的EdgeEffect为None。如Scroll嵌套List滚动时，List组件的 [edgeEffect](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) 属性需设置为EdgeEffect.None。
#### ScrollOnWillScrollCallback12+
type ScrollOnWillScrollCallback = (xOffset: number, yOffset: number, scrollState: ScrollState, scrollSource: ScrollSource) => void | OffsetResult
Scroll滚动前触发的回调。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| xOffset | number | 是 | 相对于上一帧水平方向的偏移量，Scroll中的内容向左滚动时偏移量为正，向右滚动时偏移量为负。单位vp。 |
| yOffset | number | 是 | 相对于上一帧竖直方向的偏移量，Scroll中的内容向上滚动时偏移量为正，向下滚动时偏移量为负。单位vp。 |
| scrollState | [ScrollState](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) | 是 | 当前滚动状态。 |
| scrollSource | [ScrollSource](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md) | 是 | 当前滚动操作的来源。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| void |[OffsetResult](#offsetresult11对象说明) | 返回OffsetResult时按照开发者指定的偏移量滚动；不返回时按回调参数(xOffset, yOffset)滚动。 |
#### OnScrollEdgeCallback18+
type OnScrollEdgeCallback = (side: Edge) => void
滚动到边缘时触发的回调。
**元服务API：** 从API version 18开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| side | [Edge](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md) | 是 | 滚动到的边缘位置。 |
#### OnScrollFrameBeginCallback18+
type OnScrollFrameBeginCallback = (offset: number, state: ScrollState) => OnScrollFrameBeginHandlerResult;
Scroll每帧滚动前触发的回调。
**元服务API：** 从API version 18开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| offset | number | 是 | 即将发生的滑动量，单位vp。 |
| state | [ScrollState](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) | 是 | 当前滑动状态。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [OnScrollFrameBeginHandlerResult](#onscrollframebeginhandlerresult18对象说明) | 返回实际滑动量。 |
#### OnScrollFrameBeginHandlerResult18+对象说明
[OnScrollFrameBeginCallback](#onscrollframebegincallback18) 返回的实际相对上一帧滚动偏移量。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/dc/v3/EDMHwjb-R4Kn_ewfkS3HJw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=92D9980503AA9F06F0984039F8BD25B8E67D7C010551925BC2CFDD76C426830E)
为规范匿名对象的定义，API version 18版本修改了此处的元素定义。其中，保留了历史匿名对象的起始版本信息，会出现外层元素@since版本号高于内层元素版本号的情况，但这不影响接口的使用。
**元服务API：** 从API version 18开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| offsetRemain9+ | number | 否 | 否 | 实际相对上一帧的滚动偏移量。单位vp。**元服务API：**从API version 11开始，该接口支持在元服务中使用。 |
#### ScrollOnDidZoomCallback20+
type ScrollOnDidZoomCallback = (scale: number) => void
Scroll每帧缩放完成时触发的回调。
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| scale | number | 是 | 当前缩放倍数。 |
#### Scroller
可滚动容器组件的控制器，可以将此组件绑定至容器组件，然后通过它控制容器组件的滚动。同一个控制器不可以控制多个容器组件，目前支持绑定到ArcList、ArcScrollBar、List、Scroll、ScrollBar、Grid、WaterFlow上。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/3d/v3/-71ykYJySSC0gzmAWGv0QA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=4916AB57651CFE278360AD1ABFF2916DA826B273A4953E752BAFCE332932DFFD)
1、Scroller控制器与滚动容器组件的绑定发生在组件创建阶段。
2、Scroller控制器与滚动容器组件绑定后才可以正常调用Scroller方法，否则根据调用接口不同会不生效或者抛异常。
3、以 [aboutToAppear](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/自定义组件/ts-custom-component-lifecycle.md) 为例，aboutToAppear在创建自定义组件的新实例后，在执行其build()方法之前执行。因此如果滚动组件在自定义组件build内，在该自定义组件aboutToAppear执行时，内部滚动组件还没有创建，是不能正常调用上述Scroller方法的。
4、以 [onAppear](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/通用事件/组件变化事件/ts-universal-events-show-hide.md) 为例，组件挂载显示后触发此回调。因此在滚动组件的onAppear回调执行时，滚动组件已经创建并已经和Scroller绑定成功，是可以正常调用Scroller方法的。
#### 导入对象
```
scroller: Scroller = new Scroller();
```
#### constructor
constructor()
Scroller的构造函数。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
#### scrollTo
scrollTo(options: ScrollOptions)
滑动到指定位置。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| options | [ScrollOptions](#scrolloptions18对象说明) | 是 | 滑动到指定位置的参数。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/81/v3/ynhyaFsxRaG-5VVeASmrBw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=E9BA52D552780397D469796C35EBF820D8EA5C25C38746C2F86FC3FB0AC398CC)
ScrollTo动画速度大于200vp/s时，滚动组件区域内的组件不响应点击事件。
#### scrollEdge
scrollEdge(value: Edge, options?: ScrollEdgeOptions)
滚动到容器边缘，不区分滚动轴方向，Edge.Top和Edge.Start表现相同，Edge.Bottom和Edge.End表现相同。
Scroll组件默认有动画，Grid、List、WaterFlow组件默认无动画。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | [Edge](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md) | 是 | 滚动到的边缘位置。 |
| options12+ | [ScrollEdgeOptions](#scrolledgeoptions12对象说明) | 否 | 设置滚动到边缘位置的模式。 |
#### fling12+
fling(velocity: number): void
滚动类组件根据传入的初始速度进行惯性滚动。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| velocity | number | 是 | 惯性滚动的初始速度值。单位：vp/s**说明：**velocity值设置为0，视为异常值，本次滚动不生效。如果值为正数，则向顶部滚动；如果值为负数，则向底部滚动。 |
**错误码** ：
以下错误码详细介绍请参考 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [滚动类组件错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/错误码/UI界面/errorcode-scroll.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2.Incorrect parameters types; 3. Parameter verification failed. |
| 100004 | Controller not bound to component. |
#### scrollPage9+
scrollPage(value: ScrollPageOptions)
滚动到下一页或者上一页。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | [ScrollPageOptions](#scrollpageoptions14对象说明) | 是 | 设置翻页模式。 |
#### scrollPage(deprecated)
scrollPage(value: { next: boolean, direction?: Axis })
滚动到下一页或者上一页。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/59/v3/Si3F3H0NTkqdnJsFNIuGpg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=7147DD053F2C8F528F215157342B47711492049DE4473F048378672B140E095E)
从API version 7开始支持，从API version 9开始废弃，建议使用 [scrollPage9+](#scrollpage9) 替代。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| next | boolean | 是 | 是否向下翻页。true表示向下翻页，false表示向上翻页。 |
| direction | [Axis](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md) | 否 | 设置滚动方向为水平或竖直方向。 |
#### currentOffset
currentOffset(): OffsetResult
获取当前的滚动总偏移量。
Grid、List、WaterFlow组件有懒加载机制，组件内容没有加载并布局完成时，内容总偏移量通过估算得到，估算结果可能会有误差。其中List组件可以通过 [childrenMainSize](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) 属性解决估算不准确的问题。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [OffsetResult11+](#offsetresult11对象说明) | 返回当前的滚动总偏移量。**说明：**当scroller控制器未绑定容器组件或者容器组件被异常释放时，currentOffset的返回值为undefined。 |
#### scrollToIndex
scrollToIndex(value: number, smooth?: boolean, align?: ScrollAlign, options?: ScrollToIndexOptions)
滑动到指定Index，支持设置滑动额外偏移量。
开启smooth动效时，会对经过的所有item进行加载和布局计算，当大量加载item时会导致性能问题，建议先调用scrollToIndex不带动画跳转到目标附近位置，再调用scrollToIndex带动画滚动到目标位置。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1b/v3/obsALyeCRwOyeDNKvdwySg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=E7A9695729B39DDEAD6F8BA9E4E1135ED59B9C819FD303032273775DC042A7F0)
1.仅支持ArcList、Grid、List、WaterFlow组件。
2.在 [LazyForEach](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/状态管理与渲染控制/ts-rendering-control-lazyforeach.md) 、 [ForEach](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/状态管理与渲染控制/ts-rendering-control-foreach.md) 、 [Repeat](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/状态管理与渲染控制/ts-rendering-control-repeat.md) 刷新数据源时，需确保在数据刷新完成之后再调用此接口。
3.从API version 11开始，在List中支持 [contentStartOffset](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) 和 [contentEndOffset](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-list.md) 。从API version 22开始，在Grid和Waterflow组件中支持设置 [contentStartOffset](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) 和 [contentEndOffset](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) 。
-
当滚动容器组件设置contentStartOffset时，如果ScrollAlign设置为START，滚动结束时，指定item首部会与滚动容器组件contentStartOffset处对齐。
-
当滚动容器组件设置contentEndOffset时，如果ScrollAlign设置为END，滚动结束时，指定item尾部会与滚动容器组件contentEndOffset处对齐。
-
当滚动容器组件设置contentStartOffset或contentEndOffset时，如果ScrollAlign设置为AUTO，且指定item完全处于显示区内，不做调整；否则依照滚动距离最短的原则，将指定item首部与滚动组件contentStartOffset处对齐，或指定item尾部与滚动组件contentEndOffset处对齐，使指定item完全显示。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| value | number | 是 | 要滑动到的目标元素在当前容器中的索引值。**说明：**value值设置成负值或者大于当前容器子组件的最大索引值，视为异常值，本次跳转不生效。 |
| smooth | boolean | 否 | 设置滑动到列表项在列表中的索引值时是否有动效，true表示有动效，false表示没有动效。默认值：false。 |
| align | [ScrollAlign](#scrollalign10枚举说明) | 否 | 指定滑动到的元素与当前容器的对齐方式。List中的默认值为：ScrollAlign.START。Grid中默认值为：ScrollAlign.AUTO。WaterFlow中的默认值为：ScrollAlign.START。**说明：**仅List、Grid、WaterFlow组件支持该参数。 |
| options12+ | [ScrollToIndexOptions](#scrolltoindexoptions12对象说明) | 否 | 设置滑动到指定Index的选项，如额外偏移量。默认值：0，单位：vp。 |
#### scrollBy9+
scrollBy(dx: Length, dy: Length)
滑动指定距离。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/06/v3/QN4J4UcNSPicmHAJn55SzA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=AF28E0E33E7A67EA5795DBEE6C6502ED36A7E58A8F1890186DD89E423EC8E23A)
支持ArcList、Scroll、List、Grid、WaterFlow组件。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| dx | [Length](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 是 | 水平方向滚动距离，不支持百分比形式。取值范围：(-∞, +∞) |
| dy | [Length](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 是 | 竖直方向滚动距离，不支持百分比形式。取值范围：(-∞, +∞) |
#### isAtEnd10+
isAtEnd(): boolean
查询组件是否滚动到底部。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9c/v3/RozK9Vf1Qp-XYg1tZFgmng/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=5FF9883D6C55BDDE920B8C865F4A0B0C50BBF08937EE2DA9963C097BB46906B0)
支持ArcList、Scroll、List、Grid、WaterFlow组件。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**返回值：**
| 类型 | 说明 |
| --- | --- |
| boolean | true表示组件已经滚动到底部，false表示组件还没滚动到底部。 |
#### getItemRect11+
getItemRect(index: number): RectResult
获取子组件的大小及相对容器组件的位置。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fa/v3/OTqETiF3TlSlrSJ29Lm2zg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=F90EC09149196D10FBF123818E3099ED29E29F07D0FDBB3CFB8918A503BFCC92)
支持ArcList、Scroll、List、Grid、WaterFlow组件。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| index | number | 是 | 子组件的索引值。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9d/v3/XtSKxzFnTCeQpkIQkL13sQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=C1299ACC7B0EFF42036ECB9A7E4ED1D1B5E629AD73694ECDA3AD0A01C04D9B88)
- index必须是当前显示区域显示的子组件的索引值，否则视为非法值。
- 非法值返回的大小和位置均为0。
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [RectResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/通用事件/交互事件分发控制/ts-universal-attributes-on-child-touch-test.md) | 子组件的大小和相对于组件的位置。单位：vp。 |
**错误码** ：
以下错误码详细介绍请参考 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [滚动类组件错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/错误码/UI界面/errorcode-scroll.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2.Incorrect parameters types; 3. Parameter verification failed. |
| 100004 | Controller not bound to component. |
#### getItemIndex14+
getItemIndex(x: number, y: number): number
通过坐标获取子组件的索引。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/62/v3/ErafTpKzQpyH2Om-sf7IRg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=4F17972EF9656F5D5937AA78574F199036056FAB651A66C6E9599C5739B6CFAD)
支持List、Grid、WaterFlow组件。
**元服务API：** 从API version 14开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| x | number | 是 | x轴坐标，单位为vp。 |
| y | number | 是 | y轴坐标，单位为vp。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9b/v3/aVP_kDy3Ru2I-Btk17VP9w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=57AFB3AB18614129D90BB188874BD61E08D792FBC536CA06959DE0E0E98EEBEF)
非法值返回的索引为-1。
**返回值：**
| 类型 | 说明 |
| --- | --- |
| number | 返回子组件的索引。 |
**错误码** ：
以下错误码详细介绍请参考 [通用错误码](D:/code/APIDevice/output/md_output/harmonyos-references/API参考概述/errorcode-universal.md) 和 [滚动类组件错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/错误码/UI界面/errorcode-scroll.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2.Incorrect parameters types; 3. Parameter verification failed. |
| 100004 | The controller not bound to component. |
#### contentSize22+
contentSize(): SizeResult
获取滚动组件内容总大小。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/26/v3/CT3peX30RauGJRdVHMq0HQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=AF157B0434717C4D1081050701E3ACEA76903FCA709780DBF3BA77E51C6F6161)
-
Grid、List、WaterFlow和Scroll组件主轴方向内容大小为所有子组件布局后的总大小，交叉轴方向内容大小为组件自身交叉轴方向大小减去padding和border后的大小。
-
Grid、List、WaterFlow组件有懒加载机制，该接口依赖已布局的子节点进行估算。如果组件内容没有布局完成且子组件高度不一致，估算结果可能会有误差，需要开发者去适配，比如List组件可以通过childrenMainSize属性解决估算不准问题。
-
如果应用动态增删子节点，则需要应用动态获取内容总大小，来保证接口获取结果的即时性。
-
当Scroll组件设置scrollable为ScrollDirection.FREE自由滚动模式时，获取到的内容总大小为子组件缩放后的总大小。
-
当Scroll组件设置scrollable为ScrollDirection.None不可滚动时，获取到的内容总大小为0。
-
当Grid组件同时设置columnsTemplate和rowsTemplate，或columnsTemplate和rowsTemplate都不设置时即为不可滚动场景，此时获取到的内容总大小高度为0，宽度为Grid组件内容区宽度。
**元服务API：** 从API version 22开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**返回值：**
| 类型 | 说明 |
| --- | --- |
| [SizeResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/自定义组件/ts-custom-component-layout.md) | 滚动组件内容总大小，包括内容宽度和高度。单位：vp |
**错误码** ：
以下错误码详细介绍请参考 [滚动类组件错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/错误码/UI界面/errorcode-scroll.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| 100004 | Controller not bound to a component. |
#### OffsetResult11+对象说明
滑动偏移量对象。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| xOffset | number | 否 | 否 | 水平滑动偏移。返回值单位为vp。 |
| yOffset | number | 否 | 否 | 竖直滑动偏移。返回值单位为vp。 |
#### ScrollAnimationOptions12+对象说明
自定义滚动动效的参数选项。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| duration | number | 否 | 是 | 设置滚动时长。默认值：1000**说明：**设置为小于0的值时，按默认值显示。 |
| curve | [Curve](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md)|[ICurve](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS API/UI界面/js-apis-curve.md) | 否 | 是 | 设置滚动曲线。默认值：Curve.Ease |
| canOverScroll | boolean | 否 | 是 | 设置滚动动画滚动到边界后，是否转换成越界回弹动画。默认值：false**说明：**仅在设置为true，且组件的edgeEffect设置为[EdgeEffect.Spring](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-appendix-enums.md)时，使用动画滚动到边界会转换为越界回弹动画，设置为false时，滚动到边界会直接停止动画，不会转换为越界回弹动画。从API version 20开始，如果[ScrollOptions](#scrolloptions18对象说明)中的canOverScroll设置为true，表示滚动可以停留在过界位置，滚动动画过界后不会转换为回弹动画。 |
#### ScrollAlign10+枚举说明
对齐方式枚举。
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 值 | 说明 |
| --- | --- | --- |
| START | 0 | 首部对齐。指定item首部与滚动容器组件首部对齐。 |
| CENTER | 1 | 居中对齐。指定item主轴方向居中对齐于滚动容器组件。 |
| END | 2 | 尾部对齐。指定item尾部与滚动容器组件尾部对齐。 |
| AUTO | 3 | 自动对齐。若指定item完全处于显示区，不做调整。否则依照滑动距离最短的原则，将指定item首部对齐或尾部对齐于滚动容器组件，使指定item完全处于显示区。 |
#### ScrollToIndexOptions12+对象说明
滑动到指定Index的参数选项。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| extraOffset | [LengthMetrics](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS API/UI界面/arkui/js-apis-arkui-graphics.md) | 否 | 是 | 滑动到指定Index的额外偏移量。如果值为正数，则向底部额外偏移；如果值为负数，则向顶部额外偏移。 |
#### ScrollPageOptions14+对象说明
翻页模式的参数选项。
**元服务API：** 从API version 14开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| next | boolean | 否 | 否 | 是否向下翻页。true表示向下翻页，false表示向上翻页。 |
| animation | boolean | 否 | 是 | 是否开启翻页动画效果。true有动画，false无动画。默认值：false。 |
#### OffsetOptions12+对象说明
初始滚动偏移量的参数选项。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| xOffset | [Dimension](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 否 | 是 | 水平滚动偏移。默认值：0 |
| yOffset | [Dimension](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/公共定义/ts-types.md) | 否 | 是 | 垂直滚动偏移。默认值：0 |
#### ScrollEdgeOptions12+对象说明
滚动到边缘位置的参数选项。
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| velocity | number | 否 | 是 | 设置滚动到容器边缘的固定速度。如果设置小于等于0的值，参数不生效。默认值：0单位： vp/s |
#### ScrollOptions18+对象说明
滚动到指定位置的参数选项。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/22/v3/oVcCrgXfS4G8kMym-sjxKg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=F3269E863C67357942BD19DC2938D6AD13EAD5AB7DC8B411ABCA87904369A560)
为规范匿名对象的定义，API 18版本修改了此处的元素定义。其中，保留了历史匿名对象的起始版本信息，会出现外层元素@since版本号高于内层元素版本号的情况，但这不影响接口的使用。
**元服务API：** 从API version 18开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| xOffset10+ | number | string | 否 | 否 | 水平滚动总偏移量。**说明：**该参数值不支持设置百分比。仅滚动轴为x轴时生效。取值范围：当值小于0时，不带动画的滚动，按0处理。带动画的滚动，默认滚动到起始位置后停止，可通过设置animation参数，使滚动在越界时启动回弹动画。**元服务API：**从API version 11开始，该接口支持在元服务中使用。 |
| yOffset10+ | number | string | 否 | 否 | 垂直滚动总偏移量。**说明：**该参数值不支持设置百分比。仅滚动轴为y轴时生效。取值范围：当值小于0时，不带动画的滚动，按0处理。带动画的滚动，默认滚动到起始位置后停止，可通过设置animation参数，使滚动在越界时启动回弹动画。**元服务API：**从API version 11开始，该接口支持在元服务中使用。 |
| animation10+ | [ScrollAnimationOptions](#scrollanimationoptions12对象说明)| boolean | 否 | 是 | 动画配置。- ScrollAnimationOptions: 自定义滚动动效。- boolean: 使能默认弹簧动效。默认值：ScrollAnimationOptions: { duration: 1000, curve: Curve.Ease, canOverScroll: false }boolean: false**说明：**当前List、Scroll、Grid、WaterFlow均支持boolean类型和ICurve曲线。**元服务API：**从API version 11开始，该接口支持在元服务中使用。 |
| canOverScroll20+ | boolean | 否 | 是 | 滚动目标位置是否可以超出边界停留。仅当组件的edgeEffect设置为EdgeEffect.Spring时，滚动能够越界停留。设置为true时滚动可以在过界后停留，设置为false时滚动无法在过界后停留。默认值：false**元服务API：**从API version 20开始，该接口支持在元服务中使用。 |
#### UIScrollEvent19+
frameNode中 [getEvent('Scroll')](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS API/UI界面/arkui/js-apis-arkui-framenode.md) 方法的返回值，可用于给Scroll节点设置滚动事件。
UIScrollEvent继承于 [UIScrollableCommonEvent](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scrollable-common.md) 。
#### setOnWillScroll19+
setOnWillScroll(callback: ScrollOnWillScrollCallback | undefined): void
设置 [onWillScroll](#onwillscroll12) 事件的回调。
方法入参为undefined时，会重置事件回调。
**元服务API：** 从API version 19开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | [ScrollOnWillScrollCallback](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scroll.md)| undefined | 是 | onWillScroll事件的回调函数。 |
#### setOnDidScroll19+
setOnDidScroll(callback: ScrollOnScrollCallback | undefined): void
设置 [onDidScroll](#ondidscroll12) 事件的回调。
方法入参为undefined时，会重置事件回调。
**元服务API：** 从API version 19开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.ArkUI.ArkUI.Full
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | [ScrollOnScrollCallback](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/滚动与滑动/ts-container-scroll.md)| undefined | 是 | onDidScroll事件的回调函数。 |
#### 示例
#### 示例1（设置scroller控制器）
该示例展示了Scroll组件部分属性和scroller控制器的使用。
```
// xxx.ets
import { curves } from '@kit.ArkUI';
@Entry
@Component
struct ScrollExample {
  scroller: Scroller = new Scroller();
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.scroller) {
        Column() {
          ForEach(this.arr, (item: number) => {
            Text(item.toString())
              .width('90%')
              .height(150)
              .backgroundColor(0xFFFFFF)
              .borderRadius(15)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .margin({ top: 10 })
          }, (item: number) => item.toString())
        }.width('100%')
      }
      .scrollable(ScrollDirection.Vertical) // 滚动方向纵向
      .scrollBar(BarState.On) // 滚动条常驻显示
      .scrollBarColor(Color.Gray) // 滚动条颜色
      .scrollBarWidth(10) // 滚动条宽度
      .friction(0.6)
      .edgeEffect(EdgeEffect.None)
      .onWillScroll((xOffset: number, yOffset: number, scrollState: ScrollState) => {
        console.info(xOffset + ' ' + yOffset);
      })
      .onScrollEdge((side: Edge) => {
        console.info('To the edge');
      })
      .onScrollStop(() => {
        console.info('Scroll Stop');
      })
      Button('scroll 150')
        .height('5%')
        .onClick(() => { // 点击后下滑指定距离150.0vp
          this.scroller.scrollBy(0, 150);
        })
        .margin({ top: 10, left: 20 })
      Button('scroll 100')
        .height('5%')
        .onClick(() => { // 点击后滑动到指定位置，即下滑100.0vp的距离
          const yOffset: number = this.scroller.currentOffset().yOffset;
          this.scroller.scrollTo({ xOffset: 0, yOffset: yOffset + 100 });
        })
        .margin({ top: 60, left: 20 })
      Button('scroll 100')
        .height('5%')
        .onClick(() => { // 点击后滑动到指定位置，即下滑100.0vp的距离，滑动过程配置有动画
          let curve = curves.interpolatingSpring(10, 1, 228, 30); //创建一个弹簧曲线
          const yOffset: number = this.scroller.currentOffset().yOffset;
          this.scroller.scrollTo({ xOffset: 0, yOffset: yOffset + 100, animation: { duration: 1000, curve: curve } });
        })
        .margin({ top: 110, left: 20 })
      Button('back top')
        .height('5%')
        .onClick(() => { // 点击后回到顶部
          this.scroller.scrollEdge(Edge.Top);
        })
        .margin({ top: 160, left: 20 })
      Button('next page')
        .height('5%')
        .onClick(() => { // 点击后滑到下一页
          this.scroller.scrollPage({ next: true ,animation: true });
        })
        .margin({ top: 210, left: 20 })
      Button('fling -3000')
        .height('5%')
        .onClick(() => { // 点击后触发初始速度为-3000vp/s的惯性滚动
          this.scroller.fling(-3000);
        })
        .margin({ top: 260, left: 20 })
      Button('scroll to bottom 700')
        .height('5%')
        .onClick(() => { // 点击后滑到下边缘，速度值是700vp/s
          this.scroller.scrollEdge(Edge.Bottom, { velocity: 700 });
        })
        .margin({ top: 310, left: 20 })
    }.width('100%').height('100%').backgroundColor(0xDCDCDC)
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b0/v3/IpM8_9sTT5u7cGOV4oP-Jg/zh-cn_image_0000002534251378.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=2AE4FCC327D3DA30419BD43DC23FBED8FCEDE9269D137ADAC5C2D02CCFCBAF15)
#### 示例2（嵌套滚动实现方式一）
该示例使用onScrollFrameBegin事件实现了内层List组件和外层Scroll组件的嵌套滚动。
```
import { LengthMetrics } from '@kit.ArkUI';
@Entry
@Component
struct NestedScroll {
  @State listPosition: number = 0; // 0代表滚动到List顶部，1代表中间值，2代表滚动到List底部。
  private arr: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  private scrollerForScroll: Scroller = new Scroller();
  private scrollerForList: Scroller = new Scroller();
  build() {
    Flex() {
      Scroll(this.scrollerForScroll) {
        Column() {
          Text('Scroll Area')
            .width('100%')
            .height('40%')
            .backgroundColor(0X330000FF)
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.scrollerForList.scrollToIndex(5, false, ScrollAlign.START, { extraOffset: LengthMetrics.vp(5) });
            })
          List({ space: 20, scroller: this.scrollerForList }) {
            ForEach(this.arr, (item: number) => {
              ListItem() {
                Text('ListItem' + item)
                  .width('100%')
                  .height('100%')
                  .borderRadius(15)
                  .fontSize(16)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(Color.White)
              }.width('100%').height(100)
            }, (item: string) => item)
          }
          .width('100%')
          .height('50%')
          .edgeEffect(EdgeEffect.None)
          .friction(0.6)
          .onReachStart(() => {
            this.listPosition = 0;
          })
          .onReachEnd(() => {
            this.listPosition = 2;
          })
          .onScrollFrameBegin((offset: number) => {
            if ((this.listPosition == 0 && offset <= 0) || (this.listPosition == 2 && offset >= 0)) {
              this.scrollerForScroll.scrollBy(0, offset);
              return { offsetRemain: 0 };
            }
            this.listPosition = 1;
            return { offsetRemain: offset };
          })
          Text('Scroll Area')
            .width('100%')
            .height('40%')
            .backgroundColor(0X330000FF)
            .fontSize(16)
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%').height('100%')
    }.width('100%').height('100%').backgroundColor(0xDCDCDC).padding(20)
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/83/v3/MB35zAlATg-77YUpLf9c_Q/zh-cn_image_0000002534411324.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=82F4FE7EEDFE1851C4465ECFAD7C30013F3E118DDEB83263B2632AF454288C06)
#### 示例3（嵌套滚动实现方式二）
该示例使用 [nestedScroll](#nestedscroll10) 属性实现了内层List组件和外层Scroll组件的嵌套滚动。
```
@Entry
@Component
struct StickyNestedScroll {
  @State arr: number[] = [];
  @Styles
  listCard() {
    .backgroundColor(Color.White)
    .height(72)
    .width('100%')
    .borderRadius(12)
  }
  build() {
    Scroll() {
      Column() {
        Text('Scroll Area')
          .width('100%')
          .height('40%')
          .backgroundColor('#0080DC')
          .textAlign(TextAlign.Center)
        Tabs({ barPosition: BarPosition.Start }) {
          TabContent() {
            List({ space: 10 }) {
              ForEach(this.arr, (item: number) => {
                ListItem() {
                  Text('item' + item)
                    .fontSize(16)
                }.listCard()
              }, (item: number) => item.toString())
            }.width('100%')
            .edgeEffect(EdgeEffect.Spring)
            .nestedScroll({
              scrollForward: NestedScrollMode.PARENT_FIRST,
              scrollBackward: NestedScrollMode.SELF_FIRST
            })
          }.tabBar('Tab1')
          TabContent() {
          }.tabBar('Tab2')
        }
        .vertical(false)
        .height('100%')
      }.width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .friction(0.6)
    .backgroundColor('#DCDCDC')
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
  }
  aboutToAppear() {
    for (let i = 0; i < 30; i++) {
      this.arr.push(i);
    }
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/28/v3/8N7F2CtoTOO6Dza6sSteXQ/zh-cn_image_0000002565291225.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=28BA031271FB5BBD85F5C51FAD2FAFCD57550FE4BB8F260B67C025EAB4CF8D04)
#### 示例4（嵌套滚动父组件向子组件传递滚动）
该示例使用 [enableScrollInteraction](#enablescrollinteraction10) 属性和 [onScrollFrameBegin](#onscrollframebegin9) 事件实现了父组件向子组件传递滚动。
```
@Entry
@Component
struct NestedScroll {
  private headerHeight: number = 0;
  private arr: number[] = [];
  private scrollerForParent: Scroller = new Scroller();
  private scrollerForChild: Scroller = new Scroller();
  aboutToAppear(): void {
    for (let i = 0; i < 10; i++) {
      this.arr.push(i);
    }
  }
  build() {
    Scroll(this.scrollerForParent) {
      Column() {
        Text('Scroll Area')
          .width('100%')
          .height('40%')
          .backgroundColor(0X330000FF)
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.scrollerForChild.scrollToIndex(5);
          })
          .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
            this.headerHeight = newValue.height! as number;
          })
        List({ space: 20, scroller: this.scrollerForChild }) {
          ForEach(this.arr, (item: number) => {
            ListItem() {
              Text('ListItem' + item)
                .width('100%')
                .height('100%')
                .borderRadius(15)
                .fontSize(16)
                .textAlign(TextAlign.Center)
                .backgroundColor(Color.White)
            }.width('100%').height(100)
          }, (item: number) => item.toString())
        }
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
        .enableScrollInteraction(false)
        Text('Scroll Area')
          .width('100%')
          .height('40%')
          .backgroundColor(0X330000FF)
          .fontSize(16)
          .textAlign(TextAlign.Center)
      }
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .onScrollFrameBegin((offset: number, state: ScrollState) => {
      let retOffset = offset;
      let currOffset = this.scrollerForParent.currentOffset().yOffset;
      let newOffset = currOffset + offset;
      if (offset > 0) {
        if (this.scrollerForChild.isAtEnd()) {
          return { offsetRemain: offset };
        }
        if (newOffset > this.headerHeight) {
          retOffset = this.headerHeight - currOffset;
        }
        this.scrollerForChild.scrollBy(0, offset - retOffset);
      } else {
        if (this.scrollerForChild.currentOffset().yOffset <= 0) {
          return { offsetRemain: offset };
        }
        if (newOffset < this.headerHeight) {
          retOffset = this.headerHeight - currOffset;
        }
        this.scrollerForChild.scrollBy(0, offset - retOffset);
      }
      return { offsetRemain: retOffset };
    })
    .width('100%')
    .height('100%')
    .backgroundColor(0xDCDCDC)
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c8/v3/Ykn2cwS2QheXMu6uj07BdA/zh-cn_image_0000002565211203.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=0F0C12FA5C6F508D242D478CA83BEB619D2B98F8202F22273B44988EB6931EBB)
#### 示例5（设置限位滚动）
该示例实现了Scroll组件的限位滚动。
```
@Entry
@Component
struct Index {
  scroller: Scroller = new Scroller();
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
  build() {
    Scroll(this.scroller) {
      Column() {
        ForEach(this.arr, (item: number) => {
          Text(item.toString())
            .width('90%')
            .height(200)
            .backgroundColor(0xFFFFFF)
            .borderWidth(1)
            .borderColor(Color.Black)
            .borderRadius(15)
            .fontSize(16)
            .textAlign(TextAlign.Center)
        }, (item: number) => item.toString())
      }.width('100%').backgroundColor(0xDCDCDC)
    }
    .backgroundColor(Color.Yellow)
    .height('100%')
    .edgeEffect(EdgeEffect.Spring)
    .scrollSnap({snapAlign:ScrollSnapAlign.START, snapPagination:400, enableSnapToStart:true, enableSnapToEnd:true})
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/87/v3/TPv22X_lRI-TAaYsq6lzpA/zh-cn_image_0000002534251380.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=792EBD1DA9C3A0A76B79C00EDA83423F9E1DAAC4CDC9CB42434A7893F95CB1BA)
#### 示例6（获取子组件索引）
该示例展示了如何获得List组件的子组件索引。
```
// xxx.ets
@Entry
@Component
struct ListExample {
  private arr: number[] = [];
  private scroller: ListScroller = new ListScroller();
  @State listSpace: number = 10;
  @State listChildrenSize: ChildrenMainSize = new ChildrenMainSize(100);
  @State listIndex: number = -1;
  @State itemBackgroundColorArr: boolean[] = [false];
  aboutToAppear(){
    // 初始化数据源。
    for (let i = 0; i < 10; i++) {
      this.arr.push(i);
    }
    this.listChildrenSize.splice(0, 5, [100, 100, 100, 100, 100]);
  }
  build() {
    Column() {
      List({ space: this.listSpace, initialIndex: 4, scroller: this.scroller }) {
        ForEach(this.arr, (item: number) => {
          ListItem() {
            Text('item-' + item)
              .height( item < 5 ? 100 : this.listChildrenSize.childDefaultSize)
              .width('90%')
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .borderRadius(10)
              .backgroundColor( this.itemBackgroundColorArr[item] ? 0x68B4FF: 0xFFFFFF)
          }
        }, (item: number) => item.toString())
      }
      .backgroundColor(Color.Gray)
      .layoutWeight(1)
      .scrollBar(BarState.On)
      .childrenMainSize(this.listChildrenSize)
      .alignListItem(ListItemAlign.Center)
      .gesture(
        PanGesture()
          .onActionUpdate((event: GestureEvent) => {
            if (event.fingerList[0] != undefined && event.fingerList[0].localX != undefined && event.fingerList[0].localY != undefined) {
              this.listIndex = this.scroller.getItemIndex(event.fingerList[0].localX, event.fingerList[0].localY);
              this.itemBackgroundColorArr[this.listIndex] = true;
            }
          })
      )
      .gesture(
        TapGesture({ count: 1 })
          .onAction((event: GestureEvent) => {
            if (event) {
              this.itemBackgroundColorArr.splice(0,this.itemBackgroundColorArr.length);
            }
          })
      )
      Text('您当前位置Item索引为：'+ this.listIndex)
        .fontColor(Color.Red)
        .height(50)
    }
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/06/v3/Cp5QBNdTSNyx3RcPkakRCA/zh-cn_image_0000002534411326.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=2DDC62D063110122EE40BB5EDEB20C27EF0D53DC2BADC288416E2665FD81C658)
#### 示例7（设置边缘渐隐）
该示例实现了Scroll组件开启边缘渐隐效果并设置边缘渐隐长度。
```
// xxx.ets
import { LengthMetrics } from '@kit.ArkUI';
@Entry
@Component
struct ScrollExample {
  scroller: Scroller = new Scroller();
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.scroller) {
        Column() {
          ForEach(this.arr, (item: number) => {
            Text(item.toString())
              .width('90%')
              .height(150)
              .backgroundColor(0xFFFFFF)
              .borderRadius(15)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .margin({ top: 10 })
          }, (item: string) => item)
        }.width('100%')
      }
      .fadingEdge(true,{fadingEdgeLength:LengthMetrics.vp(80)})
    }.width('100%').height('100%').backgroundColor(0xDCDCDC)
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/24/v3/E7xOekdsT5Gg3c9yKkbW1Q/zh-cn_image_0000002565291227.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=3F40CAE147000DA70B645E29B41A392505C8DE4F36E0A73558002C8CF189956D)
#### 示例8（单边边缘效果）
该示例通过 [edgeEffect](#edgeeffect) 接口，实现了Scroll组件设置单边边缘效果。
```
// xxx.ets
@Entry
@Component
struct ScrollExample {
  scroller: Scroller = new Scroller();
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.scroller) {
        Column() {
          ForEach(this.arr, (item: number) => {
            Text(item.toString())
              .width('90%')
              .height(150)
              .backgroundColor(0xFFFFFF)
              .borderRadius(15)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .margin({ top: 10 })
          }, (item: string) => item)
        }.width('100%')
      }
      .edgeEffect(EdgeEffect.Spring,{alwaysEnabled:true,effectEdge:EffectEdge.START})
    }.width('100%').height('100%').backgroundColor(0xDCDCDC)
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/5a/v3/QY_c1wx7QYWS7q9Z3tUTgQ/zh-cn_image_0000002565211205.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=BD803E22EE394AB588CD74AB094AA9ABA443C648F981B07ABBE5EB302C9E455C)
#### 示例9（划动翻页效果）
该示例通过 [enablePaging](#enablepaging11) 接口，实现了Scroll组件滑动翻页效果。
```
// xxx.ets
@Entry
@Component
struct EnablePagingExample {
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  build() {
    Stack({ alignContent: Alignment.Center }) {
      Scroll() {
        Column() {
          ForEach(this.arr, (item: number) => {
            Text(item.toString())
              .width('100%')
              .height('100%')
              .borderRadius(15)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .backgroundColor(0xFFFFFF)
          }, (item: number) => item.toString())
        }
      }.width('90%').height('90%')
      .enablePaging(true)
    }.width('100%').height('100%').backgroundColor(0xDCDCDC)
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/81/v3/W0gN4iHBTjy6hP_NAQ-jvQ/zh-cn_image_0000002534251382.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=18DA328E2E4B8BCAE1E7B3B1CA59AB0EED2D1EB6E051F79049AEAD47D7D7914A)
#### 示例10（设置过界停留）
该示例通过 [scrollTo](#scrollto) 接口，实现了Scroll组件设置过界停留效果。
```
// xxx.ets
import { curves } from '@kit.ArkUI';
@Entry
@Component
struct StickyNestedScroll {
  scroller: Scroller = new Scroller;
  build() {
    Column() {
      Row() {
        Button('有动画scrollTo').onClick(() => {
          let curve = curves.interpolatingSpring(0.5, 5, 10, 15) //创建一个弹簧曲线
          const yOffset: number = this.scroller.currentOffset().yOffset;
          this.scroller.scrollTo({
            xOffset: 0,
            yOffset: yOffset - 100,
            animation: { duration: 1000, curve: curve, canOverScroll: true },
            canOverScroll: true
          })
        }).margin({ top: 10 })
        Button('无动画scrollTo').onClick(() => {
          const yOffset: number = this.scroller.currentOffset().yOffset;
          this.scroller.scrollTo({
            xOffset: 0,
            yOffset: yOffset - 100,
            animation: false,
            canOverScroll: true
          })
        }).margin({ top: 10, left: 20 })
      }.margin({ bottom: 20 })
      Scroll(this.scroller) {
        Column() {
          Text('Scroll Area')
            .width('100%')
            .height('100%')
            .backgroundColor('#0080DC')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring) //设置边缘效果
      .fadingEdge(false) //关闭边缘渐隐效果
      .scrollBar(BarState.Auto)
      .friction(undefined)
      .backgroundColor('#DCDCDC')
      .width('100%')
      .height('50%')
    }
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/2e/v3/z3ob1WliQNesBNgb8TBLzA/zh-cn_image_0000002534411328.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=141B44F27E08A4EAA6D6534C158ECAC146E2C082B0198B20590C7032E82C534D)
#### 示例11（自由滚动和缩放）
从API version 20开始，该示例实现了Scroll组件自由滚动和缩放效果。
```
@Entry
@Component
struct ScrollZoomExample {
  @State currScale:number = 1;
  build() {
    Column() {
      Scroll() {
        Image($r('app.media.image1')) // 'app.media.image1'仅作示例，请替换实际图片。
      }
      .height(400)
      .scrollable(ScrollDirection.FREE)
      .minZoomScale(1)
      .maxZoomScale(2)
      .zoomScale(this.currScale!!)
      .enableBouncesZoom(true)
      .onDidZoom((scale: number) => {
        console.info(`onDidZoom:${scale}`);
      })
      .onZoomStart(() => {
        console.info('onZoomStart');
      })
      .onZoomStop(() => {
        console.info('onZoomStop');
      })
    }.width('100%').height('100%')
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6c/v3/nlhQ8feRRxuHg8z8ky4D-Q/zh-cn_image_0000002565291229.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=5931645CCD770248733F3D6170C3EF243DA011E25C32E3EA22548EC9287FDB7B)
#### 示例12（获取内容总大小）
从API version 22 开始，该示例实现了获取内容总大小的功能。
```
import { BusinessError } from '@kit.BasicServicesKit';
@Entry
@Component
struct ScrollExample1 {
  scroller: Scroller = new Scroller();
  private arr: number[] = []
  aboutToAppear() {
    for (let j = 0; j < 10; j++) {
      this.arr.push(j);
    }
  }
  @State contentWidth: number = -1;
  @State contentHeight: number = -1;
  build() {
    Column() {
      Text('设置scroller控制器和ForEach')
      Row() {
        // 点击按钮来调用contentSize函数获取内容尺寸
        Button('GetContentSize')
          .onClick(() => {
            // Scroller未绑定组件时会抛异常，需要加上try catch保护
            try {
              // 通过调用contentSize函数获取内容尺寸的宽度值
              this.contentWidth = this.scroller.contentSize().width;
              // 通过调用contentSize函数获取内容尺寸的高度值
              this.contentHeight = this.scroller.contentSize().height;
            } catch (error) {
              let err: BusinessError = error as BusinessError;
                console.error(`Failed to get contentSize of the grid, code=${err.code}, message=${err.message}`);
            }
          })
        // 将获取到的内容尺寸信息通过文本进行呈现
        Text('Width：' + this.contentWidth + '，Height：' + this.contentHeight)
          .fontColor(Color.Red)
          .height(50)
      }
      Stack({ alignContent: Alignment.TopStart }) {
        Scroll(this.scroller) {
          Column() {
            ForEach(this.arr, (item: number) => {
              Text(item.toString())
                .width('90%')
                .height(150)
                .backgroundColor(0xFFFFFF)
                .borderRadius(15)
                .fontSize(16)
                .textAlign(TextAlign.Center)
                .margin({ top: 10 })
            }, (item: number) => item.toString())
          }.width('100%')
        }
        .scrollable(ScrollDirection.Vertical) // 滚动方向纵向
        .scrollBar(BarState.On) // 滚动条常驻显示
        .scrollBarColor(Color.Gray) // 滚动条颜色
        .scrollBarWidth(10) // 滚动条宽度
        .friction(0.6)
        .edgeEffect(EdgeEffect.None)
      }.width('100%').height('100%').backgroundColor(0xDCDCDC)
    }
  }
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a5/v3/S3YTbCqeQUm_vFFp-dpwzA/zh-cn_image_0000002565211207.gif?HW-CC-KV=V1&HW-CC-Date=20260401T092900Z&HW-CC-Expire=86400&HW-CC-Sign=18679F6427C910E14A459BCADCAC57B35457AECE0AF5E85F55124B7C301EE5FF)
#### 示例13（设置滚动事件）
该示例通过FrameNode中的 [getEvent('Scroll')](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS API/UI界面/arkui/js-apis-arkui-framenode.md) 获取 [UIScrollEvent](#uiscrollevent19) ，并为Scroll设置滚动事件回调，用于事件监听方因无法直接修改页面代码而无法使用声明式接口设置回调的场景。
从API version 19开始，新增UIScrollEvent接口。
```
import { NodeController, FrameNode, typeNode } from '@kit.ArkUI';
class MyNodeController extends NodeController {
  public rootNode: FrameNode | null = null;
  makeNode(uiContext: UIContext): FrameNode | null {
    this.rootNode = new FrameNode(uiContext);
    this.rootNode.commonAttribute.width(100);
    return this.rootNode;
  }
  addCommonEvent(frameNode: FrameNode) {
    // 获取Scroll事件
    let scrollEvent: UIScrollEvent | undefined = typeNode.getEvent(frameNode, 'Scroll');
    // 设置OnWillScroll事件
    scrollEvent?.setOnWillScroll((xOffset: number, yOffset: number, scrollState: ScrollState,
      scrollSource: ScrollSource) => {
      console.info('onWillScroll xOffset = ${xOffset}, yOffset = ${yOffset}, scrollState = ${scrollState}, scrollSource = ${scrollSource}');
    });
    // 设置OnDidScroll事件
    scrollEvent?.setOnDidScroll((scrollOffset: number, scrollState: ScrollState) => {
      console.info('onDidScroll scrollOffset = ${scrollOffset}, scrollState = ${scrollState}');
    });
    // 设置OnReachStart事件
    scrollEvent?.setOnReachStart(() => {
      console.info('onReachStart');
    });
    // 设置OnReachEnd事件
    scrollEvent?.setOnReachEnd(() => {
      console.info('onReachEnd');
    });
    // 设置OnScrollStart事件
    scrollEvent?.setOnScrollStart(() => {
      console.info('onScrollStart');
    });
    // 设置OnScrollStop事件
    scrollEvent?.setOnScrollStop(() => {
      console.info('onScrollStop');
    });
    // 设置OnScrollFrameBegin事件
    scrollEvent?.setOnScrollFrameBegin((offset: number, state: ScrollState) => {
      console.info('onScrollFrameBegin offset = ${offset}, state = ${state}');
      return undefined;
    });
  }
}
@Entry
@Component
struct Index {
  @State index: number = 0;
  private myNodeController: MyNodeController = new MyNodeController();
  @State numbers: string[] = [];
  aboutToAppear() {
    for (let i = 0; i < 30; i++) {
      this.numbers.push('${i+1}');
    }
  }
  build() {
    Column() {
      Button('add CommonEvent to Scroll')
        .onClick(() => {
          this.myNodeController!.addCommonEvent(this.myNodeController!.rootNode!.getParent()!.getPreviousSibling()!)
        })
      Scroll() {
        Column() {
          ForEach(this.numbers, (day: string, index: number) => {
            Column() {
              Text(day)
                .fontSize(16)
                .backgroundColor(0xF9CF93)
                .width('90%')
                .height(80)
                .textAlign(TextAlign.Center)
                .margin({ top: 10 })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }, (day: string, index: number) => index.toString() + day)
        }
      }
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .width('90%')
      .backgroundColor(0xFAEEE0)
      .height(300)
      NodeContainer(this.myNodeController)
    }
  }
}
```