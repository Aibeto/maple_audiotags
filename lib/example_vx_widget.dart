import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ExampleVxWidget extends StatelessWidget {
  const ExampleVxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: "VelocityX 示例".text.make(),
      ),
      body: Center(
        child: "Hello, VelocityX!"
            .text
            .xl2
            .white
            .bold
            .center
            .make()
            .box
            .blue500
            .rounded
            .p16
            .make()
            .onInkTap(() => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("使用 VelocityX 很简单")))),
      ),
    );
  }
}