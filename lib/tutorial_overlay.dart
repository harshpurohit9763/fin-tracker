import 'package:flutter/material.dart';
import 'dart:async';

class TutorialStep {
  final GlobalKey key;
  final String text;
  final ShapeBorder shape;
  final Alignment alignment;

  TutorialStep({
    required this.key,
    required this.text,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.alignment = Alignment.bottomCenter,
  });
}

class TutorialOverlay extends StatefulWidget {
  final BuildContext context;
  final List<TutorialStep> steps;
  final VoidCallback onFinish;

  const TutorialOverlay({
    super.key,
    required this.context,
    required this.steps,
    required this.onFinish,
  });

  @override
  TutorialOverlayState createState() => TutorialOverlayState();

  static Future<void> show(
    BuildContext context,
    List<TutorialStep> steps,
    VoidCallback onFinish,
  ) {
    final completer = Completer<void>();
    // Ensure the overlay is built on top of the navigator
    final navigator = Navigator.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        context: context,
        steps: steps,
        onFinish: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
          onFinish();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    navigator.overlay?.insert(overlayEntry);
    return completer.future;
  }
}

class TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _waitForWidget();
  }

  void _waitForWidget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final step = widget.steps[_currentStep];
        final renderBox =
            step.key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          // If the widget is not ready, wait and try again.
          _waitForWidget();
        } else {
          // Widget is ready, trigger a rebuild to show the overlay.
          setState(() {});
        }
      }
    });
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
        _waitForWidget(); // Wait for the next widget to be ready
      });
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _waitForWidget();
      });
    }
  }

  void _finish() {
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStep];
    final renderBox = step.key.currentContext?.findRenderObject() as RenderBox?;

    // Don't draw anything until the widget is rendered
    if (renderBox == null || !renderBox.hasSize) {
      return const SizedBox.shrink();
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background dim
          Positioned.fill(
            child: GestureDetector(
              onTap: _finish,
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          // The "hole"
          Positioned(
            top: offset.dy,
            left: offset.dx,
            width: size.width,
            height: size.height,
            child: CustomPaint(
              painter: HolePainter(
                shape: step.shape,
              ),
            ),
          ),
          // The tooltip text
          _buildTutorialText(context, step, size, offset),
        ],
      ),
    );
  }

  Widget _buildTutorialText(
    BuildContext context,
    TutorialStep step,
    Size widgetSize,
    Offset widgetOffset,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isTop = widgetOffset.dy > screenHeight / 2;

    return Positioned(
      top: isTop
          ? null
          : widgetOffset.dy + widgetSize.height + 16,
      bottom: isTop ? screenHeight - widgetOffset.dy + 16 : null,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              step.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _prevStep,
                    child: const Text('Prev'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _nextStep,
                  child: Text(
                    _currentStep == widget.steps.length - 1
                        ? 'Finish'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HolePainter extends CustomPainter {
  final ShapeBorder shape;

  HolePainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final Path outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path innerPath = shape.getOuterPath(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final Path holePath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    // Create a transparent hole by "clearing" the area
    canvas.drawPath(holePath, Paint()..blendMode = BlendMode.clear);
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) {
    return oldDelegate.shape != shape;
  }
}
