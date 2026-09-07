import 'package:flutter/material.dart';

/// Bird colours by colour id. Distinct hues, readable on the sky background.
const List<Color> birdPalette = [
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFFFDD835), // yellow
  Color(0xFF43A047), // green
  Color(0xFF8E24AA), // purple
  Color(0xFFFB8C00), // orange
  Color(0xFF00ACC1), // teal
  Color(0xFFEC407A), // pink
];

Color birdColour(int id) => birdPalette[id % birdPalette.length];

/// Darker companion shade for wings/outlines.
Color birdShade(int id) {
  final c = birdColour(id);
  return HSLColor.fromColor(c)
      .withLightness(
          (HSLColor.fromColor(c).lightness - 0.18).clamp(0.0, 1.0))
      .toColor();
}
