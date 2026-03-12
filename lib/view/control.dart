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
  final String settingsPath = '/data/adb/mihomo/settings.yaml';

  String startCmd = '';
  String stopCmd = '';
  String webuiUrl = '';

  List<String> delays = ["--", "--", "--"];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    testDelays();
  }

  Future<void> _loadSettings() async {
    final settings = await readYamlAsObject(settingsPath);
    setState(() {
      startCmd = settings['start'] ?? '';
      stopCmd = settings['kill'] ?? '';
      webuiUrl = 'http://127.0.0.1:${settings['port'] ?? 9090}/ui';
    });
  }

  Future<void> start() async {
    if (startCmd.isEmpty) return;
    await Process.start("sh", ["-c", startCmd]);
  }

  Future<void> stop() async {
    if (stopCmd.isEmpty) return;
    await Process.start("sh", ["-c", stopCmd]);
  }

  Future<void> openWeb() async {
    if (webuiUrl.isEmpty) return;
    final uri = Uri.parse(webuiUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> testDelays() async {
    final hosts = ["www.google.com", "github.com", "t.me"];
    final futures = hosts.map((host) async {
      try {
        final ping = Ping(host, count: 1);
        await for (final event in ping.stream) {
          if (event.response != null) {
            return event.response!.time?.inMilliseconds.toString() ?? "超时";
          }
        }
        return "超时";
      } catch (_) {
        return "超时";
      }
    });
    final results = await Future.wait(futures);
    if (!mounted) return;
    setState(() => delays = results);
  }

  Widget _buildButtonRow({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              readOnly: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('控制')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 启动按钮行
            _buildButtonRow(
              label: '启动',
              icon: Icons.play_arrow,
              onPressed: start,
              value: startCmd,
            ),
            // 停止按钮行
            _buildButtonRow(
              label: '停止',
              icon: Icons.stop,
              onPressed: stop,
              value: stopCmd,
            ),
            // WEBUI按钮行
            _buildButtonRow(
              label: 'WEBUI',
              icon: Icons.language,
              onPressed: openWeb,
              value: webuiUrl,
            ),
            const SizedBox(height: 20),
            // 测速块
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
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
          ],
        ),
      ),
    );
  }
}