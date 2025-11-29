// 音频标签编辑UI组件
// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';
// 添加这一行以引入pi常量
import 'dart:io' show Platform, File;
import 'dart:ui' as ui;

import 'package:audiotags/audiotags.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

/// 音频标签编辑UI组件
/// 提供一个表单界面用于查看和编辑音频文件的标签信息
class TagEditorUI extends StatefulWidget {
  /// 构造函数
  /// [tag] 需要编辑的标签信息
  /// [filePath] 音频文件路径
  const TagEditorUI({
    super.key,
    required this.tag,
    required this.filePath,
    this.realFilePath,
  });

  /// 音频文件的标签信息
  final Tag tag;

  /// 音频文件路径（当前工作文件，通常是缓存中的原始文件）
  final String filePath;
  
  /// 真实文件路径（如果可以获取到的话）
  final String? realFilePath;

  @override
  State<TagEditorUI> createState() => _TagEditorUIState();
}

class _TagEditorUIState extends State<TagEditorUI> with TickerProviderStateMixin {
  /// 控制器用于编辑标题
  late TextEditingController _titleController;

  /// 控制器用于编辑艺术家
  late TextEditingController _artistController;

  /// 控制器用于编辑专辑
  late TextEditingController _albumController;

  /// 控制器用于编辑专辑艺术家
  late TextEditingController _albumArtistController;

  /// 控制器用于编辑年份
  late TextEditingController _yearController;

  /// 控制器用于编辑流派
  late TextEditingController _genreController;

  /// 控制器用于编辑曲目号
  late TextEditingController _trackNumberController;

  /// 控制器用于编辑曲目总数
  late TextEditingController _trackTotalController;

  /// 控制器用于编辑光盘号
  late TextEditingController _discNumberController;

  /// 控制器用于编辑光盘总数
  late TextEditingController _discTotalController;

  /// 控制器用于编辑歌词
  late TextEditingController _lyricsController;

  /// 控制器用于编辑持续时间
  late TextEditingController _durationController;

  /// 控制器用于编辑BPM
  late TextEditingController _bpmController;
  
  /// 控制器用于编辑文件名
  late TextEditingController _filenameController;
  
  /// 控制器用于编辑文件扩展名
  late TextEditingController _extensionController;

  /// 表单键，用于验证和保存表单
  final _formKey = GlobalKey<FormState>();
  
  /// 当前封面图片数据
  Uint8List? _currentCoverImage;
  
  /// 背景图片旋转动画控制器
  late AnimationController _backgroundRotationController;
  
  /// 背景图片旋转动画值
  late Animation<double> _backgroundRotationAnimation;
  
  /// 图片刷新定时器
  // Timer? _refreshTimer; // 已移除，不再使用定时器刷新

  @override
  void initState() {
    super.initState();
    
    // 初始化控制器并设置初始值
    _titleController = TextEditingController(text: widget.tag.title);
    _artistController = TextEditingController(text: widget.tag.trackArtist);
    _albumController = TextEditingController(text: widget.tag.album);
    _albumArtistController = TextEditingController(text: widget.tag.albumArtist);
    _yearController = TextEditingController(text: widget.tag.year?.toString());
    _genreController = TextEditingController(text: widget.tag.genre);
    _trackNumberController = TextEditingController(text: widget.tag.trackNumber?.toString());
    _trackTotalController = TextEditingController(text: widget.tag.trackTotal?.toString());
    _discNumberController = TextEditingController(text: widget.tag.discNumber?.toString());
    _discTotalController = TextEditingController(text: widget.tag.discTotal?.toString());
    _lyricsController = TextEditingController(text: widget.tag.lyrics);
    _durationController = TextEditingController(text: widget.tag.duration?.toString());
    _bpmController = TextEditingController(text: widget.tag.bpm?.toString());
    
    // 初始化文件名和扩展名控制器
    String fileName = path.basenameWithoutExtension(widget.filePath);
    // 删除文件名末尾的"_original"后缀（如果存在）
    if (fileName.endsWith('_original')) {
      fileName = fileName.substring(0, fileName.length - 9); // "_original" 长度为9
    }
    String fileExtension = path.extension(widget.filePath);
    _filenameController = TextEditingController(text: fileName);
    _extensionController = TextEditingController(text: fileExtension);
    
    // 初始化封面图片
    if (widget.tag.pictures.isNotEmpty) {
      _currentCoverImage = widget.tag.pictures.first.bytes;
    }
    
    // 初始化背景图片旋转动画控制器
    _backgroundRotationController = AnimationController(
      duration: const Duration(seconds: 60), // 增加50%旋转速度，360度/6度每秒 = 60秒
      vsync: this,
    )..repeat(); // 无限重复动画
    
    // 创建旋转动画值（0到1）
    _backgroundRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundRotationController);
    
    // 不再使用定时器刷新，改用更高效的方式处理图片渲染
    // 图片会在旋转动画中自然重新渲染，无需额外处理
  }

  @override
  void dispose() {
    // 释放控制器资源
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _albumArtistController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _trackNumberController.dispose();
    _trackTotalController.dispose();
    _discNumberController.dispose();
    _discTotalController.dispose();
    _lyricsController.dispose();
    _durationController.dispose();
    _bpmController.dispose();
    _filenameController.dispose();
    _extensionController.dispose();
    _backgroundRotationController.dispose(); // 释放动画控制器
    // _refreshTimer?.cancel(); // 已移除定时器刷新
    super.dispose();
  }

  /// 保存标签更改
  Future<void> _saveTags() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 显示保存进度
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              title: Text('保存中'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('正在保存标签信息...'),
                ],
              ),
            );
          },
        );

        // 直接保存到当前编辑的文件
        await _saveDirectly();
        return;
      } on PlatformException catch (e) {
        // 关闭进度对话框
        if (mounted) {
          Navigator.of(context).pop();
          
          // 显示错误消息
          if (kDebugMode) {
            print('保存失败: ${e.message}');
          }
          
          // 使用对话框显示错误
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('保存失败'),
                content: Text('保存失败: ${e.message}'),
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
        // 关闭进度对话框
        if (mounted) {
          Navigator.of(context).pop();
          
          // 显示错误消息
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('保存失败'),
                content: Text('保存失败: $e'),
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
          
          if (kDebugMode) {
            print('KDEBUG: 保存标签时出错: $e');
            print('KDEBUG: 错误堆栈: ${StackTrace.current}');
          }
        }
      }
    }
  }

  /// 直接保存标签到当前文件，并提供选项将文件保存到用户指定位置
  Future<void> _saveDirectly() async {
    try {
      // Prepare image data
      List<Picture>? pictures;
      if (_currentCoverImage != null) {
        pictures = [Picture(bytes: _currentCoverImage!, mimeType: MimeType.jpeg, pictureType: PictureType.other)];
      }
      
      // Create new tag object
      final updatedTag = Tag(
        title: _titleController.text,
        trackArtist: _artistController.text,
        album: _albumController.text,
        albumArtist: _albumArtistController.text,
        genre: _genreController.text,
        year: _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : null,
        trackNumber: _trackNumberController.text.isNotEmpty ? int.tryParse(_trackNumberController.text) : null,
        trackTotal: _trackTotalController.text.isNotEmpty ? int.tryParse(_trackTotalController.text) : null,
        discNumber: _discNumberController.text.isNotEmpty ? int.tryParse(_discNumberController.text) : null,
        discTotal: _discTotalController.text.isNotEmpty ? int.tryParse(_discTotalController.text) : null,
        lyrics: _lyricsController.text,
        duration: widget.tag.duration, // 保持原始时长
        bpm: _bpmController.text.isNotEmpty ? double.tryParse(_bpmController.text) : null,
        pictures: pictures ?? const [], // 使用新的图片数据，如果为空则使用空列表
      );

      // 直接将标签写入当前编辑的文件（即widget.filePath）
      await AudioTags.write(widget.filePath, updatedTag);
      
      if (kDebugMode) {
        print('KDEBUG: 标签已直接写入文件: ${widget.filePath}');
        print('KDEBUG: 当前平台: ${Platform.operatingSystem}');
      }
      
      // 保存后使用文件保存器将文件复制到用户选择的位置
      await _saveWithFileSaver();
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 直接保存标签失败: $e');
      }
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        // 使用对话框显示错误
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('保存失败'),
              content: Text('保存失败: $e'),
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

  /// 使用系统文件保存器将缓存中的文件复制到用户选择的位置
  Future<void> _saveWithFileSaver() async {
    try {
      // 获取当前时间戳
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      // 获取文件名和扩展名（使用用户编辑的值）
      String fileName = _filenameController.text;
      String fileExtension = _extensionController.text;
      // 构建带时间戳的文件名
      String timestampedFileName = '${fileName}_modified_$timestamp$fileExtension';
      
      if (kDebugMode) {
        print('KDEBUG: 准备使用文件保存器保存文件');
        print('KDEBUG: 建议的文件名: $timestampedFileName');
        print('KDEBUG: 当前平台: ${Platform.operatingSystem}');
      }
      
      // 根据不同平台使用不同的保存方法
      if (Platform.isAndroid) {
        // 在Android上使用替代方法保存文件
        String userDefinedFileName = '$fileName$fileExtension';
        await _saveFileForAndroid(userDefinedFileName);
        return;
      } else if (Platform.isIOS) {
        if (kDebugMode) {
          print('KDEBUG: iOS平台使用标准文件保存方法');
        }
      } else if (Platform.isWindows) {
        if (kDebugMode) {
          print('KDEBUG: Windows平台使用标准文件保存方法');
        }
      } else if (Platform.isMacOS) {
        if (kDebugMode) {
          print('KDEBUG: macOS平台使用标准文件保存方法');
        }
      } else if (Platform.isLinux) {
        if (kDebugMode) {
          print('KDEBUG: Linux平台使用标准文件保存方法');
        }
      }
      
      // 使用文件选择器让用户选择保存位置
      final FileSaveLocation? outputFile = await getSaveLocation(
        suggestedName: timestampedFileName,
        acceptedTypeGroups: [XTypeGroup(label: 'audio', extensions: [fileExtension.replaceFirst('.', '')])],
      );

      if (outputFile != null) {
        if (kDebugMode) {
          print('KDEBUG: 用户选择的输出文件路径: $outputFile');
          print('KDEBUG: 从缓存文件复制: ${widget.filePath}');
        }
        
        // 将文件复制到用户选择的位置
        final saveFile = XFile(widget.filePath);
        await saveFile.saveTo(outputFile as String);
        
        if (kDebugMode) {
          print('KDEBUG: 文件已成功复制到: $outputFile');
        }
        
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          
          // 显示成功消息
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('保存成功'),
                content: Text('文件已保存到: $outputFile'),
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
      } else {
        // 用户取消了保存操作
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('操作取消'),
                content: const Text('保存操作已取消'),
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
        
        if (kDebugMode) {
          print('KDEBUG: 用户取消了保存操作');
        }
      }
    } on UnimplementedError catch (e) {
      // 处理getSaveLocation未实现的情况
      if (kDebugMode) {
        print('KDEBUG: getSaveLocation()未实现: $e');
        print('KDEBUG: 当前平台: ${Platform.operatingSystem}');
      }
      
      // 尝试使用平台特定的替代方法
      if (Platform.isAndroid) {
        String fileName = _filenameController.text;
        String fileExtension = _extensionController.text;
        String userDefinedFileName = '$fileName$fileExtension';
        
        await _saveFileForAndroid(userDefinedFileName);
        return;
      } else if (Platform.isIOS) {
        if (kDebugMode) {
          print('KDEBUG: iOS平台不支持文件保存器的替代方案');
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        if (kDebugMode) {
          print('KDEBUG: ${Platform.operatingSystem}平台不支持文件保存器');
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        // 显示错误消息
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('功能不支持'),
              content: const Text('当前平台不支持文件保存器功能'),
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
      if (kDebugMode) {
        print('KDEBUG: 使用文件保存器保存失败: $e');
      }
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('保存失败'),
              content: Text('保存失败: $e'),
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
  
  /// Android平台的文件保存方法
  Future<void> _saveFileForAndroid(String suggestedName) async {
    try {
      if (kDebugMode) {
        print('KDEBUG: 使用Android平台文件保存方法');
        print('KDEBUG: 建议的文件名: $suggestedName');
      }
      
      // 检查并请求存储权限
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('KDEBUG: 存储权限被拒绝');
        }
        
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('权限不足'),
                content: const Text('需要存储权限才能保存文件'),
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
      
      // 使用Android默认的下载目录
      String downloadPath = '/sdcard/Download/$suggestedName';
      File targetFile = File(downloadPath);
      
      // 确保目录存在
      await targetFile.create(recursive: true);
      
      if (kDebugMode) {
        print('KDEBUG: 尝试将文件保存到: $downloadPath');
      }
      
      // 将缓存文件复制到下载目录
      File sourceFile = File(widget.filePath);
      await sourceFile.copy(downloadPath);
      
      if (kDebugMode) {
        print('KDEBUG: 文件已成功保存到: $downloadPath');
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        // 显示成功消息
        Fluttertoast.showToast(
          msg: '文件已保存到: $downloadPath',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: Android平台文件保存失败: $e');
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('保存失败'),
              content: Text('Android平台保存失败: $e'),
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
  
  /// 请求Android存储权限
  Future<bool> _requestStoragePermission() async {
    try {
      // 检查Android版本
      if (Platform.isAndroid) {
        final androidVersion = int.tryParse(Platform.operatingSystemVersion.replaceAll(RegExp(r'[^\d.]'), '').split('.').first) ?? 0;
        
        if (kDebugMode) {
          print('KDEBUG: Android版本: $androidVersion');
        }
        
        if (androidVersion >= 11) {
          // Android 11及以上版本使用MANAGE_EXTERNAL_STORAGE权限
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            if (kDebugMode) {
              print('KDEBUG: 请求MANAGE_EXTERNAL_STORAGE权限');
            }
            // 请求MANAGE_EXTERNAL_STORAGE权限
            status = await Permission.manageExternalStorage.request();
            return status.isGranted;
          }
          if (kDebugMode) {
            print('KDEBUG: MANAGE_EXTERNAL_STORAGE权限已授予');
          }
          return true;
        } else {
          // Android 10及以下版本使用传统存储权限
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            if (kDebugMode) {
              print('KDEBUG: 请求存储权限');
            }
            // 请求存储权限
            status = await Permission.storage.request();
            return status.isGranted;
          }
          if (kDebugMode) {
            print('KDEBUG: 存储权限已授予');
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 权限请求失败: $e');
      }
      return false;
    }
  }
  
  /// 选择新的封面图片
  Future<void> _selectNewCoverImage() async {
    // 使用file_selector选择图片文件
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'bmp', 'gif'],
    );
    
    final List<XFile> files = await openFiles(
      acceptedTypeGroups: [typeGroup],
      confirmButtonText: '选择图片文件',
    );
    
    // 检查用户是否选择了文件
    if (files.isEmpty) {
      // 用户取消了选择
      return;
    }
    
    // 只处理第一个文件
    final XFile selectedFile = files.first;
    
    try {
      // 直接读取文件内容为字节
      final Uint8List imageData = await selectedFile.readAsBytes();
      Fluttertoast.showToast(
        msg: '正在导入图片: ${selectedFile.name}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      // 检查文件大小是否超过3MB
      const int maxSize = 3 * 1024 * 1024; // 3MB in bytes
      if (imageData.length > maxSize) {
        // 显示文件过大的提示
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('文件过大警告'),
                content: Text('图片文件过大(${(imageData.length / (1024 * 1024)).toStringAsFixed(2)}MB)，可能导致其他软件读取时崩溃。本软件通常可以正常处理这些问题但加载较慢，且可能无法保存到标签。你可以在封面显示后截图裁切来减小图片文件大小。'),
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
      
      // 更新当前封面图片
      if (mounted) {
        setState(() {
          _currentCoverImage = imageData;
        });
      }
      
      if (kDebugMode) {
        print('KDEBUG: 新封面图片已选择，大小: ${imageData.length} 字节');
      }
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 选择新封面图片时出错: $e');
      }
      
      // 显示错误消息给用户
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('选择图片出错'),
              content: Text('选择图片时出错: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片 - 根据主题模式调整亮度并添加旋转动画
          if (_currentCoverImage != null)
    Positioned.fill(
      child: RotationTransition(
        turns: _backgroundRotationAnimation,
        child: Container(
          alignment: Alignment.center,
          child: Transform.scale(
            scale: 2.0, // 放大50%
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: MemoryImage(_currentCoverImage!),
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.05)
                        : Colors.white.withOpacity(0.05),
                    BlendMode.srcOver,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  // 模糊层 - 应用在背景图片之上
  if (_currentCoverImage != null)
    Positioned.fill(
      child: Container(
        alignment: Alignment.center,
        child: Transform.scale(
          scale: 2.0, // 放大50%，与背景图片保持一致
          child: ClipRect( // 必须包含ClipRect才能使BackdropFilter正常工作
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0), // 增大十倍模糊半径
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.30)
                    : Colors.white.withOpacity(0.25), // 使用与背景图片相同的颜色过滤器
              ),
            ),
          ),
        ),
      ),
    ),
  // 内容层 - 表单等UI元素
  SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Form(
      key: _formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // 添加间距避让状态栏
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              // 添加一个占位符，用于使内容层与状态栏之间的间距保持一致
              const SizedBox(height: 16.0),
              // 封面图片显示区域
              // 检查是否有封面图片数据，如果有则显示图片，否则显示添加图片的占位符
              if (_currentCoverImage != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _selectNewCoverImage,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Image.memory(
                            _currentCoverImage!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                )
              else
                Center(
                  child: GestureDetector(
                    onTap: _selectNewCoverImage,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                          Text('点击添加封面图片', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _filenameController,
                      decoration: const InputDecoration(
                        labelText: '文件名',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _extensionController,
                      decoration: const InputDecoration(
                        labelText: '后缀',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _artistController,
                      decoration: const InputDecoration(
                        labelText: '艺术家',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _albumController,
                      decoration: const InputDecoration(
                        labelText: '专辑',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _albumArtistController,
                decoration: const InputDecoration(
                  labelText: '专辑艺术家',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _genreController,
                      decoration: const InputDecoration(
                        labelText: '流派',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bpmController,
                      decoration: const InputDecoration(
                        labelText: 'BPM',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: '年份',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _trackNumberController,
                      decoration: const InputDecoration(
                        labelText: '曲目号',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _trackTotalController,
                      decoration: const InputDecoration(
                        labelText: '曲目总数',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discNumberController,
                      decoration: const InputDecoration(
                        labelText: '光盘号',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _discTotalController,
                      decoration: const InputDecoration(
                        labelText: '光盘总数',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: '持续时间(秒)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: false, // 持续时间不能编辑
                    ),
                  ),
                ],
              ),
            
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: TextFormField(
                  controller: _lyricsController,
                  decoration: const InputDecoration(
                    labelText: '歌词',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
              const SizedBox(height: 24),
              // Center(
              //   child: ElevatedButton.icon(
              //     onPressed: _saveTags,
              //     icon: const Icon(Icons.save),
              //     label: const Text('保存标签'),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    ),
  ),
        ],
        
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTags,
        tooltip: '保存标签',
        child: const Icon(Icons.save),
      ),
    );
  }
}
