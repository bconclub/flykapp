import 'package:hive/hive.dart';

class FlowAdapter extends TypeAdapter<Flow> {
  @override
  final int typeId = 3;

  @override
  Flow read(BinaryReader reader) {
    final id = reader.read();
    final name = reader.readString();
    final actionsList = reader.read();
    final actions = actionsList != null 
        ? List<String>.from((actionsList as List).map((e) => e.toString()))
        : <String>[];
    final createdAtStr = reader.read();
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr as String) : DateTime.now();
    final userId = reader.read();
    final isSynced = reader.readBool();
    
    return Flow(
      id: id as String?,
      name: name,
      actions: actions,
      createdAt: createdAt,
      userId: userId as String?,
      isSynced: isSynced,
    );
  }

  @override
  void write(BinaryWriter writer, Flow obj) {
    writer.write(obj.id);
    writer.writeString(obj.name);
    writer.write(obj.actions);
    writer.write(obj.createdAt.toIso8601String());
    writer.write(obj.userId);
    writer.writeBool(obj.isSynced);
  }
}

class Flow extends HiveObject {
  String? id;
  String name;
  List<String> actions; // List of action names: ['Save', 'Research', 'Next Steps', ...]
  DateTime createdAt;
  String? userId;
  bool isSynced;

  Flow({
    this.id,
    required this.name,
    required this.actions,
    required this.createdAt,
    this.userId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'actions': actions,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }

  factory Flow.fromMap(Map<String, dynamic> map) {
    final actionsData = map['actions'];
    List<String> actions = [];
    if (actionsData != null) {
      if (actionsData is List) {
        actions = actionsData.map((e) => e.toString()).toList();
      } else if (actionsData is String) {
        // Handle PostgreSQL array format
        actions = actionsData
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return Flow(
      id: map['id']?.toString(),
      name: map['name'] as String,
      actions: actions,
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['user_id']?.toString(),
      isSynced: true,
    );
  }

  Flow copyWith({
    String? id,
    String? name,
    List<String>? actions,
    DateTime? createdAt,
    String? userId,
    bool? isSynced,
  }) {
    return Flow(
      id: id ?? this.id,
      name: name ?? this.name,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

