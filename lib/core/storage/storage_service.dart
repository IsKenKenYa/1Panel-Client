import 'dart:async';

/// 通用存储服务接口
///
/// 定义了应用程序统一的存储操作规范
abstract class StorageService {
  /// 初始化服务
  Future<void> init();

  /// 获取值
  /// [T] 返回值的类型
  /// [key] 键名
  /// [defaultValue] 默认值
  T? get<T>(String key, {T? defaultValue});

  /// 保存值
  /// [key] 键名
  /// [value] 值
  Future<void> put<T>(String key, T value);

  /// 批量保存
  /// [entries] 键值对集合
  Future<void> putAll(Map<String, dynamic> entries);

  /// 删除值
  /// [key] 键名
  Future<void> delete(String key);

  /// 批量删除
  /// [keys] 键名集合
  Future<void> deleteAll(List<String> keys);

  /// 清空所有数据
  Future<void> clear();

  /// 监听数据变化
  /// [key] 键名
  Stream<dynamic> watch(String key);

  /// 获取所有键
  List<dynamic> get keys;

  /// 获取所有值
  List<dynamic> get values;

  /// 检查键是否存在
  bool containsKey(String key);
}
