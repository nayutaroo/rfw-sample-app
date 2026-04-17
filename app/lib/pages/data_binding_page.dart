import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_sample/config/server_config.dart';
import 'package:rfw_sample/server/rfw_client.dart';

const _pageTitle = 'Data Binding';
const _screenName = 'product';
const _addToCartEvent = 'add_to_cart';
const _cartAddedSuffix = ' を注文しました';
const _refetchLabel = 'サーバーに再取得';
const _retryLabel = '再試行';

Runtime _buildRuntime() {
  final runtime = Runtime();
  runtime.update(const LibraryName(['core', 'widgets']), createCoreWidgets());
  runtime.update(const LibraryName(['material', 'widgets']), createMaterialWidgets());
  return runtime;
}

class DataBindingPage extends HookWidget {
  const DataBindingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = useMemoized(_buildRuntime);
    final dynamicContent = useMemoized(() => DynamicContent());
    final fetchCount = useState(0);
    final cartMessage = useState<String?>(null);

    // fetchCount が変わるたびにサーバーへ問い合わせ、
    // サーバーがそのタイミングで選んだバリアント（ウィジェット定義＋データ）を返す
    final screenFuture = useMemoized(
      () => RfwClient.fetchScreen(_screenName),
      [fetchCount.value],
    );
    final screenSnapshot = useFuture(screenFuture);

    useEffect(() {
      if (screenSnapshot.data case final config?) {
        runtime.update(const LibraryName(['main']), config.library);
        dynamicContent.updateAll(Map<String, Object>.from(config.data));
        cartMessage.value = null;
      }
      return null;
    }, [screenSnapshot.data]);

    return Scaffold(
      appBar: AppBar(
        title: const Text(_pageTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: switch (screenSnapshot) {
        AsyncSnapshot(hasError: true, :final error?) => _ErrorBody(
            message: error.toString(),
            onRetry: () => fetchCount.value++,
          ),
        AsyncSnapshot(connectionState: ConnectionState.waiting, data: null) =>
          const Center(child: CircularProgressIndicator()),
        AsyncSnapshot(:final data?) => _ScreenBody(
            runtime: runtime,
            dynamicContent: dynamicContent,
            config: data,
            cartMessage: cartMessage.value,
            onRefetch: () => fetchCount.value++,
            onEvent: (name, args) {
              if (name == _addToCartEvent) {
                final productName = screenSnapshot.data?.data['name'] ?? '';
                cartMessage.value = '$productName$_cartAddedSuffix';
              }
            },
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ScreenBody extends StatelessWidget {
  const _ScreenBody({
    required this.runtime,
    required this.dynamicContent,
    required this.config,
    required this.cartMessage,
    required this.onRefetch,
    required this.onEvent,
  });

  final Runtime runtime;
  final DynamicContent dynamicContent;
  final ScreenConfig config;
  final String? cartMessage;
  final VoidCallback onRefetch;
  final RemoteEventHandler onEvent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VariantBadge(config: config),
          const SizedBox(height: 12),
          RemoteWidget(
            runtime: runtime,
            widget: const FullyQualifiedWidgetName(LibraryName(['main']), 'root'),
            data: dynamicContent,
            onEvent: onEvent,
          ),
          const SizedBox(height: 16),
          if (cartMessage case final msg?) ...[
            _CartBanner(message: msg),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRefetch,
              icon: const Icon(Icons.refresh),
              label: const Text(_refetchLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantBadge extends StatelessWidget {
  const _VariantBadge({required this.config});
  final ScreenConfig config;

  @override
  Widget build(BuildContext context) {
    final screenUrl = '${ServerConfig.baseUrl}/screen/$_screenName';
    final widgetUrl = '${ServerConfig.baseUrl}/widgets/${config.widgetName}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.swap_horiz, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'widget: ${config.widgetName}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        _UrlRow(url: screenUrl),
        _UrlRow(url: widgetUrl),
      ],
    );
  }
}

class _UrlRow extends StatelessWidget {
  const _UrlRow({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cloud_download_outlined, size: 12, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(url, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _CartBanner extends StatelessWidget {
  const _CartBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
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
