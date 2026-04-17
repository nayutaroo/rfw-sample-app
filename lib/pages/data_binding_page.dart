import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rfw/formats.dart' show parseLibraryFile;
import 'package:rfw/rfw.dart';

const _pageTitle = 'Data Binding';
const _sectionTitle = '同じ RFW 定義、異なるデータ';
const _sectionSubtitle = 'DynamicContent を差し替えるとウィジェットが自動更新されます';
const _switchSectionLabel = '商品を切り替える';
const _addToCartEvent = 'add_to_cart';
const _cartAddedSuffix = ' をカートに追加しました';

const _productCardRfw = '''
import core.widgets;
import material.widgets;

widget root = Card(
  elevation: 2.0,
  child: Column(
    mainAxisSize: "min",
    crossAxisAlignment: "start",
    children: [
      Container(
        color: 0xFFE3F2FD,
        child: Padding(
          padding: {left: 16.0, top: 24.0, right: 16.0, bottom: 24.0},
          child: Row(
            mainAxisAlignment: "spaceBetween",
            children: [
              Icon(icon: 0xe1bc, size: 64.0, color: 0xFF1565C0),
              Column(
                crossAxisAlignment: "end",
                children: [
                  Text(text: data.badge),
                  SizedBox(height: 4.0),
                  Text(text: ["評価: ", data.rating]),
                ],
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: {left: 16.0, top: 12.0, right: 16.0, bottom: 4.0},
        child: Text(text: data.name),
      ),
      Padding(
        padding: {left: 16.0, top: 0.0, right: 16.0, bottom: 4.0},
        child: Text(text: data.brand),
      ),
      Padding(
        padding: {left: 16.0, top: 0.0, right: 16.0, bottom: 16.0},
        child: Row(
          mainAxisAlignment: "spaceBetween",
          children: [
            Text(text: ["¥", data.price]),
            ElevatedButton(
              onPressed: event "add_to_cart" {productId: data.id},
              child: Text(text: "カートに追加"),
            ),
          ],
        ),
      ),
    ],
  ),
);
''';

const _products = <Map<String, String>>[
  {
    'id': 'p001',
    'name': 'モイスチャライジングクリーム',
    'brand': 'スキンケアブランドA',
    'price': '3,200',
    'rating': '★★★★☆',
    'badge': 'ベストセラー',
  },
  {
    'id': 'p002',
    'name': 'ビタミンCセラム',
    'brand': 'スキンケアブランドB',
    'price': '5,800',
    'rating': '★★★★★',
    'badge': '新商品',
  },
  {
    'id': 'p003',
    'name': 'サンスクリーンSPF50',
    'brand': 'スキンケアブランドC',
    'price': '2,500',
    'rating': '★★★☆☆',
    'badge': 'セール中',
  },
];

Runtime _buildRuntime() {
  final runtime = Runtime();
  runtime.update(const LibraryName(['core', 'widgets']), createCoreWidgets());
  runtime.update(const LibraryName(['material', 'widgets']), createMaterialWidgets());
  runtime.update(const LibraryName(['main']), parseLibraryFile(_productCardRfw));
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

    useEffect(() {
      data.updateAll(Map<String, Object>.from(_products[currentIndex.value]));
      return null;
    }, [currentIndex.value]);

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
            const SizedBox(height: 16),
            RemoteWidget(
              runtime: runtime,
              widget: const FullyQualifiedWidgetName(LibraryName(['main']), 'root'),
              data: data,
              onEvent: (name, args) {
                if (name == _addToCartEvent) {
                  final productName = _products[currentIndex.value]['name'] ?? '';
                  cartMessage.value = '$productName$_cartAddedSuffix';
                }
              },
            ),
            const SizedBox(height: 16),
            if (cartMessage.value case final msg?) _CartBanner(message: msg),
            const SizedBox(height: 16),
            Text(_switchSectionLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (int i = 0; i < _products.length; i++)
              _ProductTile(
                product: _products[i],
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
