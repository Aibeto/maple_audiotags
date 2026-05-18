import 'dart:io';
import 'dart:math' show pi;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:desktop_drop/desktop_drop.dart';

import 'config/ui_config.dart';
import 'pages/file_page.dart';
import 'pages/edit_page.dart';
import 'pages/settings_page.dart';

Future<void> _clearCacheDirectory() async {
  try {
    final tempDir = await getTemporaryDirectory();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create(recursive: true);
    }
  } catch (e) {
    if (kDebugMode) {
      print('KDEBUG: 清理缓存目录时出错: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  runApp(MyApp(initialIsDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool? initialIsDarkMode;

  const MyApp({super.key, this.initialIsDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isDarkMode;

  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_isDarkMode == null) {
        _isDarkMode = false;
      } else if (_isDarkMode == false) {
        _isDarkMode = true;
      } else {
        _isDarkMode = null;
      }
    });
    if (_isDarkMode != null) {
      await prefs.setBool('isDarkMode', _isDarkMode!);
    } else {
      await prefs.remove('isDarkMode');
    }
  }

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialIsDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ThemeMode themeMode = _isDarkMode == null
            ? ThemeMode.system
            : (_isDarkMode! ? ThemeMode.dark : ThemeMode.light);

        return MaterialApp(
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
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final bool? isDarkMode;
  final VoidCallback toggleTheme;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<String> _selectedFiles = [];
  Uint8List? _backgroundImageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBackgroundImage();
    });
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final response = await http.get(
        Uri.parse('https://bing.img.run/uhd.php'),
      );
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

  void _onSelectionChanged(List<String> paths) {
    setState(() {
      _selectedFiles = paths;
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sysBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildBackground(),
          _buildPageContent(),
          _buildFloatingNavBar(sysBottom),
          _buildTopButtons(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
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
          if (_backgroundImageBytes != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
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

  Widget _buildPageContent() {
    final bottomPadding = 68.0 + MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            FilePage(
              selectedFiles: _selectedFiles,
              onSelectionChanged: _onSelectionChanged,
            ),
            DropTarget(
              onDragDone: (detail) {
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
                final audioFiles = detail.files
                    .where((f) {
                      final ext = f.path.toLowerCase();
                      return audioExts.any((e) => ext.endsWith(e));
                    })
                    .map((f) => f.path)
                    .toList();
                if (audioFiles.isNotEmpty) {
                  setState(() => _selectedFiles = audioFiles);
                  _onTabChanged(1);
                }
              },
              child: EditPage(filePaths: _selectedFiles),
            ),
            SettingsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(double sysBottom) {
    return Positioned(
      bottom: 8.0 + sysBottom,
      left: MediaQuery.of(context).size.width * 0.06,
      right: MediaQuery.of(context).size.width * 0.06,
      child: LiquidGlassLayer(
        settings: _navBarGlassSettings,
        child: LiquidGlass.inLayer(
          shape: const LiquidRoundedRectangle(
            borderRadius: Radius.circular(28.0),
          ),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabItem(
                  Icons.folder_open_outlined,
                  Icons.folder_open,
                  '文件',
                  0,
                ),
                _buildTabItem(Icons.edit_outlined, Icons.edit, '编辑', 1),
                _buildTabItem(Icons.settings_outlined, Icons.settings, '设置', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final _navBarGlassSettings = LiquidGlassSettings(
    thickness: 6,
    blur: 1.0,
    lightAngle: 0.35 * pi,
    lightIntensity: 0.45,
    ambientStrength: 0.12,
    blend: 0.3,
    refractiveIndex: 1.15,
    chromaticAberration: 0.08,
    saturation: 1.04,
  );

  Widget _buildTabItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: isDarkModeActive ? 0.18 : 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              size: 28,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'MapleMono',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get isDarkModeActive {
    if (widget.isDarkMode == null) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return widget.isDarkMode!;
  }

  Widget _buildTopButtons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8.0,
      right: 12.0,
      child: LiquidGlassLayer(
        settings: UIConfig.smallButtonSettings,
        child: LiquidGlass.inLayer(
          shape: const LiquidRoundedRectangle(
            borderRadius: Radius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.toggleTheme,
                borderRadius: BorderRadius.circular(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isDarkMode == null
                          ? Icons.auto_mode
                          : (widget.isDarkMode!
                                ? Icons.dark_mode
                                : Icons.light_mode),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.isDarkMode == null
                          ? '跟随系统'
                          : (widget.isDarkMode! ? '深色' : '浅色'),
                      style: const TextStyle(
                        fontFamily: 'MapleMono',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
