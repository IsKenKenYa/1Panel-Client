# ArkTS 严格模式核心规则

生成所有意图代码时，必须遵守以下 ArkTS 严格模式规则。

## 规则速查表

| 规则                                         | 错误示例                               | 正确要点                                             |
| -------------------------------------------- | -------------------------------------- | ---------------------------------------------------- |
| 1. 禁止 `any`/`unknown`                      | `const params: any = ...`              | 定义接口并声明类型                                   |
| 2. 禁止索引访问 `obj['prop']`                | `value = params['date']`               | 使用点号 `params.date`                               |
| 3. 导入所需模块                              | `router.getParams()` 未导入            | `import router from '@ohos.router'`                  |
| 4. 对象字面量必须有类型声明                  | `return { code: 0 }`                   | 定义接口并创建显式类型变量                           |
| 5. `throw` 只能抛 `Error` 对象               | `throw error`                          | `throw new Error(JSON.stringify(error))`             |
| 6. 安全获取路由参数                          | `const date = router.getParams().date` | `try-catch` + 接口 + 判空                            |
| 7. 类属性必须初始化                          | `songName: string;`                    | `songName: string = '';`                             |
| 8. 禁止解构赋值                              | `const { songName } = this.params`     | `const songName = this.params.songName`              |
| 9. 方法返回类型不能使用对象字面量            | `(): { valid: boolean } =>`            | 定义接口 `interface ValidResult`                     |
| 10. return 语句不能直接返回对象字面量        | `return { code: 0 }`                   | `const result: Result = { code: 0 }; return result;` |
| 11. Promise.resolve 中的对象字面量需显式类型 | `return Promise.resolve({ code: 0 })`  | 先声明变量再返回                                     |

## 详细规则与示例

### 1. 类属性初始化

```typescript
// ❌ 错误：没有初始化
export default class MyExecutor extends InsightIntentEntryExecutor<string> {
  songName: string;
}

// ✅ 正确：显式初始化
export default class MyExecutor extends InsightIntentEntryExecutor<string> {
  songName: string = '';
}
```

### 2. 禁止解构赋值

```typescript
// ❌ 错误
const { songName, artistName } = this.params;

// ✅ 正确
const songName: string = this.params.songName || '';
```

### 3. 对象字面量必须有接口声明

```typescript
// ❌ 错误
const result = { code: 0, result: '播放成功' };

// ✅ 正确
interface PlayResult {
  code: number;
  result: string;
}
const result: PlayResult = { code: 0, result: '播放成功' };
```

### 4. 方法返回类型禁止使用对象字面量

```typescript
// ❌ 错误
private validate(): { valid: boolean; message: string } {
  return { valid: true, message: '' };
}

// ✅ 正确
interface ValidationResult {
  valid: boolean;
  message: string;
}
private validate(): ValidationResult {
  const result: ValidationResult = { valid: true, message: '' };
  return result;
}
```

### 5. Promise.resolve 返回值

```typescript
// ❌ 错误
return Promise.resolve({
  code: 0,
  result: '成功'
});

// ✅ 正确
interface IntentResult {
  code: number;
  result: string;
}
const successResult: IntentResult = { code: 0, result: '成功' };
return Promise.resolve(successResult);
```

### 6. throw 语句只能抛 Error

```typescript
// ❌ 错误
catch (error) {
  throw error;
}

// ✅ 正确
catch (error) {
  throw new Error(`操作失败: ${JSON.stringify(error)}`);
}
```

### 7. 禁止索引访问

```typescript
// ❌ 错误
const value = params['date'];

// ✅ 正确
interface Params { date?: string; }
const value = (params as Params).date;
```

### 8. 安全获取路由参数

```typescript
// ✅ 正确
try {
  const params = router.getParams() as RouterParams;
  const date = params?.date ?? '';
} catch (error) {
  hilog.error(0x0000, LOG_TAG, '获取参数失败: %{public}s', JSON.stringify(error));
}
```

### 9. `@InsightIntentEntry` 特有规则

- `parameters` 必须为 `{ type: 'object', properties: {...} }`（即使无参数也必须有 `properties: {}`）
- 禁止使用 `integer` 类型，统一用 `number`
- 类属性必须与 `parameters` 属性名一致，提供默认值，禁止联合类型
- `executeMode` 必须是数组
- 返回值必须为 `Promise<insightIntent.IntentResult<T>>`，`result` 中必须包含 `resultDesc`

### 10. `@InsightIntentFunctionMethod` 特有规则

- 必须同时使用 `@InsightIntentFunction()` 装饰类
- 类装饰器括号不能省略：`@InsightIntentFunction()`
- 方法必须是 `static`
- 返回值必须为 `insightIntent.ExecuteResult`，且 `result` 中包含 `resultDesc`

### 11. `insightIntent.ExecuteResult.result` 的构建方式

`result` 字段类型为 `Record<string, Object>`，不能用接口定义后赋值（接口缺少索引签名）。

❌ **错误**：用接口定义 result 数据，类型不兼容

```typescript
interface MyResult { code: number; resultDesc: string; }
const data: MyResult = { code: 0, resultDesc: '成功' };
// data 不能赋值给 Record<string, Object>，因为 MyResult 没有索引签名
```

✅ **正确**：声明 `Record<string, Object>` 后逐属性赋值

```typescript
const resultData: Record<string, Object> = {};
resultData['code'] = 0;
resultData['resultDesc'] = '成功';
resultData['itemCount'] = 3;

const executeResult: insightIntent.ExecuteResult = {
  code: 0,
  result: resultData
};
return executeResult;
```

**说明**：此处 `resultData['code']` 的索引访问是允许的，因为 `Record<string, Object>` 本身就是索引签名类型，只能通过索引赋值添加属性。这与"禁止对普通接口/对象使用索引访问"不矛盾——后者针对的是已有明确属性定义的类型。

## 代码生成检查清单

- 是否使用了 `any` 或 `unknown` 类型？
- 是否使用了索引访问 `obj['prop']`？
- 是否导入了所有需要的模块？
- 是否为所有对象字面量定义了接口？
- `@InsightIntentEntry` 返回值是否直接声明为 `insightIntent.IntentResult<T>`？
- `result` 对象中是否包含 `resultDesc` 字段？
- 是否避免了使用 `as insightIntent.ExecuteResult` 类型转换？
- `executeMode` 是否是数组格式？
- `parameters` 是否使用了正确的 JSON Schema 格式？
- `@InsightIntentFunctionMethod` 是否同时使用了 `@InsightIntentFunction()`？
- `@InsightIntentPage` 是否直接在页面 struct 上使用？
- 装饰器顺序是否正确？
- **异步存储初始化检查**：存储工具类（RDB、Distributed KV Store、Preferences）是否在模块顶层使用 `getContext(this)`？（会导致冷启动 Context 为 undefined，应改为从全局动态获取）
- **异步存储 API 等待检查**：存储工具类的 `getKVStore` / `getRdbStore` / `getPreferences` 是否在回调或 `.then()` 中赋值，且外部方法未等待就绪就使用实例？必须改造为 `waitReady()` 模式，意图代码需 `await` 就绪信号。