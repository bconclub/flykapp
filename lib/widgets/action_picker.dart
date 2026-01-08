import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActionPicker extends StatefulWidget {
  final List<String> selectedActions;
  final Function(List<String>) onActionsChanged;
  final Function(String, Map<String, dynamic>?) onRemindTimeSelected;

  const ActionPicker({
    super.key,
    required this.selectedActions,
    required this.onActionsChanged,
    required this.onRemindTimeSelected,
  });

  @override
  State<ActionPicker> createState() => _ActionPickerState();
}

class _ActionPickerState extends State<ActionPicker> {
  final List<ActionChip> _availableActions = [
    ActionChip(
      id: 'save',
      label: 'Just Save',
      icon: Icons.save_outlined,
      isDefault: true,
    ),
    ActionChip(
      id: 'research',
      label: 'Research',
      icon: Icons.search,
      description: 'AI finds context, market info',
    ),
    ActionChip(
      id: 'nextSteps',
      label: 'Next Steps',
      icon: Icons.list_alt,
      description: 'AI generates 3-5 actions',
    ),
    ActionChip(
      id: 'remind',
      label: 'Remind',
      icon: Icons.notifications_outlined,
      description: 'Set reminder',
      requiresInput: true,
    ),
    ActionChip(
      id: 'validate',
      label: 'Validate',
      icon: Icons.check_circle_outline,
      description: 'AI checks feasibility, pros/cons',
    ),
    ActionChip(
      id: 'connect',
      label: 'Connect',
      icon: Icons.link,
      description: 'Find related ideas',
    ),
    ActionChip(
      id: 'expand',
      label: 'Expand',
      icon: Icons.auto_awesome,
      description: 'AI asks follow-up questions',
    ),
    ActionChip(
      id: 'assign',
      label: 'Assign',
      icon: Icons.person_outline,
      description: 'Tag person or project',
      requiresInput: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Ensure 'save' is always selected
    if (!widget.selectedActions.contains('save')) {
      widget.selectedActions.add('save');
    }
  }

  void _toggleAction(String actionId) {
    setState(() {
      if (actionId == 'save') {
        // 'save' cannot be deselected
        return;
      }

      if (widget.selectedActions.contains(actionId)) {
        widget.selectedActions.remove(actionId);
      } else {
        widget.selectedActions.add(actionId);
      }
      widget.onActionsChanged(widget.selectedActions);
    });
  }

  Future<void> _handleRemindAction() async {
    if (!widget.selectedActions.contains('remind')) {
      _toggleAction('remind');
    }

    // Show time picker
    final time = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RemindTimePicker(),
    );

    if (time != null) {
      widget.onRemindTimeSelected('remind', time);
    }
  }

  Future<void> _handleAssignAction() async {
    if (!widget.selectedActions.contains('assign')) {
      _toggleAction('assign');
    }

    // Show assign picker
    final assignData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AssignPicker(),
    );

    if (assignData != null) {
      widget.onRemindTimeSelected('assign', assignData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to do?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableActions.map((action) {
            final isSelected = widget.selectedActions.contains(action.id);
            return GestureDetector(
              onTap: () {
                if (action.id == 'remind') {
                  _handleRemindAction();
                } else if (action.id == 'assign') {
                  _handleAssignAction();
                } else {
                  _toggleAction(action.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.surfaceColor,
                  border: Border.all(
                    color: isSelected ? AppTheme.textPrimary : AppTheme.borderColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action.icon,
                      size: 18,
                      color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action.label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (action.description != null)
                          Text(
                            action.description!,
                            style: TextStyle(
                              color: isSelected 
                                  ? AppTheme.backgroundColor.withOpacity(0.7)
                                  : AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ActionChip {
  final String id;
  final String label;
  final IconData icon;
  final String? description;
  final bool isDefault;
  final bool requiresInput;

  ActionChip({
    required this.id,
    required this.label,
    required this.icon,
    this.description,
    this.isDefault = false,
    this.requiresInput = false,
  });
}

class _RemindTimePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Text(
        'Set Reminder',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimeOption(
            label: '1 hour',
            onTap: () => Navigator.pop(context, {'time': '1h'}),
          ),
          _TimeOption(
            label: 'Tomorrow',
            onTap: () => Navigator.pop(context, {'time': 'tomorrow'}),
          ),
          _TimeOption(
            label: 'Next week',
            onTap: () => Navigator.pop(context, {'time': 'nextWeek'}),
          ),
          _TimeOption(
            label: 'Custom',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  final customDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  Navigator.pop(context, {
                    'time': 'custom',
                    'dateTime': customDateTime.toIso8601String(),
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TimeOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimeOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: TextStyle(color: AppTheme.textPrimary)),
      onTap: onTap,
    );
  }
}

class _AssignPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Text(
        'Assign to',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: TextField(
        controller: controller,
        style: TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Person or project name',
          hintStyle: TextStyle(color: AppTheme.textSecondary),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.borderColor),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              Navigator.pop(context, {
                'assignee': controller.text,
              });
            }
          },
          child: Text('Assign', style: TextStyle(color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}

