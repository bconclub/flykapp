import 'package:hive/hive.dart';

class IdeaLinkingAdapter extends TypeAdapter<IdeaLink> {
  @override
  final int typeId = 1;

  @override
  IdeaLink read(BinaryReader reader) {
    final id = reader.read();
    final ideaId1 = reader.readString();
    final ideaId2 = reader.readString();
    final similarity = reader.readDouble();
    final createdAt = DateTime.parse(reader.readString());
    final isSynced = reader.readBool();
    
    return IdeaLink(
      id: id as String?,
      ideaId1: ideaId1,
      ideaId2: ideaId2,
      similarity: similarity,
      createdAt: createdAt,
      isSynced: isSynced,
    );
  }

  @override
  void write(BinaryWriter writer, IdeaLink obj) {
    writer.write(obj.id);
    writer.writeString(obj.ideaId1);
    writer.writeString(obj.ideaId2);
    writer.writeDouble(obj.similarity);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeBool(obj.isSynced);
  }
}

class IdeaLink extends HiveObject {
  String? id;
  String ideaId1;
  String ideaId2;
  double similarity;
  DateTime createdAt;
  bool isSynced;

  IdeaLink({
    this.id,
    required this.ideaId1,
    required this.ideaId2,
    required this.similarity,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idea_id_1': ideaId1,
      'idea_id_2': ideaId2,
      'similarity': similarity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IdeaLink.fromMap(Map<String, dynamic> map) {
    return IdeaLink(
      id: map['id']?.toString(),
      ideaId1: map['idea_id_1'] as String,
      ideaId2: map['idea_id_2'] as String,
      similarity: (map['similarity'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      isSynced: true,
    );
  }
}

