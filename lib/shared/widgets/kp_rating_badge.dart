import 'package:flutter/material.dart';

/// Rating pill coloured by value (green ≥7, amber ≥5, grey otherwise).
class KpRatingBadge extends StatelessWidget {
  const KpRatingBadge(this.rating, {super.key});
  final double rating;

  Color get _color {
    if (rating >= 7) return const Color(0xFF3BB33B);
    if (rating >= 5) return const Color(0xFFCC9A2E);
    return const Color(0xFF777777);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
