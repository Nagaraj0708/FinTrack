import 'package:flutter/material.dart';

class TopRightOrganicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width * 0.3, 0);
    path.quadraticBezierTo(
      size.width * 0.1, size.height * 0.3, 
      size.width * 0.5, size.height * 0.6
    );
    path.quadraticBezierTo(
      size.width * 0.9, size.height * 0.9,
      size.width, size.height
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BottomLeftOrganicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.7,
      size.width * 0.4, size.height * 0.4
    );
    path.quadraticBezierTo(
      0, size.height * 0.1,
      0, 0
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
