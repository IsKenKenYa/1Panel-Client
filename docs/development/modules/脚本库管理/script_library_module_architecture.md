# 脚本库管理模块架构设计

## 模块目标

- Phase 1 Week 4 交付脚本库主链路
- 入口固定为 `ServerDetailPage -> OperationsCenterPage -> Scripts`
- 只做移动端 MVP：列表、查看代码、同步、运行输出、可选删除

## Source Of Truth

- Web API：`docs/OpenSource/1Panel/frontend/src/api/modules/cronjob.ts`
- Web 页面：`docs/OpenSource/1Panel/frontend/src/views/cronjob/library/index.vue`
- Web 运行页：`docs/OpenSource/1Panel/frontend/src/views/cronjob/library/run/index.vue`
- Core API：`docs/OpenSource/1Panel/core/app/api/v2/script_library.go`
- Core Router：`docs/OpenSource/1Panel/core/router/ro_script_library.go`

## Week 4 API 真值

### REST
1. `POST /core/script/search`
2. `POST /core/script/sync`
3. `POST /core/script/del`

### WebSocket
1. `GET /core/script/run`

说明：
- `run` 为 websocket，不是普通 POST
- 当前 App 默认 `operateNode=local`
- 输出协议按 `type=cmd` + base64 文本处理

## 分层落点

- API / Infra
  - `ScriptLibraryV2Api`
  - `ScriptRunWsClient`
- Repository
  - `ScriptLibraryRepository`
- Service
  - `ScriptLibraryService`
- State
  - `ScriptLibraryProvider`
- Presentation
  - `ScriptLibraryPage`
  - `ScriptCodePreviewSheetWidget`
  - `ScriptRunOutputSheetWidget`

## Week 4 UI 范围

- 搜索、分组筛选、刷新
- 脚本卡片字段：`name / group / description / interactive / createdAt`
- `view code`：等宽文本 + 复制
- `run`：只读输出 viewer + 复制
- `sync`：确认后执行
- `delete`：仅非系统脚本显示

## 已知取舍

- 不做 create/edit 页面
- 不扩展为完整终端管理
- `sync` / `run` 的真实成功流仍建议在隔离环境验证

---

**文档版本**: 1.0
**最后更新**: 2026-03-27
