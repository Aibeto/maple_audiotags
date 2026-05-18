import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../config/ui_config.dart';
import 'apple_news_demo_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GlassContainer(
            useOwnLayer: true,
            settings: UIConfig.baseSettings,
            shape: const LiquidRoundedRectangle(borderRadius: 16.0),
            width: double.infinity,
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
                ListTile(
                  leading: const Icon(Icons.newspaper),
                  title: const Text(
                    'Apple News Demo',
                    style: TextStyle(fontFamily: 'MapleMono'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => Theme(
                        data: ThemeData.dark(),
                        child: const AppleNewsDemoPage(),
                      ),
                    ),
                  ),
                ),
              ],
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(ctx).size.width * 0.85,
          ),
          child: GlassContainer(
            useOwnLayer: true,
            settings: UIConfig.dialogSettings,
            shape: const LiquidRoundedRectangle(borderRadius: 20.0),
            padding: const EdgeInsets.all(24.0),
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
    );
  }
}
