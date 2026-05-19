import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class UIConfig {
  static LiquidGlassSettings get base => LiquidGlassSettings(
        thickness: 30,
        blur: 12,
        specularSharpness: GlassSpecularSharpness.medium,
      );

  static LiquidGlassSettings get compact => LiquidGlassSettings(
        thickness: 20,
        blur: 8,
        specularSharpness: GlassSpecularSharpness.medium,
      );

  static LiquidGlassSettings get prominent => LiquidGlassSettings(
        thickness: 40,
        blur: 16,
        specularSharpness: GlassSpecularSharpness.sharp,
      );

  static LiquidGlassSettings get subtle => LiquidGlassSettings(
        thickness: 12,
        blur: 4,
        specularSharpness: GlassSpecularSharpness.soft,
      );

  static LiquidGlassSettings get baseSettings => base;
  static LiquidGlassSettings get smallButtonSettings => compact;
  static LiquidGlassSettings get largeButtonSettings => prominent;
  static LiquidGlassSettings get dialogSettings => compact;
  static LiquidGlassSettings get fileSelectorSettings => subtle;
}