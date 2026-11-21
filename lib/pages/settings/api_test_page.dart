import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/settings/services/api_diagnostics_service.dart';

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  bool _isLoading = false;
  ApiConfig? _currentConfig;
  String _testResult = '';
  String _selectedEndpoint = ApiDiagnosticsService.endpoints.first;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await ApiDiagnosticsService.currentServer();
      if (!mounted) return;
      setState(() {
        _currentConfig = config;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentConfig = null;
        _isLoading = false;
        _testResult = '加载配置失败: $e';
      });
    }
  }

  Future<void> _testApi() async {
    if (_currentConfig == null) {
      setState(() {
        _testResult = '请先配置API';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = '';
    });

    try {
      final response = await ApiDiagnosticsService.check(
        _currentConfig!,
        _selectedEndpoint,
      );
      if (!mounted) return;

      setState(() {
        _testResult =
            '请求成功!\n\n状态码: ${response.statusCode}\n\n响应数据:\n${_formatJson(response.data)}';
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _testResult =
            '请求失败!\n\n错误类型: ${e.type}\n\n错误信息: ${e.message}\n\n响应数据:\n${e.response?.data ?? '无响应数据'}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testResult = '请求失败!\n\n错误信息: $e';
        _isLoading = false;
      });
    }
  }

  String _formatJson(dynamic json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiTestView(
      config: _currentConfig,
      isLoading: _isLoading,
      result: _testResult,
      selectedEndpoint: _selectedEndpoint,
      onRefresh: _loadCurrentConfig,
      onTest: _testApi,
      onEndpointChanged: (value) => setState(() => _selectedEndpoint = value),
    );
  }
}

class ApiTestView extends StatelessWidget {
  const ApiTestView({
    super.key,
    required this.config,
    required this.selectedEndpoint,
    required this.onEndpointChanged,
    required this.onRefresh,
    required this.onTest,
    this.isLoading = false,
    this.result = '',
  });

  final ApiConfig? config;
  final String selectedEndpoint;
  final ValueChanged<String> onEndpointChanged;
  final VoidCallback onRefresh;
  final VoidCallback onTest;
  final bool isLoading;
  final String result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('API测试'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '当前API配置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (config != null) ...[
                            _buildInfoLine('名称: ${config!.name}'),
                            _buildInfoLine('地址: ${config!.url}'),
                            _buildInfoLine(
                              '密钥: ${_maskedApiKey(config!.apiKey)}',
                            ),
                          ] else
                            const Text('暂无配置，请先添加API配置'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: onRefresh,
                            child: const Text('刷新配置'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'API测试',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: selectedEndpoint,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: '选择API端点',
                              border: OutlineInputBorder(),
                            ),
                            items: ApiDiagnosticsService.endpoints.map((endpoint) {
                              return DropdownMenuItem<String>(
                                value: endpoint,
                                child: Text(
                                  endpoint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) onEndpointChanged(value);
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: config?.panelType == ApiConfig.onePanelType
                                  ? onTest
                                  : null,
                              child: const Text('测试API'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '测试结果',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (result.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          result,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API说明',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '1Panel v2 API使用自定义Token进行身份验证，格式为：\n\n'
                            'Token = hmac_sha256(API-Key, \'1panel:\' + UnixTimestamp)\n\n'
                            '每次请求必须携带以下两个Header：\n\n'
                            '- 1Panel-Token: 自定义的Token值\n'
                            '- 1Panel-Timestamp: 当前时间戳\n\n'
                            '注意事项：\n'
                            '- 确保服务器与客户端时间同步，否则会导致验证失败\n'
                            '- 建议将可信任的IP或IP段加入白名单，避免频繁Token验证的开销',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _maskedApiKey(String apiKey) {
    if (apiKey.isEmpty) return '';
    if (apiKey.length <= 8) return '••••';
    return '${apiKey.substring(0, 8)}...';
  }

  Widget _buildInfoLine(String value) {
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
