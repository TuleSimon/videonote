import 'package:flutter/material.dart';

class HoleWidget extends StatelessWidget {
  final Widget? child;
  final double? radius;
  const HoleWidget({required this.child, this.radius, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipPath(
        clipper: HoleClipper(radius: radius),
        child: Container(
          color: Colors.transparent,
          child: child, // Foreground color
        ),
      ),
    );
  }
}

class HoleClipper extends CustomClipper<Path> {
  final double? radius;

  HoleClipper({super.reclip, required this.radius});
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2), // Center of the widget

        radius: radius ?? 185, // Radius of the circle
      )); // Makes the circle a "hole"

    return path;
  }

  @override
  bool shouldReclip(HoleClipper oldClipper) => oldClipper.radius != radius;
}

@override
void paint(Canvas canvas, Size size) {
  // Paint the background

  Paint backgroundPaint = Paint()..color = Colors.blue;

  // Draw a rectangle as the background

  canvas.drawRect(Offset.zero & size, backgroundPaint);

  // Create a circular hole in the middle

  Paint holePaint = Paint()
    ..blendMode = BlendMode.clear; // This makes the circle transparent

  double radius = 150; // Radius of the hole

  Offset center = Offset(size.width / 2, size.height / 2); // Center of the hole

  // Draw the hole

  canvas.drawCircle(center, radius, holePaint);
}
