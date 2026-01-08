import 'package:hive/hive.dart';
import 'idea_action.dart';

class IdeaAdapter extends TypeAdapter<Idea> {
  @override
  final int typeId = 0;

  @override
  Idea read(BinaryReader reader) {
    final id = reader.read();
    final transcript = reader.readString();
    final createdAt = DateTime.parse(reader.readString());
    final updatedAtStr = reader.read();
    final updatedAt = updatedAtStr != null ? DateTime.parse(updatedAtStr as String) : null;
    final userId = reader.read();
    final researchOutput = reader.read();
    final isSynced = reader.readBool();
    final mode = reader.read();
    final domain = reader.read();
    final keywordsList = reader.read();
    final keywords = keywordsList != null ? List<String>.from(keywordsList as List) : null;
    final actionsList = reader.read();
    final actions = actionsList != null 
        ? (actionsList as List).map((a) => IdeaAction.fromMap(Map<String, dynamic>.from(a as Map))).toList()
        : null;
    
    return Idea(
      id: id as String?,
      transcript: transcript,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: userId as String?,
      researchOutput: researchOutput as String?,
      isSynced: isSynced,
      mode: mode as String?,
      domain: domain as String?,
      keywords: keywords,
      actions: actions,
    );
  }

  @override
  void write(BinaryWriter writer, Idea obj) {
    writer.write(obj.id);
    writer.writeString(obj.transcript);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.write(obj.updatedAt?.toIso8601String());
    writer.write(obj.userId);
    writer.write(obj.researchOutput);
    writer.writeBool(obj.isSynced);
    writer.write(obj.mode);
    writer.write(obj.domain);
    writer.write(obj.keywords);
    writer.write(obj.actions?.map((a) => a.toMap()).toList());
  }
}

class Idea extends HiveObject {
  String? id;
  String transcript;
  DateTime createdAt;
  DateTime? updatedAt;
  String? userId;
  String? researchOutput;
  bool isSynced;
  String? mode; // 'record' or 'research' (deprecated, use actions instead)
  String? domain; // Business, Tech, Creative, Personal
  List<String>? keywords; // Auto-assigned keywords
  List<IdeaAction>? actions; // Selected actions and their outputs

  Idea({
    this.id,
    required this.transcript,
    required this.createdAt,
    this.updatedAt,
    this.userId,
    this.researchOutput,
    this.isSynced = false,
    this.mode,
    this.domain,
    this.keywords,
    this.actions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transcript': transcript,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_id': userId,
      'research_output': researchOutput,
      'mode': mode,
      'domain': domain,
      'keywords': keywords,
      'actions': actions?.map((a) => a.toMap()).toList(),
    };
  }

  factory Idea.fromMap(Map<String, dynamic> map) {
    final keywordsData = map['keywords'];
    List<String>? keywords;
    if (keywordsData != null) {
      if (keywordsData is List) {
        keywords = keywordsData.map((e) => e.toString()).toList();
      } else if (keywordsData is String) {
        // Handle PostgreSQL array format
        keywords = keywordsData
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    
    return Idea(
      id: map['id']?.toString(),
      transcript: map['transcript'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      userId: map['user_id']?.toString(),
      researchOutput: map['research_output'] as String?,
      mode: map['mode'] as String?,
      domain: map['domain'] as String?,
      keywords: keywords,
      actions: map['actions'] != null
          ? (map['actions'] as List).map((a) => IdeaAction.fromMap(Map<String, dynamic>.from(a))).toList()
          : null,
      isSynced: true,
    );
  }

  Idea copyWith({
    String? id,
    String? transcript,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? researchOutput,
    bool? isSynced,
    String? mode,
    String? domain,
    List<String>? keywords,
    List<IdeaAction>? actions,
  }) {
    return Idea(
      id: id ?? this.id,
      transcript: transcript ?? this.transcript,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      researchOutput: researchOutput ?? this.researchOutput,
      isSynced: isSynced ?? this.isSynced,
      mode: mode ?? this.mode,
      domain: domain ?? this.domain,
      keywords: keywords ?? this.keywords,
      actions: actions ?? this.actions,
    );
  }
}
