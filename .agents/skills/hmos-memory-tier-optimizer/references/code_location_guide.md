# 代码定位指南

## 概述

本文档描述如何根据内存采集数据定位 HarmonyOS 项目中的相关代码文件。

## 定位流程

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   截图/Ability │ ──→ │   页面文件    │ ──→ │   组件代码    │
└──────────────┘     └──────────────┘     └──────────────┘
        │                   │                    │
        ▼                   ▼                    ▼
  视觉确认页面         Index.ets 等          List, Grid 等
```

## 定位规则

### 1. Ability → 页面文件

**数据来源**: `aa dump -l` 输出

```
main name [com.ohos.mms.MainAbility]
    │
    ▼
src/main/ets/pages/Index.ets
```

**搜索策略**:
1. 在 `src/main/ets/pages/` 目录搜索
2. 常见命名映射:
   - MainAbility → Index.ets, MainPage.ets
   - EntryAbility → Index.ets, Entry.ets
   - DetailAbility → Detail.ets, DetailPage.ets
3. 检查 `main_pages.json` 中的页面注册

### 2. UI 组件 → 代码位置

**数据来源**: UI 树 JSON 文件

```json
{
  "attributes": {
    "type": "List",
    "id": "conversation_list"
  }
}
```

**搜索策略**:
1. 提取组件类型 (List, Grid, Image 等)
2. 搜索组件声明: `List()`, `List {`
3. 结合 id 属性精确匹配
4. 从 UI 树的 hierarchy 路径定位

### 3. bundleName → 项目路径

**数据来源**: app.json5

```json
{
  "app": {
    "bundleName": "com.ohos.mms"
  }
}
```

**搜索策略**:
1. 在工作空间搜索 AppScope/app.json5
2. 匹配 bundleName 字段
3. 确定项目根目录

## 示例：MMS 应用定位

### 输入信息

```
Ability: com.ohos.mms.MainAbility
bundleName: com.ohos.mms
UI 组件: List, ListItem, RelativeContainer
截图: 短信列表页面
```

### 定位过程

```
1. Ability 定位
   com.ohos.mms.MainAbility
   → applications_mms-master/entry/src/main/ets/pages/Index.ets

2. UI 组件定位
   List 组件 → 搜索 "List()" 找到 ConversationList.ets
   ListItem → 搜索 "ListItem" 找到 MessageItem.ets

3. 确认文件
   - Index.ets (入口页面)
   - ConversationList.ets (会话列表)
   - MessageItem.ets (消息项组件)
```

## 文件确认清单

定位文件后，需要确认以下信息：

| 检查项 | 说明 |
|--------|------|
| 文件是否存在 | 路径正确且文件存在 |
| 版本匹配 | 代码版本与采集数据时的版本一致 |
| 组件匹配 | 代码中的组件与 UI 树匹配 |
| 页面正确 | 页面内容与截图一致 |

## 常见问题

### Q1: Ability 名称与页面文件名不匹配

**解决方案**: 检查 `main_pages.json` 中的页面注册

```json
{
  "src": ["pages/Index", "pages/Detail"]
}
```

### Q2: 找不到组件代码

**解决方案**:
1. 检查是否使用了动态加载
2. 检查组件是否在子目录中
3. 检查是否使用了 @Builder 装饰器

### Q3: 多个项目使用相同 bundleName

**解决方案**:
1. 检查项目路径配置
2. 使用项目路径作为区分
3. 让用户确认正确项目
