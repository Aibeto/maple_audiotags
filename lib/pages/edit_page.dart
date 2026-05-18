import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../config/ui_config.dart';
import '../isolate_utils.dart';
import '../tag_editor_ui.dart';

/// 音频标签编辑页面
/// 负责加载和显示 TagEditorUI 来编辑音频文件的标签
class EditPage extends StatefulWidget {
  /// 要编辑的文件路径列表
  final List<String> filePaths;

  /// 构造函数
  const EditPage({super.key, required this.filePaths});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  /// 当前的标签编辑器组件
  TagEditorUI? _currentEditor;

  /// 是否正在加载文件
  bool _isLoading = false;

  /// 加载指定的音频文件
  /// [filePath] 要加载的文件路径
  void loadFile(String filePath) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 在后台 isolate 中读取标签，避免阻塞 UI
      final tags = await compute(
        readAudioTagsInBackground,
        ReadTagsParams(filePath),
      );

      if (tags != null && mounted) {
        // 判断是否是批量编辑模式（有多个文件）
        final isBatch = widget.filePaths.length > 1;
        setState(() {
          // 创建标签编辑器组件
          _currentEditor = TagEditorUI(
            tag: tags,
            filePath: filePath,
            realFilePath: filePath,
            additionalFiles: isBatch ? widget.filePaths.sublist(1) : null,
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('加载文件标签失败: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(EditPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当文件路径列表变化时，重新加载第一个文件
    if (widget.filePaths.isNotEmpty &&
        (oldWidget.filePaths.isEmpty ||
            oldWidget.filePaths.first != widget.filePaths.first)) {
      loadFile(widget.filePaths.first);
    }
    // 如果文件列表变空，清空编辑器
    if (widget.filePaths.isEmpty && oldWidget.filePaths.isNotEmpty) {
      setState(() => _currentEditor = null);
    }
  }

  @override
  void initState() {
    super.initState();
    // 初始化时加载第一个文件（如果有）
    if (widget.filePaths.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadFile(widget.filePaths.first);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果已经有编辑器，直接显示
    if (_currentEditor != null) {
      return _currentEditor!;
    }

    // 如果正在加载，显示加载指示器
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 否则显示占位符
    return _buildPlaceholder();
  }

  /// 构建占位符（当没有选择文件时显示）
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            useOwnLayer: true,
            settings: UIConfig.fileSelectorSettings,
            shape: const LiquidRoundedRectangle(borderRadius: 28.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  '请先在文件页面选择文件',
                  style: TextStyle(
                    fontFamily: 'MapleMono',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '切换到"文件"标签页浏览并选择 mp3 文件',
                  style: TextStyle(
                    fontFamily: 'MapleMono',
                    fontSize: 13,
                    color: Colors.grey,
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
