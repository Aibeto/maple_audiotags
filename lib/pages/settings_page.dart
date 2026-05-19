import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'apple_news_demo_page.dart';

class SettingsPage extends StatefulWidget {
  /// 当前的主题状态
  final bool? isDarkMode;

  /// 主题切换回调
  final void Function(bool?) onThemeChanged;

  /// 构造函数
  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GlassCard(
            useOwnLayer: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '主题设置',
                  style: TextStyle(
                    fontFamily: 'MapleMono',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '选择您喜欢的外观',
                  style: TextStyle(
                    fontFamily: 'MapleMono',
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 16),
                GlassSegmentedControl(
                  segments: const ['跟随系统', '浅色', '深色'],
                  selectedIndex: widget.isDarkMode == null
                      ? 0
                      : (widget.isDarkMode! ? 2 : 1),
                  onSegmentSelected: (index) {
                    bool? newMode;
                    if (index == 0) {
                      newMode = null;
                    } else if (index == 1) {
                      newMode = false;
                    } else {
                      newMode = true;
                    }
                    widget.onThemeChanged(newMode);
                  },
                  useOwnLayer: true,
                ),
                const SizedBox(height: 16),
                Text(
                  '当前: ${widget.isDarkMode == null ? '跟随系统' : (widget.isDarkMode! ? '深色' : '浅色')}',
                  style: TextStyle(
                    fontFamily: 'MapleMono',
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GlassCard(
            useOwnLayer: true,
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

  /// 显示"关于"对话框
  /// [context] 构建上下文
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
