# 节点类型混乱

## 坑点描述

ArkUI NDK 中每种节点类型（`ArkUI_NodeType`）有各自支持的属性集合。对一种节点类型设置**另一种节点类型的属性**会被静默忽略，不报错但不生效。

## C API 事实

本坑点涉及的 C API（`ArkUI_NodeType` / `createNode` / `setAttribute` / `OH_ArkUI_GetModuleInterface`）的完整签名、头文件符号定位与来源核验方式见 `references/api-facts.md`——该文件为本 skill 的 C API 唯一权威源，本文件不在本地重复维护签名表与行号，避免行号漂移与重复维护。

`ArkUI_NodeType` 枚举定义了节点类型（如 `ARKUI_NODE_CUSTOM`、`ARKUI_NODE_TEXT`、`ARKUI_NODE_IMAGE`、`ARKUI_NODE_BUTTON`、`ARKUI_NODE_STACK` 等），需在 `<arkui/native_node.h>` 中按符号名 `ArkUI_NodeType` 检索定位。各节点类型支持的属性集合需对照 `ArkUI_NodeAttributeType` 枚举及 ArkUI C API 文档确认。

## 错误用法（反模式）

```c
// ❌ 对 TEXT 节点设置 IMAGE 属性
ArkUI_NodeHandle textNode = nodeApi->createNode(ARKUI_NODE_TEXT);
// 设置图片相关属性（如 NODE_IMAGE_SRC）对 TEXT 节点不生效
ArkUI_AttributeItem srcItem = { .string = "resource://path/to/image.png" };
nodeApi->setAttribute(textNode, NODE_IMAGE_SRC, &srcItem);
// 不报错，但图片不会显示——TEXT 节点不支持图片属性
```

## 正确用法

```c
// ✅ 按节点类型设置对应属性
ArkUI_NodeHandle textNode = nodeApi->createNode(ARKUI_NODE_TEXT);
// 设置文本内容（TEXT 节点支持的属性）
ArkUI_AttributeItem textItem = { .string = "Hello World" };
nodeApi->setAttribute(textNode, NODE_TEXT_CONTENT, &textItem);

ArkUI_NodeHandle imageNode = nodeApi->createNode(ARKUI_NODE_IMAGE);
// 设置图片源（IMAGE 节点支持的属性）
ArkUI_AttributeItem srcItem = { .string = "resource://path/to/image.png" };
nodeApi->setAttribute(imageNode, NODE_IMAGE_SRC, &srcItem);
```

## 如何确认属性适用

1. 查看 `ArkUI_NodeAttributeType` 枚举，确认属性适用的节点类型
2. 参考 ArkUI C API 文档中每个属性的适用节点说明
3. 如果不确定，先用最小示例验证属性是否生效

## 风险

- 属性设置不生效但无报错 → UI 表现与预期不一致，增加调试成本
- 开发者误以为属性已设置，实际被忽略，导致功能缺失
- 在复杂节点树中难以定位是哪个属性因类型不匹配而未生效
