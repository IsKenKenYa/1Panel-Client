# 项目配置检查

在使用任何意图装饰器之前，必须检查项目根目录的 `build-profile.json5` 配置。

## 强制检查步骤

### 步骤 1：读取配置文件

读取项目根目录下的 `build-profile.json5` 文件。如果文件不存在，提示用户创建。

### 步骤 2：提取 SDK 版本

找到 `app.products[0]` 中的以下字段：

- `compatibleSdkVersion`（如有）
- `compileSdkVersion`（如有）

### 步骤 3：格式一致性强制规则

**核心原则**：`compileSdkVersion` 的格式必须与 `compatibleSdkVersion` **完全一致**（包括类型和值）。

| 检测到的 `compatibleSdkVersion` | `compileSdkVersion` 必须设置为   |
| :------------------------------ | :------------------------------- |
| 字符串（如 `"6.1.0(23)"`）      | **完全相同的字符串**（直接复制） |
| 数字（如 `23`）                 | **相同数字**，且确保 ≥ 20        |
| 不存在                          | 数字 `20`                        |

**❌ 禁止行为**：

- 将字符串格式改为数字格式（如 `"6.1.0(23)"` → `23`）
- 使用不同的字符串（如 `"6.1.0(23)"` → `"23"`）
- 跳过读取 `compatibleSdkVersion` 直接写默认值

### 步骤 4：检查必需配置

- `compileSdkVersion >= 20`（语义版本需数值部分 ≥ 20）
- **`buildOption.strictMode.useNormalizedOHMUrl` 必须为 `true`**

⚠️ **极其重要：配置位置不能错**
该配置必须写在 **`app` → `products` 数组 → 每一个 `product` 对象 → `buildOption` → `strictMode`** 中。
**禁止**写在 `app` 下直接与 `products` 平级的位置。

✅ **正确写法（请直接复制，不要改动缩进和层级）：**

```json5
{
  "app": {
    "products": [
      {
        "compileSdkVersion": 20,
        "compatibleSdkVersion": 20,
        "buildOption": {
          "strictMode": {
            "useNormalizedOHMUrl": true
          }
        }
      }
    ]
  }
}
```

❌ **常见错误写法（切勿使用）：**

```json5
// 错误1：buildOption 写在 app 下，products 外
{
  "app": {
    "buildOption": { "strictMode": { "useNormalizedOHMUrl": true } },
    "products": [ ... ]
  }
}

// 错误2：products 漏写了数组或对象层级
{
  "app": {
    "products": {
      "buildOption": { ... }
    }
  }
}
```

**验证方法：**
在 `build-profile.json5` 中，按 `Ctrl+F` 搜索 `useNormalizedOHMUrl`，确认其父级路径为：`app > products[0] > buildOption > strictMode`。

### 步骤 5：修改配置前必须获得用户确认

- 展示将要修改的具体内容
- 等待用户明确回复“同意/确认”后再执行写入

> 违反此规则会导致编译错误：`Schema validate failed, must be string` 或类型不匹配。

### 步骤 6：检查 AppStorage 导入可用性

当意图方案中需要使用 `AppStorage`（如 Router 架构适配方案或 Tabs 信号驱动）时，**必须在生成代码前验证当前 SDK 版本是否支持从 `@kit.ArkUI` 导入 `AppStorage`**。

**检查方法**：

1. 在项目的任意 `.ets` 文件中（如 `pages/Index.ets` 顶部）临时写入：

   ```typescript
   import { AppStorage } from '@kit.ArkUI';
   ```

2. 尝试编译（或检查 IDE 是否报红）。

3. 若编译报错提示 `"@kit.ArkUI" has no exported member named 'AppStorage'`，说明该 SDK 版本导出的是 `AppStorageV2`，则不应使用 `AppStorage`，而是改用**静态类持有**方案（详见 [architecture_checks.md](architecture_checks.md/) 中的“参数传递方式对比表”）。

**处理方案**：

- **若 `AppStorage` 可用**：继续使用 `AppStorage.setOrCreate` + `AppStorage.get` 方案。
- **若 `AppStorage` 不可用**：改用静态类持有数据，在意图执行器中将数据存入一个静态类的静态属性，目标页面在 `aboutToAppear` 中从静态类读取并清空。

**示例（静态类持有）**：

```typescript
// 定义一个静态数据持有类
export class IntentDataHolder {
  static categoryType: string = '';
  static data: Record<string, Object> = {};
}

// 意图执行器中写入
IntentDataHolder.categoryType = this.categoryType;

// 目标页面 aboutToAppear 中读取
const category = IntentDataHolder.categoryType;
if (category) {
  this.categoryType = category;
  IntentDataHolder.categoryType = ''; // 清空
}
```

> **注意**：静态类持有方案无需修改 `build-profile.json5`，且适用于所有 SDK 版本，是 Router 架构中 `loadContent` 加载页面的可靠备选方案。
