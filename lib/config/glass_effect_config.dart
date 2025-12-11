import 'dart:math';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

enum EffectLevel { low, medium, high }

/// 液态玻璃效果配置类，统一管理所有液态玻璃参数
/// 实现代码复用和集中化管理
class GlassEffectConfig {
  static LiquidGlassSettings baseSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 4,
          blur: 0.3,
          lightAngle: 0.2 * pi,
          lightIntensity: 0.5,
          ambientStrength: 0.1,
          blend: 0.3,
          refractiveIndex: 1.1,
          chromaticAberration: 0.1,
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 6,
          blur: 0.5,
          lightAngle: 0.3 * pi,
          lightIntensity: 0.7,
          ambientStrength: 0.2,
          blend: 0.5,
          refractiveIndex: 1.2,
          chromaticAberration: 0.2,
          saturation: 1.05,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 8,
          blur: 0.8,
          lightAngle: 0.4 * pi,
          lightIntensity: 0.9,
          ambientStrength: 0.3,
          blend: 0.7,
          refractiveIndex: 1.3,
          chromaticAberration: 0.3,
          saturation: 1.1,
        );
    }
  }

  static LiquidGlassSettings smallButtonSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 5,
          blur: 0.6,
          lightAngle: 0.25 * pi,
          lightIntensity: 0.5,
          ambientStrength: 0.15,
          blend: 0.25,
          refractiveIndex: 1.2,
          chromaticAberration: 0.15,
          saturation: 1.05,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 6,
          blur: 0.8,
          lightAngle: 0.3 * pi,
          lightIntensity: 0.6,
          ambientStrength: 0.2,
          blend: 0.3,
          refractiveIndex: 1.3,
          chromaticAberration: 0.2,
          saturation: 1.1,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 7,
          blur: 1.0,
          lightAngle: 0.35 * pi,
          lightIntensity: 0.7,
          ambientStrength: 0.25,
          blend: 0.35,
          refractiveIndex: 1.4,
          chromaticAberration: 0.25,
          saturation: 1.15,
        );
    }
  }

  static LiquidGlassSettings largeButtonSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 6,
          blur: 0.5,
          lightAngle: 0.3 * pi,
          lightIntensity: 0.6,
          ambientStrength: 0.15,
          blend: 0.4,
          refractiveIndex: 1.2,
          chromaticAberration: 0.15,
          saturation: 1.03,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 8,
          blur: 0.7,
          lightAngle: 0.35 * pi,
          lightIntensity: 0.8,
          ambientStrength: 0.25,
          blend: 0.6,
          refractiveIndex: 1.25,
          chromaticAberration: 0.25,
          saturation: 1.08,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 10,
          blur: 0.9,
          lightAngle: 0.4 * pi,
          lightIntensity: 0.95,
          ambientStrength: 0.35,
          blend: 0.75,
          refractiveIndex: 1.35,
          chromaticAberration: 0.35,
          saturation: 1.12,
        );
    }
  }

  static LiquidGlassSettings dialogSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 5,
          blur: 0.4,
          lightAngle: 0.28 * pi,
          lightIntensity: 0.6,
          ambientStrength: 0.15,
          blend: 0.4,
          refractiveIndex: 1.15,
          chromaticAberration: 0.15,
          saturation: 1.02,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 7,
          blur: 0.6,
          lightAngle: 0.32 * pi,
          lightIntensity: 0.75,
          ambientStrength: 0.22,
          blend: 0.55,
          refractiveIndex: 1.22,
          chromaticAberration: 0.22,
          saturation: 1.06,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 9,
          blur: 0.85,
          lightAngle: 0.37 * pi,
          lightIntensity: 0.85,
          ambientStrength: 0.28,
          blend: 0.65,
          refractiveIndex: 1.28,
          chromaticAberration: 0.28,
          saturation: 1.09,
        );
    }
  }

  static LiquidGlassSettings fileSelectorSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 4,
          blur: 0.3,
          lightAngle: 0.25 * pi,
          lightIntensity: 0.55,
          ambientStrength: 0.13,
          blend: 0.35,
          refractiveIndex: 1.1,
          chromaticAberration: 0.13,
          saturation: 1.01,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 5,
          blur: 0.4,
          lightAngle: 0.28 * pi,
          lightIntensity: 0.65,
          ambientStrength: 0.18,
          blend: 0.45,
          refractiveIndex: 1.15,
          chromaticAberration: 0.18,
          saturation: 1.04,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 6,
          blur: 0.55,
          lightAngle: 0.31 * pi,
          lightIntensity: 0.75,
          ambientStrength: 0.23,
          blend: 0.55,
          refractiveIndex: 1.2,
          chromaticAberration: 0.23,
          saturation: 1.07,
        );
    }
  }
}