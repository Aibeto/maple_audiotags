import 'dart:math';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class UIConfig {
  static LiquidGlassSettings get baseSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 1.0,
        lightAngle: 0.3 * pi,
        lightIntensity: 0.4,
        ambientStrength: 0.1,
        blend: 0.3,
        refractiveIndex: 1.1,
        chromaticAberration: 0.1,
        saturation: 1.02,
      );

  static LiquidGlassSettings get smallButtonSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 1.1,
        lightAngle: 0.3 * pi,
        lightIntensity: 0.3,
        ambientStrength: 0.12,
        blend: 0.2,
        refractiveIndex: 1.15,
        chromaticAberration: 0.12,
        saturation: 1.05,
      );

  static LiquidGlassSettings get largeButtonSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 1.2,
        lightAngle: 0.35 * pi,
        lightIntensity: 0.5,
        ambientStrength: 0.15,
        blend: 0.3,
        refractiveIndex: 1.15,
        chromaticAberration: 0.15,
        saturation: 1.04,
      );

  static LiquidGlassSettings get dialogSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 0.9,
        lightAngle: 0.32 * pi,
        lightIntensity: 0.4,
        ambientStrength: 0.12,
        blend: 0.3,
        refractiveIndex: 1.1,
        chromaticAberration: 0.12,
        saturation: 1.02,
      );

  static LiquidGlassSettings get fileSelectorSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 0.8,
        lightAngle: 0.28 * pi,
        lightIntensity: 0.3,
        ambientStrength: 0.12,
        blend: 0.25,
        refractiveIndex: 1.1,
        chromaticAberration: 0.12,
        saturation: 1.01,
      );
}