import 'dart:async';
import 'package:flutter/material.dart';

class BackgroundWrapper extends StatefulWidget {
  final Widget child;

  const BackgroundWrapper({super.key, required this.child});

  @override
  State<BackgroundWrapper> createState() => _BackgroundWrapperState();
}

class _BackgroundWrapperState extends State<BackgroundWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;
  Timer? _interactionTimer;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    ); // Removed auto-repeat

    _setupAnimations();
  }

  void _setupAnimations() {
    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomLeft,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
    ]).animate(_controller);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomLeft,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  void _onInteraction() {
    if (!_isAnimating) {
      _controller.repeat(reverse: true);
      setState(() => _isAnimating = true);
    }

    _interactionTimer?.cancel();
    _interactionTimer = Timer(const Duration(seconds: 3), () {
      _controller.stop();
      setState(() => _isAnimating = false);
    });
  }

  @override
  void dispose() {
    _interactionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerDown: (_) => _onInteraction(),
      onPointerMove: (_) => _onInteraction(),
      child: Stack(
        children: [
          // Background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _topAlignmentAnimation.value,
                    end: _bottomAlignmentAnimation.value,
                    colors: isDark
                        ? const [
                            Color(0xFF0F172A), // Slate 900
                            Color(0xFF1E293B), // Slate 800
                            Color(0xFF312E81), // Indigo 900
                          ]
                        : const [
                            Colors.white,
                            Color(0xFFE1F5FE), // Light Blue 50
                            Colors.white,
                          ],
                  ),
                ),
              );
            },
          ),

          // Content
          widget.child,
        ],
      ),
    );
  }
}
