# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：arkuix-interface-scan
**类型**：functional（功能验证）

#### 输入

扫描我的 OpenHarmony Stage 工程全部 @ohos.* 接口引用，按 ArkUI-X 适配性分类输出报告

#### 预期输出

**验证标准**：

产出 ScanReport JSON + 迁移建议报告（Markdown）；接口按六分类（①完整直用/②有损直用/③等价桥接/④降级桥接/⑤平台裁剪/⑥业务决策/unknown）归类；SDK 判定源经开发者确认（询问先行——输出查找方法+参考候选+重跑通道，不自动选定）

**应包含**：ScanReport, adaptation, full_direct, reduced_direct, equivalent_bridge, business_decision, unknown

---

### 测试用例：FUNC-002

**skill**：arkuix-interface-scan
**类型**：functional（功能验证）

#### 输入

用本机 SDK 扫描这个工程，SDK 路径是 C:/Users/x/OpenHarmony/Sdk/26.0.0

#### 预期输出

**验证标准**：

SDK 路径经显式确认后扫描完成；scan-report.json 的 sdk.origin=explicit、sdk.confirmed=true；@kit.* 按 SDK kits 索引展开分类

**应包含**：sdk, confirmed, explicit
