import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/yaml.dart';
import 'package:dart_ping/dart_ping.dart';

class ControlView extends StatefulWidget {
  const ControlView({super.key});

  @override
  State<ControlView> createState() => _ControlViewState();
}

class _ControlViewState extends State<ControlView> {
  List<String> delays = ["--", "--", "--"];
  final String settingsPath = '/data/adb/mihomo/settings.yaml';
  bool running = false;

  @override
  void initState() {
    super.initState();
    checkRunning();
    testDelays();

  }

  Future<void> checkRunning() async {
    try {
      final settings = await readYamlAsObject(settingsPath);
      final port = settings['port'];

      final socket = await Socket.connect(
        "127.0.0.1",
        port,
        timeout: const Duration(seconds: 1),
      );

      socket.destroy();

      setState(() {
        running = true;
      });
    } catch (_) {
      setState(() {
        running = false;
      });
    }
  }

  Future<void> start() async {
    final settings = await readYamlAsObject(settingsPath);
    final start = settings['start'];
    await Process.start("sh", ["-c", start]);
    await checkRunning();
  }

  Future<void> kill() async {
    final settings = await readYamlAsObject(settingsPath);
    final kill = settings['kill'];
    await Process.start("sh", ["-c", kill]);
    await checkRunning();
  }

  Future<void> openWeb() async {
    final settings = await readYamlAsObject(settingsPath);
    final port = settings['port'];
    final uri = Uri.parse("http://127.0.0.1:$port/ui");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> reloadConfig() async {
    final settings = await readYamlAsObject(settingsPath);
    final dio = Dio();
    final port = settings['port'];
    await dio.put('http://127.0.0.1:$port/configs?force=true');
  }

  Future<void> testDelays() async {
    final hosts = ["www.google.com", "github.com", "t.me"];
    final futures = hosts.map((host) async {
      try {
        final ping = Ping(host, count: 1);
        await for (final event in ping.stream) {
          final r = event.response;
          if (r != null) return r.time?.inMilliseconds.toString() ?? "超时";
        }
        return "超时";
      } catch (_) {
        return "超时";
      }
    });
    final results = await Future.wait(futures);
    setState(() {
      delays = results;
    });
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: const Text('控制')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 第一个容器：一级颜色，核心状态
            // 第一个容器：核心状态
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: running
                    ? Theme.of(context).colorScheme.primaryContainer  // 运行时一级容器
                    : Theme.of(context).colorScheme.errorContainer,   // 未运行时红色容器
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: running
                              ? Theme.of(context).colorScheme.onSurfaceVariant // 运行时启动按钮禁用灰
                              : Theme.of(context).colorScheme.primary,       // 未运行时启动按钮一级颜色
                        ),
                        onPressed: running ? null : start,
                        child: const Text('启动', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: running
                              ? Theme.of(context).colorScheme.error      // 运行时停止按钮红色
                              : Theme.of(context).colorScheme.onSurfaceVariant,   // 未运行时停止按钮禁用灰
                        ),
                        onPressed: running ? kill : null,
                        child: const Text('停止', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 第二个容器：三级颜色，测速块
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Google', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(delays[0], style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Github', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(delays[1], style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Telegram', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(delays[2], style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: testDelays,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 第三个容器：二级颜色，WEBUI 和重载配置
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          running ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surface,
                        ),
                        onPressed: running ? openWeb : null,
                        child: const Text('WEBUI', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          running ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surface,
                        ),
                        onPressed: running ? reloadConfig : null,
                        child: const Text('重载配置', style: TextStyle(fontSize: 18)),
                      ),
                    ),
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