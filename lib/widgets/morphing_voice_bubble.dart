import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MorphingVoiceBubble extends StatefulWidget {
  final bool isRecording;
  final String transcript;
  final VoidCallback onTap;

  const MorphingVoiceBubble({
    super.key,
    required this.isRecording,
    required this.transcript,
    required this.onTap,
  });

  @override
  State<MorphingVoiceBubble> createState() => _MorphingVoiceBubbleState();
}

class _MorphingVoiceBubbleState extends State<MorphingVoiceBubble>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _pulseController;
  late Animation<double> _morphAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    _morphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MorphingVoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _morphController.repeat(reverse: true);
        _pulseController.repeat();
      } else {
        _morphController.stop();
        _pulseController.stop();
        _morphController.reset();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_morphAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Container(
            width: widget.isRecording ? 120 * _pulseAnimation.value : 100,
            height: widget.isRecording ? 120 * _pulseAnimation.value : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: widget.isRecording
                    ? [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.7),
                      ]
                    : [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
              ),
              boxShadow: widget.isRecording
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 30 * _pulseAnimation.value,
                        spreadRadius: 10 * _pulseAnimation.value,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
            ),
            child: CustomPaint(
              painter: _MorphingPainter(
                progress: widget.isRecording ? _morphAnimation.value : 0.0,
                isRecording: widget.isRecording,
              ),
              child: Center(
                child: Icon(
                  widget.isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MorphingPainter extends CustomPainter {
  final double progress;
  final bool isRecording;

  _MorphingPainter({
    required this.progress,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRecording) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw morphing waves
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final waveRadius = radius * (0.5 + waveProgress * 0.5);
      final opacity = (1.0 - waveProgress) * 0.5;
      
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(center, waveRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_MorphingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isRecording != isRecording;
  }
}

