import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlipClockDisplay extends StatelessWidget {
  final Duration duration;

  const FlipClockDisplay({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFlipCard(context, minutes),
        const SizedBox(width: 16),
        Text(
          ":",
          style: GoogleFonts.bebasNeue(
            fontSize: 80,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 16),
        _buildFlipCard(context, seconds),
      ],
    );
  }

  Widget _buildFlipCard(BuildContext context, String value) {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top half background (slightly lighter for depth)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 80,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF333333),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          // The Text
          Text(
            value,
            style: GoogleFonts.bebasNeue(
              fontSize: 120,
              color: const Color(0xFFE0E0E0),
              height: 1,
            ),
          ),
          // The middle split line
          Container(
            height: 2,
            width: double.infinity,
            color: Colors.black.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}
