# 运行时管理模块 FAQ

## 1. 当前支持哪些运行时分类？

- `PHP`
- `Node`
- `Java`
- `Go`
- `Python`
- `.NET`

这些分类统一显示在 `RuntimesCenterPage` 顶部。

## 2. Week 7 当前支持哪些操作？

- 列表加载
- 详情查看
- 基础表单骨架
- `start`
- `stop`
- `restart`
- `sync`
- `remark`
- `delete`

## 3. 为什么表单里没有完整的 PHP / Node 深配置？

因为 Week 7 只做通用 runtime 链路，语言特定深化能力留到 Week 8：

- PHP extensions
- PHP/FPM config
- Node modules
- Node scripts
- 完整 appstore create 向导

## 4. 为什么 `appstore create` 暂时不可用？

当前移动端已经把通用表单链路打通，但 appstore 资源的完整 app 选择和版本解析流程仍留在 Week 8 的专用向导里。

## 5. 详情页的 `Overview / Config / Advanced` 分别看什么？

- `Overview`
  - 运行时基础信息和启停重启
- `Config`
  - image / codeDir / path / port / source / params
- `Advanced`
  - remark 编辑
  - 高级配置统计
  - Week 8 能力提示

## 6. no-server 时会发生什么？

不会自动请求 runtime API；页面会保持 server-aware 的空态行为。

## 7. 当前删除运行时会不会先做依赖检查？

本轮主 UI 先只保留删除确认流，`installed/delete/check` 还没有接入移动端交互层。后续如果需要更强保护，可以直接在现有分层上补进去。

---

**文档版本**: 2.0  
**最后更新**: 2026-03-27
