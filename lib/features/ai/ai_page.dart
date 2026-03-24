import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/app_localizations.dart';
import 'ai_provider.dart';
import '../../core/services/logger/logger_service.dart';

/// AI模块主页面
class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

/// AI模块主页面状态
class _AIPageState extends State<AIPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.aiManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.ollamaModels),
            Tab(text: localizations.gpuInfo),
            Tab(text: localizations.domainBinding),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OllamaModelPage(),
          GpuInfoPage(),
          DomainBindingPage(),
        ],
      ),
    );
  }
}

/// Ollama模型管理页面
class OllamaModelPage extends StatelessWidget {
  const OllamaModelPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final aiProvider = Provider.of<AIProvider>(context);
      return _buildModelPage(context, aiProvider);
    } catch (e) {
      appLogger.eWithPackage('ai.model', '获取AIProvider失败: $e');
      final localizations = AppLocalizations.of(context)!;
      return _buildErrorPage(localizations.configLoadError, context);
    }
  }

  Widget _buildModelPage(BuildContext context, AIProvider aiProvider) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: localizations.ollamaModels,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                aiProvider.searchOllamaModels(
                  page: 1,
                  pageSize: 10,
                  info: value,
                );
              },
            ),
          ),
          // 操作按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      aiProvider.syncOllamaModels();
                    },
                    icon: const Icon(Icons.sync),
                    label: Text(localizations.ollamaModels),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showCreateModelDialog(context, aiProvider);
                    },
                    icon: const Icon(Icons.add),
                    label: Text('${localizations.ollamaModels} ${localizations.create}'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 模型列表
          Expanded(
            child: aiProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : aiProvider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              aiProvider.errorMessage!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                aiProvider.clearError();
                                aiProvider.searchOllamaModels(
                                  page: 1,
                                  pageSize: 10,
                                );
                              },
                              child: Text(localizations.retry),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: aiProvider.ollamaModelList.length,
                        itemBuilder: (context, index) {
                          final model = aiProvider.ollamaModelList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ListTile(
                              title: Text(model.name ?? ''),
                              subtitle: Text(model.size ?? ''),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  final modelName = model.name ?? '';
                                  final modelId = model.id ?? 0;
                                  switch (value) {
                                    case 'load':
                                      aiProvider.loadOllamaModel(
                                        name: modelName,
                                      );
                                      break;
                                    case 'close':
                                      aiProvider.closeOllamaModel(
                                        name: modelName,
                                      );
                                      break;
                                    case 'delete':
                                      _showDeleteModelDialog(
                                        context,
                                        aiProvider,
                                        modelId,
                                      );
                                      break;
                                    case 'recreate':
                                      aiProvider.recreateOllamaModel(
                                        name: modelName,
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'load',
                                    child: Text(localizations.load),
                                  ),
                                  PopupMenuItem(
                                    value: 'close',
                                    child: Text(localizations.close),
                                  ),
                                  PopupMenuItem(
                                    value: 'recreate',
                                    child: Text('${localizations.recreate} ${localizations.ollamaModels}'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(localizations.delete),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPage(String errorMessage, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 可以在这里添加重试逻辑，比如导航到服务器配置页面
                appLogger.iWithPackage('ai.model', '用户点击重试按钮');
              },
              child: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示创建模型对话框
  void _showCreateModelDialog(BuildContext context, AIProvider aiProvider) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController taskIdController = TextEditingController();
    final localizations = AppLocalizations.of(context)!;

    appLogger.dWithPackage('ai.model', '显示创建模型对话框');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${localizations.create} ${localizations.ollamaModels}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '${localizations.ollamaModels} ${localizations.name}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: taskIdController,
              decoration: InputDecoration(
                labelText: '${localizations.taskId} (${localizations.optional})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                appLogger.iWithPackage('ai.model', '创建Ollama模型: ${nameController.text}');
                
                aiProvider.createOllamaModel(
                  name: nameController.text,
                  taskId: taskIdController.text.isNotEmpty
                      ? taskIdController.text
                      : null,
                );
                Navigator.of(context).pop();
              }
            },
            child: Text(localizations.create),
          ),
        ],
      ),
    );
  }

  /// 显示删除模型对话框
  void _showDeleteModelDialog(
    BuildContext context,
    AIProvider aiProvider,
    int modelId,
  ) {
    bool forceDelete = false;
    final localizations = AppLocalizations.of(context)!;

    appLogger.wWithPackage('ai.model', '显示删除模型对话框，模型ID: $modelId');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${localizations.delete} ${localizations.ollamaModels}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${localizations.confirm} ${localizations.delete} ${localizations.ollamaModels}?'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text('${localizations.force} ${localizations.delete}'),
                value: forceDelete,
                onChanged: (value) {
                  setState(() {
                    forceDelete = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                appLogger.wWithPackage('ai.model', '删除Ollama模型，模型ID: $modelId，强制删除: $forceDelete');
                
                aiProvider.deleteOllamaModel(
                  ids: [modelId],
                  forceDelete: forceDelete,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(localizations.delete),
            ),
          ],
        ),
      ),
    );
  }
}

/// GPU信息页面
class GpuInfoPage extends StatelessWidget {
  const GpuInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final aiProvider = Provider.of<AIProvider>(context);
      return _buildGpuInfoPage(context, aiProvider);
    } catch (e) {
      appLogger.eWithPackage('ai.gpu', '获取AIProvider失败: $e');
      final localizations = AppLocalizations.of(context)!;
      return _buildErrorPage(localizations.configLoadError);
    }
  }

  Widget _buildGpuInfoPage(BuildContext context, AIProvider aiProvider) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                appLogger.iWithPackage('ai.gpu', '刷新GPU信息');
                aiProvider.loadGpuInfo();
              },
              icon: const Icon(Icons.refresh),
              label: Text('${localizations.refresh} ${localizations.gpuInfo}'),
            ),
          ),
          // GPU信息列表
          Expanded(
            child: aiProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : aiProvider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              aiProvider.errorMessage!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                aiProvider.clearError();
                                aiProvider.loadGpuInfo();
                              },
                              child: Text(localizations.retry),
                            ),
                          ],
                        ),
                      )
                    : aiProvider.gpuInfoList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline, size: 64, color: Colors.blue),
                                const SizedBox(height: 16),
                                Text(
                                  '${localizations.notFound} ${localizations.gpuInfo}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: aiProvider.gpuInfoList.length,
                            itemBuilder: (context, index) {
                              final gpu = aiProvider.gpuInfoList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${localizations.gpu} ${gpu.index}',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text('${localizations.name}: ${gpu.productName}'),
                                      const SizedBox(height: 4),
                                      Text('${localizations.temperature}: ${gpu.temperature}°C'),
                                      const SizedBox(height: 4),
                                      Text('${localizations.fanSpeed}: ${gpu.fanSpeed}%'),
                                      const SizedBox(height: 4),
                                      Text('${localizations.gpuUsage}: ${gpu.gpuUtil}%'),
                                      const SizedBox(height: 4),
                                      Text('${localizations.memoryUsage}: ${gpu.memoryUsage}%'),
                                      const SizedBox(height: 4),
                                      Text('${localizations.totalMemory}: ${gpu.memTotal} MB'),
                                      const SizedBox(height: 4),
                                      Text('${localizations.usedMemory}: ${gpu.memUsed} MB'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPage(String errorMessage) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 可以在这里添加重试逻辑，比如导航到服务器配置页面
                appLogger.iWithPackage('ai.gpu', '用户点击重试按钮');
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 域名绑定页面
class DomainBindingPage extends StatelessWidget {
  const DomainBindingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.domainBinding),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.domain, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '域名绑定功能开发中',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '请使用AIProvider中的bindDomain方法',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
