import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../config/ui_config.dart';
import '../isolate_utils.dart';
import '../tag_editor_ui.dart';

class EditPage extends StatefulWidget {
  final List<String> filePaths;

  const EditPage({super.key, required this.filePaths});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  TagEditorUI? _currentEditor;
  bool _isLoading = false;

  void loadFile(String filePath) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final tags = await compute(
        readAudioTagsInBackground,
        ReadTagsParams(filePath),
      );

      if (tags != null && mounted) {
        final isBatch = widget.filePaths.length > 1;
        setState(() {
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
    if (widget.filePaths.isNotEmpty &&
        (oldWidget.filePaths.isEmpty ||
            oldWidget.filePaths.first != widget.filePaths.first)) {
      loadFile(widget.filePaths.first);
    }
    if (widget.filePaths.isEmpty && oldWidget.filePaths.isNotEmpty) {
      setState(() => _currentEditor = null);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.filePaths.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadFile(widget.filePaths.first);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEditor != null) {
      return _currentEditor!;
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildPlaceholder();
  }

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
