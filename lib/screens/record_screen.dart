import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';
import '../services/gemini_service.dart';
import '../services/actions_service.dart';
import '../models/idea.dart';
import '../models/flow.dart' as models;
import '../config/test_user_config.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Auth disabled for now
import '../theme/app_theme.dart';
import '../widgets/morphing_voice_bubble.dart';
import '../widgets/flow_selection_dialog.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final SpeechService _speechService = SpeechService();
  final HiveService _hiveService = HiveService();
  final SyncService _syncService = SyncService();
  final GeminiService _geminiService = GeminiService();
  final ActionsService _actionsService = ActionsService();

  bool _isRecording = false;
  String _currentTranscript = '';
  bool _isProcessing = false;
  String? _currentFlowExecutionStep;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _speechService.initialize();
  }

  Future<void> _startRecording() async {
    if (!_isRecording) {
      setState(() {
        _isRecording = true;
        _currentTranscript = '';
      });

      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _currentTranscript = text;
          });
        },
        onDone: () async {
          await _processRecording();
        },
      );
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _speechService.stopListening();
      await _processRecording();
    }
  }

  Future<void> _processRecording() async {
    if (_currentTranscript.trim().isEmpty) {
      setState(() {
        _isRecording = false;
        _currentTranscript = '';
      });
      return;
    }

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    try {
      // Create basic idea from transcript
      final userId = TestUserConfig.testUserId;
      
      // Initial processing with Gemini for cleaning
      final geminiResponse = await _geminiService.processIdea(
        _currentTranscript,
        'record',
      );

      final cleanedTranscript = geminiResponse.cleanedTranscript.isNotEmpty
          ? geminiResponse.cleanedTranscript
          : _autoCorrect(_currentTranscript);

      final idea = Idea(
        transcript: cleanedTranscript,
        createdAt: DateTime.now(),
        mode: 'record',
        isSynced: false,
        userId: userId,
      );

      idea.id = 'local_${DateTime.now().millisecondsSinceEpoch}';

      // Apply initial Gemini results
      if (geminiResponse.domain != null) {
        idea.domain = geminiResponse.domain;
      }
      if (geminiResponse.keywords.isNotEmpty) {
        idea.keywords = geminiResponse.keywords;
      }

      // Show flow selection dialog
      final selectedFlow = await _showFlowSelectionDialog();
      
      if (!mounted) return;

      // Execute selected flow or just save
      if (selectedFlow == null) {
        // Just Save - execute Save action
        await _executeFlowWithProgress(idea, ['Save']);
      } else if (selectedFlow is models.Flow) {
        // User selected a flow
        await _executeFlowWithProgress(idea, selectedFlow.actions);
      } else if (selectedFlow is List<String>) {
        // Custom flow (list of action names)
        await _executeFlowWithProgress(idea, selectedFlow);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Idea saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing idea: $e'),
            backgroundColor: AppTheme.textSecondary,
          ),
        );
      }
    } finally {
      setState(() {
        _currentTranscript = '';
        _isProcessing = false;
        _currentFlowExecutionStep = null;
      });
    }
  }

  Future<void> _executeFlowWithProgress(Idea idea, List<String> actions) async {
    setState(() => _currentFlowExecutionStep = 'Starting...');

    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      setState(() => _currentFlowExecutionStep = '${i + 1}/${actions.length}: $action');
      
      await _actionsService.executeAction(action, idea);
    }

    // Final save and sync
    setState(() => _currentFlowExecutionStep = 'Saving...');
    idea.updatedAt = DateTime.now();
    await _hiveService.saveIdea(idea);
    await _syncService.syncAll();
  }

  Future<dynamic> _showFlowSelectionDialog() async {
    final flows = await _hiveService.getFlows();
    
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FlowSelectionDialog(flows: flows),
    );
  }

  String _autoCorrect(String text) {
    if (text.isEmpty) return text;
    
    // Simple auto-correction: capitalize first letter
    final sentences = text.split(RegExp(r'[.!?]\s+'));
    return sentences
        .map((s) => s.trim().isEmpty
            ? ''
            : s.trim()[0].toUpperCase() + s.trim().substring(1))
        .join('. ')
        .trim();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture'),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  if (_currentFlowExecutionStep != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _currentFlowExecutionStep!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MorphingVoiceBubble(
                    isRecording: _isRecording,
                    transcript: _currentTranscript,
                    onTap: _isRecording ? _stopRecording : _startRecording,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isRecording ? 'Capturing...' : 'Flyk it',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!_isRecording)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Your ideas deserve more than a graveyard. Tap to start.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

