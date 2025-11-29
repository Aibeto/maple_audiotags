// 导入Flutter基础Material设计组件库
// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 导入动态颜色支持库，用于Android 12+的Monet取色功能
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fluttertoast/fluttertoast.dart';
// 导入共享偏好设置库，用于持久化存储用户设置
import 'package:shared_preferences/shared_preferences.dart';
// 导入Dart IO库，用于文件操作
import 'dart:io';
import 'dart:math';
// 导入路径处理库
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
// 导入Flutter服务库，用于获取应用目录
import 'package:path_provider/path_provider.dart';
// 导入批量编辑页面
import 'batch_edit_page.dart';
// 导入标签编辑
import 'edit.dart';
// 导入标签编辑UI
import 'tag_editor_ui.dart';
// 导入Toast库

// 导入日期格式化库
import 'package:intl/intl.dart';

// 导入权限处理库
import 'package:permission_handler/permission_handler.dart';

// 导入文件选择器
import 'package:file_selector/file_selector.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

// 导入网络图片加载库
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

// 程序入口点，使用async关键字支持异步操作
void main() async {
  // 确保Flutter框架初始化完成
  WidgetsFlutterBinding.ensureInitialized();
  // 获取共享偏好设置实例，用于读取和保存用户设置
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // 从存储中读取暗色模式设置，如果不存在则返回null
  bool? isDarkMode = prefs.getBool('isDarkMode');
  // 运行应用程序并传入初始主题设置
  runApp(MyApp(initialIsDarkMode: isDarkMode));
}

// 应用程序主类，负责管理整个应用的状态，继承自StatefulWidget表示有状态组件
class MyApp extends StatefulWidget {
  // 构造函数，接收初始暗色模式设置
  const MyApp({super.key, this.initialIsDarkMode});

  // 初始暗色模式设置，可为true(暗色)/false(亮色)/null(跟随系统)
  final bool? initialIsDarkMode;

  // 创建对应的状态类
  @override
  State<MyApp> createState() => _MyAppState();
}

// 应用程序状态管理类，继承自State
class _MyAppState extends State<MyApp> {
  // 主题模式状态，默认使用系统主题模式
  bool? _isDarkMode;

  // 切换主题模式的方法
  void _toggleTheme() async {
    // 获取共享偏好设置实例
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 更新状态
    setState(() {
      // 根据当前状态进行循环切换
      if (_isDarkMode == null) {
        // 如果当前是跟随系统，则切换为亮色模式
        _isDarkMode = false;
      } else if (_isDarkMode == false) {
        // 如果当前是亮色模式，则切换为暗色模式
        _isDarkMode = true;
      } else {
        // 如果当前是暗色模式，则切换回跟随系统
        _isDarkMode = null;
      }
    });
    
    // 将新的主题设置保存到本地存储
    if (_isDarkMode != null) {
      // 如果不为null，保存设置
      await prefs.setBool('isDarkMode', _isDarkMode!);
    } else {
      // 如果为null，移除设置项以恢复默认行为
      await prefs.remove('isDarkMode');
    }
  }

  // 初始化状态方法，在组件创建时调用
  @override
  void initState() {
    super.initState();
    // 设置初始主题模式
    _isDarkMode = widget.initialIsDarkMode;
  }

  // 构建应用程序UI的方法
  @override
  Widget build(BuildContext context) {
    // 使用DynamicColorBuilder构建支持动态颜色的应用
    return DynamicColorBuilder(
      // builder函数接收亮色和暗色主题的ColorScheme参数
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 根据_isDarkMode值确定主题模式
        ThemeMode themeMode = _isDarkMode == null
            // 如果为null，则使用系统主题模式
            ? ThemeMode.system
            // 否则根据布尔值选择暗色或亮色模式
            : (_isDarkMode! ? ThemeMode.dark : ThemeMode.light);
        
        // 返回MaterialApp组件，这是Flutter应用的基础组件
        return MaterialApp(
          // 应用标题
          title: '音乐标签编辑器',
          // 设置主题模式
          themeMode: themeMode,
          // 浅色主题配置
          theme: ThemeData(
            // 使用Material Design 3
            useMaterial3: true,
            // 颜色方案配置，优先使用系统动态颜色
            colorScheme: lightDynamic ??
                // 如果系统不支持动态颜色，则使用蓝色种子颜色生成
                ColorScheme.fromSeed(
                  // 种子颜色为蓝色
                  seedColor: Colors.blue,
                  // 亮度设置为亮色
                  brightness: Brightness.light,
                ),
          ),
          // 深色主题配置
          darkTheme: ThemeData(
            // 使用Material Design 3
            useMaterial3: true,
            // 颜色方案配置，优先使用系统动态颜色
            colorScheme: darkDynamic ??
                // 如果系统不支持动态颜色，则使用蓝色种子颜色生成
                ColorScheme.fromSeed(
                  // 种子颜色为蓝色
                  seedColor: Colors.blue,
                  // 亮度设置为暗色
                  brightness: Brightness.dark,
                ),
            // 脚手架背景颜色设置为黑色
            scaffoldBackgroundColor: Colors.black,
          ),
          // 设置主页
          home: MyHomePage(
            // 页面标题
            title: '音乐标签编辑',
            // 当前暗色模式设置
            isDarkMode: _isDarkMode,
            // 切换主题的方法
            toggleTheme: _toggleTheme,
          ),
        );
      },
    );
  }
}

// 音频标签编辑器主页类，继承自StatefulWidget表示有状态组件
class MyHomePage extends StatefulWidget {
  // 构造函数，接收必需的参数
  const MyHomePage({
    super.key, 
    required this.title,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  // 页面标题
  final String title;
  // 当前暗色模式设置
  final bool? isDarkMode;
  // 切换主题的方法
  final VoidCallback toggleTheme;

  // 创建对应的状态类
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// 音频标签编辑器主页状态管理类，继承自State
class _MyHomePageState extends State<MyHomePage> {
  // 创建与原生通信的MethodChannel
  Uint8List? _backgroundImageBytes;

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
      if (kDebugMode) {
        print('KDEBUG: 无法加载背景图片: $e');
      }
    }
  }

  // 请求存储权限
  Future<bool> _requestFullStoragePermission() async {
    if (Platform.isAndroid) {
      // 检查Android版本
      final androidVersion = int.tryParse(Platform.operatingSystemVersion.replaceAll(RegExp(r'[^\d.]'), '').split('.').first) ?? 0;
      
      if (androidVersion >= 11) {
        // Android 11及以上版本使用MANAGE_EXTERNAL_STORAGE权限
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          // 请求MANAGE_EXTERNAL_STORAGE权限
          status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        }
        return true;
      } else {
        // Android 10及以下版本使用传统存储权限
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          // 请求存储权限
          status = await Permission.storage.request();
          return status.isGranted;
        }
        return true;
      }
    }
    return true;
  }

  // 选择音乐文件的方法
  void _selectMusicFile() async {
    // 请求完全存储权限
    bool hasPermission = await _requestFullStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('权限不足'),
              content: const Text('需要完全存储权限才能选择和修改文件'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    try {
      // 使用file_selector选择音频文件
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'audio',
        extensions: ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'],
      );
      
      final List<XFile> files = await openFiles(
        acceptedTypeGroups: [typeGroup],
        confirmButtonText: '选择音频文件',
      );
      
      // 检查用户是否选择了文件
      if (files.isEmpty) {
        // 用户取消了选择
        return;
      }
      
      // 只处理第一个文件（因为我们希望是单文件选择）
      final XFile selectedFile = files.first;
      final String fileName = path.basename(selectedFile.path);
      // 记录原始文件路径
      final String originalFilePath = selectedFile.path;
      
      if (kDebugMode) {
        print('KDEBUG: 用户选择的文件路径: $originalFilePath');
        print('KDEBUG: 用户选择的文件名: $fileName');
      }
      
      // 显示进度对话框
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('正在读取文件'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('正在读取 $fileName...'),
                ],
              ),
            );
          },
        );
      }
      
      // 获取应用缓存目录
      Directory cacheDir = await getTemporaryDirectory();
      // 获取当前日期作为文件夹名称
      String dateFolder = DateFormat('yyyyMMdd').format(DateTime.now());
      // 构建带日期的缓存目录路径
      String datedCacheDirPath = path.join(cacheDir.path, 'audio_cache', dateFolder);
      // 创建带日期的缓存目录
      Directory datedCacheDir = Directory(datedCacheDirPath);
      if (!await datedCacheDir.exists()) {
        await datedCacheDir.create(recursive: true);
      }
      
      // 构建原始文件的目标路径（加上"_original"后缀）
      String originalFileName = '${path.basenameWithoutExtension(fileName)}_original${path.extension(fileName)}';
      String targetPath = path.join(datedCacheDirPath, originalFileName);
      
      if (kDebugMode) {
        print('KDEBUG: 原始文件路径: $originalFilePath');
        print('KDEBUG: 缓存目录: $datedCacheDirPath');
        print('KDEBUG: 缓存中的原始文件路径: $targetPath');
      }
      
      // 将选中的文件复制到缓存目录，覆盖已存在的同名文件
      await selectedFile.saveTo(targetPath);
      
      if (kDebugMode) {
        print('KDEBUG: 原始文件已成功复制到缓存');
        print('KDEBUG: 缓存中的原始文件是否存在: ${await File(targetPath).exists()}');
        print('KDEBUG: 缓存中的原始文件大小: ${await File(targetPath).length()} 字节');
      }
      
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // 调用edit.dart中的函数读取音频标签
      final tags = await readAudioTags(targetPath);
      
      if (kDebugMode) {
        print('读取到的标签: $tags');
      }
      
      // 如果成功读取标签，则导航到标签编辑界面
      // 传递缓存中的原始文件路径和真实的文件路径
      if (tags != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TagEditorUI(
              tag: tags, 
              filePath: targetPath, // 使用缓存中的原始文件路径
              realFilePath: originalFilePath, // 传递真实的原始文件路径
            ),
          ),
        );
      } else if (mounted) {
        // 显示对话框通知用户文件已复制但未能读取标签信息
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('读取失败'),
              content: const Text('文件已复制到缓存，但未能读取标签信息'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // 关闭可能仍在显示的进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (kDebugMode) {
        print('选择或处理文件时出错: $e');
      }
      
      // 显示错误消息给用户
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('处理文件出错'),
              content: Text('处理文件时出错: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 在其他初始化完成后异步加载背景图片
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBackgroundImage();
    });
  }

  // 构建页面UI的方法
  @override
  Widget build(BuildContext context) {
    // 返回Scaffold布局组件，这是Material Design的基本页面布局结构
    return Scaffold(
      // 页面主体内容
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
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withOpacity(0.2) 
                  : Colors.white.withOpacity(0.2),
              ),
            ),
          // 页面内容
          Center(
            // 居中布局组件
            child: Column(
              // 主轴居中对齐
              mainAxisAlignment: MainAxisAlignment.center,
              // 子组件列表
              children: <Widget>[
                Icon(
                  Icons.music_note,
                  size: 100,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
                ),
                const SizedBox(height: 20),
                Text(
                  '选择一个音频文件开始编辑标签',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                // 选择文件按钮
                LiquidGlassLayer(
                  settings: LiquidGlassSettings(
                    thickness: 12,
                    blur: 1.5,
                    lightAngle: 0.3 * pi,
                    lightIntensity: 1.2,
                    ambientStrength: 0.4,
                    blend: 0.7,
                    refractiveIndex: 1.6,
                    chromaticAberration: 0.4,
                    saturation: 1.2,
                  ),
                  child: LiquidGlass.inLayer(
                    shape: LiquidRoundedRectangle(
                      borderRadius: const Radius.circular(28.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _selectMusicFile,
                          borderRadius: BorderRadius.circular(28.0),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.music_note),
                              SizedBox(width: 8),
                              Text('选择音频文件'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 右上角操作按钮列表
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.0,
            right: 12.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 主题切换按钮
                LiquidGlassLayer(
                  settings: LiquidGlassSettings(
                    thickness: 12,
                    blur: 1.5,
                    lightAngle: 0.3 * pi,
                    lightIntensity: 1.2,
                    ambientStrength: 0.4,
                    blend: 0.7,
                    refractiveIndex: 1.6,
                    chromaticAberration: 0.4,
                    saturation: 1.2,
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
                          onTap: widget.toggleTheme,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isDarkMode == null
                                    // 如果为null，显示自动模式图标
                                    ? Icons.auto_mode
                                    // 否则根据布尔值显示暗色或亮色模式图标
                                    : (widget.isDarkMode! ? Icons.dark_mode : Icons.light_mode),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.isDarkMode == null
                                    ? '跟随系统'
                                    : (widget.isDarkMode! ? '深色模式' : '浅色模式'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 批量编辑功能按钮
                LiquidGlassLayer(
                  settings: LiquidGlassSettings(
                    thickness: 12,
                    blur: 1.5,
                    lightAngle: 0.3 * pi,
                    lightIntensity: 1.2,
                    ambientStrength: 0.4,
                    blend: 0.7,
                    refractiveIndex: 1.6,
                    chromaticAberration: 0.4,
                    saturation: 1.2,
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
                            // 导航到批量编辑页面
                            Navigator.push(
                              context,
                              // 使用MaterialPageRoute进行页面跳转
                              MaterialPageRoute(builder: (context) => const BatchEditPage()),
                            );
                          },
                          borderRadius: BorderRadius.circular(20.0),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu),
                              SizedBox(width: 6),
                              Text('批量编辑'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}