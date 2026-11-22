# 使用 @InsightIntentForm 装饰器创建卡片意图

使用该装饰器装饰 FormExtensionAbility 并配置 FormExtensionAbility 绑定的卡片名称，便于 AI 入口通过意图添加卡片。

---

## Quick Start

### 快速上手

```typescript
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want, InsightIntentForm } from '@kit.AbilityKit';

@InsightIntentForm({
  intentName: 'PlayMusic',
  domain: 'MusicDomain',
  intentVersion: '1.0.1',
  displayName: '播放歌曲',
  displayDescription: '播放音乐意图',
  llmDescription: '添加音乐播放卡片到桌面',
  keywords: ['音乐播放', '卡片', 'widget'],
  formName: 'widget'
})
export default class MusicFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    let formData = {
      title: '音乐播放',
      songName: '未播放'
    };
    return formBindingData.createFormBindingData(formData);
  }
}
```

### 完整流程（必须全部执行）

1. **创建卡片配置**：在 `form_config.json` 中定义卡片
2. **创建 FormExtensionAbility**：继承 `FormExtensionAbility` 类
3. **添加装饰器**：使用 `@InsightIntentForm` 装饰器
4. **创建卡片 UI 组件**：在 `widget/pages/` 下创建 `.ets` 文件，使用 `@LocalStorageProp` 接收数据
5. **添加 DataProvider + FormRegistry**：跨上下文数据共享（如需）
6. **实现生命周期**：实现 `onAddForm`（同步 + 轮询）、`onUpdateForm`、`onRemoveForm`
7. **修改主应用**：在数据变化点写文件 + 推送
8. **注册意图**：在 `insight_intent.json` 中添加文件路径

------

## 核心规则

### 适用场景

- ✅ 需要将应用卡片暴露给 AI 入口
- ✅ 允许用户通过语音或 AI 助手快速添加卡片到桌面
- ✅ 卡片需要支持意图参数定制（如播放指定歌曲的卡片）
- ❌ 不适用于非卡片相关的意图定义

### 代码输出要求

- ✅ 必须**继承** `FormExtensionAbility` 类
- ✅ 类必须使用 `export default` 导出
- ✅ `formName` 必须与 `form_config.json` 中定义的卡片名称一致
- ✅ 实现 `onAddForm` 方法返回 `FormBindingData`（同步）
- ✅ **必须同时提供对应的卡片 UI 组件**（`Widget.ets`），使用 `@LocalStorageProp` 接收数据
- ✅ 新增文件时，在 `insight_intent.json` 的 `insightIntentsSrcEntry` 数组中添加文件路径
- ❌ 不允许装饰非 FormExtensionAbility 的类

### ⚠️ onAddForm 同步约束（编译强检查）

`FormExtensionAbility` 基类签名 **`onAddForm(want: Want): FormBindingData`**（同步，非 async）。
子类不可改为 `async` 或返回 `Promise<FormBindingData>`。编译器报错：

> Property 'onAddForm' is not assignable to the same property in base type.
> Type '(want: Want) => Promise<FormBindingData>' is not assignable to type '(want: Want) => FormBindingData'.

**影响**：所有数据读取必须在 `onAddForm` 返回前就绪。不能 `await Preferences.getPreferences()` 等异步操作。

### 🧩 卡片 UI 数据绑定机制（重要）

`formBindingData.createFormBindingData(formData)` 创建的数据会通过 **LocalStorage** 机制注入到卡片 UI 组件。卡片组件必须使用 `@LocalStorageProp` 从 LocalStorage 中读取对应字段，**不能使用 `@State` 或 `@Local`（V2 专属）**。

| 卡片 UI 组件要求 | 说明                                                         |
| :--------------- | :----------------------------------------------------------- |
| 装饰器           | `@LocalStorageProp('字段名') 变量: 类型 = 默认值`            |
| Entry 声明       | 必须使用 `let storage = new LocalStorage();` + `@Entry(storage)` |
| 组件结构         | `@Entry(storage) @Component struct XxxWidget { ... }`        |

> **V1 与 V2 差异**：`@Local` 是 `@ComponentV2` 的专属装饰器，本项目（V1）必须使用 `@LocalStorageProp`。

### 跨上下文数据共享（⛔ 常见误区）

| 方案                             | UIAbility ↔ FormExtensionAbility 是否可用 | 原因                                        |
| :------------------------------- | :---------------------------------------- | :------------------------------------------ |
| `AppStorage`                     | ❌                                         | 绑定 UIAbility 上下文，FormExtension 无权限 |
| 模块级静态变量（`SharedAngles`） | ❌                                         | 两者有独立的模块加载作用域                  |
| `@ohos.data.preferences`         | ⚠️                                         | 可能因 context 不同导致存储路径不一致       |
| **`@ohos.file.fs` 同步文件读写** | ✅                                         | **同一进程共享文件系统沙箱**                |

### 标准实现模板（必须严格遵循）

每次生成 `@InsightIntentForm` 代码必须包含以下组件：

**① DataProvider.ets** — 跨上下文同步数据共享层：

```typescript
import fs from '@ohos.file.fs';
import { Context } from '@kit.AbilityKit';

interface XxxData {
  // 定义你的数据结构
}

/**
 * 同步写入数据到文件（供主应用和卡片共享）
 * @param context UIAbility 或 FormExtension 的 context，用于获取 filesDir
 * @param data 要保存的数据
 */
export function saveXxxData(context: Context, data: XxxData): void {
  const path: string = context.filesDir + '/xxx_data.json';  // ⚠️ 必须使用 filesDir
  const file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
  fs.writeSync(file.fd, JSON.stringify(data));
  fs.closeSync(file);
}

/**
 * 同步读取数据（若无文件则返回默认值）
 */
export function loadXxxData(context: Context): XxxData {
  const path: string = context.filesDir + '/xxx_data.json';
  try {
    const content: string = fs.readTextSync(path);
    return JSON.parse(content) as XxxData;
  } catch {
    return { /* 默认值 */ };
  }
}
```

> **路径规范**：必须使用 `context.filesDir`（或 `getApplicationContext().filesDir`），不能使用 `cacheDir`。`filesDir` 在 UIAbility 和 FormExtension 之间路径一致，保证数据互通。

**② FormRegistry.ets** — formId 注册表（Preferences 存储）：

```typescript
import preferences from '@ohos.data.preferences';
import { Context } from '@kit.AbilityKit';

export default class FormRegistry {
  private static readonly PREF_NAME: string = 'form_registry';
  private static readonly KEY_FORM_IDS: string = 'form_ids';

  static async register(context: Context, formId: string): Promise<void> {
    const pref = await preferences.getPreferences(context, FormRegistry.PREF_NAME);
    const ids = await this.getAll(context);
    if (!ids.includes(formId)) {
      ids.push(formId);
      await pref.put(FormRegistry.KEY_FORM_IDS, JSON.stringify(ids));
      await pref.flush();
    }
  }

  static async unregister(context: Context, formId: string): Promise<void> {
    const pref = await preferences.getPreferences(context, FormRegistry.PREF_NAME);
    let ids = await this.getAll(context);
    ids = ids.filter(id => id !== formId);
    await pref.put(FormRegistry.KEY_FORM_IDS, JSON.stringify(ids));
    await pref.flush();
  }

  static async getAll(context: Context): Promise<string[]> {
    const pref = await preferences.getPreferences(context, FormRegistry.PREF_NAME);
    const json = await pref.get(FormRegistry.KEY_FORM_IDS, '[]') as string;
    return JSON.parse(json) as string[];
  }
}
```

**③ FormAbility** — 核心逻辑（含轮询兜底）：

```typescript
import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { Want, InsightIntentForm, Context } from '@kit.AbilityKit';
import { loadXxxData, saveXxxData } from '../utils/DataProvider';
import FormRegistry from '../utils/FormRegistry';

@InsightIntentForm({
  intentName: 'AddXxxWidget',
  domain: 'YourDomain',
  intentVersion: '1.0.1',
  displayName: 'xxx卡片',
  llmDescription: '添加xxx卡片到桌面',
  keywords: ['xxx', '卡片'],
  formName: 'xxxWidget'
})
export default class XxxFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;

    // 1. 注册 formId（异步，不阻塞返回）
    if (formId) {
      FormRegistry.register(this.context, formId).catch(e => {
        console.error('register formId failed', e);
      });
    }

    // 2. 同步读取当前数据
    const data = loadXxxData(this.context);

    // 3. 构造卡片初始数据（可能为默认值）
    const formData: Record<string, Object> = {
      fieldA: data.fieldA,
      fieldB: data.fieldB,
    };

    // 4. 如果数据不完整，启动轮询兜底（数据可能稍后由主应用写入）
    if (formId && (data.fieldA === undefined || data.fieldA === '')) {
      this.startPolling(this.context, formId);
    }

    return formBindingData.createFormBindingData(formData);
  }

  private startPolling(context: Context, formId: string): void {
    let attempts = 0;
    const maxAttempts = 15;   // 15 * 200ms = 3s
    const interval = 200;

    const poll = () => {
      attempts++;
      const data = loadXxxData(context);
      if (data.fieldA && data.fieldA !== '') {
        // 数据已就绪，更新卡片
        const updateData: Record<string, Object> = {
          fieldA: data.fieldA,
          fieldB: data.fieldB,
        };
        formProvider.updateForm(formId, formBindingData.createFormBindingData(updateData))
          .catch(e => console.error('updateForm failed', e));
        return;
      }
      if (attempts < maxAttempts) {
        setTimeout(poll, interval);
      }
    };
    poll();
  }

  onRemoveForm(formId: string): void {
    FormRegistry.unregister(this.context, formId).catch(e => {
      console.error('unregister formId failed', e);
    });
  }
}
```

**④ Widget UI 组件** — 卡片界面（必须提供）：

```typescript
// 文件路径：entry/src/main/ets/widget/pages/XxxWidget.ets
import { LocalStorage } from '@kit.ArkUI';

// ⚠️ 必须创建 LocalStorage 实例并传入 @Entry
let storage = new LocalStorage();

@Entry(storage)
@Component
struct XxxWidget {
  // 使用 @LocalStorageProp 绑定从 formBindingData 传递来的数据
  @LocalStorageProp('fieldA') fieldA: string = '默认值A';
  @LocalStorageProp('fieldB') fieldB: string = '默认值B';

  build() {
    Column() {
      Text(this.fieldA)
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
      Text(this.fieldB)
        .fontSize(14)
        .fontColor('#666');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}
```

> **关键点**：
>
> - 必须使用 `let storage = new LocalStorage();` 并在 `@Entry(storage)` 中传入。
> - 数据字段名必须与 `formBindingData.createFormBindingData(formData)` 中的键完全一致。
> - 提供合理的默认值，避免卡片显示空白。

**⑤ form_config.json** — 卡片配置：

```json
{
  "forms": [
    {
      "name": "xxxWidget",
      "displayName": "xxx卡片",
      "description": "xxx卡片描述",
      "src": "./ets/widget/pages/XxxWidget.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "colorMode": "auto",
      "isDefault": true,
      "updateEnabled": true,
      "scheduledUpdateTime": "10:30",
      "updateDuration": 1,
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2", "4*2"]
    }
  ]
}
```

**⑥ module.json5** — 扩展能力注册：

```json5
{
  "module": {
    "extensionAbilities": [
      {
        "name": "XxxFormAbility",
        "srcEntry": "./ets/formability/XxxFormAbility.ets",
        "type": "form",
        "label": "$string:form_label",
        "description": "$string:form_desc",
        "metadata": [
          {
            "name": "ohos.extension.form",
            "resource": "$profile:form_config"
          }
        ]
      }
    ]
  }
}
```

**⑦ insight_intent.json** — 意图注册：

```json
{
  "insightIntentsSrcEntry": [
    { "srcEntry": "./ets/formability/XxxFormAbility.ets" }
  ]
}
```

### 主应用侧修改（强制）

当主应用数据发生变化时，必须同步更新文件并推送给所有卡片：

```typescript
import { saveXxxData, loadXxxData } from '../utils/DataProvider';
import FormRegistry from '../utils/FormRegistry';
import { formProvider, formBindingData } from '@kit.FormKit';

// 在数据变更处（例如保存按钮、网络数据返回后）：
function onDataChanged(newData: XxxData, context: Context) {
  // 1. 写入文件
  saveXxxData(context, newData);

  // 2. 获取所有卡片 ID
  FormRegistry.getAll(context).then((formIds: string[]) => {
    // 3. 构造卡片更新数据
    const updateData: Record<string, Object> = {
      fieldA: newData.fieldA,
      fieldB: newData.fieldB,
    };
    const formData = formBindingData.createFormBindingData(updateData);
    // 4. 逐卡片更新
    for (let id of formIds) {
      formProvider.updateForm(id, formData).catch(e => {
        console.error(`updateForm ${id} failed`, e);
      });
    }
  }).catch(e => {
    console.error('getAll formIds failed', e);
  });
}
```

------

## 示例详解

### 基础示例（简单卡片）——含 Widget UI

**FormAbility**：

```typescript
@InsightIntentForm({
  intentName: 'AddClockWidget',
  domain: 'ToolsDomain',
  intentVersion: '1.0.1',
  displayName: '添加时钟卡片',
  llmDescription: '添加一个时钟显示卡片到桌面',
  keywords: ['时钟', '卡片', 'clock', 'widget'],
  formName: 'clockWidget'
})
export default class ClockFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    let formData = {
      time: new Date().toLocaleTimeString()
    };
    return formBindingData.createFormBindingData(formData);
  }
}
```

**Widget UI（clockWidget.ets）**：

```typescript
let storage = new LocalStorage();

@Entry(storage)
@Component
struct ClockWidget {
  @LocalStorageProp('time') time: string = '--:--:--';

  build() {
    Column() {
      Text(this.time)
        .fontSize(24)
        .fontWeight(FontWeight.Bold);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}
```

### 带参数的卡片示例（音乐播放）

**FormAbility**：

```typescript
@InsightIntentForm({
  intentName: 'PlayMusic',
  domain: 'MusicDomain',
  intentVersion: '1.0.1',
  displayName: '播放歌曲',
  llmDescription: '添加指定歌曲的播放卡片',
  keywords: ['音乐播放', '播放歌曲', 'PlayMusic'],
  formName: 'musicWidget',
  parameters: {
    'type': 'object',
    'properties': {
      'songName': { 'type': 'string', 'description': '歌曲名称', 'minLength': 1 },
      'artist': { 'type': 'string', 'description': '歌手名称' }
    },
    'required': ['songName']
  }
})
export default class MusicFormAbility extends FormExtensionAbility {
  songName: string = '';
  artist: string = '';

  onAddForm(want: Want) {
    if (want.parameters?.songName) {
      this.songName = want.parameters.songName as string;
      this.artist = want.parameters.artist as string || '';
    }
    let formData = {
      songName: this.songName || '未知歌曲',
      artist: this.artist || '未知歌手',
      isPlaying: true
    };
    return formBindingData.createFormBindingData(formData);
  }
}
```

**Widget UI（musicWidget.ets）**：

```typescript
let storage = new LocalStorage();

@Entry(storage)
@Component
struct MusicWidget {
  @LocalStorageProp('songName') songName: string = '未播放';
  @LocalStorageProp('artist') artist: string = '';
  @LocalStorageProp('isPlaying') isPlaying: boolean = false;

  build() {
    Column() {
      Text(this.songName)
        .fontSize(18)
        .fontWeight(FontWeight.Medium);
      Text(this.artist)
        .fontSize(14)
        .fontColor('#888');
      Image(this.isPlaying ? $r('app.media.playing') : $r('app.media.paused'))
        .width(30)
        .height(30)
        .margin({ top: 8 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}
```

### 天气卡片示例（含 DataProvider）

**DataProvider.ets**：

```typescript
import fs from '@ohos.file.fs';
import { Context } from '@kit.AbilityKit';

interface WeatherData {
  city: string;
  temperature: string;
  condition: string;
}

export function saveWeather(context: Context, data: WeatherData): void {
  const path = context.filesDir + '/weather_data.json';
  const file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
  fs.writeSync(file.fd, JSON.stringify(data));
  fs.closeSync(file);
}

export function loadWeather(context: Context): WeatherData {
  const path = context.filesDir + '/weather_data.json';
  try {
    const content = fs.readTextSync(path);
    return JSON.parse(content) as WeatherData;
  } catch {
    return { city: '未知', temperature: '--', condition: '--' };
  }
}
```

**FormAbility**：

```typescript
@InsightIntentForm({
  intentName: 'AddWeatherWidget',
  domain: 'LifeDomain',
  intentVersion: '1.0.1',
  displayName: '天气卡片',
  llmDescription: '添加天气显示卡片到桌面',
  keywords: ['天气', '卡片'],
  formName: 'weatherWidget'
})
export default class WeatherFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    if (formId) FormRegistry.register(this.context, formId);

    const data = loadWeather(this.context);
    const formData = {
      city: data.city,
      temperature: data.temperature,
      condition: data.condition
    };
    // 若数据为空，启动轮询
    if (formId && !data.city) {
      this.startPolling(this.context, formId);
    }
    return formBindingData.createFormBindingData(formData);
  }

  private startPolling(context: Context, formId: string) { /* 同模板 */ }
}
```

**Widget UI（weatherWidget.ets）**：

```typescript
let storage = new LocalStorage();

@Entry(storage)
@Component
struct WeatherWidget {
  @LocalStorageProp('city') city: string = '--';
  @LocalStorageProp('temperature') temperature: string = '--';
  @LocalStorageProp('condition') condition: string = '--';

  build() {
    Column() {
      Text(this.city)
        .fontSize(20)
        .fontWeight(FontWeight.Bold);
      Row() {
        Text(this.temperature)
          .fontSize(28)
          .fontWeight(FontWeight.Bold);
        Text('°C')
          .fontSize(16)
          .fontColor('#999');
      }
      Text(this.condition)
        .fontSize(14)
        .fontColor('#666');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}
```

### 多卡片场景示例（多个 FormAbility）

若一个应用有多个卡片，每个卡片对应独立的 FormExtensionAbility 类，每个类使用 `@InsightIntentForm` 装饰不同的 `formName`。每个卡片需要有各自的 Widget UI 文件。

------

## @InsightIntentForm 文件清单

| #    | 文件路径（相对于 entry/src/main）            | 说明                                |
| :--- | :------------------------------------------- | :---------------------------------- |
| 1    | `ets/formability/XxxFormAbility.ets`         | FormExtensionAbility 实现           |
| 2    | `ets/utils/DataProvider.ets`                 | 同步文件读写工具（可选，按需）      |
| 3    | `ets/utils/FormRegistry.ets`                 | formId 注册表（可选）               |
| 4    | `resources/base/profile/form_config.json`    | 卡片配置文件                        |
| 5    | `module.json5`                               | extensionAbilities 注册             |
| 6    | `resources/base/profile/insight_intent.json` | 意图注册（新增 FormAbility 时需要） |
| 7    | `ets/widget/pages/XxxWidget.ets`             | **卡片 UI 组件（必须）**            |
| 8    | 主应用数据变化处 .ets 文件                   | 添加推送逻辑（强制）                |

**注意**：如果项目中已存在 FormExtensionAbility，只需在其上添加 `@InsightIntentForm` 装饰器并补充对应的 Widget UI，无需新建 FormAbility 文件，也无需修改 `insight_intent.json`。

------

## 快速参考

### @InsightIntentForm 必填字段

| 字段            | 类型   | 说明                                                         | 示例                                |
| :-------------- | :----- | :----------------------------------------------------------- | :---------------------------------- |
| `intentName`    | string | 英文 PascalCase，动词-名词结构                               | `"PlayMusic"`, `"AddWeatherWidget"` |
| `domain`        | string | 域标识符，取值范围参见[各垂域的智慧分发特性列表](https://developer.huawei.com/consumer/cn/doc/service/intents-ai-distribution-characteristic-0000001901922213#section2656133582215) | `"MusicDomain"`, `"WeatherDomain"`  |
| `intentVersion` | string | 语义化版本，匹配标准意图的条件之一，默认填写 1.0.1           | `"1.0.1"`                           |
| `displayName`   | string | 中文显示名称                                                 | `"播放歌曲卡片"`                    |
| `formName`      | string | FormExtensionAbility 绑定的卡片名称，必须与 form_config.json 中一致 | `"widget"`                          |

### @InsightIntentForm 可选字段

| 字段                 | 类型                   | 说明                                                         | 示例                          |
| :------------------- | :--------------------- | :----------------------------------------------------------- | :---------------------------- |
| `displayDescription` | string                 | 详细描述                                                     | `"添加音乐播放卡片到桌面"`    |
| `schema`             | string                 | 标准意图 schema                                              | `"PlayMusic"`                 |
| `icon`               | ResourceStr            | 图标资源                                                     | `$r('app.media.icon')`        |
| `llmDescription`     | string                 | LLM 理解描述（自定义意图必填）                               | `"添加指定歌曲的播放卡片..."` |
| `keywords`           | string[]               | 搜索关键词（自定义意图必填）                                 | `["卡片", "音乐", "widget"]`  |
| `parameters`         | Record<string, Object> | 意图参数的数据格式声明，参考 [jsonschema_reference.md](jsonschema_reference.md/) | 见上文示例                    |
| `result`             | Record<string, Object> | 意图调用返回结果的格式声明                                   | 见上文示例                    |

------

## 常见问题

### Q1: formName 与卡片配置的关系？

`formName` 必须与 `form_config.json` 中定义的卡片 `name` 字段完全一致：

```typescript
// form_config.json
{ "name": "widget", ... }

// 装饰器中使用
@InsightIntentForm({ formName: 'widget', ... })
```

### Q2: 如何获取意图参数？

通过 `want.parameters` 获取：

```typescript
onAddForm(want: Want) {
  const songName = want.parameters?.songName as string;
  // 使用参数
}
```

### Q3: 卡片如何更新？

使用 `formProvider.updateForm()` 方法：

```typescript
import { formProvider, formBindingData } from '@kit.FormKit';
formProvider.updateForm(formId, formBindingData.createFormBindingData(newData));
```

### Q4: 卡片 UI 收不到数据，显示默认值？

- 检查 Widget UI 是否使用了 `@LocalStorageProp` 且字段名与 `formBindingData.createFormBindingData({...})` 中的键一致。
- 检查是否使用了 `let storage = new LocalStorage();` 和 `@Entry(storage)`。
- 确认 `onAddForm` 返回的 `FormBindingData` 中数据格式正确。

### Q5: 跨上下文文件读取失败？

- 确保路径使用 `context.filesDir`（或 `getApplicationContext().filesDir`），不要硬编码路径。
- 检查读写权限，FormExtension 与 UIAbility 共享同一沙箱，路径一致。

### Q6: 卡片尺寸支持？

在 `form_config.json` 的 `supportDimensions` 中定义，合法值包括：`"1*2"`, `"2*2"`, `"2*4"`, `"4*4"`, `"1*1"`, `"6*4"`, `"2*3"`, `"3*3"`。

------

## 相关资源

- [InsightIntentForm API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-insightintentdecorator#insightintentform)
- [FormExtensionAbility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [卡片配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)
- [ArkTS 卡片开发](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-development)
- [formBindingData](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata)
