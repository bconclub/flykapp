import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Auth disabled for now
import '../theme/app_theme.dart';
import '../widgets/morphing_voice_bubble.dart';
import '../services/speech_service.dart';
import '../services/entity_learning_service.dart';
import '../services/auto_tagging_service.dart';
import '../services/hive_service.dart';
import '../models/idea.dart';
import '../config/test_user_config.dart';
import 'main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final SpeechService _speechService = SpeechService();
  final EntityLearningService _entityService = EntityLearningService();
  final AutoTaggingService _taggingService = AutoTaggingService();
  final HiveService _hiveService = HiveService();
  
  bool _isIntroRecording = false;
  String _introTranscript = '';
  Timer? _introTimer;
  int _introSecondsRemaining = 60;
  bool _introCompleted = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Capture',
      description: 'One tap. Never lose an idea again.',
      icon: Icons.mic,
      animation: OnboardingAnimation.voiceBubble,
    ),
    OnboardingPage(
      title: 'Connect',
      description: 'See how your ideas link.',
      icon: Icons.auto_graph,
      animation: OnboardingAnimation.networkGraph,
    ),
    OnboardingPage(
      title: 'Act',
      description: 'Get next steps, not just notes.',
      icon: Icons.checklist,
      animation: OnboardingAnimation.checklist,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _speechService.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startIntroRecording() async {
    if (_isIntroRecording) return;
    
    setState(() {
      _isIntroRecording = true;
      _introTranscript = '';
      _introSecondsRemaining = 60;
    });

    // Start 60-second timer
    _introTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _introSecondsRemaining--;
      });
      
      if (_introSecondsRemaining <= 0) {
        timer.cancel();
        _stopIntroRecording();
      }
    });

    await _speechService.startListening(
      onResult: (text) {
        setState(() {
          _introTranscript = text;
        });
      },
      onDone: () {
        _stopIntroRecording();
      },
    );
  }

  Future<void> _stopIntroRecording() async {
    if (!_isIntroRecording) return;
    
    await _speechService.stopListening();
    _introTimer?.cancel();
    
    setState(() {
      _isIntroRecording = false;
    });

    // Process intro transcript
    if (_introTranscript.trim().isNotEmpty) {
      await _processIntroTranscript();
    }
    
    setState(() {
      _introCompleted = true;
    });
  }

  Future<void> _processIntroTranscript() async {
    // Using hardcoded test user_id (auth disabled for now)
    // final userId = Supabase.instance.client.auth.currentUser?.id;
    final userId = TestUserConfig.testUserId;
    
    // Create intro idea
    final introIdea = Idea(
      transcript: _introTranscript,
      createdAt: DateTime.now(),
      mode: 'record',
      isSynced: false,
      userId: userId,
    );

    // Auto-tag
    await _taggingService.tagIdea(introIdea);

    // Extract entities (seeds knowledge graph)
    await _entityService.processIdea(introIdea);

    // Save locally
    introIdea.id = 'local_intro_${DateTime.now().millisecondsSinceEpoch}';
    await _hiveService.saveIdea(introIdea);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Show intro recording page
      if (!_introCompleted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _completeOnboarding();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length + 1, // +1 for intro recording
                itemBuilder: (context, index) {
                  if (index == _pages.length) {
                    return _buildIntroRecordingPage();
                  }
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildIndicator(index == _currentPage),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Next/Get Started button
            if (_currentPage < _pages.length)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Continue'
                          : 'Next',
                    ),
                  ),
                ),
              )
            else if (_introCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Animation/Icon
          SizedBox(
            height: 300,
            child: _buildAnimation(page),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            page.description,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildAnimation(OnboardingPage page) {
    switch (page.animation) {
      case OnboardingAnimation.voiceBubble:
        return Center(
          child: MorphingVoiceBubble(
            isRecording: false,
            transcript: '',
            onTap: () {},
          ),
        );
      
      case OnboardingAnimation.networkGraph:
        return _buildNetworkGraphPreview();
      
      case OnboardingAnimation.checklist:
        return _buildChecklistPreview();
    }
  }

  Widget _buildNetworkGraphPreview() {
    return CustomPaint(
      painter: NetworkGraphPainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildChecklistPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.checklist,
          size: 120,
          color: AppTheme.textPrimary,
        ),
        const SizedBox(height: 24),
        ...List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 200,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildIntroRecordingPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Title
          Text(
            'Tell Flyk about yourself',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Record a 60-second intro about yourself, your projects, and interests. This helps Flyk understand you better.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Voice bubble
          MorphingVoiceBubble(
            isRecording: _isIntroRecording,
            transcript: _introTranscript,
            onTap: _isIntroRecording ? _stopIntroRecording : _startIntroRecording,
          ),
          
          const SizedBox(height: 24),
          
          // Timer
          if (_isIntroRecording)
            Text(
              '$_introSecondsRemaining seconds remaining',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (_introCompleted)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Intro recorded!',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            Text(
              'Tap to start recording',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Transcript preview
          if (_introTranscript.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _introTranscript,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          
          const Spacer(),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final OnboardingAnimation animation;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.animation,
  });
}

enum OnboardingAnimation {
  voiceBubble,
  networkGraph,
  checklist,
}

class NetworkGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    // Draw nodes
    final nodes = List.generate(6, (index) {
      final angle = (index * 2 * math.pi) / 6;
      return Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    });

    // Draw connections
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if ((i - j).abs() <= 2 || (i - j).abs() >= 4) {
          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    // Draw nodes
    final nodePaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    
    for (var node in nodes) {
      canvas.drawCircle(node, 12, nodePaint);
    }
  }

  @override
  bool shouldRepaint(NetworkGraphPainter oldDelegate) => false;
}

