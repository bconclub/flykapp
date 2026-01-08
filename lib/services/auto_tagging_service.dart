import '../models/idea.dart';

class AutoTaggingService {
  // Domain keywords for classification
  final Map<String, List<String>> _domainKeywords = {
    'Business': [
      'marketing', 'sales', 'revenue', 'profit', 'customer', 'client',
      'business', 'strategy', 'market', 'brand', 'campaign', 'advertising',
      'finance', 'budget', 'investment', 'roi', 'growth', 'revenue',
      'operations', 'process', 'workflow', 'efficiency', 'productivity',
      'team', 'management', 'leadership', 'meeting', 'presentation',
    ],
    'Tech': [
      'development', 'coding', 'programming', 'software', 'app', 'application',
      'api', 'database', 'server', 'cloud', 'infrastructure', 'architecture',
      'ai', 'machine learning', 'ml', 'algorithm', 'data', 'analytics',
      'tech', 'technology', 'platform', 'system', 'tool', 'framework',
      'code', 'bug', 'feature', 'deploy', 'build', 'test',
    ],
    'Creative': [
      'design', 'creative', 'art', 'visual', 'brand', 'identity',
      'content', 'writing', 'story', 'narrative', 'video', 'photo',
      'music', 'audio', 'podcast', 'blog', 'social media', 'instagram',
      'color', 'typography', 'layout', 'illustration', 'animation',
    ],
    'Personal': [
      'health', 'fitness', 'exercise', 'diet', 'wellness', 'mental',
      'learning', 'education', 'course', 'skill', 'hobby', 'interest',
      'relationship', 'family', 'friend', 'personal', 'life', 'goal',
      'habit', 'routine', 'meditation', 'mindfulness', 'self',
    ],
  };

  // Assign domain and keywords to an idea
  Future<void> tagIdea(Idea idea) async {
    final transcript = idea.transcript.toLowerCase();
    
    // Calculate domain scores
    final domainScores = <String, double>{};
    for (var entry in _domainKeywords.entries) {
      final domain = entry.key;
      final keywords = entry.value;
      double score = 0.0;
      
      for (var keyword in keywords) {
        if (transcript.contains(keyword.toLowerCase())) {
          score += 1.0;
        }
      }
      
      // Normalize by keyword count
      domainScores[domain] = score / keywords.length;
    }
    
    // Select top 1-2 domains
    final sortedDomains = domainScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    String? primaryDomain;
    if (sortedDomains.isNotEmpty && sortedDomains.first.value > 0.1) {
      primaryDomain = sortedDomains.first.key;
    }
    
    // Extract keywords (2-3 most relevant)
    final keywords = _extractKeywords(transcript, primaryDomain);
    
    // Update idea
    idea.domain = primaryDomain;
    idea.keywords = keywords;
  }

  // Extract 2-3 most relevant keywords from transcript
  List<String> _extractKeywords(String transcript, String? domain) {
    final keywords = <String>[];
    
    // Get domain-specific keywords first
    if (domain != null && _domainKeywords.containsKey(domain)) {
      final domainKeywords = _domainKeywords[domain]!;
      for (var keyword in domainKeywords) {
        if (transcript.contains(keyword.toLowerCase()) && keywords.length < 3) {
          keywords.add(keyword);
        }
      }
    }
    
    // If not enough keywords, extract from all domains
    if (keywords.length < 2) {
      for (var entry in _domainKeywords.entries) {
        if (entry.key == domain) continue; // Skip already processed domain
        
        for (var keyword in entry.value) {
          if (transcript.contains(keyword.toLowerCase()) && 
              !keywords.contains(keyword) && 
              keywords.length < 3) {
            keywords.add(keyword);
          }
        }
      }
    }
    
    // If still not enough, extract important words from transcript
    if (keywords.length < 2) {
      final words = transcript.split(RegExp(r'\s+'))
          .where((w) => w.length > 4) // Only longer words
          .where((w) => !_isStopWord(w))
          .toList();
      
      // Take unique words up to 3
      final uniqueWords = <String>{};
      for (var word in words) {
        if (uniqueWords.length >= 3) break;
        if (!keywords.contains(word) && !uniqueWords.contains(word)) {
          uniqueWords.add(word);
        }
      }
      keywords.addAll(uniqueWords);
    }
    
    return keywords.take(3).toList();
  }

  bool _isStopWord(String word) {
    final stopWords = {
      'that', 'this', 'with', 'from', 'have', 'been', 'will', 'would',
      'could', 'should', 'about', 'their', 'there', 'these', 'those',
      'which', 'while', 'where', 'when', 'what', 'than', 'then',
    };
    return stopWords.contains(word.toLowerCase());
  }

  // Get domain color for visualization (monochrome: shades of white/gray)
  static int getDomainColor(String? domain) {
    switch (domain) {
      case 'Tech':
        return 0xFFFFFFFF; // White
      case 'Business':
        return 0xFFCCCCCC; // Light gray
      case 'Creative':
        return 0xFF999999; // Medium gray
      case 'Personal':
        return 0xFF666666; // Dark gray
      default:
        return 0xFFFFFFFF; // White
    }
  }
}

