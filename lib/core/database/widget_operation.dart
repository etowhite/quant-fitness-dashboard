import 'package:isar_community/isar.dart';
part 'widget_operation.g.dart';

/// Durable idempotency journal, not a second store of health data.
@Collection(accessor: 'widgetOperations')
class WidgetOperation {
  Id? id;
  @Index(unique: true)
  late String requestId;
  late DateTime recordedAt;
}
