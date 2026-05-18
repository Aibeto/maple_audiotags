// 导入音频标签处理库
import 'package:audiotags/audiotags.dart';
// 导入 Flutter 基础库
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 参数类
// ─────────────────────────────────────────────────────────────────────────────

/// 在 isolate 中读取音频标签的参数类
/// 封装了读取标签所需的所有参数，用于传递给 compute 函数
class ReadTagsParams {
  /// 音频文件的完整路径
  final String filePath;

  /// 构造函数
  ReadTagsParams(this.filePath);
}

/// 在 isolate 中保存音频标签的参数类
/// 封装了保存标签所需的所有参数，用于传递给 compute 函数
class SaveTagsParams {
  /// 音频文件的完整路径
  final String filePath;
  /// 要保存的标签数据
  final Tag tag;

  /// 构造函数
  SaveTagsParams(this.filePath, this.tag);
}

// ─────────────────────────────────────────────────────────────────────────────
// 异步操作函数
// ─────────────────────────────────────────────────────────────────────────────

/// 在 isolate 中读取音频标签
/// 使用 compute 函数在后台 isolate 中执行，避免阻塞 UI 线程
/// [params] 包含文件路径的参数对象
/// 返回读取到的标签对象，失败时返回 null
Future<Tag?> readAudioTagsInBackground(ReadTagsParams params) async {
  try {
    // 调试模式下打印日志
    if (kDebugMode) {
      print('在 isolate 中读取音频标签，文件路径: ${params.filePath}');
    }
    
    // 调用 AudioTags 库读取标签
    final tag = await AudioTags.read(params.filePath);
    
    // 调试模式下打印读取结果
    if (kDebugMode) {
      print('在 isolate 中成功读取标签: 标题=${tag?.title}, 艺术家=${tag?.trackArtist}');
    }
    
    // 返回读取到的标签
    return tag;
  } catch (e) {
    // 发生错误时打印错误信息
    if (kDebugMode) {
      print('在 isolate 中读取音频标签时发生错误: $e');
    }
    // 读取失败返回 null
    return null;
  }
}

/// 在 isolate 中保存音频标签
/// 使用 compute 函数在后台 isolate 中执行，避免阻塞 UI 线程
/// [params] 包含文件路径和标签数据的参数对象
/// 返回保存是否成功
Future<bool> saveAudioTagsInBackground(SaveTagsParams params) async {
  try {
    // 调试模式下打印日志
    if (kDebugMode) {
      print('在 isolate 中保存音频标签，文件路径: ${params.filePath}');
    }
    
    // 调用 AudioTags 库写入标签
    await AudioTags.write(params.filePath, params.tag);
    
    // 调试模式下打印成功信息
    if (kDebugMode) {
      print('在 isolate 中成功保存标签到文件: ${params.filePath}');
    }
    
    // 保存成功返回 true
    return true;
  } catch (e) {
    // 发生错误时打印错误信息
    if (kDebugMode) {
      print('在 isolate 中保存音频标签时发生错误: $e');
    }
    // 保存失败返回 false
    return false;
  }
}
