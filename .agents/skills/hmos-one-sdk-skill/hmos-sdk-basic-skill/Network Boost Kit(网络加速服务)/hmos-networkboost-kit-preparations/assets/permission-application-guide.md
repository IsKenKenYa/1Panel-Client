# Network Boost Kit权限申请指南

## 权限类型说明

Network Boost Kit涉及三种权限：

### 1. ohos.permission.GET_NETWORK_INFO（必需）
- **类型**：普通权限
- **用途**：获取设备网络信息
- **申请方式**：在module.json5中声明即可

### 2. ohos.permission.INTERNET（必需）
- **类型**：普通权限
- **用途**：允许使用因特网访问网络
- **申请方式**：在module.json5中声明即可

### 3. ohos.permission.LINKTURBO（可选）
- **类型**：受限ACL权限
- **用途**：允许应用使用多网并发、连接迁移等网络加速能力
- **申请方式**：需要通过AGC平台特别申请和审核

## 权限申请流程

### 基础权限配置（GET_NETWORK_INFO、INTERNET）

**步骤1：在module.json5中声明权限**
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_reason_network_info",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_reason_internet",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**步骤2：在资源文件中定义reason字符串**

在`entry/src/main/resources/base/element/string.json`中：
```json
{
  "string": [
    {
      "name": "permission_reason_network_info",
      "value": "用于获取当前网络状态信息"
    },
    {
      "name": "permission_reason_internet",
      "value": "用于访问网络服务"
    }
  ]
}
```

### 受限ACL权限申请（LINKTURBO）

**前提条件**：
- 已注册华为开发者账号
- 已在AGC创建项目和应用
- 已完成基础权限配置

**申请流程**：

**步骤1：申请调试Profile（调试阶段）**

1. 登录AGC平台：https://developer.huawei.com/consumer/cn/service/josp/agc/index.html
2. 进入项目 > 应用 > 项目设置
3. 点击"签名配置" > "调试签名"
4. 点击"申请调试Profile"

**步骤2：申请受限ACL权限**

在申请调试Profile的第4步"申请权限"中：
- ✅ 选中"受限ACL权限"
- ✅ 点击"选择"
- ✅ 在搜索框输入"ohos.permission.LINKTURBO"
- ✅ 勾选LINKTURBO权限
- ✅ 提交申请

**步骤3：填写申请原因**

示例申请原因：
```
应用需要使用多网并发能力，为用户提供更稳定的网络连接体验。
具体场景：
1. 在视频会议场景中，同时使用WiFi和蜂窝网络，提升视频通话质量
2. 在文件下载场景中，利用多网并发提高下载速度
3. 在网络切换时保持连接不中断，提升用户体验
```

**步骤4：等待审核**

- 审核时间：约1个工作日
- 查看进度：AGC平台 > 互动中心

**步骤5：审核通过后**

- 在"已获取权限"中勾选已申请的权限
- 点击确定
- 点击"添加"生成新的Profile文件
- 下载Profile文件
- 在DevEco Studio中替换Profile文件

**步骤6：在module.json5中添加LINKTURBO权限**

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_reason_network_info",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_reason_internet",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.LINKTURBO",
        "reason": "$string:permission_reason_linkturbo",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**步骤7：更新资源文件**

在`entry/src/main/resources/base/element/string.json`中：
```json
{
  "string": [
    {
      "name": "permission_reason_network_info",
      "value": "用于获取当前网络状态信息"
    },
    {
      "name": "permission_reason_internet",
      "value": "用于访问网络服务"
    },
    {
      "name": "permission_reason_linkturbo",
      "value": "用于使用多网并发和网络加速功能，提升网络体验"
    }
  ]
}
```

## 发布阶段权限申请

### API版本 < 26.0.0 Beta1

需要申请发布Profile：
1. 申请发布证书
2. 申请发布Profile（在第4步申请LINKTURBO权限）
3. 配置签名信息

### API版本 >= 26.0.0 Beta1

流程已简化，无需申请发布证书和发布Profile

## 自动签名方式（推荐）

使用DevEco Studio自动签名：
1. 打开DevEco Studio
2. 选择 File > Project Structure > Signing Configs
3. 勾选"Automatically generate signature"
4. DevEco Studio将自动完成：
   - 向AGC申请调试证书
   - 注册设备
   - 申请调试Profile
   - 申请受限ACL权限（如需要）

## 常见问题

### Q1：申请原因如何填写才能快速通过审核？
建议：
- 说明具体的业务场景
- 说明用户受益点
- 说明技术实现方式
- 避免笼统描述

### Q2：申请被拒绝怎么办？
解决方法：
- 查看拒绝原因
- 补充更详细的业务场景说明
- 重新提交申请

### Q3：审核时间过长怎么办？
解决方法：
- 检查申请原因是否足够详细
- 在互动中心查看审核进度
- 联系华为开发者支持

### Q4：是否可以先开发后申请权限？
不建议：
- 缺少权限会导致API调用失败（错误码201）
- 建议先完成权限配置，再进行功能开发

## 权限验证

完成配置后，可以通过以下方式验证：

### 编译验证
```bash
# 编译项目
hvigorw assembleHap

# 检查编译日志中是否有权限相关错误
```

### 运行验证
```typescript
import { netBoost } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

try {
  let sceneDesc: netBoost.SceneDesc = {
    scene: 'realtimeVoice',
    sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
  };
  netBoost.setSceneDesc(sceneDesc);
  console.info('权限配置正确，API调用成功');
} catch (err) {
  const error = err as BusinessError;
  if (error.code === 201) {
    console.error('权限校验失败，请检查module.json5配置');
  } else {
    console.error(`其他错误: ${error.code}, ${error.message}`);
  }
}
```

## 参考链接

- [申请调试Profile详细步骤](https://developer.huawei.com/consumer/cn/doc/app/agc-help-debug-profile-0000002248181278)
- [申请发布Profile详细步骤](https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-profile-0000002248341090)
- [互动中心](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html#/interactive)
- [自动签名配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing)