---
name: hmos-share-kit-share-utd-link
description: 分享链接到目标应用或浏览器,支持App Linking和普通链接两种方式,缩略图限制32KB以下,适用于应用间跳转、网页链接分享场景
---

# 分享链接技能

## 功能描述

本技能提供系统分享链接功能,支持两种分享方式:
- **App Linking分享**: 使用App Linking分享应用,目标设备接收后可直达应用,实现应用间跳转
- **普通链接分享**: 分享网页链接,目标设备接收时通过浏览器直接打开链接

分享面板会根据屏幕大小和设备类型自动选择显示方式(模态/弹窗/悬浮窗)。开发者可以配置缩略图、标题、描述等元数据增强分享展示效果。

## 使用场景

### 触发词
- "分享链接"
- "分享App Linking"
- "系统分享链接"
- "分享网页链接"
- "分享URL"
- "链接直达应用"

### 能做
- 分享App Linking链接直达目标应用
- 分享普通网页链接到浏览器
- 配置分享数据的标题、描述、缩略图
- 添加多条分享数据记录
- 接收分享链接并处理跳转
- 监听分享面板关闭事件
- 监听分享完成事件

### 绝不做
- 分享文件类型数据(应使用文件分享技能)
- 分享图片、视频等媒体类型(应使用相应媒体分享技能)
- 分享纯文本内容(应使用文本分享技能)
- 直接修改Want数据结构
- 超过500条分享数据记录
- 缩略图超过32KB大小

### 补充
- App Linking分享需要提前开通App Linking服务并完成相关配置
- 缩略图建议传入应用图标,不传则显示默认html图标
- 分享App Linking时需要生成应用图标缩略图并适当压缩质量
- 目标应用需要配置skills关联的网站域名
- 数据总大小不超过IPC传输上限200KB

## 调用规范和规则

### 输入约束
- **缩略图大小**: 最大32KB,推荐使用ImagePacker压缩质量
- **链接格式**: 必须是有效的URL格式(App Linking或普通URL)
- **数据记录数量**: 最大500条
- **数据总大小**: 最大200KB(包含want数据本身字段)
- **字符长度**: title和description建议简洁明了

### 执行约束
- **最大耗时**: 分享面板显示操作建议10秒内完成
- **异步调用**: ShareController.show()使用Promise异步回调
- **API版本**: systemShare模块起始版本4.1.0(11)
- **模型约束**: 仅可在Stage模型下使用

### 内容约束
- **禁止生成**: 禁止生成超过500条分享数据记录
- **禁止使用高危函数**: 禁止直接修改Want数据结构
- **禁止操作**: 禁止分享非链接类型数据(HYPERLINK类型)
- **必须配置**: 至少配置一条有效的分享数据信息

### 降级约束
- **缩略图过大**: 使用ImagePacker压缩图片质量,推荐quality: 30
- **链接无效**: 提示用户检查链接格式
- **分享失败**: 捕获错误并记录日志,提示用户重新分享
- **App Linking未开通**: 提示开发者先开通App Linking服务并调试
- **权限不足**: 检查应用权限配置

## 调用流程和步骤

### 场景一: 分享App Linking直达应用

#### 步骤1: 开通App Linking服务

**前置校验**:
1. 确认已开通App Linking服务
2. 确认App Linking已完成调试
3. 确认应用配置文件已添加skills关联配置

**参考文档**: [调试App Linking](https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-applinking-debug-0000001059139667)

#### 步骤2: 配置应用关联域名

在应用配置文件(src/main/module.json5)的skills配置中增加关联配置:

```json
{
  "module": {
    "abilities": [
      {
        "skills": [
          {
            "actions": ["ohos.want.action.viewData"],
            "entities": ["entity.system.browsable"],
            "uris": [
              {
                "scheme": "https",
                "domain": "your-domain.com"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

**参考文档**: [声明应用关联的网站域名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startupapp)

#### 步骤3: 生成应用图标缩略图

```typescript
import { image } from '@kit.ImageKit';

async function generateThumbnail(context: Context): Promise<Uint8Array> {
  let thumbnailPath = context.filesDir + '/exampleImage.jpg';
  let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
  let imagePacker: image.ImagePacker = image.createImagePacker();
  
  let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
    format: 'image/jpeg',
    quality: 30
  });
  
  return new Uint8Array(buffer);
}
```

#### 步骤4: 构造分享数据并显示分享面板

```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function shareAppLinking(uiContext: UIContext) {
  let contextFaker: Context = uiContext.getHostContext() as Context;
  let thumbnail = await generateThumbnail(contextFaker);
  
  let shareData: systemShare.SharedData = new systemShare.SharedData({
    utd: utd.UniformDataType.HYPERLINK,
    content: 'https://sharekitdemo.drcn.agconnect.link/ZB3p',
    title: '应用名称',
    description: '应用描述',
    thumbnail: thumbnail
  });
  
  let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
  let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
  
  controller.show(context, {
    previewMode: systemShare.SharePreviewMode.DEFAULT,
    selectionMode: systemShare.SelectionMode.SINGLE
  }).then(() => {
    console.info('ShareController show success.');
  }).catch((error: BusinessError) => {
    console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
  });
}
```

#### 步骤5: 目标应用处理App Linking

```typescript
import { common, OpenLinkOptions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

function handleAppLinking(uiContext: UIContext, link: string) {
  let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
  let openLinkOptions: OpenLinkOptions = {
    appLinkingOnly: false
  };
  
  context.openLink(link, openLinkOptions)
    .then(() => {
      console.info('openlink success.');
    })
    .catch((error: BusinessError) => {
      console.error(`openlink failed. code: ${error.code}, message: ${error.message}`);
    });
}
```

**参考文档**: [拉起方实现跳转指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startupapp)

### 场景二: 分享普通链接直达浏览器

#### 步骤1: 导入相关模块

```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

#### 步骤2: 构造分享数据

```typescript
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'https://www.vmall.com/index.html?cid=128688',
  title: '华为商城',
  description: '华为手机'
});
```

#### 步骤3: 额外增加一条数据(可选)

```typescript
shareData.addRecord({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'https://www.vmall.com/index.html?cid=128688',
  title: '测试链接',
  description: '测试描述'
});
```

#### 步骤4: 启动分享面板

```typescript
let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
let uiContext: UIContext = this.getUIContext();
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

controller.show(context, {
  selectionMode: systemShare.SelectionMode.SINGLE,
  previewMode: systemShare.SharePreviewMode.DEFAULT
}).then(() => {
  console.info('ShareController show success.');
}).catch((error: BusinessError) => {
  console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
});
```

### 错误处理

```typescript
try {
  await controller.show(context, options);
} catch (error) {
  let businessError: BusinessError = error as BusinessError;
  
  switch (businessError.code) {
    case 1003702001:
      console.error('数据记录类型不支持,请检查链接格式');
      break;
    case 1003702002:
      console.error('数据量超过上限200KB,请压缩缩略图或减少文本内容');
      break;
    case 401:
      console.error('参数错误,请检查参数类型和必填项');
      break;
    default:
      console.error(`未知错误: code ${businessError.code}, message ${businessError.message}`);
  }
}
```

### 降级处理

```typescript
async function shareWithFallback(uiContext: UIContext, link: string) {
  try {
    let shareData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: link
    });
    
    let controller = new systemShare.ShareController(shareData);
    let context = uiContext.getHostContext() as common.UIAbilityContext;
    
    await controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    });
  } catch (error) {
    console.warn('分享面板显示失败,使用复制到剪贴板降级方案');
    
    try {
      let pasteboard = pasteboard.getSystemPasteboard();
      await pasteboard.addData(pasteboard.createPlainTextData(link));
      console.info('链接已复制到剪贴板');
    } catch (pasteError) {
      console.error('降级方案失败,请手动复制链接');
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查参数类型和必填项是否正确 |
| 1003700001 | 数据记录超过上限 | 限制分享数据记录数量不超过500条 |
| 1003702001 | 数据记录类型不支持 | 检查链接格式是否正确,确认utd类型为HYPERLINK |
| 1003702002 | IPC数据量超过上限 | 压缩缩略图大小,减少文本内容长度 |
| 1003703001 | 数据解析失败 | 目标应用中止分享数据处理,提示用户分享数据错误 |

**详细错误码文档**: [分享服务错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-error-code)

## 编译和修复问题

### 依赖声明

```json
{
  "dependencies": {
    "@kit.ShareKit": "API 11+",
    "@kit.ArkData": "API 10+",
    "@kit.AbilityKit": "API 9+",
    "@kit.ImageKit": "API 9+",
    "@kit.BasicServicesKit": "API 9+"
  }
}
```

### 环境要求
- **HarmonyOS API**: 最低版本11(systemShare模块)
- **开发模型**: 仅支持Stage模型
- **设备类型**: 支持手机、平板、2in1设备
- **App Linking**: 需要开通App Gallery Connect服务

### 常见编译问题

**问题1: 导入systemShare模块失败**
```
Module '@kit.ShareKit' has no exported member 'systemShare'
```
**解决方法**: 确认HarmonyOS API版本不低于11,systemShare模块从API 11开始支持

**问题2: SharedData构造失败**
```
Argument of type '{ utd: string; content: string }' is not assignable to parameter of type 'SharedRecord'
```
**解决方法**: 检查utd字段是否使用了utd.UniformDataType枚举值,确保content字段不为空

**问题3: 缩略图过大导致分享失败**
```
ShareController show error. code: 1003702002, message: IPC data is oversized
```
**解决方法**: 使用ImagePacker压缩缩略图质量,推荐设置quality为30

**问题4: App Linking无法跳转**
```
openlink failed. code: xxx, message: xxx
```
**解决方法**: 确认App Linking服务已开通并调试,检查应用配置文件的skills关联配置是否正确

## 常见问题与解决方法

### Q1: 分享面板显示失败怎么办?

**原因**: 可能是参数错误、数据量超限或权限不足

**解决方法**:
- 检查SharedData构造参数是否正确
- 确认缩略图大小不超过32KB
- 检查应用权限配置
- 查看错误码并根据提示处理

### Q2: 如何添加多条分享数据记录?

**原因**: 需要分享多个链接选项供用户选择

**解决方法**:
```typescript
let shareData = new systemShare.SharedData({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'link1'
});

shareData.addRecord({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'link2',
  title: '链接2'
});
```

注意: 最大支持500条数据记录

### Q3: 如何监听分享完成事件?

**原因**: 需要统计用户分享渠道或执行后续操作

**解决方法**:
```typescript
controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
  console.info('分享完成,渠道:', result.targetAbilityInfo.name);
});
```

注意: 此接口从API version 18开始支持,TV设备无效果

### Q4: 缩略图如何生成和压缩?

**原因**: 缩略图过大可能导致分享失败

**解决方法**:
- 使用ImagePacker.packToData压缩图片
- 推荐设置quality为30
- 只支持image/jpeg、image/webp、image/png格式
- 缩略图大小限制32KB以下

### Q5: App Linking分享需要哪些前置配置?

**原因**: App Linking需要开通服务和配置应用关联

**解决方法**:
- 开通App Gallery Connect的App Linking服务
- 完成App Linking调试
- 在module.json5中配置skills关联的网站域名
- 参考文档: [声明应用关联的网站域名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startupapp)

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "shareType": "App Linking 或 普通链接",
  "linkContent": "分享的链接地址",
  "thumbnailSize": "缩略图大小(KB)",
  "recordCount": "分享数据记录数量",
  "apiUsed": [
    "systemShare.SharedData",
    "systemShare.ShareController",
    "utd.UniformDataType.HYPERLINK",
    "image.ImagePacker",
    "context.openLink"
  ]
}
```

## 参考文档

- [分享链接开发指南](references/share-utd-link-guide.md)
- [systemShare API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [UniformDataType API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-uniformtypedescriptor)
- [分享服务错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-error-code)
- [App Linking调试](https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-applinking-debug-0000001059139667)
- [使用App Linking实现应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startup)
- [声明应用关联的网站域名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startupapp)

## 完整示例代码

- [分享App Linking示例](assets/share-applinking-example.ets)
- [分享普通链接示例](assets/share-link-example.ets)
- [完整UI示例](assets/share-link-ui.ets)
- [缩略图生成示例](assets/generate-thumbnail.ets)

## 测试用例

### 正向测试用例
- [分享App Linking链接](tests/test_applinking_share.ets): 测试App Linking链接分享功能
- [分享普通网页链接](tests/test_normal_link_share.ets): 测试普通链接分享功能
- [添加多条分享数据](tests/test_multiple_records.ets): 测试添加多条分享数据记录
- [监听分享事件](tests/test_share_events.ets): 测试监听分享面板关闭和分享完成事件

### 边界测试用例
- [最大500条数据记录](tests/test_max_records.ets): 测试最大数据记录数量限制
- [最大32KB缩略图](tests/test_max_thumbnail.ets): 测试最大缩略图大小限制
- [单选和批量模式](tests/test_selection_mode.ets): 测试单选和批量分享模式

### 异常测试用例
- [无效链接格式](tests/test_invalid_link.ets): 测试无效链接格式错误处理
- [缩略图超限](tests/test_oversized_thumbnail.ets): 测试缩略图超过32KB的错误处理
- [数据量超限](tests/test_data_overflow.ets): 测试数据总量超过200KB的错误处理
- [权限不足](tests/test_permission_denied.ets): 测试权限不足的错误处理