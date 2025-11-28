// 批量编辑页面
import 'package:flutter/material.dart';

// 批量编辑页面组件，继承自StatelessWidget，表示这是一个无状态组件
class BatchEditPage extends StatelessWidget {
  // 构造函数，使用const构造函数提高性能
  const BatchEditPage({super.key});

  // 构建UI界面的方法
  @override
  Widget build(BuildContext context) {
    // 使用Scaffold作为页面的基本结构
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
      ),
      // 页面主体内容区域
      body: const Center(
        // 居中显示文本内容
        child: Text(
          // 显示提示文本
          '批量编辑功能预留界面',
          // 文本样式设置
          style: TextStyle(
            // 字体大小
            fontSize: 20,
            // 颜色设置为灰色
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}