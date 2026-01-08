class IdeaAction {
  final String type; // 'save', 'research', 'nextSteps', 'remind', 'validate', 'connect', 'expand', 'assign'
  final String? output; // Action result/output
  final Map<String, dynamic>? metadata; // Additional data (e.g., reminder time, assigned person)

  IdeaAction({
    required this.type,
    this.output,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'output': output,
      'metadata': metadata,
    };
  }

  factory IdeaAction.fromMap(Map<String, dynamic> map) {
    return IdeaAction(
      type: map['type'] as String,
      output: map['output'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}



