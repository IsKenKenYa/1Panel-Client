---
name: hmos-appgallery-kit-productview-loadproduct
description: 展示应用详情页面，支持loadProduct接口、Deep Linking和App Linking方式拉起应用市场，应用内推荐使用loadProduct接口，Web页面推荐使用App Linking方式，适用于应用推荐、下载安装场景
---

# 展示应用详情页面技能

## 功能描述

本技能用于在应用内或Web页面中展示应用市场应用详情页面，帮助用户快速下载和安装应用。提供三种实现方式：

1. **loadProduct接口**：应用内推荐方式，直接调用应用市场服务接口，体验更流畅
2. **Deep Linking方式**：通过URI scheme拉起应用市场，适用于跨应用跳转
3. **App Linking方式**：Web页面推荐方式，支持在浏览器中拉起应用市场

## 使用场景

### 触发词
- "展示应用详情页"
- "打开应用详情"
- "loadProduct"
- "拉起应用市场"
- "应用下载页面"
- "AppGallery详情页"

### 能做
- 在应用内通过loadProduct接口展示应用详情页
- 通过Deep Linking方式拉起应用市场应用详情页
- 通过App Linking方式在Web页面拉起应用市场
- 传递归因来源数据（广告曝光数据）
- 监听应用详情页的打开、关闭等状态变化

### 绝不做
- 不支持在模拟器上使用（仅支持真机调试）
- 不支持设备类型：Phone、Tablet、PC/2in1、TV以外的设备（6.0.2(22)版本开始支持TV）
- 不处理应用安装后的业务逻辑
- 不提供应用内支付功能

### 补充
- 应用市场推荐服务不支持模拟器，请使用真机调试
- 支持设备类型：Phone、Tablet、PC/2in1，从6.0.2(22)版本开始支持TV设备
- 应用内打开应用市场推荐使用loadProduct方式
- Web页面打开应用市场推荐使用App Linking方式

## 调用规范和规则

### 输入约束
- 应用包名（bundleName）：必填，字符串类型，长度不超过64个字符
- 归因数据（skExposure）：可选，包含广告曝光数据
- 归因角色ID（adTechId）：长度固定为8个字符
- 营销任务ID（campaignId）：长度不超过9个字符（6.0.2(22)开始）
- 应用ID（destinationId）：长度不超过64个字符
- 归因监测平台ID（mmpIds）：最多2个，每个固定8个字符
- 业务信息（serviceTag）：长度不超过32个字符
- 随机数（nonce）：长度固定为32个字符
- 时间戳（timestamp）：Unix时间戳，单位毫秒
- 签名值（signature）：长度不超过800个字符

### 执行约束
- 最大耗时：网络请求超时时间建议设置为10秒
- API调用频次：无明确限制
- 必须在Stage模型下使用
- 必须在真机上调试

### 内容约束
- 禁止使用模拟器测试
- 禁止传递空的应用包名
- 禁止传递无效的归因数据
- 时间戳偏差不超过10分钟

### 降级约束
- 网络失败：提示用户检查网络连接
- 应用市场未安装：引导用户安装应用市场
- 权限不足：提示用户授予权限
- 设备不支持：提示用户设备不兼容

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认运行环境为真机设备（不支持模拟器）
2. 确认设备类型为Phone、Tablet、PC/2in1或TV（6.0.2(22)及以上版本）
3. 确认已安装应用市场应用
4. 准备要展示详情页的应用包名

**参数准备**：
```typescript
import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 准备应用包名
const bundleName: string = 'com.huawei.hmsapp.books';

// 准备归因数据（可选）
const exposureData: productViewManager.SKExposure = {
  adTechId: '20****e8',
  campaignId: '123456',
  destinationId: '10******',
  mmpIds: ['2f****5', '2f7***5'],
  serviceTag: '123***2',
  nonce: '123***2',
  timestamp: 1705536488,
  signature: 'MEQCIEQlmZ****zKBSE8QnhLTIHZZZ****ZpRqRxHss65Ko****JgJKjdrWdkL****juEx2RmFS7da****ZRVZ8RyMyUXg=='
};

// 准备Want参数
const wantParam: Want = {
  parameters: {
    bundleName: bundleName,
    skExposure: exposureData // 可选
  }
};
```

### 步骤2：调用loadProduct接口

**示例代码**：
```typescript
@Entry
@Component
struct LoadProductView {
  @State message: string = '拉起应用市场详情页';

  build() {
    Row() {
      Column() {
        Button(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            try {
              // 获取UIAbility上下文
              const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

              // 构造Want参数
              const wantParam: Want = {
                parameters: {
                  bundleName: 'com.huawei.hmsapp.books', // 必填：应用包名
                  skExposure: exposureData // 可选：归因数据
                }
              };

              // 构造回调函数
              const callback: productViewManager.ProductViewCallback = {
                onError: (error: BusinessError) => {
                  hilog.error(0, 'TAG', 
                    `loadProduct onError.code is ${error.code}, message is ${error.message}`);
                },
                onAppear: () => {
                  hilog.info(0, 'TAG', `loadProduct onAppear.`);
                },
                onDisappear: () => {
                  hilog.info(0, 'TAG', `loadProduct onDisappear.`);
                }
              };

              // 调用loadProduct接口
              productViewManager.loadProduct(uiContext, wantParam, callback);
            } catch (err) {
              hilog.error(0, 'TAG', `loadProduct failed.code is ${err.code}, message is ${err.message}`);
            }
          })
          .width('100%')
      }
      .height('100%')
    }
  }
}
```

### 步骤3：使用Deep Linking方式

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';

// 拉起应用市场对应的应用详情页面
function startAppGalleryDetailAbility(context: common.UIAbilityContext, bundleName: string): void {
  let want: Want = {
    action: 'ohos.want.action.appdetail', // 隐式指定action
    uri: 'store://appgallery.huawei.com/app/detail?id=' + bundleName, // bundleName为需要打开应用详情的应用包名
  };
  
  context.startAbility(want).then(() => {
    hilog.info(0x0001, 'TAG', "Succeeded in starting Ability successfully.");
  }).catch((error: BusinessError) => {
    hilog.error(0x0001, 'TAG', `Failed to startAbility.Code: ${error.code}, message is ${error.message}`);
  });
}

@Entry
@Component
struct StartAppGalleryDetailAbilityView {
  @State message: string = '拉起应用市场详情页';

  build() {
    Row() {
      Column() {
        Button(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            const context: common.UIAbilityContext = 
              this.getUIContext().getHostContext() as common.UIAbilityContext;
            const bundleName = 'com.huawei.hmsapp.books'; // 应用包名
            startAppGalleryDetailAbility(context, bundleName);
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

### 步骤4：使用App Linking方式

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  build() {
    Button('start app linking', { type: ButtonType.Capsule, stateEffect: true })
      .width('87%')
      .height('5%')
      .margin({ bottom: '12vp' })
      .onClick(() => {
        let context: common.UIAbilityContext = 
          this.getUIContext().getHostContext() as common.UIAbilityContext;
        let bundleName: string = 'com.huawei.hmsapp.books'; // 应用包名
        let link: string = 'https://appgallery.huawei.com/app/detail?id=' + bundleName;
        
        // 以App Linking优先的方式在应用市场打开指定包名的应用详情页
        context.openLink(link, { appLinkingOnly: false })
          .then(() => {
            hilog.info(0x0001, 'TAG', 'openlink success.');
          })
          .catch((error: BusinessError) => {
            hilog.error(0x0001, 'TAG', 
              `openlink failed. Code: ${error.code}, message is ${error.message}`);
          });
      })
  }
}
```

### 步骤5：错误处理

```typescript
try {
  productViewManager.loadProduct(uiContext, wantParam, callback);
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      hilog.error(0, 'TAG', 'Parameter error. Please check input parameters.');
      break;
    case 1011:
      hilog.error(0, 'TAG', 'Failed to launch or switch to foreground.');
      break;
    case 1012:
      hilog.error(0, 'TAG', 'Failed to switch to background.');
      break;
    case 1013:
      hilog.error(0, 'TAG', 'Failed to destroy.');
      break;
    default:
      hilog.error(0, 'TAG', `Unknown error: code ${err.code}, message ${err.message}`);
  }
}
```

### 步骤6：降级处理

```typescript
async function openAppDetailWithFallback(context: common.UIAbilityContext, bundleName: string): Promise<void> {
  try {
    // 首选方式：使用loadProduct
    const wantParam: Want = {
      parameters: {
        bundleName: bundleName
      }
    };
    
    productViewManager.loadProduct(context, wantParam, {
      onError: async (error: BusinessError) => {
        hilog.error(0, 'TAG', `loadProduct failed: ${error.code}`);
        
        // 降级方案1：尝试Deep Linking
        try {
          const want: Want = {
            action: 'ohos.want.action.appdetail',
            uri: 'store://appgallery.huawei.com/app/detail?id=' + bundleName,
          };
          await context.startAbility(want);
        } catch (deepLinkError) {
          // 降级方案2：尝试App Linking
          try {
            const link = 'https://appgallery.huawei.com/app/detail?id=' + bundleName;
            await context.openLink(link, { appLinkingOnly: false });
          } catch (appLinkError) {
            // 最终降级：提示用户手动搜索
            hilog.error(0, 'TAG', 'All methods failed. Please search the app manually.');
          }
        }
      }
    });
  } catch (error) {
    hilog.error(0, 'TAG', 'Failed to open app detail page.');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查输入参数是否正确，特别是bundleName参数 |
| 1011 | 拉起/切前台失败 | 检查应用市场是否已安装，网络是否正常 |
| 1012 | 切后台失败 | 系统内部错误，建议重试或使用降级方案 |
| 1013 | 销毁失败 | 系统内部错误，建议重试或使用降级方案 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": ">=4.1.0(11)",
    "@kit.AbilityKit": ">=4.1.0(11)",
    "@kit.BasicServicesKit": ">=4.1.0(11)",
    "@kit.PerformanceAnalysisKit": ">=4.1.0(11)"
  }
}
```

### 环境要求
- HarmonyOS API版本：>= 4.1.0(11)
- 设备类型：Phone、Tablet、PC/2in1，从6.0.2(22)版本开始支持TV
- 运行环境：真机（不支持模拟器）
- 开发模型：Stage模型

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.AppGalleryKit'
```
**解决方法**：
- 确保HarmonyOS API版本 >= 4.1.0(11)
- 检查oh-package.json5中是否正确配置了依赖

**问题2：类型错误**
```
Error: Property 'getHostContext' does not exist on type 'UIAbilityContext'
```
**解决方法**：
- 确保使用正确的上下文获取方式
- 在组件中使用`this.getUIContext().getHostContext()`

**问题3：设备不支持**
```
Error: 401 Parameter error
```
**解决方法**：
- 确认设备类型是否支持
- 在模拟器上运行会报错，请使用真机调试

## 常见问题与解决方法

### Q1：在模拟器上运行报错"无法获取内容"
**原因**：应用市场推荐服务不支持模拟器
**解决方法**：
- 使用真机进行调试
- 确认设备类型为Phone、Tablet、PC/2in1或TV（6.0.2(22)及以上版本）

### Q2：loadProduct调用后无响应
**原因**：可能是应用市场未安装或网络问题
**解决方法**：
- 检查设备是否安装了应用市场
- 检查网络连接是否正常
- 查看错误回调中的具体错误码

### Q3：归因数据传递失败
**原因**：归因数据格式不正确或签名验证失败
**解决方法**：
- 检查归因数据各字段是否符合格式要求
- 确认时间戳偏差不超过10分钟
- 验证签名值是否正确计算

### Q4：Deep Linking方式在Web页面不工作
**原因**：Web页面不支持URI scheme方式
**解决方法**：
- Web页面推荐使用App Linking方式
- 使用https://appgallery.huawei.com/app/detail?id=bundleName格式

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "method": "loadProduct | DeepLinking | AppLinking",
  "bundleName": "com.huawei.hmsapp.books",
  "message": "应用详情页已成功打开",
  "apiUsed": [
    "productViewManager.loadProduct",
    "UIAbilityContext.startAbility",
    "UIAbilityContext.openLink"
  ],
  "callbacks": {
    "onAppear": "详情页成功打开",
    "onDisappear": "详情页已关闭"
  }
}
```

## 参考文档

- [API开发指南 - 展示应用详情页面](references/appgallery-productview-loadproduct-guide.md)
- [API参考说明 - productViewManager](references/store-productviewmanager.md)

## 完整示例代码

- [loadProduct接口示例](assets/loadproduct_example.ets)
- [Deep Linking示例](assets/deep_linking_example.ets)
- [App Linking示例](assets/app_linking_example.ets)
- [降级处理示例](assets/fallback_example.ets)

## 测试用例

### 正向测试用例
- [基本功能测试](tests/test_positive.py)：测试loadProduct接口正常调用
- [Deep Linking测试](tests/test_positive.py)：测试Deep Linking方式拉起应用市场
- [App Linking测试](tests/test_positive.py)：测试App Linking方式拉起应用市场

### 边界测试用例
- [参数边界测试](tests/test_boundary.py)：测试参数长度边界值
- [归因数据测试](tests/test_boundary.py)：测试归因数据各字段边界值

### 异常测试用例
- [无效包名测试](tests/test_exception.py)：测试传递无效的应用包名
- [网络异常测试](tests/test_exception.py)：测试网络异常情况下的处理
- [设备不支持测试](tests/test_exception.py)：测试在不支持的设备上调用接口