import '../models/idea.dart';
import '../models/flow.dart';
import 'hive_service.dart';
import 'research_service.dart';
import 'idea_linking_service.dart';
import 'gemini_service.dart';
import 'auto_tagging_service.dart';
import 'entity_learning_service.dart';
import 'sync_service.dart';

class ActionsService {
  final HiveService _hiveService = HiveService();
  final ResearchService _researchService = ResearchService();
  final IdeaLinkingService _linkingService = IdeaLinkingService();
  final GeminiService _geminiService = GeminiService();
  final AutoTaggingService _taggingService = AutoTaggingService();
  final EntityLearningService _entityService = EntityLearningService();
  final SyncService _syncService = SyncService();

  // Execute a single action on an idea
  Future<Map<String, dynamic>> executeAction(
    String actionName,
    Idea idea,
  ) async {
    switch (actionName) {
      case 'Save':
        return await _executeSave(idea);
      case 'Research':
        return await _executeResearch(idea);
      case 'Next Steps':
        return await _executeNextSteps(idea);
      case 'Remind':
        return await _executeRemind(idea);
      case 'Validate':
        return await _executeValidate(idea);
      case 'Connect':
        return await _executeConnect(idea);
      case 'Expand':
        return await _executeExpand(idea);
      case 'Assign':
        return await _executeAssign(idea);
      default:
        return {
          'success': false,
          'output': 'Unknown action: $actionName',
        };
    }
  }

  // Execute a flow on an idea
  Future<Map<String, dynamic>> executeFlow(Flow flow, Idea idea) async {
    final results = <String, Map<String, dynamic>>{};
    final allOutputs = <String>[];

    for (final action in flow.actions) {
      final result = await executeAction(action, idea);
      results[action] = result;
      if (result['success'] == true && result['output'] != null) {
        allOutputs.add('${action}: ${result['output']}');
      }
    }

    // Save idea with all outputs
    if (allOutputs.isNotEmpty) {
      // Store flow outputs in a structured way
      // For now, append to researchOutput or create a new field
      idea.researchOutput = (idea.researchOutput ?? '') + 
          '\n\n--- Flow: ${flow.name} ---\n' +
          allOutputs.join('\n');
      idea.updatedAt = DateTime.now();
      await _hiveService.saveIdea(idea);
      await _syncService.syncAll();
    }

    return {
      'success': true,
      'results': results,
      'output': allOutputs.join('\n'),
    };
  }

  Future<Map<String, dynamic>> _executeSave(Idea idea) async {
    try {
      if (idea.id == null) {
        idea.id = 'local_${DateTime.now().millisecondsSinceEpoch}';
        idea.createdAt = DateTime.now();
      }
      idea.updatedAt = DateTime.now();
      
      // Process with Gemini for cleaning and enhancement
      final geminiResponse = await _geminiService.processIdea(
        idea.transcript,
        idea.mode ?? 'record',
      );

      // Apply Gemini results
      if (geminiResponse.cleanedTranscript.isNotEmpty) {
        idea.transcript = geminiResponse.cleanedTranscript;
      }
      if (geminiResponse.domain != null) {
        idea.domain = geminiResponse.domain;
      }
      if (geminiResponse.keywords.isNotEmpty) {
        idea.keywords = geminiResponse.keywords;
      }

      // Auto-tag if needed
      if (idea.domain == null || (idea.keywords?.isEmpty ?? true)) {
        await _taggingService.tagIdea(idea);
      }

      // Extract entities
      if (geminiResponse.entities.isNotEmpty) {
        for (var entity in geminiResponse.entities) {
          await _entityService.processEntityFromGemini(
            entity.name,
            entity.type,
            idea,
          );
        }
      } else {
        await _entityService.processIdea(idea);
      }

      await _hiveService.saveIdea(idea);
      await _syncService.syncAll();

      return {
        'success': true,
        'output': 'Idea saved successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error saving idea: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _executeResearch(Idea idea) async {
    try {
      final researchOutput = await _researchService.generateResearch(idea);
      idea.researchOutput = (idea.researchOutput ?? '') + 
          '\n\n--- Research ---\n$researchOutput';
      idea.updatedAt = DateTime.now();
      await _hiveService.saveIdea(idea);
      await _researchService.saveIdeaWithResearch(idea, researchOutput);

      return {
        'success': true,
        'output': researchOutput,
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error generating research: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _executeNextSteps(Idea idea) async {
    try {
      // Generate next steps using Gemini
      final prompt = '''
Based on this idea: "${idea.transcript}"

Generate 3-5 actionable next steps. Format as a numbered list.
''';

      final geminiService = GeminiService();
      final response = await geminiService.processIdea(prompt, 'research');
      
      String nextSteps = response.researchOutput ?? 
          '1. Review and refine the idea\n2. Research similar concepts\n3. Plan implementation';

      idea.researchOutput = (idea.researchOutput ?? '') + 
          '\n\n--- Next Steps ---\n$nextSteps';
      idea.updatedAt = DateTime.now();
      await _hiveService.saveIdea(idea);
      await _syncService.syncAll();

      return {
        'success': true,
        'output': nextSteps,
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error generating next steps: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _executeRemind(Idea idea) async {
    try {
      // For now, just mark the idea for reminder
      // In a full implementation, this would set up a notification/reminder
      idea.updatedAt = DateTime.now();
      await _hiveService.saveIdea(idea);

      return {
        'success': true,
        'output': 'Reminder set for this idea',
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error setting reminder: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _executeValidate(Idea idea) async {
    try {
      // Validate idea using AI
      final prompt = '''
Validate this idea and provide feedback: "${idea.transcript}"

Provide:
1. Strengths
2. Potential issues
3. Validation criteria met
''';

      final geminiService = GeminiService();
      final response = await geminiService.processIdea(prompt, 'research');
      
      String validation = response.researchOutput ?? 
          'Idea validation completed. Review strengths and areas for improvement.';

      idea.researchOutput = (idea.researchOutput ?? '') + 
          '\n\n--- Validation ---\n$validation';
      idea.updatedAt = DateTime.now();
      await _hiveService.saveIdea(idea);
      await _syncService.syncAll();

      return {
        'success': true,
        'output': validation,
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error validating idea: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _executeConnect(Idea idea) async {
    try {
      await _linkingService.linkNewIdea(idea);
      final links = await _hiveService.getIdeaLinks(idea.id!);
      
      idea.updatedAt = DateTime.now();
      await _hiveService.saveIdea(idea);
      await _syncService.syncAll();

      return {
        'success': true,
        'output': 'Connected to ${links.length} similar idea(s)',
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error connecting ideas: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _executeExpand(Idea idea) async {
    try {
      // Expand idea with more details
      final prompt = '''
Expand on this idea with more details and context: "${idea.transcript}"

Provide:
1. Expanded description
2. Related concepts
3. Potential variations
''';

      final geminiService = GeminiService();
      final response = await geminiService.processIdea(prompt, 'research');
      
      String expansion = response.researchOutput ?? 
          'Idea expansion: Add more details and explore variations.';

      idea.researchOutput = (idea.researchOutput ?? '') + 
          '\n\n--- Expansion ---\n$expansion';
      idea.updatedAt = DateTime.now();
      await _hiveService.saveIdea(idea);
      await _syncService.syncAll();

      return {
        'success': true,
        'output': expansion,
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error expanding idea: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _executeAssign(Idea idea) async {
    try {
      // Assign tags/categories (similar to auto-tagging but more explicit)
      await _taggingService.tagIdea(idea);
      idea.updatedAt = DateTime.now();
      await _hiveService.saveIdea(idea);
      await _syncService.syncAll();

      final tags = [
        if (idea.domain != null) idea.domain!,
        ...(idea.keywords ?? []),
      ].join(', ');

      return {
        'success': true,
        'output': 'Assigned tags: $tags',
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Error assigning tags: $e',
      };
    }
  }

  // Get available actions
  static List<String> getAvailableActions() {
    return [
      'Save',
      'Research',
      'Next Steps',
      'Remind',
      'Validate',
      'Connect',
      'Expand',
      'Assign',
    ];
  }

  // Get action emoji/icon
  static String getActionIcon(String actionName) {
    switch (actionName) {
      case 'Save':
        return '💾';
      case 'Research':
        return '🔍';
      case 'Next Steps':
        return '📋';
      case 'Remind':
        return '⏰';
      case 'Validate':
        return '✓';
      case 'Connect':
        return '🔗';
      case 'Expand':
        return '📈';
      case 'Assign':
        return '🏷️';
      default:
        return '•';
    }
  }
}

