import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../config/ui_config.dart';

class FilePage extends StatefulWidget {
  final String? initialDir;
  final List<String> selectedFiles;
  final ValueChanged<List<String>> onSelectionChanged;

  const FilePage({
    super.key,
    this.initialDir,
    required this.selectedFiles,
    required this.onSelectionChanged,
  });

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  late String _currentDir;
  List<_FileEntry> _entries = [];
  final Set<String> _selectedPaths = {};
  bool _isLoading = false;
  bool _multiSelectMode = false;

  static const _displayExts = {
    '.mp3',
    '.flac',
    '.wav',
    '.aac',
    '.ogg',
    '.wma',
    '.m4a',
    '.opus',
    '.aiff',
    '.ape',
    '.lrc',
  };

  static const _selectableExts = {
    '.mp3',
    '.flac',
    '.wav',
    '.aac',
    '.ogg',
    '.wma',
    '.m4a',
    '.opus',
    '.aiff',
    '.ape',
  };

  bool _isSelectableExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    return _selectableExts.contains(ext);
  }

  static const _bottomBarClearance = 12.0;

  String get _defaultRoot {
    if (Platform.isAndroid) {
      return '/sdcard';
    }
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? 'C:\\';
    }
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['HOME'] ?? '/';
    }
    return '/';
  }

  @override
  void initState() {
    super.initState();
    _currentDir = widget.initialDir ?? _defaultRoot;
    _selectedPaths.addAll(widget.selectedFiles);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionAndLoad();
    });
  }

  Future<void> _requestPermissionAndLoad() async {
    if (Platform.isAndroid) {
      final granted = await _requestStoragePermission();
      if (!granted) {
        if (mounted) {
          Fluttertoast.showToast(msg: '需要存储权限才能浏览文件');
        }
      }
    }
    _loadDirectory();
  }

  Future<bool> _requestStoragePermission() async {
    try {
      final androidVersion =
          int.tryParse(
            Platform.operatingSystemVersion
                .replaceAll(RegExp(r'[^\d.]'), '')
                .split('.')
                .first,
          ) ??
          0;

      if (androidVersion >= 11) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        return status.isGranted;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);

    try {
      final dir = Directory(_currentDir);
      if (!await dir.exists()) {
        if (mounted) {
          Fluttertoast.showToast(msg: '目录不存在: $_currentDir');
          _navigateToParent();
        }
        setState(() => _isLoading = false);
        return;
      }

      final List<FileSystemEntity> entities = dir.listSync();
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase());
      });

      _entries = entities
          .where((e) {
            if (e is Directory) {
              final name = p.basename(e.path);
              return !name.startsWith('.');
            }
            if (e is File) {
              final ext = p.extension(e.path).toLowerCase();
              return _displayExts.contains(ext);
            }
            return false;
          })
          .map((e) {
            final isDir = e is Directory;
            return _FileEntry(
              path: e.path,
              name: p.basename(e.path),
              isDirectory: isDir,
            );
          })
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) {
        print('加载目录失败: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        Fluttertoast.showToast(msg: '加载目录失败: $e');
      }
    }
  }

  void _navigateTo(String dirPath) {
    setState(() {
      _currentDir = dirPath;
    });
    _loadDirectory();
  }

  void _navigateToParent() {
    final parent = p.dirname(_currentDir);
    if (parent != _currentDir) {
      _navigateTo(parent);
    }
  }

  void _toggleSelection(String path) {
    if (!_isSelectableExtension(path)) {
      Fluttertoast.showToast(msg: 'LRC 歌词文件不可选中');
      return;
    }
    setState(() {
      if (_multiSelectMode) {
        if (_selectedPaths.contains(path)) {
          _selectedPaths.remove(path);
        } else {
          _selectedPaths.add(path);
        }
      } else {
        _selectedPaths.clear();
        _selectedPaths.add(path);
      }
    });
    widget.onSelectionChanged(_selectedPaths.toList());
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _multiSelectMode = !_multiSelectMode;
      if (!_multiSelectMode) {
        _selectedPaths.clear();
        widget.onSelectionChanged([]);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final entry in _entries) {
        if (!entry.isDirectory && _isSelectableExtension(entry.path)) {
          _selectedPaths.add(entry.path);
        }
      }
    });
    widget.onSelectionChanged(_selectedPaths.toList());
  }

  void _deselectAll() {
    setState(() {
      _selectedPaths.clear();
    });
    widget.onSelectionChanged([]);
  }

  Future<void> _renameFile(String oldPath) async {
    final oldName = p.basename(oldPath);
    final dirPath = p.dirname(oldPath);
    final ext = p.extension(oldPath);

    final controller = TextEditingController(
      text: p.basenameWithoutExtension(oldPath),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Center(
          child: LiquidGlassLayer(
            settings: UIConfig.dialogSettings,
            child: LiquidGlass.inLayer(
              shape: const LiquidRoundedRectangle(
                borderRadius: Radius.circular(20.0),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(ctx).size.width * 0.85,
                ),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Theme.of(ctx).colorScheme.surface.withAlpha(220),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '重命名',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MapleMono',
                        color: Theme.of(ctx).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '当前: $oldName',
                      style: TextStyle(
                        fontFamily: 'MapleMono',
                        color: Theme.of(ctx).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '新文件名',
                        suffixText: ext,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'MapleMono'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            '取消',
                            style: TextStyle(fontFamily: 'MapleMono'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, controller.text.trim()),
                          child: const Text(
                            '确定',
                            style: TextStyle(fontFamily: 'MapleMono'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final newPath = p.join(dirPath, '$result$ext');
      try {
        await File(oldPath).rename(newPath);
        if (_selectedPaths.contains(oldPath)) {
          _selectedPaths.remove(oldPath);
          _selectedPaths.add(newPath);
          widget.onSelectionChanged(_selectedPaths.toList());
        }
        _loadDirectory();
        Fluttertoast.showToast(msg: '重命名成功');
      } catch (e) {
        Fluttertoast.showToast(msg: '重命名失败: $e');
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPathBar(),
        _buildToolBar(),
        Expanded(child: _buildFileList()),
        if (_selectedPaths.isNotEmpty) _buildBottomBar(),
      ],
    );
  }

  Widget _buildPathBar() {
    final parts = _currentDir
        .split(Platform.pathSeparator)
        .where((p) => p.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: LiquidGlassLayer(
        settings: UIConfig.smallButtonSettings,
        child: LiquidGlass.inLayer(
          shape: const LiquidRoundedRectangle(
            borderRadius: Radius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _navigateToParent,
                  child: const Icon(Icons.arrow_upward, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _navigateTo('/'),
                          child: Text(
                            '/ ',
                            style: TextStyle(
                              fontFamily: 'MapleMono',
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        for (int i = 0; i < parts.length; i++)
                          GestureDetector(
                            onTap: () {
                              final subPath =
                                  '/${parts.sublist(0, i + 1).join('/')}';
                              _navigateTo(subPath);
                            },
                            child: Text(
                              '${parts[i]} ${i < parts.length - 1 ? '/ ' : ''}',
                              style: TextStyle(
                                fontFamily: 'MapleMono',
                                fontSize: 13,
                                color: i == parts.length - 1
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          LiquidGlassLayer(
            settings: UIConfig.smallButtonSettings,
            child: LiquidGlass.inLayer(
              shape: const LiquidRoundedRectangle(
                borderRadius: Radius.circular(8.0),
              ),
              child: InkWell(
                onTap: _toggleMultiSelectMode,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _multiSelectMode
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _multiSelectMode ? '取消多选' : '多选',
                        style: const TextStyle(
                          fontFamily: 'MapleMono',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_multiSelectMode) ...[
            const SizedBox(width: 8),
            LiquidGlassLayer(
              settings: UIConfig.smallButtonSettings,
              child: LiquidGlass.inLayer(
                shape: const LiquidRoundedRectangle(
                  borderRadius: Radius.circular(8.0),
                ),
                child: InkWell(
                  onTap: _selectAll,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.select_all, size: 18),
                        SizedBox(width: 4),
                        Text(
                          '全选',
                          style: TextStyle(
                            fontFamily: 'MapleMono',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            LiquidGlassLayer(
              settings: UIConfig.smallButtonSettings,
              child: LiquidGlass.inLayer(
                shape: const LiquidRoundedRectangle(
                  borderRadius: Radius.circular(8.0),
                ),
                child: InkWell(
                  onTap: _deselectAll,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.deselect, size: 18),
                        SizedBox(width: 4),
                        Text(
                          '全不选',
                          style: TextStyle(
                            fontFamily: 'MapleMono',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty) {
      return Center(
        child: Text(
          '此目录下没有支持的音频或歌词文件',
          style: TextStyle(
            fontFamily: 'MapleMono',
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final isSelected = _selectedPaths.contains(entry.path);

        return _buildFileTile(entry, isSelected);
      },
    );
  }

  Widget _buildFileTile(_FileEntry entry, bool isSelected) {
    final isSelectable = _isSelectableExtension(entry.path);
    final isLrc = p.extension(entry.path).toLowerCase() == '.lrc';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: Opacity(
        opacity: isLrc ? 0.5 : 1.0,
        child: LiquidGlassLayer(
          settings: UIConfig.smallButtonSettings,
          child: LiquidGlass.inLayer(
            shape: LiquidRoundedRectangle(
              borderRadius: const Radius.circular(10.0),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10.0),
                onTap: () {
                  if (entry.isDirectory) {
                    _navigateTo(entry.path);
                  } else if (isSelectable) {
                    _toggleSelection(entry.path);
                  } else {
                    Fluttertoast.showToast(msg: 'LRC 歌词文件不可选中');
                  }
                },
                onLongPress: () {
                  if (!entry.isDirectory && isSelectable) {
                    _showFileOptions(entry);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: isSelected && isSelectable
                        ? Theme.of(context).colorScheme.primary.withAlpha(30)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      if (_multiSelectMode && !entry.isDirectory)
                        Icon(
                          isLrc
                              ? Icons.block
                              : (isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank),
                          size: 20,
                          color: isLrc
                              ? Theme.of(context).textTheme.bodySmall?.color
                              : (isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color),
                        ),
                      if (_multiSelectMode && !entry.isDirectory)
                        const SizedBox(width: 8),
                      Icon(
                        entry.isDirectory
                            ? Icons.folder
                            : _getFileIcon(entry.path),
                        size: 22,
                        color: entry.isDirectory
                            ? Colors.amber
                            : _getFileIconColor(entry.path),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.name,
                                    style: TextStyle(
                                      fontFamily: 'MapleMono',
                                      fontSize: 14,
                                      fontWeight: isSelected && isSelectable
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isLrc)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '歌词',
                                      style: TextStyle(
                                        fontFamily: 'MapleMono',
                                        fontSize: 10,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (!entry.isDirectory)
                              FutureBuilder<FileStat>(
                                future: File(entry.path).stat(),
                                builder: (context, snapshot) {
                                  final size = snapshot.data?.size ?? 0;
                                  return Text(
                                    _formatFileSize(size),
                                    style: TextStyle(
                                      fontFamily: 'MapleMono',
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      if (!entry.isDirectory && isSelectable)
                        GestureDetector(
                          onTap: () => _showFileOptions(entry),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.more_vert, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.lrc') return Icons.lyrics;
    if (ext == '.flac') return Icons.multitrack_audio;
    if (ext == '.wav' || ext == '.aiff') return Icons.graphic_eq;
    return Icons.audio_file;
  }

  Color _getFileIconColor(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.lrc') return Colors.teal;
    if (ext == '.flac') return Colors.deepPurple;
    if (ext == '.wav' || ext == '.aiff') return Colors.orange;
    if (ext == '.ogg' || ext == '.opus') return Colors.amber;
    if (ext == '.aac' || ext == '.m4a') return Colors.green;
    if (ext == '.wma') return Colors.red;
    if (ext == '.ape') return Colors.brown;
    return Colors.blue;
  }

  void _showFileOptions(_FileEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12.0),
        child: LiquidGlassLayer(
          settings: UIConfig.dialogSettings,
          child: LiquidGlass.inLayer(
            shape: const LiquidRoundedRectangle(
              borderRadius: Radius.circular(20.0),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Theme.of(ctx).colorScheme.surface.withAlpha(230),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(150),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text(
                        '重命名',
                        style: TextStyle(fontFamily: 'MapleMono'),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _renameFile(entry.path);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        _selectedPaths.contains(entry.path)
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      title: Text(
                        _selectedPaths.contains(entry.path) ? '取消选择' : '选择',
                        style: const TextStyle(fontFamily: 'MapleMono'),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _toggleSelection(entry.path);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, _bottomBarClearance),
      child: LiquidGlassLayer(
        settings: UIConfig.baseSettings,
        child: LiquidGlass.inLayer(
          shape: const LiquidRoundedRectangle(
            borderRadius: Radius.circular(16.0),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '已选 ${_selectedPaths.length} 个文件',
                  style: TextStyle(
                    fontFamily: 'MapleMono',
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedPaths.clear());
                    widget.onSelectionChanged([]);
                  },
                  child: const Text(
                    '清除',
                    style: TextStyle(fontFamily: 'MapleMono'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileEntry {
  final String path;
  final String name;
  final bool isDirectory;

  const _FileEntry({
    required this.path,
    required this.name,
    required this.isDirectory,
  });
}
