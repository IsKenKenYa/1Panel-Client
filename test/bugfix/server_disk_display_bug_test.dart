import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/server/server_repository.dart';
import 'package:onepanel_client/core/config/api_config.dart';

/// Bug Condition 探索性测试
/// 
/// Property 1: Bug Condition - Monitor API 磁盘数据缺失
/// 
/// 此测试验证当前实现中磁盘数据显示为"--"的bug。
/// 在未修复的代码上，此测试应该失败，证明bug存在。
/// 在修复后，此测试应该通过，证明bug已解决。
/// 
/// Bug Condition: 
/// - 使用 Monitor API (/api/v2/hosts/monitor/search) 获取服务器指标
/// - 请求包含磁盘数据 (diskPercent)
/// - 返回的 diskPercent 为 null
/// 
/// Expected Behavior:
/// - diskPercent 应该是有效的数值（0-100之间）
/// - UI 应该显示实际的磁盘使用百分比，而不是"--"
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Bug Condition - Server Disk Display', () {
    test('Property 1: diskPercent should not be null when server has disk data', () async {
      // 这个测试在未修复的代码上应该失败
      // 因为当前实现使用 Monitor API，可能返回 null diskPercent
      
      // 注意: 这是一个探索性测试，用于确认bug存在
      // 我们不会在这里修复代码，只是记录失败的反例
      
      final repository = const ServerRepository();
      
      // 使用真实的服务器配置进行测试
      // 如果没有配置的服务器，跳过测试
      try {
        final configs = await ApiConfigManager.getConfigs();
        if (configs.isEmpty) {
          print('⚠️  跳过测试: 没有配置的服务器');
          return;
        }
        
        final testServerId = configs.first.id;
        print('📊 测试服务器: $testServerId');
        
        // 调用当前实现的 loadServerMetrics
        final metrics = await repository.loadServerMetrics(testServerId);
        
        print('📈 返回的指标:');
        print('  - cpuPercent: ${metrics.cpuPercent}');
        print('  - memoryPercent: ${metrics.memoryPercent}');
        print('  - diskPercent: ${metrics.diskPercent}');
        print('  - load: ${metrics.load}');
        
        // Bug Condition: diskPercent 为 null
        if (metrics.diskPercent == null) {
          print('❌ Bug 确认: diskPercent 为 null');
          print('   这证明了 bug 存在 - 磁盘信息无法显示');
          print('   UI 将显示 "--" 而不是实际的磁盘使用率');
        }
        
        // Expected Behavior: diskPercent 应该是有效的数值
        expect(
          metrics.diskPercent,
          isNotNull,
          reason: 'diskPercent 不应该为 null - 服务器应该有磁盘数据',
        );
        
        expect(
          metrics.diskPercent! >= 0 && metrics.diskPercent! <= 100,
          isTrue,
          reason: 'diskPercent 应该在 0-100 之间',
        );
        
        print('✅ 测试通过: diskPercent = ${metrics.diskPercent}%');
      } catch (e, stackTrace) {
        print('❌ 测试执行失败: $e');
        print('堆栈跟踪: $stackTrace');
        rethrow;
      }
    });
    
    test('Bug Condition: Monitor API returns null diskPercent', () async {
      // 这个测试直接验证 Monitor API 的行为
      // 用于理解为什么 diskPercent 为 null
      
      final repository = const ServerRepository();
      
      try {
        final configs = await ApiConfigManager.getConfigs();
        if (configs.isEmpty) {
          print('⚠️  跳过测试: 没有配置的服务器');
          return;
        }
        
        final testServerId = configs.first.id;
        final metrics = await repository.loadServerMetrics(testServerId);
        
        // 记录反例
        if (metrics.diskPercent == null) {
          print('');
          print('========================================');
          print('反例 (Counterexample) 记录:');
          print('========================================');
          print('服务器ID: $testServerId');
          print('Bug Condition: diskPercent = null');
          print('');
          print('其他指标状态:');
          print('  - cpuPercent: ${metrics.cpuPercent ?? "null"}');
          print('  - memoryPercent: ${metrics.memoryPercent ?? "null"}');
          print('  - load: ${metrics.load ?? "null"}');
          print('');
          print('根本原因分析:');
          print('  当前实现使用 Monitor API (/api/v2/hosts/monitor/search)');
          print('  Monitor API 可能未返回 diskData 字段');
          print('  或者 diskData 为空数组');
          print('');
          print('推荐修复方案:');
          print('  使用 Dashboard API (/api/v2/dashboard/base)');
          print('  Dashboard API 已验证返回正确的磁盘数据');
          print('========================================');
        }
        
        // 这个断言应该失败，证明bug存在
        expect(
          metrics.diskPercent,
          isNotNull,
          reason: 'Bug Condition: Monitor API 未返回有效的 diskPercent',
        );
      } catch (e) {
        print('测试执行异常: $e');
        rethrow;
      }
    });
  });
}
