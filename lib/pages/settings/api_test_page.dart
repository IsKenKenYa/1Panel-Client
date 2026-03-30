import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  bool _isLoading = false;
  ApiConfig? _currentConfig;
  String _testResult = '';
  String _selectedEndpoint = '/api/v2/dashboard/base/os';
  final List<String> _endpoints = [
    '/api/v2/dashboard/base/os',
    '/api/v2/system/host',
    '/api/v2/system/load',
    '/api/v2/apps',
    '/api/v2/containers',
    '/api/v2/websites',
  ];

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
      final config = await ApiConfigManager.getCurrentConfig();
      setState(() {
        _currentConfig = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
      final apiClient = DioClient(
        baseUrl: _currentConfig!.url,
        apiKey: _currentConfig!.apiKey,
      );

      final response = await apiClient.get(_selectedEndpoint);

      setState(() {
        _testResult =
            '请求成功!\n\n状态码: ${response.statusCode}\n\n响应数据:\n${_formatJson(response.data)}';
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _testResult =
            '请求失败!\n\n错误类型: ${e.type}\n\n错误信息: ${e.message}\n\n响应数据:\n${e.response?.data ?? '无响应数据'}';
        _isLoading = false;
      });
    } catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('API测试'),
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
                          if (_currentConfig != null) ...[
                            _buildInfoLine('名称: ${_currentConfig!.name}'),
                            _buildInfoLine('地址: ${_currentConfig!.url}'),
                            _buildInfoLine(
                              '密钥: ${_maskedApiKey(_currentConfig!.apiKey)}',
                            ),
                          ] else
                            const Text('暂无配置，请先添加API配置'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCurrentConfig,
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
                            initialValue: _selectedEndpoint,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: '选择API端点',
                              border: OutlineInputBorder(),
                            ),
                            items: _endpoints.map((endpoint) {
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
                              setState(() {
                                _selectedEndpoint = value ?? _selectedEndpoint;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _currentConfig == null ? null : _testApi,
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
                  if (_testResult.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _testResult,
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
                            'Token = md5(\'1panel\' + API-Key + UnixTimestamp)\n\n'
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
    if (apiKey.length <= 8) {
      return apiKey;
    }
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
