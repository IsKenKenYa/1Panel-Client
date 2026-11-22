# 19. 废弃接口替换

## 规则

| 规则 | 说明 |
|------|------|
| **禁止使用 CustomDialogController** | API 12 起不推荐，用 `promptAction.openCustomDialog` 替代 |
| **禁止使用 pageTransition** | 用 Navigation 转场或 Modal 转场替代 |
| **禁止使用 @ohos.* 路径导入** | 旧版导入路径已废弃，必须用 `@kit.*` 替代 |
| **禁止在 @Component 中使用 static {}** | V1 中静态代码块不执行（API 22 起告警） |

## 废弃对照表

| ❌ 废弃写法 | ✅ 正确替代 |
|------------|-----------|
| `CustomDialogController` | `promptAction.openCustomDialog` |
| `pageTransition()` | Navigation 转场 / Modal 转场 |
| `@ohos.router` 做导航 | Navigation + NavDestination |
| 全局 `animateTo`/`vp2px` 等（API 18+） | `this.getUIContext().animateTo()` 等 |
| `@Component` + `static {}` | 使用 @ComponentV2 或移除静态代码块 |
| `@ohos.*` 导入 | `@kit.*` 导入 |
| `SwiperDisplayMode.AutoLinear` | `SwiperDisplayMode.Auto`（AutoLinear 已废弃） |

## 参考

- 导入规则见 [01-import](01-import.md)
- UIContext 替换见 [02-uicontext](02-uicontext.md)
- 导航与路由见 [11-navigation](08-navigation.md)