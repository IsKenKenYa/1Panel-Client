---
name: hmos-form-kit-widget-call-event
description: 实现ArkTS卡片通过call事件拉起应用UIAbility到后台并调用指定方法,支持传递参数和接收返回值,仅支持单实例UIAbility,需配置后台运行权限,适用于音乐播放控制、卡片后台任务处理场景
---

# 卡片拉起应用UIAbility到后台（call事件）技能

## 功能描述

本技能提供ArkTS卡片通过call事件拉起应用UIAbility到后台的能力,实现卡片与应用的深度交互。通过call事件,卡片可以在后台调用应用UIAbility中的指定方法,传递参数并接收返回值,使应用在后台运行时可以通过卡片上的按钮执行不同的功能。

**核心能力**:
- 从卡片拉起应用UIAbility到后台(不调度到前台)
- 调用UIAbility中指定的方法(通过method参数)
- 支持参数传递和数据交互
- 通过rpc.Parcelable实现数据序列化和反序列化

**适用范围**:
- 仅支持ArkTS动态卡片(不支持静态卡片)
- 仅支持单实例UIAbility(launchType为singleton)
- 需要配置后台运行权限(ohos.permission.KEEP_BACKGROUND_RUNNING)

**典型场景**:
- 音乐卡片:播放、暂停、切歌等控制
- 任务卡片:后台执行下载、上传等任务
- 数据同步卡片:后台数据更新和同步

## 使用场景

### 触发词
- "卡片call事件"
- "卡片后台调用"
- "卡片拉起UIAbility到后台"
- "卡片调用应用方法"
- "Form Kit call事件"

### 能做
- 创建支持call事件的ArkTS动态卡片页面
- 实现卡片按钮触发call事件
- 在UIAbility中监听和处理call事件
- 通过rpc.Parcelable传递参数和返回值
- 配置后台运行权限和UIAbility启动模式

### 绝不做
- 不支持静态卡片(FormLink)
- 不支持多实例UIAbility
- 不支持拉起UIAbility到前台(应使用router事件)
- 不处理卡片的消息事件(message事件)
- 不实现卡片之间的通信

### 补充
- call事件与router事件的区别:call拉起UIAbility到后台,router拉起UIAbility到前台
- call事件与message事件的区别:call调用UIAbility方法,message触发FormExtensionAbility生命周期回调
- UIAbility监听的方法名必须与卡片调用的method参数保持一致
- 参数传递使用rpc.MessageSequence进行序列化

## 调用规范和规则

### 输入约束
- method参数:必填,字符串类型,用于标识需要调用的方法名称
- abilityName:必填,UIAbility名称,必须与module.json5配置保持一致
- params参数:可选,JSON格式键值对,支持任意参数传递
- formId:可选,卡片ID,用于标识卡片实例

### 执行约束
- postCardAction只能在卡片页面的onClick等事件中调用
- UIAbility的callee监听必须在onCreate生命周期中注册
- callee监听的方法必须返回rpc.Parcelable对象
- 进程退出时必须在onDestroy生命周期中解除监听
- 后台运行权限必须在module.json5中声明

### 内容约束
- 禁止在静态卡片中使用postCardAction
- 禁止使用launchType不为singleton的UIAbility
- 禁止在前台UIAbility中使用call事件
- 禁止在call事件中执行耗时超过5秒的操作
- 禁止传递超过1MB的数据

### 降级约束
- 后台权限缺失:提示用户配置权限,改用router事件拉起到前台
- UIAbility未启动:自动启动UIAbility后再调用方法
- 方法监听失败:记录错误日志,返回空Parcelable对象
- 参数过大:分片传递或提示用户减少数据量

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 检查是否为ArkTS动态卡片(静态卡片不支持)
2. 检查UIAbility的launchType是否为singleton
3. 检查是否已配置ohos.permission.KEEP_BACKGROUND_RUNNING权限
4. 检查method参数是否已定义

**参数准备**:
```typescript
// 卡片页面参数定义
interface CallActionParams {
  formId?: string;
  method: string;
  num?: number;
  message?: string;
}

// UIAbility监听方法参数定义
interface CalleeMethodParams {
  num: number;
  str: string;
}
```

### 步骤2:创建卡片页面

**示例代码**:
```typescript
// src/main/ets/widgeteventcall/pages/WidgetEventCallCard.ets
let storageEventCall = new LocalStorage();
@Entry(storageEventCall)
@Component
struct WidgetEventCallCard {
  @LocalStorageProp('formId') formId: string = '12400633174999288';
  
  build() {
    RelativeContainer() {
      Button('方法A')
        .id('funA__')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          postCardAction(this, {
            action: 'call',
            abilityName: 'WidgetEventCallEntryAbility',
            params: {
              formId: this.formId,
              method: 'funA'
            }
          });
        })
      
      Button('方法B')
        .id('funB__')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10 })
        .alignRules({
          top: { anchor: 'funA__', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          postCardAction(this, {
            action: 'call',
            abilityName: 'WidgetEventCallEntryAbility',
            params: {
              formId: this.formId,
              method: 'funB',
              num: 1
            }
          });
        })
    }
    .height('100%')
    .width('100%')
  }
}
```

### 步骤3:创建UIAbility监听

**示例代码**:
```typescript
// src/main/ets/WidgetEventCallEntryAbility/WidgetEventCallEntryAbility.ets
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { rpc } from '@kit.IPCKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'WidgetEventCallEntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

class MyParcelable implements rpc.Parcelable {
  private num: number;
  private str: string;
  
  constructor(num: number, str: string) {
    this.num = num;
    this.str = str;
  }
  
  marshalling(messageSequence: rpc.MessageSequence): boolean {
    messageSequence.writeInt(this.num);
    messageSequence.writeString(this.str);
    return true;
  }
  
  unmarshalling(messageSequence: rpc.MessageSequence): boolean {
    this.num = messageSequence.readInt();
    this.str = messageSequence.readString();
    return true;
  }
}

export default class WidgetEventCallEntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.callee.on('funA', (data: rpc.MessageSequence) => {
        hilog.info(DOMAIN_NUMBER, TAG, `FunACall param: ${JSON.stringify(data.readString())}`);
        return new MyParcelable(1, 'aaa');
      });
      
      this.callee.on('funB', (data: rpc.MessageSequence) => {
        hilog.info(DOMAIN_NUMBER, TAG, `FunBCall param: ${JSON.stringify(data.readString())}`);
        return new MyParcelable(2, 'bbb');
      });
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, `Failed to register callee on. Cause: ${JSON.stringify(err as BusinessError)}`);
    }
  }
  
  onDestroy(): void | Promise<void> {
    try {
      this.callee.off('funA');
      this.callee.off('funB');
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, `Failed to register callee off. Cause: ${JSON.stringify(err as BusinessError)}`);
    }
  }
}
```

### 步骤4:配置权限和UIAbility

**module.json5配置**:
```json
// src/main/module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.KEEP_BACKGROUND_RUNNING"
      }
    ],
    "abilities": [
      {
        "name": "WidgetEventCallEntryAbility",
        "srcEntry": "./ets/widgeteventcallentryability/WidgetEventCallEntryAbility.ets",
        "description": "$string:WidgetEventCallEntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:WidgetEventCallEntryAbility_label",
        "startWindowIcon": "$media:icon",
        "startWindowBackground": "$color:start_window_background",
        "launchType": "singleton"
      }
    ]
  }
}
```

### 步骤5:错误处理

**错误处理代码**:
```typescript
// 卡片页面错误处理
Button('方法A')
  .onClick(() => {
    try {
      postCardAction(this, {
        action: 'call',
        abilityName: 'WidgetEventCallEntryAbility',
        params: {
          method: 'funA'
        }
      });
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `postCardAction failed: ${error.message}`);
      // 降级处理:提示用户或改用router事件
    }
  })

// UIAbility错误处理
this.callee.on('funA', (data: rpc.MessageSequence) => {
  try {
    let params = data.readString();
    hilog.info(DOMAIN_NUMBER, TAG, `FunACall param: ${params}`);
    return new MyParcelable(1, 'success');
  } catch (error) {
    hilog.error(DOMAIN_NUMBER, TAG, `Method execution failed: ${error.message}`);
    return new MyParcelable(-1, 'error');
  }
});
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误,method参数缺失或类型不正确 | 检查method参数是否为字符串类型 |
| 16000050 | UIAbility不存在 | 检查abilityName是否与module.json5配置一致 |
| 16000051 | UIAbility启动模式不正确 | 修改UIAbility的launchType为singleton |
| 16000052 | 后台运行权限缺失 | 在module.json5中添加ohos.permission.KEEP_BACKGROUND_RUNNING权限 |
| 1900008 | rpc对象无效 | 检查Parcelable对象的序列化方法实现 |
| 1900009 | 写入MessageSequence失败 | 检查参数数据是否超过限制或格式不正确 |
| 1900010 | 读取MessageSequence失败 | 检查数据读取顺序是否与写入顺序一致 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AbilityKit": "^1.0.0",
    "@kit.IPCKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0",
    "@kit.PerformanceAnalysisKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version: >= 9
- DevEco Studio: >= 3.1
- ArkTS编译器: >= 1.0

### 常见编译问题

**问题1:postCardAction未定义**
```
Error: Cannot find name 'postCardAction'
```
**解决方法**: postCardAction为全局API,无需导入,确保在卡片页面中使用

**问题2:rpc.Parcelable未找到**
```
Error: Cannot find namespace 'rpc'
```
**解决方法**: 添加导入语句 `import { rpc } from '@kit.IPCKit';`

**问题3:权限未生效**
```
Error: Permission denied
```
**解决方法**: 检查module.json5中requestPermissions配置是否正确

**问题4:UIAbility监听方法不触发**
```
Warning: callee method not called
```
**解决方法**: 检查method参数与UIAbility监听的方法名是否一致

## 常见问题与解决方法

### Q1:call事件无法触发UIAbility方法
**原因**: UIAbility未启动或监听方法未注册
**解决方法**:
- 确保UIAbility已启动(可在onCreate中打印日志)
- 检查callee.on监听是否在onCreate生命周期中注册
- 检查method参数与监听方法名是否完全一致(区分大小写)

### Q2:参数传递失败或数据丢失
**原因**: Parcelable序列化方法实现错误
**解决方法**:
- 确保marshalling方法按正确顺序写入数据
- 确保unmarshalling方法按相同顺序读取数据
- 检查数据类型是否匹配(如writeInt对应readInt)

### Q3:UIAbility无法后台运行
**原因**: 后台运行权限缺失或配置错误
**解决方法**:
- 在module.json5中添加ohos.permission.KEEP_BACKGROUND_RUNNING权限
- 检查权限声明格式是否正确
- 确保应用已重新编译安装

### Q4:静态卡片无法使用call事件
**原因**: postCardAction仅支持ArkTS动态卡片
**解决方法**:
- 改用FormLink组件实现静态卡片交互
- 或将静态卡片改为动态卡片

### Q5:call事件导致应用前台显示
**原因**: UIAbility的launchType不是singleton
**解决方法**:
- 修改module.json5中UIAbility的launchType为singleton
- 确保只有一个UIAbility实例

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "widgetPage": "WidgetEventCallCard.ets",
  "uiAbility": "WidgetEventCallEntryAbility.ets",
  "permissions": ["ohos.permission.KEEP_BACKGROUND_RUNNING"],
  "methods": ["funA", "funB"],
  "apiUsed": [
    "postCardAction",
    "rpc.Parcelable",
    "UIAbility.callee.on",
    "UIAbility.callee.off"
  ],
  "configModified": [
    "module.json5 (requestPermissions)",
    "module.json5 (abilities)"
  ]
}
```

## 参考文档

- [卡片拉起应用UIAbility到后台开发指南](references/arkts-ui-widget-event-call.md)
- [postCardAction API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-postcardaction)
- [rpc.Parcelable API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-rpc)
- [后台运行权限说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/permissions-for-all)

## 完整示例代码

- [卡片页面示例](assets/WidgetEventCallCard.ets)
- [UIAbility示例](assets/WidgetEventCallEntryAbility.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试call事件正常触发](tests/test_positive.ets):验证卡片按钮点击能成功调用UIAbility方法
- [测试参数传递](tests/test_positive.ets):验证参数能正确传递并返回结果

### 边界测试用例
- [测试大数据传递](tests/test_boundary.ets):验证接近1MB数据传递的稳定性
- [测试多方法并发调用](tests/test_boundary.ets):验证多个call事件并发触发

### 异常测试用例
- [测试权限缺失](tests/test_exception.ets):验证未配置后台权限时的错误处理
- [测试UIAbility不存在](tests/test_exception.ets):验证调用不存在UIAbility的错误处理
- [测试method参数缺失](tests/test_exception.ets):验证method参数为空时的错误处理