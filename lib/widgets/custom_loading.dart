import 'dart:async';
import 'package:flutter/material.dart';

class CustomLoadingWidget extends StatefulWidget {
  final bool compact;
  const CustomLoadingWidget({super.key, this.compact = false});

  @override
  State<CustomLoadingWidget> createState() => _CustomLoadingWidgetState();
}

class _CustomLoadingWidgetState extends State<CustomLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _loadingText = '';
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    // Up and down bounce animation (Translate Y)
    _animation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (!widget.compact) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
          if (_seconds >= 10) {
            _loadingText = 'sorry ya bos';
          } else if (_seconds >= 5) {
            _loadingText = 'check your wifi bro';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.compact) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Smaller bounce for compact mode
          return Transform.translate(
            offset: Offset(0, _animation.value * 0.5),
            child: child,
          );
        },
        child: Image.asset(
          isDark ? 'assets/logo_dark.png' : 'assets/logo.png',
          width: 20,
          height: 20,
          color: isDark ? null : Colors.white,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animation.value),
                child: child,
              );
            },
            child: Image.asset(
              isDark ? 'assets/logo_dark.png' : 'assets/logo.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          if (_loadingText.isNotEmpty) ...[
            const SizedBox(height: 24), // Increased spacing for bounce room
            Text(
              _loadingText,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
