// 音频标签编辑UI组件
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform, File;
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

        // 检查并请求权限（仅在需要的平台上）
        if (Platform.isAndroid) {
          // 根据Android版本处理不同的存储权限
          final androidVersion = int.tryParse(Platform.operatingSystemVersion.replaceAll(RegExp(r'[^\d.]'), '').split('.').first) ?? 0;
          
          if (androidVersion >= 10) {
            // Android 10及以上版本
            if (kDebugMode) {
              print('KDEBUG: 检测到 Android 10+ (版本 $androidVersion)，正在检查适当的存储权限');
            }
            
            // 从Android 10开始，外部存储访问发生了重大变化
            if (androidVersion >= 11) {
              // Android 11及以上版本使用MANAGE_EXTERNAL_STORAGE权限
              var manageStorageStatus = await Permission.manageExternalStorage.status;
              if (!manageStorageStatus.isGranted) {
                if (kDebugMode) {
                  print('KDEBUG: 正在请求 MANAGE_EXTERNAL_STORAGE 权限');
                }
                
                // 请求MANAGE_EXTERNAL_STORAGE权限
                manageStorageStatus = await Permission.manageExternalStorage.request();
                if (!manageStorageStatus.isGranted) {
                  // 如果权限申请失败，则引导用户到设置页面
                  if (mounted) {
                    Navigator.of(context).pop(); // 关闭进度对话框
                    Fluttertoast.showToast(
                      msg: '请在设置中授予"所有文件访问"权限',
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                    );
                    if (kDebugMode) {
                      print('请在设置中授予"所有文件访问"权限');
                    }
                    
                    // 引导用户到设置页面
                    await openAppSettings();
                    return;
                  }
                }
              }
            } else {
              // Android 10使用传统的存储权限
              var storageStatus = await Permission.storage.status;
              if (!storageStatus.isGranted) {
                if (kDebugMode) {
                  print('KDEBUG: 正在为 Android 10 请求存储权限');
                }
                
                // 请求存储权限
                storageStatus = await Permission.storage.request();
                if (!storageStatus.isGranted) {
                  // 如果权限申请失败，则使用回退方案
                  if (mounted) {
                    Navigator.of(context).pop(); // 关闭进度对话框
                    Fluttertoast.showToast(
                      msg: '存储权限不足，将使用文件保存器保存',
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                    );
                    if (kDebugMode) {
                      print('存储权限不足，将使用文件保存器保存');
                    }
                    
                    // 使用回退方案保存文件
                    await _saveWithFileSaver();
                    return;
                  }
                }
              }
            }
          } else {
            // Android 9及以下版本
            if (kDebugMode) {
              print('KDEBUG: 检测到 Android 9 或更低版本 (版本 $androidVersion)，正在检查存储权限');
            }
            
            // 检查写入存储权限
            var writeStatus = await Permission.storage.status;
            if (!writeStatus.isGranted) {
              if (kDebugMode) {
                print('KDEBUG: 正在请求 WRITE_EXTERNAL_STORAGE 权限');
              }
              // 如果没有权限，则请求权限
              writeStatus = await Permission.storage.request();
              if (!writeStatus.isGranted) {
                // 如果权限申请失败，则使用回退方案
                if (mounted) {
                  Navigator.of(context).pop(); // 关闭进度对话框
                  Fluttertoast.showToast(
                    msg: '存储权限不足，将使用文件保存器保存',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                  );
                  if (kDebugMode) {
                    print('存储权限不足，将使用文件保存器保存');
                  }
                  
                  // 使用回退方案保存文件
                  await _saveWithFileSaver();
                  return;
                }
              }
            }
          }
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
          pictures: widget.tag.pictures, // 保持原始图片
        );

        // 确定要写入的文件路径
        String targetFilePath = widget.realFilePath ?? widget.filePath;
        
        if (kDebugMode) {
          print('KDEBUG: 尝试将标签保存到文件: $targetFilePath');
          print('KDEBUG: 写入前文件是否存在: ${await File(targetFilePath).exists()}');
        }

        // 直接写入目标文件
        await AudioTags.write(targetFilePath, updatedTag);
        
        if (kDebugMode) {
          print('KDEBUG: 成功将标签写入文件: $targetFilePath');
          print('KDEBUG: 写入后文件是否存在: ${await File(targetFilePath).exists()}');
          print('KDEBUG: 写入后文件大小: ${await File(targetFilePath).length()} 字节');
        }
        
        // 如果使用的是缓存文件，也要更新缓存文件
        if (widget.realFilePath != null) {
          if (kDebugMode) {
            print('KDEBUG: 同时更新缓存文件: ${widget.filePath}');
          }
          
          await AudioTags.write(widget.filePath, updatedTag);
          
          if (kDebugMode) {
            print('KDEBUG: 成功更新缓存文件: ${widget.filePath}');
            print('KDEBUG: 缓存文件是否存在: ${await File(widget.filePath).exists()}');
            print('KDEBUG: 缓存文件大小: ${await File(widget.filePath).length()} 字节');
          }
        }
        
        // 在同一目录下创建一个带时间戳的修改版本文件
        // 获取文件所在的目录
        String fileDirectory = path.dirname(targetFilePath);
        // 获取文件名（不含扩展名）和扩展名
        String fileNameWithoutExtension = path.basenameWithoutExtension(targetFilePath);
        String fileExtension = path.extension(targetFilePath);
        // 获取当前时间戳
        String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        // 构建修改后的文件路径（加上时间戳）
        String modifiedFilePath = path.join(fileDirectory, '${fileNameWithoutExtension}_modified_${timestamp}$fileExtension');
        
        if (kDebugMode) {
          print('KDEBUG: 同时在同一目录下创建修改版本文件: $modifiedFilePath');
        }
        
        // 先复制当前文件
        await File(targetFilePath).copy(modifiedFilePath);
        // 然后写入更新后的标签到修改版本文件
        await AudioTags.write(modifiedFilePath, updatedTag);
        
        if (kDebugMode) {
          print('KDEBUG: 成功创建修改版本文件: $modifiedFilePath');
          print('KDEBUG: 修改版本文件是否存在: ${await File(modifiedFilePath).exists()}');
          print('KDEBUG: 修改版本文件大小: ${await File(modifiedFilePath).length()} 字节');
        }
        
        // 关闭进度对话框
        if (mounted) {
          Navigator.of(context).pop();
          
          // 显示成功消息
          Fluttertoast.showToast(
            msg: '标签保存成功',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
          
          if (kDebugMode) {
            print('KDEBUG: 标签已成功保存到文件: $targetFilePath');
            if (widget.realFilePath != null) {
              print('KDEBUG: 同时更新了缓存文件: ${widget.filePath}');
            }
            print('KDEBUG: 同时创建了修改版本文件: $modifiedFilePath');
          }
        }
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

  /// 使用系统文件保存器的回退保存方法
  Future<void> _saveWithFileSaver() async {
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

      // 确定要写入的文件路径
      String targetFilePath = widget.realFilePath ?? widget.filePath;
      
      if (kDebugMode) {
        print('KDEBUG: 使用备用文件保存方法');
        print('KDEBUG: 正在将标签写入文件: $targetFilePath');
      }

      // 先将标签写入目标文件
      await AudioTags.write(targetFilePath, updatedTag);
      
      if (kDebugMode) {
        print('KDEBUG: 标签已写入文件，现在提示用户选择保存位置');
      }
      
      // 获取当前时间戳
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      // 获取文件名（不含扩展名）和扩展名
      String fileNameWithoutExtension = path.basenameWithoutExtension(targetFilePath);
      String fileExtension = path.extension(targetFilePath);
      // 构建带时间戳的文件名
      String timestampedFileName = '${fileNameWithoutExtension}_modified_${timestamp}$fileExtension';
      
      // 使用文件选择器让用户选择保存位置
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '请选择保存位置:',
        fileName: timestampedFileName,
      );

      if (outputFile != null) {
        if (kDebugMode) {
          print('KDEBUG: 用户选择的输出文件路径: $outputFile');
          print('KDEBUG: 从目标文件复制: $targetFilePath');
        }
        
        // 将文件复制到用户选择的位置
        await File(targetFilePath).copy(outputFile);
        
        if (kDebugMode) {
          print('KDEBUG: 文件已成功复制到: $outputFile');
          print('KDEBUG: 输出文件是否存在: ${await File(outputFile).exists()}');
          print('KDEBUG: 输出文件大小: ${await File(outputFile).length()} 字节');
        }
        
        if (mounted) {
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
    } catch (e) {
      if (kDebugMode) {
        print('使用文件保存器保存失败: $e');
      }
      if (mounted) {
        Fluttertoast.showToast(
          msg: '保存失败: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: '艺术家',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入艺术家';
                  }
                  return null;
                },
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
              TextFormField(
                controller: _lyricsController,
                decoration: const InputDecoration(
                  labelText: '歌词',
                  border: OutlineInputBorder(),
                ),
                maxLines: 28,
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