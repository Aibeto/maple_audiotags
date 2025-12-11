// 设置页面
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'config/glass_effect_config.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:ui';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 效果等级变量，默认值为1
  int _effectLevel = 1;
  Uint8List? _backgroundImageBytes;

  @override
  void initState() {
    super.initState();
    // 初始化时从shared preferences加载效果等级
    _loadEffectLevel();
    // 加载背景图片
    _loadBackgroundImage();
  }
  
  // 异步获取背景图片
  Future<void> _loadBackgroundImage() async {
    try {
      final response = await http.get(Uri.parse('https://bing.img.run/uhd.php'));
      if (response.statusCode == 200) {
        setState(() {
          _backgroundImageBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      // 忽略错误
    }
  }
  
  // 从shared preferences加载效果等级
  Future<void> _loadEffectLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _effectLevel = prefs.getInt('effectLevel') ?? 1; // 默认值为1
    });
  }
  
  // 保存效果等级到shared preferences
  Future<void> _saveEffectLevel(int level) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('effectLevel', level);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 移除AppBar以隐藏设置字样和顶栏
      appBar: null,
      // 让body撑满整个屏幕
      body: Stack(
        children: [
          // 背景图片
          if (_backgroundImageBytes != null)
            Positioned.fill(
              child: Transform.scale(
                scale: 1, // 放大50%
                child: Image.memory(
                  _backgroundImageBytes!,
                  fit: BoxFit.cover, // 自适应并撑满屏幕高度
                  alignment: Alignment.center,
                ),
              ),
            ),
          // 模糊层 (根据主题模式使用不同颜色的遮罩)
          if (_backgroundImageBytes != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withValues(alpha: 0.25) 
                    : Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          // 页面内容容器，限制最大宽度
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600), // 限制最大宽度
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80), // 为顶部留出空间
                    // 添加效果等级设置
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LiquidGlassLayer(
                        settings: GlassEffectConfig.baseSettings(
                          level: _effectLevel <= 1 
                            ? EffectLevel.low 
                            : (_effectLevel == 2 ? EffectLevel.medium : EffectLevel.high)
                        ),
                        child: LiquidGlass.inLayer(
                          shape: const LiquidRoundedRectangle(
                            borderRadius: Radius.circular(16.0), // 圆角矩形
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(16.0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '效果等级',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('简单'),
                                    Expanded(
                                      child: Slider(
                                        value: _effectLevel.toDouble(),
                                        min: 1,
                                        max: 3,
                                        divisions: 2, // 三档：1, 2, 3
                                        label: _effectLevel.toString(),
                                        onChanged: (value) {
                                          setState(() {
                                            _effectLevel = value.toInt();
                                          });
                                        },
                                        onChangeEnd: (value) {
                                          // 滑动结束时保存设置
                                          _saveEffectLevel(value.toInt());
                                        },
                                      ),
                                    ),
                                    const Text('复杂'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '当前等级: $_effectLevel',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80), // 为底部留出空间
                  ],
                ),
              ),
            ),
          ),
          // 返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.0,
            left: 12.0,
            child: LiquidGlassLayer(
              settings: GlassEffectConfig.smallButtonSettings(
                level: _effectLevel <= 1 
                  ? EffectLevel.low 
                  : (_effectLevel == 2 ? EffectLevel.medium : EffectLevel.high)
              ),
              child: LiquidGlass.inLayer(
                shape: LiquidRoundedRectangle(
                  borderRadius: const Radius.circular(20.0),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(20.0),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 6),
                          Text('返回'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}