import 'package:hive/hive.dart';

class UserEntityAdapter extends TypeAdapter<UserEntity> {
  @override
  final int typeId = 2;

  @override
  UserEntity read(BinaryReader reader) {
    final id = reader.read();
    final userId = reader.read();
    final name = reader.readString();
    final type = reader.readString();
    final confidence = reader.readDouble();
    final mentionCount = reader.readInt();
    final confirmed = reader.readBool();
    final createdAtStr = reader.read();
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr as String) : DateTime.now();
    final isSynced = reader.readBool();
    
    return UserEntity(
      id: id as String?,
      userId: userId as String?,
      name: name,
      type: type,
      confidence: confidence,
      mentionCount: mentionCount,
      confirmed: confirmed,
      createdAt: createdAt,
      isSynced: isSynced,
    );
  }

  @override
  void write(BinaryWriter writer, UserEntity obj) {
    writer.write(obj.id);
    writer.write(obj.userId);
    writer.writeString(obj.name);
    writer.writeString(obj.type);
    writer.writeDouble(obj.confidence);
    writer.writeInt(obj.mentionCount);
    writer.writeBool(obj.confirmed);
    writer.write(obj.createdAt.toIso8601String());
    writer.writeBool(obj.isSynced);
  }
}

@HiveType(typeId: 2)
class UserEntity extends HiveObject {
  @HiveField(0)
  String? id;
  
  @HiveField(1)
  String? userId;
  
  @HiveField(2)
  String name;
  
  @HiveField(3)
  String type; // person, product, company, place, concept, habit, goal, event, etc.
  
  @HiveField(4)
  double confidence;
  
  @HiveField(5)
  int mentionCount;
  
  @HiveField(6)
  bool confirmed;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  bool isSynced;
  
  bool get isImportant => mentionCount >= 3;

  UserEntity({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    this.confidence = 0.5,
    this.mentionCount = 1,
    this.confirmed = false,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'confidence': confidence,
      'mention_count': mentionCount,
      'confirmed': confirmed,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      name: map['name'] as String,
      type: map['type'] as String,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      mentionCount: (map['mention_count'] as num?)?.toInt() ?? 1,
      confirmed: (map['confirmed'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      isSynced: (map['is_synced'] as bool?) ?? true,
    );
  }

  UserEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? confidence,
    int? mentionCount,
    bool? confirmed,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return UserEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      mentionCount: mentionCount ?? this.mentionCount,
      confirmed: confirmed ?? this.confirmed,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

