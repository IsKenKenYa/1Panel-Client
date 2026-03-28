part of '../runtime_models.dart';

class FpmStatusItem extends Equatable {
  final String key;
  final dynamic value;

  const FpmStatusItem({
    required this.key,
    this.value,
  });

  factory FpmStatusItem.fromJson(Map<String, dynamic> json) {
    return FpmStatusItem(
      key: json['key'] as String? ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
      };

  @override
  List<Object?> get props => [key, value];
}

