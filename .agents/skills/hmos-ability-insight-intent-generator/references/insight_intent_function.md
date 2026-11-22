# 使用 @InsightIntentFunction 装饰器创建函数意图

> **⚠️ 开始之前必读**
>
> `@InsightIntentFunctionMethod` **不能单独使用**。您必须同时：
>
> - 用 `@InsightIntentFunction()` 装饰**类**
> - 用 `@InsightIntentFunctionMethod({...})` 装饰类中的**静态方法**
>
> 缺少任何一个都会导致意图无法注册或运行时错误。

---

> 📌 **公共规则**：本文档涉及的 ArkTS 严格模式规则、返回值规范、冷启动时序约束、导入规范等，统一收录于 **[common_rules.md](common_rules.md)**。生成代码前请先阅读对应章节。

---

使用 `@InsightIntentFunctionMethod` 装饰类中的静态函数，同时使用 `@InsightIntentFunction` 装饰器装饰静态函数所属的类，可以将对应的静态函数定义为意图，便于 AI 入口能够快速执行此函数。

## Quick Start

### 快速上手

```typescript
import { InsightIntentFunction, InsightIntentFunctionMethod } from '@kit.AbilityKit';

@InsightIntentFunction()
export class WeatherFunctions {
  @InsightIntentFunctionMethod({
    intentName: 'GetWeather',
    domain: 'LifeDomain',
    intentVersion: '1.0.1',
    displayName: '查询天气',
    displayDescription: '显示天气信息',
    icon: $r('app.media.app_icon'),
    llmDescription: '查询指定城市的天气信息',
    keywords: ['天气', '查询', 'weather'],
    parameters: {
      'type': 'object',
      'properties': {
        'location': {
          'type': 'string',
          'description': '城市名称，如：杭州',
          'minLength': 1
        }
      },
      'required': ['location']
    }
  })
  static getWeather(location: string): string {
    console.info(`location: ${location}`);
    return `${location}当前气温24℃`;
  }
}
```

### 完整流程

1. **（可选）创建工具类**：定义包含静态方法的类
2. **装饰类**：使用 `@InsightIntentFunction()` 装饰类
3. **装饰静态方法**：使用 `@InsightIntentFunctionMethod()` 装饰静态方法
4. **导出类**：确保类使用 `export` 导出
5. **（可选）注册意图**：在 `insight_intent.json` 中添加文件路径

## 核心规则

### 适用场景

- ✅ 纯函数计算，无需 UI 交互
- ✅ 数据查询、格式转换等工具类功能
- ✅ 快速执行的轻量级操作
- ✅ 无需拉起 Ability 或页面的场景
- ❌ 不适用于需要 UI 交互的场景（使用 `@InsightIntentEntry` 或 `@InsightIntentPage`）
- ❌ 不适用于需要访问 Ability 上下文的场景
- ❌ **不适用于依赖 UI 组件渲染状态或页面生命周期初始化才能获取的运行时数据**

### 代码输出要求

- ✅ **必须**同时使用 `@InsightIntentFunction` 和 `@InsightIntentFunctionMethod` 装饰器
- ✅ 类**必须**使用 `export` 导出（不需要 `default`）
- ✅ 方法**必须**是 `static` 静态方法
- ✅ 函数参数名称、参数类型**必须**与意图定义的参数名称、参数类型保持一致
- ✅ 新增文件时，在 `insight_intent.json` 的 `insightIntentsSrcEntry` 数组中添加文件路径
- ❌ 不允许使用实例方法
- ❌ 不允许在方法中访问 `this` 或实例属性

### 装饰器组合规则

```typescript
// ✅ 正确：装饰器组合使用
@InsightIntentFunction()
export class MyFunctions {
  @InsightIntentFunctionMethod({...})
  static myMethod(param: string): string {
    return `result: ${param}`;
  }
}

// ❌ 错误：缺少 @InsightIntentFunction
export class MyFunctions {
  @InsightIntentFunctionMethod({...})
  static myMethod(param: string): string { ... }
}

// ❌ 错误：使用实例方法（缺少 static）
@InsightIntentFunction()
export class MyFunctions {
  @InsightIntentFunctionMethod({...})
  myMethod(param: string): string { ... }
}
```

### ⚠️ 禁止使用 InsightIntentContext 作为静态方法参数

`@InsightIntentFunctionMethod` 的静态方法**只能**接收与 `parameters` 定义对应的基本类型参数（`string`、`number`、`boolean`）。**不允许**在参数列表中添加 `InsightIntentContext` 或 `abilityContext`。

```typescript
// ❌ 错误：InsightIntentContext 不属于 @InsightIntentFunctionMethod 的参数
@InsightIntentFunctionMethod({...})
static queryByDate(context: InsightIntentContext, date: string): Promise<string> {
  const abilityContext = context.abilityContext;  // ❌ 编译错误或运行时 undefined
}

// ✅ 正确：参数仅匹配 parameters 定义
@InsightIntentFunctionMethod({
  parameters: { 'type': 'object', 'properties': { 'date': { 'type': 'string' } }, 'required': ['date'] }
})
static queryByDate(date: string): insightIntent.ExecuteResult {
  // 数据库访问依赖 EntryAbility.onCreate 中已完成初始化
}
```

------

## 快速参考

### @InsightIntentFunctionMethod 必填字段

| 字段             | 类型     | 说明                           | 示例                 |
| :--------------- | :------- | :----------------------------- | :------------------- |
| `intentName`     | string   | 英文 PascalCase，动词-名词结构 | `"GetWeather"`       |
| `domain`         | string   | 域标识符                       | `"LifeDomain"`       |
| `intentVersion`  | string   | 语义化版本，三位数格式         | `"1.0.1"`            |
| `displayName`    | string   | 中文显示名称                   | `"查询天气"`         |
| `llmDescription` | string   | LLM 理解描述                   | `"查询指定城市天气"` |
| `keywords`       | string[] | 搜索关键词                     | `["天气", "查询"]`   |

### @InsightIntentFunctionMethod 可选字段

| 字段                 | 类型                   | 说明               |
| :------------------- | :--------------------- | :----------------- |
| `displayDescription` | string                 | 详细描述           |
| `schema`             | string                 | 标准意图 schema    |
| `icon`               | ResourceStr            | 图标资源           |
| `parameters`         | Record<string, Object> | 参数 JSON Schema   |
| `result`             | Record<string, Object> | 返回值 JSON Schema |

------

## 示例详解

### 基础示例（无参数）

```typescript
import { InsightIntentFunction, InsightIntentFunctionMethod } from '@kit.AbilityKit';

@InsightIntentFunction()
export class TimeFunctions {
  @InsightIntentFunctionMethod({
    intentName: 'GetCurrentTime',
    domain: 'ToolsDomain',
    intentVersion: '1.0.0',
    displayName: '获取当前时间',
    llmDescription: '获取当前的日期和时间',
    keywords: ['时间', '日期', 'time']
  })
  static getCurrentTime(): string {
    return new Date().toLocaleString('zh-CN');
  }
}
```

### 带参数示例

```typescript
import { InsightIntentFunction, InsightIntentFunctionMethod } from '@kit.AbilityKit';

@InsightIntentFunction()
export class CalculatorFunctions {
  @InsightIntentFunctionMethod({
    intentName: 'Calculate',
    domain: 'ToolsDomain',
    intentVersion: '1.0.1',
    displayName: '计算',
    displayDescription: '执行数学计算',
    llmDescription: '执行加减乘除运算',
    keywords: ['计算', '数学', 'calculator'],
    parameters: {
      'type': 'object',
      'properties': {
        'a': { 'type': 'number', 'description': '第一个数字' },
        'b': { 'type': 'number', 'description': '第二个数字' },
        'operator': { 'type': 'string', 'description': '运算符', 'enum': ['+', '-', '*', '/'] }
      },
      'required': ['a', 'b', 'operator']
    }
  })
  static calculate(a: number, b: number, operator: string): string {
    let result: number = 0;
    switch (operator) {
      case '+': result = a + b; break;
      case '-': result = a - b; break;
      case '*': result = a * b; break;
      case '/': result = b !== 0 ? a / b : NaN; break;
    }
    return `${a} ${operator} ${b} = ${result}`;
  }
}
```

### 异步数据库查询示例

当意图需要查询数据库时，必须使用 `async/await`。

**⚠️ 关键约束**：

- 方法声明为 `async`，返回 `Promise<insightIntent.ExecuteResult>`
- `result` 必须为 `Record<string, Object>` 类型，用索引赋值构建
- **数据库初始化守卫**：必须包含 DB 就绪等待机制（`await dbUtils.ready()` 或轮询 `isInitSuccess()`）

```typescript
import { InsightIntentFunction, InsightIntentFunctionMethod } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface ItemInfo { id: number; name: string; }

@InsightIntentFunction()
export class ItemFunctions {
  private static readonly LOG_TAG: string = 'ItemFunctions';

  @InsightIntentFunctionMethod({
    intentName: 'GetActiveItems',
    domain: 'AppDomain',
    intentVersion: '1.0.1',
    displayName: '获取已添加项',
    llmDescription: '查询已添加的项。当用户说"已添加的"、"我的XX"等时调用。',
    keywords: ['已添加', '我的', 'GetActiveItems'],
    result: {
      'type': 'object',
      'properties': {
        'code': { 'type': 'number' },
        'resultDesc': { 'type': 'string' },
        'itemCount': { 'type': 'number' },
        'items': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'id': { 'type': 'number' },
              'name': { 'type': 'string' }
            }
          }
        }
      }
    }
  })
  static async getActiveItems(): Promise<insightIntent.ExecuteResult> {
    // ① 冷启动时序保护：确保 DB 已就绪
    try {
      if (typeof RdbUtils.ready === 'function') {
        await RdbUtils.ready();
      } else {
        // 降级：轮询 isInitSuccess()
        if (!RdbUtils.isInitSuccess?.()) {
          RdbUtils.initDB?.();
          const maxWait: number = 3000;
          const interval: number = 100;
          let waited: number = 0;
          while (!RdbUtils.isInitSuccess?.() && waited < maxWait) {
            await new Promise<void>((resolve) => setTimeout(resolve, interval));
            waited += interval;
          }
          if (!RdbUtils.isInitSuccess?.()) {
            const errData: Record<string, Object> = {};
            errData['code'] = -2;
            errData['resultDesc'] = '数据库初始化超时';
            errData['itemCount'] = 0;
            errData['items'] = [];
            return { code: -2, result: errData };
          }
        }
      }
    } catch (initError) {
      const errData: Record<string, Object> = {};
      errData['code'] = -2;
      errData['resultDesc'] = '数据库就绪检查失败';
      errData['itemCount'] = 0;
      errData['items'] = [];
      return { code: -2, result: errData };
    }

    // ② 执行业务查询
    let itemList: ItemInfo[] = [];
    try {
      itemList = await queryItemsFromDb();
    } catch (error) {
      const errData: Record<string, Object> = {};
      errData['code'] = -1;
      errData['resultDesc'] = '查询失败';
      errData['itemCount'] = 0;
      errData['items'] = [];
      return { code: -1, result: errData };
    }

    // ③ 构建返回结果（Record<string, Object> 索引赋值）
    const items: Record<string, Object>[] = [];
    for (let i = 0; i < itemList.length; i++) {
      const item: Record<string, Object> = {};
      item['id'] = itemList[i].id;
      item['name'] = itemList[i].name;
      items.push(item);
    }

    const resultData: Record<string, Object> = {};
    resultData['code'] = 0;
    resultData['resultDesc'] = `共有${items.length}项`;
    resultData['itemCount'] = items.length;
    resultData['items'] = items;

    return { code: 0, result: resultData };
  }
}
```

> **更多示例**：KV Store 查询、工具类改造模板等，请参阅 [code_exploration.md](code_exploration.md) 第 3 节。

------

## 冷启动窗口生命周期（func 类型意图）

`@InsightIntentFunctionMethod` 意图以 `background` 模式执行时，Ability 冷启动**不经过 `onWindowStageCreate`**，窗口未创建。之后用户手动启动应用时，`singleton` Ability 走 `onNewWant` 但窗口仍然不存在，导致白屏。

**解决方案**：在 `EntryAbility.onNewWant` / `onForeground` 中检查窗口是否已创建，未创建则手动恢复窗口内容。

详细检查步骤和模板请参考 [code_exploration.md](code_exploration.md) 第 3 节和第 5 节。

------

## 冷启动 EntryAbility 改造模板（强制配套）

**使用 `@InsightIntentFunctionMethod` 时，必须同步改造 `EntryAbility.ets`**，确保冷启动后手动打开应用不会白屏/闪退。

### 必须执行的 3 项改造

| 改造项                                   | 正确做法                                                     | 错误示例                                   |
| :--------------------------------------- | :----------------------------------------------------------- | :----------------------------------------- |
| 1. 关键资源初始化迁移到 `onCreate`       | 播放器 `setContext`、数据库初始化等，**必须在 `onCreate` 中调用** | 仅在 `onWindowStageCreate` 中初始化        |
| 2. `onForeground` / `onNewWant` 窗口兜底 | 用 `window.getLastWindow(this.context)` 恢复页面。**禁止 `createWindow`** | 无窗口恢复逻辑，或使用 `createWindow`      |
| 3. `onNewWant` 路由安全                  | 窗口未就绪时跳过 `router.pushUrl`                            | 在 `onNewWant` 中直接调用 `router.pushUrl` |

### 完整改造模板

```typescript
// EntryAbility.ets
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import window from '@ohos.window';

const LOG_TAG = 'EntryAbility';
const MAIN_PAGE = 'pages/Index';

export default class EntryAbility extends UIAbility {
  private windowContentReady: boolean = false;
  private pendingIntent?: Want;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, LOG_TAG, 'onCreate');
    // ✅ 改造1：关键资源初始化放在 onCreate
    this.initCriticalResources();
    this.handleInsightIntent(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowContentReady = true;
    windowStage.loadContent(MAIN_PAGE, (err) => {
      if (!err.code && this.pendingIntent) {
        this.handleNavigation(this.pendingIntent);
        this.pendingIntent = undefined;
      }
    });
  }

  onWindowStageDestroy(): void {
    this.windowContentReady = false;
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, LOG_TAG, 'onNewWant');
    this.handleInsightIntent(want);

    if (!this.windowContentReady) {
      this.pendingIntent = want;
      this.ensureWindowContent();
    } else {
      this.handleNavigation(want);
    }
  }

  onForeground(): void {
    if (!this.windowContentReady) {
      this.ensureWindowContent();
    }
  }

  // ✅ 改造2：使用 getLastWindow 恢复窗口
  private ensureWindowContent(): void {
    if (this.windowContentReady) return;

    window.getLastWindow(this.context)
      .then((win: window.Window) => {
        this.initWindowContent(win);
      })
      .catch((err: Error) => {
        hilog.error(0x0000, LOG_TAG, 'getLastWindow failed: %{public}s', err.message);
      });
  }

  private initWindowContent(win: window.Window): void {
    win.setUIContent(MAIN_PAGE, (err) => {
      if (err.code) {
        hilog.error(0x0000, LOG_TAG, 'setUIContent failed: %{public}s', err.message);
        return;
      }
      this.windowContentReady = true;
      win.showWindow().catch((e: Error) => {
        hilog.error(0x0000, LOG_TAG, 'showWindow failed: %{public}s', e.message);
      });
      if (this.pendingIntent) {
        this.handleNavigation(this.pendingIntent);
        this.pendingIntent = undefined;
      }
    });
  }

  private handleInsightIntent(want: Want): void {
    // 解析意图参数，设置路由目标（不执行跳转）
  }

  private handleNavigation(want: Want): void {
    // 窗口已就绪，执行页面跳转
  }

  private initCriticalResources(): void {
    // 播放器 setContext、数据库初始化等（幂等）
  }
}
```

> 详细模板说明和 Window API 版本差异请参阅 [code_exploration.md](code_exploration.md) 第 3-5 节。

------

## 与其他装饰器的区别

| 特性               | @InsightIntentFunctionMethod | @InsightIntentEntry | @InsightIntentPage | @InsightIntentLink    |
| :----------------- | :--------------------------- | :------------------ | :----------------- | :-------------------- |
| **用途**           | 将静态函数定义为意图         | 创建复杂意图执行器  | 将页面定义为意图   | 将 URI 链接定义为意图 |
| **装饰对象**       | 静态方法                     | 类（继承 Executor） | struct 页面        | 类                    |
| **基类要求**       | 无                           | 必须继承            | 无                 | 无                    |
| **UI 交互**        | 不支持                       | 支持                | 支持               | 支持（跳转）          |
| **Ability 上下文** | 无法访问                     | 可以访问            | 可以访问           | 通过 URI              |
| **导出方式**       | `export`                     | `export default`    | struct 定义        | `export`              |

------

## 装饰器组合图示

```typescript
@InsightIntentFunction()          ← 装饰类
export class FunctionClass {
  @InsightIntentFunctionMethod({  ← 装饰静态方法
    intentName: 'xxx',
    domain: 'xxx',
    ...
  })
  static methodName(param: Type): ReturnType {
    // 函数实现
  }

  @InsightIntentFunctionMethod({  ← 可装饰多个静态方法
    intentName: 'yyy',
    ...
  })
  static anotherMethod(): string {
    // 另一个意图
  }
}
```

------

## 常见问题

### Q1: 为什么必须使用静态方法？

静态方法可以在不实例化类的情况下直接调用，AI 入口无需了解类的实例化方式即可执行意图。

### Q2: 如何处理异步操作？

可以使用 `async/await`，但返回值需要是 `Promise<insightIntent.ExecuteResult>`：

```typescript
@InsightIntentFunctionMethod({...})
static async fetchData(url: string): Promise<insightIntent.ExecuteResult> {
  const response = await fetch(url);
  const data = await response.text();
  const resultData: Record<string, Object> = {};
  resultData['resultDesc'] = data;
  return { code: 0, result: resultData };
}
```

### Q3: 可以在一个类中定义多少个意图？

没有限制，一个类中可以定义多个被 `@InsightIntentFunctionMethod` 装饰的静态方法。

### Q4: 如何注册意图？

意图文件需要添加到 `insight_intent.json` 配置中。详细配置请参阅 [write_config_file.md](write_config_file.md)。

```json
{
  "insightIntentsSrcEntry": [
    { "srcEntry": "./ets/insightintents/WeatherFunctions.ets" }
  ]
}
```

### Q5: 参数类型必须与 parameters 定义完全匹配吗？

是的，函数的参数名称和类型必须与 `parameters` 中定义的名称和类型完全一致，否则会导致意图执行失败。

### Q6: 标准意图和自定义意图的区别？

- **标准意图**：配置 `schema` 和 `intentVersion` 字段，系统自动填充定义
- **自定义意图**：需要配置 `llmDescription`、`keywords`、`parameters` 等字段

------

## 相关资源

- [InsightIntentFunctionMethod API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-insightintentdecorator#insightintentfunctionmethod)
- [标准意图接入规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-access-specifications)
- [各垂域意图 Schema](https://developer.huawei.com/consumer/cn/doc/service/intents-schema-0000001901962713)
- [common_rules.md](common_rules.md) - 公共规则
- [code_exploration.md](code_exploration.md) - 冷启动模板
