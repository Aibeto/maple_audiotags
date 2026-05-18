import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../config/ui_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LiquidGlassLayer(
            settings: UIConfig.baseSettings,
            child: LiquidGlass.inLayer(
              shape: const LiquidRoundedRectangle(
                borderRadius: Radius.circular(16.0),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text(
                        '关于',
                        style: TextStyle(fontFamily: 'MapleMono'),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: LiquidGlassLayer(
          settings: UIConfig.dialogSettings,
          child: LiquidGlass.inLayer(
            shape: const LiquidRoundedRectangle(
              borderRadius: Radius.circular(20.0),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(ctx).size.width * 0.85,
              ),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Theme.of(ctx).colorScheme.surface.withAlpha(230),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    '枫糖标签',
                    style: TextStyle(
                      fontFamily: 'MapleMono',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '版本 1.0.0',
                    style: TextStyle(
                      fontFamily: 'MapleMono',
                      fontSize: 14,
                      color: Theme.of(ctx).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '一款使用液态玻璃 UI 的音频标签编辑工具。\n支持 MP3 文件的标签读取与编辑、\nLRC 歌词文件管理与文件浏览器。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'MapleMono',
                      fontSize: 13,
                      color: Theme.of(ctx).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      '确定',
                      style: TextStyle(fontFamily: 'MapleMono'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
