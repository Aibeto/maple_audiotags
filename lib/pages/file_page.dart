import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../config/ui_config.dart';

/// 文件浏览页面
/// 用于浏览文件系统并选择音频文件进行标签编辑
class FilePage extends StatefulWidget {
  /// 初始打开的目录路径
  final String? initialDir;

  /// 已选中的文件列表
  final List<String> selectedFiles;

  /// 选中文件变化时的回调函数
  final ValueChanged<List<String>> onSelectionChanged;

  /// 构造函数
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
  /// 当前浏览的目录路径
  late String _currentDir;

  /// 目录中的文件/文件夹条目列表
  List<_FileEntry> _entries = [];

  /// 已选中的文件路径集合
  final Set<String> _selectedPaths = {};

  /// 是否正在加载目录
  bool _isLoading = false;

  /// 是否处于多选模式
  bool _multiSelectMode = false;

  /// 可显示的文件扩展名集合（包括歌词文件）
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

  /// 可选择的文件扩展名集合（仅音频文件）
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

  /// 检查文件是否可以被选择
  /// [path] 文件路径
  bool _isSelectableExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    return _selectableExts.contains(ext);
  }

  /// 底部栏的额外间距
  static const _bottomBarClearance = 12.0;

  /// 特殊根目录标识，用于 Windows 显示所有盘符和固定项
  static const _winRoot = '::WIN_ROOT::';

  /// 获取默认的根目录路径，根据平台不同返回不同路径
  String get _defaultRoot {
    if (Platform.isAndroid) {
      return '/sdcard';
    }
    if (Platform.isWindows) {
      return _winRoot;
    }
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['HOME'] ?? '/';
    }
    return '/';
  }

  /// 获取 Windows 系统所有可用驱动器列表
  List<String> _getWindowsDrives() {
    // 常见的 Windows 驱动器字母
    const possibleDrives = [
      'A:',
      'B:',
      'C:',
      'D:',
      'E:',
      'F:',
      'G:',
      'H:',
      'I:',
      'J:',
      'K:',
      'L:',
      'M:',
      'N:',
      'O:',
      'P:',
      'Q:',
      'R:',
      'S:',
      'T:',
      'U:',
      'V:',
      'W:',
      'X:',
      'Y:',
      'Z:',
    ];
    final drives = <String>[];
    for (final drive in possibleDrives) {
      try {
        if (Directory('$drive\\').existsSync()) {
          drives.add('$drive\\');
        }
      } catch (e) {
        // 忽略不可访问的驱动器
      }
    }
    return drives;
  }

  /// 获取 Windows 系统常用固定项（桌面、文档、下载等）
  List<_FileEntry> _getWindowsQuickAccessItems() {
    final items = <_FileEntry>[];
    final profileDir = Platform.environment['USERPROFILE'];

    // 桌面
    if (profileDir != null) {
      final desktopPath = p.join(profileDir, 'Desktop');
      if (Directory(desktopPath).existsSync()) {
        items.add(
          const _FileEntry(path: '::DESKTOP::', name: '桌面', isDirectory: true),
        );
      }

      // 文档
      final docsPath = p.join(profileDir, 'Documents');
      if (Directory(docsPath).existsSync()) {
        items.add(
          const _FileEntry(
            path: '::DOCUMENTS::',
            name: '文档',
            isDirectory: true,
          ),
        );
      }

      // 下载
      final downloadsPath = p.join(profileDir, 'Downloads');
      if (Directory(downloadsPath).existsSync()) {
        items.add(
          const _FileEntry(
            path: '::DOWNLOADS::',
            name: '下载',
            isDirectory: true,
          ),
        );
      }

      // 音乐
      final musicPath = p.join(profileDir, 'Music');
      if (Directory(musicPath).existsSync()) {
        items.add(
          const _FileEntry(path: '::MUSIC::', name: '音乐', isDirectory: true),
        );
      }
    }

    return items;
  }

  /// 将特殊路径标识转换为真实路径
  String _resolveSpecialPath(String path) {
    final profileDir = Platform.environment['USERPROFILE'];
    if (profileDir == null) return path;

    switch (path) {
      case '::DESKTOP::':
        return p.join(profileDir, 'Desktop');
      case '::DOCUMENTS::':
        return p.join(profileDir, 'Documents');
      case '::DOWNLOADS::':
        return p.join(profileDir, 'Downloads');
      case '::MUSIC::':
        return p.join(profileDir, 'Music');
      default:
        return path;
    }
  }

  @override
  void initState() {
    super.initState();
    // 初始化当前目录
    _currentDir = widget.initialDir ?? _defaultRoot;
    // 初始化已选中的文件
    _selectedPaths.addAll(widget.selectedFiles);
    // 在第一帧绘制后请求权限并加载目录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionAndLoad();
    });
  }

  /// 请求存储权限并加载目录
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

  /// 请求 Android 存储权限
  /// 返回是否获得权限
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

  /// 加载当前目录的内容
  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);

    try {
      // Windows 特殊根目录：显示固定项和所有驱动器
      if (Platform.isWindows && _currentDir == _winRoot) {
        final quickAccess = _getWindowsQuickAccessItems();
        final drives = _getWindowsDrives();

        final driveEntries = drives.map((drive) {
          final driveLetter = drive.substring(0, 2); // 如 "C:"
          return _FileEntry(path: drive, name: driveLetter, isDirectory: true);
        }).toList();

        _entries = [...quickAccess, ...driveEntries];
        setState(() => _isLoading = false);
        return;
      }

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
      // 排序：文件夹在前，文件在后，均按名称字母顺序
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

      // 过滤并转换为 _FileEntry 对象
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

  /// 导航到指定目录
  /// [dirPath] 目标目录路径
  void _navigateTo(String dirPath) {
    setState(() {
      _currentDir = _resolveSpecialPath(dirPath);
    });
    _loadDirectory();
  }

  /// 导航到父目录
  void _navigateToParent() {
    if (Platform.isWindows) {
      // 如果当前在某个驱动器根目录，导航到特殊根
      if (_currentDir.endsWith('\\') && _currentDir.length == 3) {
        // 例如 "C:\"，长度为3
        setState(() => _currentDir = _winRoot);
        _loadDirectory();
        return;
      }
    }
    final parent = p.dirname(_currentDir);
    if (parent != _currentDir) {
      _navigateTo(parent);
    }
  }

  /// 切换文件的选中状态
  /// [path] 文件路径
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

  /// 切换多选模式
  void _toggleMultiSelectMode() {
    setState(() {
      _multiSelectMode = !_multiSelectMode;
      if (!_multiSelectMode) {
        _selectedPaths.clear();
        widget.onSelectionChanged([]);
      }
    });
  }

  /// 选中所有可选择的文件
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

  /// 取消所有选中
  void _deselectAll() {
    setState(() {
      _selectedPaths.clear();
    });
    widget.onSelectionChanged([]);
  }

  /// 重命名文件
  /// [oldPath] 原文件路径
  Future<void> _renameFile(String oldPath) async {
    final oldName = p.basename(oldPath);
    final dirPath = p.dirname(oldPath);
    final ext = p.extension(oldPath);

    final controller = TextEditingController(
      text: p.basenameWithoutExtension(oldPath),
    );

    // 显示重命名对话框
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(ctx).size.width * 0.85,
            ),
            child: GlassContainer(
              useOwnLayer: true,
              settings: UIConfig.compact,
              shape: const LiquidRoundedRectangle(borderRadius: 20.0),
              padding: const EdgeInsets.all(24.0),
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
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final newPath = p.join(dirPath, '$result$ext');
      try {
        await File(oldPath).rename(newPath);
        // 如果文件在选中列表中，更新选中状态
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

  /// 格式化文件大小
  /// [bytes] 字节数
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
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // 如果是 Android 或 Windows 平台
        if (Platform.isAndroid || Platform.isWindows) {
          // 检查是否在根目录
          if ((Platform.isAndroid && _currentDir == '/sdcard') ||
              (Platform.isWindows && _currentDir == _winRoot)) {
            // 在根目录时不允许返回
            Fluttertoast.showToast(msg: '已到达根目录');
            return false;
          }
          // 否则导航到父目录
          _navigateToParent();
          return false;
        }
        // 其他平台默认行为
        return true;
      },
      child: Column(
        children: [
          _buildPathBar(),
          _buildToolBar(),
          Expanded(child: _buildFileList()),
          if (_selectedPaths.isNotEmpty) _buildBottomBar(),
        ],
      ),
    );
  }

  /// 构建路径栏
  Widget _buildPathBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: GlassContainer(
        useOwnLayer: true,
        settings: UIConfig.compact,
        shape: const LiquidRoundedRectangle(borderRadius: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            // 在特殊根目录时不显示上一级按钮
            if (!(Platform.isWindows && _currentDir == _winRoot))
              GestureDetector(
                onTap: _navigateToParent,
                child: const Icon(Icons.arrow_upward, size: 20),
              ),
            if (!(Platform.isWindows && _currentDir == _winRoot))
              const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Windows 特殊根目录
                    if (Platform.isWindows && _currentDir == _winRoot)
                      Text(
                        '此电脑',
                        style: TextStyle(
                          fontFamily: 'MapleMono',
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      )
                    // Windows 普通路径
                    else if (Platform.isWindows)
                      ..._buildWindowsPathParts()
                    // Linux/Mac 路径
                    else
                      ..._buildUnixPathParts(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Windows 路径栏部分
  List<Widget> _buildWindowsPathParts() {
    final parts = _currentDir
        .split(Platform.pathSeparator)
        .where((p) => p.isNotEmpty)
        .toList();
    final widgets = <Widget>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final isLast = i == parts.length - 1;

      // 构建到当前部分的完整路径
      final String subPath;
      if (i == 0) {
        // 驱动器部分，如 C: -> C:\
        subPath = '$part\\';
      } else {
        subPath = parts.sublist(0, i + 1).join('\\') + '\\';
      }

      widgets.add(
        GestureDetector(
          onTap: isLast ? null : () => _navigateTo(subPath),
          child: Text(
            '$part${isLast ? '' : ' \\ '}',
            style: TextStyle(
              fontFamily: 'MapleMono',
              fontSize: 13,
              color: isLast
                  ? Theme.of(context).textTheme.bodyMedium?.color
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 构建 Unix(Linux/Mac) 路径栏部分
  List<Widget> _buildUnixPathParts() {
    final parts = _currentDir
        .split(Platform.pathSeparator)
        .where((p) => p.isNotEmpty)
        .toList();
    final widgets = <Widget>[];

    widgets.add(
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
    );

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final isLast = i == parts.length - 1;
      final subPath = '/${parts.sublist(0, i + 1).join('/')}';

      widgets.add(
        GestureDetector(
          onTap: isLast ? null : () => _navigateTo(subPath),
          child: Text(
            '$part${isLast ? '' : ' / '}',
            style: TextStyle(
              fontFamily: 'MapleMono',
              fontSize: 13,
              color: isLast
                  ? Theme.of(context).textTheme.bodyMedium?.color
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 构建工具栏
  Widget _buildToolBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          GlassContainer(
            useOwnLayer: true,
            settings: UIConfig.compact,
            shape: const LiquidRoundedRectangle(borderRadius: 8.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            child: InkWell(
              onTap: _toggleMultiSelectMode,
              borderRadius: BorderRadius.circular(8.0),
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
          if (_multiSelectMode) ...[
            const SizedBox(width: 8),
            GlassContainer(
              useOwnLayer: true,
              settings: UIConfig.compact,
              shape: const LiquidRoundedRectangle(borderRadius: 8.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
              ),
              child: InkWell(
                onTap: _selectAll,
                borderRadius: BorderRadius.circular(8.0),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.select_all, size: 18),
                    SizedBox(width: 4),
                    Text(
                      '全选',
                      style: TextStyle(fontFamily: 'MapleMono', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GlassContainer(
              useOwnLayer: true,
              settings: UIConfig.compact,
              shape: const LiquidRoundedRectangle(borderRadius: 8.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
              ),
              child: InkWell(
                onTap: _deselectAll,
                borderRadius: BorderRadius.circular(8.0),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.deselect, size: 18),
                    SizedBox(width: 4),
                    Text(
                      '全不选',
                      style: TextStyle(fontFamily: 'MapleMono', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建文件列表
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

  /// 构建单个文件/文件夹条目
  /// [entry] 文件/文件夹条目
  /// [isSelected] 是否被选中
  Widget _buildFileTile(_FileEntry entry, bool isSelected) {
    final isSelectable = _isSelectableExtension(entry.path);
    final isLrc = p.extension(entry.path).toLowerCase() == '.lrc';
    final isWinDrive = Platform.isWindows && entry.path.endsWith('\\');

    // 获取特殊固定项的图标
    IconData getSpecialIcon() {
      switch (entry.path) {
        case '::DESKTOP::':
          return Icons.desktop_windows;
        case '::DOCUMENTS::':
          return Icons.description;
        case '::DOWNLOADS::':
          return Icons.download;
        case '::MUSIC::':
          return Icons.music_note;
        default:
          return Icons.folder;
      }
    }

    // 获取特殊固定项的图标颜色
    Color getSpecialColor() {
      switch (entry.path) {
        case '::DESKTOP::':
          return Colors.blue;
        case '::DOCUMENTS::':
          return Colors.indigo;
        case '::DOWNLOADS::':
          return Colors.green;
        case '::MUSIC::':
          return Colors.purple;
        default:
          return Colors.amber;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: Opacity(
        opacity: isLrc ? 0.5 : 1.0,
        child: GlassContainer(
          useOwnLayer: true,
          settings: UIConfig.compact,
          shape: const LiquidRoundedRectangle(borderRadius: 10.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: ColoredBox(
            color: isSelected && isSelectable
                ? Theme.of(context).colorScheme.primary.withAlpha(30)
                : Colors.transparent,
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
                      isWinDrive
                          ? Icons.storage
                          : (entry.path.startsWith('::')
                                ? getSpecialIcon()
                                : (entry.isDirectory
                                      ? Icons.folder
                                      : _getFileIcon(entry.path))),
                      size: 22,
                      color: isWinDrive
                          ? Colors.blue
                          : (entry.path.startsWith('::')
                                ? getSpecialColor()
                                : (entry.isDirectory
                                      ? Colors.amber
                                      : _getFileIconColor(entry.path))),
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
    );
  }

  /// 根据文件扩展名获取对应的图标
  /// [path] 文件路径
  IconData _getFileIcon(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.lrc') return Icons.lyrics;
    if (ext == '.flac') return Icons.multitrack_audio;
    if (ext == '.wav' || ext == '.aiff') return Icons.graphic_eq;
    return Icons.audio_file;
  }

  /// 根据文件扩展名获取对应的图标颜色
  /// [path] 文件路径
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

  /// 显示文件操作选项
  /// [entry] 文件条目
  void _showFileOptions(_FileEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12.0),
        child: GlassContainer(
          useOwnLayer: true,
          settings: UIConfig.compact,
          shape: const LiquidRoundedRectangle(borderRadius: 20.0),
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
    );
  }

  /// 构建底部栏（显示选中的文件信息）
  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, _bottomBarClearance),
      child: GlassContainer(
        useOwnLayer: true,
        settings: UIConfig.base,
        shape: const LiquidRoundedRectangle(borderRadius: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
    );
  }
}

/// 文件/文件夹条目数据类
class _FileEntry {
  /// 完整路径
  final String path;

  /// 文件名
  final String name;

  /// 是否是目录
  final bool isDirectory;

  const _FileEntry({
    required this.path,
    required this.name,
    required this.isDirectory,
  });
}
