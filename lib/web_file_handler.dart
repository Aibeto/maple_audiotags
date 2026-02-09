// Minimal, stable Web file handler: one-shot file picker, parse bytes, navigate to TagEditorUI
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;

import 'package:audiotags/audiotags.dart';
import 'tag_editor_ui.dart';

class WebFileHandler {
  static final html.FileUploadInputElement _input = html.FileUploadInputElement()..accept = 'audio/*';

  /// 触发文件选择并直接处理（最小实现）
  static Future<void> selectAndProcessFiles(BuildContext context) async {
    _input.multiple = true;
    try {
      _input.value = '';
    } catch (_) {}
    _input.click();

    html.Event? ev;
    try {
      ev = await _input.onChange.first.timeout(const Duration(minutes: 5));
    } on TimeoutException {
      return;
    }

    final files = _input.files;
    if (files == null || files.isEmpty) {
      Fluttertoast.showToast(msg: '未选择任何文件');
      return;
    }

    if (files.length > 1000) {
      if (context.mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(title: const Text('文件数量过多'), content: Text('您选择了 ${files.length} 个文件，超过最大限制 1000 个文件。')));
      }
      return;
    }

    if (context.mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(title: Text('正在处理文件'), content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))));
    }

    try {
      final List<WebFileData> webFiles = [];
      for (final f in files) {
        final bytes = await _readFile(f);
        webFiles.add(WebFileData(name: f.name, bytes: bytes, mimeType: f.type));
      }

      if (context.mounted) Navigator.of(context).pop();

      // 读取第一个文件的标签（内存解析）
      Tag? tag;
      try {
        tag = await _parseTagsFromBytes(webFiles[0].bytes);
      } catch (_) {
        tag = null;
      }

      // 导航到编辑界面（保持原生代码路径一致性）
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TagEditorUI(
          tag: tag ?? Tag(title: '', trackArtist: '', album: '', albumArtist: '', genre: '', pictures: const []),
          filePath: webFiles[0].name,
          realFilePath: null,
          webFileData: webFiles[0],
          additionalWebFiles: webFiles.length > 1 ? webFiles.sublist(1) : null,
        )));
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (kDebugMode) print('Web 处理失败: $e');
      if (context.mounted) showDialog(context: context, builder: (_) => AlertDialog(title: const Text('处理失败'), content: Text('$e')));
    }
  }

  static Future<Uint8List> _readFile(html.File f) {
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final res = reader.result;
      if (res is ByteBuffer) {
        completer.complete(Uint8List.view(res));
      } else if (res is TypedData) completer.complete(res.buffer.asUint8List());
      else if (res is List<int>) completer.complete(Uint8List.fromList(res));
      else completer.completeError('Unexpected FileReader result: ${res.runtimeType}');
    });
    reader.onError.listen((e) => completer.completeError(e));
    reader.readAsArrayBuffer(f);
    return completer.future;
  }

  // 简单 ID3v2 / ID3v1 解析（用于 web 最小实现）
  static Future<Tag?> _parseTagsFromBytes(Uint8List bytes) async {
    try {
      String? title, artist, album, albumArtist, genre;
      String decode(Uint8List d, int enc) {
        try {
          if (enc == 0) return latin1.decode(d).trim();
          if (enc == 3) return utf8.decode(d).trim();
          return String.fromCharCodes(d).trim();
        } catch (_) { return ''; }
      }

      if (bytes.length > 10 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
        final ver = bytes[3];
        int headerSize = ((bytes[6] & 0x7F) << 21) | ((bytes[7] & 0x7F) << 14) | ((bytes[8] & 0x7F) << 7) | (bytes[9] & 0x7F);
        int pos = 10; final end = 10 + headerSize;
        while (pos + 10 <= bytes.length && pos < end) {
          final id = latin1.decode(bytes.sublist(pos, pos + 4));
          if (id.trim().isEmpty) break;
          int size = ver >= 4 ? ((bytes[pos+4]&0x7F)<<21)|((bytes[pos+5]&0x7F)<<14)|((bytes[pos+6]&0x7F)<<7)|(bytes[pos+7]&0x7F) : (bytes[pos+4]<<24)|(bytes[pos+5]<<16)|(bytes[pos+6]<<8)|(bytes[pos+7]);
          final dataStart = pos + 10;
          if (size <= 0 || dataStart + size > bytes.length) break;
          final data = bytes.sublist(dataStart, dataStart + size);
          if (id == 'TIT2') title = decode(data.sublist(1), data.isNotEmpty ? data[0] : 0);
          if (id == 'TPE1') artist = decode(data.sublist(1), data.isNotEmpty ? data[0] : 0);
          if (id == 'TALB') album = decode(data.sublist(1), data.isNotEmpty ? data[0] : 0);
          if (id == 'TPE2') albumArtist = decode(data.sublist(1), data.isNotEmpty ? data[0] : 0);
          if (id == 'TCON') genre = decode(data.sublist(1), data.isNotEmpty ? data[0] : 0);
          pos = dataStart + size;
        }
      }

      if ((title == null || title.isEmpty) && bytes.length > 128) {
        final tail = bytes.sublist(bytes.length - 128);
        if (tail.length >= 128 && tail[0] == 0x54 && tail[1] == 0x41 && tail[2] == 0x47) {
          title ??= latin1.decode(tail.sublist(3,33)).trim();
          artist ??= latin1.decode(tail.sublist(33,63)).trim();
          album ??= latin1.decode(tail.sublist(63,93)).trim();
        }
      }

      if ((title?.isNotEmpty ?? false) || (artist?.isNotEmpty ?? false) || (album?.isNotEmpty ?? false)) {
        return Tag(title: title ?? '', trackArtist: artist ?? '', album: album ?? '', albumArtist: albumArtist ?? '', genre: genre ?? '', pictures: const []);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('parse tags error: $e');
      return null;
    }
  }


  /// 保存Web文件
  /// 通过浏览器下载功能保存文件
  Future<void> saveWebFile(WebFileData webFile, String fileName) async {
    // 创建Blob对象
    final blob = html.Blob([webFile.bytes], webFile.mimeType);
    
    // 创建下载链接
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    
    // 触发下载
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  /// 批量保存Web文件
  /// 依次下载所有文件
  Future<void> saveMultipleWebFiles(List<WebFileData> webFiles, String baseFileName) async {
    for (int i = 0; i < webFiles.length; i++) {
      final webFile = webFiles[i];
      final fileName = i == 0 
          ? baseFileName 
          : '${path.basenameWithoutExtension(baseFileName)}_${i + 1}${path.extension(baseFileName)}';
      
      await saveWebFile(webFile, fileName);
    }
  }
}