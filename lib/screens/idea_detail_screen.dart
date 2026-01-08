import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/idea.dart';
import '../services/hive_service.dart';
import '../services/idea_linking_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class IdeaDetailScreen extends StatefulWidget {
  final Idea idea;

  const IdeaDetailScreen({super.key, required this.idea});

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  final HiveService _hiveService = HiveService();
  final IdeaLinkingService _linkingService = IdeaLinkingService();
  final SyncService _syncService = SyncService();
  
  late TextEditingController _textController;
  bool _isEditing = false;
  bool _hasChanges = false;
  List<Idea> _linkedIdeas = [];
  bool _loadingLinks = true;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.idea.transcript);
    _textController.addListener(() {
      _hasChanges = _textController.text != widget.idea.transcript;
    });
    _loadLinkedIdeas();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedIdeas() async {
    if (widget.idea.id != null) {
      setState(() => _loadingLinks = true);
      final linked = await _linkingService.getLinkedIdeas(widget.idea.id!);
      setState(() {
        _linkedIdeas = linked;
        _loadingLinks = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_hasChanges && _textController.text.trim().isNotEmpty) {
      final updatedIdea = widget.idea.copyWith(
        transcript: _textController.text.trim(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await _hiveService.saveIdea(updatedIdea);
      await _syncService.syncAll();
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Idea saved')),
        );
      }
    } else {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _deleteIdea() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Idea'),
        content: const Text('Are you sure you want to delete this idea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.idea.id != null) {
      await _hiveService.deleteIdea(widget.idea.id!);
      await _syncService.syncAll();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idea'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _hasChanges ? _saveChanges : () => setState(() => _isEditing = false),
              child: Text(
                'Save',
                style: TextStyle(
                  color: _hasChanges ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteIdea,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.idea.createdAt),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (widget.idea.updatedAt != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Edited ${_formatDate(widget.idea.updatedAt!)}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (widget.idea.mode == 'research') ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Research',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            
            // Transcript
            _isEditing
                ? TextField(
                    controller: _textController,
                    maxLines: null,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.textSecondary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.textSecondary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  )
                : Text(
                    widget.idea.transcript,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
            
            // Research Output
            if (widget.idea.researchOutput != null && widget.idea.researchOutput!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Divider(color: AppTheme.textSecondary.withOpacity(0.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Next steps to make this real',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.borderColor,
                  ),
                ),
                child: Text(
                  widget.idea.researchOutput!,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            
            // Linked Ideas
            const SizedBox(height: 32),
            Divider(color: AppTheme.textSecondary.withOpacity(0.2)),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.link, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Linked Ideas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingLinks)
              const Center(child: CircularProgressIndicator())
            else if (_linkedIdeas.isEmpty)
              Text(
                'No linked ideas',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ..._linkedIdeas.map((linkedIdea) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      linkedIdea.transcript.length > 60
                          ? '${linkedIdea.transcript.substring(0, 60)}...'
                          : linkedIdea.transcript,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IdeaDetailScreen(idea: linkedIdea),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
