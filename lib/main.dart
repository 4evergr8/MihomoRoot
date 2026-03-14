import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quick_settings_with_flutter_plugins/quick_settings.dart';
import '../theme/theme.dart';
import '../theme/util.dart';
import '../widget.dart';
import '../service/yaml.dart';

const String settingsPath = '/data/adb/mihomo/settings.yaml';

bool _mihomoRunning = false;

Future<void> _stopMihomo() async {
  final settings = await readYamlAsObject(settingsPath);
  final stopCmd = settings['kill'] ?? '';
  if (stopCmd.isNotEmpty) {
    await Process.run("sh", ["-c", stopCmd]);
  }
}

Future<void> _startMihomo() async {
  try {
    final settings = await readYamlAsObject(settingsPath);
    final stopCmd = settings['kill'] ?? '';
    final startCmd = settings['start'] ?? '';

    // 先停止
    if (stopCmd.isNotEmpty) {
      await Process.run("sh", ["-c", stopCmd]);
    }

    // 再启动
    if (startCmd.isNotEmpty) {
      await Process.start("sh", ["-c", startCmd]);
    }
  } catch (_) {}
}

/// Tile 点击回调
@pragma('vm:entry-point')
Tile onTileClicked(Tile tile) {
  if (_mihomoRunning) {
    _stopMihomo();
    _mihomoRunning = false;
    tile.subtitle = "点击启动";
    tile.contentDescription = "mihomo 已停止";
  } else {
    _stopMihomo().then((_) => _startMihomo());
    _mihomoRunning = true;
    tile.subtitle = "点击停止";
    tile.contentDescription = "mihomo 已启动";
  }

  tile.label = "mihomo";
  tile.drawableName = "quick_settings_base_icon";
  return tile;
}

/// Tile 添加回调
@pragma('vm:entry-point')
Tile? onTileAdded(Tile tile) {
  tile.label = "mihomo";
  tile.drawableName = "quick_settings_base_icon";
  tile.contentDescription = "mihomo 核心开关";
  return tile;
}

/// Tile 移除回调
@pragma('vm:entry-point')
void onTileRemoved() {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  QuickSettings.setup(
    onTileClicked: onTileClicked,
    onTileAdded: onTileAdded,
    onTileRemoved: onTileRemoved,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Noto Sans", "Noto Sans");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'mihomoR',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    QuickSettings.addTileToQuickSettings(
      label: "mihomo",
      drawableName: "quick_settings_base_icon",
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar();
  }
}