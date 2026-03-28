part of '../runtime_models.dart';

enum RuntimeType {
  java('java'),
  node('node'),
  python('python'),
  go('go'),
  php('php'),
  dotnet('dotnet');

  const RuntimeType(this.value);
  final String value;

  static RuntimeType fromString(String value) {
    return RuntimeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RuntimeType.java,
    );
  }
}
