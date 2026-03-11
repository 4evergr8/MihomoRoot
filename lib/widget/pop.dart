import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, String title, Object error) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(error.toString())),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
Future<VoidCallback> showLoadingDialog(BuildContext context, {String? title}) async {
  final dialogContext = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (title != null) ...[
            const SizedBox(height: 12),
            Text(title),
          ],
        ],
      ),
    ),
  );

  // 返回一个关闭函数
  return () => Navigator.of(context, rootNavigator: true).pop();
}