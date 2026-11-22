---
name: hmos-share-kit-app-trust-list
description: 配置分享目标应用白名单，限制企业应用仅分享到指定应用列表，支持最多50个应用标识符，适用于企业数据安全管控场景
---

# 配置目标应用名单技能

## 功能描述

该功能仅对企业应用开放，从6.0.1(21)版本开始支持。允许宿主应用配置目标应用名单列表（最多支持50个应用），配置成功后，仅名单内的目标应用可出现在系统分享面板的分享推荐区和分享方式区。该功能通过配置`appLaunchTrustInfo`参数，指定目标应用的`appIdentifier`列表，实现企业内部数据分享的安全管控。

**核心能力**：
- 配置分享目标应用白名单
- 限制企业数据仅分享到信任应用
- 控制分享面板显示的目标应用

**适用场景**：
- 企业内部应用数据分享管控
- 企业机密资料分享限制
- 集团应用间数据共享管理

**API版本要求**：6.0.1(21)及以上

## 使用场景

### 触发词
- "配置分享目标应用白名单"
- "限制分享应用范围"
- "企业应用分享管控"
- "配置appLaunchTrustInfo"
- "分享应用信任列表"

### 能做
- 配置分享目标应用的信任列表
- 限制企业数据仅分享到指定的应用
- 控制系统分享面板显示的目标应用
- 实现企业内部数据分享的安全管控
- 支持最多50个应用的信任列表配置

### 绝不做
- 不适用于非企业应用（权限受限开放）
- 不支持动态修改信任列表（需重新启动分享面板）
- 不支持配置超过50个应用标识符
- 不替代目标应用自身的权限校验
- 不处理目标应用不存在或未安装的情况

### 补充
- 该功能需要申请受限开放权限`ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST`
- 仅支持企业应用，申请权限时需提供企业应用信息和管控场景说明
- 配置的应用标识符为`appIdentifier`字段，可通过BundleInfo获取
- 过多的应用标识符可能影响分享面板性能，建议合理配置

## 调用规范和规则

### 输入约束
- **应用标识符列表**：数组类型，最多50个有效的`appIdentifier`字符串
- **数据记录**：至少配置一条有效的分享数据信息（utd和content/uri）
- **权限要求**：必须申请并获取`ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST`权限
- **应用类型**：仅限企业应用，需通过AGC审核

### 执行约束
- **权限校验**：启动分享面板前必须完成权限申请和配置
- **参数校验**：`appLaunchTrustInfo`数组元素不得超过50个，超出部分不生效
- **分享面板显示**：调用`controller.show()`时必须传入配置好的options
- **数据有效性**：SharedData必须包含有效数据记录，否则分享面板无法正常显示

### 内容约束
- **禁止伪造标识符**：必须使用真实有效的应用`appIdentifier`
- **禁止跨企业配置**：信任列表应限于企业内部应用
- **禁止滥用权限**：仅用于企业数据安全管控，不得用于恶意限制用户选择
- **禁止遗漏权限声明**：必须在module.json5中声明权限

### 降级约束
- **权限申请失败**：提示用户权限申请未通过，降级为普通分享模式（不限制目标应用）
- **配置参数错误**：参数校验失败时，记录错误日志并降级为普通分享模式
- **目标应用不存在**：信任列表中的应用未安装时，该应用不会出现在分享面板，但不影响其他应用
- **API版本不支持**：低于6.0.1(21)版本时，提示用户升级系统或降级为普通分享模式

## 调用流程和步骤

### 步骤1：申请受限权限

**前置准备**：
1. 确认应用为企业应用，符合受限权限使用场景
2. 查阅[受限开放权限列表](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/restricted-permissions)，确认`ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST`权限要求
3. 准备权限申请材料，包括企业应用信息和管控场景说明

**申请权限步骤**：
1. 登录[AGC（AppGallery Connect）](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 申请发布Profile文件，在"添加Profile页面"申请使用`ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST`权限
3. 在权限申请页面填写企业应用信息和管控场景说明（例如：用于XXX集团应用管控内部资料仅限于企业内部分享）
4. 等待审核结果（审核时长请查询受限开放权限列表）

**权限配置示例**：
在`module.json5`配置文件的`requestPermissions`标签中声明权限：

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST",
        "reason": "$string:permission_reason_set_system_share_app_launch_trust_list"
      }
    ]
  }
}
```

**权限原因字符串配置**：
在`string.json`文件中配置权限使用理由：
```json
{
  "string": [
    {
      "name": "permission_reason_set_system_share_app_launch_trust_list",
      "value": "用于企业应用管控内部资料仅限于企业内部分享"
    }
  ]
}
```

### 步骤2：获取目标应用标识符

**获取appIdentifier的方法**：

方法1：通过BundleInfo获取目标应用的appIdentifier
```typescript
import { bundleManager } from '@kit.AbilityKit';

async function getAppIdentifier(bundleName: string): Promise<string> {
  try {
    const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    // 从BundleInfo中获取appIdentifier
    return bundleInfo.appIdentifier;
  } catch (error) {
    console.error('Failed to get app identifier:', error);
    return '';
  }
}
```

方法2：通过已知的appIdentifier配置（企业内部应用已知标识符）
```typescript
// 企业内部应用信任列表（示例值）
const trustAppList: string[] = [
  '5765880207853060000',  // 企业内部应用1的appIdentifier
  '1171817433862770000',  // 企业内部应用2的appIdentifier
  // ... 最多50个
];
```

**参数说明**：
- `appIdentifier`：应用唯一标识符，在应用安装后由系统分配
- 可通过BundleInfo的`appIdentifier`字段获取
- 建议提前获取并配置在应用配置文件中

### 步骤3：构造分享数据并配置信任列表

**代码示例**：
```typescript
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

@Component
export struct ShareAppTrustInfo {
  build() {
    Button('分享到企业应用')
      .onClick(() => {
        this.shareToTrustedApps();
      })
  }

  private async shareToTrustedApps() {
    try {
      // 步骤3.1：构造分享数据
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.PLAIN_TEXT,
        content: '企业内部机密资料'
      });
      
      // 步骤3.2：创建分享控制器
      const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      
      // 步骤3.3：获取UI上下文
      const uiContext: UIContext = this.getUIContext();
      const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      
      // 步骤3.4：配置目标应用信任列表
      const trustAppList: string[] = [
        '5765880207853060000',  // 企业内部应用1
        '1171817433862770000',  // 企业内部应用2
        // 注意：最多50个应用标识符
      ];
      
      // 步骤3.5：显示分享面板（配置信任列表）
      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE,
        appLaunchTrustInfo: trustAppList  // 配置目标应用名单
      });
      
      console.info('Share panel displayed with trust list');
    } catch (error) {
      console.error('Failed to show share panel:', error);
      this.handleShareError(error);
    }
  }
  
  private handleShareError(error: Error) {
    // 错误处理逻辑
    console.error('Share error:', error.message);
  }
}
```

### 步骤4：错误处理

**错误处理代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

async function shareWithTrustList(context: common.UIAbilityContext, uiContext: UIContext) {
  try {
    const shareData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: '企业内部数据'
    });
    
    const controller = new systemShare.ShareController(shareData);
    
    await controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE,
      appLaunchTrustInfo: ['5765880207853060000']
    });
  } catch (error) {
    const businessError = error as BusinessError;
    switch (businessError.code) {
      case 401:
        console.error('参数错误，请检查传入的参数');
        break;
      case 1003702001:
        console.error('记录类型不支持');
        break;
      case 1003702002:
        console.error('IPC数据过大，请减少分享数据大小');
        break;
      default:
        console.error('分享失败:', businessError.message);
        // 降级处理：使用普通分享模式
        fallbackToNormalShare(context, uiContext);
    }
  }
}

// 降级方案：使用普通分享模式（不限制目标应用）
async function fallbackToNormalShare(context: common.UIAbilityContext, uiContext: UIContext) {
  try {
    const shareData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: '企业内部数据'
    });
    
    const controller = new systemShare.ShareController(shareData);
    
    // 不配置appLaunchTrustInfo，使用普通分享模式
    await controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    });
    
    console.warn('已降级为普通分享模式');
  } catch (error) {
    console.error('降级分享也失败:', error);
  }
}
```

### 步骤5：监听分享结果（可选）

**监听分享完成事件**：
```typescript
const controller = new systemShare.ShareController(shareData);

// 注册分享完成事件监听
controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
  console.info('分享完成，目标应用:', result.targetAbilityInfo.name);
  
  // 可以在这里记录分享日志或进行数据统计
  if (result.targetAbilityInfo.name.includes('企业内部应用标识')) {
    console.info('成功分享到企业内部应用');
  }
});

// 显示分享面板
await controller.show(context, {
  previewMode: systemShare.SharePreviewMode.DEFAULT,
  selectionMode: systemShare.SelectionMode.SINGLE,
  appLaunchTrustInfo: trustAppList
});

// 注册分享面板关闭事件监听
controller.on('dismiss', () => {
  console.info('分享面板已关闭');
});
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查传入的参数类型和格式是否正确，确保SharedData包含有效数据 |
| 1003702001 | 记录类型不支持 | 检查SharedRecord的utd字段是否为支持的类型，批量模式仅支持FILE类型 |
| 1003702002 | IPC数据过大 | 减少分享数据大小，确保数据总大小不超过IPC传输上限200KB，缩略图不超过32KB |
| 权限申请被驳回 | 未通过AGC审核 | 检查权限申请材料是否符合企业应用场景，重新提交申请并提供详细说明 |
| 应用安装失败 | Profile文件未包含权限 | 确保Profile文件已申请并包含`SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST`权限 |
| 分享面板未限制目标应用 | appLaunchTrustInfo参数未生效 | 检查权限是否正确配置，确保API版本不低于6.0.1(21) |
| 目标应用未出现在分享面板 | 应用未安装或标识符错误 | 确认目标应用已安装，检查appIdentifier是否正确 |
| 信任列表超过50个 | 数组元素超出限制 | 精简信任列表，仅保留必要的应用标识符 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "^版本号",
    "@kit.AbilityKit": "^版本号",
    "@kit.ArkData": "^版本号",
    "@kit.BasicServicesKit": "^版本号"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：6.0.1(21)及以上
- **DevEco Studio**：最新版本
- **编译API版本**：API 21及以上
- **应用类型**：企业应用

### 常见编译问题

**问题1：权限声明错误**
```
Error: Permission ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST is not granted
```
**解决方法**：
1. 确保应用为企业应用
2. 在AGC申请Profile时勾选该权限
3. 在module.json5中正确声明权限
4. 使用DevEco Studio自动签名功能申请权限

**问题2：API版本不匹配**
```
Error: Property 'appLaunchTrustInfo' does not exist on type 'ShareControllerOptions'
```
**解决方法**：
1. 升级HarmonyOS SDK到6.0.1(21)及以上
2. 在build-profile.json5中设置`compileSdkVersion`为API 21及以上
3. 同步项目依赖

**问题3：appIdentifier获取失败**
```
Error: Cannot read property 'appIdentifier' of undefined
```
**解决方法**：
1. 确保应用已正确安装
2. 使用`bundleManager.getBundleInfoForSelf()`获取当前应用信息
3. 检查BundleInfo是否包含`appIdentifier`字段

**问题4：分享面板未限制目标应用**
```
分享面板显示了非信任列表中的应用
```
**解决方法**：
1. 检查权限是否正确配置和授权
2. 确认API版本不低于6.0.1(21)
3. 验证`appLaunchTrustInfo`参数是否正确传递
4. 检查设备是否支持该功能

**问题5：参数类型错误**
```
Type 'string[]' is not assignable to type 'Array<string>'
```
**解决方法**：
1. 确保`appLaunchTrustInfo`为字符串数组类型
2. 检查数组元素是否为有效的字符串
3. 使用类型断言：`appLaunchTrustInfo: appIdentifiers as string[]`

## 常见问题与解决方法

### Q1：如何获取目标应用的appIdentifier？
**原因**：appIdentifier是应用安装后由系统分配的唯一标识符
**解决方法**：
- 方法1：通过`bundleManager.getBundleInfoForSelf()`获取当前应用的appIdentifier
- 方法2：企业内部应用的appIdentifier可以通过应用发布渠道获取
- 方法3：通过设备上的应用管理器查看应用详细信息

### Q2：权限申请被AGC驳回怎么办？
**原因**：应用场景不符合受限权限使用要求
**解决方法**：
1. 检查应用是否为企业应用
2. 完善权限申请说明，详细描述企业数据管控场景
3. 提供企业证明材料
4. 考虑使用替代方案（如普通分享模式+目标应用权限校验）

### Q3：信任列表配置后不生效？
**原因**：可能存在权限、版本或参数配置问题
**解决方法**：
- 检查权限是否正确配置在module.json5中
- 确认Profile文件已申请该权限
- 验证API版本是否不低于6.0.1(21)
- 确认`appLaunchTrustInfo`参数是否正确传递给`controller.show()`方法
- 检查设备是否支持该功能（模拟器可能不支持）

### Q4：能否动态修改信任列表？
**原因**：信任列表在分享面板启动时生效
**解决方法**：
- 信任列表配置后无法动态修改
- 如需修改，需要重新调用`controller.show()`方法
- 建议在配置文件中维护信任列表，便于管理

### Q5：目标应用未安装会怎样？
**原因**：信任列表中的应用可能未安装
**解决方法**：
- 未安装的应用不会出现在分享面板中
- 不影响其他已安装的信任应用显示
- 建议在分享前检查目标应用是否已安装

### Q6：能否用于普通应用？
**原因**：权限受限开放
**解决方法**：
- 该权限仅对企业应用开放
- 普通应用无法申请该权限
- 普通应用可使用标准分享功能，无法限制目标应用

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "sharePanelDisplayed": true,
  "trustListConfigured": true,
  "appCount": 2,
  "apiUsed": [
    "systemShare.SharedData",
    "systemShare.ShareController",
    "controller.show()",
    "bundleManager.getBundleInfoForSelf()"
  ],
  "permissions": [
    "ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST"
  ],
  "apiVersion": "6.0.1(21)"
}
```

## 参考文档

- [配置目标应用名单开发指南](references/share-app-sharing-mode.md)
- [systemShare API参考](references/share-system-share.md)
- [申请使用受限权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions-in-acl)
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)

## 完整示例代码

- [ArkTS完整示例](assets/share-with-trust-list.ets)
- [权限配置示例](assets/module.json5)
- [字符串资源配置](assets/string.json)

## 测试用例

### 正向测试用例
- [企业应用配置信任列表分享](tests/test_positive.ts)：正常场景，企业应用配置信任列表后分享
- [配置单个目标应用](tests/test_positive.ts)：信任列表仅包含一个应用
- [配置最大数量应用](tests/test_positive.ts)：信任列表包含50个应用

### 边界测试用例
- [空信任列表测试](tests/test_boundary.ts)：appLaunchTrustInfo为空数组
- [超过50个应用测试](tests/test_boundary.ts)：appLaunchTrustInfo包含51个应用
- [无效appIdentifier测试](tests/test_boundary.ts)：信任列表包含无效的应用标识符

### 异常测试用例
- [权限未申请测试](tests/test_exception.ts)：未申请权限时调用
- [权限申请被驳回测试](tests/test_exception.ts)：权限申请被AGC驳回
- [API版本不支持测试](tests/test_exception.ts)：低于6.0.1(21)版本调用
- [参数错误测试](tests/test_exception.ts)：传入错误类型的参数
- [目标应用未安装测试](tests/test_exception.ts)：信任列表中的应用未安装