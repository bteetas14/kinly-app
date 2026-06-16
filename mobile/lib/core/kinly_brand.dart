import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class KinlyLogo extends StatelessWidget {
  const KinlyLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kinly',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _KinlyLogoPainter()),
      ),
    );
  }
}

class KinlyTitle extends StatelessWidget {
  const KinlyTitle({super.key, this.text = 'Kinly'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const KinlyLogo(size: 30),
        const SizedBox(width: 10),
        Text(text),
      ],
    );
  }
}

class KinlyBackButton extends StatelessWidget {
  const KinlyBackButton({super.key, this.fallbackLocation = '/'});

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackLocation);
        }
      },
    );
  }
}

class _KinlyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 200;
    final scaleY = size.height / 200;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final background = Paint()..color = const Color(0xff1b1b1b);
    final foreground = Paint()..color = const Color(0xffe9e3d8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 200, 200),
        const Radius.circular(42),
      ),
      background,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(66, 38, 22, 124),
        const Radius.circular(6),
      ),
      foreground,
    );

    final upperLeaf = Path()
      ..moveTo(88, 103)
      ..cubicTo(96, 72, 132, 44, 155, 40)
      ..cubicTo(148, 62, 118, 88, 88, 103)
      ..close();
    canvas.drawPath(upperLeaf, foreground);

    final lowerLeaf = Path()
      ..moveTo(88, 103)
      ..cubicTo(118, 118, 148, 144, 155, 166)
      ..cubicTo(132, 162, 96, 134, 88, 103)
      ..close();
    canvas.drawPath(lowerLeaf, foreground);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
