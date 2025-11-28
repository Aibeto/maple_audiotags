// 导入Flutter基础Material设计组件库
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 导入动态颜色支持库，用于Android 12+的Monet取色功能
import 'package:dynamic_color/dynamic_color.dart';
// 导入共享偏好设置库，用于持久化存储用户设置
import 'package:shared_preferences/shared_preferences.dart';
// 导入文件选择器库，用于选择音乐文件
import 'package:file_picker/file_picker.dart';
// 导入Dart IO库，用于文件操作
import 'dart:io';
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
import 'package:fluttertoast/fluttertoast.dart';

// 导入日期格式化库
import 'package:intl/intl.dart';

// 导入MethodChannel用于与原生通信
import 'package:flutter/services.dart';

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
  static const platform = MethodChannel('aibeto.maple.audiotags/filepath');

  // 选择音乐文件的方法
  void _selectMusicFile() async {
    // 使用file_picker选择音乐文件
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      // 按后缀名过滤文件
      allowedExtensions: ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'],
      // 限制只能选择指定类型文件
      type: FileType.custom,
      // 只允许选择一个文件
      allowMultiple: false,
    );

    // 检查用户是否选择了文件
    if (result != null) {
      // 获取选中的第一个文件
      PlatformFile file = result.files.first;
      
      // 检查文件路径是否存在
      if (file.path != null) {
        try {
          // 尝试获取真实文件路径（仅在Android上）
          String? realPath;
          if (Platform.isAndroid) {
            try {
              realPath = await platform.invokeMethod('getRealPathFromUri', {'uri': file.path});
              if (kDebugMode) {
                print('KDEBUG: 尝试获取真实路径: $realPath');
              }
            } catch (e) {
              if (kDebugMode) {
                print('KDEBUG: 获取真实路径失败: $e');
              }
            }
          }
          
          // 显示进度对话框
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
                    Text('正在读取 ${file.name}...'),
                  ],
                ),
              );
            },
          );
          
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
          String originalFileName = '${path.basenameWithoutExtension(file.name)}_original${path.extension(file.name)}';
          String targetPath = path.join(datedCacheDirPath, originalFileName);
          
          if (kDebugMode) {
            print('KDEBUG: file_picker返回的路径(可能是缓存路径): ${file.path}');
            if (realPath != null) {
              print('KDEBUG: 获取到的真实文件路径: $realPath');
            }
            print('KDEBUG: 带日期的缓存目录: $datedCacheDirPath');
            print('KDEBUG: 原始文件在缓存中的路径: $targetPath');
          }
          
          // 将选中的文件复制到缓存目录，覆盖已存在的同名文件
          await File(file.path!).copy(targetPath);
          
          if (kDebugMode) {
            print('KDEBUG: 原始文件已成功复制到缓存');
            print('KDEBUG: 缓存中的原始文件是否存在: ${await File(targetPath).exists()}');
            print('KDEBUG: 缓存中的原始文件大小: ${await File(targetPath).length()} 字节');
          }
          
          // 关闭进度对话框
          Navigator.of(context).pop();
          
          // 调用edit.dart中的函数读取音频标签
          final tags = await readAudioTags(targetPath);
          
          if (kDebugMode) {
            print('读取到的标签: $tags');
          }
          
          // 如果成功读取标签，则导航到标签编辑界面
          // 传递缓存中的原始文件路径和真实路径（如果有的话）
          if (tags != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TagEditorUI(
                  tag: tags, 
                  filePath: targetPath, // 使用缓存中的原始文件路径
                  realFilePath: realPath, // 传递真实文件路径（如果有）
                ),
              ),
            );
          } else if (mounted) {
            // 显示Toast通知用户文件已复制但未能读取标签信息
            Fluttertoast.showToast(
              msg: '文件已复制到缓存，但未能读取标签信息',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
            );
          }
        } catch (e) {
          // 关闭进度对话框
          Navigator.of(context).pop();
          
          // 处理文件复制错误
          if (kDebugMode) {
            if (kDebugMode) {
              print('处理文件时出现异常: $e');
            }
          }
          if (mounted) {
            Fluttertoast.showToast(
              msg: '处理文件时出错: $e',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
            );
          }
        }
      } else {
        // 文件路径为空时的处理
        if (mounted) {
          Fluttertoast.showToast(
            msg: '无法获取文件路径',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }
    } else {
      // 用户取消了选择
      if (mounted) {
        Fluttertoast.showToast(
          msg: '未选择任何文件',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  // 构建页面UI的方法
  @override
  Widget build(BuildContext context) {
    // 返回Scaffold布局组件，这是Material Design的基本页面布局结构
    return Scaffold(
      // 应用栏
      appBar: AppBar(
        // 设置应用栏背景色，使用主题中的反向主色
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // 设置应用栏标题，使用从父组件传递的title参数
        title: Text(widget.title),
        // 右侧操作按钮列表
        actions: [
          // 主题切换按钮
          IconButton(
            // 根据当前主题模式显示不同图标
            icon: Icon(
              widget.isDarkMode == null
                  // 如果为null，显示自动模式图标
                  ? Icons.auto_mode
                  // 否则根据布尔值显示暗色或亮色模式图标
                  : (widget.isDarkMode! ? Icons.dark_mode : Icons.light_mode),
            ),
            // 点击事件处理，调用父组件传递的切换主题方法
            onPressed: widget.toggleTheme,
          ),
          // 批量编辑功能按钮
          IconButton(
            // 菜单图标
            icon: const Icon(Icons.menu),
            // 点击事件处理
            onPressed: () {
              // 导航到批量编辑页面
              Navigator.push(
                context,
                // 使用MaterialPageRoute进行页面跳转
                MaterialPageRoute(builder: (context) => const BatchEditPage()),
              );
            },
          ),
        ]
      ),
      // 页面主体内容
      body: Center(
        // 居中布局组件
        child: Column(
          // 主轴居中对齐
          mainAxisAlignment: MainAxisAlignment.center,
          // 子组件列表
          children: <Widget>[
            const Icon(
              Icons.music_note,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              '选择一个音频文件开始编辑标签',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      // 浮动操作按钮
      floatingActionButton: FloatingActionButton(
        // 按钮点击事件，调用选择音乐文件方法
        onPressed: _selectMusicFile,
        // 按钮提示信息
        tooltip: '选择音乐文件',
        // 按钮图标
        child: const Icon(Icons.music_note),
      ),
    );
  }
}