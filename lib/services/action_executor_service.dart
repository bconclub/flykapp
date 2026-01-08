import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/idea.dart';
import '../models/idea_action.dart';
import '../config/gemini_config.dart';
import 'idea_linking_service.dart';

class ActionExecutorService {
  final IdeaLinkingService _linkingService = IdeaLinkingService();
  late final GenerativeModel _geminiModel;

  ActionExecutorService() {
    _geminiModel = GenerativeModel(
      model: 'gemini-pro',
      apiKey: GeminiConfig.apiKey,
    );
  }

  Future<Map<String, IdeaAction>> executeActions(
    Idea idea,
    List<String> actionTypes,
    Map<String, Map<String, dynamic>>? actionMetadata,
  ) async {
    final results = <String, IdeaAction>{};

    for (var actionType in actionTypes) {
      try {
        IdeaAction? action;
        
        switch (actionType) {
          case 'save':
            action = IdeaAction(type: 'save', output: 'Saved successfully');
            break;
            
          case 'research':
            action = await _executeResearch(idea);
            break;
            
          case 'nextSteps':
            action = await _executeNextSteps(idea);
            break;
            
          case 'remind':
            final metadata = actionMetadata?['remind'];
            action = IdeaAction(
              type: 'remind',
              output: 'Reminder set',
              metadata: metadata,
            );
            break;
            
          case 'validate':
            action = await _executeValidate(idea);
            break;
            
          case 'connect':
            action = await _executeConnect(idea);
            break;
            
          case 'expand':
            action = await _executeExpand(idea);
            break;
            
          case 'assign':
            final metadata = actionMetadata?['assign'];
            action = IdeaAction(
              type: 'assign',
              output: 'Assigned',
              metadata: metadata,
            );
            break;
        }
        
        if (action != null) {
          results[actionType] = action;
        }
      } catch (e) {
        print('[ActionExecutor] Error executing $actionType: $e');
        results[actionType] = IdeaAction(
          type: actionType,
          output: 'Error: $e',
        );
      }
    }

    return results;
  }

  Future<IdeaAction> _executeResearch(Idea idea) async {
    final prompt = '''
Research this idea and provide context and market information:

Idea: "${idea.transcript}"

Provide:
1. Market context (if applicable)
2. Similar existing solutions/products
3. Key considerations
4. Brief research summary (2-3 sentences)
''';

    try {
      final response = await _geminiModel.generateContent([Content.text(prompt)]);
      return IdeaAction(
        type: 'research',
        output: response.text ?? 'No research data available',
      );
    } catch (e) {
      return IdeaAction(
        type: 'research',
        output: 'Error generating research: $e',
      );
    }
  }

  Future<IdeaAction> _executeNextSteps(Idea idea) async {
    final prompt = '''
Generate 3-5 actionable next steps for this idea:

Idea: "${idea.transcript}"

Format as numbered list:
1. Step one
2. Step two
3. Step three
''';

    try {
      final response = await _geminiModel.generateContent([Content.text(prompt)]);
      return IdeaAction(
        type: 'nextSteps',
        output: response.text ?? 'No next steps generated',
      );
    } catch (e) {
      return IdeaAction(
        type: 'nextSteps',
        output: 'Error generating next steps: $e',
      );
    }
  }

  Future<IdeaAction> _executeValidate(Idea idea) async {
    final prompt = '''
Validate this idea. Check feasibility and provide pros/cons:

Idea: "${idea.transcript}"

Provide:
- Feasibility assessment (High/Medium/Low)
- Pros (3-5 points)
- Cons (3-5 points)
- Overall recommendation
''';

    try {
      final response = await _geminiModel.generateContent([Content.text(prompt)]);
      return IdeaAction(
        type: 'validate',
        output: response.text ?? 'No validation available',
      );
    } catch (e) {
      return IdeaAction(
        type: 'validate',
        output: 'Error validating: $e',
      );
    }
  }

  Future<IdeaAction> _executeConnect(Idea idea) async {
    try {
      // Find related ideas
      await _linkingService.linkNewIdea(idea);
      final relatedIdeas = idea.id != null 
          ? await _linkingService.getLinkedIdeas(idea.id!)
          : [];
      
      final output = relatedIdeas.isEmpty
          ? 'No related ideas found'
          : 'Found ${relatedIdeas.length} related ideas';
      
      return IdeaAction(
        type: 'connect',
        output: output,
        metadata: {
          'relatedCount': relatedIdeas.length,
        },
      );
    } catch (e) {
      return IdeaAction(
        type: 'connect',
        output: 'Error finding connections: $e',
      );
    }
  }

  Future<IdeaAction> _executeExpand(Idea idea) async {
    final prompt = '''
Ask 3-5 follow-up questions to expand on this idea:

Idea: "${idea.transcript}"

Generate thoughtful questions that help explore:
- Implementation details
- Potential challenges
- Opportunities
- Next considerations

Format as numbered list:
1. Question one?
2. Question two?
3. Question three?
''';

    try {
      final response = await _geminiModel.generateContent([Content.text(prompt)]);
      return IdeaAction(
        type: 'expand',
        output: response.text ?? 'No questions generated',
      );
    } catch (e) {
      return IdeaAction(
        type: 'expand',
        output: 'Error generating questions: $e',
      );
    }
  }
}

