import 'dart:math';
import 'package:flutter/material.dart';

class FloatingParticles extends StatefulWidget {
  final int count;
  final Color color;

  const FloatingParticles({
    super.key,
    this.count = 20,
    this.color = Colors.purple,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _particles = List.generate(
      widget.count,
      (index) => Particle(color: widget.color),
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
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            animation: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double speedX;
  late double speedY;
  late double size;
  Color color;

  Particle({required this.color}) {
    final random = Random();
    x = random.nextDouble();
    y = random.nextDouble();
    speedX = (random.nextDouble() - 0.5) * 0.001;
    speedY = (random.nextDouble() - 0.5) * 0.001;
    size = random.nextDouble() * 2 + 1;
  }

  void update() {
    x += speedX;
    y += speedY;

    if (x < 0 || x > 1) speedX *= -1;
    if (y < 0 || y > 1) speedY *= -1;

    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;

  ParticlePainter({required this.particles, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = particle.color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final position = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
