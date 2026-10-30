// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';

/// Helper condiviso per visualizzare SnackBar/Toast coerenti con il design system
/// sull'Overlay root dell'applicazione (fluttuante in basso, angoli arrotondati,
/// visibile sia sopra i modal bottom sheet/dialog sia dopo la loro chiusura).
class AppSnackBar {
  static OverlayEntry? _currentEntry;
  static AppSnackBarWidgetState? _currentState;

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
        return AppSnackBarWidget(
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
      _currentState!.animateOut();
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

class AppSnackBarWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final IconData? icon;
  final ThemeData theme;
  final VoidCallback onDismissed;
  final ValueChanged<AppSnackBarWidgetState> onStateCreated;

  const AppSnackBarWidget({
    super.key,
    required this.message,
    required this.isError,
    required this.duration,
    required this.icon,
    required this.theme,
    required this.onDismissed,
    required this.onStateCreated,
  });

  @override
  State<AppSnackBarWidget> createState() => AppSnackBarWidgetState();
}

class AppSnackBarWidgetState extends State<AppSnackBarWidget>
    with SingleTickerProviderStateMixin {
  // Unico controller che governa TUTTE le transizioni (entrata, uscita auto,
  // uscita manuale) — così l'animazione è sempre identica.
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  // Offset in pixel verso il basso: 72px → 0 in entrata, 0 → 72px in uscita.
  // Valore fisso così non dipende dalla dimensione dello schermo.
  late Animation<double> _slideY;

  // Stato drag per il dismiss manuale
  double _dragOffset = 0;
  bool _isDragging = false;
  bool _isDismissing = false;

  Timer? _timer;

  // Soglia oltre la quale il drag conferma il dismiss (px)
  static const double _dismissThreshold = 60.0;
  // Soglia di velocità (px/s) per un flick rapido
  static const double _velocityThreshold = 500.0;
  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
    );

    // easeOutCubic: parte lentamente, decelera naturalmente — nessun salto
    // nelle prime frame. In reverse usa easeIn (accelera mentre scende).
    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideY = Tween<double>(begin: 72.0, end: 0.0).animate(curve);

    _ctrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.duration, animateOut);
  }

  /// Esce con la stessa animazione (reverse del controller) — usata sia da
  /// auto-dismiss che da dismiss programmatico.
  void animateOut() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _timer?.cancel();
    _ctrl.reverse().whenComplete(() {
      if (mounted) widget.onDismissed();
    });
  }

  // ─── Gestione drag manuale ─────────────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    if (_isDismissing) return;
    _timer?.cancel(); // pausa il timer mentre si trascina
    _isDragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isDismissing) return;
    // Solo drag verso il basso
    final delta = details.delta.dy;
    if (_dragOffset + delta < 0) return; // blocca il drag verso l'alto
    setState(() {
      _dragOffset += delta;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging || _isDismissing) return;
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond.dy;
    final shouldDismiss =
        _dragOffset > _dismissThreshold ||
        velocity > _velocityThreshold;

    if (shouldDismiss) {
      // Completa lo slide verso il basso e poi rimuovi
      _isDismissing = true;
      _timer?.cancel();
      // Anima il drag residuo verso il basso (non torna indietro)
      _ctrl
          .animateTo(
            0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          )
          .whenComplete(() {
            if (mounted) widget.onDismissed();
          });
    } else {
      // Snap back: ritorna alla posizione originale
      setState(() => _dragOffset = 0);
      _startTimer(); // riprende il timer
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
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

    final bg = widget.isError ? colorScheme.error : colorScheme.inverseSurface;
    final fg =
        widget.isError ? colorScheme.onError : colorScheme.onInverseSurface;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomSpacing,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              // _slideY: pixel verso il basso (72→0 in entrata, 0→72 in uscita)
              // _dragOffset: pixel di drag manuale verso il basso
              final totalDy = _slideY.value + _dragOffset;

              return Transform.translate(
                offset: Offset(0, totalDy),
                child: Opacity(
                  opacity: _opacity.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
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
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
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
    );
  }
}
