// 导入audiotags包，用于处理音频文件标签
import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 读取音频文件的标签信息
/// 
/// [filePath] 音频文件的路径
/// 返回包含标签信息的 [Tag] 对象，如果读取失败则返回 null
Future<Tag?> readAudioTags(String filePath) async {
  try {
    if (kDebugMode) {
      print('尝试读取音频标签，文件路径: $filePath');
      print('KDEBUG: 文件是否存在: ${await File(filePath).exists()}');
      print('KDEBUG: 文件大小: ${await File(filePath).length()} 字节');
    }
    final tag = await AudioTags.read(filePath);
    if (kDebugMode) {
      print('成功读取标签: 标题=${tag?.title}, 艺术家=${tag?.trackArtist}');
    }
    return tag;
  } on MissingPluginException catch (e) {
    if (kDebugMode) {
      print('插件异常: $e');
    }
    if (kDebugMode) {
      print('可能是本地库文件缺失或未正确加载');
    }
    return null;
  } on PlatformException catch (e) {
    if (kDebugMode) {
      print('平台异常: $e');
    }
    if (kDebugMode) {
      print('错误代码: ${e.code}, 错误详情: ${e.details}');
    }
    return null;
  } catch (e) {
    // 处理可能的异常，例如文件不存在或格式不支持
    if (kDebugMode) {
      print('读取音频标签时发生未知错误: $e');
    }
    return null;
  }
}