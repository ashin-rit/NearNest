// lib/screens/common_widgets.dart
import 'package:flutter/material.dart';

class CustomGradientBackground extends StatefulWidget {
  final List<Color> gradientColors;
  final Widget child;

  const CustomGradientBackground({
    super.key,
    required this.gradientColors,
    required this.child,
  });

  @override
  _CustomGradientBackgroundState createState() => _CustomGradientBackgroundState();
}

class _CustomGradientBackgroundState extends State<CustomGradientBackground> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(widget.gradientColors[0], widget.gradientColors[1], _animation.value)!,
                Color.lerp(widget.gradientColors[1], widget.gradientColors[2], _animation.value)!,
                Color.lerp(widget.gradientColors[2], widget.gradientColors[3], _animation.value)!,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}