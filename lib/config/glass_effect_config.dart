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
          thickness: 3,  // 降低厚度
          blur: 0.2,     // 降低模糊度
          lightAngle: 0.2 * pi,
          lightIntensity: 0.3,  // 降低光强
          ambientStrength: 0.05, // 降低环境光强度
          blend: 0.2,    // 降低混合度
          refractiveIndex: 1.05, // 降低折射率
          chromaticAberration: 0.05, // 降低色差
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 4,  // 降低厚度
          blur: 0.3,     // 降低模糊度
          lightAngle: 0.3 * pi,
          lightIntensity: 0.5,  // 降低光强
          ambientStrength: 0.1,  // 降低环境光强度
          blend: 0.3,    // 降低混合度
          refractiveIndex: 1.1,  // 降低折射率
          chromaticAberration: 0.1, // 降低色差
          saturation: 1.02,
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
          thickness: 3,  // 降低厚度
          blur: 0.3,     // 降低模糊度
          lightAngle: 0.25 * pi,
          lightIntensity: 0.3,  // 降低光强
          ambientStrength: 0.08, // 降低环境光强度
          blend: 0.15,   // 降低混合度
          refractiveIndex: 1.1,  // 降低折射率
          chromaticAberration: 0.08, // 降低色差
          saturation: 1.02,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 4,  // 降低厚度
          blur: 0.5,     // 降低模糊度
          lightAngle: 0.3 * pi,
          lightIntensity: 0.4,  // 降低光强
          ambientStrength: 0.12, // 降低环境光强度
          blend: 0.2,    // 降低混合度
          refractiveIndex: 1.15, // 降低折射率
          chromaticAberration: 0.12, // 降低色差
          saturation: 1.05,
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
          thickness: 4,  // 降低厚度
          blur: 0.2,     // 降低模糊度
          lightAngle: 0.3 * pi,
          lightIntensity: 0.4,  // 降低光强
          ambientStrength: 0.08, // 降低环境光强度
          blend: 0.2,    // 降低混合度
          refractiveIndex: 1.1,  // 降低折射率
          chromaticAberration: 0.08, // 降低色差
          saturation: 1.01,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 5,  // 降低厚度
          blur: 0.4,     // 降低模糊度
          lightAngle: 0.35 * pi,
          lightIntensity: 0.6,  // 降低光强
          ambientStrength: 0.15, // 降低环境光强度
          blend: 0.3,    // 降低混合度
          refractiveIndex: 1.15, // 降低折射率
          chromaticAberration: 0.15, // 降低色差
          saturation: 1.04,
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
          thickness: 3,  // 降低厚度
          blur: 0.15,    // 降低模糊度
          lightAngle: 0.28 * pi,
          lightIntensity: 0.3,  // 降低光强
          ambientStrength: 0.08, // 降低环境光强度
          blend: 0.2,    // 降低混合度
          refractiveIndex: 1.05, // 降低折射率
          chromaticAberration: 0.08, // 降低色差
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 4,  // 降低厚度
          blur: 0.3,     // 降低模糊度
          lightAngle: 0.32 * pi,
          lightIntensity: 0.5,  // 降低光强
          ambientStrength: 0.12, // 降低环境光强度
          blend: 0.3,    // 降低混合度
          refractiveIndex: 1.1,  // 降低折射率
          chromaticAberration: 0.12, // 降低色差
          saturation: 1.02,
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
          thickness: 3,  // 降低厚度
          blur: 0.15,    // 降低模糊度
          lightAngle: 0.25 * pi,
          lightIntensity: 0.3,  // 降低光强
          ambientStrength: 0.08, // 降低环境光强度
          blend: 0.2,    // 降低混合度
          refractiveIndex: 1.05, // 降低折射率
          chromaticAberration: 0.08, // 降低色差
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 4,  // 降低厚度
          blur: 0.2,     // 降低模糊度
          lightAngle: 0.28 * pi,
          lightIntensity: 0.4,  // 降低光强
          ambientStrength: 0.12, // 降低环境光强度
          blend: 0.25,   // 降低混合度
          refractiveIndex: 1.1,  // 降低折射率
          chromaticAberration: 0.12, // 降低色差
          saturation: 1.01,
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