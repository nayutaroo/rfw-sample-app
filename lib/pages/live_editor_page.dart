import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';

const _pageTitle = 'Live Editor';
const _editorPanelLabel = 'RFW 定義';
const _previewPanelLabel = 'プレビュー';
const _applyButtonLabel = '適用';
const _eventPrefix = 'イベント: ';
const _parseErrorTitle = 'パースエラー';
const _togglePreviewTooltip = 'プレビュー拡大';
const _toggleEditorTooltip = 'エディタ表示';

const _initialRfw = '''
import core.widgets;
import material.widgets;

widget root = Center(
  child: Column(
    mainAxisSize: "min",
    children: [
      Icon(icon: 0xe87d, size: 64.0, color: 0xFF4CAF50),
      SizedBox(height: 16.0),
      Text(text: "ここを編集してみよう！"),
      SizedBox(height: 8.0),
      ElevatedButton(
        onPressed: event "hello" {},
        child: Text(text: "タップ"),
      ),
    ],
  ),
);
''';

Runtime _buildRuntime() {
  final runtime = Runtime();
  runtime.update(const LibraryName(['core', 'widgets']), createCoreWidgets());
  runtime.update(const LibraryName(['material', 'widgets']), createMaterialWidgets());
  return runtime;
}

void _applyRfw(Runtime runtime, String rfwText, ValueNotifier<String?> errorMessage) {
  try {
    runtime.update(const LibraryName(['main']), parseLibraryFile(rfwText));
    errorMessage.value = null;
  } on Object catch (e) {
    errorMessage.value = e.toString();
  }
}

class LiveEditorPage extends HookWidget {
  const LiveEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = useMemoized(_buildRuntime);
    final data = useMemoized(() => DynamicContent());
    final controller = useTextEditingController(text: _initialRfw);
    final errorMessage = useState<String?>(null);
    final lastEvent = useState<String?>(null);
    final isPreviewMode = useState(false);

    useEffect(() {
      _applyRfw(runtime, _initialRfw, errorMessage);
      return null;
    }, const []);

    void applyChanges() {
      _applyRfw(runtime, controller.text, errorMessage);
      lastEvent.value = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(_pageTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(isPreviewMode.value ? Icons.edit : Icons.preview),
            tooltip: isPreviewMode.value ? _toggleEditorTooltip : _togglePreviewTooltip,
            onPressed: () => isPreviewMode.value = !isPreviewMode.value,
          ),
        ],
      ),
      body: isPreviewMode.value
          ? _PreviewPanel(
              runtime: runtime,
              data: data,
              errorMessage: errorMessage.value,
              lastEvent: lastEvent,
            )
          : Row(
              children: [
                Expanded(
                  child: _EditorPanel(controller: controller, onApply: applyChanges),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _PreviewPanel(
                    runtime: runtime,
                    data: data,
                    errorMessage: errorMessage.value,
                    lastEvent: lastEvent,
                  ),
                ),
              ],
            ),
    );
  }
}

class _EditorPanel extends HookWidget {
  const _EditorPanel({required this.controller, required this.onApply});

  final TextEditingController controller;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(_editorPanelLabel, style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text(_applyButtonLabel),
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
            ),
            textAlignVertical: TextAlignVertical.top,
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends HookWidget {
  const _PreviewPanel({
    required this.runtime,
    required this.data,
    required this.errorMessage,
    required this.lastEvent,
  });

  final Runtime runtime;
  final DynamicContent data;
  final String? errorMessage;
  final ValueNotifier<String?> lastEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(_previewPanelLabel, style: Theme.of(context).textTheme.labelMedium),
        ),
        if (lastEvent.value case final event?)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              '$_eventPrefix$event',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: switch (errorMessage) {
            final msg? => _ErrorView(message: msg),
            null => RemoteWidget(
                runtime: runtime,
                widget: const FullyQualifiedWidgetName(LibraryName(['main']), 'root'),
                data: data,
                onEvent: (name, args) => lastEvent.value = '$name($args)',
              ),
          },
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
          const SizedBox(height: 12),
          Text(
            _parseErrorTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
