import 'package:flutter/material.dart';
import 'package:taftaf/core/constants/app_colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Real property photo fills the top section
          SizedBox(
            height: height * 0.42,
            width: double.infinity,
            child: Image.asset(
              'assets/images/bg_auth.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Dark gradient scrim so the form card blends in naturally
          Container(
            height: height * 0.42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC0D1B2A)],
                stops: [0.4, 1.0],
              ),
            ),
          ),
          // Main content
          child,
        ],
      ),
    );
  }
}
