# 图标对比 - Material Design 3 优化

## 底部导航栏图标变化

### 服务器 (Servers)
- 保持不变: `dns_outlined` / `dns`
- 原因: 已经是最佳的服务器图标

### 文件 (Files)
- **旧**: `folder_outlined` / `folder`
- **新**: `folder_open_outlined` / `folder_open`
- **改进**: 打开的文件夹更直观地表示"浏览文件"的操作

### 容器管理 (Containers)
- **旧**: `layers_outlined` / `layers`
- **新**: `widgets_outlined` / `widgets`
- **改进**: widgets 图标更符合容器/组件的概念，layers 更适合图层概念

### 设置 (Settings)
- 保持不变: `settings_outlined` / `settings`
- 原因: 标准的设置图标

## 其他模块图标变化

### 应用商店 (Apps)
- **旧**: `apps_outlined` / `apps`
- **新**: `grid_view_outlined` / `grid_view`
- **改进**: 网格视图更清晰地表示应用列表

### 网站 (Websites)
- **旧**: `language_outlined` / `language`
- **新**: `public_outlined` / `public`
- **改进**: public 图标（地球）更准确表示公共网站

### AI 服务 (AI)
- **旧**: `smart_toy_outlined` / `smart_toy`
- **新**: `psychology_outlined` / `psychology`
- **改进**: 大脑图标更符合 AI/智能的概念

### 安全验证 (Verification)
- **旧**: `verified_user_outlined` / `verified_user`
- **新**: `shield_outlined` / `shield`
- **改进**: 盾牌图标更简洁，更符合安全防护的概念

## 设计原则

1. **语义化**: 图标应直观表达功能含义
2. **一致性**: 所有图标都使用 Material Icons 的 outlined 变体
3. **可识别性**: 选中状态使用 filled 变体，增强视觉反馈
4. **简洁性**: 避免过于复杂的图标，保持清晰可辨

## MD3 图标规范

- **未选中**: outlined 变体（线条图标）
- **选中**: filled 变体（实心图标）
- **尺寸**: 24dp (默认)
- **颜色**: 由主题自动控制
- **动画**: 200ms 缩放+淡入淡出过渡
