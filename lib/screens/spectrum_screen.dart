import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/idea.dart';
import '../models/idea_link.dart';
import '../models/user_entity.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../services/auto_tagging_service.dart';
import 'idea_detail_screen.dart';

class SpectrumScreen extends StatefulWidget {
  const SpectrumScreen({super.key});

  @override
  State<SpectrumScreen> createState() => _SpectrumScreenState();
}

class _SpectrumScreenState extends State<SpectrumScreen>
    with TickerProviderStateMixin {
  final HiveService _hiveService = HiveService();
  final SyncService _syncService = SyncService();
  
  List<Idea> _ideas = [];
  List<IdeaLink> _links = [];
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _floatController;
  
  // Gesture handling
  double _scale = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  Offset _lastPanPosition = Offset.zero;
  
  // Bubble data
  List<BubbleData> _bubbles = [];
  String? _selectedBubbleId;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final ideas = await _hiveService.getIdeas();
    final links = await _hiveService.getAllIdeaLinks();
    final entities = await _hiveService.getAllUserEntities();
    
    setState(() {
      _ideas = ideas;
      _links = links;
      _bubbles = _buildBubbles(ideas, links, entities);
      _isLoading = false;
    });
  }

  Future<void> _syncData() async {
    await _syncService.syncAll();
    _loadData();
  }

  List<BubbleData> _buildBubbles(
    List<Idea> ideas,
    List<IdeaLink> links,
    List<UserEntity> entities,
  ) {
    final bubbles = <BubbleData>[];
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // Group ideas by domain or entity
    final domainGroups = <String, List<Idea>>{};
    final entityGroups = <String, List<Idea>>{};
    
    for (var idea in ideas) {
      // Group by domain
      final domain = idea.domain ?? 'Other';
      domainGroups.putIfAbsent(domain, () => []).add(idea);
      
      // Group by entity (if entity mentioned in transcript)
      for (var entity in entities) {
        if (idea.transcript.toLowerCase().contains(entity.name.toLowerCase())) {
          entityGroups.putIfAbsent(entity.id ?? entity.name, () => []).add(idea);
        }
      }
    }
    
    // Create bubbles from domain groups
    for (var entry in domainGroups.entries) {
      final domain = entry.key;
      final domainIdeas = entry.value;
      
      // Calculate recent activity (ideas in last 7 days)
      final recentCount = domainIdeas
          .where((idea) => idea.createdAt.isAfter(sevenDaysAgo))
          .length;
      final activityIntensity = domainIdeas.isEmpty
          ? 0.0
          : (recentCount / domainIdeas.length).clamp(0.0, 1.0);
      
      // Calculate position (physics-based, gravity toward center)
      final angle = (bubbles.length * 137.5) * (math.pi / 180); // Golden angle
      final radius = 100.0 + (domainIdeas.length * 10.0);
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      
      bubbles.add(BubbleData(
        id: 'domain_$domain',
        name: domain,
        ideas: domainIdeas,
        position: Offset(x, y),
        size: 30.0 + (domainIdeas.length * 5.0),
        color: AppTheme.textPrimary, // Monochrome: white
        activityIntensity: activityIntensity,
        domain: domain,
      ));
    }
    
    // Create bubbles from entity groups (only important entities)
    for (var entry in entityGroups.entries) {
      final entityId = entry.key;
      final entityIdeas = entry.value;
      final entity = entities.firstWhere(
        (e) => (e.id ?? e.name) == entityId,
        orElse: () => entities.first,
      );
      
      if (!entity.isImportant || entityIdeas.length < 2) continue;
      
      final recentCount = entityIdeas
          .where((idea) => idea.createdAt.isAfter(sevenDaysAgo))
          .length;
      final activityIntensity = entityIdeas.isEmpty
          ? 0.0
          : (recentCount / entityIdeas.length).clamp(0.0, 1.0);
      
      final angle = (bubbles.length * 137.5) * (math.pi / 180);
      final radius = 120.0 + (entityIdeas.length * 8.0);
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      
      bubbles.add(BubbleData(
        id: 'entity_$entityId',
        name: entity.name,
        ideas: entityIdeas,
        position: Offset(x, y),
        size: 25.0 + (entityIdeas.length * 4.0),
        color: AppTheme.textPrimary, // Monochrome: white
        activityIntensity: activityIntensity,
        domain: entityIdeas.firstOrNull?.domain,
      ));
    }
    
    return bubbles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Spectrum'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncData,
            tooltip: 'Sync',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bubbles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_graph_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start capturing ideas.\nWatch your knowledge universe form.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onScaleStart: (details) {
                    _lastPanPosition = details.localFocalPoint;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _scale = (_scale * details.scale).clamp(0.5, 3.0);
                      final delta = details.localFocalPoint - _lastPanPosition;
                      _panX += delta.dx;
                      _panY += delta.dy;
                      _lastPanPosition = details.localFocalPoint;
                    });
                  },
                  onTapDown: (details) {
                    final localPoint = details.localPosition;
                    final center = Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2,
                    );
                    final transformedPoint = Offset(
                      (localPoint.dx - center.dx - _panX) / _scale,
                      (localPoint.dy - center.dy - _panY) / _scale,
                    );
                    
                    // Find tapped bubble
                    for (var bubble in _bubbles) {
                      final distance = (transformedPoint - bubble.position).distance;
                      if (distance < bubble.size) {
                        setState(() {
                          _selectedBubbleId = _selectedBubbleId == bubble.id
                              ? null
                              : bubble.id;
                        });
                        break;
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      // Background ambient glow
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: [
                              AppTheme.backgroundColor,
                              AppTheme.backgroundColor.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      
                      // Bubble visualization
                      CustomPaint(
                        painter: BubblePainter(
                          bubbles: _bubbles,
                          links: _links,
                          ideas: _ideas,
                          selectedId: _selectedBubbleId,
                          scale: _scale,
                          panX: _panX,
                          panY: _panY,
                          pulseValue: _pulseController.value,
                          floatValue: _floatController.value,
                        ),
                        child: const SizedBox.expand(),
                      ),
                      
                      // Selected bubble details overlay
                      if (_selectedBubbleId != null)
                        _buildBubbleDetails(),
                      
                      // Reset button
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed: () {
                            setState(() {
                              _scale = 1.0;
                              _panX = 0.0;
                              _panY = 0.0;
                              _selectedBubbleId = null;
                            });
                          },
                          child: const Icon(Icons.center_focus_strong),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBubbleDetails() {
    final bubble = _bubbles.firstWhere(
      (b) => b.id == _selectedBubbleId,
      orElse: () => _bubbles.first,
    );
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bubble.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedBubbleId = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${bubble.ideas.length} ${bubble.ideas.length == 1 ? 'idea' : 'ideas'}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ...bubble.ideas.take(3).map((idea) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  idea.transcript.length > 60
                      ? '${idea.transcript.substring(0, 60)}...'
                      : idea.transcript,
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IdeaDetailScreen(idea: idea),
                    ),
                  );
                },
              );
            }),
            if (bubble.ideas.length > 3)
              TextButton(
                onPressed: () {
                  // Show all ideas
                },
                child: Text('View all ${bubble.ideas.length} ideas'),
              ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 300.ms).fadeIn(),
    );
  }
}

class BubbleData {
  final String id;
  final String name;
  final List<Idea> ideas;
  final Offset position;
  final double size;
  final Color color;
  final double activityIntensity;
  final String? domain;

  BubbleData({
    required this.id,
    required this.name,
    required this.ideas,
    required this.position,
    required this.size,
    required this.color,
    required this.activityIntensity,
    this.domain,
  });
}

class BubblePainter extends CustomPainter {
  final List<BubbleData> bubbles;
  final List<IdeaLink> links;
  final List<Idea> ideas;
  final String? selectedId;
  final double scale;
  final double panX;
  final double panY;
  final double pulseValue;
  final double floatValue;

  BubblePainter({
    required this.bubbles,
    required this.links,
    required this.ideas,
    this.selectedId,
    required this.scale,
    required this.panX,
    required this.panY,
    required this.pulseValue,
    required this.floatValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Apply transformations
    canvas.save();
    canvas.translate(center.dx + panX, center.dy + panY);
    canvas.scale(scale);
    
    // Draw connections (light trails)
    _drawConnections(canvas, size);
    
    // Draw bubbles
    for (var bubble in bubbles) {
      _drawBubble(canvas, bubble, size);
    }
    
    canvas.restore();
  }

  void _drawConnections(Canvas canvas, Size size) {
    final connectionPaint = Paint()
      ..color = AppTheme.borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw connections between linked ideas
    for (var link in links) {
      final bubble1 = bubbles.firstWhere(
        (b) => b.ideas.any((idea) => idea.id == link.ideaId1),
        orElse: () => bubbles.first,
      );
      final bubble2 = bubbles.firstWhere(
        (b) => b.ideas.any((idea) => idea.id == link.ideaId2),
        orElse: () => bubbles.first,
      );
      
      if (bubble1.id != bubble2.id) {
        final opacity = link.similarity.clamp(0.0, 1.0) * 0.2;
        connectionPaint.color = AppTheme.textSecondary.withOpacity(opacity);
        canvas.drawLine(bubble1.position, bubble2.position, connectionPaint);
      }
    }
  }

  void _drawBubble(Canvas canvas, BubbleData bubble, Size size) {
    final isSelected = bubble.id == selectedId;
    final isInactive = bubble.activityIntensity < 0.2;
    
    // Calculate pulse effect
    final pulse = 1.0 + (math.sin(pulseValue * 2 * math.pi) * 0.1);
    final currentSize = bubble.size * (isSelected ? 1.2 : 1.0) * pulse;
    
    // Calculate glow intensity based on activity
    final glowIntensity = isSelected
        ? 1.0
        : (bubble.activityIntensity * 0.7 + 0.3) * (isInactive ? 0.5 : 1.0);
    
    // Draw glow
    final glowPaint = Paint()
      ..color = AppTheme.textPrimary.withOpacity(0.3 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    for (var i = 0; i < 3; i++) {
      final glowSize = currentSize + (i * 10.0);
      canvas.drawCircle(
        bubble.position,
        glowSize,
        glowPaint..color = AppTheme.textPrimary.withOpacity(0.2 * glowIntensity / (i + 1)),
      );
    }
    
    // Draw bubble
    final bubblePaint = Paint()
      ..color = AppTheme.textPrimary.withOpacity(0.8 * glowIntensity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(bubble.position, currentSize, bubblePaint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = AppTheme.textPrimary.withOpacity(0.9 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(bubble.position, currentSize, borderPaint);
    
    // Draw label
    if (currentSize > 30) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: bubble.name.length > 10
              ? '${bubble.name.substring(0, 10)}...'
              : bubble.name,
          style: TextStyle(
            color: AppTheme.textPrimary.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          bubble.position.dx - textPainter.width / 2,
          bubble.position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.floatValue != floatValue ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.scale != scale ||
        oldDelegate.panX != panX ||
        oldDelegate.panY != panY;
  }
}
