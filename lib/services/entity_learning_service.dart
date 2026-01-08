import 'dart:math';
import '../models/user_entity.dart';
import '../models/idea.dart';
import 'hive_service.dart';
import 'supabase_service.dart';
import 'sync_service.dart';

class EntityLearningService {
  final HiveService _hiveService = HiveService();
  final SupabaseService _supabaseService = SupabaseService();
  final SyncService _syncService = SyncService();

  // Entity type patterns for classification
  final Map<String, List<String>> _typePatterns = {
    'person': [
      'i', 'me', 'my', 'myself', 'we', 'our', 'us', 'he', 'she', 'they',
      'friend', 'colleague', 'partner', 'team', 'client', 'customer',
      'mr', 'mrs', 'dr', 'professor', 'manager', 'director',
    ],
    'product': [
      'app', 'software', 'tool', 'platform', 'service', 'product',
      'feature', 'functionality', 'system', 'solution',
    ],
    'company': [
      'company', 'business', 'startup', 'corporation', 'firm',
      'organization', 'enterprise', 'agency', 'studio',
    ],
    'place': [
      'location', 'city', 'country', 'office', 'home', 'place',
      'venue', 'restaurant', 'cafe', 'park', 'beach',
    ],
    'concept': [
      'idea', 'concept', 'theory', 'principle', 'method', 'approach',
      'strategy', 'philosophy', 'framework', 'model',
    ],
    'habit': [
      'habit', 'routine', 'daily', 'weekly', 'always', 'never',
      'regularly', 'often', 'sometimes', 'practice',
    ],
    'goal': [
      'goal', 'objective', 'target', 'aim', 'want', 'need',
      'achieve', 'accomplish', 'reach', 'plan', 'intend',
    ],
    'event': [
      'meeting', 'conference', 'event', 'workshop', 'seminar',
      'party', 'celebration', 'launch', 'deadline', 'milestone',
    ],
  };

  // Extract entities from transcript
  Future<List<UserEntity>> extractEntities(String transcript, String? userId) async {
    final entities = <UserEntity>[];
    
    // Extract potential entities (capitalized words, quoted phrases, etc.)
    final potentialEntities = _extractPotentialEntities(transcript);
    
    for (var entityName in potentialEntities) {
      final type = _classifyEntityType(entityName, transcript);
      final confidence = _calculateConfidence(entityName, type, transcript);
      
      if (confidence > 0.3) { // Only include entities with reasonable confidence
        final entity = UserEntity(
          name: entityName,
          type: type,
          confidence: confidence,
          mentionCount: 1,
          userId: userId,
          createdAt: DateTime.now(),
        );
        
        entities.add(entity);
      }
    }
    
    return entities;
  }

  // Extract potential entity names from text
  List<String> _extractPotentialEntities(String text) {
    final entities = <String>{};
    
    // Extract capitalized words/phrases (likely proper nouns)
    final capitalizedPattern = RegExp(r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b');
    final matches = capitalizedPattern.allMatches(text);
    for (var match in matches) {
      final entity = match.group(0)!.trim();
      if (entity.length > 2 && !_isCommonWord(entity)) {
        entities.add(entity);
      }
    }
    
    // Extract quoted phrases
    final quotedPattern = RegExp(r'"([^"]+)"');
    final quotedMatches = quotedPattern.allMatches(text);
    for (var match in quotedMatches) {
      entities.add(match.group(1)!.trim());
    }
    
    // Extract words after "my", "our", "the", etc.
    final possessivePattern = RegExp(r'\b(my|our|the|a|an)\s+([a-z]+(?:\s+[a-z]+){0,2})\b', caseSensitive: false);
    final possessiveMatches = possessivePattern.allMatches(text);
    for (var match in possessiveMatches) {
      final entity = match.group(2)!.trim();
      if (entity.length > 3 && !_isCommonWord(entity)) {
        entities.add(entity);
      }
    }
    
    return entities.toList();
  }

  // Classify entity type based on context
  String _classifyEntityType(String entityName, String context) {
    final lowerContext = context.toLowerCase();
    final lowerEntity = entityName.toLowerCase();
    
    // Check against type patterns
    for (var entry in _typePatterns.entries) {
      final type = entry.key;
      final patterns = entry.value;
      
      for (var pattern in patterns) {
        if (lowerContext.contains(pattern) || lowerEntity.contains(pattern)) {
          return type;
        }
      }
    }
    
    // Default classification based on entity characteristics
    if (_isLikelyPerson(entityName)) return 'person';
    if (_isLikelyPlace(entityName)) return 'place';
    if (_isLikelyProduct(entityName)) return 'product';
    
    return 'concept'; // Default fallback
  }

  bool _isLikelyPerson(String name) {
    final personIndicators = ['mr', 'mrs', 'dr', 'prof', 'sir', 'madam'];
    final lower = name.toLowerCase();
    return personIndicators.any((indicator) => lower.startsWith(indicator));
  }

  bool _isLikelyPlace(String name) {
    final placeIndicators = ['city', 'street', 'avenue', 'park', 'beach', 'mountain'];
    final lower = name.toLowerCase();
    return placeIndicators.any((indicator) => lower.contains(indicator));
  }

  bool _isLikelyProduct(String name) {
    final productIndicators = ['app', 'software', 'tool', 'platform', 'system'];
    final lower = name.toLowerCase();
    return productIndicators.any((indicator) => lower.contains(indicator));
  }

  bool _isCommonWord(String word) {
    final commonWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
      'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
      'should', 'could', 'may', 'might', 'must', 'can', 'this', 'that',
      'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
    };
    return commonWords.contains(word.toLowerCase());
  }

  double _calculateConfidence(String entityName, String type, String context) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence if entity appears multiple times
    final occurrences = entityName.toLowerCase().allMatches(context.toLowerCase()).length;
    confidence += (occurrences - 1) * 0.1;
    
    // Increase confidence if entity is capitalized (likely proper noun)
    if (entityName[0] == entityName[0].toUpperCase()) {
      confidence += 0.2;
    }
    
    // Increase confidence if entity is quoted
    if (context.contains('"$entityName"')) {
      confidence += 0.15;
    }
    
    // Increase confidence based on type match quality
    final typePatterns = _typePatterns[type] ?? [];
    final contextLower = context.toLowerCase();
    if (typePatterns.any((pattern) => contextLower.contains(pattern))) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  // Process entity from Gemini response
  Future<void> processEntityFromGemini(String entityName, String entityType, Idea idea) async {
    if (idea.userId == null) return;
    
    final entity = UserEntity(
      name: entityName,
      type: entityType,
      confidence: 0.9, // High confidence from Gemini
      mentionCount: 1,
      userId: idea.userId,
      createdAt: DateTime.now(),
    );
    
    // Check if entity already exists
    final existingEntities = await _hiveService.getUserEntities(idea.userId!);
    final existing = existingEntities.firstWhere(
      (e) => e.name.toLowerCase() == entity.name.toLowerCase(),
      orElse: () => entity,
    );
    
    if (existing.id != null) {
      // Update existing entity
      final updated = existing.copyWith(
        mentionCount: existing.mentionCount + 1,
        confidence: max(existing.confidence, entity.confidence),
      );
      await _hiveService.saveUserEntity(updated);
      
      // Try to sync
      if (await _syncService.isOnline()) {
        try {
          await _supabaseService.updateUserEntity(updated);
          updated.isSynced = true;
          await _hiveService.saveUserEntity(updated);
        } catch (e) {
          print('Error syncing entity: $e');
        }
      }
    } else {
      // Create new entity
      entity.id = 'local_${DateTime.now().millisecondsSinceEpoch}';
      await _hiveService.saveUserEntity(entity);
      
      // Try to sync
      if (await _syncService.isOnline()) {
        try {
          final synced = await _supabaseService.createUserEntity(entity);
          synced.isSynced = true;
          await _hiveService.saveUserEntity(synced);
        } catch (e) {
          print('Error syncing entity: $e');
        }
      }
    }
  }

  // Process a new idea and update entities
  Future<void> processIdea(Idea idea) async {
    if (idea.userId == null) return;
    
    final entities = await extractEntities(idea.transcript, idea.userId);
    
    for (var newEntity in entities) {
      // Check if entity already exists
      final existingEntities = await _hiveService.getUserEntities(idea.userId!);
      final existing = existingEntities.firstWhere(
        (e) => e.name.toLowerCase() == newEntity.name.toLowerCase(),
        orElse: () => newEntity,
      );
      
      if (existing.id != null) {
        // Update existing entity
        final updated = existing.copyWith(
          mentionCount: existing.mentionCount + 1,
          confidence: max(existing.confidence, newEntity.confidence),
        );
        await _hiveService.saveUserEntity(updated);
        
        // Try to sync
        if (await _syncService.isOnline()) {
          try {
            await _supabaseService.updateUserEntity(updated);
            updated.isSynced = true;
            await _hiveService.saveUserEntity(updated);
          } catch (e) {
            print('Error syncing entity: $e');
          }
        }
      } else {
        // Create new entity
        newEntity.id = 'local_${DateTime.now().millisecondsSinceEpoch}';
        await _hiveService.saveUserEntity(newEntity);
        
        // Try to sync
        if (await _syncService.isOnline()) {
          try {
            final synced = await _supabaseService.createUserEntity(newEntity);
            synced.isSynced = true;
            await _hiveService.saveUserEntity(synced);
          } catch (e) {
            print('Error syncing entity: $e');
          }
        }
      }
    }
  }

  // Get important entities (3+ mentions)
  Future<List<UserEntity>> getImportantEntities(String? userId) async {
    if (userId == null) return [];
    final entities = await _hiveService.getUserEntities(userId);
    return entities.where((e) => e.isImportant).toList();
  }

  // Update entity type (user correction)
  Future<void> updateEntityType(String entityId, String newType) async {
    final entities = await _hiveService.getAllUserEntities();
    final entity = entities.firstWhere((e) => e.id == entityId);
    
    final updated = entity.copyWith(
      type: newType,
      confirmed: true,
    );
    
    await _hiveService.saveUserEntity(updated);
    
    if (await _syncService.isOnline()) {
      try {
        await _supabaseService.updateUserEntity(updated);
        updated.isSynced = true;
        await _hiveService.saveUserEntity(updated);
      } catch (e) {
        print('Error syncing entity update: $e');
      }
    }
  }
}

