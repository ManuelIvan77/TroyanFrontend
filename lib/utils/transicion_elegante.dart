import 'package:flutter/material.dart';

class TransicionElegante extends PageRouteBuilder {
  final Widget page;

  TransicionElegante({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400), 
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;
            var opacityTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

            return FadeTransition(
              opacity: animation.drive(opacityTween),
              child: child,
            );
          },
        );
}