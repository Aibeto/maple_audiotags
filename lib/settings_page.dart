// 设置页面
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 效果等级变量，默认值为1
  int _effectLevel = 1;
  
  @override
  void initState() {
    super.initState();
    // 初始化时从shared preferences加载效果等级
    _loadEffectLevel();
  }
  
  // 从shared preferences加载效果等级
  Future<void> _loadEffectLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _effectLevel = prefs.getInt('effectLevel') ?? 1; // 默认值为1
    });
  }
  
  // 保存效果等级到shared preferences
  Future<void> _saveEffectLevel(int level) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('effectLevel', level);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '通用设置',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // 添加效果等级设置
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '效果等级',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('简单'),
                      Expanded(
                        child: Slider(
                          value: _effectLevel.toDouble(),
                          min: 1,
                          max: 3,
                          divisions: 2, // 三档：1, 2, 3
                          label: _effectLevel.toString(),
                          onChanged: (value) {
                            setState(() {
                              _effectLevel = value.toInt();
                            });
                          },
                          onChangeEnd: (value) {
                            // 滑动结束时保存设置
                            _saveEffectLevel(value.toInt());
                          },
                        ),
                      ),
                      const Text('复杂'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当前等级: $_effectLevel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}