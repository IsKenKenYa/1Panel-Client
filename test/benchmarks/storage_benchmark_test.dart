// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('Storage Benchmark', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_benchmark');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Benchmark: Write 10,000 items (No Encryption)', () async {
      final box = await Hive.openBox('benchmark_no_enc');
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 10000; i++) {
        await box.put('key_$i', {
          'id': i,
          'value': 'test_value_$i',
          'timestamp': DateTime.now().toIso8601String()
        });
      }

      stopwatch.stop();
      print(
          'Write 10,000 items (No Encryption): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });

    test('Benchmark: Read 10,000 items (No Encryption)', () async {
      final box = await Hive.openBox('benchmark_no_enc_read');
      // Pre-fill
      for (var i = 0; i < 10000; i++) {
        await box.put('key_$i', {
          'id': i,
          'value': 'test_value_$i',
          'timestamp': DateTime.now().toIso8601String()
        });
      }

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        box.get('key_$i');
      }
      stopwatch.stop();
      print(
          'Read 10,000 items (No Encryption): ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Benchmark: Write 10,000 items (AES-256 Encryption)', () async {
      final key = Hive.generateSecureKey();
      final box = await Hive.openBox('benchmark_enc',
          encryptionCipher: HiveAesCipher(key));
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 10000; i++) {
        await box.put('key_$i', {
          'id': i,
          'value': 'test_value_$i',
          'timestamp': DateTime.now().toIso8601String()
        });
      }

      stopwatch.stop();
      print(
          'Write 10,000 items (AES-256 Encryption): ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Benchmark: Read 10,000 items (AES-256 Encryption)', () async {
      final key = Hive.generateSecureKey();
      final box = await Hive.openBox('benchmark_enc_read',
          encryptionCipher: HiveAesCipher(key));
      // Pre-fill
      for (var i = 0; i < 10000; i++) {
        await box.put('key_$i', {
          'id': i,
          'value': 'test_value_$i',
          'timestamp': DateTime.now().toIso8601String()
        });
      }

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        box.get('key_$i');
      }
      stopwatch.stop();
      print(
          'Read 10,000 items (AES-256 Encryption): ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Benchmark: Batch Write 1,000 items (Monitor Data Simulation)',
        () async {
      final box = await Hive.openBox('benchmark_monitor');
      final stopwatch = Stopwatch()..start();

      // Simulate saving 1 hour of data (12 points * 5 metrics = 60 points) per batch
      // 1000 batches = 1000 hours simulation
      for (var i = 0; i < 1000; i++) {
        final data =
            List.generate(60, (index) => {'time': index, 'value': index * 1.0});
        await box.put('metric_cpu_$i', data);
      }

      stopwatch.stop();
      print(
          'Batch Write 1,000 monitor buckets: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
