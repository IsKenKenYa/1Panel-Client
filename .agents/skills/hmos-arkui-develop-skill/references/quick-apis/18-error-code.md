# 18. 错误码速查

| 错误码 | 说明 | 相关章节 |
|--------|------|---------|
| **100003** | Router 页面栈超过 32 页 | [08-navigation](08-navigation.md) |
| **100005** | Navigation 跳转未注册 builder 函数的页面 | [08-navigation](08-navigation.md) |
| **100006** | Navigation 跳转未包含 NavDestination 的页面 | [08-navigation](08-navigation.md) |
| **100021** | 声明式 FrameNode 不允许修改（设属性、增删子节点、绑定控制器） | [11-extension](11-extension.md) |
| **10505001** | 成员属性名与 CustomComponent 链式方法/通用属性重名；属性不存在；NavDestination 错用 titleMode 等 | [03-component](03-component.md)、[07-attribute-params](07-attribute-params.md) |
| **10605038** | 无类型对象字面量（arkts-no-untyped-obj-literals） | [00-arkts-syntax](00-arkts-syntax.md) |
| **10605040** | 内联对象字面量作类型（arkts-no-obj-literals-as-types） | [00-arkts-syntax](00-arkts-syntax.md) |
| **106203** | 对未挂载节点执行操作 | [11-extension](11-extension.md) |
| **10905202** | Button('label') 与 children 同时传入 | [04-build](04-build.md) |
| **130000** | addMonitor/clearMonitor 目标必须是 @ObservedV2 class 或 @ComponentV2 实例 | [05-state](05-state.md) |
| **130002** | addMonitor/clearMonitor 回调必须为命名函数 | [05-state](05-state.md) |
| **140109** | @Builder 内修改入参（API 23+） | [05-state](05-state.md) |
| **arkts-no-decl-merging** | 跨文件顶层 interface/class 重名 | [03-component](03-component.md) |
| **arkts-no-destruct-decls** | 禁止解构声明 | [00-arkts-syntax](00-arkts-syntax.md) |
| **arkts-no-any-unknown** | 禁止 any/unknown | [00-arkts-syntax](00-arkts-syntax.md) |
| **arkts-no-ctor-prop-decls** | 禁止构造参数属性 | [00-arkts-syntax](00-arkts-syntax.md) |
| **arkts-no-func-expressions** | 禁止函数表达式（用箭头函数） | [00-arkts-syntax](00-arkts-syntax.md) |
| **arkts-no-nested-funcs** | @Extend/@Styles 内嵌套函数定义 | [10-style](10-style.md)、[00-arkts-syntax](00-arkts-syntax.md) |
| **arkts-no-untyped-obj-literals** | 无类型对象字面量 | [00-arkts-syntax](00-arkts-syntax.md) |
| **arkts-no-spread** | 禁止对象展开 | [00-arkts-syntax](00-arkts-syntax.md) |