// 音频标签编辑UI组件
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_selector/file_selector.dart';

import 'dart:io' show Platform, File, Directory;
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

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

class _TagEditorUIState extends State<TagEditorUI> {
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

  /// 表单键，用于验证和保存表单
  final _formKey = GlobalKey<FormState>();

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
          Fluttertoast.showToast(
            msg: '保存失败: ${e.message}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } catch (e) {
        // 关闭进度对话框
        if (mounted) {
          Navigator.of(context).pop();
          
          // 显示错误消息
          Fluttertoast.showToast(
            msg: '保存失败: $e',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
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
        pictures: widget.tag.pictures, // 保持原始图片
      );

      // 直接将标签写入当前编辑的文件（即widget.filePath）
      await AudioTags.write(widget.filePath, updatedTag);
      
      if (kDebugMode) {
        print('KDEBUG: 标签已直接写入文件: ${widget.filePath}');
      }
      
      // 保存后使用文件保存器将文件复制到用户选择的位置
      await _saveWithFileSaver();
    } catch (e) {
      if (kDebugMode) {
        print('直接保存标签失败: $e');
      }
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        if (kDebugMode) {
          print('KDEBUG: 保存失败: $e');
        }
        Fluttertoast.showToast(
          msg: '保存失败: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  /// 使用系统文件保存器将缓存中的文件复制到用户选择的位置
  Future<void> _saveWithFileSaver() async {
    try {
      // 获取当前时间戳
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      // 获取文件名（不含扩展名）和扩展名
      String fileNameWithoutExtension = path.basenameWithoutExtension(widget.filePath);
      String fileExtension = path.extension(widget.filePath);
      // 构建带时间戳的文件名
      String timestampedFileName = '${fileNameWithoutExtension}_modified_${timestamp}$fileExtension';
      
      if (kDebugMode) {
        print('KDEBUG: 准备使用文件保存器保存文件');
        print('KDEBUG: 建议的文件名: $timestampedFileName');
      }
      
      // 检查是否在Android平台
      if (Platform.isAndroid) {
        // 在Android上使用替代方法保存文件
        await _saveFileForAndroid(timestampedFileName);
        return;
      }
      
      // 使用文件选择器让用户选择保存位置
      final FileSaveLocation? outputFile = await getSaveLocation(
        suggestedName: timestampedFileName,
        acceptedTypeGroups: [const XTypeGroup(label: 'audio', extensions: ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'])],
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
          Fluttertoast.showToast(
            msg: '文件已保存到: $outputFile',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        // 用户取消了保存操作
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          
          Fluttertoast.showToast(
            msg: '保存操作已取消',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
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
      }
      
      // 尝试使用Android的替代方法
      if (Platform.isAndroid) {
        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        String fileNameWithoutExtension = path.basenameWithoutExtension(widget.filePath);
        String fileExtension = path.extension(widget.filePath);
        String timestampedFileName = '${fileNameWithoutExtension}_modified_${timestamp}$fileExtension';
        
        await _saveFileForAndroid(timestampedFileName);
        return;
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        // 显示错误消息
        Fluttertoast.showToast(
          msg: '当前平台不支持文件保存器功能',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('使用文件保存器保存失败: $e');
      }
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        Fluttertoast.showToast(
          msg: '保存失败: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
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
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          
          Fluttertoast.showToast(
            msg: '需要存储权限才能保存文件',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
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
        
        Fluttertoast.showToast(
          msg: 'Android平台保存失败: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
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
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 权限请求失败: $e');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑标签'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTags,
            tooltip: '保存标签',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kDebugMode) 
                Text('当前工作文件路径: ${widget.filePath}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (kDebugMode && widget.realFilePath != null)
                Text('真实文件路径: ${widget.realFilePath}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: '艺术家',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _albumController,
                decoration: const InputDecoration(
                  labelText: '专辑',
                  border: OutlineInputBorder(),
                ),
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
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: '流派',
                  border: OutlineInputBorder(),
                ),
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
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
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
                  const SizedBox(width: 16),
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
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
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
              TextFormField(
                controller: _bpmController,
                decoration: const InputDecoration(
                  labelText: 'BPM(每分钟节拍数)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              // const SizedBox(height: 24),
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
    );
  }
}