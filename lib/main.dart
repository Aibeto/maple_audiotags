// 导入Flutter基础Material设计组件库
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 导入动态颜色支持库，用于Android 12+的Monet取色功能
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'settings_page.dart';
// 导入共享偏好设置库，用于持久化存储用户设置
import 'package:shared_preferences/shared_preferences.dart';
// 导入Dart IO库，用于文件操作
import 'dart:io';
// 导入路径处理库
import 'package:path/path.dart' as path;
// 导入标签编辑UI
import 'tag_editor_ui.dart';
// 导入设置页面

// 导入日期格式化库

// 导入权限处理库
import 'package:permission_handler/permission_handler.dart';

// 导入文件选择器
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'config/glass_effect_config.dart';

// 导入 isolate 工具
import 'isolate_utils.dart';

// 导入网络图片加载库
import 'package:http/http.dart' as http;
import 'dart:ui';

// 导入路径提供器，用于获取临时目录
import 'package:path_provider/path_provider.dart';
// 导入桌面拖放库
import 'package:desktop_drop/desktop_drop.dart';

// 程序入口点，使用async关键字支持异步操作
Future<void> _clearCacheDirectory() async {
  try {
    // 获取临时目录
    final tempDir = await getTemporaryDirectory();
    // 删除临时目录下的所有文件和文件夹
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      // 重新创建临时目录
      await tempDir.create(recursive: true);
    }
    if (kDebugMode) {
      print('KDEBUG: 缓存目录已清理');
    }
  } catch (e) {
    if (kDebugMode) {
      print('KDEBUG: 清理缓存目录时出错: $e');
    }
  }
}

void main() async {
  // 确保Flutter框架初始化完成
  WidgetsFlutterBinding.ensureInitialized();
  
  // 如果是Android系统，清理缓存目录
  if (Platform.isAndroid) {
    await _clearCacheDirectory();
  }
  
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
            // 否则使用用户选择的主题模式
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
            // 设置默认字体
            fontFamily: 'MapleMono',
            // 颜色方案配置，优先使用系统动态颜色
            colorScheme: lightDynamic ??
                // 如果系统不支持动态颜色，则使用蓝色种子颜色生成
                ColorScheme.fromSeed(
                  // 种子颜色
                  seedColor: Colors.blue,
                  // 亮度设置为亮色
                  brightness: Brightness.light,
                ),
          ),
          // 深色主题配置
          darkTheme: ThemeData(
            // 使用Material Design 3
            useMaterial3: true,
            // 设置默认字体
            fontFamily: 'MapleMono',
            // 颜色方案配置，优先使用系统动态颜色
            colorScheme: darkDynamic ??
                // 如果系统不支持动态颜色，则使用蓝色种子颜色生成
                ColorScheme.fromSeed(
                  // 种子颜色为蓝色
                  seedColor: Colors.blue,
                  // 亮度设置为暗色
                  brightness: Brightness.dark,
                ),
            // 背景颜色设置为黑色
            scaffoldBackgroundColor: Colors.black,
          ),
          // 设置主页
          home: HomePage(
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
class HomePage extends StatefulWidget {
  // 构造函数，接收必需的参数
  const HomePage({
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
  State<HomePage> createState() => _HomePageState();
}

// 音频标签编辑器主页状态管理类，继承自State
class _HomePageState extends State<HomePage> {
  // 效果等级变量
  int _effectLevel = 1;
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

    // 显示"正在获取音频"对话框
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('正在获取音频'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('请稍候...'),
              ],
            ),
          );
        },
      );
    }
    
    // 等待一小段时间确保对话框显示出来
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // // 关闭"正在获取音频"对话框
      // if (mounted) {
      //   Navigator.of(context).pop();
      // }
      
      // 使用file_picker选择音频文件（支持多选）
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'],
        allowMultiple: true,
      );
      
      // 检查用户是否选择了文件
      if (result == null || result.files.isEmpty) {
        // 用户取消了选择
        // 关闭"正在获取音频"对话框
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Toastrr显示提示信息
        Fluttertoast.showToast(
          msg: '未选择任何文件',

        );
        

        return;
      }
      
      // 限制最多处理文件个数
      if (result.files.length > 1000) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('文件数量过多'),
                content: Text('您选择了 ${result.files.length} 个文件，超过最大限制 1000 个文件。\n请减少选择的文件数量。'),
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
      
      // 转换为PlatformFile列表
      List<PlatformFile> selectedFiles = result.files.toList();
      
      // 根据选择的文件数量决定编辑模式
      if (selectedFiles.length == 1) {
        // 单个文件，进入正常编辑模式
        await _processSingleFile(selectedFiles.first);
      } else {
        // 多个文件，进入批量编辑模式（现在是在同一个编辑界面中处理）
        await _processMultipleFilesInSingleView(selectedFiles);
      }
    } catch (e) {
      // 关闭"正在获取音频"对话框
      if (mounted) {
        Navigator.of(context).pop();

      }
      
      // 关闭"正在获取音频"对话框
      // if (mounted) {
      //   Navigator.of(context).pop();
      // }

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

  // 处理单个文件（正常编辑模式）
  Future<void> _processSingleFile(PlatformFile selectedFile) async {
    final String fileName = path.basename(selectedFile.path!);
    // 记录原始文件路径
    final String originalFilePath = selectedFile.path!;
    
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
    
    try {
      // 确保UI有时间渲染进度对话框
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 直接读取原始文件的标签，不复制到缓存
      final tags = await compute(readAudioTagsInBackground, ReadTagsParams(originalFilePath));
      
      if (kDebugMode) {
        print('读取到的标签: $tags');
      }
      
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 关闭"正在获取音频"对话框
      if (mounted) {
        Navigator.of(context).pop();
      }


      // 如果成功读取标签，则导航到标签编辑界面
      // 直接使用原始文件路径
      if (tags != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TagEditorUI(
              tag: tags, 
              filePath: originalFilePath, // 直接使用原始文件路径
              realFilePath: originalFilePath, // 传递真实的原始文件路径
            ),
          ),
        );
      } else if (mounted) {
        // 显示对话框通知用户未能读取标签信息
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('读取失败'),
              content: const Text('未能读取文件标签信息'),
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

  // 处理多个文件（在单一视图中显示）
  Future<void> _processMultipleFilesInSingleView(List<PlatformFile> selectedFiles) async {
    if (kDebugMode) {
      print('KDEBUG: 处理多个文件 (${selectedFiles.length} 个)');
    }
    
    // 关闭"正在获取音频"对话框
    if (mounted) {
      Navigator.of(context).pop();

    }


    // 显示进度对话框
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('正在处理文件'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('正在处理 ${selectedFiles.length} 个文件...'),
              ],
            ),
          );
        },
      );
    }
    
    try {
      // 确保UI有时间渲染进度对话框
      await Future.delayed(const Duration(milliseconds: 100));
      
      List<String> filePaths = [];
      String? firstOriginalFilePath;
      
      // 收集所有文件路径
      for (int i = 0; i < selectedFiles.length; i++) {
        final selectedFile = selectedFiles[i];
        final String fileName = path.basename(selectedFile.path!);
        // 记录第一个文件的原始路径
        if (i == 0) {
          firstOriginalFilePath = selectedFile.path!;
        }
        
        if (kDebugMode) {
          print('KDEBUG: 处理第 ${i+1}/${selectedFiles.length} 个文件: $fileName');
        }
        
        filePaths.add(selectedFile.path!);
      }
      
      // 读取第一个文件的标签作为初始显示
      final tags = await compute(readAudioTagsInBackground, ReadTagsParams(filePaths[0]));
      
      if (kDebugMode) {
        print('读取到的第一个文件的标签: $tags');
      }
      
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // 如果成功读取标签，则导航到标签编辑界面
      // 直接使用原始文件路径
      if (tags != null && mounted) {
        // 从文件路径列表中移除第一个，因为它已经是主文件
        List<String> additionalFiles = filePaths.sublist(1);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TagEditorUI(
              tag: tags, 
              filePath: filePaths[0], // 直接使用第一个原始文件路径
              realFilePath: firstOriginalFilePath, // 传递真实的原始文件路径
              additionalFiles: additionalFiles, // 传递额外的文件列表
            ),
          ),
        );
      } else if (mounted) {
        // 显示对话框通知用户未能读取标签信息
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('读取失败'),
              content: const Text('未能读取文件标签信息'),
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
    // 加载效果等级设置
    _loadEffectLevel();
    // 在其他初始化完成后异步加载背景图片
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBackgroundImage();
    });
  }

  // 从shared preferences加载效果等级
  Future<void> _loadEffectLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _effectLevel = prefs.getInt('effectLevel') ?? 1; // 默认值为1
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
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withValues(alpha: 0.25) 
                    : Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          // DropTarget 包装整个背景区域
          Positioned.fill(
            child: DropTarget(
              onDragDone: (detail) {
                // 处理拖拽进来的文件
                _processDroppedFiles(detail.files);
              },
              child: Container(
                color: Colors.transparent, // 透明背景，不影响视觉效果
                child: Center(
                  // 居中布局组件
                  child: Column(
                    // 居中对齐
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
                        '选择音频文件开始编辑标签',
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
                        settings: GlassEffectConfig.fileSelectorSettings(
                          level: _effectLevel <= 1 
                            ? EffectLevel.low 
                            : (_effectLevel == 2 ? EffectLevel.medium : EffectLevel.high)
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
                      const SizedBox(height: 20),
                      Text(
                        '或者将音频文件拖拽到这里',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white70 
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          onTap: widget.toggleTheme,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isDarkMode == null
                                    // 如果为null，显示自动模式图标
                                    ? Icons.auto_mode
                                    // 否则显示暗色或亮色模式图标
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
                const SizedBox(width: 16),
                // 设置按钮
                LiquidGlassLayer(
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20.0),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.settings),
                              SizedBox(width: 6),
                              Text('设置'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 处理拖拽进来的文件
  void _processDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) return;

    // 过滤出音频文件
    List<XFile> audioFiles = files.where((file) {
      String? extension = path.extension(file.path).toLowerCase();
      return ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'].contains(extension);
    }).toList();

    if (audioFiles.isEmpty) {
      Fluttertoast.showToast(msg: '未找到支持的音频文件');
      return;
    }

    // 限制最多处理文件个数
    if (audioFiles.length > 1000) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('文件数量过多'),
              content: Text('您拖入了 ${audioFiles.length} 个文件，超过最大限制 1000 个文件。\n请减少拖入的文件数量。'),
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

    // 显示进度对话框
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('正在处理文件'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('正在处理 ${audioFiles.length} 个文件...'),
              ],
            ),
          );
        },
      );
    }

    try {
      // 确保UI有时间渲染进度对话框
      await Future.delayed(const Duration(milliseconds: 100));

      List<String> filePaths = [];
      String? firstOriginalFilePath;

      // 收集所有文件路径
      for (int i = 0; i < audioFiles.length; i++) {
        final XFile file = audioFiles[i];
        final String fileName = path.basename(file.path);
        // 记录第一个文件的原始路径
        if (i == 0) {
          firstOriginalFilePath = file.path;
        }

        if (kDebugMode) {
          print('KDEBUG: 处理第 ${i+1}/${audioFiles.length} 个文件: $fileName');
        }

        filePaths.add(file.path);
      }

      // 读取第一个文件的标签作为初始显示
      final tags = await compute(readAudioTagsInBackground, ReadTagsParams(filePaths[0]));

      if (kDebugMode) {
        print('读取到的第一个文件的标签: $tags');
      }

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 如果成功读取标签，则导航到标签编辑界面
      // 直接使用原始文件路径
      if (tags != null && mounted) {
        // 如果只有一个文件，直接进入编辑界面
        if (filePaths.length == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TagEditorUI(
                tag: tags,
                filePath: filePaths[0], // 直接使用原始文件路径
                realFilePath: firstOriginalFilePath, // 传递真实的原始文件路径
              ),
            ),
          );
        } else {
          // 多个文件，进入批量编辑模式
          // 从文件路径列表中移除第一个，因为它已经是主文件
          List<String> additionalFiles = filePaths.sublist(1);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TagEditorUI(
                tag: tags,
                filePath: filePaths[0], // 直接使用第一个原始文件路径
                realFilePath: firstOriginalFilePath, // 传递真实的原始文件路径
                additionalFiles: additionalFiles, // 传递额外的文件列表
              ),
            ),
          );
        }
      } else if (mounted) {
        // 显示对话框通知用户未能读取标签信息
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('读取失败'),
              content: const Text('未能读取文件标签信息'),
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
        print('处理拖拽文件时出错: $e');
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
}
