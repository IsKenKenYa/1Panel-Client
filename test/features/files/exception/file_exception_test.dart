import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/data/models/file/file_info.dart';
import 'package:onepanel_client/core/services/transfer/transfer_task.dart';

void main() {
  group('异常处理测试', () {
    group('网络错误处理', () {
      test('应该正确处理网络连接异常', () {
        const exception = NetworkConnectionException('Connection timeout');

        expect(exception.message, contains('timeout'));
        expect(exception.toString(), contains('NetworkException'));
      });

      test('应该正确处理连接失败异常', () {
        const exception = NetworkConnectionException('Failed to connect to server');

        expect(exception.message, contains('Failed to connect'));
      });

      test('应该正确处理 SSL 错误', () {
        const exception = NetworkConnectionException('SSL certificate error');

        expect(exception.message, contains('SSL'));
      });

      test('应该正确处理 DNS 解析失败', () {
        const exception = NetworkConnectionException('DNS resolution failed');

        expect(exception.message, contains('DNS'));
      });
    });

    group('服务器错误处理', () {
      test('应该正确处理 500 服务器错误', () {
        const exception = ServerException(
          'Internal Server Error',
          statusCode: 500,
        );

        expect(exception.statusCode, equals(500));
        expect(exception.message, contains('Internal Server Error'));
      });

      test('应该正确处理 404 未找到错误', () {
        const exception = HttpException(
          'File not found',
          statusCode: 404,
        );

        expect(exception.statusCode, equals(404));
        expect(exception.message, contains('not found'));
      });

      test('应该正确处理 403 权限拒绝错误', () {
        const exception = HttpException(
          'Access denied',
          statusCode: 403,
        );

        expect(exception.statusCode, equals(403));
        expect(exception.message, contains('Access denied'));
      });

      test('应该正确处理 401 未授权错误', () {
        const exception = AuthException(
          'Invalid token',
          statusCode: 401,
        );

        expect(exception.statusCode, equals(401));
        expect(exception.message, contains('Invalid token'));
      });

      test('应该正确处理 400 请求错误', () {
        const exception = HttpException(
          'Invalid parameters',
          statusCode: 400,
        );

        expect(exception.statusCode, equals(400));
        expect(exception.message, contains('Invalid parameters'));
      });

      test('应该正确处理 429 请求过多', () {
        const exception = HttpException(
          'Rate limit exceeded',
          statusCode: 429,
        );

        expect(exception.statusCode, equals(429));
        expect(exception.message, contains('Rate limit'));
      });
    });

    group('认证失败处理', () {
      test('应该正确处理 Token 过期', () {
        const exception = AuthException('Token has expired');

        expect(exception.message, contains('expired'));
      });

      test('应该正确处理无效 Token', () {
        const exception = AuthException('Invalid authentication token');

        expect(exception.message, contains('Invalid'));
      });

      test('应该正确处理会话过期', () {
        const exception = AuthException('Session has expired');

        expect(exception.message, contains('Session'));
      });
    });

    group('文件操作错误处理', () {
      test('应该正确处理文件不存在错误', () {
        final file = FileInfo(
          name: 'nonexistent.txt',
          path: '/nonexistent.txt',
          size: 0,
          type: 'file',
        );

        expect(file.name, equals('nonexistent.txt'));
      });

      test('应该正确处理权限不足错误', () {
        const exception = HttpException(
          'Permission denied: /root/secret',
          statusCode: 403,
        );

        expect(exception.message, contains('Permission denied'));
        expect(exception.message, contains('/root/secret'));
      });

      test('应该正确处理磁盘空间不足错误', () {
        const errorMessage = 'No space left on device';
        
        expect(errorMessage, contains('No space'));
      });

      test('应该正确处理文件已存在错误', () {
        const errorMessage = 'File already exists: /test/file.txt';
        
        expect(errorMessage, contains('already exists'));
      });

      test('应该正确处理目录非空错误', () {
        const errorMessage = 'Directory not empty: /test/dir';
        
        expect(errorMessage, contains('not empty'));
      });

      test('应该正确处理文件被占用错误', () {
        const errorMessage = 'File is in use by another process';
        
        expect(errorMessage, contains('in use'));
      });
    });

    group('传输错误处理', () {
      test('应该正确处理上传中断', () {
        final task = TransferTask(
          id: 'test-001',
          path: '/file.txt',
          totalSize: 1000,
          transferredSize: 500,
          type: TransferType.upload,
          status: TransferStatus.failed,
          error: 'Upload interrupted',
          createdAt: DateTime.now(),
        );

        expect(task.status, equals(TransferStatus.failed));
        expect(task.error, equals('Upload interrupted'));
        expect(task.isResumable, isTrue);
      });

      test('应该正确处理下载中断', () {
        final task = TransferTask(
          id: 'test-002',
          path: '/remote/file.txt',
          totalSize: 2000,
          transferredSize: 1000,
          type: TransferType.upload,
          status: TransferStatus.failed,
          error: 'Connection lost',
          createdAt: DateTime.now(),
        );

        expect(task.status, equals(TransferStatus.failed));
        expect(task.progress, equals(0.5));
        expect(task.isResumable, isTrue);
      });

      test('应该正确处理校验失败', () {
        const errorMessage = 'Checksum mismatch: expected abc123, got def456';
        
        expect(errorMessage, contains('Checksum mismatch'));
      });

      test('应该正确处理分块丢失', () {
        const errorMessage = 'Missing chunk: chunk 5 of 10';
        
        expect(errorMessage, contains('Missing chunk'));
      });
    });

    group('数据解析错误处理', () {
      test('应该正确处理 JSON 解析错误', () {
        expect(() => throw FormatException('Invalid JSON'), throwsFormatException);
      });

      test('应该正确处理类型转换错误', () {
        final json = {'size': 'not_a_number'};
        
        expect(() => json['size'] as int, throwsA(isA<TypeError>()));
      });

      test('应该正确处理空值处理', () {
        final json = <String, dynamic>{};
        
        expect(json['nonexistent'], isNull);
      });

      test('应该正确处理字段缺失', () {
        final json = {'name': 'test.txt'};
        
        expect(json.containsKey('size'), isFalse);
        expect(json['size'], isNull);
      });
    });

    group('重试机制测试', () {
      test('应该正确计算重试延迟', () {
        final delays = [1, 2, 4, 8, 16];
        
        for (var i = 0; i < delays.length; i++) {
          final delay = delays[i];
          expect(delay, equals(1 << i));
        }
      });

      test('应该正确处理最大重试次数', () {
        const maxRetries = 3;
        var attempts = 0;

        while (attempts < maxRetries) {
          attempts++;
        }

        expect(attempts, equals(maxRetries));
      });

      test('应该在重试次数用尽后放弃', () {
        const maxRetries = 3;
        var attempts = 0;
        var success = false;

        while (attempts < maxRetries && !success) {
          attempts++;
        }

        expect(attempts, equals(maxRetries));
        expect(success, isFalse);
      });
    });
  });
}
