import 'package:equatable/equatable.dart';

class CommandSearchRequest extends Equatable {
  const CommandSearchRequest({
    this.page = 1,
    this.pageSize = 20,
    this.groupID,
    this.info,
    this.orderBy = 'name',
    this.order = 'ascending',
    this.type = 'command',
  });

  final int page;
  final int pageSize;
  final int? groupID;
  final String? info;
  final String orderBy;
  final String order;
  final String type;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'groupID': groupID ?? 0,
      'info': info,
      'orderBy': orderBy,
      'order': order,
      'type': type,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        page,
        pageSize,
        groupID,
        info,
        orderBy,
        order,
        type,
      ];
}
