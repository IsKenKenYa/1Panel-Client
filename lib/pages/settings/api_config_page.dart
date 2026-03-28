import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/logger/logger_service.dart';

class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key});

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;
  List<ApiConfig> _configs = [];
  ApiConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      appLogger.dWithPackage('api.config', '开始加载API配置');

      final configs = await ApiConfigManager.getConfigs();
      final currentConfig = await ApiConfigManager.getCurrentConfig();

      if (!mounted) return;
      setState(() {
        _configs = configs;
        _currentConfig = currentConfig;
        _isLoading = false;
      });

      appLogger.dWithPackage('api.config', 'API配置加载成功，共${configs.length}个配置');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      appLogger.eWithPackage('api.config', '加载API配置失败', error: e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载配置失败: $e')),
      );
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      appLogger.iWithPackage(
          'api.config', '开始保存API配置: ${_nameController.text}');

      final config = ApiConfig(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text,
        url: _urlController.text,
        apiKey: _apiKeyController.text,
        isDefault: _isDefault,
      );

      await ApiConfigManager.saveConfig(config);

      // 如果保存的是默认配置或者没有当前配置，设置为当前配置
      if (_isDefault || _currentConfig == null) {
        await ApiConfigManager.setCurrentConfig(config.id);
      }

      await _loadConfigs();
      if (!mounted) return;

      _clearForm();

      appLogger.iWithPackage(
          'api.config', 'API配置保存成功: ${_nameController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置保存成功')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      appLogger.eWithPackage('api.config', '保存API配置失败: ${_nameController.text}',
          error: e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存配置失败: $e')),
      );
    }
  }

  Future<void> _deleteConfig(String id) async {
    final config = _configs.firstWhere((c) => c.id == id);

    appLogger.wWithPackage('api.config', '删除API配置: ${config.name}');

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiConfigManager.deleteConfig(id);
      await _loadConfigs();
      if (!mounted) return;

      appLogger.wWithPackage('api.config', 'API配置删除成功: ${config.name}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('配置 "${config.name}" 删除成功')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      appLogger.eWithPackage('api.config', '删除API配置失败: ${config.name}',
          error: e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除配置失败: $e')),
      );
    }
  }

  Future<void> _setCurrentConfig(String id) async {
    final config = _configs.firstWhere((c) => c.id == id);

    appLogger.iWithPackage('api.config', '切换当前API配置: ${config.name}');

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiConfigManager.setCurrentConfig(id);
      await _loadConfigs();
      if (!mounted) return;

      appLogger.iWithPackage('api.config', 'API配置切换成功: ${config.name}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已切换到配置 "${config.name}"')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      appLogger.eWithPackage('api.config', '切换API配置失败: ${config.name}',
          error: e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('切换配置失败: $e')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _urlController.clear();
    _apiKeyController.clear();
    setState(() {
      _isDefault = false;
    });
  }

  void _editConfig(ApiConfig config) {
    _nameController.text = config.name;
    _urlController.text = config.url;
    _apiKeyController.text = config.apiKey;
    setState(() {
      _isDefault = config.isDefault;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API配置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '添加/编辑API配置',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: '配置名称',
                                hintText: '例如：生产环境',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入配置名称';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _urlController,
                              decoration: const InputDecoration(
                                labelText: '服务器地址',
                                hintText: '例如：http://192.168.1.100:10086',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入服务器地址';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _apiKeyController,
                              decoration: const InputDecoration(
                                labelText: 'API密钥',
                                hintText: '请输入API密钥',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入API密钥';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              title: const Text('设为默认配置'),
                              value: _isDefault,
                              onChanged: (value) {
                                setState(() {
                                  _isDefault = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _saveConfig,
                                    child: const Text('保存配置'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _clearForm,
                                    child: const Text('清空'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '已保存的配置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _configs.isEmpty
                      ? const Center(
                          child: Text('暂无配置，请添加新的API配置'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _configs.length,
                          itemBuilder: (context, index) {
                            final config = _configs[index];
                            final isCurrent = _currentConfig?.id == config.id;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(config.name),
                                subtitle: Text(config.url),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (config.isDefault)
                                      const Tooltip(
                                        message: '默认配置',
                                        child: Icon(Icons.star,
                                            color: Colors.amber),
                                      ),
                                    if (isCurrent)
                                      const Tooltip(
                                        message: '当前配置',
                                        child: Icon(Icons.check_circle,
                                            color: Colors.green),
                                      ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editConfig(config);
                                        } else if (value == 'delete') {
                                          _showDeleteConfirmDialog(config);
                                        } else if (value == 'set_current') {
                                          _setCurrentConfig(config.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (!isCurrent)
                                          const PopupMenuItem(
                                            value: 'set_current',
                                            child: Text('设为当前配置'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('编辑'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('删除',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (!isCurrent) {
                                    _setCurrentConfig(config.id);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  void _showDeleteConfirmDialog(ApiConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除配置"${config.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteConfig(config.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
