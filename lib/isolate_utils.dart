import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';

/// 在 isolate 中读取音频标签的参数类
class ReadTagsParams {
  final String filePath;

  ReadTagsParams(this.filePath);
}

/// 在 isolate 中保存音频标签的参数类
class SaveTagsParams {
  final String filePath;
  final Tag tag;

  SaveTagsParams(this.filePath, this.tag);
}

/// 在 isolate 中读取音频标签
Future<Tag?> readAudioTagsInBackground(ReadTagsParams params) async {
  try {
    if (kDebugMode) {
      print('在 isolate 中读取音频标签，文件路径: ${params.filePath}');
    }
    
    final tag = await AudioTags.read(params.filePath);
    
    if (kDebugMode) {
      print('在 isolate 中成功读取标签: 标题=${tag?.title}, 艺术家=${tag?.trackArtist}');
    }
    
    return tag;
  } catch (e) {
    if (kDebugMode) {
      print('在 isolate 中读取音频标签时发生错误: $e');
    }
    return null;
  }
}

/// 在 isolate 中保存音频标签
Future<bool> saveAudioTagsInBackground(SaveTagsParams params) async {
  try {
    if (kDebugMode) {
      print('在 isolate 中保存音频标签，文件路径: ${params.filePath}');
    }
    
    await AudioTags.write(params.filePath, params.tag);
    
    if (kDebugMode) {
      print('在 isolate 中成功保存标签到文件: ${params.filePath}');
    }
    
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('在 isolate 中保存音频标签时发生错误: $e');
    }
    return false;
  }
}