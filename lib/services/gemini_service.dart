import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: GeminiConfig.apiKey,
    );
  }

  Future<GeminiIdeaResponse> processIdea(String transcript, String mode) async {
    try {
      // Build prompt based on mode
      final prompt = _buildPrompt(transcript, mode);
      
      // Call Gemini API
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';
      
      // Parse response
      return _parseResponse(responseText, mode);
    } catch (e) {
      print('[GeminiService] Error: $e');
      // Return fallback response
      return GeminiIdeaResponse(
        cleanedTranscript: transcript,
        keywords: [],
        entities: [],
        domain: null,
        researchOutput: mode == 'research' ? 'Error processing with AI. Please try again.' : null,
      );
    }
  }

  String _buildPrompt(String transcript, String mode) {
    final basePrompt = '''
Analyze this voice transcript and provide structured output:

Transcript: "$transcript"

Tasks:
1. Clean the transcript: Fix grammar, remove filler words (um, uh, like), correct capitalization
2. Extract 3-5 most important keywords (comma-separated)
3. Detect entities: For each entity, provide name and type (person/product/company/concept/place/event)
4. Assign domain: One of Business, Tech, Creative, Personal, or null if unclear
''';

    if (mode == 'research') {
      return basePrompt + '''
5. Generate research output:
   - 3 actionable next steps (numbered list)
   - Brief research summary (2-3 sentences)

Format your response as JSON:
{
  "cleanedTranscript": "cleaned text here",
  "keywords": ["keyword1", "keyword2", "keyword3"],
  "entities": [
    {"name": "entity name", "type": "person|product|company|concept|place|event"}
  ],
  "domain": "Business|Tech|Creative|Personal|null",
  "researchOutput": "Next steps:\n1. Step one\n2. Step two\n3. Step three\n\nSummary: Brief summary here"
}
''';
    } else {
      return basePrompt + '''
Format your response as JSON:
{
  "cleanedTranscript": "cleaned text here",
  "keywords": ["keyword1", "keyword2", "keyword3"],
  "entities": [
    {"name": "entity name", "type": "person|product|company|concept|place|event"}
  ],
  "domain": "Business|Tech|Creative|Personal|null",
  "researchOutput": null
}
''';
    }
  }

  GeminiIdeaResponse _parseResponse(String responseText, String mode) {
    try {
      // Try to extract JSON from response
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}');
      
      if (jsonStart == -1 || jsonEnd == -1) {
        // Fallback: parse from text
        return _parseFromText(responseText, mode);
      }
      
      final jsonStr = responseText.substring(jsonStart, jsonEnd + 1);
      
      // Try proper JSON parsing first
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return _parseJsonMap(json, mode);
      } catch (e) {
        // Fallback to simple parsing
        return _parseSimpleJson(jsonStr, mode);
      }
    } catch (e) {
      print('[GeminiService] Parse error: $e');
      return _parseFromText(responseText, mode);
    }
  }

  GeminiIdeaResponse _parseJsonMap(Map<String, dynamic> json, String mode) {
    final cleanedTranscript = json['cleanedTranscript'] as String? ?? '';
    final keywords = (json['keywords'] as List<dynamic>?)
        ?.map((k) => k.toString())
        .where((k) => k.isNotEmpty)
        .toList() ?? [];
    
    final entities = <GeminiEntity>[];
    if (json['entities'] != null) {
      final entitiesList = json['entities'] as List<dynamic>;
      for (var entityJson in entitiesList) {
        if (entityJson is Map<String, dynamic>) {
          entities.add(GeminiEntity(
            name: entityJson['name']?.toString() ?? '',
            type: entityJson['type']?.toString() ?? 'concept',
          ));
        }
      }
    }
    
    final domain = json['domain']?.toString();
    final researchOutput = json['researchOutput']?.toString();
    
    return GeminiIdeaResponse(
      cleanedTranscript: cleanedTranscript,
      keywords: keywords,
      entities: entities,
      domain: domain,
      researchOutput: researchOutput,
    );
  }

  GeminiIdeaResponse _parseSimpleJson(String jsonStr, String mode) {
    // Extract cleaned transcript
    final cleanedMatch = RegExp(r'"cleanedTranscript"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
    final cleanedTranscript = cleanedMatch?.group(1) ?? '';

    // Extract keywords
    final keywordsMatch = RegExp(r'"keywords"\s*:\s*\[(.*?)\]').firstMatch(jsonStr);
    final keywordsStr = keywordsMatch?.group(1) ?? '';
    final keywords = keywordsStr
        .split(',')
        .map((k) => k.trim().replaceAll('"', ''))
        .where((k) => k.isNotEmpty)
        .toList();

    // Extract entities
    final entities = <GeminiEntity>[];
    final entityPattern = RegExp(r'\{"name"\s*:\s*"([^"]+)"\s*,\s*"type"\s*:\s*"([^"]+)"\}');
    for (var match in entityPattern.allMatches(jsonStr)) {
      entities.add(GeminiEntity(
        name: match.group(1) ?? '',
        type: match.group(2) ?? 'concept',
      ));
    }

    // Extract domain
    final domainMatch = RegExp(r'"domain"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
    final domain = domainMatch?.group(1);

    // Extract research output
    String? researchOutput;
    if (mode == 'research') {
      final researchMatch = RegExp(r'"researchOutput"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
      researchOutput = researchMatch?.group(1);
    }

    return GeminiIdeaResponse(
      cleanedTranscript: cleanedTranscript.isNotEmpty ? cleanedTranscript : '',
      keywords: keywords,
      entities: entities,
      domain: domain,
      researchOutput: researchOutput,
    );
  }

  GeminiIdeaResponse _parseFromText(String text, String mode) {
    // Fallback parsing from plain text
    final lines = text.split('\n');
    String cleanedTranscript = '';
    final keywords = <String>[];
    final entities = <GeminiEntity>[];

    for (var line in lines) {
      if (line.toLowerCase().contains('cleaned') || line.toLowerCase().contains('transcript')) {
        cleanedTranscript = line.replaceAll(RegExp(r'[^:]+:\s*'), '').trim();
      } else if (line.toLowerCase().contains('keyword')) {
        final kw = line.replaceAll(RegExp(r'[^:]+:\s*'), '').split(',').map((k) => k.trim()).toList();
        keywords.addAll(kw);
      }
    }

    return GeminiIdeaResponse(
      cleanedTranscript: cleanedTranscript.isNotEmpty ? cleanedTranscript : '',
      keywords: keywords.take(5).toList(),
      entities: entities,
      domain: null,
      researchOutput: mode == 'research' ? text : null,
    );
  }
}

class GeminiIdeaResponse {
  final String cleanedTranscript;
  final List<String> keywords;
  final List<GeminiEntity> entities;
  final String? domain;
  final String? researchOutput;

  GeminiIdeaResponse({
    required this.cleanedTranscript,
    required this.keywords,
    required this.entities,
    this.domain,
    this.researchOutput,
  });
}

class GeminiEntity {
  final String name;
  final String type; // person, product, company, concept, place, event

  GeminiEntity({
    required this.name,
    required this.type,
  });
}

