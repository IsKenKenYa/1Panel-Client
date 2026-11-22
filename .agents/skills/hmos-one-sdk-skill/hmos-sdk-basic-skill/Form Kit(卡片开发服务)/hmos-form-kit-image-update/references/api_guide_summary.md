# 原始API开发指南文档

本文件为ArkTS卡片图片刷新功能的原始开发指南文档内容。

**文档来源**：
- 本地路径：`D:\code\APIDevice\output\md_output\harmonyos-guides\应用框架\Form Kit（卡片开发服务）\ArkTS卡片开发（推荐）\ArkTS卡片提供方开发指导\ArkTS卡片页面刷新\刷新本地图片和网络图片\arkts-ui-widget-image-update.md`
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-image-update

**文档摘要**：
本文档详细介绍如何在ArkTS卡片上刷新展示本地图片和网络图片。主要内容包括：

1. **功能说明**：
   - 在卡片上展示本地图片或从网络下载的图片
   - 通过FormExtensionAbility实现图片获取和传递
   - 使用文件描述符(fd)方式传递图片数据

2. **开发步骤**：
   - 步骤1：申请ohos.permission.INTERNET权限
   - 步骤2：导入相关模块
   - 步骤3：在onAddForm中实现本地图片刷新
   - 步骤4：在onFormEvent中实现网络图片刷新
   - 步骤5：在卡片页面通过backgroundImage展示图片

3. **关键要点**：
   - 图片通过文件描述符而非路径传递
   - 使用memory://协议加载图片
   - 网络下载必须在5秒内完成
   - imgName必须每次不同才能触发刷新

4. **代码示例**：
   - FormExtensionAbility完整实现代码
   - 卡片页面UI代码
   - 文件IO操作代码
   - HTTP请求代码

**完整文档内容**：
请访问在线链接或本地路径查看完整的开发指南文档，包含详细的步骤说明、代码示例和注意事项。

**注意事项**：
- FormExtensionAbility创建后10秒内无操作将被清理
- FormExtensionAbility不支持音频、相机等模块
- 图片文件数量和大小有明确限制
- 网络下载时间限制为5秒