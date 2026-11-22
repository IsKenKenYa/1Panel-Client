# 触发验证

验证 hmos-share-kit-knock-share 是否在正确场景被触发、在无关场景不被触发。提示词参考 [test-prompts.md](test-prompts.md)。

**测试约束**：每个用例的输入自包含，无需追问；判定标准为"应触发 / 不应触发"的二值结论；输入不得显式包含 skill 名，以真实验证路由触发能力。

---

### 测试用例：TRIGGER-001

**skill**：hmos-share-kit-knock-share（必填）  
**类型**：trigger（触发验证）

#### 输入
```
帮我在当前工程接入碰一碰传送文件。
```
#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-share-kit-knock-share（必填）  
**类型**：trigger（触发验证）

#### 输入

```
请接入碰一碰链接分享（App Linking）。挂载页是 pages/VideoPlay。
```
#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-003

**skill**：hmos-share-kit-knock-share（必填）  
**类型**：trigger（触发验证）

#### 输入

```
接入碰一碰。要电脑端应用内接收，也要精准碰一碰。
```
#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-004

**skill**：hmos-share-kit-knock-share（必填）  
**类型**：trigger（触发验证）

#### 输入

```
工程已有碰一碰文件分享，请再接入碰一碰链接分享。

```
#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-005

**skill**：hmos-share-kit-knock-share（必填）  
**类型**：trigger（触发验证）

#### 输入

```
请接入隔空传送（gesturesShare）分享文件。

```
#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-006

**skill**：hmos-share-kit-knock-share（必填）  
**类型**：trigger（触发验证）

#### 输入

```
请帮我修复一个 ArkTS 编译报错：Type 'string' is not assignable to type 'number'。

```
#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-007

**skill**：hmos-share-kit-knock-share（必填）  
**类型**：trigger（触发验证）

#### 输入

```
请帮我为 HarmonyOS 应用添加数据路由分享（dataRoutingShare）能力。

```
#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-008

**skill**：hmos-share-kit-knock-share（必填）  
**类型**：trigger（触发验证）

#### 输入

```
请在 pages/Detail 页面挂载碰一碰分享，分享当前页已选中的本地文件 URI 列表。

```
#### 预期输出

**应触发**：是
