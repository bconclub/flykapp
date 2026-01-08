import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/idea.dart';
import '../models/idea_link.dart';
import '../models/user_entity.dart';
import '../models/flow.dart';

class HiveService {
  static const String _ideasBoxName = 'ideas';
  static const String _linksBoxName = 'idea_links';
  static const String _entitiesBoxName = 'user_entities';
  static const String _flowsBoxName = 'flows';

  Future<void> init() async {
    try {
      if (kIsWeb) {
        // Web doesn't support Hive.initFlutter(), use regular init
        // For web, we'll use a different storage approach or skip Hive
        debugPrint('Hive: Web platform detected, using web storage');
      } else {
        await Hive.initFlutter();
      }
      
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(IdeaAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(IdeaLinkingAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserEntityAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(FlowAdapter());
      }
    } catch (e) {
      debugPrint('Hive init error: $e');
      // Continue anyway - app can work without Hive on web
    }
  }

  Future<Box<Idea>> getIdeasBox() async {
    if (!Hive.isBoxOpen(_ideasBoxName)) {
      return await Hive.openBox<Idea>(_ideasBoxName);
    }
    return Hive.box<Idea>(_ideasBoxName);
  }

  Future<Box<IdeaLink>> getLinksBox() async {
    if (!Hive.isBoxOpen(_linksBoxName)) {
      return await Hive.openBox<IdeaLink>(_linksBoxName);
    }
    return Hive.box<IdeaLink>(_linksBoxName);
  }

  Future<Box<UserEntity>> getEntitiesBox() async {
    if (!Hive.isBoxOpen(_entitiesBoxName)) {
      return await Hive.openBox<UserEntity>(_entitiesBoxName);
    }
    return Hive.box<UserEntity>(_entitiesBoxName);
  }

  Future<Box<Flow>> getFlowsBox() async {
    if (!Hive.isBoxOpen(_flowsBoxName)) {
      return await Hive.openBox<Flow>(_flowsBoxName);
    }
    return Hive.box<Flow>(_flowsBoxName);
  }

  // Ideas
  Future<void> saveIdea(Idea idea) async {
    final box = await getIdeasBox();
    if (idea.id != null) {
      await box.put(idea.id, idea);
    } else {
      final key = await box.add(idea);
      idea.id = key.toString();
      await box.put(key, idea);
    }
  }

  Future<List<Idea>> getIdeas() async {
    final box = await getIdeasBox();
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Idea?> getIdea(String id) async {
    final box = await getIdeasBox();
    return box.get(id);
  }

  Future<void> deleteIdea(String id) async {
    final box = await getIdeasBox();
    await box.delete(id);
  }

  Future<List<Idea>> getUnsyncedIdeas() async {
    final box = await getIdeasBox();
    return box.values.where((idea) => !idea.isSynced).toList();
  }

  // Idea Links
  Future<void> saveIdeaLink(IdeaLink link) async {
    final box = await getLinksBox();
    if (link.id != null) {
      await box.put(link.id, link);
    } else {
      final key = await box.add(link);
      link.id = key.toString();
      await box.put(key, link);
    }
  }

  Future<List<IdeaLink>> getIdeaLinks(String ideaId) async {
    final box = await getLinksBox();
    return box.values
        .where((link) => link.ideaId1 == ideaId || link.ideaId2 == ideaId)
        .toList();
  }

  Future<List<IdeaLink>> getAllIdeaLinks() async {
    final box = await getLinksBox();
    return box.values.toList();
  }

  Future<List<IdeaLink>> getUnsyncedLinks() async {
    final box = await getLinksBox();
    return box.values.where((link) => !link.isSynced).toList();
  }

  // User Entities
  Future<void> saveUserEntity(UserEntity entity) async {
    final box = await getEntitiesBox();
    if (entity.id != null) {
      await box.put(entity.id, entity);
    } else {
      final key = await box.add(entity);
      entity.id = key.toString();
      await box.put(key, entity);
    }
  }

  Future<List<UserEntity>> getUserEntities(String userId) async {
    final box = await getEntitiesBox();
    return box.values
        .where((entity) => entity.userId == userId)
        .toList()
      ..sort((a, b) => b.mentionCount.compareTo(a.mentionCount));
  }

  Future<List<UserEntity>> getAllUserEntities() async {
    final box = await getEntitiesBox();
    return box.values.toList();
  }

  Future<UserEntity?> getUserEntity(String id) async {
    final box = await getEntitiesBox();
    return box.get(id);
  }

  Future<List<UserEntity>> getUnsyncedEntities() async {
    final box = await getEntitiesBox();
    return box.values.where((entity) => !entity.isSynced).toList();
  }

  // Flows
  Future<void> saveFlow(Flow flow) async {
    final box = await getFlowsBox();
    if (flow.id != null) {
      await box.put(flow.id, flow);
    } else {
      final key = await box.add(flow);
      flow.id = key.toString();
      await box.put(key, flow);
    }
  }

  Future<List<Flow>> getFlows() async {
    final box = await getFlowsBox();
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Flow?> getFlow(String id) async {
    final box = await getFlowsBox();
    return box.get(id);
  }

  Future<void> deleteFlow(String id) async {
    final box = await getFlowsBox();
    await box.delete(id);
  }

  Future<List<Flow>> getUnsyncedFlows() async {
    final box = await getFlowsBox();
    return box.values.where((flow) => !flow.isSynced).toList();
  }

  Future<void> clearAll() async {
    final ideasBox = await getIdeasBox();
    final linksBox = await getLinksBox();
    final entitiesBox = await getEntitiesBox();
    final flowsBox = await getFlowsBox();
    await ideasBox.clear();
    await linksBox.clear();
    await entitiesBox.clear();
    await flowsBox.clear();
  }
}

