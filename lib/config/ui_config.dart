// 导入 Dart 数学库，用于计算角度相关数值
import 'dart:math';

// 导入液态玻璃 UI 组件库
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UI 配置类
// ─────────────────────────────────────────────────────────────────────────────

/// UI 配置类
/// 集中管理应用中所有液态玻璃组件的视觉效果配置
class UIConfig {
  /// 基础配置
  /// 适用于大多数普通玻璃组件，提供平衡的视觉效果
  static LiquidGlassSettings get baseSettings => LiquidGlassSettings(
        // 玻璃厚度，影响 3D 效果的强度
        thickness: 6,
        // 模糊程度，数值越大越模糊
        blur: 1.0,
        // 光源角度（弧度），影响高光反射方向
        lightAngle: 0.3 * pi,
        // 光源强度，控制高光亮度
        lightIntensity: 0.4,
        // 环境光强度，控制玻璃的整体亮度
        ambientStrength: 0.1,
        // 折射率，影响光通过玻璃时的弯曲程度
        refractiveIndex: 1.1,
        // 色差（色散）强度，模拟棱镜效果
        chromaticAberration: 0.1,
        // 饱和度增强系数，让颜色更鲜艳
        saturation: 1.02,
        // 高光锐利度，medium 表示中等锐利
        specularSharpness: GlassSpecularSharpness.medium,
      );

  /// 小按钮配置
  /// 适用于较小的按钮组件，提供更精致的视觉效果
  static LiquidGlassSettings get smallButtonSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 1.1, // 稍微增强模糊
        lightAngle: 0.3 * pi,
        lightIntensity: 0.3, // 降低光源强度
        ambientStrength: 0.12, // 稍微提高环境光
        refractiveIndex: 1.15, // 提高折射率
        chromaticAberration: 0.12, // 稍微增强色散
        saturation: 1.05, // 增强饱和度
        specularSharpness: GlassSpecularSharpness.medium,
      );

  /// 大按钮配置
  /// 适用于较大的按钮组件，提供更醒目的视觉效果
  static LiquidGlassSettings get largeButtonSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 1.2, // 进一步增强模糊
        lightAngle: 0.35 * pi, // 调整光源角度
        lightIntensity: 0.5, // 提高光源强度
        ambientStrength: 0.15, // 提高环境光
        refractiveIndex: 1.15,
        chromaticAberration: 0.15, // 增强色散
        saturation: 1.04,
        specularSharpness: GlassSpecularSharpness.medium,
      );

  /// 对话框配置
  /// 适用于对话框和弹窗组件，提供柔和的视觉效果
  static LiquidGlassSettings get dialogSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 0.9, // 降低模糊，更清晰
        lightAngle: 0.32 * pi,
        lightIntensity: 0.4,
        ambientStrength: 0.12,
        refractiveIndex: 1.1,
        chromaticAberration: 0.12,
        saturation: 1.02,
        specularSharpness: GlassSpecularSharpness.medium,
      );

  /// 文件选择器配置
  /// 适用于文件选择器组件，提供低调的视觉效果
  static LiquidGlassSettings get fileSelectorSettings => LiquidGlassSettings(
        thickness: 6,
        blur: 0.8, // 最低模糊度，最清晰
        lightAngle: 0.28 * pi,
        lightIntensity: 0.3, // 最低光源强度
        ambientStrength: 0.12,
        refractiveIndex: 1.1,
        chromaticAberration: 0.12,
        saturation: 1.01, // 最低饱和度
        specularSharpness: GlassSpecularSharpness.medium,
      );
}
