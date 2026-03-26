import 'package:equatable/equatable.dart';

class ProcessWsMessage extends Equatable {
  const ProcessWsMessage._(this.payload);

  final Map<String, dynamic> payload;

  factory ProcessWsMessage.process({
    int? pid,
    String name = '',
    String username = '',
  }) {
    return ProcessWsMessage._(<String, dynamic>{
      'type': 'ps',
      'pid': pid,
      'name': name,
      'username': username,
    });
  }

  factory ProcessWsMessage.ssh({
    String loginUser = '',
    String loginIP = '',
  }) {
    return ProcessWsMessage._(<String, dynamic>{
      'type': 'ssh',
      'loginUser': loginUser,
      'loginIP': loginIP,
    });
  }

  Map<String, dynamic> toJson() => payload;

  @override
  List<Object?> get props => <Object?>[payload];
}
