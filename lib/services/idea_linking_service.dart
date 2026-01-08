import '../models/idea.dart';
import '../models/idea_link.dart';
import 'hive_service.dart';
import 'supabase_service.dart';
import 'sync_service.dart';

class IdeaLinkingService {
  final HiveService _hiveService = HiveService();
  final SupabaseService _supabaseService = SupabaseService();
  final SyncService _syncService = SyncService();

  // Calculate similarity based on shared keywords
  double _calculateKeywordSimilarity(Idea idea1, Idea idea2) {
    final keywords1 = (idea1.keywords ?? []).map((k) => k.toLowerCase()).toSet();
    final keywords2 = (idea2.keywords ?? []).map((k) => k.toLowerCase()).toSet();
    
    if (keywords1.isEmpty && keywords2.isEmpty) {
      // Fallback to text similarity if no keywords
      return _calculateTextSimilarity(idea1.transcript, idea2.transcript);
    }
    
    if (keywords1.isEmpty || keywords2.isEmpty) return 0.0;
    
    final sharedKeywords = keywords1.intersection(keywords2).length;
    final totalKeywords = keywords1.union(keywords2).length;
    
    // Strength = shared keywords / total keywords
    return sharedKeywords / totalKeywords;
  }

  // Fallback text similarity
  double _calculateTextSimilarity(String text1, String text2) {
    final words1 = text1.toLowerCase().split(RegExp(r'\s+')).toSet();
    final words2 = text2.toLowerCase().split(RegExp(r'\s+')).toSet();
    
    if (words1.isEmpty || words2.isEmpty) return 0.0;
    
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    
    return intersection / union;
  }

  Future<void> linkNewIdea(Idea newIdea) async {
    final allIdeas = await _hiveService.getIdeas();
    final threshold = 0.2; // 20% keyword overlap threshold (lower since keywords are more specific)
    
    for (var existingIdea in allIdeas) {
      if (existingIdea.id == newIdea.id) continue;
      
      final similarity = _calculateKeywordSimilarity(newIdea, existingIdea);
      
      if (similarity >= threshold) {
        final link = IdeaLink(
          ideaId1: newIdea.id!,
          ideaId2: existingIdea.id!,
          similarity: similarity,
          createdAt: DateTime.now(),
          isSynced: false,
        );
        
        // Generate local ID
        link.id = 'local_${DateTime.now().millisecondsSinceEpoch}';
        
        await _hiveService.saveIdeaLink(link);
        
        // Try to sync if online
        if (await _syncService.isOnline()) {
          try {
            final syncedLink = await _supabaseService.createIdeaLink(link);
            syncedLink.isSynced = true;
            await _hiveService.saveIdeaLink(syncedLink);
          } catch (e) {
            // Keep as unsynced, will sync later
            print('Error syncing link: $e');
          }
        }
      }
    }
  }

  Future<List<Idea>> getLinkedIdeas(String ideaId) async {
    final links = await _hiveService.getIdeaLinks(ideaId);
    final allIdeas = await _hiveService.getIdeas();
    final linkedIds = links
        .map((link) => link.ideaId1 == ideaId ? link.ideaId2 : link.ideaId1)
        .toSet();
    
    return allIdeas.where((idea) => linkedIds.contains(idea.id)).toList();
  }
}

