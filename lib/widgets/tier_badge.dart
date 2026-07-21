import 'package:flutter/material.dart';

const tierColors = {
  'S': Color(0xFFFF6B5F),
  'A': Color(0xFFFFA94D),
  'B': Color(0xFFFFD43B),
  'C': Color(0xFF69DB7C),
  'D': Color(0xFF4DABF7),
  'F': Color(0xFF9775FA),
};

class TierBadge extends StatelessWidget {
  const TierBadge(this.tier, {super.key, this.size = 38});
  final String tier;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tierColors[tier],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      tier,
      style: TextStyle(
        fontSize: size * .5,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    ),
  );
}
