---
name: hmos-push-kit-send-alert
description: 发送Push Kit通知消息+支持通知样式设置、账号校验、前台处理+最大1000条测试消息/日+适用于消息推送、用户提醒场景
---

# 发送通知消息技能

## 功能描述

本技能提供Push Kit通知消息的完整发送能力，通过Push Kit通道直接下发通知消息，可在终端设备的通知中心、锁屏、横幅等位置展示，用户点击后拉起应用。支持多种通知样式（普通通知、通知角标、通知大图标、多行文本样式）、账号校验、前台消息处理、自定义铃声等高级功能，满足各类消息推送和用户提醒场景需求。

**核心能力**：
- 客户端通知授权请求
- Push Token获取和管理
- 服务端REST API消息推送
- 通知消息样式定制
- 应用账号绑定校验
- 应用前台消息接收处理
- 通知消息自定义铃声

**适用设备**：
- Phone、Tablet、PC/2in1：全部版本支持
- Wearable：5.1.0(18)版本起支持
- TV：5.1.1(19)版本起支持

## 使用场景

### 触发词
- "发送通知消息"
- "推送通知"
- "Push Kit通知"
- "发送Alert消息"
- "通知消息推送"
- "push notification"

### 能做
- 通过Push Kit服务端REST API发送通知消息到指定设备
- 请求客户端通知授权，确保应用可正常接收通知
- 获取和管理Push Token用于消息推送
- 设置多种通知样式（普通、角标、大图标、多行文本）
- 绑定/解绑应用账号实现账号校验功能
- 应用在前台时接收通知消息并进行业务处理
- 设置自定义通知铃声（category非MARKETING时支持）
- 配置点击消息跳转到应用首页或应用内页
- 传递自定义数据到客户端应用
- 发送测试消息（每个项目每日最多1000条）

### 绝不做
- 不发送包含敏感信息的图片通知
- 不在category为MARKETING时使用自定义铃声功能
- 不在Wearable设备上使用通知角标和大图标样式
- 不在TV设备上使用通知角标样式
- 不在应用首页skill中配置uris（会导致消息接收失败）
- 不发送超过频控限制的消息数量
- 不使用高危操作（如硬编码敏感信息）
- 不申请超出必需的权限

### 补充
- 未申请通知消息自分类权益时，推送的通知消息默认为资讯营销类（category=MARKETING）
- 资讯营销类消息每天可发送数量为2条或5条（根据应用类型）
- 服务通讯类消息与资讯营销类消息有不同的频控策略
- 测试消息标识testMessage=true时，单次推送Token数不超过10个
- foregroundShow=true时，receiveMessage不会被触发
- 应用在前台时需要配置action.ohos.push.listener才能接收消息
- 多行文本样式需要设置style字段为3，最多展示3行内容
- 绑定的应用内账号数量最大为10

## 调用规范和规则

### 输入约束
- **通知标题**：必填，文本内容最多显示3行
- **通知内容**：必填，文本内容最多显示3行
- **Push Token**：必填，字符长度为112，单次推送Token数不超过10个（测试消息）
- **projectId**：必填，项目ID，从AppGallery Connect获取
- **Authorization**：必填，JWT格式字符串
- **通知消息类型（category）**：MARKETING（资讯营销类）或其他服务通讯类
- **图片格式**：PNG、JPG、JPEG、BMP、WEBP，总字节数不超过192KB
- **自定义铃声文件**：必须放在/resources/rawfile路径下
- **profileId**：账号匿名标识，最大长度64，不可为空字符串
- **notifyId**：可选，数字范围[0, 2147483647]
- **ttl**：可选，消息缓存时间
- **soundDuration**：可选，铃声时长范围[1, 60]秒

### 执行约束
- **测试消息频控**：每个项目每日全网最多推送1000条测试消息
- **正式消息频控**：单设备单应用下每日推送消息总条数受频控限制
- **资讯营销类频控**：每天可发送2条或5条（根据应用类型）
- **API调用频次**：遵循Push Kit服务端频控规则
- **最大耗时**：REST API调用建议在30秒内完成
- **账号绑定数量**：单设备单应用最多绑定10个账号

### 内容约束
- **禁止推送内容**：包含敏感信息的图片、违法违规内容
- **禁止使用高危函数**：eval、exec、os.system等高危函数
- **禁止操作**：硬编码敏感信息、本地高权限路径遍历、代码漏洞
- **禁止配置**：应用首页skill中配置uris（会导致消息接收失败）
- **category限制**：MARKETING类型不支持自定义铃声功能
- **设备限制**：Wearable不支持通知角标和大图标，TV不支持通知角标

### 降级约束
- **网络失败**：提示网络错误，建议用户检查网络连接并重试
- **Token获取失败**：提示Token获取失败原因（错误码），建议检查推送权益开通状态
- **频控限制**：提示频控限制，建议申请自分类权益或调整发送策略
- **权限不足**：提示通知权限未开启，引导用户开启通知权限
- **账号未绑定**：提示账号绑定失败，建议检查账号登录状态和绑定流程
- **消息发送失败**：根据错误码提供具体解决方案
- **图片过大**：提示图片超过192KB限制，建议压缩图片或更换图片
- **匹配失败**：action和uri都未匹配成功时，降级到应用首页

## 调用流程和步骤

### 步骤1：客户端准备 - 获取Push Token

**前置校验**：
1. 检查应用是否已开通Push Kit服务权益
2. 检查设备是否支持Push Token获取（Phone/Tablet/PC/2in1/Wearable/TV）
3. 检查网络连接状态

**导入必要模块**：
```typescript
import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**获取Push Token示例代码**：
```typescript
const DOMAIN = 0x0000;

async function getPushToken(): Promise<string> {
  try {
    const token: string = await pushService.getToken();
    hilog.info(DOMAIN, 'testTag', 'Succeeded in getting push token');
    return token;
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, 'testTag', 'Failed to get push token: %{public}d %{public}s', e.code, e.message);
    throw e;
  }
}
```

**错误处理**：
```typescript
try {
  const token = await getPushToken();
  // 将Token上报到应用服务端
} catch (error) {
  switch (error.code) {
    case 1000900001:
      hilog.error(DOMAIN, 'testTag', 'System internal error');
      break;
    case 1000900008:
      hilog.error(DOMAIN, 'testTag', 'Failed to connect to the push service');
      break;
    case 1000900011:
      hilog.error(DOMAIN, 'testTag', 'The network is unavailable');
      break;
    case 1000900012:
      hilog.error(DOMAIN, 'testTag', 'Push rights are not activated');
      break;
    case 1000900014:
      hilog.error(DOMAIN, 'testTag', 'The device does not support getting token');
      break;
    default:
      hilog.error(DOMAIN, 'testTag', 'Unknown error: %{public}d', error.code);
  }
}
```

### 步骤2：客户端准备 - 请求通知授权

**前置校验**：
1. 检查应用是否已导入NotificationKit模块
2. 检查应用是否在UIAbility的onWindowStageCreate生命周期中

**导入必要模块**：
```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { notificationManager } from '@kit.NotificationKit';
```

**请求通知授权示例代码**：
```typescript
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      
      notificationManager.requestEnableNotification(this.context).then(() => {
        hilog.info(DOMAIN, 'testTag', 'RequestEnableNotification success');
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, 'testTag', 
          `RequestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
      });
    });
  }
}
```

### 步骤3：客户端准备 - 配置点击消息跳转

#### 点击消息进入应用首页

**module.json5配置示例**：
```json
{
  "module": {
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:layered_image",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "ohos.want.action.home"
            ]
          }
        ]
      }
    ]
  }
}
```

**重要提示**：应用首页的skill中不要配置uris，否则消息会接收不到。

#### 点击消息进入应用内页

**方式一：配置actions参数**：
```json
{
  "name": "TestAbility",
  "srcEntry": "./ets/abilities/TestAbility.ets",
  "exported": false,
  "startWindowIcon": "$media:startIcon",
  "startWindowBackground": "$color:start_window_background",
  "skills": [
    {
      "actions": [
        "com.app.action"
      ]
    },
    {
      "actions": [
        "com.test.action"
      ]
    }
  ]
}
```

**方式二：配置uris参数（必须同时配置actions参数且为空）**：
```json
{
  "name": "InnerUrisAbility",
  "srcEntry": "./ets/abilities/InnerUrisAbility.ets",
  "exported": false,
  "startWindowIcon": "$media:startIcon",
  "startWindowBackground": "$color:start_window_background",
  "skills": [
    {
      "actions": [
        "com.app.action"
      ]
    },
    {
      "actions": [
        ""
      ],
      "uris": [
        {
          "scheme": "https",
          "host": "www.xxx.com",
          "port": "8080",
          "path": "push/test"
        }
      ]
    }
  ]
}
```

### 步骤4：服务端推送 - 调用REST API发送通知消息

**请求URL**：
```
POST https://push-api.cloud.huawei.com/v3/[projectId]/messages:send
```

**请求Header**：
```
Content-Type: application/json
Authorization: Bearer eyJr*****OiIx---****.eyJh*****iJodHR--***.QRod*****4Gp---****
push-type: 0
```

**普通通知消息体示例**：
```json
{
  "payload": {
    "notification": {
      "category": "MARKETING",
      "title": "普通通知标题",
      "body": "普通通知内容",
      "clickAction": {
        "actionType": 0
      },
      "foregroundShow": true,
      "notifyId": 12345
    }
  },
  "target": {
    "token": ["MAMzLg**********lPW"]
  },
  "pushOptions": {
    "testMessage": true,
    "ttl": 86400
  }
}
```

**带大图标的通知消息体示例**：
```json
{
  "payload": {
    "notification": {
      "category": "MARKETING",
      "title": "推送服务",
      "body": "推送服务是华为提供的消息推送平台",
      "image": "https://***.png",
      "clickAction": {
        "actionType": 0
      }
    }
  },
  "target": {
    "token": ["MAMzLg**********lPW"]
  },
  "pushOptions": {
    "testMessage": true
  }
}
```

**多行文本样式通知消息体示例**：
```json
{
  "payload": {
    "notification": {
      "category": "MARKETING",
      "title": "推送个性化显示",
      "body": "通知内容",
      "style": 3,
      "inboxContent": [
        "1. 通知栏消息样式",
        "2. 通知栏消息提醒方式和展示方式",
        "3. 通知栏消息语言本地化"
      ],
      "clickAction": {
        "actionType": 0
      }
    }
  },
  "target": {
    "token": ["MAMzLg**********lPW"]
  },
  "pushOptions": {
    "testMessage": true
  }
}
```

**点击消息进入应用内页消息体示例**：
```json
{
  "payload": {
    "notification": {
      "category": "MARKETING",
      "title": "普通通知标题",
      "body": "普通通知内容",
      "clickAction": {
        "actionType": 1,
        "action": "com.test.action",
        "uri": "https://www.xxx.com:8080/push/test",
        "data": {"testKey": "testValue"}
      }
    }
  },
  "target": {
    "token": ["MAMzLg**********lPW"]
  },
  "pushOptions": {
    "testMessage": true
  }
}
```

**参数说明**：
- `projectId`：项目ID，从AppGallery Connect项目设置页面获取
- `Authorization`：JWT格式字符串，参见Authorization获取方式
- `push-type`：0表示Alert消息（通知消息场景）
- `category`：通知消息类型，MARKETING为资讯营销类
- `actionType`：0表示进入应用首页，1表示进入应用内页
- `token`：Push Token数组
- `testMessage`：测试消息标识，true表示测试消息
- `ttl`：消息缓存时间
- `notifyId`：自定义消息标识，用于消息撤回
- `foregroundShow`：通知是否在前台展示
- `image`：大图标URL，图片总字节数不超过192KB
- `style`：3表示多行文本样式
- `inboxContent`：多行文本内容数组，最多3行
- `action`：能够接收Want的action值
- `uri`：与Want中uris相匹配的集合
- `data`：点击消息时携带的JSON格式数据

### 步骤5：客户端接收 - 数据传递处理

**在Ability中接收数据示例**：
```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

export default class InnerUrisAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'InnerUrisAbility onCreate');
    const value = want.parameters?.['testKey'];
    hilog.info(DOMAIN, 'testTag', 'Succeeded in getting message data, value is %{public}s', value ?? 'default value');
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'InnerUrisAbility onNewWant');
    const value = want.parameters?.['testKey'];
    hilog.info(DOMAIN, 'testTag', 'Succeeded in getting message data, value is %{public}s', value ?? 'default value');
  }
}
```

**注意**：onNewWant()方法仅在单例（singleton）模式下可用。

### 步骤6：账号校验 - 绑定应用账号（可选）

**导入必要模块**：
```typescript
import { pushCommon, pushService } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

**绑定应用账号示例代码**：
```typescript
const profileId: string = '111***222';
const DOMAIN = 0x0000;

function bindAppProfileId(): void {
  pushService.bindAppProfileId(pushCommon.AppProfileType.PROFILE_TYPE_APPLICATION_ACCOUNT, profileId).then(() => {
    hilog.info(DOMAIN, 'testTag', 'Succeeded in binding app profile id');
  }).catch((err: BusinessError) => {
    hilog.error(DOMAIN, 'testTag', 'Failed to bind app profile id: %{public}d %{public}s', err.code, err.message);
  });
}
```

**解绑应用账号示例代码**：
```typescript
function unbindAppProfileId(): void {
  pushService.unbindAppProfileId(pushCommon.AppProfileType.PROFILE_TYPE_APPLICATION_ACCOUNT, profileId).then(() => {
    hilog.info(DOMAIN, 'testTag', 'Succeeded in unbinding app profile id');
  }).catch((err: BusinessError) => {
    hilog.error(DOMAIN, 'testTag', 'Failed to unbind app profile id: %{public}d %{public}s', err.code, err.message);
  });
}
```

**服务端推送带账号校验的消息体示例**：
```json
{
  "payload": {
    "notification": {
      "category": "MARKETING",
      "title": "普通通知标题",
      "body": "普通通知内容",
      "profileId": "111***222",
      "clickAction": {
        "actionType": 0
      }
    }
  },
  "target": {
    "token": ["MAMzLg**********lPW"]
  },
  "pushOptions": {
    "testMessage": true
  }
}
```

### 步骤7：前台消息处理 - 应用在前台接收通知（可选）

**module.json5配置**：
```json
{
  "name": "PushMessageAbility",
  "srcEntry": "./ets/abilities/PushMessageAbility.ets",
  "description": "$string:PushMessageAbility_desc",
  "icon": "$media:layered_image",
  "label": "$string:PushMessageAbility_label",
  "startWindowIcon": "$media:startIcon",
  "startWindowBackground": "$color:start_window_background",
  "launchType": "singleton",
  "exported": false,
  "skills": [
    {
      "actions": [
        "com.app.action"
      ]
    },
    {
      "actions": [
        "action.ohos.push.listener"
      ]
    }
  ]
}
```

**注意**：项目中有且只能有一个ability定义action.ohos.push.listener。

**服务端消息体设置foregroundShow为false**：
```json
{
  "payload": {
    "notification": {
      "category": "MARKETING",
      "title": "普通通知标题",
      "body": "普通通知内容",
      "clickAction": {
        "actionType": 0
      },
      "foregroundShow": false
    }
  },
  "target": {
    "token": ["MAMzLg**********lPW"]
  },
  "pushOptions": {
    "testMessage": true
  }
}
```

**客户端接收消息示例代码**：
```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

export default class PushMessageAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      pushService.receiveMessage('DEFAULT', this, (payload) => {
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Receive message for DEFAULT type.');
        try {
          const data: string = payload?.data;
          hilog.info(DOMAIN, 'testTag', 'Succeeded in getting notification,data=%{public}s',
            JSON.stringify(JSON.parse(data)?.notification));
        } catch (err) {
          const e: BusinessError = err as BusinessError;
          hilog.error(DOMAIN, 'testTag', 'Failed to process data: %{public}d %{public}s.', e.code, e.message);
        }
      });
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in registering default message.');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Failed to register default message: %{public}d %{public}s', e.code, e.message);
    }
  }
}
```

### 步骤8：自定义铃声 - 设置通知铃声（可选）

**客户端准备**：
将自定义铃声文件放在客户端工程中/resources/rawfile路径下（例如alert.mp3）。

**服务端消息体示例**：
```json
{
  "payload": {
    "notification": {
      "category": "TRAVEL",
      "title": "普通通知标题",
      "body": "普通通知内容",
      "clickAction": {
        "actionType": 0
      },
      "notifyId": 12345,
      "sound": "alert.mp3",
      "soundDuration": 10
    }
  },
  "target": {
    "token": ["MAMzLg**********lPW"]
  },
  "pushOptions": {
    "testMessage": true,
    "ttl": 86400
  }
}
```

**注意**：category取值为MARKETING时，不支持自定义铃声功能。

## 错误码说明

### 客户端错误码

| 错误码ID | 错误信息 | 说明 | 解决方法 |
|---------|---------|------|---------|
| 401 | Parameter error | 参数错误：必填参数未指定、参数类型不正确、参数验证失败 | 检查参数是否正确填写，确保参数类型匹配 |
| 1000900001 | System internal error | 系统内部错误 | 重试或联系技术支持 |
| 1000900008 | Failed to connect to the push service | 无法连接推送服务 | 检查网络连接，确认Push Kit服务是否正常 |
| 1000900009 | Internal error of the push service | Push服务内部错误 | 重试或联系技术支持 |
| 1000900010 | Illegal application identity | 应用身份非法 | 检查应用配置和签名信息 |
| 1000900011 | The network is unavailable | 网络不可用 | 检查网络连接状态 |
| 1000900012 | Push rights are not activated | 推送权益未开通 | 在AppGallery Connect开通Push Kit服务权益 |
| 1000900013 | Cross-location application is not allowed to obtain the token | 跨位置应用不允许获取Token | 检查应用配置的地区设置 |
| 1000900014 | The device does not support getting token | 设备不支持获取Token | 检查设备类型和API版本要求 |
| 1000900015 | The number of bound profile-app relationships exceeds the maximum | 绑定的账号数量超过最大值 | 单设备单应用最多绑定10个账号 |
| 1000900016 | The os distributed account is not logged in | 分布式账号未登录 | 检查华为账号登录状态 |

### Notification Manager错误码

| 错误码ID | 错误信息 | 说明 | 解决方法 |
|---------|---------|------|---------|
| 1600001 | Internal error | 内部错误 | 重试或联系技术支持 |
| 1600002 | Marshalling or unmarshalling error | 序列化或反序列化错误 | 检查数据格式 |
| 1600003 | Failed to connect to the service | 连接服务失败 | 检查Notification服务状态 |
| 1600004 | Notification disabled | 通知已禁用 | 用户需要开启通知权限 |
| 1600005 | Notification slot disabled | 通知渠道已禁用 | 检查通知渠道配置 |
| 1600007 | The notification does not exist | 通知不存在 | 检查通知ID是否正确 |
| 1600009 | The notification sending frequency reaches the upper limit | 通知发送频率达到上限 | 等待频控限制解除或申请自分类权益 |
| 1600012 | No memory space | 内存空间不足 | 清理设备内存 |
| 1600014 | No permission | 无权限 | 检查应用权限配置 |
| 1600020 | The application is not allowed to send notifications due to permission settings | 应用不允许发送通知 | 用户需要开启通知权限 |
| 2300007 | Network unreachable | 网络不可达 | 检查网络连接 |

### 服务端REST API错误码

| HTTP状态码 | 说明 | 解决方法 |
|----------|------|---------|
| 200 | 成功 | 消息发送成功 |
| 400 | 请求参数错误 | 检查请求参数格式和必填字段 |
| 401 | 认证失败 | 检查Authorization JWT字符串是否正确 |
| 403 | 权限不足 | 检查应用是否开通推送权益 |
| 404 | 资源不存在 | 检查projectId是否正确 |
| 429 | 频控限制 | 等待频控限制解除或申请自分类权益 |
| 500 | 服务器内部错误 | 重试或联系技术支持 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PushKit": "^4.0.0",
    "@kit.NotificationKit": "^9.0.0",
    "@kit.AbilityKit": "^4.0.0",
    "@kit.BasicServicesKit": "^4.0.0",
    "@kit.PerformanceAnalysisKit": "^4.0.0",
    "@kit.ArkUI": "^4.0.0"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：最低版本4.0.0(10)
- **DevEco Studio**：最低版本3.1
- **Node.js**：最低版本14.x
- **npm**：最低版本6.x
- **设备要求**：
  - Phone/Tablet/PC/2in1：全部版本
  - Wearable：5.1.0(18)及以上
  - TV：5.1.1(19)及以上

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PushKit' or its corresponding type declarations.
```
**解决方法**：
1. 检查HarmonyOS SDK版本是否满足最低要求4.0.0(10)
2. 在DevEco Studio中更新SDK到最新版本
3. 检查项目配置文件中的依赖声明

**问题2：API不存在错误**
```
Error: Property 'getToken' does not exist on type 'pushService'.
```
**解决方法**：
1. 确认API起始版本，getToken从4.0.0(10)开始支持
2. 检查设备类型是否支持该API
3. 确认导入路径是否正确：`import { pushService } from '@kit.PushKit';`

**问题3：类型定义错误**
```
Error: Type 'BusinessError' is not defined.
```
**解决方法**：
导入BusinessError类型：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
```

**问题4：权限未配置错误**
```
Error: No permission to use push service.
```
**解决方法**：
1. 在AppGallery Connect开通Push Kit服务权益
2. 检查module.json5中是否配置了必要权限
3. 检查应用签名配置是否正确

**问题5：网络连接失败**
```
Error: Failed to connect to the push service (1000900008)
```
**解决方法**：
1. 检查设备网络连接状态
2. 检查防火墙是否阻止了Push Kit服务连接
3. 确认Push Kit服务端点是否可访问

### module.json5权限配置示例
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_reason_network"
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_reason_internet"
      }
    ]
  }
}
```

## 常见问题与解决方法

### Q1：应用无法收到通知消息
**原因**：
- 通知权限未开启
- Push Token未正确获取
- 服务端推送失败
- 消息频控限制
- 应用首页skill配置了uris

**解决方法**：
1. 调用requestEnableNotification()请求通知授权
2. 检查Push Token获取是否成功，查看错误码
3. 检查服务端REST API响应状态码和响应参数
4. 检查频控规则，确认是否超过频控限制
5. 检查module.json5中应用首页skill是否配置了uris（不要配置）
6. 查看Push Kit常见问题文档

### Q2：推送消息后设备未收到通知
**原因**：
- Push Token过期或无效
- 设备网络不可用
- 通知权限被用户关闭
- foregroundShow设置为false且应用在前台
- 频控限制

**解决方法**：
1. 重新获取Push Token并上报到服务端
2. 检查设备网络连接状态
3. 引导用户开启通知权限
4. 如果需要前台展示，将foregroundShow设置为true
5. 检查频控限制，发送测试消息（testMessage=true）不受设备频控限制

### Q3：发送测试消息超过1000条限制
**原因**：
每个项目每日全网最多可推送1000条测试消息

**解决方法**：
- 等待第二天频控重置
- 申请通知消息自分类权益，发送正式消息
- 单次推送Token数不超过10个（测试消息限制）

### Q4：资讯营销类消息频控限制
**原因**：
资讯营销类消息每天可发送数量为2条或5条（根据应用类型）

**解决方法**：
- 申请通知消息自分类权益，开通服务通讯类消息权益
- 服务通讯类消息频控策略与资讯营销类不同
- 合理规划消息发送时间和频率

### Q5：点击消息无法跳转到应用内页
**原因**：
- module.json5中未配置对应的skill
- action或uri参数配置错误
- action和uri都未匹配成功
- Ability未正确配置exported属性

**解决方法**：
1. 在module.json5中为目标Ability配置skills标签
2. 检查action和uri参数是否与skill配置匹配
3. 如果action和uri都未匹配成功，会降级到应用首页
4. 检查Ability的exported属性是否正确设置
5. 确保skills数组中创建独立的skill对象，不要与其他能力共用

### Q6：账号绑定后仍收到其他账号的消息
**原因**：
- 账号切换时未重新绑定
- 账号登出时未解绑
- profileId未正确上报到服务端

**解决方法**：
1. 在账号登录后立即调用bindAppProfileId()绑定
2. 在账号切换时重新调用bindAppProfileId()绑定新账号
3. 在账号登出时调用unbindAppProfileId()解绑
4. 将profileId正确上报到应用服务端
5. 服务端推送时携带正确的profileId

### Q7：自定义铃声不播放
**原因**：
- category为MARKETING不支持自定义铃声
- 铃声文件路径不正确
- 铃声文件格式不支持

**解决方法**：
1. 确保category不为MARKETING
2. 铃声文件必须放在/resources/rawfile路径下
3. 支持的铃声格式为MP3等常见音频格式
4. sound字段传入文件名（如"alert.mp3")
5. soundDuration字段仅在携带sound字段时生效

### Q8：通知角标数字不准确
**原因**：
- addNum和setNum优先级理解错误
- 未调用setBadgeNumber()清理角标
- 打开应用或点击消息不会自动清理角标

**解决方法**：
1. setNum优先级高于addNum，设置setNum后角标显示为setNum值
2. addNum是累加数字，非实际显示数字
3. 打开应用或点击、清理通知消息不会清理角标
4. 开发者需调用notificationManager.setBadgeNumber(0)清理角标
5. 导入notificationManager模块：`import { notificationManager } from '@kit.NotificationKit';`

### Q9：多行文本样式显示不正确
**原因**：
- style字段未设置为3
- inboxContent数组超过3行
- title和body字段配置错误

**解决方法**：
1. 多行文本样式需要设置style字段为3
2. inboxContent数组最多展示3行内容
3. 每行内容无法完全展示时以"..."截断
4. 折叠时显示的标题和内容取自title和body字段
5. 展开后显示的标题和内容取自title和inboxContent字段

### Q10：应用在前台时无法接收消息数据
**原因**：
- foregroundShow设置为true
- 未配置action.ohos.push.listener
- 未调用receiveMessage()方法
- Ability配置错误

**解决方法**：
1. foregroundShow=false时应用在前台不展示通知，可接收消息数据
2. 在对应Ability的skills标签中配置actions为"action.ohos.push.listener"
3. 项目中有且只能有一个ability定义该action
4. 在Ability的onCreate()中调用receiveMessage('DEFAULT', this, callback)
5. foregroundShow=true时receiveMessage不会被触发

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "pushToken": "MAMzLg**********lPW",
  "projectId": "123456789",
  "messageType": "Alert",
  "category": "MARKETING",
  "notificationEnabled": true,
  "accountBind": false,
  "foregroundHandling": false,
  "customSound": false,
  "apiUsed": [
    "pushService.getToken()",
    "notificationManager.requestEnableNotification()",
    "pushService.bindAppProfileId()",
    "pushService.receiveMessage()",
    "REST API: POST /v3/{projectId}/messages:send"
  ],
  "deviceSupported": [
    "Phone",
    "Tablet",
    "PC/2in1",
    "Wearable (5.1.0+)",
    "TV (5.1.1+)"
  ],
  "apiVersion": "4.0.0(10)",
  "testMode": true,
  "testMessageCount": 1,
  "freqControlRemaining": 999
}
```

## 参考文档

- [API开发指南 - 发送通知消息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-send-alert)
- [API参考 - pushService模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-pushservice)
- [API参考 - notificationManager模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-notificationmanager)
- [API参考 - pushCommon模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-pushcommon)
- [API参考 - REST API请求结构](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-scenariozed-api-request-struct)
- [API参考 - REST API请求参数](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-scenariozed-api-request-param)
- [API参考 - REST API响应参数](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-scenariozed-api-response)
- [API参考 - Push Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-error-code)
- [开发指南 - 申请通知消息自分类权益](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-apply-right)
- [开发指南 - 获取Push Token](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-get-token)
- [开发指南 - 点击消息动作](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file)
- [开发指南 - 请求通知授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/notification-enable)
- [开发指南 - Push Kit常见问题](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-faq-2)

## 完整示例代码

- [ArkTS客户端示例 - 获取Token和请求授权](assets/push_client_example.ets)
- [ArkTS客户端示例 - 账号绑定和消息接收](assets/push_account_example.ets)
- [Python服务端示例 - REST API推送](assets/push_server_example.py)
- [JavaScript服务端示例 - REST API推送](assets/push_server_example.js)
- [配置文件示例 - module.json5](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试1：获取Push Token成功](tests/test_positive.ts)：正常获取Push Token并上报服务端
- [测试2：请求通知授权成功](tests/test_positive.ts)：用户同意开启通知权限
- [测试3：发送普通通知成功](tests/test_positive.py)：服务端成功推送普通通知消息
- [测试4：发送大图标通知成功](tests/test_positive.py)：服务端成功推送带大图标的通知
- [测试5：发送多行文本通知成功](tests/test_positive.py)：服务端成功推送多行文本样式通知
- [测试6：点击消息跳转首页成功](tests/test_positive.ts)：点击消息成功进入应用首页
- [测试7：点击消息跳转内页成功](tests/test_positive.ts)：点击消息成功进入应用内页
- [测试8：账号绑定成功](tests/test_positive.ts)：成功绑定应用账号并接收消息
- [测试9：前台消息接收成功](tests/test_positive.ts)：应用在前台成功接收消息数据
- [测试10：自定义铃声播放成功](tests/test_positive.py)：通知成功播放自定义铃声

### 边界测试用例
- [测试1：Push Token长度为112](tests/test_boundary.ts)：验证Token字符长度为112
- [测试2：测试消息达到1000条限制](tests/test_boundary.py)：验证测试消息频控限制
- [测试3：资讯营销类消息频控限制](tests/test_boundary.py)：验证资讯营销类消息频控
- [测试4：图片大小达到192KB限制](tests/test_boundary.py)：验证图片大小上限
- [测试5：多行文本达到3行限制](tests/test_boundary.py)：验证inboxContent最多3行
- [测试6：账号绑定达到10个限制](tests/test_boundary.ts)：验证账号绑定数量上限
- [测试7：profileId长度达到64限制](tests/test_boundary.ts)：验证profileId最大长度
- [测试8：soundDuration达到60秒限制](tests/test_boundary.py)：验证铃声时长上限
- [测试9：单次推送Token达到10个限制](tests/test_boundary.py)：验证测试消息Token数量上限

### 异常测试用例
- [测试1：网络不可用获取Token失败](tests/test_exception.ts)：模拟网络断开场景
- [测试2：推送权益未开通失败](tests/test_exception.ts)：模拟权益未开通场景
- [测试3：通知权限拒绝失败](tests/test_exception.ts)：模拟用户拒绝授权场景
- [测试4：Push Token无效推送失败](tests/test_exception.py)：模拟Token过期场景
- [测试5：JWT认证失败](tests/test_exception.py)：模拟Authorization错误场景
- [测试6：projectId不存在失败](tests/test_exception.py)：模拟projectId错误场景
- [测试7：频控限制推送失败](tests/test_exception.py)：模拟频控限制场景
- [测试8：图片超过192KB失败](tests/test_exception.py)：模拟图片过大场景
- [测试9：category为MARKETING不支持铃声](tests/test_exception.py)：模拟category限制场景
- [测试10：账号未绑定接收消息失败](tests/test_exception.py)：模拟账号校验失败场景