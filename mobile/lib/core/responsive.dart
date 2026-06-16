import 'package:flutter/material.dart';

const double kinlyDesktopBreakpoint = 900;

bool kinlyIsDesktop(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= kinlyDesktopBreakpoint;
}

class KinlyPageFrame extends StatelessWidget {
  const KinlyPageFrame({
    super.key,
    required this.child,
    this.maxWidth = 920,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}
