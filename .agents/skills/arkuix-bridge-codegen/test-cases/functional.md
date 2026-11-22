# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：arkuix-bridge-codegen
**类型**：functional（功能验证）

#### 输入

根据这份 ScanReport（含 ③等价桥接+④降级桥接接口），为每个接口生成跨平台桥接六件套

#### 预期输出

**验证标准**：

产出 bridge-artifact.json + 六件套（①Interface 契约 ②Local ③ArkUIX ④Android BridgePlugin ⑤iOS BridgePlugin ⑥Impl 分发器）；③类查 native-api-map 映射等价原生 API；④类降级占位；audit 自检（deficient=硬残缺待补+action 指引）

**应包含**：bridge-artifact, Interface, Local, ArkUIX, Impl, BridgePlugin, audit
