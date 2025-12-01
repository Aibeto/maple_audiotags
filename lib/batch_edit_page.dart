// 批量编辑页面
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path/path.dart' as path;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// 批量编辑条目类，用于存储每个文件的信息
class BatchEditEntry {
  final String filePath;
  final String fileName;
  Tag? tag;
  bool isSelected;

  BatchEditEntry({
    required this.filePath,
    required this.fileName,
    this.tag,
    this.isSelected = true,
  });
}

// 批量编辑页面组件，继承自StatefulWidget，表示这是一个有状态组件
class BatchEditPage extends StatefulWidget {
  final List<XFile>? initialFiles;

  const BatchEditPage({super.key, this.initialFiles});

  @override
  State<BatchEditPage> createState() => _BatchEditPageState();
}

class _BatchEditPageState extends State<BatchEditPage> {
  // 存储选择的文件列表
  List<BatchEditEntry> _files = [];
  
  // 控制器用于批量编辑字段
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;
  late TextEditingController _yearController;
  
  // 控制器用于额外的批量编辑字段
  late TextEditingController _trackNumberController;
  late TextEditingController _trackTotalController;
  late TextEditingController _discNumberController;
  late TextEditingController _discTotalController;
  late TextEditingController _albumArtistController;
  late TextEditingController _bpmController;
  late TextEditingController _lyricsController;
  
  // 是否正在加载文件标签
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (kDebugMode) {
      print('KDEBUG: BatchEditPage initState 调用');
      print('KDEBUG: 初始文件数量: ${widget.initialFiles?.length ?? 0}');
    }
    
    // 初始化控制器
    _titleController = TextEditingController();
    _artistController = TextEditingController();
    _albumController = TextEditingController();
    _genreController = TextEditingController();
    _yearController = TextEditingController();
    _trackNumberController = TextEditingController();
    _trackTotalController = TextEditingController();
    _discNumberController = TextEditingController();
    _discTotalController = TextEditingController();
    _albumArtistController = TextEditingController();
    _bpmController = TextEditingController();
    _lyricsController = TextEditingController();
    
    if (kDebugMode) {
      print('KDEBUG: 文本控制器初始化完成');
    }
    
    // 如果提供了初始文件，则处理这些文件
    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      if (kDebugMode) {
        print('KDEBUG: 发现初始文件，开始处理');
      }
      _processInitialFiles();
    } else {
      if (kDebugMode) {
        print('KDEBUG: 没有提供初始文件');
      }
    }
  }

  // 处理初始文件
  Future<void> _processInitialFiles() async {
    try {
      if (kDebugMode) {
        print('KDEBUG: 开始处理 ${widget.initialFiles!.length} 个初始文件');
      }
      
      // 更新状态，设置为正在加载
      setState(() {
        _isLoading = true;
      });
      
      // 创建新的文件列表
      List<BatchEditEntry> newFiles = [];
      
      // 处理每个选中的文件
      for (int i = 0; i < widget.initialFiles!.length; i++) {
        final file = widget.initialFiles![i];
        final String fileName = path.basename(file.path);
        final String originalFilePath = file.path;
        
        if (kDebugMode) {
          print('KDEBUG: 处理第 ${i + 1}/${widget.initialFiles!.length} 个初始文件');
          print('KDEBUG: 处理初始文件路径: $originalFilePath');
          print('KDEBUG: 处理初始文件名: $fileName');
        }
        
        // 将文件复制到缓存目录
        final String cachedFilePath = await _copyFileToCache(file);
        
        // 将选中的文件添加到列表
        newFiles.add(BatchEditEntry(
          filePath: cachedFilePath,
          fileName: fileName,
        ));
        
        if (kDebugMode) {
          print('KDEBUG: 第 ${i + 1} 个文件处理完成，缓存路径: $cachedFilePath');
          print('KDEBUG: 原始文件路径: $originalFilePath');
        }
      }
      
      // 更新文件列表
      setState(() {
        _files = newFiles;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('KDEBUG: 所有初始文件处理完成，开始读取标签');
        print('KDEBUG: 文件总数: ${_files.length}');
      }
      
      // 读取所有文件的标签
      await _readAllTags();
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 处理初始文件时出错: $e');
      }
      
      // 显示错误消息给用户
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理文件时出错: $e')),
        );
      }
      
      // 更新状态
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 将文件复制到缓存目录
  Future<String> _copyFileToCache(XFile file) async {
    if (kDebugMode) {
      print('KDEBUG: 开始将文件复制到缓存目录');
      print('KDEBUG: 原始文件路径: ${file.path}');
      print('KDEBUG: 原始文件名: ${file.name}');
    }
    
    // 获取应用缓存目录
    Directory cacheDir = await getTemporaryDirectory();
    // 获取当前日期作为文件夹名称
    String dateFolder = DateFormat('yyyyMMdd').format(DateTime.now());
    // 构建带日期的缓存目录路径
    String datedCacheDirPath = path.join(cacheDir.path, 'audio_cache', dateFolder);
    
    if (kDebugMode) {
      print('KDEBUG: 缓存根目录: ${cacheDir.path}');
      print('KDEBUG: 日期文件夹名: $dateFolder');
      print('KDEBUG: 带日期的缓存目录路径: $datedCacheDirPath');
    }
    
    // 创建带日期的缓存目录
    Directory datedCacheDir = Directory(datedCacheDirPath);
    if (!await datedCacheDir.exists()) {
      if (kDebugMode) {
        print('KDEBUG: 缓存目录不存在，正在创建目录');
      }
      await datedCacheDir.create(recursive: true);
      if (kDebugMode) {
        print('KDEBUG: 缓存目录创建成功');
      }
    } else {
      if (kDebugMode) {
        print('KDEBUG: 缓存目录已存在');
      }
    }
    
    // 构建原始文件的目标路径（加上"_original"后缀）
    String originalFileName = '${path.basenameWithoutExtension(file.name)}_original${path.extension(file.name)}';
    String targetPath = path.join(datedCacheDirPath, originalFileName);
    
    if (kDebugMode) {
      print('KDEBUG: 原始文件名(无扩展名): ${path.basenameWithoutExtension(file.name)}');
      print('KDEBUG: 文件扩展名: ${path.extension(file.name)}');
      print('KDEBUG: 带_original后缀的文件名: $originalFileName');
      print('KDEBUG: 最终目标路径: $targetPath');
    }
    
    // 将选中的文件复制到缓存目录，覆盖已存在的同名文件
    if (kDebugMode) {
      print('KDEBUG: 开始复制文件到缓存目录');
      print('KDEBUG: 源文件路径: ${file.path}');
      print('KDEBUG: 目标文件路径: $targetPath');
    }
    
    await file.saveTo(targetPath);
    
    if (kDebugMode) {
      print('KDEBUG: 文件复制完成');
      print('KDEBUG: 缓存中的原始文件是否存在: ${await File(targetPath).exists()}');
      print('KDEBUG: 缓存中的原始文件大小: ${await File(targetPath).length()} 字节');
      print('KDEBUG: 文件已保存到缓存路径: $targetPath');
    }
    
    return targetPath;
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('KDEBUG: BatchEditPage dispose 调用');
      print('KDEBUG: 释放文本控制器资源');
    }
    
    // 释放控制器资源
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _trackNumberController.dispose();
    _trackTotalController.dispose();
    _discNumberController.dispose();
    _discTotalController.dispose();
    _albumArtistController.dispose();
    _bpmController.dispose();
    _lyricsController.dispose();
    super.dispose();
    
    if (kDebugMode) {
      print('KDEBUG: 文本控制器资源释放完成');
    }
  }

  // 选择多个音乐文件的方法
  void _selectMusicFiles() async {
    try {
      if (kDebugMode) {
        print('KDEBUG: 用户开始选择音乐文件');
      }
      
      // 使用file_selector选择多个音频文件
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'audio',
        extensions: ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'],
      );
      
      final List<XFile> selectedFiles = await openFiles(
        acceptedTypeGroups: [typeGroup],
        confirmButtonText: '选择音频文件',
      );
      
      // 检查用户是否选择了文件
      if (selectedFiles.isEmpty) {
        if (kDebugMode) {
          print('KDEBUG: 用户取消了文件选择');
        }
        // 用户取消了选择
        return;
      }
      
      if (kDebugMode) {
        print('KDEBUG: 用户选择了 ${selectedFiles.length} 个文件');
      }
      
      // 更新状态，设置为正在加载
      setState(() {
        _isLoading = true;
      });
      
      // 创建新的文件列表
      List<BatchEditEntry> newFiles = [];
      
      // 处理每个选中的文件
      for (int i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        final String fileName = path.basename(file.path);
        
        if (kDebugMode) {
          print('KDEBUG: 处理第 ${i + 1}/${selectedFiles.length} 个用户选择的文件');
          print('KDEBUG: 用户选择的文件路径: ${file.path}');
          print('KDEBUG: 用户选择的文件名: $fileName');
        }
        
        // 将文件复制到缓存目录
        final String cachedFilePath = await _copyFileToCache(file);
        
        if (kDebugMode) {
          print('KDEBUG: 第 ${i + 1} 个文件已复制到缓存，路径: $cachedFilePath');
          print('KDEBUG: 原始文件路径: ${file.path}');
        }
        
        // 将选中的文件添加到列表
        newFiles.add(BatchEditEntry(
          filePath: cachedFilePath,
          fileName: fileName,
        ));
      }
      
      // 更新文件列表
      setState(() {
        _files = newFiles;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('KDEBUG: 所有用户选择的文件处理完成，开始读取标签');
        print('KDEBUG: 文件总数: ${_files.length}');
      }
      
      // 读取所有文件的标签
      await _readAllTags();
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 选择或处理文件时出错: $e');
      }
      
      // 显示错误消息给用户
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理文件时出错: $e')),
        );
      }
      
      // 更新状态
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 读取所有文件的标签
  Future<void> _readAllTags() async {
    if (kDebugMode) {
      print('KDEBUG: 开始读取所有文件的标签，共 ${_files.length} 个文件');
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      int successCount = 0;
      for (int i = 0; i < _files.length; i++) {
        try {
          if (kDebugMode) {
            print('KDEBUG: 正在读取第 ${i + 1}/${_files.length} 个文件标签: ${_files[i].fileName}');
            print('KDEBUG: 文件路径: ${_files[i].filePath}');
          }
          
          final tag = await AudioTags.read(_files[i].filePath);
          setState(() {
            _files[i].tag = tag;
          });
          
          successCount++;
          if (kDebugMode) {
            if (tag != null) {
              print('KDEBUG: 成功读取标签: ${_files[i].fileName}, 标题: ${tag.title}, 艺术家: ${tag.trackArtist}');
              print('KDEBUG: 标签详情 - 专辑: ${tag.album}, 流派: ${tag.genre}, 年份: ${tag.year}');
            } else {
              print('KDEBUG: 标签读取结果为空: ${_files[i].fileName}');
            }
            print('KDEBUG: 文件标签读取完成: ${_files[i].filePath}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('KDEBUG: 读取文件标签时出错 ${_files[i].fileName}: $e');
            print('KDEBUG: 出错文件路径: ${_files[i].filePath}');
          }
        }
      }
      
      if (kDebugMode) {
        print('KDEBUG: 标签读取完成，成功: $successCount/${_files.length}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 切换文件选择状态
  void _toggleFileSelection(int index) {
    if (kDebugMode) {
      print('KDEBUG: 切换文件选择状态，索引: $index, 当前状态: ${_files[index].isSelected}');
    }
    
    setState(() {
      _files[index].isSelected = !_files[index].isSelected;
    });
    
    if (kDebugMode) {
      print('KDEBUG: 文件选择状态已更新，索引: $index, 新状态: ${_files[index].isSelected}');
    }
  }

  // 切换所有文件选择状态
  void _toggleAllSelection(bool selectAll) {
    if (kDebugMode) {
      print('KDEBUG: 切换所有文件选择状态，selectAll: $selectAll');
    }
    
    setState(() {
      for (final file in _files) {
        file.isSelected = selectAll;
      }
    });
    
    if (kDebugMode) {
      final selectedCount = _files.where((f) => f.isSelected).length;
      print('KDEBUG: 所有文件选择状态已更新，已选择: $selectedCount/${_files.length}');
    }
  }

  // 应用批量编辑
  void _applyBatchEdit() {
    if (kDebugMode) {
      print('KDEBUG: 开始应用批量编辑');
    }
    
    final selectedFiles = _files.where((file) => file.isSelected).toList();
    
    if (kDebugMode) {
      print('KDEBUG: 选中的文件数量: ${selectedFiles.length}');
    }
    
    if (selectedFiles.isEmpty) {
      if (kDebugMode) {
        print('KDEBUG: 没有选中的文件，显示提示信息');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个文件')),
      );
      return;
    }
    
    if (kDebugMode) {
      print('KDEBUG: 应用批量编辑到 ${selectedFiles.length} 个文件');
      print('KDEBUG: 标题字段内容长度: ${_titleController.text.length}');
      print('KDEBUG: 艺术家字段内容长度: ${_artistController.text.length}');
      print('KDEBUG: 专辑字段内容长度: ${_albumController.text.length}');
      print('KDEBUG: 流派字段内容长度: ${_genreController.text.length}');
      print('KDEBUG: 年份字段内容: ${_yearController.text}');
      print('KDEBUG: 专辑艺术家字段内容长度: ${_albumArtistController.text.length}');
      print('KDEBUG: 曲目号字段内容: ${_trackNumberController.text}');
      print('KDEBUG: 曲目总数字段内容: ${_trackTotalController.text}');
      print('KDEBUG: 光盘号字段内容: ${_discNumberController.text}');
      print('KDEBUG: 光盘总数字段内容: ${_discTotalController.text}');
      print('KDEBUG: BPM字段内容: ${_bpmController.text}');
      print('KDEBUG: 歌词字段内容长度: ${_lyricsController.text.length}');
    }
    
    try {
      // 对每个选中的文件应用编辑
      int updatedCount = 0;
      for (int i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        
        if (kDebugMode) {
          print('KDEBUG: 处理第 ${i + 1}/${selectedFiles.length} 个文件: ${file.fileName}');
          print('KDEBUG: 文件路径: ${file.filePath}');
        }
        
        if (file.tag != null) {
          // 更新标签对象
          file.tag = Tag(
            title: _titleController.text.isNotEmpty ? _titleController.text : file.tag!.title,
            trackArtist: _artistController.text.isNotEmpty ? _artistController.text : file.tag!.trackArtist,
            album: _albumController.text.isNotEmpty ? _albumController.text : file.tag!.album,
            albumArtist: _albumArtistController.text.isNotEmpty ? _albumArtistController.text : file.tag!.albumArtist,
            genre: _genreController.text.isNotEmpty ? _genreController.text : file.tag!.genre,
            year: _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : file.tag!.year,
            trackNumber: _trackNumberController.text.isNotEmpty ? int.tryParse(_trackNumberController.text) : file.tag!.trackNumber,
            trackTotal: _trackTotalController.text.isNotEmpty ? int.tryParse(_trackTotalController.text) : file.tag!.trackTotal,
            discNumber: _discNumberController.text.isNotEmpty ? int.tryParse(_discNumberController.text) : file.tag!.discNumber,
            discTotal: _discTotalController.text.isNotEmpty ? int.tryParse(_discTotalController.text) : file.tag!.discTotal,
            lyrics: _lyricsController.text.isNotEmpty ? _lyricsController.text : file.tag!.lyrics,
            duration: file.tag!.duration, // 保持原有时长
            bpm: _bpmController.text.isNotEmpty ? double.tryParse(_bpmController.text) : file.tag!.bpm,
            pictures: file.tag!.pictures, // 保持原有图片
          );
          
          updatedCount++;
          
          if (kDebugMode) {
            print('KDEBUG: 文件标签更新成功: ${file.fileName}');
            print('KDEBUG: 新标题: ${file.tag!.title}');
            print('KDEBUG: 新艺术家: ${file.tag!.trackArtist}');
            print('KDEBUG: 新专辑: ${file.tag!.album}');
            print('KDEBUG: 文件路径: ${file.filePath}');
          }
        } else {
          if (kDebugMode) {
            print('KDEBUG: 文件标签为空，跳过更新: ${file.fileName}');
            print('KDEBUG: 文件路径: ${file.filePath}');
          }
        }
      }
      
      if (kDebugMode) {
        print('KDEBUG: 批量编辑应用完成，共更新 $updatedCount 个文件');
      }
      
      // 显示成功消息
      Fluttertoast.showToast(
        msg: '已应用批量编辑到 ${selectedFiles.length} 个文件',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      
      if (kDebugMode) {
        print('KDEBUG: 批量编辑已应用，已显示提示消息');
      }
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 应用批量编辑时出错: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('应用批量编辑时出错: $e')),
      );
    }
  }

  // 保存所有更改
  void _saveAllChanges() async {
    if (kDebugMode) {
      print('KDEBUG: 开始保存所有更改');
    }
    
    final selectedFiles = _files.where((file) => file.isSelected).toList();
    
    if (kDebugMode) {
      print('KDEBUG: 选中的文件数量: ${selectedFiles.length}');
    }
    
    if (selectedFiles.isEmpty) {
      if (kDebugMode) {
        print('KDEBUG: 没有选中的文件，显示提示信息');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个文件')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    if (kDebugMode) {
      print('KDEBUG: 开始保存 ${selectedFiles.length} 个文件');
    }
    
    try {
      // 保存每个文件的更改
      int successCount = 0;
      for (int i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        
        if (kDebugMode) {
          print('KDEBUG: 处理第 ${i + 1}/${selectedFiles.length} 个文件: ${file.fileName}');
          print('KDEBUG: 文件路径: ${file.filePath}');
        }
        
        if (file.tag != null) {
          try {
            if (kDebugMode) {
              print('KDEBUG: 开始写入标签到文件: ${file.fileName}');
              print('KDEBUG: 文件路径: ${file.filePath}');
            }
            
            await AudioTags.write(file.filePath, file.tag!);
            successCount++;
            
            if (kDebugMode) {
              print('KDEBUG: 成功保存文件: ${file.fileName}');
              print('KDEBUG: 保存路径: ${file.filePath}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('KDEBUG: 保存文件时出错 ${file.fileName}: $e');
              print('KDEBUG: 出错文件路径: ${file.filePath}');
            }
          }
        } else {
          if (kDebugMode) {
            print('KDEBUG: 文件标签为空，跳过保存: ${file.fileName}');
            print('KDEBUG: 文件路径: ${file.filePath}');
          }
        }
      }
      
      if (kDebugMode) {
        print('KDEBUG: 保存操作完成，成功: $successCount/${selectedFiles.length}');
      }
      
      // 显示结果
      Fluttertoast.showToast(
        msg: '成功保存 $successCount/${selectedFiles.length} 个文件',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      
      if (kDebugMode) {
        print('KDEBUG: 保存完成，成功: $successCount/${selectedFiles.length}，已显示提示消息');
      }
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 保存文件时出错: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存文件时出错: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 导出选中的文件到用户指定位置
  void _exportSelectedFiles() async {
    if (kDebugMode) {
      print('KDEBUG: 开始导出选中的文件');
    }
    
    final selectedFiles = _files.where((file) => file.isSelected).toList();
    
    if (kDebugMode) {
      print('KDEBUG: 选中的文件数量: ${selectedFiles.length}');
    }
    
    if (selectedFiles.isEmpty) {
      if (kDebugMode) {
        print('KDEBUG: 没有选中的文件，显示提示信息');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个文件')),
      );
      return;
    }
    
    try {
      // 获取当前时间戳用于文件名
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      
      if (kDebugMode) {
        print('KDEBUG: 时间戳: $timestamp');
      }
      
      // 导出每个选中的文件
      int successCount = 0;
      for (int i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        
        if (kDebugMode) {
          print('KDEBUG: 处理第 ${i + 1}/${selectedFiles.length} 个文件: ${file.fileName}');
          print('KDEBUG: 文件路径: ${file.filePath}');
        }
        
        try {
          // 生成建议的文件名
          String suggestedName = '${path.basenameWithoutExtension(file.fileName)}_modified_$timestamp${path.extension(file.fileName)}';
          
          if (kDebugMode) {
            print('KDEBUG: 建议文件名: $suggestedName');
          }
          
          // 使用file_selector让用户选择保存位置
          final FileSaveLocation? outputFile = await getSaveLocation(
            suggestedName: suggestedName,
            acceptedTypeGroups: [XTypeGroup(
              label: 'audio',
              extensions: [path.extension(file.fileName).replaceAll('.', '')],
            )],
          );
          
          if (outputFile != null) {
            if (kDebugMode) {
              print('KDEBUG: 用户选择的输出路径: $outputFile');
            }
            
            // 复制文件到用户选择的位置
            final sourceFile = XFile(file.filePath);
            await sourceFile.saveTo(outputFile as String);
            
            successCount++;
            
            if (kDebugMode) {
              print('KDEBUG: 文件导出成功: $outputFile');
            }
          } else {
            if (kDebugMode) {
              print('KDEBUG: 用户取消了文件导出');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('KDEBUG: 导出文件时出错 ${file.fileName}: $e');
          }
        }
      }
      
      // 显示结果
      Fluttertoast.showToast(
        msg: '成功导出 $successCount/${selectedFiles.length} 个文件',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      
      if (kDebugMode) {
        print('KDEBUG: 文件导出完成，成功: $successCount/${selectedFiles.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('KDEBUG: 导出文件时出错: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出文件时出错: $e')),
      );
    }
  }

  // 构建文件列表项
  Widget _buildFileListItem(int index) {
    final file = _files[index];
    
    if (kDebugMode) {
      print('KDEBUG: 构建文件列表项，索引: $index, 文件名: ${file.fileName}, 是否选中: ${file.isSelected}');
      print('KDEBUG: 文件路径: ${file.filePath}');
      if (file.tag != null) {
        print('KDEBUG: 标签信息 - 标题: ${file.tag!.title}, 艺术家: ${file.tag!.trackArtist}');
      } else {
        print('KDEBUG: 标签信息: 无');
      }
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Checkbox(
          value: file.isSelected,
          onChanged: (_) => _toggleFileSelection(index),
        ),
        title: Text(file.fileName),
        subtitle: file.tag != null
            ? Text('${file.tag!.title} - ${file.tag!.trackArtist}')
            : const Text('无法读取标签'),
        trailing: file.tag != null 
            ? const Icon(Icons.check, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
      ),
    );
  }

  // 构建批量编辑表单
  Widget _buildBatchEditForm() {
    if (kDebugMode) {
      print('KDEBUG: 构建批量编辑表单，当前文件数: ${_files.length}');
    }
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '批量编辑字段',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: '艺术家',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(
                labelText: '专辑',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _albumArtistController,
              decoration: const InputDecoration(
                labelText: '专辑艺术家',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _genreController,
                    decoration: const InputDecoration(
                      labelText: '流派',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: '年份',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _bpmController,
                    decoration: const InputDecoration(
                      labelText: 'BPM',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackNumberController,
                    decoration: const InputDecoration(
                      labelText: '曲目号',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discNumberController,
                    decoration: const InputDecoration(
                      labelText: '光盘号',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _discTotalController,
                    decoration: const InputDecoration(
                      labelText: '光盘总数',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lyricsController,
              decoration: const InputDecoration(
                labelText: '歌词',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _applyBatchEdit,
                  child: const Text('应用编辑'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveAllChanges,
                  child: const Text('保存更改'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _exportSelectedFiles,
                  child: const Text('导出文件'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建UI界面的方法
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 页面顶部的应用栏
      appBar: AppBar(
        // 应用栏标题
        title: const Text('批量编辑'),
        // 左上角的返回按钮
        leading: IconButton(
          // 返回按钮图标
          icon: const Icon(Icons.arrow_back),
          // 点击事件处理函数，用于返回上一页
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // 全选按钮
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () {
              _toggleAllSelection(true);
            },
          ),
          // 取消全选按钮
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: () {
              _toggleAllSelection(false);
            },
          ),
        ],
      ),
      // 页面主体内容区域
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 选择文件按钮
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectMusicFiles,
                        icon: const Icon(Icons.add),
                        label: const Text('添加文件'),
                      ),
                      const SizedBox(width: 12),
                      if (_files.isNotEmpty) ...[
                        Text('${_files.where((f) => f.isSelected).length}/${_files.length} 已选择'),
                        const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
                
                // 批量编辑表单
                if (_files.isNotEmpty) _buildBatchEditForm(),
                
                // 文件列表
                if (_files.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _files.length,
                      itemBuilder: (context, index) => _buildFileListItem(index),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Text(
                        '正在加载文件...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}