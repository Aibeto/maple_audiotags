import 'package:flutter/material.dart';
import 'package:predictive_back_gesture/predictive_back_gesture.dart';

class BatchEditPage extends StatelessWidget {
  const BatchEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BackGestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('批量编辑'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: Text(
            '批量编辑功能预留界面',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}