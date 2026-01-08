import 'package:flutter/material.dart';
import '../models/flow.dart' as models;
import '../services/hive_service.dart';
import '../services/actions_service.dart';
import '../theme/app_theme.dart';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  final HiveService _hiveService = HiveService();
  List<models.Flow> _flows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlows();
  }

  Future<void> _loadFlows() async {
    setState(() => _isLoading = true);
    try {
      final flows = await _hiveService.getFlows();
      setState(() {
        _flows = flows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading flows: $e')),
        );
      }
    }
  }

  Future<void> _createFlow() async {
    final result = await showDialog<models.Flow>(
      context: context,
      builder: (context) => const FlowBuilderDialog(),
    );

    if (result != null) {
      await _hiveService.saveFlow(result);
      _loadFlows();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flow created successfully')),
        );
      }
    }
  }

  Future<void> _deleteFlow(models.Flow flow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flow'),
        content: Text('Are you sure you want to delete "${flow.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _hiveService.deleteFlow(flow.id!);
      _loadFlows();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flow deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Create Flow Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createFlow,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Flow'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.cardColor,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                // My Flows Section
                if (_flows.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          'My Flows',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Divider(
                            color: AppTheme.borderColor,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _flows.length,
                      itemBuilder: (context, index) {
                        final flow = _flows[index];
                        return _FlowCard(
                          flow: flow,
                          onDelete: () => _deleteFlow(flow),
                        );
                      },
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No flows yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first flow to automate\nidea processing',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Available Actions Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Actions',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ActionsService.getAvailableActions()
                            .map((action) => Chip(
                                  label: Text(action),
                                  avatar: Text(
                                    ActionsService.getActionIcon(action),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  backgroundColor: AppTheme.cardColor,
                                  labelStyle: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final models.Flow flow;
  final VoidCallback onDelete;

  const _FlowCard({
    required this.flow,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    flow.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: AppTheme.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: flow.actions.asMap().entries.map((entry) {
                final action = entry.value;
                final isLast = entry.key == flow.actions.length - 1;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(action),
                      avatar: Text(
                        ActionsService.getActionIcon(action),
                        style: const TextStyle(fontSize: 14),
                      ),
                      backgroundColor: AppTheme.surfaceColor,
                      labelStyle: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class FlowBuilderDialog extends StatefulWidget {
  const FlowBuilderDialog({super.key});

  @override
  State<FlowBuilderDialog> createState() => _FlowBuilderDialogState();
}

class _FlowBuilderDialogState extends State<FlowBuilderDialog> {
  final _nameController = TextEditingController();
  final List<String> _selectedActions = [];
  final List<String> _availableActions = ActionsService.getAvailableActions();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addAction(String action) {
    setState(() {
      _selectedActions.add(action);
    });
  }

  void _removeAction(int index) {
    setState(() {
      _selectedActions.removeAt(index);
    });
  }

  void _moveAction(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final action = _selectedActions.removeAt(oldIndex);
      _selectedActions.insert(newIndex, action);
    });
  }

  void _saveFlow() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a flow name')),
      );
      return;
    }

    if (_selectedActions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one action')),
      );
      return;
    }

      final flow = models.Flow(
      name: _nameController.text.trim(),
      actions: List.from(_selectedActions),
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, flow);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Flow',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flow Name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Flow Name',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 24),
                    // Selected Actions
                    if (_selectedActions.isNotEmpty) ...[
                      Text(
                        'Flow Actions (drag to reorder)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedActions.length,
                        onReorder: _moveAction,
                        itemBuilder: (context, index) {
                          final action = _selectedActions[index];
                          return Card(
                            key: ValueKey('$action-$index'),
                            margin: const EdgeInsets.only(bottom: 8),
                            color: AppTheme.cardColor,
                            child: ListTile(
                              leading: Text(
                                ActionsService.getActionIcon(action),
                                style: const TextStyle(fontSize: 20),
                              ),
                              title: Text(
                                action,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => _removeAction(index),
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Available Actions
                    Text(
                      'Add Actions',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableActions.map((action) {
                        final isSelected = _selectedActions.contains(action);
                        return FilterChip(
                          label: Text(action),
                          avatar: Text(
                            ActionsService.getActionIcon(action),
                            style: const TextStyle(fontSize: 14),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _addAction(action);
                            } else {
                              _removeAction(_selectedActions.indexOf(action));
                            }
                          },
                          backgroundColor: AppTheme.cardColor,
                          selectedColor: AppTheme.surfaceColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Save Flow'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

