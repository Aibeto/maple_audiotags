import 'dart:io';

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
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildPageContent(),
          _buildFloatingNavBar(),
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
    return SafeArea(
      child: IndexedStack(
        index: _currentIndex,
        children: [
          FilePage(
            selectedFiles: _selectedFiles,
            onSelectionChanged: _onSelectionChanged,
          ),
          DropTarget(
            onDragDone: (detail) {
              final mp3Files = detail.files
                  .where((f) => f.path.toLowerCase().endsWith('.mp3'))
                  .map((f) => f.path)
                  .toList();
              if (mp3Files.isNotEmpty) {
                setState(() => _selectedFiles = mp3Files);
                _onTabChanged(1);
              }
            },
            child: EditPage(filePaths: _selectedFiles),
          ),
          SettingsPage(),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Positioned(
      bottom: 16.0,
      left: MediaQuery.of(context).size.width * 0.12,
      right: MediaQuery.of(context).size.width * 0.12,
      child: LiquidGlassLayer(
        settings: UIConfig.largeButtonSettings,
        child: LiquidGlass.inLayer(
          shape: const LiquidRoundedRectangle(
            borderRadius: Radius.circular(28.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.0),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedFontSize: 12,
                unselectedFontSize: 11,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(
                  context,
                ).textTheme.bodySmall?.color,
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.folder_open, 0),
                    label: '文件',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.edit, 1),
                    label: '编辑',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon(Icons.settings, 2),
                    label: '设置',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return Icon(
      icon,
      size: isSelected ? 26 : 22,
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).textTheme.bodySmall?.color,
    );
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
