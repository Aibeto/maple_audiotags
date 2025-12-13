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
          thickness: 1,  // 最小厚度
          blur: 0.5,     // 保留模糊度
          lightAngle: 0.0, // 关闭光源角度
          lightIntensity: 0.0,  // 关闭光强
          ambientStrength: 0.0, // 关闭环境光强度
          blend: 0.0,    // 关闭混合
          refractiveIndex: 1.0, // 最小折射率
          chromaticAberration: 0.0, // 关闭色差
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 6,  // 降低厚度
          blur: 1.0,     // 增强模糊度
          lightAngle: 0.3 * pi,
          lightIntensity: 0.4,  // 降低光强
          ambientStrength: 0.1,  // 降低环境光强度
          blend: 0.3,    // 降低混合度
          refractiveIndex: 1.1,  // 降低折射率
          chromaticAberration: 0.1, // 降低色差
          saturation: 1.02,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 12, // 增加厚度
          blur: 1.2,     // 增强模糊度
          lightAngle: 0.45 * pi,
          lightIntensity: 1.2,   // 增强光强
          ambientStrength: 0.5,  // 增强环境光强度
          blend: 0.9,            // 增强混合度
          refractiveIndex: 1.5,  // 增强折射率
          chromaticAberration: 0.5, // 增强色差
          saturation: 1.2,
        );
    }
  }

  static LiquidGlassSettings smallButtonSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 1,  // 最小厚度
          blur: 0.6,     // 保留模糊度
          lightAngle: 0.0, // 关闭光源角度
          lightIntensity: 0.0,  // 关闭光强
          ambientStrength: 0.0, // 关闭环境光强度
          blend: 0.0,    // 关闭混合
          refractiveIndex: 1.0, // 最小折射率
          chromaticAberration: 0.0, // 关闭色差
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 6,  // 降低厚度
          blur: 1.1,     // 增强模糊度
          lightAngle: 0.3 * pi,
          lightIntensity: 0.3,  // 降低光强
          ambientStrength: 0.12, // 降低环境光强度
          blend: 0.2,    // 降低混合度
          refractiveIndex: 1.15, // 降低折射率
          chromaticAberration: 0.12, // 降低色差
          saturation: 1.05,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 9,         // 增加厚度
          blur: 1.3,            // 增强模糊度
          lightAngle: 0.4 * pi,
          lightIntensity: 1.0,  // 增强光强
          ambientStrength: 0.4, // 增强环境光强度
          blend: 0.6,           // 增强混合度
          refractiveIndex: 1.5, // 增强折射率
          chromaticAberration: 0.4, // 增强色差
          saturation: 1.25,
        );
    }
  }

  static LiquidGlassSettings largeButtonSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 1,  // 最小厚度
          blur: 0.5,     // 保留模糊度
          lightAngle: 0.0, // 关闭光源角度
          lightIntensity: 0.0,  // 关闭光强
          ambientStrength: 0.0, // 关闭环境光强度
          blend: 0.0,    // 关闭混合
          refractiveIndex: 1.0, // 最小折射率
          chromaticAberration: 0.0, // 关闭色差
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 6,  // 降低厚度
          blur: 1.2,     // 增强模糊度
          lightAngle: 0.35 * pi,
          lightIntensity: 0.5,  // 降低光强
          ambientStrength: 0.15, // 降低环境光强度
          blend: 0.3,    // 降低混合度
          refractiveIndex: 1.15, // 降低折射率
          chromaticAberration: 0.15, // 降低色差
          saturation: 1.04,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 15, // 增加厚度以更像iOS液态玻璃
          blur: 1.5,     // 增强模糊度
          lightAngle: 0.5 * pi,
          lightIntensity: 1.5,   // 增强光强
          ambientStrength: 0.7,  // 增强环境光强度
          blend: 1.0,            // 最大混合度
          refractiveIndex: 1.7,  // 增强折射率
          chromaticAberration: 0.7, // 增强色差
          saturation: 1.3,
        );
    }
  }

  static LiquidGlassSettings dialogSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 1,  // 最小厚度
          blur: 0.4,    // 保留模糊度
          lightAngle: 0.0, // 关闭光源角度
          lightIntensity: 0.0,  // 关闭光强
          ambientStrength: 0.0, // 关闭环境光强度
          blend: 0.0,    // 关闭混合
          refractiveIndex: 1.0, // 最小折射率
          chromaticAberration: 0.0, // 关闭色差
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 6,  // 降低厚度
          blur: 0.9,     // 增强模糊度
          lightAngle: 0.32 * pi,
          lightIntensity: 0.4,  // 降低光强
          ambientStrength: 0.12, // 降低环境光强度
          blend: 0.3,    // 降低混合度
          refractiveIndex: 1.1,  // 降低折射率
          chromaticAberration: 0.12, // 降低色差
          saturation: 1.02,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 13, // 增加厚度
          blur: 1.4,     // 增强模糊度
          lightAngle: 0.45 * pi,
          lightIntensity: 1.3,   // 增强光强
          ambientStrength: 0.6,  // 增强环境光强度
          blend: 0.9,            // 增强混合度
          refractiveIndex: 1.6,  // 增强折射率
          chromaticAberration: 0.6, // 增强色差
          saturation: 1.25,
        );
    }
  }

  static LiquidGlassSettings fileSelectorSettings({EffectLevel level = EffectLevel.medium}) {
    switch (level) {
      case EffectLevel.low:
        return LiquidGlassSettings(
          thickness: 1,  // 最小厚度
          blur: 0.4,    // 保留模糊度
          lightAngle: 0.0, // 关闭光源角度
          lightIntensity: 0.0,  // 关闭光强
          ambientStrength: 0.0, // 关闭环境光强度
          blend: 0.0,    // 关闭混合
          refractiveIndex: 1.0, // 最小折射率
          chromaticAberration: 0.0, // 关闭色差
          saturation: 1.0,
        );
      case EffectLevel.medium:
        return LiquidGlassSettings(
          thickness: 6,  // 降低厚度
          blur: 0.8,     // 增强模糊度
          lightAngle: 0.28 * pi,
          lightIntensity: 0.3,  // 降低光强
          ambientStrength: 0.12, // 降低环境光强度
          blend: 0.25,   // 降低混合度
          refractiveIndex: 1.1,  // 降低折射率
          chromaticAberration: 0.12, // 降低色差
          saturation: 1.01,
        );
      case EffectLevel.high:
        return LiquidGlassSettings(
          thickness: 11, // 增加厚度
          blur: 1.1,     // 增强模糊度
          lightAngle: 0.35 * pi,
          lightIntensity: 1.1,   // 增强光强
          ambientStrength: 0.5,  // 增强环境光强度
          blend: 0.8,            // 增强混合度
          refractiveIndex: 1.5,  // 增强折射率
          chromaticAberration: 0.5, // 增强色差
          saturation: 1.2,
        );
    }
  }
}