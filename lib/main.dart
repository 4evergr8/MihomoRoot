import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quick_settings/quick_settings.dart';
import '../theme/theme.dart';
import '../theme/util.dart';
import '../widget.dart';
import '../service/yaml.dart';

const String settingsPath = '/data/adb/mihomo/settings.yaml';

/// 执行重启 mihomo
void _restartMihomo() async {
  try {
    final settings = await readYamlAsObject(settingsPath);
    final stopCmd = settings['kill'] ?? '';
    final startCmd = settings['start'] ?? '';

    if (stopCmd.isNotEmpty) await Process.run("sh", ["-c", stopCmd]);
    if (startCmd.isNotEmpty) await Process.start("sh", ["-c", startCmd]);
  } catch (_) {}
}

/// Tile 点击回调
@pragma("vm:entry-point")
Tile onTileClicked(Tile tile) {
  _restartMihomo();                    // 执行重启
  tile.label = "重启 mihomo";           // 显示文字
  tile.drawableName = "quick_settings_base_icon"; // 图标
  tile.contentDescription = "重启 mihomo 服务";   // 无障碍描述
  tile.stateDescription = "已执行";               // 状态说明
  tile.subtitle = "点击可重启";                    // 副标题
  return tile;
}

/// Tile 添加回调
@pragma("vm:entry-point")
Tile? onTileAdded(Tile tile) => tile;

/// Tile 移除回调
@pragma("vm:entry-point")
void onTileRemoved() {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册 Tile 回调
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
    // 请求用户添加 Quick Settings Tile
    QuickSettings.addTileToQuickSettings(
      label: "重启 mihomo",
      drawableName: "quick_settings_base_icon",
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar();
  }
}