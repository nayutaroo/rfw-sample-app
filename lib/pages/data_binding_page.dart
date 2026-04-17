import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_sample/config/server_config.dart';
import 'package:rfw_sample/server/rfw_client.dart';

const _pageTitle = 'Data Binding';
const _sectionTitle = '同じ RFW 定義、異なるデータ';
const _sectionSubtitle = 'ウィジェット定義・データともにサーバーから取得しています';
const _switchSectionLabel = '商品を切り替える';
const _addToCartEvent = 'add_to_cart';
const _cartAddedSuffix = ' をカートに追加しました';
const _retryLabel = '再試行';
const _widgetSource = 'product_card';

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
    final data = useMemoized(() => DynamicContent());
    final currentIndex = useState(0);
    final cartMessage = useState<String?>(null);
    final retryCount = useState(0);

    final widgetFuture = useMemoized(
      () => RfwClient.fetchWidget(_widgetSource),
      [retryCount.value],
    );
    final productsFuture = useMemoized(
      () => RfwClient.fetchProducts(),
      [retryCount.value],
    );

    final widgetSnapshot = useFuture(widgetFuture);
    final productsSnapshot = useFuture(productsFuture);

    useEffect(() {
      if (widgetSnapshot.data case final library?) {
        runtime.update(const LibraryName(['main']), library);
      }
      return null;
    }, [widgetSnapshot.data]);

    useEffect(() {
      if (productsSnapshot.data case final products?) {
        if (currentIndex.value < products.length) {
          data.updateAll(Map<String, Object>.from(products[currentIndex.value]));
        }
      }
      return null;
    }, [productsSnapshot.data, currentIndex.value]);

    final isLoading = widgetSnapshot.connectionState == ConnectionState.waiting ||
        productsSnapshot.connectionState == ConnectionState.waiting;

    final error = widgetSnapshot.error ?? productsSnapshot.error;

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(_pageTitle),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => retryCount.value++,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(_retryLabel),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final products = productsSnapshot.data ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(_pageTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sectionTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(_sectionSubtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            _SourceRow(widgetName: _widgetSource),
            const SizedBox(height: 12),
            RemoteWidget(
              runtime: runtime,
              widget: const FullyQualifiedWidgetName(LibraryName(['main']), 'root'),
              data: data,
              onEvent: (name, args) {
                if (name == _addToCartEvent && currentIndex.value < products.length) {
                  final productName = products[currentIndex.value]['name'] ?? '';
                  cartMessage.value = '$productName$_cartAddedSuffix';
                }
              },
            ),
            const SizedBox(height: 16),
            if (cartMessage.value case final msg?) _CartBanner(message: msg),
            const SizedBox(height: 16),
            Text(_switchSectionLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (int i = 0; i < products.length; i++)
              _ProductTile(
                product: products[i],
                isSelected: currentIndex.value == i,
                onTap: () {
                  currentIndex.value = i;
                  cartMessage.value = null;
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.widgetName});
  final String widgetName;

  @override
  Widget build(BuildContext context) {
    final widgetUrl = '${ServerConfig.baseUrl}/widgets/$widgetName';
    final dataUrl = '${ServerConfig.baseUrl}/data/products';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UrlChip(url: widgetUrl),
        const SizedBox(height: 2),
        _UrlChip(url: dataUrl),
      ],
    );
  }
}

class _UrlChip extends StatelessWidget {
  const _UrlChip({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cloud_download_outlined, size: 14, color: Theme.of(context).colorScheme.outline),
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

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final Map<String, String> product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        selected: isSelected,
        title: Text(product['name'] ?? ''),
        subtitle: Text('¥${product['price'] ?? ''}'),
        trailing: Text(product['badge'] ?? ''),
        onTap: onTap,
      ),
    );
  }
}
