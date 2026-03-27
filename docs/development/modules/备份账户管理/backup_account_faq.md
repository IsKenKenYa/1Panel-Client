# 备份账户管理模块FAQ

## 常见问题

### Q1: 支持哪些备份存储类型？

**A**: 支持以下备份存储类型：
- **本地存储** - 服务器本地磁盘
- **SFTP** - SSH文件传输协议
- **WebDAV** - WebDAV协议
- **OneDrive** - 微软OneDrive
- **Google Drive** - 谷歌云盘
- **S3** - Amazon S3及兼容存储
- **OSS** - 阿里云OSS
- **COS** - 腾讯云COS
- **Kodo** - 七牛云Kodo

**相关代码**: [backup_account_v2.dart](../../../lib/api/v2/backup_account_v2.dart)

### Q2: 如何添加备份账户？

**A**: 添加备份账户步骤：
1. 进入备份账户管理页面
2. 点击"添加账户"按钮
3. 选择存储类型
4. 填写账户配置信息
5. 点击"测试连接"验证
6. 点击"保存"完成添加

**API端点**: `POST /backups`

### Q3: 如何测试备份账户连接？

**A**: 测试连接步骤：
1. 在添加/编辑账户时
2. 填写完配置信息后
3. 点击"测试连接"按钮
4. 查看测试结果

**API端点**: `POST /backups/conn/check`

### Q4: 备份记录保留多长时间？

**A**: 备份记录保留策略：
- 记录信息永久保存
- 备份文件按配置保留
- 可手动删除旧备份

### Q5: 如何执行系统备份？

**A**: 执行备份步骤：
1. 进入备份账户管理页面
2. 点击"创建备份"按钮
3. 选择备份账户
4. 选择备份内容
5. 点击"开始备份"

**API端点**: `POST /backups/backup`

### Q6: 如何恢复系统数据？

**A**: 恢复数据步骤：
1. 进入备份记录列表
2. 选择要恢复的记录
3. 点击"恢复"按钮
4. 选择恢复内容
5. 确认恢复操作

**API端点**: `POST /backups/recover`

**当前移动端 recover submit 支持**:
- `app`
- `website`
- `mysql / mysql-cluster / mariadb`
- `postgresql / postgresql-cluster`
- `redis / redis-cluster`

**当前移动端只保留记录上下文、不开放直接提交恢复**:
- `directory`
- `snapshot`
- `log`

这些类型现在会稳定进入 `BackupRecoverPage`，但会明确提示“当前不可直接恢复”，避免页面进入非法状态。

补充口径：
- `recordType` 保留真实记录来源，用于 `record/search`
- `requestType` 作为 recover submit 的真实提交类型
- UI 仍只按 `app / website / database / other` 展示高层分类；数据库类在 UI 侧归并为 `mysql / postgresql / redis` 家族

### Q7: 备份失败怎么办？

**A**: 备份失败排查：
1. 检查备份账户连接
2. 验证存储空间是否充足
3. 查看错误日志
4. 检查网络连接
5. 重试备份操作

### Q8: 如何删除备份账户？

**A**: 删除备份账户步骤：
1. 在账户列表中找到目标账户
2. 点击"删除"按钮
3. 确认删除操作

**注意**: 删除账户不会删除已有的备份记录。

**API端点**: `POST /backups/del`

### Q9: Token过期如何刷新？

**A**: 刷新Token步骤：
1. 进入账户详情页面
2. 点击"刷新Token"按钮
3. 重新授权（如需要）
4. 保存更新

**API端点**: `POST /backups/refresh/token`

### Q10: 如何查看备份文件列表？

**A**: 查看备份文件：
1. 进入备份账户详情
2. 点击"浏览文件"按钮
3. 查看远程存储文件列表

**API端点**: `POST /backups/search/files`

## 故障排查指南

### 问题1: 连接测试失败

**可能原因**:
- 网络连接问题
- 认证信息错误
- 存储服务不可用
- 防火墙阻止

**排查步骤**:
1. 检查网络连接
2. 验证认证信息
3. 确认存储服务状态
4. 检查防火墙规则

### 问题2: 备份上传失败

**可能原因**:
- 存储空间不足
- 网络中断
- 权限不足
- 文件过大

**排查步骤**:
1. 检查存储空间
2. 验证网络状态
3. 确认写入权限
4. 查看错误日志

### 问题3: 恢复失败

**可能原因**:
- 备份文件损坏
- 版本不兼容
- 权限问题
- 磁盘空间不足

**排查步骤**:
1. 验证备份文件完整性
2. 检查版本兼容性
3. 确认操作权限
4. 检查磁盘空间

### 问题4: Token刷新失败

**可能原因**:
- 授权已过期
- 网络问题
- 服务端异常

**排查步骤**:
1. 重新授权
2. 检查网络连接
3. 查看服务状态
4. 联系服务提供商

### 问题5: 备份速度慢

**可能原因**:
- 网络带宽限制
- 文件数量过多
- 服务器负载高

**排查步骤**:
1. 检查网络带宽
2. 优化备份内容
3. 调整备份时间
4. 增加服务器资源

## 最佳实践建议

### 开发建议

1. **使用Provider管理状态**
   ```dart
   class BackupAccountProvider extends ChangeNotifier {
     List<BackupAccountInfo> _accounts = [];
     List<BackupRecord> _records = [];
     
     List<BackupAccountInfo> get accounts => _accounts;
     List<BackupRecord> get records => _records;
     
     Future<void> loadAccounts() async {
       // 加载账户列表
     }
   }
   ```

2. **实现连接测试**
   ```dart
   Future<bool> testConnection(BackupOperate config) async {
     try {
       final response = await api.testBackupAccount(config);
       return response.data ?? false;
     } catch (e) {
       return false;
     }
   }
   ```

3. **错误处理**
   - 提供详细的错误信息
   - 实现自动重试机制
   - 记录操作日志

### 运维建议

1. **备份策略**
   - 定期自动备份
   - 多地备份存储
   - 定期验证备份

2. **存储管理**
   - 监控存储空间
   - 定期清理旧备份
   - 合理设置保留策略

3. **安全配置**
   - 加密存储凭证
   - 限制访问权限
   - 定期更换密钥

### 安全建议

1. **凭证管理**
   - 加密存储访问密钥
   - 定期轮换密钥
   - 限制访问权限

2. **传输安全**
   - 使用HTTPS传输
   - 启用传输加密
   - 验证服务器证书

3. **访问控制**
   - 限制备份操作权限
   - 审计备份操作日志
   - 敏感数据加密备份

---

**文档版本**: 1.0  
**最后更新**: 2026-02-14  
**维护者**: Open1Panel开发团队
