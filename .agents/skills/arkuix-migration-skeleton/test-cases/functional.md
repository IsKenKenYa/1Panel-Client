# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：arkuix-migration-skeleton
**类型**：functional（功能验证）

#### 输入

用 modify 模式把我的 Stage 工程改造成 ArkUI-X 跨平台工程

#### 预期输出

**验证标准**：

产出 skeleton-result.json + .arkui-x/{android,ios} 平台壳 + hvigorfile 改写 + hvigor-config 注入 arkui-x 插件 + buildArkTS 占位符 + local.properties；modify 默认走内置归档（零 ace 依赖）

**应包含**：skeleton-result, .arkui-x, android, ios, hvigorfile, arkui-x-config

---

### 测试用例：FUNC-002

**skill**：arkuix-migration-skeleton
**类型**：functional（功能验证）

#### 输入

用 new 模式新建一个 ArkUI-X scaffold 工程并迁入我的源码，Compile SDK 选 26.0.0

#### 预期输出

**验证标准**：

归档物化 scaffold（零 ace 交互）；--compile-sdk 26.0.0 做六元组替换（build-profile/hvigor-config/oh-package）；--migrate-configs 须显式确认（非 TTY 缺参=退出码 6）；platform_baseline 实测提取

**应包含**：scaffold, compile-sdk, 26.0.0, platform_baseline
