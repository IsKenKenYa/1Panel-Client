---
inclusion: auto
---

# 功能测试用例自动生成规则

## 触发条件

当以下情况发生时，自动生成对应测试用例：

1. 新增 API 端点调用
2. 新增或修改 Repository 方法
3. 新增或修改 Provider/Service 业务逻辑
4. 修复 Bug

## 测试用例结构

### 1. API/Repository 层测试

```dart
// test/api_client/{module}_api_client_test.dart
// test/data/repositories/{module}_repository_test.dart

group('{功能模块}', () {
  test('正常流程：{操作描述}', () async {
    // Arrange: 准备数据
    // Act: 执行操作
    // Assert: 验证结果
  });

  test('异常流程：{错误场景}', () async {
    // 验证错误处理
  });

  test('边界条件：{边界描述}', () async {
    // 验证边界情况
  });
});
```

### 2. Provider/Service 层测试

```dart
// test/features/{module}/{module}_provider_test.dart
// test/core/services/{module}_service_test.dart

group('{Provider/Service 名称}', () {
  late {Type}Provider provider;
  late Mock{Type}Repository mockRepository;

  setUp(() {
    mockRepository = Mock{Type}Repository();
    provider = {Type}Provider(mockRepository);
  });

  test('初始状态正确', () {
    expect(provider.isLoading, false);
    expect(provider.items, isEmpty);
  });

  test('加载数据成功', () async {
    // Mock 数据
    when(mockRepository.getData()).thenAnswer((_) async => mockData);
    
    // 执行
    await provider.loadData();
    
    // 验证
    expect(provider.items, mockData);
    expect(provider.isLoading, false);
  });

  test('加载数据失败', () async {
    // Mock 异常
    when(mockRepository.getData()).thenThrow(Exception('Network error'));
    
    // 执行
    await provider.loadData();
    
    // 验证错误处理
    expect(provider.hasError, true);
    expect(provider.isLoading, false);
  });
});
```

### 3. Bug 修复回归测试

```dart
// test/bugfix/{issue_description}_test.dart

/// 回归测试：{Bug 描述}
/// 
/// 问题：{问题说明}
/// 错误信息：{错误日志}
/// 修复方案：{修复说明}
void main() {
  group('Bug 修复验证', () {
    test('修复前的错误场景不再出现', () {
      // 重现修复前的场景
      // 验证修复后的正确行为
    });

    test('相关功能未受影响', () {
      // 验证相关功能正常
    });
  });
}
```

## 必需测试场景

### API 层
- ✅ 成功响应解析
- ✅ 错误响应处理（400/401/403/404/500）
- ✅ 网络超时
- ✅ 空数据处理
- ✅ 分页参数验证

### Repository 层
- ✅ 数据转换正确性
- ✅ 缓存逻辑（如适用）
- ✅ 异常传播
- ✅ 并发请求处理

### Provider/Service 层
- ✅ 初始状态
- ✅ 加载状态管理
- ✅ 成功状态更新
- ✅ 错误状态处理
- ✅ 通知监听器时机

### Model 层
- ✅ JSON 序列化/反序列化
- ✅ null 值处理
- ✅ 默认值正确性
- ✅ 必填字段验证

## 测试命名规范

```dart
// 格式：{操作}_{场景}_{预期结果}
test('loadData_withValidParams_returnsData', () {});
test('loadData_withNetworkError_setsErrorState', () {});
test('toJson_withNullField_usesDefaultValue', () {});
```

## Mock 数据准备

```dart
// test/fixtures/{module}_fixtures.dart

class {Module}Fixtures {
  static {Type} get valid{Type} => {Type}(
    id: 1,
    name: 'test',
    // ...
  );

  static Map<String, dynamic> get valid{Type}Json => {
    'id': 1,
    'name': 'test',
    // ...
  };

  static {Type} get invalid{Type} => {Type}(
    // 边界或异常数据
  );
}
```

## 测试执行顺序

1. **开发前**：设计测试用例
2. **开发中**：编写测试（TDD 可选）
3. **开发后**：
   ```bash
   flutter test test/{specific}_test.dart  # 单个测试
   dart run test/scripts/test_runner.dart unit  # 单元测试
   dart run test/scripts/test_runner.dart integration  # 集成测试（API/网络）
   ```

## 测试覆盖率要求

- 新增代码：≥ 80%
- 关键路径：100%
- Bug 修复：必须有回归测试

## 不需要测试的场景

- 纯 UI Widget（使用 Widget 测试）
- 生成代码（`*.g.dart`、`*.freezed.dart`）
- 简单的 getter/setter
- 第三方库封装（除非有业务逻辑）

## 测试文件位置

```
test/
├── api_client/           # API 客户端测试
├── data/
│   ├── models/          # 模型测试
│   └── repositories/    # 仓库测试
├── features/            # 功能模块测试
├── core/
│   └── services/        # 核心服务测试
├── bugfix/              # Bug 修复回归测试
└── fixtures/            # 测试数据夹具
```

## 快速检查清单

创建新功能时，确保：

- [ ] API 调用有对应的 API 客户端测试
- [ ] Repository 方法有单元测试
- [ ] Provider/Service 有状态管理测试
- [ ] Model 有序列化测试
- [ ] 异常场景有错误处理测试
- [ ] 运行 `flutter analyze` 无错误
- [ ] 运行 `dart run test/scripts/test_runner.dart unit` 通过

修复 Bug 时，确保：

- [ ] 在 `test/bugfix/` 创建回归测试
- [ ] 测试能重现修复前的问题
- [ ] 测试验证修复后的正确行为
- [ ] 相关功能未受影响
