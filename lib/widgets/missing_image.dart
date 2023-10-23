import 'package:flutter/material.dart';

class MissingImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final lightGrey = Paint()
      ..color = const Color.fromARGB(255, 188, 188, 195)
      ..style = PaintingStyle.fill;

    final darkGrey = Paint()
      ..color = const Color.fromARGB(255, 135, 135, 135)
      ..style = PaintingStyle.fill;

    final purple = Paint()
      ..color = const Color.fromARGB(255, 247, 58, 225)
      ..style = PaintingStyle.fill;

    final orange = Paint()
      ..color = const Color.fromARGB(255, 255, 57, 0)
      ..style = PaintingStyle.fill;

    final green = Paint()
      ..color = const Color.fromARGB(255, 0, 242, 72)
      ..style = PaintingStyle.fill;

    final darkGreen = Paint()
      ..color = const Color.fromARGB(255, 0, 137, 30)
      ..style = PaintingStyle.fill;

    final lightBlue = Paint()
      ..color = const Color.fromARGB(255, 0, 251, 254)
      ..style = PaintingStyle.fill;

    final blue = Paint()
      ..color = const Color.fromARGB(255, 0, 100, 251)
      ..style = PaintingStyle.fill;

    final darkBlue = Paint()
      ..color = const Color.fromARGB(255, 0, 50, 147)
      ..style = PaintingStyle.fill;

    // Background
    canvas.drawRect(const Rect.fromLTWH(1, 1, 1, 14), white);
    canvas.drawRect(const Rect.fromLTWH(2, 1, 8, 1), white);
    canvas.drawRect(const Rect.fromLTWH(11, 2, 2, 5), white);
    canvas.drawRect(const Rect.fromLTWH(12, 10, 1, 5), white);
    canvas.drawRect(const Rect.fromLTWH(8, 14, 4, 1), white);
    canvas.drawRect(const Rect.fromLTWH(2, 2, 9, 8), lightGrey);
    canvas.drawRect(const Rect.fromLTWH(11, 5, 1, 2), lightGrey);
    canvas.drawRect(const Rect.fromLTWH(2, 9, 6, 3), lightGrey);
    canvas.drawRect(const Rect.fromLTWH(2, 12, 2, 2), lightGrey);
    canvas.drawRect(const Rect.fromLTWH(11, 11, 1, 3), lightGrey);
    canvas.drawRect(const Rect.fromLTWH(9, 13, 2, 1), lightGrey);

    // Outline
    canvas.drawRect(const Rect.fromLTWH(0, 0, 10, 1), black);
    canvas.drawRect(const Rect.fromLTWH(0, 1, 1, 15), black);
    canvas.drawRect(const Rect.fromLTWH(1, 15, 1, 1), black);
    canvas.drawRect(const Rect.fromLTWH(8, 15, 6, 1), black);
    canvas.drawRect(const Rect.fromLTWH(13, 10, 1, 5), black);
    canvas.drawRect(const Rect.fromLTWH(13, 4, 1, 3), black);
    canvas.drawRect(const Rect.fromLTWH(10, 4, 3, 1), black);

    // Green ball
    // 4, 3
    canvas.drawRect(const Rect.fromLTWH(4, 4, 1, 2), darkGreen);
    canvas.drawRect(const Rect.fromLTWH(5, 3, 2, 3), darkGreen);
    canvas.drawRect(const Rect.fromLTWH(5, 4, 1, 1), green);
    canvas.drawRect(const Rect.fromLTWH(7, 4, 1, 2), black);
    canvas.drawRect(const Rect.fromLTWH(5, 6, 2, 1), black);

    // Blue square
    // 8, 7
    canvas.drawRect(const Rect.fromLTWH(8, 7, 3, 3), blue);
    canvas.drawRect(const Rect.fromLTWH(9, 8, 1, 1), lightBlue);
    canvas.drawRect(const Rect.fromLTWH(10, 9, 1, 1), darkBlue);
    canvas.drawRect(const Rect.fromLTWH(11, 7, 1, 2), black);
    canvas.drawRect(const Rect.fromLTWH(8, 10, 2, 1), black);

    // Fuchsia triangle
    // 3, 8
    canvas.drawRect(const Rect.fromLTWH(3, 9, 2, 3), purple);
    canvas.drawRect(const Rect.fromLTWH(5, 11, 1, 1), purple);
    canvas.drawRect(const Rect.fromLTWH(3, 8, 1, 1), orange);
    canvas.drawRect(const Rect.fromLTWH(4, 9, 1, 1), orange);
    canvas.drawRect(const Rect.fromLTWH(5, 10, 1, 1), orange);
    canvas.drawRect(const Rect.fromLTWH(6, 11, 1, 1), orange);
    canvas.drawRect(const Rect.fromLTWH(3, 12, 3, 1), black);

    // Dogear
    // 10, 0
    canvas.drawRect(const Rect.fromLTWH(10, 0, 1, 4), darkGrey);
    canvas.drawRect(const Rect.fromLTWH(11, 1, 1, 1), darkGrey);
    canvas.drawRect(const Rect.fromLTWH(12, 2, 1, 1), darkGrey);
    canvas.drawRect(const Rect.fromLTWH(13, 3, 1, 1), darkGrey);

    // final paint = Paint()..style = PaintingStyle.fill;
    // final path = Path()
    //   ..moveTo(0, 0)
    //   ..lineTo(12, 10)
    //   ..lineTo(13, 13)
    //   ..lineTo(10, 12)
    //   ..close();
    // canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MissingImage extends StatelessWidget {
  const MissingImage({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: 14.0,
        height: 16.0,
        child: CustomPaint(
          painter: MissingImagePainter(),
        ),
      ),
    );
  }
}
