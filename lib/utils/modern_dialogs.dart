import 'package:flutter/material.dart';

void showModernError(BuildContext context, String error) {
  String message = error;
  Color iconColor = Colors.red;
  IconData icon = Icons.error_outline;

  // Humorous mapping
  final lowerError = error.toLowerCase();
  if (lowerError.contains('password')) {
    message = 'Aiya, wrong password lah! Try again.';
    icon = Icons.lock_open;
  } else if (lowerError.contains('user-not-found') ||
      lowerError.contains('no user')) {
    message = 'Ghost User? Can\'t find you anywhere.';
    icon = Icons.person_off;
  } else if (lowerError.contains('network') ||
      lowerError.contains('connection')) {
    message = 'Internet gone for holiday? Check wifi bro.';
    icon = Icons.wifi_off;
  } else if (lowerError.contains('email-already-in-use')) {
    message = 'This email is already famous. Login instead.';
    icon = Icons.email;
  } else if (lowerError.contains('invalid-email')) {
    message = 'That\'s not email formatting aiya!';
    icon = Icons.alternate_email;
  } else {
    message = 'Something exploded: $error';
  }

  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _TopBanner(
      message: message,
      icon: icon,
      iconColor: iconColor,
      onDismiss: () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      },
    ),
  );

  overlay.insert(overlayEntry);

  // Auto remove after 4 seconds
  Future.delayed(const Duration(seconds: 4), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

class _TopBanner extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;

  const _TopBanner({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
  });

  @override
  State<_TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<_TopBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: widget.iconColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
