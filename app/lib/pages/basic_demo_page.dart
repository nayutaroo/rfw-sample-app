import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_sample/config/server_config.dart';
import 'package:rfw_sample/server/rfw_client.dart';

const _pageTitle = 'Basic Demo';
const _sectionTitle = 'サーバーから取得した RFW バイナリをレンダリング';
const _eventReceivedPrefix = 'イベント受信: ';
const _retryLabel = '再試行';

const _definitions = [
  (label: 'カード', widgetName: 'basic_card'),
  (label: 'バナー', widgetName: 'basic_banner'),
  (label: 'リスト', widgetName: 'basic_list'),
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
    final retryCount = useState(0);

    final widgetName = _definitions[selectedIndex.value].widgetName;

    final widgetFuture = useMemoized(
      () => RfwClient.fetchWidget(widgetName),
      [widgetName, retryCount.value],
    );
    final widgetSnapshot = useFuture(widgetFuture);

    useEffect(() {
      if (widgetSnapshot.data case final library?) {
        runtime.update(const LibraryName(['main']), library);
      }
      return null;
    }, [widgetSnapshot.data]);

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
            child: switch (widgetSnapshot) {
              AsyncSnapshot(hasError: true, :final error?) => _ErrorBody(
                  message: error.toString(),
                  onRetry: () => retryCount.value++,
                ),
              AsyncSnapshot(connectionState: ConnectionState.waiting, data: null) =>
                const Center(child: CircularProgressIndicator()),
              _ => Padding(
                  padding: const EdgeInsets.all(16),
                  child: RemoteWidget(
                    runtime: runtime,
                    widget: const FullyQualifiedWidgetName(LibraryName(['main']), 'root'),
                    data: data,
                    onEvent: (name, args) => lastEvent.value = '$name $args',
                  ),
                ),
            },
          ),
          _SourceLabel(widgetName: widgetName),
        ],
      ),
    );
  }
}

class _SourceLabel extends StatelessWidget {
  const _SourceLabel({required this.widgetName});
  final String widgetName;

  @override
  Widget build(BuildContext context) {
    final url = '${ServerConfig.baseUrl}/widgets/$widgetName';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_download_outlined, size: 14, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 4),
          Text(url, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(_retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
