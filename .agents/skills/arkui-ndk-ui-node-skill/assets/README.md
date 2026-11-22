# assets/ — ArkUI NDK UI 节点 Skill 用法导航

> 本文件仅作**导航用途**：一句话用途 + 目录结构 + 指向权威源的链接。
> Skill 完整规则以同级 `../SKILL.md` 为**唯一权威源**——触发关键词、工作流程、七类坑点速查、骨架生成六条工程约束等规则细节均不在本文件重复维护，避免内容漂移与上下文冗余。

## 用途

帮助开发者使用 ArkUI C 接口（NDK）构建 UI 节点并挂载到 ArkTS 侧（P1 ArkTS→C），或将 ArkTS 组件挂载到 C 侧 Native 节点下（P2 C→ArkTS）。

## 目录结构

```
arkui-ndk-ui-node-skill/
├── SKILL.md                       # ⭐ Skill 主文件（权威规则源：方向判定 / 骨架生成 / 坑点检测 / 工程约束）
├── references/                    # 坑点参考文档 + API 事实表（命中时按需加载）
│   ├── api-facts.md               #   C/ArkTS API 唯一权威源表（头文件 / 符号名 / 签名要点）
│   ├── handle-limit.md            #   handle 只能当 child
│   ├── napi-ref-pair.md           #   引用成对
│   ├── node-dispose.md            #   dispose 防泄漏
│   ├── node-type-confusion.md     #   节点类型混乱
│   ├── thread-safety.md           #   子线程调用
│   ├── napi-descriptor-field-order.md   #   descriptor 字段顺序
│   └── component-content-constructor.md #   ComponentContent 构造签名
├── templates/                     # 可编译工程骨架模板
│   ├── P1/                        #   ArkTS→C 方向（NodeContent + ContentSlot + Native 节点树）
│   └── P2/                        #   C→ArkTS 方向（ComponentContent + wrapBuilder + addChild）
├── test-cases/                    # 功能与触发测试用例
│   ├── functional.md              #   功能验证用例（FUNC-* 系列）
│   └── trigger.md                 #   触发词验证用例
└── assets/                        # 本目录：用法导航 + 运行时评测产物
    ├── README.md                  #   本文件（导航）
    ├── bench/                     #   （运行时生成）bench 用例集与验证用例
    └── report/                    #   （运行时生成）评测报告
```

> `assets/bench/` 与 `assets/report/` 由 `hmos-skill-test-runner` / `hmos-skill-reviewer` 工具在评测时生成，不纳入源仓版本管理。

## 权威源指引

需要查阅规则细节时直接读以下文件，不在本文件复制：

- **Skill 规则全貌**（触发关键词、方向判定决策树、骨架生成步骤、坑点检测规则与 Checklist、骨架生成六条工程约束）→ [`../SKILL.md`](../SKILL.md)
- **C/ArkTS API 事实**（头文件 / .d.ts 符号定位、签名要点、用途、来源核验方式）→ [`../references/api-facts.md`](../references/api-facts.md)
- **七类坑点速查**（每类坑点的检测条件、Reference 文件、摘要）→ `SKILL.md`「坑点检测规则」表
- **模板集成步骤** → [`../templates/P1/README.md`](../templates/P1/README.md) / [`../templates/P2/README.md`](../templates/P2/README.md)
