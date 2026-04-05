import 'package:flutter/material.dart';

import '../theme.dart';

class UsageTrendChart extends StatelessWidget {
  const UsageTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: UsageTrendPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 110, 10, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ChartAxisLabel('M'),
            ChartAxisLabel('T'),
            ChartAxisLabel('W'),
            ChartAxisLabel('T'),
            ChartAxisLabel('F'),
          ],
        ),
      ),
    );
  }
}

class UsageTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.redAlert,
          Color(0xCCF14A43),
        ],
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..color = AppColors.redAlert
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (var index = 1; index < 4; index++) {
      final y = (size.height / 4) * index;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final points = <Offset>[
      Offset(0, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.36),
      Offset(size.width * 0.5, size.height * 0.48),
      Offset(size.width * 0.74, size.height * 0.56),
      Offset(size.width, size.height * 0.66),
    ];

    final fillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(points.first.dx, points.first.dy);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      linePath.lineTo(points[index].dx, points[index].dy);
      fillPath.lineTo(points[index].dx, points[index].dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()..color = AppColors.redAlert;
    for (final point in points) {
      canvas.drawCircle(point, 2.4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChartAxisLabel extends StatelessWidget {
  const ChartAxisLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.softText,
          ),
    );
  }
}

class ScannerBackdrop extends StatelessWidget {
  const ScannerBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF272B31),
            Color(0xFF11151B),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: ScannerNoisePainter()),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.canvas.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerFrame extends StatelessWidget {
  const ScannerFrame({super.key});

  @override
  Widget build(BuildContext context) {
    const cornerSize = 34.0;
    return Stack(
      children: const [
        CornerMark(alignment: Alignment.topLeft, size: cornerSize),
        CornerMark(alignment: Alignment.topRight, size: cornerSize),
        CornerMark(alignment: Alignment.bottomLeft, size: cornerSize),
        CornerMark(alignment: Alignment.bottomRight, size: cornerSize),
      ],
    );
  }
}

class CornerMark extends StatelessWidget {
  const CornerMark({
    super.key,
    required this.alignment,
    required this.size,
  });

  final Alignment alignment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment.x < 0;
    final isTop = alignment.y < 0;
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: CornerPainter(isLeft: isLeft, isTop: isTop),
        ),
      ),
    );
  }
}

class CornerPainter extends CustomPainter {
  CornerPainter({required this.isLeft, required this.isTop});

  final bool isLeft;
  final bool isTop;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startX = isLeft ? size.width : 0.0;
    final elbowX = isLeft ? 0.0 : size.width;
    final startY = isTop ? size.height : 0.0;
    final elbowY = isTop ? 0.0 : size.height;

    path.moveTo(startX, elbowY);
    path.lineTo(elbowX, elbowY);
    path.lineTo(elbowX, startY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScannerNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.018);
    for (var row = 0; row < 18; row++) {
      for (var column = 0; column < 9; column++) {
        final rect = Rect.fromLTWH(
          column * (size.width / 9),
          row * (size.height / 18),
          size.width / 12,
          size.height / 28,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
