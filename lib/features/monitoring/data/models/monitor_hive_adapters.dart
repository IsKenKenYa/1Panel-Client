import 'package:hive/hive.dart';
import '../../../../data/models/monitor_models.dart';

class MonitorDataPointAdapter extends TypeAdapter<MonitorDataPoint> {
  @override
  final int typeId = 1;

  @override
  MonitorDataPoint read(BinaryReader reader) {
    final time = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final value = reader.readDouble();
    return MonitorDataPoint(time: time, value: value);
  }

  @override
  void write(BinaryWriter writer, MonitorDataPoint obj) {
    writer.writeInt(obj.time.millisecondsSinceEpoch);
    writer.writeDouble(obj.value);
  }
}
