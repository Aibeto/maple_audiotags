// 导入 Dart 标准库文件操作模块
import 'dart:io';

// 导入 Flutter 基础库
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 导入动态颜色主题库
import 'package:dynamic_color/dynamic_color.dart';
// 导入 SharedPreferences 用于本地数据持久化
import 'package:shared_preferences/shared_preferences.dart';
// 导入液态玻璃 UI 组件库
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
// 导入 HTTP 请求库
import 'package:http/http.dart' as http;
// 导入 UI 图形库
import 'dart:ui' as ui;
// 导入路径提供库用于获取系统临时目录
import 'package:path_provider/path_provider.dart';
// 导入桌面端拖拽支持库
import 'package:desktop_drop/desktop_drop.dart';

// 导入项目内部模块
import 'pages/file_page.dart';
import 'pages/edit_page.dart';
import 'pages/settings_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 工具函数
// ─────────────────────────────────────────────────────────────────────────────

/// 清理缓存目录
/// 在 Android 平台启动时调用，清除临时文件以释放存储空间
Future<void> _clearCacheDirectory() async {
  try {
    // 获取系统临时目录路径
    final tempDir = await getTemporaryDirectory();
    // 检查目录是否存在
    if (await tempDir.exists()) {
      // 递归删除目录下所有文件
      await tempDir.delete(recursive: true);
      // 重新创建空的临时目录
      await tempDir.create(recursive: true);
    }
  } catch (e) {
    // 仅在调试模式下打印错误信息
    if (kDebugMode) {
      print('KDEBUG: 清理缓存目录时出错: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 应用入口
// ─────────────────────────────────────────────────────────────────────────────

/// 应用程序主函数
/// 负责初始化 Flutter 框架、清理缓存、读取主题设置并启动应用
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LiquidGlassWidgets.initialize();

  try {
    if (Platform.isAndroid) {
      await _clearCacheDirectory();
    }
  } catch (e) {
    if (kDebugMode) {
      print('KDEBUG: Platform.isAndroid 不支持此平台运行: $e');
    }
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? isDarkMode = prefs.getBool('isDarkMode');

  runApp(LiquidGlassWidgets.wrap(child: MyApp(initialIsDarkMode: isDarkMode)));
}

// ─────────────────────────────────────────────────────────────────────────────
// 主应用组件
// ─────────────────────────────────────────────────────────────────────────────

/// 主应用组件类
/// 负责管理应用主题、创建 MaterialApp 并渲染主页
class MyApp extends StatefulWidget {
  /// 初始深色模式设置（可选，null 表示跟随系统）
  final bool? initialIsDarkMode;

  /// 构造函数
  const MyApp({super.key, this.initialIsDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// MyApp 的状态类
/// 管理主题切换逻辑和应用根组件渲染
class _MyAppState extends State<MyApp> {
  /// 当前深色模式状态
  /// null = 跟随系统，true = 强制深色，false = 强制浅色
  bool? _isDarkMode;

  /// 切换主题函数
  /// 如果提供了 newMode，直接设置为该模式
  /// 否则在浅色 → 深色 → 跟随系统 三种模式间循环切换
  void _toggleTheme([bool? newMode]) async {
    // 获取 SharedPreferences 实例
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 更新状态并触发 UI 重建
    setState(() {
      if (newMode != null) {
        _isDarkMode = newMode;
      } else {
        if (_isDarkMode == null) {
          // 当前是跟随系统，切换到浅色
          _isDarkMode = false;
        } else if (_isDarkMode == false) {
          // 当前是浅色，切换到深色
          _isDarkMode = true;
        } else {
          // 当前是深色，切换到跟随系统
          _isDarkMode = null;
        }
      }
    });
    // 保存用户选择到本地存储
    if (_isDarkMode != null) {
      await prefs.setBool('isDarkMode', _isDarkMode!);
    } else {
      await prefs.remove('isDarkMode');
    }
  }

  @override
  void initState() {
    super.initState();
    // 初始化主题状态为传入的初始值
    _isDarkMode = widget.initialIsDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ThemeMode themeMode = _isDarkMode == null
            ? ThemeMode.system
            : (_isDarkMode! ? ThemeMode.dark : ThemeMode.light);

        return GlassTheme(
          data: GlassThemeData(
            light: GlassThemeVariant(
              settings: const GlassThemeSettings(
                thickness: 30,
                blur: 12,
                specularSharpness: GlassSpecularSharpness.medium,
              ),
              quality: GlassQuality.standard,
              glowColors: const GlassGlowColors(
                primary: Colors.blue,
                glowBlurRadius: 12,
                glowOpacity: 0.8,
              ),
            ),
            dark: GlassThemeVariant(
              settings: const GlassThemeSettings(
                thickness: 50,
                blur: 18,
                specularSharpness: GlassSpecularSharpness.medium,
              ),
              quality: GlassQuality.premium,
              glowColors: const GlassGlowColors(
                primary: Colors.blue,
                glowBlurRadius: 12,
                glowOpacity: 0.8,
              ),
            ),
          ),
          child: MaterialApp(
            title: '枫糖标签',
            themeMode: themeMode,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'MapleMono',
              colorScheme:
                  lightDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.light,
                  ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              fontFamily: 'MapleMono',
              colorScheme:
                  darkDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.dark,
                  ),
              scaffoldBackgroundColor: Colors.black,
            ),
            home: HomePage(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 主页组件
// ─────────────────────────────────────────────────────────────────────────────

/// 主页组件
/// 包含底部导航栏、文件浏览、编辑、设置三个主要页面
class HomePage extends StatefulWidget {
  /// 当前深色模式状态
  final bool? isDarkMode;

  /// 切换主题回调函数
  final void Function([bool?]) toggleTheme;

  /// 构造函数
  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

/// HomePage 的状态类
/// 管理底部导航栏状态、选中文件列表和背景图
class _HomePageState extends State<HomePage> {
  /// 当前选中的底部导航栏索引（0=文件，1=编辑，2=设置）
  int _currentIndex = 0;

  /// 用户选中的音频文件路径列表
  List<String> _selectedFiles = [];

  /// 背景图片字节数据（从必应壁纸 API 获取）
  Uint8List? _backgroundImageBytes;

  @override
  void initState() {
    super.initState();
    // 在第一帧渲染后加载背景图片，避免阻塞 UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBackgroundImage();
    });
  }

  /// 加载背景图片
  /// 从必应壁纸 API 获取每日壁纸并显示为背景
  Future<void> _loadBackgroundImage() async {
    try {
      // 发送 HTTP GET 请求获取壁纸
      final response = await http.get(
        Uri.parse('https://bing.img.run/uhd.php'),
      );
      // 请求成功时更新状态
      if (response.statusCode == 200) {
        setState(() {
          _backgroundImageBytes = response.bodyBytes;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 无法加载背景图片: $e');
      }
    }
  }

  /// 文件选择变化回调
  /// 当用户在文件页面选择或取消选择文件时调用
  void _onSelectionChanged(List<String> paths) {
    setState(() {
      _selectedFiles = paths;
    });
  }

  /// 底部导航栏切换回调
  /// 当用户点击不同的导航项时切换页面
  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 构建主 Scaffold，包含背景、页面内容和导航栏
    return Scaffold(
      // 让内容延伸到导航栏下方
      extendBody: true,
      // 避免键盘弹出时调整布局（影响玻璃效果）
      resizeToAvoidBottomInset: false,
      body: Stack(children: [_buildBackground(), _buildPageContent()]),
      // 液态玻璃效果的底部导航栏
      bottomNavigationBar: GlassBottomBar(
        tabs: [
          GlassBottomBarTab(
            label: '文件',
            icon: const Icon(Icons.folder_open_outlined),
            activeIcon: const Icon(Icons.folder_open),
          ),
          GlassBottomBarTab(
            label: '编辑',
            icon: const Icon(Icons.edit_outlined),
            activeIcon: const Icon(Icons.edit),
          ),
          GlassBottomBarTab(
            label: '设置',
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
          ),
        ],
        selectedIndex: _currentIndex,
        onTabSelected: (index) => _onTabChanged(index),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 子组件构建方法
  // ─────────────────────────────────────────────────────────────────────────

  /// 构建背景层
  /// 包含壁纸图片和毛玻璃效果
  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // 如果有背景图片则显示并缩放以填充
          if (_backgroundImageBytes != null)
            Positioned.fill(
              child: Transform.scale(
                scale: 1,
                child: Image.memory(
                  _backgroundImageBytes!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          // 在背景图上叠加毛玻璃效果
          if (_backgroundImageBytes != null)
            Positioned.fill(
              child: BackdropFilter(
                // 应用高斯模糊滤镜
                filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                // 添加半透明遮罩层，根据主题调整透明度
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建页面内容层
  /// 使用 IndexedStack 实现页面切换
  Widget _buildPageContent() {
    return SafeArea(
      // 不保护底部，因为导航栏是透明的
      bottom: false,
      child: IndexedStack(
        // 显示当前选中的页面
        index: _currentIndex,
        children: [
          // 文件浏览页面
          FilePage(
            selectedFiles: _selectedFiles,
            onSelectionChanged: _onSelectionChanged,
          ),
          // 编辑页面，包裹在 DropTarget 中支持拖放文件
          DropTarget(
            onDragDone: (detail) {
              // 定义支持的音频文件扩展名
              final audioExts = {
                '.mp3',
                '.flac',
                '.wav',
                '.aac',
                '.ogg',
                '.wma',
                '.m4a',
                '.opus',
                '.aiff',
                '.ape',
              };
              // 过滤拖放的文件，只保留音频文件
              final audioFiles = detail.files
                  .where((f) {
                    final ext = f.path.toLowerCase();
                    return audioExts.any((e) => ext.endsWith(e));
                  })
                  .map((f) => f.path)
                  .toList();
              // 如果有音频文件被拖放，选中并切换到编辑页
              if (audioFiles.isNotEmpty) {
                setState(() => _selectedFiles = audioFiles);
                _onTabChanged(1);
              }
            },
            child: EditPage(filePaths: _selectedFiles),
          ),
          // 设置页面
          SettingsPage(
            isDarkMode: widget.isDarkMode,
            onThemeChanged: widget.toggleTheme,
          ),
        ],
      ),
    );
  }
}
