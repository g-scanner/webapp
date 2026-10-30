// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';

/// Helper condiviso per visualizzare SnackBar/Toast coerenti con il design system
/// sull'Overlay root dell'applicazione (fluttuante in basso, angoli arrotondati,
/// visibile sia sopra i modal bottom sheet/dialog sia dopo la loro chiusura).
class AppSnackBar {
  static OverlayEntry? _currentEntry;
  static _AppSnackBarOverlayState? _currentState;

  /// Mostra una snackbar / toast sull'overlay root dell'applicazione.
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    if (!context.mounted) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Fallback per contesti senza root overlay
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        final colorScheme = Theme.of(context).colorScheme;
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor:
                isError ? colorScheme.error : colorScheme.inverseSurface,
            content: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isError
                        ? colorScheme.onError
                        : colorScheme.onInverseSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isError
                          ? colorScheme.onError
                          : colorScheme.onInverseSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: duration,
          ),
        );
      }
      return;
    }

    _dismissCurrent();

    final theme = Theme.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _AppSnackBarOverlay(
          message: message,
          isError: isError,
          duration: duration,
          icon: icon,
          theme: theme,
          onDismissed: () {
            if (_currentEntry == entry) {
              _currentEntry = null;
              _currentState = null;
            }
            if (entry.mounted) {
              entry.remove();
            }
          },
          onStateCreated: (state) {
            _currentState = state;
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Chiude immediatamente l'eventuale snackbar attiva.
  static void dismiss() {
    _dismissCurrent();
  }

  static void _dismissCurrent() {
    if (_currentState != null) {
      _currentState!.dismissImmediately();
      _currentState = null;
      _currentEntry = null;
    } else if (_currentEntry != null) {
      if (_currentEntry!.mounted) {
        _currentEntry!.remove();
      }
      _currentEntry = null;
    }
  }
}

/// Scorciatoia per visualizzare un toast/snackbar con [AppSnackBar.show].
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  AppSnackBar.show(
    context,
    message,
    isError: isError,
    duration: duration,
    icon: icon,
  );
}

class _AppSnackBarOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final IconData? icon;
  final ThemeData theme;
  final VoidCallback onDismissed;
  final ValueChanged<_AppSnackBarOverlayState> onStateCreated;

  const _AppSnackBarOverlay({
    required this.message,
    required this.isError,
    required this.duration,
    required this.icon,
    required this.theme,
    required this.onDismissed,
    required this.onStateCreated,
  });

  @override
  State<_AppSnackBarOverlay> createState() => _AppSnackBarOverlayState();
}

class _AppSnackBarOverlayState extends State<_AppSnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();

    _timer = Timer(widget.duration, () {
      _animateOut();
    });
  }

  void dismissImmediately() {
    _timer?.cancel();
    if (mounted) {
      widget.onDismissed();
    }
  }

  void _animateOut() {
    if (_isDismissing) return;
    _isDismissing = true;
    _timer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismissed();
        }
      });
    } else {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;
    final double bottomSpacing =
        (bottomInset > 0 ? bottomInset : bottomPadding) + 16;

    final bg =
        widget.isError ? colorScheme.error : colorScheme.inverseSurface;
    final fg =
        widget.isError ? colorScheme.onError : colorScheme.onInverseSurface;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomSpacing,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Dismissible(
                key: const ValueKey('AppSnackBarDismissible'),
                direction: DismissDirection.horizontal,
                onDismissed: (_) {
                  _timer?.cancel();
                  widget.onDismissed();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fg, size: 20),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: fg,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
