import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/idea.dart';
import '../models/idea_link.dart';
import '../models/user_entity.dart';
import '../models/flow.dart';
import '../config/test_user_config.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Auth methods - COMMENTED OUT FOR NOW (will re-enable later)
  // Future<AuthResponse> signUp(String email, String password) async {
  //   return await _client.auth.signUp(
  //     email: email,
  //     password: password,
  //   );
  // }

  // Future<AuthResponse> signIn(String email, String password) async {
  //   return await _client.auth.signInWithPassword(
  //     email: email,
  //     password: password,
  //   );
  // }

  // Future<void> signOut() async {
  //   await _client.auth.signOut();
  // }

  // User? get currentUser => _client.auth.currentUser;

  // Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Ideas CRUD
  Future<Idea> createIdea(Idea idea) async {
    // Using hardcoded test user_id (auth disabled for now)
    final ideaMap = idea.toMap();
    ideaMap['user_id'] = TestUserConfig.testUserId;
    ideaMap.remove('id'); // Let Supabase generate UUID
    
    final response = await _client
        .from('ideas')
        .insert(ideaMap)
        .select()
        .single();
    return Idea.fromMap(response);
  }

  Future<List<Idea>> getIdeas() async {
    final response = await _client
        .from('ideas')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => Idea.fromMap(e)).toList();
  }

  Future<Idea> updateIdea(Idea idea) async {
    final response = await _client
        .from('ideas')
        .update(idea.toMap())
        .eq('id', idea.id!)
        .select()
        .single();
    return Idea.fromMap(response);
  }

  Future<void> deleteIdea(String id) async {
    await _client.from('ideas').delete().eq('id', id);
  }

  // Idea Links
  Future<IdeaLink> createIdeaLink(IdeaLink link) async {
    final linkMap = link.toMap();
    linkMap.remove('id'); // Let Supabase generate UUID
    
    final response = await _client
        .from('idea_links')
        .insert(linkMap)
        .select()
        .single();
    return IdeaLink.fromMap(response);
  }

  Future<List<IdeaLink>> getIdeaLinks(String ideaId) async {
    final response = await _client
        .from('idea_links')
        .select()
        .or('idea_id_1.eq.$ideaId,idea_id_2.eq.$ideaId');
    return (response as List).map((e) => IdeaLink.fromMap(e)).toList();
  }

  Future<List<IdeaLink>> getAllIdeaLinks() async {
    final response = await _client.from('idea_links').select();
    return (response as List).map((e) => IdeaLink.fromMap(e)).toList();
  }

  // User Entities CRUD
  Future<UserEntity> createUserEntity(UserEntity entity) async {
    // Using hardcoded test user_id (auth disabled for now)
    final entityMap = entity.toMap();
    entityMap['user_id'] = TestUserConfig.testUserId;
    entityMap.remove('id'); // Let Supabase generate UUID
    
    final response = await _client
        .from('user_entities')
        .insert(entityMap)
        .select()
        .single();
    return UserEntity.fromMap(response);
  }

  Future<List<UserEntity>> getUserEntities() async {
    // Using hardcoded test user_id (auth disabled for now)
    final response = await _client
        .from('user_entities')
        .select()
        .eq('user_id', TestUserConfig.testUserId)
        .order('mention_count', ascending: false);
    return (response as List).map((e) => UserEntity.fromMap(e)).toList();
  }

  Future<UserEntity> updateUserEntity(UserEntity entity) async {
    final entityMap = entity.toMap();
    entityMap.remove('id'); // Don't update ID
    
    final response = await _client
        .from('user_entities')
        .update(entityMap)
        .eq('id', entity.id!)
        .select()
        .single();
    return UserEntity.fromMap(response);
  }

  Future<void> deleteUserEntity(String id) async {
    await _client.from('user_entities').delete().eq('id', id);
  }

  // Flows CRUD
  Future<Flow> createFlow(Flow flow) async {
    final flowMap = flow.toMap();
    flowMap['user_id'] = TestUserConfig.testUserId;
    flowMap.remove('id'); // Let Supabase generate UUID
    
    final response = await _client
        .from('flows')
        .insert(flowMap)
        .select()
        .single();
    return Flow.fromMap(response);
  }

  Future<List<Flow>> getFlows() async {
    final response = await _client
        .from('flows')
        .select()
        .eq('user_id', TestUserConfig.testUserId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Flow.fromMap(e)).toList();
  }

  Future<Flow> updateFlow(Flow flow) async {
    final flowMap = flow.toMap();
    flowMap.remove('id');
    
    final response = await _client
        .from('flows')
        .update(flowMap)
        .eq('id', flow.id!)
        .select()
        .single();
    return Flow.fromMap(response);
  }

  Future<void> deleteFlow(String id) async {
    await _client.from('flows').delete().eq('id', id);
  }
}

