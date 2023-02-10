import 'package:flutter/material.dart';

class CommandBPage extends StatelessWidget {
  const CommandBPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command B'),
      ),
      body: Center(
        child: TextButton(
          child: const Text('完了'),
          onPressed: () {
            Navigator.pop(context, "CommandBPageの結果");
          },
        ),
      ),
    );
  }
}
