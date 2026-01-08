import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import 'idea_detail_screen.dart';
import '../widgets/idea_card.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});

  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  final HiveService _hiveService = HiveService();
  final SyncService _syncService = SyncService();
  
  List<Idea> _ideas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
    _syncIdeas();
  }

  Future<void> _loadIdeas() async {
    setState(() => _isLoading = true);
    final ideas = await _hiveService.getIdeas();
    setState(() {
      _ideas = ideas;
      _isLoading = false;
    });
  }

  Future<void> _syncIdeas() async {
    await _syncService.syncAll();
    _loadIdeas();
  }

  Future<void> _deleteIdea(Idea idea) async {
    if (idea.id != null) {
      await _hiveService.deleteIdea(idea.id!);
      await _loadIdeas();
    }
  }

  void _navigateToDetail(Idea idea) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdeaDetailScreen(idea: idea),
      ),
    );
    if (result == true) {
      _loadIdeas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncIdeas,
            tooltip: 'Sync',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ideas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nothing yet. Your best idea is one tap away.',
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
              : RefreshIndicator(
                  onRefresh: () async {
                    await _syncIdeas();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ideas.length,
                    itemBuilder: (context, index) {
                      final idea = _ideas[index];
                      return IdeaCard(
                        idea: idea,
                        onTap: () => _navigateToDetail(idea),
                        onDelete: () => _deleteIdea(idea),
                      );
                    },
                  ),
                ),
    );
  }
}

