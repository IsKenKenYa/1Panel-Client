/**
 * 事件响应与自定义走焦模板（G 类 + 事件回调）
 * 事实基准：references/api-facts.md、references/event-and-focus.md
 * 版本门禁：onAccessibilityHover 12+ / onAccessibilityFocus 18+ /
 *           accessibilityDefaultFocus 18+ / accessibilityNextFocusId 18+（isConsiderDescendants 26+）
 */

// ========== 事件回调：统计获焦次数（US-4，onAccessibilityFocus，API 18+） ==========
@Entry
@Component
struct FocusCountPage {
  @State focusCount: number = 0;

  build() {
    Column({ space: 16 }) {
      Text(`已获焦 ${this.focusCount} 次`)
      Button('目标卡片')
        .onAccessibilityFocus((isFocus: boolean) => {
          if (isFocus) {
            this.focusCount += 1;    // 移入计数；移出 isFocus=false
          }
        })
    }
  }
}

// ========== 事件回调：无障碍触摸预览（onAccessibilityHover，API 12+） ==========
// 场景：读屏用户单指摸到卡片时展开详情、离开时收起（属性与方法可叠加）
// 回调双参数：(isHover, event)——单参数写法会编译报错（2026-10 评测 vod-3 实测）
Column() {
  // 卡片内容
}
  .onAccessibilityHover((isHover: boolean, event: AccessibilityHoverEvent) => {
    if (isHover) {
      // 触摸进入：展开
    } else {
      // 触摸离开：收起
    }
  })

// ========== G 类：页面首焦点（accessibilityDefaultFocus，API 18+） ==========
build() {
  Column() {
    Button('确认')                    // 页面首个读屏焦点
      .accessibilityDefaultFocus(true)
    Button('取消')
  }
}

// ========== G 类：自定义下一焦点（accessibilityNextFocusId，API 18+） ==========
// 简约性（vod-6）：仅目标组件需要 .id()；源组件（挂 nextFocusId 的组件）不加 id——无业务用途
Column() {
  TextInput({ placeholder: '手机号' })
    .id('phone_input')                             // 仅目标组件需要 id
  TextInput({ placeholder: '验证码' })
    .accessibilityNextFocusId('phone_input')       // 验证码之后回到手机号（源组件无需 id）
}

// 子节点参与模式（API 26+）：isConsiderDescendants 默认 false（下一焦点落到目标本身，不进入其子节点）
// 简约性（vod-6）：与默认值一致的参数不显式传——跳过目标子节点是默认行为，省略第二参数即可；
// 仅当需要进入目标子节点时才显式传 true
Column() {
  // 目标容器含多个子节点
}
  .id('target_group')
  .accessibilityNextFocusId('target_group', { isConsiderDescendants: true })   // 进入其子节点（非默认值，显式传）
// 跳过目标子节点（默认行为）：.accessibilityNextFocusId('next_step')，不传第二参数

// ========== 组合：首焦点 + 聚焦统计 + 软提示（API 18+，对满足版本工程不阻断） ==========
// 版本门禁输出模板：
//   该能力需 API 18+。当前 build-profile：compileSdkVersion=X / compatibleSdkVersion=Y / targetSdkVersion=Z
//   任一 < 18 → 阻断并给字段提升建议，零代码输出（含"方案示意"形式）；全部 ≥ 18 → 软提示版本要求后正常输出
@Entry
@Component
struct PlayerPage {
  @State focusCount: number = 0;

  build() {
    Column() {
      Button('播放')
        .accessibilityDefaultFocus(true)
        .onAccessibilityFocus((isFocus: boolean) => {
          if (isFocus) {
            this.focusCount += 1;
          }
        })
    }
  }
}
