import '../models/idea.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

class ResearchService {
  final HiveService _hiveService = HiveService();
  final SupabaseService _supabaseService = SupabaseService();

  // Placeholder for research functionality
  // In a real implementation, this would call an AI service
  Future<String> generateResearch(Idea idea) async {
    // Simulate research generation
    // TODO: Integrate with AI service (OpenAI, Anthropic, etc.)
    
    await Future.delayed(const Duration(seconds: 2));
    
    return '''
Research Summary for: "${idea.transcript}"

Key Points:
- This idea relates to voice-to-text technology
- Potential applications in productivity tools
- Consider integration with knowledge management systems

Related Concepts:
- Speech recognition
- Natural language processing
- Idea management

Next Steps:
- Explore similar ideas in your collection
- Consider expanding on this concept
- Link to related research areas
''';
  }

  Future<Idea> saveIdeaWithResearch(Idea idea, String researchOutput) async {
    final ideaWithResearch = idea.copyWith(
      researchOutput: researchOutput,
      mode: 'research',
    );
    
    // Save locally first
    if (ideaWithResearch.id == null) {
      ideaWithResearch.id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
    ideaWithResearch.isSynced = false;
    await _hiveService.saveIdea(ideaWithResearch);
    
    // Try to sync if online
    try {
      if (ideaWithResearch.id!.startsWith('local_')) {
        final synced = await _supabaseService.createIdea(ideaWithResearch);
        await _hiveService.deleteIdea(ideaWithResearch.id!);
        synced.isSynced = true;
        await _hiveService.saveIdea(synced);
        return synced;
      } else {
        final synced = await _supabaseService.updateIdea(ideaWithResearch);
        synced.isSynced = true;
        await _hiveService.saveIdea(synced);
        return synced;
      }
    } catch (e) {
      // Keep as unsynced
      print('Error syncing research idea: $e');
    }
    
    return ideaWithResearch;
  }
}

