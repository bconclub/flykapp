import 'package:flutter/material.dart';
import '../models/flow.dart' as models;
import '../services/actions_service.dart';
import '../theme/app_theme.dart';

class FlowSelectionDialog extends StatefulWidget {
  final List<models.Flow> flows;

  const FlowSelectionDialog({
    super.key,
    required this.flows,
  });

  @override
  State<FlowSelectionDialog> createState() => _FlowSelectionDialogState();
}

class _FlowSelectionDialogState extends State<FlowSelectionDialog> {
  String? _selectedFlowId;
  List<String>? _customActions;
  bool _showCustomBuilder = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, null),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Just Save option
                    _FlowOption(
                      title: 'Just Save',
                      subtitle: 'Save the idea without additional processing',
                      icon: '💾',
                      isSelected: _selectedFlowId == 'just_save' && !_showCustomBuilder,
                      onTap: () {
                        setState(() {
                          _selectedFlowId = 'just_save';
                          _showCustomBuilder = false;
                          _customActions = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // User flows
                    if (widget.flows.isNotEmpty) ...[
                      Text(
                        'Your Flows',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.flows.map((flow) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _FlowOption(
                              title: flow.name,
                              subtitle: flow.actions.join(' → '),
                              icon: '▶️',
                              isSelected: _selectedFlowId == flow.id && !_showCustomBuilder,
                              onTap: () {
                                setState(() {
                                  _selectedFlowId = flow.id;
                                  _showCustomBuilder = false;
                                  _customActions = null;
                                });
                              },
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                    // Custom option
                    _FlowOption(
                      title: 'Custom',
                      subtitle: 'Pick actions to run',
                      icon: '⚙️',
                      isSelected: _showCustomBuilder,
                      onTap: () {
                        setState(() {
                          _selectedFlowId = null;
                          _showCustomBuilder = true;
                          if (_customActions == null) {
                            _customActions = ['Save'];
                          }
                        });
                      },
                    ),
                    // Custom builder
                    if (_showCustomBuilder) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Actions',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ActionsService.getAvailableActions().map((action) {
                                final isSelected = _customActions?.contains(action) ?? false;
                                return FilterChip(
                                  label: Text(action),
                                  avatar: Text(
                                    ActionsService.getActionIcon(action),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _customActions ??= [];
                                      if (selected) {
                                        _customActions!.add(action);
                                      } else {
                                        _customActions!.remove(action);
                                      }
                                      // Always include Save if empty
                                      if (_customActions!.isEmpty) {
                                        _customActions = ['Save'];
                                      }
                                    });
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
                            if (_customActions != null && _customActions!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Order: ${_customActions!.join(' → ')}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedFlowId == 'just_save') {
                        Navigator.pop(context, null); // null = just save
                      } else if (_selectedFlowId != null) {
                        final flow = widget.flows.firstWhere((f) => f.id == _selectedFlowId);
                        Navigator.pop(context, flow);
                      } else if (_showCustomBuilder && _customActions != null) {
                        Navigator.pop(context, _customActions);
                      } else {
                        // Default to just save
                        Navigator.pop(context, null);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Continue'),
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

class _FlowOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FlowOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

