// 音频标签编辑UI组件
// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';
import 'dart:io' show Platform, File;
import 'dart:ui' as ui;
import 'dart:math';
// 添加用于计算MD5哈希值

import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/glass_effect_config.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart'; // 添加用于计算MD5哈希值


// 上间距



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
    this.additionalFiles,
  });

  /// 音频文件的标签信息
  final Tag tag;

  /// 音频文件路径（当前工作文件，通常是缓存中的原始文件）
  final String filePath;
  
  /// 真实文件路径（如果可以获取到的话）
  final String? realFilePath;
  
  /// 额外的文件列表（用于批量编辑模式）
  final List<String>? additionalFiles;

  @override
  State<TagEditorUI> createState() => _TagEditorUIState();
}

class _TagEditorUIState extends State<TagEditorUI> with TickerProviderStateMixin {
  // 添加效果等级参数
  EffectLevel effectLevel = EffectLevel.medium;
  // 效果等级数值
  int _effectLevelValue = 1;

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
  
  /// 滚动控制器用于批量编辑模式下的文件列表
  late ScrollController _fileListScrollController;

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

  /// 创建带液态玻璃效果背景的文本输入框组件
  Widget _buildGlassTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          // 液态玻璃背景效果
          Positioned.fill(
            child: LiquidGlassLayer(
              settings: GlassEffectConfig.baseSettings(level: effectLevel),
              child: LiquidGlass.inLayer(
                shape: LiquidRoundedRectangle(
                  borderRadius: const Radius.circular(12.0),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          // 文本输入框
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent, // 背景透明，显示液态玻璃效果
            ),
            style: const TextStyle(
              fontFamily: 'SourceHanSans',
            ),
            keyboardType: keyboardType,
            enabled: enabled,
          ),
        ],
      ),
    );
  }

  /// 创建带液态玻璃效果背景的歌词输入框组件（多行文本）
  Widget _buildGlassLyricsFormField() {
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          // 液态玻璃背景效果
          Positioned.fill(
            child: LiquidGlassLayer(
              settings: GlassEffectConfig.baseSettings(level: effectLevel),
              child: LiquidGlass.inLayer(
                shape: LiquidRoundedRectangle(
                  borderRadius: const Radius.circular(12.0),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          // 歌词文本输入框
          TextFormField(
            controller: _lyricsController,
            decoration: InputDecoration(
              labelText: '歌词',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent, // 背景透明，显示液态玻璃效果
            ),
            style: const TextStyle(
              fontFamily: 'SourceHanSans',
            ),
            maxLines: null,
            expands: true,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    
    // 加载效果等级设置
    _loadEffectLevel();
    
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
    
    // 初始化文件列表滚动控制器
    _fileListScrollController = ScrollController();
    
    // 初始化封面图片
    // 批量编辑模式下默认不显示封面图片，除非所有文件的封面MD5一致
    final bool isBatchMode = widget.additionalFiles != null && widget.additionalFiles!.isNotEmpty;
    if (!isBatchMode && widget.tag.pictures.isNotEmpty) {
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
    
    // 如果是批量编辑模式，检查所有文件的封面是否一致
    if (isBatchMode) {
      _checkAndLoadConsistentCoverImage();
    }
  }

  /// 从shared preferences加载效果等级
  Future<void> _loadEffectLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _effectLevelValue = prefs.getInt('effectLevel') ?? 1; // 默认值为1
      effectLevel = _effectLevelValue <= 1 
        ? EffectLevel.low 
        : (_effectLevelValue == 2 ? EffectLevel.medium : EffectLevel.high);
    });
  }

  /// 检查所有文件的封面是否一致，如果一致则加载显示
  Future<void> _checkAndLoadConsistentCoverImage() async {
    try {
      if (kDebugMode) {
        print('KDEBUG: 检查批量编辑模式下的封面一致性');
      }
      
      // 获取所有文件路径
      final List<String> allFiles = [
        widget.filePath,
        if (widget.additionalFiles != null) ...widget.additionalFiles!
      ];
      
      if (kDebugMode) {
        print('KDEBUG: 总共 ${allFiles.length} 个文件需要检查');
        // 打印所有文件路径用于调试
        for (int i = 0; i < allFiles.length; i++) {
          print('KDEBUG: 文件 $i: ${allFiles[i]}');
        }
      }
      
      // 读取所有文件的标签
      List<Tag?> tags = [];
      for (String filePath in allFiles) {
        if (kDebugMode) {
          print('KDEBUG: 正在读取文件标签: $filePath');
        }
        final tag = await AudioTags.read(filePath);
        tags.add(tag);
      }
      
      if (kDebugMode) {
        print('KDEBUG: 成功读取 ${tags.length} 个标签');
      }
      
      // 检查是否有封面图片
      bool hasCoverInAllFiles = true;
      for (int i = 0; i < tags.length; i++) {
        Tag? tag = tags[i];
        if (tag == null || tag.pictures.isEmpty) {
          hasCoverInAllFiles = false;
          if (kDebugMode) {
            print('KDEBUG: 文件 $i 没有封面图片');
          }
          break;
        }
      }
      
      if (!hasCoverInAllFiles) {
        if (kDebugMode) {
          print('KDEBUG: 并非所有文件都有封面图片');
        }
        return;
      }
      
      // 计算所有封面的MD5哈希值
      List<String> coverMD5s = [];
      for (int i = 0; i < tags.length; i++) {
        Tag? tag = tags[i];
        if (tag != null && tag.pictures.isNotEmpty) {
          final bytes = tag.pictures.first.bytes;
          final digest = md5.convert(bytes);
          coverMD5s.add(digest.toString());
          if (kDebugMode) {
            print('KDEBUG: 文件 $i 封面MD5: ${digest.toString()}');
          }
        }
      }
      
      if (kDebugMode) {
        print('KDEBUG: 计算得到 ${coverMD5s.length} 个封面MD5');
      }
      
      // 检查所有MD5是否一致
      bool allCoversSame = coverMD5s.every((md5) => md5 == coverMD5s.first);
      
      if (allCoversSame) {
        if (kDebugMode) {
          print('KDEBUG: 所有文件的封面一致，显示第一个文件的封面');
        }
        
        // 如果所有封面一致，则显示第一个文件的封面
        if (mounted) {
          setState(() {
            _currentCoverImage = tags.first?.pictures.first.bytes;
          });
        }
      } else {
        if (kDebugMode) {
          print('KDEBUG: 文件封面不一致，不显示封面');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 检查封面一致性时出错: $e');
        print('KDEBUG: 错误堆栈: ${StackTrace.current}');
      }
    }
  }

  /// 创建带液态玻璃效果的对话框
  Widget _buildGlassDialog({
    Widget? title,
    Widget? content,
    List<Widget>? actions,
  }) {
    return Center(
      child: LiquidGlassLayer(
        settings: GlassEffectConfig.dialogSettings(level: effectLevel),
        child: LiquidGlass.inLayer(
          shape: LiquidRoundedRectangle(
            borderRadius: const Radius.circular(20.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Theme.of(context).dialogBackgroundColor.withOpacity(0.9),
            ),
            padding: const EdgeInsets.all(24.0),
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) 
                  DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: 'SourceHanSans',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        )
                      ],
                    ),
                    child: title,
                  ),
                if (title != null && content != null) const SizedBox(height: 16),
                if (content != null)
                  DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: 'SourceHanSans',
                      fontSize: 17,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0.5, 0.5),
                        )
                      ],
                    ),
                    child: content,
                  ),
                if (actions != null && actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示带液态玻璃效果的对话框
  void _showGlassDialog({
    Widget? title,
    Widget? content,
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildGlassDialog(
          title: title,
          content: content,
          actions: actions,
        );
      },
    );
  }

  /// 还原所有更改到初始状态
  void _resetChanges() {
    // 显示确认对话框
    _showGlassDialog(
      title: const Text('确认还原'),
      content: const Text('确定要还原所有更改吗？此操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 关闭对话框
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 关闭确认对话框
            // 还原所有文本控制器的值到初始状态
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
            
            // 还原文件名和扩展名
            String fileName = path.basenameWithoutExtension(widget.filePath);
            if (fileName.endsWith('_original')) {
              fileName = fileName.substring(0, fileName.length - 9);
            }
            String fileExtension = path.extension(widget.filePath);
            _filenameController.text = fileName;
            _extensionController.text = fileExtension;
            
            // 还原封面图片
            Uint8List? originalImage;
            final bool isBatchMode = widget.additionalFiles != null && widget.additionalFiles!.isNotEmpty;
            if (!isBatchMode && widget.tag.pictures.isNotEmpty) {
              originalImage = widget.tag.pictures.first.bytes;
            }
            
            // 更新状态
            setState(() {
              _currentCoverImage = originalImage;
            });
          },
          child: const Text('确定'),
        ),
      ],
    );
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
    _fileListScrollController.dispose();
    _backgroundRotationController.dispose(); // 释放动画控制器
    // _refreshTimer?.cancel(); // 已移除定时器刷新
    super.dispose();
  }

  /// 保存标签更改
  Future<void> _saveTags() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 显示保存进度
        _showGlassDialog(
          title: const Text('保存中'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('正在保存标签信息...'),
            ],
          ),
        );

        // 检查是否为批量编辑模式
        final bool isBatchMode = widget.additionalFiles != null && widget.additionalFiles!.isNotEmpty;
        
        if (isBatchMode) {
          // 批量编辑模式下保存所有文件
          await _saveAllFiles();
        } else {
          // 单文件模式下直接保存
          await _saveDirectly();
        }
      } on PlatformException catch (e) {
        // 关闭进度对话框
        if (mounted) {
          Navigator.of(context).pop();
          
          // 显示错误消息
          if (kDebugMode) {
            print('保存失败: ${e.message}');
          }
          
          // 使用对话框显示错误
          _showGlassDialog(
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
        }
      } catch (e) {
        // 关闭进度对话框
        if (mounted) {
          Navigator.of(context).pop();
          
          // 显示错误消息
          _showGlassDialog(
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
          
          if (kDebugMode) {
            print('KDEBUG: 保存标签时出错: $e');
            print('KDEBUG: 错误堆栈: ${StackTrace.current}');
          }
        }
      }
    }
  }

  /// 批量保存所有文件
  Future<void> _saveAllFiles() async {
    try {
      if (kDebugMode) {
        print('KDEBUG: 开始批量保存文件');
      }
      
      // 获取所有文件路径
      final List<String> allFiles = [
        widget.filePath,
        if (widget.additionalFiles != null) ...widget.additionalFiles!
      ];
      
      if (kDebugMode) {
        print('KDEBUG: 总共需要保存 ${allFiles.length} 个文件');
        for (int i = 0; i < allFiles.length; i++) {
          print('KDEBUG: 文件 $i: ${allFiles[i]}');
        }
      }
      
      // 为每个文件创建相同的标签数据
      List<Picture>? pictures;
      if (_currentCoverImage != null) {
        pictures = [Picture(bytes: _currentCoverImage!, mimeType: MimeType.jpeg, pictureType: PictureType.other)];
      }
      
      // 创建新的标签对象
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
      
      // 保存所有文件并收集结果
      int successCount = 0;
      List<String> failedFiles = [];
      
      for (int i = 0; i < allFiles.length; i++) {
        String filePath = allFiles[i];
        if (kDebugMode) {
          print('KDEBUG: 正在保存文件 $i: $filePath');
        }
        
        try {
          await AudioTags.write(filePath, updatedTag);
          successCount++;
          if (kDebugMode) {
            print('KDEBUG: 文件保存成功: $filePath');
          }
        } catch (e) {
          if (kDebugMode) {
            print('KDEBUG: 保存文件时出错 $filePath: $e');
          }
          failedFiles.add(filePath);
          // 继续保存其他文件，不中断整个过程
        }
      }
      
      if (kDebugMode) {
        print('KDEBUG: 所有文件保存完成，成功: $successCount，失败: ${failedFiles.length}');
      }
      
      // 为每个文件分别执行导出流程
      await _saveEachFileWithFileSaver(allFiles, successCount, failedFiles);
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 批量保存标签失败: $e');
      }
      rethrow;
    }
  }
  
  /// 为每个文件分别执行导出流程
  Future<void> _saveEachFileWithFileSaver(List<String> allFiles, int successCount, List<String> failedFiles) async {
    if (kDebugMode) {
      print('KDEBUG: 开始为每个文件执行保存流程，总文件数: ${allFiles.length}');
    }
    
    // 关闭之前的进度对话框
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    // 显示批量保存进度
    if (mounted) {
      _showGlassDialog(
        title: const Text('批量保存'),
        content: Text('正在保存文件...\n已完成: 0/${allFiles.length}'),
      );
    }
    
    int savedCount = 0;
    List<String> saveFailedFiles = [];
    
    // 为每个文件执行保存操作
    for (int i = 0; i < allFiles.length; i++) {
      String filePath = allFiles[i];
      String fileName = path.basenameWithoutExtension(filePath);
      String fileExtension = path.extension(filePath);
      
      // 删除文件名末尾的"_original"后缀（如果存在）
      if (fileName.endsWith('_original')) {
        fileName = fileName.substring(0, fileName.length - 9); // "_original" 长度为9
      }
      
      try {
        if (kDebugMode) {
          print('KDEBUG: 正在保存文件 $i: $filePath');
          print('KDEBUG: 处理后的文件名: $fileName$fileExtension');
        }
        
        // 更新进度显示
        if (mounted) {
          Navigator.of(context).pop(); // 关闭之前的对话框
          _showGlassDialog(
            title: const Text('批量保存'),
            content: Text('正在保存文件...\n已完成: $savedCount/${allFiles.length}\n当前: $fileName$fileExtension'),
          );
        }
        
        // 构建不带时间戳和_modified后缀的文件名
        String cleanFileName = fileName;
        if (cleanFileName.endsWith('_modified')) {
          cleanFileName = cleanFileName.substring(0, cleanFileName.length - 9); // "_modified" 长度为9
        }
        
        String suggestedFileName = '$cleanFileName$fileExtension';
        
        if (kDebugMode) {
          print('KDEBUG: 保存文件建议名: $suggestedFileName');
        }
        
        // 根据不同平台使用不同的保存方法
        if (Platform.isAndroid) {
          // 在Android上使用替代方法保存文件
          await _saveFileForAndroidSingle(filePath, fileName, fileExtension, "");
        } else {
          // 使用文件选择器让用户选择保存位置
          final String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: '请选择保存位置:',
            fileName: suggestedFileName,
          );
          
          if (outputFile != null) {
            if (kDebugMode) {
              print('KDEBUG: 用户选择的输出文件路径: $outputFile');
              print('KDEBUG: 从缓存文件复制: $filePath');
            }
            
            // 将文件复制到用户选择的位置
            final saveFile = File(filePath);
            await saveFile.copy(outputFile);
            
            if (kDebugMode) {
              print('KDEBUG: 文件已成功复制到: $outputFile');
            }
          } else {
            // 用户取消了保存操作
            saveFailedFiles.add(filePath);
            if (kDebugMode) {
              print('KDEBUG: 用户取消了保存操作: $filePath');
            }
          }
        }
        
        savedCount++;
      } catch (e) {
        saveFailedFiles.add(filePath);
        if (kDebugMode) {
          print('KDEBUG: 保存文件时出错 $filePath: $e');
        }
      }
    }
    
    // 显示最终结果
    if (mounted) {
      Navigator.of(context).pop(); // 关闭进度对话框
      
      String resultMessage = '标签保存完成:\n'
          '成功保存标签: $successCount/${allFiles.length}\n'
          '成功保存文件: $savedCount/${allFiles.length}';
      
      if (failedFiles.isNotEmpty) {
        resultMessage += '\n标签保存失败: ${failedFiles.length} 个文件';
      }
      
      if (saveFailedFiles.isNotEmpty) {
        resultMessage += '\n文件保存失败: ${saveFailedFiles.length} 个文件';
      }
      
      _showGlassDialog(
        title: const Text('批量操作完成'),
        content: Text(resultMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      );
    }
  }
  
  /// Android平台的单文件保存方法
  Future<void> _saveFileForAndroidSingle(String sourceFilePath, String baseFileName, String fileExtension, String timestamp) async {
    try {
      if (kDebugMode) {
        print('KDEBUG: 使用Android平台单文件保存方法');
        print('KDEBUG: 源文件路径: $sourceFilePath');
        print('KDEBUG: 基础文件名: $baseFileName');
        print('KDEBUG: 文件扩展名: $fileExtension');
      }
      
      // 检查并请求存储权限
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('KDEBUG: 存储权限被拒绝');
        }
        return;
      }
      
      // 构建不带_modified后缀的文件名
      String cleanFileName = baseFileName;
      if (cleanFileName.endsWith('_modified')) {
        cleanFileName = cleanFileName.substring(0, cleanFileName.length - 9); // "_modified" 长度为9
      }
      
      String targetFileName = '$cleanFileName$fileExtension';
      
      // 使用Android默认的下载目录
      String downloadPath = '/sdcard/Download/$targetFileName';
      File targetFile = File(downloadPath);
      
      // 确保目录存在
      await targetFile.create(recursive: true);
      
      if (kDebugMode) {
        print('KDEBUG: 尝试将文件保存到: $downloadPath');
      }
      
      // 将缓存文件复制到下载目录
      File sourceFile = File(sourceFilePath);
      await sourceFile.copy(downloadPath);
      
      if (kDebugMode) {
        print('KDEBUG: 文件已成功保存到: $downloadPath');
      }
      
      Fluttertoast.showToast(
        msg: '文件已保存到: $downloadPath',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: Android平台单文件保存失败: $e');
      }
      rethrow;
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
        _showGlassDialog(
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
      
      // 检查是否为批量编辑模式
      final bool isBatchMode = widget.additionalFiles != null && widget.additionalFiles!.isNotEmpty;
      
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
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '请选择保存位置:',
        fileName: timestampedFileName,
      );

      if (outputFile != null) {
        if (kDebugMode) {
          print('KDEBUG: 用户选择的输出文件路径: $outputFile');
          print('KDEBUG: 从缓存文件复制: ${widget.filePath}');
        }
        
        // 将文件复制到用户选择的位置
        final saveFile = File(widget.filePath);
        await saveFile.copy(outputFile);
        
        // 如果是批量编辑模式，提示用户其他文件也需要单独保存
        if (isBatchMode) {
          final List<String> allFiles = [
            widget.filePath,
            if (widget.additionalFiles != null) ...widget.additionalFiles!
          ];
          
          if (kDebugMode) {
            print('KDEBUG: 批量编辑模式，总共 ${allFiles.length} 个文件已保存标签');
            print('KDEBUG: 其中第一个文件已导出到: $outputFile');
          }
          
          if (mounted) {
            Navigator.of(context).pop(); // 关闭进度对话框
            
            // 显示成功消息
            _showGlassDialog(
              title: const Text('保存成功'),
              content: Text(
                  '已保存 ${allFiles.length} 个文件的标签。\n'
                  '第一个文件已导出到: $outputFile\n'
                  '其他文件保存在缓存中，请手动导出。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          }
        } else {
          // 单文件模式
          if (kDebugMode) {
            print('KDEBUG: 文件已成功复制到: $outputFile');
          }
          
          if (mounted) {
            Navigator.of(context).pop(); // 关闭进度对话框
            
            // 显示成功消息
            _showGlassDialog(
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
          }
        }
      } else {
        // 用户取消了保存操作
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          
          _showGlassDialog(
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
        }
        
        if (kDebugMode) {
          print('KDEBUG: 用户取消了保存操作');
        }
      }
    } on UnimplementedError catch (e) {
      // 处理文件保存器未实现的情况
      if (kDebugMode) {
        print('KDEBUG: 文件保存器未实现: $e');
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
        _showGlassDialog(
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
      }
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 使用文件保存器保存失败: $e');
      }
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        _showGlassDialog(
          title: const Text(
            '保存失败',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          
          _showGlassDialog(
            title: const Text(
              '权限不足',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        
        _showGlassDialog(
          title: const Text(
            '保存失败',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    // 使用file_picker选择图片文件
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'gif'],
    );
    
    // 检查用户是否选择了文件
    if (result == null || result.files.isEmpty) {
      // 用户取消了选择
      return;
    }
    
    final selectedFile = result.files.first;
    
    try {
      // 直接读取文件内容为字节
      final Uint8List imageData = selectedFile.bytes ?? Uint8List(0);
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
          _showGlassDialog(
            title: const Text(
              '文件过大警告',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        _showGlassDialog(
          title: const Text(
            '选择图片出错',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      }
    }
  }

  /// 构建封面部分
  Widget _buildCoverSection() {
    if (_currentCoverImage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _selectNewCoverImage,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                constraints: const BoxConstraints(maxWidth: 400),
                child: Stack(
                  children: [
                    // 液态玻璃背景效果
                    Positioned.fill(
                      child: LiquidGlassLayer(
                        settings: LiquidGlassSettings(
                          thickness: 6,
                          blur: 0.5,
                          lightAngle: 0.3 * pi,
                          lightIntensity: 0.7,
                          ambientStrength: 0.2,
                          blend: 0.5,
                          refractiveIndex: 1.2,
                          chromaticAberration: 0.2,
                          saturation: 1.05,
                        ),
                        child: LiquidGlass.inLayer(
                          shape: LiquidRoundedRectangle(
                            borderRadius: const Radius.circular(12.0),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.memory(
                          _currentCoverImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    } else {
      return Center(
        child: GestureDetector(
          onTap: _selectNewCoverImage,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Stack(
              children: [
                // 液态玻璃背景效果
                Positioned.fill(
                  child: LiquidGlassLayer(
                    settings: GlassEffectConfig.baseSettings(level: effectLevel),
                    child: LiquidGlass.inLayer(
                      shape: LiquidRoundedRectangle(
                        borderRadius: const Radius.circular(12.0),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                        Text('点击添加封面图片', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// 构建表单字段列表
  List<Widget> _buildFormFields() {
    final bool isBatchMode = widget.additionalFiles != null && widget.additionalFiles!.isNotEmpty;
    
    List<Widget> fields = [];
    
    // 只有在非批量模式下才显示文件名和扩展名编辑框
    if (!isBatchMode) {
      fields.add(
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildGlassTextFormField(
                controller: _filenameController,
                labelText: '文件名',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildGlassTextFormField(
                controller: _extensionController,
                labelText: '后缀',
              ),
            ),
          ],
        ),
      );
      fields.add(const SizedBox(height: 16));
    } else {
      // 在批量模式下显示文件列表
      fields.add(_buildFileList());
      fields.add(const SizedBox(height: 16));
    }
    
    // 标题单独一行（通常较长）
    fields.add(_buildGlassTextFormField(
      controller: _titleController,
      labelText: '标题',
    ));
    fields.add(const SizedBox(height: 16));
    
    // 艺术家和专辑放在同一行
    fields.add(_buildGlassTextFormField(
      controller: _artistController,
      labelText: '艺术家',
    ));
    fields.add(const SizedBox(height: 16));
    
    fields.add(_buildGlassTextFormField(
      controller: _albumController,
      labelText: '专辑',
    ));
    fields.add(const SizedBox(height: 16));
    
    // 专辑艺术家单独一行
    fields.add(_buildGlassTextFormField(
      controller: _albumArtistController,
      labelText: '专辑艺术家',
    ));
    fields.add(const SizedBox(height: 16));
    
    // 流派、BPM、年份放在同一行
    fields.add(
      Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildGlassTextFormField(
              controller: _genreController,
              labelText: '流派',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildGlassTextFormField(
              controller: _bpmController,
              labelText: 'BPM',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildGlassTextFormField(
              controller: _yearController,
              labelText: '年份',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
    fields.add(const SizedBox(height: 16));
    
    // 曲目号、曲目总数、光盘号放在同一行
    fields.add(
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildGlassTextFormField(
              controller: _trackNumberController,
              labelText: '曲目号',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildGlassTextFormField(
              controller: _trackTotalController,
              labelText: '曲目数',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildGlassTextFormField(
              controller: _discNumberController,
              labelText: '光盘号',
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
    fields.add(const SizedBox(height: 16));
    
    // 光盘总数和时长放在同一行
    fields.add(
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildGlassTextFormField(
              controller: _discTotalController,
              labelText: '光盘数',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _buildGlassTextFormField(
              controller: _durationController,
              labelText: '时长(秒)',
              keyboardType: TextInputType.number,
              enabled: false, // 持续时间不能编辑
            ),
          ),
        ],
      ),
    );
    fields.add(const SizedBox(height: 16));
    
    fields.add(
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: _buildGlassLyricsFormField(),
      ),
    );
    fields.add(const SizedBox(height: 24));
    
    return fields;
  }

  /// 构建文件列表组件（使用文本输入框实现）
  Widget _buildFileList() {
    final List<String> allFiles = [
      widget.filePath,
      if (widget.additionalFiles != null) ...widget.additionalFiles!
    ];
    
    // 构建文件列表文本，每个文件名占一行
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < allFiles.length; i++) {
      String fileName = path.basenameWithoutExtension(allFiles[i]);
      String fileExtension = path.extension(allFiles[i]);
      
      // 删除文件名末尾的"_original"后缀（如果存在）
      if (fileName.endsWith('_original')) {
        fileName = fileName.substring(0, fileName.length - 9); // "_original" 长度为9
      }
      
      buffer.write('$fileName$fileExtension');
      if (i < allFiles.length - 1) {
        buffer.write('\n'); // 每个文件名后添加换行符，除了最后一个
      }
    }
    
    // 创建一个文本控制器并设置文件列表文本
    final TextEditingController fileListController = TextEditingController(text: buffer.toString());
    
    // 计算最大高度为屏幕高度的25%（比原来增加了10个百分点）
    final double maxHeight = MediaQuery.of(context).size.height * 0.25;
    
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: const EdgeInsets.all(4.0), // 与其他文本框统一外边距
      child: Stack(
        children: [
          // // 液态玻璃背景效果
          // Positioned.fill(
          //   child: LiquidGlassLayer(
          //     settings: LiquidGlassSettings(
          //       thickness: 6,
          //       blur: 0.5,
          //       lightAngle: 0.3 * pi,
          //       lightIntensity: 0.7,
          //       ambientStrength: 0.2,
          //       blend: 0.5,
          //       refractiveIndex: 1.2,
          //       chromaticAberration: 0.2,
          //       saturation: 1.05,
          //     ),
          //     child: LiquidGlass.inLayer(
          //       shape: LiquidRoundedRectangle(
          //         borderRadius: const Radius.circular(12.0),
          //       ),
          //       child: Container(
          //         decoration: BoxDecoration(
          //           borderRadius: BorderRadius.circular(12.0),
          //           color: Theme.of(context).brightness == Brightness.dark
          //               ? Colors.black.withOpacity(0.2)
          //               : Colors.white.withOpacity(0.2),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          // 可滚动的文本区域（禁用编辑）
          Scrollbar(
            controller: _fileListScrollController,
            child: SingleChildScrollView(
              controller: _fileListScrollController,
              scrollDirection: Axis.vertical,
              child: TextFormField(
                controller: fileListController,
                decoration: InputDecoration(
                  labelText: '\n文件列表',
                  // 设置输入框的各种边框样式
                  // 默认边框：圆角12，无边框线
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  // 启用状态下的边框：圆角12，无边框线
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  // 获得焦点时的边框：圆角12，无边框线
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                maxLines: null, // 允许多行
                enabled: false, // 禁用编辑
                textAlign: TextAlign.start, // 文本左对齐
                style: const TextStyle(
                  fontFamily: 'SourceHanSans',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;
    
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
  LayoutBuilder(
    builder: (context, constraints) {
      if (isLandscape) {
        // 横屏模式：左侧封面，右侧表单
        return Row(
        
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 64),
            // 固定封面部分（不滚动）
            SizedBox(
              width: constraints.maxWidth * 0.35,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    const SizedBox(height: 64),
                    _buildCoverSection(), // 封面部分独立出来
                  ],
                ),
              ),
            ),
            // 可滚动的表单部分
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(64.0),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFormFields(), // 表单字段独立出来
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        // 竖屏模式：保持原有布局
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    const SizedBox(height: 30),
                    _buildCoverSection(), // 封面部分
                    ..._buildFormFields(), // 表单字段
                  ],
                ),
              ),
            ),
          ),
        );
      }
    },
  ),
  // const SizedBox(height: 16),
          // 左上角返回按钮 (移到最后确保在最顶层)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16, // 更靠近顶部
            left: 12.0,
            child: LiquidGlassLayer(
              settings: GlassEffectConfig.smallButtonSettings(level: effectLevel),
              child: LiquidGlass.inLayer(
                shape: LiquidRoundedRectangle(
                  borderRadius: const Radius.circular(20.0),
                ),
                child: SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    mini: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),
          ),
          // 右上角操作按钮组
          Positioned(
            top: MediaQuery.of(context).padding.top + 16, // 更靠近顶部
            right: 12.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 还原更改按钮
                LiquidGlassLayer(
                  settings: GlassEffectConfig.largeButtonSettings(level: effectLevel),
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
                          onTap: _resetChanges,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '还原更改',
                                style: TextStyle(
                                  fontFamily: 'MapleMono',
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.refresh, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 保存按钮
                LiquidGlassLayer(
                  settings: GlassEffectConfig.largeButtonSettings(level: effectLevel),
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
                          onTap: _saveTags,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '保存',
                                style: TextStyle(
                                  fontFamily: 'MapleMono',
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.save, size: 20),
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