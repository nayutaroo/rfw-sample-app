import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';

const _pageTitle = 'Basic Demo';
const _sectionTitle = 'RFW テキスト定義からウィジェットをレンダリング';
const _eventReceivedPrefix = 'イベント受信: ';
const _showDefinitionLabel = 'RFW 定義を表示';

const _definitions = [
  (
    label: 'カード',
    rfw: '''
import core.widgets;
import material.widgets;

widget root = Card(
  elevation: 4.0,
  child: Padding(
    padding: {left: 20.0, top: 20.0, right: 20.0, bottom: 20.0},
    child: Column(
      mainAxisSize: "min",
      children: [
        Icon(icon: 0xe047, size: 48.0, color: 0xFF9C27B0),
        SizedBox(height: 12.0),
        Text(text: "RFW で描画されたカード", textAlign: "center"),
        SizedBox(height: 8.0),
        Text(
          text: "このウィジェットはテキスト形式の定義から動的に生成されています",
          textAlign: "center",
        ),
      ],
    ),
  ),
);
''',
  ),
  (
    label: 'バナー',
    rfw: '''
import core.widgets;
import material.widgets;

widget root = Container(
  color: 0xFF1565C0,
  child: Padding(
    padding: {left: 24.0, top: 32.0, right: 24.0, bottom: 32.0},
    child: Column(
      crossAxisAlignment: "start",
      children: [
        Text(text: "NEW ARRIVAL"),
        SizedBox(height: 8.0),
        Text(text: "プロモーションバナー"),
        SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: event "banner_tapped" {},
          child: Text(text: "詳細を見る"),
        ),
      ],
    ),
  ),
);
''',
  ),
  (
    label: 'リスト',
    rfw: '''
import core.widgets;
import material.widgets;

widget root = Column(
  children: [
    ListTile(
      leading: Icon(icon: 0xe318),
      title: Text(text: "設定"),
      trailing: Icon(icon: 0xe5c8),
      onTap: event "item_tapped" {index: 0},
    ),
    Divider(),
    ListTile(
      leading: Icon(icon: 0xe7fd),
      title: Text(text: "プロフィール"),
      trailing: Icon(icon: 0xe5c8),
      onTap: event "item_tapped" {index: 1},
    ),
    Divider(),
    ListTile(
      leading: Icon(icon: 0xe0c9),
      title: Text(text: "通知"),
      trailing: Icon(icon: 0xe5c8),
      onTap: event "item_tapped" {index: 2},
    ),
  ],
);
''',
  ),
];

Runtime _buildRuntime() {
  final runtime = Runtime();
  runtime.update(const LibraryName(['core', 'widgets']), createCoreWidgets());
  runtime.update(const LibraryName(['material', 'widgets']), createMaterialWidgets());
  return runtime;
}

class BasicDemoPage extends HookWidget {
  const BasicDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = useMemoized(_buildRuntime);
    final data = useMemoized(() => DynamicContent());
    final selectedIndex = useState(0);
    final lastEvent = useState<String?>(null);

    useEffect(() {
      runtime.update(
        const LibraryName(['main']),
        parseLibraryFile(_definitions[selectedIndex.value].rfw),
      );
      return null;
    }, [selectedIndex.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text(_pageTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_sectionTitle, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: [
                    for (int i = 0; i < _definitions.length; i++)
                      ButtonSegment(value: i, label: Text(_definitions[i].label)),
                  ],
                  selected: {selectedIndex.value},
                  onSelectionChanged: (s) {
                    selectedIndex.value = s.first;
                    lastEvent.value = null;
                  },
                ),
              ],
            ),
          ),
          if (lastEvent.value case final event?)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('$_eventReceivedPrefix$event'),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RemoteWidget(
                runtime: runtime,
                widget: const FullyQualifiedWidgetName(LibraryName(['main']), 'root'),
                data: data,
                onEvent: (name, args) => lastEvent.value = '$name $args',
              ),
            ),
          ),
          _DefinitionPanel(rfw: _definitions[selectedIndex.value].rfw),
        ],
      ),
    );
  }
}

class _DefinitionPanel extends HookWidget {
  const _DefinitionPanel({required this.rfw});
  final String rfw;

  @override
  Widget build(BuildContext context) {
    final expanded = useState(false);

    return Column(
      children: [
        InkWell(
          onTap: () => expanded.value = !expanded.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(_showDefinitionLabel, style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                Icon(expanded.value ? Icons.expand_more : Icons.expand_less, size: 16),
              ],
            ),
          ),
        ),
        if (expanded.value)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                rfw,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ),
      ],
    );
  }
}
