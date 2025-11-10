import 'package:flutter/material.dart';

class OverlappingCardView extends StatefulWidget {
  final List<Widget> children;
  final double overlap;

  const OverlappingCardView({
    super.key,
    required this.children,
    this.overlap = 40.0,
  });

  @override
  State<OverlappingCardView> createState() => _OverlappingCardViewState();
}

class _OverlappingCardViewState extends State<OverlappingCardView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = 0;
            if (_pageController.hasClients &&
                _pageController.position.haveDimensions) {
              page = _pageController.page ?? 0;
            }

            double value = (index - page);
            double scale = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
            double yOffset = value * -widget.overlap;

            return Transform.translate(
                offset: Offset(0, yOffset),
                child: Transform.scale(scale: scale, child: child));
          },
          child: widget.children[index],
        );
      },
    );
  }
}
