# 开发准备

> 文档ID: development-preparation
> 更新时间: 2026-08-06

---

# 开发准备

应用开发前的准备工作，包括环境配置、权限申请、项目创建等。

## 1. 环境要求

- **IDE**: DevEco Studio（最新版本）
- **SDK**: HarmonyOS NEXT SDK，compatibleSdkVersion ≥ 5.0.5(17)，targetSdkVersion ≥ 6.0.0(20)
- **设备**: 支持Phone、Tablet、PC/2in1设备
  - PC/2in1设备需确保智慧营销服务或广告服务版本 ≥ 8.4.80.300

## 2. 创建项目

1. 打开 DevEco Studio，选择 File > New > Create Project
2. 选择 "Empty Ability" 模板
3. 配置项目信息：
   - Bundle Name: 自定义（如 com.example.myapp）
   - Compatible SDK: ≥ 5.0.5(17)
   - Target SDK: ≥ 6.0.0(20)
4. 完成创建

## 3. 申请权限

应用在使用 Ads Kit 能力前，需要声明对应权限。

### 所需权限

| 权限名 | 类型 | 说明 |
| ------ | ---- | ---- |
| `ohos.permission.INTERNET` | system_grant | 用于请求和展示广告、回传竞价结果 |
| `ohos.permission.APP_TRACKING_CONSENT` | user_grant | 用于获取开放匿名设备标识符（OAID），提升广告精准度 |

### module.json5 配置

在 `entry/src/main/module.json5` 中配置所需申请的权限：

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "mainElement": "EntryAbility",
    "deviceTypes": ["phone", "tablet"],
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:ic_launcher",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:ic_launcher",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": ["entity.system.home"],
            "actions": ["action.system.home"]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.APP_TRACKING_CONSENT",
        "reason": "$string:app_tracking_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

> **重要**：`ohos.permission.APP_TRACKING_CONSENT` 是 user_grant 权限，`reason` 和 `usedScene` 标签必填。

### 字符串资源配置

在 `entry/src/main/resources/base/element/string.json` 中添加权限说明文案：

```json
{
  "string": [
    {
      "name": "app_tracking_permission_reason",
      "value": "The app obtains this information to recommend content that you may be interested in."
    }
  ]
}
```

## 4. 导入 Ads Kit 模块

在代码中导入所需的 Ads Kit 模块：

```typescript
// 广告核心模块（所有广告类型都需要）
import { advertising } from '@kit.AdsKit';

// 广告展示组件（按需导入）
import { AutoAdComponent } from '@kit.AdsKit';   // 横幅广告
import { AdComponent } from '@kit.AdsKit';        // 原生/开屏/贴片广告

// OAID 标识符
import { identifier } from '@kit.AdsKit';

// 权限管理（请求 APP_TRACKING_CONSENT 时需要）
import { abilityAccessCtrl, common, PermissionRequestResult } from '@kit.AbilityKit';

// 公共事件管理（激励/插屏广告状态监听需要）
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

// 日志
import { hilog } from '@kit.PerformanceAnalysisKit';
```

## 5. 获取测试广告位ID

在开发调试阶段，使用华为提供的测试广告位ID即可测试广告功能，无需申请正式广告位。

| 广告类型 | 测试广告位ID | 说明 |
| -------- | ------------ | ---- |
| 开屏 | g3tl51sqih | 半屏开屏（图片） |
| 开屏 | r145sz31dp | 全屏开屏（视频） |
| 原生 | h8asowxwhq | 大图 |
| 原生 | k94abyn2z4 | 小图 |
| 原生 | o7dj7qsbvy | 三图 |
| 原生 | s7moc0jc6m | 视频 |
| 激励 | j14rx3xtac | 图片 |
| 激励 | j2mh81xmqs | 视频 |
| 横幅 | h5xkz3mbr2 | 图片 19:3 |
| 横幅 | f9enfij16h | 图片 19:3 |
| 横幅 | u8fqe1ru81 | 图片 5:2 |
| 插屏 | p540739a8w | 图片 |
| 插屏 | v1rknehtfa | 视频 |
| 贴片 | o2e960bnfz | 视频 |

> 测试广告位ID仅用于功能调试，不可用于广告变现。正式发布前需在 [鲸鸿动能媒体服务平台](https://developer.huawei.com/consumer/cn/service/ads/publisher/html/index.html?lang=zh) 申请正式广告位ID。

## 6. 申请正式广告位ID

1. 进入 [流量变现官网](https://developer.huawei.com/consumer/cn/monetize)
2. 点击"开始变现"
3. 登录 [鲸鸿动能媒体服务平台](https://developer.huawei.com/consumer/cn/service/ads/publisher/html/index.html?lang=zh)
4. 申请正式广告位ID（参见 [展示位创建](https://developer.huawei.com/consumer/cn/doc/monetize/zhanshiweichuangjian-0000001132700049)）
5. 在代码中将测试广告位ID替换为正式广告位ID

## 7. 关键注意事项

- 使用测试广告位时，**必须先获取OAID信息**，否则无法获取到测试广告
- `ohos.permission.APP_TRACKING_CONSENT` 需要在运行时动态申请，用户可能拒绝
- 激励广告和插屏广告必须通过公共事件订阅监听广告状态，需设置 `publisherBundleName: 'com.huawei.hms.adsservice'` 以防止接收到伪造事件
- 开屏广告建议设置超时处理（推荐1秒），超时后跳转到应用首页
- 贴片广告需在 `AdOptions` 中设置 `totalDuration`（广告展示时长）
