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
    testDelays();
    checkRunning();
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
    final hosts = [
      "www.google.com",
      "github.com",
      "t.me"
    ];

    final futures = hosts.map((host) async {
      try {
        final ping = Ping(host, count: 1);

        await for (final event in ping.stream) {
          final r = event.response;
          if (r != null) {
            return r.time?.inMilliseconds.toString() ?? "超时";
          }
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

  Widget delayCardGroup(VoidCallback onRefresh) {

    Widget item(String title, String delay) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(delay, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Row(
              children: [
                item('Google', delays[0]),
                item('Github', delays[1]),
                item('Telegram', delays[2]),
              ],
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              color: Theme.of(context).colorScheme.primary,
              onPressed: onRefresh,
            ),
          )
        ],
      ),
    );
  }

  Widget bigButton(String text, VoidCallback? onPressed, Color color) {
    return Expanded(
      child: SizedBox(
        height: 70,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(text, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget smallButton(String text, VoidCallback onPressed) {
    final isDisabled = !running; // 当未运行时禁用
    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled
                ? Theme.of(context).colorScheme.surfaceVariant
                : Theme.of(context).colorScheme.primary,
            foregroundColor: isDisabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isDisabled ? null : onPressed,
          child: Text(text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final startColor = running
        ? Theme.of(context).colorScheme.surfaceVariant
        : Theme.of(context).colorScheme.primary;

    final stopColor = running
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.surfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('控制')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                bigButton(
                  '启动',
                  running ? null : start,
                  startColor,
                ),
                const SizedBox(width: 16),
                bigButton(
                  '停止',
                  running ? kill : null,
                  stopColor,
                ),
              ],
            ),
            const SizedBox(height: 20),
            delayCardGroup(testDelays),
            const SizedBox(height: 20),
            Row(
              children: [
                smallButton('WebUI', openWeb),
                const SizedBox(width: 16),
                smallButton('重载配置', reloadConfig),
              ],
            ),
          ],
        ),
      ),
    );
  }
}