import 'package:flutter/material.dart';

class SpinningLoader extends StatefulWidget {
  const SpinningLoader({super.key});

  @override
  State<SpinningLoader> createState() => _SpinningLoaderState();
}

class _SpinningLoaderState extends State<SpinningLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Image.asset(
        'assets/images/icons/spinner.png',
        width: 50,
        height: 50,
      ),
    );
  }
}