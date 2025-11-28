// 音频标签编辑UI组件
import 'package:audiotags/audiotags.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  });

  /// 音频文件的标签信息
  final Tag tag;

  /// 音频文件路径
  final String filePath;

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

        // TODO: 实现实际的标签保存逻辑
        // 这里需要根据 audiotags 插件的文档来实现标签写入功能
        
        // 模拟保存过程
        await Future.delayed(const Duration(seconds: 1));
        
        // 关闭进度对话框
        if (mounted) {
          Navigator.of(context).pop();
          
          // 显示成功消息
          Fluttertoast.showToast(
            msg: '标签保存成功',
            toastLength: Toast.LENGTH_SHORT,
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
        }
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
                maxLines: 50,
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