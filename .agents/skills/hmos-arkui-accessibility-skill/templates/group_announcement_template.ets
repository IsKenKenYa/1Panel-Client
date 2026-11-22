/**
 * 聚合播报模板（C 类 + 反 group，API 12+）
 * 事实基准：references/api-facts.md、references/group-dynamic-announcement.md
 */

// ========== C 类：整组朗读（在父容器上设置） ==========
// 场景：日期由年、月、日三个 Text 组成，读屏逐个聚焦很碎
Column() {
  Text('2026')
  Text('9')
  Text('14')
}
  .accessibilityGroup(true)
// 行为：容器成为单一聚焦单元，一次播报聚合内容，子 Text 不再分别聚焦
// 组播报文本优先级：用户设置文本优先，否则组内文本聚合（GetContent，api-facts.md）
// 错误做法：给每个 Text 单独加 accessibilityText 当作"聚合"

// 指定组播报文本（可选）：在容器上设 accessibilityText
Column() {
  Text('2026')
  Text('9')
  Text('14')
}
  .accessibilityGroup(true)
  .accessibilityText('出生日期 2026年9月14日')

// ========== 反 group：组内某组件仍需单独聚焦 ==========
// 场景：生日聚合播报，但年份仍要能单独聚焦并播报'出生年份'
Column() {
  Text('2026')
    .accessibilityLevel('yes')        // 例外：仍可单独聚焦（level 是 group 的反操作维度）
    .accessibilityText('出生年份')     // 单独聚焦时的语义文本（注意：设置后原文本'2026'不再播报）
  Text('9')
  Text('14')
}
  .accessibilityGroup(true)

// ========== 动态播报（内容变化时主动通知，与聚合组合） ==========
import { accessibility } from '@kit.AccessibilityKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct CountdownPage {
  @State remain: string = '10';

  build() {
    Column() {
      Text(`剩余 ${this.remain} 秒`)
        .accessibilityGroup(true)              // 若与图标组合，容器聚合
    }
    .onAppear(() => {
      setInterval(() => {
        this.remain = String(Number(this.remain) - 1);
        this.announce();                       // 内容变化主动通知辅助服务
      }, 1000)
    })
  }

  announce() {
    let eventInfo: accessibility.EventInfo = {
      type: 'requestFocusForAccessibility',
      bundleName: (getContext() as common.UIAbilityContext)?.abilityInfo?.bundleName,
      triggerAction: 'common',
      customId: 'countdown'
    };
    accessibility.sendAccessibilityEvent(eventInfo);
  }
}
// 注意：@State 文本变化会自动反映到无障碍树；"变化即播/抢焦点提醒"类才需要 sendAccessibilityEvent
